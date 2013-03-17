#charset "us-ascii"
#include "advlite.h"

property subLocation;

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
    isIt = (!(isHim || isHer))
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
     *   Match the object to a noun phrase in the player's input.  If the
     *   given token list is a valid name for this object, we return a
     *   combination of MatchXxx flag values describing the match.  If the
     *   token list isn't a valid name for this object, we return 0.
     *   
     *   By default, we call simpleMatchName(), which matches the name if
     *   all of the words in the token list are in the object's vocabulary
     *   list, regardless of word order.
     *   
     *   In most cases, an unordered word match works just fine.  The
     *   obvious drawback with this approach is that it's far too generous
     *   at matching nonsense phrases to object names - DUSTY OLD SPELL
     *   BOOK and BOOK DUSTY SPELL OLD are treated the same.  In most
     *   cases, users won't enter nonsense phrases like that anyway, so
     *   they'll probably never notice that we accept them.  If they enter
     *   something like that intentionally, we can plead Garbage In/Garbage
     *   Out: a user who willfully types a nonsense command has only
     *   himself to blame for a nonsense reply.
     *   
     *   Occasionally, though, there are reasons to be pickier.  When these
     *   come up, you can override matchName() to be as picky as you like.
     *   
     *   The most common situation where pickiness is called for is when
     *   two objects happen to share some of the same vocabulary words, but
     *   certain words orderings clearly refer to only one or the other.
     *   With the unordered approach, this can be a nuisance for the player
     *   because it can trigger disambiguation questions that seem
     *   unnecessary.  Overriding matchName() to be picky about word order
     *   for those specific objects can often fix this.
     *   
     *   Another example is ensuring the user knows the correct full name
     *   of an object as part of a puzzle: you can override matchName() to
     *   make sure the user doesn't accidentally stumble on the object by
     *   using one of its vocabulary words to refer to something else
     *   nearby.  Another example is matching words that aren't in the
     *   vocabulary list, such as a game object that represents a group of
     *   apparent objects that have a whole range of labels ("post office
     *   box 123", say).  
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
         *   First try the phrase-match matcher; if this fails return 0 to
         *   indicate that we don't match. If it succeeds in matching a phrase
         *   of more than one word, return MatchPhrase (we found a match).
         */
        
        local phraseMatch = 0;
        
        if(phrases != nil)
        {    
            phraseMatch = phraseMatchName(phrases, tokens);
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
        
        local tokLen = tokens.length;
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
     *   the vocab property; the purpose of the phraseMatches property is to
     *   limit matches. Note also that object will be matched if any of the
     *   phrases in the list are matched.
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
     *   directly.
     */
    
    redirect(cmd, altAction, dobj:?, iobj:?, isReplacement: = true)
    {
        if(iobj != nil && dobj != nil)
            execNestedAction(isReplacement, gActor, altAction, dobj, iobj);
        else if(dobj != nil)
            execNestedAction(isReplacement, gActor, altAction, dobj);
        else
            execNestedAction(isReplacement, gActor, altAction);
    }
;

class Thing:  ReplaceRedirector, Mentionable
   
    /* 
     *   The description of this Thing that's displayed when it's examined.
     *   Normally this would be defined as a double-quoted string, but in more
     *   complicated cases you could also define it as a method that displays
     *   some text.
     */
    desc() 
    { 
        /* 
         *   Only display the 'nothing special' message if there's no status
         *   description.
         */
        
        local str = gOutStream.captureOutput({: examineStatus()});
        
        str = str == nil ? '' : str.trim();
        
        if(str == '')            
            DMsg(nothing special,  '{I} {see} nothing special about {1}. ', 
                 theName); 
    }
    
    /* 
     *   The state-specific description of this object, which is appended to its
     *   desc when examined. This is defined as a single-quoted string to make
     *   it easy to change at run-time.
     */
    stateDesc = ''
    
    lookDesc(pov) { desc; }
    childDesc(pov) { desc; }
    
    
    /* 
     *   Attempt to display prop appropriately according to it data type
     *   (single-quoted string, double-quoted string, integer or code )
     */
    display(prop)
    {
        switch(propType(prop))
        {
        case TypeSString:
        case TypeInt:    
            say(self.(prop));
            break;
        case TypeDString:
            self.(prop);
            break;
        case TypeCode:
            local str = self.(prop);
            if(dataType(str) == TypeSString)
                say(str);
            break;
        default:
            /* do nothing */
            break;
        }
    }
    
    
    /* 
     *   Has this item been mentioned yet in a room description. Note that this
     *   flag is used internally by the library; it shouldn't normally be
     *   necessary to manipulate it directly from game code.
     */
    mentioned = nil
    
    
    /* 
     *   Most of the following properties and methods down to the next dashed
     *   line are usually only relevant on Room, but they have been moved to
     *   Thing in case the player char finds itself in a closed Booth.
     */
    
    roomHeadline(pov)
    {
        /* start with the room title */
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

    
    isIlluminated
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
    
    isThereALightSourceIn(lst)
    {
        foreach(local obj in lst)
        {
            if(obj.isLit)
                return true;
            
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
    
    
    lookAroundWithin()
    {
         /* Reset everything in the room to not mentioned. */
        unmention(contents);
        
        /* Reset everything in remote rooms we're connected to */
        
        unmentionRemoteContents();
        
        "<.roomname><<statusName(gPlayerChar)>><./roomname>\n";
        if(isIlluminated)
        {
            "<<interiorDesc>><.p>";
            listContents();
            seen = true;
            visited = true;
        }
        else
        {
            "<<darkDesc>>";
            if(recognizableInDark)
            {
                visited = true;
                setKnown();
            }
        
        }
        "<.p>";
        

        if(gExitLister != nil)
            gExitLister.lookAroundShowExits(gActor, self, isIlluminated);
    }
    
    listContents(lister = roomContentsLister)
    {    
        
        /* Don't list the contents if we can't see in */
        if(!canSeeIn())
            return;
        
        local firstSpecialList = [];
        local miscContentsList = [];
        local secondSpecialList = [];
          
        /* 
         *   First mention the actor's immediate container, if it isn't the
         *   object we're looking around within. Then list the oontainer's
         *   contents immediately after.
         */
        
        local loc = gActor.location;        
        
        if(loc != self && lister == roomContentsLister)
        {
            if(gAction == nil)
                gAction = Look.createInstance();
            
            gMessageParams(loc);
            DMsg(list immediate container, '{I} {am} {in loc}. <.p>');
            loc.mentioned = true;
            if(loc.ofKind(SubComponent) && loc.lexicalParent != nil)
                loc.lexicalParent.mentioned = true;
                
            listSubcontentsOf([loc]);
        }
        
        foreach(local obj in contents)
        {            
            if((obj.propType(&initSpecialDesc) != TypeNil &&
               obj.useInitSpecialDesc()) ||
               (obj.propType(&specialDesc) != TypeNil && obj.useSpecialDesc()))
            {
                if(obj.specialDescBeforeContents)
                    firstSpecialList += obj;
                else
                    secondSpecialList += obj;
            }
            else if(obj.lookListed)
                miscContentsList += obj;
                      
            obj.noteSeen();
        }
        
        firstSpecialList = firstSpecialList.sort(nil, {a, b: a.specialDescOrder -
                                                 b.specialDescOrder});
                 
        
        secondSpecialList = secondSpecialList.sort(nil, {a, b: a.specialDescOrder -
                                                 b.specialDescOrder});
        
        foreach(local obj in firstSpecialList)        
            obj.showSpecialDesc();                
        
        /* 
         *   If we're listing the contents of a room, then show the specialDescs
         *   of any items in the other rooms in our SenseRegions, where
         *   specialDescBeforeContents is true
         */
        
        if(lister == roomContentsLister)
            showFirstConnectedSpecials(gPlayerChar);
        
        
        miscContentsList = miscContentsList.subset({o: o.mentioned == nil});
                        
        lister.show(miscContentsList, self);
               
        listSubcontentsOf(contents, lookContentsLister);
        
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
        if(lister == roomContentsLister)        
            showConnectedMiscContents(gPlayerChar);
                
        foreach(local obj in secondSpecialList)
            obj.showSpecialDesc();
        
        
        /* 
         *   Show the specialDescs of any items in the other rooms in our
         *   SenseRegions, where specialDescBeforeContents is nil
         */
       if(lister == roomContentsLister)
           showSecondConnectedSpecials(gPlayerChar);
    }
    
    /* 
     *   List the contents of every item in contList, recursively listing the
     *   contents of contents all the way down the containment tree. The
     *   contList parameter can also be passed as a singleton object.
     */
    listSubcontentsOf(contList, lister = examineLister)
    {
       
        /* 
         *   If contList has been passed as a singleton value, convert it to a
         *   list, otherwise retain the list that's been passed.
         */
        contList = valToList(contList);
                
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
             *   Don't list the inventory of any actors, or of any items that
             *   don't want their contents listed, or any items we can't see in,
             *   or of any items that don't have any contents to list.
             */
            if(obj.contType == Carrier 
               || obj.(lister.contentsListedProp) == nil
               || obj.canSeeIn() == nil
               || obj.contents.length == 0)
                continue;
            
                      
            /* Don't list any items that have already been mentioned */ 
            local objList = obj.contents.subset({x: x.mentioned == nil});
            
            
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
            foreach(local cur in firstSpecialList)                    
                cur.showSpecialDesc(); 
            
            
            /*   List the miscellaneous items */
            if(objList.length > 0)   
            {
                lister.show(objList, obj, paraBrksBtwnSubcontents);                      
                objList.forEach({o: o.mentioned = true });
            }
            
            /* 
             *   If we're not putting paragraph breaks between each subcontents
             *   listing sentence, insert a space instead.
             */
            if(!paraBrksBtwnSubcontents)
                " ";
            
            
            /*  
             *   Show the specialDescs of items whose specialDescs should be
             *   shown after the list of miscellaneous items.
             */
            foreach(local cur in secondSpecialList)        
                cur.showSpecialDesc(); 
            
            
            /* 
             *   Recursively list the contents of each item in this object's
             *   contents, if it has any; but don't list recursively for an
             *   object that's just been opened.
             */
            if(obj.contents.length > 0 && lister != openingContentsLister)
                listSubcontentsOf(obj.contents, lister);          
            
            
        }
        
         
    }
    
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
    
//------------------------------------------------------------------------------  

    /* Do we want this object to report whether it's open? */

    openStatusReportable = (isOpenable && isOpen)
    
    examineStatus()
    {        
        display(&stateDesc);
        
        if(contType != Carrier && contentsListedInExamine)
        {          
            unmention(contents);
            listSubcontentsOf(self, examineLister);            
        }           
           
    }
    
    /* The lister to use to list an item's contents when it's examined. */
    
    examineLister = descContentsLister
    
    
    
    
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
    
    
    /* Show our specialDesc */
    showSpecialDesc()
    {
        /* 
         *   If we've already been mentioned in the room description, don't show
         *   us again. Otherwise note that we've now been mentioned.
         */
        if(mentioned)
            return;
        else
            mentioned = true;
        
        
        /* 
         *   If we have an initSpecialDesc and useInitSpecialDesc is true, show
         *   our initSpecialDesc, otherwise show our specialDesc.
         */
        if(propType(&initSpecialDesc) != TypeNil && useInitSpecialDesc)
            initSpecialDesc;
        else
            specialDesc;
           
        "<.p>";
        
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
    isListed = (!isFixed)
    lookListed = (isListed)
    inventoryListed = (isListed)
    examineListed = (isListed)
    searchListed = (isListed)
    
    contentsListed = true
    contentsListedInLook = (contentsListed)
    contentsListedInExamine = (contentsListed)
    contentsListedInSearch = true
    
    
    /*
     *   The text we display in response to a READ command. This can be nil
     *   (if we're not readable), a single-quoted string, a double-quoted string
     *   or a routine to display a string.
     */
    
    readDesc = nil
    
    /* The description displayed in response to a SMELL command */
    smellDesc = nil
    
    /* 
     *   Is the this object's smellDesc displayed in response to an intransitive
     *   SMELL command? (Only relevant if smellDesc is not nil)
     */
    isProminentSmell = true
    
    /*   The description displayed in response to a FEEL command */
    feelDesc = nil
    
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
    
    globalParamName = nil
    
   
    /* 
     *   Is this object lit, i.e. providing sufficient light to see not only
     *   this object but other objects in the vicinity by.
     */    
    isLit = nil
    
    /* Make this object lit or unlit */
    makeLit(stat) { isLit = stat; }
    
    /* 
     *   Set this to true for an object that is visible in the dark but does not
     *   provide enough light to see anything else by, e.g. the night sky.
     */
    visibleInDark = nil
    
    
    /* 
     *   Is this object lightable (via a player command)? Note that setting this
     *   property to true also automatically makes the LitUnlit State applicable
     *   to this object, allowing it to be referred to as 'lit' or 'unlit' as
     *   appropriate.
     */
    isLightable = nil
    
    /*   
     *   The preposition that should be used to describe containment within this
     *   thing (e.g. 'in', 'on' , 'under' or 'behimnd'). By default we get this
     *   from our contType.
     */
    objInPrep = (contType.prep)
    
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
     *   of any items currently worn.
     */
    getCarriedBulk()
    {
        local totalBulk = 0;
        foreach(local cur in contents)
        {
            if(cur.wornBy == nil)
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
        gMessageParams(obj);
        if(obj.bulk > maxSingleBulk || obj.bulk > bulkCapacity)
            DMsg(too big, '{The subj obj} {is} too big to fit {1} {2}. ', 
                 objInPrep, theName);
            
        else if(obj.bulk > bulkCapacity - getBulkWithin())
            DMsg(no room, 'There {dummy} {is} not enough room {1} {2} for {the
                obj). ', objInPrep, theName);            
    }
    
    
    
    /* Remap LOOK IN, PUT IN etc. to the following objects if they're not nil */
    
    remapIn = nil
    remapOn = nil
    remapUnder = nil
    remapBehind = nil
    
    
    /* 
     *   my notional total contents is my normal contents plus anything from my
     *   remapXX contents lists, assuming they're visible
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
    hiddenBehind = []
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
     *   The lockability property determines whether this object is lockable and
     *   if so how. The possible values are notLockable, lockableWithoutKey,
     *   lockableWithKey and indirectLockable.
     */
    
    lockability = notLockable
    
    /* Is this object currently locked */
    isLocked = nil
    
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
    
    /* If this object is worn, presumably it's worn by its immediate location */    
    makeWorn(stat)  { wornBy = stat ? location : nil; }
    
    /* are we directly held by the given object? */
    isDirectlyHeldBy(obj) { return location == obj && !obj.isFixed &&
            obj.wornBy == nil; }

    /* get everything I'm directly holding */
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
    directlyWorn = (contents.subset({ obj: obj.wornBy = self }))
    
    
    /* 
     *   Although there are (or may be) mechanisms that would allow objects to
     *   be put under other objects, in general we probably don't want to allow
     *   it.
     */
    
    canPutUnderMe = (contType == Under)
    canPutBehindMe = (contType == Behind)
    canPutInMe = (contType == In)
    
    
    
    /* 
     *   Can an actor enter (get in or on) this object. Note that for such an
     *   action to be allowing the objInPrep must also match the proposed
     *   action.
     */
    
    isBoardable = nil
    
    /* Can this thing be eaten */
    
    isEdible = nil  
   
    
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
       *   On, etc).      
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
    
    addToContents(obj, vec?)
    {
        contents = contents.appendUnique([obj]);
        if(vec != nil)
            vec.appendUnique(self);
    }
    
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
     *   program fiat.
     */
    
    moveInto(newCont)
    {
        if(location != nil)            
            location.removeFromContents(self);
               
        location = newCont;
               
        if(location != nil)
            location.addToContents(self);        
    }
    
    /* Move into generated by a user action, which includes notifications */
    actionMoveInto(newCont)
    {
        if(location != nil)
            location.notifyRemove(self);            
        
        if(newCont != nil)
            newCont.notifyInsert(self); 
        
        moveInto(newCont);
        
        moved = true;
        
        if(Q.canSee(gPlayerChar, self))
            noteSeen();
    }
    
    
    notifyRemove(obj) { }
    notifyInsert(obj) { }
    
    canSee(obj) { return Q.canSee(self, obj); }
    canHear(obj) { return Q.canHear(self, obj); }
    canSmell(obj) { return Q.canSmell(self, obj); }
    canReach(obj) { return Q.canReach(self, obj); }
    
    
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
        return isIn(obj);
    }

    /* 
     *   Are a a direct containment child of the given object with the
     *   given containment type?  'typ' is a LocType giving the
     *   relationship to test for, or nil.  If it's nil, we'll return true
     *   if we have any direct containment relationship with 'obj'. 
     */
    isDirectChild(obj, typ)
    {
        return isDirectlyIn(obj);
    }
    
    isDirectlyIn(cont)
    {
        if(cont == nil)
            return location == nil;
        
        return location == cont || valToList(cont.contents).indexOf(self) != nil;
    }
    
    isIn(cont)
    {
        if(isDirectlyIn(cont))
            return true;
        
        if(location == nil)
            return nil;
        
        return location.isIn(cont);
    }
    
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
    
    
    preinitThing()
    {
        if(subLocation != nil && location != nil)
            location = location.(subLocation);
        
        if(location != nil)
            location.addToContents(self);
        
        /* if we have a global parameter name, add it to the global table */
        if (globalParamName != nil)
            libGlobal.nameTable_[globalParamName] = self;
    }
    
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
           location.lexicalParent == obj)
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
            new function(c) { if (c == nil) vec.append(outermostParent()); },
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
    
    
    locType()
    {
        /* My locType depends on the contType of my immediate parent */
        
        if(location == nil)
            return nil;
        
        if(location.contType == Carrier)
        {
            if(wornBy == location)
                return Worn;
            
            if(isFixed)
                return Outside;
            
            return Held;
        }
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
     *   List group.  
     */
    listWith = nil

    /*
     *   Group order.  This gives the relative order of this item within
     *   its list group.  
     */
    groupOrder = 100

     
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
    
    showStatuslineExits()
    {
        location.showStatuslineExits();
    }
    
    wouldBeLitFor(actor)   
    {
        return getOutermostRoom.isIlluminated;
    }
    
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

    allContents()
    {
        local vec = new Vector(20);
               
        addToAllContents(vec, contents);
        
        return vec.toList;
    }
    
    addToAllContents(vec, lst)
    {
        vec.appendAll(lst);
        foreach(local cur in lst)
            addToAllContents(vec, cur.contents);
    }
    

    /* get everything that's directly in me */
    directlyIn = (contents.subset({ obj: obj.locType == In }))
    
    
    
    /* Run the check method and return any string it tried to display */
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
     *   overridet his to make it (!enclosing) instead.  
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
            { c: c.locType.ofKind(IntLocType) && c.shinesOut() }) != nil)
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
     */
    setKnowsAbout(obj) { obj.(knownProp) = true; }
    setKnown() { gPlayerChar(setKnowsAbout(self)); }
    setHasSeen(obj) { obj.(seenProp) = true; }
    setSeen() { gPlayerChar(setHasSeen(self)); }
    hasSeen(obj) { return obj.(seenProp); }
    knowsAbout(obj) {return hasSeen(obj) || obj.(knownProp); }
    knownProp = &familiar
    seenProp = &seen
    
    /* 
     *   The player character knows about this object either if it has been seen
     *   or if it is familiar.
     */
    
   
    known = (gPlayerChar.knowsAbout(self)) 
    
    
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

    vocabLikelihood = 0
    
    /* before and after travel notifications. By default we do nothing */
    
    beforeTravel(traveler, connector) {}
    afterTravel(traveler, connector) {}
    
    /* 
     *   Handle a command directed to this open (e.g. BALL, GET IN BOX). Since
     *   inanimate objects generally can't respond to commands we simply display
     *   a message announcing the futility of issuing one. This method is
     *   overridden on Actor to allow Actors to respond to commands via
     *   CommandTopics.
     */
    
    handleCommand(action)
    {
        DMsg(cant command thing, 'There{dummy}\'s no point trying to give
            orders to {1}. ', aName);
    }
    
    
    /* 
     *   The before action handling on this Thing if it's the current actor. We
     *   define it here rather than on Actor since the player character can be a
     *   Thing. By default we do nothing.
     */
    actorAction() { }
    
    
    /* Is this object the player character? */
    isPlayerChar = (gPlayerChar == self)
    
    
    /*
     *   *******************************************************************
     *   ACTION HANDLING
     */
    
     /* 
     *   If I declare this object to be a decoration (i.e. isDecoration = true)
     *   then its default behaviour will be to display its notImportantMsg for
     *   every action except Examine. We can extend the actions it will respond
     *   to by adding them to the list in the decorationActions property.
     */
    
    isDecoration = nil
    
    /*   
     *   The list of actions this object will respond to specifically if
     *   isDecoration is true. All other actions will be handled by
     *   dobjFor(Default) and/or iobjFor(Default).
     */
    
    decorationActions = [Examine, GoTo]
    /* 
     *   The verify routines to be used if this object is a deooration
     *   (isDecoration is true). Note that (at least in this version of the
     *   library) it's only meaningful to define verify routines here.
     */
    
    
    /* 
     *   Allow this object to respond to an action just before or just after it
     *   takes place.
     */
    
    beforeAction() { }
    
    afterAction() { }
    
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
            display(&desc);
            
            examineStatus();
            examined = true;
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
        verify()
        {
            if(!isSmellable)
                illogical(cannotSmellMsg);
        }
        
        action()
        {
            if(propType(&smellDesc) == TypeNil)
               DMsg(smell nothing, '{I} {smell} nothing out of the
                    ordinary.<.p>');
            else
                display(&smellDesc);
        }
    }
    
    
    dobjFor(ListenTo)
    {
        
        preCond = [objAudible]
        
        action()
        {
            if(propType(&listenDesc) == TypeNil)            
                DMsg(hear nothing, '{I} {hear} nothing out of the ordinary.<.p>');
            else
                display(&listenDesc);
            
        }
    }
    
    
    /* 
     *   By default everything is tasteable, but there might well be things the
     *   that it would not be appropriate to taste.
     */
    isTasteable = true
    
    
    cannotTasteMsg = BMsg(cannot taste, '{The subj dobj} {is} not suitable for
        tasting. ')
    
    dobjFor(Taste)
    {
        preCond = [objHeld]
        
        verify()
        {
            if(!isTasteable)
                illogical(cannotTasteMsg);
        }
        
        action()
        {
            if(propType(&tasteDesc) == TypeNil)           
                DMsg(hear nothing, '{I} {taste} nothing unexpected.<.p>');
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
    
    dobjFor(Feel)    
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isFeelable)
                illogical(cannotFeelMsg);
        }
        
        action()
        {
            if(propType(&feelDesc) == TypeNil)            
                DMsg(hear nothing, '{I} {feel} nothing unexpected.<.p>');
            else
                display(&feelDesc);
        }
    }
    
    /* By default a Thing is takeable if it's not fixed in place */
    isTakeable = (!isFixed)
    
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
            actionMoveInto(gActor);
        }
        
        report()
        {            
            DMsg(report take, 'Taken. | {I} {take} {1}. ', gActionListStr);
        }
    }
       
    cannotTakeMsg = BMsg(cannot take, '{The subj dobj} {is} fixed in place.
        ')
    
    alreadyHeldMsg = BMsg(already holding, '{I}{\'m} already holding {the dobj}.
        ')
    
    cannotTakeMyContainerMsg = BMsg(cannot take my container, '{I} {can\'t}
        {take} {the dobj} while {i}{\'m} {1} {him dobj}. ', objInPrep)
    
    cannotTakeSelfMsg = BMsg(cannot take self, '{I} {can} hardly take {myself}. ')
    
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
        if(hiddenUnder.length > 0)
        {
            moveReport += 
                BMsg(reveal move under,'Moving {1} reveals {2} that {3}
                    hidden under {4}. ',
                     theName, makeListStr(hiddenUnder), 
                     (hiddenUnder.length > 1 || hiddenUnder[1].plural) ?
                     'were' : 'was', himName);
                     
            moveHidden(&hiddenUnder, location);
            
        }
        
        if(hiddenBehind.length > 0)
        {
            moveReport += 
                BMsg(reveal move behind,'Moving {1} reveals {2} that {3}
                    hidden behind {4}. ',
                     theName, makeListStr(hiddenBehind), 
                     (hiddenBehind.length > 1 || hiddenBehind[1].plural) ?
                     'were' : 'was', himName);
            
            
            moveHidden(&hiddenBehind, location);            
        }
        
        
        
        if(moveReport != '' )
            reportAfter(moveReport);
    }
    
    /* 
     *   Service method: move everything in the prop property to loc and mark it
     *   as seen
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
     *   Check that the actor has enough spare bulkCapacity to add this item to
     *   his/her inventory. Since by default everything has a bulk of zero and a
     *   very large bulkCapacity by default there will be no effective
     *   restriction on what an actor (and in particular the player char) can
     *   carry, but game authors may often wish to give portable items bulk in
     *   the interests of realism and may wish to impose an inventory limit by
     *   bulk by reducing the bulkCapacity of the player char.
     */
    
    checkRoomToHold()
    {
        /* 
         *   First check whether this item is individually too big for the actor
         *   to carry.
         */
        if(bulk > gActor.maxSingleBulk)
            DMsg(too big to carry, '{The subj dobj} {is} too big for {me} to
                carry. ');
        /* 
         *   otherwise check that the actor has sufficient spare carrying
         *   capacity.
         */
        else if(bulk > gActor.bulkCapacity - gActor.getCarriedBulk())
            DMsg(cant carry any more, '{I} {can\'t} carry any more than
                {i}{\'m} already carrying. ');
    }
    
    /* By default we can drop anything that's held */
    isDroppable = true
    
    cannotDropMsg = BMsg(cannot drop, '{The subj dobj} {can\'t} be dropped. ')
    
    /* The location in which something dropped in me should land. */
    dropLocation = self
    
    dobjFor(Drop)
    {
        preCond = [objNotWorn]
        
        verify()
        {
            if(!isDirectlyIn(gActor))
                illogicalNow(notHoldingMsg);
            
            else if(isFixed)
                illogical(partOfYouMsg);
            
            else if(!isDroppable)
                illogical(cannotDropMsg);
            
            logical;
        }
                
        
        action()
        {           
            actionMoveInto(gActor.location.dropLocation);
        }
        
        report()
        {
            DMsg(report drop, 'Dropped. |{I} {drop} {1}. ', gActionListStr);            
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
        
        
        /* 
         *   In case isAttackable is changed to true but no other handling is
         *   added, we need to provide some kind of default report.
         */
        report()
        {
            DMsg(futile attack, futileToAttackMsg, gActionListStr); 
        }
    }
   
   
    
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
            DMsg(futile attack, futileToAttackMsg,  gActionListStr); 
        }       
    }
    
    futileToAttackMsg = 'Attacking {1} {dummy}{proves} futile. '
    
    iobjFor(AttackWith)
    {
        preCond = [objHeld]
        verify() 
        { 
            if(!canAttackWithMe)
               illogical(cannotAttackWithMsg); 
            
            if(gDobj == self)
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
        preCond = [objHeld]
        
        verify()
        {
            if(!isThrowable)
                illogical(cannotThrowMsg);
               
        }
             
        
        action() { moveInto(getOutermostRoom); }
        
        report()
        {
            local obj = gActionListObj;
            
            gMessageParams(obj);
            
            DMsg(throw dir, '{I} {throw} {the obj} {1}wards and {he obj} {lands}
                on the ground. ', gAction.direction.name );
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
    }
    
    dobjFor(Open)
    {
        
        preCond = [touchObj]
        
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
        
        check()
        {
            if(isLocked)
                say(lockedMsg);
        }
        
        action()
        {
            makeOpen(true);
            if(!gAction.isImplicit)
            {              
                unmention(contents);
                listSubcontentsOf(self, openingContentsLister);
            }
            
            
        }
        
        report()
        {
            DMsg(okay open, okayOpenMsg, gActionListStr);
        }
    }
    

    okayOpenMsg = 'Opened.|{I} {open} {1}. '
    
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
            if(!isOpenable && remapIn != nil && remapIn.isOpenable)
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
            DMsg(report close, 'Done |{I} {close} <<theName>>. ');
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
    
    turnNoEffectMsg = BMsg(turn useless, 'Turning {1} {dummy} {achieves}
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
            if(gDobj == self)
                illogical(cannotTurnWithSelfMsg);            
            
            if(!canTurnWithMe)
                illogical(cannotTurnWithMsg); 
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
            if(self == gDobj)
                illogicalSelf(cannotCutWithSelfMsg);
            
            if(!canCutWithMe)
                illogical(cannotCutWithMsg);
        }
    }
    
    cannotCutMsg = BMsg(cannot cut, '{I} {can\'t} cut {the dobj}. ')
    cannotCutWithMsg = BMsg(cannot cut with, '{I} {can\'t} cut anything with
        {that iobj}. ')
    cannotCutWithSelfMsg = BMsg(cut self, '{I} {cannot} cut anything with
        itself. ')
                     
    
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
        preCond = [objVisible, containerOpen]
        
        remap()
        {
            if(contType != In && remapIn != nil && remapIn.contType == In)
                return remapIn;
            else
                return self;
        }
        
        
        verify()
        {
            if(contType == In)
                logicalRank(120);
            
            if(remapIn != nil)
                logicalRank(120);
            
            logical;
        }
        
        action()
        {
            local obj = remapIn ?? self;
            gMessageParams(obj);
                       
            if(obj.contType == In)
            {
            
                /* 
                 *   If there's anything hidden inside us move it into us before
                 *   doing anything else
                 */
                if(obj.hiddenIn.length > 0)
                {
                    for(local item in obj.hiddenIn)
                        item.moveInto(obj);
                    
                    hiddenIn = [];
                }
                
                if(obj.contents.length == 0)
                    say(obj.lookInMsg);                    
                else
                {
                    obj.unmention(contents);
                    if(gOutStream.watchForOutput(
                        {: obj.listSubcontentsOf(obj, lookInLister) }) == nil)
                      say(obj.lookInMsg);  
                    

                }
            }
            else if(obj.hiddenIn.length > 0)
            {
                obj.findHiddenIn();               
            }            
            else
                say(obj.lookInMsg);
        }
        
    }
    
    
    
    lookInMsg = BMsg(look in, '{I} {see} nothing interesting in {the
        dobj}. ')
    
    
    /* 
     *   If there's something hidden in the dobj but nowhere obvious to move it
     *   to then by default we move everything from the hiddenIn list to the
     *   actor's inventory and announce that the actor has taken it. We call
     *   this out as a separate method to make it easy to override if desired.
     */
    
    findHiddenIn()
    {
        DMsg(find in, 'In {the dobj} {i} {find} {1}<<if findHiddenDest ==
              gActor>>, which {i} {take}<<end>>. ',
             makeListStr(hiddenIn));
        
        foreach(local cur in hiddenIn)
        {
            cur.moveInto(findHiddenDest);
            cur.noteSeen();
        }
        
        hiddenIn = [];
    }
    
    /* 
     *   We can look under most things, but there are some things (houses, the
     *   ground, sunlight) it might not make much sense to try looking under.
     */
    canLookUnderMe = true
    
    
    
    dobjFor(LookUnder)
    {
        preCond = [objVisible, touchObj]
        
        verify()
        {
            if(!canLookUnderMe)
                illogical(cannotLookUnderMsg);       
        }
        
        
        action()
        {            
            local obj = remapUnder ?? self;
            gMessageParams(obj);
                       
            if(obj.contType == Under)
            {
                
                /* 
                 *   If there's anything hidden under us move it into us before
                 *   doing anything else
                 */
                if(obj.hiddenUnder.length > 0)
                {
                    for(local item in obj.hiddenUnder)
                        item.moveInto(obj);
                    
                    obj.hiddenUnder = [];
                }
                
                if(obj.contents.length == 0)
                    say(obj.lookUnderMsg);                
                else
                {
                    obj.unmention(contents);
                    if(gOutStream.watchForOutput(
                        {: obj.listSubcontentsOf(obj, lookInLister) }) == nil)
                        say(obj.lookUnderMsg);  
                    
                }
            }
            else if(obj.hiddenUnder.length > 0)            
                obj.findHiddenUnder();               
            else
                say(obj.lookUnderMsg);           
            
        }
    }
    
    cannotLookUnderMsg = BMsg(cannot look under, '{I} {can\'t} look under {that
        dobj}. ')
    
    lookUnderMsg = BMsg(look under, '{I} {find} nothing of interest under
        {the dobj}. ')
    
     /* 
      *   If there's something hidden under the dobj but nowhere obvious to move
      *   it to then by default we move everything from the hiddenUnder list to
      *   the actor's inventory and announce that the actor has taken it. We
      *   call this out as a separate method to make it easy to override if
      *   desired.
      */
    
    findHiddenUnder()
    {
        DMsg(find under, 'Under {the dobj} {i} {find} {1}<<if findHiddenDest ==
              gActor>>, which {i} {take}<<end>>. ',
             makeListStr(hiddenUnder));
        
        foreach(local cur in hiddenUnder)
        {
            cur.moveInto(findHiddenDest);
            cur.noteSeen();
        }
        
        hiddenUnder = [];
    }
    
    
    /* 
     *   By default we make it possible to look behind things, but there could
     *   be many things it makes no sense to try to look behind.
     */
    
    canLookBehindMe = true    
    
    dobjFor(LookBehind)
    {
        preCond = [objVisible, touchObj]
        
        verify()
        {
            if(!canLookBehindMe)
                illogical(cannotLookBehindMsg);
        }
        
        
        action()
        {
            
            local obj = remapBehind ?? self;
            gMessageParams(obj);
            
            if(obj.contType == Behind)
            {
                
                /* 
                 *   If there's anything hidden under us move it into us before
                 *   doing anything else
                 */
                if(obj.hiddenBehind.length > 0)
                {
                    for(local item in obj.hiddenBehind)
                        item.moveInto(obj);
                    
                    obj.hiddenBehind = [];
                }
                
                if(obj.contents.length == 0)
                    say(obj.lookBehindMsg);                
                else
                {
                    obj.unmention(contents);
                    if(gOutStream.watchForOutput(
                        {: obj.listSubcontentsOf(obj, lookInLister) }) == nil)                        
                        say(obj.lookBehindMsg); 

                }
            }
            else if(obj.hiddenBehind.length > 0)            
                obj.findHiddenBehind();               
            else
                say(obj.lookBehindMsg);           
            
            
        }
    }
    
    cannotLookBehindMsg = BMsg(cannot look behind, '{I} {can\'t} look behind
        {that dobj}. ')
    
    lookBehindMsg = BMsg(look behind, '{I} {find} nothing behind {the
        dobj}. ')
    
    
     /* 
      *   If there's something hidden under the dobj but nowhere obvious to move
      *   it to then by default we move everything from the hiddenUnder list to
      *   the actor's inventory and announce that the actor has taken it. We
      *   call this out as a separate method to make it easy to override if
      *   desired.
      */
    
    findHiddenBehind()
    {
        DMsg(find behind, 'Behind {the dobj} {i} {find} {1}<<if findHiddenDest
              == gActor>>, which {i} {take}<<end>>. ',
             makeListStr(hiddenBehind));
        
        foreach(local cur in hiddenBehind)
        {
            cur.moveInto(findHiddenDest);
            cur.noteSeen();
        }
        
        hiddenBehind = [];
    }
        
        
    
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
        
        action() { say(lookThroughMsg); }
    }
    
    cannotLookThroughMsg = BMsg(cannot look through, '{I} {can\'t} look through
        {that dobj}. ')
    
    lookThroughMsg = BMsg(look through, '{I} {see} nothing through {the
        dobj}. ')
    
    
    /* Most things cannot be gone through */
    canGoThrougMe = nil
    
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
        
    cannotPushMsg = BMsg(cannot push, '{There}{\'s} no point trying to push
        {that dobj}. ')
    
    pushNoEffectMsg = BMsg(push no effect, 'Pushing {1} {dummy} {has} no
        effect. ', gActionListStr)
    
    /* We can at least try to push most things. */
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
    
    cannotPullMsg = BMsg(cannot pull, '{There}{\'s} no point trying to pull
        {that dobj}. ')
    
    pullNoEffectMsg = BMsg(pull no effect, 'Pulling {1} {dummy} {has} no
        effect. ', gActionListStr)
    
    dobjFor(PutOn)
    {
        preCond = [objHeld, objNotWorn]
        
        verify()
        {
            if(gIobj != nil && self == gIobj)
                illogicalSelf(cannotPutInSelfMsg);  
            
            if(isFixed)
                illogical(cannotTakeMsg);
            
            if(gIobj != nil && isDirectlyIn(gIobj))
                illogicalNow(alreadyInMsg);
            
            if(gIobj != nil && gIobj.isIn(self))
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
    
    alreadyInMsg = BMsg(already in, '{The subj dobj} {is} already {in iobj}. ')
    
    circularlyInMsg = BMsg(circularly in, '{I} {can\'t} put {the dobj} {in iobj}
        while {the subj iobj} {is} {in dobj}. ')
        
    cannotPutInSelfMsg = BMsg(cannot put in self, '{I} {can\'t} put anything
        {1} itself. ', gIobj.objInPrep)
    
    iobjFor(PutOn)
    {
        
        preCond = [touchObj]
        
        remap()
        {
            if(contType != On && remapOn != nil)
                return remapOn;
            else
                return self;
        }
        
        
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
            if(gIobj != nil && self == gIobj)
                illogicalSelf(cannotPutInSelfMsg);   
            
            if(isFixed)
                illogical(cannotTakeMsg);
            
            if(gIobj != nil && isDirectlyIn(gIobj))
                illogicalNow(alreadyInMsg);
            
            if(gIobj != nil && gIobj.isIn(self))
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
        preCond = [containerOpen, touchObj]
        
        remap()
        {
            if(contType != In && remapIn != nil)
                return remapIn;
            else
                return self;
        }
        
        verify()
        {
            if(!canPutInMe)
                illogical(cannotPutInMsg);
            
            logical;
        }
        
        check()
        {
            if(contType == In)
               checkInsert(gDobj);
            else if(gDobj.bulk > maxBulkHiddenIn - getBulkHiddenIn)
                DMsg(no room in, 'There {dummy}{isn\'t} enough room for {the
                    dobj} in {the iobj}. ');            
        }
        
        action()
        {
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
            if(gIobj != nil && self == gIobj)
                illogicalSelf(cannotPutInSelfMsg);     
            
            if(isFixed)
                illogical(cannotTakeMsg);
            
            if(gIobj != nil && (isDirectlyIn(gIobj)))
                illogicalNow(alreadyInMsg);
            
            if(gIobj != nil && gIobj.isIn(self))
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
        
        verify()
        {
            if(!canPutUnderMe)
                illogical(cannotPutUnderMsg);
            else
                logical;
        }
        
        check() 
        { 
            if(contType == Under)
               checkInsert(gDobj); 
            else if(gDobj.bulk > maxBulkHiddenUnder - getBulkHiddenUnder)
                DMsg(no room in, 'There {dummy}{isn\'t} enough room for {the
                    dobj} under {the iobj}. ');    
        }
        
        action()
        {
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
            if(gIobj != nil && self == gIobj)
                illogicalSelf(cannotPutInSelfMsg);     
            
            if(isFixed)
                illogical(cannotTakeMsg);
            
            if(gIobj != nil && (isDirectlyIn(gIobj)))
                illogicalNow(alreadyInMsg);
            
            if(gIobj != nil && gIobj.isIn(self))
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
        
        verify()
        {
            if(!canPutBehindMe)
                illogical(cannotPutBehindMsg);
            else
                logical;
        }
        
        check() 
        { 
            if(contType == Behind)
                checkInsert(gDobj);
             else if(gDobj.bulk > maxBulkHiddenBehind - getBulkHiddenBehind)
                DMsg(no room in, 'There {dummy}{isn\'t} enough room for {the
                    dobj} behind {the iobj}. ');    
        }
        
        action()
        {
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
     *   Note: we don't use isLockable, because this is not a binary property;
     *   there are different kings of lockability and defining an isLockable
     *   property in addition would only confuse things and might break the
     *   logic.
     */
    
    dobjFor(UnlockWith)
    {
        
        preCond = [touchObj]
        
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
                    logical;
                else
                    illogicalNow(notLockedMsg);
            }
        }
    }
    
    notLockableMsg = BMsg(not lockable, '{The subj dobj} {isn\'t} lockable. ')
    keyNotNeededMsg = BMsg(key not needed,'{I} {don\'t need} a key to lock and
        unlock {the dobj}. ')
    indirectLockableMsg = BMsg(indirect lockable,'{The dobj} {appears} to use
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
        verify()
        {
            if(!canUnlockWithMe)
               illogical(cannotUnlockWithMsg);
            
            if(gDobj == self)
                illogicalSelf(cannotUnlockWithSelfMsg);
        }      
    }
    
    cannotUnlockWithMsg = BMsg(cannot unlock with, '{I} {can\'t} unlock
        anything with {that dobj}. ' )
    
    cannotUnlockWithSelfMsg = BMsg(cannot unlock with self, '{I} {can\'t} unlock
        anything with itself. ' )
    
    dobjFor(LockWith)
    {
        preCond  = [objClosed, touchObj]
        
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
        verify()
        {
            if(!canLockWithMe)
               illogical(cannotLockWithMsg);
            
            if(gDobj == self)
                illogicalSelf(cannotLockWithSelfMsg);
        }      
    }
    
    cannotLockWithMsg = BMsg(cannot lock with, '{I} {can\'t} lock anything with
        {that dobj}. ' )
    
    cannotLockWithSelfMsg = BMsg(cannot lock with self, '{I} {can\'t} lock
        anything with itself. ' )
    
    
    dobjFor(Unlock)
    {
        preCond = [touchObj]
        
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
            {
                findPlausibleKey();                
            }
               
        }
        
        action()
        {
            if(useKey_ != nil)
                extraReport(withKeyMsg);
            else if(lockability == lockableWithKey)
                askForIobj(UnlockWith);
            
            makeLocked(nil);               
        }
        
        report()
        {
            DMsg(report unlock, okayUnlockMsg, gActionListStr);
        }
        
    }
    
    okayUnlockMsg = 'Unlocked.|{I} {unlock} {1}. '
    
    dobjFor(Lock)
    {
        preCond = [objClosed, touchObj]
        
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
             *   if we need a key to be unlocked with, check whether the player
             *   is holding a suitable one.
             */
            if(lockability == lockableWithKey)
            {
                findPlausibleKey();                
            }
               
        }
        
        action()
        {
            if(useKey_ != nil)
                extraReport(withKeyMsg);
            else if(lockability == lockableWithKey)
                askForIobj(LockWith);
         
            makeLocked(true);              
        }
        
        report()
        {
            DMsg(report lock, okayLockMsg, gActionListStr);
        }
    }
    
    
    
    
    okayLockMsg = 'Locked.|{I} {lock} {1}. '
    
    withKeyMsg = BMsg(with key, '(with {1})\n', useKey_.theName)
    
    findPlausibleKey()
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
        if(useKey_ && useKey_.actualLockList.indexOf(lockObj) == nil)
        {
            DMsg(with key, '(with {1})\n', useKey_.theName);
            say(keyDoesntWorkMsg);            
        }
        
    }
  
    
    keyDoesntWorkMsg = BMsg(key doesnt work, 'Unfortunately {1} {dummy}
        {doesn\'t work} on {the dobj}. ', useKey_.theName)
    
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
            DMsg(report turn on, 'Done.|{I} {turn} on {the dobj}. ');
        } 
    }
    
    notSwitchableMsg = BMsg(not switchable, '{The subj dobj} {can\'t} be
        switched on and off. ')
    alreadyOnMsg = Msg(already switched on, '{The subj dobj} {is} already
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
            DMsg(report turn off, 'Done.|{I} {turn} off {the dobj}. ');
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
            DMsg(report switch, 'Okay, you turn {1} {the dobj}. ', isOn ? 'on' :
                 'off');
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
        
        action()  {  makeWorn(true);  }
        
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
        preCond = [objHeld]
        
        verify()
        {
            if(!isThrowable)
                illogical(cannotThrowMsg);
        }
        
        action()
        {
            moveInto(getOutermostRoom);            
        }
        
        report()
        {
            local obj = gActionListObj;
            gMessageParams(obj);
            DMsg(throw, '{The subj obj} {sails} through the air and {lands}
                on the ground. ' );
        }
        
    }
    
    
    dobjFor(Board)
    {
        preCond = [touchObj]
        
        remap = remapOn
        
        verify()
        {
            if(!isBoardable || contType != On)
                illogical(cannotBoardMsg);
            
            if(gActor.isIn(self))
                illogicalNow(actorAlreadyOnMsg);
            
            if(isIn(gActor))
                illogicalNow(cannotGetOnCarriedMsg);
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
            if(gActor.isIn(self))
                illogicalNow(actorAlreadyOnMsg);
            logicalRank(standOnScore);
        }
    }
    
    dobjFor(SitOn)
    {
        verify()
        {
            if(!canSitOnMe)
                illogical(cannotSitOnMsg);
            if(gActor.isIn(self))
                illogicalNow(actorAlreadyOnMsg);
            logicalRank(sitOnScore);
        }
    }
    
    dobjFor(LieOn)
    {
        verify()
        {
            if(!canLieOnMe)
                illogical(cannotLieOnMsg);
            if(gActor.isIn(self))
                illogicalNow(actorAlreadyOnMsg);
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
        preCond = [touchObj, containerOpen]
        
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
    actorAlreadyInMsg = BMsg(already in, '{I}{\'m} already {in dobj}. ')
     
    cannotGetInCarriedMsg = BMsg(cannot enter carried, '{I} {can\'t} get in {the
        dobj} while {i}{\'m} carrying {him dobj}. ')
    
    
    dobjFor(StandIn) asDobjFor(Enter)
    dobjFor(SitIn) asDobjFor(Enter)
    dobjFor(LieIn) asDobjFor(Enter)
    
    
    exitLocation = (lexicalParent == nil ? location : lexicalParent.location)
    
    dobjFor(GetOff)
    {
        
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
        preCond = [containerOpen]
        
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
    
    dobjFor(Search) asDobjFor(LookIn)
    
    /* By default we assume anything fixed isn't moveable */
    isMoveable = (!isFixed)
    
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
            DMsg(move no effect, 'Moving {1} {dummy} {has} no effect. ',
                 gActionListStr);
        }
    }
    
    cannotMoveMsg = (cannotTakeMsg)
    
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
            DMsg(move no effect, 'Moving {1} {dummy} {has} no effect. ',
                 gActionListStr);
        }
    }
    
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
            
            if(gDobj == self)
                illogicalSelf(cannotMoveWithSelfMsg);
        }
    }
    
    cannotMoveWithMsg = BMsg(cannot move with, '{I} {can\'t} move {the dobj}
        with {the iobj}. ')
    
    cannotMoveWithSelfMsg = BMsg(cannot move with self, '{The subj dobj}
        {can\'t} be used to move {itself dobj}. ')
    
    dobjFor(MoveTo)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isMoveable)
                illogical(cannotMoveMsg);
        }
        
        action()
        {
            makeMovedTo(gIobj);
        }
        
        report()
        {
            DMsg(move no effect, 'Moving {1} {dummy} {has} no effect. ',
                 gActionListStr);
        }
    }
    
    /* 
     *   The notional location (other object) this object has been moved to as
     *   the result of a MoveTo command.
     */
    movedTo = nil
    
    makeMovedTo(loc) { movedTo = loc; }
    
    /* In general there's no reason why most objects can't be moved to. */
    canMoveToMe = true
    
    iobjFor(MoveTo)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!canMoveToMe)
                illogical(cannotMoveToMsg);
            
            if(gDobj == self)
                illogicalSelf(cannotMoveToSelfMsg);
            
            if(gDobj.movedTo == self)
                illogicalNow(alreadyMovedToMsg);
            
        }
        
    }
    
    cannotMoveToMsg = BMsg(cannot move to, '{The subj dobj} {can\'t} be moved to
        {the iobj}. ')
    
    cannotMoveToSelfMsg = BMsg(cannot move to self, '{The subj dobj} {can\'t}
        be moved to {itself dobj}. ')
    
    alreadyMovedToMsg = BMsg(already moved to, '{The subj dobj} {has} already
        been moved to {the iobj}. ')
    
    
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
     *   cleaning in practice
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
            
            else if(mustBeCleanedWith != nil)
                implausible(cleanWithObjNeededMsg);
        }
        
        
        action() { makeCleaned(true); }
        
        report()
        {
            DMsg(okay clean, 'Cleaned|{I} {clean} {1}. ', gActionListStr);
        }
    }
    
    makeCleaned(stat) { isClean = stat; }
    
    cannotCleanMsg = BMsg(cannot clean, '{The subj dobj} {is} not something {i}
        {can} clean. ')
    
    alreadyCleanMsg = BMsg(already clean, '{The subj dobj} {is} already quite
        clean enough. ')
    
    noNeedToCleanMsg = BMsg(no clean, '{The subj dobj} {doesn\'t need} cleaning.
        ')
    
    cleanWithObjNeededMsg = BMsg(clean with obj needed, '{I} {need} something to
        clean {it dobj} with. ')
    
    dontNeedCleaningObjMsg = BMsg(dont need cleaning obj, '{I} {don\'t need}
        anything to clean {the dobj} with. ')
    
    
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
            else if(valToList(mustBeCleanedWith).indexOf(gIobj) == nil)
                implausible(cannotCleanWithMsg);
        }
        
        
        action() { makeCleaned(true); }
        
        report()
        {
            DMsg(okay clean, 'Cleaned|{I} {clean} {1}. ', gActionListStr);
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
        
        action() { askForIobj(DigWith); }
    }
    
    /* Most objects aren't suitable digging instruments */
    canDigWithMe = nil
    
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
            
            if(gDobj == self)
                illogicalSelf(cannotDigWithSelfMsg);
        }
    }
    
    cannotDigMsg = BMsg(cannot dig, '{I} {can\'t} dig there. ')
    cannotDigWithMsg = BMsg(cannot dig with, '{I} {can\'t} dig anything with
        {that iobj}. ')
    cannotDigWithSelfMsg = BMsg(cannot dig with self, '{I} {can\'t} dig {the
        dobj} with {itself dobj}. ')
    
        
    dobjFor(TakeFrom) asDobjWithoutVerifyFor(Take)
    
    dobjFor(TakeFrom)
    {           
        verify()
        {
            if(!isTakeable)
                illogical(cannotTakeMsg);
            
            if(gIobj.notionalContents.indexOf(self) == nil)
                illogicalNow(notInMsg);
            if(self == gIobj)
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
    
    notInMsg = BMsg(not inside, '{The dobj} {is}n\'t {in iobj}. ')
    cannotTakeFromSelfMsg =  BMsg(cannot take from self, '{I} {can\'t} take
        {the subj dobj} from {the dobj}. ')
    
        
    dobjFor(ThrowAt)
    {
        preCond = [objHeld]
        
        verify() { verifyDobjThrow(); }
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
            gDobj.moveInto(getOutermostRoom);
        }
        
        report()
        {
            local obj = gActionListObj;
            gMessageParams(obj);
            DMsg(throw at, '{The subj obj} {strikes} {the iobj} and {lands}
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
        preCond = [objHeld]
        
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
            
            if(gDobj == self)
                illogical(cannotThrowToSelfMsg);
        } 
        
    }
    
    cannotThrowToMsg = BMsg(cannot throw to, '{The subj dobj} {can\'t} catch
        anything. ')
    
    cannotThrowToSelfMsg = BMsg(cannot throw at self, '{The subj dobj} {can\'t}
        be thrown to {itself dobj}. ')
    
    throwFallsShortMsg = BMsg(throw falls short, '{The subj dobj} {lands} far
        short of {the iobj}. ')
    
    canTurnMeTo = nil
    
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
            DMsg(okay turn to, 'Okay, {I} {turn} {1} to {2}', gActionListStr, 
                 gLiteral);
        }
    }
    
    /* 
     *   If the setting is valid, do nothing. If it's invalid display a message
     *   explaining why.
     */
    
    checkSetting(val) { }
    
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
            DMsg(okay set to, 'Okay, {i} {set} {1} to {2}', gActionListStr, 
                 gLiteral); 
        }
    }
       
    makeSetting(val) { curSetting = val; }
    
    cannotSetToMsg = BMsg(cannot set to, '{I} {cannot} set {that dobj} to
        anything. ')
    
    dobjFor(GoTo)
    {
        verify()
        {
            if(gActor.isIn(self))
                illogicalNow(alreadyThereMsg);
            
            if(isIn(gActor.getOutermostRoom))
                illogicalNow(alreadyPresentMsg);
            
            if(isDecoration)
                logicalRank(90);
        }
        
        action()
        {
            local route = defined(pcRouteFinder) && lastSeenAt != nil 
                ? pcRouteFinder.findPath(
                gActor.getOutermostRoom, lastSeenAt.getOutermostRoom) : nil;
            
            if(route == nil)
                DMsg(route unknown, '{I} {don\'t know} how to get there. ');
            else if(route.length == 1)
                DMsg(destination unknown, '{I} {don\'t know} how to reach
                    {him dobj}.' );
            else
            {
                local dir = route[2][1];
                Continue.takeStep(dir, getOutermostRoom);               
            }
        }
    }
    
    alreadyThereMsg = BMsg(already there, '{I}{\'m} already there. ')
    alreadyPresentMsg = BMsg(already present, '{The subj dobj} {is} right
        {here}. ')    
    
    
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
            
            if(gDobj == self)
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
            
            if(gIobj == self)
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
    
    
    /* Fasten by itself presumably refers to objects like seat-belts */
    
    isFastenable = nil
    isFastened = nil
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
            DMsg(okay fasten, 'Done|{I} {fasten} {1}. ', gActionListStr);
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
            
            if(gDobj == self)
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
        }
    }
    
    
    dobjFor(UnfastenFrom)
    {
        preCond = [touchObj]
        verify() 
        {
            if(!isUnfastenable)
               illogical(cannotUnfastenMsg); 
            
            if(gIobj == self)
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

    
    isPlugable = nil
    canPlugIntoMe = nil
    
    dobjFor(PlugInto)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!isPlugable)
                illogical(cannotPlugMsg);
            
            if(self == gIobj)
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
            
            if(gIobj == self)
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
    
    dobjFor(Kiss)
    {
        preCond = [touchObj]
        /* if we create an actor class it'll be more logical to kiss actors */
        verify() 
        { 
            if(!isKissable)
                illogical(cannotKissMsg);
                
            logicalRank(80); 
        }
        
        report()
        {
            DMsg(kiss, 'Kissing {1} {dummy}{proves} remarkably unrewarding. ',
                 gActionListStr); 
        }
    }
    
    cannotKissMsg = BMsg(cannot kiss, '{I} really {can\'t} kiss {that dobj}. ')

    
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
            gActor.actionMoveInto(location);
        }
        
        report()
        {
            DMsg(jump off, '{I} {jump} off {1} and {land} on the ground', 
                 gActionListStr);
        }
    }
    
    cannotJumpOffMsg = BMsg(cannot jump off, '{I}{\'m} not on {the dobj}. ')
    
    
    canJumpOverMe = nil
    
    dobjFor(JumpOver)
    {
        preCond = [touchObj]
        
        verify()
        {
            if(!canJumpOverMe)
               illogical(cannotJumpOverMsg); 
        }
    }
    
    cannotJumpOverMsg = BMsg(pointless to jump over, 'It {dummy}{is}
        pointless to try to jump over {the dobj}. ')
    
    isSettable = nil
    
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
    
    
    canTypeOnMe = nil
    
    dobjFor(TypeOnVague)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canTypeOnMe)
               illogical(cannotTypeOnMsg); 
        }
    }
    
    dobjFor(TypeOn)
    {
        preCond = [touchObj]
        verify() 
        { 
            if(!canTypeOnMe)
               illogical(cannotTypeOnMsg); 
        }
    }
    
    cannotTypeOnMsg = BMsg(cannot type on, '{I} {can\'t} type anything on {the
        dobj}. ')
    
    canEnterOnMe = nil
    
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
    
    
    canWriteOnMe = nil
    
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
    
    
    isConsultable = nil
    
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
    
    isPourable = nil
    
    
    /* 
     *   Sometimes we may have a container, such as an oilcan, from which we
     *   want to pour a liquid, such as oil, and we're using the same object to
     *   do duty for both. We can then use the fluidName property to say 'the
     *   oil' rather than 'the oilcan' in messages that refer specifically to
     *   pouring the liquid.
     */
    fluidName = theName
    
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
     *   though we might want to prevent it in practice.
     */
    
    canPourOntoMe = true
    allowPourOntoMe = nil
    
    
    
    iobjFor(PourOnto)
    {
        preCond = [touchObj]
        
        remap = (remapOn)
        
        verify()
        {
            if(gDobj == self)
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
            if(gDobj == self)
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
    cannotPourIntoMsg = BMsg(cannot pour into, '{I} {can\'t} pour {1)
        into {that dobj}. ', gDobj.fluidName)
    cannotPourOntoMsg = BMsg(cannot pour onto, '{I} {can\'t} pour {1}
        into {that dobj}. ', gDobj.fluidName)
    shouldNotPourIntoMsg = BMsg(should not pour into, 'It{dummy}{\'s} better not
        to pour {1} into {the iobj}. ', gDobj.fluidName)
    
    shouldNotPourOntoMsg = BMsg(cannot pour onto, 'It{dummy}{\'s} better not
        to pour {1} onto {the iobj}. ', gDobj.fluidName)  
    
    
    isScrewable = nil
    canScrewWithMe = nil
    
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
            
            if(gDobj == self)
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
            
            if(gDobj == self)
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
    
    
    
    verifyPushTravel(via)
    {
        viaMode = via;
        
        if(!canPushTravel)
            illogical(cannotPushTravelMsg);
        
        if(gActor.isIn(self))
            illogicalNow(cannotPushOwnContainerMsg);
        
        if(gIobj == self)
            illogicalSelf(cannotPushViaSelfMsg);
    }
        
    viaMode = ''
    
    cannotPushOwnContainerMsg = BMsg(cannot push own container, '{I} {can\'t}
        push {the dobj} anywhere while {he actor}{\'s} {1} {him dobj}. ',
                                     gDobj.objInPrep)
    
    cannotPushViaSelfMsg = BMsg(cannot push via self, '{I} {can\'t} push {the
        dobj} {1} {itself dobj}. ', viaMode.prep)
    
    canPushTravel = nil
    
    dobjFor(PushTravelDir)
    {
        preCond = [touchObj]
        
        verify()  {  verifyPushTravel('');  }
        
        
        action()
        {
            gAction.travelAllowed = true;
            
            pushTravelRevealItems();            
        }
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
         *   report of them now, before moving to another location./
         */
        
        gCommand.afterReport();
        
        /* 
         *   We don't want to see these reports again at the end of the action,
         *   so clear the list.
         */
        gCommand.afterReports = [];   
    }
    
    
    
   
      
    cannotPushTravelMsg()
    {
        if(isFixed)
            return cannotTakeMsg;
        return BMsg(cannot push travel, 'There{dummy}{\'s} no point trying to
            push {that dobj} anywhere. ');
    }
    
    /* Check the travel barriers on the indirect object of the action */
    checkPushTravel()
    {
        checkTravelBarriers(gDobj);
        checkTravelBarriers(gActor);
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
                        
        gIobj.travelVia(gDobj);
        
        /* 
         *   The travel of the object being pushed might fail, e.g. if we're
         *   trying to push it through a locked door, so we only complete the
         *   travel and report on it if the object being pushed arrives at its
         *   destination.
         */
        if(location == gIobj.destination)
        {
            DMsg(push travel somewhere, '{I} {push} {the dobj} {1} {the iobj}. ',
                 via.prep);        
            gIobj.travelVia(gActor);
        }       
        
    }
    
    dobjFor(PushTravelThrough)    
    {
        preCond = [touchObj]
        verify()   {   verifyPushTravel(Through);   }
        
        action() { doPushTravel(Through); }
    }
    
    iobjFor(PushTravelThrough)
    {
        preCond = [touchObj]
        verify() 
        {  
            if(!canGoThroughMe || destination == nil)
                illogical(cannotPushThroughMsg);
        }
        
        check() { checkPushTravel(); }
                
        
    }
    
    cannotPushThroughMsg = BMsg(cannot push through, '{I} {can\'t} {push}
        anything through {the iobj}. ')
    
    
    dobjFor(PushTravelEnter)
    {
        preCond = [touchObj]
        verify()  {  verifyPushTravel(Into);  }        
        
    }
    
    okayPushIntoMsg = BMsg(okay push into, '{I} {push} {the dobj} into {the
        iobj}. ')
    
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
    
    cannotPushIntoMsg = BMsg(cannot push into, '{I} {can\'t} {push}
        anything into {the iobj}. ')
    
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
    
    okayPushOutOfMsg = BMsg(okay push out of, '{I} {push} {the dobj} {outof
        iobj}. ')
    
    dobjFor(PushTravelClimbUp)
    {
        preCond = [touchObj]
        verify()  {  verifyPushTravel(Up);  }
        
        action() { doPushTravel(Up); }
    }
    
    iobjFor(PushTravelClimbUp)
    {
        preCond = [touchObj]
        
        verify() 
        {  
            if(!isClimbable || destination == nil)
                illogical(cannotPushUpMsg);
        }
        
        check() { checkPushTravel(); }
    }
    
    cannotPushUpMsg = BMsg(cannot push up, '{I} {can\'t} {push}
        anything up {the iobj}. ')
    
    dobjFor(PushTravelClimbDown)
    {
        preCond = [touchObj]
        verify()  { verifyPushTravel(Down);  }
        
        action() { doPushTravel(Down); }
    }
    
    iobjFor(PushTravelClimbDown)
    {
        preCond = [touchObj]
        
        verify() 
        {  
            if(!canClimbDownMe || destination == nil)
                illogical(cannotPushDownMsg);
        }
        
        check() { checkPushTravel(); }
    }
    
    cannotPushDownMsg = BMsg(cannot push down, '{I} {can\'t} {push}
        anything down {the iobj}. ')
    
    /* 
     *   We don't bother to define isAskable etc. properties since we assume
     *   that no inanimate object can be conversed with, and that game code will
     *   use the Actor class to allow conversation. In any case since there's
     *   never any difficult in talking about oneself, the various illogicalSelf
     *   checks aren't needed.
     */
    
    dobjFor(AskAbout)
    {
        preCond = [objAudible]
        verify() { illogical(cannotTalkToMsg); }
    }
    
    dobjFor(AskFor)
    {
        preCond = [objAudible]
        verify() { illogical(cannotTalkToMsg); }
    }
    
    
    dobjFor(TellAbout)
    {
        preCond = [objAudible]
        verify() { illogical(cannotTalkToMsg); }
    }
    
        
    dobjFor(SayTo)
    {
        preCond = [objAudible]
        verify() { illogical(cannotTalkToMsg); }
    }
    
    dobjFor(QueryAbout)
    {
        preCond = [objAudible]
        verify() { illogical(cannotTalkToMsg); }
    }
    
    dobjFor(TalkAbout)
    {
        preCond = [objAudible]
        verify() { illogical(cannotTalkToMsg); }
    }
    
    dobjFor(TalkTo)
    {
        preCond = [objAudible]
        verify() { illogical(cannotTalkToMsg); }
    }
    
    cannotTalkToMsg = BMsg(cannot talk, 'There{dummy}{\'s} no point trying to
        talk to {the cobj}. ')
    
    dobjFor(GiveTo)
    {
        preCond = [objHeld]
        verify()
        {
            if(isIn(gIobj))
                illogical(alreadyHasMsg);
        }
    
    }
    
    alreadyHasMsg = BMsg(already has, '{The subj iobj} already {has}
        {the dobj}.')
    
    iobjFor(GiveTo)
    {
        preCond = [touchObj]
        verify() { illogical(cannotGiveToMsg); }
        report()
        {
            if(gAction.giveReport != nil)
                dmsg(gAction.giveReport, gActionListStr);
        }
    }
    
    cannotGiveToMsg = BMsg(cannot give to, '{I} {can\'t} give anything to {that
        iobj}. ')
    
    dobjFor(ShowTo)
    {
        preCond = isFixed ? [objVisible] : [objHeld]  
        report()
        {
            if(gAction.giveReport != nil)
                dmsg(gAction.giveReport, gActionListStr);
        }
    }
    
    iobjFor(ShowTo)
    {
        preCond = [touchObj]
        verify() { illogical(cannotShowToMsg); }
    }
    
    cannotShowToMsg = BMsg(cannot show to, '{I} {can\'t} show anything to {that
        iobj}. ')
    
    
    dobjFor(ShowToImplicit)
    {
        preCond = isFixed ? [objVisible] : [objHeld]
        
        verify() 
        {
            if(gPlayerChar.currentInterlocutor == nil)
                illogical(notTalkingToAnyoneMsg);
            else if(!Q.canTalkTo(gPlayerChar, gPlayerChar.currentInterlocutor))
                illogicalNow(noLongerTalkingToAnyoneMsg);            
            
        }
        
        action()
        {
            gPlayerChar.currentInterlocutor.handleTopic(&showTopics, [self]);
        }
    }
    
    dobjFor(GiveToImplicit)
    {
        preCond = [objHeld]
        
        verify() 
        {
            if(gPlayerChar.currentInterlocutor == nil)
                illogical(notTalkingToAnyoneMsg);
            else if(!Q.canTalkTo(gPlayerChar, gPlayerChar.currentInterlocutor))
                illogicalNow(noLongerTalkingToAnyoneMsg);            
            
        }
        
        action()
        {
             gPlayerChar.currentInterlocutor.handleTopic(&giveTopics, [self]);
        }
    }
    
    notTalkingToAnyoneMsg = BMsg(not talking to anyone, '{I}{\'m} not talking to
        anyone. ')
    
    noLongerTalkingToAnyoneMsg = BMsg(no longer talking to anyone, '{I}{\'m} no
        longer talking to anyone. ')
    
 #ifdef __DEBUG
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
            moveInto(gActor);
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
        foreach(local cur in gPlayerChar.contents)
            gSetKnown(cur);
    }
    
    execBeforeMe = [pronounPreinit]
;


class Key: Thing
    actualLockList = []
    plausibleLockList = []
    knownLockList = []
    
    isPossibleKeyFor(obj)
    {
        if(obj.lexicalParent != nil && obj.lexicalParent.remapIn == obj
           &&(knownLockList.indexOf(obj.lexicalParent) != nil
              || plausibleLockList.indexOf(obj.lexicalParent) != nil))
            return true;
        
        return knownLockList.indexOf(obj) != nil ||
            plausibleLockList.indexOf(obj) != nil;
    }
    
    canUnlockWithMe = true
    
    iobjFor(UnlockWith)
    {
        preCond = [objHeld]
        
               
        verify()
        {
            inherited;
            
            if(isPossibleKeyFor(gDobj))
                logical;
            else
                implausible(notAPlausibleKeyMsg);            
        }
        
        check()
        {
            if(actualLockList.indexOf(gDobj) == nil
               && (gDobj.lexicalParent == nil
               || gDobj.lexicalParent.remapIn != gDobj
               || actualLockList.indexOf(gDobj.lexicalParent) == nil))
                say(keyDoesntFitMsg);              
        }
        
        action()
        {
            gDobj.makeLocked(nil);
            if(knownLockList.indexOf(gDobj) == nil)
                knownLockList += gDobj;
        }
        
        report()
        {
            DMsg(okay unlock with, okayUnlockWithMsg, gActionListStr);
        }
        
    }
    
    okayUnlockWithMsg = '{I} {unlock} {the dobj} with {the iobj}. '
    
    iobjFor(LockWith)
    {
        preCond = [objHeld]
        
        verify()
        {
            inherited;
            
            if(isPossibleKeyFor(gDobj))
                logical;
            else
                implausible(notAPlausibleKeyMsg);            
        }
        
        check()
        {
             if(actualLockList.indexOf(gDobj) == nil
               && (gDobj.lexicalParent == nil
               || gDobj.lexicalParent.remapIn != gDobj
               || actualLockList.indexOf(gDobj.lexicalParent) == nil))
                say(keyDoesntFitMsg);              
        }
        
        action()
        {
            gDobj.makeLocked(true);
            if(knownLockList.indexOf(gDobj) == nil)
                knownLockList += gDobj;
        }
        
        report()
        {
             DMsg(okay lock with, okayLockWithMsg, gActionListStr);
        }
    }
    
    
    okayLockWithMsg = '{I} {lock} {the dobj} with {the iobj}. '
    
    notAPlausibleKeyMsg = '\^<<theName>> clearly won\'t work on <<gDobj.theName>>. '
    
    keyDoesntFitMsg = '\^<<theName>> won\'t fit <<gDobj.theName>>. '
    
    
   
    
;

class SubComponent: Thing
    
    isFixed = true
    preinitThing()
    {
        initializeSubComponent(lexicalParent);
        origVocab = vocab;
        inherited;
    }
    
    initializeSubComponent(parent)
    {
        if(parent == nil)
            return;
        
        location = parent;
        name = parent.name;
        
        if(parent.remapIn == self)
            contType = In;
        
        if(parent.remapOn == self)
            contType = On;
        
        if(parent.remapUnder == self)
            contType = Under;
        
        if(parent.remapBehind == self)
            contType = Behind;
        
        if(contType != nil)
            listOrder = contType.listOrder;
    }
    
    makeOpen(stat)
    {
        inherited(stat);
        
        /* 
         *   If we close this item when the playerChar is inside it, the player
         *   will need to be able to refer to it with the vocab of its
         *   lexicalParent
         */
        if(lexicalParent != nil && gPlayerChar.isIn(self))
        {
            if(stat)
            {
                replaceVocab(origVocab);
                name = lexicalParent.name;
            }
            else
                addVocab(lexicalParent.vocab);
        }
    }
    
    origVocab = nil
    
;

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
     *   region
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
        if(initialLocationList.length == 0)
        {
            initialLocationList = locationList;
            locationList = [];               
        }
        
        local locationVec = new Vector(10);
        
        foreach(local loc in valToList(initialLocationList))
        {           
            loc.addToContents(self, locationVec);             
        }
        
        if(initialLocationClass != nil)
        {
            for(local obj = firstObj(initialLocationClass); obj != nil; obj =
                nextObj(obj, initialLocationClass))   
            {
                if(isInitiallyIn(obj))
                    obj.addToContents(self, locationVec);
            }
        }
        
        foreach(local loc in valToList(exceptions))            
        {
            loc.removeFromContents(self, locationVec); 
        }
        
        locationList = locationVec.toList();
    }
      
    /* 
     *   Move this MultiLoc into an additional location by adding it to that
     *   location's contents list and adding that location to our locationList.
     */  
    
    moveIntoAdd(loc)
    {
        if(loc.contents.indexOf(self) == nil)
            loc.addToContents(self);     
        
        
        if(locationList.indexOf(loc) == nil)
            locationList += loc;
    }
    
    /* 
     *   Remove this MultiLoc from location by removing it from that location's
     *   contents list and removing that locationg from our locationList.
     */ 
    
    
    moveOutOf(loc)
    {
        loc.removeFromContents(self);  
        locationList -= loc;
        
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
     *   object's contents list
     */
    
    isDirectlyIn(loc)
    {
        if(loc != nil)
            return loc.contents.indexOf(self) != nil;
        
        return locationList == [];
    }
    
    /* 
     *   A MultiLoc is in another object either if it's directly in that object
     *   or if one of the items in its location list is in that object.
     */
    
    isIn(loc)
    {
        return isDirectlyIn(loc) || locationList.indexWhich({x: x.isIn(loc)}) !=
            nil;    
    }
    
    
    
    /* 
     *   For certain purposes, such as sense path calculations, a Multiloc needs
     *   a notional location. We assume the enquiry is made from the perspective
     *   of the current actor, or, failing that, the player char.
     */
    
    location()
    {
        local rm = gActor == nil ? gPlayerChar.getOutermostRoom :
        gActor.getOutermostRoom;
        local loc;
        
        /* First see if we're directly in the actor's enclosing room. */
        
        if(isDirectlyIn(rm))
            return rm;
        
        /* 
         *   If that doesn't work, check if anything in our location list is in
         *   the actor's room; if so, use that.
         */
        
        loc = locationList.valWhich({x: x.isIn(loc)});
        
        if(loc != nil)
            return loc;
        
        /* if all else fails, return the location we were last seen at */
        
        return lastSeenAt;
        
    }   
;

class Floor: MultiLoc, Decoration
    initialLocationClass = Room
    contType = On
    isInitiallyIn(obj) { return obj.floorObj == self; }
    
    /* 
     *   The Floor object needs to appear to share the contents of the player
     *   character's room (or other enclosing container) for certain purposes
     *   (such as disambiguating by container or the TakeFrom command), but
     *   nothing is really moved into or out of a Floor).
     */
    contents = (gActor.outermostVisibleParent().contents - self)
    
    decorationActions = [Examine, TakeFrom]
    
    
    /* 
     *   By default we probably want to keep the description of a Floor object
     *   as minimalistic as possible to discourage players from trying to
     *   interact with it, so we won't listed the 'contents' of a Floor when
     *   it's examined. This can of course be overridden if desired.
     */
    
    contentsListed = nil
        
;

defaultGround: Floor
;

multiLocInitiator: PreinitObject
    execute()
    {
        for(local cur = firstObj(MultiLoc); cur !=nil ; cur = nextObj(cur,
            MultiLoc))
            
            cur.addToLocations();
    }
    execBeforeMe = [regionPreinit]
;


class Topic: Mentionable
    construct(name_)
    {        
        vocab = name_;
        initVocab();
    }
    
    /*
     *   Whether the player character knows of the existence of this topic, if
     *   By default we assume this is true.
     */
    
    familiar = true
    
    /* 
     *   Properties to set and test whether a topic is known about
     *   
     */
        
    
    setKnown() { gPlayerChar(setKnowsAbout(self)); }
    known = (gPlayerChar.knowsAbout(self)) 
    
    getTopicText()
    {
        return name == nil ? vocab : name;
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

Carrier: ExtLocType
;


class ViaType: object
    prep = ''
;

Into: ViaType;
OutOf: ViaType;
Down: ViaType;
Up: ViaType;
Through: ViaType;

    