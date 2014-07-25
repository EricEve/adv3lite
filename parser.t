#charset "us-ascii"
#include "advlite.h"

/* ------------------------------------------------------------------------ */
/*
 *   Temporary scaffolding for the game world.  This gives us information
 *   on scope, pronoun antecedents, and other information the parser needs
 *   from the game world.  
 */
World: PreinitObject
    /*
     *   Get the list of objects in scope 
     */
    scope()
    {
        local s = scope_;

        if (s == nil)
            scope_ = s = Q.scopeList(gPlayerChar);

        return s;
    }

    /* cached scope list */
    scope_ = nil

    /* 
     *   A list of all Mentionables in the game, useful for building scope lists
     *   for resolving Topics.
     */
    universalScope = nil
    
    buildUniversalScope()
    {
        local vec = new Vector(100);
        forEachInstance(Mentionable, {o: vec.append(o) });
        universalScope = vec.toList;
    }
    
    execute()
    {
        buildUniversalScope();
    }
    
    
;


/* ------------------------------------------------------------------------ */
/*
 *   Parser is the class that implements the main parsing procedure, namely
 *   taking a line of text from the player, figuring out what it means, and
 *   executing it.
 *   
 *   The conventional IF parsing loop simply consists of reading a line of
 *   text from the player, calling Parser.parse() on the string, and
 *   repeating.
 *   
 *   In most cases you'll just need a single Parser instance.  The Parser
 *   object keeps track of unfinished commands, such as when we need to ask
 *   for disambiguation help or for a missing object.  If for some reason
 *   you want to keep multiple sets of this kind of state (reading input
 *   from more than one player, for example), you can create as many Parser
 *   instances as needed.  
 */
class Parser: object
    /*
     *   Auto-Look: Should we treat an empty command line (i.e., the user
     *   just presses Return) as a LOOK AROUND command?
     *   
     *   The traditional handling since the Infocom era has always been to
     *   treat an empty command line as a parsing error, and display an
     *   error message along the lines of "I beg your pardon?".  Given that
     *   an empty command line has no conflicting meaning, though, we
     *   *could* assign it a meaning.
     *   
     *   But what meaning should that be?  A blank line is the simplest
     *   possible command for a player to enter, so it would make sense to
     *   define it as some very commonly used command.  It's also fairly
     *   easy to enter a blank line accidentally (which is partly why the
     *   traditional reply is an error message), so the command should be
     *   benign - it shouldn't be a problem to enter it unintentionally.
     *   It can't be anything with parallel verbs, like NORTH, since then
     *   there'd be no good reason to pick NORTH instead of, say, SOUTH.
     *   Finally, it has to be intransitive, since it obviously won't
     *   involve an object name.  The obvious candidates that fit all of
     *   these criteria are LOOK and INVENTORY.  LOOK is probably the more
     *   useful and the more frequently used of the two, so it's the one we
     *   choose by default.
     *   
     *   If this property is set to true, we'll perform a LOOK AROUND
     *   command when the player enters a blank command line.  If nil,
     *   we'll show an error message.  
     */
    autoLook = true

    /*
     *   Default Actions: Should we treat a command line that consists entirely
     *   of a single noun phrase to be a "Default Action" on the named object?
     *   The precise meaning of the default action varies by object.  For most
     *   objects, it's EXAMINE.  For locations, it's GO TO.
     *
     *   We make the default value nil since setting it to true can result in
     *   some rather odd parser behaviour.
     */
    
    defaultActions = true

    /*
     *   Should we attempt automatic spelling correction?  If this is true,
     *   whenever a command fails, we'll check for a word that we don't
     *   recognize; if we find one, we'll try applying spelling correction
     *   to see if we can come up with a working command.
     *   
     *   Our spelling correction algorithm is designed to be quite
     *   conservative.  In particular, we generally limit candidates for
     *   "correct" words to the vocabulary for objects that are actually in
     *   scope, which avoids revealing the existence of objects that
     *   haven't been seen yet; and we only apply a correction when it
     *   yields a command that parses and resolves correctly.  When we
     *   can't correct a command and get something resolvable, we don't
     *   even mention that we tried.  This avoids the bizarre, random
     *   guesses at "corrections" that often show up in other applications,
     *   and more importantly avoids giving away information that the
     *   player shouldn't know yet.
     *   
     *   We set this to true by default, in an attempt to reduce the
     *   player's typing workload by automatically correcting simple typos
     *   when possible.  If for some reason the spelling corrector is
     *   problematic in a particular game, you can disable it by setting
     *   this property to nil.  
     */
    autoSpell = true

    /*
     *   Maximum spelling correction time, in milliseconds.  The spelling
     *   correction process is iterative, and each iteration involves a new
     *   parsing attempt.  On a fast machine this doesn't tend to be
     *   noticeable, but it's conceivable that a pathological case could
     *   involve a large number of attempts that could be noticeably slow
     *   on an older machine.  To avoid stalling the game while we
     *   overanalyze the spelling possibilities, we set an upper bound to
     *   the actual elapsed time for spelling correction.  Each time we
     *   consider a new correction candidate, we'll check the elapsed time,
     *   and abort the process if it exceeds this limit.  Note that this
     *   limit doesn't limit the parsing time itself - we'll never
     *   interrupt that mid-stream.  
     */
    spellTimeLimit = 250

    /*
     *   When the parser doesn't recognize a word, should it say so?  If
     *   this property is set to true, when parsing fails, we'll scan the
     *   command line for a word that's not in the dictionary and show a
     *   message such as "I don't know the word <foo>."  If this property
     *   is nil, the parser will instead simply say that it doesn't
     *   recognize the syntax, or that the object in question isn't
     *   present, without saying specifically which word wasn't recognized,
     *   or indeed even admitting that there was such a thing.
     *   
     *   There are two schools of thought on this, both concerned with
     *   optimizing the user experience.
     *   
     *   The first school holds that the parser's job is to be as helpful
     *   as possible.  First and foremost, that means we should understand
     *   the user's input as often as possible.  But when we can't, it
     *   means that we should be do our best to explain what we didn't
     *   understand, to help the user formulate a working command next
     *   time.  In the case of a word the parser doesn't recognize, we can
     *   be pretty sure that the unknown word is the reason we can't
     *   understand the input.  The best way to help the user correct the
     *   problem is to let them know exactly which word we didn't know,
     *   rather than make them guess at what we didn't understand.  This is
     *   the way the classic Infocom games worked, and it's the traditional
     *   TADS default as well.
     *   
     *   The second school holds that the user's overriding interest is
     *   maintaining suspension of disbelief, and that the parser should do
     *   its best not to interfere with that.  A major aspect of this in IF
     *   the illusion that the game world is as boundless as the real
     *   world.  Missing dictionary words tend to break this illusion: if
     *   the user types EXAMINE ZEBRA, and the parser replies that it
     *   doesn't know the word "zebra", we've suddenly exposed a limit of
     *   the game world.  If we instead play coy and simply say that
     *   there's no zebra currently present, we allow the player to imagine
     *   that a zebra might yet turn up.  This is the way Inform games
     *   typically work.
     *   
     *   Each approach has its advantages and disadvantages, adherents and
     *   detractors, and it seems that neither one is objectively "right".
     *   It comes down to taste.  But there seems to be a clear preference
     *   among the majority of players in the modern era for the second
     *   approach.  The key factor is probably that typical IF commands are
     *   so short that it's easy enough to spot a typo without help from
     *   the parser, so the clarity benefits of "unknown word" messages
     *   seem considerably outweighed by the harm they do to the illusion
     *   of boundlessness.  So, our default is the second option, playing
     *   coy.  
     */
    showUnknownWords = nil

    /*
     *   Parse and execute a command line.  This is the main parsing
     *   routine.  We take the text of a command line, parse it against the
     *   grammar defined in the language module, resolve the noun phrases
     *   to game-world objects, and execute the action.  If the command
     *   line has more than one verb phrase, we repeat the process for each
     *   one.
     *   
     *   'str' is the text of the command line, as entered by the player.
     */
    parse(str)
    {
        /* tokenize the input */
        local toks;
        try
        {
            /* run the command tokenizer over the input string */
            toks = cmdTokenizer.tokenize(str);
            
            /* Dispose of any unwanted terminal punctuation */
            while(toks.length > 0 && getTokType(toks[toks.length]) == tokPunct)
                toks = toks.removeElementAt(toks.length);
            
        }
        catch (TokErrorNoMatch err)
        {
            /* 
             *   The tokenizer found a character (usually a punctuation
             *   mark) that doesn't fit any of the token rules.  
             */
            DMsg(token error, 'I don\'t understand the punctuation {1}',
                 err.curChar_);

           
            
            
            /* give up on the parse */
            return;
        }

        /* 
         *   Assume initially that the actor is the player character, but only
         *   if we don't have a question, since if the player is replying to a
         *   question the actor may already have been resolved.
         */
        if(question == nil)
            gActor = gPlayerChar;        
        
        /* no spelling corrections have been attempted yet */
        local history = new transient SpellingHistory(self);

        /* we're starting with the first command in the string */
        local firstCmd = true;

        /* parse the tokens */
        try
        {
            /* if there are no tokens, simply perform the empty command */
            if (toks.length() == 0)
            {
                /* 
                 *   this counts as a new command, so forget any previous
                 *   question or typo information 
                 */
                question = nil;
                lastTokens = nil;

                /* process an empty command */
                emptyCommand();

                /* we're done */
                return;
            }

            /* check for an OOPS command */
            local lst = oopsCommand.parseTokens(toks, cmdDict);
            if (lst.length() != 0)
            {
                /* this only works if we have an error to correct */
                local ui;
                if (lastTokens == nil
                    || (ui = spellingCorrector.findUnknownWord(lastTokens))
                        == nil)
                {
                    /* OOPS isn't available - throw an error */
                    throw new CantOopsError();
                }

                /* apply the correction, and proceed to parse the result */
                toks = OopsProduction.applyCorrection(lst[1], lastTokens, ui);
            }

            /*   
             *   Parse each predicate in the command line, until we run out
             *   of tokens.  The beginning of a whole new command line is
             *   definitely the beginning of a sentence, so start parsing
             *   with firstCommandPhrase.  
             */
            for (local root = firstCommandPhrase ; toks.length() != 0 ; )
            {
                /* we don't have a parse list yet */
                local cmdLst = nil;

                /* 
                 *   we haven't found a resolution error in a non-command
                 *   parsing yet 
                 */
                local qErr = nil, defErr = nil;

                /* 
                 *   If we have an outstanding question, and it takes
                 *   priority over interpreting input as a new command, try
                 *   parsing the input against the question.  Only do this
                 *   on the first command on the line - a question answer
                 *   has to be the entire input, so if we've already parsed
                 *   earlier commands on the same line, this definitely
                 *   isn't an answer to a past question.  
                 */
                if (firstCmd && question != nil && question.priority)
                {
                    /* try parsing against the Question */
                    local l = question.parseAnswer(toks, cmdDict);

                    /* if it parsed and resolved, this is our command */
                    if (l != nil && l.cmd != nil)
                        cmdLst = l;

                    /* if it parsed but didn't resolved, note the error */
                    if (l != nil)
                        qErr = l.getResErr();
                }

                /* 
                 *   if the question didn't grab it, try parsing as a whole
                 *   new command against the ordinary command grammar
                 */
                if (cmdLst == nil || cmdLst.cmd == nil)
                {
                    cmdLst = new CommandList(
                        root, toks, cmdDict, { p: new Command(p) });
                }

                /* 
                 *   If we didn't find any resolvable commands, and this is
                 *   the first command, check to see if it's an answer to
                 *   an outstanding query.  We only check this if the
                 *   regular grammar parsing fails, because anything that
                 *   looks like a valid new command overrides a past query.
                 *   This is important because some of the short, common
                 *   commands sometimes can look like noun phrases, so we
                 *   explicitly give preference to interpreting these as
                 *   brand new commands.  
                 */
                if (cmdLst.cmd == nil
                    && firstCmd
                    && question != nil
                    && !question.priority)
                {
                    /* try parsing against the Question */
                    local l = question.parseAnswer(toks, cmdDict);

                    /* if it parsed and resolved, this is our command */
                    if (l != nil && l.cmd != nil)
                        cmdLst = l;

                    /* if it parsed but didn't resolved, note the error */
                    if (l != nil)
                        qErr = l.getResErr();
                }

                /*
                 *   If we don't have a command yet, and this is the first
                 *   command on the line, handle it as a conversational command
                 *   if conversation is in progress; otherwise if default
                 *   actions are enabled, check to see if the command looks like
                 *   a single noun phrase.  If so, handle it as the default
                 *   action on the noun.
                 */
                if (cmdLst.cmd == nil
                    && firstCmd)
                {
                    local l;                   
                    
                    
                    /* 
                     *   If a conversation is in progress parse the command line
                     *   as the single topic object phrase of a Say command,
                     *   provided that the first word on the command line
                     *   doesn't match a possible action.
                     */
                    
                    if(gPlayerChar.currentInterlocutor != nil
                       && cmdLst.length == 0 
                       && Q.canTalkTo(gPlayerChar,
                                       gPlayerChar.currentInterlocutor)
                       && str.find(',') == nil)
                    {
                         l = new CommandList(
                            topicPhrase, toks, cmdDict,
                            { p: new Command(SayAction, p) });
                        
                        libGlobal.lastCommandForUndo = str;
                        savepoint();
                    }
                    /* 
                     *   If the player char is not in conversation with anyone,
                     *   or the first word of the command matches a possible
                     *   command verb, then try parsing the command line as a
                     *   single direct object phrase for the DefaultAction verb,
                     *   provided defaultActions are enabled (which they aren't
                     *   by default).
                     */
                    else if(defaultActions)                                                
                        l = new CommandList(
                            defaultCommandPhrase, toks, cmdDict,
                            { p: new Command(p) });                       
                    
                    
                       
                    /* accept a curable reply */
                    if (l != nil && l.acceptCurable() != nil)
                    {
                        cmdLst = l;
                        
                        /* note any resolution error */
                        defErr = l.getResErr();
                    }
                }
                
                /*
                 *   If we've applied a spelling correction, and the
                 *   command match didn't consume the entire input, make
                 *   sure what's left of the input has a valid parsing as
                 *   another command.  This ensures that we don't get a
                 *   false positive by excessively shortening a command,
                 *   which we can sometimes do by substituting a word like
                 *   "then" for another word.  
                 */
                if (cmdLst.length() != nil
                    && history.hasCorrections())
                {
                    /* get the best available parsing */
                    local c = cmdLst.getBestCmd();

                    /* if it doesn't use all the tokens, check what's left */
                    if (c != nil && c.tokenLen < toks.length())
                    {
                        /* try parsing the next command */
                        local l = commandPhrase.parseTokens(
                            c.nextTokens, cmdDict);

                        /* 
                         *   if that didn't work, invalidate the command by
                         *   substituting an empty command list 
                         */
                        if (l.length() == 0)
                            cmdLst = new CommandList();
                    }
                }
                
                /* 
                 *   If we didn't find a parsing at all, it's a generic "I
                 *   don't understand" error.  If we found a parsing, but
                 *   not a resolution, reject it if it's a spelling
                 *   correction.  We only want completely clean spelling
                 *   corrections, without any errors.
                 */
                if (cmdLst.length() == 0
                    || (history.hasCorrections()
                        && cmdLst.getResErr() != nil
                        && !cmdLst.getResErr().allowOnRespell))
                {
                    /* 
                     *   If we were able to parse the input using one of
                     *   the non-command interpretations, use the
                     *   resolution error from that parsing.  Otherwise, we
                     *   simply can't make any sense of this input, so use
                     *   the generic "I don't understand" error. 
                     */
                    local err = (qErr != nil ? qErr :
                                 defErr != nil ? defErr :
                                 new NotUnderstoodError());
                    
                    /* look for a spelling correction */
                    local newToks = history.checkSpelling(toks, err);
                    if (newToks != nil)
                    {
                        /* parse again with the new tokens */
                        toks = newToks;
                        continue;
                    }

                    /* 
                     *   There's no spelling correction available.  If we've 
                     *   settled on an auto-examine or question error, skip 
                     *   that and go back to "I don't understand" after 
                     *   all.  We don't want to assume Auto-Examine unless we
                     *   actually have something to examine, since we can 
                     *   parse noun phrase grammar out of practically any 
                     *   input.  
                     */
                    if (err is in (defErr, qErr))
                    {
                        /* return to the not-understood error */
                        err = new NotUnderstoodError();
                        
                        /* check spelling again with this error */
                        newToks = history.checkSpelling(toks, err);
                        if (newToks != nil)
                        {
                            /* parse again with the new tokens */
                            toks = newToks;
                            continue;
                        }
                    
                        
                        /* 
                         *   We didn't find any spelling corrections this time
                         *   through.  Since we're rolling back to the
                         *   not-understood error, discard any spelling
                         *   corrections we attempted with other
                         *   interpretations.
                         */
                        history.clear();                   
                    }
                
                    /* fail with the error */
                    throw err;
                }

                /* if we found a resolvable command, execute it */
                if (cmdLst.cmd != nil)
                {
                    /* get the winning Command */
                    local cmd = cmdLst.cmd;
                    
                    /* 
                     *   We next have to ensure that the player hasn't entered
                     *   multiple nouns in a slot that only allows a single noun
                     *   in the grammar. If the player has entered two objects
                     *   like "the bat and the ball" in such a case, the
                     *   badMulti flag will be set on the command object, so we
                     *   first test for that and abort the command with a
                     *   suitable error message if badMulti is not nil (by
                     *   throwing a BadMultiError
                     *
                     *   Unfortunately the badMulti flag doesn't get set if the
                     *   player enters a multiple object as a plural (e.g.
                     *   "bats"), so we need to trap this case too. We do that
                     *   by checking whether there's multiple objects in the
                     *   direct, indirect and accessory object slots at the same
                     *   time as the grammar tag matching the slot in question
                     *   is 'normal', which it is only for a single noun match.
                     */
                     
                    if(cmd && cmd.verbProd != nil &&                        
                        (cmd.badMulti != nil 
                       || (cmd.verbProd.dobjMatch != nil &&
                           cmd.verbProd.dobjMatch.grammarTag == 'normal'
                           && cmd.dobjs.length > 1)
                       ||
                       (cmd.verbProd.iobjMatch != nil &&
                           cmd.verbProd.iobjMatch.grammarTag == 'normal'
                           && cmd.iobjs.length > 1)                          
                        ||
                       (cmd.verbProd.accMatch != nil &&
                           cmd.verbProd.accMatch.grammarTag == 'normal'
                           && cmd.accs.length > 1)
                           ))
                        cmd.cmdErr = new BadMultiError(cmd.np);
                    
                    /* if this command has a pending error, throw it */
                    if (cmd.cmdErr != nil)
                        throw cmd.cmdErr;

                    /* 
                     *   Forget any past question and typo information.
                     *   The new command is either an answer to this
                     *   question, or it's simply ignoring the question; in
                     *   either case, the question is no longer in play for
                     *   future input.  
                     */
                    question = nil;
                    lastTokens = nil;
                    
                    /* note any spelling changes */
                    history.noteSpelling(toks);
                    
                    /* execute the command */
                    cmd.exec();
                    
                    /* start over with a new spelling correction history */
                    history = new transient SpellingHistory(self);
                    
                    /* 
                     *   Set the root grammar production for the next
                     *   predicate.  If the previous command ended the
                     *   sentence, start a new sentence; otherwise, use the
                     *   additional clause syntax. 
                     */
                    root = cmd.endOfSentence
                        ? firstCommandPhrase : commandPhrase;
                    
                    /* we're no longer on the first command in the string */
                    firstCmd = nil;
                    
                    /* go back and parse the remainder of the command line */
                    toks = cmd.nextTokens;
                    continue;
                }

                /*
                 *   We weren't able to resolve any of the parse trees.  If
                 *   one of the errors is "curable", meaning that the
                 *   player can fix it by answering a question, pick the
                 *   first of those, in predicate priority order.
                 *   Otherwise, just pick the first command overall in
                 *   predicate priority order.  In either case, since we
                 *   didn't find any working alternatives, it's time to
                 *   actually show the error and fail the command.  
                 */
                local c = cmdLst.acceptAny();

                /* 
                 *   If the error isn't curable, check for spelling errors,
                 *   time permitting.  Don't bother doing this with a
                 *   curable error, since that will have its own way of
                 *   solving the problem that reflects a better
                 *   understanding of the input than considering it a
                 *   simple typo.  
                 */
                if (!c.cmdErr.curable)
                {
                    /*
                     *   For spelling correction purposes, if this is an
                     *   unmatched noun error, but the command has a misc
                     *   word list and an empty noun phrase, treat this as
                     *   a "not understood" error.  The combination of noun
                     *   phrase errors suggests that we took a word that
                     *   was meant to be part of the verb, and incorrectly
                     *   parsed it as part of a noun phrase, leaving the
                     *   verb structure and other noun phrase incomplete.
                     *   This is really a verb syntax error, not a noun
                     *   phrase error.  
                     */
                    local spellErr = c.cmdErr;
                    if (c.cmdErr.ofKind(UnmatchedNounError)
                        && c.miscWordLists.length() > 0
                        && c.missingNouns > 0)
                        spellErr = new NotUnderstoodError();

                    /* try spelling correction */
                    local newToks = history.checkSpelling(toks, spellErr);

                    /* if that worked, try the corrected command */
                    if (newToks != nil)
                    {
                        /* parse again with the new tokens */
                        toks = newToks;
                        continue;
                    }
                }

                /* re-throw the error that caused the resolution to fail */
                throw c.cmdErr;
            }
        }
        catch (ParseError err)
        {
            /* 
             *   roll back any spelling changes to the last one that
             *   improved matters 
             */
            local h = history.rollback(toks, err);
            toks = h.oldToks;
            err = h.parseError;

            /* 
             *   if this is a curable error, it poses a question, which the
             *   player can answer on the next input 
             */
            if (err.curable)
                question = new ParseErrorQuestion(err);
            
            /* 
             *   If the current error isn't curable, and unknown word
             *   disclosure is enabled, and there's a word in the command
             *   that's not in the dictionary, replace the parsing error
             *   with an unknown word error.  
             */
            local ui;
            if (!err.curable
                && showUnknownWords
                && (ui = spellingCorrector.findUnknownWord(toks)) != nil)
            {
                /* find the misspelled word in the original tokens */
                err = new UnknownWordError(getTokOrig(toks[ui]));
            }
            
            /* 
             *   If the new error isn't an error in an OOPS command, save
             *   the token list for an OOPS command next time out. 
             */
            if (!err.ofKind(OopsError))
                lastTokens = toks;
            
            /* log any spelling changes we kept */
            history.noteSpelling(toks);

            /* display the error we finally decided upon */
            err.display();
        }
        catch (CommandSignal sig)
        {
            /* 
             *   On any command signal we haven't caught so far, simply
             *   stop processing this command line.  
             */
        }
    }

    /*
     *   The token list from the last command, if an error occurred.  This
     *   is the token list that we'll retry if the player enters an OOPS
     *   command.  
     */
    lastTokens = nil

    /*
     *   The outstanding Question object.  When we ask an interactive
     *   question (such as a disambiguation query, a missing noun phrase
     *   query, or a custom question from the game), this is set to the
     *   Question waiting to be answered.  We parse the next command
     *   against the Question to see if it's a reply, and if so we execute
     *   the reply.  
     */
    question = nil

    /*
     *   Execute an empty command line.  The parse() routine calls this
     *   when given a blank command line (i.e., the user simply pressed the
     *   Return key).  By default, we execute a Look Around command if
     *   autoLook is enabled, otherwise we show the "I beg your pardon"
     *   error.
     */
    emptyCommand()
    {
        if (autoLook)
            new Command(Look).exec();
        else
        {
            /* 
             *   The player entered an empty command line (i.e., pressed
             *   Return at the command prompt, without typing anything else
             *   first).  Note that this error can only occur if Auto-Look
             *   is disabled, since otherwise an empty command implicitly
             *   means LOOK AROUND.  
             */
            DMsg(empty command line, 'I beg your pardon?');

        }
    }
    
    /* 
     *   The action to be tried if the parser can't find a verb in the command
     *   line and tries to parse the command line as the single object of a
     *   DefaultAction command instead.
     */
    
    DefaultAction = ExamineOrGoTo
    
    /*  Return an rmcXXXX enum code depending on the state of Parser.question */
    rmcType()
    {
        if(Parser.question != nil && Parser.question.err != nil)
        {
            /* 
             *   If the Parser error is an EmptyNounError then we're asking for
             *   an object.
             */
            if(Parser.question.err.ofKind(EmptyNounError))
                return rmcAskObject;
            
            /* 
             *   If the Parser error is an AmbiguousError then we're requesting
             *   disambiguation.
             */
            if(Parser.question.err.ofKind(AmbiguousError))
                return rmcDisambig;            
        }
        
        /* 
         *   If there's no special situation, assume we're reading a standard
         *   command.
         */
        return rmcCommand;
    }
;

/* ------------------------------------------------------------------------ */
/*
 *   Base class for command execution signals.  These allow execution
 *   handlers to terminate execution for the current command line or
 *   portion of the command line.  
 */
class CommandSignal: Exception
;


/* 
 *   Terminate the entire command line.
 */
class ExitCommandLineSignal: CommandSignal
;
    

/* ------------------------------------------------------------------------ */
/*
 *   A CommandList is a set of potential parsings for a given input with a
 *   given grammar.  
 */
class CommandList: object
    /*
     *   new CommandList(prod, toks, dict, wrapper) - construct a new
     *   CommandList object by parsing an input token list.  'prod' is the
     *   GrammarProd to parse against; 'toks' is the token list; 'dict' is
     *   the main parser dictionary; 'wrapper' is a callback function that
     *   maps a parse tree to a Command object.
     *   
     *   new CommandList(Command) - construct a CommandList containing a
     *   single pre-resolved Command object.  
     */
    construct([args])
    {
        /* check which argument list we have */
        if (args.matchProto([GrammarProd, Collection, Dictionary, TypeFuncPtr]))
        {
            /* retrieve the arguments */
            local prod = args[1], toks = args[2], dict = args[3],
                wrapper = args[4];

            /* parse the token list, and map the list to Command objects  */
            cmdLst = prod.parseTokens(toks, dict).mapAll(wrapper);
            
            /* sort in priority order */
            cmdLst = Command.sortList(cmdLst);
            
            /* 
             *   Go through the list, looking for an item with noun phrases we
             *   can resolve.  Take the first item that we can properly
             *   resolve.  
             */
            foreach (local c in cmdLst)
            {
                try
                {
                    /* resolve this phrase */
                    c.resolveNouns();
                    
                    /* success - take this as the result; look no further */
                    /* 
                     *   But only if we haven't yet got a command or the new
                     *   command didn't have to create a new Topic object.
                     */
                    if(cmd == nil || !c.madeTopic)
                        cmd = c;
                    
                    /* 
                     *   But if this command had to create a new Topic object,
                     *   let's go on to see if we can find a better match.
                     */
                    if(!cmd.madeTopic)
                       break;
                }
                catch(InsufficientNounsError err)
                {
                    c.cmdErr = err;
                    throw err;
                }
                catch(NoneInOwnerError err)
                {
                    c.cmdErr = err;
                    throw err;
                }
                
                catch (ParseError err)
                {
                    /* save the error with the command */
                    c.cmdErr = err;
                    
                    /* 
                     *   That didn't resolve correctly.  But don't actually
                     *   show the error message yet; instead, continue through
                     *   the list to see if we can find another alternative
                     *   that we can resolve.
                     *   
                     *   If it's the first curable error we've seen, note it. 
                     */
                    if (err.curable && curable == nil)
                        curable = c;
                }
            }
        }
        else if (args.matchProto([Command]))
        {
            /* get the command - it's the single list entry */
            cmd = args[1];
            cmdLst = [cmd];
        }
        else if (args.matchProto([]))
        {
            /* empty command list */
            cmd = nil;
            cmdLst = [];
        }
        else
            throw new ArgumentMismatchError();
    }

    /* number of parsings in the list */
    length() { return cmdLst.length(); }

    /*
     *   Accept a curable resolution as the actual resolution.  If we don't
     *   have an error-free resolution, we'll set 'cmd' to the curable
     *   resolution.  Returns true if we have any resolution, nil if not.  
     */
    acceptCurable()
    {
        /* if we don't have an error-free resolution, accept a curable one */
        if (cmd == nil)
            cmd = curable;

        /* indicate whether we have a resolution now */
        return cmd;
    }

    /*
     *   Accept ANY command, with or without a resolution error, curable or
     *   not.  We'll take the error-free resolution if we have one,
     *   otherwise the resolution with a curable error, otherwise just the
     *   first parsing in priority order. 
     */
    acceptAny()
    {
        /* accept the best command, and return it */
        return cmd = getBestCmd();
    }

    /*
     *   Get the most promising command from the available parsings.  This
     *   returns the first successfully resolved command in priority order,
     *   if any; otherwise the first command with a curable error, if any;
     *   otherwise the first command in priority order.  
     */
    getBestCmd()
    {
        /* if we have a parsed and resolved command, return it */
        if (cmd != nil)
            return cmd;

        /* if we have a curable command, return it */
        if (curable != nil)
            return curable;

        /* if we have any parsing at all, return the first one */
        if (cmdLst.length() > 0)
            return cmdLst[1];

        /* we don't have any parsing */
        return nil;
    }

    /*
     *   Get the resolution error, if any.  If we parsed but didn't
     *   resolve, this returns the error from the first parsing in priority
     *   order.  
     */
    getResErr()
    {
        /* if we resolved a command, return any error from it */
        if (cmd != nil)
            return cmd.cmdErr;

        /* if we have a curable error, return it */
        if (curable != nil)
            return curable.cmdErr;

        /* otherwise, return the first item with a cmdErr */
        local c = cmdLst.valWhich({ c: c.cmdErr != nil });
        return (c != nil ? c.cmdErr : nil);
    }

    /* our list of Command objects */
    cmdLst = []

    /* 
     *   Our resolved Command.  This is the first parsing in our list that
     *   (in priority order) we were able to resolve with no errors.  
     */
    cmd = nil

    /* 
     *   Our semi-resolved Command.  When we can't find a command that
     *   resolves without errors, we'll set this to the first one (in
     *   priority order) that resolves with a curable error.  
     */
    curable = nil
;


/* ------------------------------------------------------------------------ */
/*
 *   A Question is an interactive question we ask the player via the
 *   regular command line.  The player then has the option to answer the
 *   question, or to ignore the question and enter a new command.
 *   
 *   The parser uses Question objects internally to handle certain errors
 *   that the player can fix by entering additional information, such as
 *   disambiguation queries and missing noun phrase queries.  Games can use
 *   Question objects for other, custom interactions.
 *   
 *   The basic Question object is incomplete - you have to subclass it to
 *   get a functional question handler.  In particular, you must provide a
 *   parseAnswer() routine that parses the reply and creates a Command to
 *   carry out the action of answering the question.  
 */
class Question: object
    /*
     *   Priority: Should the answer be parsed before checking for a
     *   regular command entry?  If this is true, the parser will try
     *   parsing the player's input as an answer to this question BEFORE it
     *   tries parsing the input as a regular command.  If the answer
     *   parses, we'll assume it really is an answer to the question, and
     *   we won't even try parsing it as a new command.
     *   
     *   For disambiguation and missing noun queries, the parser only
     *   parses question replies AFTER parsing regular commands.  Replies
     *   to these questions are frequently very short, abbreviated noun
     *   phrases - maybe just a single adjective or noun.  It's fairly
     *   common for there be at least a few nouns that are the same as
     *   verbs in the game, so the input after a disambiguation or missing
     *   noun reply can often be interpreted equally well as a new verb or
     *   as a reply to the question.  There's probably no theoretical basis
     *   for choosing one over the other when this happens, but in practice
     *   it seems that it's usually better to treat the reply as a new
     *   command.  So, by default we set this property to nil, to give
     *   priority to a new command.
     *   
     *   Custom questions posed by the game might want to give higher
     *   priority to the answer interpretation, though.  Yes/No questions
     *   in particular will probably want to do this, because otherwise the
     *   parser would take the answer as a conversational overture to any
     *   nearby NPC.  
     */
    priority = nil
    
    /*
     *   Parse the answer.  'toks' is the token list of the user's input,
     *   and 'dict' is the main parser Dictionary object.
     *   
     *   If the input does look like a valid answer to the question,
     *   returns a CommandList with the parsed reply.  If not, returns nil,
     *   in which case the parser will continue trying to parse the input
     *   as a whole new command.
     *   
     *   By default, we simply return nil.  Subclasses/instances must
     *   override this to provide the custom answer parsing.  
     */
    parseAnswer(toks, dict) { return nil; }

    /* the answer template */
    answerTemplate = nil
;

/*
 *   A GramQuestion is a question handler that parses an answer using a
 *   grammar rule.
 */
class GramQuestion: Question
    /*
     *   Create a simple question.  'prod' is the root GrammarProd to use
     *   for parsing the reply.  'func' is a callback function that carries
     *   out the action of the answering the question.  'func' is invoked
     *   with a single argument giving the Command object representing the
     *   answer; you can get the match tree from the Command if you need
     *   the parsed form of the answer input.  
     */
    construct(prod, func)
    {
        answerProd = prod;
        answerFunc = func;
    }

    /*
     *   Parse the answer.  We'll match the token list against the grammar
     *   rule.  If we find a match, we'll call makeCommand() to create the
     *   command to carry out the action of answering the question.  
     */
    parseAnswer(toks, dict)
    {
        /* try parsing against our grammar rule */
        return new CommandList(
            answerProd, toks, dict, { p: makeCommand(p) });
    }

    /*
     *   Create a Command object for a successful grammar match.  'prod' is
     *   the root match object of the grammar match.  This returns a
     *   suitable Command that carries out the action of answering the
     *   question.  
     */
    makeCommand(prod) { return new FuncCommand(prod, answerFunc); }

    /* the GrammarProd rule that we use to parse the answer */
    answerProd = nil

    /* the callback function that carries out the reply action */
    answerFunc = nil
;

/*
 *   A YesNoQuestion is a simple subclass of Question for asking
 *   interactive questions with Yes or No answers. 
 */
class YesNoQuestion: GramQuestion
    /*
     *   Create - 'func' is the callback function to invoke on answering
     *   the question.  This is invoked with one argument, true if the
     *   answer was Yes, nil if the answer was No.  
     */
    construct(func)
    {
        /* 
         *   Parse our answer against the simple yes-or-no grammar.  To
         *   execute the answer, call the user's callback, providing the
         *   yes/no result from the Command.  The yes-or-no production sets
         *   the yesOrNoAnswer property in the Command during the build
         *   process.  
         */
        inherited(yesOrNoPhrase, { cmd: func(cmd.yesOrNoAnswer) });
    }

    /* 
     *   parse Yes/No replies ahead of new commands, since we'd otherwise
     *   never get an answer - the parser would always match the reply to a
     *   conversational verb instead 
     */
    priority = true
;

/*
 *   A RexQuestion is a simple subclass of Question for parsing answers
 *   with regular expressions. 
 */
class RexQuestion: Question
    /*
     *   Create - 'pat' is the regular expression pattern, as either a
     *   string or a RexPattern object.  We'll parse an answer simply by
     *   matching it against the regular expression; if we match, we'll
     *   take it as an answer.  'func' is a callback function that we'll
     *   call to carry out the action of answering the question.  We'll
     *   invoke this with one argument giving the literal text of the
     *   input.  
     */
    construct(pat, func)
    {
        answerPat = pat;
        answerFunc = func;
    }

    parseAnswer(toks, dict)
    {
        /* reconstruct the string input */
        local str = cmdTokenizer.buildOrigText(toks);

        /* check for a match to our pattern */
        if (rexMatch(answerPat, str,) != nil)
        {
            /* set up a single-entry command list for the answer */
            return new CommandList(new FuncCommand(
                nil, { cmd: answerFunc(str) }));
        }
        else
        {
            /* no match */
            return nil;
        }
    }

    /* the regular expression pattern to match */
    answerPat = nil

    /* the callback to invoke on answering */
    answerFunc = nil
;

/*
 *   An ErrorQuestion is a subclass of Question for curable parsing errors.
 */
class ParseErrorQuestion: Question
    construct(err)
    {
        /* remember the ParseError object */
        self.err = err;
    }

    parseAnswer(toks, dict)
    {
        /* ask the error to parse the response */
        return err.tryCuring(toks, dict);
    }

    /* the curable ParseError that posed the question */
    err = nil
;


/* ------------------------------------------------------------------------ */
/*
 *   A Distinguisher is an abstract parser object that represents one way
 *   that we can tell two objects apart, both in the name we display and in
 *   command input.
 *   
 *   Note that this class is designed primarily for the parser's internal
 *   use, to facilitate some bookkeeping that we have to do during
 *   disambiguation.  It's not really designed as an extensibility
 *   mechanism, because it's not usually enough to just add a new instance:
 *   you usually also have to add grammar for whatever new phrasing the new
 *   distinguisher represents, plus object resolution code to handle the
 *   new form of qualification.  
 */
class Distinguisher: object
    /* 
     *   Sorting order.  The parser sorts the master list of distinguishers
     *   in ascending order of this value to determine the order of
     *   application.  
     */
    sortOrder = 0

    /*
     *   Compare two objects for equivalence under this distinguisher.
     *   Returns true if the objects are equivalent, nil others. 
     */
    equal(a, b) { return nil; }

    /* 
     *   Is this distinguisher applicable to the given object?  Some
     *   distinguishers can only apply to certain objects.  For example, a
     *   Lit/Unlit distinguisher can only be applied to objects with that
     *   state variable, because there's no vocabulary that we can add to
     *   an object without the variable.  (We can talk about "lit" and
     *   "unlit" matches, but we don't have any standard vocabulary to talk
     *   about "unlightable" matches.)  
     */
    appliesTo(obj) { return true; }

    /*
     *   Apply the distinguisher.  Returns a DistResult object with the
     *   results.  
     */
    apply(lst)
    {
        /* create the results object */
        local r = new DistResult(self);

        /* set up the list of applicable objects */
        r.appliesTo = lst.subset({ obj: appliesTo(obj) });

        /* make a to-do vector, starting with all applicable items */
        local toDo = new Vector(10, r.appliesTo);

        /* process each item in the to-do list */
        while (toDo.length() > 0)
        {
            /* pop the last item */
            local obj = toDo.pop();

            /* start a partition list for this item and its equivalents */
            local sv = new Vector(10);

            /* start the partition with the current object */
            sv.append(obj);

            /* add the new partition to the partition list */
            r.partitioned.append(sv);

            /* scan the to-do list for items equivalent to obj */
            for (local i = toDo.length() ; i > 0 ; --i)
            {
                /* get this item and check for equivalence to obj */
                local obj2 = toDo[i];
                if (equal(obj, obj2))
                {
                    /* it's equivalent to obj, so add it to obj's partition */
                    sv.append(obj2);

                    /* it's been processed; remove it from the to-do list */
                    toDo.removeElementAt(i);
                }
            }
        }

        /* return the result object */
        return r;
    }

    /* class property: master list of all distinguishers */
    all = []

    /* during initialization, build the master list */
    classInit()
    {
        /* add each instance to the master list */
        forEachInstance(Distinguisher, {d: all += d});

        /* arrange by sortOrder */
        all = all.sort(SortAsc, {a, b: a.sortOrder - b.sortOrder});
    }

    /* make sure the StateDistinguisher instances are constructed first */
    classInitFirst = [StateDistinguisher]

    /*
     *   Class method: generate distinguishing names for a list of objects.
     *   This generates names that distinguish the objects from one
     *   another, by applying as many Distinguishers as needed to come up
     *   with unique names.
     *   
     *   If 'article' is true, we'll use a definite or indefinite article,
     *   as appropriate: definite if the name we settle upon uniquely
     *   identifies the object within the list, indefinite if not.  If
     *   'article' is nil, the names don't have articles at all.
     *   
     *   Returns a list of [name, [objects]] sublists.  The name is a
     *   string giving the distinguished name; the [objects] sub-sublist is
     *   a list of the objects known under that name.  
     */
    getNames(objs, article)
    {
        /* start with an empty result list */
        local names = new Vector(objs.length());

        /* start with an empty list of distinguisher results */
        local dres = new Vector(Distinguisher.all.length());

        /* apply each distinguisher to our objects, saving the results */
        foreach (local d in Distinguisher.all)
            dres.append(d.apply(objs));

        /* find the distinguishing characteristics for each object */
        while (objs.length() != 0)
        {
            /* treat the to-do list as a stack: pop an object */
            local obj = objs.pop();

            /* get the subset of dist results that apply to this object */
            local ores = dres.subset({ r: r.appliesTo.indexOf(obj) != nil });

            /*
             *   What we're after is the minimum set of distinguishers that
             *   can tell this object apart from as many of the others as
             *   possible.
             *   
             *   In the best case, there's a single distinguisher that can
             *   pick out this object uniquely.  For example, if this is
             *   the lit match, and all the other matches are unlit, the
             *   Lit/Unlit State distinguisher is all we need: 'lit'
             *   uniquely identifies this object among our set.  If that's
             *   the case, obj will appear in the Lit/Unlit list in its own
             *   partition, with no other objects.
             *   
             *   It might be that there's no one distinguisher that can
             *   tell obj apart from all of the others.  But perhaps a
             *   combination of two distinguishers can: perhaps obj is one
             *   of two lit matches, and one of two matches belonging to
             *   Bob, but it's the only lit match belonging to Bob.  We'd
             *   thus find obj in two partitions of two objects each;
             *   intersecting the two will yield a list with just one
             *   element, so we'd get down to a unique object again.
             *   
             *   We might not ever get down to a single-object partition,
             *   even after combining several distinguishers, since we
             *   might be truly indistinguishable from one or more other
             *   objects.  In such a case, we'll have to group the objects
             *   and ask if the player means "*a* lit match of Bob's", say.
             *   
             *   In any case, our fastest route to the smallest set is to
             *   start with the smallest set, and intersect against larger
             *   sets until we get down to one object or run out of other
             *   sets to intersect.  So start by sorting the results by the
             *   size of the partition in which obj appears, smallest to
             *   largest.  
             */
            ores.sort(SortAsc, new function(a, b)
            {
                /* sort by partition size */
                local asiz = a.partSize(obj);
                local bsiz = b.partSize(obj);

                /* if they differ, sort according to the relative sizes */
                if (asiz != bsiz)
                    return asiz - bsiz;

                /* same size partitions; sort by Distinguisher order */
                return a.distinguisher.sortOrder - b.distinguisher.sortOrder;
            });

            /* we haven't used any distinguishers yet */
            local used = new Vector(10);

            /* 
             *   Start with the first distinguisher in the list, and its
             *   initial set.  Note that we're guaranteed to have at least
             *   one result in the list, since the basic name distinguisher
             *   applies to everything.  
             */
            used.append(ores[1].distinguisher);
            local rem = ores[1].partition(obj).toList();

            /* 
             *   now apply additional distinguishers until we get the set
             *   down to one object, or run out of distinguishers 
             */
            for (local i = 2, local olen = ores.length() ;
                 rem.length() > 1 && i <= olen ; ++i)
            {
                /* 
                 *   figure the intersection of this distinguisher
                 *   partition with the remaining set 
                 */
                local rcur = ores[i];
                local isect = rem.intersect(rcur.partition(obj).toList());

                /* 
                 *   If that reduced the set size, keep the result.  Ignore
                 *   distinguishers that don't reduce the set size, because
                 *   they don't help - they'd just add words to the
                 *   generated name without helping to tell things apart.  
                 */
                if (isect.length() < rem.length())
                {
                    /* keep the reduced list */
                    rem = isect;

                    /* note that we used this distinguisher */
                    used.append(rcur.distinguisher);
                }
            }

            /* 
             *   We've thrown out as many distinguishable items as
             *   possible, and in the process we've built a list of the
             *   distinguishing characteristics that we needed in order to
             *   tell this object apart from the others.  Generate the
             *   name, based on that list of characteristics.  If we
             *   whittled the set size down to a single object, use a
             *   definite article; otherwise, we have a group of
             *   indistinguishable objects, so use an indefinite article to
             *   refer to an arbitrary one of these.  
             */
            local rlen = rem.length();
            local nm = obj.distinguishedName(
                article ? (rlen == 1 ? Definite : Indefinite) : Unqualified,
                used);

            /* 
             *   This name covers the whole group, so remove all of the of
             *   additional objects from the to-do list.  (We've already
             *   removed the first one, so don't waste time looking for it
             *   again.)  
             */
            for (local i = 2 ; i <= rlen ; ++i)
                objs.removeElement(rem[i]);

            /* append this name result */
            names.append([nm, rem]);
        }

        /* return the name list */
        return names;
    }
;

/*
 *   Result object from applying a Distinguisher to a set of objects. 
 */
class DistResult: object
    construct(dist)
    {
        /* remember the distinguisher */
        distinguisher = dist;

        /* set up a vector for the partition list */
        partitioned = new Vector(10);
    }

    /* get the partition in which 'obj' appears */
    partition(obj)
    {
        return partitioned.valWhich({ p: p.indexOf(obj) != nil });
    }

    /* get the size of the partition in which 'obj' appears */
    partSize(obj)
    {
        return partition(obj).length();
    }

    /* the objects that the distinguisher applies to */
    appliesTo = []

    /* 
     *   The partitioned list of objects.  This is a list of lists.  Each
     *   sublist is a group of objects we can't distinguish from one
     *   another.  Each object in appliesTo appears once in a sublist, and
     *   each object in a sublist appears in appliesTo.  
     */
    partitioned = []

    /* the Distinguisher that these results come from */
    distinguisher = nil
;

/*
 *   The basic name distinguisher distinguishes objects by their base names.
 *   This is the first distinguisher we apply, since the name is always the
 *   easiest way to tell objects apart in parsing. However since one name could
 *   be entirely contained within another (e.g. 'ball' and 'red ball') we
 *   consider the names as equal for this purpose if one of them is part of the
 *   other.
 */
nameDistinguisher: Distinguisher
    sortOrder = 100
    equal(a, b) { return a.name.find(b.name) || b.name.find(a.name); }
;

/*
 *   The disambiguation name distinguisher.  This distinguishes objects by
 *   their disambiguation names.  We apply this immediately after the basic
 *   name distinguisher, since the disambiguation name is a custom name
 *   provided by the author for the express purpose of distinguishing the
 *   object in parsing.  
 */
disambigNameDistinguisher: Distinguisher
    sortOrder = 200
    equal(a, b) { return a.disambigName == b.disambigName; }
;

/*
 *   The class for state distinguishers.  A state distinguisher tells
 *   objects apart based on their having distinct current values for a
 *   given state.  During preinit, we create a separate instance of this
 *   for each State object in the game.  
 */
class StateDistinguisher: Distinguisher
    sortOrder = 300

    /* we distinguish based on each object's current value for the state */
    equal(a, b) { return a.(state.stateProp) == b.(state.stateProp); }

    /* we only apply to objects that have our state variable */
    appliesTo(obj) { return state.appliesTo(obj); }
    
    /* build from a State */
    construct(st)
    {
        /* remember the state object */
        state = st;
    }

    /* during preinit, build an instance for each State */
    classInit()
    {
        forEachInstance(State, {st: stateList += new StateDistinguisher(st)});
    }

    /* the State this distinguisher tests */
    state = nil

    /* class property: the list of state distinguisher instances */
    stateList = []
;


/*
 *   Owner distinguisher.  This tells objects apart based on their nominal
 *   owners (and only applies to objects with nominal owners at all).  
 */
ownerDistinguisher: Distinguisher
    sortOrder = 400
    appliesto(obj) { return obj.nominalOwner() != nil; }
    equal(a, b) { return a.nominalOwner() == b.nominalOwner(); }
;

/*
 *   Location distinguisher.  This tells objects apart based on their
 *   immediate containers. 
 */
locationDistinguisher: Distinguisher
    sortOrder = 500
    equal(a, b) { return a.location == b.location; }
;

/*
 *   Contents distinguisher.  This tells objects apart based on their
 *   nominal contents (and only applies to objects with nominal contents at
 *   all).  Note that we're interested in the *names* of the contents, so
 *   even if two objects have different contents objects, they're still
 *   considered equal if the contents' names match.  (E.g., two "buckets of
 *   water" are indistinguishable, even if the contents are two distinct
 *   "water" objects.  But "bucket of water" and "bucket of fish" are
 *   distinguishable.)  
 */
contentsDistinguisher: Distinguisher
    sortOrder = 600
    appliesTo(obj) { return obj.distinguishByContents != nil; }
    equal(a, b)
    {
        local ac = a.nominalContents(), bc = b.nominalContents();
        return (ac != nil ? ac.name : nil) == (bc != nil ? bc.name : nil);
    }
;
    

/* ------------------------------------------------------------------------ */
/*
 *   A NounPhrase object represents a noun phrase within a command line.
 *   This class handles the mapping from the text of the noun phrase in the
 *   input to the game-world objects that the noun phrase refers to.
 *   
 *   This object encompasses a core noun phrase plus all of its qualifiers.
 *   Qualifiers can themselves be noun phrases: possessives, locationals,
 *   and contents phrases contain subsidiary noun phrases, so we represent
 *   these qualifiers with subsidiary NounPhrase objects.  
 */
class NounPhrase: object
    /* create */
    construct(parent, prod)
    {
        /* 
         *   remember the parent NounPhrase and the grammar production
         *   match object that's the source of the noun phrase
         */
        self.parent = parent;
        self.prod = self.coreProd = prod;
    }

    /* clone - create a modifiable copy based on this original noun phrase */
    clone()
    {
        /* create a new object with my same property values */
        local cl = createClone();

        /* make safe copies of any vectors */
        foreach (local p in cl.getPropList())
        {
            local v;
            if (cl.propType(p) == TypeObject && (v = cl.(p)).ofKind(Vector))
                cl.(p) = new Vector(v.length(), v);
        }

        /* return the clone */
        return cl;
    }

    /* 
     *   By default, use the original input text of my "core" production as
     *   the name we show for this noun phrase in error messages.  The core
     *   production is the noun phrase minus any qualifiers (articles,
     *   possessives, locational phrases, etc).
     *   
     *   As we successfully resolve qualifiers, we'll expand this to
     *   include the qualifying phrases.  Any error we find after resolving
     *   a qualifier will necessary apply to the qualified form, so we want
     *   to include the qualifier in any error message.
     *   
     *   For example, if the original phrase is BUCKET OF FISH ON TABLE,
     *   we'll start out with the core phrase of BUCKET.  We'll next
     *   resolve the contents qualifier, OF FISH.  Assuming that we find a
     *   BUCKET OF FISH, that becomes the new error name.  If we then fail
     *   to find such an object ON TABLE, we'll be able to report that
     *   there's no BUCKET OF FISH on the table.  This is better than
     *   reporting that we don't see any BUCKET on the table, because there
     *   could in fact be a different bucket on the table.  
     */
    errName = (errNameProd.getText())

    /* the source of the error name is initially the core production */
    errNameProd = (coreProd)

    /*
     *   Expand the error-message name to include the given qualifier.
     *   We'll find the common parent of the core production and the given
     *   qualifier's production, and use its text as the new error name. 
     */
    expandErrName(np)
    {
        /* 
         *   look for the common parent of 'np' and the current error name
         *   source 
         */
        for (local prod = np.prod ; prod != nil ; prod = prod.parent)
        {
            /* 
             *   if this is also a parent of errNameProd, we've found the
             *   common parent 
             */
            if (prod == errNameProd || errNameProd.isChildOf(prod))
            {
                /* establish this as the new error name source */
                errNameProd = prod;

                /* no need to keep looking */
                break;
            }
        }
    }

    /*
     *   Does this NounPhrase contain the given NounPhrase?  Returns true
     *   if NounPhrase is self, or one of our qualifier noun phrases
     *   contains it. 
     */
    contains(np)
    {
        return (np == self
                || (possQual != nil && possQual.contains(np))
                || (locQual != nil && locQual.contains(np))
                || (exclusions != nil
                    && exclusions.indexWhich({ x: x.contains(np) }) != nil));
    }
    
    /*
     *   Get the list of objects matching the vocabulary words in our noun
     *   phrase.  Populates our 'matches' property with a vector of matching
     *   objects.  This doesn't look at any of our qualifiers, or attempt
     *   to disambiguate contextually; it simply finds everything in scope
     *   that the noun phrase could refer to.  
     */
    matchVocab(cmd)
    {
        /* start with an empty vector */
        local v = new Vector(32);

        /* get the current scope list */        
        cmd.action.buildScopeList();
        local scope = cmd.action.scopeList;

        /* check what kind of phrase we have */
        if (pronoun != nil)
        {
            /* it's a pronoun - resolved based on the antecedent */
            addMatches(v, pronoun.resolve(), 0);

            /* if there are no antecedents, flag the error */
            if (v.length() == 0)
                throw new NoAntecedentError(self, pronoun);

            /* filter for in-scope objects (or reflexive placeholders) */
            v = v.subset(
                { m: m.obj.ofKind(Pronoun) || scope.find(m.obj) });

            /* if that leaves nothing, flag the error */
            if (v.length() == 0)
                throw new AntecedentScopeError(cmd, self, pronoun);

        }
        else if (determiner == All && tokens == [])
        {
            /* ALL - use everything in scope applicable to the verb */
            addMatches(v, cmd.action.getAllUnhidden(cmd, role), 0);
            cmd.matchedAll = true;
        }
        else
        {
            /* 
             *   It's a named object.  Our 'tokens' property is a list of
             *   the words in the noun phrase in the user input.  Match it
             *   against the objects in physical scope.
             */
            v.appendAll(matchNameScope(cmd, scope));
        }

        /* save the match list so far */
        matches = v;

        /* if we have a contents qualifier, match its vocabulary */
        if (contQual != nil)
        {
            /* match vocabulary */
            contQual.matchVocab(cmd);

            /* apply the qualifier to keep only matching items */
            contQual.applyContQual();

            /* if that empties our list, flag it */
            if (matches.length() == 0)
                throw new NoneWithContentsError(cmd, self, contQual);

            /* 
             *   Expand the error text name to include the contents
             *   qualifier, since any subsequent failure to match will be
             *   against the result of this qualification.  For example, if
             *   the phrase is BUCKET OF FISH ON TABLE, we've now limited
             *   the scope to just BUCKET OF FISH, so if we fail to find
             *   such an object on the table it'll be because there's no
             *   BUCKET OF FISH on the table, not because there's simply no
             *   BUCKET.  
             */
            expandErrName(contQual);
        }

        /* if we have a possessive qualifier, apply it */
        if (possQual != nil)
        {
            /* match vocabulary for the possessive phrase */
            possQual.matchVocabPoss(cmd);

            /* 
             *   apply the qualifier, filtering out things not owned by the
             *   object named in the qualifier 
             */
            possQual.applyPossessive();

            /* if that empties our list, flag it */
            if (matches.length() == 0)
                throw new NoneInOwnerError(cmd, self, possQual);

            /* expand the error text to include the possessive qualifier */
            expandErrName(possQual);
        }

        /* if we have a locational qualifier, match its vocabulary */
        if (locQual != nil)
        {
            /* match vocabulary */
            locQual.matchVocab(cmd);

            /* apply the qualifier to keep only properly located items */
            locQual.applyLocational();

            /* if that empties our list, flag it */
            if (matches.length() == 0)
                throw new NoneInLocationError(cmd, self, locQual);

            /* expand the error name to include the locational */
            expandErrName(locQual);
        }

        /* if there's an exclusion list, apply it */
        if (exclusions != nil)
            exclusions.forEach({ x: x.applyExclusion(cmd) });
    }

    /*
     *   Add matching objects to a match vector.  'lst' can be a list or
     *   vector of objects, or a single object.  'match' is the MatchXxx
     *   flag value returned from the object name match, if applicable.  
     */
    addMatches(vec, lst, match)
    {
        /* ignore nil */
        if (lst == nil)
            return;

        /* wrap each item in an NPMatch object and add it to the vector */
        vec.appendAll(valToList(lst).mapAll({ obj: new NPMatch(self, obj, match) }));
    }

    /*
     *   Find the vocabulary matches for a given noun phrase within a given
     *   scope list.  Add all of the matches to the given vector.  
     */
    matchNameScope(cmd, scope)
    {
        /* set up a vector for the results */
        local v = new Vector(32);
        
        /*
         *   Run through the scope list and ask each object if it matches
         *   the noun phrase.  Keep the ones that match.  
         */
        foreach (local obj in scope)
        {
            /* ask this object if it matches */
            local match = obj.matchName(tokens);
            
            /* if it matches, include it in the results */
            if (match)
                v.append(new NPMatch(self, obj, match));
        }

        /*
         *   Now narrow the list according to the match strength.  Only
         *   keep the matches that have the maximum strength of the list.
         */
        if (v.length() > 0)
        {
            /* sort in descending order of strength */
            v.sort(SortDesc, { a, b: a.strength - b.strength });

            /* 
             *   discard everything that doesn't match the highest strength
             *   (which is the first element's strength, since we've sorted
             *   in descending order) 
             */
            v = v.subset({ a: a.strength == v[1].strength });
        }
        else
        {
            /* the list is empty - complain about it */
            throw new UnmatchedNounError(cmd, self);
        }

        /* return the list */
        return v;
    }

    /*
     *   Match vocabulary for a possessive qualifier phrase.
     *   
     *   Possessive matching has somewhat different rules than for ordinary
     *   noun phrases.
     *   
     *   First, possessive pronouns (HIS, HER, ITS, THEIR) *can* act like
     *   reflexives, in that they can refer back to earlier clauses in the
     *   same predicate: ASK BOB ABOUT HIS MOTHER.  However, they can also
     *   refer to previous commands: SEARCH BOB; TAKE HIS WALLET.  The
     *   deciding factor is whether or not there's an earlier noun phrase
     *   in the command that matches in gender and number; if so, we use
     *   the reflexive meaning, otherwise we use the external referent.
     *   
     *   Second, the scope for ordinary noun phrases has to be expanded to
     *   include the owners of the objects in scope.  If we have a wallet
     *   that we know belongs to Bob, we should be able to refer to it as
     *   "Bob's wallet" whether or not Bob himself is in scope.  So, for
     *   the purposes of the possessive, Bob is in scope even if he
     *   wouldn't be for an ordinary noun phrase.  
     */
    matchVocabPoss(cmd)
    {
        /* start with an empty vector */
        local v = matches = new Vector(32);

        /* check what kind of phrase we have */
        if (pronoun != nil)
        {
            /* 
             *   It's a possessive pronoun (HIS, HER, ITS, etc).
             *   Possessive pronouns can refer back to something in the
             *   same sentence (ASK BOB ABOUT HIS WALLET) or to earlier
             *   commands (SEARCH BOB; TAKE HIS WALLET).
             *   
             *   If it's a second-person possessive (YOUR), and there's an
             *   addressee actor, it refers to the actor.  For example,
             *   "Bob, give me your wallet".
             *   
             *   Look at the preceding noun phrases in the predicate to see
             *   if we can find an object that matches this pronoun.  If
             *   so, use it as the antecedent.  If not, use the regular
             *   antecedent.  
             */
            local done = nil;
            cmd.forEachNP(new function(np)
            {
                /* if we've already finished, ignore this noun phrase */
                if (done)
                    return;

                /* 
                 *   if this is our parent, stop looking - pronoun
                 *   references of this sort are always back references 
                 */
                if (np == parent)
                {
                    done = true;
                    return;
                }

                /* 
                 *   If this is the addressee actor, and we have a
                 *   second-person possessive pronoun (YOUR), the pronoun
                 *   refers to the actor. 
                 */
                if (np.role == ActorRole && pronoun.person == 2)
                {
                    v.appendAll(np.matches);
                    done = true;
                    return;
                }

                /* check for matches to this pronoun in this match list */
                local s = np.matches.subset(
                    { o: pronoun.matchObj(o.obj) });

                /* 
                 *   if we found any matches, use them, and stop looking -
                 *   we only want to use the nearest match 
                 */
                if (s.length() != 0)
                {
                    v.appendAll(s);
                    done = true;
                }
            });

            /* 
             *   if we didn't find any matches, use the antecedent from a
             *   previous command, if available 
             */
            if (v.length() == 0)
                v.appendAll(pronoun.resolve().mapAll({
                    x: new NPMatch(self, x, 0) }));
        }
        else
        {
            /* 
             *   It's a named object.  We need an expanded scope list that
             *   includes the owners of the objects referred to by the
             *   underlying noun phrase that we qualify.  
             */
            local expScope = new Vector(32);
            foreach (local obj in parent.matches)
            {
                /* 
                 *   if this object has an owner or owners, add it/them to
                 *   the expanded scope list 
                 */
                local owner = obj.obj.owner;
                if (owner != nil)
                    expScope.appendAll(owner);
            }

            /* add the objects in scope, filtering out duplicates */
            expScope.appendUnique(World.scope.toList());

            /* now build the match list using the expanded scope */
            v.appendAll(matchNameScope(cmd, expScope));
        }

        /* 
         *   a possessive qualifier can itself have a possessive qualifier
         *   (BOB'S MOTHER'S HAT), so go resolve that as well 
         */
        if (possQual != nil)
            possQual.matchVocabPoss(cmd);
    }

    /*
     *   Apply this possessive phrase's qualification.  This filters the
     *   underlying (parent) noun list to keep only objects owned by the
     *   object(s) named in this noun phrase.  
     */
    applyPossessive()
    {
        /* 
         *   First, do "reverse" filtering: consider only owners who own
         *   something that's in the underlying noun list.  For example, if
         *   there are two guards present, but only one of them is carrying
         *   a sword, GUARD'S SWORD must refer to the guard who's carrying
         *   a sword.
         *   
         *   (Take a subset of our own objects, keeping each object 'o'
         *   where there's something in the parent list owned by 'o'.  That
         *   is, there's an object 'p' in the parent list where 'p' is
         *   owned by 'o'.)  
         */
        local m = matches.subset(
            { o: parent.matches.indexWhich(
                { p: p.obj.ownedBy(o.obj) }) != nil });

        /* if the reverse filter didn't rule everything out, apply it */
        if (m.length() > 0)
            matches = m;
        
        /* next, apply any possessive qualifier of my own */
        if (possQual != nil)
            possQual.applyPossessive();

        /* filter parent objects not owned by anything in my list */
        parent.matches = parent.matches.subset(
            { p: matches.indexWhich(
                { o: p.obj.ownedBy(o.obj) }) != nil });
    }

    /*
     *   Apply this contents qualifier phrase's qualification.  This
     *   filters the underlying (parent) noun list to keep only objects
     *   that contain the object(s) named in this noun list.  
     */
    applyContQual()
    {
        /* 
         *   First, do the reverse filtering, to keep only objects that
         *   could be inside objects in the underlying list.  
         */
        local m = matches.subset(
            { o: parent.matches.indexWhich(
                { p: o.obj.isChild(p.obj, nil) }) != nil });

        /* if that didn't rule everything out, apply the filter */
        if (m.length() > 0)
            matches = m;

        /* next, apply any locational qualifier of my own */
        if (contQual != nil)
            contQual.applyContQual();

        /* filter parent objects not containing anything in my list */
        parent.matches = parent.matches.subset(
            { p: matches.indexWhich(
                { o: o.obj.isChild(p.obj, nil) }) != nil });
    }
    
    /*
     *   Apply this locational phrase's qualification.  This filters the
     *   underlying (parent) noun list to keep only objects located within
     *   the object(s) named in this noun phrase.  
     */
    applyLocational()
    {
        /* 
         *   First, do the reverse filtering, to keep only objects that
         *   could contain objects in the underlying list. 
         */
        local m = matches.subset(
            { o: parent.matches.indexWhich(
                { p: p.obj.isChild(o.obj, locType) }) != nil });

        /* if that didn't rule everything out, apply the filter */
        if (m.length() > 0)
            matches = m;

        /* next, apply any locational qualifier of my own */
        if (locQual != nil)
            locQual.applyLocational();

        /* first, try limiting to items DIRECTLY in the location */
        m = parent.matches.subset(
            { p: matches.indexWhich(
                { o: p.obj.isDirectChild(o.obj, locType) }) != nil });

        /* if there weren't any, try items indirectly in the location */
        if (m.length() == 0)
            m = parent.matches.subset(
                { p: matches.indexWhich(
                    { o: p.obj.isChild(o.obj, locType) }) != nil });

        /* save the filtered list in the parent */
        parent.matches = m;
    }
    
    /*
     *   Apply an exclusion item.  This resolves the vocabulary for the
     *   exclusion phrase and filters the matching item(s) noun phrase out
     *   of the parent list.  
     */
    applyExclusion(cmd)
    {
        /* do our vocabulary matching */
        matchVocab(cmd);

        /* filter the parent list to exclude everything we matched */
        parent.matches = parent.matches.subset(
            { p: matches.indexWhich(
                { o: o.obj == p.obj }) == nil });
    }

    /*
     *   Select the objects from among the vocabulary matches.  This
     *   narrows the list of possible vocabulary matches for our noun
     *   phrase to find the actual object or objects the player is
     *   referencing.
     *   
     *   When this is called, we've already filled in the match list with
     *   all objects in scope that match the vocabulary of the core noun
     *   phrase (including non-reflexive pronouns and ALL), and we've
     *   applied any possessive, locational, and exclusion qualifiers.
     *   What we're left with is the list of in-scope objects that meet all
     *   of the specifications contained in the entire noun phrase.  In
     *   other words, we've squeezed all available information out of the
     *   noun phrase itself.  If the result is ambiguous, then, we'll have
     *   to look beyond the noun phrase, to the broader semantic content of
     *   the overall command.  
     *   
     *   There are three possible "goals" for what our final object list
     *   should look like after disambiguation.  Only one goal applies to
     *   each particular noun phrase; which it is depends on the grammar of
     *   the phrase:
     *   
     *   1.  Definite mode: TAKE BOOK, TAKE THE BOOK, TAKE BOTH BOOKS, TAKE
     *   THE THREE BOOKS.  The goal in definite mode is to choose the given
     *   number of objects, *and* to make sure that the player could *only*
     *   have meant those precise objects.  In other words, we're not
     *   allowed to make an arbitrary choice: in natural language, the
     *   definite mode says that the speaker believes the listener knows
     *   which *particular* object or objects the speaker is referring to.
     *   If we're not absolutely sure which objects the player is talking
     *   about, we have a disagreement with the player's apparent
     *   expectations and must ask for clarification.
     *   
     *   2.  Indefinite mode: TAKE A BOOK, TAKE ANY BOOK, TAKE TWO BOOKS.
     *   The goal is to choose the given number of objects from the
     *   possible matches, arbitrarily choosing from the available objects.
     *   
     *   3. Plural mode: TAKE BOOKS, TAKE THE BOOKS, TAKE ALL BOOKS.  The
     *   goal here is to choose all of the matching objects.  
     */
    selectObjects(cmd)
    {
        /* take the mode from the determiner */
        local mode = determiner;

        /* 
         *   Sort the matches by listing order.  If we have a plural, this
         *   will make the order of processing more logical when there's
         *   some kind of natural order (such as alphabetized or numbered
         *   items).  
         */
        matches.groupSort(
            { ent, idx: [ent.obj.disambigGroup, ent.obj.disambigOrder] });

        /* if there's no determiner, assume definite */
        if (mode == nil)
            mode = Definite;

        /*
         *   If we're in Definite mode and we don't have a quantifier,
         *   check for a plural noun phrase.  A plural without a specific
         *   number puts us in Plural mode.  Consider the noun phrase to be
         *   plural if it matched any of our objects with plural usage.
         *   Even if some objects were singular in usage, one plural is
         *   enough to suggest that the name has plural usage. 
         */
        if (mode == Definite
            && quantifier == nil
            && matches.indexWhich({ m: m.match & MatchPlural }) != nil)
            mode = All;

        /* 
         *   Figure the target quantity.  If there's a quantifier, it's the
         *   quantifier value; otherwise we implicitly want a singleton.
         *   Note that the quantifier is ignored in Plural mode, since we
         *   simply want to match all of the objects in this case.  
         */
        local num = (quantifier != nil ? quantifier : 1);

        /*
         *   If we don't have enough objects to satisfy the request,
         *   complain about it. 
         */
        if (num > matches.length())
            throw new InsufficientNounsError(cmd, self);
        
        if (mode == Definite && isAllEquivalent(matches))
            mode = Indefinite;

        
        for(local cur in objs)
            cur.filterResolveList(self, cmd, mode);
        
        /* select the goal based on the mode */
        switch (mode)
        {
        case Definite:        
            /* 
             *   Definite mode.  If we have more than the desired number,
             *   we must disambiguate.  
             */
            if (matches.length() > num)
                disambiguate(cmd, num, cmd.action);
            else
                /* 
                 *   If we don't disambiguate we don't run the verify routine
                 *   that stores a reference to the object selected for this
                 *   role so that it can be available to the verify routine for
                 *   the other role; so we store a reference now.
                 */
                cmd.action.(role.curObjProp) = cmd.(role.objListProp)[1].obj;
            break;

        case Indefinite:
            /*
             *   Indefinite mode - we must select the desired number, but
             *   we can do so arbitrarily.  Simply select the first 'num'
             *   in the list.
             */
            
            /* start by getting object rankings from the verb */
            cmd.action.scoreObjects(cmd, role, matches);
            
            /* sort by score (highest to lowest), except for the ActorRole */
            matches.sort(SortDesc, { a, b: a.score - b.score });
            
            if (matches.length() > num)
                matches.removeRange(num + 1, matches.length());

            /* flag the objects as arbitrarily chosen */
            matches.forEach({ m: m.flags |= SelArbitrary });
            break;

        case All:
            /* 
             *   Plural mode - select all of the objects.  Simply use the
             *   set we've already built.  Flag the selections as plural.  
             */
            matches.forEach({ m: m.flags |= SelPlural });
            cmd.matchedMulti = true;
            break;
        }
    }

    /* 
     *   Determine whether all matches in the matchList are impossible to
     *   disambiguate.
     */
    isAllEquivalent(matchList){
        local names = Distinguisher.getNames(
            matchList.mapAll({ x: x.obj }), nil);
        return (names.length() == 1);
    }
    
    /*
     *   Disambiguate the match list to select the given target number of
     *   objects.  
     */
    disambiguate(cmd, num, action)
    {
        /* start by getting object rankings from the verb */
        action.scoreObjects(cmd, role, matches);

        /* sort by score (highest to lowest) */
        matches.sort(SortDesc, { a, b: a.score - b.score });

        /* 
         *   To pick automatically, we need exactly 'num' objects at the
         *   highest score.  The sort put the object with the highest score
         *   at the start of the list, so the high-scoring subset is the
         *   subset that matches the first object's score.
         *   
         *   We only disambiguate in definite mode, and definite mode in
         *   input is the player's way of telling us that they think there
         *   are exactly this many objects that obviously apply to their
         *   command.  The score tells us which objects *we* think are the
         *   obvious choices for the command.  If we come up with the same
         *   set size that the player expressed, then we presumably
         *   understand what the player is saying.  If our set size differs
         *   from theirs, we're not thinking alike, so we need to ask for
         *   clarification.  
         */
        local sub = matches.subset({x: x.score == matches[1].score});
        
        if (isAllEquivalent(sub))
            sub.setLength(num);
        
        if (sub.length() == num)
        {
            /* 
             *   We have the desired number of most obvious matches, so
             *   we've successfully disambiguated it.  We might want to
             *   announce the selection, since we're making a guess, so
             *   generate a name for each that distinguishes it from the
             *   other items we could have matched.  
             */
            local names = Distinguisher.getNames(
                matches.mapAll({ x: x.obj }), nil);            

            /* save the disambiguated subset */
            matches = sub;

            /* mark each as disambiguated, and save the distinctive name */
            foreach (local m in matches)
            {
                m.flags |= SelDisambig;
                m.name = names.valWhich({ n: n[2].indexOf(m.obj) != nil })[1];
            }
            
            /* we've successfully disambiguated the phrase */
            return;
        }        
        else if (sub.length() > num && num > 1)                    
        {
            /*            
             *   We've asked for a definite number of 2 or more items, but there
             *   are different options among the best matches.  This poses a
             *   problem because there's no good disambiguation we can possibly
             *   ask here. So we just give up and ask them to be more specific.
             *   I can imagine someone responding to this message by just
             *   retyping a more specific form of the noun phrase. For example,
             *   after GET THE TWO MATCHES doesn't work, they might just want to
             *   type THE LIT MATCH AND AN UNLIT MATCH, but currently the parser
             *   does not do this.  Probably the DMsg should also refer to the
             *   specific noun phrase that is ambiguous in its message.
             */
            throw new AmbiguousMultiDefiniteError(cmd,self);
        }
    
        /*
         *   We have more than what we need in the highest scoring section,
         *   so make this the matches and proceed with disambiguation.
         *   This line makes it so that when you say something like "drop match"
         *   it will only try to disambiguate among the things you are holding.
         *   I think this behavior is more desirable, but am not certain.
         */
        matches = sub;
        

        /* it's still ambiguous, so throw an error to ask for help */
        ambigError(cmd);
        matches.setLength(num);
    }

    /*
     *   Throw an ambiguous noun phrase error for the current match list. 
     */
    ambigError(cmd)
    {
        /* if we have a reply to a past disambiguation question, apply it */
        local disambig = cmd.fetchDisambigReply();
        if (disambig != nil)
        {
            /* start a list for the result */
            local dmatches = new Vector(matches.length());

            /* add the object(s) selected by each noun phrase in the reply */
            foreach (local dnp in disambig)
            {
                /* 
                 *   resolve this noun phrase of the reply and add its
                 *   selections to the master list 
                 */
                dmatches.appendAll(
                    dnp.applyDisambig(cmd, matches, disambigNameList));
            }

            /* 
             *   If we get this far, we have a valid result set now, even
             *   if it's not of the original size.  The reply can select a
             *   different number of objects than originally implied, since
             *   the reply can say something like "the red one and the blue
             *   one" to pick more than one of the offered objects.  
             */
            matches = dmatches;
            return;
        }

        /* 
         *   Still ambiguous, so we need to ask for clarification, with a
         *   question like "Which do you mean, the red book, or the blue
         *   book?"  Generate the list of names.  
         */
        local nameList = Distinguisher.getNames(
            matches.mapAll({ x: x.obj }), true);

        /* 
         *   Sort by disambigGroup and disambigOrder.  Note that it's
         *   possible for a set to have more than one item with a
         *   disambigGroup, and these might not match.  We can't break up a
         *   set, though, so we'll just have to pick one group arbitrarily
         *   for the whole set. 
         */
        nameList.groupSort(new function(entry, idx)
        {
            /* find an arbitrary entry in the set with a disambigGroup */
            local gobj = entry[2].valWhich({ x: x.disambigGroup != nil });
            
            /* if we found one, use its group and order; otherwise use nil */
            return gobj != nil
                ? [gobj.disambigGroup, gobj.disambigOrder]
                : [nil, idx];
        });

        /* 
         *   remember this list, since it determines the meanings of
         *   ordinals ("the second one") in the reply 
         */
        disambigNameList = nameList;       
        
        /* throw the still-ambiguous error */
        throw new AmbiguousError(cmd, self, nameList);
        
        
    }

    /*
     *   Apply this noun phrase as a disambiguation reply to the given
     *   original list of matches to an ambiguous noun phrase.  
     */
    applyDisambig(cmd, ambigMatches, nameList)
    {
        /* 
         *   Start with the ambiguous list.  Our goal is to narrow the list
         *   that the original noun phrase matched, so start with the list
         *   and remove items that don't match the additional vocabulary
         *   and/or qualifiers in the reply.  
         */
        matches = ambigMatches;

        /* if there's an ordinal, pick out the selected item */
        if (ordinal != nil)
        {
            /* pick the name list entry based on the list position */
            local n;
            if (ordinal == -1 && nameList.length() > 0)
                n = nameList[nameList.length()];
            else if (ordinal >= 1 && ordinal <= nameList.length())
                n = nameList[ordinal];
            else
                throw new OrdinalRangeError(self, ordinal);

            /* 
             *   take the first object from the group, and build a resolved
             *   object list with this object 
             */
            n = n[2][1];
            matches = matches.subset({ m: m.obj == n });
        }

        /* if there's a locational qualifier, apply it */
        if (locQual != nil)
        {
            /* apply the locational qualifier */
            locQual.matchVocab(cmd);
            locQual.applyLocational();

            /* if that empties our list, flag it */
            if (matches.length() == 0)
                throw new NoneInLocationError(cmd, parent, locQual);
        }
                
        /* if there's a possessive qualifier, apply it */
        if (possQual != nil)
        {
            /* apply the possessive qualifier */
            possQual.matchVocabPoss(cmd);
            possQual.applyPossessive();

            /* if that empties our list, flag it */
            if (matches.length() == 0)
                throw new NoneInOwnerError(cmd, parent, possQual);
        }

        /* if there's a contents qualifier, apply it */
        if (contQual != nil)
        {
            /* apply the qualifier */
            contQual.matchVocab(cmd);
            contQual.applyContQual();

            /* if that empties our list, flag it */
            if (matches.length() == 0)
                throw new NoneWithContentsError(cmd, parent, contQual);
        }

        /* if there's vocabulary, apply it */
        if (tokens.length() > 0)
        {
            /*
             *   The basic vocabulary of the reply isn't as simple to
             *   handle as it might seem, since the words could refer to
             *   the object itself, a container, an owner, or the nominal
             *   contents.  Consider:
             *   
             *   Which bucket do you mean, the empty bucket, the bucket on
             *   the shelf, the tall fisherman's bucket, or the bucket of
             *   water?
             *   
             *   Players are accustomed to being able to answer these
             *   questions by entering just a word or two from the prompt,
             *   so we'd want to accept EMPTY, SHELF, TALL, and WATER for
             *   the respective choices.
             *   
             *   So: first assume that the reply refers to the object
             *   itself.  If we don't find any matches, try the other
             *   possibilities: containers, owners, and nominal contents.  
             */
            if (tokens.length() > 0 && matches.length() > 0)
            {
                /* first try applying the words to the object itself */
                local m = matches.subset(
                    { o: o.obj.matchNameDisambig(tokens) != 0 });
                
                /* if that didn't match anything, try containers */
                if (m.length() == 0)
                {
                    /* get the list of in-scope objects matching the tokens */
                    local locs = World.scope.subset(
                        { o: o.matchNameDisambig(tokens) != 0 });

                    /* get the subset of 'matches' that are in 'locs' */
                    m = matches.subset(
                        { o: locs.indexWhich(
                            { l: o.obj.isChild(l, nil) }) != nil });
                }
                
                /* if we still don't have any matches, try owners */
                if (m.length() == 0)
                {
                    /* get the list of scope objects plus potential owners */
                    local owners = new Vector(50, World.scope.toList());
                    foreach (local obj in matches)
                    {
                        local owner = obj.obj.owner;
                        if (owner != nil)
                            owners.appendAll(owner);
                    }

                    /* get the subset matching the tokens */
                    owners = owners.subset(
                        { o: o.matchNameDisambig(tokens) != 0 });

                    /* get the subset of 'matches' with owners in 'owners' */
                    m = matches.subset(
                        { o: owners.indexWhich(
                            { l: o.obj.ownedBy(l) }) != nil });
                }
                
                /* if we still don't have any matches, try nominal contents */
                if (m.length() == 0)
                {
                    /* get the list of in-scope objects matching the tokens */
                    local conts = World.scope.subset(
                        { c: c.matchNameDisambig(tokens) != 0 });

                    /* get the subset of 'matches' with contents in 'conts' */
                    m = matches.subset(
                        { o: conts.indexOf(o.obj.nominalContents) != nil });
                }
                
                /* if we've eliminated everything, it's an error */
                if (m.length() == 0)
                    throw new UnmatchedNounError(cmd, self);

                /* we're out of things to try, so take what we have */
                matches = m;
            }
        }

        /* determine how many the reply *wants* to select */
        local num = (quantifier != nil ? quantifier : 1);

        /* if we don't have enough, it's an error */
        if (matches.length() < num)
            throw new InsufficientNounsError(cmd, self);
        
        if (determiner == Definite && isAllEquivalent(matches))
            determiner = Indefinite;
        
        /* determine the actual number available */
        switch (determiner)
        {
        case Definite:
            /* 
             *   They want exactly the number indicated.  If we still have
             *   more than this, it's *still* ambiguous, so throw another
             *   ambiguity error to further disambiguate the new list.
             *   Otherwise, we're set.  
             */
            if (num < matches.length())
                ambigError(cmd);
            break;
            
        case Indefinite:
            /* indefinite - arbitrarily select any 'num' of the items */
            if (matches.length() > num)
                matches.removeRange(num + 1, matches.length());

            /* mark them as arbitrary */
            matches.forEach({ m: m.flags |= SelArbitrary });
            break;
            
        case All:
            /* all - keep all of the items */
            break;
        }

        /* return our final match list */
        return matches;
    }

    /*
     *   Resolve ALL.  This is called on a separate pass after
     *   selectObjects(), because two-object verbs sometimes resolve ALL in
     *   one slot according to the selection in the other slot.  
     */
    resolveAll(cmd)
    {
        /* if this is a simple ALL phrase, re-resolve it */
        if (determiner == All)
        {
            /* 
             *   If it's just ALL, re-match the vocabulary to pick up the
             *   final ALL list.  Otherwise, take the subset of the ALL
             *   list that matches the vocabulary. 
             */
            if (tokens == [])
            {
                /* it's just ALL - start over with the final ALL list */
                matchVocab(cmd);
            }
            else
            {
                /* 
                 *   it's ALL <somethings> - take the subset that's in the
                 *   final ALL list 
                 */
                local all = cmd.action.getAll(cmd, role);
                local sub = matches.subset({ m: all.indexOf(m.obj) != nil });

                /* 
                 *   If we found any objects in the intersection, keep only
                 *   the subset, since this is the set that actually makes
                 *   sense for this command.  If the subset is empty,
                 *   though, ignore it and stick with the objects we've
                 *   already selected based on the vocabulary; these will
                 *   probably fail the command, but that'll make more sense
                 *   to the player than claiming there's nothing matching
                 *   the description they gave.  
                 */
                if (sub.length() != 0)
                    matches = sub;
            }
        }
    }
    
    /*
     *   Resolve reflexive pronouns.  Our Command calls this AFTER
     *   resolving all of the regular noun phrases, because reflexives
     *   refer back to other nouns in the same command.  
     */
    resolveReflexives(cmd)
    {
        /* if we have a reflexive pronoun object in the list, resolve it */
        if (matches.length() == 1 && matches[1].obj.ofKind(Pronoun))
        {
            /* 
             *   We have a reflexive pronoun pending.  Ask the command for
             *   the current meaning of the reflexive.  
             */
            matches = cmd.resolveReflexive(matches[1].obj).mapAll(
                { x: new NPMatch(self, x, 0) });

            /* it's an error if that didn't yield anything */
            if (matches.length() == 0)
                throw new NoAntecedentError(self, pronoun);
        }
        else
        {
            /*
             *   This isn't a reflexive, so it's a candidate to be an
             *   antecedent of a reflexive later in the phrase.  Pass it
             *   along to the command to note for future use.  Since we
             *   visit the noun phrases in their order of appearance in the
             *   command, we'll naturally have the latest one before the
             *   pronoun when we encounter a pronoun, which is exactly what
             *   we want: a reflexive pronoun binds to the nearest
             *   preceding noun that matches in gender, number, etc.  
             */
            matches.forEach({ match: cmd.saveReflexiveAnte(match.obj) });

            /* also save the entire list, for THEMSELVES */
            cmd.saveReflexiveAnte(matches.mapAll({ x: x.obj }));
        }
    }

    /* Build the 'objs' list from the match list */
    buildObjList()
    {
        objs = matches.mapAll({x: x.obj});
    }

    /* 
     *   List of NPMatch objects.  This is populated during the matchName
     *   phase with the list of possible vocabulary matches, and then
     *   reduced during disambiguation to the final set.  
     */
    matches = []

    /* 
     *   List of resolved objects.  This is populated after disambiguation
     *   from the 'matches' set - it contains the same objects, but simply
     *   the objects rather than the NPMatch wrappers. 
     */
    objs = []

    /* add a literal to this phrase */
    addLiteral(tok) { tokens += tok; }

    /* add a possessive qualifier, returning the new noun phrase */
    addPossessive(prod)
    {
        /* create, store, and return a new noun phrase for the possessor */
        return possQual = new NounPhrase(self, prod);
    }

    /* add a contents qualifier, returning the new noun phrase */
    addContents(prep, prod)
    {
        /* remember the contents preposition */
        contPrep = prep;

        /* create, store, and return a new noun phrase for the contents */
        return contQual = new NounPhrase(self, prod);
    }

    /* add a locational qualifier, returning the new noun phrase */
    addLocation(locType, prod)
    {
        /* create a new noun phrase for the location */
        locQual = new NounPhrase(self, prod);

        /* set its location type */
        locQual.locType = locType;

        /* return the new phrase */
        return locQual;
    }

    /* add a quantifier, given as an integer value */
    addQuantifier(num)
    {
        quantifier = num;
    }

    /* add an ordinal, given as an integer value */
    addOrdinal(num)
    {
        ordinal = num;
    }

    /* add an exclusion list item */
    addExclusionItem(prod)
    {
        /* if we don't already have an exclusion list, create one */
        if (exclusions == nil)
            exclusions = [];

        /* create a new NounPhrase */
        local np = new NounPhrase(self, prod);

        /* add it to the exclusion list */
        exclusions += np;

        /* return the new noun phrase */
        return np;
    }

    /*
     *   Does this noun phrase refer to multiple objects structurally?
     *   This is true if any the matches used plural words, or the
     *   determiner is All, or we have a quantifier greater than 1.  
     */
    isMultiple()
    {
        return determiner == All
            || (quantifier != nil && quantifier > 1)
            || matches.indexWhich({ m: m.match & MatchPlural }) != nil;
    }

    /* 
     *   the Command list we're a part of (&dobjNPs, &iobjNPs, etc: the
     *   Command overrides this to the actual list property for a primary
     *   noun phrase, and for qualifiers such as possessives, this
     *   inherited version looks it up via the parent) 
     */
    role = (parent.role)

    /* the NounPhrase we qualify, if we're a possessive or locational */
    parent = nil

    /* the grammar production match object for this noun phrase */
    prod = nil

    /* 
     *   the grammar match for the core noun phrase; this is the part that
     *   names a single object, stripped of all qualifiers (such as
     *   possessives, articles, quantifiers, and locational phrases) 
     */
    coreProd = nil

    /* the literal tokens making up the noun phrase */
    tokens = []

    /* the pronoun, if any, as a Pronoun object */
    pronoun = nil

    /* the possessive qualifier, if any ("BOB'S box") */
    possQual = nil

    /* the locational qualifier phrase, if any ("the box ON THE SHELF") */
    locQual = nil

    /* 
     *   The locational qualifier relationship, as a LocType object.  (This
     *   is stored on the locational qualifier noun phrase itself, not on
     *   the underlying noun phrase it qualifies.)  
     */
    locType = nil

    /* the contents qualifier phrase, if any ("the bucket OF WATER") */
    contQual = nil

    /* the preposition of the contents qualifier */
    contPrep = nil

    /* the quantifier, if any, as a number: for "five books", this is 5 */
    quantifier = nil

    /* 
     *   The ordinal value, if any, as a number: for "the third one", this
     *   is 3.  This is intended for use in disambiguation replies, to let
     *   the user pick out an item by its position in the offered list.  
     */
    ordinal = nil

    /* the determiner, if any, as a Determiner object */
    determiner = nil

    /* 
     *   the exclusion list, if any (this is the list following EXCEPT or
     *   BUT in a phrase like ALL EXCEPT THE RED ONES) 
     */
    exclusions = nil

    /* the name list from the disambiguation query */
    disambigNameList = nil
;

/*
 *   TopicPhrase is a special kind of NounPhrase for topics (ASK ABOUT,
 *   TELL ABOUT, TALK ABOUT, LOOK UP, etc).  These phrases aren't resolved
 *   to game-world objects the way ordinary noun phrases are, but instead
 *   are resolved to conversation topic objects.  
 */
class TopicPhrase: NounPhrase
     /*
     *   Get the list of objects matching the vocabulary words in our noun
     *   phrase.  Populates our 'matches' property with a vector of matching
     *   objects.  This doesn't look at any of our qualifiers, or attempt
     *   to disambiguate contextually; it simply finds everything in scope
     *   that the noun phrase could refer to.  
     */
    matchVocab(cmd)
    {
        /* start with an empty vector */
        local v = new Vector(32);
        
        /* get the current scope list */
        //        local scope = World.scope;
        
        
        local scope = Q.topicScopeList;
        
        /* check what kind of phrase we have */
        if (pronoun != nil)
        {
            /* it's a pronoun - resolved based on the antecedent */
            addMatches(v, pronoun.resolve(), 0);
            
            /* if there are no antecedents, flag the error */
            if (v.length() == 0)
                throw new NoAntecedentError(self, pronoun);
            
            /* filter for in-scope objects (or reflexive placeholders) */
            v = v.subset(
                { m: m.obj.ofKind(Pronoun) || scope.find(m.obj) });
            
            /* if that leaves nothing, flag the error */
            if (v.length() == 0)
                throw new AntecedentScopeError(cmd, self, pronoun);
            
        }
        
        else
        {
            /* 
             *   It's a named object.  Our 'tokens' property is a list of the
             *   words in the noun phrase in the user input.  Match it against
             *   the objects in physical scope.
             */
             v.appendAll(matchNameScope(cmd, scope));

        }
        
        /* save the match list so far */
        matches = v;
        
        
        
        /* if we have a possessive qualifier, apply it */
        if (possQual != nil)
        {
            /* match vocabulary for the possessive phrase */
            possQual.matchVocabPoss(cmd);
            
            /* 
             *   apply the qualifier, filtering out things not owned by the
             *   object named in the qualifier
             */
            possQual.applyPossessive();
            
            /* if that empties our list, flag it */
            if (matches.length() == 0)
                throw new NoneInOwnerError(cmd, self, possQual);
            
            /* expand the error text to include the possessive qualifier */
            expandErrName(possQual);
        }
        
      
        
        if(matches.length == 0)
        {        
            /* Create a dummy object to represent the literal text */
            local obj = new Topic(tokens.join(' ').trim());
            
            /* Wrap the dummy object in am NPMatch object */
            local lst = [obj];
//            addMatches(v, lst, MatchNoApprox);
            addMatches(v, lst, 1);
            
            matches = v;  
            
            cmd.madeTopic = true;
        }
        
        
        local res = new ResolvedTopic(matches.mapAll({o: o.obj}).toList, tokens);
        
        res = new NPMatch(v[1].np, res, v[1].match);
        
        matches = new Vector([res]);
        
        
    }
    
    matchNameScope(cmd, scope)
    {
        /* set up a vector for the results */
        local v = new Vector(32);
        
        /*
         *   Run through the scope list and ask each object if it matches
         *   the noun phrase.  Keep the ones that match.  
         */
        foreach (local obj in scope)
        {
            /* ask this object if it matches */
            local match = obj.matchName(tokens);
            
            /* if it matches, include it in the results */
            if (match)
                v.append(new NPMatch(self, obj, match));
        }


        /* return the list */
        return v;
    }
    
    selectObjects(cmd)
    {
        filterResolveList(self, cmd, All);
    }
;

class ResolvedTopic: object
    construct(lst, toks)
    {
        /* 
         *   if our list of topics has more than one entry, sort it in ascending
         *   order of length of name. That's because the shorter the name, the
         *   closer it may be to what the player actually typed.
         */
        if(lst != nil && lst.length > 1)
            topicList = lst.sort(SortAsc, {a, b: a.name.length - b.name.length});
        else       
            topicList = lst;    
        tokens = toks;
    }    
    
    topicList = nil
    tokens = nil
    
    getBestMatch = (topicList == nil ? nil : topicList[1])
    getTopicText = tokens.join(' ').trim()
    theName = (getTopicText)
    name = (topicList != nil ? topicList[1].name : theName)
    person = 3
;

/*
     *   LiteralPhrase is a special kind of NounPhrase for literals (TYPE,
     *   WRITE, SET TO, etc).  These phrases aren't resolved to game-world
     *   objects, but instead are just treated as literal text.  
 */
class LiteralPhrase: NounPhrase
    matchVocab(cmd)
    {
        local v = new Vector(2);
        
        /* Recreate the literal text */
        local litName = tokens.join(' ');
               
        /* Create a dummy object to represent the literal text */
        local obj = new LiteralObject(litName.trim());
        
        /* Wrap the dummy object in am NPMatch object */
        local lst = [obj];
        addMatches(v, lst, MatchNoApprox);
        
        matches = v;   
    }
    
    selectObjects(cmd)
    {
        /* do nothing; there's only one object */
    }
;

/* object to hold the result of a literal input */

class LiteralObject: object
    construct(name_)
    {
        name = name_;
    }
    
    name = nil
    theName = (name)
    person = 3
;
    
/*
 *   NumberPhrase is a special kind of NounPhrase for numeric literals
 *   (e.g., FOOTNOTE n).  These phrases aren't resolved to game-world
 *   objects, but are simply taken as numeric values. 
 */
class NumberPhrase: NounPhrase
    
;
    

/* ------------------------------------------------------------------------ */
/*
 *   NPMatch is an object that describes one object matching a noun phrase.
 */
class NPMatch: object
    construct(np, obj, match)
    {
        /* save the NounPhrase, the object we matched, and the match flags */
        self.np = np;
        self.obj = obj;
        self.match = match;

        /* 
         *   set the name initially to the object name; the Command will
         *   replace this before execution with a name from the
         *   Distinguishers that's unique relative to the other objects in
         *   the list 
         */
        self.name = obj.name;

        /*
         *   Calculate the match strength for sorting purposes.
         *   
         *   The strength tells us how well the vocabulary matched the
         *   object.  Matches without truncation are stronger than those
         *   that include truncated words; likewise character
         *   approximation.  Matches that consist of entirely adjectives
         *   are weaker than those that contain nouns or plurals (for
         *   example, if we have a TOY CAR and a TOY CAR REMOTE CONTROL in
         *   scope, we'd consider CAR to be an unambiguous match to the TOY
         *   CAR, since the match to the REMOTE is weak by virtue of being
         *   all adjectives).
         *   
         *   The MatchXxx bit flags are arranged in arithmetic order of
         *   match strength, so the 'match' value basically equals the
         *   strength.  However, for the strength calculation, plurals and
         *   nouns are equivalent.  So the strength value is the match
         *   value with any plural flag replaced by the noun flag. 
         */
        self.strength = (match & ~MatchPlural)
            | (match & MatchPlural ? MatchNoun : 0);
    }

    /* the NounPhrase we matched */
    np = nil

    /* the matching object */
    obj = nil

    /* 
     *   the match flags - this is a combination of MatchXxx flags as
     *   returned from Mentionable.matchName()
     */
    match = 0

    /* the match strength, for sorting the match list */
    strength = 0

    /* the selection/disambiguation flags (SelXxx) */
    flags = 0

    /*
     *   Disambiguation score.  This is a number assigned by the action in
     *   scoreObjects().
     */
    score = 0

    /*
     *   The name, for announcement purposes.  This is filled in by the
     *   Command during execution.  The Command figures the name so that
     *   it's distinguished from all of the other objects in the same noun
     *   role in the command.  
     */
    name = ''
;


/* ------------------------------------------------------------------------ */
/*
 *   Our root class for grammar productions.  (A "production" represents a
 *   match to a syntax rule, as defined with a 'grammar' template.)
 *   
 *   The language module's grammar rules can define certain special
 *   properties on any production match object, and we'll find them in the
 *   course of building the command from the match tree:
 *   
 *   endOfSentence=true - define this on a production for a sentence-ending
 *   verb conjunction.  In English (and most Western languages), this can
 *   be used with rules that match punctuation marks like periods,
 *   exclamation points, and question marks, since these marks typically
 *   end a sentence.  The parser distinguishes between the grammar rules
 *   for the first clause in a sentence vs subsequent clauses.  It starts a
 *   new input line with the first-in-sentence rule, then uses the
 *   additional clause rule for each subsequent clause.  When a clause ends
 *   with a sentence-ending mark, though, we'll treat the next clause as a
 *   sentence opener again.  
 */
class Production: object
    /* get the original text of the command for this match */
    getText()
    {
        /* if we have no token list, return an empty string */
        if (tokenList == nil)
            return '';
        
        /* build the string based on my original token list */
        return cmdTokenizer.buildOrigText(getTokens());
    }

    /* get my original token list, in canonical tokenizer format */
    getTokens()
    {
        /* 
         *   return the subset of the full token list from my first token
         *   to my last token
         */
        return nilToList(tokenList).sublist(
            firstTokenIndex, lastTokenIndex - firstTokenIndex + 1);
    }

    /*
     *   Build the command for this production and its children.  By
     *   default, we'll simply traverse into our children.  
     */
    build(cmd, np)
    {
        /* if this is a sentence-ending mark, note it */
        if (endOfSentence)
            noteEndOfSentence(cmd, self);

        /* run through our list of matches */
        local info = grammarInfoForBuild();
        for (local i = 2, local len = info.length() ; i <= len ; ++i)
        {
            /* get the current match */
            local cur = info[i];

            /* process it based on its type */
            switch (dataType(cur))
            {
            case TypeSString:
                /* it's a literal token match item */
                visitLiteral(cmd, np, cur);
                break;

            case TypeObject:
                /* 
                 *   An object is a production sub-tree.  Set its parent
                 *   pointer to point back at us. 
                 */
                cur.parent = self;

                /* visit the production */
                visitProd(cmd, np, cur);
                break;
            }
        }

        /* 
         *   If there's a determiner, apply it the noun phrase.  Apply the
         *   determiner after building out the subtree, so that the parent
         *   determiner overrides any found in the subtree. 
         */
        if (determiner != nil)
            np.determiner = determiner;
    }

    /*
     *   Get the grammar match list for build() purposes.  By default, this
     *   simply returns the grammarInfo() results, which are automatically
     *   generated by the compiler to return a list of the "->prop" values from
     *   the matched grammar rule.  Some rules might want to modify that default
     *   value list, so we provide this routine as an override hook.
     */
    grammarInfoForBuild()
    {
        return grammarInfo();
    }
    
    
    /*
     *   Add a new NounPhrase item to the list under construction.  Certain
     *   productions are associated with specific functional slots in the
     *   abstract command - direct object, indirect object, EXCEPT list,
     *   etc.  This routine is for such production subclasses to override,
     *   to direct new noun phrases into the appropriate slot lists.  In a
     *   grammar, the functional role is typically at a higher level in the
     *   tree, with ordinary noun phrases plugged in underneath.
     *   
     *   Our default handling is to first check our nounPhraseRole
     *   property; if it's set, it tells us the role that this sub-tree
     *   plays in the predicate (direct object, indirect object,
     *   accessory).  We use that information to add the new NounPhrase to
     *   the Command list that we're building for our assigned role.
     *   
     *   If nounPhraseRole is nil, then we simply pass the request up to
     *   our parent.  Eventually we should reach a node encoding the
     *   function slot.  
     */
    addNounListItem(cmd, prod)
    {
        if (nounPhraseRole != nil)
            return cmd.addNounListItem(nounPhraseRole, prod);
        else
            return parent.addNounListItem(cmd, prod);
    }

    /* 
     *   Note an end-of-sentence marker.  We'll simply notify our parent by
     *   default. 
     */
    noteEndOfSentence(cmd, prod)
    {
        if (parent != nil)
            parent.noteEndOfSentence(cmd, prod);
    }

    /*
     *   The NounPhrase subclass to use for noun phrases within this
     *   sub-tree.  By default, we look to our parent; if we don't have a
     *   parent, we use the base NounPhrase class.
     *   
     *   Special phrase types (topics, literals, and numbers) have their
     *   own NounPhrase subclasses.  This is important because the
     *   resolution rules for these phrase types differ from the regular
     *   object resolution rules.  
     */
    npClass = (parent != nil ? parent.npClass : NounPhrase)

    /*
     *   My assigned noun phrase role, as a NounRole object.  This must be
     *   explicitly set for the top node in a noun slot (which can be a
     *   noun list production, a single noun production, a topic, etc).
     *   
     *   In a positional language grammar, the predicate production will
     *   mark its immediate child in each noun phrase slot by setting this
     *   according to the role that the sub-tree plays in the predicate
     *   grammar.  Non-positional languages that use grammatical case or
     *   other ways of encoding the role information must set this some
     *   other way.  
     */
    nounPhraseRole = nil

    /*
     *   Get our noun phrase role.  If we don't have a role defined
     *   directly, we'll inherit the role from our parent node. 
     */
    getNounPhraseRole()
    {
        return nounPhraseRole != nil
            ? nounPhraseRole : parent.nounPhraseRole;
    }

    /* 
     *   Visit a literal token child in our sub-tree.  This is called
     *   during the build process for each literal token in our child list.
     *   By default, we add the token to the command's current noun phrase.
     */
    visitLiteral(cmd, np, tok)
    {
        /* add the literal to the current noun phrase */
        if(np != nil)
           np.addLiteral(tok);
    }

    /* 
     *   Visit a production object in our list.  This is called during the
     *   build process for each production object in our child list.  By
     *   default, we simply build the child production recursively.  
     */
    visitProd(cmd, np, prod)
    {
        /* build out this production recursively */
        prod.build(cmd, np);
    }

    /*
     *   The determiner that this production applies to the noun phrase
     *   it's part of, as a Determiner object.  If this is non-nil, this
     *   Determiner will be set in the current NounPhrase when we visit
     *   this production in the build process.  
     */
    determiner = nil

    /* 
     *   My parent production.  The low-level GrammarProd mechanism doesn't
     *   set this up, so we set it up ourselves in the course of building
     *   out the tree.  In build(), just before we visit each
     *   sub-production, we set the sub-production's 'parent' property to
     *   point back to the parent production.  This property is therefore
     *   always set while we're traversing the child's tree, but won't
     *   necessarily be set yet if we're not currently working somewhere
     *   within the child's tree.  That means that you can always look at
     *   'parent' within your own build() routine or a child build()
     *   routine, but you can't necessarily look at it across the tree or
     *   within your own children.  
     */
    parent = nil

    /* 
     *   Find a parent matching a given test.  We'll scan up the parent
     *   tree, looking for the nearest parent p for which func(p) returns
     *   true, returning p.  If we can't find one, we return nil.  
     */
    findParent(func)
    {
        /* find the nearest parent that passes the callback test */
        local par;
        for (par = parent ; par != nil && !func(par) ; par = par.parent) ;

        /* return what we found */
        return par;
    }

    /* Is this production a child of the given production? */
    isChildOf(prod)
    {
        /* look up my parent tree for the given parent */
        for (local par = parent ; par != nil ; par = par.parent)
        {
            /* if this is the one we're looking for, we're a child */
            if (par == prod)
                return true;
        }

        /* didn't find it */
        return nil;
    }

    /*
     *   Find the action.  This finds the child of type VerbProduction,
     *   then retrieves the action from the verb production.  
     */
    findAction()
    {
        /* find the VerbProduction among our children */
        local vp = findChild(VerbProduction);

        /* return the action from the VerbProduction, if we found it */
        return (vp != nil ? vp.action : nil);
    }

    /*
     *   Find a child of a given class. 
     */
    findChild(cls)
    {
        /* if I'm of the desired class, we're done */
        if (ofKind(cls))
            return self;

        /* recursively scan my children */
        for (local gi = grammarInfo(), local i = 2, local len = gi.length() ;
             i <= len ; ++i)
        {
            /* try this child */
            local chi = gi[i].findChild(cls);
            if (chi != nil)
                return chi;
        }

        /* didn't find it */
        return nil;
    }
;

/*
 *   CommandProduction is a special Production subclass for the top-level
 *   grammar rule for the overall command. 
 *   
 *   Each instance of this type of production must define the following
 *   '->' properties in its syntax template:
 *   
 *   actor_ is the noun phrase giving the addressee of the command, if any.
 *   A command such as TELL ACTOR TO DO X or (using the long-standing IF
 *   convention) ACTOR, DO X addresses a command to an actor; i.e., it
 *   tells the actor to carry out the command, rather than the player's
 *   avatar.  A command that isn't addressed to an actor can leave actor_
 *   as nil.  
 *   
 *   cmd_ is the *first* predicate phrase (see below), in the desired order
 *   of execution.  For example, for "open the door and go north", cmd_
 *   should be set to the match tree for the "open the door" predicate.
 *   
 *   conj_ is any conjunction or punctuation ending the first predicate
 *   phrase.  This might be a period at the end of the sentence, or a word
 *   like 'and' or 'then' that can separate multiple commands.  This can be
 *   nil if there's no conjunction at all (such as when the whole command
 *   is just the first predicate).  The reason we need conj_ is that it
 *   tells us where any subsequent command on the same command line starts.
 *   If cmd2_ is not nil, we'll ignore conj_ and use cmd2_ instead for this
 *   purpose.
 *   
 *   cmd2_ is optional: it's the *second* predicate phrase.  If this is not
 *   nil, it tells the parser where to start parsing the next predicate on
 *   the same command line after finishing with the first one.  This is
 *   optional, even if the command line really does have more than one
 *   predicate, because the parser can use conj_ instead to infer where the
 *   second predicate must start.
 *   
 *   (It's probably intuitively obvious what "first predicate" means, but
 *   for the sake of translators, here's a more thorough analysis.  Some
 *   command productions can match more than one predicate phrase, but this
 *   is only for the sake of determining where the first one ends,
 *   syntactically.  The execution engine actually only carries out the
 *   first predicate matched for a given parse tree - it simply ignores any
 *   others in the same tree.  After we finish executing the first
 *   predicate from the match, we go back and re-parse the remaining text
 *   from scratch, as raw text; at that point, the next predicate in the
 *   text becomes the first predicate in the new parse tree and gets
 *   executed.  We repeat this until we run out of text.  So we do
 *   eventually execute everything the player types in - but not on the
 *   first parse; we have to do one parse per predicate.  We have to repeat
 *   the parsing because carrying out the first action could change the
 *   game state in such a way that we'll find a different match to the next
 *   predicate than we would have if we'd parsed everything up front.  By
 *   "first predicate phrase", then, we mean the one that gets executed
 *   first.  The point is to carry out the user's wishes as expressed in
 *   the command, so we want the first predicate we execute to be the one
 *   that the player *intends* to be carried out first; so by "first" we
 *   really mean the one that a speaker of the natural language would
 *   expect to be performed first, given the structure of the sentence and
 *   the rules of the language.  In English, this is easy: X THEN Y or X,Y
 *   or X AND Y all mean "first do X, then do Y" - the reading order is the
 *   same as the execution order.)  
 */
class CommandProduction: Production
    /* -> property: the match tree for the addressee, if any */
    actor_ = nil

    /*
     *   The grammatical person of the actor to whom we're giving orders.
     *   This is 2 for second person and 3 for third person.  (It's not
     *   meaningful to give orders in the first person.)
     *   
     *   In English (and probably most languages), commands of the form
     *   ACTOR, DO SOMETHING address ACTOR in the second person.  In
     *   contrast, TELL ACTOR TO DO SOMETHING gives orders to ACTOR, but in
     *   the third person.
     *   
     *   In the second-person form of giving orders, second-person pronouns
     *   (YOU, YOURSELF) within the command will refer back to the actor
     *   being addressed: BOB, EXAMINE YOURSELF tells Bob to look at Bob.
     *   In the indirect form, YOU refers to the player character: TELL BOB
     *   TO EXAMINE YOU tells Bob to look at the PC.
     *   
     *   The default is 2, since the long-standing IF convention is the
     *   ACTOR, DO SOMETHING format.  Override this (to 3) for TELL TO
     *   grammar rules.  
     */
    actorPerson = 2
    
    /* build the tree */
    build(cmd, np)
    {
        /* if we're giving orders, tell the command which person they're in */
        if (actor_ != nil)
            cmd.actorPerson = actorPerson;

        /* 
         *   if we have a second predicate or a conjunction, note where the
         *   second predicate starts 
         */
        if (cmd2_ != nil)
        {
            /* 
             *   we have a second predicate production, so the second
             *   predicate starts with the first token of that production 
             */
            cmd.nextTokens = tokenList.sublist(cmd2_.firstTokenIndex);
        }
        else if (conj_ != nil)
        {
            /* 
             *   we don't have an explicit second predicate production, but
             *   we do have a conjunction, so the second predicate must
             *   start at the next token after the conjunction 
             */
            cmd.nextTokens = tokenList.sublist(conj_.lastTokenIndex + 1);
        }

        /* do the normal work */
        inherited(cmd, np);
    }

    /* visit a production */
    visitProd(cmd, np, prod)
    {
        /* if this is the actor, create a NounPhrase for the actor role */
        if (prod == actor_)
            np = cmd.addNounListItem(ActorRole, prod);

        /*
         *   If this is the first predicate, actor, or conjunction, build
         *   it out as usual; otherwise ignore it.  We specifically don't
         *   want to build out any command processing for a second or
         *   subsequent predicate, because we only execute the first
         *   predicate in a parse tree.  
         */
        if (prod is in (cmd_, actor_, conj_))
        {
            /* expand the token extent to include this phrase */
            if (prod.lastTokenIndex > cmd.tokenLen)
                cmd.tokenLen = prod.lastTokenIndex;

            /* do the normal work */
            inherited(cmd, np, prod);
        }
    }

    /* note the end of the sentence */
    noteEndOfSentence(cmd, prod)
    {
        /* 
         *   if the production is within the conjunction, the command ends
         *   the sentence 
         */
        if (prod == conj_ || prod.isChildOf(conj_))
            cmd.endOfSentence = true;
    }
;

/*
 *   A NounRole is a internal parser object that provides information on a
 *   given noun role in a predicate.
 *   
 *   A noun role is one of the standard semantic roles that a noun phrase
 *   can play in a natural language predicate.  A predicate is a
 *   combination of an action and the objects that it applies to.  Any
 *   given verb has a set of assigned roles that need to be filled to make
 *   a complete thought.  (Sometimes the same verb word has multiple senses
 *   with different numbers of slots to fill, but you can think of the
 *   different senses as actually being different actions at some abstract
 *   level, which all happen to share the same verb word.)  For example,
 *   TAKE requires a noun phrase telling us which object is to be taken;
 *   this is called the direct object of the verb.  PUT X IN Y has a direct
 *   object (the thing to be put somewhere) and an indirect object (the
 *   place to put it).
 *   
 *   Natural languages use a fairly small number of these noun roles.  Most
 *   predicates in most languages have just one role: TAKE, DROP, OPEN,
 *   CLOSE.  We call this first-and-only noun role the direct object.  A
 *   few predicates have two roles: PUT IN, GIVE TO, UNLOCK WITH.  We call
 *   the second role the indirect object.  A very few predicates have three
 *   roles: TRADE BOB AN APPLE FOR AN ORANGE, PUT PLUTONIUM IN REACTOR WITH
 *   TONGS.  We call the third role the "accessory" object (which is
 *   something we made up - there doesn't seem to be an agreed-upon word
 *   among linguists for this role).  And it appears that there's simply no
 *   such thing as a "tetratransitive" verb in any natural human language,
 *   so we don't bother defining a fourth slot.
 *   
 *   (It would be easy for a game to add an object defining a fourth slot,
 *   analogous with these others, and use it to include a fourth noun
 *   phrase in the grammar for applicable verbs.  The rest of the parser
 *   will pick it up automatically if you do.  However, the practical
 *   utility of this seems minimal.  *Three*-noun verbs are incredibly rare
 *   in IF, in part because situations requiring them are rare, and in part
 *   because they're almost guaranteed to vex players and be panned as
 *   guess-the-syntax puzzles.  One can only imagine how a *four*-noun
 *   command would be received.)  
 */
class NounRole: object
    /* 
     *   The -> property slot in the predicate grammar that's assigned to
     *   this role.  This is the property that predicate grammar rules
     *   assign for the match tree for a noun phrase taking this role.
     */
    matchProp = nil

    /* the NounPhrase list property in the Command object for this role */
    npListProp = nil

    /* the object match list property in the Command object for this role */
    objListProp = nil

    /* the property in the Command for the *current* item being executed */
    objProp = nil

    /* the property in the Command for the current item's NPMatch */
    objMatchProp = nil

    /*
     *   Is this a predicate noun phrase role?  This is true for roles that
     *   serve as objects of a verb: direct object, indirect object,
     *   accessory.  This is nil for non-predicate roles, such as the
     *   addressee actor. 
     */
    isPredicate = true

    /* 
     *   the predicate match object property that gives the grammar rule
     *   for parsing a reply to a missing noun question for this role 
     */
    missingReplyProp = nil

    /* 
     *   name - this is an ID string that we use internally for embedding
     *   the role in things like verb template strings 
     */
    name = ''

    /*
     *   Internal sequence number.  This tells us the order in which this
     *   role appears in lists (including argument lists) when we store
     *   lists of roles.  
     */
    order = 1000

    /* class property: master list of all roles */
    all = []

    /* class property: master list of all predicate roles */
    allPredicate = []

    /* on construction, populate the various maps */
    construct()
    {
        /* add it to our master list of roles */
        NounRole.all += self;

        /* add it to the master list of predicate roles, if applicable */
        if (isPredicate)
            NounRole.allPredicate += self;
        
        /* keep the lists in sorted order */
        NounRole.all = NounRole.all.sort(SortAsc, { a, b: a.order - b.order });
        NounRole.allPredicate = NounRole.allPredicate.sort(
            SortAsc, { a, b: a.order - b.order });
    }
;

/*
 *   The DirectObject role is the role of the object being most directly
 *   acted upon in the command.  The is the only role in a verb that has
 *   only one object.  In a verb with two objects, this is the object most
 *   directly affected.  For example, UNLOCK DOOR WITH KEY directly acts
 *   upon the door, so the door is the direct object; the key isn't the
 *   direct object because it's merely a tool used to effect the change on
 *   the door.  
 */
DirectObject: NounRole
    matchProp = &dobjMatch
    npListProp = &dobjNPs
    objListProp = &dobjs
    objProp = &dobj
    objMatchProp = &dobjInfo
    missingReplyProp = &dobjReply
    curObjProp = &curDobj
    name = 'dobj'
    order = 1
;

/*
 *   The IndirectObject role is the role of a secondary object that is used
 *   in the command, but isn't the primary object being acted upon.  This
 *   is usually a tool (UNLOCK dobj WITH iobj), a destination (PUT dobj IN
 *   iobj), or a topic (ASK dobj ABOUT iobj). 
 */
IndirectObject: NounRole
    matchProp = &iobjMatch
    npListProp = &iobjNPs
    objListProp = &iobjs
    objProp = &iobj
    objMatchProp = &iobjInfo
    missingReplyProp = &iobjReply
    curObjProp = &curIobj
    name = 'iobj'
    order = 2
;

/*
 *   The AccessoryObject role is for a *third* object, beyond the direct
 *   and indirect objects, involved in the command.  This might be a peer
 *   to the indirect object in an exchange (TRADE dobj AN iobj FOR AN
 *   accessory), but the canonical IF use is as a tool in a two-object
 *   operation (PUT dobj IN iobj WITH accessory, WRITE dobj ON iobj WITH
 *   accessory).  
 */
AccessoryObject: NounRole
    matchProp = &accMatch
    npListProp = &accNPs
    objListProp = &accs
    objProp = &acc
    objMatchProp = &accInfo
    missingReplyProp = &accReply
    curObjProp = &curAobj
    name = 'acc'
    order = 3
;

/*
 *   ActorRole is a special role for the addressee of a command (BOB, GO
 *   NORTH, or TELL BOB TO GO NORTH).  This doesn't appear as part of a
 *   predicate structure, so there's no matchProp, but it is used within
 *   the Command.  
 */
ActorRole: NounRole
    npListProp = &actorNPs
    objListProp = &actors
    objProp = &actor
    isPredicate = nil
;


/*
 *   VerbProduction is a special Production subclass for verb (predicate)
 *   rules.  This production has special processing for building out the
 *   object phrases making up the verb.
 *   
 *   Each instance should have an 'action' property giving the Action
 *   object associated with the verb rule.  This is the Action that will be
 *   performed when the parser matches the command input to the rule.
 *   
 *   Some languages, such as English, have "positional" predicate grammars.
 *   This means that the position of a noun phrase in the sentence
 *   determines its role (direct object, indirect object, etc).  In the
 *   grammar for a positional language, each predicate rule simply needs to
 *   plug in a singleNoun or nounList production (as appropriate) in each
 *   noun phrase position, with its '->' property set to correspond to the
 *   role: ->dobjMatch for a direct object, ->iobjMatch for an indirect
 *   object, and ->accMatch for an accessory object.
 *   
 *   Some languages, such as German and Latin, identify the role of a noun
 *   phrase using grammatical case.  This means that the articles change
 *   form in the different roles, or that the nouns themselves are
 *   inflected (they have different forms, such as added suffixes)
 *   according to role.  Case languages tend to have flexible predicate
 *   word order, because the case markers tell you the role of each noun
 *   even if the nouns are rearranged.  For this reason, it can be tedious
 *   to write a grammar for a case language the way we do for English,
 *   where the word ordering for a given verb is so rigid that we can
 *   easily just write out each possible phrasing manually.  For a case
 *   language, you'll probably instead want to write a set of generic verb
 *   rules that cover *all* verbs (i.e., you leave the verb word itself as
 *   a sub-production) in all of the different word orders, and use the
 *   case tagging in the language to determine the role of each noun
 *   phrase.  For this style of grammar, the grammar must set the property
 *   nounPhraseRole in the top-level rule for each noun phrase case; set
 *   this to DirectObject, IndirectObject, AccessoryObject, etc., according
 *   to the role denoted by the case.
 *   
 *   Still other languages, such as Japanese, use particles (grammar
 *   function words) to denote the role of each noun phrase in the
 *   sentence.  This is similar to grammatical case, but the role
 *   information is encoded in separate words (the particles) rather than
 *   in noun affixes, so the nouns themselves aren't inflected.  You can
 *   handle this type of language roughly the same way you'd handle a case
 *   language.  Create generic rules that cover all verbs, then create a
 *   grammar rule for each particle-plus-noun structure.  In each
 *   particle-plus-noun phrase's top-level rule, set the nounPhraseRole
 *   property to the appropriate role object (DirectObject, etc).  
 */
class VerbProduction: Production
    /*
     *   The "priority" of this grammar rule.  This is a contributor to the
     *   Command priority - see Command.priority for an explanation of how
     *   that's used.
     *   
     *   The predicate priority is a small number, 0-99.  The default is
     *   50, which should apply to most normal, complete verb phrases.  For
     *   incomplete phrases (with a missing object, which will force the
     *   parser to assume a default or ask the player for the missing
     *   information), use 25.  Other values are for fine-tuning as needed
     *   in the individual grammar rules.  A higher value means higher
     *   priority.  
     */
    priority = 50

    /* 
     *   Do we want to consider this production to be active; we may want some
     *   VerbRules to be active only under certain circumstanes.
     */
    isActive = true
    
    /* build the command */
    build(cmd, np)
    {
        /* set the action and the predicate phrase priority in the command */
        cmd.action = action;
        cmd.verbProd = self;
        cmd.predPriority = priority;
        cmd.predActive = isActive;;

        /* do the standard work */
        inherited(cmd, np);

        /* if we have a structurally empty slot, note it in the command */
        if (missingRole != nil)
            cmd.emptyNounRole(missingRole);
    }

    /*
     *   Visit a production during the build process.  If this is one of
     *   our noun phrase slots, we tell the command to add a new noun
     *   phrase of this type, and make it the current phrase; then we
     *   recursively build out this child to populate the new noun phrase.
     */
    visitProd(cmd, np, prod)
    {
        /* 
         *   If this is a special phrase slot, mark the child with its
         *   role.  This is necessary for positional languages, where the
         *   role of a noun phrase is determined by its position in the
         *   predicate.  Grammars for these languages use generic rules
         *   that apply to any noun phrases, so the match objects don't
         *   know what role they have until they find out their position in
         *   the parent grammar.  We're the parent grammar, so when we see
         *   one of these special positional markers, we need to pass the
         *   information down to the sub-tree here.  
         */
        local r;
        if ((r = NounRole.all.valWhich(
            {x: x.matchProp != nil && self.(x.matchProp) == prod})) != nil)
        {
            /* set the role in the sub-tree */
            prod.nounPhraseRole = r;

            /* start a new noun phrase for the role */
            np = prod.addNounListItem(cmd, prod);
        }

        /* 
         *   build out the child, in the context of the noun phrase we
         *   decided upon 
         */
        prod.build(cmd, np);
    }

    /*
     *   The parser calls answerMissing() when the player answers a query
     *   for a missing noun phrase in the last command.  There's nothing
     *   that needs to happen here, and by default we do nothing; this is
     *   purely advisory.  This routine gives the language module a chance
     *   to alter the command according to the reply, if necessary.  
     */
    answerMissing(cmd, np) { }
;

/*
 *   NounListProduction is a special Production subclass for lists
 *   including more than one noun.
 *   
 *   Each instance should have two '->' properties: np1_ and np2_.  These
 *   should be set to the match sub-tree for the first and second elements
 *   of the noun list (respectively).  Note that we assume there are only
 *   two elements in each list grammar item - this isn't because we want to
 *   limit noun lists to two elements, but rather because we assume that
 *   the grammars for longer lists will be constructed recursively out of
 *   two-element nodes: A, B, C, D becomes something along the lines of
 *   List(a, List(b, List(c, List(d)))).  
 */
class NounListProduction: Production
    /*
     *   Visit a production during the build process.  When parsing the
     *   second element, we'll add a new NounPhrase to the current slot's
     *   list.  
     */
    visitProd(cmd, np, prod)
    {
        /* if this is the second list item, add a new NounPhrase for it */
        if (prod == np2_)
            np = prod.addNounListItem(cmd, prod);

        /* for noun phrases, tell the noun phrase about the production */
        if (prod is in (np1_, np2_))
            np.prod = prod;

        /* do the normal work */
        inherited(cmd, np, prod);
    }
;

/*
 *   A BadListProduction is a Production subclass for a noun list written
 *   in a slot intended for a single noun only.  This isn't really a
 *   grammatical error, so the language grammar will probably want to
 *   include a rule for this.  However, it *is* a semantic error; rules
 *   that are written for single objects are written that way because we
 *   can't make sense of a list there.  For example, PUT BOOK IN BOX AND
 *   BAG would be nonsensical to us, because we can't put something in two
 *   places at once.  This class can be used for a grammar rule that parses
 *   a list where a single noun is required; we'll flag it with an
 *   explanatory error message for the user.  
 */
class BadListProduction: Production
    build(cmd, np)
    {
        /* mark the command with the list-in-single-slot error */
        cmd.badMulti = getNounPhraseRole();

        /* do the normal work */
        inherited(cmd, np);
    }
;

/*
 *   ExceptListProduction is a Production subclass for EXCEPT lists.  This
 *   is a slot in the grammar that holds a list of objects excepted from
 *   some set, as in ALL BUT THE RED BOOK or THE COINS EXCEPT THE PENNIES.
 */
class ExceptListProduction: Production
    /*
     *   Build this phrase.  Our sub-tree is a noun list that's to be
     *   excluded from the current noun phrase under construction, 'np';
     *   this exclusion list is a type of qualifier.  So, we (a) start an
     *   exception qualifier for 'np', (b) make that list the current noun
     *   phrase within our sub-tree, then (c) do the normal work to build
     *   out our sub-tree, but using the new context.  
     */
    build(cmd, np)
    {
        /* 
         *   remember the noun phrase that we qualify - this is simply the
         *   parent noun phrase, np 
         */
        qualifiedNP = np;

        /* 
         *   start an exclusion list for the noun phrase; make the first
         *   element of the new list the active noun phrase for our
         *   sub-tree 
         */
        np = np.addExclusionItem(self);

        /* do the normal work */
        inherited(cmd, np);
    }

    /*
     *   Add a noun list item.  List items within our sub-tree go into the
     *   exclusion list for the parent noun phrase that we qualify.  
     */
    addNounListItem(cmd, prod)
    {
        /* add a new noun phrase to the qualified NP's exclusion list */
        return qualifiedNP.addExclusionItem(prod);
    }

    /* the noun phrase we qualify */
    qualifiedNP = nil
;

/*
 *   CoreNounPhraseProduction is a Production subclass for the "core" noun
 *   phrase grammar for noun phrases with object vocabulary.  This is the
 *   part of the grammar that matches the basic name of an object, after
 *   all qualifiers (such as articles, possessives, and quantifiers) have
 *   already been dealt with.  This is the part of the phrase that contains
 *   the vocabulary words for game-world objects.
 *   
 *   This class is only needed for noun phrases with object vocabulary
 *   words.  It captures the unqualified core of the phrase as entered by
 *   the user, mostly for reiteration in error messages from the parser.
 *   It's not necessary to define rules of this class for noun phrases that
 *   don't have object vocabulary words (e.g., pronouns, ALL).  
 */
class CoreNounPhraseProduction: Production
    build(cmd, np)
    {
        /* note in the NounPhrase that this is the core noun phrase */
        np.coreProd = self;

        /* do the normal work */
        inherited(cmd, np);
    }
;

/*
 *   EmptyNounProduction is a Production subclass for a grammar rule that
 *   matches no tokens where a noun phrase would ordinarily go.  
 */
class EmptyNounProduction: Production
    build(cmd, np)
    {
        /* mark the noun phrase role as empty in the command */
        cmd.emptyNounRole(np.role);
    }
;

/*
 *   NumberNounProduction is a Production subclass for a number that serves
 *   as a direct, indirect, or accessory object.  
 */
class NumberNounProduction: Production
    /* we use the NumberPhrase subclass for a noun phrase entries */
    npClass = NumberPhrase
;

/*
 *   TopicNounProduction is a Production subclass for a topic that serves
 *   as a direct, indirect, or accessory object.  
 */
class TopicNounProduction: Production
    /* we use the TopicPhrase subclass for a noun phrase entries */
    npClass = TopicPhrase
;

/*
 *   LiteralNounProduction is a Production subclass for a literal phrase
 *   that serves as a direct, indirect, or accessory object. 
 */
class LiteralNounProduction: Production
    /* we use the LiteralPhrase subclass for a noun phrase entries */
    npClass = LiteralPhrase
;

/*
 *   PronounProduction is a Production subclass for pronoun phrases.
 *   Each instance should set the property 'pronoun' to a Pronoun object
 *   giving the pronoun role for the phrase.  
 */
class PronounProduction: Production
    /*
     *   Build the phrase.  We'll add our pronoun association to the
     *   current noun phrase.  (We'll also build out any sub-tree, although
     *   in nearly all cases a pronoun phrase is just a literal and won't
     *   have a sub-tree.) 
     */
    build(cmd, np)
    {
        /* set the pronoun association in the noun phrase */
        np.pronoun = pronoun;

        /* do the normal work */
        inherited(cmd, np);
    }
;

/*
 *   A PossessiveProduction is a production subclass for possessive
 *   qualifier phrases ("John's", "my").  When we build out this
 *   production's contribution to the command, we add a separate NounPhrase
 *   object for it, as a possessive qualifier to the current noun phrase.  
 */
class PossessiveProduction: Production
    /*
     *   Build the phrase.  We'll build out our sub-tree as normal, except
     *   that we'll assign its output to a new NounPhrase, which we attach
     *   as a possessive qualifier to the encompassing noun phrase under
     *   construction.  
     */
    build(cmd, np)
    {
        /* 
         *   create a new noun phrase to serve as a possessive qualifier to
         *   the current noun phrase 
         */
        np = np.addPossessive(self);

        /* if I have a pronoun, set it in the noun phrase */
        np.pronoun = pronoun;

        /* do the normal work in the context of the possessive qualifier */
        inherited(cmd, np);
    }
;

/*
 *   ContentsQualifierProduction is a subclass of Production for phrases
 *   that involve contents qualifiers, as in "the bucket of water".
 *   
 *   Each grammar rule of this type needs to define two special '->'
 *   associations in its template:
 *   
 *   cont_ is the contents qualifier.  This is also just an ordinary noun
 *   phrase.  This is the "water" part in "bucket of water".
 *   
 *   prep_ is the preposition giving the relationship. 
 */
class ContentsQualifierProduction: Production
    /*
     *   Visit a production.  When we process the contents qualifier
     *   phrase, we'll build out the sub-tree in the context of a new
     *   NounPhrase, which we attach as a contents qualifier to the
     *   encompassing noun phrase under construction.  
     */
    visitProd(cmd, np, prod)
    {
        /* 
         *   if this sub-production is the contents qualifier phrase,
         *   create a new locational qualifier for it 
         */
        if (prod == cont_)
            np = np.addContents(prep_.getText(), prod);

        /* do the normal work in the context of the noun phrase we set up */
        inherited(cmd, np, prod);
    }
;
    

/*
 *   LocationalProduction is a subclass of Production for phrases that
 *   involve locational qualifiers, as in "the book on the table".
 *   
 *   Each grammar rule of this type needs to define two special '->'
 *   associations in its template:
 *   
 *   cont_ is the locational qualifier.  This is also just an ordinary noun
 *   phrase.  This is the "the table" part in "the book on the table".
 *   
 *   prep_ is the preposition production.  This should be *or* contain a
 *   LocationTypeProduction match, which tells us the type of containment
 *   relationship specified by the grammar.  *Alternatively*, you can
 *   define locType directly on this production.  This specifies a LocType
 *   object giving the containment relationship.  
 */
class LocationalProduction: Production
    /*
     *   Visit a production.  When we process the locational qualifier
     *   phrase, we'll build out the sub-tree in the context of a new
     *   NounPhrase, which we attach as a locational qualifier to the
     *   encompassing noun phrase under construction.  
     */
    visitProd(cmd, np, prod)
    {
        /* 
         *   if this sub-production is the locational qualifier phrase,
         *   create a new locational qualifier for it 
         */
        if (prod == cont_)
        {
            /* add the location to the noun phrase */
            np = np.addLocation(locType, prod);

            /* 
             *   explicitly build out the preposition sub-tree in the
             *   context of the locational noun phrase - this ensures that
             *   the locType gets set for the locational rather than the
             *   base noun phrase 
             */
            if (prep_ != nil)
                prep_.build(cmd, np);
        }            

        /* 
         *   we already built the prep_ subtree explicitly in build(), so
         *   we can ignore it if we're hitting it again here 
         */
        if (prod == prep_)
            return;

        /* do the normal work in the context of the noun phrase we set up */
        inherited(cmd, np, prod);
    }

    /*
     *   Our location type.  This is a LocType object giving the location
     *   relationship specified by this locational phrase.  For languages
     *   that special locational phrases prepositionally, this will be set
     *   by the LocationPrepProduction in our sub-tree.  For languages that
     *   use case inflection to specify the type of relationship, this must
     *   be set by the noun phrase sub-tree instead.  
     */
    locType = nil
;

/*
 *   A LocationPrepProduction is a special Production type for phrases that
 *   encode the preposition of a locational phrase.  This is only needed in
 *   languages that use prepositional grammar to express location
 *   relationships.  For languages that use noun case inflection, the
 *   relationship will have to be inferred from the case grammar of the
 *   noun phrase (such as noun affixes or articles), and the noun phrase
 *   production will have to set the locType in the LocationalProduction.
 *   
 *   Set the locType property to the LocType object corresponding to the
 *   location relationship of the preposition.  
 */
class LocationPrepProduction: Production
    /* our location relationship type, as a LocType object */
    locType = nil

    /* 
     *   on building the production, set the locType in our
     *   LocationalProduction parent 
     */
    build(cmd, np)
    {
        /* set the location type on the noun phrase */
        np.locType = locType;
        
        /* do the normal work */
        inherited(cmd, np);
    }
;    

/*
 *   QuantifierProduction is a subclass of Production for phrases that add
 *   a number qualifier, as in "five books".
 *   
 *   Each grammar rule of this type needs to define a special '->quant_'
 *   association in its template, giving the quantity phrase production.
 *   This phrase must in turn provide a 'numval' property giving its
 *   numeric value. 
 *   
 *   Alternatively, this production can itself simply provide a 'numval'
 *   property with the correct number.  This is convenient for
 *   adjective-like qualifier phrases that imply a number without stating
 *   one directly, such as BOTH BOOKS.  
 */
class QuantifierProduction: Production
    /*
     *   Build out the subtree.  If we have a numval embedded in this
     *   production, we'll use it as the quantifier.  Otherwise, we'll
     *   expect to find a separate quant_ sub-production among our
     *   children, and that it provides the quantity.  
     */
    build(cmd, np)
    {
        /* if we have our own numval value, apply it as the quantifier */
        if (numval != nil)
            np.addQuantifier(numval);

        /* do the normal work */
        inherited(cmd, np);
    }

    /*
     *   Visit a production.  When we visit the quantifier phrase, we'll
     *   handle it specially: we'll add the quantifier value to the main
     *   noun phrase, and then we *won't* parse into the subtree.  There's
     *   no need to parse the quantifier subtree, as its entire meaning is
     *   captured in its numeric value.  Parsing into it is undesirable
     *   because that would add the numeric tokens to the noun phrase -
     *   they don't belong there, since their qualification is captured in
     *   the quantifier and shouldn't also be added as adjectives.  
     */
    visitProd(cmd, np, prod)
    {
        /* if this is the quantifier, handle it specially */
        if (prod == quant_)
        {
            /* add the quantifier to the noun phrase */
            np.addQuantifier(prod.numval);

            /* note that we explicitly DON'T parse into the subtree */
        }
        else
        {
            /* do the inherited work */
            inherited(cmd, np, prod);
        }
    }
;

/*
 *   OrdinalProduction is a subclass of Production for ordinal phrases
 *   ("first", "second", etc).  The match object must define a method
 *   ordval() that returns the integer value of the ordinal (1 for "first",
 *   2 for "second", etc).  
 */
class OrdinalProduction: Production
    build(cmd, np)
    {
        /* apply the ordinal value to the noun phrase */
        np.addOrdinal(ordval);

        /* 
         *   we don't want to build out the subtree, since we don't want to
         *   treat literals as vocabulary words for this type of phrase 
         */
    }
;

/*
 *   MiscWordListProduction is a subclass of Production for miscellaneous
 *   word list rules.  These are grammar rules of last resort, for matching
 *   text that's positionally where a noun phrase ought to be, but which
 *   doesn't match any of our other rules for constructing a valid noun
 *   phrase.  These rules let us still recognize the overall verb-phrase
 *   structure of a command, even though we can't make sense of what goes
 *   where the nouns ought to be.  
 */
class MiscWordListProduction: Production
    build(cmd, np)
    {
        /* tell the Command that it contains a misc word list */
        cmd.noteMiscWords(np);

        /* do the normal work */
        inherited(cmd, np);
    }
;

/*
 *   An OopsProduction is a subclass for the word list part of an OOPS
 *   command.  This must have a ->toks_ property that holds the sub-tree
 *   for the literal token list of the correction. 
 */
class OopsProduction: Production
    /* 
     *   Class method: apply the correction for an OOPS command to an
     *   original token list.
     */
    applyCorrection(prod, toks, typoIdx)
    {
        /* build the tree into an OopsCommand object */
        local cmd = new OopsCommand();
        prod.build(cmd, nil);

        /* 
         *   splice the corrected tokens into the original token list,
         *   replacing the unknown word token, and return the result 
         */
        return toks.splice(typoIdx, 1, cmd.tokens...);
    }

    /* build the command */
    build(cmd, np)
    {
        /* add the token list of the correction to the command */
        cmd.tokens += toks_.getTokens();
    }
;

/*
 *   An OopsCommand is a fake Command object for building out an Oops tree.
 */
class OopsCommand: object
    /* the token list: this is filled in when we build the Oops nodes */
    tokens = []
;

/*
 *   DisambigProduction is a subclass of Production for the root of a
 *   disambiguation reply tree grammar. 
 */
class DisambigProduction: Production
    addNounListItem(cmd, prod)
    {
        /* 
         *   add the new item to the disambig reply list for the original
         *   noun phrase 
         */
        return cmd.addDisambigNP(prod);
    }
;

/*
 *   Production class for Yes-or-No phrases 
 */
property yesOrNoAnswer;
class YesOrNoProduction: Production
    build(cmd, np)
    {
        /* set the yes/no answer property in the Command */
        cmd.yesOrNoAnswer = answer;

        /* do the normal work */
        inherited(cmd, np);
    }
;

/* ------------------------------------------------------------------------ */
/*
 *   Base class for pronouns.  We represent each type of pronoun with an
 *   object, to abstract pronouns away from the vocabulary.
 *   
 *   The base library defines a set of pronouns that are common to most
 *   languages: It, Him, Her, Them, You, Y'all, Me, and Us, plus reflexive
 *   forms of It, Him, Her, and Them.  Some languages might not employ all
 *   of these (French, for example, has no neuter gender, so there's no
 *   equivalent of It), and some might need additional pronouns (e.g.,
 *   French needs a feminine third-person plural).  If a pronoun we define
 *   here has no equivalent in a given language, the language module should
 *   simply omit any grammar mentioning it.  If the language has pronouns
 *   that aren't in the basic set, the language module can provide
 *   definitions for its own additional Pronoun objects, along with the
 *   corresponding grammar rules.
 *   
 *   The library itself only directly references one pronoun object: You.
 *   The parser specifically references this pronoun because it binds to
 *   the addressee of a command, which has a special role in the parsing
 *   process.  Apart from You, though, the library's use of pronouns is
 *   directed by the grammar: if a given Pronoun doesn't appear in the
 *   grammar anywhere, the library will never use it.  (Other than in
 *   iterations over Pronoun instances, anyway; but these will be harmless
 *   because the parser is just trying to be inclusive.)  This means that
 *   language modules are free to ignore pronouns (other than You) from the
 *   standard set when they're not a good match for the language's needs.
 *   For example, if you need distinct Animate and Inanimate forms of Him
 *   and Her, you could simply define four new Pronoun objects for these
 *   forms, and use them in place of Him and Her throughout your grammar.  
 *   
 *   Note that these objects are NOT grammar rules or dictionary words.
 *   These are abstract objects representing the "binding" of the pronouns
 *   - basically the set of grammatical attributes (gender, number) that
 *   determine whether a given noun phrase is a valid antecedent for a
 *   given pronoun.  That's why we don't define separate Pronoun objects
 *   the different grammatical cases (nominative, accusative, dative, etc):
 *   case is a feature of the grammar, and we're one step removed from that
 *   here.  
 */
class Pronoun: object
    /*
     *   Resolve the pronoun during parsing.  The usual way of doing this
     *   is to return the list of antecedents we store as part of the
     *   pronoun object.  This lets each type of pronoun store an
     *   appropriate list of antecedents.
     *   
     *   For a reflexive pronoun, return the Pronoun object for the
     *   ordinary form of the pronoun.  This tells the parser that it needs
     *   to find a match for the pronoun within the command itself, rather
     *   than looking for an external antecedent.  Second person is
     *   inherently reflexive, in that it refers to the addressee(s), so
     *   this should return 'self' for a second-person pronoun.  
     */
    resolve() { return ante; }

    /* 
     *   The grammatical person of the pronoun.  Pronouns come in three
     *   persons: first (me, us), second (you), and third (her, them).  We
     *   represent these as 1, 2, and 3.  
     */
    person = 3

    /* 
     *   Set the antecedent(s) for future pronoun usage based on the
     *   objects mentioned in the current command input or narrative
     *   output.  'obj' can be a single antecedent object, or it can be a
     *   list.  Even a singular pronoun can have a list of antecedents:
     *   some commands have more than one noun phrase, and there's no way
     *   of knowing which one the user might want to refer to with a
     *   pronoun in a future command.  We can't know until we see the
     *   context of the future pronoun use.  For example, UNLOCK DOOR WITH
     *   KEY could be followed by OPEN IT, in which case IT is probably the
     *   door; or by DROP IT, in which case IT is probably the key.  The
     *   best thing to do is to save both the door and the key as possible
     *   antecedents, so that we can choose the most suitable object when
     *   we actually see a pronoun in a subsequent command.  
     */
    setAntecedents(obj){ ante = obj; }

    /*
     *   Does this pronoun match the given object or list of objects?  By
     *   default, we won't match lists, and we'll ask the object if it
     *   thinks we're a match.  
     */
    matchObj(obj)
    {
        return !obj.ofKind(Collection) && obj.matchPronoun(self);
    }

    /* my antecedent or list of antecedents */
    ante = []

    /* 
     *   the corresponding reflexive pronoun, if any - this is set up
     *   automatically during preinit 
     */
    reflexive = nil

    /* 
     *   Class property - list of all regular Pronoun objects.  (Note that
     *   this excludes the reflexive pronouns, because the ReflexivePronoun
     *   class has its own separate 'all' list for its instances.)  
     */
    all = []

    /* on initialization, add me to the master list of pronoun objects */
    construct()
    {
        /* get the nearest class that has a master list */
        local cl = propDefined(&all, PropDefGetClass);

        /* add me to my class's master list */
        cl.all += self;
    }
;

/* It - third-person neuter singular */
It: Pronoun
;

/* Her - third-person feminine singular */
Her: Pronoun
;

/* Him - third-person masculine singular */
Him: Pronoun
;

/* Them - third-person mixed-gender plural */
Them: Pronoun
    /* 
     *   Them is a plural, so it can match a list, as well as an individual
     *   object that matches Them 
     */
    matchObj(obj)
    {
        return obj.ofKind(Collection) || obj.matchPronoun(self);
    }
;

/* 
 *   You - the second-person singular.  YOU always binds to the addressee
 *   of the command: either the player character, or the actor being given
 *   orders via a construct like ACTOR, DO THIS.
 *   
 *   Binding to the PC is grammatically correct in a first-person
 *   narration, because the PC is the narrator's ME and therefore the
 *   player's YOU.  It's less so in a second-person game: the PC is the
 *   narrator's YOU, so the player's YOU ought to be the narrator.
 *   However, some players are literal-minded about second-person
 *   narration, so rather than reflecting the narrator's YOU into the
 *   player's ME, they simply say YOU too.  Fortunately, there's not any
 *   serious ambiguity here.  The narrator is typically not a game-world
 *   object, but is an entity that exists outside the game world, so it's
 *   off-limits for discussion in commands.  So YOU can't mean the
 *   narrator.  That means that if the player uses YOU at all, they must
 *   mean the PC.  
 */
You: Pronoun
    /* 
     *   The second-person pronoun binds to information contained within
     *   the command itself, namely the addressee of the command, so we
     *   need to resolve it using the parser's "late binding" scheme.  That
     *   is, we return 'self' to tell the parser that it needs to go back
     *   and resolve this pronoun after resolving other phrases.  
     */
    resolve() 
    { 
        /* 
         *   But if no other actor has been specified, 'YOU' must mean 'ME',
         *   i.e. the player character
         */
             
        if(gCommand && gCommand.actorNPs == [] && gCommand.actorPerson == 2)
            return [gPlayerChar];
        
        return [self]; 
    }

    /* this is a second-person pronoun */
    person = 2
;

/*
 *   Y'all - the second-person plural.  ("Y'all" isn't exactly standard
 *   English, but it's as close as English comes to having a distinct
 *   plural You, and we had to call this *something*.)
 *   
 *   By default, we treat Y'all as a synonym for You, since there's rarely
 *   any reason in an IF context to distinguish them.  The main value in
 *   natural language is in group conversation, where it can be useful to
 *   clarify whether the speaker is addressing the whole group or just an
 *   individual.  In IF, though, this is never ambiguous: the addressee is
 *   either explicitly stated in the command, or it's the player character.
 *   The only thing we could do with a plural is check that the verb agrees
 *   in number, and chastise the player's sloppy grammar if not.  But that
 *   would be contrary to our general philosophy that we should be as lax
 *   as we can about the input grammar, to minimize the player's typing
 *   workload.  So our advice here is to implement a grammar rule for the
 *   various YOUs that treats all of the second-person pronoun forms as
 *   synonyms for the basic singular YOU.  
 */
Yall: Pronoun
    resolve() { return You.resolve(); }
    person = 2
;

/*
 *   Me - the first-person singular.  ME always binds to the player
 *   character.
 *   
 *   The discussion about the validity of binding YOU to the PC applies in
 *   mirror image here.  In a second-person game, the PC is the narrator's
 *   YOU and the player's ME; in a first-person game, she's the narrator's
 *   ME and the player's YOU.  But there is no game-world object for ME to
 *   bind to in commands in a first-person game - if anything, ME would be
 *   the player (not the player character, but the actual player), who is
 *   clearly not a game-world entity.  Since that's not meaningful, we can
 *   assume that a player talking about ME in a first-person game is being
 *   literal-minded and just using the same pronouns the narrator does, or
 *   that they're so accustomed to the second-person convention of most IF
 *   that they're saying ME out of habit.  In either case, the PC is the
 *   one they're talking about.  
 */
Me: Pronoun
    /* 
     *   the first person always resolves to the player character,
     *   regardless of context 
     */
    resolve() { return [libGlobal.playerChar]; }

    /* this is a first-person pronoun */
    person = 1
;

/* 
 *   Us - the first-person plural.  We throw this one in for relative
 *   completeness, but we simply treat it as a synonym for Me.  This could
 *   be useful in a game with a PC that represents a group of people (an
 *   adventuring party in a hack-n-slash game, say), or a royal personage.
 *   
 *   A more sophisticated use would be to allow the player to refer
 *   collectively to the PC and a group of accompanying NPCs.  The base
 *   library doesn't implement this because it doesn't define a way to
 *   identify such a group, but a game could add that capability.  Once
 *   you've defined what US means, you could make the pronoun US bind to
 *   that group simply by modifying the resolve() method here.  
 */
Us: Pronoun
    resolve() { return Me.resolve(); }
;


/*
 *   Base class for reflexive pronouns.  These are pronouns like "himself"
 *   that specifically refer to an antecedent in the same sentence, rather
 *   than to an earlier sentence: ASK BOB ABOUT HIMSELF is an inquiry about
 *   Bob, while ASK BOB ABOUT HIM refers to some male antecedent from an
 *   earlier statement.  
 *   
 *   Note that the first- and second-person reflexives are generally not
 *   needed in the parser.  (We define them here anyway, because they're
 *   useful for message generation.)  The third-person reflexive pronouns
 *   have distinct meanings in input from the corresponding ordinary
 *   pronouns, in that they refer to noun phrases within the same command
 *   rather than in earlier exchanges.  In contrast, the second-person
 *   pronouns have the same meaning in ordinary and reflexive forms, at
 *   least within the confines of the IF parser: EXAMINE ME and EXAMINE
 *   MYSELF mean the same thing in all typical IF command syntax.
 */
class ReflexivePronoun: Pronoun
    /* during construction, set the regular pronoun to point back at me */
    construct()
    {
        inherited();
        pronoun.reflexive = self;
    }

    /*
     *   A reflexive pronoun binds to another noun phrase contained in the
     *   same command, so we resolve using the parser's "late binding"
     *   scheme.  We invoke this by returning the ordinary (non-reflexive)
     *   pronoun object representing the attributes that we match; upon
     *   seeing this, the parser will know to come back to this pronoun
     *   after it's finished resolving earlier phrases, and look for the
     *   appropriate pronoun binding within those other phrases.  
     */
    resolve() { return pronoun; }

    /*
     *   Get the corresponding ordinary (non-reflexive) form of the
     *   pronoun.  For example, for HIMSELF we'd return HIM.  
     */
    pronoun = nil

    /* my grammatical person is the same as my underlying pronoun's */
    person = (pronoun.person)

    /* 
     *   Class property - list of all reflexive pronoun objects.  This
     *   keeps the reflexive pronouns in a separate list from the base
     *   Pronoun list.  
     */
    all = []
;

/* first-person singular reflexive */
Myself: ReflexivePronoun
    pronoun = Me
;

/* second-person singular reflexive */
Yourself: ReflexivePronoun
    pronoun = You
;

/* third-person singular neuter reflexive */
Itself: ReflexivePronoun
    pronoun = It
;

/* third-person singular feminine reflexive */
Herself: ReflexivePronoun
    pronoun = Her
;

/* third-person singular masculine reflexive */
Himself: ReflexivePronoun
    pronoun = Him
;

/* first-person plural reflexive */
Ourselves: ReflexivePronoun
    pronoun = Us
;

/* second-person plural reflexive */
Yourselves: ReflexivePronoun
    pronoun = Yall
;

/* third-person mixed-gender plural reflexive */
Themselves: ReflexivePronoun
    pronoun = Them
;


/* ------------------------------------------------------------------------ */
/*
 *   Determiners.  A determiner qualifies a noun phrase with information on
 *   how it relates to the objects it describes.  For example, "a book"
 *   refers to any book that's in scope for the discussion (in IF terms,
 *   this is usually any book that's physically present), while "the book"
 *   refers to some specific single book.
 *   
 *   Language modules can add determiners as needed.  For example, a
 *   language with grammatical gender would probably find gendered versions
 *   of Definite and Indefinite useful, to represent the use of gendered
 *   articles in input.
 */
class Determiner: object;

/* Unqualified mode ("book") */
Unqualified: Determiner;

/* Definite mode ("the book", "book", "both books", "the three books") */
Definite: Determiner;

/* Indefinite mode ("a book", "any book", "one of the books", three books") */
Indefinite: Determiner;

/* All ("the books", "all", "all of the books") */
All: Determiner;


/* ------------------------------------------------------------------------ */
/*
 *   ParseError is an Exception subclass for parsing errors. 
 */
class ParseError: Exception
    /*
     *   Display the error message
     */
    display() { "Unknown parsing error."; }

    /*
     *   Rank a spelling correction candidate for input that triggered this
     *   error on parsing.
     *   
     *   'toks' is the new token list, with the spelling correction
     *   applied; 'idx' is the index in the list of the corrected word.
     *   'dict' is the Dictionary used for parsing.
     *   
     *   Returns an integer value giving the ranking.  The ranking is used
     *   for sorting, so the scale is arbitrary - we simply take the
     *   highest ranking item.  The value 0 is special, though: it means
     *   that we should filter out the candidate and not consider it at
     *   all.  
     */
    rankCorrection(toks, idx, dict) { return 1; }

    /*
     *   Is this error allowed on a spelling correction candidate?  By
     *   default, this is nil, meaning that this error invalidates a
     *   correction candidate.  We mostly reject spelling "corrections"
     *   that result in errors because these are probably false positives:
     *   they probably replace a misspelled word with one that's in the
     *   dictionary but that's still wrong.  However, there are a few
     *   curable errors where it can make sense to keep a correction, such
     *   as an ambiguous noun phrase: that's so close to being a working
     *   command that we probably have a good correction.  
     */
    allowOnRespell = nil

    /*
     *   Is this a "curable" error?  A curable error is one that the user
     *   can fix by answering a question, such as "which one do you mean?"
     *   or "what do you want to unlock it with?"
     *   
     *   When we find more than one grammar match to an input string, the
     *   parser tries resolving each one, in order of the predicate match
     *   quality.  If one resolves without an error, the parser stops and
     *   uses that match.  But if *none* of the possible matches resolve
     *   without an error, the parser picks a match with a curable error
     *   over one with an incurable error.  
     */
    curable = nil

    /*
     *   Try curing this error with the user's answer to the error message.
     *   The parser calls this when (a) the PREVIOUS command resulted in
     *   this error, (b) this error is curable, and (c) the user typed
     *   something on the CURRENT command that didn't parse as a valid new
     *   command.  Since the new input doesn't look like a valid command,
     *   the parser calls this to determine if the input was instead meant
     *   as an answer to the question posed by the last error.
     *   
     *   If this new command is indeed a valid response to the error
     *   message, we return a CommandList with the "cured" version of the
     *   command.  This new command list should supplement the command with
     *   the new information provided by the reply.  If not, we simply
     *   return nil.  
     */
    tryCuring(toks, dict) { return nil; }

    /*
     *   The parsing "stage" of this error.  We can distinguish three
     *   levels of intelligibility as we work through the parsing process:
     *   (1) completely unintelligible, (2) valid verb structure, and (3)
     *   resolved noun phrases.  This property tells us which stage we
     *   finish in when we encounter an error of this type.
     */
    errStage = 1
;

/*
 *   The basic command-level parsing error.  This occurs when we can't find
 *   a grammar match to the overall command phrasing. 
 */
class NotUnderstoodError: ParseError
    display()
    {
        /*
         *   We couldn't parse a command.  This means that we were unable
         *   to find any grammar match for the input, so we basically have
         *   no idea what the player was trying to say.  
         */
        DMsg(not understood, 'I don\'t understand that command.');        
    }

    /* 
     *   This is a general verb syntax error, so our best candidates will
     *   words that are used in verb phrases.  The next best is a corrected
     *   word that's used in any GrammarProd, since the problem might
     *   actually be in some other structural part of the command phrase
     *   above the verb phrase (a conjunction, for example).  
     */
    rankCorrection(toks, idx, dict)
    {
        /* get the text of the token */
        local txt = getTokVal(toks[idx]);

        /* look up the word in the action vocabulary table */
        local w = actionDictionary.wordToAction[txt];
        if (w != nil)
        {
            /* get the highest spelling priority of the matching actions */
            local maxAct = w.maxVal({ a: a.spellingPriority });

            /* 
             *   Look for other words in the token list that are also in
             *   this words associated word list.  (For example, if the
             *   candidate is 'up', look for words like 'pick', 'go', or
             *   'look' that occur in the same verb rules with 'up'.) 
             */
            local xlst = actionDictionary.xwords[txt] - txt;
            local xbonus = (toks.indexWhich(
                { t: xlst.indexOf(getTokVal(t)) != nil }) != nil);

            /* 
             *   Give this a high rating, with the action priority and
             *   associated word bonuses to break ties.
             */
            return 200 + maxAct*2 + (xbonus ? 1 : 0);
        }

        /* okay, no predicate; how about any other GrammarProd word? */
        w = dict.findWord(txt);
        if (w.indexWhich(
            { x: dataType(x) == TypeObject && x.ofKind(GrammarProd) }) != nil)
            return 100;

        /* 
         *   No luck on any of our preferences; give it our lowest rank.
         *   We still want to allow it to be considered, so give it a
         *   non-zero rank. 
         */
        return 1;
    }
;

/*
 *   An UnknownWordError points out a word that's not in the game's
 *   dictionary. 
 */
class UnknownWordError: ParseError
    construct(txt)
    {
        self.badWord = txt;
    }

    display()
    {
        /*
         *   The command contains a word that's not in the dictionary.
         *   This error is only used when the parser is set to admit to
         *   unknown words, and only when we fail to parse the command.
         *   (It's possible for a command to succeed even when it contains
         *   words that aren't in the dictionary, since objects and topics
         *   can sometimes match arbitrary input.)  
         */
        DMsg(unknown word, 'I don\'t know the word "{1}".', badWord);

    }

    /* the text of the unknown word */
    badWord = nil
;

/* 
 *   OopsError is the base class for errors in an OOPS command.
 */
class OopsError: ParseError
;

/*
 *   A CantOopsError means that the player typed OOPS when we don't have a
 *   previous command typo we can correct.  
 */
class CantOopsError: OopsError
    display()
    {
        /*
         *   The player typed an OOPS command, but we don't have anything
         *   from a past command that we can correct.  This means that
         *   either the last command succeeded, or that it simply didn't
         *   contain any non-dictionary words. 
         */
        DMsg(no oops now, 'Sorry, I\'m not sure what you\'re correcting.');
    }
;


/*
 *   A CommandError is an error in parsing that occurs within the build
 *   process for a Command object.  
 */
class CommandError: ParseError
    construct(cmd)
    {
        /* remember the command */
        self.cmd = cmd;
    }

    /* the Command object where the error occurred */
    cmd = nil

    /* 
     *   these errors occur once we have a valid predicate structure, so
     *   we're in stage 2 of the parsing when we encounter an error of this
     *   type 
     */
    errStage = 2
;

/*
 *   Rejected parsing structure.  There are certain structures that are
 *   hard to eliminate in the grammar, but which we don't want to accept
 *   semantically.  This error can be thrown when such a structure is
 *   encountered.  This effectively rules out a parse tree.  It's not a
 *   displayable error; the parser simply rules out these structures.  
 */
class RejectParseTreeError: CommandError
    display()
    {
        /* 
         *   users should never see this error - it should be handled
         *   internally to the library 
         */
        "\n(Internal: Parse tree rejected.)\n";
    }
;

/*
 *   Empty noun slot error.  This occurs when there are no noun phrases in
 *   a functional slot in the predicate (e.g., when the player types "TAKE"
 *   without a direct object).  
 */
class EmptyNounError: CommandError
    construct(cmd, role)
    {
        inherited(cmd);
        self.role = role;
    }

    /* our message is a missing noun query (e.g., "What do want to open?") */
    display()
    {
        askMissingNoun(cmd, role);
    }

    /*
     *   Try curing the error.  After a missing noun query, the player can
     *   respond with a simple noun phrase answering the question. 
     */
    tryCuring(toks, dict)
    {
        /* try parsing against the appropriate reply grammar */
        local lst = new CommandList(
            cmd.verbProd.missingRoleProd(role), toks, dict,
            new function(prod)
        {
            /* create a copy of the original command */
            local newCmd = cmd.clone();
            
            /* plug the new noun phrase tree into the empty role */
            newCmd.addNounProd(role, prod);
                        
            /* the new command is the mapped list entry */
            return newCmd;
        });

        /* accept curable resolutions as replies */
        lst.acceptCurable();

        /* return the list */
        return lst;
    }

    /* we can cure by asking the player for the missing noun phrase */
    curable = true
;



/*
 *   Noun phrase resolution error.  This is a special type of parsing error
 *   that indicates that the problem is with resolving a noun phrase to
 *   game-world objects.  
 */
class ResolutionError: ParseError
    construct(np)
    {
        /* do the normal work */
        inherited();
        
        /* save the noun phrase */
        self.np = np;

        /* note the error-display text of the noun phrase */
        self.txt = np.errName;
    }

    /* the NounPhrase object for the errant phrase, if available */
    np = nil

    /* the text of the errant phrase, if available */
    txt = nil

    /*
     *   For a noun resolution error, our best bet for a spelling
     *   correction would be a word associated with a game-world object.
     *   Only consider in-scope objects when making the correction, to
     *   avoid spurious corrections that give away information on objects
     *   the player has yet to encounter.  We'll also allow words that are
     *   used in non-predicate grammar productions, since we might have a
     *   structural noun phrase word (an article, pronoun, etc).  
     */
    rankCorrection(toks, idx, dict)
    {
        /* make a list consisting of the single changed word */
        local disList = [getTokVal(toks[idx])];

        /* look for an in-scope object association for the word */
        local m = 0;
        foreach (local obj in World.scope())
            m |= obj.matchNameDisambig(disList);

        /* 
         *   if we found any matches, give this the highest score; adjust
         *   slightly to prefer nouns, then adjectives, then plurals 
         */
        if (m != 0)
        {
            return ((m & MatchNoun) != 0 ? 102 :
                    (m & MatchAdj) != 0 ? 101 : 100);
        }

        /* check for non-predicate grammar words */
        local w = dict.findWord(getTokVal(toks[idx]))
            .subset({ x: dataType(x) == TypeObject });

        if (w.indexWhich({ x: x.ofKind(GrammarProd) && !x.ofKind(predicate) })
            != nil)
            return 90;

        /* 
         *   it's not an in-scope object word or a structural word, so
         *   don't allow it, in case it refers to a yet-unseen object 
         */
        return 0;
    }
;

/*
 *   ActorResolutionError - this is for resolution errors that are in the
 *   context of what the target actor of the command (the addressee) can
 *   see.  These require the Command in addition to the noun phrase, since
 *   that provides the target actor information.  
 */
class ActorResolutionError: ResolutionError
    construct(cmd, np)
    {
        inherited(np);
        self.cmd = cmd;
    }

    /* the command that we were attempting to resolve */
    cmd = nil
;

/*
 *   No objects match the addressee of a command (BOB, GO NORTH or TELL BOB
 *   TO GO NORTH).  
 */
class UnmatchedActorError: ResolutionError
    display()
    {
        /*
         *   An actor phrase in a command (BOB, GO NORTH) didn't match any
         *   in-scope objects.  This doesn't necessarily mean that the
         *   phrase doesn't refer to any object anywhere in the game, just
         *   that it doesn't refer to anything in scope.  Since we didn't
         *   match anything, all we have is the text of the actor phrase
         *   from the player's input.  
         */
        DMsg(unmatched actor, '{I} {see} no {1} {here}.', txt);
    }
;

/*
 *   No objects match a noun phrase. 
 */
class UnmatchedNounError: ActorResolutionError
    display()
    {
        /*
         *   A noun phrase didn't match any in-scope objects.  This doesn't
         *   necessarily mean that the phrase doesn't refer to any object
         *   anywhere in the game, just that it doesn't refer to anything
         *   in scope.  Since we didn't find an object, all we have is the
         *   text of the noun phrase from the player's input.  
         */
        DMsg(unmatched noun, '{I} {see} no {2} {here}.', cmd, stripArticle(txt));
    }
;

/*
 *   Base class for resolution errors involving pronouns 
 */
class PronounError: ResolutionError
    construct(np, pro)
    {
        inherited(np);
        pronoun = pro;
    }

    /* the pronoun that caused the error, as a Pronoun object */
    pronoun = nil
;
        

/*
 *   No pronouns match a noun phrase. 
 */
class NoAntecedentError: PronounError
    display()
    {
        /*
         *   The player used a pronoun for which there's currently no
         *   antecedent.  
         */
        DMsg(no antecedent,
             'I\'m not sure what you mean by "{1}".', np.prod.getText());
    }
;


/*
 *   The antecedent of the pronoun is no longer in scope
 */
class AntecedentScopeError: PronounError
    construct(cmd, np, pro)
    {
        inherited(np, pro);
        self.cmd = cmd;
    }

    cmd = nil

    display()
    {
        /*
         *   The player used a pronoun that refers to an object that's no
         *   longer in scope. 
         */
        DMsg(antecedent out of scope,
             '{I} no longer {see} that {here}.', cmd);
    }
;


/*
 *   There aren't enough objects matching a noun phrase to satisfy a
 *   quantifier (e.g., TAKE FIVE COINS, but only three coins are present). 
 */
class InsufficientNounsError: ActorResolutionError
    display()
    { 
        
        if(cmd.matchedAll)
            
            /* 
             *   The player used ALL when there's nothing suitable for all to
             *   refer to.
             */
            DMsg(nothing suitable for all, 'There{\'s} nothing suitable for        
                ALL to refer to. ');
        
        else
            
            /*
             *   The player used a noun phrase that specifically calls for some
             *   number of objects (such as FIVE COINS or BOTH BOOKS), but there
             *   aren't enough of those objects present.
             */
            DMsg(not enough nouns,
                 '{I} {don\'t see} that many {2} {here}.', cmd, txt);       

    }
;

/*
 *   The owner in a possessive phrase doesn't have any of the objects
 *   named. 
 */
class NoneInOwnerError: ActorResolutionError
    construct(cmd, np, poss)
    {
        inherited(cmd, np);
        possQual = poss;
    }

    /* the possessive qualifier */
    possQual = nil

    display()
    {
        /* 
         *   if we have other than one possible owner, show the original
         *   text of the owner phrase, since we can't be sure which matched
         *   object was intended; otherwise show the name of the actual
         *   owner we matched 
         */
        if (possQual.matches.length() != 1)
        {
            /*
             *   The player used a possessive to qualify a noun phrase, and
             *   we matched multiple objects for the possessive phrase, but
             *   none of those owners actually owns anything in scope that
             *   matches the main noun phrase.  For example, the player
             *   entered THE GUARD'S SWORD, and there are two guards
             *   present, but neither of them has a sword (not that's in
             *   scope, anyway).  
             */
            DMsg(none in owners, 'No {2} {dummy}appear{s/ed} to have any {3}.',
                 cmd, possQual.prod.getText(), txt);
        }
        else
        {
            /*
             *   The player used a possessive to qualify a noun phrase, and
             *   we matched a single object for the possessive phrase, but
             *   that owner doesn't actually possess anything in scope that
             *   matches the main noun phrase.  For example, the player
             *   entered BOB'S WALLET, and Bob is indeed in scope, but Bob
             *   doesn't own a wallet (not one that's in scope, anyway).  
             */
            local obj = possQual.matches[1].obj;
            gMessageParams(obj);
            
            DMsg(none in owner, '{The subj obj} {doesn\'t appear[ed]} to have
                any {2}.',  cmd,  txt);
                      
        }
    }    
    
;

/*
 *   The location in a locational qualifier doesn't contain any of the
 *   objects named. 
 */
class NoneInLocationError: ActorResolutionError
    construct(cmd, np, loc)
    {
        inherited(cmd, np);
        locQual = loc;
    }

    /* the locational qualifier */
    locQual = nil
    
    display()
    {
        /* 
         *   if we have other than one possible location, show the original
         *   text of the locational phrase, since we can't be sure which
         *   matched object was intended; otherwise show the name of the
         *   actual location we matched 
         */
        if (locQual.matches.length() !=  1)
        {
            /*
             *   We have a locational qualifier, and we have multiple
             *   objects that match the location, but there's nothing in
             *   scope that matches the main noun phrase that's in any of
             *   those locations.  For example, the player typed THE BOX ON
             *   THE TABLE, and we have two tables in scope, but there's no
             *   box in scope that's on either of them.  
             */
            DMsg(none in locations,
                 '{I} {see} no {2} {3} any {4}.',
                 cmd, txt, locQual.locType.prep, locQual.prod.getText());
        }
        else
        {
            /*
             *   We have a locational qualifier, and we have exactly one
             *   object that matches the location, but there's nothing in
             *   scope that matches the main noun phrase that's in that
             *   location.  For example, the player typed THE BOX ON THE
             *   TABLE, and we have a table in scope, but there's no box on
             *   it. 
             */
            DMsg(none in location,
                 '{I} {see} no {2} {3} {the 4}.',
                 cmd, txt, locQual.locType.prep, locQual.matches[1].obj);
        }
    }
;

/*
 *   There are no objects matching this noun phrase name that have the
 *   contents mentioned in the contents qualifier. 
 */
class NoneWithContentsError: ActorResolutionError
    construct(cmd, np, cont)
    {
        inherited(cmd, np);
        contQual = cont;
    }

    /* the contents qualifier */
    contQual = nil

    display()
    {
        /* 
         *   if we have other than one possible contents object, show the
         *   original text of the contents phrase, since we can't be sure
         *   which matched object was intended; otherwise show the name of
         *   the object we matched 
         */
        if (contQual.matches.length() != 1)
        {
            /*
             *   We have a contents qualifier, and we have multiple objects
             *   in scope that match the contents phrase, but there's
             *   nothing in scope that matches the main noun phrase that
             *   actually contains any of the contents objects.  For
             *   example, the player typed THE BUCKET OF WATER, and we do
             *   have multiple "water" objects present, but none of them
             *   are inside buckets that are in scope.  
             */
            DMsg(none with contents in list,
                 '{I} {see} no {2} of {3}.',
                 cmd, txt, contQual.prod.getText());
        }
        else
        {
            /*
             *   We have a contents qualifier, and we have exactly one
             *   object in scope that matches the contents phrase, but
             *   there's nothing in scope that matches the main noun phrase
             *   that actually contains that object.  For example, the
             *   player typed THE BUCKET OF WATER, and we do have a "water"
             *   object present, but it's not inside anything called a
             *   bucket (not one that's in scope, anyway).  
             */
            DMsg(none with contents,
                 '{I} {see} no {2} of {3}.',
                 cmd, txt, contQual.matches[1].obj);
        }
    }
;

/*
 *   A noun phrase is ambiguous, so we'll have to ask for clarification.
 */
class AmbiguousError: ResolutionError
    construct(cmd, np, names)
    {
        inherited(np);
        self.cmd = cmd;
        self.nameList = names;
    }

    display()
    {
        /* ask the language-specific ambiguous noun question */
        askAmbiguous(cmd, np.role, nameList.mapAll({ n: n[1] }));     
        
    }

    /* 
     *   Accept spelling corrections that trigger an ambiguous noun error.
     *   If we find an ambiguous noun it means that we have valid overall
     *   verb syntax *and* we have noun phrases that match in-scope objects
     *   - in fact, they match too many objects.  This is pretty good
     *   evidence that the respelling is valid.  
     */
    allowOnRespell = true


    /* 
     *   this is a curable error, since the player can fix the problem by
     *   answering the disambiguation question 
     */
    curable = true

    /* 
     *   Try curing the error.  After an ambiguous noun error, the player
     *   can type a partial noun phrase that clarifies which object was
     *   intended: a distinguishing adjective, a locational phrase, a
     *   possessive, etc. 
     */
    tryCuring(toks, dict)
    {
        /* try parsing against the main disambiguation grammar */
        local lst = new CommandList(
            mainDisambigPhrase, toks, dict,
            new function(prod)
            {
                /* create a new copy of the Command to apply the change to */
                local newCmd = cmd.clone();

                /* add the reply to the new command */
                local dnp = newCmd.startDisambigReply(np, prod);

                /* build the reply tree */
                prod.build(newCmd, dnp);

                /* the mapping is the new command */
                return newCmd;
            });

        /* accept curable errors in the reply */
        lst.acceptCurable();

        /* return the list */
        return lst;
    }

    /* the original Command that we were trying to resolve */
    cmd = nil

    /* 
     *   The list of object names, with distinguisher information.  This is
     *   the same information returned from Distinguisher.getNames(). 
     */
    nameList = []
;

class AmbiguousMultiDefiniteError: UnmatchedNounError
    display()
    {
        DMsg(be more specific, 'I don\'t know which ones you mean.  
            Can you be more specific?');
    }

    /* 
     *   this is not really curable, but we need to say it is curable so that
     *   our custom message is displayed.  Would like to find a way to do this
     *   where curable=nil
     */
    curable = true
;


/*
 *   Ordinal out of range.  This occurs when the player replies to a
 *   disambiguation query with an ordinal that's out of the bounds of the
 *   offered list. 
 */
class OrdinalRangeError: ResolutionError
    construct(np, ordinal)
    {
        inherited(np);
        self.ordinal = ordinal;
    }

    display()
    {
        /*
         *   An ordinal reply to a disambiguation question is out of range.
         *   For example, we asked "Which do you mean, the red book or the
         *   blue book?", and the player answered THE THIRD ONE.  There are
         *   only two options, so THIRD is out of range.  
         */
        DMsg(ordinal out of range,
             'Sorry, I don\'t see what you\'re referring to.');
    }

    /* the ordinal, as an integer value (1=first, 2=second, etc) */
    ordinal = nil
;

class BadMultiError: ParseError
    display() 
    { 
        DMsg(multi not allowed, 'Sorry; multiple objects aren\'t allowed with
            that command.'); 
    }
;

/* ------------------------------------------------------------------------ */
/*
 *   A placeholder object for dictionary entries.  The Dictionary class
 *   stores a three-way association: word string, part-of-speech property,
 *   and object.  The object association is designed to allow the parser to
 *   come up with a list of objects that could match a given word, but the
 *   adv3L library doesn't use this feature.  We instead figure out the
 *   word-to-object association by directly asking the objects in scope if
 *   they're associated with a word.  We still need *something* to store as
 *   the object association for each word entry in the dictionary, though.
 *   That's where this object comes in: it's a dummy object that serves as
 *   the required object to associate with each word.
 *   
 *   A language module can ignore this and use the word-object-property
 *   association feature of the dictionary, if desired.
 */
dictionaryPlaceholder: object
;



/* Exception thrown by exit macro */
class ExitSignal: Exception
;

/* Exception thrown by abortImplicit macro */
class AbortImplicitSignal: Exception
;

/* Exception thrown by abort macro */
class AbortActionSignal: Exception
;

/* Exception thrown by exitAction macro */
class ExitActionSignal: Exception  
;

/* Exception thrown to terminate a command. */
class TerminateCommandException: Exception
;