#charset "us-ascii"
#include "advlite.h"

property subLocation;
property lookAroundShowExits;
property stanceToward;
property setStanceToward;
property destinationName;

/*
 *   Mentionable is the base class for objects that the player can refer to
 *   in command input.  In order for the parser to recognize an object, the
 *   object must have vocabulary words in the dictionary.  This class's
 *   main function, then, is to set up the dictionary for an object, so
 *   that its words are recognizable to the parser.
 *   
 *   This class is based on LMentionable, which is defined in the language
 *   module.  LMentionable provides implementations for certain methods
 *   that we rely upon for functionality that varies by language.  
 */
class Mentionable: LMentionable
    /*
     *   'vocab' is a string that we use to initialize the object's short
     *   name, dictionary words, grammatical gender, and grammatical number
     *   (singular/plural).  This is designed to make it as convenient as
     *   possible to describe the object's name and grammatical behavior
     *   for input and output purposes.
     *   
     *   The syntax is language-specific - see initVocab() for details.  
     */
    vocab = nil

    /*
     *   The object's short name, for display in lists and announcements.
     *   By default, this is automatically derived from 'vocab', so you
     *   usually don't have to set it directly.  If you define a non-nil
     *   'name' value manually, though, it takes precedence (i.e., the
     *   library won't replace it with the name implied by 'vocab').  
     */
    name = nil

    /*
     *   My room title.  This is displayed as the start of the room
     *   headline, which is the first line of the room description when
     *   'self' is the outermost visible container of the point-of-view
     *   actor.  The headline is also conventionally shown on the status
     *   line whenever the player is in the location.
     *   
     *   The room title essentially serves as a label for the room on the
     *   player's mental and/or paper map of the game's geography.  It's
     *   usually something short and pithy that sums up the room's essence,
     *   function, or appearance, and is usually written in title case: Ice
     *   Cave, Bank Lobby, Front of House, Transporter Room 3, etc.
     *   
     *   The room headline sometimes adds more status information to the
     *   title, such as the point-of-view actor's direct container when the
     *   actor is inside an intermediate container within the room, such as
     *   a chair.  
     */
    roomTitle = nil

    /*
     *   The object's disambiguation name.  This is a more detailed version
     *   of the name, for situations where the short name is ambiguous.
     *   For example, the parser displays this name in "Which do you mean"
     *   questions when it would help tell two of the listed objects apart.
     *   
     *   By default, this is the same as the short name.  It's uncommon to
     *   override this, since short names are typically already detailed
     *   enough for most purposes.  Every so often, though, you'll want to
     *   keep the short name very terse, so you'll leave out some
     *   distinguishing detail that it *could* have had.  In such cases,
     *   you can add the distinguishing detail here, so that it's displayed
     *   only when it's really needed.  
     */
    disambigName = (name)

    /*
     *   Disambiguation prompt grouping.  When the parser generates a
     *   disambiguation question ("Which did you mean, the red book, or the blue
     *   book?"), it'll group the objects in the list by common disambigGroup
     *   values.  The group is just an arbitrary value that keeps like objects
     *   together in the list.  You can use a string, a class, or whatever you
     *   like for this, as long as grouped objects have the same value in
     *   common. We give this property a default value of 0 so that the
     *   disambigOrder will work by default without the need to specify a
     *   disambigGroup.
     */
    disambigGroup = 0

    /* 
     *   Disambiguation prompt sorting.  This gives the display order of
     *   this item within its disambiguation group, if it has one.  The
     *   parser sorts objects within each group in ascending order of this
     *   value when generating the object list for a disambiguation
     *   question.  This is simply an integer; the default is 1 for every
     *   object, which makes the ordering arbitrary.
     *   
     *   This property is useful for grouped objects with a natural
     *   ordering, such as items with sequential labels of some sort
     *   (numbers, letters, etc).  You can use this property to ensure that
     *   lists of these items will be displayed in the natural order:
     *   "button 1, button 2, or button 3?" or "the door on the left, the
     *   door in the middle, or the door on the right?"  
     */
    disambigOrder = (listOrder)

    /* 
     *   Is this object's short name a proper name?  A proper name is the
     *   name of a person, place, or other unique entity with its own name.
     *   
     *   This property controls how the library shows the object's name in
     *   generated messages.  In English, for example, articles (a, the)
     *   aren't used with a proper name.
     *   
     *   The English library tries to infer whether the object has a proper
     *   name based on the 'vocab' string: if all the words in the short
     *   name are capitalized, we'll consider it a proper name.  This rule
     *   of thumb doesn't always apply, though, so you can override it:
     *   simply set 'proper' explicitly in an individual object, and the
     *   setting will take precedence over whatever the name's
     *   capitalization would otherwise imply.  (Other languages might have
     *   different rules for inferring 'proper', and some might not be able
     *   to infer it at all.)  
     */
    proper = nil

    /*
     *   The object's name is "qualified" grammatically, meaning that it
     *   can't be combined with articles (a, the) or possessives.  Proper
     *   names are considered to be qualified, but it's possible for a name
     *   to be qualified but not proper, such as a name that incorporates a
     *   possessive.  
     */
    qualified = (proper)

    /*
     *   The grammatical person of narration relative to this object.  Use
     *   1 for first person ("I am in a cave"), 2 for second person ("You
     *   are in a cave"), and 3 for third person ("Bob is in a cave").
     *   
     *   Usually, every object in the game will be in the third person -
     *   *except* the player character object, which is usually in the
     *   second person.  The library doesn't care which person you use for
     *   the player character, though - you're free to use first or third
     *   person if you prefer.  First-person and third-person IF are
     *   relatively uncommon, but not unheard of.
     *   
     *   This property is used for verb agreement when library messages are
     *   generated.  This ensures that library messages adapt to the
     *   correct narrative person of the story automatically.  To write a
     *   first-person game, you don't have to replace all of the default
     *   messages, but simply set person=1 in your PC object.
     */
    person = 3

    /*
     *   The object's grammatical gender(s).  This information is used to
     *   determine which pronouns can match the object as an antecedent,
     *   which pronouns should represent it in output, and (for some
     *   languages) which articles and other gender-agreement words should
     *   be used in conjunction with the object name in output.
     *   
     *   The default is neuter.  Use isHim and isHer to give an object
     *   masculine and/or feminine gender.  Use isIt to explicitly give an
     *   object neuter gender.  By default, we infer isIt from isHim and
     *   isHer: we assume the object is neuter if it's not masculine or
     *   feminine.
     *   
     *   Languages that have grammatical gender will almost certainly want
     *   to parse articles in the 'vocab' property to make it more
     *   convenient to encode each object's gender.  For example, a French
     *   implementation could parse 'le' or 'la' at the start of a vocab
     *   string and set isHim and isHer accordingly.
     *   
     *   The English library sets isHim and isHer if 'him' and 'her'
     *   (respectively) are found in the object's pronoun list.  (This is
     *   the most convenient way to represent gender via the vocab string
     *   in English, since English doesn't have gendered articles.)
     *   
     *   Note that we define the genders as three separate properties, so
     *   the genders are NOT mutually exclusive - an object can be a "him",
     *   a "her", and an "it" at the same time.  This is because a single
     *   object can have multiple grammatical genders in some languages.
     *   In English, for example, an animal can be referred to as gendered
     *   (matching its physical gender) or neuter; and a few inanimate
     *   objects have a sort of optional, idiomatic gender, such as
     *   referring to a ship or country as "her".  
     *   
     *   Some languages might need additional genders.  When needed,
     *   LMentionable should simply define suitable additional properties.
     *   
     *   In most gendered languages, the grammatical gender is an attribute
     *   of the noun, not of the object.  In particular, if an object has
     *   two nouns in its vocabulary, the two nouns might be of different
     *   genders.  The language module might therefore limit the use of
     *   isIt et al to the gender of the object's name string as it appears
     *   in output (e.g., for selecting an article when showing the name in
     *   a list, or selecting a pronoun to represent the object), and use a
     *   completely different scheme to tag the gender of individual
     *   vocabulary words.  One approach would be to use separate mNoun and
     *   fNoun token properties (and more if needed) to distinguish the
     *   gender of individual nouns in the dictionary.  
     */
    isIt = (!(isHim || isHer || isGenderNeutral))
    isHim = nil
    isHer = nil

    /*
     *   The object's name's grammatical number.  This specifies singular
     *   or plural usage for the object's name when it appears in generated
     *   messages.  By default, an object has singular usage, so it'll
     *   appear as (for example) "an orange".  Some objects have names with
     *   plural usage, either because they're words that always appear in
     *   the plural (such as "scissors"), or because the game object
     *   represents a group of items that are too numerous and unimportant
     *   to the game to actually implement as separate Thing objects.  For
     *   example, the books in a library might be implemented collectively
     *   as a single "books" object.
     *   
     *   The English library sets this to true if 'them' is listed as a
     *   pronoun for the object in the 'vocab' property.  
     */
    plural = nil
    
    /*   
     *   Some objects, such as a pair of shoes or a flight of stairs could be
     *   regarded as either singular or plural and referred to as either 'it' or
     *   'them'. Set ambiguouslyPlural to true for such objects.
     */
    ambiguouslyPlural = nil

    /*
     *   The object's name is a mass noun.  A mass noun is a word that has
     *   singular form but represents an indeterminate quantity or group of
     *   something, such as "sand" or "furniture". 
     *   
     *   In English, mass nouns use "some" as the indefinite article rather
     *   than "a" (some sand, not a sand).  Their plural usage tends to
     *   differ from regular nouns, in that they already carry a sense of
     *   plurality; if you have two distinct piles of sand, the two
     *   together are usually still just "sand", not "two sands".
     *   
     *   When a mass noun is awkward as an object's name, you can often
     *   make it into a regular noun by naming its overall form.  "Sand" is
     *   a mass noun, but recasting it as "pile of sand" makes it an
     *   ordinary noun.  (The generic way to do this for a homogeneous
     *   substance is to add "quantity of".)  
     */
    massNoun = nil
    
    /*
     *   My nominal contents is the special contents item we can use in
     *   naming the object.  This is useful for containers whose identities
     *   come primarily from their contents, such as a vessel for liquids
     *   or a box of loose files.  Returns an object that qualifies the
     *   name: a "water" object for BOX OF WATER, a "files" object for BOX
     *   OF FILES.  Nil means that the object isn't named by its contents.
     *   
     *   Note that this is always a single object (or nil), not the whole
     *   list of contents.  We can only be named by one content object.
     *   (So you can't have a "box of books and papers" by having separate
     *   nominal contents objects for the books and the papers; although
     *   you could fake it by creating a "books and papers" object.)  
     */
    nominalContents = nil

    /* 
     *   Can I be distinguished in parser messages by my contents?  If so,
     *   we can be distinguished (in parser messages) from similar objects
     *   by our contents, or lack thereof: "bucket of water" vs "empty
     *   bucket".  If this is true, our nominalContents property determines
     *   the contents we display for this.  
     */
    distinguishByContents = nil

    /*
     *   Match the object to a noun phrase in the player's input.  If the given
     *   token list is a valid name for this object, we return a combination of
     *   MatchXxx flag values describing the match.  If the token list isn't a
     *   valid name for this object, we return 0.
     *
     *   By default, we call simpleMatchName(), which matches the name if all of
     *   the words in the token list are in the object's vocabulary list,
     *   regardless of word order.
     *
     *   In most cases, an unordered word match works just fine.  The obvious
     *   drawback with this approach is that it's far too generous at matching
     *   nonsense phrases to object names - DUSTY OLD SPELL BOOK and BOOK DUSTY
     *   SPELL OLD are treated the same.  In most cases, users won't enter
     *   nonsense phrases like that anyway, so they'll probably never notice
     *   that we accept them.  If they enter something like that intentionally,
     *   we can plead Garbage In/Garbage Out: a user who willfully types a
     *   nonsense command has only himself to blame for a nonsense reply.
     *
     *   Occasionally, though, there are reasons to be pickier.  When these come
     *   up, you can override matchName() to be as picky as you like.
     *
     *   The most common situation where pickiness is called for is when two
     *   objects happen to share some of the same vocabulary words, but certain
     *   words orderings clearly refer to only one or the other. With the
     *   unordered approach, this can be a nuisance for the player because it
     *   can trigger disambiguation questions that seem unnecessary.  Overriding
     *   matchName() to be picky about word order for those specific objects can
     *   often fix this. In this implementation the matchPhrases property can be
     *   used for this purpose.
     *
     *   Another example is ensuring the user knows the correct full name of an
     *   object as part of a puzzle: you can override matchName() to make sure
     *   the user doesn't accidentally stumble on the object by using one of its
     *   vocabulary words to refer to something else nearby.  Another example is
     *   matching words that aren't in the vocabulary list, such as a game
     *   object that represents a group of apparent objects that have a whole
     *   range of labels ("post office box 123", say).
     */
    matchName(tokens)
    {        
        return matchNameCommon(tokens, matchPhrases, matchPhrasesExclude);      
    }
    
    /* 
     *   Match a name against a list of tokens entered by the player. phrases is
     *   the list of match phrases defined on the object (either for initial
     *   matching or for disambiguation) and excludes should be true or nil
     *   depending on whether failure to match phrases should exclude a match
     *   overall.
     */    
    matchNameCommon(tokens, phrases, excludes)
    {
        /* 
         *   If an item is hidden, the player character either shouldn't know of
         *   its existence, or at least shouldn't be able to interact with it,
         *   so it shouldn't match any vocab.
         */
        if(isHidden && !gCommand.action.unhides)
            return 0;
        
        /* 
         *   First try the phrase-match matcher; if this fails return 0 to
         *   indicate that we don't match. If it succeeds in matching a phrase
         *   of more than one word, return MatchPhrase (we found a match).
         */        
        local phraseMatch = 0;
        
        /* 
         *   We only need to test for phrase matching if there are any phrases
         *   to match,
         */
        if(phrases != nil)
        {    
            /* See if our list of tokens matches any of our phrases. */           
            phraseMatch = phraseMatchName(phrases, tokens);
            
            /* 
             *   If there's a mismatch between our phrases and our tokens,
             *   return 0 to indicate we don't have a match overall. A mismatch
             *   only occurs if one or more of our tokens appears in one or more
             *   of our phrases but there's no match between a phrase and the
             *   succession of tokens.
             */
            if(phraseMatch is in (0, nil) && excludes)    
                return 0;
            
            /* 
             *   A return type of true means there was no overlap between the
             *   tokens and the matchPhrases, so the matchPhrases should have no
             *   effect on the match.
             */
            if(dataType(phraseMatch) != TypeInt)
                phraseMatch = 0;
        }
        
        /* 
         *   Now compute our simple match score (based on our individual tokens
         *   without regard to their ordering or to their matching any phrases).
         */
        local simpleMatch = simpleMatchName(tokens);
        
        /* 
         *   If the simpleMatchName routine fails to match anything, consider
         *   the match a failure
         */
        if(simpleMatch == 0)
            return 0;
        
        
        /* 
         *   Otherwise boost the simpleMatch score with the result of the phrase
         *   match.
         */
        return phraseMatch | simpleMatch;
    }
    
    

    /*
     *   Match the object to a noun phrase in *disambiguation* input.  This
     *   checks words in the player's reply to a "Which one did you
     *   mean...?" question from the parser.  When the player replies to
     *   this kind of question, they usually don't respond with the full
     *   name, but with just an adjective or two.
     *   
     *   Now, you might think we should handle these replies by just
     *   appending them to the original noun phrase in the input.  But we
     *   can't just do that: matchName() *could* care about the order of
     *   the words in the noun phrase, so we can't just assume that we can
     *   stick them in somewhere and still have a valid name for the
     *   object.  So, instead of doing that, we call this routine with the
     *   phrase from the player's answer to the "Which one" question.
     *   Since this routine knows that the new words aren't part of the
     *   original phrase, it can deal with them as it sees fit with respect
     *   to word order.
     *   
     *   The default here, of course, is to do the same thing as the
     *   default matchName(): we simply call simpleMatchName() to match the
     *   input to the object vocabulary, ignoring word order.  This will
     *   usually work even when matchName() is overridden to care about
     *   word order, since the added words here are just serving to
     *   distinguish one object from another.
     */
    matchNameDisambig(tokens)
    {
        
        /* 
         *   If disambigMatchPhrases is defined then we must match it
         *   exclusively; i.e. a fail to match any relevant phrase must result
         *   in a failure overall; otherwise we'll just keep getting the same
         *   disambiguation question over and over.
         */        
        return matchNameCommon(tokens, disambigMatchPhrases, true);
           
    }
   
    /*
     *   Simple implementation of matchName(), which simply checks to see
     *   if all of the tokens are associated with the object.  The "simple"
     *   aspect is that we don't pay any attention to the order of the
     *   words - we simply check that they're all in the object's
     *   vocabulary list, in any order.
     */
    simpleMatchName(tokens)
    {
        /* if the token list is empty, it's no match */
        if (tokens.length() == 0)
            return 0;
        
        /* we haven't found any strength demerits yet */
        local strength = MatchNoTrunc | MatchNoApprox;

        /* we haven't found any part-of-speech matches yet */
        local partOfSpeech = 0;

        /* remember the vocabulary word list and the string comparator */
        local vw = vocabWords, cmp = Mentionable.dictComp;

        /*
         *   if we're distinguishable by contents, add either the
         *   vocabulary for our contents object, if we have one, or the
         *   special 'empty' vocabulary words 
         */
        if (distinguishByContents)
        {
            vw += nominalContents != nil
                ? nominalContents.vocabWords : emptyVocabWords;
        }

        /* note the number of states we have */
        local stateCnt = states.length();

        /* scan the token list */
        for (local i = 1, local len = tokens.length() ; i <= len ; ++i)
        {
            /* get the word */
            local tok = tokens[i];

            /* match this word */
            local match = matchToken(tok, vw, cmp);

            /* 
             *   if we didn't match it from our own vocabulary, try
             *   matching it against any states we have 
             */
            if (match == 0)
            {
                /* try each state until we find a match or run out of states */
                for (local j = 1 ; j <= stateCnt ; ++j)
                {
                    /* try this state - stop searching if it matches */
                    local state = states[j];
                    if ((match = state.matchName(
                        tok, self.(state.stateProp), cmp)) != 0)
                        break;
                }
            }

            /* 
             *   if we didn't find a match for this token, the whole phrase
             *   fails (even if we've already matched other tokens) 
             */
            if (match == 0)
                return 0;

            /* 
             *   We found a match for this token, so combine it into the
             *   running totals for the overall phrase.  The overall phrase
             *   strength is the WEAKEST of the individual token strengths.
             *   The overall phrase part-of-speech mix is the union of the
             *   individual token part-of-speech matches. 
             */
            strength = min(strength, match & MatchStrengthMask);
            partOfSpeech |= match;
        }

        /* 
         *   Omit prepositions from the results.  We don't want to reject
         *   prepositions that are in our vocabulary, which is why we've
         *   kept them in the results thus far, but we also don't want to
         *   match the whole phrase on the strength of just a preposition -
         *   "of" just isn't sufficiently specific to match "pile of
         *   paper".  Also mask out the match-strength bits we've
         *   accumulated, so that we can tell specifically which parts of
         *   speech we've matched.  
         */
        partOfSpeech &= MatchPartMask & ~MatchPrep;

        /* 
         *   we need at least one actual part-of-speech match - if we
         *   didn't find any, we must have had a string of nothing but
         *   prepositions 
         */
        if (partOfSpeech == 0)
            return 0;

        /* return the overall results, combined into a single bit vector */
        return strength | partOfSpeech;
    }

    
    /* 
     *   If we have any phraseMatches defined, check whether we fail to match
     *   any of them. This will be the case if we find a phraseMatch containing
     *   one of our tokens but not the rest in the right order.
     */
    phraseMatchName(phrases, tokens)
    {
        /* Start by assuming we won't find a mismatch */
        local ok = true;
        
        /* Note the number of tokens to check */
        local tokLen = tokens.length;
        
        /* Note the string comparator to use. */
        local cmp = Mentionable.dictComp;
        
        /* 
         *   Go through each phraseMatch in turn to see if the tokens either
         *   fail to match it or succeed in matching it.
         */
        foreach(local pm in valToList(phrases))
        {
            /* Split the phraseMatch into a list of words */
            local pmList = pm.split(' ');
            
            /* 
             *   If the list of words from the phraseMatch contains no words in
             *   common with the token list, there's nothing to test; but if it
             *   does, we need to test it.
             */
            if(pmList.overlapsWith(tokens))
            {
                /* 
                 *   See if we can find a list equivalent to the phraseMatch
                 *   list as a sublist of the tokens list.
                 */                
                local pmLength = pmList.length();
                for(local i in 1 .. tokLen - pmLength + 1)
                {
                    /* 
                     *   If we can we've succeeded in finding a phrase match, so
                     *   we can return true straight away.
                     */
                    if(tokens.sublist(i, pmLength).strComp(pmList, cmp))
                    {
                        return pmLength > 1 ? MatchPhrase : MatchAdj;                            
                    }                                            
                }
                /* 
                 *   If we don't find a phrase match, note the failure, but
                 *   there may be other phrases to try matching, so carry on
                 *   looking.
                 */
                ok = 0;
            }           
        }
        
        /* Return the result */
        return ok;
    }
    
    
    
    /* 
     *   A single-quoted string, or a list of single-quoted strings containing
     *   exact phrases (i.e. sequences of words) that must be matched by the
     *   player input if any of the words in the phrase matches appear in the
     *   player input. Note that words defined here should also be defined in
     *   the vocab property; the purpose of the matchPhrases property is to
     *   limit matches. Note also that object will be matched if any of the
     *   phrases in the list is matched.
     */
    matchPhrases = nil
    
    
    /* 
     *   Do we want to test for phrase matches when disambiguating? We'll assume
     *   that by default we do since the same reasons for wanting the phrase
     *   match are likely to apply when disambiguating, and that we'll use the
     *   same set of phrases. This can be overridden to supply a different set
     *   of phrases or none.
     */
    disambigMatchPhrases = matchPhrases
        
    
    /*   
     *   If failing to match any of the match phrases (when the player's input
     *   includes at least one word used in any of them) excludes a match, then
     *   return nil
     */
    matchPhrasesExclude = true
   
     
    
    /* 
     *   On dynamically creating a new object, do the automatic vocabulary
     *   and short name initialization.  
     */
    construct()
    {
        /* do the vocabulary initialization */
        initVocab();

        /* build the list of applicable states */
        foreach (local s in State.all)
        {
            if (s.appliesTo(self))
                states += s;
        }
    }

    /*
     *   Vocabulary word list.  This is a vector of VocabWord objects that
     *   we build in initVocab(), giving the individual words that this
     *   object uses for its noun phrase vocabulary.  
     */
    vocabWords = []

    /* the State objects applying to this object */
    states = []
    
    /*  
     *   The filterResolveList method allows this object to remove itself or
     *   other objects from the list of resolved objects.
     *
     *   np is the noun phrase, so np.matches gives the current list of matches,
     *   and np.matches[i].obj gives the ith object match. To change the list of
     *   matches, manipulate the np.matches list.
     *
     *   cmd is the command object, so that cmd.action gives the action about to
     *   be executed.
     *
     *   mode is the match mode.
     *
     *   By default we do nothing here.
     */
    filterResolveList(np, cmd, mode) { }
    
    /* 
     *   Our original vocab string, if we've defined an altVocab that might replace our original
     *   vocab. Tbis is should normally be left to the library to set at preinit.
     */
    originalVocab = nil
    
    /* 
     *   An alternative vocab string to be used when useAltVocabWhen is true, or list of altenative
     *   strings to be used under various conditions.
     */
    altVocab = nil
    
    /* 
     *   A condition that must be true for us to change (or maintain) our vocab to our altVocab. If
     *   it returns nil we revert back to our original vocab. If we return -1 the change to altVocab
     *   becomes permanent and our updateVocab methdd won't be executed any more.
     *
     *   But if altViocab is defined as a list, we return nil to return to our originalVocab, 0 to
     *   return to our original vocab and keep it for the rest of the game, n (where n > 0) to
     *   change our vocab to the nth item in our altVocab list or -n to change our vocab to the nth
     *   item in our altVocab list and then keep it there for the remainder of the game (i.e. stop
     *   checking or vocab updates).
     */
    useAltVocabWhen = nil
    
    /*  
     *   A condition that when true means that the library will stop checking for switching vocab to
     *   and from the altVocab (or between different vocabs). This could, for example, be set to
     *   useAltVocabWhen when we only want to change vocab once, say when the player gets to learn
     *   the name of an NPC or the true nature of an object is first revealed.
     */
    finalizeVocabWhen = nil
    
    /* Initialize our alternative vocab */
    initAltVocab()    
    {
        /* 
         *   Add ourselves to the list of Things whose vocab might change so we can be checked each
         *   turn.
         */
        libGlobal.altVocabLst += self;
        
        /* Store a copy of our original vocab string so we can revert to it. */
        originalVocab = vocab;
    }
    
    /* 
     *   This is called every turn on every Thing listed in libGlobal.altVocabLst. By default it
     *   carries out alternation between our original vocab and our altVocab according to the value
     *   of useAltVocabWhen. Game code can override this methed to do something different, but must
     *   give altVocab a non-nil value for this method to be invoked each turn, or each turn when
     *   this Thing is in scope.
     *
     */
    updateVocab()
    {                
        if(altVocab)
        {          
            /* Stash the current value of useAltVocabWhen so we don't have to recalculate it. */
            local uavw = useAltVocabWhen; 
            
            /*  
             *   If the condition for using our altVocab is false and we're not already using our
             *   original vocab, replace our current vocab with our original vocab.
             */
            if(uavw == nil && vocab != originalVocab)
                replaceVocab(originalVocab);
            
            /* 
             *   if altVocab is defined as a list we change vocab to the appropriate item in the
             *   list.
             */
            if(dataType(altVocab) == TypeList)
            {
                /* 
                 *   A return value of less that 1 means we want to change the vocab to the -uavw
                 *   item in the list and keep it there for the rest of the game.
                 */
                if((uavw != nil && uavw < 1) || finalizeVocabWhen)
                {
                    libGlobal.altVocabLst -= self;
                    
                    uavw = -uavw;
                }
                /* 
                 *   If uavw is in range and is different from the previous value, then we need to
                 *   change the vocab to entry uavw in our altVocab list. A value of 0 means that we
                 *   want to change the vocab to its original value and leave it there for the rest
                 *   of the game.
                 */
                if(uavw != uavwNum && (uavw == nil || uavw <= altVocab.length))
                {
                    uavwNum = uavw;
                    
                    local newVocab = (uavw && uavw > 0) ? altVocab[uavw] : originalVocab;
                    
                    replaceVocab(newVocab);
                }
            }
            else
            {
                /* 
                 *   If the condition for using our altVocab is true and we're not already using it,
                 *   then replace our vocab with our altVocab.
                 */
                if(uavw && vocab != altVocab)
                    replaceVocab(altVocab);            
                
                /* 
                 *   If our useAltVocabWhen property evaluates to the special value of -1, then we
                 *   want the change to our altVocab to be permanent, so remove us from the list of
                 *   Things whose updateVocab() property is regularly called.
                 */
                if(uavw == -1 || finalizeVocabWhen)
                    libGlobal.altVocabLst -= self;
            }
        }
    }
    
    /* The previous return value from useAltVocabWhen - for internal library use only. */
    uavwNum = nil
    
    /* 
     *   Method designed to be called from the action() method of a dobjFor(XXX) block to display a
     *   message safely for an action that might be executed implicitly. If the action is implicit,
     *   the message won't be displayed until immediately after the implicit action reports. If the
     *   action isn't an implicit one, the message will be displayed straight away. The optional
     *   second msg2 parameter is a variant message for display immediately after the implicit
     *   action reports; otherwise msg will be used.
     */
    actionReport(msg, msg2?)
    {
        if(gAction.isImplicit)
            reportPostImplicit(msg2 ?? msg);
        else
            say(msg);
    }
    
    
    /* 
     *   The text (or method to display the text) to display in response to a THINK ABOUT command
     *   directed to this Mentionable. Note that this thinkDesc will only be used if the THINK ABOUT
     *   command is not handled by a Thought object.
     */    
    // thinkDesc = nil
;

/* ------------------------------------------------------------------------ */
/*
 *   Match a token from the player's input against a given vocabulary list.
 *   Returns a set of MatchXxx flags for a match, or 0 if there's no match.
 *   
 *   'tok' is the token string to match.  'words' is the list of words to
 *   match, as VocabWords objects.  'cmp' is the StringComparator object
 *   that we use to compare the strings.  
 */
matchToken(tok, words, cmp)
{
    /* we don't have a match for this token yet */
    local strength = 0, partOfSpeech = 0;

    /* try matching this token against our vocabulary list */
    for (local len = words.length(), local i = 1 ; i <= len ; ++i)
    {
        /* get this vocabulary word entry */
        local entry = words[i];

        /* check this token against the dictionary word */
        local match = cmp.matchValues(tok, entry.wordStr);

        /* if there's no match, keep looking */
        if (match == 0)
            continue;

        /* 
         *   Figure the result flags for this match.  Note that any
         *   bits in the String Comparator match value above 0x80
         *   are character approximation flags. 
         */
        local result =
            (match & StrCompTrunc ? 0 : MatchNoTrunc)
            | (match & ~0xFF ? 0 : MatchNoApprox);

        /* 
         *   Check the required match-strength flags to see if this
         *   match is allowed.  If a MatchNoXxx flag is set in the
         *   required flags in the dictionary entry, it means that
         *   the match itself MUST have that flag.  So, if a flag
         *   is set in the dictionary, and it's not set in the
         *   result, reject this match.  
         */
        if (entry.strengthFlags & ~result)
            continue;

        /*
         *   Okay, it's a match.  There are three possibilities for how
         *   it relates to other matches we've already found:
         *   
         *   - It's stronger, meaning that it's not truncated while the
         *   earlier match was, or not approximated while the earlier
         *   match was.  We only want to keep the strongest matche(es),
         *   so if we have a prior match, forget it.
         *   
         *   - It's equally strong.  We might have found another
         *   part-of-speech usage for the word at the same match
         *   strength.  Combine the part-of-speech flags into the
         *   running total.
         *   
         *   - It's weaker.  We only want to keep the best matches, so
         *   reject this one.  
         */
        if (result > strength)
        {
            /* it's stronger - replace any past match with this one */
            strength = result;
            partOfSpeech = entry.posFlags;
        }
        else if (result == strength)
        {
            /* equally strong - add this entry's part of speech */
            partOfSpeech |= entry.posFlags;
        }
    }

    /* return the combined MatchXxx flags */
    return strength | partOfSpeech;
}


/* ------------------------------------------------------------------------ */
/*
 *   A VocabWord is an entry in a Mentionable object's list of noun phrase
 *   words. 
 */
class VocabWord: object
    construct(w, f)
    {
        /* remember the word string */
        wordStr = w;

        /* separate out the part-of-speech and match-strength flags */
        posFlags = f & MatchPartMask;
        strengthFlags = f & MatchStrengthMask;
    }

    /* the word string (the text of this vocabulary word) */
    wordStr = nil

    /* the part-of-speech flags (MatchNoun, etc) */
    posFlags = 0

    /* the required match strength flags (MatchNoTrunc, MatchNoApprox) */
    strengthFlags = 0
;


/* ------------------------------------------------------------------------ */
/*
 *   A State represents a changeable condition of a Mentionable that can be
 *   used as part of the object's name in command input.  For example, a
 *   state could be used to represent whether a match is lit or unlit: the
 *   words 'lit' and 'unlit' could then be used to describe the object,
 *   according to its current condition.
 *   
 *   The actual current condition of a given object is given by a property
 *   of the Mentionable, which we define as part of the State object.  So
 *   testing whether an object is lit or unlit is just a matter of checking
 *   the corresponding property of the object.
 *   
 *   The parser considers an object to have the state, for parsing
 *   purposes, if the object defines any value for the state property.
 *   
 *   Most of the State object's definition is its vocabulary, which is
 *   obviously language-specific.  We therefore leave it to the language
 *   modules to define the individual State instances.  Games can also add
 *   new states as needed, of course.  
 */
class State: LState
    /*
     *   The Mentionable property that indicates the current condition of
     *   an object that has this State.  The range of values that this
     *   property takes on in the Mentionable is up to the State to define.
     *   For some states, this will be a simple boolean: Lit/Unlit,
     *   Open/Closed, On/Off, etc.  For others, this might be an integer
     *   range or a set of string values.
     */
    stateProp = nil

    /*
     *   Does this state apply to the given object?  By default, we
     *   consider any object that defines the state property to exhibit the
     *   state.  
     */
    appliesTo(obj) { return obj.propDefined(stateProp); }

    /*
     *   Match a token from the object name for the given state value.
     *   Mentionable.matchName() calls this to see if a token applies
     *   because of the object's current conditdion.  'tok' is the token
     *   string; 'state' is the object's value for the state property; and
     *   'cmp' is the string comparator to use for the string comparisons.
     *   Returns a combination of MatchXxx flags, or zero if the token
     *   doesn't match the current condition.
     *   
     *   For example, a Lit/Unlit state would return MatchAdj for 'lit' if
     *   'state' is true, 0 otherwise.  
     */
    matchName(tok, state, cmp)
    {
        /* get the vocabulary for the state; if none, there's no match */
        local v = getVocab(state);
        if (v == nil)
            return 0;

        /* compare the token against the list for the current state */
        return matchToken(tok, v, cmp);
    }

    /*
     *   Get the vocabulary words that apply to the given state.  For
     *   example, a Lit/Unlit object might return 'lit' if state is true
     *   and 'unlit' if state is nil.  
     */
    getVocab(state)
    {
        /* return the list for this state */
        return vocabTab[state];
    }

    /* state vocabulary lookup table (built automatically during preinit) */
    vocabTab = nil

    /*
     *   State/adjective initializer list.
     *   
     *   States are generally represented in names by adjectives added to
     *   the object name, both in displaying output and in parsing input.
     *   For example, a Lit/Unlit state would add 'lit' in the lit state
     *   and 'unlit' in the unlit state.  So we provide an easy way of
     *   initializing a state object: just list the states and their
     *   corresponding adjectives.
     *   
     *   Make one entry in this list for each possible state; the entry is
     *   a list, [stateval, [adjectives]], where 'stateval' is the state
     *   variable value, and [adjectives] is a list of strings giving the
     *   corresponding adjectives.  The first adjective in the list is the
     *   display adjective - this is the one that addToName() will use to
     *   generate an object name for display.  The rest are used to parse
     *   input; they'll all be matched to the state.  
     */
    adjectives = []

    /* 
     *   *Full* vocabulary initializer list.  If the 'adjectives' list
     *   isn't sufficiently flexible for your needs, you can use this
     *   initializer list instead.  This consists of a list of sublist
     *   entries, [stateval, word, flags].  'stateval' is a state value,
     *   'word' is a string giving a vocabulary word to match, and 'flags'
     *   is a combination of MatchXxx flags for the word.
     *   
     *.     [[nil, 'unlit', MatchAdj],
     *.      [true, 'lit', MatchAdj]]
     */
    vocabWords = []

    /* class property: master list of all State objects */
    all = []

    /* construction */
    construct()
    {
        /* create the vocabulary table */
        local tab = vocabTab = new LookupTable(8, 16);

        /* do the inherited work */
        inherited();

        /* load the vocabulary table from the adjectives list, if present */
        foreach (local a in adjectives)
        {
            /* make sure there's a list for this state */
            local st = a[1];
            if (tab[st] == nil)
                tab[st] = [];

            /* add a VocabWord for each adjective for this state */
            foreach (local adj in a[2])
            {
                initWord(adj);
                tab[st] += new VocabWord(adj, MatchAdj);
            }
        }

        /* load the vocabulary table from the vocabWords list, if present */
        foreach (local w in vocabWords)
        {
            /* 
             *   create an empty list for the state if this is the first
             *   word we've seen for this state 
             */
            local st = w[1];
            if (tab[st] == nil)
                tab[st] = [];

            /* add a VocabWord for this word to the state list */
            initWord(w[2]);
            tab[st] += new VocabWord(w[2], w[3]);
        }
    }

    /* class initialization */
    classInit()
    {
        /* build the master list of State objects */
        forEachInstance(State, { s: State.all += s });
    }
;

/*  
 *   A ReplaceRedirector is a Redirector that uses replaceAction (or its
 *   execNestedAction equivalent) to redirect one action to another.
 */
class ReplaceRedirector: Redirector
    
    /* 
     *   User code should normally call this method via doInstead rather than
     *   directly. cmd is the current command object, altAction is the action we
     *   want to perform instead of the current action, dobj and iobj are the
     *   direct and indirect objects of the new action, and isReplacement
     *   determines whether the new action replaces the original one (if true)
     *   or merely takes place during the execution of the original one, which
     *   then resumes when the new action is complete (if isReplacement is nil).
     */    
    redirect(cmd, altAction, dobj:?, iobj:?, aobj:?, isReplacement: = true)
    {
        if(iobj != nil && dobj != nil && aobj != nil)
            execNestedAction(isReplacement, gActor, altAction, dobj, iobj, aobj); 
        else if(iobj != nil && dobj != nil)    
            execNestedAction(isReplacement, gActor, altAction, dobj, iobj);
        else if(dobj != nil)
            execNestedAction(isReplacement, gActor, altAction, dobj);
        else
            execNestedAction(isReplacement, gActor, altAction);
    }
;

/* 
 *   Thing is the base class for all game objects that represent physical
 *   objects which can be interacted with in the game world. All such physical
 *   objects are either Things or based on a subclass of Thing.
 */
class Thing:  ReplaceRedirector, Mentionable
   
    
    /* 
     *   Most of the following properties and methods down to the next dashed
     *   line are usually only relevant on Room, but they have been moved to
     *   Thing in case the player char finds itself in a closed Booth.
     */
    
    /*   
     *   The title of this room to be displayed at the start of a room
     *   description, or in the status line.
     */
    roomHeadline(pov)
    {
        /* 
         *   start with the room title; if this room is illuminated use the
         *   standard roomTitle, otherwise use our darkName. 
         */
        say(isIlluminated ? roomTitle : darkName);

        /* if the actor is in an intermediate container, add the container */
        if (pov.location not in (self, nil))
            pov.location.roomSubhead(pov);
    }
    
    /* 
     *   Can the player character recognize this room (enough to know its name
     *   and have a rough idea of its location) in the dark? (If so then looking
     *   around in this room in the dark makes it visited and familiar,
     *   otherwise it doesn't).
     */
    recognizableInDark = nil
    
    /* The name to display at the head of a room description */
    roomTitle = name
    
    /* The name to display at the head of a room description when it's dark */
    darkName =  BMsg(dark name, 'In the dark')
    
    /* The description of the room when it's dark */
    darkDesc() 
    { 
        DMsg(dark desc, 'It{dummy} {is} pitch black; {i} {can\'t} see a thing.
            '); 
    }
    
    /*
     *   The "inside" description.  This is displayed when an actor LOOKS AROUND
     *   from within this object.  Note that this applies not only to top-level
     *   rooms but also to things like chairs, platforms, and booths that can
     *   contain an actor.  By default, we simply show the ordinary EXAMINE
     *   description (or the darkDesc if there's no illumination).  Non-room
     *   containers such as chairs or booths should usually override this to
     *   provide the view from inside the object, which usually differs from the
     *   ordinary EXAMINE description.  For a top-level room, you don't usually
     *   override this, since the only description needed for a room is normally
     *   the LOOK AROUND perspective.
     */    
    interiorDesc = (desc)

    /*  
     *   If we're a room, are we illuminated (is there enough light for an actor
     *   within us to see by)?
     */
    isIlluminated()
    {
        /* 
         *   If the room itself is lit, then it's self-illuminating and we don't
         *   need to check anything else.
         */        
        if(isLit)
            return true;
            
        /* 
         *   Otherwise we need to see if there's anything visible in the room's
         *   contents that's lit.
         */        
        return isThereALightSourceIn(contents);
    }
    
    /* 
     *   Determine (recursively) whether lst contains a light source; i.e.
     *   whether any of the items within list is lit or whether any of the
     *   visible contents of any of the items in lst it lit.
     */
    isThereALightSourceIn(lst)
    {
        foreach(local obj in lst)
        {
            /* If we find an object that's lit, return true. */
            if(obj.isLit)
                return true;
            
            /* 
             *   If we have any contents and our contents are visible from
             *   outside us, return true if there's a light source among our
             *   contents.
             */
            if(obj.contents.length > 0 
               && (obj.isOpen || obj.contType != In || obj.isTransparent)
               && isThereALightSourceIn(obj.contents))
                return true;                      
            
        }
        
        /* If we get this far we haven't found a light source. */        
        return nil;
    }
    
    /* 
     *   The contents lister to use for listing this room's miscellaneous
     *   contents. By default we use the standard lookLister but this can be
     *   overridden to use a CustomRoomLister (say) to provide just about any
     *   wording we like.
     */
    roomContentsLister = lookLister
    
    /* 
     *   The contents lister to use for listing this room's miscellaneous
     *   subcontents. By default we use the standard lookContentsLister but this
     *   can be overridden.
     */
    roomSubContentsLister = lookContentsLister
    
    /* 
     *   Do we want to use our interior desc even if we can see out to an enclosing location? By
     *   default we don't, but we may want to change this to true on Booths (or other enterable
     *   containers) where the immediate surroundings would be more apparent to someone viewing from
     *   within than those of the enlosing location.
     */
    useInteriorDesc = nil
    
    /* 
     *   Look around within this Thing (Room or Booth) to provide a full
     *   description of this location as seen from within, including our
     *   headline name, our internal description, and a listing of our visible
     *   contents.
     */
    lookAroundWithin()
    {
         /* Reset everything in the room to not mentioned. */
        unmention(contents);
        
        /* Reset everything in any remote rooms we're connected to */        
        unmentionRemoteContents();
        
        /* Begin by displaying our name */
        "<.roomname><<roomHeadline(gPlayerChar)>><./roomname>\n";
        
        if(gActionIn(GoTo, Continue) && !gameMain.verbose)
            return;

    
        
        /* The object whose interiorDesc we want to use. Normally this will be ourselves. */
        local descObj = self;
        
        /* Start from the actor's location and work outwards. */
        local loc = gActor.location;        
        
        /* 
         *   Iterate outwards till we've either reached ourselves or the outermost room or else a
         *   location that wants to use its interiorDesc in any case.
         */
        while(loc && loc != self)
        {
            if(loc.useInteriorDesc)
            {
                descObj = loc;
                break;
            }
            
            loc = loc.location;
        }
        
        
        /* If we're illuminate show our description and list our contents. */
        if(isIlluminated)
        {
            /* Display our interior description. */
            if(gameMain.verbose || !visited || gActionIs(Look))
                "<.roomdesc><<descObj.interiorDesc>><./roomdesc><.p>";
            
            /* List our contents. */
            "<.roomcontents>";
            listContents();
            "<./roomcontents>";
            
            /* Note that we've been seen, examined and visited. */
            setSeen();
            visited = true;
            examined = true;
        }
        
        /* 
         *   Otherwise, if there's not enough light to see by, just show our
         *   dark description.
         */
        else
        {
            /* Display the darkDesc */
            "<.roomdesc><<darkDesc>><./roomdesc>";
            
            /* 
             *   If this location is recognizable to the player character in the
             *   dark despite the poor lighting (for example, the PC knows it's
             *   a cellar because s/he's just descended a flight of steps that
             *   clearly lead to a cellar), note that we've been visited and
             *   that we're now known about (the pc knows of our existence).
             */
            if(recognizableInDark)
            {
                visited = true;
                setKnown();
            }
        
        }
        "<.p>";
        
        /* If the game includes an exit lister, list our exits. */        
        if(gExitLister != nil)
            gExitLister.lookAroundShowExits(gActor, self, isIlluminated);
    }
    
    /* List the contents of this object using lister. */
    listContents(lister = &roomContentsLister)
    {    
        
        /* Don't list the contents if we can't see in and we're not inside */
        if(!canSeeIn() && !gActor.isIn(self))
            return;
        
        /* 
         *   Set up a variable to contain the list of objects with specialDescs
         *   to be shown before the list of miscellaneous contents.
         */
        local firstSpecialList = [];
        
        /* Set up a variable to contain of list of miscellaneous contents. */
        local miscContentsList = [];
        
        /* 
         *   Set up a variable to contain the list of objects with specialDescs
         *   to be shown after the list of miscellaneous contents.
         */
        local secondSpecialList = [];
          
        /* 
         *   First mention the actor's immediate container, if it isn't the
         *   object we're looking around within. Then list the oontainer's
         *   contents immediately after.
         */        
        local loc = gActor.location;                
        
        /* 
         *   If we're not the pc's immediate container and we're looking around,
         *   start by describing the pc's immediate container and listing its
         *   contents.
         */
        if(loc != self && lister == &roomContentsLister)
        {
            /* 
             *   If there isn't a current action (e.g. because we're showing a
             *   room description before the first turn) create a Look Action to
             *   provide an action context for the gMessageParams() call that
             *   follows.
             */
            if(gAction == nil)
                gAction = Look.createInstance();
            
            /* Create a message parameter substitution. */
            gMessageParams(loc);
            
            /* 
             *   We start by describing the PC's immediate environment, provided the flag
             *   pclistedInLook is true.
             */
            if(loc.pcListedInLook)
            {
                /* Start by mentioning the PC's immediate container. */            
                DMsg(list immediate container, '{I} {am} {in loc}. <.p>');
                
                /* Note that the pc's immediate container has been mentioned. */
                loc.mentioned = true;
                
                /* 
                 *   If the pc's immediate container is a subcomponent (of a complex container
                 *   object), note that its parent has been mentioned.
                 */
                if(loc.ofKind(SubComponent) && loc.location != nil)
                    loc.location.mentioned = true;
            }
            
            /* 
             *   List the contents of the pc's immediate container, provided it's not hidden and its
             *   contentsListedInLook property is true
             */
            if(!loc.isHidden && loc.contentsListedInLook)            
                listSubcontentsOf([loc]);
        }
        
        /* List every listable item in our contents. */
        foreach(local obj in contents)
        {            
            /* Don't include any hidden items in the listing */
            if(obj.isHidden)
                continue;
            
            /* 
             *   If the object has an initSpecialDesc or a specialDesc which is
             *   currently in use, add it to the appropriate list.
             */
            if((obj.propType(&initSpecialDesc) != TypeNil &&
               obj.useInitSpecialDesc()) ||
               (obj.propType(&specialDesc) != TypeNil && obj.useSpecialDesc()))
            {
                /* 
                 *   If the specialDesc should be shown before the list of
                 *   miscellaneous items, add this object to the first list of
                 *   specials.
                 */
                if(obj.specialDescBeforeContents)
                    firstSpecialList += obj;
                
                /* Otherwise add it to the second list of specials. */
                else
                    secondSpecialList += obj;
            }
            /* 
             *   Otherwise add it to the list of miscellaneous items, provided
             *   it should be listed when looking around.
             */
            else if(obj.lookListed)
                miscContentsList += obj;
                      
            /* Note that the object has been seen by the pc. */
            obj.noteSeen();
        }
        
        /* Sort the first list of specials in order of their specialDescOrder */
        firstSpecialList = firstSpecialList.sort(nil, {a, b: a.specialDescOrder -
                                                 b.specialDescOrder});
                 
        /* Sort the second list of specials in order of their specialDescOrder */
        secondSpecialList = secondSpecialList.sort(nil, {a, b: a.specialDescOrder -
                                                 b.specialDescOrder});

        /* 
         *   Show the specialDesc (or initSpecialDesc) of all the objects in the
         *   first specials list.
         */
        foreach(local obj in firstSpecialList)        
            obj.showSpecialDesc();                
        
        /* 
         *   If we're listing the contents of a room, then show the specialDescs
         *   of any items in the other rooms in our SenseRegions, where
         *   specialDescBeforeContents is true
         */        
        if(lister == &roomContentsLister)
            showFirstConnectedSpecials(gPlayerChar);
        
        /* 
         *   Remove any items from the miscellaneous list that have already been
         *   mentioned.
         */
        miscContentsList = miscContentsList.subset({o: o.mentioned == nil});
                
        /* 
         *   Display the list of miscellaneous items using the lister passed as
         *   parameter to this method.         
         */
        self.(lister).show(miscContentsList, self);
               
        /*   List the contents of our contents. */
        listSubcontentsOf(contents, &roomSubContentsLister);
        
         /* 
          *   If we're not putting paragraph breaks between each subcontents
          *   listing sentence, insert a paragraph break after the lot before we
          *   list anything else.
          *
          */
            if(!paraBrksBtwnSubcontents)
                "<.p>";
        
        /* 
         *   If we're listing the contents of a room, then show the
         *   miscellaneous contents of other rooms in our sense regions
         */
        if(lister == &roomContentsLister)        
            showConnectedMiscContents(gPlayerChar);
                
        /* 
         *   Show the specialDesc (or initSpecialDesc) of every object in our
         *   second list of specials.
         */
        secondSpecialList = secondSpecialList.subset({o: o.mentioned == nil});
        
        foreach(local obj in secondSpecialList)
            obj.showSpecialDesc();
        
        
        /* 
         *   Show the specialDescs of any items in the other rooms in our
         *   SenseRegions, where specialDescBeforeContents is nil
         */
       if(lister == &roomContentsLister)
           showSecondConnectedSpecials(gPlayerChar);
    }
    
    /* 
     *   List the contents of every item in contList, recursively listing the
     *   contents of contents all the way down the containment tree. The
     *   contList parameter can also be passed as a singleton object.
     */
    listSubcontentsOf(contList, lister = &examineLister)
    {
       
        /* 
         *   If contList has been passed as a singleton value, convert it to a
         *   list, otherwise retain the list that's been passed.
         */
        contList = valToList(contList);
        
        /* 
         *   Ensure the contents of any associated remapXX items are included in
         *   the list of items whose contents are to be listed.
         */
        
        /* Initialize an empty list to collect the remapXXX items. */
        local lst = [];
        
        /* 
         *   Go through every item in the contList to see if it has any remapXXX
         *   objects attached. If so add the remapXXX object to our list.
         */
        foreach(local cur in contList)
        {
            foreach(local prop in remapProps)
            {
                local obj = cur.(prop);
                if(obj != nil)
                    lst += obj;
            }
        }
        
        /*  
         *   Append the list of remapXXX objects to the list of items whose
         *   contents are to be listed.
         */
        contList = contList.appendUnique(lst);
        
        /* Reduce the contList to items that the actor can see. */
        contList = contList.subset({o: gActor.canSee(o)});
        
        
 
        /* 
         *   Sort the contList in listOrder. Although we're listing the contents
         *   of each item in the contList, it seems good to mention each item's
         *   contents in the listOrder order of the item. Amongst other things
         *   this helps give a consistent ordering for the listing of 
         *   SubComponents.
         */
        contList = contList.sort(nil, {a, b: a.listOrder - b.listOrder});
                     
        
        foreach(local obj in contList)
        {
            /* 
             *   We don't explicitly list things in actors' inventory, but we
             *   should note them as seen if the player can see them.
             */            
            if(obj.contType == Carrier && markInventoryAsSeen)
                obj.allContents.subset({o: gPlayerChar.canSee(o) }).forEach( {o:
                    o.noteSeen() });           
            
            /* 
             *   Don't list the inventory of any actors, or of any items that
             *   don't want their contents listed, or any items we can't see in
             *   if the actor isnt' in them.
             *   or of any items that don't have any contents to list.
             */
            if(obj.contType == Carrier 
               || obj.(obj.(lister).contentsListedProp) == nil
               || (!gActor.isIn(obj) && obj.canSeeIn() == nil)
               || obj.contents.length == 0)
                continue;
            
                      
            /* 
             *   Don't list any items that have already been mentioned or which
             *   are hidden.
             */ 
            local objList = obj.contents.subset({x: x.mentioned == nil 
                                                && x.isHidden == nil
                                                && x != gPlayerChar});
            
            
            /* 
             *   Extract the list of items that have active specialDescs or
             *   initSpecial Descs
             */
            local firstSpecialList = objList.subset(
                {o: (o.propType(&specialDesc) != TypeNil && o.useSpecialDesc())
                || (o.propType(&initSpecialDesc) != TypeNil &&
                    o.useInitSpecialDesc() )
                }
                );
            
            
            /* 
             *   Remove items with specialDescs or initSpecialDescs from the
             *   list of miscellaneous items.
             */
            objList = objList - firstSpecialList;
            
            
            /*   
             *   From the list of items with specialDescs, extract those whose
             *   specialDescs should be listed after any miscellaneous items
             */
            local secondSpecialList = firstSpecialList.subset(
                { o: o.specialDescBeforeContents == nil });
            
            
            /* 
             *   Remove the items whose specialDescs should be listed after the
             *   miscellaneous items from the list of all items with
             *   specialDescs to give the list of items with specialDescs that
             *   should be listed before the miscellaneous items.
             */
            firstSpecialList = firstSpecialList - secondSpecialList;
            
            /*   
             *   Sort the list of items with specialDescs to be displayed before
             *   miscellaneous items by specialDescOrder
             */
            firstSpecialList = firstSpecialList.sort(nil, {a, b: a.specialDescOrder -
                b.specialDescOrder});
            
            /*   
             *   Sort the list of items with specialDescs to be displayed after
             *   miscellaneous items by specialDescOrder
             */
            secondSpecialList = secondSpecialList.sort(nil, {a, b: a.specialDescOrder -
                b.specialDescOrder});
            
            
            /*  
             *   Show the specialDescs of items whose specialDescs should be
             *   shown before the list of miscellaneous items.
             */
            firstSpecialList = firstSpecialList.subset({o: o.mentioned == nil});
            foreach(local cur in firstSpecialList)                    
                cur.showSpecialDesc(); 
            
            
            objList = objList.subset({o: o.mentioned == nil});
            /*   List the miscellaneous items */
            if(objList.length > 0)   
            {
                obj.(lister).show(objList, obj, paraBrksBtwnSubcontents);                      
                objList.forEach({o: o.mentioned = true });
            }
            
            /* 
             *   If we're not putting paragraph breaks between each subcontents
             *   listing sentence, insert a space instead.
             */
            if(!paraBrksBtwnSubcontents && secondSpecialList.indexWhich({o:o.isListed}))
                " ";
            
            
            /*  
             *   Show the specialDescs of items whose specialDescs should be
             *   shown after the list of miscellaneous items.
             */
            secondSpecialList = secondSpecialList.subset({o: o.mentioned == nil});
            foreach(local cur in secondSpecialList)        
                cur.showSpecialDesc(); 
            
            
            /* 
             *   Recursively list the contents of each item in this object's
             *   contents, if it has any; but don't list recursively for an
             *   object that's just been opened (for which the lister's
             *   listRecursively property should be nil).
             */
            local lstr = obj.(lister);
            
            if(obj.contents.length > 0 && lstr.listRecursively)
//               && obj.contents.countWhich({x: lstr.listed(x)}) > 0)
                listSubcontentsOf(obj.contents, lister);                     
            
        }         
    }
    
    /*   
     *   The name given to this object when it's the container for another object viewed remotely,
     *   e.g. 'in the distant bucket' as opposed to just 'in the bucket'. By default we just use the
     *   objInName. Tbis can also be used for situations when the pov and the object being viewed
     *   are in the same Room but one of them is in a Nested Room.
     */
     
    remoteObjInName(pov) { return objInName; }
    
    /* 
     *   Do we want paragraph breaks between the listings of subcontents (i.e.
     *   the contents of this item's contents)? By default we take our value
     *   from the global setting on gameMain.
     */
    paraBrksBtwnSubcontents = (gameMain.paraBrksBtwnSubcontents)
    
    /* 
     *   Mark everything item in lst as not mentioned , and carry on down the
     *   containment tree marking the contents of every item in lst as not
     *   mentioned.
     */
    unmention(lst)
    {
        foreach(local obj in lst)
        {
            obj.mentioned = nil;
            
            /* If obj has any contents, unmention every item in is contents */
            if(obj.contents.length > 0)
                unmention(obj.contents);
        }
    }
    
    /* 
     *   The next four methods are provided so that listContents() can call
     *   them, but they do nothing in the core library. They are overridden in
     *   senseRegion.t (for use if senseRegion.t is included in the build).
     */    
    unmentionRemoteContents() {}
    showFirstConnectedSpecials(pov) {}
    showConnectedMiscContents(pov) {}
    showSecondConnectedSpecials(pov) {}
    
    /*
     *   Display the "status line" name of the room.  This is normally a
     *   brief, single-line description.
     *   
     *   By long-standing convention, each location in a game usually has a
     *   distinctive name that's displayed here.  Players usually find
     *   these names helpful in forming a mental map of the game.
     *   
     *   By default, if we have an enclosing location, and the actor can
     *   see the enclosing location, we'll defer to the location.
     *   Otherwise, we'll display our roo interior name.  
     */
    statusName(actor)
    {
        /* 
         *   use the enclosing location's status name if there is an
         *   enclosing location and its visible; otherwise, show our
         *   interior room name 
         */
        if (location != nil && Q.canSee(actor, location))
            location.statusName(actor);
        else
        {
            roomHeadline(actor);
        }
    }
    
    /* 
     *   Get the estimated height, in lines of text, of the exits display's
     *   contribution to the status line.  This is used to calculate the
     *   extra height we need in the status line, if any, to display the
     *   exit list.  If we're not configured to display exits in the status
     *   line, this should return zero. 
     */
    getStatuslineExitsHeight()
    {
        if (gExitLister != nil)
            return gExitLister.getStatuslineExitsHeight();
        else
            return 0;
    }
    
    /* Show our exits in the status line */
    showStatuslineExits()
    {
        location.showStatuslineExits();
    }
    
    /* 
     *   Would this location be lit for actor. By default it would if it's
     *   illuminated.
     */
    wouldBeLitFor(actor)   
    {
        return getOutermostRoom.isIlluminated;
    }
    
//------------------------------------------------------------------------------  
    /* 
     *   From here on we have properties and methods relating to Things in
     *   general rather than just Rooms and Booths.
     */
    
    /* 
     *   The description of this Thing that's displayed when it's examined.
     *   Normally this would be defined as a double-quoted string, but in more
     *   complicated cases you could also define it as a method that displays
     *   some text.
     */
    desc = ""     
    
    /* 
     *   The state-specific description of this object, which is appended to its
     *   desc when examined. This is defined as a single-quoted string to make
     *   it easy to change at run-time.
     */
    stateDesc = ''
    
    /* 
     *   Additional information to display after our desc in response to an
     *   EXAMINE command.
     */
    examineStatus()
    {        
        /* First display our stateDesc (our state-specific information) */
        display(&stateDesc);
        
        /* 
         *   Then display our list of contents, unless we're a Carrier (an actor
         *   carrying our oontents) or our contentsListedInExamine is nil.
         */
        if(contType != Carrier && areContentsListedInExamine)
        {          
            /* 
             *   Start by marking our contents as not mentioned to ensure that
             *   they all get listed.
             */
            unmention(contents);
            
            /* Then list our contents using our examineLister. */
            listSubcontentsOf(self, &examineLister);            
        }                   
    }
    
    /* The lister to use to list an item's contents when it's examined. */    
    examineLister = descContentsLister
    
       
    /* 
     *   Has this item been mentioned yet in a room description. Note that this
     *   flag is used internally by the library; it shouldn't normally be
     *   necessary to manipulate it directly from game code.
     */
    mentioned = nil
    
    /* 
     *   Simpply return the value of contentsListedInExamine. We supply this extra step to faciliate
     *   overrrding this in senseRegion.t to allow for remotv viewing.
     */
    areContentsListedInExamine = contentsListedInExamine
    
    /* 
     *   Do we want this object to report whether it's open? By default we do if
     *   it's both openable and open.
     */
    openStatusReportable = (isOpenable && isOpen)
            
    /* 
     *   If present, a description of this object shown in a separate paragraph
     *   in the listing of the contents of a Room. If specialDesc is defined
     *   then this paragraph will be displayed regardless of the value of
     *   isListed.
     */    
    specialDesc = nil
    
    /* 
     *   Should the specialDesc be used? Normally we use the specialDesc if we
     *   have one, but we may want to override this for particular cases. For
     *   example, if we want an item to have a paragraph to itself until it's
     *   moved we could define useSpecialDesc = (!moved) [making it equivalent
     *   to initSpecialDesc]. Note that the useSpecialDesc property only
     *   has any effect if specialDesc is not nil.
     */ 
    useSpecialDesc = true
    
    
    /* A specialDesc that's shown until this item has been moved */
    initSpecialDesc = nil
    
    
    /* 
     *   By default we use the initSpecialDesc until the object has been moved,
     *   but this can be overridden with some other condition.
     */
    useInitSpecialDesc = (!moved)
    
    /*  
     *   The specialDescOrder property controls where in a series of specialDesc
     *   paragraphs this item is mentioned: the higher the number, the later it
     *   will come relative to other items. Note that this does not override the
     *   specialDescBeforeContents setting.
     */
    specialDescOrder = 100
    
    /*   
     *   Is this item listed before or after the list of miscellaneous contents
     *   in the room. By default we'll show the specialDesc of items before
     *   miscellaneous items in a room description but afterwards otherwise:
     *   this places specialDescs in a more logical order in relation to the
     *   text of listers used to list the contents of obejcts other than rooms.
     */    
    specialDescBeforeContents = (location && location.ofKind(Room))
    
    /* For possible future use; at the moment this doesn't do anything */
    specialDescListWith = nil
    
    
    /* Show our specialDesc or initSpecialDesc, as appropriate */
    showSpecialDesc()
    {
        /* 
         *   If we've already been mentioned in the room description, don't show
         *   us again. Otherwise note that we've now been mentioned.
         */
        if(mentioned)
            return;
        
        
        
        /* 
         *   If we have an initSpecialDesc and useInitSpecialDesc is true, show
         *   our initSpecialDesc, otherwise show our specialDesc.
         */
        if(propType(&initSpecialDesc) != TypeNil && useInitSpecialDesc)
        {
            initSpecialDesc;
            
            mentioned = true;
        }       
        else if(propType(&specialDesc) != TypeNil)
        {        
            specialDesc;
            
            mentioned = true;
        }
           
        /*  Add a paragraph break. */
        if(mentioned)
            "<.p>";
        
        /* Note that we've been seen. */
        noteSeen();
    }
    
    
    
    /* 
     *   Flag to indicate whether this item is portable (nil) or fixed in place
     *   (true). If it's fixed in place it can't be picked up or moved around
     *   (by player commands).
     */    
    isFixed = (isDecoration)
    
    /* 
     *   Is this item listed in room descriptions and the like. We tend to list
     *   portable items but not those fixed in place, so we make this the
     *   default.
     */
    
    /*   
     *   A global isListed property that can be used to set the value of all the
     *   others. By default we're listed if we're not fixed in place.
     */
    isListed = (!isFixed)
    
    /*  
     *   Flag: is this item listed in a room description (when looking around).
     */
    lookListed = (isListed)
    
    /* Flag: is this item listed in an inventory listing. */
    inventoryListed = (isListed)
    
    /* Flag: is this item listed when its container is examined. */    
    examineListed = (isListed)
    
    /* 
     *   Flag: is this item listed when is container is searched (or looked in).
     */
    searchListed = (isListed)
    
    /*  
     *   Flag: should this item's contents be listed? This can be used to
     *   control both contentsListedInLook and contentsListedInExamine.
     */
    contentsListed = true
    
    /*  
     *   Flag: should this item's contents be listed as part of a room
     *   description (when looking around).
     */
    contentsListedInLook = (contentsListed)
    
    /*  
     *   Fllag: should the Player Character be listed as being in this object as part of a room
     *   description (this is often useful but may sometimes look redundant)? By default we take out
     *   value from contentsListedInLook.
     */
    pcListedInLook = (contentsListedInLook)
    
    /*  
     *   Flag: should this item's contents be listed when its container is
     *   examined.
     */
    contentsListedInExamine = (contentsListed)
    
    /*  
     *   Flag, should this item's contents be listed when it is searched (by
     *   default this is simply true, since it would be odd to have a container
     *   that failed to reveal its contents when searched).
     */
    contentsListedInSearch = true
    
    /*
     *   Flag, if our contType is Carrier (i.e. we're an Actor), should our
     *   contents be marked as seen even though it hasn't been listed in a room
     *   description? By default this is set to true, on the basis that the
     *   inventory (and parts) of an actor would normally be in plain sight.
     */    
    markInventoryAsSeen = true
    
    /*
     *   The text we display in response to a READ command. This can be nil
     *   (if we're not readable), a single-quoted string, a double-quoted string
     *   or a routine to display a string.     */
    
    readDesc = nil
    
    /* The description displayed in response to a SMELL command */
    smellDesc = nil
    
    /* 
     *   Is the this object's smellDesc displayed in response to an intransitive
     *   SMELL command? (Only relevant if smellDesc is not nil)
     */
    isProminentSmell = true
    
    /*   The description displayed in response to a FEEL or TOUCH command */
    feelDesc = nil
    
    /*   
     *   By default TOUCH and FEEL both do the same things and both use feelDesc, but if game code
     *   wants to override dobjFor(Touch) to distinguish them it may want to use a touchDesc
     *   property for TOUCH.
     */
//    touchDesc = feelDesc
    
    /*   The description displayed in response to a LISTEN command */
    listenDesc = nil
    
    /* 
     *   Is the this object's listenDesc displayed in response to an
     *   intransitive LISTEN command? (Only relevant if listenDesc is not nil)
     */
    isProminentNoise = true
    
    /*   The description displayed in response to a TASTE command */
    tasteDesc = nil
      
    /*  The subset of our contents that should be listed. */
    listableContents = (contents.subset({x: x.lookListed}))
    
    /* The subset of the contents of cont that should be listed. */
    listableContentsOf(cont)
    {
        local lst = [];
        foreach(local obj in cont.contents)
        {
            if(obj.isListed)
                lst += obj;
        }
        return lst;    
    }
    
    /* 
     *   Our globalParamName is an arbitrary string value that can be used to
     *   refer to this thing in a message substitution parameter; for code
     *   readability it may be a good idea to make this a string representation
     *   of our programmatic name (where we want to define it at all).
     */
    globalParamName = nil
    
   
    /* 
     *   Is this object lit, i.e. providing sufficient light to see not only
     *   this object but other objects in the vicinity by.
     */    
    isLit = nil
    
    /* Make this object lit or unlit */
    makeLit(stat) { isLit = stat; }
    
    /* 
     *   Is this object visible in the dark without (necessarily) providing
     *   enough light to see anything else by, e.g. the night sky.
     */
    visibleInDark = nil
    
    /*   
     *   An optional description to be displayed instead of our normal desc and
     *   any status information (such as our contents) if we're examined in a
     *   dark room and visibleInDark is true. Note that if visibleInDark is nil
     *   inDarkDesc will never be used.
     */
    inDarkDesc = nil
    
    /* 
     *   Is this object lightable (via a player command)? Note that setting this
     *   property to true also automatically makes the LitUnlit State applicable
     *   to this object, allowing it to be referred to as 'lit' or 'unlit' as
     *   appropriate.
     */
    isLightable = nil
    
    /*   
     *   The preposition that should be used to describe containment within this
     *   thing (e.g. 'in', 'on' , 'under' or 'behind'). By default we get this
     *   from our contType.
     */
    objInPrep = (contType.prep)
    
    /*   
     *   The preposition that should be used to describe movement to within this
     *   thing (e.g. 'into', 'onto' , 'under' or 'behind'). By default we get
     *   this from our contType.
     */
    objIntoPrep = (contType.intoPrep)
    
    /*   
     *   This object's bulk, in arbitrary units (game authors should devise
     *   their own bulk scale according to the needs of their game).
     */
    bulk = 0
    
    /*   
     *   The maximum bulk that can be contained in this Thing. We set a very
     *   large number by default.
     */
    bulkCapacity = 10000
    
    /*   
     *   The maximum bulk that a single item may have to be inserted into (onto,
     *   under, behind) this object; by default this is the same as the bulk
     *   capacity, but you could set a lower value, e.g. to model a bottle with
     *   a narrow neck.
     */
    maxSingleBulk = (bulkCapacity)
    
    
    /* 
     *   The maximum number of items we can hold, irrespective of their bulk (or weight). By default
     *   we make this a very large number so there's no effective limit; game code can set a lower
     *   limit on the player character and/or other actors.
     */
    maxItemsCarried = 100000
    
    /*   Calculate the total bulk of the items contained within this object. */
    getBulkWithin()
    {
        local totalBulk = 0;
        foreach(local cur in contents)
            totalBulk += cur.bulk;
        
        return totalBulk;
    }
    
    /*  
     *   Calculate the total bulk carried by an actor, which excludes the bulk
     *   of any items currently worn or anything fixed in place.
     */
    getCarriedBulk()
    {
        local totalBulk = 0;
        foreach(local cur in directlyHeld)
        {           
            totalBulk += cur.bulk;
        }
        
        return totalBulk;
    }
    
    /*  
     *   Check whether an item can be inserted into this object, or whether
     *   doing so would either exceed the total bulk capacity of the object or
     *   the maximum bulk allowed for a single item.
     */
    checkInsert(obj)
    {
        /* Create a message parameter substitution. */
        gMessageParams(obj);
        
        /* 
         *   If the bulk of obj is greater than the maxSingleBulk this Thing can
         *   take, or greater than its overall bulk capacity then display a
         *   message to say it's too big to fit inside ue.
         */
        if(obj.bulk > maxSingleBulk || obj.bulk > bulkCapacity)
            DMsg(too big, '{The subj obj} {is} too big to fit {1} {2}. ', 
                 objInPrep, theName);
            
        /* 
         *   Otherwise if the bulk of obj is greater than the remaining bulk
         *   capacity of this Thing allowing for what it already contains,
         *   display a message saying there's not enough room for obj.
         */
        else if(obj.bulk > bulkCapacity - getBulkWithin())
            DMsg(no room, 'There {dummy} {is} not enough room {1} {2} for {the
                obj}. ', objInPrep, theName);            
    }
    
    
    /* The list of possible remap props */
    remapProps = [&remapOn, &remapIn, &remapUnder, &remapBehind]
    
    
    /* 
     *   If remapIn is not nil, a LOOK IN, PUT IN, OPEN, CLOSE, LOCK or UNLOCK
     *   command performed on this Thing will be redirected to the object
     *   specified on remapIn. In other words, remapIn specifies the object that
     *   acts as our proxy container.
     */
    remapIn = nil
    
    /* 
     *   If non-nil, remapOn speficies the object that acts as our proxy
     *   surface, in other words the object to which PUT ON will be redirected.
     */
    remapOn = nil
    
    /*  
     *   If non-nil, remapUnder specified the object that acts as our proxy
     *   underside, i.e. the object to which any PUT UNDER or LOOK UNDER action
     *   directed at us will be redirected.
     */
    remapUnder = nil
    
    /*  
     *   If non-nil, remapUnder specified the object that acts as our proxy
     *   rear, i.e. the object to which any PUT BEHIND or LOOK BEHIND action
     *   directed at us will be redirected.
     */
    remapBehind = nil
    
    
    /* 
     *   Our notional total contents is our normal contents plus anything
     *   contained in any of our remapXX objects representing our associated
     *   proxy container, surface, underside and rear, excluding anything in a
     *   closed opaque container (which would not be visible).
     */    
    notionalContents()
    {
        local nc = [];
        
        if(isTransparent || !enclosing)
            nc = contents;
        if(remapIn != nil && (remapIn.isTransparent || !remapIn.enclosing))
            nc = nc + remapIn.contents;
        if(remapOn != nil)
            nc = nc + remapOn.contents;
        if(remapUnder != nil)
            nc = nc + remapUnder.contents;
        if(remapBehind != nil)
            nc = nc + remapBehind.contents;
        
        return nc;
    }
    
    /* 
     *   A list of objects that are treated as hidden under this one. A LOOK
     *   UNDER command will list them and move them into the enclosing room. It
     *   follows that objects placed in this property should not be given an
     *   initial location. This should deal with the most common reason for
     *   wanting items to be placed under things (i.e. to hide them). Note, the
     *   items in the hiddenUnder property should also be revealed when the
     *   player moves the hiding item.
     */    
    hiddenUnder = []
    
    /* 
     *   A list of objects that are treated as hidden behind this one. A LOOK
     *   BEHIND command will list them and move them into the enclosing room. It
     *   follows that objects placed in this property should not be given an
     *   initial location. This should deal with the most common reason for
     *   wanting items to be placed behind things (i.e. to hide them). Note, the
     *   items in the hiddenBehind property should also be revealed when the
     *   player moves the hiding item.
     */   
    hiddenBehind = []
    
    /* 
     *   A list of objects that are treated as hidden inside this one. A LOOK IN
     *   command will list them and move them into the enclosing room (or in
     *   this one if we're a container). It follows that objects placed in this
     *   property should not be given an initial location.
     */   
    hiddenIn = []
    
    
    /* 
     *   The maximum bulk that can be hidden under, behind or in this object,
     *   assuming that the player can put anything there at all. Note that this
     *   only affects what the player can place there with PUT IN, PUT UNDER and
     *   PUT BEHIND commands, not what can be defined there initially or moved
     *   there programmatically.
     */    
    maxBulkHiddenUnder = 100
    maxBulkHiddenBehind = 100
    maxBulkHiddenIn = 100
    
    /* The total bulk of items hidden in, under or behind this object */    
    getBulkHiddenUnder = (totalBulkIn(hiddenUnder))
    getBulkHiddenIn = (totalBulkIn(hiddenIn))
    getBulkHiddenBehind = (totalBulkIn(hiddenBehind))
    
    /* Calculate the total bulk of the items in lst */
    totalBulkIn(lst)
    {
        local totBulk = 0;
        for(local item in valToList(lst))
            totBulk += item.bulk;
        
        return totBulk;
    }
                          
    /* 
     *   Flag, do we want to treat this object as hidden from view (so that the
     *   player can't interact with it)?
     */
    isHidden = nil
    
    /* 
     *   Make a hidden item unhidden. If the method is called with the optional
     *   parameter and the parameter is nil, i.e. discover(nil), the method
     *   instead hides the object.
     */
    discover(stat = true)
    {
        isHidden = !stat;
        
        /* 
         *   If the player character can see me when I'm hidden, note that the
         *   player character has now seen me.
         */
        if(stat && Q.canSee(gPlayerChar, self))
            noteSeen();
    }
       
    /* 
     *   The lockability property determines whether this object is lockable and
     *   if so how. The possible values are notLockable, lockableWithoutKey,
     *   lockableWithKey and indirectLockable.
     */    
    lockability = keyList == nil ? notLockable : lockableWithKey
    
    /* 
     *   Flag: is this object currently locked. By default we start out locked
     *   if we're lockable.
     */
    isLocked = lockability not in (nil, notLockable)
        
    /* 
     *   Make us locked or ublocked. We define this as a method so that
     *   subclasses such as Door can override to produce side effects (such as
     *   locking or unlocking the other side).
     */    
    makeLocked(stat)
    {
        isLocked = stat;
    }
    
    /* 
     *   Can this object be switched on and off? 
     */
    isSwitchable = nil
    
    /* is this item currently switched on? */
    isOn = nil
    
    /* switch this item on or off */
    makeOn(stat) { isOn = stat; }
    
    /* is this object something that can be worn */
    isWearable = nil
    
    /* 
     *   If this object is currently being worn by someone, the wornBy property
     *   contains the identity of the person wearing it.
     */
    wornBy = nil
    
    /* 
     *   Make this object worn or not worn. If this object is worn, note who     
     *   it's worn by. If stat is nil the object is no longer being worn.
     */    
    makeWorn(stat)  { wornBy = stat; }
    
    /* are we directly held by the given object? */
    isDirectlyHeldBy(obj) { return location == obj && !isFixed && wornBy == nil; }

    /* 
     *   Get everything I'm directly holding, which is everything in my
     *   immediate contents which is neither fixed in place nor being worn.
     */
    directlyHeld = (contents.subset({ obj: !obj.isFixed &&
            obj.wornBy == nil }))

    /* are we worn by the given object, directly or indirectly? */
    isWornBy(obj)
    {
        return (location == obj ? wornBy == obj :
                location != nil && location.isWornBy(obj));
    }

    /* are we directly worn by the given object? */
    isDirectlyWornBy(obj) { return location == obj && wornBy == obj; }

    /* get everything I'm directly wearing */
    directlyWorn = (contents.subset({ obj: obj.wornBy == self }))
    
    
    
    /* 
     *   Flag: can under objects be placed under us? By default they can if our
     *   contType is Under. If this is set to true and our contType is not
     *   Under, anything placed under us will be treated as hidden under.
     */
    canPutUnderMe = (contType == Under)
    
    /* 
     *   Flag: can under objects be placed behind us? By default they can if our
     *   contType is Behind. If this is set to true and our contType is not
     *   Behind, anything placed behind us will be treated as hidden behind.
     */
    canPutBehindMe = (contType == Behind)    
    
    /* 
     *   Flag: can under objects be placed inside us? By default they can if our
     *   contType is In. If this is set to true and our contType is not
     *   In, anything placed in us will be treated as hidden in.
     */
    canPutInMe = (contType == In)    
    
    
    /* 
     *   Can an actor enter (get in or on) this object. Note that for such an
     *   action to be allowing the contType must also match the proposed action.
     */    
    isBoardable = nil
    
    /* Flag: Can this thing be eaten */
    
    isEdible = nil  
   
    /* 
     *   Flag, if this object appears more than once in the list of objects to the current action,
     *   do we want all the duplicates removed from the list leaving only one instance? By default
     *   we most probably do.
     */
    combineDuplicateObjects = true
    
    /*
     *   My nominal contents is the special contents item we can use in
     *   naming the object.  This is useful for containers whose identities
     *   come primarily from their contents, such as a vessel for liquids
     *   or a box of loose files.  Returns an object that qualifies the
     *   name: a "water" object for BOX OF WATER, a "files" object for BOX
     *   OF FILES.  Nil means that the object isn't named by its contents.
     *   
     *   Note that this is always a single object (or nil), not the whole
     *   list of contents.  We can only be named by one content object.
     *   (So you can't have a "box of books and papers" by having separate
     *   nominal contents objects for the books and the papers; although
     *   you could fake it by creating a "books and papers" object.)  
     */
    nominalContents = nil

    /* 
     *   Can I be distinguished in parser messages by my contents?  If so,
     *   we can be distinguished (in parser messages) from similar objects
     *   by our contents, or lack thereof: "bucket of water" vs "empty
     *   bucket".  If this is true, our nominalContents property determines
     *   the contents we display for this.  
     */
    distinguishByContents = nil

    
      /*
       *   This object's containment type - that is, the locType for direct
       *   children.  This is given as one of the spatial relation types (In,
       *   On, Under, Behind etc).      
       */
    contType = Outside
    
    
    /* The list of things directly contained by this object */
    contents = [ ]
    
    /* 
     *   The location of this object, i.e. this object's immediate container
     *   (which may be another Thing, a Room, or an Actor such as the player
     *   char). Note that while you should specify the initial location of an
     *   object via this property you should never directly alter this property
     *   in game code thereafter; to change the location on object during the
     *   the course of a game use the moveInto(loc) or actionMoveInto(loc)
     *   method.
     */
    location = nil
    
    /*  
     *   Add an item to this object's contents. Normally this method is used
     *   internally in the library than directly by game code. If the vec
     *   parameter is supplied, the object added to our contents is also added
     *   to vec; again this is intended primarily for internal use by the
     *   library.
     */
    addToContents(obj, vec?)
    {
        contents = contents.appendUnique([obj]);
        if(vec != nil)
            vec.appendUnique(self);
    }
    
    /*  
     *   Remove an item to this object's contents. Normally this method is used
     *   internally in the library than directly by game code. If the vec
     *   parameter is supplied, the object removed from our contents is also
     *   removed from vec; again this is intended primarily for internal use by
     *   the library.
     */
    removeFromContents(obj, vec?)
    {
        local idx = contents.indexOf(obj);
        if(idx != nil)
            contents = contents.removeElementAt(idx);
        
        if(vec != nil)
            vec.removeElement(self);
    }

    /* 
     *   Basic moveInto for moving an object from one container to another by
     *   programmatic fiat.
     */    
    moveInto(newCont)
    {
        /* If we have a location, remove us from its list of contents. */
        if(location != nil)            
            location.removeFromContents(self);
        
        /* 
         *   If we have changed location, we are no longer being worn by our
         *   original location and we are no longer in our notional moveTo location.
         */
        if(newCont != location)
        {
            wornBy = nil; 
            
            movedTo = nil;
        }
        
        /* Set our new location. */
        location = newCont;
               
        /* 
         *   Provided our new location isn't nil, add us to our new location's
         *   list of contents.
         */
        if(location != nil)
            location.addToContents(self);        
    }
    
    /* Move into generated by a user action, which includes notifications */
    actionMoveInto(newCont)
    {
        /* 
         *   If we have a location, notify our existing location that we're
         *   about to be removed from it.
         */
        if(location != nil)
            location.notifyRemove(self);            
        
        /* 
         *   If the location we're about to be moved into is non-nil, notify our
         *   new location that we're about to be moved into it. Note that both
         *   this and the previous notification can veto the move with an exit
         *   command.
         */
        if(newCont != nil)
            newCont.notifyInsert(self); 
        
        /* Note which room we're in before the moce. */
        local oldRoom = trackedLocation;
        
        /* Carry out the move. */
        moveInto(newCont);
        
        /* Note that we have been moved. */
        moved = true;
        
        /* If the player character can now see us, note that we've been seen */
        if(Q.canSee(gPlayerChar, self))
            noteSeen();
        
        /* 
         *   Set up a local variable for our new room; this avoids needing to calculate the value of
         *   getOutermostRoom twice.
         */
        local newRoom;
        
        /* 
         *   If we're recording location history for this object and we'v moved to a new room,
         *   update our location history.
         */
        if(locationHistoryLength && oldRoom != (newRoom = trackedLocation))
            updateLocationHistory(newRoom);
            
    }
    
       
    
    /* 
     *   Receive notification that obj is about to be removed from inside us; by default we do
     *   nothing. Do NOT use this method to prevent the removal of the object from us; use
     *   checkRemove(obj) instead.
     */
    notifyRemove(obj) { }
    
    /* 
     *   checkRemove is called from the check stage of an action (typically TAKE) that might remove
     *   obj from me. If it wants to object to the removal of the object, it should simply display a
     *   message explaining why. By default we call the same method our container to check whether
     *   anything in our containment hierarchy objects to the removal. If this method is overridden
     *   in game code it may only need to call inherited(obj) on any branch that doesn't itself
     *   object to the removal.
     */
    checkRemove(obj) 
    {  
        if(location)
            location.checkRemove(obj); 
    }
    
    /* 
     *   Receive notification that obj is about to be inserted into us; by
     *   default we do nothing.
     */
    notifyInsert(obj) { }
    
    /* 
     *   Flag, if location tracking is active, do we want to track only the rooms this object has
     *   been in, or track every location its been directl in. By default we only track rooms.
     */
    trackRoomsOnly = true
    
    
    /* 
     *   The location we're tracking is this obect's outermost location if trackRoomsOnly is true or
     *   its location otherwise. This property can be overridden in user code if tracking some other
     definition of location is desired, e,g, trackedLocation = (isIn(me) ? me : location).
     */
    trackedLocation = (trackRoomsOnly ? getOutermostRoom : location)
    
    /* 
     *   The number of previous room locations to keep track of. By default this is nil, meaning we
     *   don't normally track this object's previous rooms.
     */
    locationHistoryLength = nil
    
    /*   
     *   Thus object's previous location history. If present, this will be list of up to
     *   locationHistoryLength elements with the most recent (i.e. current) room location last.
     */
    locationHistory = nil
    
    /*  Returns a List containing the actor’s location history.*/    
    getLocationHistory()  { return valToList(locationHistory); }
    
    updateLocationHistory(newRoom)
    {
        /* Add the new room to our location history) */
        locationHistory = valToList(locationHistory)  + newRoom;
        
        /* 
         *   If the resultant list islonger than our required locatio0n history length, truncate our
         *   locationHistory list accordingly.
         */
        if(locationHistory.length > locationHistoryLength)
            locationHistory = locationHistory.cdr();    
    }
    
    /* 
     *   Returns the most recent room location, not counting the current one, that this object
     *   occupied.
     */
    getPreviousLocation()
    {
        /* Obtain the index of the last but one enty in our locationHistory list. */
        local idx = valToList(locationHistory).length - 1;
        
        /* 
         *   If that index is greater than 0, return the last but one item in the list, otherwise
         *   return nil.
         */
        return idx > 0 ? locationHistory[idx] : nil ;
    }
    
    /* 
     *   Move a MultiLoc (ml) into this additional Thing or Room, by adding it
     *   to this thing's contents list and adding the Thing to ml's
     *   locationList.
     */
    moveMLIntoAdd(ml)
    {
        if(contents.indexOf(ml) == nil)
            addToContents(ml);     
        
        
        if(ml.locationList.indexOf(self) == nil)
            ml.locationList += self;
    }
    
    /*  
     *   Move a MultiLoc (ml) out of this object, by removing it from our
     *   contents list and removing us from its locationList.
     */
    moveMLOutOf(ml)
    {
        removeFromContents(ml);  
        
        ml.locationList -= self;    
    }
    
    
    
    /* Is obj visible from us? */
    canSee(obj) { return Q.canSee(self, obj); }
    
    /* Is obj audible from us? */
    canHear(obj) { return Q.canHear(self, obj); }
    
    /* Is obj smellable from us? */
    canSmell(obj) { return Q.canSmell(self, obj); }
    
    /* Is obj reachable (by touch) from us? */
    canReach(obj) { return Q.canReach(self, obj); }
    
    /* 
     *   We define canTouch(obj) to do the same as canReach(obj) in case game code tries to call
     *   canTouch() on analogy with canSee(), canHear() and canSmell().
     */
    canTouch(obj) { return canReach(obj); }
    
    
     /* 
     *   Are we a containment "child" of the given object with the given
     *   location type?  This returns true if our location is the given
     *   object and our locType is the given type, or our location is a
     *   containment child of the given object with the given type.
     *   
     *   'typ' is a LocType giving the relationship to test for, or nil.
     *   If it's nil, we'll return true if we have any containment
     *   relationship to 'obj'.  
     */
    isChild(obj, typ)    
    {
        /* 
         *   If the typ we're testing for is neither nil nor the containment
         *   type of obj, return nil.
         */
        if(typ not in (nil, obj.contType))
            return nil;
        
        /* Otherwise return whether or not we're in obj. */
        return isIn(obj);
    }

    /* 
     *   Are we a direct containment child of the given object with the
     *   given containment type?  'typ' is a LocType giving the
     *   relationship to test for, or nil.  If it's nil, we'll return true
     *   if we have any direct containment relationship with 'obj'. 
     */
    isDirectChild(obj, typ)
    {
        /* 
         *   If the typ we're testing for is neither nil nor the containment
         *   type of obj, return nil.
         */
        if(typ not in (nil, obj.contType))
            return nil;
        
        /* Otherwise return whether or not we're directly in obj. */
        return isDirectlyIn(obj);
    }
    
    
    /*  Are we directly in cont? */
    isDirectlyIn(cont)
    {
        /* If cont is nil then we're in cont if our location is nil. */
        if(cont == nil)
            return location == nil;
        
        /* 
         *   Otherwise we're directly in cont either if our location is cont or
         *   if we're in cont's contents list (the latter test caters for
         *   MultiLocs).
         */
        return location == cont || valToList(cont.contents).indexOf(self) != nil;
    }
    
    /* Are we in cont? */
    isIn(cont)
    {
        /* If we're directly in cont, then we're certainly in cont. */
        if(isDirectlyIn(cont))
            return true;
        
        /* Otherwise if our location is nil, we're not in cont */
        if(location == nil)
            return nil;
        
        /* Otherwise we're in cont if our location is in cont. */
        return location.isIn(cont);
    }
    
    /* Are either oont or in cont ? */
    isOrIsIn(cont)
    {
        return self == cont || isIn(cont);
    }
    
     /*
     *   Get my list of enclosed direct contents.  This is the subset of my
     *   direct contents that have interior location types (In).  
     */
    intContents = ( contType == In ? contents : [] )

    /*
     *   Get my list of unenclosed direct contents.  This is the subset of
     *   my direct contents that have exterior location types (On, Outside,
     *   Behind, Under). 
     */
    extContents = ( contType == In ? [] : contents)

    /* 
     *   The isInitialPlayerChar property was formerly used as an alternative method of identifying
     *   the player character. This method of doing so is now deprecated, except for its use on the
     *   Player class. Instead you should now define the player character on
     *   gameMain.initialPlayerChar
     */    
    isInitialPlayerChar = nil
    
    /* Carry out the preinitialization of a Thing */
    preinitThing()
    {
        /*    
         *   If I am meant to be the initial player character and gameMain does
         *   not already define another one, register this object as the initial
         *   player character.
         */
        if(isInitialPlayerChar && gameMain.propType(&initialPlayerChar) != TypeObject)
        {
            /* Register me as the initial player character on gameMain */
            gameMain.initialPlayerChar = self;
            
            /* Register me as the current player character on libGlobal */
            gPlayerChar = gameMain.initialPlayerChar;
        }
        
        
        /* 
         *   If we have both a location and a subLocation (which should be a
         *   property pointer if it's not nil), change our location to the
         *   object defined on the subLocation property of our location; this is
         *   used to place objects in the SubComponents of their parent objects.
         */
        if(subLocation != nil && location != nil)
            location = location.(subLocation);
        
        /*   If we have a location, add ourselves to its contents list. */
        if(location != nil)
            location.addToContents(self);
        
        /* if we have a global parameter name, add it to the global table */
        if (globalParamName != nil)
            libGlobal.nameTable_[globalParamName] = self;
        
        /* If our owner property isn't already a list, convert it to one. */
        owner = valToList(owner);
        
        /* If we have a keyList, add ourselves to every key in the list */
        if(keyList != nil)
        {
            foreach(local key in valToList(keyList))
            {
                if(key.ofKind(Key))
                {
                    key.actualLockList = key.actualLockList.appendUnique([self]);
                    key.plausibleLockList = key.plausibleLockList.appendUnique([self]);
                }
            }
            
            foreach(local key in valToList(knownKeyList))
            {
                if(key.ofKind(Key))
                {
                    key.knownLockList = key.knownLockList.appendUnique([self]);                    
                }
            }       
                    
        }
        
        /* 
         *   if we have any remapXXX properties, set those objects to the same
         *   listOrder as our own, since they're effectively representations of
         *   ourself.
         */
        
        for(local prop in remapProps)
        {
            local obj = self.(prop);
            if(obj)
                obj.listOrder = listOrder;
        }
        
        /* Set us as knowning about everything in our initiallyKnown lisr. */
        foreach(local item in valToList(initiallyKnowsAbout))
            setKnowsAbout(item);
        
        /* if we have an altVocab string, initialize our altVocab handling. */
        if(altVocab)
            initAltVocab();
        
        /* 
         *   If we want to record location history for this item, initialize our locationHistory
         *   list with our initial room location.
         */
        if(locationHistoryLength)
            locationHistory = [trackedLocation];
        

        /* 
         *   If we're compiling for debug, warn the user if s/he's used the
         *   canSitOn, canLieOn or canStand on properties in an inconsistent
         *   manner.
         */
#ifdef __DEBUG
        if(isBoardable == nil && contType != On)
        {
            if(canSitOnMe)
                "WARNING! canSitOnMe is true on <<theName>> when <<theName>>
                cannot be boarded.\n";
            if(canStandOnMe)
                "WARNING! canStandOnMe is true on <<theName>> when <<theName>>
                cannot be boarded.\n";
            if(canLieOnMe)
                "WARNING! canLieOnMe is true on <<theName>> when <<theName>>
                cannot be boarded.\n";
            
            if(canSitOnMe || canStandOnMe || canLieOnMe)
                "You either need to make <<objToString()>> a Platform or remove
                your override on its canSit/Stand/LieOnMe properties\b";
        }
        
        
#endif
    }
    
    /* 
     *   Our outermost room, i.e. the top level Room in which we are indirectly
     *   or directly contained.
     */
    getOutermostRoom = (location == nil ? nil : location.getOutermostRoom)
    
    
    interiorParent()
    {
        /* if I don't have a location, there's no interior parent */
        if (location == nil)
            return nil;

        /* if my immediate location is interior, it's the interior parent */
        if (location.contType == In || location.ofKind(Room))
            return location;

        /* otherwise, it's my parent's interior parent */
        return location.interiorParent();
    }
    
    /* 
     *   Am I on the inside of the given object?  This returns true if our
     *   relationship to the given object is an interior location type. 
     */
    isInterior(obj)
    {
        if(location == nil)
            return nil;
        
        if(location == obj && obj.contType == In)
            return true;
        
        if(location.ofKind(SubComponent) && location.contType == In &&
           location.location == obj)
            return true;
        
        return location.isInterior(obj);
    }
    
    /*
     *   Find the immediate child of 'self' that contains 'other'.  If
     *   'other' is directly in 'self', we return 'other'; otherwise, we
     *   return an object directly within 'self' that contains 'obj',
     *   directly or indirectly.  If 'other' is not within 'self', we
     *   return nil.  
     */
    directChildParent(other)
    {
        /* scan other's parent chain until we find a direct child of self */
        for (local o = other ; o != nil ; o = o.location)
        {
            if (o.location == self)
                return o;
        }

        /* 'other' is not a child */
        return nil;
    }
    
      /*
     *   Get the containment relationship between 'child' and 'self'.  This
     *   returns the containment type of the immediate child of 'self' that
     *   contains 'child'.
     */
    childLocType(child)
    {
        /* get the direct child of self containing child */
        child = directChildParent(child);

        /* 
         *   If we found the direct child container, the containment
         *   relationship is the one between 'self' and the direct child;
         *   otherwise there's no relationship.  
         */
        return (child != nil ? child.locType : nil);
    }
    
    /* 
     *   Find the nearest common containing parent of self and other. Unlike
     *   commonInteriorParent this doesn't take account of the type of
     *   containment (it can be In, On, Under, Behind or anything else) just so
     *   long as we find a common parent in the containment hierarchy.
     */    
    commonContainingParent(other)
    {
        /* start at each object's nearest direct parent */
        local l1 = location;
        local l2 = other.location;
        
         /* 
          *   if one or the other doesn't have a location, there's no common
          *   parent.
          */
        
        if(l1 == nil || l2 == nil)
            return nil;
        
         /* work up the containment tree one parent at a time */
        while (l1 != nil || l2 != nil)
        {
            /* if I'm inside the current other parent, that's the common one */
            if (l2 != nil && isIn(l2))
                return l2;

            /* if other is in my current parent, that's the nearest one */
            if (l1 != nil && other.isIn(l1))
                return l1;
            
            /* move up one level */
            l1 = (l1 != nil ? l1.location : nil);
            l2 = (l2 != nil ? l2.location : nil);
        }

        /* there's no common parent */
        return nil;
    }
    
    
   /*
     *   Find the nearest common interior parent of self and other.  This
     *   finds the nearest parent that both self and other are inside of.  
     */
    commonInteriorParent(other)
    {
        /* start at each object's nearest interior parent */
        local l1 = interiorParent();
        local l2 = other.interiorParent();
        
        /* 
         *   if one or the other doesn't have an interior parent, there's no
         *   common parent.
         */
        
        if(l1 == nil || l2 == nil)
            return nil;
        
        /* work up the containment tree one interior at a time */
        while (l1 != nil || l2 != nil)
        {
            /* if I'm inside the current other parent, that's the common one */
            if (l2 != nil && isInterior(l2))
                return l2;

            /* if other is in my current parent, that's the nearest one */
            if (l1 != nil && other.isInterior(l1))
                return l1;
            
            /* move up one level */
            l1 = (l1 != nil ? l1.interiorParent() : nil);
            l2 = (l2 != nil ? l2.interiorParent() : nil);
        }

        /* there's no common parent */
        return nil;
    }
    
    
    /*
     *   Get the interior containment path from 'self' to 'other'.  This
     *   returns a list containing three elements.  The first element is a
     *   sublist giving the interior containers you have to traverse
     *   outwards from self up to the common interior parent.  The second
     *   element is the common container; this will be nil if the two
     *   objects are in separate rooms.  The third element is a sublist
     *   giving the containers you have to traverse inwards from the common
     *   parent to other.  
     */
    containerPath(other)
    {
        /* set up vectors for the outward and inward paths */
        local outPath = new Vector(10), inPath = new Vector(10);

        /* set up a variable for the common parent */
        local commonPar = nil;

        /* trace the paths, accumulating the elements in the vectors */
        traceContainerPath(
            other,
            { c: outPath.append(c) },
            { c: commonPar = c },
            { c: inPath.append(c) });

        /* return the lists */
        return [outPath.toList(), commonPar, inPath.toList()];
    }
    
    /*
     *   Trace the interior containment path from 'self' to 'other'.
     *   
     *   We'll start by working up the containment tree from 'self' to the
     *   nearest interior container we have in common with 'other' - that
     *   is, the nearest object that contains both 'self' and 'other' with
     *   an interior location type for each object.  For each container
     *   BELOW the common parent, we call outFunc(container).
     *   
     *   Next, we call parentFunc(container) on the common container.  If
     *   there is no common container, we call parentFunc(nil).
     *   
     *   Next, we work back down the containment tree from the common
     *   parent to 'other'.  For each container below the common parent, we
     *   call inFunc(container).
     */
    traceContainerPath(other, outFunc, parentFunc, inFunc)
    {
        /* find the nearest common enclosing container */
        local cpar = commonInteriorParent(other);

        /* work up from self to the common parent */
        for (local c = interiorParent() ; c != cpar ; c = c.interiorParent())
            outFunc(c);

        /* call the common parent callback */
        parentFunc(cpar);

        /* 
         *   Work back down from the common parent to other.  The easy way
         *   to do this is to build a stack from other up to cpar, then
         *   work back through the stack.  
         */
        local stk = new Vector(10);
        for (local c = other.interiorParent() ; c != cpar ; 
             c = c.interiorParent())
            stk.push(c);
        
        /* work back through the stack */
        while (!stk.isEmpty())
            inFunc(stk.pop());
    }
    
    /*
     *   Search for a "blockage" along the container path between 'self'
     *   and 'other'.  'outProp' and 'inProp' are "can" properties
     *   (&canSeeOut, &canReachIn, etc) that test a container to see
     *   whether we can see/reach/hear/etc in or out of the container.
     *   
     *   We trace the containment path, using traceContainerPath().  For
     *   each outbound container on the path, we evaluate the container's
     *   outProp property: if this is nil, we add that container to the
     *   blockage list.  Next, if there's no common parent, we add the
     *   outermost room containing 'self' to the list.  Next, we trace the
     *   inbound path, evaluating each container's inProp property: if nil,
     *   we add that container to the blockage list.
     *   
     *   Finally, we return the blockage list.  This is a vector giving all
     *   of the blockages we found, in the order we encountered them.  
     */
    containerPathBlock(other, inProp, outProp)
    {
        /* set up a vector for the blockage list */
        local vec = new Vector(10);

        /* trace the path, noting each blockage */
        traceContainerPath(
            other,
            new function(c) { if (!c.(inProp)) vec.append(c); },
            new function(c) { if (c == nil && outermostParent) vec.append(outermostParent()); },
            new function(c) { if (!c.(outProp)) vec.append(c); });

        /* return the path */
        return vec;
    }

    /*
     *   Get the first blockage in a container path.  This calls
     *   containerPathBlock() and returns the first blockage in the list,
     *   or nil if there's no blockage.  
     */
    firstContainerPathBlock(other, inProp, outProp)
    {
        local v = containerPathBlock(other, inProp, outProp);
        return (v.length() != 0 ? v[1] : nil);
    }

        
    outermostVisibleParent()
    {
        /* 
         *   our "eyes" are on our outside, so we can always see our own
         *   parent; find its outermost visible container 
         */
        local loc;
        for (loc = location ; loc != nil ; loc = loc.location)
        {
            /* if this is the outermost container, we're done */
            if (loc.location == nil)
                break;

            /* if we can't see out to our next container, stop here */
            if (loc.contType == In && !loc.canSeeOut)
                break;
        }

        /* return what we found */
        return loc;
        

    }
    
    /* 
     *   Our location type with respect to our immediate container; e.g. are we
     *   In, On, Under or Behind it?
     */
    locType()
    {
        /* If we don't have a location we can't have a locType */        
        if(location == nil)
            return nil;
        
        /* 
         *   If our location is a Carrier then our locType depends on other
         *   factors.
         */
        if(location.contType == Carrier)
        {
            /* If we're worn by our location then our locType is Worn. */
            if(wornBy == location)
                return Worn;
            
            /* 
             *   Otherwise, if we're fixed in place we're a component of our
             *   location (i.e. a part of the actor that's our location), so our
             *   locType is Outside (we're attached to but external to our
             *   location
             */
            if(isFixed)
                return Outside;
            
            /*  Otherwise, if we're a portable object, we're being carried. */
            return Held;
        }
        
        /* Otherwise our locType is simply our location's contType. */
        else return location.contType;      
    }
    
     /*
     *   Get my outermost parent.  This is simply our ancestor in the
     *   location tree that has no location itself. 
     */
    outermostParent()
    {
        return locationWhich({ p: p.location == nil });
    }
    
    /* are we on the exterior of the given object, directly or indirectly? */
    isOutside(obj)
    {
        return (location == obj ? locType == Outside :
                location != nil && location.isOutside(obj));
    }
    

    /* are we held by the given object, directly or indirectly? */
    isHeldBy(obj)
    {
        return (location == obj ? locType == Held :
                location != nil && location.isHeldBy(obj));
    }


    /* 
     *   Flag; is this Thing a vehicle for an actor? If so then issuing a travel
     *   command while in this vehicle will call this vehicle to travel
     */
    isVehicle = nil
    
    /*
     *   The nested room subhead.  This shows a little addendum to the room
     *   headline when the point-of-view actor is inside an object within
     *   the main room, such as a chair or platform.  This usually shows
     *   something of the form "(in the chair)".  Note that only the
     *   *immediate* container is shown; if the actor is in a chair in a
     *   booth on a stage, we normally only mention the chair.
     *   
     *   We leave this to the language library to define, since the exact
     *   syntax varies by language.  
     */
    // roomSubhead(pov) { }

   
    /*
     *   Listing order.  This is an integer giving the relative position of
     *   this item in a miscellaneous item list.  The list is sorted in
     *   ascending order of this value.  
     */
    listOrder = 100

    /*
     *   The ListGroup or ListGroups (if any) we want this item to be grouped with in any item
     *   listing.
     */
    listWith = nil

    /*
     *   Group order.  This gives the relative order of this item within
     *   its list group. By default we use its listOrder. 
     */
    groupOrder = listOrder

     /*   
      *   CollectiveGroup, or a list of CollectiveGroups, to which this item
      *   belongs.
      */
    collectiveGroups = nil
    
    /*
     *   The owner or owners of the object.  This is for resolving
     *   possessives in the player's input, such as BOB'S WALLET.  By
     *   default, an object has no explicit owner, so this is an empty
     *   list.
     *   
     *   This should only return the *explicit* owner(s), not an implied
     *   locational owner.  For example, if Bob is holding a key, it's
     *   implicitly BOB'S KEY.  However, the key may or may not still be
     *   Bob's after he drops it.  If the key is something that's
     *   understood to belong to Bob, whether it's currently in his
     *   physical possession or not, then this routine would return Bob;
     *   otherwise it would return nil.
     *   
     *   An object can have multiple explicit owners, in which case it'll
     *   be recognized with a possessive qualifier for any of the owners.
     *   The first owner in the list is the nominal owner, meaning its the
     *   one we'll use if we're called upon to display the object's name
     *   with a possessive phrase.  
     */
    owner = []

    /*
     *   Are we the nominal owner of the objects we contain?  This controls
     *   whether or not we can be chosen as the nominal owner of a contained
     *   object for display purposes.  If a contained object has no explicit
     *   owner, it can still be implicitly owned by an actor carrying it, or by
     *   another suitable container.  (Note that this only applies as a default.
     *   When an item in our contents has an explicit owner, that will override
     *   the implied container ownership for that item.  So, for example, Bob
     *   can be carrying Bill's wallet wallet, and as long as the wallet has its
     *   explicit owner set, we'll still describe it as Bill's despite its
     *   location.)
     *
     *   By default, most objects are not nominal owners.  Actors generally
     *   should set this to true, so that (for example) anything Bob is carrying
     *   can be described as Bob's. Something with contType = Carrier is likely
     *   to be an actor and hence something that can own its contents.
     */
    ownsContents = (contType == Carrier)

    /*
     *   Get my nominal owner.  If we have an explicit owner, we'll return
     *   the first explicit owner.  Otherwise, we'll look for a container
     *   that has ownsContents = true, and return the first such container.
     */
    nominalOwner()
    {
        /* if I have an explicit owner, return the first one */
        if (owner.length() > 0)
            return owner[1];

        /* look for a container with ownsContents = true */
        return locationWhich({loc: loc.ownsContents});
    }

    /*
     *   Does the given object own me, explicitly or implicitly?  This
     *   returns true if 'obj' is in my 'owner' list, but it can also
     *   return true if there's merely an implied ownership relationship.
     *   Location can imply ownership: BOB'S KEY could refer to the key
     *   that Bob is holding, whether or not it would continue to be
     *   considered his key if he were to drop it.
     *   
     *   We return true if 'obj' is an explicit owner, OR self is contained
     *   within 'obj', OR self is contained within an object owned by
     *   'obj'.  (The latter case is for things like BOB'S TWENTY DOLLAR
     *   BILL, which is Bob's by virtue of being inside a wallet explicitly
     *   owned by Bob.)  
     */
    ownedBy(obj)
    {
        /* if obj is in my explicit owner, we're owned by obj */
        if (owner.indexOf(obj))
            return true;

        /* if we're a child of obj, we're implicitly owned by obj */
        if (isChild(obj, nil))
            return true;

        /* are we inside something owned by obj? */
        if (location != nil && location.ownedBy(obj))
            return true;

        /* we're not owned by obj */
        return nil;
    }

    /* 
     *   Return a list of everything that's directly or indirectly contained
     *   within us.
     */
    allContents()
    {
        local vec = new Vector(20);
               
        addToAllContents(vec, contents);
        
        return vec.toList;
    }
    
    addToAllContents(vec, lst)
    {
        vec.appendUnique(lst);
        foreach(local cur in lst)
            addToAllContents(vec, cur.contents);
    }
    

    /* get everything that's directly in me */
    directlyIn = (contents.subset({ obj: obj.locType == In }))
    
        
    /* 
     *   Run a check method passed as a property pointer in the prop parameter
     *   and return any string it tried to display
     */
    tryCheck(prop)
    {
        local ret;
        try
        {
            ret = gOutStream.captureOutput({: self.(prop) });      
        }
        catch (ExitSignal ex)
        {
            if(ret is in ('', nil))
                ret = gAction.failCheckMsg;
        }
        finally
        {
            return ret;
        }
    }
    
    locationWhich(func)
    {
        /* 
         *   scan up the location tree until we reach the top, or a
         *   location for which func(loc) returns true 
         */
        local loc;
        for (loc = location ; loc != nil && !func(loc) ; loc = loc.location) ;

        /* return what we found */
        return loc;
    }
    
    /*
     *   Are we transparent to light?  If this is true, then an observer
     *   outside this object can see through it to objects on its interior,
     *   and an observer inside can see through to objects on its exterior.
     *   
     *   This property controls transparency symmetrically (looking in from
     *   outside and looking out from within).  The library also lets you
     *   control transparency asymmetrically, using canSeeIn and canSeeOut.
     *   Those values are by default derived from this one, but you can
     *   override them separately to create something like a one-way
     *   mirror.  
     */
    isTransparent = nil

    /*
     *   Do we fully enclose our interior contents (true), or only
     *   partially (nil)?  By default, we assume that our contents are
     *   fully enclosed.  This can be set to nil for objects that represent
     *   spaces that are open on one side, such as a nook in a rock or a
     *   create without a lid.
     *   
     *   For an object that's sometimes fully enclosing and sometimes not,
     *   such as a cabinet with a door that can be opened and closed, this
     *   should be overridden with a method that figures the current value
     *   based on the open/closed state.
     *   
     *   Note that this only applies to our *interior* contents, such as
     *   contents of location type In.  Contents that are atop the object
     *   or otherwise arranged around the exterior aren't affected by this.
     */
    enclosing = (contType == In && isOpen == nil)

    /*
     *   Can we see in from my exterior to my interior?  That is, can an
     *   observer outside of this object see things located within it?  By
     *   default, we can see in from outside if we're transparent or we're
     *   non-enclosing.  
     */
    canSeeIn = (isTransparent || !enclosing)

    /*
     *   Can we see out from my interior to my exterior?  That is, can an
     *   observer inside this object see things located outside of it?  By
     *   default, we can see out from inside if we're transparent or we're
     *   non-enclosing.  
     */
    canSeeOut = (isTransparent || !enclosing)

     /*
     *   Can we hear in from my exterior to my interior?  That is, can an
     *   observer on the outside of this container hear a sound source on
     *   the inside?
     *   
     *   By default, we can hear in for all containers, since most
     *   materials transmit at least some sound even if they're opaque to
     *   light.  For a soundproof material (a glass booth, say), you could
     *   override this to make it (!enclosing) instead.  
     */
    canHearIn = true

    /*
     *   Can we hear out from my interior to my exterior?  That is, can an
     *   observer on the inside of this container hear a sound source on
     *   the outside?
     *   
     *   By default, we can hear out for all containers, since most
     *   materials transmit at least some sound even if they're opaque to
     *   light.  For a soundproof material (a glass both, say), you could
     *   override this to make it (!enclosing) instead.  
     */
    canHearOut = true

    /*
     *   Can we smell in (from an observer on my exterior to an odor source
     *   on my interior)?  By default, we can smell in if we're
     *   non-enclosing, since most solid materials aren't very permeable to
     *   scents (at human sensitivities, at least).  
     */
    canSmellIn = (!enclosing)

    /*
     *   Can we smell out (from an observer on my interior to an odor
     *   source on my exterior)?  By default, we can smell out if we're
     *   non-enclosing, since most solid materials aren't very permeable to
     *   scents (at human sensitivities, at least).  
     */
    canSmellOut = (!enclosing)

    /*
     *   Can we reach out from my interior to my exterior?  That is, can an
     *   observer inside this object reach something outside of it?  By
     *   default, we can reach out if we're non-enclosing. 
     */
    canReachOut = (!enclosing)

    /*
     *   Can we reach in from my exterior to my interior?  That is, can an
     *   observer outside this object reach something inside of it?  By
     *   default, we can reach in if we're non-enclosing. 
     */
    canReachIn = (!enclosing)

    /*   
     *   Allow this object to add additional checks at the check and verify
     *   stages to stipulate whether it can reach obj (or obj can reach it). We
     *   might use this, for example, to put an object conditionally out of
     *   reach if it's on top of a high cupboard or it's too hot to touch.
     */
    
    
    /*  
     *   If the verifyReach() method is defined, it should use the
     *   illogical/inaccessible/implausible/logical/logicalRank verify macros
     *   like a verify method. Don't define this method if you don't want it to
     *   block reaching.
     */
//    verifyReach(obj) { }
    
    /* 
     *   Check whether the actor can reach (touch) this object. If this method
     *   displays anything (which should be the reason this object can't be
     *   touched) then the object can't be reached. Note that this only has any
     *   effect when the touchObj preCondition is defined.
     */
    checkReach(actor) {  }
   
    
    
    /*   
     *   Check whether an actor can reach inside this object (for reasons other
     *   that it enclosing its contents; e.g. because it's out of reach). If
     *   this method displays anything (which should be the reason the interior
     *   of this object can't be reached) then disallow reaching inside. Note
     *   that this only has any effect when the touchObj preCondition is defined
     *   on this object. By default we can reach inside if we can reach this
     *   object and not otherwise. If the optional target parameter is supplied,
     *   it's the object that actor is trying to reach.
     */
    checkReachIn(actor, target?)  
    {
        checkReach(actor);
    }
    
    
    /* 
     *   Check whether the actor can reach out of this object to touch obj, if
     *   obj is not in this object.
     */    
    allowReachOut(obj) { return true; }
    
     
    
    /*  
     *   If an actor within me cannot reach an object from me, should the actor
     *   automatically try to get out of me?
     */        
    autoGetOutToReach = true
    
    
    /* 
     *   Check whether the actor can reach in to this object to touch obj, if
     *   obj is not in this object.
     */ 
    allowReachIn(obj) { return true; }
    
     /*  
     *   If an actor outside cannot reach an object inside me, should the actor
     *   automatically try to get into me?
     */        
    autoGetInToReach = true
    
    /* 
     *   Message to display if we cannot reach in to obj. By default we use the same message as for
     *   not being able to reach out to obj.
     */
    cannotReachInMsg(targObj, blockObj)
    {        
        return BMsg(cannot reach inside from, '{I} {cannot} reach {1} from outside {2}. ', 
                    targObj.theName, blockObj.theName);
    }

       
    /* 
     *   Return a message explaining why an object outside me can't reach one
     *   inside (or vice versa); this will normally be triggered by an attempt
     *   to reach an object inside a closed transparent container. The method is
     *   defined here to make it easier to customize the message on the
     *   container that's doing the blocking.
     */
    reachBlockedMsg(target)
    {
        local obj = self;
        gMessageParams(obj, target);
        return  BMsg(cannot reach, '{I} {can\'t} reach {the target} through
            {the obj}. ');
    }
    
    /*  
     *   Return a message (single-quoted string) explaining why we can't be
     *   reached by the actor (typically because we're in a different room).
     */
    tooFarAwayMsg
    {
        local obj = self;
        gMessageParams(obj);
        return BMsg(too far away, '{The subj obj} {is} too far away. ');
    }
    
    /* 
     *   Return a message (single-quoted string) explaining why target can't be
     *   reached from inside this Thing (when this Thing is typically some kind
     *   of nested room such as a Booth or Platform).
     */
    cannotReachOutMsg(target)
    {
        local loc = self;
        gMessageParams(loc, target);
        return BMsg(cannot reach out, '{I} {can\'t} reach {the target} from
                    {the loc}. ');
    }
    
    
    /*
     *   Does this object shine light outwards?  This determines if the
     *   object is a light source to objects outside of it.  Light shines
     *   out from an object if the object itself is a light source, or one
     *   of its direct exterior contents shines out, or its contents are
     *   visible from the outside and one of its direct interior contents
     *   shines out.  
     */
    shinesOut()
    {
        /* if I'm a light source directly, we shine light outwards */
        if (isLit)
            return true;

        /* check my exterior contents */
        if (contents.indexWhich(
            { c: c.locType.ofKind(ExtLocType) && c.shinesOut() }) != nil)
            return true;

        /* if we can see into this object from outside, check the contents */
        if (canSeeIn
            && contents.indexWhich(
                { c: c.locType.ofKind(IntLocType) && c.shinesOut() }) != nil)
            return true;

        /* I don't provide light outwards */
        return nil;
    }

    /*
     *   Is this object's interior lit?  
     *   an object if the object itself is a light source, or anything
     *   directly inside shines outwards, or we can see out from within and
     *   our location shines inwards.  
     */
    litWithin()
    {
        /* if I'm a light source directly, we shine inwards */
        if (isLit)
            return true;

        /* if any interior contents shine outwards, we're lit within */
        if (contents.indexWhich(
            { c: c.locType.ofKind(IntLocType) && !c.ofKind(Floor)
              && c.shinesOut() }) != nil)
            return true;

        /* 
         *   if we can see out from within, and my enclosing parent is lit
         *   within, I'm lit within 
         */
        if (canSeeOut)
        {
            local p = interiorParent();
            if (p != nil && p.litWithin())
                return true;
        }

        /* I don't provide light inwards */
        return nil;
    }

    
    
    /*
     *   Has this object ever been moved by the player character?  This is
     *   set to true when the PC takes the object or puts it somewhere.  
     */
    moved = nil

    /*
     *   Have we been examined?  This is set to true when the player
     *   character examines the object.  For a room, LOOK AROUND counts as
     *   examination, as does triggering a room description by traveling
     *   into the room.  
     */
    examined = nil

  
    /*
     *   Have we been seen?  This is set to true the first time the object
     *   is described or listed in a room description or the description of
     *   another object (such as LOOK IN this object's container).  
     */
    seen = nil

    /*
     *   The last location where the player character saw this object.
     *   Whenever the object is described or listed in the description of a
     *   room or another object, we set this to the object's location at
     *   that time.  
     */
    lastSeenAt = nil

    /* Note that we've been seen and where we were last seen */    
    noteSeen()
    {
        gPlayerChar.setHasSeen(self);
        lastSeenAt = location;
    }       
    
    /*
     *   Whether the player character knows of the existence of this object, if
     *   if it hasn't been seen. Set to true for objects that the player
     *   character should be familiar with at the start of play, or make true
     *   when the PC learns of them.
     */    
    familiar = nil
    
    /* 
     *   Properties to set and test whether an object is known about or has been
     *   seen; we define these on Thing to allow the player char to be a Thing.
     *   In what follows 'this Thing' is the object on which the method is
     *   called (which would typically be an Actor, the player character, or
     *   some other object representing an NPC) and obj is the object that is
     *   potentially known about or seen.
     */
        
    /*  Mark this Thing as knowing about obj. */
    setKnowsAbout(obj, val?) 
    { 
        switch(dataType(obj))
        {
        case TypeObject:
            obj.(knownProp) = true; 
            break;
        case TypeSString:
            setInformed(obj, val);
            break;
        default:
            ;
        }
    }
    
    /*  Mark the player character as knowing about us (i.e. this Thing) */
    setKnown() { gPlayerChar.setKnowsAbout(self); }
    
    /*  Mark this Thing as having seen obj. */
    setHasSeen(obj) { obj.(seenProp) = true; }
    
    /*  Mark the player character as having seen this Thing. */
    setSeen() { gPlayerChar.setHasSeen(self); }
    
    /*  Test whether this Thing has seen obbj. */
    hasSeen(obj) { return obj.(seenProp); }
       
    /*  
     *   Test whether this Thing knows about obj, which it does either if it has seen this obj or
     *   its knownProp (by default, familiar) is true, or, if obj is passsed as a string tag, if we
     *   have been informed about it.
     */   
    knowsAbout(obj)
    {
        switch(dataType(obj))
        { 
        
        /* 
         *   If obj is an object, then return true either if we've seen this objector if we know
         *   about it as defined by our knownProp.
         */    
        case TypeObject:
            return hasSeen(obj) || obj.(knownProp);
            
            /* 
             *   If obj is a single-quoted string, assume it's a knowledge tag and test for our
             *   being informed abnout it.
             */
        case TypeSString:
            return informedAbout(obj);
            
        default:
            return nil;           
                
        }
    }    
   
    
    /* 
     *   Test whether this Thing is known to the player character.
     */
    known = (gPlayerChar.knowsAbout(self)) 
    
    
     /*  
      *   If we want to track whether characters other than than the player char
      *   know about or have seen this object, we can define knownProp and
      *   seenProp as the properties used by this Thing to track what it knows
      *   about and has seen.
      */
    knownProp = &familiar
    seenProp = &seen
    
    /* Our look up table for things we've been informed about */    
    informedNameTab = nil
    
    /* 
     *   Note that we've been informed of something, by adding it to our
     *   informedNameTab. Tag is an arbitrary single-quoted string value used to
     *   represent the information in question.
     */    
    setInformed(tag, val?)
    {
        if(informedNameTab == nil)
            informedNameTab = new LookupTable(32, 32);
               
        if(val == nil && informedNameTab[tag] == nil)        
            informedNameTab[tag] = true;
        else
            informedNameTab[tag] = val ?? true;
    }
    
    /* Make this Actor or Consultable forget about tag altogether. */
    forget(tag)
    {
        if(informedNameTab)
            informedNameTab.removeElement(tag);
    }
    
    
    /* 
     *   Determine whether this Thing has been informed about tag. We return true if there is a
     *   corresponding non-nil entry in our informedNameTab, or else the value of the corresponding
     *   entry if ibGlobal.informedTrueOrFalseOnly is nil (the default).
     */
    informedAbout(tag) 
    {        
        return informedNameTab == nil ? nil 
            : (libGlobal.informedTrueOrFalseOnly ? (informedNameTab[tag] != nil)
               : informedNameTab[tag]);     
    }
    
    /* 
     *   The list of things we start the game knowing about. This list can contain a mix of game
     *   objects (Things and/or Topics) and fact tags. Note that it would be redundant to include
     *   Things and Topics already defined as familiar if this property is overridden on the initial
     *   player character object.
     */         
    initiallyKnowsAbout = nil
    
    /*   
     *   The currentInterlocutor is the Actor this object is currently in
     *   conversation with. This property is only relevant on gPlayerChar, but
     *   it is defined here rather than on Actor since the player char can be of
     *   kind Thing.
     */    
    currentInterlocutor = nil
    
    
     /* 
      *   Can this Thing (which might be the Player Char for instance) talk to
      *   other?
      */
    canTalkTo(other)
    {
        return Q.canTalkTo(self, other);
    }
   
      /* 
       *   The lister to use when listing this object's inventory. By default we use the standard
       *   inventory lister for the default WIDE inventory listing and the inventoryTallLister for
       *   the TALL inventory listing.
       */
//    myInventoryLister = libGlobal.inventoryTall ? inventoryTallLister : inventoryLister
    
    myInventoryLister = Inventory.inventoryStyle == InventoryWide ? inventoryLister :
    inventoryTallLister
    
    /* The lister to use when listing what this object is wearing. */
    myWornLister = wornLister
    
    /*
     *   Score this object for disambiguation.  When a noun phrase is
     *   ambiguous (for example, the phrase matches multiple in-scope
     *   objects, and we have to choose just one), the parser calls this
     *   routine on each object it's considering as a match.
     *   
     *   Our job here is to read the player's mind.  The question before us
     *   is: did the player mean *this* object when typing this noun
     *   phrase?  Obviously we can't really know what's in the player's
     *   mind, but in many cases we can make an educated guess based on
     *   what ought to make the most sense in context.  The context in this
     *   case is the state of the simulated game world, as it's portrayed
     *   to the player.  That last bit is important: be cognizant of what
     *   the player is *meant* to know at this point.  DON'T base the score
     *   on information that the player isn't supposed to know, though:
     *   that could give away secrets that the player is meant to discover
     *   on her own.
     *   
     *   Before this routine is called, the Action has already assigned an
     *   initial score to each object, but this routine can override the
     *   initial score by assigning its own score value.  This routine is
     *   most useful in cases where a particular object has a special
     *   affinity for a verb, or for the verb in combination with
     *   particular other objects involved in the command.
     *   
     *   'cmd' is the Command object.  'role' is the noun phrase's role in
     *   the command (DirectObject, IndirectObject, etc).  'lst' is a list
     *   of NPMatch objects identifying the objects that matched the noun
     *   phrase.  'm' is the NPMatch object for self.
     *   
     *   To override or adjust the score, simply set m.score to the new
     *   value.  This routine is also free to override the scores of any
     *   other objects in the list, if needed.
     *   
     *   By default, we don't make any adjustment - we simply accept the
     *   initial score calculated by the Action, by leaving m.score
     *   unchanged.
     *   
     *   See Action.scoreObjects() for full details.  
     */
    scoreObject(cmd, role, lst, m) 
    {
        m.score += vocabLikelihood;
        
        /* 
         *   If we're the last object written on, boost our score if the player
         *   wants to write something again.
         */
        if(libGlobal.lastWrittenOnObj == self && cmd.action == WriteOn && role
           == IndirectObject)
            m.score += 20;
        
        /* 
         *   If we're the last object typed on, boost our score if the player
         *   wants to type something again.
         */
        if(libGlobal.lastTypedOnObj == self && cmd.action == TypeOn && role
           == IndirectObject)
            m.score += 20;
        
    }

    /*  
     *   A property that can be used to boost this object being chosen by the
     *   parser, other things being equal; it can be used as a tie-breaker
     *   between two objects that otherwise have the same verification scores.
     *   Game code should normally use fairly small values for this property,
     *   say between -20 and +20, to prevent overriding the verification score.
     */
    vocabLikelihood = 0
          
    
    /*   
     *   A list of objects that are facets of this object, and so can be
     *   referred to with the same pronoun.
     */
    getFacets = []
    
    
    /* 
     *   Before travel notification. This is called just before traveler
     *   attempts to travel via connector. By default we do nothing
     */    
    beforeTravel(traveler, connector) {}
    
    
    /* 
     *   After travel notification. This is called just after traveler has
     *   traveled via connector. 
     */     
    afterTravel(traveler, connector) {}
    
    /*   
     *   Cause this Thing to travel via the connector conn. This method is
     *   supplied in case travelVia is called on a Thing which is not an Actor,
     *   although it's Actor that has the full implementation.
     */
    travelVia(conn, announceArrival = true)
    {
        /* 
         *   If we've been mixed in with a TravelConnector class, it's almost
         *   certainly the TravelConnector's version of travelVia() that we need
         *   to execute here.
         */        
        if(ofKind(TravelConnector))
            inherited TravelConnector(conn);
        
        else    
            /* Move this actor via conn. */
            conn.travelVia(self);
    }
    
    /* 
     *   Handle a command directed to this open (e.g. BALL, GET IN BOX). Since
     *   inanimate objects generally can't respond to commands we simply display
     *   a message announcing the futility of issuing one. This method is
     *   overridden on Actor to allow Actors to respond to commands via
     *   CommandTopics.
     */    
    handleCommand(action)
    {
        DMsg(cannot command thing, 'There{dummy}\'s no point trying to give
            orders to {1}. ', aName);
    }
    
    
    /* 
     *   The preAction handling on this Thing if it's the current actor. This is called just before
     *   the relevant Doer is executed to provide a convenient entrypoint to intervene in an action
     *   before it can do anything at all (typically when the actor is tied up, paralysed, or
     *   otherwise temporarily incapacitated, which might require the intervention of three or four
     *   simlar Doers to trap). the object combination to execute: this is an [action, dobj, iobj,
     *...] list.
     */
    
    preAction(lst)
    {
    }
    
    /* 
     *   The before action handling on this Thing if it's the current actor. We
     *   define it here rather than on Actor since the player character can be a
     *   Thing. By default we do nothing.
     */
    actorAction() { }
    
    /* 
     *   Before action notification on this Thing; this is triggered whenever an
     *   action is about to be performed when we're in scope (and could be used
     *   to veto the action with an exit macro). The action we'd test for here
     *   would normally be one that *doesn't* involve this Thing.
     */    
    beforeAction() { }
    
    /* 
     *   After action notification on this Thing; this is triggered whenever an
     *   action has just been performed when we're in scope. The action we'd
     *   test for here would normally be one that *doesn't* involve this Thing.
     */  
    afterAction() { }
    
    /* Is this object the player character? */
    isPlayerChar = (gPlayerChar == self)
    
    /* 
     *   To exclude this item from the list of objects to be acted upon when the
     *   player types a command with ALL for action, override this method to
     *   return true for the action or actions concerned. Note that this
     *   exclusion is applied after the action has constructed its own list of
     *   objects that ALL should apply to, and can only be used to make further
     *   exclusions.
     *
     *   It shouldn't be necessary to use this method very often, since the
     *   normal approach will be to override the getAll() method on the
     *   appropriate action. It may be useful to use this method to handle
     *   exceptional cases, however.
     */
    hideFromAll(action) { return nil; }
    
    /*   
     *   This method is primarily intended for use with the symconn extension, where it is
     *   redefined, but other code may find a use for it.
     */
    byRoom(arg) { return ''; }
    
    /* 
     *   The ThoughtManager object associated with this Thing (if this Thing does any thinking);
     *   this is only relevant if thoughts.t is present and this Thing becomea a player character.
     */
    myThoughtManager = nil
    
    /*   
     *   Tbe object referred to in our verify routine. For a Thing this is always self. We use
     this indirection here to allow the various verify macros (illogical, etc.) to be called from a
     function where verobj can be a local variable (or parameter). 
     */
    verobj = self
    
    /* 
     *   A Hook for the postures extension. In the main library this just evaluates to an empty
     *   string, although it could be overridden to a posture psrticiple such as 'standing' or
     *   'sitting'. The postures extension will handle this automatically.
     */
    postureDesc = ''
    
    /*
     *   ******************************************************************
     *   ACTION HANDLING
     *
     *   Here follows code relating to the handling of specific actions
     */
    
     /* 
      *   If I declare this object to be a decoration (i.e. isDecoration = true)
      *   then its default behaviour will be to display its notImportantMsg for
      *   every action except Examine or GoTo. We can extend the actions it will
      *   respond to by adding them to the list in the decorationActions
      *   property.
      */    
    isDecoration = nil
    
    /*   
     *   The list of actions this object will respond to specifically if
     *   isDecoration is true. All other actions will be handled by
     *   dobjFor(Default) and/or iobjFor(Default). Game code can override this
     *   list (usually to expand it) for decorations that are required to handle
     *   additional actions.
     *
     *   If we're compiling for debugging, it will be useful to allow the GONEAR
     *   command with Decorations for testing purposes, but this can't be
     *   included in a release build without causing a compilation error, so we
     *   define the decorationActions property with different lists of actions
     *   depending on whether we're compiling for debugging or release.
     */    
#ifdef __DEBUG
    decorationActions = [Examine, GoTo, GoNear]
#else
    decorationActions = [Examine, GoTo]
#endif
    /*   
     *   Our handling of any action of which we're the direct or indirect action
     *   that's not in our list of decorationActions when our isDecoration
     *   property is true. By default we just stop the action at the verify
     *   stage and display our notImportantMsg.
     */    
    dobjFor(Default)
    {
        verify
        {
            illogical(notImportantMsg);
        }
    }
    
    iobjFor(Default)
    {
        verify()
        {
            illogical(notImportantMsg);
        }
    }
    
    notImportantMsg = BMsg(not important, '{The subj cobj} {is} not important.
         ')
    
    
    /* 
     *   Next deal with what happens if this object is being tested as a
     *   potential actor
     */    
    verifyActor()
    {
       /* 
        *   If our contType isn't Carrier we're unlikely to be an actor, so
        *   we're a poor choice of object if the parser has to select an actor,
        *   typically when the player has entered a command targeted at an NPC.
        */
        if(contType != Carrier)
            logicalRank(70);
    }
    
    remapActor = nil
    
    preCondActor = [objAudible]
    
    
    /* Now the handling for specific actions */
    
    dobjFor(Examine)
    {
        preCond = [objVisible]
        
        verify() 
        { 
            if(isDecoration)
                logicalRank(70);
            else
                logical; 
        }
        
        check() { }
        
        action()
        {            
            local descDisplayed = nil;
            
            /* 
             *   If we have a non-nil darkDesc property and we're in a dark
             *   room, display our darkDesc and stop there. Note this will only
             *   ever happen if we're visibleInDark.
             */
            if(propType(&inDarkDesc) != TypeNil 
               && !getOutermostRoom.isIlluminated())
            {
                /* Display our darkDesc */
                display(&inDarkDesc);
                
                /* 
                 *   Stop there, because in a dark room we can only be seen
                 *   partially, and so we don't add any status information or
                 *   record that we've been (properly) examined.
                 */
                return;
            }
            
            /* 
             *   Display our description. Normally the desc property will be
             *   specified as a double-quoted string or a routine that displays
             *   a string, but by using the display() message we ensure that it
             *   will still be shown even if desc has been defined a
             *   single-quoted string.
             */
            if(gOutStream.watchForOutput({:display(&desc) }))
               descDisplayed = true;
            
            /*   
             *   Display any additional information, such as our stateDesc (if
             *   we have one) and our contents (if we have any).
             */
            if(gOutStream.watchForOutput({:examineStatus()} ))
                descDisplayed = true;
               
            /*   
             *   If nothing has been displayed yet, show the default message
             *   saying we nothing special about this object.
             */
            if(!descDisplayed)
                DMsg(nothing special,  '{I} {see} nothing special about 
                {the 1}. ', self); 
               
            
            /*   Note that we've now been examined. */
            examined = true;
            
            /*   
             *   Note that the player character has seen us. 99 times out a
             *   hundred this probably won't be necessary, but it may catch the
             *   odd case where something is examined that hasn't yet been set
             *   as seen.
             */
            if(gActor == gPlayerChar)
                noteSeen();
            
            
            "\n";
        }
    }
    
    /* The message to display when it's too dark to see anything */
    tooDarkToSeeMsg = BMsg(too dark to see, 'It{dummy}{\'s} too dark to see
        anything. ')
    
    /* 
     *   By default everything is smellable, but you can override this to nil if
     *   something isn't
     */
    isSmellable = true
       
    
    cannotSmellMsg = BMsg(cannot smell, '{I} {can\'t} smell {the dobj}. ')
    
    dobjFor(SmellSomething)
    {
        preCond = [objSmellable]
        
        verify()
        {
            if(!isSmellable)
                illogical(cannotSmellMsg);
        }
        
        action()
        {
            displayAlt(&smellDesc, &smellNothingMsg);            
        }
    }
    
    smellNothingMsg = BMsg(smell nothing, '{I} {smell} nothing out of the
                    ordinary.<.p>')
    
    dobjFor(ListenTo)
    {
        
        preCond = [objAudible]
        
        action()
        {
            displayAlt(&listenDesc, &hearNothingMsg);           
        }
    }
    
    hearNothingMsg = BMsg(hear nothing listen to, '{I} hear{s/d} nothing out of
        the ordinary.<.p>')
    
    /* 
     *   By default everything is tasteable, but there might well be things the
     *   that it would not be appropriate to taste.
     */
    isTasteable = true
    
    
    cannotTasteMsg = BMsg(cannot taste, '{The subj dobj} {is} not suitable for
        tasting. ')
    
    dobjFor(Taste)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isTasteable)
                illogical(cannotTasteMsg);
        }
        
        action()
        {
            if(propType(&tasteDesc) == TypeNil)           
                DMsg(taste nothing, '{I} taste{s/d} nothing unexpected.<.p>');
            else
                display(&tasteDesc);      
        }
    }
    
    
    /* 
     *   By default we can try feeling most things, but there may be some things
     *   it would be inappropriate to try feeling (like a blazing fire or Aunt
     *   Mable) or somethings that cannot be felt (like a ray of light).
     */
    isFeelable = true
    
    cannotFeelMsg = BMsg(cannot feel, 'It{\'s} hardly a good idea to try feeling
        {the dobj}. ')
    
    /* 
     *   This property can be defined to display a message at the check stage
     *   (and so stop the FEEL action there). Normally checkFeelMsg would be
     *   defined as a double-quoted string, but it can also be defined as a
     *   double-quoted string or a method that displays some text.
     */
    checkFeelMsg = nil
    
    dobjFor(Feel)    
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isFeelable)
                illogical(cannotFeelMsg);
        }
        
        check()
        {
            if(dataType(&checkFeelMsg) != TypeNil)
                display(&checkFeelMsg);
        
        }
        
        action()
        {
            if(gActionIs(Touch) && propDefined(&touchDesc) && propType(&touchDesc) != TypeNil)
                display(&touchDesc);
            
            else if(propType(&feelDesc) == TypeNil)            
                DMsg(feel nothing, '{I} {feel} nothing unexpected.<.p>');
            else
                display(&feelDesc);
        }
    }
    
    /* By default a Thing is takeable if it's not fixed in place */
    isTakeable = (!isFixed)
    
    /* Make TOUCH act the sane as FEEL */
    dobjFor(Touch) asDobjFor(Feel)
    
    dobjFor(Take)    
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isTakeable)
                illogical(cannotTakeMsg);
            
            if(isDirectlyIn(gActor))
                illogicalNow(alreadyHeldMsg);
            
            if(gActor.isIn(self))
                illogicalNow(cannotTakeMyContainerMsg);
            
            if(gActor == self)
                illogicalSelf(cannotTakeSelfMsg);
            
            logical;
        }
        
        check() 
        {
            
            /* First check that my container doesn't object to my being removed from it. */
            if(location)
                location.checkRemove(self);
            
            /* 
             *   Check that the actor has room to hold the item s/he's about to
             *   pick up.
             */
            checkRoomToHold();
        }
        
        action()
        {
            /* 
             *   If we have any contents hidden behind us or under us, reveal it
             *   now
             */
            revealOnMove();     
            
            /* 
             *   move us into the actor who is taking us, triggering the
             *   appropriate notifications.
             */
            actionMoveInto(gActor);
        }
        
        /* 
         *   Report that we've been taken. Note that if the action causes
         *   several items to be taken, this method will only be called on the
         *   final item, and will need to report on all the items taken.
         */
        report()
        {            
            DMsg(report take, 'Taken. | {I} {take} {1}. ', gActionListStr);
        }
    }
       
    cannotTakeMsg = BMsg(cannot take, '{The subj cobj} {is} fixed in place.
        ')
    
    alreadyHeldMsg = BMsg(already holding, '{I}{\'m} already holding {the dobj}.
        ')
    
    cannotTakeMyContainerMsg = BMsg(cannot take my container, '{I} {can\'t}
        take {the dobj} while {i}{\'m} {1} {him dobj}. ', objInPrep)
    
    cannotTakeSelfMsg = BMsg(cannot take self, '{I} {can} hardly take {myself}. ')
    
    /* 
     *   Flag, should any items behind me be left behind when I'm moved; by
     *   default, they should.
     */
    dropItemsBehind = true
    
    /* 
     *   Flag, should any items behind me be left behind when I'm moved; by
     *   default, they should.
     */
    dropItemsUnder = true
    
    
    /* 
     *   List and move into an appropriate location any item that was hidden
     *   behind or under us. We place this in a separate method so it can be
     *   conveniently called by other actions that move an object, or overridden
     *   by particular objects that want a different handling.
     *
     *   Note that we don't provide any handling for the hiddenIn property here,
     *   on the assumption that items hidden in something may well stay there
     *   when it's moved; but this method can always be overridden to provide
     *   custom behaviour.
     */    
    revealOnMove()
    {
        local moveReport = '';
        local underLoc = location;
        local behindLoc = location;
        
        /* 
         *   If I don't want to leave items under me behind when I'm moved, and
         *   I am or have an underside, change the location to move items hidden
         *   under me to accordingly.
         */
        if(contType == Under && dropItemsUnder == nil)
            underLoc = self;
        else if(remapUnder != nil && dropItemsUnder == nil)
            underLoc = remapUnder;
        
         /* 
          *   If I don't want to leave items behind me behind when I'm moved,
          *   and I am or have a RearContainer, change the location to move
          *   items hidden under me to accordingly.
          */
        if(contType == Behind && dropItemsBehind == nil)
            behindLoc = self;
        else if(remapBehind != nil && dropItemsBehind == nil)
            behindLoc = remapBehind;
        
        
        /* 
         *   If anything is hidden under us, add a report saying that it's just
         *   been revealed moved and then move the previously hidden items to
         *   our location.
         */
        if(hiddenUnder.length > 0)
        {
            moveReport += 
                BMsg(reveal move under,'Moving {1} {dummy} reveal{s/ed} {2}
                    previously hidden under {3}. ',
                     theName, makeListStr(hiddenUnder), himName);
                     
            moveHidden(&hiddenUnder, underLoc);
            
        }
        
        
        /* 
         *   If anything is hidden behind us, add a report saying that's just
         *   been revealed and then move the previously hidden items to our
         *   location.
         */
        if(hiddenBehind.length > 0)
        {
            moveReport += 
                BMsg(reveal move behind,'Moving {1} {dummy} reveal{s/ed} {2}
                    previously hidden behind {3}. ',
                     theName, makeListStr(hiddenBehind), himName);
                        
            moveHidden(&hiddenBehind, behindLoc);            
        }
        
        /* 
         *   Construct a list of anything left behind from under or behind us
         *   when we're moved.
         */
        local lst = [];
        
        if(dropItemsUnder)
        {
            if(contType == Under)
                lst = contents;
            else if(remapUnder)
                lst = remapUnder.contents;                    
        }
               
        if(dropItemsBehind)
        {
            if(contType == Behind)
                lst += contents;
            else if(remapBehind)
                lst += remapBehind.contents;           
        }
        
        lst = lst.subset({o: !o.isFixed});
        
        if(lst.length > 0)
        {
            foreach(local cur in lst)
                cur.moveInto(location);                
         
            moveReport +=
                BMsg(report left behind, '<<if moveReport == ''>>Moving {1}
                    <<else>>It also <<end>> {dummy} {leaves} {2} behind. ',
                     theName, makeListStr(lst));
        }
        
        
        /* 
         *   If anything has been reported as being revealed, report the
         *   discovery after reporting the action that caused it.
         */
        if(moveReport != '' )
            reportAfter(moveReport);
    }
    
    /* 
     *   Service method: move everything in the prop property to loc and mark it
     *   as seen.
     */    
    moveHidden(prop, loc)
    {
        foreach(local cur in self.(prop))
        {
            cur.moveInto(loc);
            cur.noteSeen();
        }
        self.(prop) = [];
                
    }
    
    /* 
     *   Check that the actor has enough spare bulkCapacity and enough items carried capacity to add
     *   this item to his/her inventory. Since by default everything has a bulk of zero and a very
     *   large bulkCapacity, by default there will be no effective restriction on what an actor (and
     *   in particular the player char) can carry, but game authors may often wish to give portable
     *   items bulk in the interests of realism and may wish to impose an inventory limit by bulk by
     *   reducing the bulkCapacity of the player char.
     */    
    checkRoomToHold()
    {
        /* 
         *   First check whether this item is individually too big for the actor to carry.
         */
        if(bulk > gActor.maxSingleBulk)
            DMsg(too big to carry, '{The subj dobj} {is} too big for {me} to
                carry. ');
        
        /* 
         *   If the BagOfHolding class is defined and the actor doesn't have enough spare bulk
         *   capacity or maxItemCarried capacity, see if the BagOfHolding class can deal with it by
         *   moving something to a BagOfHolding.
         */
        if(defined(BagOfHolding) 
           && (bulk > gActor.bulkCapacity - gActor.getCarriedBulk ||
               gActor.directlyHeld.length > gActor.maxItemsCarried - 1)
           && BagOfHolding.tryHolding(self));
        
        
        /* 
         *   otherwise check that the actor has sufficient spare carrying capacity.
         */
        else if(bulk > gActor.bulkCapacity - gActor.getCarriedBulk ||
                gActor.directlyHeld.length > gActor.maxItemsCarried - 1)
            DMsg(cannot carry any more, '{I} {can\'t} carry any more than
                {i}{\'m} already carrying. ');
    }
    
    /* By default we can drop anything that's held */
    isDroppable = true
    
    /* The message to display if something can't be dropped. */
    cannotDropMsg = BMsg(cannot drop, '{The subj dobj} {can\'t} be dropped. ')
    
    /* The location in which something dropped in me should land. */
    dropLocation = self
    
    /* 
     *   Flag: can our contents be dropped when we're in the actor's inventory (if they can, an
     *   implicit TaksFrom us will be performed to enable the Drop). By default they can't.
     */
    canDropContents = nil
    
    dobjFor(Drop)
    {
        preCond = [touchObj, objNotWorn, objCarried]
        
        verify()
        {
            
            /* 
             *   This object cannot be dropped if game code deems it to be undroppable for reasons
             *   beyond throse enforced in the objCarried PreCondition.
             */            
            if(!isDroppable)
                illogical(cannotDropMsg);           
        }
                
        
        action()
        {           
            actionMoveInto(gActor.location.dropLocation);
        }
        
        report()
        {
            DMsg(report drop, 'Dropped. |{I} drop{s/?ed} {1}. ', gActionListStr);            
        }
    }
    
    notHoldingMsg = BMsg(not holding, '{I} {amn\'t} holding {the dobj}. ')
    partOfYouMsg = BMsg(part of me, '{The subj dobj} {is} part of {me}. ')
    
    /* By default an object is readable if it defines a non-nil readDesc */
    isReadable = (propType(&readDesc) != TypeNil)
    
    dobjFor(Read)
    {
        preCond = [objVisible]
        
        verify()
        {
            if(!isReadable)
                illogical(cannotReadMsg);
        }
        
        action()
        {
            if(propType(&readDesc) == TypeNil)
                say(cannotReadMsg);
            else                
                display(&readDesc);         
        }
    }
    
    cannotReadMsg = BMsg(cannot read, 'There {dummy} {is} nothing to read on
        {the dobj}. ')
    

    /* 
     *   Flag: can this object be followed? Most inanimate objects cannot, so
     *   the default value is nil.
     */
    isFollowable = nil
    
    dobjFor(Follow)
    {
        preCond = [objVisible]
        
        verify()
        {
            if(!isFollowable)
                illogical(cannotFollowMsg);
            
            if(self == gActor)
                illogicalSelf(cannotFollowSelfMsg);
        }
    }
    
    
    cannotFollowMsg = BMsg(cannot follow, '{The subj dobj} {isn\'t} going
        anywhere. ')
    
    cannotFollowSelfMsg = BMsg(cannot follow self, '{I} {can\'t} follow
        {myself}. ')

    
   
    /* 
     *   Although in theory we can attack almost anything, in practice there's
     *   seldom reason to do so.
     */
    isAttackable = nil
    
    dobjFor(Attack)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isAttackable)
                illogical(cannotAttackMsg);
        }
        
        check()
        {
            if(dataType(&checkAttackMsg) != TypeNil)
                display(&checkAttackMsg);
        }
        
        /* 
         *   In case isAttackable is changed to true but no other handling is
         *   added, we need to provide some kind of default report.
         */
        report()
        {
            say(futileToAttackMsg); 
        }
    }
   
    /* 
     *   If we want Attack to fail at the check stage we can supply a message
     *   explaining why.
     */ 
    checkAttackMsg = nil
    
    cannotAttackMsg = BMsg(cannot attack, 'It{dummy}{\'s} best to avoid
        pointless violence. ')
    
    dobjFor(AttackWith)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isAttackable)
                illogical(cannotAttackMsg);
        }
        
        
        /* 
         *   In case isAttackable is changed to true but no other handling is
         *   added, we need to provide some kind of default report.
         */
        report()
        {
            say(futileToAttackMsg); 
        }       
    }
    
    futileToAttackMsg = BMsg(futile attack, 'Attacking {1} prove{s/d} futile. ', 
                             gActionListStr)
    
    iobjFor(AttackWith)
    {
        preCond = [objHeld]
        verify() 
        { 
            if(!canAttackWithMe)
               illogical(cannotAttackWithMsg); 
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotAttackWithSelfMsg);
        }
    }
    
    
    /* By default we can't use most things as weapons */    
    canAttackWithMe = nil
    
    cannotAttackWithSelfMsg = BMsg(cannot attack with self, '{I} {can\'t}
        attack anything with itself. ')
    
    cannotAttackWithMsg = BMsg(cannot attack with, '{I} {can\'t} attack
        anything with {that iobj}. ')
    
    dobjFor(Strike) asDobjFor(Attack)
    
    /* 
     *   By default treat everything as breakable, but there are somethings that
     *   clearly aren't like sunbeams, sounds and mountains.
     */
    isBreakable = true
    
    /*   Probably most things shouldn't be broken though. */
    shouldBeBroken = nil
    
    dobjFor(Break)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isBreakable)
                illogical(cannotBreakMsg);
            else if(!shouldBeBroken)
                implausible(shouldNotBreakMsg);            
        }       
    }
    
    cannotBreakMsg = BMsg(cannot break, '{The subj dobj} {is} not the sort of
        thing (i) {can} break. ')
    
    shouldNotBreakMsg = BMsg(dont break, '{I} {see} no point in breaking {that
        dobj}. ')
    
    /* By default something is throwable unless it's fixed in place. */
    isThrowable = (!isFixed)
    
    dobjFor(ThrowDir)
    {
        preCond = [objHeld ,objNotWorn]
        
        verify()
        {
            if(!isThrowable)
                illogical(cannotThrowMsg);
               
        }
             
        /* 
         *   The default result of throwing something in a compass direction is
         *   that it lands in the dropLocation of its outermost room.
         */
        action() { actionMoveInto(getOutermostRoom.dropLocation); }
        
        report()
        {
            local obj = gActionListObj;
            
            gMessageParams(obj);
            
            DMsg(throw dir, '{I} {throw} {the obj} {1} and {he obj}
                land{s/ed} on the ground. ', gAction.direction.name );
        }
    }
    
    cannotThrowMsg = BMsg(cannot throw, '{I} {can\'t} throw {the dobj} anywhere.
        ')
    
    
    /* 
     *   Is this object openable. If this property is set to true then this
     *   object can be open and closed via the OPEN and CLOSE commands. Note
     *   that setting this property to true also automatically makes the
     *   OpenClosed State apply to this object, so that it can be referred to as
     *   'open' or 'closed' accordingly.
     */
    isOpenable = nil
    
    /* 
     *   Is this object open. By default we'll make Things open so that their
     *   interiors (if they have any) are accessible, unless they're openable,
     *   in which case we'll assume they start out closed.
     */
    isOpen = (!isOpenable)
    
    /* 
     *   Make us open or closed. We define this as a method so that subclasses
     *   such as Door can override to produce side effects (such as opening or
     *   closing the other side).
     */    
    makeOpen(stat)
    {
        isOpen = stat;
        if(stat)
            opened = true;
    }
    
    /* 
     *   Flag, has this object ever been opened. Note that this is nil for an
     *   object that starts out open but has never been closed and opened again.
     */
    opened = nil
    
    /* 
     *   Flag, do we want to attempt to unlock this item it it's locked when we
     *   try to open it?
     */
    autoUnlock = nil
    
    
    dobjFor(Open)
    {
        
        preCond = autoUnlock ? [touchObj, objUnlocked] : [touchObj]
        
        /* 
         *   If this object is not itself openable, but its remapIn property
         *   points to an associated object that is, remap this action to use
         *   the remapIn object instead of us.
         */
        remap()
        {
            if(!isOpenable && remapIn != nil && remapIn.isOpenable)
                return remapIn;
            else
                return self;
        }
        
        verify()
        {
            if(isOpenable == nil)
                illogical(cannotOpenMsg);
            
            if(isOpen)
                illogicalNow(alreadyOpenMsg);
            
            logical;                          
        }
        
        /* 
         *   An object can't be open if it's locked. We test this at check
         *   rather than verify since it may not be obvious that an object's
         *   locked until someone tries to open it.
         */
        check()
        {
            if(isLocked)           
                say(lockedMsg);            
        }
        
        action()
        {
            makeOpen(true);
            
            /* 
             *   If opening us is not being performed as an implicit action,
             *   list the contents that are revealed as a result of our being
             *   opened.
             */
            if(!gAction.isImplicit)
            {              
                unmention(contents);
                listSubcontentsOf(self, &myOpeningContentsLister);
            }           
        }
        
        report()
        {
            DMsg(okay open, okayOpenMsg, gActionListStr);
        }
    }
    
    /* 
     *   The lister to use when listing my contents when I'm opened. By default
     *   we use the openingContentsLister.
     */
    myOpeningContentsLister = openingContentsLister

    okayOpenMsg = 'Opened.|{I} open{s/ed} {1}. '
    
    cannotOpenMsg = BMsg(cannot open, '{The subj dobj} {is} not something {i}
        {can} open. ')
    alreadyOpenMsg = BMsg(already open, '{The subj dobj} {is} already open. ')
    lockedMsg = BMsg(locked, '{The subj dobj} {is} locked. ')
 
    
    /* By default something is closeable if it's openable */         
    isCloseable = (isOpenable)
    
    dobjFor(Close)
    {
        preCond = [touchObj]
        
        remap()
        {
            if(!isCloseable && remapIn != nil && remapIn.isCloseable)
                return remapIn;
            else
                return self;
        }
        
        
        verify()
        {
            if(!isCloseable)
                illogical(cannotCloseMsg);
            if(!isOpen)
                illogicalNow(alreadyClosedMsg);
            logical;
        }
           
        
        action()
        {            
            makeOpen(nil);
        }
        
        report()
        {
            DMsg(report close, 'Done. |{I} close{s/d} {1}. ',  gActionListStr);
        }
    }
    
    cannotCloseMsg = BMsg(not closeable, '{The subj dobj} {is} not something
        that {can} be closed. ')
    alreadyClosedMsg = BMsg(already closed,'{The subj dobj} {isn\'t} open. ')
    
       
    
    /* 
     *   By default we make everything turnable, but lots of things clearly
     *   won't be.
     */
    isTurnable = true
    
    
    dobjFor(Turn)
    {
        
        preCond = [touchObj]
        
        verify()
        {
            if(!isTurnable)
                illogical(cannotTurnMsg);
            else if(isDirectlyIn(gActor))
                logical;
            else
                logicalRank(80);
        }
        
        report()
        {
            say(turnNoEffectMsg);
        }
        
    }
    
    cannotTurnMsg = BMsg(cannot turn, '{The subj dobj} {can\'t} be turned. ')
    
    turnNoEffectMsg = BMsg(turn useless, 'Turning {1} {dummy} achieve{s/d}
        nothing. ', gActionListStr)
    
    dobjFor(TurnWith)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isTurnable)
                illogical(cannotTurnMsg);
            else if(isDirectlyIn(gActor))
                logical;
            else
                logicalRank(80);
        }
        
        report()
        {
            say(turnNoEffectMsg);
        }
        
    }
    
    /* By default things can't be used to turn other things with */
    canTurnWithMe = nil
    
    iobjFor(TurnWith)
    {
        preCond = [objHeld]
        verify() 
        {           
            if(!canTurnWithMe)
                illogical(cannotTurnWithMsg); 
            
            if(gVerifyDobj == self)
                illogical(cannotTurnWithSelfMsg); 
        }
    }
        
    
    cannotTurnWithMsg = BMsg(cannot turn with, '{I} {can\'t} turn anything with
        {that iobj}. ')
    
    cannotTurnWithSelfMsg = BMsg(turn self, '{I} {cannot} turn anything with
        itself. ')
    
    /* By default things can't be cut */
    isCuttable = nil
    
    dobjFor(Cut)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isCuttable)
               illogical(cannotCutMsg); 
        }
        
        action() { askForIobj(CutWith); }
    }
    
    dobjFor(CutWith)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isCuttable)
               illogical(cannotCutMsg); 
        }
    }
    
    /* Most things can't be used to cut other things with */
    canCutWithMe = nil
    
    iobjFor(CutWith)
    {
        preCond = [objHeld]
        
        verify()
        {                       
            if(!canCutWithMe)
                illogical(cannotCutWithMsg);
            
            if(self == gVerifyDobj)
                illogicalSelf(cannotCutWithSelfMsg);
        }
    }
    
    cannotCutMsg = BMsg(cannot cut, '{I} {can\'t} cut {the dobj}. ')
    cannotCutWithMsg = BMsg(cannot cut with, '{I} {can\'t} cut anything with
        {that iobj}. ')
    cannotCutWithSelfMsg = BMsg(cannot cut with self, '{I} {cannot} cut anything
        with itself. ')
                     
    
    /* 
     *   If the actor finds something in a hiddenPrep list and there's nowhere
     *   obvious for it go, should he take it? By default the actor should take
     *   it if the object he's found it in/under/behind is fixed in place.
     */
    autoTakeOnFindHidden = (isFixed)
    
    /*   
     *   Where should an item that's been hidden in/under/behind something be
     *   moved to when its found? If it's taken, move into the actor; otherwise
     *   move it to the location of the object it's just been found
     *   in/under/behind.
     */
    findHiddenDest = (autoTakeOnFindHidden ? gActor : location)
      
    dobjFor(LookIn)
    {
        preCond = [objVisible, containerInteriorVisible]
        
        remap = remapIn
                
        verify()
        {
            if(contType == In || remapIn != nil)
                logicalRank(120);
                        
            logical;
        }
        
        action()
        {       
           /* 
            *   If we're actually a container-type object, i.e. if our contType
            *   is In, try to determine what's inside us and display a list of
            *   it; if there's nothing inside us just display a message to that
            *   effect.
            */
            if(contType == In)
            {            
                /* 
                 *   If there's anything hidden inside us move it into us before
                 *   doing anything else
                 */
                if(hiddenIn.length > 0)                
                    moveHidden(&hiddenIn, self);                    
                
                
                /* If there's nothing inside us, simply display our lookInMsg */
                if(contents.length == 0)
                    display(&lookInMsg);                    
                
                /* Otherwise display a list of our contents */
                else
                {
                    /* Start by marking our contents as not mentioned. */
                    unmention(contents);
                    
                    /* 
                     *   It's possible that we have contents but nothing in our
                     *   contents is listable, so instead of just displaying a
                     *   list of contents we also watch to see if anything is
                     *   displayed; if nothing was we display our lookInMsg
                     *   instead.
                     */
                    if(gOutStream.watchForOutput(
                        {: listSubcontentsOf(self, &myLookInLister) }) == nil)
                      display(&lookInMsg);       

                }
            }
            
            /* 
             *   Otherwise, if we're not a container-type object (our contType
             *   is not In), if there's anything in our hiddenIn list move it
             *   into scope and display a list of it.
             */
            else if(hiddenIn.length > 0)            
                findHidden(&hiddenIn, In);                               
                        
            
            /*  Otherwise just display our lookInMsg */
            else
                display(&lookInMsg);
        }
        
    }
    
    /* 
     *   The lister to use when listing the objects inside me in response to a
     *   LOOK IN command. By default we use the lookInLister.
     */
    myLookInLister = lookInLister
    
    
    /* 
     *   By default our lookInMsg just says the actor finds nothing of interest
     *   in us; this could be overridden for an objecy with a more interesting
     *   interior.
     */
    lookInMsg = BMsg(look in, '{I} {find} nothing of interest in {the
        dobj}. ')
    
    
    /* 
     *   If there's something hidden in the dobj but nowhere obvious to move it
     *   to then by default we move everything from the hiddenIn list to the
     *   actor's inventory and announce that the actor has taken it. We call
     *   this out as a separate method to make it easy to override if desired.
     */    
    findHidden(prop, prep)
    {
        /* Report what we find */
        sayFindHidden(prop, prep);
        
        /* Move the hidden items to the appropriate location. */
        moveHidden(prop, findHiddenDest);        
    }
    
    /*  
     *   Report what was found hidded in/under/behind us. We make this a
     *   separate method so that it can be easily customized on individual
     *   objects.
     */
    sayFindHidden(prop, prep)
    {
         DMsg(find hidden, '\^{1} {the dobj} {i} {find} {2}<<if findHiddenDest ==
              gActor>>, which {i} {take}<<end>>. ',
             prep.prep, makeListStr(self.(prop)));
    }
    
    /* 
     *   We can look under most things, but there are some things (houses, the
     *   ground, sunlight) it might not make much sense to try looking under.
     */
    canLookUnderMe = true  
    
    
    dobjFor(LookUnder)
    {
        preCond = [objVisible, touchObj]
        
        remap = remapUnder        
        
        verify()
        {
            if(!canLookUnderMe)
                illogical(cannotLookUnderMsg);       
        }
        
        
        action()
        {            
            /* 
             *   If we're actually an underside-type object, i.e. if our
             *   contType is Under, try to determine what's under us and display
             *   a list of it; if there's nothing under us just display a
             *   message to that effect.
             */                       
            if(contType == Under)
            {
                
                /* 
                 *   If there's anything hidden under us move it into us before
                 *   doing anything else
                 */
                if(hiddenUnder.length > 0)                
                    moveHidden(&hiddenUnder, self);                    
                
                /* If there's nothing under us, simply display our lookUnerMsg */
                if(contents.length == 0)
                    display(&lookUnderMsg);  
                
                /* Otherwise display a list of our contents */
                else
                {
                    /* Start by marking our contents as not mentioned. */
                    unmention(contents);
                    
                    /* 
                     *   It's possible that we have contents but nothing in our
                     *   contents is listable, so instead of just displaying a
                     *   list of contents we also watch to see if anything is
                     *   displayed; if nothing was we display our lookUnderMsg
                     *   instead.
                     */
                    if(gOutStream.watchForOutput(
                        {: listSubcontentsOf(self, &myLookUnderLister) }) == nil)
                        display(&lookUnderMsg);  
                    
                }
            }
            
            /* 
             *   Otherwise, if we're not an underside-type object (our contType
             *   is not Under), if there's anything in our hiddenUnder list move
             *   it into scope and display a list of it.
             */
            else if(hiddenUnder.length > 0)            
                findHidden(&hiddenUnder, Under);      
            
            /*  Otherwise just display our lookUnderMsg */
            else
                display(&lookUnderMsg);           
            
        }
    }
    
    /* 
     *   The lister to use when listing the objects under me in response to a
     *   LOOK UNDER command. By default we use the lookInLister.
     */
    myLookUnderLister = lookInLister
    
    cannotLookUnderMsg = BMsg(cannot look under, '{I} {can\'t} look under {that
        dobj}. ')
    
    lookUnderMsg = BMsg(look under, '{I} {find} nothing of interest under
        {the dobj}. ')
    
     
    
    /* 
     *   By default we make it possible to look behind things, but there could
     *   be many things it makes no sense to try to look behind.
     */    
    canLookBehindMe = true    
    
    dobjFor(LookBehind)
    {
        preCond = [objVisible, touchObj]
        
        remap = remapBehind        
        
        verify()
        {
            if(!canLookBehindMe)
                illogical(cannotLookBehindMsg);
        }
        
        
        action()
        {            
            /* 
             *   If we're actually a rear-type object, i.e. if our contType is
             *   Behind, try to determine what's behind us and display a list of
             *   it; if there's nothing behind us just display a message to that
             *   effect.
             */
            if(contType == Behind)
            {
                
                /* 
                 *   If there's anything hidden behind us move it into us before
                 *   doing anything else
                 */
                if(hiddenBehind.length > 0)                
                    moveHidden(&hiddenBehind, self);                    
                
                /* 
                 *   If there's nothing behind us, simply display our
                 *   lookBehindMsg
                 */
                if(contents.length == 0)
                    display(&lookBehindMsg);  
                
                /* Otherwise display a list of our contents */
                else
                {
                    /* Start by marking our contents as not mentioned. */
                    unmention(contents);
                    
                    /* 
                     *   It's possible that we have contents but nothing in our
                     *   contents is listable, so instead of just displaying a
                     *   list of contents we also watch to see if anything is
                     *   displayed; if nothing was we display our lookBehindMsg
                     *   instead.
                     */
                    if(gOutStream.watchForOutput(
                        {: listSubcontentsOf(self, &myLookBehindLister) }) == nil)                        
                        display(&lookBehindMsg); 

                }
            }
            
            /* 
             *   Otherwise, if we're not a rear-type object (our contType is not
             *   Behind), if there's anything in our hiddenBehind list move it
             *   into scope and display a list of it.
             */
            else if(hiddenBehind.length > 0)            
                findHidden(&hiddenBehind, Behind);     
            
            /*  Otherwise just display our lookBehindMsg */
            else
                display(&lookBehindMsg);           
            
            
        }
    }
    
    
    /* 
     *   The lister to use when listing the objects behind me in response to a
     *   LOOK BEHIND command. By default we use the lookInLister.
     */
    myLookBehindLister = lookInLister
    
    
    cannotLookBehindMsg = BMsg(cannot look behind, '{I} {can\'t} look behind
        {that dobj}. ')
    
    lookBehindMsg = BMsg(look behind, '{I} {find} nothing of interest behind {the
        dobj}. ')
    
           
    
    /* 
     *   By default we make it possible to look through things, but there may
     *   well be things you obviously couldn't look through.
     */
    canLookThroughMe = true
    
    dobjFor(LookThrough)
    {
        preCond = [objVisible]
        
        verify()
        {
            if(!canLookThroughMe)
                illogical(cannotLookThroughMsg);            
        }
        
        action() { display(&lookThroughMsg); }
    }
    
    cannotLookThroughMsg = BMsg(cannot look through, '{I} {can\'t} look through
        {that dobj}. ')
    
    lookThroughMsg = BMsg(look through, '{I} {see} nothing of interest through {the
        dobj}. ')
    
    
    /* Most things cannot be gone through */
    canGoThroughMe = nil
    
    dobjFor(GoThrough)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canGoThroughMe)
                illogical(cannotGoThroughMsg); 
        }
    }
    
    cannotGoThroughMsg = BMsg(cannot go through,'{I} {can\'t} go through {that
        dobj}. ')
    
    
    /* Most things cannot be gone along */
    canGoAlongMe = nil
    
    dobjFor(GoAlong)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canGoAlongMe)
                illogical(cannotGoAlongMsg); 
        }
    }
    
    cannotGoAlongMsg = BMsg(cannot go through,'{I} {can\'t} go along {that
        dobj}. ')
    
    
    /* We can at least try to push most things. */
    isPushable = true
    
    dobjFor(Push)
    {
        preCond = [touchObj]
        verify()
        {
            if(!isPushable)
                illogical(cannotPushMsg);
        }
        
        report() { say(pushNoEffectMsg); }
    }
        
    cannotPushMsg = BMsg(cannot push, 'There{\'s} no point trying to push
        {that dobj}. ')
    
    pushNoEffectMsg = BMsg(push no effect, 'Pushing {1} {dummy} {has} no
        effect. ', gActionListStr)
    
    /* We can at least try to pull most things. */
    isPullable = true
    
    dobjFor(Pull)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isPullable)
                illogical(cannotPullMsg);
        }
        
        report() { say(pullNoEffectMsg); }
    }
    
    cannotPullMsg = BMsg(cannot pull, 'There{\'s} no point trying to pull
        {that dobj}. ')
    
    pullNoEffectMsg = BMsg(pull no effect, 'Pulling {1} {dummy} {has} no
        effect. ', gActionListStr)
    
    /* 
     *   The most usual reason why we can't put something somewhere is that we
     *   can't pick it up in the first place, so by default we'll just copy
     *   cannotPutMsg from cannotTakeMsg.
     */
    cannotPutMsg = cannotTakeMsg
    
       
    dobjFor(PutOn)
    {
        preCond = [objHeld, objNotWorn]
        
        verify()
        {
            if(gVerifyIobj == self)
                illogicalSelf(cannotPutInSelfMsg);  
            
            if(isFixed)
                illogical(cannotPutMsg);
            
            if(isDirectlyIn(gVerifyIobj))
                illogicalNow(alreadyInMsg);
            
            if(gVerifyIobj.isIn(self))
                illogicalNow(circularlyInMsg);     
            
           
            
            logical;
        }
        
        
        action()
        {          
            /* Handled on iobj */                                    
        }
        
        report()
        {
            DMsg(report put on, '{I} {put} {1} on {the iobj}. ', gActionListStr);            
        }
    }
    
    alreadyInMsg = BMsg(already in, '{The subj dobj} {is} already {1}. ', gVerifyIobj.objInName)
    
    circularlyInMsg = BMsg(circularly in, '{I} {can\'t} put {the dobj} {1}
        while {the subj iobj} {is} {in dobj}. ', gVerifyIobj.objInName)
        
    cannotPutInSelfMsg = BMsg(cannot put in self, '{I} {can\'t} put {the dobj}
        {1} {itself dobj}. ', gIobj.objInPrep)
    
    iobjFor(PutOn)
    {
        
        preCond = [touchObj]
        
        remap = remapOn         
        
        verify()
        {
            if(contType != On)
                illogical(cannotPutOnMsg);
            
            logical;
        }
        
        check()
        {
            checkInsert(gDobj);
        }
        
        action()
        {
            gDobj.actionMoveInto(self);
        }      
    
    }
    
    cannotPutOnMsg = BMsg(cannot put on,'{I} {can\'t} put anything on {the
        iobj}. '   )
    
    dobjFor(PutIn)
    {
        preCond = [objHeld, objNotWorn]
        
        verify()
        {            
            if(gVerifyIobj == self)
                illogicalSelf(cannotPutInSelfMsg);   
            
            if(isDirectlyIn(gVerifyIobj))
                illogicalNow(alreadyInMsg);
            
            if(isFixed)
                illogical(cannotPutMsg);
            
            if(gVerifyIobj.isIn(self))
                illogicalNow(circularlyInMsg);    
                        
            
            logical;
        }
        
              
        action()
        {                     
            /* handled on iobj */                          
        }
        
        report()
        {
            DMsg(report put in, '{I} {put} {1} in {the iobj}. ', gActionListStr);            
        }
    }
    
    
        
    iobjFor(PutIn)
    {
        preCond = [containerInteriorAccessible, touchObj]
        
        remap = remapIn        
        
        verify()
        {
            if(!canPutInMe)
                illogical(cannotPutInMsg);
            
            logical;
        }
        
        check()
        {            
            /* 
             *   If we're actually a container-like object (our contType is In),
             *   check whether there's enough room inside us to contain the
             *   direct object.
             */
            if(contType == In)
               checkInsert(gDobj);
            
            /*  
             *   Otherwise check whether adding the direct object to our
             *   hiddenIn list would exceed the amount of bulk allowed there.
             */
            else if(gDobj.bulk > maxBulkHiddenIn - getBulkHiddenIn)
                DMsg(no room in, 'There {dummy}{isn\'t} enough room for {the
                    dobj} in {the iobj}. ');            
        }
        
        action()
        {
            
            /* 
             *   If we're actually a container-like object (i.e. if our contType
             *   is In) then something put in us can be moved inside us.
             *   Otherwise, all we can do with something put in us is to add it
             *   to our hiddenIn list and move it off-stage.
             */            
            if(contType == In)
                gDobj.actionMoveInto(self);
            else
            {
                hiddenIn += gDobj;
                gDobj.actionMoveInto(nil);
            }  
        }      
    
    }
    
    cannotPutInMsg = BMsg(cannot put in, '{I} {can\'t} put anything in {the
        iobj}. ')
    
    
    
    dobjFor(PutUnder)
    {
        preCond = [objHeld, objNotWorn]
        
                
        verify()
        {
            if(gVerifyIobj == self)
                illogicalSelf(cannotPutInSelfMsg);     
            
            if(isFixed)
                illogical(cannotPutMsg);
            
            if(isDirectlyIn(gVerifyIobj))
                illogicalNow(alreadyInMsg);
            
            if(gVerifyIobj.isIn(self))
                illogicalNow(circularlyInMsg);           
            
                         
            logical;           
        }
        
        action()
        {
            /* Handled by iobj */
        }
        
        report()
        {
            DMsg(report put under, '{I} {put} {1} under {the iobj}. ', 
                 gActionListStr);
        }
        
            
    }
    
    iobjFor(PutUnder)
    {
        preCond = [touchObj]
        
        remap = remapUnder
        
        verify()
        {
            if(!canPutUnderMe)
                illogical(cannotPutUnderMsg);
            else
                logical;
        }
        
        check() 
        { 
            /* 
             *   If we're actually an underside-like object (our contType is
             *   Under), check whether there's enough room under us to contain
             *   the direct object.
             */
            if(contType == Under)
               checkInsert(gDobj); 
            
            /*  
             *   Otherwise check whether adding the direct object to our
             *   hiddenUnder list would exceed the amount of bulk allowed there.
             */
            else if(gDobj.bulk > maxBulkHiddenUnder - getBulkHiddenUnder)
                DMsg(no room under, 'There {dummy}{isn\'t} enough room for {the
                    dobj} under {the iobj}. ');    
        }
        
        action()
        {
            /* 
             *   If we're actually an underside-like object (i.e. if our
             *   contType is Under) then something put under us can be moved
             *   inside us. Otherwise, all we can do with something put under us
             *   is to add it to our hiddenUnder list and move it off-stage.
             */
            if(contType == Under)
                gDobj.actionMoveInto(self);
            else
            {
                hiddenUnder += gDobj;
                gDobj.actionMoveInto(nil);
            }
        }
        
        
    }
    
    cannotPutUnderMsg = BMsg(cannot put under, '{I} {cannot} put anything under
        {the iobj}. ' )
        
    dobjFor(PutBehind)
    {
        preCond = [objHeld, objNotWorn]
        
        verify()
        {
            if(gVerifyIobj == self)
                illogicalSelf(cannotPutInSelfMsg);     
            
            if(isFixed)
                illogical(cannotPutMsg);
            
            if(isDirectlyIn(gVerifyIobj))
                illogicalNow(alreadyInMsg);
            
            if(gVerifyIobj.isIn(self))
                illogicalNow(circularlyInMsg);           
            
                         
            logical;           
        }
        
        action()
        {
            /* Handled by iobj */
        }
        
        report()
        {
            DMsg(report put behind, '{I} {put} {1} behind {the iobj}. ', 
                 gActionListStr);
        }
        
            
    }
    
    iobjFor(PutBehind)
    {
        preCond = [touchObj]
        
        remap = remapBehind
        
        verify()
        {
            if(!canPutBehindMe)
                illogical(cannotPutBehindMsg);
            else
                logical;
        }
        
        check() 
        { 
            /* 
             *   If we're actually a rear-like object (our contType is Behind),
             *   check whether there's enough room behind us to contain the
             *   direct object.
             */
            if(contType == Behind)
                checkInsert(gDobj);
            
            /*  
             *   Otherwise check whether adding the direct object to our
             *   hiddenBehind list would exceed the amount of bulk allowed
             *   there.
             */
             else if(gDobj.bulk > maxBulkHiddenBehind - getBulkHiddenBehind)
                DMsg(no room behind, 'There {dummy}{isn\'t} enough room for {the
                    dobj} behind {the iobj}. ');    
        }
        
        action()
        {
            /* 
             *   If we're actually a rear-like object (i.e. if our contType is
             *   Behind) then something put behind us can be moved inside us.
             *   Otherwise, all we can do with something put behind us is to add
             *   it to our hiddenBehind list and move it off-stage.
             */
            if(contType == Behind)
                gDobj.actionMoveInto(self);
            else
            {
                hiddenBehind += gDobj;
                gDobj.actionMoveInto(nil);
            }
        }
        
        
    }   
    
    cannotPutBehindMsg = BMsg(cannot put behind, '{I} {cannot} put anything
        behind {the iobj}. ')
    
    /* 
     *   A list of Keys that can be used to lock or unlock this Thing. Any Keys
     *   in this list will cause this Thing to be added to the plausible and
     *   actual lock lists of that Key at PreInit. This provides an alternative
     *   way of specifying the relation between locks and keys.
     */        
    keyList = nil
       
    /*   
     *   A list of Keys that the player character starts out knowing at the
     *   start of the game can lock our unlock this Thing.
     */
    knownKeyList = nil
    
    /* 
     *   Note: we don't use isLockable, because this is not a binary property;
     *   there are different kings of lockability and defining an isLockable
     *   property in addition would only confuse things and might break the
     *   logic.
     */    
    dobjFor(UnlockWith)
    {
        
        preCond = [touchObj]
        
        /* 
         *   Remap the unlock action to our remapIn object if we're not lockable
         *   but we have a lockable remapIn object (i.e. an associated
         *   container).
         */
        remap()
        {
            if(lockability == notLockable && remapIn != nil &&
               remapIn.lockability != notLockable)
                return remapIn;
            else
                return self;
        }
        
        verify()
        {
            /* 
             *   If we're not lockable at all, we're a very poor choice of
             *   direct object for an UnlockWith action.
             */
            if(lockability == notLockable || lockability == nil)
                illogical(notLockableMsg);
            
            /*  
             *   If we're lockable, but not with a key (either because we don't
             *   need one at all or because we use some other form of locking
             *   mechanism) then we're still a bad choice of object for an
             *   UnlockWith action, but not so bad as if we weren't lockable at
             *   all.
             */
            if(lockability == lockableWithoutKey)
                implausible(keyNotNeededMsg);
            
            if(lockability == indirectLockable)
                implausible(indirectLockableMsg);
            
            /*  
             *   If we are lockable with key, then were a good choice of object
             *   for an UnlockWith action provided we're currently locked.
             */
            if(lockability == lockableWithKey)
            {
                if(isLocked)
                    logical;
                else
                    illogicalNow(notLockedMsg);
            }
        }
    }
    
    notLockableMsg = BMsg(not lockable, '{The subj dobj} {isn\'t} lockable. ')
    keyNotNeededMsg = BMsg(key not needed,'{I} {don\'t need[ed]} a key to lock
        and unlock {the dobj}. ')
    indirectLockableMsg = BMsg(indirect lockable,'{The dobj} appear{s/ed} to use
        some other kind of locking mechanism. ')
    notLockedMsg = BMsg(not locked, '{The subj dobj} {isn\'t} locked. ')
    
    /* 
     *   Most things can't be used to unlock with. In practice there's probably
     *   little point in overriding this property since if you do want to use
     *   something to unlock other things with, you'd use the Key class.
     */
    canUnlockWithMe = nil 
    
    iobjFor(UnlockWith)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!canUnlockWithMe)
               illogical(cannotUnlockWithMsg);
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotUnlockWithSelfMsg);
        }      
    }
    
    cannotUnlockWithMsg = BMsg(cannot unlock with, '{I} {can\'t} unlock
        anything with {that iobj}. ' )
    
    cannotUnlockWithSelfMsg = BMsg(cannot unlock with self, '{I} {can\'t} unlock
        anything with itself. ' )
    
    dobjFor(LockWith)
    {
        preCond  = [objClosed, touchObj]
        
         /* 
          *   Remap the lock action to our remapIn object if we're not lockable
          *   but we have a lockable remapIn object (i.e. an associated
          *   container).
          */
        remap()
        {
            if(lockability == notLockable && remapIn != nil &&
               remapIn.lockability != notLockable)
                return remapIn;
            else
                return self;
        }
        
        verify()
        {
            if(lockability == notLockable || lockability == nil)
                illogical(notLockableMsg);
            
            if(lockability == lockableWithoutKey)
                implausible(keyNotNeededMsg);
            
            if(lockability == indirectLockable)
                implausible(indirectLockableMsg);
            
            if(lockability == lockableWithKey)
            {
                if(isLocked)
                   illogicalNow(alreadyLockedMsg);
                else                    
                    logical;
            }
        }
        
    }
    
    alreadyLockedMsg = BMsg(already locked, '{The subj dobj} {is} already
        locked. ')
    
    
    /* 
     *   Usually, if something can be used to unlock things it can also be used
     *   to lock them
     */
    canLockWithMe = (canUnlockWithMe)
    
    iobjFor(LockWith)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!canLockWithMe)
               illogical(cannotLockWithMsg);
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotLockWithSelfMsg);
        }      
    }
    
    cannotLockWithMsg = BMsg(cannot lock with, '{I} {can\'t} lock anything with
        {that iobj}. ' )
    
    cannotLockWithSelfMsg = BMsg(cannot lock with self, '{I} {can\'t} lock
        anything with itself. ' )
    
    
    dobjFor(Unlock)
    {
        preCond = [touchObj]
        
        /* 
         *   Remap the unlock action to our remapIn object if we're not lockable
         *   but we have a lockable remapIn object (i.e. an associated
         *   container).
         */
        remap()
        {
            if(lockability == notLockable && remapIn != nil &&
               remapIn.lockability != notLockable)
                return remapIn;
            else
                return self;
        }
        
        verify()
        {
            if(lockability == notLockable || lockability == nil)
                illogical(notLockableMsg);
            
            if(lockability == indirectLockable)
                implausible(indirectLockableMsg);
            
            if(!isLocked)            
                illogicalNow(notLockedMsg);           
        }
        
        check()
        {
            /* 
             *   if we need a key to be unlocked with, check whether the player
             *   is holding a suitable one.
             */
            if(lockability == lockableWithKey)            
                findPlausibleKey();                
            
               
        }
        
        action()
        {
            /* 
             *   The useKey_ property will have been set by the
             *   findPlausibleKey() method at the check stage. If it's non-nil
             *   it's the key we're going to use to try to unlock this object
             *   with, so we display a parenthetical note to the player that
             *   we're using this key. (Note: the action would have failed at
             *   the check stage if useKey_ wasn't the right key for the job).
             */
            if(useKey_ != nil)
                extraReport(withKeyMsg);
            
            /* 
             *   Otherwise, if we need a key to unlock this object with, ask the
             *   player to specify it and then execute an UnlockWith action
             *   using that key.
             */ 
            else if(lockability == lockableWithKey)
                askForIobj(UnlockWith);
            
            /*  Make us unlocked. */
            makeLocked(nil);               
        }
        
        report()
        {
            DMsg(report unlock, okayUnlockMsg, gActionListStr);
        }
        
    }
    
    okayUnlockMsg = 'Unlocked.|{I} unlock{s/ed} {1}. '
    
    dobjFor(Lock)
    {
        preCond = [objClosed, touchObj]
        
         /* 
          *   Remap the lock action to our remapIn object if we're not lockable
          *   but we have a lockable remapIn object (i.e. an associated
          *   container).
          */
        remap()
        {
            if(lockability == notLockable && remapIn != nil &&
               remapIn.lockability != notLockable)
                return remapIn;
            else
                return self;
        }
        
        verify()
        {
            if(lockability == notLockable || lockability == nil)
                illogical(notLockableMsg);
            
            if(lockability == indirectLockable)
                implausible(indirectLockableMsg);            
            
            if(isLocked)
                illogicalNow(alreadyLockedMsg);            
            
        }
        
        check()
        {
            /* 
             *   if we need a key to be locked with, check whether the player
             *   is holding a suitable one.
             */
            if(lockability == lockableWithKey)            
                findPlausibleKey();                
            
               
        }
        
        action()
        {
            /* 
             *   The useKey_ property will have been set by the
             *   findPlausibleKey() method at the check stage. If it's non-nil
             *   it's the key we're going to use to try to lock this object
             *   with, so we display a parenthetical note to the player that
             *   we're using this key. (Note: the action would have failed at
             *   the check stage if useKey_ wasn't the right key for the job).
             */
            if(useKey_ != nil)
                extraReport(withKeyMsg);
                
            /* 
             *   Otherwise, if we need a key to unlock this object with, ask the
             *   player to specify it and then execute a LockWith action
             *   using that key.
             */    
            else if(lockability == lockableWithKey)
                askForIobj(LockWith);
         
            /*  Make us locked. */
            makeLocked(true);              
        }
        
        report()
        {
            DMsg(report lock, okayLockMsg, gActionListStr);
        }
    }
    
    
    
    
    okayLockMsg = 'Locked.|{I} lock{s/ed} {1}. '
    
    withKeyMsg = BMsg(with key, '<.assume>with {1}<./assume>\n', useKey_.theName)
    
    /* 
     *   Find a key among the actor's possessions that might plausibly lock or
     *   unlock us. If the silent parameter is true, then don't report a failed
     *   attempt.
     */
    findPlausibleKey(silent = nil)
    {
      
        useKey_ = nil;   
        local lockObj = self;
        
        /* 
         *   First see if the actor is holding a key that is known to work on
         *   this object. If so, use it.
         */
        foreach(local obj in gActor.contents)
        {
            if(obj.ofKind(Key) 
               && obj.knownLockList.indexOf(self) !=  nil)
            {
                useKey_ = obj;
                return;
            }
        }
        
        
        /*  
         *   Then see if the actor is holding a key that might plausibly work on
         *   this object; if so, try that.
         */
        foreach(local obj in gActor.contents)
        {
            if(obj.ofKind(Key) 
               && obj.plausibleLockList.indexOf(self) !=  nil)
            {
                useKey_ = obj;
                break;
            }
        }
        
        /*  
         *   If we haven't found a suitable key yet, check to see if the actor
         *   is holding one that might fit our lexicalParent, if we have a
         *   lexicalParent whose interior we're representing.
         */
        if(useKey_ == nil)
        {
            if(lexicalParent != nil && lexicalParent.remapIn == self)
            {
                lexicalParent.findPlausibleKey();
                useKey_ = lexicalParent.useKey_;
                lockObj = lexicalParent;
            }
        }
        
        /*  
         *   If we've found a possible key but it doesn't actually work on this
         *   object, report that we're trying this key but it doesn't work.
         */
        if(useKey_ && useKey_.actualLockList.indexOf(lockObj) == nil && !silent)
        {
            say(withKeyMsg);
            say(keyDoesntWorkMsg);            
        }
        
    }
  
    
    keyDoesntWorkMsg = BMsg(key doesnt work, 'Unfortunately {1} {dummy}
        {doesn\'t work[ed]} on {the dobj}. ', useKey_.theName)
    
    useKey_ = nil
    
    
    
    dobjFor(SwitchOn)
    {
        
        preCond = [touchObj]
        
        verify()
        {
            if(!isSwitchable)
                illogical(notSwitchableMsg);
            else if(isOn)
                illogicalNow(alreadyOnMsg);
        }
        
        action()
        {
            makeOn(true);
        }
        
        report()
        {
            DMsg(report turn on, 'Done.|{I} turn{s/ed} on {the dobj}. ');
        } 
    }
    
    notSwitchableMsg = BMsg(not switchable, '{The subj dobj} {can\'t} be
        switched on and off. ')
    alreadyOnMsg = BMsg(already switched on, '{The subj dobj} {is} already
        switched on. ')
    
    dobjFor(SwitchOff)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isSwitchable)
                illogical(notSwitchableMsg);
            else if(!isOn)
                illogicalNow(alreadyOffMsg);
        }
        
        action()
        {
            makeOn(nil);
        }
        
        report()
        {
            DMsg(report turn off, 'Done.|{I} turn{s/ed} off {the dobj}. ');
        } 
    }
    
   alreadyOffMsg = BMsg(not switched on, '{The subj dobj} {isn\'t} switched on.
       ')
    
    
    dobjFor(SwitchVague)
    {
        verify()
        {
            if(!isSwitchable)
                illogical(notSwitchableMsg);
        }
        
        action()
        {
            makeOn(!isOn);
        }
        
        report()
        {
            DMsg(report switch, 'Okay, {i} turn{s/ed} {1} {2}. ', isOn ? 
                 'on' : 'off', gActionListStr);
        }
    }
    
    /* 
     *   Since FLIP X is often synonymous with SWITCH X , by default we make
     *   something flippable if it's switchable.
     */
    isFlippable = (isSwitchable)
    
    dobjFor(Flip)
    {
        verify() 
        { 
            if(!isFlippable)
               illogical(cannotFlipMsg); 
        }
    }
    
    cannotFlipMsg = BMsg(cannot flip, '{I} {can\'t} usefully flip {the dobj}. ')
    
    
    /* By default we assume most things aren't burnable */
    isBurnable = nil
    
    dobjFor(Burn)
    {
        preCond = [touchObj]
        verify() 
        {
            if(!isBurnable)
               illogical(cannotBurnMsg); 
        }
    }
        
    dobjFor(BurnWith)
    {
        preCond = [touchObj]        
        verify() 
        {
            if(!isBurnable)
               illogical(cannotBurnMsg); 
        }
    }
    
    /* 
     *   By default we assume most things can't be used to burn other things
     *   with.
     */
    canBurnWithMe = nil
    
    iobjFor(BurnWith)
    {
        preCond = [objHeld]
        verify() 
        { 
            if(!canBurnWithMe)
                illogical(cannotBurnWithMsg); 
        }
    }
    
    cannotBurnMsg = BMsg(cannot burn, '{I} {cannot} burn {the dobj}. ')
    cannotBurnWithMsg = BMsg(cannot burn with, '{I} {can\'t} burn {the dobj}
        with {that iobj}. ')
    
    dobjFor(Wear)
    {
        preCond = [objHeld]
        
        verify()
        {
            if(!isWearable)
                illogical(cannotWearMsg);
            
            if(wornBy == gActor)
                illogicalNow(alreadyWornMsg);
        }
        
        action()  {  makeWorn(gActor);  }
        
        report()
        {
            DMsg(okay wear, 'Okay, {i}{\'m} now wearing {1}. ',
                 gActionListStr);
        }
    }
    
    cannotWearMsg = BMsg(cannot wear, '{The subj dobj} {can\'t} be worn. ')
    alreadyWornMsg = BMsg(already worn, '{I}{\'m} already wearing {the dobj}. ')
    
    
    /* By default we assume that something's doffable if it's wearable */
    isDoffable = (isWearable)
    
    dobjFor(Doff)
    {
        
        verify()
        {
            if(wornBy != gActor)
                illogicalNow(notWornMsg);
                        
            if(!isDoffable)
                illogical(cannotDoffMsg);
        }
        
        check()
        {
            checkRoomToHold();
        }
        
        action()  {   makeWorn(nil);  }
        
        report()
        {
            DMsg(okay doff, 'Okay, {I}{\'m} no longer wearing {1}. ', 
                 gActionListStr);
            
        }
    }
    
  
    cannotDoffMsg = (cannotWearMsg)
    
    notWornMsg = BMsg(not worn, '{I}{\'m} not wearing {the dobj}. ')
    
    /* Most things can't be climbed */
    isClimbable = nil
    
    dobjFor(Climb)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isClimbable)
               illogical(cannotClimbMsg); 
        }
    }
    
    canClimbUpMe = (isClimbable)
    
    dobjFor(ClimbUp)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canClimbUpMe)
               illogical(cannotClimbMsg); 
        }
    }
    
    cannotClimbMsg = BMsg(cannot climb,'{The subj dobj} {is} not something {i}
        {can} climb. ')
    
    canClimbDownMe = (isClimbable)
    
    dobjFor(ClimbDown)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canClimbDownMe)
               illogical(cannotClimbDownMsg); 
        }
    }
    
    cannotClimbDownMsg = BMsg(cannot climb down, '{The subj dobj} {is} not
        something {i} {can} climb down. ')
    
    dobjFor(Throw)
    {
        preCond = [objHeld, objNotWorn]
        
        verify()
        {
            if(!isThrowable)
                illogical(cannotThrowMsg);
        }
        
        action()
        {
            actionMoveInto(getOutermostRoom.dropLocation);            
        }
        
        report()
        {
            local obj = gActionListObj;
            gMessageParams(obj);
            DMsg(throw, '{The subj obj} sail{s/ed} through the air and land{s/ed}
                on the ground. ' );
        }
        
    }
    
    
    dobjFor(Board)
    {
        preCond = [touchObj, actorInStagingLocation]
        
        remap = remapOn
        
        verify()
        {
            if(!isBoardable || contType != On)
                illogical(cannotBoardMsg);
            
            if(gActor.isIn(self))
                illogicalNow(actorAlreadyOnMsg);
            
            if(isIn(gActor))
                illogicalNow(cannotGetOnCarriedMsg);
            
            if(gActor == self)
                illogicalSelf(cannotBoardSelfMsg);
        }
        
        check() { checkInsert(gActor); }
        
        action()
        {
            gActor.actionMoveInto(self);            
        }
        
        report()
        {
            DMsg(okay get on, '{I} {get} on {1}. ', gActionListStr);
        }
    }
    
    cannotBoardMsg = BMsg(cannot board, '{The subj dobj} {is} not something {i}
        {can} get on. ')
    
    cannotBoardSelfMsg = BMsg(cannot board self, '{I} {can} hardly get on {myself}. ')         
    
    actorAlreadyOnMsg = BMsg(already on, '{I}{\'m} already {in dobj}. ')
     
    cannotGetOnCarriedMsg = BMsg(cannot board carried, '{I} {can\'t} get on {the
        dobj} while {i}{\'m} carrying {him dobj}. ')
    
    /* 
     *   Since we don't track postures in this library we'll treat STAND ON as
     *   equivalent to BOARD
     */    
    dobjFor(StandOn) asDobjWithoutVerifyFor(Board)
    dobjFor(SitOn) asDobjWithoutVerifyFor(Board)
    dobjFor(LieOn) asDobjWithoutVerifyFor(Board)
    
    /*  
     *   Although we don't track postures as such, some objects may be better
     *   choices than other for sitting on (e.g. chairs), lying on (e.g. beds)
     *   and standing on (e.g. rugs), so we allow these to be tested for
     *   individually at the verify stage.
     *
     *   Note that none of these three properties (canSitOnMe, canLieOnMe,
     *   canStandOnMe) should normally be overridden to simply true, since they
     *   cannot make it possible to sit, lie or stand on something for which
     *   isBoardable is not true (or which contType is not On).
     */
    canSitOnMe = isBoardable
    canLieOnMe = isBoardable
    canStandOnMe = isBoardable
    
    
    /*   
     *   As well as ruling out certain objects for sitting, lying or standing
     *   on, we can also give them a score for each of these postures; e.g. a
     *   bed may be particularly suitable for lying on (although you could lie
     *   on the sofa) while a chair may be particularly suitable for sitting on
     *   (though you could sit on the bed.
     *
     *   By default we'll give each posture a score of 100, the normal logical
     *   verify score. Note that these scores have no effect if the
     *   corresponding can xxxOnMe property is nil.
     */
    sitOnScore = 100
    lieOnScore = 100
    standOnScore = 100
    
    dobjFor(StandOn)
    {
        verify()
        {
            if(!canStandOnMe)
                illogical(cannotStandOnMsg);
            else
                verifyDobjBoard();
            
            logicalRank(standOnScore);
        }
    }
    
    dobjFor(SitOn)
    {
        verify()
        {
            if(!canSitOnMe)
                illogical(cannotSitOnMsg);
            else
                verifyDobjBoard();            
            
            logicalRank(sitOnScore);
        }
    }
    
    dobjFor(LieOn)
    {
        verify()
        {
            if(!canLieOnMe)
                illogical(cannotLieOnMsg);
            else
                verifyDobjBoard();
            
            logicalRank(lieOnScore);
        }
    }
    
    cannotStandOnMsg = BMsg(cannot stand on, '{The subj dobj} {isn\'t}
        something {i} {can} stand on. ')
    cannotSitOnMsg = BMsg(cannot sit on, '{The subj dobj} {isn\'t}
        something {i} {can} sit on. ')
    cannotLieOnMsg = BMsg(cannot lie on, '{The subj dobj} {isn\'t}
        something {i} {can} lie on. ')
    
    
    /*   
     *   Flag, can we enter (i.e. get inside) this thing? For most objects, we
     *   can't
     */
    isEnterable = nil
    
    /*   Treat Enter X as equivalent to Get In X */
    
    dobjFor(Enter) 
    {
        preCond = [touchObj, containerOpen, actorInStagingLocation]
        
        remap = remapIn
        
        verify()
        {
            if(!isEnterable || contType != In)
                illogical(cannotEnterMsg);
            
            if(gActor.isIn(self))
                illogicalNow(actorAlreadyInMsg);
            
            if(isIn(gActor))
                illogicalNow(cannotGetInCarriedMsg);
        }
        
        check() { checkInsert(gActor); }
        
        action()
        {
            gActor.actionMoveInto(self);            
        }
        
        report()
        {
            DMsg(okay get in, '{I} {get} in {1}. ', gActionListStr);
        }
        
    }
    
    cannotEnterMsg = BMsg(cannot enter, '{The subj dobj} {is} not something {i}
        {can} enter. ')
    actorAlreadyInMsg = BMsg(actor already in, '{I}{\'m} already {in dobj}. ')
     
    cannotGetInCarriedMsg = BMsg(cannot enter carried, '{I} {can\'t} get in {the
        dobj} while {i}{\'m} carrying {him dobj}. ')
    
    
    /* 
     *   By default we'll treat standing, sitting or lying IN something as
     *   simply equivalent to entering it.
     */
    dobjFor(StandIn) asDobjFor(Enter)
    dobjFor(SitIn) asDobjFor(Enter)
    dobjFor(LieIn) asDobjFor(Enter)
    
    /* 
     *   Our exitLocation is the location an actor should be moved to when s/he
     *   gets off/out of us.
     */
    exitLocation = location
    
    /*   Our staging location is where we need to be to get on/in us */
    stagingLocation = (exitLocation)
    
    dobjFor(GetOff)
    {        
        preCond = [actorOutOfSubNested]
        
        remap = remapOn
        
        verify()
        {
            if(!gActor.isIn(self) || contType != On)
                illogicalNow(actorNotOnMsg);
            
        }
        
        action()
        {
            gActor.actionMoveInto(exitLocation);            
        }
        
        report() { say(okayGetOutOfMsg); }
    }
            
    dobjFor(GetOutOf) 
    {
        preCond = [containerOpen, actorOutOfSubNested]
        
        remap = remapIn
        
        verify()
        {
            if(!gActor.isIn(self) || contType != In)
                illogicalNow(actorNotInMsg);
            
        }
        
        action()
        {
            gActor.actionMoveInto(exitLocation);            
        }
        
        report() { say(okayGetOutOfMsg); }        
    }
    
    
    okayGetOutOfMsg = BMsg(okay get outof, 'Okay, {i} {get} {outof dobj}. ')
    
    actorNotInMsg = BMsg(actor not in,'{I}{\'m} not in {the dobj}. ')
    actorNotOnMsg = BMsg(actor not on,'{I}{\'m} not on {the dobj}. ')
    
    /* 
     *   We'll take REMOVE to mean DOFF when it's dobj is worn and TAKE
     *   otherwise. This handling will be dealt with by removeDoer insteadof
     *   remap, since this form of remap has now been discontinued. See
     *   english.t for removeDoer (which seems to be a language-specific
     *   construct)
     */
    dobjFor(Remove)
    {
        /* 
         *   We still need a verify() routine to help the parser find a suitable
         *   target for the command.
         */
             
        verify()
        {
            if(!isRemoveable)
                illogical(cannotRemoveMsg);
            
            /* 
             *   If we're already holding the object (and not wearing it),
             *   there's nothing for remove to do.
             */
            if(isDirectlyIn(gActor) && wornBy != gActor)
                illogicalNow(alreadyHeldMsg);
        }
    
        
    }
    
    /* By default an object is removeable if it's takeable */
         
    isRemoveable = (isTakeable)
    
    /* 
     *   Note that this message should never display in an English-language game
     *   since removeDoer will intercept the action before it gets to this
     *   point.
     */
    cannotRemoveMsg = BMsg(cannot remove, '{The subj dobj} {cannot} be removed.
        ')
    
    /* Treat SEARCH as equivalent to LOOK IN */
    dobjFor(Search) asDobjFor(LookIn)
    
    /* 
     *   By default we assume anything fixed isn't moveable unless it explicitly can be moved by
     *   PushTravel or PullTravel)
     */
    isMoveable = (!isFixed || canPushTravel || canPullTravel)
    
    /* 
     *   Moving an object is generally possible if the object is portable, but
     *   there's no obvious effect, so by default this action does nothing
     *   except say it's done nothing.
     */
    dobjFor(Move)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isMoveable)
                illogical(cannotMoveMsg);
        }
        
        action()  {  }
        
        report()
        {
            say(moveNoEffectMsg);
        }
    }
    
    cannotMoveMsg = BMsg(cannot move, '{The subj dobj} {won\'t} budge. ')  
    
    dobjFor(MoveWith)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isMoveable)
                illogical(cannotMoveMsg);
                        
        }
        
        action() {  }
        
        report()
        {
            say(moveNoEffectMsg);
        }
    }
    
    moveNoEffectMsg = BMsg(move no effect, 'Moving {1} {dummy} {has} no effect. ',
                 gActionListStr)
    
    /* 
     *   Most things can't be used to move other things with. Note that since
     *   the dobj is resolved first, objects or subclasses could override this
     *   with a method that returns true or nil depending on the identity of the
     *   dobj.
     */
    canMoveWithMe = nil
    
    iobjFor(MoveWith)
    {
        preCond = [objHeld]
        
        verify() 
        { 
            if(!canMoveWithMe)
               illogical(cannotMoveWithMsg); 
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotMoveWithSelfMsg);
        }
    }
    
    cannotMoveWithMsg = BMsg(cannot move with, '{I} {can\'t} move {the dobj}
        with {the iobj}. ')
    
    cannotMoveWithSelfMsg = BMsg(cannot move with self, '{The subj dobj}
        {can\'t} be used to move {itself dobj}. ')
    
    
    /*  
     *   MoveTo is a more complex case than MOVE or MOVE WITH. In this
     *   implementation we assume that it represents moving the direct object to
     *   the vicinity of the indirect object, and so we track the object it's
     *   been moved to.
     *
     *   This might be useful, say, if you wanted the player to have to MOVE the
     *   chair TO the bookcase before being able to reach the top shelf by
     *   standing on the chair, since you could then check the value of the
     *   chair's movedTo property before deciding whether the top shelf was
     *   accesssible.
     */
    dobjFor(MoveTo)
    {
        preCond = location.ofKind(Room) ? [touchObj] : [objHeld]
        
        verify()
        {
            if(!isMoveable)
                illogical(cannotMoveMsg);
        }
        
        action()
        {
            /* 
             *   If the iobj is a container-like object, assume MOVE TO it means putting us inside
             *   it/
             */
            if(gIobj.contType == In)
                replaceAction(PutIn, self, gIobj);
            
            /* If the obj is a surface-like object, assume MOVE TO it means putting us on it. */
            if(gIobj.contType == On)
                replaceAction(PutOn, self, gIobj);        
            
            /* Otherwise we mean moving us near the iobj. */
            makeMovedTo(gIobj);
        }
        
        report()
        {
            DMsg(okay move to, '{I} move{s/d} {1} {dummy} to {the iobj}. ',
                 gActionListStr);
        }
    }
    
    /* 
     *   The notional location (other object) this object has been moved to as
     *   the result of a MoveTo command.
     */
    movedTo = nil
    
    /* Cause this object to be moved to loc */
    makeMovedTo(loc)  
    { 
        actionMoveInto(loc.location);
        if(location == loc.location)            
            movedTo = loc; 
        
    }
    
    /* In general there's no reason why most objects can't be moved to. */
    canMoveToMe = true
    
    iobjFor(MoveTo)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!canMoveToMe)
                illogical(cannotMoveToMsg);           
            
            if(gDobj.movedTo == self)
                illogicalNow(alreadyMovedToMsg);
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotMoveToSelfMsg);
            
        }
        
    }
    
    cannotMoveToMsg = BMsg(cannot move to, '{The subj dobj} {can\'t} be moved to
        {the iobj}. ')
    
    cannotMoveToSelfMsg = BMsg(cannot move to self, '{The subj dobj} {can\'t}
        be moved to {itself dobj}. ')
    
    alreadyMovedToMsg = BMsg(already moved to, '{The subj dobj} {has} already
        been moved to {the iobj}. ')
    
    dobjFor(MoveAwayFrom)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isMoveable)
                illogical(cannotMoveMsg);
        }
        
        action()
        {
            if(movedTo)
                movedTo = nil;
            else if(gIobj.contType is in (In, On, Under, Behind))
                doInstead(TakeFrom, gDobj, gIobj);
        }
        
        report()
        {
            DMsg(okay move from, '{I} move{s/d} {1} {dummy} away from {the iobj}. ',
                 gActionListStr);   
        }
    } 
    
    iobjFor(MoveAwayFrom)
    {
        verify()
        {
            if(gDobj == self)
                illogicalSelf(cantMoveAwayFromSelfMsg);
            
            if(gDobj.movedTo != self && contType not in (In, On, Under, Behind))
                illogicalNow(notMovedToMsg);
        }
    }
    
    cantMoveAwayFromSelfMsg = BMsg(cant move away from self, '{I} {can\'t} move {the dobj} away from
        {itself dobj}. ')
    
    notMovedToMsg = BMsg(not by obj, '{The subj dobj} {is}n\'t by {the iobj}. ')
    
    /* 
     *   Lighting an object makes it a light source by making its isLit property
     *   true.
     */
    dobjFor(Light)
    {
        preCond = [touchObj]
        
        verify() 
        {
            if(!isLightable)
                illogical(cannotLightMsg); 
            else if(isLit)
                illogicalNow(alreadyLitMsg);
        }
        
        action()
        {
            makeLit(true);
        }
        
        report()
        {
            DMsg(okay lit,'Done.|{I} {light} {1}. ', gActionListStr);
        }
    }
    
    cannotLightMsg = BMsg(cannot light, '{The subj dobj} {is} not something
        {i} {can} light. ')
    
    alreadyLitMsg = BMsg(already lit, '{The subj dobj} {is} already lit. ')
    
    /* 
     *   Most things are extinguishable if they're lit, but some things (like
     *   the sun or a nuclear explosion) might conceivably not be. Note that
     *   this property should only be set to nil for things that couldn't be
     *   extinguished even if they were lit (the flames of Hell, for example,
     *   which might be considered undousable for all eternity, if you're bent
     *   on writing an infernal game).
     */
    isExtinguishable = true
    
    dobjFor(Extinguish)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isLit)
                illogicalNow(notLitMsg);
            
            if(!isExtinguishable)
                illogical(cannotExtinguishMsg);
            
        }
        
        action()
        {
            makeLit(nil);            
        }
        
        report()
        {
            DMsg(extinguish, '{I} {put} out {1}. ', gActionListStr);
        }
    }
    
    notLitMsg = BMsg(not lit, '{The subj dobj} {isn\'t} lit. ')
    
    cannotExtinguishMsg = BMsg(cannot extinguish, '{The dobj} {cannot} be
        extinguished. ')
    
        
    dobjFor(Eat)
    {
        preCond = [objHeld]
        
        verify() 
        { 
            if(!isEdible)
                illogical(cannotEatMsg); 
        }
        
        action()
        {
            moveInto(nil);            
        }
        
        report()
        {
            DMsg(eat, '{I} {eat} {1}. ', gActionListStr);
        }
    }
    
    cannotEatMsg = BMsg(cannot eat, '{The subj dobj} {is} plainly inedible. ')
    
    /* Most things aren't drinkable */
    isDrinkable = nil
    
    dobjFor(Drink)
    {
        preCond = [touchObj]
        
        verify() 
        {
            if(!isDrinkable)
               illogical(cannotDrinkMsg); 
            
        }
                
    }
        
    cannotDrinkMsg = BMsg(not potable, '{I} {can\'t} drink {1}. ', fluidName)
    
    
    /* 
     *   Most things probably could be cleaned, even if they're not worth
     *   cleaning in practice. Some things like a mountain or the moon probably
     *   can't be cleaned and could reasonably define isCleanable = nil.
     */
    isCleanable = true
    
    /* Assume most things start out not as clean as they could be */
    isClean = nil
    
    /* But that most things don't actually need cleaning in the game */
    needsCleaning = nil
    
    /* 
     *   If this is non-nil then this is an object or a list of objects that
     *   must be/can be used to clean this object.
     */
    mustBeCleanedWith = nil
    
    
    /*  
     *   The handling of the Clean action is possibly more elaborate than it
     *   needs to be by default, and game code may wish to override it with a
     *   different implementation, but the aim is to provide a framework that
     *   covers some common cases.
     *
     *   An object starts out with isClean = nil. Cleaning the object makes
     *   isClean true (at which point it doesn't need cleaning again).
     *
     *   If an object needs another object to be cleaned with (e.g. if in order
     *   to clean the window you need a wet sponge to clean it with), this can
     *   be defined by setting mustBeCleanedWith to an object or a list of
     *   objects that can be used to clean this direct object.
     */
    dobjFor(Clean)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isCleanable) 
                illogical(cannotCleanMsg);
            
            else if(isClean)
                illogicalNow(alreadyCleanMsg);        
        
            else if(!needsCleaning)
                implausible(noNeedToCleanMsg);           
            
        }
        
        
        action() 
        {
            if(mustBeCleanedWith != nil)
                askForIobj(CleanWith);
            
            makeCleaned(true); 
        }
        
        report()
        {
            say(okayCleanMsg);
        }
    }
    
    /* 
     *   Carry out the effects of cleaning. By default we just set the value of
     *   the isClean property, but game code could override this to carry out
     *   any side effects of cleaning, such as revealing the inscription on a
     *   dirty old gravestone.
     */
    makeCleaned(stat) { isClean = stat; }
    
    cannotCleanMsg = BMsg(cannot clean, '{The subj dobj} {is} not something {i}
        {can} clean. ')
    
    alreadyCleanMsg = BMsg(already clean, '{The subj dobj} {is} already quite
        clean enough. ')
    
    noNeedToCleanMsg = BMsg(no clean, '{The subj dobj} {doesn\'t need[ed]}
        cleaning. ')
        
    
    dontNeedCleaningObjMsg = BMsg(dont need cleaning obj, '{I} {don\'t need[ed]}
        anything to clean {the dobj} with. ')
    
    okayCleanMsg = DMsg(okay clean, 'Cleaned.|{I} clean{s/ed} {1}. ',
                        gActionListStr)
    
    dobjFor(CleanWith)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isCleanable) 
                illogical(cannotCleanMsg);
            
            else if(isClean)
                illogicalNow(alreadyCleanMsg);
        
            else if(!needsCleaning)
                implausible(noNeedToCleanMsg);
            
            else if(mustBeCleanedWith == nil)
                implausible(dontNeedCleaningObjMsg);
            
            else if(valToList(mustBeCleanedWith).indexOf(gVerifyIobj) == nil)
                implausible(cannotCleanWithMsg);
        }
        
        
        action() { makeCleaned(true); }
        
        report()
        {
            say(okayCleanMsg);
        }
    }
    
    /* 
     *   We assume most objects aren't suitable for cleaning other objects with.
     *   Since the dobj is resolved first canCleanWithMe could be a method that
     *   checks whether the proposed iobj is suitable for cleaning gDobj; but a
     *   better way of doing it might be to list suitable objects in the
     *   mustBeCleanedWith property.
     */      
    canCleanWithMe = nil
    
    iobjFor(CleanWith)
    {
        preCond = [objHeld]
        verify() 
        { 
            if(!canCleanWithMe)
               illogical(cannotCleanWithMsg); 
        }
    }
    
    cannotCleanWithMsg = BMsg(cannot clean with, '{I} {can\'t} clean {the dobj}
        with {the iobj}. ')
    
    /* Most things are not suitable for digging in*/
    isDiggable = nil
    
    dobjFor(Dig)
    {
        preCond = [touchObj]
        verify() 
        {
            if(!isDiggable)
               illogical(cannotDigMsg); 
        }
        
        /* 
         *   If digging is allowed, then most likely we need an implement like a
         *   spade to dig with, so our default action is to ask for one. This
         *   can be overridden on objects in which the actors can effectively
         *   dig with their bare hands.
         */
        action() { askForIobj(DigWith); }
    }
    
    /* Most objects aren't suitable digging instruments */
    canDigWithMe = nil
    
    /* 
     *   For DigWith we merely provide verify handlers that rule out the action
     *   wih the default values of isDiggable and canDigWithMe. The library
     *   cannot model the effect of digging in general, so it's up to game code
     *   to implement this on particular objects as required.
     */
    dobjFor(DigWith)
    {
        preCond = [touchObj]
        verify() 
        {
            if(!isDiggable)
               illogical(cannotDigMsg); 
        }
    }
        
    iobjFor(DigWith)
    {
        preCond = [objHeld]
        verify() 
        { 
            if(!canDigWithMe)
               illogical(cannotDigWithMsg); 
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotDigWithSelfMsg);
        }
    }
    
    cannotDigMsg = BMsg(cannot dig, '{I} {can\'t} dig there. ')
    cannotDigWithMsg = BMsg(cannot dig with, '{I} {can\'t} dig anything with
        {that iobj}. ')
    cannotDigWithSelfMsg = BMsg(cannot dig with self, '{I} {can\'t} dig {the
        dobj} with {itself dobj}. ')
    
    
    /* 
     *   We treat TAKE FROM as equivalent to TAKE except at the verify stage,
     *   where we first check that the direct object is actually in the indirect
     *   object.
     */
    dobjFor(TakeFrom) asDobjWithoutVerifyFor(Take)
    
    dobjFor(TakeFrom)
    {           
        verify()
        {
            if(!isTakeable)
                illogical(cannotTakeMsg);
            
            /* Test whether we are contained in any possible iobj. */
            local contained = nil;
            
            /* 
             *   If we already know what the indirect object is, test if we are in its contents
             *   (which may include one of its remapXXX subcontainers).
             */
            if(gIobj)
            {
                if(gIobj.notionalContents.indexOf(self))
                    contained = true;
            }
            /*  
             *   Otherwise, test if we are in any of the possible matches for the iobj of this
             *   command.
             */
            else  
            {                
                for(local obj in gTentativeIobj)
                {
                    if(obj.notionalContents.indexOf(self))
                    {
                        contained = true;
                        break;
                    }
                }
            }
            
            /* 
             *   If we're not in any possible iobj for this command, we can't be taken from any of
             *   them.
             */
            if(!contained)
                illogicalNow(notInMsg);
            
            /* 
             *   If we have a resolved iobj and it's the same as us (the dobj) or our tentative iobj
             *   list contains only us (the dobj) the player is trying to take us from ourselvdes,
             *   which we rule out as impossible.
             */
            if((gIobj == self)
               || (gTentativeIobj.length == 1 && self == gVerifyIobj))
                illogicalSelf(cannotTakeFromSelfMsg);
        }        
    }
    
    iobjFor(TakeFrom)
    {
        preCond = [touchObj]
        
        verify()       
        {          
            /*We're a poor choice of indirect object if there's nothing in us */
            if(notionalContents.countWhich({x: !x.isFixed}) == 0)
                logicalRank(70);
            
            /* 
             *   We're also a poor choice if none of the tentative direct
             *   objects is in our list of notional contents
             */
            if(gTentativeDobj.overlapsWith(notionalContents) == nil)
                logicalRank(80);        
        
        }      
    }
    
    notInMsg = BMsg(not inside, '{The dobj} {is}n\'t ' + 
                    (gIobj ? '{in iobj}.' : '{1}.'), gVerifyIobj.objInName)
    
    cannotTakeFromSelfMsg =  BMsg(cannot take from self, '{I} {can\'t} take
        {the subj dobj} from {himself dobj}. ')
    
    /* 
     *   Flag, can we supply more items from us that are currently in scope? By
     *   default we can't; but a DispensingCollective may be able to.
     */
    canSupply = nil
        
    dobjFor(ThrowAt)
    {
        preCond = [objHeld, objNotWorn]
        
        verify() { verifyDobjThrow(); }
        
        action()
        {
            /* 
             *   Normally the action handling for the ThrowAt action is dealt
             *   with on the indirect object - iobjFor(ThrowAt) - but if for
             *   particular objects you want to handle it on the direct object
             *   and you don't want the iobj handling as well, then you need to
             *   end your dobj action method with exitAction to suppress the
             *   iobj action method.
             */
        }
    }
    
    
    /* 
     *   Most objects can the target of a throw, but it's conceivable that some
     *   might be obviously unsuitable
     */
    canThrowAtMe = true
    
    iobjFor(ThrowAt)
    {
        preCond = [objVisible]
        
        verify()
        {
            if(!canThrowAtMe)
                illogical(cannotThrowAtMsg);
            
            if(gDobj == self)
                illogical(cannotThrowAtSelfMsg);
        }
        
        
        action()
        {            
            gDobj.actionMoveInto(getOutermostRoom.dropLocation);
        }
        
        report()
        {
            local obj = gActionListObj;
            gMessageParams(obj);
            DMsg(throw at, '{The subj obj} {strikes} {the iobj} and land{s/ed}
                on the ground. ');            
        }
        
    }
    
    /* 
     *   Particular instances will nearly always need to override with a less
     *   generic and more plausible refusal message.
     */
    cannotThrowAtMsg = BMsg(cannot throw at, '{I} {can\'t} throw anything at
        {the iobj}. ')
    
    cannotThrowAtSelfMsg = BMsg(cannot throw at self, '{The subj dobj} {can\'t}
        be thrown at {itself dobj}. ')
    
    dobjFor(ThrowTo)
    {
        preCond = [objHeld, objNotWorn]
        
        verify() { verifyDobjThrow(); }
    }
    
    /* 
     *   Most objects cannot have things thrown to then, since this would imply
     *   that they might be able to catch them, which only animate objects can
     *   do.
     */
    canThrowToMe = nil
    
    iobjFor(ThrowTo)
    {
        preCond = [objVisible]
        
        verify()
        {
            if(!canThrowToMe)
                illogical(cannotThrowToMsg);
            
            if(gVerifyDobj == self)
                illogical(cannotThrowToSelfMsg);
        } 
        
    }
    
    cannotThrowToMsg = BMsg(cannot throw to, '{The subj iobj} {can\'t} catch
        anything. ')
    
    cannotThrowToSelfMsg = BMsg(cannot throw to self, '{The subj dobj} {can\'t}
        be thrown to {itself dobj}. ')
    
    throwFallsShortMsg = BMsg(throw falls short, '{The subj dobj} land{s/ed} far
        short of {the iobj}. ')
    
    canTurnMeTo = nil
    
    
    /* 
     *   Turning something To is setting it to a value by rotating it, such as
     *   turning a dial to point to a particular number.
     */
    dobjFor(TurnTo)
    {
        preCond = [touchObj]
        
        verify() 
        {
            if(!canTurnMeTo)
               illogical(cannotTurnToMsg); 
        }   
        
        check()
        {
            checkSetting(gLiteral);
        }
        
        action()
        {
            makeSetting(gLiteral);                        
        }
        
        report()
        {
            DMsg(okay turn to, 'Okay, {I} turn{s/ed} {1} to {2}', gActionListStr, 
                 gLiteral);
        }
    }
    
    /* 
     *   If the setting is valid, do nothing. If it's invalid display a message
     *   explaining why. We do nothing here but this is overridden on the
     *   Settable class, which may be easier to use than providing your own
     *   implementation on Thing.
     */    
    checkSetting(val) { }
    
    /* The value we're currently set to. */
    curSetting = ''
    
    cannotTurnToMsg = BMsg(cannot turn to, '{I} {cannot} turn {that dobj} to
        anything. ')
    
    
    canSetMeTo = nil
    
    dobjFor(SetTo)
    {
        preCond = [touchObj]
        
        verify() 
        { 
            if(!canSetMeTo)
               illogical(cannotSetToMsg); 
        }
        
        check()
        {
            /* This would be a good place to put code to validate the setting */
            checkSetting(gLiteral);
        }
        
        action()
        {
            makeSetting(gLiteral);                       
        }
        
        report()
        {
            say(okaySetMsg);
        }
    }
       
    makeSetting(val) { curSetting = val; }
    
    okaySetMsg = BMsg(okay set to, '{I} {set} {1} to {2}. ', gActionListStr,
        curSetting)
    
    cannotSetToMsg = BMsg(cannot set to, '{I} {cannot} set {that dobj} to
        anything. ')
    
    
    /* 
     *   The GoTo action allows the player character to navigate the map through
     *   the use of commands such as GO TO LOUNGE.
     */
    dobjFor(GoTo)
    {
        verify()
        {
            /* 
             *   If the actor is already in the direct object, there's no need
             *   to move any further.
             */
            if(gActor.isIn(self))
                illogicalNow(alreadyThereMsg);
            
            /*  
             *   If the direct object is in the actor's location, there's no
             *   need for the actor to move to get to it.
             */
            if(isIn(gActor.getOutermostRoom))
                illogicalNow(alreadyPresentMsg);
            
            /*  
             *   It's legal to GO TO a decoration object, but given the choice,
             *   it's probably best to let the parser choose a non-decoration in
             *   cases of ambiguity, so we'll decorations a slightly lower
             *   logical rank.
             */
            if(isDecoration)
                logicalRank(90);
        }
        
        /* 
         *   The purpose of the GO TO action is to take the player char along
         *   the shortest route to the destination. The action routine
         *   calculates the route and takes the first step.
         */
        
        action()
        {
            /* Get our destination. */
            local dest = lastSeenAt ? lastSeenAt.getOutermostRoom : nil;
            
            /* 
             *   Calculate the route from the actor's current room to the location where the target
             *   object was last seen, using the pcRouteFinder to carry out the calculations if it
             *   is present.
             */
            local route = defined(pcRouteFinder) && lastSeenAt != nil 
                ? pcRouteFinder.findPath(
                    gActor.getOutermostRoom, dest) : nil;
            
            /*  
             *   If we don't find a route, just display a message saying we don't know how to get to
             *   our destination.
             */
            if(route == nil)
                sayDontKnowHowToGetThere();
            
            /*  
             *   If the route we find has only one element in its list, that means that we're where
             *   we last saw the target but it's no longer there, so we don't know where it's gone.
             *   In which case we display a message saying we don't know how to reach our target.
             */
            else if(route.length == 1)
                sayDontKnowHowToReach();
            
            /*  
             *   If the route we found has at least two elements, then use the first element of the
             *   second element as the direction in which we need to travel, and use the Continue
             *   action to take a step in that direction.
             */
            else
            {
                local idx = 2;
                local dir = route[2][1];
                local oldLoc = gPlayerChar.getOutermostRoom();
                
                local commonRegions =
                    gPlayerChar.getOutermostRoom.regionsInCommonWith(dest);
                
                local regionFastGoTo = 
                    commonRegions.indexWhich({r: r.fastGoTo }) != nil;
                
                local regionBriefGoTo = 
                    commonRegions.indexWhich({r: r.briefGoTo }) != nil;
                
                local fastGo = regionFastGoTo || regionBriefGoTo 
                    || gameMain.fastGoTo || gameMain.briefGoTo;
                local wasVerbose = gameMain.verbose;
                
                try
                {                   
                    
                    if(gameMain.briefGoTo || regionBriefGoTo)
                        gameMain.verbose = nil;
                    
                    Continue.takeStep(dir, getOutermostRoom, fastGo);                
                    
                    
                    /* 
                     *   If the fastGoTo option is active, continue moving towards the destination
                     *   until either we reach it our we're prevented from going any further.
                     */
                    while((fastGo)
                          && oldLoc != gPlayerChar.getOutermostRoom 
                          && idx < route.length)
                    {
                        local dir = route[++idx][1];
                        if(idx == route.length())
                            gameMain.verbose = wasVerbose;
                        
                        Continue.takeStep(dir, getOutermostRoom, true);
                    }    
                    
                    
                }
                finally
                {
                    gameMain.verbose = wasVerbose;
                    
                    if((gameMain.briefGoTo || regionBriefGoTo) && wasVerbose && !gActor.isIn(dest))
                        gActor.getOutermostRoom.lookAroundWithin();
                }
            }
        }
    }
    
    /* 
     *   We make these two sayDontKnowHowTo... methods separate methods so that
     *   they can be reused on the Distant class without having to repeat the
     *   DMsg() definitions.
     */
    sayDontKnowHowToGetThere() 
        { DMsg(route unknown, '{I} {don\'t know} how to get there. ');}
   
    sayDontKnowHowToReach()
        {  DMsg(destination unknown, '{I} {don\'t know} how to reach
            {him dobj}.' );}
    
    
    alreadyThereMsg = BMsg(already there, '{I}{\'m} already there. ')
    alreadyPresentMsg = BMsg(already present, '{The subj dobj} {is} right
        {here}. ')    
    
    /* 
     *   By default most things can't be attached to any things. The base
     *   handling of ATTACH and DETACH on Thing merely rules them out at the
     *   verify stage. The SimpleAttachable and NearbyAttachable classes define
     *   in the optional attachables.t module provide fuller handling.
     */
    isAttachable = nil
    
    dobjFor(Attach)
    {
        preCond = [touchObj]        
        verify() 
        {
            if(!isAttachable)
               illogical(cannotAttachMsg); 
        }
        action() { askForIobj(AttachTo); }
    }
    
    dobjFor(AttachTo)
    {
        preCond = [touchObj]        
        verify() 
        {
            if(!isAttachable)
               illogical(cannotAttachMsg); 
        }
    }
    
    canAttachToMe = nil
    
    iobjFor(AttachTo)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canAttachToMe)
               illogical(cannotAttachToMsg); 
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotAttachToSelfMsg);
        }
    }
    
    cannotAttachMsg = BMsg(cannot attach, '{I} {cannot} attach {the dobj} to
        anything. ')
    cannotAttachToMsg = BMsg(cannot attach to, '{I} {cannot} attach anything to
        {the iobj}. ')
    
    cannotAttachToSelfMsg = BMsg(cannot attach to self, '{I} {cannot} attach
        {the iobj} to {itself iobj}. ')
   
    
    isDetachable = nil
    
    dobjFor(Detach)
    {
        preCond = [touchObj]
        verify() 
        {
            if(!isDetachable)
               illogical(cannotDetachMsg); 
        }            
    }
    
    cannotDetachMsg = BMsg(cannot detach, 'There{dummy} {is}n\'t anything from
        which {the subj dobj} could be detached. ')
    
    
    dobjFor(DetachFrom)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isDetachable)
               illogical(cannotDetachMsg); 
            
            if(gVerifyIobj == self)
                illogicalSelf(cannotDetachFromSelfMsg);
        }
    }

    canDetachFromMe = nil
    
    iobjFor(DetachFrom)
    {
        verify()
        {
            if(!canDetachFromMe)
                illogical(cannotDetachFromMsg);
        }
    }
    
    cannotDetachFromMsg = BMsg(cannot detach from, 'There{dummy} {is}n\'t
        anything that could be detached from {the iobj}. ')
    
    cannotDetachFromSelfMsg = BMsg(cannot detach from self, '{The subj dobj}
        {can\'t} be detached from {itself dobj}. ')
    
    
    /* 
     *   Fasten by itself presumably refers to objects like seat-belts. There
     *   are not many such fastenable objects so we may things not fastenable by
     *   default.
     */    
    isFastenable = nil
    
    /*   Most things start out unfastened. */
    isFastened = nil
    
    /*  
     *   Make something fastened or unfastened. By default we just change the
     *   value of its isFastened property, but game code could override this to
     *   provide further side-effects on particular objects.
     */
    makeFastened(stat) { isFastened = stat; }
    
    dobjFor(Fasten)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isFastenable)
                illogical(cannotFastenMsg); 
            
            if(isFastened)
                illogicalNow(alreadyFastenedMsg);
        }
        
        action() { makeFastened(true); }
        
        report()
        {
            DMsg(okay fasten, 'Done|{I} fasten{s/ed} {1}. ', gActionListStr);
        }
    }
    
    cannotFastenMsg = BMsg(cannot fasten, '{That subj dobj}{\'s} not something
        {i} {can} fasten. ')
    
    alreadyFastenedMsg = BMsg(already fastened, '{The subj dobj} {is} already
        fastened. ')

        
    
    dobjFor(FastenTo)
    {
        preCond = [objHeld]
        verify() 
        {
            if(!isFastenable)
               illogical(cannotFastenMsg); 
        }
    }
    
    canFastenToMe = nil
    
    iobjFor(FastenTo)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canFastenToMe)
                illogical(cannotFastenToMsg); 
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotFastenToSelfMsg);
        }  
    }
    
    cannotFastenToMsg = BMsg(cannot fasten to, '{I} {can\'t} fasten anything to
        {that iobj}. ')
    
    cannotFastenToSelfMsg = BMsg(cannot fasten to self, '{The subj iobj}
        {can\'t} be fastened to {itself iobj}. ')
                                
    isUnfastenable = nil
    
    dobjFor(Unfasten)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isUnfastenable)
               illogical(cannotUnfastenMsg); 
            
            if(!isFastened)
                illogicalNow(notFastenedMsg);
        }
    }
    
    
    
    
    dobjFor(UnfastenFrom)
    {
        preCond = [touchObj]
        verify() 
        {
            if(!isUnfastenable)
               illogical(cannotUnfastenMsg); 
            
            if(gVerifyIobj == self)
                illogical(cannotUnfastenFromSelfMsg);
        }
    }
    
    canUnfastenFromMe = nil
    
    iobjFor(UnfastenFrom)
    {
        preCond = [touchObj]
        verify()             
        {
            if(!canUnfastenFromMe)
               illogical(cannotUnfastenFromMsg); 
        }
    }
    
    cannotUnfastenMsg = BMsg(cannot unfasten, '{The subj dobj} {cannot} be
        unfastened. ')
    
    cannotUnfastenFromMsg = BMsg(cannot unfasten from, '{I} {can\'t} unfasten
        anything from {that iobj}. ')
    
    cannotUnfastenFromSelfMsg = BMsg(cannot unfasten from self, '{I} {can\'t}
        unfasten {the dobj} from {itself dobj}. ')

    notFastenedMsg = BMsg(not fastened, '{The subj dobj} {isn\'t} fastened. ')
    
    /* 
     *   Most things can't be plugged into other things or have other things
     *   plugged into them.
     */
    isPlugable = nil
    canPlugIntoMe = nil
    
                          
    /* 
     *   The base handling of PlugInto on Thing merely rules it out at the
     *   verify stage. A fuller implementation is provided by the PlugAttachable
     *   class in the optional attachables module.
     */                      
    dobjFor(PlugInto)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isPlugable)
                illogical(cannotPlugMsg);
            
            if(self == gVerifyIobj)
                illogicalSelf(cannotPlugIntoSelfMsg);            
        }        
        
    }
    
    iobjFor(PlugInto)
    {
        preCond = [touchObj]
        verify()
        {          
            if(!canPlugIntoMe)
                illogical(cannotPlugIntoMsg);
        }
    }
    
    
    cannotPlugMsg = BMsg(cannot plug, '{The subj dobj} {can\'t} be plugged into
        anything. ')
    cannotPlugIntoSelfMsg = BMsg(cannot plug into self, '{I} {can\'t} plug
        {the dobj} into {itself dobj}. ')
    cannotPlugIntoMsg = BMsg(cannot plug into, '{I} {can\'t} plug anything into
        {the iobj}. ')
    
    isUnplugable = (isPlugable)
    canUnplugFromMe = (canPlugIntoMe)
    
    dobjFor(UnplugFrom)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isUnplugable)
                illogical(cannotUnplugMsg);
            
            if(gVerifyIobj == self)
                illogicalSelf(cannotUnplugFromSelfMsg);
        }
    }
    
    iobjFor(UnplugFrom)
    {
        preCond = []
        
        verify()
        {
            if(!canUnplugFromMe)
                illogical(cannotUnplugFromMsg);
            
           
        }
    }
    
    cannotUnplugMsg = BMsg(cannot unplug, '{The subj dobj} {can\'t} be
        unplugged. ')
    
    cannotUnplugFromSelfMsg = BMsg(cannot unplug from self, '{I} {can\'t} unplug
        {the dobj} from {itself dobj}. ')
    
    cannotUnplugFromMsg = BMsg(cannot unplug from, '{I} {can\'t} unplug anything
        from {the iobj}. ')
    
    dobjFor(PlugIn)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isPlugable)
                illogical(cannotPlugMsg);
        }
    }
    
    dobjFor(Unplug)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isUnplugable)
                illogical(cannotUnplugMsg);
        }
    }
    
    /* We can try kissing most things, even if it isn't very rewarding */
    isKissable = true
    
    /* 
     *   The logical rank assigned to kissing this object if kissing is allowed.
     *   Kissing an inanimate object is less likely than kissing an Actor.
     */
    kissRank = 80
    
    dobjFor(Kiss)
    {
        preCond = [touchObj]
        
        
        verify() 
        { 
            if(!isKissable)
                illogical(cannotKissMsg);
             
            /* 
             *   It's more logical to kiss actors, so we give the Kiss action a
             *   lower logical rank on ordinary things.
             */
            logicalRank(kissRank); 
        }
        
        check()
        {
            if(dataType(&checkKissMsg) != TypeNil)
                display(&checkKissMsg);
        }
        
        action()
        {
            if(dataType(&futileToKissMsg) != TypeNil)
                display(&futileToKissMsg);
        }
        
        
        report()
        {
            DMsg(report kiss, 'Kissing {1} {dummy}prove{s/d} remarkably
                unrewarding. ',  gActionListStr); 
        }
    }
    
    futileToKissMsg = nil
    
    cannotKissMsg = BMsg(cannot kiss, '{I} really {can\'t} kiss {that dobj}. ')

    /* 
     *   If we want Kissing to fail at the check stage we can supply a message
     *   here explaining why. This is most simply given as a single-quoted
     *   string, but a double-quoted string or method will also work.
     */
    checkKissMsg = nil
    
    /* 
     *   Flag, if this is a nested room, should an actor get out of it before
     *   executing an intransitive Jump command. By default it should.
     */
    getOutToJump = true
    
    /* 
     *   It should be possible to jump off something if and only if the actor is
     *   on it in the first place.
     */
    canJumpOffMe = (gActor.location == self && contType == On)
    
    dobjFor(JumpOff)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!canJumpOffMe)
                illogical(cannotJumpOffMsg);
        }
        
        action()
        {
            /* 
             *   Jumping off something has much the same effect as getting off
             *   it, i.e. moving the actor to our exitLocation.
             */
            gActor.actionMoveInto(exitLocation);
        }
        
        report()
        {
            DMsg(jump off, '{I} jump{s/ed} off {1} and land{s/ed} on the ground', 
                 gActionListStr);
        }
    }
    
    cannotJumpOffMsg = BMsg(cannot jump off, '{I}{\'m} not on {the dobj}. ')
    
    /* It usually isn't possible (or at least useful) to jump over things. */
    canJumpOverMe = nil
    
    /* 
     *   The base handling of JumpOver is simply to rule it out at the verify
     *   stage.
     */
    dobjFor(JumpOver)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!canJumpOverMe)
               illogical(cannotJumpOverMsg); 
            if(gDobj == gActor)
                illogicalSelf(cannotJumpOverSelfMsg);
        }
    }
    
    cannotJumpOverMsg = BMsg(pointless to jump over, 'It {dummy}{is}
        pointless to try to jump over {the dobj}. ')
    
    cannotJumpOverSelfMsg = BMsg(cannot jump over self, '{I} {can} hardly jump over {myself}. '  )
    
    
    /* Most things aren't settable. */
    isSettable = nil
    
    /* 
     *   The Set command by itself doesn't do much. By default we just rule it
     *   out at the verify stage.
     */
    dobjFor(Set)
    {
        preCond = [touchObj]
        verify() 
        {
            if(!isSettable)
               illogical(cannotSetMsg); 
        }
    }
    
    cannotSetMsg = BMsg(cannot set, '{The subj dobj} {is} not something {i}
        {can} set. ')
    
    /* Most things can't be typed on. */
    canTypeOnMe = nil
    
    /* 
     *   The base handling of both the vague (TYPE ON X) and specific (TYPE FOO
     *   ON X) forms of TypeOn is simply to rule them out at the verify stage.
     *   Game code that needs objects that can be typed on is responsible for
     *   handling these actions in custom code.
     */
    dobjFor(TypeOn)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canTypeOnMe)
               illogical(cannotTypeOnMsg);  
        }
    }
    
    dobjFor(TypeOnVague)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canTypeOnMe)
               illogical(cannotTypeOnMsg); 
        }        
        
        action() { askMissingLiteral(TypeOn, DirectObject); }
    }
    
    cannotTypeOnMsg = BMsg(cannot type on, '{I} {can\'t} type anything on {the
        dobj}. ')
    
    
    /* 
     *   Entering something on means ENTER FOO ON BAR where FOO is a string
     *   literal and BAR is an object such as a computer terminal. Most objects
     *   can't be entered on in this sense.
     */
    canEnterOnMe = nil
    
    
    /*   
     *   The base handling is simply to rule out EnterOn at verify. There's no
     *   further handling the library can provide for a 'general' case so it's
     *   up to game code to define it for specific cases.
     */
    dobjFor(EnterOn)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canEnterOnMe)
               illogical(cannotEnterOnMsg); 
        }
    }
    
    cannotEnterOnMsg = BMsg(cannot enter on, '{I} {can\'t} enter anything on
        {the dobj}. ')
    
    
    /*  Most things can't be written on. */
    canWriteOnMe = nil
    
    /*  By default we simply rule out writing on things at the verify stage. */
    dobjFor(WriteOn)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canWriteOnMe)
               illogical(cannotWriteOnMsg); 
        }        
        
    }
    
    cannotWriteOnMsg = BMsg(cannot write on, '{I} {can\'t} write anything on
        {the dobj}. ')
    
    /* Most things aren't consultable */
    isConsultable = nil
    
    /* 
     *   The base handling on Thing merely rules out the Consult action at the
     *   verify stage. For a fuller implementation that allows consulting use
     *   the Consultable class.
     */
    dobjFor(ConsultAbout)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isConsultable)
               illogical(cannotConsultMsg); 
        }
        
    }
    
    cannotConsultMsg = BMsg(cannot consult, '{The subj dobj} {is} not a
        provider of information. ')
    
    /* 
     *   Most things aren't pourable (they can't be poured into or onto other
     *   things.
     */
    isPourable = nil
    
    
    /* 
     *   Sometimes we may have a container, such as an oilcan, from which we
     *   want to pour a liquid, such as oil, and we're using the same object to
     *   do duty for both. We can then use the fluidName property to say 'the
     *   oil' rather than 'the oilcan' in messages that refer specifically to
     *   pouring the liquid.
     */
    fluidName = theName
    
    /*  
     *   The base handling of Pour, PourOnto and PourInto is simply to rule out
     *   all three actions at the verify stage. Game code that wants to allow
     *   these actions on specific objects will need to provide further handling
     *   for them.
     */
    dobjFor(Pour)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isPourable)
               illogical(cannotPourMsg); 
        }
    }
    
    dobjFor(PourOnto)
    {
        preCond = [touchObj]
        
        verify()
        { 
            if(!isPourable)
               illogical(cannotPourMsg); 
        }
    }
    
    /* 
     *   Most things can probably have something poured onto them in principle,
     *   though we might want to prevent it in practice. The canPourOntoMe
     *   property controls whether it's possible to pour onto this thing.
     */
      
    canPourOntoMe = true
    
    /* 
     *   The allowPourOntoMe property controls whether we want allow anything to
     *   be poured onto this thing (even if it's possible). By default we don't.
     */
    allowPourOntoMe = nil
    
    
    
    iobjFor(PourOnto)
    {
        preCond = [touchObj]
        
        remap = (remapOn)
        
        verify()
        {
            if(gVerifyDobj == self)
                illogicalSelf(cannotPourOntoSelfMsg);
            
            if(!canPourOntoMe)
                illogical(cannotPourOntoMsg);
            else if(!allowPourOntoMe)
                implausible(shouldNotPourOntoMsg);
           
        }    
    }
    
    
    
    
    dobjFor(PourInto)
    {
        preCond = [touchObj]
        verify()
        { 
            if(!isPourable)
               illogical(cannotPourMsg); 
        }
    }
    
    /* 
     *   Presumably it's possible by default to pour something into me if I'm a
     *   container; but this could be overridden simply to true for objects like
     *   the sea or a river.
     */
    canPourIntoMe = (contType == In || remapIn != nil)
    
    
    /*        
     *   While it's possible to pour stuff into any container, we probably don't
     *   want to allow it on most of them
     */
    allowPourIntoMe = nil
    
    iobjFor(PourInto)
    {
        preCond = [touchObj]
        
        remap = (remapIn) 
        
        verify()
        {
            if(gVerifyDobj == self)
                illogicalSelf(cannotPourIntoSelfMsg);
            
            if(!canPourIntoMe)
                illogical(cannotPourIntoMsg);
            else if(!allowPourIntoMe)
                implausible(shouldNotPourIntoMsg);
        }
    }
    
    cannotPourMsg = BMsg(cannot pour, '{I} {can\'t} pour {1} anywhere. ',
                         fluidName)
    cannotPourOntoSelfMsg = BMsg(cannot pour on self, '{I} {can\'t} pour {the
        dobj} onto {itself dobj}. ')
    cannotPourIntoSelfMsg = BMsg(cannot pour in self, '{I} {can\'t} pour {the
        dobj} into {itself dobj}. ')
    cannotPourIntoMsg = BMsg(cannot pour into, '{I} {can\'t} pour {1}
        into {that dobj}. ', gDobj.fluidName)
    cannotPourOntoMsg = BMsg(cannot pour onto, '{I} {can\'t} pour {1}
        into {that dobj}. ', gDobj.fluidName)
    shouldNotPourIntoMsg = BMsg(should not pour into, 'It{dummy}{\'s} better not
        to pour {1} into {the iobj}. ', gDobj.fluidName)
    
    shouldNotPourOntoMsg = BMsg(should not pour onto, 'It{dummy}{\'s} better not
        to pour {1} onto {the iobj}. ', gDobj.fluidName)  
    
    
    /* Most things can't be screwed */
    isScrewable = nil
    
    /* Most things can't be used to screw other things with. */
    canScrewWithMe = nil
    
    /* 
     *   In the base handling we simply rule out Screw and Unscrew actions at
     *   the verify stage. It's up to game code to provide specific handling for
     *   objects that can be screwed and unscrewed.
     */
    dobjFor(Screw)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isScrewable)
               illogical(cannotScrewMsg); 
        }        
    }
    
    dobjFor(ScrewWith)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isScrewable)
               illogical(cannotScrewMsg); 
        }       
    }
    
    iobjFor(ScrewWith)
    {
        preCond = [objHeld]
        verify() 
        { 
            if(!canScrewWithMe)
                illogical(cannotScrewWithMsg); 
            
            if(gVerifyDobj == self)
                illogical(cannotScrewWithSelfMsg);
        }        
    }
    
    isUnscrewable = (isScrewable)
    canUnscrewWithMe = (canScrewWithMe)
    
    dobjFor(Unscrew)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isUnscrewable)
               illogical(cannotUnscrewMsg); 
        }        
    }
    
    dobjFor(UnscrewWith)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!isUnscrewable)
               illogical(cannotUnscrewMsg); 
        }      
    }
    
    iobjFor(UnscrewWith)
    {
        preCond = [objHeld]
        verify() 
        { 
            if(!canUnscrewWithMe)
                illogical(cannotUnscrewWithMsg); 
            
            if(gVerifyDobj == self)
                illogicalSelf(cannotUnscrewWithSelfMsg);
        }        
    }
    
    cannotScrewMsg = BMsg(cannot screw, '{I} {can\'t} screw {the dobj}. ')
    cannotScrewWithMsg = BMsg(cannot screw with, '{I} {can\'t} screw anything
        with {that iobj}. ') 
    cannotScrewWithSelfMsg = BMsg(cannot screw with self, '{I} {can\'t} screw
        {the iobj} with {itself iobj}. ')
    cannotUnscrewMsg = BMsg(cannot unscrew, '{I} {can\'t} unscrew {the dobj}. ')
    cannotUnscrewWithMsg = BMsg(cannot unscrew with, '{I} {can\'t} unscrew
        anything with {that iobj}. ')
    cannotUnscrewWithSelfMsg = BMsg(cannot unscrew with self, '{I} {can\'t}
        unscrew {the iobj} with {itself iobj}. ')
    
    
    /* 
     *   Common handler for verifying push travel actions. The via parameter may
     *   be a preposition object (such as Through) defining what kind of push
     *   traveling the actor is trying to do (e.g. through a door or up some
     *   stairs).
     */
    verifyPushTravel(via)
    {
        viaMode = via;
        
        if(!canPushTravel && !canPullTravel)
            illogical(cannotPushTravelMsg);
        
        if(matchPushOnly && !canPushTravel)
            implausible(cannotPushTravelMsg);
        
        if(matchPullOnly && !canPullTravel)
            implausible(cannotPushTravelMsg);       
        
        
        if(gActor.isIn(self))
            illogicalNow(cannotPushOwnContainerMsg);
        
        if(gVerifyIobj == self)
            illogicalSelf(cannotPushViaSelfMsg);            
        
    }
    
    /* 
     *   Check if the player specifically asked to PUSH this object somewhere.
     *   In the main library we assume not, but language-specific code will need
     *   to override to check what that player's command actually said.
     */
    matchPushOnly = nil
    
    
    /* 
     *   Check if the player specifically asked to PULL this object somewhere.
     *   In the main library we assume not, but language-specific code will need
     *   to override to check what that player's command actually said.
     */
    matchPullOnly = nil
    
       
    viaMode = ''
    
    cannotPushOwnContainerMsg = BMsg(cannot push own container, '{I} {can\'t}
        {1} {the dobj} anywhere while {he actor}{\'s} {2} {him dobj}. ',
                                     gVerbWord, gDobj.objInPrep)
    
    cannotPushViaSelfMsg = BMsg(cannot push via self, '{I} {can\'t} {1} {the
        dobj} {2} {itself dobj}. ', gVerbWord, viaMode.prep)
    
    /* 
     *   By default we can't push travel most things. Push Travel means pushing
     *   an object from one place to another and traveling with it.
     */
    canPushTravel = nil
    
    /*  
     *   Normally we don't distinguish PushTravel from PullTravel, but if we
     *   want something to be pushable between rooms but not pullable, or vice
     *   versa, we can set these to different values.
     */
    canPullTravel = canPushTravel
    
    /* 
     *   PushTravelDir handles pushing an object in a particular direction, e.g.
     *   PUSH BOX NORTH
     */
    dobjFor(PushTravelDir)
    {
        preCond = [touchObj, travelPermitted]
        
        check()
        {
            /* set up a local variable to hold the connector we want to travel through. */
            local conn;
            
            /* note which room we're in */
            local loc = getOutermostRoom;
            
            /* Get the direction of travel from the command */
            local dirn = gCommand.verbProd.dirMatch.dir;
            
            if(loc.propType(dirn.dirProp) == TypeObject)
            {
                /* Note the connector object in the relevant direction */
                conn = loc.(dirn.dirProp);
                
                /* 
                 *   If our connector is an UnlistedProxyConnector we need to replace the direction
                 *   we're heading in with the one the UPC points to and our connector with the one
                 *   our new direction points to.
                 */
                if(conn.ofKind(UnlistedProxyConnector))
                {
                    /* get our real direction of travel. */
                    dirn = conn.direction; 
                    
                    /* get the connector in that direction, or nil if it's not an object */
                    conn = loc.propType(dirn.dirProp) == TypeObject ? loc.(dirn.dirProp) : nil;
                    
                }                                 
                
                /* If the connector we want to use is an object then check its travel barriers. */
                if(dataType(conn) == TypeObject)
                {                    
                    if(!conn.setTravelPosture())
                        exit;
                    
                    if(conn.checkTravelBarriers(self))
                        conn.checkTravelBarriers(gActor);
                    
                    
                }
            }
            
            
        }
    }
    
    /* Display a message saying we pushed the direct object in a particular direction. */
    sayPushTravel(dir)
    {
        DMsg(before push travel dir, '{I} <<gDobj.matchPullOnly ? 'pull(s/ed}' : 'push{es/ed}'>>
              {the dobj} {1}. ',  dir.departureName);   
        "<.p>";
    }    
    
     
    pushTravelRevealItems()
    {
        /* 
         *   Check whether moving this object revealed any items hidden behind
         *   or beneath it (even if we don't succeed in pushing the object to
         *   another room we can presumably move it far enough across its
         *   current one to reveal any items it was concealing.
         */
        revealOnMove();
        
        /* 
         *   If moving this item did reveal any hidden items, we want to see the
         *   report of them now, before moving to another location.
         */        
        gCommand.afterReport();
        
        /* 
         *   We don't want to see these reports again at the end of the action,
         *   so clear the list.
         */
        gCommand.afterReports = [];   
    }
    
    
    /* Display a message explaining that push travel is not possible */   
    cannotPushTravelMsg()
    {
        if(isFixed)
            return cannotTakeMsg;
        return BMsg(cannot push travel, 'There{dummy}{\'s} no point trying to
            {1} {that dobj} anywhere. ', gVerbWord);
    }

    
    /* Check the travel barriers on the indirect object of the action */
    checkPushTravel()
    {
        /* 
         *   First check the travel barriers for the actor doing the pushing.
         *   Only go on to check those for the item being pushed if the actor
         *   can travel, so we don't see the same messages twice.
         */
        if(checkTravelBarriers(gActor))        
            checkTravelBarriers(gDobj);     
        
              
    }
    
    /*  Carry out the push travel on the direct object of the action. */
    doPushTravel(via)
    {
        /* 
         *   Check whether moving this object revealed any items hidden behind
         *   or beneath it (even if we don't succeed in pushing the object to
         *   another room we can presumably move it far enough across its
         *   current one to reveal any items it was concealing.
         */
        pushTravelRevealItems();       
                 
        if(!gIobj.isLocked)
            describePushTravel(via); 
        
        /*  
         *   We temporarily make the push traveler item hidden before moving it
         *   to the new location so that it doesn't show up listed in its former
         *   location when actor moves to the new location and there's a sight
         *   path between the two.
         */
        local wasHidden;
        
        /*   Note the actor's current location. */
        local oldLoc = gActor.getOutermostRoom;
        try
        {
            wasHidden = propType(&isHidden) is in (TypeCode, TypeFuncPtr) ?
                    getMethod(&isHidden) : isHidden;
            
            isHidden = true;
            
            gIobj.travelVia(gActor);
        }
        finally
        {
            if(dataTypeXlat(wasHidden) is in (TypeCode, TypeFuncPtr))
                setMethod(&isHidden, wasHidden);
            else
                isHidden = wasHidden;
        }
              
        
        /*   
         *   Use the travelVia() method of the iobj to move the dobj to its new
         *   location.
         */        
        
        if(gActor.isIn(gIobj.getDestination(oldLoc)))
        {
            gIobj.travelVia(gDobj);
            gDobj.describeMovePushable(self, gActor.location);
        }
    }
    
    
    beforeMovePushable(connector, dir)
    {
        /* make a note of our connector */
        local conn = connector;
         
        /* 
         *   If our connector is an UnlistedProxyConnector we need some special handling to identify
         *   the real connector we're going to use.
         */
        if(connector.ofKind(UnlistedProxyConnector))
        {
            /* Note the room we're in. */
            local loc = getOutermostRoom;
            
                    
            /* Get the direction prop our UnlistedProxyConnector is a proxy for. */
            local prop = connector.direction.dirProp;
            
            if(loc.propType(prop) == TypeObject)  
            {
                
                /* Get the connector that direction property points to. */
                conn = loc.(prop);                
                
                /* Make that connector the iobj of this action. */
                gIobj = conn; 
            }
            else
            {
                /*  Otherwise note the direction we're actually going to try to go in. */
                dir = connector.direction;
                
                /* If the connector isn't an object, we don't want to deal with it here. */
                conn = nil;
            }
        }
            
        /* 
         *   Next check that there's nothing that wants to disallow this travel.. If the
         *   travelPermitted preCond is present for this action on this object this should already
         *   have been done, but if game code has overridden that we need to carry out the
         *   beforeTravelNotifications now.
         */         
        if(conn && dataType(conn == TypeObject))
            conn.beforeTravelNotifications(self);        
        
       /*  If we have an indirect object, describe our PushTravel via it */
        if(gIobj)
            describePushTravel(gAction.viaMode);    
        
        /*  
         *   Otherwise we have a travel connector to travel through, report which direction we're
         *   pushing to.
         */
        else if(objOfKind(conn, TravelConnector))
            sayPushTravel(dir);
        
        /*  
         *   Otherwise do nothing, because our 'connector' must be a string or method that explains
         *   why travel that way isn't possible.
         */
    }
    
    describeMovePushable (connector, dest)
    {
        local obj = self;
        gMessageParams(obj, dest);
        DMsg(describe move pushable, '{The subj obj} {comes} to a halt. ' );
        
    }
    
    /* 
     *   This message, called on the direct object of a PushTravel command (i.e.
     *   the object being pushed) is displayed just before travel takes place.
     *   It is used when the PushTravel command also involves an indirect
     *   object, e.g. a Passage, Door or Stairway the direct object is being
     *   pushed through, up or down. The via parameter is the preposition
     *   relevant to the kind of pushing, e.g. Into, Through or Up.
     */
    describePushTravel(via)
    {
        /* If I have a traversalMsg, use it */
        if(gIobj && gIobj.propType(&traversalMsg) != TypeNil)
            DMsg(push travel traversal, '{I} <<if matchPullOnly>> pull{s/ed}
                <<else>> push{es/ed}<<end>> {the dobj} {1}. <.p>',
                 gIobj.traversalMsg);
        else
            DMsg(push travel somewhere, '{I} <<if matchPullOnly>> pull{s/ed}
                <<else>> push{es/ed}<<end>> {the dobj} {1} {the iobj}. <.p>', 
                 via.prep); 
        
        "<.p>";
    }
    
   
    
    /* 
     *   PushTravelThrough handles pushing something through something, such as a door or archway.
     *   Most of the actual handling is dealt with by the common routines defined above.
     */
    dobjFor(PushTravelThrough)    
    {
        preCond = [touchObj]
        verify()   {   verifyPushTravel(Through);   }
        
        action() { doPushTravel(Through); }
    }
    
    iobjFor(PushTravelThrough)
    {
        preCond = [travelPermitted, touchObj]
        verify() 
        {  
            if(!canGoThroughMe || getDestination(gActor.getOutermostRoom) == nil)
                illogical(cannotPushThroughMsg);
        }
        
        check() { checkPushTravel(); }       
    }
    
    cannotPushThroughMsg = BMsg(cannot push through, '{I} {can\'t} {1}
        anything through {the iobj}. ', gVerbWord)
    
    
    /* 
     *   PushTravelEnter handles commands like PUSH BOX INTO COFFIN, where the
     *   indirect object is a Booth-like object. The syntactically identical
     *   command for pushing things into an Enterable (e.g. PUSH BOX INTO HOUSE
     *   where HOUSE represents the outside of a separate location) is handled
     *   on the Enterable class.
     */         
    dobjFor(PushTravelEnter)
    {
        preCond = [touchObj]
        verify()  {  verifyPushTravel(Into);  }        
        
    }
    
    okayPushIntoMsg = BMsg(okay push into, '{I} <<if matchPullOnly>> pull{s/ed}
                <<else>> push{es/ed}<<end>> {the dobj} into {the iobj}. ')
    
    iobjFor(PushTravelEnter)
    {
        preCond = [containerOpen]
        verify() 
        {  
            if(!isEnterable)
                illogical(cannotPushIntoMsg);
        }
        
        check() 
        {             
            checkInsert(gActor);            
            checkInsert(gDobj);
        }    
        
        action() 
        {
            gDobj.actionMoveInto(self);
            gActor.actionMoveInto(self);
            
            if(gDobj.isIn(self))
                say(okayPushIntoMsg);
        }
    }
    
    cannotPushIntoMsg = BMsg(cannot push into, '{I} {can\'t} {1}
        anything into {the iobj}. ', gVerbWord)
    
    dobjFor(PushTravelGetOutOf)
    {
        preCond = [touchObj]
        verify()
        {
            verifyPushTravel(OutOf);
            if(!self.isIn(gIobj))
                illogicalNow(notInMsg);
        }
        
        
        
    }
    
    iobjFor(PushTravelGetOutOf)
    {
        preCond = [touchObj]
        
        verify() 
        {  
            if(!gActor.isIn(self))
                illogicalNow(actorNotInMsg);   
            
        }
        
        action()
        {
            gDobj.actionMoveInto(location);
            if(gDobj.location ==  location)
            {
                say(okayPushOutOfMsg);
                gActor.actionMoveInto(location);
            }
        }
       
    }
    
    okayPushOutOfMsg = BMsg(okay push out of, '{I} <<if matchPullOnly>> pull{s/ed}
                <<else>> push{es/ed}<<end>> {the dobj} {outof iobj}. ')
    
    dobjFor(PushTravelClimbUp)
    {
        preCond = [touchObj]
        verify()  {  verifyPushTravel(Up);  }
        
        action() { doPushTravel(Up); }
    }
    
    iobjFor(PushTravelClimbUp)
    {
        preCond = [travelPermitted, touchObj]
        
        verify() 
        {  
            if(!isClimbable || getDestination(gActor.getOutermostRoom) == nil)
                illogical(cannotPushUpMsg);
        }
        
        check() { checkPushTravel(); }
    }
    
    cannotPushUpMsg = BMsg(cannot push up, '{I} {can\'t} {1}
        anything up {the iobj}. ', gVerbWord)
    
    dobjFor(PushTravelClimbDown)
    {
        preCond = [touchObj]
        verify()  { verifyPushTravel(Down);  }
        
        action() { doPushTravel(Down); }
    }
    
    iobjFor(PushTravelClimbDown)
    {
        preCond = [travelPermitted, touchObj]
        
        verify() 
        {  
            if(!canClimbDownMe || getDestination(gActor.getOutermostRoom) == nil)
                illogical(cannotPushDownMsg);
        }
        
        check() { checkPushTravel(); }
    }
    
    cannotPushDownMsg = BMsg(cannot push down, '{I} {can\'t} {1}
        anything down {the iobj}. ', gVerbWord)
    
    /* 
     *   We don't bother to define isAskable etc. properties since we assume
     *   that no inanimate object can be conversed with, and that game code will
     *   use the Actor class to allow conversation. In any case since there's
     *   never any difficult in talking about oneself, the various illogicalSelf
     *   checks aren't needed.
     *
     *   Indeed, the handling of conversational commands on Thing is minimal;
     *   they are simply ruled out at the verify stage, since most Things can't
     *   converse. The implementation of these actions that allows conversation
     *   to take place is on the Actor class. We do however define a canTalkToMe
     *   property so that Actor can use the verify handling defined on Thing by
     *   just overriding it.
     *
     *   Things can't be talked to, so game code shouldn't normally override
     *   this property; it's there to be overridden on the Actor class.
     */
    canTalkToMe = nil
    
    
    dobjFor(AskAbout)
    {
        preCond = [canTalkToObj]
        verify() 
        { 
            if(gActor == self)
                illogicalSelf(cannotTalkToSelfMsg);
            
            else if(!canTalkToMe)
              illogical(cannotTalkToMsg); 
        }
    }
    
    dobjFor(AskFor)
    {
        preCond = [canTalkToObj]
        verify() 
        { 
            if(gActor == self)
                illogicalSelf(cannotTalkToSelfMsg);
            
            else if(!canTalkToMe)
              illogical(cannotTalkToMsg); 
        }
    }
    
    
    dobjFor(TellAbout)
    {
        preCond = [canTalkToObj]
        verify() 
        { 
            if(gActor == self)
                illogicalSelf(cannotTalkToSelfMsg);
            
            else if(!canTalkToMe)
              illogical(cannotTalkToMsg); 
        }
    }
    
        
    dobjFor(SayTo)
    {
        preCond = [canTalkToObj]
        verify() 
        { 
            if(gActor == self)
                illogicalSelf(cannotTalkToSelfMsg);
            
            else if(!canTalkToMe)
              illogical(cannotTalkToMsg); 
        }
    }
    
    /* 
     *   Do we allow an implicit say command to be directed to this object? Normally we don't. Thuis
     *   property is only really meaningful on the Actor class but we define it here because it's
     *   needed by parser.t.
     */
    allowImplicitSay = nil
    
    dobjFor(QueryAbout)
    {
        preCond = [canTalkToObj]
        verify() 
        { 
            if(gActor == self)
                illogicalSelf(cannotTalkToSelfMsg);
            
            else if(!canTalkToMe)
              illogical(cannotTalkToMsg); 
        }
    }
    
    dobjFor(TalkAbout)
    {
        preCond = [canTalkToObj]
        verify() 
        { 
            if(gActor == self)
                illogicalSelf(cannotTalkToSelfMsg);
            
            else if(!canTalkToMe)
              illogical(cannotTalkToMsg); 
        }
    }
    
    dobjFor(TalkTo)
    {
        preCond = [canTalkToObj]
        verify() 
        { 
            if(gActor == self)
                illogicalSelf(cannotTalkToSelfMsg);
            
            else if(!canTalkToMe)
              illogical(cannotTalkToMsg); 
        }
    }
    
    cannotTalkToMsg = BMsg(cannot talk, 'There{dummy}{\'s} no point trying to
        talk to {the cobj}. ')
    
    cannotTalkToSelfMsg = BMsg(cannot talk to self, 'Talking to oneself {dummy}
        {is} generally pointless. ')
        
    
    dobjFor(GiveTo)
    {
        preCond = [objHeld, objNotWorn]
        verify()
        {
            if(isIn(gIobj))
                illogical(alreadyHasMsg);
        }
    
        report()
        {
            if(gAction.summaryReport != nil)
                dmsg(gAction.summaryReport, gActionListStr);
            
            if(gAction.summaryProp != nil)
                gIobj.(gAction.summaryProp);
        }
    }
    
    alreadyHasMsg = BMsg(already has, '{The subj iobj} already {has}
        {the dobj}.')
    
    iobjFor(GiveTo)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canTalkToMe)
                illogical(cannotGiveToMsg); 
            if(gActor == self)
                illogicalSelf(cannotGiveToSelfMsg);
        }
        
    }
    
    cannotGiveToMsg = BMsg(cannot give to, '{I} {can\'t} give anything to {that
        iobj}. ')
    
    cannotGiveToSelfMsg = BMsg(cannot give to self, '{I} {can\'t} give anything
        to {himself actor}. ')
    
    dobjFor(ShowTo)
    {
        preCond = isFixed ? [objVisible] : [objHeld]  
        report()
        {
            if(gAction.summaryReport != nil)
                dmsg(gAction.summaryReport, gActionListStr);
            
            if(gAction.summaryProp != nil)
                gIobj.(gAction.summaryProp);
        }
    }
    
    iobjFor(ShowTo)
    {
        preCond = [touchObj]
        verify() 
        {
            if(gActor == self)
                illogicalSelf(cannotShowToSelfMsg);
            else if(!canTalkToMe)
                illogical(cannotShowToMsg);
        }
    }
    
    cannotShowToMsg = BMsg(cannot show to, '{I} {can\'t} show anything to {that
        iobj}. ')
    
    cannotShowToSelfMsg = BMsg(cannot show to self, '{I} {can\'t} show anything
        to {himself actor}. ')
    
    
    dobjFor(ShowToImplicit)
    {
        preCond = isFixed ? [objVisible] : [objHeld]
        
        verify() 
        {
            if(gActor.currentInterlocutor == nil)
                illogical(notTalkingToAnyoneMsg);
            else if(!Q.canTalkTo(gActor, gActor.currentInterlocutor))
                illogicalNow(noLongerTalkingToAnyoneMsg);            
            
        }
        
        action()
        {
            gActor.currentInterlocutor.handleTopic(&showTopics, [self]);
        }
        
        report()
        {
            if(gAction.summaryReport != nil)
                dmsg(gAction.summaryReport, gActionListStr);
            
            if(gAction.summaryProp != nil)
                gActor.currentInterlocutor.(gAction.summaryProp);
        }
    }
    
    dobjFor(GiveToImplicit)
    {
        preCond = [objHeld]
        
        verify() 
        {
            if(gActor.currentInterlocutor == nil)
                illogical(notTalkingToAnyoneMsg);
            else if(!Q.canTalkTo(gActor, gActor.currentInterlocutor))
                illogicalNow(noLongerTalkingToAnyoneMsg);            
            
        }
        
        action()
        {
             gActor.currentInterlocutor.handleTopic(&giveTopics, [self]);
        }
        
        report()
        {
            if(gAction.summaryReport != nil)
                dmsg(gAction.summaryReport, gActionListStr);
            
            if(gAction.summaryProp != nil)
                gActor.currentInterlocutor.(gAction.summaryProp);
        }
    }
    
    notTalkingToAnyoneMsg = BMsg(not talking to anyone, '{I}{\'m} not talking to
        anyone. ')
    
    noLongerTalkingToAnyoneMsg = BMsg(no longer talking to anyone, '{I}{\'m} no
        longer talking to anyone. ')
    
   
    dobjFor(SpecialAction)
    {
        verify() 
        {
            illogical(cantSpecialActionMsg);
        }
    }
    
    cantSpecialActionMsg = BMsg(cant do special, '{I} {can\'t} {1} {the dobj}. ',
                                gAction.specialPhrase )
    
    
 #ifdef __DEBUG
    /* Handling of Debugging actions. */
    
    
    /* 
     *   PURLOIN allows the player to move any portable object in the game
     *   directly into his/her inventory, wherever it is currently. We don't
     *   allow absolutely anything to be purloined, as this could cause chaos.
     */
    dobjFor(Purloin)
    {
        verify()
        {
            if(isDirectlyIn(gActor))
                illogicalNow(alreadyHeldMsg);

            if(self == gActor)
                illogicalSelf(cannotPurloinSelfMsg);
                        
            if(isFixed)
                illogical(cannotTakeMsg);
            
            if(ofKind(Room))
                illogical(cannotPurloinRoomMsg);
            
            if(gActor.isIn(self))
                illogicalNow(cannotPurloinContainerMsg);
            
            logical;
        }
        
        check() {}
        
        action()
        {
            /* 
             *   We use moveInto() rather than actionMoveInto() to move the item
             *   into the player's inventory since this isn't a regular take and
             *   we don't want the side-effects of movement notifications,
             *   neither to we want a notifyRemove() routine to veto a Purloin.
             */
            moveInto(gActor);
            
            /*   
             *   Make this item unhidden even if it was hidden before, otherwise
             *   it won't show up in inventory and we can't interact with it.
             */
            isHidden = nil;
            
            /*  
             *   Note that the player char has seen the purloined item. Not
             *   doing this can make it appear that the player character doesn't
             *   know about an object that's in his/her inventory.
             */
            if(gPlayerChar.canSee(self))
                gSetSeen(self);
        }
        
        report()
        {
            DMsg(purloin, '{I} suddenly {find} {myself} holding {1}. ',                 
                gActionListStr );
        }
    }
        
    cannotPurloinSelfMsg = BMsg(cannot purloin self, '{I} {can\'t} purloin
        {myself}. ')
    cannotPurloinRoomMsg = BMsg(cannot purloin room, '{I} {can\'t} purloin a
        room. ')
    cannotPurloinContainerMsg = BMsg(cannot purloin container, '{I} {can\'t}
        purloin something {i}{\'m} contained within. ')
    
    
    /* 
     *   The GoNear action allows the player character to teleport around the
     *   map.
     */
    dobjFor(GoNear)
    {       
        verify()
        {
            if(getOutermostRoom == nil)
                illogicalNow(cannotGoNearThereMsg);
            
            if(ofKind(Room))
                logicalRank(120);
        }
        
        action()
        {
            DMsg(gonear, '{I} {am} translated in the twinkling of an
                eye...<.p>');
            getOutermostRoom.travelVia(gActor);
        }
    }
    
     
    
    cannotGoNearThereMsg = BMsg(cannot go there, '{I} {can\'t} go there right
        {now}. ')
    
 #endif
;

thingPreinit: PreinitObject
    execute()
    {
        forEachInstance(Thing, {obj: obj.preinitThing }); 
        
        /* 
         *   The player character presumably knows about the objects s/he's
         *   immediately holding even without explicitly examining them or
         *   taking inventory
         */
        foreach(local cur in getPlayerChar().contents)
            gSetKnown(cur);
    }
    
    execBeforeMe = [pronounPreinit]
;

/* 
 *   The Player class can be used to define the player character object. If
 *   there is only one player character in the game (the PC never changes) and
 *   the game is in the second person this can be done very conveniently, and
 *   the Player object will register itself with gameMain and libGlobal.
 */
class Player: Actor
    
    /* The player character can't be picked up */
    isFixed = true       
    
    /* 
     *   The player character is most normally referred to in the first person,
     *   although this can be overridden to 1 or 3 for first- or third-person
     *   games.
     */
    person = 2  
    
     
    /*   The Player object is the initial player character. */
    isInitialPlayerChar = true
    
    isProper = true
;

/*  
 *   A Key is any object that can be used to lock or lock selected items whose
 *   lockabilty is lockableWithKey. We define all the special handling on the
 *   Key class rather than on the items to be locked and/or unlocked.
 */
class Key: Thing
    
    /* The list of things this key can actually be used to lock and unlock. */
    actualLockList = []
    
    /* 
     *   The list of things this key plausibly looks like it might lock and
     *   unlock (e.g. if we're a yale key, we might list all the doors in the
     *   game that have yale locks here).
     */
    plausibleLockList = []
    
    /* 
     *   The list of all the things the player character knows this key can lock
     *   and unlock. Items are automatically added to this list when this key is
     *   successfully used to lock or unlock them, but game code can also use
     *   this property to list items the player character starts out knowing,
     *   such as the door locked by his/her own front door key.
     */
    knownLockList = []
    
    /*  
     *   Determine whether we're a possible key for obj (i.e. whether we might
     *   be able to lock or unlock obj).
     */
    isPossibleKeyFor(obj)
    {
        /* 
         *   First test if we've been defined as a plausible or known key for
         *   our lexicalParent in the case that we're the remapIn object for our
         *   lexicalParent. If so return true. We do this because game code
         *   might easily define the plausibleKeyList and/or knownKeyList on our
         *   lexicalParent intending to refer to what keys might unlock is
         *   associated container (i.e. ourselves if we're our lexicalParent's
         *   remapIn object).
         */        
        if(obj.lexicalParent != nil && obj.lexicalParent.remapIn == obj
           &&(knownLockList.indexOf(obj.lexicalParent) != nil
              || plausibleLockList.indexOf(obj.lexicalParent) != nil))
            return true;
        
        /* 
         *   Otherwise return true if obj is in either our knownLockList or our
         *   plausibleLockList or nil otherwise.
         */
        return knownLockList.indexOf(obj) != nil ||
            plausibleLockList.indexOf(obj) != nil;
    }
    
    /* A key is something we can unlock with. */
    canUnlockWithMe = true
    
    iobjFor(UnlockWith)
    {
        preCond = [objHeld]
        
               
        verify()
        {
            inherited;
            
            /* 
             *   We're a logical choice of key if we're a possible key for the
             *   direct object.
             */
            if(gVerifyDobj && isPossibleKeyFor(gVerifyDobj))
                logical;
            
            /* Otherwise we're not a very good choice. */
            else
                implausible(notAPlausibleKeyMsg);            
        }
        
        check()
        {
            /* 
             *   Check whether this key *actually* fits the direct object, and
             *   if not display a message to say it doesn't (which halts the
             *   action).
             *
             *   This is complicated by the fact that if the direct object is a
             *   SubComponent the game author may have listed the dobj's
             *   lexicalParent in our actualLockList property instead of the
             *   actual dobj (e.g. the fridge object itself instead of the
             *   SubComponent representing the interior of the fridge). So in
             *   addition to seeing if the dobj is included in our
             *   actuallockList we need to check whether, if the dobj has a
             *   lexicalParent of which it's the remapIn object, dobj's
             *   lexicalParent is in our actualLockList.
             */
            
            if(actualLockList.indexOf(gDobj) == nil
               && (gDobj.lexicalParent == nil
               || gDobj.lexicalParent.remapIn != gDobj
               || actualLockList.indexOf(gDobj.lexicalParent) == nil))
                say(keyDoesntFitMsg);              
        }
        
        action()
        {
            /* Make the dobj unlocked. */
            gDobj.makeLocked(nil);
            
            /* If the dobj is not already in our knownLockList, add it there. */
            if(knownLockList.indexOf(gDobj) == nil)
                knownLockList += gDobj;
        }
        
        report()
        {
            DMsg(okay unlock with, okayUnlockWithMsg, gActionListStr);
        }
        
    }
    
    okayUnlockWithMsg = '{I} unlock{s/ed} {the dobj} with {the iobj}. '
    
    iobjFor(LockWith)
    {
        preCond = [objHeld]
        
        verify()
        {
            inherited;
            
            if(gVerifyDobj && isPossibleKeyFor(gVerifyDobj))
                logical;
            else
                implausible(notAPlausibleKeyMsg);            
        }
        
        check()
        {
            /* 
             *   Check whether this key *actually* fits the direct object, and
             *   if not display a message to say it doesn't (which halts the
             *   action).
             *
             *   This is complicated by the fact that if the direct object is a
             *   SubComponent the game author may have listed the dobj's
             *   lexicalParent in our actualLockList property instead of the
             *   actual dobj (e.g. the fridge object itself instead of the
             *   SubComponent representing the interior of the fridge). So in
             *   addition to seeing if the dobj is included in our
             *   actuallockList we need to check whether, if the dobj has a
             *   lexicalParent of which it's the remapIn object, dobj's
             *   lexicalParent is in our actualLockList.
             */
             if(actualLockList.indexOf(gDobj) == nil
               && (gDobj.lexicalParent == nil
               || gDobj.lexicalParent.remapIn != gDobj
               || actualLockList.indexOf(gDobj.lexicalParent) == nil))
                say(keyDoesntFitMsg);              
        }
        
        action()
        {
            /*Make the dobj locked. */
            gDobj.makeLocked(true);
            
            /* If the dobj is not already in our knownLockList, add it there. */
            if(knownLockList.indexOf(gDobj) == nil)
                knownLockList += gDobj;
        }
        
        report()
        {
             DMsg(okay lock with, okayLockWithMsg, gActionListStr);
        }
    }
    
    /* The message to say that the actor has lock the dobj with this key. */
    okayLockWithMsg = '{I} lock{s/ed} {the dobj} with {the iobj}. '
    
    /* 
     *   The message to say that this key clearly won\'t work on the dobj
     *   (because it\'s the wrong sort of key for the lock; e.g. a yale key
     *   clearly won\'t fit the lock on a small jewel box).
     */
    notAPlausibleKeyMsg = '\^<<theName>> clearly won\'t work on <<gVerifyDobj.theName>>. '
    
    /*  The message to say that this key doesn\'t in fact fit the dobj. */
    keyDoesntFitMsg = '\^<<theName>> won\'t fit <<gVerifyDobj.theName>>. '
    
    preinitThing()
    {
        inherited;
        
        /* 
         *   Add the actualLockList to the plausibleLockList if it's not already
         *   there to ensure that this key will work on anything in its
         *   actualLockList.
         */
        plausibleLockList = plausibleLockList.appendUnique(actualLockList);
        
    }
    
;

/* 
 *   A SubComponent is a Thing that is part of something else and represents the
 *   surface, container, underside or rear of the object to which it's attached.
 *   This allows a Thing to model several types of containment at once, by
 *   having (say) one SubComponent that represents its top (on which things can
 *   be placed) and another to represent its interior (in which things can be
 *   placed.
 *
 *   A SubComponent is normally defined as a nested anonymous object on the
 *   remapOn, remapIn, remapUnder or remapBehind property of a Thing. There's no
 *   need to further specify whether a SubComponent is also a Surface,
 *   Container, Underside or RearContainer, since the library can work this out
 *   from the property on which it is defined.
 *
 *   A SubComponent's 'name' property, and other related properties which
 *   control how the game refers to the object, delegate to the parent
 *   object. SubComponents assume their parent's vocabulary, but get a
 *   likelihood adjustment of -15 if their parent is also in scope. If you
 *   assign its own vocabulary, vocabulary it gets from its parent will be
 *   available in addition to that. For example, a car might have a remapIn
 *   SubComponent which can be referred to as 'interior' and a remapUnder
 *   SubComponent which can be referred to as 'undercarriage'. A car presumably
 *   has a windows and a windshield (hence isTransparent = true on the remapIn
 *   SubComponent), so if you're inside it then you can still see the exterior,
 *   and so 'car' will be matched preferentially to the parent object. However,
 *   an action such as 'TOUCH CAR', which is illogical for the exterior because
 *   it can only be seen and not reached, will instead apply to the
 *   SubComponent. On the other hand, if  you're inside a truck trailer and
 *   can't see out, then the exterior is not even in scope and so 'truck' will
 *   match on the SubComponent with no penalty applied.
 *
 *   For all purposes other than those described above, the SubComponent is a
 *   distinct object from its parent, and does not delegate any of its
 *   behavior. In particular, sense-related properties such as 'desc' are not
 *   delegated. Therefore, if the SubComponent can ever have vocabulary then
 *   you will likely want to implement some of these. Passing them through to
 *   the parent is usually not appropriate, because, e.g., the interior or the
 *   undercarriage of a car should probably be described differently than the
 *   car itself.
 */
class SubComponent : Thing
    /* 
     *   A SubComponent is always fixed in place since it represents a fixed
     *   part of its parent.
     */
    isFixed = true

     /* Preinitialize a SubComponent. */
    preinitThing() {
        /* 
         *   Normally, a SubComponent is defined as an anonymous object and we use its lexicalParent
         *   as its location. However, if its location is otherwise defined, we won't override it.
         */
        if(location == nil)
            location = lexicalParent;
        
        initializeSubComponent(location);
        
        /* Store our original vocabLikelihood */
        origVocabLikelihood = vocabLikelihood;
        
        
        
        inherited;
    }
   
    /* Out original vocabLikelihood, which will be set to our vocabLikelihood at preinit. */ 
    origVocabLikelihood = 0
    
     /* 
     * The contType of a SubComponent is deduced based on what remapFoo
     * property it's attached to.
     */
    contType() {
        if (location == nil)
            return inherited;
        if(location.remapIn == self)
            return In;
        else if(location.remapOn == self)
            return On;
        else if(location.remapUnder == self)
            return Under;
        else if(location.remapBehind == self)
            return Behind;
        return inherited;
    }

    /*
     * A SubComponent's listOrder is determined by its contType.
     */
    listOrder() {
        if (contType != nil)
            return contType.listOrder;
        return inherited;
    }

    /* Delegate 'name' and related properties to the parent object. */
#define delegateParent(prop) prop() { \
        if (location != nil) \
            return location.prop; \
        else \
            return inherited; \
        }
    delegateParent(name)
    delegateParent(proper)
    delegateParent(qualified)
    delegateParent(person)
    delegateParent(plural)
    delegateParent(massNoun)
    delegateParent(isHim)
    delegateParent(isHer)
    delegateParent(isIt)
    delegateParent(aName)
    delegateParent(theName)
    delegateParent(owner)
    delegateParent(ownerNamed)
#undef delegateParent

    /* Use the parent's vocabulary, but with a likelihood penalty if
       the parent is in scope. */
    matchName(tokens) {
        local match = inherited(tokens);

        if(location != nil) {
            if(match != 0 || Q.scopeList(gActor).toList().indexOf(location) == nil) {
                vocabLikelihood = origVocabLikelihood;
            } else {
                vocabLikelihood = origVocabLikelihood - 15;
            }
            match |= location.matchName(tokens);
        } else {
            vocabLikelihood = origVocabLikelihood;
        }

        return match;
    }
    
    matchNameDisambig(tokens)
    {
        local match = inherited(tokens);
        if(location != nil)
            match |= location.matchNameDisambig(tokens);
        return match;
    }

    /* 
     *   Normally we want any command that might be directed to a SubComponent to be directed to its
     *   parent, unless the actor is inside the SubComponent in which case we want to match the
     *   SubComponent.
     */
     
    filterResolveList(np, cmd, mode)
    {       
        if(np.matches.length > 1)
        {
            if(gActor.isIn(self) && contType == In)
                np.matches = np.matches.subset({m: m.obj == self});
            else
                np.matches = np.matches.subset({m: m.obj != self});
        }
    }
    
    /*
     *  DEPRECATED. It used to be necessary to call this method after changing
     *  the parent's name-related properties. Now it's a no-op.
     */
    nameAs(parent) {}

    /*
     *   If we're an enterable container then we and our parent object may alternate as the parser'c
     *   choice when the player refers to us. In such a case, this method makes this SubComponent
     *   and its parent facets of each other so that if the player refers to us with the appropriate
     *   pronound (probably iT) the parser will pick whichever of the SubComponent and the parent is
     *   in scope.
     */
    initializeSubComponent(parent) 
    {       
        if(parent.remapIn == self)
        {
            parent.getFacets = valToList(parent.getFacets).appendUnique([self]);
            getFacets = valToList(getFacets).appendUnique([parent]);
            
            
            /* 
             *   If we've been defined as a separate object then we need to give ourselves a
             *   vocabLikehood boost to avoid a spurious disambiguation prompt in response to a LOOK
             *   IN command.
             */
            if(lexicalParent == nil && vocabLikelihood == 0)
                vocabLikelihood = 10;
        }
    } 
    
    /* 
     *   Our exit location will normally be our location's (i.e. parent object's) location. If for
     *   any reason that's nil will use our lexicalParent's location instead.
     */
    exitLocation = (location == nil ? lexicalParent.location : location.location)
;


/*  
 *   A MultiLoc is an object that can exist in several locations at once.
 *   MultiLoc is a mix-in class that should be used in conjunction with Thing or
 *   a Thing-derived class.
 */
class MultiLoc: object
    
    /* 
     *   A list of the locations this object is currently present in. If this
     *   property is defined at the start of the game and initialLocationList
     *   isn't, then this list will be copied to initialLocationList, and so can
     *   be specified by users in exactly the same way.
     */
    locationList = []
    
    
    /* 
     *   A list of the locations this object is to start out in. Locations may
     *   be specified as Things, Rooms or Regions, or as some mix of all three.
     */   
    initialLocationList = []
    
    /* 
     *   A list of locations this object is not to be present in. This is
     *   intended mainly to allow certain rooms to be excepted from a specified
     *   region.
     */    
    exceptions = []
    
    
    /* 
     *   If the initialLocationClass property is defined, then this MultiLoc is
     *   initially located in every instance of this class. Note that this would
     *   be in addition to the locations defined in the locationList class and
     *   would likewise be subject to anything defined in the exceptions
     *   property.
     */
    initialLocationClass = nil
    
    /*
     *   Test an object for inclusion in our initial location list.  By
     *   default, we'll simply return true to include every object.  We
     *   return true by default so that an instance can merely specify a
     *   value for initialLocationClass in order to place this object in
     *   every instance of the given class.
     */
    isInitiallyIn(obj) { return true; }
    
    /*   
     *   In Preinit, add this MultiLoc into the contents list of every item in
     *   its locationList and every object of class initialLocationClass (if
     *   this is not nil) and then remove it from the contents list of every
     *   item in its exceptions list.
     */    
    addToLocations()
    {
        /* 
         *   If there's nothing in the initialLocationList, we'll assume the
         *   author used the locationList property to specify the initial
         *   locations of this MultiLoc, since this was correct in earlier
         *   versions and should be maintained for backward compatibility. In
         *   That case copy the locationList to the initialLocationList and then
         *   set the locationList to an empty list before attempting to build
         *   it.
         */
        if(initialLocationList == nil || initialLocationList.length == 0)
        {
            initialLocationList = locationList;
            locationList = [];               
        }
        
        /* Create a new Vector to keep track of our list of locations. */
        local locationVec = new Vector(10);
        
        /* 
         *   Add ourselves to the content property of all the items listed in
         *   our initialLocationList. At the same time append each item listed
         *   to our locationVec vector.
         */
        foreach(local loc in valToList(initialLocationList))
        {           
            loc.addToContents(self, locationVec);             
        }
        
        /* 
         *   If we have an initialLocationClass, add ourselves to the location
         *   list of every object of that class for which our isInitiallyIn(obj)
         *   method returns true; at the last time add all such objects to our
         *   locationVec vector.
         */
        if(initialLocationClass != nil)
        {
            for(local obj = firstObj(initialLocationClass); obj != nil; obj =
                nextObj(obj, initialLocationClass))   
            {
                if(isInitiallyIn(obj))
                    obj.addToContents(self, locationVec);
            }
        }
        
        /*  
         *   Now remove ourselves from the contents list of all objects listed
         *   as exceptions in our exceptions property, and remove those objects
         *   from our locationVec vector.
         */
        foreach(local loc in valToList(exceptions))            
        {
            loc.removeFromContents(self, locationVec); 
        }
        
        /* 
         *   Store our resulting list of locations in our locationList property.
         */
        locationList = locationVec.toList();
    }
      
    /* 
     *   Move this MultiLoc into an additional location or locations. The locs parameter may be
     *   supplied as a single location or a list of locations.
     */      
   moveIntoAdd(locs)
    {
        locs = valToList(locs);
        foreach(local loc in locs)
            /* 
             *   Let the new location handle it, so it will work whether the new location is a
             *   Thing, a Room or a Region.
             */
            loc.moveMLIntoAdd(self);
    }
    
    /* 
     *   Remove this MultiLoc from loc.
     */         
    moveOutOf(loc)
    {
        /* 
         *   Let the new location handle it, so it will work whether the new
         *   location is a Thing, a Room or a Region.
         */
        loc.moveMLOutOf(self);        
    }
    
    /* 
     *   To move a MultiLoc into a single location, first remove it from every
     *   location in its location list, then add it to the single location it's
     *   now in.
     */    
    moveInto(loc)
    {
        foreach(local cur in locationList)
            cur.removeFromContents(self);
        
        locationList = [];
        
        if(loc != nil)
            moveIntoAdd(loc);
    }
    
        
    /* 
     *   A MultiLoc is directly in another object if it's listed in that other
     *   object's contents list.     
     */    
    isDirectlyIn(loc)
    {               
        if(loc != nil)
            return valToList(loc.contents).indexOf(self) != nil;
        
        /* 
         *   We only reach this point if loc is nil, in which case we're testing
         *   whether this MultiLoc is in nil, i.e. nowhere at all. This will be
         *   the case if and only if its location list is empty.
         */
        return locationList == [];
    }
    
    /* 
     *   A MultiLoc is in another object either if it's directly in that object
     *   or if one of the items in its location list is in that object.
     */    
    isIn(loc)
    {
        return isDirectlyIn(loc) 
            || locationList.indexWhich({x: x.isIn(loc)}) != nil;    
    }
    
    
    
    /* 
     *   For certain purposes, such as sense path calculations, a Multiloc needs
     *   a notional location. We assume the enquiry is made from the perspective
     *   of the current actor, or, failing that, the player char, so we return
     *   the current actor's (or the player char's) current location if the
     *   MultiLoc is present there, or the last place where the MultiLoc was
     *   seen otherwise. The intention is to select the most currently
     *   significant location where we're present.
     */    
    location()
    {
        /* 
         *   If our locationList is empty, then we aren't anywhere, so our
         *   location is nil.
         */
         if(locationList.length == 0)
            return nil;       
        
        /* 
         *   Get the room either of the current actor (if there is one) or else
         *   of the player char.
         */
        local rm = gActor == nil ? gPlayerChar.getOutermostRoom :
        gActor.getOutermostRoom;
             
        
        /* 
         *   First see if we're directly in the actor's enclosing room. If so,
         *   return that room as our location.
         */        
        if(isDirectlyIn(rm))
            return rm;
        
        /* 
         *   If that doesn't work, check if anything in our location list is in
         *   the actor's room; if so, use that.
         */        
        local loc = locationList.valWhich({x: x.isIn(rm)});
        
        if(loc != nil)
            return loc;
        
        
        /* 
         *   If that doesn't work, see if there's a location in our location list that's in a room
         *   the actor can see and return that.
         */
        
        foreach(rm in valToList(gActorRoom.visibleRooms))
        {
            loc = locationList.valWhich({x: x.isOrIsIn(rm)});
            
            if(loc)
                return loc;
        
        }
        
        
        /* 
         *   If that doesn't work, return the location we were last seen at,
         *   provided we have one and we're still there.
         */
        if(lastSeenAt != nil && locationList.indexOf(lastSeenAt) != nil)        
            return lastSeenAt;    
        
         /* 
          *   If all else fails, return the first location from our locationList
          *   (if we've reached this point we know for sure there is one, since
          *   if our locationList were empty this method would have already
          *   returned nil).
          */         
        return locationList[1];
    }   
    
    /* 
     *   If we're a MultiLoc we don't want to carry out any of the normal
     *   preinitialization related to our location.
     */
    preinitThing()
    {
        /* if we have a global parameter name, add it to the global table */
        if (globalParamName != nil)
            libGlobal.nameTable_[globalParamName] = self;
    }
;

/*  
 *   The Floor Class is used to provide a floor or ground object to each room
 *   that wants one (by default, every Room). While this serves the secondary
 *   purpose of allowing the player to refer to the ground/floor of the current
 *   location (which is nearly always implicitly present), it's primary purpose
 *   is to allow the parser to refer to the floor/ground when it wants to
 *   distinguish items directly in a Room (and hence notionally on the ground)
 *   from those in or on some other object.
 */
class Floor: MultiLoc, Thing
    /* 
     *   A Floor is a Decoration, but since the extras.t module is optional we
     *   have to define is as isFixed = true and isDecoration = true.
     */
    isFixed = true
    
    isDecoration = true
    
    /* By default, every room has a floor. */
    initialLocationClass = Room
    
    /* A Floor is something we can put things on. */
    contType = On
    
    /* 
     *   We narrow down our list of locations to those Rooms that actually
     *   define this Floor as their floorObj. Some rooms may wish to define a
     *   custom floorObj, and some (e.g. those representing the top of a mast or
     *   tree) may want to have no floorObj at all.
     */
    isInitiallyIn(obj) { return obj.floorObj == self; }
    
    /* 
     *   The Floor object needs to appear to share the contents of the player
     *   character's room (or other enclosing container) for certain purposes
     *   (such as disambiguating by container or the TakeFrom command), but
     *   nothing is really moved into or out of a Floor).
     */
    contents = (gPlayerChar.outermostVisibleParent().contents - self)
    
    /*   
     *   We can examine a Floor or take something from it, but other actions are
     *   ruled out. A Floor should generally be treated as a Decoration object
     *   rather than something with which any extensive interaction is allowed.
     */
    decorationActions = [Examine, TakeFrom]
    
    
    /* 
     *   By default we probably want to keep the description of a Floor object
     *   as minimalistic as possible to discourage players from trying to
     *   interact with it, so we won't listed the 'contents' of a Floor when
     *   it's examined. This can of course be overridden if desired.
     */    
    contentsListed = nil        
;


/* 
 *   The defaultGround object is the specific Floor object that's present in
 *   every Room by default.
 */
defaultGround: Floor
;

/* Preinitilizer for MultiLocs */
multiLocInitiator: PreinitObject
    execute()
    {
        /* 
         *   Add every MultiLoc to the contents list of all its locations. This
         *   also builds each MultiLoc's locationList as it goes.
         */
        for(local cur = firstObj(MultiLoc); cur !=nil ; cur = nextObj(cur,
            MultiLoc))
            
            cur.addToLocations();
    }
    
    /* 
     *   Make sure we've preinitialized Regions first, so that their roomLists
     *   are ready when we want to use them.
     */
    execBeforeMe = [regionPreinit]
;




/*  
 *   A Topic is something that the player character can refer to in the course
 *   of conversation or look up in a book, but which is not implemented as a
 *   physical object in the game. Topics can be used for abstract concepts such
 *   as life, liberty and happiness, or for physical objects that are referred
 *   to but not actually implemented as Things in the game, such as Alfred the
 *   Great or the Great Wall of China.
 */
class Topic: Mentionable
    construct(name_)
    {        
        vocab = name_;
        initVocab();
    }
    
    /*
     *   Whether the player character knows of the existence of this topic. By
     *   default we assume this is true.
     */    
    familiar = true
    
    /*   Make this topic known to the player character */   
    setKnown() { gPlayerChar.setKnowsAbout(self); }
    
    /* Test whether this topic is known to the player character */
    known = (gPlayerChar.knowsAbout(self)) 
    
    /* 
     *   Return a textual description of this topic, which will normally be just
     *   its name. We use the vocab as fall-back alternative.
     */
    getTopicText()
    {
        return name == nil ? vocab : name;
    }
    
    /* For internal use by the parser; has the parser newly created us for its own purposes? */
    newlyCreated = nil
;

/* Stub definitions to allow Actor to be modfied in actor.t */
class EndConvBlocker: object;
class AgendaManager: object;
class ActorTopicDatabase: TopicDatabase;
class TopicDatabase: object;


/* 
 *   Very basic Actor class with a few basic properties defined. This allows code that need to
 *   references the Actor class to compile in adv3Liter and adv3Litest. It also allows the Player
 *   class to descend from Actor. The implementation here is replaced by the much more sophisticated
 *   one in actor.t when actor.t is present.
 */
class Actor: EndConvBlocker, AgendaManager, ActorTopicDatabase, Thing
    isFixed = true
    contType = Carrier
    ownsContents = true
    mood = nil
    stance = nil
    cannotTalkToMsg = BMsg(cannot talk basicactor, '{The subj cobj} {doesn\'t seem} interested. ')
    cannotGiveToMsg = cannotTalkToMsg
    cannotShowToMsg = cannotTalkToMsg
    isAttackable = true
    checkAttackMsg = cannotAttackMsg    
    
    /* By default, show what we're carrying when we're examined. */
    contentsListedInExamine = true
    examineStatus()
    {
        inherited();
                       
        if(contentsListedInExamine && listableContents.length > 0)        
            nestedActorAction(self, Inventory);      
        
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   LocType objects are used for Thing.locType property values to specify
 *   the relationship between an object and its container.
 *   
 *   The language module must set appropriate vocabulary properties for
 *   each LocType object during pre-initialization.  The exact vocabulary
 *   needed is up to the language to define.  For the English module, we
 *   set the 'prep' property to a suitable preposition for constructing
 *   locational phrases ("the book *on* the table", etc).  
 */
class LocType: object
    
    listOrder = 100
;

/*
 *   An IntLocType is an interior location type.  These represent objects
 *   on the inside of an enclosed space. 
 */
IntLocType: LocType
    
;

/*
 *   An ExtLocType is an exterior location type.  These represent objects
 *   on the outside of an object, such as atop it or attached to it. 
 */
ExtLocType: LocType
;

/* 
 *   "In" location type - specifies that an object is contained within its
 *   location; its location encloses it.
 */
In: IntLocType
    listOrder = 10
;

/*
 *   "Outside" location type - specifies that an object is situated
 *   somewhere on the exterior of the object.  This can be used for
 *   components, attachments, things stuck to an object, things nailed to
 *   it, messages painted on it, etc.  
 */
Outside: ExtLocType
;

/*
 *   "On" location type - specifies that an object is sitting on the top
 *   surface of its container.  
 */
On: ExtLocType
    listOrder = 20
;

/*
 *   "Under" location type - specifies that an object is situated
 *   underneath its container. 
 */
Under: ExtLocType
    listOrder = 30
;

/*
 *   "Behind" location type - specifies that an object is situated behind
 *   its container. 
 */
Behind: ExtLocType
    listOrder = 40
;

/*
 *   "Held" location type - specifies that an object is being held by its
 *   container, in the sense of a person holding an object in her hands.
 *   An object being held is exterior to the holder, not enclosed.  
 */
Held: ExtLocType
;

/*
 *   "Worn" location type - specifies that an object is being worn by its
 *   container, in the sense of a person wearing a coat. 
 */
Worn: ExtLocType
;

/*  
 *   "Attached" location type - specifies that an object is attached to its
 *   container.
 */
Attached: ExtLocType
;
    
/* 
 *   "PartOf" location type - specifies that an object is part of -- a component
 *   of -- its container.
 */
PartOf: ExtLocType
;

/*  
 *   "Carrier" location type - specifies that the object is being carried by its
 *   container (which will then normally be the actor holding this object). Any
 *   actor-type object should define Carrier as its contType.
 */
Carrier: ExtLocType
;

/* 
 *   A ViaType is an object used to define the preposition to use to describe
 *   various kinds of PushTravel. The language-specific part of the libary needs
 *   to override the various ViaType objects to give the names of the
 *   prepositions in the target language.
 */
class ViaType: object
    prep = ''
;

Into: ViaType;
OutOf: ViaType;
Down: ViaType;
Up: ViaType;
Through: ViaType;

/* 
 *   The displayProbe object is used to store the result of capturing text in
 *   Thing.checkDisplay() before undoing the trial display of the string. By
 *   making displayProbe transient we preserve the value of its displayed
 *   property across the undo.
 */
transient displayProbe: object
    displayed = nil
;


/*  
 *   The failVerifyObj is intended for internal library use only as a fallback value for gVerifyIobj
 *   or gVerifyDobj when these might otherwise evailuate to nil and potentially cause nil object
 *   reference runtime errors. Since this is never intended to be a valid verify result,
 *   failVerifyObj is designed to fail the verify stage of any action.
 */

failVerifyObj: Thing
    dobjFor(Default) { verify {inaccessible(inaccessibleMsg);}}
    iobjFor(Default) { verify {inaccessible(inaccessibleMsg);}}    
    aobjFor(Default) { verify {inaccessible(inaccessibleMsg);}}   
    
    inaccessibleMsg = BMsg(dummy object inaccessible, 'The dummy failVerifyObj is not a valid object
        of a command. ')
;

/* We define Mood and Stance in thing.t so english.t can define the built-in moods and stances */

/* A Mood object can be used to represent the mood of an actor (happy, sad, bored, etc.) */
class Mood: object
    /* 
     *   A single-quoted string giving the name of this Mood, which will normally correspond to the
     *   name of the Mood object; e.g. happyMood.name = 'happy'
     */
    name = nil
    
    objToString() { return name; }
;


/* 
 *   A Stance object can be used to represent the stance of an actor towards the player character
 *   (neutral, friendly, hostile, etc.).
 */
class Stance: object
    /* 
     *   A single-quoted string giving the name of this Stance which will normally correspond to the
     *   name of the Mood object; e.g. friendlyStance.name = 'friendly'
     */
    name = nil
    
    /* 
     *   The score is a measure of how positive or negative an actor with this stance is towards the
     *   player character. Each Stance object defines its own score.
     */
    score = 0
    
    operator >> (x) { return self.score > x.score;  }
    operator << (x) { return self.score < x.score; }
    operator >>> (x) { return self.score >= x.score;  }
    operator []= (x, y) { x.setStanceToward(y, self); }
    operator - (x) {return self.score - x.score; }
    
    /* Get a list of actors who have this stance towards x */
    operator * (x)
    {
        local vec = new Vector;
        for(local a = firstObj(Actor); a != nil; a = nextObj(a, Actor))
        {
            if(a.stanceToward(x) == self)
                vec.append(a);
        }
        
        return vec.toList();
    }
    
    /* Get a list of actors x holds this stance towards */
    operator [](x)
    {
        local vec = new Vector;
        for(local a = firstObj(Actor); a != nil; a = nextObj(a, Actor))
        {
            if(x.stanceToward(a) == self)
                vec.append(a);
        }
        
        return vec.toList();
    }
    
    objToString() { return name; }
;


/* 
 *   Default multimethods for action handling. We make them match Mentionable dobj and iobj so that
 *   if game code wants to define a Multimethod matching Thing and Thing it will take precedence.
 *   The library action multikmethods all do nothing at all but need to exist so the action handling
 *   for ITActions libary actions can call them.
 *
 *   User-defined action multimethods should return nil if they want to add their behaviour to the
 *   library's behavious or true if they want to replace the library methods.
 */     
//verifyPutIn(Mentionable dobj, Mentionable iobj) { }
//checkPutIn(Object dobj, Object iobj) { }
//actionPutIn(Mentionable dobj, Mentionable iobj) { }
//
//verifyPutOn(Mentionable dobj, Mentionable iobj) { }
//checkPutOn(Mentionable dobj, Mentionable iobj) { }
//actionPutOn(Mentionable dobj, Mentionable iobj) { }
//
//verifyPutBehind(Mentionable dobj, Mentionable iobj) { }
//checkPutBehind(Mentionable dobj, Mentionable iobj) { }
//actionPutBehind(Mentionable dobj, Mentionable iobj) { }
//
//verifyPutUnder(Mentionable dobj, Mentionable iobj) { }
//checkPutUnder(Mentionable dobj, Mentionable iobj) { }
//actionPutUnder(Mentionable dobj, Mentionable iobj) { }


