#charset "us-ascii"

#pragma once

/*
 *   Remap 'cmd' to another 'cmd'
 *
 *  Accepts in the source remap a string that has "|" and "(" for grouping.
 *  It does NOT support "*" or "?" or any wildcards nor does it accept words
 *  that use special characters outside of apostrophe (') or comma ','.
 *
 *  Several forms of the mapping occur:
 *      1. Provide the actual text for the new command
 *  OR  2. Do a normal doInstead command with the appropriate values [via execute()]
 *      3. Or put out a message with "" that ends the command [via execute()]
 *
 *
 *  Contributed by Mitchell Mlinar
 *  Copyright (c) 2025
 *
 *  Licensed using MIT defintion
 *
 *
 *  v1.00: 14 Oct 2025
 *  v1.02: 15 Oct 2025 (thanks to advice/feedback from Eric Eve)
 *  v1.03: 16 Oct 2025 (thanks to additional advice/feedback from Eric Eve)
 *
 */

#include "advlite.h"
#include <lookup.h>

/*
 *   The object put into your code
 
 */

/*
 *   RemapCmd is similar a Doer in that it remaps one command into another command, but
 *   there the differences end.  What are the differences?
 *
 *   RemapCmd parses up the cmd and does not make any attempt to map them to existing
 *   objects in the game.  Rather, it builds all the possible variations (by the use of
 *   "|", "(" and ")" operators) and then matches that against the user input FIRST before
 *   any other routines get a whack at it.  You can also provide two or more disjoint
 *   phrases that are separated by semi-colon ";" to provide additional phrases that
 *   match.
 *
 *   If a match is found against a RemapCmd, it will then act on it.  There are three
 *   different ways top operate on it.
 *
 *   - provide a complete text phrase replacement (remappedCmd, or use template)
 *   - if no replacement text phrase is provided, the execute() routine is run for that
 *     object; within that execute routine, you have two possibilities
 *     * emit some messages to the console via say() or "..."
 *     * use doInstead(action[,dobj[,iobj[,aobj]]]) within to execute that resolved
 *       command instead
 *   - NOTE: If text phrase is present, execute() will NOT be run!
 *
 *   Note that RemapCmd does not accept wildcards or punctuation of any sort other than
 *   "," and "'" -- and ";" to separate distinct input phrases.
 *
 */

class RemapCmd: object
    /* The command text to be recognized (see above) */
    cmd = ''
    
    /* 
     *   The remapped (replacement) text (if provided). This should be in the form of a command the
     *   parser can parse and exectute
     */
    remappedCmd = nil
    
    /* 
     *   If remapped command is NOT provided, game code should override this method to do
     *   something (or display some text). 
     */
    execute() {}

    /* 
     *   where this can happen (nil if everywhere); can be Room/Region or list of Rooms and/or
     *   Regions.
     */
    where = nil
    
    /* An expression defining under what circumstances this RemapCmd is matched. */
    when = true
    
    /* 
     *   A scene that must be happening, or list one of scenes of which must be happening for
     *   this to happen (nil if no scene is required)
     */
    during = nil
    
    /* 
     *   By default, you generally want any non-system command to take a turn.
     *   However, there may also be other circumstances where a turn should not be
     *   consumed.  Change to 0 if we want execute() to NOT count as a turn.
     *   This property is ignored if doInstead(...) is called within execute()
     */
    turnsTaken = 1
    
    //////////////////////////////////////////
    // Internals
    //
        
    /* Execute our custom method and then our turn sequence. For internal use only. */
    execute_()
    {       
        "<.p0>";
        execute();
        
        turnSequence();
    }
    
    /* 
     *   If doInstead has been used in our execute() method, then call the standard turn sequence
     *   routine to execute any Events and update the turn counter. For internal use only.
     */
    turnSequence() { 
        if(doInsteadItems == nil)
            delegated Action;
    }

    /* 
     *   A list containing the actoin and objects defined by a call to doInstead in our execute
     *   routine, or nil if doInstead() wasn't used. For internal use only
     */
    doInsteadItems = nil    
    
    /* 
     *   Populate our doInsteadItems from any call to doInstead() in our execute() routine. For
     *   internal use only.
     */
    doInstead(action,[args]) {
        /* get the optional items */
        local dobj = args.element(1);
        local iobj = args.element(2);    
        local aobj = args.element(3);
        
        local deftext = '';
        local len = args.length();

        if(doInsteadItems != nil) {
            "ERROR in doInstead(...) for remapCmd:\nYou cannot have more than one
            doInstead\b";
            abort;
        }
        if(action == nil)
            deftext += 'action is undefined!\n';
        if(dobj == nil && len > 0)
            deftext += 'direct object is set, but not defined/understood!\n';
        if(iobj == nil && len > 1)
            deftext += 'indirect object is set, but not defined/understood!\n';
        if(aobj == nil && len > 2)
            deftext += 'auxiliary object is set, but not defined/understood!\n';
        if(deftext != '') {
            "ERROR in doInstead(...) for remapCmd:\n<<deftext>>\b";
            abort;
        }
        doInsteadItems = [action,dobj,iobj,aobj];
    }
    
    /* The strings that are the command(s) to match. For internal use only. */
    cmdTerms = []   
    
    /* The hash for these strings (faster compare later). For internal use only. */
    cmdTermHash = []    
;

/* ------------------------------------------------------------------------ */
/*
 *   This gathers up all of the RemapCmd items and gets them ready for execution in the
 *   actual game
 *
 *  This is persistent and there should only be one of these
 *
 */

remapCmdDicts: PreinitObject
    /* Lookup table with hash and then list of objects that match it */
    remapTbl = nil  
    
    /* The pre-init execution routine */
    execute() {
        remapTbl = new LookupTable(50,50);
        local scmp = new StringComparator(nil,true,nil);    // case-sensitive as lower anyway
        
        for(local obj = firstObj(RemapCmd); obj != nil; obj = nextObj(obj,RemapCmd)) {
            // process the command
            local res, toks;
            local lst = [];
            foreach(local str in obj.cmd.split(';')) {
                try {
                    toks = remapCmdTokenizer.tokenize(str);
                    match = remapCmdGrammar.parseTokens(toks,nil);
                    if(match.length > 0) {
                        res = match[1].lstval();
                        lst = remapCmdGrammarOr(lst,res);
                    } else
                        throw new EvalToksError(toks);
                }
                catch (TokErrorNoMatch err)
                {
                    "Unrecognized punctuation: <<err.remainingStr_.substr(1, 1)>>";
                    break;
                }
                catch (EvalToksError err)                
                {
                    "Command phrase cannot be processed: <<str>>";
                    break;
                }
            }
            // have the parsed up items -- now join them up into individual possible commands
            foreach(toks in lst) {
                // always only allow ONE space between words
                res = toks.join(' ').findReplace(R'<Space><Space>+',' ',ReplaceAll);
                res = res.findReplace(R'(^<Space>+)|(<Space>+$)','',ReplaceAll);
                obj.cmdTerms = obj.cmdTerms.append(res);
                res = scmp.calcHash(res);
                obj.cmdTermHash = obj.cmdTermHash.append(res);
                addHashMap(res,obj);
            }
        }
    }
    
    /* add to the remapTbl for hash lookup */
    addHashMap(hash,obj) {
        if(remapTbl.isKeyPresent(hash)) {
            remapTbl[hash] = remapTbl[hash].append(obj);
        } else {
            remapTbl[hash] = [obj];
        }
    }
    
    /* process a tokenized string: return new string, obj if deferred, or nil if no match */
    processCmd(toks,tokcnt) {
        local scmp = new StringComparator(nil,true,nil);    // everything is lower case
        local acmd = '', ahash, obj, v;    // the string and its hash
        
        /* build the command */
        if(tokcnt > 0)
            toks = toks.sublist(1,tokcnt);
        acmd = toks.mapAll({x:x[1]});
        acmd = acmd.join(' ');
        ahash = scmp.calcHash(acmd);
        
        if(!remapTbl.isKeyPresent(ahash))
            return nil;
        
        /* scan the items that fit */
        foreach(obj in remapTbl[ahash]) {
            // support list of locations???
            if(obj.where != nil && valToList(obj.where).indexWhich({x:gLocation.isOrIsIn(x)}) == nil ) continue; // ECSE mod
            if(!obj.when) continue; // ECSE mod
            if(obj.during != nil && valToList(obj.during).indexWhich({s:s.isHappening}) == nil) continue; // ECSE mod
            for(v = 1; v <= obj.cmdTermHash.length(); ++v) {
                if(obj.cmdTermHash[v] == ahash && 
                   scmp.matchValues(obj.cmdTerms[v],acmd) != 0) {
                    // found it!
                    obj.doInsteadItems = nil;  // clear it out before we move on
                    if(obj.remappedCmd != nil)
                        return obj.remappedCmd;
                    return obj;
                }
            }
        }
        return nil;
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   remapCmd tokenizer for US English.  Other language modules should
 *   provide their own tokenizers to allow for differences in punctuation
 *   and other lexical elements.
 *   
 */
enum token tokOp;

/* Exception to handle exceptions occurring in the remapCmd tokenizer */
class EvalToksError: Exception
    displayException() { "Evaluate tokenizer exception -- unable to parse"; }
;

/* Tokenizer for use with RemapCmd */
remapCmdTokenizer: Tokenizer
    rules_ = static
    [
        /* skip whitespace */
        ['whitespace', R'<Space>+', nil, &tokCvtSkip, nil],

        /* 
         *   Words - note that we convert everything to lower-case.  A
         *   word can start with any letter or number and then
         *   alphabetics, digits, hyphens, and apostrophes after that. (tokWord,tokString)
         */
        ['word', R'<AlphaNum>(<AlphaNum>|[-\'])*', tokWord, &tokCvtLower, nil],
        
        // handle , as a separate item for conversations
        ['comma', ',', tokWord, nil, nil],
        
        /* 
         *   Single-quoted strings also allowed and only way to get empty string
         */
        ['string', R'\\?\'(<AlphaNum>|[-\'])*\\?\'', tokWord, &tokCvtStripSingle, nil],

        // operators
        ['emptystring',R'(<vbar><Space>*<rparen>)|(<lparen><Space>*<vbar>)', tokOp, &tokDoEmptyString, nil],
        ['operator', R'[|()]', tokOp, nil, nil]
    ]
    
    
    /* strip the leading and trailing single-quote -- and then push to lower-case */
    tokCvtStripSingle(txt, typ, toks)
    {
        if(txt.startsWith('\\'))
            txt = txt.substr(2);
        if(txt.endsWith('\\'))
            txt = txt.substr(1,txt.length() - 1);
        local newlen = txt.length() - 2;
        toks.append([txt.substr(2,newlen).toLower(), typ, txt]);
    }
    
    /* handle the |) or the (| sequence */
    tokDoEmptyString(txt, typ, toks)
    {
        local len = txt.length();
        toks.append([txt.substr(1,1),typ,txt.substr(1,1)]);
        toks.append(['',tokWord,'']);
        toks.append([txt.substr(len,1),typ,txt.substr(len,1)]);
    }
;

//////////////////////////////////////////////////////////
// Define the remapCmd grammar for the parser

/* The most basic left level grammar map */
grammar remapCmdGrammar(lit): tokWord->txt_: Production
    lstval() {
        lst_ = [[txt_]];
        return lst_;
    }
;

/* handle concatenation of two words into the list
 note the use of badness to prioritize the correct conversions */
grammar remapCmdGrammar(concat): [badness 50]
    remapCmdGrammar->pp_  remapCmdGrammar->pp2_ : Production
    lstval() {
        return remapCmdGrammarConcat(pp_.lstval(),pp2_.lstval());
    }
;

grammar remapCmdGrammar(or): [badness 30]
    remapCmdGrammar->pp_ '|' remapCmdGrammar->pp2_ : Production
    lstval() {
        return remapCmdGrammarOr(pp_.lstval(),pp2_.lstval());
    }
;

grammar remapCmdGrammar(tail): [badness 40]
    remapCmdGrammar->pp_  remapCmdGrammar->pp2_ '|' remapCmdGrammar->pp3_: Production
    lstval() {
        local lst = remapCmdGrammarOr(pp2_.lstval(),pp3_.lstval());
        return remapCmdGrammarConcat(pp_.lstval(),lst);
    }
;

grammar remapCmdGrammar(grp): [badness 20]
    '(' remapCmdGrammar->pp_ ')' : Production
    lstval() {
        return pp_.lstval();
    }
;


/*
 *   Helper routines for the grammar text expansion
 */
remapCmdGrammarConcat(lstleft,lstright) {
    local lft, rght;
    local lst = [];
    for(local i = 1; i <= lstleft.length(); ++i) {
        for(local j = 1; j <= lstright.length(); ++j) {
            lft = lstleft[i];
            rght = lstright[j];
            for(local k = 1; k <= rght.length(); ++k)
                lft = lft.append(rght[k]);
            lst = lst.append(lft);
        }
    }
    return lst;
}

remapCmdGrammarOr(lst,lstright) {
    for(local j = 1; j <= lstright.length(); ++j) {
        lst = lst.append(lstright[j]);
    }
    return lst;
}

/////////////////////////////////////////////////////////////////////////////////

/* Modifications to the Parser to accommodate RemapCmd */
modify Parser

    // return nil if an error; otherwise, return token list that could be empty
    parseToksOnly(str)
    {
        /* Make sure our current SpecialVerb is set to nil before we start parsing a new command. */
        specialVerbMgr.currentSV = nil;

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
            return nil;
        }
        return toks;
    }
    
    parse(str)
    {
        /* tokenize the input */
        local toks = parseToksOnly(str);
        if(toks == nil)
            return;

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
            
             /* Update the vocabulary of any game objects with alternating/changing vocab. */
            updateVocab();
            
             /* Allow the specialVerb Manager to adjust our toks */            
            toks = specialVerbMgr.matchSV(toks);  
            
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
                local remapCmdItem = nil;   // for later processing
                local remapCmdTokCnt = 0;

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
                } else {
                    remapCmdTokCnt = 0;
                    while(++remapCmdTokCnt <= toks.length()) {
                        if(toks[remapCmdTokCnt][1] == ';' ||
                           toks[remapCmdTokCnt][1] == '.') {
                            break;
                        }
                    }
                    // if i is 1, then semicolon is the (empty) command!
                    if(--remapCmdTokCnt > 0) {
                        if(remapCmdTokCnt == toks.length())
                            remapCmdTokCnt = 0;
                        remapCmdItem = remapCmdDicts.processCmd(toks,remapCmdTokCnt);
                        if(dataType(remapCmdItem) == TypeSString) {
                            local remaptoks = parseToksOnly(remapCmdItem);
                            if(remaptoks == nil)
                                return;
                            local i = remapCmdTokCnt;
                            remapCmdTokCnt = remaptoks.length();
                            // rip out old tokens and replace with new ones!
                            if(i > 0) {
                                while(++i <= toks.length())
                                    remaptoks = remaptoks.append(toks[i]);
                            }
                            // readjust the token set
                            toks = remaptoks;
                            remapCmdItem = nil;
                        }
                    }
                }

                /* 
                 *   if the question didn't grab it, try parsing as a whole
                 *   new command against the ordinary command grammar
                 */
                if (cmdLst == nil || cmdLst.cmd == nil)
                {
                    if(remapCmdItem == nil) {
                        cmdLst = new CommandList(
                            root, toks, cmdDict, { p: new Command(p) });
                    } else {
                        remapCmdItem.execute_(); // ECSE mod
                        if(remapCmdItem.doInsteadItems != nil) {
                            // create the artificial command
                            local cobj = remapCmdItem.doInsteadItems;
                            local c2;
                            if(cobj[2] == nil)
                                c2 = new Command(cobj[1]);
                            else if(cobj[3] == nil)
                                c2 = new Command(cobj[1],cobj[2]);
                            else if(cobj[4] == nil)
                                c2 = new Command(cobj[1],cobj[2],cobj[3]);
                            else
                                c2 = new Command(cobj[1],cobj[2],cobj[3],cobj[4]);
                            // fix c2 for items needed later here
                            c2.endOfSentence = true;   // remapped commands are stand-alone
                            c2.nextTokens = remapCmdTokCnt > 0?
                                toks.sublist(remapCmdTokCnt+2) : [];
                            cmdLst = new CommandList(c2);
                        } else {
                            firstCmd = nil;
                            
                            /* start over with a new spelling correction history */
                            history = new transient SpellingHistory(self);

                            // since we remapped, it will always be end-of-sentence
                            root = firstCommandPhrase;
                            /* 
                             *   Set the root grammar production for the next
                             *   predicate.  If the previous command ended the
                             *   sentence, start a new sentence; otherwise, use the
                             *   additional clause syntax. 
                             */
                            
//                            root = cmd.endOfSentence
//                                ? firstCommandPhrase : commandPhrase;
//                    
                   
                            /* go back and parse the remainder of the command line */
                            /* start index is 1 and have to skip the semi-colon as well */
                            if(remapCmdTokCnt > 0)
                                toks = toks.sublist(remapCmdTokCnt+2);
                            else
                                toks = [];
                            continue;
                        }
                    }
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
                       && str.find(',') == nil
                       && gPlayerChar.currentInterlocutor.allowImplicitSay())
                    {
                         l = new CommandList(
                            topicPhrase, toks, cmdDict,
                            { p: new Command(SayAction, p) });
                        
                        libGlobal.lastCommandForUndo = str;
                        savepoint();
                    }
                    /* 
                     *   If the player char is not in conversation with anyone,
                     *   and the first word of the command doesn't match a possible
                     *   command verb, then try parsing the command line as a
                     *   single direct object phrase for the DefaultAction verb,
                     *   provided defaultActions are enabled (which they are
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
;



////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////

/*
 *   This is only emabled for testing the tokenizer and parser if you want to see how it
 *   operates.  You will need to run tok_test2() from somewhere (I usually put it in
 *   showIntro for quick/easy/immediate access
 */

#if 0
tok_test2()
{    
    local tmap = new LookupTable([tokWord,'word',tokString,'string',tokOp,'operator']);
    
    // get grammar info
//    local ginfo = remapCmdGrammar.getGrammarInfo();   
//    local val = spelledToInt('ninety-six');   // to see how it is done

    "Enter text to tokenize.  Type Q or QUIT when done. ";
    for (;;)
    {
        local str, toks, tok, match, res, c, lsthold;

        /* read a string */
        "\b>";
        str = inputLine().split(';');
        
        lsthold = [];
        foreach(c in str) {
            try {
                toks = remapCmdTokenizer.tokenize(c);
                //getTokVal(tok) returns the parsed value of the token.
                //getTokType(tok) returns the type of the token.
                //getTokOrig(tok) returns the original source text the token matched.
                /* display the tokens */
                for (local i = 1, local cnt = toks.length() ; i <= cnt ; ++i) {
                    tok = toks[i];
                    "(<<getTokVal(tok)>>,<<tmap[getTokType(tok)]>>)";
                }
                "\n";
                // this phrase is set -- parse it up
                match = remapCmdGrammar.parseTokens(toks,nil);
                if(match.length > 0) {
                    res = match[1].lstval();
                    dumpList(res); "\n";
                    lsthold = remapCmdGrammarOr(lsthold,res);
                }
                else
                    "?????\n";
                "-----\n";            
            }
            catch (TokErrorNoMatch err)
            {
                "Unrecognized punctuation: <<err.remainingStr_.substr(1, 1)>>";
            }
        }
        "------ Final -----\n";
        dumpList(lsthold);
    }
}

// simple list dumper
dumpList(lst) {
    if(lst == nil)
        "<nil>";
    else {
        "[";
        local prefix = '';
        foreach(local item in lst) {
            "<<prefix>>";
            prefix = ',';
            if(dataType(item) == TypeList)
                dumpList(item);
            else if(item == ',')
                "(comma)";
            else {
                item = toString(item);
                item = item.findReplace(',','(comma)',ReplaceAll);
                "<<item>>";
            }
        }
        "]";
    }    
}

getDataType(data) {
    local s = '?';
    switch(dataType(data)) {
        case TypeObject: s='object'; break;
        case TypeList: s='list'; break;
        case TypeSString: s='single-string'; break;
        case TypeInt: s='integer'; break;
        case TypeFuncPtr: s='func-ptr'; break;
        case TypeProp: s='property'; break;
        case TypeNil: s='nil'; break;
        case TypeTrue: s='true'; break;
        case TypeEnum: s='enum'; break;

        // grammars
        case GramTokTypeProd: s='gramProd'; break;
        case GramTokTypeSpeech: s='gramSpeech'; break;
        case GramTokTypeNSpeech: s='gramNSpeech'; break;
        case GramTokTypeLiteral: s='gramLiteral'; break;
        case GramTokTypeTokEnum: s='gramEnum'; break;
        case GramTokTypeStar: s='gramStar'; break;
    }
    return s;
}

#endif
