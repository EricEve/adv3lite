#charset "us-ascii"
#include "advlite.h"

/*
 *   The main English language module.
 *   
 *   This is the English implementation of the generic language interfaces.
 *   All of the code here is English-specific, so other language modules
 *   will replace the actual implementation.  However, somef of the methods
 *   and properties are part of the generic interface - this means that
 *   each language module must define methods and properties with these
 *   names, and with the abstract behavior described.  How they actually
 *   implement the behavior is up to them.
 *   
 *   Methods and properties that are part of the generic interface are
 *   identified with [Required].  
 */

/* ------------------------------------------------------------------------ */
/*
 *   English module options. 
 */
englishOptions: object
    /* decimal point character */
    decimalPt = '.'

    /* group separator in large numbers */
    numGroupMark = ','
;


/* ------------------------------------------------------------------------ */
/*
 *   LMentionable is the language-specific base class for Mentionable.
 *   
 *   This is the root class for objects that the player can mention in
 *   commands.  The key feature of these objects is that they can match
 *   noun phrases in command input.  The library subclasses this base class
 *   with Mentionable.  This class provides the part of the class that
 *   varies by language.  
 *   
 *   [Required] 
 */
class LMentionable: object
    /*
     *   Get the indefinite form of the name, nominative case.
     *   
     *   [Required] 
     */
    aName = (ifPronoun(&name, aNameFrom(name)))

    /*
     *   Get the definite form of the name, nominative case.
     *   
     *   [Required] 
     */
    theName = (ifPronoun(&name, theNameFrom(name)))

    /* Definite name, objective case. */
    theObjName = (ifPronoun(&objName, theNameFrom(name)))

    /*
     *   Get the objective form of the name.  The regular 'name' property
     *   gives the subjective form - i.e., the form that appears as the
     *   subject of a verb.  'objName' gives the form that appears as a
     *   direct or indirect object.  Unlike many languages, English doesn't
     *   further distinguish cases for the different roles of verb objects;
     *   they're all just "objective".  English also doesn't inflect
     *   regular nouns at all for these two cases - the objective form of
     *   "book" or "key" or "widget" is identical to the subjective form.
     *   The only place where case makes a difference in English is
     *   pronouns: "I" and "me", "he" and "him", etc.  So, this routine
     *   simply returns the subjective name string by default, which will
     *   work for any object with a regular noun as its name.  Generally,
     *   this will only need to be overridden for the player character
     *   object, which usually uses a pronoun as its name ("you" for a
     *   second-person game, "I" for a first-person game).  
     */
    objName = (name)

    /*
     *   Get the possessive adjective-like form of the name.  This is the form of the name we use as
     *   a qualifier phrase when showing an object we possess.  The English rule for ordinary nouns
     *   is just to add apostrophe-s to the name: "Bob" becomes "Bob's", "Orc guard" becomes "Orc
     *   guard's".  This works for nearly all nouns in English, but you can override this if the
     *   rule produces the wrong result for a particular name. But if the noun is plural and its
     *   name ends with an 's' we should just add an apostrophe - so we do this via the possEnding
     *   property.
     *
     *   However, it does vary for pronouns.  By default, we check the name to see if it's a
     *   pronoun, and apply the correct pronoun mapping if so.
     */
    possAdj = (ifPronoun(&possAdj, '<<theName>><<possEnding>>'))

    /*
     *   Get the possessive noun-like form of the name.  This is the form
     *   of the possessive we use in a genetive "of" phrase or a "being"
     *   predicate, such as "that's a book of Bob's" or "that book is
     *   Bob's".  In English, this is almost always identical to the
     *   possessive adjective form for a regular noun - it's just the same
     *   apostrophe-s word as the adjective form.
     *   
     *   However, it diverges for some of the pronouns: "my" vs "mine",
     *   "her" vs "hers", "their" vs "theirs", "our" vs "ours".  We check
     *   the name to see if it's a pronoun, and apply the appropriate
     *   pronoun mapping if so.  
     */
    possNoun = (ifPronoun(&possNoun, '<<theName>><<possEnding>>'))
    
    /*  
     *   The correct ending for our possessive form. This is usually apostrophe-s for an English
     *   noun, except where the noun is plural and ends with an 's', which case we just want an
     *   apostrophe; for example "the clerks' lunch" but "the women's dinner".
     */     
    possEnding = (theName.endsWith('s') && plural ? '&rsquo;' : '&rsquo;s')
     
    /* The subjective-case pronoun for this object.  We'll try to infer the pronoun from the
     *   gender and number flags: if plural, 'they'; if isHim, 'he'; if isHer 'she'; otherwise 'it'.
     */
    heName = (pronoun().name)

    /*
     *   The objective-case pronoun for this object.  We'll try to infer
     *   the pronoun from the gender and number flags: if plural, 'them';
     *   if isHim, 'him'; if isHer 'her'; otherwise 'it'.  
     */
    himName = (pronoun().objName)

    /*
     *   The possessive adjective pronoun for this object.  We'll try to
     *   infer the pronoun from the gender and number flags: if plural,
     *   'their'; if isHim, 'his'; if isHer, 'her'; otherwise
     *   'its'.  
     */
    herName = (pronoun().possAdj)

    /*
     *   The possessive noun pronoun for this object.  We'll try to infer
     *   the pronoun from the gender and number flags: if plural, 'theirs';
     *   if isHim, 'his'; if isHer, 'hers'; otherwise 'its'.  
     */
    hersName = (pronoun().possNoun)

    /*
     *   The demonstrative pronoun for this object, nominative case.  For a
     *   singular gendered object, or a first- or second-person object,
     *   we'll use the regular pronoun (I, you, he, her).  For any other
     *   singular object, we'll use 'that', and for plural, 'those'.  
     */
    thatName = (pronoun().thatName)

    /*
     *   The demonstrative pronoun, objective case.  For a singular
     *   gendered object, or a first- or second-person object, we'll use
     *   the regular pronoun (me, you, him, her).  For any other singular
     *   object, we'll use 'that', and for plural, 'those'.  
     */
    thatObjName = (pronoun().thatObjName)
    
    /*  The reflexive name as a pronoun, e.g. himself, herself, itself */
    reflexiveName = (pronoun().reflexive.name)    
    
    /*
     *   Pronoun-or-name mapper.  If our name is a pronoun, return the
     *   given pronoun name property.  Otherwise return the given name
     *   string.  
     */
    ifPronoun(prop, str)
    {
        /* check to see if our name is a pronoun */
        local p = LMentionable.pronounMap[name];
        if (p != nil)
        {
            /* our name is a pronoun - return the pronoun property */
            return p.(prop);
        }
        else
        {
            /* not a pronoun - use the name string */
            return str;
        }
    }

    /*
     *   The VocabWords list for empty objects.  These are words (usually
     *   adjectives) that can be applied to an object that can be
     *   distinguished from similar objects by its contents ("box of
     *   papers", "bucket of water"), for times when it's empty.  This is a
     *   list of VocabWords objects for matching during parsing.
     *   
     *   [Required] 
     */
    emptyVocabWords = static [new VocabWord('empty', MatchAdj)]

    
    /* 
     *   Flag, do we want our theName to be constructed from our owner's name,
     *   e.g. "Bob's wallet" rather than "the wallet".
     */
    ownerNamed = nil
    
    /*
     *   Get the definite form of the name, given the name string under
     *   construction.  The English default is "the <name>", unless the object
     *   is already qualified, in which case it's just the base name. If,
     *   however, we're ownerNamed and we have a nominalOwner, return our
     *   owner's possessive adjective followed by our name (e.g. "Bob's
     *   wallet").
     */
    theNameFrom(str)
    {
        if(ownerNamed && nominalOwner != nil)
            return nominalOwner.possAdj + ' ' + str;
        
        if (qualified)
            return str;
        else
            return 'the <<str>>';
    }

    /* Determine the gender of this object */
    isHim = nil
    isHer = nil
    
    /*  
     *   By default an object is neuter if it's neither masculine nor feminine,
     *   but that can be overridden in cases where something might be referred
     *   to as either 'him' or 'it' for example.
     */
    isIt = (!(isHim || isHer))
    
    
    /*   
     *   The name with a definite article (or just the proper or qualified name)
     *   followed by the appropriate form of the verb 'to be'. This can be
     *   useful for producing sentences of which this object is the subject.
     */
    theNameIs()
    {
        local obj = self;
        
        /* 
         *   Return theName plus the appropriate conjugation of the verb 'to
         *   be', which we obtain from the conjugateBe() function, which expects
         *   a ctx object as its first parameter; we instead create an inline
         *   object and set its subj property to the current object (which is
         *   all the conjugateBe() function needs).
         */
         
        return theName + ' ' + conjugateBe(object {subj = obj; }, nil);

    }
    
    /*
     *   Class initialization.  The library calls this at preinit time,
     *   before calling construct() on any instances, to set up any
     *   pre-built tables in the class.  There's no required implementation
     *   here - this is purely for the language module's convenience to do
     *   any initial set-up work.
     *   
     *   For the English version, we take the opportunity to set up the
     *   main parser Dictionary object, and initialize the plural table.
     *   The plural table is a lookup table we build from the plural list,
     *   for quicker access during execution.
     *   
     *   [Required] 
     */
    classInit()
    {
        /* initialize the dictionary comparator */
        cmdDict.setComparator(Mentionable.dictComp);

        /* create the lookup table for the plurals and a/an words */
        local plTab = irregularPlurals = new LookupTable(128, 256);
        local anTab = specialAOrAn = new LookupTable(128, 256);

        /* set up the a/an pattern */
        local aAnPat = R'^(a|an)<space>+(.*)$';

        /* populate our tables from the CustomVocab objects we find */
        forEachInstance(CustomVocab, function(cv) {

            /* set up the irregular plurals */
            for (local lst = cv.irregularPlurals, local i = 1, 
                 local len = lst.length() ; i <= len ; i += 2)
            {
                /* add the association for singular -> plural */
                plTab[lst[i]] = lst[i+1];
                
                /* 
                 *   also add an association for plural -> plural, in case we
                 *   encounter words like 'data' that are already plural 
                 */
                plTab[lst[i+1][1]] = lst[i+1];
            }

            /* set up the special a/an words */
            for (local lst = cv.specialAOrAn, local i = 1,
                 local len = lst.length() ; i <= len ; ++i)
            {
                /* parse the entry */
                rexMatch(aAnPat, lst[i]);

                /* 
                 *   Set up its table entry - 1 for 'a', 2 for 'an'.  (We
                 *   use an integer rather than storing the full 'a' or
                 *   'an' string to make the table a little smaller
                 *   memory-wise.  Storing the strings would require an
                 *   object per string.  Since there are only the two
                 *   possibilities, it's easy to store an integer instead,
                 *   and it saves a bit of space.)  
                 */
                anTab[rexGroup(2)[3]] = rexGroup(1)[3] == 'a' ? 1 : 2;
            }

            /* we're done with these lists - to save space, forget them */
            cv.irregularPlurals = nil;
            cv.specialAOrAn = nil;
        });
    }

    /*
     *   Match a pronoun.  This returns true if this object is a valid
     *   antecedent for this pronoun grammatically: that is, it matches the
     *   pronoun in gender, number, and any other attributes the pronoun
     *   carries.
     *   
     *   English pronouns have gender and number.  (Some other languages
     *   have other attributes, such as animation - whether or not they
     *   refer to living creatures.)
     *   
     *   This routine doesn't tell us if the object is a *current*
     *   antecedent for the pronoun.  The current antecedent is a function
     *   of the command history.  This routine only tells us whether this
     *   object is a match in terms of grammatical attributes for the
     *   pronoun.
     *   
     *   Note that this routine can and should ignore first-person and
     *   second-person pronouns.  Those pronouns are relative to the
     *   speaker, so the parser handles them directly.
     *   
     *   [Required] 
     */
    matchPronoun(p)
    {
        /*
         *   - If we have plural usage, we'll match Them
         *.  - If we're gendered, we'll match Him or Her as appropriate
         *.  - If we have singular neuter usage, we'll match It
         */
        return (p == Them && (plural || ambiguouslyPlural)
                || p == Him && isHim
                || p == Her && isHer
                || p == It && isIt && (!plural || ambiguouslyPlural));
    }

    /*
     *   Get the pronoun to use for this object.  This returns the Pronoun
     *   object suitable for representing this object in a generated
     *   message.
     *   
     *   [Required] 
     */
    pronoun()   
    {
        switch(person)
        {
        case 1:
            return (plural ? Us : Me);
        case 2:
            return (plural ? Yall : You);
        default:
            return (plural ? Them :
                isHim ? Him : isHer ? Her : It);    
        }
        
        
    }

    
    /* The appropriate pronoun for leaving (getting out of) this object */
    objOutOfPrep
    {
        switch(contType)
        {
        case On:
            return 'off';
        case Under:
            return 'out from under';
        case Behind:
            return 'out from behind';
        default:
            return 'out of';
        }
    }
    
    /* 
     *   The prepositional phrase for something located inside this object, e.g.
     *   'in the box' or 'on the table
     */
    objInName = (objInPrep + ' ' + theName)
    
    
    /* 
     *   The prepositional phrase for something being moved inside this object, e.g.
     *   'into the box' or 'onto the table
     */
    objIntoName = (objIntoPrep + ' ' + theName)
    
    /*   
     *   The pronominal phrase for something leaving this object, e.g. 'out of
     *   the box'
     */
    objOutOfName = (objOutOfPrep + ' ' + theName)
    
    
    /*
     *   initVocab() - Parse the 'vocab' string.  This is called during preinit
     *   and on dynamically constructing a new Mentionable, to initialize up the
     *   object's vocabulary for use by the parser.
     *
     *   The vocab string is designed to make it as quick and easy as possible
     *   to define an object's name and vocabulary.  To the extent possible, we
     *   derive the vocabulary from the name, so for many objects the whole
     *   definition will just look like the object name. However, we also make
     *   it possible to define as much extra vocabulary beyond the name as
     *   needed, and to control the way the words making up the name are handled
     *   in terms of their parts of speech.
     *
     *   The 'vocab' string has this overall syntax:
     *
     *.    vocab = 'article short name; adjectives; nouns; pronouns'
     *
     *   You don't have to include all of the parts; you can simply stop when
     *   you're done, so it's valid, for example, to just write the 'short name'
     *   part.  It's also fine to include an empty part: if you have extra nouns
     *   to list, but no adjectives, you can say 'short name;;nouns'.
     *
     *   The 'article' is optional.  This can be one of 'a', 'an', 'some', or
     *   '()'.  If it's 'a' or 'an', and this differs from what we'd
     *   automatically generate based on the first word of the short name, we
     *   automatically enter the first word into the list of special cases for
     *   a/an words.  If it's 'some', we automatically set massNoun=true for the
     *   object.  If it's '-', we set qualified=true ('()' means that the name
     *   doesn't take an article at all).
     *
     *   Note that if you want to use 'a', 'an', 'some', or '()' as the first
     *   word of the actual short name, you simply need to add the desired
     *   article in front of it: 'an a tile from a scrabble set'.
     *
     *   The short name gives name that we display whenever the parser needs to
     *   show the object in a list, an announcement, etc.
     *
     *   If the short name consists entirely of capitalized words (that is, if
     *   every word starts with a capital letter), and the 'proper' property
     *   isn't explicitly set for this object, we'll set 'proper' to true to
     *   indicate that this is a proper name.
     *
     *   We also try to infer the object's vocabulary words from the short name.
     *   We first break off any prepositional phrases, if we see the
     *   prepositions 'to', 'of', 'from', 'with', or 'for'.  We then assume that
     *   the FIRST phrase is of the form 'adj adj adj... noun' - that is, zero
     *   or more adjectives followed by a noun; and that the SECOND and
     *   subsequent phrases are entirely adjectives.  You can override the
     *   part-of-speech inference by putting the actual part of speech
     *   immediately after a word (with no spaces) in square brackets: 'John[n]
     *   Smith' overrides the assumption that 'John' is an adjective.  Use [n]
     *   to make a word a noun, [adj] to make it an adjective, [prep] to make it
     *   a preposition, and [pl] to make it a plural. You can also add [weak] to
     *   make it a weak token (one on which the object won't be matched alone),
     *   or equivalently, enclose the word in parentheses. These annotations
     *   are stripped out of the name when it's displayed.
     *
     *   We consider ALL of the words in the short name's second and subsequent
     *   phrases (the prepositional phrases) to be adjectives, except for the
     *   preposition words themselves, which we consider to be prepositions.
     *   This is because these phrases all effectively qualify the main phrase,
     *   so we don't consider them as "important" to the object's name.  This
     *   helps the parser be smarter about disambiguation, without bothering the
     *   user with clarifying questions all the time.  When the player types
     *   "garage", we'll match the "key to the garage" object as well as the
     *   "garage" object, but if both objects are present, we'll know to choose
     *   the garage over the key because the noun usage is a better match to
     *   what the user typed.
     *
     *   We automatically ignore articles (a, an, the, and some) as vocabulary
     *   words when they immediately follow prepositions in the short name.  For
     *   example, in 'key to the garage', we omit 'the' as a vocabulary word for
     *   the object because it immediately follows 'to'.  We also omit 'to',
     *   since we don't enter the prepositions as vocabulary.  We do the
     *   complementary work on parsing, by ignoring these words when we see them
     *   in the command input in the proper positions.  These words are really
     *   structural parts of the grammar rather than parts of the object names,
     *   so the parser can do a better job of recognizing noun phrases by
     *   considering the grammatical functions of these words.
     *
     *   For many (if not most) objects, the short name won't be enough to state
     *   all of the vocabulary words you want to recognize for the object in
     *   command input.  Trying to cram every possible vocabulary word into the
     *   short name would usually make for an unwieldy display name.
     *   Fortunately, it's easy to add input vocabulary words that aren't
     *   displayed in the name.  Just add a semicolon, then the adjectives, then
     *   another semicolon, then the nouns.
     *
     *   Note that there's no section for adding extra prepositions, but you can
     *   still add them.  Put the prepositions in the adjective list, and
     *   explicitly annotate each one as a preposition by adding "[prep]" at the
     *   end, as in "to[prep]".
     *
     *   Next, there's the matter of plurals.  For each noun, we'll try to
     *   automatically infer a plural according to the spelling pattern. We also
     *   have a table of common irregular plurals that we'll apply. For
     *   irregular words that aren't in the table, you can override the
     *   spelling-based plural by putting the real plural in braces
     *   immediately after the noun, with no spaces.  Start with a hyphen to
     *   specify a suffix; otherwise just write the entire plural word. For
     *   example, you could write 'man{men}' or 'child{-ren}' (although these
     *   particular irregular plurals are already in our special-case list, so
     *   the custom plurals aren't actually needed in these cases).  You can use
     *   plural annotations in the short name as well as the extra noun list;
     *   they'll be removed from the short name when it's displayed.  We don't
     *   try to generate a plural for a proper noun (a noun that starts with a
     *   capital letter), but you can provide explicit plurals.
     *
     *   For words longer than the truncation length in the string comparator,
     *   you can set the word to match exactly by adding '=' as the last
     *   character.  This also requires exact character matching, rather than
     *   allowing accented character approximations (e.g., matching 'a' in the
     *   input to 'a-umlaut' in the dictionary).
     *
     *   We automatically assume that plurals should be matched without
     *   truncation.  This is because English plurals are usually formed with
     *   suffixes; if the user wants to enter a plural, they'll have to type the
     *   whole word anyway, because that's the only way you make it all the way
     *   to the suffix.  You can override this assumption for a given plural by
     *   adding '~' at the end of the plural.  This explicitly allows truncated
     *   and character approximation matches.
     *
     *   Finally, the 'pronouns' section gives a list of the pronouns that this
     *   word can match.  You can include 'it', 'him', 'her', and 'them' in this
     *   section.  We'll automatically set the isIt, isHim, isHer, and plural
     *   properties to true when we see the corresponding pronouns.
     *
     *   [Required]
     */
    initVocab()
    {
        /* If we're a singular first-person object, our name is 'I' or 'we' */
        if(person == 1)
            name = plural ? 'we' : 'I';
        
        /* If we're a second-person object, our name is 'you' */
        if(person == 2)
            name = 'you';
        
        /* if we don't have a vocab string, there's nothing to do */
        if (vocab == nil || vocab == '')
            return;

        /* inherit any vocab from our superclasses */
        inheritVocab();
                
        /* clear our vocabulary word list */
        vocabWords = new Vector(10);

        
        /* 
         *   get the initial string; we'll break it down as we work
         *   At the same time change any weak tokens of the form
         *   (tok) into tok[weak], so that they're effectively treated
         *   as prepositions (i.e. they won't match alone)
         */
        local str = vocab.findReplace(R'<lparen>.*?<rparen>', 
                                      {s: s.substr(2, s.length - 2) +
                                      (s == '()' ? '()' : '[weak]')});

        /* pull out the major parts, delimited by semicolons */
        local parts = str.split(';').mapAll({x: x.trim()});
        
        
 #ifdef __DEBUG

        if(parts.length > 4)
        {
            "<b><FONT COLOR=RED>WARNING!</b></FONT> ";
            "Too many semicolons in vocab string '<<vocab>>'; there should be a
            maximum of three separating four different sections.\n";
        }
 #endif

        /* the first part is the short name */
        local shortName = parts[1].trim();
 

        /* 
         *   if the short name is all in title case, and 'proper' isn't
         *   explicitly set, mark it as a proper name 
         */
        if (propDefined(&proper, PropDefGetClass) == Mentionable
            && rexMatch(properNamePat, shortName) != nil)
            proper = true;

        /* note the tentative name value */
        local tentativeName = shortName;

        /* split the name into individual words */
        local wlst = shortName.split(' '), wlen = wlst.length();

        /* check for an article at the start of the phrase */
        local i = 1;
        if (wlen > 0 && wlst[1] is in('a', 'an', 'some', 'the', '()'))
        {
            /* check which word we have */
            switch (wlst[1])
            {
            case 'a':
            case 'an':
                /* 
                 *   if this doesn't match what we'd synthesize by default
                 *   from the second word, add the word as a special case 
                 */
                if (wlen > 1 && aNameFrom(wlst[2]) != '<<wlst[1]>> <<wlst[2]>>')
                    specialAOrAn[wlst[2]] = (wlst[1] == 'a' ? 1 : 2);
                break;
                
            case 'some':
                /* mark this as a mass noun */
                massNoun = true;
                break;
                
            case '()':            
                /* mark this as a qualified name */
                qualified = true;
                break;               
            
            case 'the':
                qualified = true;
                wlst[1] = '!!!&&&';
                break;
            }

            /* it's a special flag, not a vocabulary word - skip it */
            ++i;

            /* trim this word from the tentative name as well */
            tentativeName = tentativeName.findReplace(
                wlst[1], '', ReplaceOnce).trim();
        }

        /* 
         *   If there's no 'name' property already, assign the name from
         *   the short name string.  Remove any of the special annotations
         *   for parts of speech or plural forms. 
         */
        if (name == nil && tentativeName != '')
            name = tentativeName.findReplace(deannotatePat, '', ReplaceAll);

        /* 
         *   Process each word in the short name.  Assume each is an
         *   adjective except the last word of the first phrase, which we
         *   assume is a noun.  We treat everything in a prepositional
         *   phrase (i.e., any phrase beyond the first) as an adjective,
         *   because it effectively modifies the main phrase: a "pile of
         *   paper" is effectively a paper pile; a "key to the front door
         *   of the house" is effectively a front door house key.  
         */
        local firstPhrase = true;
        for ( ; i <= wlen ; ++i)
        {
            /* get this word and the next one */
            local w = wlst[i].trim();
            local wnxt = (i + 1 <= wlen ? wlst[i+1] : nil);

            /* 
             *   If this word is one of our prepositions, enter it without
             *   a part of speech - it doesn't count towards a match when
             *   parsing input, since it's so non-specific, but it's not
             *   rejected either.  
             *   
             *   If the *next* word is a preposition, or there's no next
             *   word, this is the last word in a sub-phrase.  If this is
             *   the first sub-phrase, enter the word as a noun.
             *   Otherwise, enter it as an adjective.  
             */
            local pos;
            if (rexMatch(prepWordPat, w) != nil)
            {
                /* it's a preposition */
                pos = MatchPrep;

                /* 
                 *   If the next word is an article, skip it.  Articles in
                 *   the name phrase don't count as vocabulary words, since
                 *   the parser strips these out when matching objects to
                 *   input.  (That doesn't mean the parser ignores
                 *   articles, though.  It parses them in input and
                 *   respects the meaning they convey, but it does that
                 *   internally, sparing the object name matcher the
                 *   trouble of dealing with them.)  
                 */
                if (wnxt is in ('a', 'an', 'the', 'some'))
                    ++i;
            }
            else if (rexMatch(weakWordPat, w) != nil)
            {
                /* It's a weak token */
                pos = MatchWeak;
            }
            
            else if (firstPhrase
                     && (wnxt == nil || rexMatch(prepWordPat, wnxt) != nil))
            {
                /* it's the last word in the first phrase - it's a noun */
                pos = MatchNoun;

                /* we've just left the first phrase */
                firstPhrase = nil;
            }
            else
            {
                /* anything else is an adjective */
                pos = MatchAdj;
            }

            /* enter the word under the part of speech we settled on */
            initVocabWord(w, pos);
        }

        
        /* the second section is the list of adjectives */
        if (parts.length() >= 2 && parts[2] != '') 
        {
            parts[2].split(' ').forEach(
                {x: initVocabWord(x.trim(), MatchAdj)});
            
#ifdef __DEBUG
            /* 
             *   If we're compiling for debugging, issue a warning if a pronoun
             *   appears in the adjective section. We exclude 'her' from the
             *   list of pronouns we test for here since 'her' in the adjective
             *   section could be intended as the female possessive pronoun. But
             *   only carry out this check for a Thing, since a Topic might
             *   legally have pronouns in any section.
             */
            parts[2].split(' ').forEach(function(x){
                if(ofKind(Thing) && x is in ('him', 'it', 'them'))
                {
                    "<b><FONT COLOR=RED>WARNING!</FONT></B> ";
                    "Pronoun '<<x>>' appears in adjective section (after first
                    semicolon) of vocab string '<<vocab>>'. This may mean the
                    vocab string has too few semicolons.\n";
                }
                
            });
#endif
            
        }


        /* the third section is the list of nouns */
        if (parts.length() >= 3 && parts[3] != '')
        {            
            parts[3].split(' ').forEach(
                {x: initVocabWord(x.trim(), MatchNoun)});
            
#ifdef __DEBUG
            /* 
             *   If we're compiling for debugging, issue a warning if a pronoun
             *   appears in the noun section.
             */
            parts[3].split(' ').forEach(function(x){
                if(ofKind(Thing) && x is in ('him', 'her', 'it', 'them'))
                {
                    "<b><FONT COLOR=RED>WARNING!</FONT></B> ";
                    "Pronoun '<<x>>' appears in noun section (after second
                    semicolon) of vocab string '<<vocab>>'. This probably
                    mean this vocab string has too few semicolons.\n";
                }
                
            });
#endif
        }


            
            /* the fourth section is the list of pronouns */
            if (parts.length() >= 4 && parts[4] != '')
            {
                local map = ['it', &isIt,
                    'him', &isHim,
                    'her', &isHer,
                    'them', &plural];
                
                local explicitlySingular = nil;
                
                               
                parts[4].split(' ').forEach(function(x) {
                    
                    local i = map.indexOf(x.trim());
                    if (i != nil)
                        self.(map[i+1]) = true;
                    
                    if(x.trim() != 'them')                    
                        explicitlySingular = true;     
                                          
                });
                
                /* 
                 *   If we're both explicitly singular and plural (i.e. both a
                 *   singular pronoun and 'them' have appeared in our pronoun
                 *   list) we must be ambiguously plural.
                 */
                
                if(explicitlySingular && plural)
                {
                    ambiguouslyPlural = true;
                    
                    /* 
                     *   We're actually plural only if 'them' is the first
                     *   pronoun encountered; so if it's not we're actually
                     *   singular.
                     */
                    
                    if(!parts[4].trim().startsWith('them'))
                        plural = nil;
                    
                }
#ifdef __DEBUG
            /* 
             *   If we're compiling for debugging, issue a warning if a
             *   something other than a pronoun appears in the pronoun section.
             */
            parts[4].split(' ').forEach(function(x){
                if(x not in ('him', 'her', 'it', 'them'))
                {
                    "<b><FONT COLOR=RED>WARNING!</FONT></B> ";
                    "Non-Pronoun '<<x>>' appears in pronoun section (after third
                    semicolon) of vocab string '<<vocab>>'. Check that this
                    vocab string doesn't have too many semicolons.\n";
                }
                
            });
#endif
            }


        
        
        /* turn vocabWords back into a list */
        vocabWords = vocabWords.toList();
    }

    /* 
     *   pattern for detecting a proper name - each word starts with a
     *   capital letter 
     */
    properNamePat = R'(<upper><^space>*)(<space>+<upper><^space>*)*'

       
    /*   
     *   Inherit vocab from our superclasses according to the following scheme:
     *.  1. A + sign in the name section will be replaced with the name from our
     *   superclass.
     *.  2  Unless the adjective and nouns section start with a -, any
     *   adjectives and nouns from our superclasses vocab will be added to the
     *   respective section.
     *.  3  If our pronouns section is empty or contains a +, inherit pronouns
     *   from our superclass, otherwise leave it unchanged.
     */
    inheritVocab()
    {
        /* 
         *   If we don't have any vocab, there's no work to do.
         */
        if(vocab == nil || vocab == '')            
            return;
        
        
        foreach(local cls in getSuperclassList)
        {   
            /* 
             *   If the superclass doesn't have any vocab, there's nothing more
             *   we need do with it. Otherwise Ensure that our superclasses have
             *   inherited any vocab they need to before we try to inherit from
             *   them.
             */
            
            if(cls.vocab not in (nil, ''))        
                cls.inheritVocab();
        }
          
        
        /* 
         *   If we don't define our own vocab property directly, there's no more
         *   work to do; it's all been done on our parent classes. There's also
         *   no more work to do if none of our parent classes defines any vocab.
         */
        if(!propDefined(&vocab, PropDefDirectly) 
           || getSuperclassList.indexWhich({c: c.vocab not in (nil, '')}) == nil)
            return;
        
        /* Our list of vocab, split into parts. */
        local vlist = vocab.split(';').mapAll({x: x.trim()});
        
        /* for convenience, make sure we end up with four parts */
        for(local i = vlist.length; i < 4; i++)
            vlist += '';
        
        foreach(local cls in getSuperclassList)
        {  
            /* 
             *   If this class doesn't specify any vocab, we don't need to
             *   process it.
             */
            if(cls.vocab is in (nil, ''))
                continue;
            
            /* The inherited vocab, split into parts */               
            local ilist = cls.vocab.split(';').mapAll({x: x.trim()});
            
            /* For convenience, make sure we have four parts. */
            for(local i = ilist.length; i < 4; i++)
                ilist += '';
        
            /* Replace any + sign in the first part with the inherited name */
            vlist[1] = vlist[1].findReplace('+', ilist[1]);
            
            /* 
             *   For the second and third parts, unless they atart with - add in
             *   the inherited adjectives and nouns.
             */
            
            for(local i in 2..3)
            {
                if(!vlist[i].startsWith('-'))
                    vlist[i] = vlist[i] + ' ' + ilist[i];
            }
            
            /* 
             *   For the 4th (pronoun) part, add any inherited pronouns only if
             *   we don't have any of our own or there's a + in the pronoun part
             */
            
            if((vlist[4] == '' || vlist[4].find('+') != nil) && ilist[4] != '')
                vlist[4] = vlist[4] + ' ' + ilist[4];
            
        }
        
        /* Strip out any leading - in parts 2 and 3 */
        for(local i in 2..3)
        {
            if(vlist[i].startsWith('-'))
                vlist[i] = vlist[i].substr(2);
        }
        
        /* Strip out any + in part 4 */
        vlist[4] = vlist[4].findReplace('+', '');
            
        /* Join the list back into a vocab string */
        vocab = vlist.join(';');
    }
    
    
    
    
    
    /* 
     *   Initialize vocabulary for one word from the 'vocab' list.  'w' is
     *   the word text, with optional part-of-speech and plural-form
     *   annotations ([n], [adj], [prep], [pl], (-s)).  It can also have a
     *   special flag character as its final character: '=' for an exact
     *   match (no truncation and no character approximations), or '~' for
     *   fuzzy matches (truncation and approximation allowed).
     *   
     *   'matchFlags' is a combination of MatchXxx values.  This should
     *   minimally provide the part of speech as one of MatchAdj,
     *   MatchNoun, or MatchPlural.  You can also include MatchNoTrunc to
     *   specify that user input can only match this word without any
     *   truncation, and MatchNoApprox to specify that input can only match
     *   without character approximations (e.g., 'a' matching 'a-umlaut').
     */
    initVocabWord(w, matchFlags)
    {
        /* presume this will be entered in the dictionary as a noun */
        local partOfSpeech = &noun;
        
        /* 
         *   if there's an explicit part-of-speech annotation, it overrides
         *   the assumed part of speech 
         */
        if (w.find(posPat) != nil)
        {
            /* clear the old part-of-speech flags */
            matchFlags &= ~(MatchPrep | MatchAdj | MatchNoun | MatchPlural |
                            MatchWeak);
            
            /* note the new part of speech */
            switch (rexGroup(1)[3])
            {
            case 'n':
                matchFlags |= MatchNoun;
                break;

            case 'adj':
                matchFlags |= MatchAdj;
                break;
 
            case 'weak':    
                matchFlags |= MatchWeak;
                break;
                
            case 'prep':                
                matchFlags |= MatchPrep;
                break;

            case 'pl':
                matchFlags |= MatchPlural;
                break;
            }

            /* strip the annotation from the word string */
            w = w.findReplace(posPat, '', ReplaceOnce);
        }
        
        /* 
         *   If we're compiling for debug, try to warn the author of any illegal
         *   part-of-speech tags that may have inadvertently crept into a vocab
         *   string.
         */
#ifdef __DEBUG
    else if(w.find(R'<lsquare>.*<rsquare>') != nil && !w.endsWith('s'))
    {
        "<B><FONT COLOR=RED>WARNING!</FONT></B> ";
        "Illegal part of speech tag for '<<w>>' in vocab string '<<vocab>>'\n";
    }
        
#endif        
        

        /* 
         *   if this is an adjective ending in apostrophe-S, use that form
         *   of the word 
         */
//        if (rexMatch(apostSPat, w))
//        {
//            /* note the existing value of w*/
//            local wOld = w;
//            
//            /* 
//             *   strip off the apostrophe-S, since the tokenizer will do
//             *   this when parsing the input 
//             */
//            w = rexGroup(1)[3];
//
//            /* mark it as an apostrophe-S word in the dictionary */
//            partOfSpeech = &nounApostS;
//                      
//            w += '^s';
//            
//            apostropheSPreParser.addEntry(wOld, w);
//        }
        
        if (rexMatch(apostSPat, w))
        {
            /* mark it as an apostrophe-S word in the dictionary */
            partOfSpeech = &nounApostS;
            
            /* 
             *   Add a dictionary word without the apostrophe-S, since the
             *   tokenizer will separate the apostrophe-S as a separate token,
             *   hence we need to be able to look up the base word in the
             *   dictionary.  But then proceed with our regular handling with
             *   the full word as well, since the parser will reassemble the
             *   full token with the apostrophe-S for the actual noun phrase
             *   matching.
             */
            cmdDict.addWord(dictionaryPlaceholder, rexGroup(1)[3],
                            partOfSpeech);
        }
        
        
        /* if there's a plural annotation, note it */
        if ((matchFlags & MatchPlural) != 0
            || partOfSpeech == &nounApostS)
        {
            /* 
             *   Either this is already marked as a plural, or it has an
             *   apostrophe-S.  In either case, it's already as inflected
             *   as an English word can get, so we don't want to try
             *   inflecting it further with a plural formation.  
             */
        }
        else if (w.find(pluralPat) != nil)
        {
            /* there's an explicit plural - retrieve it */
            local pl = rexGroup(1)[3];

            /* strip it out of the string */
            w = w.findReplace(pluralPat, '', ReplaceOnce);

            /* split out the list elements, if there are multiple entries */
            pl = pl.split(',').mapAll({x: x.trim()});

            /* for each plural given as a suffix, append it to the word */
            pl = pl.mapAll({x: x.startsWith('-') ? w + x.substr(2) : x});

            /* add each plural; assume truncation isn't allowed */
            pl.forEach({x: initVocabWord(x, MatchPlural | MatchNoTrunc)});
        }
        else if (matchFlags == MatchNoun && rexMatch(properPat, w) == nil)
        {
            /* 
             *   it's a noun, it's not a proper noun, and no plural form
             *   was explicitly provided, so infer one 
             */
            local pl = [pluralWordFrom(w, '\'')];

            /* 
             *   if it's an acronym or number, add the apostrophe-s plural
             *   as an alternative (1990's, LCD's) 
             */
            if (rexMatch(acronymPluralPat, w) != nil
                || w.length() == 1)
                pl += ['<<w>>\'s'];

            /* 
             *   If it's an irregular plural form, add any variations.
             *   (The first irregular will have already been picked up, so
             *   we only need to add the second and other variations here.)
             */
            local irr;
            if ((irr = irregularPlurals[w]) != nil && irr.length() > 1)
                pl += irr.sublist(2);

            /* 
             *   Remove the original word from the plural list, if it's
             *   there.  Some words are their own plurals, such as "fish"
             *   or "sheep".  Practically speaking, it's better to treat
             *   these words as singular in the parser.  It's easy to
             *   explicitly make a phrase plural: you just put ALL in front
             *   of it (PUT ALL FISH IN BOWL).  But there's no converse; if
             *   we treated FISH as plural, there'd be no good way to
             *   singularize it when you just wanted to talk about one
             *   fish.
             *   
             *   (Note that we have to remove these words here.  We don't
             *   want to strip them out of the irregular plural list,
             *   because we also use that list to synthesize plural names,
             *   and we certainly want the correct word for that purpose.
             *   We also don't want to strip them out in initVocabWord(),
             *   because the game might call that to explicitly add a
             *   plural that matches a noun.  The correct place to remove
             *   them is right here, because we only want to remove them
             *   from implicitly generated lists of vocabulary plurals.)  
             */
            pl -= w;

            /* add each plural; assume truncation isn't allowed */
            pl.forEach({x: initVocabWord(x, MatchPlural | MatchNoTrunc)});
        }

        /* check for exact and inexact flags */
        if (w.endsWith('='))
        {
            matchFlags |= MatchNoTrunc | MatchNoApprox;
            w = w.left(-1);
        }
        else if (w.endsWith('~'))
        {
            matchFlags &= ~(MatchNoTrunc | MatchNoApprox);
            w = w.left(-1);
        }

        /* add this word to the dictionary and to our part-of-speech list */
        addDictWord(w, partOfSpeech, matchFlags);
    }

    /* pattern for apostrophe-s words */
    apostSPat = R'^(.*)(\'|&rsquo;|\u2019)s$'

    /* 
     *   Add a word to the dictionary and to our vocabulary list for the
     *   given match flags.  
     */
    addDictWord(w, partOfSpeech, matchFlags)
    {
        /* for dictionary purposes, we want everything in lower case */
        w = w.toLower();

        /* 
         *   Add it to the dictionary.  Note that our parser doesn't use
         *   the dictionary's object association feature; but we do need
         *   *some* object for the entry, so use the dictionary placeholder
         *   object as the associated object.  Using the placeholder
         *   minimizes the dictionary's memory needs by creating only one
         *   entry for each word.  
         */
        cmdDict.addWord(dictionaryPlaceholder, w, partOfSpeech);

        /* add it to our internal vocabulary list */
        vocabWords = vocabWords.append(new VocabWord(w, matchFlags));
    }

    /* 
     *   reinitialize the vocab of this object from scratch, using the string
     *   voc in place of the original vocab property. 
     */
    
    replaceVocab(voc)
    {
        /* clear out the existing name */
        name = nil;
        
        /* Set our vocab property to the vocab we're replacing it with */
        vocab = voc;
       
        /* Clear out any existing vocabWords */
        vocabWords = [];
        
        /* Initialize the vocab again */
        initVocab();
    }
                 
    /*  
     *   Add additional vocab words to those already in use for this object. If
     *   we specify the name part this will replace the existing name for the
     *   object.
     */
    addVocab(voc)
    {
        /* 
         *   First check if we have anything in the name part. If so, assume
         *   that it's meant to replace the existing name.
         */
        local parts = voc.split(';');
        if(parts[1] > '')
            name = nil;
        
        /* 
         *   Make a note of the existing vocabWords, since they'll be overridden
         *   when we add the new ones.
         */
        local vocWords = vocabWords;
        
        /*   Copy the new vocab string to our vocab property. */
        vocab = voc;
        
        /*  Initialize our vocabWords using the new string. */
        initVocab();
        
        /*  Add back our old vocabWords, without any duplicates */
        vocabWords = vocabWords.appendUnique(vocWords);
        
    }
    
    
    /* 
     *   Remove a word from this object's vocabulary. If the matchFlags
     *   parameter is supplied it should be one of MatchNoun, MatchAdj,
     *   MatchPrep or MatchPlural, in which case only VocabWords matching the
     *   corresponding part of speech (as well as word) will be removed.
     */
    removeVocabWord(word, matchFlags?)
    {
        if(matchFlags)            
            vocabWords = vocabWords.subset({v: v.wordStr != word || v.posFlags !=
                                           matchFlags});
        else
            vocabWords = vocabWords.subset({v: v.wordStr != word});
    }
    
    addVocabWord(word, matchFlags)
    {
        initVocabWord(word, matchFlags);
    }
    
    /* 
     *   Regular expression pattern for matching a single preposition word.
     *   A word is a preposition if it's in our preposition list, OR it's
     *   annotated explicitly with "[prep]" at the end. 
     */
    prepWordPat = static new RexPattern(
        '^(<<prepList>>)$|.*<lsquare>prep<rsquare>$')
    
    weakWordPat = static new RexPattern(
        '.*<lsquare>weak<rsquare>$')

    /* preposition list, as a regular expression OR pattern */
    prepList = 'to|of|from|with|for'

    /* regular expression for removing annotations from a short name */
    deannotatePat =
        R"<lsquare><alpha>+<rsquare>|<lbrace><alphanum|-|'|,|~|=>+<rbrace>"

    /* pattern for part-of-speech annotations */
    posPat = R'<lsquare>(n|adj|pl|prep|weak)<rsquare>'

    /* pattern for plural annotations */
    pluralPat = R"<lbrace>(<alphanum|-|'|space|,|~|=>+)<rbrace>"

    /* 
     *   pattern for proper nouns: starts with a capital, and at least one
     *   lower-case letter within 
     */
    properPat = R'^<upper>(.*<lower>.*)'

    /*
     *   Generate the "distinguished name" for this object, given a list of
     *   Distinguisher objects that we're using to tell it apart from
     *   others in a list.
     *   
     *   'article' indicates which kind of article to use: Definite
     *   ("the"), Indefinite ("a", "an", "some"), or nil (no article).
     *   'distinguishers' is a list of Distinguisher object that are being
     *   used to identify this object uniquely.  Our job is to elaborate
     *   the object's name with all of the qualifying phrases implied by
     *   the distinguishers.
     *   
     *   [Required] 
     */
    distinguishedName(article, distinguishers)
    {
        local ret;

        /* note which distinguishers are present */
        local dis = distinguishers.indexOf(disambigNameDistinguisher) != nil;
        local poss = distinguishers.indexOf(ownerDistinguisher) != nil;
        local loc = distinguishers.indexOf(locationDistinguisher) != nil;
        local cont = distinguishers.indexOf(contentsDistinguisher) != nil;

        /* 
         *   start with the core name: this is either the basic name or the
         *   disambiguation name, depending on whether there's a
         *   disambigNameDistinguisher in the list 
         */
        ret = (dis ? disambigName : name);

        /* add any state adjectives */
        foreach (local d in distinguishers)
        {
            if (d.ofKind(StateDistinguisher))
                ret = d.state.addToName(self, ret);
        }

        /* add the possessive, if it's not a qualified name */      
        if (poss && !qualified)
        {
            local o = nominalOwner();
            if (o != nil)
                ret = nominalOwner().possessify(article, self, ret);
            // If this object is unowned and no locational distinguisher is present
            // and the object is lying on the ground, we still need to describe it.
            else if (!loc && self.location == gActor.getOutermostRoom())
            {
                ret = self.location.locify(self, ret);
            }
        }    

        /* add the contents qualifier */
        if (cont)
        {
            local c = nominalContents();
            if (c != nil)
                ret = c.contify(self, ret);
            else
                ret = 'empty <<ret>>';
        }

        /* add the locational qualifier */
        if (loc)
        {
            if (location != nil)
                ret = location.locify(self, ret);
        }

        /* 
         *   If an article is desired, add it.  Exception: don't add a
         *   definite article if there's a possessive, since the possessive
         *   takes the place of the definite article. 
         */
        if (article == Indefinite)
            ret = (poss ? aNameFromPoss(ret) : aNameFrom(ret));
        else if (article == Definite && !poss)
            ret = theNameFrom(ret);

        /* return the result */
        return ret;
    }

    /*
     *   Generate a possessive name for an object that we own, given a
     *   string under construction for the object's name.  'obj' is the
     *   object we're possessing ('self' is the owner), and 'str' is the
     *   name string under construction, without any possessive or article
     *   qualifiers yet.
     *   
     *   Note that we must add to 'str', not the base name of the object.
     *   We might be using a variation on the name (such as the
     *   disambiguation name), or we might have already adorned the name
     *   with other qualifiers.  
     *   
     *   'article' specifies the usage: Definite, Indefinite, or nil for no
     *   article.  We DON'T actually add the article here; rather, this
     *   tells us the form that the name will take when the caller is done
     *   with it, so we should use a suitable form of the possessive
     *   phrasing to the extent it varies by article.  In English, it does
     *   vary.  In the Definite case, the possessive effectively replaces
     *   the article: "the book" becomes "Bob's book".  In the Indefinite
     *   case, the possessive has to be rephrased prepositionally so that
     *   the article can still be included: "a book" becomes "a book of
     *   Bob's".  Mass nouns are a further special case: "some water"
     *   becomes "some of Bob's water".
     *   
     *   The default behavior is as follows.  In Definite mode, we return
     *   "<name>'s <string>".  In Indefinite mode, we return "<string> of
     *   <name>" (for a final result like "a book of Bob's").
     */
    possessify(article, obj, str)
    {
        /*
         *   Definite: book -> Bob's book -> Bob's book
         *.  No article: book -> Bob's book -> Bob's book
         *.  Indefinite mass noun: water -> Bob's water -> some of Bob's water
         *.  Indefinite count noun: book -> book of Bob's -> a book of Bob's
         */
        if (article is in (Definite, nil)
            || (article == Indefinite && obj.massNoun))
            return '<<possAdj>> <<str>>';
        else
            return '<<str>> of <<possNoun>>';
    }

    /*
     *   Apply a locational qualifier to the name for an object contained
     *   within me.  'obj' is the object (something among my contents), and
     *   'str' is the name under construction.  We'll add the appropriate
     *   prepositional phrase: "the box UNDER THE TABLE".  
     */
    locify(obj, str)
    {        
        if (obj.location == gActor.getOutermostRoom()
            && obj.location.floorObj != nil)
            return '<<str>> <<obj.location.floorObj.objInName>> ';
        else
            return '<<str>> <<obj.locType.prep>> <<theName>>';
    }

    /*
     *   Apply a contents qualifier to the name for my container.  'obj' is
     *   the object (my container), and 'str' is the name under
     *   construction.  We'll add the appropriate prepositional phrase:
     *   "the bucket OF WATER".  
     */
    contify(obj, str)
    {
        return '<<str>> of <<name>>';
    }

    /*
     *   Apply an indefinite article ("a box", "an orange", "some lint") to
     *   the given name string 'str' for this object.  We'll try to figure
     *   out which indefinite article to use based on what kind of noun
     *   phrase we use for our name (singular, plural, or a "mass noun"
     *   like "lint"), and our spelling.
     *   
     *   By default, we'll use the article "a" if the name starts with a
     *   consonant, or "an" if it starts with a vowel.
     *   
     *   If the name starts with a "y", we'll look at the second letter; if
     *   it's a consonant, we'll use "an", otherwise "a" (hence "an yttrium
     *   block" but "a yellow brick").
     *   
     *   If the object is marked as a mass noun or having plural usage, we
     *   will use "some" as the article ("some water", "some shrubs").  If
     *   the string has a possessive qualifier, we'll make that "some of"
     *   instead ("some of Bob's water").
     *   
     *   Some objects will want to override the default behavior, because
     *   the lexical rules about when to use "a" and "an" are not without
     *   exception.  For example, silent-"h" words ("honor") are written
     *   with "an", and "h" words with a pronounced but weakly stressed
     *   initial "h" are sometimes used with "an" ("an historian").  Also,
     *   some 'y' words might not follow the generic 'y' rule.
     *   
     *   'U' words are especially likely not to follow any lexical rule -
     *   any 'u' word that sounds like it starts with 'y' should use 'a'
     *   rather than 'an', but there's no good way to figure that out just
     *   looking at the spelling (consider "unassuming", " unimportant
     *   word", or "a unanimous decision" and "an unassuming man").  We
     *   simply always use 'an' for a word starting with 'u', but this will
     *   have to be overridden when the 'u' sounds like 'y'.  
     */
    aNameFrom(str)
    {
        /* remember the original source string */
        local inStr = str;

        /*
         *   The complete list of unaccented, accented, and ligaturized
         *   Latin vowels from the Unicode character set.  (The Unicode
         *   database doesn't classify characters as vowels or the like,
         *   so it seems the only way we can come up with this list is
         *   simply to enumerate the vowels.)
         *
         *   These are all lower-case letters; all of these are either
         *   exclusively lower-case or have upper-case equivalents that
         *   map to these lower-case letters.
         *
         *   (Note an implementation detail: the compiler will append all
         *   of these strings together at compile time, so we don't have
         *   to perform all of this concatenation work each time we
         *   execute this method.)
         *
         *   Note that we consider any word starting with an '8' to start
         *   with a vowel, since 'eight' and 'eighty' both take 'an'.
         */
        local vowels = '8aeiou\u00E0\u00E1\u00E2\u00E3\u00E4\u00E5\u00E6'
                       + '\u00E8\u00E9\u00EA\u00EB\u00EC\u00ED\u00EE\u00EF'
                       + '\u00F2\u00F3\u00F4\u00F5\u00F6\u00F8\u00F9\u00FA'
                       + '\u00FB\u00FC\u0101\u0103\u0105\u0113\u0115\u0117'
                       + '\u0119\u011B\u0129\u012B\u012D\u012F\u014D\u014F'
                       + '\u0151\u0169\u016B\u016D\u016F\u0171\u0173\u01A1'
                       + '\u01A3\u01B0\u01CE\u01D0\u01D2\u01D4\u01D6\u01D8'
                       + '\u01DA\u01DC\u01DF\u01E1\u01E3\u01EB\u01ED\u01FB'
                       + '\u01FD\u01FF\u0201\u0203\u0205\u0207\u0209\u020B'
                       + '\u020D\u020F\u0215\u0217\u0254\u025B\u0268\u0289'
                       + '\u1E01\u1E15\u1E17\u1E19\u1E1B\u1E1D\u1E2D\u1E2F'
                       + '\u1E4D\u1E4F\u1E51\u1E53\u1E73\u1E75\u1E77\u1E79'
                       + '\u1E7B\u1E9A\u1EA1\u1EA3\u1EA5\u1EA7\u1EA9\u1EAB'
                       + '\u1EAD\u1EAF\u1EB1\u1EB3\u1EB5\u1EB7\u1EB9\u1EBB'
                       + '\u1EBD\u1EBF\u1EC1\u1EC3\u1EC5\u1EC7\u1EC9\u1ECB'
                       + '\u1ECD\u1ECF\u1ED1\u1ED3\u1ED5\u1ED7\u1ED9\u1EDB'
                       + '\u1EDD\u1EDF\u1EE1\u1EE3\u1EE5\u1EE7\u1EE9\u1EEB'
                       + '\u1EED\u1EEF\u1EF1\uFF41\uFF4F\uFF55';

        /*
         *   A few upper-case vowels in unicode don't have lower-case
         *   mappings - consider them separately.
         */
        local vowelsUpperOnly = '\u0130\u019f';

        /*
         *   the various accented forms of the letter 'y' - these are all
         *   lower-case versions; the upper-case versions all map to these
         */
        local ys = 'y\u00FD\u00FF\u0177\u01B4\u1E8F\u1E99\u1EF3'
                   + '\u1EF5\u1EF7\u1EF9\u24B4\uFF59';

        /* if the name is already qualified, don't add an article at all */
        if (qualified)
            return str;

        /* if it's plural or a mass noun, use "some" as the article */
        if (plural || massNoun)
        {
            /* use "some" as the article */
            return 'some <<str>>';
        }
        else
        {
            local firstChar;
            local firstCharLower;

            /* if it's empty, just use "a" */
            if (inStr == '')
                return 'a';

            /* 
             *   if the first word is in our special-case list, use the special
             *   case handling 
             */
            local sc;
            if (rexMatch(firstWordPat, str)
                && (sc = specialAOrAn[rexGroup(1)[3]]) != nil)
                return (sc == 1 ? 'a ' : 'an ') + str;

            /* get the first character of the name */
            firstChar = inStr.substr(1, 1);

            /* skip any leading HTML tags */
            if (rexMatch(tagOrQuotePat, firstChar) != nil)
            {
                /*
                 *   Scan for tags.  Note that this pattern isn't quite
                 *   perfect, as it won't properly ignore close-brackets
                 *   that are inside quoted material, but it should be good
                 *   enough for nearly all cases in practice.  In cases too
                 *   complex for this pattern, the object will simply have
                 *   to override aDesc.
                 */
                local len = rexMatch(leadingTagOrQuotePat, inStr);
                
                /* if we got a match, strip out the leading tags */
                if (len != nil)
                {
                    /* strip off the leading tags */
                    inStr = inStr.substr(len + 1);

                    /* re-fetch the first character */
                    firstChar = inStr.substr(1, 1);
                }
            }

            /* get the lower-case version of the first character */
            firstCharLower = firstChar.toLower();

            /*
             *   if the first word of the name is only one letter long,
             *   treat it specially
             */
            if (rexMatch(oneLetterWordPat, inStr) != nil)
            {
                /*
                 *   We have a one-letter first word, such as "I-beam" or
                 *   "M-ray sensor", or just "A".  Choose the article based
                 *   on the pronunciation of the letter as a letter.
                 */
                return (rexMatch(oneLetterAnWordPat, inStr) != nil
                        ? 'an ' : 'a ') + str;
            }

            /*
             *   look for the first character in the lower-case and
             *   upper-case-only vowel lists - if we find it, it takes
             *   'an'
             */
            if (vowels.find(firstCharLower) != nil
                || vowelsUpperOnly.find(firstChar) != nil)
            {
                /* it starts with a vowel */
                return 'an <<str>>';
            }
            else if (ys.find(firstCharLower) != nil)
            {
                local secondChar;

                /* get the second character, if there is one */
                secondChar = inStr.substr(2, 1);

                /*
                 *   It starts with 'y' - if the second letter is a
                 *   consonant, assume the 'y' is a vowel sound, hence we
                 *   should use 'an'; otherwise assume the 'y' is a
                 *   diphthong 'ei' sound, which means we should use 'a'.
                 *   If there's no second character at all, or the second
                 *   character isn't alphabetic, use 'a' - "a Y" or "a
                 *   Y-connector".
                 */
                if (secondChar == ''
                    || rexMatch(alphaCharPat, secondChar) == nil
                    || vowels.find(secondChar.toLower()) != nil
                    || vowelsUpperOnly.find(secondChar) != nil)
                {
                    /*
                     *   it's just one character, or the second character
                     *   is non-alphabetic, or the second character is a
                     *   vowel - in any of these cases, use 'a'
                     */
                    return 'a <<str>>';
                }
                else
                {
                    /* the second character is a consonant - use 'an' */
                    return 'an <<str>>';
                }
            }
            else if (rexMatch(elevenEighteenPat, inStr) != nil)
            {
                /*
                 *   it starts with '11' or '18', so it takes 'an' ('an
                 *   11th-hour appeal', 'an 18-hole golf course')
                 */
                return 'an <<str>>';
            }
            else
            {
                /* it starts with a consonant */
                return 'a <<str>>';
            }
        }
    }

    /*
     *   Get the indefinite name for a version of our name that has a
     *   possessive qualifier.  The caller is responsible for ensuring that
     *   the possessive is already in a suitable format for adding an
     *   indefinite article - usually something like "book of Bob's", so
     *   that we can turn this into "a book of Bob's".
     *   
     *   In English, there's a special case where the regular indefinite
     *   name format differs from the possessive format, which is why we
     *   need this separate method in the English module.  Specifically, if
     *   the basic name is a plural or mass noun, we have to use "some of"
     *   in the possessive case, rather than the usual "some": "some water"
     *   in the normal case, but "some of Bob's water" in the possessive
     *   case.  
     */
    aNameFromPoss(str)
    {
        /* 
         *   for mass nouns and plurals, use "some of"; otherwise use the
         *   normal a-name 
         */
        return (massNoun || plural ? 'some of <<str>>' : aNameFrom(str));
    }

    /* 
     *   lookup table of special-case a/an words (we build this
     *   automatically during classInit from CustomVocab objects) 
     */
    specialAOrAn = nil

    /* pre-compile some regular expressions for aName */
    tagOrQuotePat = R'[<"\']'
    leadingTagOrQuotePat = R'(<langle><^rangle>+<rangle>|"|\')+'
    firstWordPat =
        R'(?:<langle><^rangle>+<rangle>|"|\'|<space>)*(<alphanum>+)%>'
    oneLetterWordPat = R'<alpha>(<^alpha>|$)'
    oneLetterAnWordPat = R'<nocase>[aefhilmnorsx]'
    alphaCharPat = R'<alpha>'
    elevenEighteenPat = R'1[18](<^digit>|$)'

    /*
     *   Get the plural form of the given name.  If the string ends in
     *   vowel-plus-'y' or anything other than 'y', we'll add an 's';
     *   otherwise we'll replace the 'y' with 'ies'.  We also handle
     *   abbreviations and individual letters specially.
     *   
     *   This can only deal with simple adjective-noun forms.  For more
     *   complicated forms, particularly for compound words, it must be
     *   overridden (e.g., "Attorney General" -> "Attorneys General",
     *   "man-of-war" -> "men-of-war").  We recognize a fairly extensive
     *   set of special cases (child -> children, man -> men), as listed in
     *   the irregularPlural lists in any CustomVocab objects.  Add new
     *   items to the irregular plural list by creating one or more
     *   CustomVocab objects with their own irregularPlural lists.  
     */
    pluralNameFrom(str)
    {
        local str2;
        
        /* check for a 'phrase prep phrase' format */
        if (str.find(prepPhrasePat) != nil)
        {
            /*
             *   Pull out the two parts - the part up to the 'of' is the 
             *   part we'll actually pluralize, and the rest is a suffix 
             *   we'll stick on the end of the pluralized part. 
             */
            str = rexGroup(1)[3];
            str2 = rexGroup(2)[3];

            /*
             *   now pluralize the part up to the 'of' using the normal
             *   rules, then add the rest back in at the end
             */
            return pluralNameFrom(str) + str2;
        }

        /* parse out the last word */
        rexMatch(lastWordPat, str);

        /* pluralize the last word */
        str = rexGroup(1)[3];
        str2 = rexGroup(2)[3];
        return str + pluralWordFrom(str2, '&rsquo;');
    }

    /* 
     *   if we need to add 's as the plural ending - this should be either
     *   a simple straight quote ('\''), or HTML markup for a curly quote
     *   regular expression for separating the main phrase and
     *   prepositional phrase from a "noun prep noun" phrase 
     */
    prepPhrasePat = static new RexPattern(
        '^(.+)(<space>+(<<prepList>>)<space>+.+)$')

    /* pattern for pulling the last word out of a phrase */
    lastWordPat = R'^(.*?)(<^space>*)<space>*$'

    /*
     *   Get the plural of the given word.  If there's an irregular plural
     *   entry for the word, we return that; otherwise we infer the plural
     *   from the spelling.  'apost' is the string to use for an apostrophe
     *   ('&rsquo;').  
     */
    pluralWordFrom(str, apost)
    {
        local irr;
        local len;

        /* 
         *   Check for irregulars from our table.  If we find an entry, use
         *   the first plural in the list, since it's the preferred form in
         *   cases where there are multiple variations (e.g., indices vs.
         *   indexes).  
         */
        if ((irr = irregularPlurals[str]) != nil)
            return irr[1];

        /* check for words ending in 'man' */
        if (rexMatch(menPluralPat, str))
            return '<<rexGroup(1)[3]>>men';

        /* if the string is empty, return empty */
        len = str.length();
        if (len == 0)
            return '';

        /*
         *   Certain plurals are formed with apostrophe-s.  This applies to
         *   single lower-case letters; certain upper-case letters that
         *   would be ambiguous without the apostrophe, because they'd
         *   otherwise look like words or common abbreviations (As, Es, Is,
         *   Ms, Us, Vs); and words made up of initials with periods
         *   between each letter.  
         */
        if (rexMatch(apostPluralPat, str) != nil)
            return '<<str>><<apost>>s';

        /* for any other single letter, return the letter + 's' */
        if (len == 1)
            return '<<str>>s';

        /* for all-capital words (CPA, PC) or numbers, just add -s */
        if (rexMatch(acronymPluralPat, str) != nil)
            return '<<str>>s';

        /* check for -es plurals */
        if (rexMatch(esPluralPat, str) != nil)
            return '<<str>>es';

        /* check for 'y' -> 'ies' plurals */
        if (rexMatch(iesPluralPat, str) != nil)
            return '<<rexGroup(1)[3]>>ies';

        /* for anything else, just add -s */
        return '<<str>>s';
    }

    /* lookup table for irregular plurals - we build this at preinit time */
    irregularPlurals = nil
    
    /* regular expression for trimming leading and trailing spaces */
    trimPat = R'^<space>+|<space>+$'

    /* pattern for nouns with -es plurals */
    esPluralPat = R'^.*((?!o)o|u|sh|ch|ss|z|x|us)$'

    /* pattern for nouns y -> -ies plurals) */
    iesPluralPat = R'<case>^((?![A-Z]).*[^aeoAEO])y$'

    /* pattern for words ending in 'men' (chairman, fireman, etc) */
    menPluralPat = R'^(.*)man$'

    /* pattern for plurals that add apostrophe-s */
    apostPluralPat = R'<case>^(<lower|A|E|I|M|U|V>|(<alpha><dot>)+)$'

    /* pattern for acronyms and numbers */
    acronymPluralPat = R'<case>^<upper|digit>+$'

    /* class property: the main dictionary StringComparator */
    dictComp = static new StringComparator(truncationLength, nil, nil)

    /* 
     *   class property: the truncation length to use for the main dictionary
     *   StringComparator. 
     */
    truncationLength = 8
    
    
    /* class property: pronoun lookup table (built during preinit) */
    pronounMap = nil
 
    
    /* 
     *   The dummyName is a property that displays nothing, for use when we want
     *   to use an object in a sentence without actually displaying any text for
     *   it (e.g. to provide a subject for a verb to agree with).
     */
    dummyName = ''
;


modify SubComponent
    /* 
     *   In addition to the properties copied on the original definition of this
     *   class in his method, we need to copy all the other name related
     *   properties of the parent object that game authors might conceivably
     *   customize.
     */
    nameAs(parent)
    {
        /* Carry out the inherited handling. */
        inherited(parent);
        
        /* Then copy all the other name-related properties. */
        aName = parent.aName;
        theName = parent.theName;
        theObjName = parent.theObjName;
        objName = parent.objName;
        possAdj = parent.possAdj;
        possNoun = parent.possNoun;
//        objInName = parent.objInName;
//        objIntoName = parent.objIntoName;
//        objOutOfName = parent.objOutOfName;
        
    }
    
;


/* ------------------------------------------------------------------------ */
/*
 *   LState is the language-specific base class for State objects.
 *   
 *   [Required] 
 */
class LState: object
    /*
     *   Add the state name to an object name under construction.  'obj' is
     *   the object, and 'str' the object name being built.  This adds the
     *   appropriate adjective for the state to the name.
     *   
     *   [Required] 
     */
    addToName(obj, str)
    {
        /* get the adjective list entry for the object's current state */
        local st = obj.(stateProp);
        local adj = adjectives.valWhich({ ele: ele[1] == st });

        /* add it to the name */
        return '<<adj[2][1]>> <<str>>';
    }

    /*
     *   Initialize a state adjective.  The base library calls this during
     *   preinit for each word, given as a string.  The language module
     *   must define this routine, but it doesn't have to do anything.  The
     *   English version adds the word to the dictionary, so that the
     *   spelling corrector can recognize it.
     *   
     *   [Required] 
     */
    initWord(w)
    {
        /* add it to the dictionary */
        cmdDict.addWord(dictionaryPlaceholder, w, &noun);
    }
    
    /*  
     *   Additional info to be added to the item name when it appears in a
     *   listing and is in the corresponding state
     */
    additionalInfo = []
    
    /* 
     *   Get the string providing additional info about this object when it's in
     *   a particular state (such as '(providing light)', the only additional
     *   state info actually defined in the English library)
     */
    getAdditionalInfo(obj)
    {
        /* get the info list entry for the object's current state */
        local st = obj.(stateProp);
        local info = additionalInfo.valWhich({ ele: ele[1] == st });
        
        return info != nil ? info[2] : '';
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   Common object states.  The objects themselves are cross-language and
 *   thus are required, but the base library leaves it up to the language
 *   modules to provide the actual definitions, since the body of each
 *   definition is mostly vocabulary words.  
 */

/*
 *   Lit/Unlit state.  This is useful for light sources and flammable
 *   objects.
 *   
 *   [Required] 
 */
LitUnlit: State
    stateProp = &isLit
    adjectives = [[nil, ['unlit']], [true, ['lit']]]
    appliesTo(obj) { return obj.isLightable || obj.isLit; }
    additionalInfo = [[true, ' (providing light)']]
;

/*
 *   Open/Closed state.  This is useful for things like doors and
 *   containers.  
 */
OpenClosed: State
    stateProp = &isOpen
    adjectives = [[nil, ['closed']], [true, ['open']]]
    appliesTo(obj) { return obj.isOpenable; }
;

/*  
 *   DirState. This is useful for SymConnectors and the like, whose directional
 *   vocab may change according to which direction they're approached from.
 */
DirState: State
    stateProp = &attachedDir
    adjectives = [[&north, ['north', 'n']], [&south, ['south', 's']],
        [&east, ['east', 'e']], [&west, ['west', 'w']],
        [&southeast, ['southeast', 'se']], [&northeast, ['northeast', 'ne']],
        [&southwest, ['southwest', 'sw']], [&northwest, ['northwest', 'nw']],
        [&port, ['port', 'p']], [&starboard, ['starboard', 'sb']],
        [&fore, ['fore', 'f', 'forward']], [&aft, ['aft']],
        [&up, ['up', 'upward']], [&down, ['down', 'downward'] ],
        [&in, ['in', 'inner', 'inward']], [&out, ['out', 'outer', 'outward']]
    ]
;

/*  
 *   Modifications to TopicPhrase to make it work better with the
 *   English-specific part of the library.
 */
modify TopicPhrase
    matchNameScope(cmd, scope)
    {
        
        local toks = tokens;
        local ret;
        
        /* 
         *   Strip any apostrophe-S from our tokens since the vocab words
         *   initialization will have done the same
         */        
        tokens = tokens.subset({x: x != '\'s'});
        
        /* 
         *   Strip any articles out of the tokens. We need to do this in the
         *   English library to ensure that we get a sensible match to a Topic
         *   when the player's input includes articles (e.g. ASK ABOUT THE
         *   DARK), since the parser will first try to match items that include
         *   the tokens 'the' and 'dark' in their vocabWords, with results that
         *   may not be what we want.
         */        
        tokens = tokens.subset({x: x not in ('a', 'the', 'an')});
        
        
        try
        {
            /* Carry out the inherited handling and store the result */
            ret = inherited(cmd, scope);
        }
        finally
        {
            /* Restore the original tokens on the way out. */
            tokens = toks;
        }
        
        /* Return the result of the inherited handling. */
        return ret;
    }
    
;

/* 
 *   Modification to the ResolvedTopic for use with the English-language
 *   specific part of the library.
 */
modify ResolvedTopic
    
    /* 
     *   The English Tokenizer separates apostrophe-S from the word it's part
     *   of, so in restoring the original text we need to join any apostrophe-S
     *   back to the word it was separated from.
     */    
    getTopicText()
    {
        local str = tokens.join(' ').trim();
        str = str.findReplace(' \'s', '\'s', ReplaceAll);
        return str;        
    }
    
;

/* 
 *   Modification to the Topic class so that when constructing a new Topic a
 *   separate apostrophe-S token is concatenated with the previous word when
 *   storing the name (which undoes the effect on building the name of what the
 *   English-language tokenizer does with apostrophe-S).
 */
modify Topic
    construct(name_)
    {
        name_ = name_.findReplace(' \'s', '\'s', ReplaceAll);
        inherited(name_);
    }
    
;

/* 
 *   Modification to the Command class so that when reconstructing a command
 *   string from its tokens a separate apostrophe-S token is concatenated with
 *   the previous word when storing the name (which undoes the effect on
 *   building the name of what the English-language tokenizer does with
 *   apostrophe-S).
 */
modify Command
    buildCommandString()
    {
        local str = valToList(verbProd.tokenList).mapAll({x:        
            getTokVal(x)}).join(' ');
        str = str.findReplace(' \'s', '\'s', ReplaceAll);
        return str;         
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   English modifications for Thing.  This adds some methods that vary by
 *   language, so they can't be defined in the generic Thing class.  
 */
modify Thing
    /*
     *   Show the nested room subhead.  This shows the actor's immediate
     *   container as an addendum to the room name in the room description
     *   headline.
     *   
     *   [Required] 
     */
    roomSubhead(pov)
    {
        " (<<childLocType(pov).prep>> <<theName>>)";
    }
    
    /* Did the player's command ask to PUSH this object ? */
    matchPushOnly = (gVerbWord == 'push')
    
    /* Did the player's command ask to PULL this object? */
    matchPullOnly = (gVerbWord is in ('pull', 'drag'))
    
    /* 
     *   Check whether we need to add or remove the LitUnlit State from our list
     *   of states.
     */
    makeLit(stat)
    {
        inherited(stat);
        
        if(LitUnlit.appliesTo(self))
            states = states.appendUnique([LitUnlit]);
        else
            states -= LitUnlit;
    }
    
    /* 
     *   Announce Best Choice name. This can be used in those rare cases where
     *   you want to override the name the parser uses to describe an object
     *   when announcing its best choice of object. For example, if you have a
     *   bottle of wine from which you can fill a glass, you might prefer '(with
     *   wine from the bottle)' to '(with the bottle of wine)' following FILL
     *   GLASS; action is the action being carried out for which the object has
     *   been chosen and role(DirectObject or IndirectObject) is the role the
     *   chosen object is playing in the action. By default this method just
     *   returns theName.
     */
    abcName(action, role)
    {
        return theName;
    }
    
;



/*-------------------------------------------------------------------------- */
/*  
 *   English language modifications to Room. Here we simply allow a Room to take
 *   its vocab from its roomTitle property if vocab is not already defined; this
 *   reduces the need to type the same text twice when the two are effectively
 *   the same.
 */
modify Room
    initVocab()
    {
        /* 
         *   If our vocab property isn't already defined, take it from our
         *   roomTitle, converting it to lower case, provided proper is false.
         */
        if(vocab == nil && autoName && roomTitle)            
            vocab = proper ? roomTitle : roomTitle.toLower() ;
        
        /* Carry out the inherited handling */
        inherited();
    }
    
    /* 
     *   Flag: do we want this room to take its vocab (and hence its name) from
     *   its roomTitle property if its vocab property isn't explicitly defined?
     *   By default we do.
     */
    autoName = true
;



/* 
 *   Modifications to Pronoun to ensure that aName, theName and theObjName
 *   return the appropriate results.
 */
modify Pronoun
    aName = (name)
    theName = (name)
    theObjName = (objName)  
    
;

/* ------------------------------------------------------------------------ */
/*
 *   Base library vocabulary initialization.  For the English module's own
 *   convenience, we add vocabulary words to a number of abstract
 *   grammar-related objects defined in the base library parser.  The base
 *   library can't define vocabulary, for obvious reasons, so we have to
 *   add the vocabulary words ourselves.  
 */
property prep;
pronounPreinit: PreinitObject
    execute()
    {
        /* 
         *   Initialize the pronoun names.  These are used only within the
         *   English library.  Other language modules will probably need to
         *   define vocabulary for pronouns as well, but the specific
         *   properties are up to the translator.  Languages that have more
         *   noun cases than English can add properties for the extra noun
         *   cases as needed.  
         */
        It.name = It.objName = 'it';
        It.possAdj = It.possNoun = 'its';
        It.thatName = It.thatObjName = 'that';
	It.reflexive = Itself;

        Her.name = 'she';
        Her.objName = Her.possAdj = 'her';
        Her.possNoun = 'hers';
	Her.reflexive = Herself;

        Him.name = 'he';
        Him.objName = 'him';
        Him.possAdj = Him.possNoun = 'his';
	Him.reflexive = Himself;

        Them.name = 'they';
        Them.objName = 'them';
        Them.possAdj = 'their';
        Them.possNoun = 'theirs';
        Them.thatName = Them.thatObjName = 'those';
	Them.reflexive = Themselves;
        Them.plural = true;
        
        You.name = You.objName = 'you';
        You.possAdj = 'your';
        You.possNoun = 'yours';
	You.reflexive = Yourself;

        Yall.name = Yall.objName = 'you';
        Yall.possAdj = 'your';
        Yall.possNoun = 'yours';
	Yall.reflexive = Yourselves;
        Yall.plural = true;

        Me.name = 'I';
        Me.objName = 'me';
        Me.possAdj = 'my';
        Me.possNoun = 'mine';
	Me.reflexive = Myself;

        Us.name = 'we';
        Us.objName = 'us';
        Us.possAdj = 'our';
        Us.possNoun = 'ours';
	Us.reflexive = Ourselves;
        Us.plural = true;
        

        Myself.name = Myself.objName = 'myself';
        Yourself.name = Yourself.objName = 'yourself';
        Itself.name = Itself.objName = 'itself';
        Herself.name = Herself.objName = 'herself';
        Himself.name = Himself.objName = 'himself';
        Ourselves.name = Ourselves.objName = 'ourselves';
        Yourselves.name = Yourselves.objName = 'yourselves';
        Themselves.name = Themselves.objName = 'themselves';

        /* 
         *   Set the default 'that' name for each pronoun to its regular
         *   name.  We use the regular pronoun instead of 'that' for any
         *   gendered noun or first- or second-person object.  
         */
        foreach (local pro in Pronoun.all)
        {
            if (pro.thatName == nil)
                pro.thatName = pro.name;
            if (pro.thatObjName == nil)
                pro.thatObjName = pro.objName;
        }

        /* create the pronoun map for LMentionable */
        LMentionable.pronounMap = new LookupTable(16, 32);
        forEachInstance(Pronoun, function(p) {
            LMentionable.pronounMap[p.name] = p;
            if (p.objName != nil)
                LMentionable.pronounMap[p.objName] = p;
        });

        /* 
         *   Initialize the LocType prepositions.  The 'prep' property is
         *   English-specific and is NOT used by the base library, but
         *   other language modules will probably need some type of
         *   corresponding vocabulary for each LocType.  
         */
        In.prep = 'in';
        Outside.prep = 'on';
        On.prep = 'on';
        Under.prep = 'under';
        Behind.prep = 'behind';
        Held.prep = 'held by';
        Worn.prep = 'worn by';
        Attached.prep = 'attached to';
        PartOf.prep = 'part of';
    }
;
    

/* ------------------------------------------------------------------------ */
/*
 *   CustomVocab objects define special-case vocabulary for the parser and
 *   name generation routines.
 *   
 *   The library provides a CustomVocab object with many common
 *   special-case words, but games and extensions can augment the built-in
 *   lists by defining their own CustomVocab objects that follow the same
 *   patterns.  The library automatically includes all of the special word
 *   lists in all of the CustomVocab objects defined throughout the game.  
 */
class CustomVocab: object
    /* 
     *   The list of special-case a/an words.  Choosing 'a' or 'an' is
     *   purely phonetic, and English orthography is notoriously
     *   inconsistent phonetically.  What's more, the choice for many words
     *   varies by dialect, accent, and personal style.  We try to cover as
     *   much as we can in our spelling-based rules, but it's hopeless to
     *   cover all the bases purely with spelling.  At some point we just
     *   have to turn to a table of special cases.
     *   
     *   We apply the special rules based on the first word in a name.  The
     *   first word is simply the first contiguous group of alphanumeric
     *   characters.  If the first word in a name is found in this list,
     *   the setting here will override any spelling rules.
     *   
     *   The entries here are simply strings of the form 'a word' or 'an
     *   word'.  Start with the appropriate form of a/an, then add a space,
     *   then the special word to match.
     */
    specialAOrAn = []

    /* 
     *   Irregular plural list.  This is a list of words with plurals that
     *   can't be inferred from any of the usual spelling rules.  The
     *   entries are in pairs: singular, [plurals].  The plurals are given
     *   in a list, since some words have more than one valid plural.  The
     *   first plural is the preferred one; the remaining entries are
     *   alternates.  
     */
    irregularPlurals = []

    /*
     *   Verbs for substitution parameter strings.  This is a list of
     *   strings, using the following template:
     *   
     *.     'infinitive/present3/past/past-participle'
     *   
     *   The 'infinitive' is the 'to' form of the verb (to go, to look, to
     *   see), but *without* the word 'to'.  'present3' is the third-person
     *   present form (is, goes, sees).  'past' is the past tense form
     *   (went, looked, saw).  'past-participle' is the past participle
     *   form; this is optional, and is needed only for verbs with distinct
     *   past and past participle forms (e.g., saw/seen, went/gone).  Most
     *   regular verbs - those with the past formed by adding -ed to the
     *   infinitive - have identical past and participle forms.
     *   
     *   For every English verb except "to be", the entire present and past
     *   conjugations can be derived from these three bits of information.
     *   The past perfect, future, and future perfect conjugations can also
     *   be derived from this information, for any verb except "to be" and
     *   the auxiliary verbs (could, should, etc).  The English library
     *   pre-defines "to be" and all of the auxiliary verbs, so there's no
     *   need to define those with this mechanism.  
     */
    verbParams = []
;

/*
 *   Custom English vocabulary.  Here we define a basic dictionary of
 *   irregular plurals, a/an words, and verb parameters.  Games that want
 *   to save a little compiled file space might want to replace this with a
 *   set that only defines the words actually needed in the game.  Games
 *   are free to define additional custom vocabulary words by adding their
 *   own CustomVocab objects; the library will automatically find and merge
 *   them into the dictionary during preinit.  
 */
englishCustomVocab: CustomVocab
    /* irregular plurals */
    irregularPlurals = [
        'calf', ['calves', 'calfs'],
        'elf', ['elves', 'elfs'],
        'half', ['halves', 'halfs'],
        'hoof', ['hooves', 'hoofs'],
        'knife', ['knives'],
        'leaf', ['leaves'],
        'life', ['lives'],
        'loaf', ['loaves'],
        'scarf', ['scarves', 'scarfs'],
        'self', ['selves', 'selfs'],
        'sheaf', ['sheaves', 'sheafs'],
        'shelf', ['shelves'],
        'bookshelf', ['bookshelves'],
        'thief', ['thieves'],
        'wife', ['wives'],
        'wolf', ['wolves'],

        'foot', ['feet'],
        'goose', ['geese'],
        'louse', ['lice'],
        'mouse', ['mice'],
        'tooth', ['teeth'],

        'auto', ['autos'],
        'kilo', ['kilos'],
        'memo', ['memos'],
        'motto', ['mottos'],
        'photo', ['photos'],
        'piano', ['pianos'],
        'pimento', ['pimentos'],
        'pro', ['pros'],
        'solo', ['solos'],
        'soprano', ['sopranos'],
        'studio', ['studios'],
        'video', ['videos'],

        'die', ['dice', 'dies'],

        'alga', ['algae'],
        'larva', ['larvae', 'larvas'],
        'vertebra', ['vertebrae'],

        'alumnus', ['alumni'],
        'alumna', ['alumnae'],
        'bacillus', ['bacilli'],
        'cactus', ['cacti', 'catuses'],
        'focus', ['foci', 'focuses'],
        'fungus', ['fungi', 'funguses'],
        'nucleus', ['nuclei'],
        'octopus', ['octopi', 'octopuses'],
        'radius', ['radii'],
        'stimulus', ['stimuli'],
        'terminus', ['termini'],

        'addendum', ['addenda'],
        'bacterium', ['bacteria'],
        'cirriculum', ['cirricula'],
        'datum', ['data'],
        'erratum', ['errata'],
        'medium', ['media'],
        'memorandum', ['memoranda'],
        'ovum', ['ova'],
        'stratum', ['strata'],
        'symposium', ['symposia'],

        'appendix', ['appendices', 'appendixes'],
        'index', ['indices', 'indexes'],
        'matrix', ['matrices', 'matrixes'],
        'vortex', ['vortices', 'vortexes'],

        'analysis', ['analyses'],
        'axis', ['axes'],
        'basis', ['bases'],
        'crisis', ['crises'],
        'diagnosis', ['diagnoses'],
        'emphasis', ['emphases'],
        'hypothesis', ['hypotheses'],
        'neurosis', ['neuroses'],
        'parenthesis', ['parentheses'],
        'synopsis', ['synopses'],
        'thesis', ['theses'],

        'criterion', ['criteria'],
        'phenomenon', ['phenomena'],
        'automaton', ['automata'],

        'libretto', ['libretti'],
        'tempo', ['tempi'],
        'virtuoso', ['virtuosi'],
        'cherub', ['cherubim'],
        'seraph', ['seraphim'],
        'schema', ['schemata'],

        'barracks', ['barracks'],
        'crossroads', ['crossroads'],
        'dice', ['dice'],
        'gallows', ['gallows'],
        'headquarters', ['headquarters'],
        'means', ['means'],
        'offspring', ['offspring'],
        'series', ['series'],
        'species', ['species'],
        'cattle', ['cattle'],
        'billiards', ['billiards'],
        'clothes', ['clothes'],
        'pants', ['pants'],
        'measles', ['measles'],
        'thanks', ['thanks'],
        'pliers', ['pliers'],
        'scissors', ['scissors'],
        'shorts', ['shorts'],
        'trousers', ['trousers'],
        'tweezers', ['tweezers'],
        'glasses', ['glasses'],
        'eyeglasses', ['eyeglasses'],
        'spectacles', ['spectacles'],
        'information', ['information'],
        'honesty', ['honesty'],
        'wisdom', ['wisdom'],
        'beauty', ['beauty'],
        'intelligence', ['intelligence'],
        'stupidity', ['stupidity'],
        'curiosity', ['curiosity'],
        'chemistry', ['chemistry'],
        'geometry', ['geometry'],
        'physics', ['physics'],
        'mechanics', ['mechanics'],
        'optics', ['optics'],
        'dynamics', ['dynamics'],
        'thermodynamics', ['thermodynamics'],
        'linguistics', ['linguistics'],
        'acoustics', ['acoustics'],
        'mathematics', ['mathematics'],
        'jazz', ['jazz'],
        'traffic', ['traffic'],
        'sand', ['sand'],
        'air', ['air'],
        'water', ['water'],
        'furniture', ['furniture'],
        'equipment', ['equipment'],
        
        'cod', ['cod', 'cods'],
        'deer', ['deer', 'deers'],
        'fish', ['fish', 'fishes'],
        'perch', ['perch', 'perches'],
        'sheep', ['sheep'],
        'trout', ['trout', 'trouts']
    ]

    /* special-case 'a' vs 'an' words */
    specialAOrAn = [
        'an heir',
        'an honest',
        'an honor',
        'an honour',
        'an hors',
        'an hour',
        'a one',
        'a ouija',
        'a unified',
        'a union',
        'a unit',
        'a united',
        'a unity',
        'a universal',
        'a university',
        'a universe',
        'a unicycle',
        'a unicorn',
        'a usage',
        'a user'
    ]

    /* verb parameters, for {xxx} tokens in message strings */
    verbParams = [                
        'arise/arises/arose/arisen',        
        'awake/awakes/awoke/awoken',        
        'bear/bears/bore/born',
        'beat/beats/beat/beaten',
        'become/becomes/became/become',
        'begin/begins/began/begun',
        'behold/beholds/beheld',
        'bend/bends/bent',
        'bet/bets/bet',
        'bid/bids/bade/bidden',
        'bind/binds/bound',
        'bite/bites/bit/bitten',
        'bleed/bleeds/bled',
        'blow/blows/blew/blown',                
        'break/breaks/broke/broken',
        'breed/breeds/bred',
        'bring/brings/brought',
        'build/builds/built',
        'burn/burns/burnt',
        'bust/busts/bust',
        'buy/buys/bought',
        'cast/casts/cast',
        'catch/catches/caught',
        'choose/chooses/chose/chosen',
        'clap/claps/clapt',        
        'cling/clings/clung',        
        'come/comes/came',        
        'creep/creeps/crept',
        'cut/cuts/cut',
        'deal/deals/dealt',        
        'dig/digs/dug',
        'dive/dives/dove/dived',
        'do/does/did',        
        'draw/draws/drew/drawn',
        'dream/dreams/dreamt',
        'drink/drinks/drank/drunk',
        'drive/drives/drove/driven',        
        'dwell/dwells/dwelt',
        'eat/eats/ate/eaten',        
        'fall/falls/fell/fallen',        
        'feed/feeds/fed',
        'feel/feels/felt',
        'fight/fights/fought',
        'find/finds/found',
        'fling/flings/flung',        
        'fly/flies/flew/flown',        
        'forbid/forbids/forbade/forbidden',
        'freeze/freezes/froze/frozen',
        'get/gets/got/gotten',
        'give/gives/gave/given',
        'go/goes/went/gone',
        'grind/grinds/ground',
        'grow/grows/grew/grown',
        'handwrite/handwrites/handwrote/handwritten',        
        'hang/hangs/hung',
        'have/has/had',
        'hide/hides/hid/hidden',
        'hit/hits/hit',
        'hold/holds/held',
        'hurt/hurts/hurt',
        'inlay/inlays/inlaid',
        'input/inputs/input',
        'interlay/interlays/interlaid',        
        'keep/keeps/kept',
        'kneel/kneels/knelt',
        'knit/knits/knit',
        'know/knows/knew/known',        
        'lay/lays/laid',
        'lead/leads/led',
        'leans/leans/leant',
        'leap/leaps/leapt',
        'learn/learns/learnt',
        'leave/leaves/left',
        'lend/lends/lent',
        'let/lets/let',
        'lie/lies/lay/lain',
        'light/lights/lit',        
        'lose/loses/lost',
        'make/makes/made',
        'mean/means/meant',
        'meet/meets/met',
        'melt/melts/melted/molten',
        'mislead/misleads/misled',
        'mistake/mistakes/mistook/mistaken',
        'misunderstand/misunderstands/misunderstood',
        'miswed/misweds/miswed',        
        'mow/mows/mowed/mown',        
        'overdraw/overdraws/overdrew/overdrawn',
        'overhear/overhears/overheard',
        'overtake/overtakes/overtook/overtaken',        
        'pay/pays/paid',        
        'preset/presets/preset',
        'prove/proves/proved/proven',
        'put/puts/put',
        'quit/quits/quit',        
        'read/reads/read',
        'rid/rids/rid',
        'ride/rides/rode/ridden',
        'ring/rings/rang/rung',
        'rise/rises/rose/risen',
        'rive/rives/rived/riven',        
        'run/runs/ran/run',        
        'saw/saws/sawed/sawn',
        'sew/sews/sewed/sewn',
        'say/says/said',
        'see/sees/saw/seen',        
        'set/sets/set',
        'shake/shakes/shook/shaken',
        'shave/shaves/shaved/shaven',
        'shear/shears/shore',
        'shed/sheds/shed',
        'shine/shines/shone',
        'shoe/shoes/shod',
        'shoot/shoots/shot',        
        'show/shows/showed/shown',
        'shrink/shrinks/shrank/shrunk',
        'shut/shuts/shut',
        'sing/sings/sang/sung',
        'sit/sits/sat',
        'slay/slays/slew/slain',
        'sleep/sleeps/slept',
        'slide/slides/slid',
        'sling/slings/slung',
        'slink/slinks/slunk',
        'slit/slits/slit',
        'smell/smells/smelt',
        'sneak/sneaks/snuck',
        'soothsay/soothsays/soothsaid',
        'sow/sows/sowed/sown',
        'speak/speaks/spoke/spoken',
        'speed/speeds/sped',
        'spell/spells/spelt',
        'spend/spends/spent',
        'spill/spills/spilt',
        'spin/spins/span/spun',
        'spit/spits/spat',
        'split/splits/split',
        'spoil/spoils/spoilt',
        'spread/spreads/spread',
        'spring/springs/sprang/sprung',
        'stand/stands/stood',
        'steal/steals/stole/stolen',
        'stick/sticks/stuck',
        'sting/stings/stung',
        'stink/stinks/stank/stunk',
        'stride/strides/strode/stridden',
        'strike/strikes/struck/stricken',
        'strive/strives/strove/striven',
        'sublet/sublets/sublet',
        'sunburn/sunburns/sunburnt',
        'swear/swears/swore/sworn',
        'sweat/sweats/sweat',
        'sweep/sweeps/swept',
        'swell/swells/swelled/swollen',
        'swim/swims/swam/swum',
        'swing/swings/swung',        
        'take/takes/took/taken',        
        'teach/teaches/taught',
        'tear/tears/tore/torn',
        'tell/tells/told',
        'think/thinks/thought',
        'thrive/thrives/throve/thrived',
        'throw/throws/threw/thrown',
        'thrust/thrusts/thrust',
        'tread/treads/trod/trodden',        
        'undergo/undergoes/underwent/undergone',
        'understand/understands/understood',
        'undertake/undertakes/undertook/undertaken',        
        'upset/upsets/upset',
        'vex/vexes/vext',      
        'wake/wakes/woke/woken',        
        'wear/wears/wore/worn',
        'weave/weaves/wove/woven',
        'wed/weds/wed',
        'weep/weeps/wept',
        'wend/wends/went',
        'wet/wets/wet',
        'will/will/would',
        'win/wins/won',
        'wind/wind/wound',
        'withdraw/withdraws/withdrew/withdrawn',
        'withhold/withholds/withheld',
        'withstand/withstands/withstood',
        'won\'t/won\'t/would not',        
        'wring/wrings/wrung',
        'write/writes/wrote',
        'zinc/zincks/zincked'        
    ]
;

/* ------------------------------------------------------------------------ */
/*
 *   Generate a spelled-out version of the given number value, or simply a
 *   string representation of the number.  We follow fairly standard
 *   English style rules:
 *   
 *.    - we spell out numbers below 100
 *.    - we also spell out round figures above 100 that can be expressed
 *.      in two words (e.g., "fifteen thousand" or "thirty million")
 *.    - for millions and billions, we write, e.g., "1.7 million", if possible
 *.    - for anything else, we return the decimal digits, with commas to
 *.      separate groups of thousands (e.g., 120,400)
 *   
 *   Other languages might have different style rules, so the choice using
 *   a spelled-out number or digits might vary by language.
 *   
 *   [Required] 
 */
spellNumber(n)
{
    /* get the number formatting options */
    local dot = englishOptions.decimalPt;
    local comma = englishOptions.numGroupMark;
    
    /* if it's a BigNumber with a fractional part, write as digits */
    if (dataType(n) == TypeObject
        && n.ofKind(BigNumber)
        && n.getFraction() != 0)
    {
        /* 
         *   format it, and convert decimals and group separators per the
         *   options 
         */
        return n.formatString(n.getPrecision(), BignumCommas).findReplace(
            ['.', ','], [dot, comma]);
    }

    /* if it's less than zero, use "minus seven" or "-123" */
    if (n < 0)
    {
        /* get the spelled version of the absolute value */
        local s = spellNumber(-n);

        /* if it has any letters, use "minus", otherwise "-" */
        return (s.find(R'<alpha>') != nil ? 'minus ' : '-') + s;
    }

    /* spell anything less than 100 */
    if (n < 100)
    {
        if (n < 20)
            return ['zero', 'one', 'two', 'three', 'four', 'five', 'six',
                    'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve',
                    'thirteen', 'fourteen', 'fifteen', 'sixteen',
                    'seventeen', 'eighteen', 'nineteen'][n+1];
        else
            return ['twenty', 'thirty', 'forty', 'fifty', 'sixty',
                    'seventy', 'eighty', 'ninety'][n/10-1]
            + ['', '-one', '-two', '-three', '-four', '-five', '-six',
               '-seven', '-eight', '-nine'][n%10 + 1];
    }

    /* spell out single-digit multiples of 100 */
    if (n % 100 == 0 && n/100 < 10)
        return '<<spellNumber(n/100)>> hundred';
    
    /* 
     *   Spell out single-digit multiples of each power of 10 from a thousand to
     *   a billion.
     */
    if (n % 1000000000 == 0 && n/1000000000 < 10)
        return '<<spellNumber(n/1000000000)>> billion';
    if ((n % 1000000 == 0 && n/1000000 < 10)
        || (n % 10000000 == 0 && n/10000000 < 10)
        || (n % 100000000 == 0 && n/100000000 < 10))
        return '<<spellNumber(n/1000000)>> million';
    if ((n % 1000 == 0 && n/1000 < 10)
        || (n % 10000 == 0 && n/10000 < 10)
        || (n % 100000 == 0 && n/100000 < 10))
        return '<<spellNumber(n/1000)>> thousand';

    /*
     *   check to see if it can be expressed as a whole number of millions or
     *   billions, or as millions or billions using up to three significant
     *   figures ("1.75 million", "17.5 billion")
     */
    if (n % 1000000 == 0 && n/1000000 < 1000)
        return '<<n/1000000>> million';
    if (n % 100000 == 0 && n/1000000 < 100)
        return '<<n/1000000>><<dot>><<n%1000000 / 100000>> million';
    if (n % 10000 == 0 && n/1000000 < 10)
        return '<<n/1000000>><<dot>><<n%1000000 / 10000>> million';
    if (n % 1000000000 == 0 && n/1000000000 < 1000)
        return '<<n/1000000000>> billion';
    if (n % 100000000 == 0 && n/1000000000 < 100)
        return '<<n/1000000000>><<dot>><<n%1000000000 / 100000000>> billion';
    if (n % 10000000 == 0 && n/1000000000 < 10)
        return '<<n/1000000000>><<dot>><<n%1000000000 / 10000000>> billion';

    /* convert to digits */
    local s = toString(n);

    /* insert commas at the thousands */
    for (local i = s.length() - 2 ; i > 1 ; i -= 3)
        s = s.splice(i, 0, comma);

    /* return the result */
    return s;
}

/* 
 *   Try to convert a spelled out number (e.g. 'ninety-six') to its integer
 *   representation. If this fails, return nil.
 */
spelledToInt(str)
{
    /* Tokenize the input string */
    local toks = cmdTokenizer.tokenize(str);
    
    /* Try parsing the tokens against the spelledNumber production */
    local lst = spelledNumber.parseTokens(toks, cmdDict);
    
    /*  If there's a vlid result, convert it to an integer. */
    if(lst.length > 0)
        return lst[1].numval();
    
    /* Otherwise return nil */
    return nil;
}

  
   


/* ------------------------------------------------------------------------ */
/*
 *   List display routines
 */
modify Lister
    /* 
     *   Show the list as an 'and' list, that is a list of the aNames of each
     *   item in lst formatted with commas between list elements and 'and'
     *   between the last two items in the list.
     */
    showList(lst, pl, paraCnt)
    {        
        "<<andList(lst.mapAll({ o: o.aName }))>>";
    }
    
;

/* 
 *   Modifications to the ItemLister (the base class for listers that list
 *   physical objects) for the English-language part of the library.
 */
modify ItemLister    
    
    /* 
     *   For an item lister we use the listName method of the lister rather than
     *   the aName property of the object to provide a name for the object; this
     *   allows the lister to add status-specific information like '(providing
     *   light)' or '(being worn)' to the name as it appears in the list.
     */
    showList(lst, pl, parent)   
    {        
        "<<andList(lst.mapAll({ o: listName(o) }))>>";        
    }
    
    /* 
     *   The listName is the aName of o plus any status-specific information we
     *   might want to appear in the listing, such as '(providing light)'
     */
    listName(o)
    {
        /* Store the object name in a local variable */
        local lName = o.aName;
        
        /* 
         *   Add any additional state-specific info, such as  ' (providing
         *   light)', to the name of this object.
         */
        if(showAdditionalInfo)
        {
            foreach(local state in o.states)
                lName += state.getAdditionalInfo(o);
        }            

        /* 
         *   If this object is being worn and we want to show information about
         *   objects being worn, add ' (being worn)' to the name
         */
        if(o.wornBy != nil && showWornInfo)
            lName += BMsg(being worn, ' (being worn)');
        
        /* 
         *   If the object being listed has visible contents, list its visible contents recursively.
         *   Then do the same for any remapIn or remapOn subcomponents.
         */        
        if(showSubListing)
        {
            local lists = [o];
            
            if(o.remapIn)
                lists += o.remapIn;
            
            if(o.remapOn)                
                lists += o.remapOn;
            
            foreach(local s in lists)
            {
                if(s.contents != nil && s.contents.length > 0 && s.canSeeIn)          
                {
                    lName += subLister.buildList(s.contents);
                    s.contents.forEach({x: x.mentioned = true});
                }
                
            }
        }     
        
               
        /* 
         *   Return the result, i.e. the aName of the object plus any additional
         *   information about its state and/or contents.
         */
        return lName;
    }
    
    
    /* 
     *   Flag: do we want to show additional information such as '(providing
     *   light)' after the names of items listed in inventory.
     *   By default we do.
     */
    showAdditionalInfo = true
    
    
    /* 
     *   Flag: do we want to show (bveing worn) after items in an inventory list
     *   that the player character is wearing. By default we do if we're showing
     *   additional info.
     */
    showWornInfo = (showAdditionalInfo)
    
    /* 
     *   Flag: do we want to show the contents of items listed in inventory (in
     *   parentheses after the name, e.g. a bag (in which is a blue ball)). By
     *   default we do.
     */
    showSubListing = true
;

/*  
 *   English-language modifications to the lister used for miscellaneous items
 *   when looking around in a room.
 */
modify lookLister
    showListPrefix(lst, pl, paraCnt)
    {
        "{I} {can} see ";
    }
    
    showListSuffix(lst, pl, paraCnt)
    {
        " {here}.";
    }
    
    showSubListing = (gameMain.useParentheticalListing)
;

/* 
 *   English-language modifications to the lister used for listing items carried
 *   by the player character.
 */
modify inventoryLister
    showListPrefix(lst, pl, paraCnt)
    {
        "<<if paraCnt == 0>>{I} {am}<<else>>, and<<end>> carrying ";
    }
    
    showListSuffix(lst, pl, paraCnt)
    {
        ".";
    }
    
    showListEmpty(paraCnt)
    {
        "{I} {am} empty-handed. ";
    }    
;

/* 
 *   English-language modifications to the lister used for listing items worn
 *   by the player character.
 */
modify wornLister
    showListPrefix(lst, pl, paraCnt)
    {
        "{I} {am} wearing ";
    }
    
    showListSuffix(lst, pl, paraCnt)
    {
        
    }
    
    showListEmpty(paraCnt)
    {
        
    }
     
    /* 
     *   We don't want to show "(being worn)" after items listed after "You are
     *   wearing" since this would clearly be redundant.
     */
    showWornInfo = nil
;

/* 
 *   The subLister is used by other listers such as inventoryLister and
 *   wornLister to show the contents of listed items in parentheses (e.g. '(in
 *   which is a pen, a pencil and a piece of paper). The depth of nesting is
 *   limited by the maxNestingDepth property. 
 */
subLister: ItemLister
    showListPrefix(lst, pl, paraCnt)
    {
        " (<<lst[1].location.objInPrep>> which <<pl ? '{plural} {is}' :
          '{dummy} {is}'>> ";
    }
    
    showListSuffix(lst, pl, paraCnt) { ")"; }
    
    showListEmpty(paraCnt) { }
   
    /* Construct the list contents from lst to a maximum nesting depth */
    buildList(lst)
    {
        /* increase the nesting depth by 1 */
        nestingDepth++;
        
        /* 
         *   if we've gone beyond the maximum nesting depth, simply return an
         *   empty string to stop going any deeper.
         */
        if(nestingDepth > maxNestingDepth)
        {
            /* reduce the nesting depth by 1 */
            nestingDepth--;
            
            /* return an empty string. */
            return '';
        }
    
        /* 
         *   Carry out the inherited handling and store the result in a local
         *   variable.
         */
        local str = inherited(lst);
        
        /* Reduce the nesting depth by 1 */
        nestingDepth--;
        
        /* Return the result */
        return str;
    }
    
    showList(lst, pl, paraCnt)
    {
        "<<andList(lst.mapAll({ o: listName(o) }))>>";
    }
    
    /* The maximum nesting depth this subLister is allowed to reach */
    maxNestingDepth = 1
    
    /* The current nesting depth of this subLister */
    nestingDepth = 0
    
    
    showSubListing = true 
    
    listed(o) { return o.lookListed; }
;


/* 
 *   English language modifications to the descContentsLister, which is used to
 *   list the contents of a container when it's examined.
 */
modify descContentsLister
    showListPrefix(lst, pl, parent)
    {
        gMessageParams(parent);
        
        /* 
         *   If the item whose contents we're listing want to report its
         *   open-or-closed status, start the listing by reporting that it's
         *   open and then say 'and contains'
         */
        if(parent.openStatusReportable)
            "{The subj parent} {is} open and contain{s/ed} ";  
        
        /*  
         *   Otherwise start the listing without explicitly mentioning that the
         *   container is open.
         */
        else
            "{In parent} {i} {see} ";               
        
    }

    showListSuffix(lst, pl, paraCnt)
    {
        ".";
    }
    
    /* 
     *   If there's no contents to list, but the item whose contents we were
     *   trying to list wants to report its open-or-closed status, simply state
     *   that it's open or closed.
     */
    showListEmpty(parent)  
    {
        if(parent.openStatusReportable)
            "\^<<parent.theNameIs>> <<if parent.isOpen>>open<<else>>
            closed<<end>>. ";
    }
    
    /* 
     *   Flag: Show a sublisting (i.e. the contents of the items in our
     *   immediate contents, in parentheses after the name of the item, if the
     *   gameMain option useParentheticalListing is true.
     */
    showSubListing = (gameMain.useParentheticalListing)
;

/* 
 *   English-language modifications to the lister used to list the contents of
 *   containers when looking around in a room.
 */
modify lookContentsLister
    showListPrefix(lst, pl, parent)
    {
        "\^<<parent.objInName>> {i} {see} ";
    }

    showListSuffix(lst, pl, paraCnt)
    {
        ".";
    }    
    
    /* 
     *   Flag: Show a sublisting (i.e. the contents of the items in our
     *   immediate contents, in parentheses after the name of the item, if the
     *   gameMain option useParentheticalListing is true.
     */
    showSubListing = (gameMain.useParentheticalListing)
    
;

/* 
 *   English-language modifications to the lister used to describe the contents
 *   of an openable container when it has just been opened.
 */
modify openingContentsLister
    showListPrefix(lst, pl, parent)
    {
        gMessageParams(parent);
        "Opening {the parent} {dummy} reveal{s/ed} ";        
    }

    showListSuffix(lst, pl, paraCnt)
    {
        ".\n";
    }
    
    showListEmpty(parent)  
    {
        "{I} open{s/ed} {the dobj}. ";
    }
    
    showSubListing = (gameMain.useParentheticalListing)
;


/* 
 *   English-language modifications to the lister used to list the contents of
 *   something that's being looked in (or searched).
 */
modify lookInLister
    showListPrefix(lst, pl, parent)
    {
        gMessageParams(parent);
        "{In parent} {i} {see} ";        
    }

    showListSuffix(lst, pl, paraCnt)
    {
        ".\n";
    }
    
    showListEmpty(parent)  
    {
       
    }
    
    showSubListing = (gameMain.useParentheticalListing)
; 
    
/* 
 *   English-language modifications to the lister used to list the items
 *   attached to a SimpleAttachable.
 */
modify simpleAttachmentLister
    showListPrefix(lst, pl, parent)
    {
        "{I} {see} ";        
    }

    showListSuffix(lst, pl, parent)
    {
        " attached to <<parent.theName>>. ";
    }
     
    showSubListing = (gameMain.useParentheticalListing) 
;

/*  
 *   English-language modifications to the lister used to list the items plugged
 *   into a PlugAttachable.
 */
modify plugAttachableLister
    showListSuffix(lst, pl, parent)
    {
        " plugged into <<parent.theName>>. ";
    }    
;

/* 
 *   The lister used to list the options from which the player can choose when
 *   the game comes to an end.
 */
finishOptionsLister: Lister
    showList(lst, pl, paraCnt)
    {
        /* 
         *   List the options as alternatives (with an 'or' between the last two
         *   items).
         */
        "<<orList(lst.mapAll({ o: o.desc }))>>";
    }
    
    showListPrefix(lst, pl, parent)
    {
        cquoteOutputFilter.deactivate();
         "<.p>Would you like to ";       
    }
    
    
    showListSuffix(lst, pl, paraCnt)
    {
        /* end the question, add a blank line */
        "?\b";
        cquoteOutputFilter.activate();
    }
    
    showSubListing = nil
    
    
;

/* 
 *   Take a list of objects supplied in objList and return a formatted list in a
 *   single quoted string, having first sorted the items in objList in the order
 *   of their listOrder property.
 *
 *   If the nameProp parameter is supplied, we'll use that property for the name
 *   of every item in the list; otherwise we use the aName property by default.
 *
 *   By default the last two items in the list are separated by 'and', but we
 *   can choose a different conjunction by supplying the conjunction parameter.
 */ 
makeListStr(objList, nameProp = &aName, conjunction = 'and')
{
    local lst = [];
    local i = 0;
    local obj;
    objList = valToList(objList);
    
    /* 
     *   Sort the list by listOrder, but only if the items it contains provide
     *   the property, and only if they use it to define an order. If all the
     *   items in the list have the same sortOrder, we don't want to shuffle
     *   them out of their original order by performing an unnecessary sort.
     */       
    if(objList.length > 0 && objList[1].propDefined(&listOrder) &&
       objList.indexWhich({x: x.listOrder != objList[1].listOrder}))
        objList = objList.sort(SortAsc, {a, b: a.listOrder - b.listOrder});
    
    /* Go through every item in our sorted list */
    for(i = 1, obj in objList ; ; ++i)
    {
        /* Mark it as having been mentioned in a list */
        obj.mentioned = true;        
        
        /* Store the value of the nameProp property in a local variable */
        local desc = obj.(nameProp);
        
        /* Add any state-specific information */
        foreach(local state in obj.states)
            desc += state.getAdditionalInfo(obj);
        
        /* Add the expanded name to our list of strings. */
        lst += desc;
    }
    
    
    /* 
     *   Note whether the list would make a singular or plural grammatical
     *   subject if referred to with the {prev} tag.
     */        
    if(objList.length > 1 || (objList.length > 0 && objList[1].plural))
        prevDummy_.plural = true;
    else
        prevDummy_.plural = nil;   
          
    
    /* 
     *   If the list is empty return 'nothing', otherwise use the genList()
     *   function to construct the string representation of the list and return
     *   that.
     */
    return lst == [] ? 'nothing' : genList(lst, conjunction);
       
}

/* 
 *   Function to use with the <<mention a *>> string template. This marks the
 *   object as mentioned in a room description and allows it to be used as the
 *   antecedent of a {prev} tag, to ensure verb agreement.
 */
mentionA(obj)
{
    /* Note that the object has been mentioned */
    obj.mentioned = true;
    
    /* Note that the object has been seen */
    obj.noteSeen();
    
    /* 
     *   Set the plurality of the prevDummy_ object to the plurality of the
     *   object we're mentioning (so that prevDummy_ can be used to secure
     *   grammatical agreement with a subsequent verb).
     */
    prevDummy_.plural = obj.plural;
    
    /* Return the aName of our obj. */
    return obj.aName;    
}

/* 
 *   Function to use with the <<mention the *>> string template. This marks the
 *   object as mentioned in a room description and allows it to be used as the
 *   antecedent of a {prev} tag, to ensure verb agreement.
 */
mentionThe(obj)
{
    /* Note that the object has been mentioned */
    obj.mentioned = true;
    
    /* Note that the object has been seen */
    obj.noteSeen();
    
    /* 
     *   Set the plurality of the prevDummy_ object to the plurality of the
     *   object we're mentioning (so that prevDummy_ can be used to secure
     *   grammatical agreement with a subsequent verb).
     */
    prevDummy_.plural = obj.plural;
    
    /* Return the theName of our obj. */
    return obj.theName;
}

/* 
 *   A version of makeListStr that uses only one parameter, for use by the
 *   <<list of *>>string template
 */
makeListInStr(objList)
{   
     return makeListStr(objList);    
}

/* 
 *   Function for use with the <<is list of *>> string template, prefixing a
 *   list with the correct form of the verb to be to match the grammatical
 *   number of the list (e.g. "There are a box and a glove here" or "There is
 *   box here").
 */
isListStr(objList)
{
    if(objList.length > 1 || objList[1].plural)
        prevDummy_.plural = true;
    else
        prevDummy_.plural = nil;   
    
    return '{prev} {is} ' + makeListStr(objList);    
}
   
/*  
 *   Function for use by the <<list of * is>> string template, which returns a
 *   formatted list followed by the appropriate form of the verb 'to be' in
 *   grammatical agreement with that list.
 */
listStrIs(objList)
{    
    return makeListStr(objList) + ' {prev} {is}';
}


/*
 *   Construct a printable list of strings separated by "or" conjunctions.
 */
orList(lst)
{
    return genList(lst, 'or');
}

/*
 *   Construct a printable list of strings separated by "and" conjunctions.
 */
andList(lst)
{
    return genList(lst, 'and');
}

/*
 *   General list constructor 
 */
genList(lst, conj)
{
    /* start with an empty string */
    local ret = new StringBuffer();

    /* combine any duplicate items in the list */
    lst = mergeDuplicates(lst); 
   
    /* add each element */
    local i = 1, len = lst.length();
    foreach (local str in lst)
    {
        /* add a separator if this isn't the first item */
        if (i > 1)
        {
            if (len == 2)
                ret.append(' <<conj>> ');
            else if (i == len)
                ret.append(', <<conj>> ');
            else
                ret.append(', ');
        }

        /* add this item */
        ret.append(str);

        /* count the item */
        ++i;
    }

    /* return the string */
    return toString(ret);
}

/* 
 *   Take a list of strings of the form ['a book', 'a cat', 'a book'] and merge
 *   the duplicate items to return a list of the form ['two books', 'a cat']
 */     
mergeDuplicates(lst)
{
    /* A vector to store items that have duplicates */
    local dupVec = new Vector(10);
    
    /* The Vector we build to return the processed list */
    local processedVec = new Vector(10);
    
    /* Go through every item in our list */
    foreach(local cur in lst)
    {
        /* 
         *   If we've already dealt with this item (or one identical to it),
         *   skip over it.
         */
        if(dupVec.indexOf(cur))
            continue;
        
        /*   Count how many times the current item occurs in the list */
        local num = lst.countWhich({x: x == cur});
        
        /*   
         *   If it doesn't occur more than once, simply add it to the processed
         *   list and continue to the next item.
         */
        if(num < 2)
        {
            processedVec.append(cur);
            continue;
        }
        
        /*  
         *   Othewise get the appropriate plural according to the number of
         *   times the item appears in the list; e.g. if 'a gold coin' appears
         *   three times in the list, pl will be 'three gold coins'
         */
        
        local pl = makeCountedPlural(cur, num);
        {
            /* 
             *   If the makeCountedPlural() function returned the current value
             *   unchanged simply add it to the processed list, otherwise add
             *   the plural form to the processed list and the current form to
             *   the list of duplicated items.
             */
            if(pl == cur)
                processedVec.append(cur);
            else
            {
                processedVec.append(pl);
                dupVec.append(cur);                    
            }
        }
        
    }
    
    /* Convert the processed vector to a list and return it */
    return processedVec.toList();
}

/* 
 *   Take the string representation of a name (str) and a number (num) and
 *   return a string with the number spelled out and the name pluralised, e.g.
 *   makeCountPlural('a cat', 3) -> 'three cats' Amended to deal with the more
 *   complex case ('taking the coin'), 3) -> 'taking three coins'); i.e. the
 *   method now substitutes the number for the first occurrence of an article,
 *   if there is one.
 */
makeCountedPlural(str, num)
{
    /* Split the string into a list of words to make it easier to manipulate */
    local strList = str.split(' ');
    
    /* 
     *   Don't attempt to pluralize the name unless it contains the singular
     *   indefinite article or the definite article
     */
    local idx = strList.indexWhich({s: s is in ('a', 'an', 'the')});
    if(idx == nil)
        return str;

    /*  Substitute the number for the article */
    strList[idx] = spellNumber(num);
    
    
    /* Look for any part of the name in parentheses */
    local idx1 = strList.indexWhich({x: x.startsWith('(')});
    local idx2 = strList.indexWhich({x: x.endsWith(')')});
    
    /* 
     *   If the name ends with a section in parentheses, pluralize the part of
     *   the name before the parentheses and then append the parenthetical
     *   section.
     */    
    if(idx1 != nil && idx2 != nil && idx2 >= idx1 && idx2 == strList.length)
    {
        local plStr = strList.sublist(1, idx1 - 1).join(' ');
        local parStr = strList.sublist(idx1).join(' ');
        return LMentionable.pluralNameFrom(plStr) + ' ' + parStr;
    }
    
    /* Otherwise return the entire string pluralized */
    return LMentionable.pluralNameFrom(strList.join(' '));
}

/* 
 *   Remove any definite or indefinite article that occurs at the beginning of
 *   txt, and return the resultant string in lower case.
 */
stripArticle(txt)
{
    txt = txt.toLower();
    
    txt = txt.findReplace(R'^(the|a|an|some) ','');
    return txt;
}


/* ------------------------------------------------------------------------ */
/*
 *   finishGame options.  We provide descriptions and keywords for the
 *   option objects here, because these are inherently language-specific.
 *   
 *   Note that we provide hyperlinks for our descriptions when possible.
 *   When we're in plain text mode, we can't show links, so we'll instead
 *   show an alternate form with the single-letter response highlighted in
 *   the text.  We don't highlight the single-letter response in the
 *   hyperlinked version because (a) if the user wants a shortcut, they can
 *   simply click the hyperlink, and (b) most UI's that show hyperlinks
 *   show a distinctive appearance for the hyperlink itself, so adding even
 *   more highlighting within the hyperlink starts to look awfully busy.  
 */
modify finishOptionQuit
    desc = '<<aHrefAlt('quit', 'QUIT', '<b>Q</b>UIT', 'Leave the story')>>'
    responseKeyword = 'quit'
    responseChar = 'q'
;

modify finishOptionRestore
    desc = '''<<aHrefAlt('restore', 'RESTORE', '<b>R</b>ESTORE',
            'Restore a saved position')>> a saved position'''
    responseKeyword = 'restore'
    responseChar = 'r'
;

modify finishOptionRestart
    desc = '''<<aHrefAlt('restart', 'RESTART', 'RE<b>S</b>TART',
            'Start the story over from the beginning')>> the story'''
    responseKeyword = 'restart'
    responseChar = 's'
;

modify finishOptionUndo
    desc = '''<<aHrefAlt('undo', 'UNDO', '<b>U</b>NDO',
            'Undo the last move')>> the last move'''
    responseKeyword = 'undo'
    responseChar = 'u'
;

modify finishOptionCredits
    desc = '''see the <<aHrefAlt('credits', 'CREDITS', '<b>C</b>REDITS',
            'Show credits')>>'''
    responseKeyword = 'credits'
    responseChar = 'c'
;

modify finishOptionFullScore
    desc = '''see your <<aHrefAlt('full score', 'FULL SCORE',
            '<b>F</b>ULL SCORE', 'Show full score')>>'''
    responseKeyword = 'full score'
    responseChar = 'f'
;

modify finishOptionAmusing
    desc = '''see some <<aHrefAlt('amusing', 'AMUSING', '<b>A</b>MUSING',
            'Show some amusing things to try')>> things to try'''
    responseKeyword = 'amusing'
    responseChar = 'a'
;

modify restoreOptionStartOver
    desc = '''<<aHrefAlt('start', 'START', '<b>S</b>TART',
            'Start from the beginning')>> the game from the beginning'''
    responseKeyword = 'start'
    responseChar = 's'
;

modify restoreOptionRestoreAnother
    desc = '''<<aHrefAlt('restore', 'RESTORE', '<b>R</b>ESTORE',
            'Restore a saved position')>> a different saved position'''
;

/* ------------------------------------------------------------------------ */
/* English-language addition to defaultGround to give it appropriate vocab */

modify defaultGround
    vocab = 'ground;;floor'
;


/* ------------------------------------------------------------------------ */
/*
 *   Ask for a missing noun phrase.  The parser calls this when the player
 *   enters a command that omits a required noun phrase, such as PUT KEY or
 *   just TAKE.
 *   
 *   'cmd' is the Command object.  The other objects in the command, if
 *   any, have been resolved as much as possible when this is called.
 *   'role' is the NounRole object telling us which predicate role is
 *   missing (DirectObject, IndirectObject, etc).
 *   
 *   [Required] 
 */
askMissingNoun(cmd, role)
{
    "\^<<nounRoleQuestion(cmd, role)>>?\n";
}

/*
 *   Ask for help with an ambiguous noun.  The parser calls this when the
 *   player enters a noun phrase that's ambiguous, and we need to ask for
 *   clarification.
 *   
 *   'cmd' is the command, 'role' is the noun phrase's role in the
 *   predicate (DirectObject, etc), and 'nameList' is a list of strings
 *   determined by the Distinguisher process.
 *   
 *   [Required] 
 */
askAmbiguous(cmd, role, names)
{
    /* 
     *   For the direct object or actor role, keep it simple and just ask "which do
     *   you mean".
     *   
     *   For other roles, be more specific: use the basic predicate
     *   question for the role, so it's clear which object we're asking
     *   about.  Replace 'what' with 'which' in these questions.  
     */
    local q;
    if (role is in (DirectObject, ActorRole))
        q = 'Which do you mean';
    else
        q = nounRoleQuestion(cmd, role)
        .findReplace('what', 'which', ReplaceOnce);
    
    
    /* 
     *   If the option to enumerate the dimabigiation possibilites is set, then prefix every item in
     *   the list with a number, provided we have no more than 20 options (the parser seems unable
     *   to cope with more than this).
     */
    if(libGlobal.enumerateDisambigOptions && names.length < 20)
    {
        /* Set up a new list to hold the numbered names */
        local numbered_names = [];
        
        /* The current item in the list of names */
        local item;
        
        /* For each item in the list of names, prepend its number in the list. */
        for(local i in 1 .. names.length)
        {
            /* 
             *   Prepend the number represented the place in the list to the name of the item in the
             *   list.
             */
            item = '<b>(' + toString(i) + ')</b> ' + names[i];
            
            /* Add the numbered item to the list of numbered names; */
            numbered_names += item;
        }
        
        /* Copy the numbered list to the original list of names. */
        names = numbered_names;
        
        /* Note the number of available choices. */
        libGlobal.disambigLen = names.length;
    }
    
    /* ask the question */
    "\^<<q>>, <<orList(names)>>?\n";
}

/*
 *   Get the basic question for a noun role.  This turns the verb around
 *   into a question about one of its roles.  For example, for (Open,
 *   DirectObject), we'd return "what do you want to open".  For (AttachTo
 *   IndirectObject), "what do you want to connect it to".  
 */
nounRoleQuestion(cmd, role)
{
    /* get the missing query from the verb, and split into its parts */
    local q = cmd.verbProd.missingQ.split(';');

    /* pull out the appropriate question */
    q = q[role == DirectObject ? 1 : role == IndirectObject ? 2 : 3];

    /* the implied order of the object references is dobj-iobj-acc */
    local others = [DirectObject, IndirectObject, AccessoryObject];
    local otheridx = 1;

    /* set up the replacement function */
    local f = function(match, idx, str) {

        /* get the explicit or implied other-object role */
        local r;
        if (rexGroup(3) != nil)
        {
            r = rexGroup(3)[3];
            r = (r == 'dobj' ? DirectObject :
                 r == 'iobj' ? IndirectObject :
                 AccessoryObject);
        }
        else
        {
            /* 
             *   no -role suffix, so it's implied: get the next role, but
             *   skip the role we're asking about 
             */
            while ((r = others[otheridx++]) == role) ;
        }

        /* get the preposition, if supplied */
        local prep = (rexGroup(1) != nil ? rexGroup(1)[3].substr(2) : '');

        /* return the noun phrase */
        return npListPronoun(rexGroup(2)[3], cmd.(r.npListProp), prep);
    };

    /* substitute each other-object phrase and return the result */    
   return q.findReplace(
        R'(<lparen><alpha|space>+)?%<(it|that)(-<alpha>+)?%><rparen>?',
        f).trim();   
   
}


/* 
 *   Announce our choice of object when askForIobj() or askForDobj() chooses the
 *   best match on the player's behalf. We find the section of the verbPhrase
 *   appropriate to the direct or indirect object (e.g. '(what)' or '(on what)')
 *   and replace 'what' with the object name.
 */
announceBestChoice(action, obj, role)
{    
    /* The string to display the object announcement */
    local ann;
    
    /* Get the verb phrase for the action */
    local vp = action.verbRule.verbPhrase;
    
    /* 
     *   Set up a rex pattern to search for the shortest match to something in
     *   parentheses.
     */
    local pat = R'(<lparen>.*?<rparen>)';
    
    /* Pull out the first parenthesised section */
    local rm = rexSearch(pat, vp);
    
    
    /* 
     *   If we're looking for the indirect object pull out the next
     *   parenthesized section
     */
    if(role == IndirectObject)
        rm = rexSearch(pat, vp, rm[1] + rm[2]);
    
    /*  Replace 'what' with the object name */
    ann = rm[3].findReplace('what', obj.abcName(action, role));
    
    /*  Display the annoucement */
    "<<ann>>\n";
}

/*
 *   Get the pronoun for a resolved (or partially resolved) NounPhrase list
 *   from a command. 
 */
npListPronoun(pro, nplst, prep)
{
    /* 
     *   the prep starts with '(', it means that we should omit this role
     *   from queries about other roles 
     */
    if (prep.startsWith('('))
        return '';

    /* if there's no noun phrase, return nothing */
    if (nplst.length() == 0)
        return '';

    /* if we have more than one noun phrase, it's obviously 'them' */
    if (nplst.length() > 1)
        return '<<prep>> them';

    /* we have a single noun phrase - retrieve it */
    local np = nplst[1];

    /* if it explicitly refers to multiple objects, use 'them' */
    if (np.matches.length() > 1 && np.isMultiple())
        return '<<prep>> them';

    /* run through the matches and check for genders */
    local him = true, her = true, them = true;
    foreach (local m in np.matches)
    {
        if (!m.obj.isHim)
            him = nil;
        if (!m.obj.isHer)
            her = nil;
        if (!m.obj.plural)
            them = nil;
    }

    /* if all matches agree on a pronoun, use it, otherwise use 'it' */
    if (them)
        return '<<prep>> them';
    if (him)
        return '<<prep>> him';
    if (her)
        return '<<prep>> her';
    else
        return '<<prep>> <<pro>>';
}

/* 
 *   The libMessages object contains a number of messages/string values needed
 *   by the menu system and the WebUI. It is not used for any other library
 *   messages.
 */
libMessages: object
    
    /*
     *   Command key list for the menu system.  This uses the format
     *   defined for MenuItem.keyList in the menu system.  Keys must be
     *   given as lower-case in order to match input, since the menu
     *   system converts input keys to lower case before matching keys to
     *   this list.  
     *   
     *   Note that the first item in each list is what will be given in
     *   the navigation menu, which is why the fifth list contains 'ENTER'
     *   as its first item, even though this will never match a key press.
     */
    menuKeyList = [
                   ['q'],
                   ['p', '[left]', '[bksp]', '[esc]'],
                   ['u', '[up]'],
                   ['d', '[down]'],
                   ['ENTER', '\n', '[right]', ' ']
                  ]

    /* link title for 'previous menu' navigation link */
    prevMenuLink = '<font size=-1>Previous</font>'

    /* link title for 'next topic' navigation link in topic lists */
    nextMenuTopicLink = '<font size=-1>Next</font>'

    /*
     *   main prompt text for text-mode menus - this is displayed each
     *   time we ask for a keystroke to navigate a menu in text-only mode 
     */
    textMenuMainPrompt(keylist)
    {
        "\bSelect a topic number, or press &lsquo;<<
        keylist[M_PREV][1]>>&rsquo; for the previous
        menu or &lsquo;<<keylist[M_QUIT][1]>>&rsquo; to quit:\ ";
    }

    /* prompt text for topic lists in text-mode menus */
    textMenuTopicPrompt()
    {
        "\bPress the space bar to display the next line,
        &lsquo;<b>P</b>&rsquo; to go to the previous menu, or
        &lsquo;<b>Q</b>&rsquo; to quit.\b";
    }

    /*
     *   Position indicator for topic list items - this is displayed after
     *   a topic list item to show the current item number and the total
     *   number of items in the list, to give the user an idea of where
     *   they are in the overall list.  
     */
    menuTopicProgress(cur, tot) { " [<<cur>>/<<tot>>]"; }

    /*
     *   Message to display at the end of a topic list.  We'll display
     *   this after we've displayed all available items from a
     *   MenuTopicItem's list of items, to let the user know that there
     *   are no more items available.  
     */
    menuTopicListEnd = '[The End]'

    /*
     *   Message to display at the end of a "long topic" in the menu
     *   system.  We'll display this at the end of the long topic's
     *   contents.  
     */
    menuLongTopicEnd = '[The End]'

    /*
     *   instructions text for banner-mode menus - this is displayed in
     *   the instructions bar at the top of the screen, above the menu
     *   banner area 
     */
    menuInstructions(keylist, prevLink)
    {
        "<tab align=right ><b>\^<<keylist[M_QUIT][1]>></b>=Quit <b>\^<<
        keylist[M_PREV][1]>></b>=Previous Menu<br>
        <<prevLink != nil ? aHrefAlt('previous', prevLink, '') : ''>>
        <tab align=right ><b>\^<<keylist[M_UP][1]>></b>=Up <b>\^<<
        keylist[M_DOWN][1]>></b>=Down <b>\^<<
        keylist[M_SEL][1]>></b>=Select<br>";
    }

    /* show a 'next chapter' link */
    menuNextChapter(keylist, title, hrefNext, hrefUp)
    {
        "Next: <<aHref(hrefNext, title)>>;
        <b>\^<<keylist[M_PREV][1]>></b>=<<aHref(hrefUp, 'Menu')>>";
    }

    
    /* 
     *   Standard dialog titles, for the Web UI.  These are shown in the
     *   title bar area of the Web UI dialog used for inputDialog() calls.
     *   These correspond to the InDlgIconXxx icons.  The conventional
     *   interpreters use built-in titles when titles are needed at all,
     *   but in the Web UI we have to generate these ourselves. 
     */
    dlgTitleNone = 'Note'
    dlgTitleWarning = 'Warning'
    dlgTitleInfo = 'Note'
    dlgTitleQuestion = 'Question'
    dlgTitleError = 'Error'

    /*
     *   Standard dialog button labels, for the Web UI.  These are built in
     *   to the conventional interpreters, but in the Web UI we have to
     *   generate these ourselves.  
     */
    dlgButtonOk = 'OK'
    dlgButtonCancel = 'Cancel'
    dlgButtonYes = 'Yes'
    dlgButtonNo = 'No'
    
      /* web UI alert when a new user has joined a multi-user session */
    webNewUser(name) { "\b[<<name>> has joined the session.]\n"; }
    
    
    /*
     *   Warning prompt for inputFile() warnings generated when reading a
     *   script file, for the Web UI.  The interpreter normally displays
     *   these warnings directly, but in Web UI mode, the program is
     *   responsible, so we need localized messages.  
     */
    inputFileScriptWarning(warning, filename)
    {
        /* remove the two-letter error code at the start of the string */
        warning = warning.substr(3);

        /* build the message */
        return warning + ' Do you wish to proceed?';
    }
    inputFileScriptWarningButtons = [
        '&Yes, use this file', '&Choose another file', '&Stop the script']
    
    /* Web UI inputFile error: uploaded file is too large */
    webUploadTooBig = 'The file you selected is too large to upload.'
   
 
;


/* 
 *   make an error message into a sentence, by capitalizing the first letter and
 *   adding a period at the end if it doesn't already have one
 */
makeSentence(msg)
{
    return rexReplace(
        ['^<space>*[a-z]', '(?<=[^.?! ])<space>*$'], msg,
        [{m: m.toUpper()}, '.']);
}

/* 
 *   The dummy object is used to provide a {dummy} parameter in a message
 *   parameter substitution to provide a grammatical subject in a sentence for
 *   which no actual in-game subject is available; e.g. "There {dummy}{is}
 *   nothing here" provides a subject for {is} without displaying any text.
 */
modify dummy_ 
    dummyName = ''
    name = ''
    noteName(src)
    {
        name = src;
    }
;

/*  
 *   pluralDummy_ provides the same function as dummy_ when a plural subject is
 *   required in a sentence.
 */
modify pluralDummy_ 
    dummyName = ''
    name = ''
    noteName(src)
    {
        name = src;
    }
    
    plural = true
;

/* 
 *   prevDummy_ is used by the {prev} message parameter substitution to enable a
 *   subsequent verb to agree with a previous list defined through one of the
 *   string templates.
 */
prevDummy_: Mentionable
    dummyName = ''
    name = ''
    noteName(src)
    {
        name = src;
    }
    
    plural = true    
;

/* 
 *   When the actor has multiple verbs per sentence, we can use this to keep the expansion on
 *   track.
 */
actorActionContinuer_: dummy_ {
    person = (gActor == nil ? 3 : gActor.person)
    plural = (gActor == nil ? nil : gActor.plural)
}



/* ------------------------------------------------------------------------ */
/*
 *   The message parameters object.  The language module must provide one
 *   instance of MessageParams, to fill in the language-specific list of
 *   parameter names and expansion functions.
 *   
 *   [Required] 
 */
englishMessageParams: MessageParams
    /*
     *   The language's general sentence order.  This should be a string
     *   containing the letters S, V, and O in the appropriate order for
     *   the language.  S is for Subject, V is for Verb, and O is for
     *   Object.  For example, English is an SVO language, since the
     *   general order of an English sentence is Subject Verb Object.
     *   
     *   This can be left nil for languages with no prevailing sentence
     *   order.  
     */
    sentenceOrder = 'SVO'

    /*
     *   The English parameter mappings.  The base library doesn't use any
     *   of these directly, so parameter names and mappings are entirely up
     *   to the language module.  The only part of the library that uses
     *   the parameters is the library message strings, which are all
     *   defined by the language module itself.  Other translations are
     *   free to use different parameter names, and don't have to replicate
     *   1-for-1 the parameters defined for English.  Translations only
     *   have to define the parameters needed for their own library
     *   messages (plus any others they want to provide for use by game
     *   authors, of course).
     *   
     *   [Required] 
     */
    params = [

        /* {lb} is a literal left brace */
        [ 'lb', { ctx, params: '{' } ],

        /* {rb} is a literal right brace */
        [ 'rb', { ctx, params: '}' } ],

        /* {bar} is a literal vertical bar */
        [ 'bar', { ctx, params: '|' } ],

        /* 
         *   {s}, {es}, and {ies} are context-sensitive plural suffixes:
         *   these expand to nothing if the previous parameter was
         *   singular, or 's', 'es', and 'ies' if plural.  If the previous
         *   parameter was a numeric value, 1 is singular and anything else
         *   is plural; if it was a Mentionable, the 'plural' property
         *   determines it.  
         */
        [ 's', { ctx, params: ctx.lastParamPlural() ? 's' : '' } ],
        [ 'es', { ctx, params: ctx.lastParamPlural() ? 'es' : '' } ],
        [ 'ies', { ctx, params: ctx.lastParamPlural() ? 'ies' : 'y' } ],

        /* {1} through {9} substitute literal text string arguments 1-9 */
        [ '1',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[1])) } ],
        [ '2',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[2])) } ],
        [ '3',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[3])) } ],
        [ '4',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[4])) } ],
        [ '5',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[5])) } ],
        [ '6',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[6])) } ],
        [ '7',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[7])) } ],
        [ '8',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[8])) } ],
        [ '9',
         { ctx, params: ctx.paramToString(ctx.noteParam(ctx.args[9])) } ],

        /* {# n} - spells the number given by integer argument n (1-9) */
        [ '#', { ctx, params:
         spellNumber(ctx.paramToNum(ctx.noteParam(
             ctx.args[toInteger(params[2])]))) } ],

        /* 
         *   {and n} - shows the list given by integer argument n (1-9) as
         *   a basic "and" list ("x, y, and z")
         */
        [ 'and', { ctx, params:
         andList(ctx.noteParam(ctx.args[toInteger(params[2])])
                 .mapAll({ x: ctx.paramToString(x) })) } ],

        /* 
         *   {or n} - shows the list given by integer argument n (1-9) as a
         *   basic "or" list ("x, y, or z") 
         */
        [ 'or', { ctx, params:
         orList(ctx.noteParam(ctx.args[toInteger(params[2])])
                .mapAll({ x: ctx.paramToString(x) })) } ],
        

        /* {I} is the addressee's name in subjective case */
        [ 'i',  { ctx, params: cmdInfo(ctx, &actor, &theName, vSubject) } ],

        /* {me} is the addressee's name in objective case */
        [ 'me', { ctx, params: cmdInfo(ctx, &actor, &theObjName, vObject) } ],

        /* {my} is a possessive adjective for the addressee */
        [ 'my', { ctx, params: cmdInfo(ctx, &actor, &possAdj, vPossessive) } ],
        
        /* {mine} is a possessive noun for the addressee */
        [ 'mine', { ctx, params: cmdInfo(ctx, &actor, &possNoun, vPossessive) } ],
        
        /* {myself} is the reflexive pronoun for the addressee */
        [ 'myself', { ctx, params: cmdInfo(ctx, &actor, &reflexiveName, vObject) } ],
        
         /* {we} is the addressee's name in subjective case */
        [ 'we',  { ctx, params: cmdInfo(ctx, &actor, &theName, vSubject) } ],

        /* {us} is the addressee's name in objective case */
        [ 'us', { ctx, params: cmdInfo(ctx, &actor, &theObjName, vObject) } ],

        /* {our} is a possessive adjective for the addressee */
        [ 'our', { ctx, params: cmdInfo(ctx, &actor, &possAdj, vPossessive) } ],
        
        /* {ours} is a possessive noun for the addressee */
        [ 'ours', { ctx, params: cmdInfo(ctx, &actor, &possNoun, vPossessive) } ],
        
        /* {ourselves} is the reflexive pronoun for the addressee */
        [ 'ourselves', { ctx, params: cmdInfo(ctx, &actor, &reflexiveName, vObject) } ],
        
        /* 
         *   {dummy} provides a singular subject for an ensuing verb without
         *   displaying any text
         */
        [ 'dummy', { ctx, params: cmdInfo(ctx, dummy_, &dummyName, vSubject) } ],
        
        /* 
         *   {sing} provides a singular subject for an ensuing verb without
         *   displaying any text
         */
        [ 'sing', { ctx, params: cmdInfo(ctx, dummy_, &dummyName, vSubject) } ],
        
        /* 
         *   {plural} provides a plural subject for an ensuing verb without
         *   displaying any text
         */
        [ 'plural', { ctx, params: cmdInfo(ctx, pluralDummy_, &dummyName, vSubject) } ],
        
        /* 
         *   {prev} provides a singular or plural subject for an ensuing verb,
         *   matching the plurarity of a previous list, without displaying any
         *   text
         */
        [ 'prev', { ctx, params: cmdInfo(ctx, prevDummy_, &dummyName, vSubject) } ],
        
        
        /* 
         *   {aac} can be used to enure multiple verbs following the same actor continue to agree in
         *   person and number with the actor, e.g. "{I} yell{s/ed} and {aac} drop{s/?ed} my guard
         *   and {aac} scream{s/ed}.
         */ 
        
        [ 'aac', { ctx, params:
            cmdInfo(ctx, actorActionContinuer_, &dummyName, vSubject) } ],

        /* 
         *   {here} is the addressee's location, relative to the PC's.
         *   
         *   If the actor is the PC, this translates to "here" for present
         *   tense, and "there" for other tenses.  We use "there" for
         *   tenses other than the present because other tenses impose a
         *   distance between the narration and the events.  Once the
         *   narration is separated from the events in time, it's
         *   implicitly separated in space as well.  Saying "here" in the
         *   past tense seems to imply that the narrator is standing at a
         *   later time in the same spot where the events took place.
         *   Switching to "there" fixes this, by making the spatial locale
         *   of the narration indeterminate the same way the tense makes
         *   the temporal locale indeterminate.
         *   
         *   If the actor is an NPC, this translates to nothing at all (we
         *   use the special "backspace" notation to delete any preceding
         *   space).  We could say something like "there" or "in the
         *   kitchen" or "where Bob is", but it usually seems more pleasing
         *   to say nothing at all in these cases.  When another actor is
         *   specifically mentioned, the implication that we're talking
         *   about that actor's location is usually strong enough that it
         *   seems redundant to state it explicitly.  
         */
        [ 'here',
         { ctx, params:
           ctx.actorIsPC() ? (Narrator.tense == Present ? 'here' : 'there') :
           '\010' } ],

        /*
         *   {then} translates to "now" if we're in the present tense,
         *   "then" otherwise. 
         */
        [ 'then',
         { ctx, params: Narrator.tense == Present ? 'now' : 'then' } ],

        /*
         *   {now} translates to "now" if we're in the present tense,
         *   nothing otherwise.  There are times when we want to add "now"
         *   to a thought, but more as a flavor particle than as a precise
         *   specification of time: "You can't do that now".  The flavor
         *   particle doesn't seem to have an equivalent in other tenses,
         *   so it's better to just leave it out entirely: "You couldn't do
         *   that".  
         */
        [ 'now',
         { ctx, params: Narrator.tense == Present ? 'now' : '\010' } ],

        /*
         *   {the subj obj} - name, subjective case
         *.  {the obj} - name, objective case
         *.  {the obj's} - name, possessive case
         */
        [ 'the', function(ctx, params) {
        
        if (params[2] == 'subj')
           return cmdInfo(ctx, params[3], &theName, vSubject);
        else if (params[2].endsWith('\'s'))
           return cmdInfo(ctx, params[2].left(-2), &possAdj, vObject);
        else
           return cmdInfo(ctx, params[2], &theObjName, vAmbig);
        }
        ],
            
        /*
         *   {a subj obj} - aName, subjective case
         *.  {a obj} - name, objective case         
         */
        [ 'a', function(ctx, params) {
        
        if (params[2] == 'subj')
           return cmdInfo(ctx, params[3], &aName, vSubject);       
        else
           return cmdInfo(ctx, params[2], &aName, vAmbig);
        }
        ],
    
        /*
         *   {an subj obj} - aName, subjective case
         *.  {an obj} - name, objective case         
         */
        [ 'an', function(ctx, params) {
        
        if (params[2] == 'subj')
           return cmdInfo(ctx, params[3], &aName, vSubject);       
        else
           return cmdInfo(ctx, params[2], &aName, vAmbig);
        }
        ],
    
        /* 
         *   {in obj} - the appropriate containment preposition (in, on, under
         *   or behind) followed by the theName of the object (e.g. 'in the
         *   bath')
         */
        [ 'in', { ctx, params: cmdInfo(ctx, params[2], &objInName, vObject) } ],

    /* {inprep obj} the objInPrep (in, on, under or behind) of obj */
    ['inprep' , { ctx, params: cmdInfo(ctx, params[2], &objInPrep, vObject) } ], 

/* 
 *   {into obj} - the appropriate movement preposition (inro, onto, under or
 *   behind) followed by the theName of the object (e.g. 'into the bath')
 */
    [ 'into', { ctx, params: cmdInfo(ctx, params[2], &objIntoName, vObject) } ],

/* 
 *   {outof obj} the appropriate exit preposition followed the theName of the obj, e.g. 'out of the
 *   bath'
 */ 
    ['outof', { ctx, params: cmdInfo(ctx, params[2], &objOutOfName, vObject) } ],

/* {he obj} - pronoun, subjective case */
    [ 'he',
    { ctx, params: cmdInfo(ctx, params[2], &heName, vSubject) } ],

/* {she obj} - pronoun, subjective case */
    [ 'she',
    { ctx, params: cmdInfo(ctx, params[2], &heName, vSubject) } ],

/* {they obj} - pronoun, subjective case */
    [ 'they',
    { ctx, params: cmdInfo(ctx, params[2], &heName, vSubject) } ],

    
        /* {him obj} - pronoun, objective case */
        [ 'him',
         { ctx, params: cmdInfo(ctx, params[2], &himName, vObject) } ],

     /* {them obj} - pronoun, objective case */
        [ 'them',
         { ctx, params: cmdInfo(ctx, params[2], &himName, vObject) } ],

        /* {her obj} - possessive adjective pronoun (my, his, her) */
        [ 'her',
         { ctx, params: cmdInfo(ctx, params[2], &herName, vPossessive) } ],

        /* {his obj} - possessive adjective pronoun (my, his, her) */
        [ 'his',
         { ctx, params: cmdInfo(ctx, params[2], &herName, vPossessive) } ], 

        /* {its obj} - possessive adjective pronoun (my, his, her) */
        [ 'its',
         { ctx, params: cmdInfo(ctx, params[2], &herName, vPossessive) } ],

        /* {their obj} - possessive adjective pronoun (my, his, her) */
        [ 'their',
         { ctx, params: cmdInfo(ctx, params[2], &herName, vPossessive) } ],

        /* {hers obj} - possessive noun pronoun (mine, his, hers) */
        [ 'hers',
         { ctx, params: cmdInfo(ctx, params[2], &hersName, vPossessive) } ],
    
    
        /* {theirs obj} - possessive noun pronoun (mine, his, hers) */
        [ 'theirs',
         { ctx, params: cmdInfo(ctx, params[2], &hersName, vPossessive) } ],
    
       /* {herself obj} - reflexive pronouns (itself, herself, himself) */
    [ 'herself',
         { ctx, params: cmdInfo(ctx, params[2], &reflexiveName, vObject) } ],
    
     [ 'himself',
         { ctx, params: cmdInfo(ctx, params[2], &reflexiveName, vObject) } ],
    
     [ 'itself',
         { ctx, params: cmdInfo(ctx, params[2], &reflexiveName, vObject) } ],

     [ 'themselves',
         { ctx, params: cmdInfo(ctx, params[2], &reflexiveName, vObject) } ],

        /*
         *.  {that subj obj} - demonstrative pronoun, subjective (that, those)
         *.  {that obj} - demonstrative pronoun, objective
         */
        [ 'that', function(ctx, params) {
            if (params[2] == 'subj')
                return cmdInfo(ctx, params[3], &thatName, vSubject);
            else
                return cmdInfo(ctx, params[2], &thatObjName, vObject);
        } ],
        
        /* To Be verbs */
        [ 'am', conjugateBe ],
        [ 'are', conjugateBe ],
        [ 'is', conjugateBe ],
        [ 'isn\'t', conjugateIsnt ],
        [ 'aren\'t', conjugateIsnt ],
        [ 'amn\'t', conjugateIsnt ],
        [ '\'m', conjugateIm ],
        [ '\'re', conjugateIm ],
        [ '\'s', conjugateIm ],
        [ 'was', conjugateWas],
        [ 'were', conjugateWas],
        [ 'wasn\'t', conjugateWasnt],
        [ 'weren\'t', conjugateWasnt],
        [ 'wasnot', conjugateWasnot],
        [ 'werenot', conjugateWasnot], 

        /* {don't <verb>} - the second token is the verb infinitive */
        [ 'don\'t', conjugateDont ],
        [ 'doesn\'t', conjugateDont ],
        [ 'doesnot', conjugateDoNot],
        [ 'donot', conjugateDoNot],


        /* Have verbs */
        ['\'ve', conjugateIve ],
        ['haven\'t', conjugateHavnt ],
        ['hasn\'t', conjugateHavnt ],
        ['havenot', conjugateHavenot ],
        ['hasnot', conjugateHavenot ],
        
        /* {can}, {cannot}, {can't} */
        [ 'can', { ctx, params: conjugateCan(
            ctx, params, conjugateBe, 'can', 'could') } ],
        [ 'cannot', { ctx, params: conjugateCan(
            ctx, params, conjugateBeNot, 'cannot', 'could not') } ],
        [ 'can\'t', { ctx, params: conjugateCan(
            ctx, params, conjugateIsnt, 'can\'t', 'couldn\'t') } ],

        /* {must <verb>} - the second token is a verb infinitive */
        [ 'must', { ctx, params: conjugateMust(ctx, params) } ],
        
        [ 'actionliststr', {ctx, params: gActionListStr } ],

        /* conj <verb> <type> congugate a regular verb */
        ['conj', {ctx, params: conjugateRegular(ctx, params) } ]

    ]

    /*
     *   Check for reflexives in cmdInfo.  This is called when we see a
     *   noun phrase being used as an object of the verb (i.e., in a role
     *   other than as the subject of the verb).  If appropriate, we can
     *   return a reflexive pronoun instead of the noun we'd normally
     *   generate.  If no reflexive is required, we return nil, and the
     *   caller will use the normal noun or pronoun instead.  
     */
    cmdInfoReflexive(ctx, srcObj, objProp)
    {
        /* 
         *   if this object has already been used in the sentence in an
         *   objective role, use a reflexive pronoun instead 
         */
        
        /* 
         *   Note, this seems to produce rather odd results, so I'll try
         *   commenting it out.
         */        
        if (ctx.reflexiveAnte.indexOf(srcObj) != nil)
            return srcObj.pronoun().reflexive.name;

        /* it's not reflexive - use the normal noun or pronoun */
        return nil;
    }

    /*
     *   On construction, fill in the verb parameters from CustomVocab
     *   objects.  
     */
    construct()
    {
        /* create the verb form table */
        verbTab = new LookupTable(128, 256);

        /* add the verb parameters for all CustomVocab objects */
        forEachInstance(CustomVocab, function(cv) {

            /* set up a vector for the mapping */
            local vec = new Vector(cv.verbParams.length() * 2);

            /* set up a mapping for each verb */
            foreach (local p in cv.verbParams)
            {
                /* tokenize the verb conjugation string */
                local toks = p.split('/').mapAll({ s: s.trim() });

                /* 
                 *   if there are only three elements (infinite, present3,
                 *   and past), the participle is identical to the past 
                 */
                if (toks.length() == 3)
                    toks += toks[3];

                /* add the verb forms to the verb table */
                verbTab[toks[1]] = toks;
                verbTab[toks[2]] = toks;

                /* 
                 *   in the main parameters table, point the verb to the
                 *   generic regular verb conjugator 
                 */
                vec.append([toks[1], conjugate]);
                vec.append([toks[2], conjugate]);
            }

            /* add all of the verb mappings to our parameter list */
            params += vec;
        });

        /* 
         *   Do the base class construction.  Note that we had to wait to
         *   do this *after* we scan the CustomVocab objects, because the
         *   inherited constructor will populate the param table from the
         *   param list. 
         */
        inherited();
    }

    /* verb table - we build this at preinit from the verb parameters */
    verbTab = nil
    
    /* 
     *   Word-ending letter combinations that are awkward to follow with a
     *   contracted verb such a 've.
     */
    sLetters = ['s', 'x', 'z', 'sh', 'ch']

    /* 
     *   Does nam end with one of the letter combinations in sLetters, in which
     *   case it's awkward to follow it with a contraction.
     */
    awkwardEnding(nam)
    {
        return sLetters.indexWhich({lts: nam.endsWith(lts)})!= nil;
    }

    
;

/* 
 *   Regular verb conjugator.  This takes the list of CustomVocab
 *   verbParmas tokens built during preinit, and returns the
 *   appropriate conjugation for the subject and tense.  
 */
conjugate(ctx, params)
{
    /* get the list of forms for the verb */
    local toks = englishMessageParams.verbTab[params[1]];
    if (toks == nil)
        return nil;

    /* 
     *   get the present tense index: third-person singular has the second
     *   slot, all other forms have the first slot 
     */
    local idx = ctx.subj.plural || ctx.subj.person != 3 ? 1 : 2;
    
    switch (Narrator.tense)
    {
    case Present:
        /* "I go"/"he goes" - return the appropriate present token */
        return toks[idx];
        
    case Past:
        /* "I went" - all persons and numbers use the same past form */
        return toks[3];
        
    case Perfect:
        /* "I have gone" - "have" plus the participle */
        return ['have ', 'has '][idx] + toks[4];
        
    case PastPerfect:
        /* "I had gone" - "had" plus the participle */
        return 'had <<toks[4]>>';
        
    case Future:
        /* "I will go" - "will" plus the infinitive */
        return 'will <<toks[1]>>';
        
    case FuturePerfect:
        /* "I will have gone" - "will have" plus the participle */
        return 'will have <<toks[4]>>';
    }
    
    return nil;
}

/* 
 *   Language specific adjustments to a string applied before the message
 *   processor looks for parameter substitutions. Here we scan txt for sequences
 *   like 'verb{s/d}' and convert them to '{conj verb s/d}', which the parameter
 *   substitution mechanism can then deal with.
 */
langAdjust(txt)
{
    if(txt == nil)
        return '';
    
    for(;;)
    {
        local rf = rexSearch(
                   R'<lbrace>(s/d|s/ed|es/ed|ies/ied|s/<question>ed)<rbrace>',
            txt);
    
        if(rf == nil)
            break;
    
        local idx = rf[1];
        
        local str = rf[3];
    
        local rootStart = idx;
        while(rootStart > 1)
        {
            if(txt.substr(--rootStart, 1) is in (' ', '}'))
                break;
        }
            
        local verbRoot = txt.substr(rootStart + 1, idx - rootStart - 1);
        txt = txt.findReplace(verbRoot+str, '{conj ' + verbRoot + ' '
                              + str.substr(2));
    }
    
    return txt;
}

/* Conjugate a regular verb */
conjugateRegular(ctx, params)
{    
    local thirdPresentEnding = '';
    local participleEnding = '';
    local root = params[2];
    
    switch(params[3])
    {
    case 's/d':
        thirdPresentEnding = 's';
        participleEnding = 'd';
        break;
        
    case 's/ed':      
        thirdPresentEnding = 's';
        participleEnding = 'ed';
        break;
        
    case 'es/ed':      
        thirdPresentEnding = 'es';
        participleEnding = 'ed';
        break;
        
    case 'ies/ied':      
        thirdPresentEnding = 'ies';
        participleEnding = 'ied';    
        if(root.endsWith('y'))
            root = root.substr(1, root.length - 1);
        else
            params[2] = root + 'y';
        break;
        
    case 's/?ed':      
        thirdPresentEnding = 's';
        participleEnding = root.substr(root.length, 1) + 'ed';    
        break;
            
    }
    
    switch (Narrator.tense)
    {
        
        
    case Present:
        return !ctx.subj.plural && ctx.subj.person == 3 ? root +
            thirdPresentEnding : params[2];
        
    case Past:
        return root + participleEnding;
        
    case Perfect:
        return (!ctx.subj.plural && ctx.subj.person == 3 ? 'has ' : 'have ') +
            root + participleEnding;
        
    case PastPerfect:
        return 'had ' + root + participleEnding;
        
    case Future:
        return (ctx.subj.person == 1 ? 'shall ' : 'will ') + params[2];
    
    case FuturePerfect:
        return (ctx.subj.person == 1 ? 'shall have ' : 'will have ') + params[2];
        
    }
    
    return nil;
}

/* 
 *   Form the past participle of a verb, which may either be given in the form
 *   xxx, in which case we assume it's an irregular verb to be looked up in the
 *   table of irregular verbs, or in the form xxx[y/z], in which case we assume
 *   it's a regular verb to be conjugated according to the [y/z] ending.
 */
pastParticiple(verb)
{
    local b1 = verb.find('[');
    local b2 = verb.find(']');
    
    
    if(b1 != nil && b2 != nil && b2 > b1)
    {
        local stem = verb.substr(1, b1 - 1);
        local suffix = verb.substr(b1 + 1, b2 - b1 - 1);
        local dash = suffix.find('/');
        local ending = suffix;
        if(dash)
        {    
            ending = suffix.substr(dash + 1, suffix.length - 2);
            
        }
        
        if(ending.startsWith('?'))
        {
            stem = stem + stem.substr(-1, 1);
            ending = ending.substr(2);
        }
        return stem + ending;
                                     
    }
    else
        return englishMessageParams.verbTab[verb][4];
    
}


/*
 *   Conjugate "to be".  This is a handler function for message parameter
 *   expansion, for the "be" verb parameters ({am}, {is}, {are}).  
 */
conjugateBe(ctx, params)
{
    /* 
     *   get the present/past conjugation index for the grammatical person
     *   and number: [I am, you are, he/she/it is, we are, you are, they
     *   are] 
     */
    local idx = ctx.subj.plural ? 4 : ctx.subj.person;

    /* 
     *   for other tenses, the conjugation boils down to at most two
     *   options: third person singular and everything else 
     */
    local idx2 = ctx.subj.person == 3 && !ctx.subj.plural ? 2 : 1;

    /* look up the conjugation in the current tense */
    switch (Narrator.tense)
    {
    case Present:
        return ['am', 'are', 'is', 'are'][idx];

    case Past:
        return ['was', 'were', 'was', 'were'][idx];

    case Perfect:
        return ['have been', 'has been'][idx2];

    case PastPerfect:
        return 'had been';

    case Future:
        return 'will be';

    case FuturePerfect:
        return 'will have been';
    }

    return nil;
}

/*
 *   Conjugate "to be" in negative senses.  This is a handler function for
 *   message parameter expansion, for auxiliaries with negative usage
 *   (cannot, will not, etc).  
 */
conjugateBeNot(ctx, params)
{
    /* 
     *   get the present/past conjugation index for the grammatical person
     *   and number: [I am, you are, he/she/it is, we are, you are, they
     *   are] 
     */
    local idx = ctx.subj.plural ? 4 : ctx.subj.person;

    /* 
     *   for other tenses, the conjugation boils down to at most two
     *   options: third person singular and everything else 
     */
    local idx2 = ctx.subj.person == 3 && !ctx.subj.plural ? 2 : 1;

    /* look up the conjugation in the current tense */
    switch (Narrator.tense)
    {
    case Present:
        return '<<['am', 'are', 'is', 'are'][idx]>> not';

    case Past:
        return '<<['was', 'were', 'was', 'were'][idx]>> not';

    case Perfect:
        return ['have not been', 'has not been'][idx2];

    case PastPerfect:
        return 'had not been';

    case Future:
        return 'will not be';

    case FuturePerfect:
        return 'will not have been';
    }

    return nil;
}

/*
 *   Conjugate "isn't".  This is a handler function for message parameter
 *   expansion, for the "be" verb parameters with "not" contractions ({am
 *   not}, {isn't}, {aren't}).  
 */
conjugateIsnt(ctx, params)
{
    /* 
     *   get the present/past conjugation index for the grammatical person
     *   and number: [I am, you are, he/she/it is, we are, you are, they
     *   are] 
     */
    local idx = ctx.subj.plural ? 4 : ctx.subj.person;

    /* 
     *   for other tenses, the conjugation boils down to at most two
     *   options: third person singular and everything else 
     */
    local idx2 = ctx.subj.person == 3 && !ctx.subj.plural ? 2 : 1;

    /* look up the conjugation in the current tense */
    switch (Narrator.tense)
    {
    case Present:
        return ['am not', 'aren\'t', 'isn\'t', 'aren\'t'][idx];

    case Past:
        return ['wasn\'t', 'weren\'t', 'wasn\'t', 'weren\'t'][idx];

    case Perfect:
        return ['haven\'t been', 'hasn\'t been'][idx2];

    case PastPerfect:
        return 'hadn\'t been';

    case Future:
        return 'won\'t be';

    case FuturePerfect:
        return 'won\'t have been';
    }

    return nil;
}

/*
 *   Conjugate "to be" contractions - I'm, you're, he's, she's, etc.  This
 *   is a handler function for message parameter expansion, for the "be"
 *   verb parameters with contraction ({I'm}, {he's}, {you're}).  
 */
conjugateIm(ctx, params)
{
    /* 
     *   get the present/past conjugation index for the grammatical person
     *   and number: [I am, you are, he/she/it is, we are, you are, they
     *   are] 
     */
    local idx = ctx.subj.plural ? 4 : ctx.subj.person;

    /* 
     *   for other tenses, the conjugation boils down to at most two
     *   options: third person singular and everything else 
     */
    local idx2 = ctx.subj.person == 3 && !ctx.subj.plural ? 2 : 1;

    /* look up the conjugation in the current tense */
    switch (Narrator.tense)
    {
    case Present:
        return ['\'m', '\'re', '\'s', '\'re'][idx];

    case Past:
        return [' was', ' were', ' was', ' were'][idx];

    case Perfect:
        return ['\'ve been', '\'s been'][idx2];

    case PastPerfect:
        return '\'d been';

    case Future:
        return '\'ll be';

    case FuturePerfect:
        return '\'ll have been';
    }

    return nil;
}

/* 
 *   Conjugate the past tense of "to be" where we want to use the past tense in
 *   a present context (e.g. "You can see that Kilroy was here. "). This is a
 *   handler function for {was} or {were}.
 */

conjugateWas(ctx, params)
{ 
    switch (Narrator.tense)
    {
    case Present:
        return ctx.subj.plural || ctx.subj.person == 2 ? 'were' : 'was';
        
    case Past:
    case Perfect:
    case PastPerfect:
        return 'had been';
        
    case Future:
    case FuturePerfect:
        return 'will have been';
    }
    
    return nil;
}

conjugateWasnt(ctx, params)
{ 
    switch (Narrator.tense)
    {
    case Present:
        return ctx.subj.plural || ctx.subj.person == 2 ? 'weren\'t' : 'wasn\'t';
        
    case Past:
    case Perfect:
    case PastPerfect:
        return 'hadn\'t been';
        
    case Future:
    case FuturePerfect:
        return 'won\'t have been';
    }
    
    return nil;
}
    
conjugateWasnot(ctx, params)
{ 
    switch (Narrator.tense)
    {
    case Present:
        return ctx.subj.plural || ctx.subj.person == 2 ? 'were not' : 'was not';
        
    case Past:
    case Perfect:
    case PastPerfect:
        return 'had not been';
        
    case Future:
    case FuturePerfect:
        return 'will not have been';
    }
    
    return nil;
}

/* 
 *   Conjugate 've (contraction of have). After some words it's better not to
 *   contract (e.g. Liz's or Jesus'd is a a bit awkward) so we use the full
 *   'have' or 'had' form for such subjects and the contracted form otherwise.
 */

conjugateIve(ctx, params)
{
    local fullForm = englishMessageParams.awkwardEnding(ctx.subj.name);
    
    switch (Narrator.tense)
    {
    case Present:
        if(fullForm)
            return !ctx.subj.plural && ctx.subj.person == 3 ? ' has' : ' have';
        else
            return !ctx.subj.plural && ctx.subj.person == 3 ? '\'s' : '\'ve';
        
        
        
    case Past:
    case Perfect:
    case PastPerfect:
        return fullForm ? ' had' : '\'d';       
        
    case Future:
    case FuturePerfect:
        return fullForm ? ' will have' : '\'ll have';
    }
    
    return nil;
}    

/* Conjugate haven\'t (contracted have not) */
conjugateHavnt(ctx, params)
{
    switch (Narrator.tense)
    {
    case Present:       
            return !ctx.subj.plural && ctx.subj.person == 3 ? 'hasn\'t' 
            : 'haven\'t';      
        
    case Past:
    case Perfect:
    case PastPerfect:
        return 'hadn\'t';       
        
    case Future:
    case FuturePerfect:
        return 'won\'t have' ;
    }
    
    return nil;
}


conjugateHavenot(ctx, params)
{
    switch (Narrator.tense)
    {
    case Present:       
            return !ctx.subj.plural && ctx.subj.person == 3 ? 'has not' 
            : 'have not';      
        
    case Past:
    case Perfect:
    case PastPerfect:
        return 'had not';       
        
    case Future:
    case FuturePerfect:
        return 'will not have' ;
    }
    
    return nil;
}

/*
 *   Conjugate "don't" plus a verb.  "Don't" is always an auxiliary in
 *   English, and has an irregular structure in different tenses.  The
 *   second token in the {don't x} phrase is the main verb we're
 *   auxiliarizing.  
 */
conjugateDont(ctx, params)
{
    /* get the present index - don't vs doesn't */
    local idx = ctx.subj.person == 3 && !ctx.subj.plural ? 2 : 1;
    
    /* get the infinitive form by splitting off any [x/y] ending */
    local inf = params[2].split('[')[1];

    /* look up the conjugation in the current tense */
    switch (Narrator.tense)
    {
    case Present:
        /* I don't see that here */
        return ['don\'t ', 'doesn\'t '][idx] + inf;

    case Past:
        /* I didn't see that here */
        return 'didn\'t <<inf>>';

    case Perfect:
        /* I don't see -> I haven't seen */
        return ['haven\'t ', 'hasn\'t '][idx]
            + pastParticiple(params[2]);
//            

    case PastPerfect:
        /* I don't see -> I hadn't seen */
        return 'hadn\'t <<pastParticiple(params[2])>>';

    case Future:
        /* I don't see -> I won't see */
        return 'won\'t <<inf>>';

    case FuturePerfect:
        /* I don't see -> I won't have seen */
        return 'won\'t have <<pastParticiple(params[2])>>';
    }

    return nil;
}

/*
 *   Conjugate "do not" plus a verb.  "Do not" is always an auxiliary in
 *   English, and has an irregular structure in different tenses.  The
 *   second token in the {donot x} phrase is the main verb we're
 *   auxiliarizing.  
 */
conjugateDoNot(ctx, params)
{
    /* get the present index - don't vs doesn't */
    local idx = ctx.subj.person == 3 && !ctx.subj.plural ? 2 : 1;
    
    /* get the infinitive form by splitting off any [x/y] ending */
    local inf = params[2].split('[')[1];

    /* look up the conjugation in the current tense */
    switch (Narrator.tense)
    {
    case Present:
        /* I do not see that here */
        return ['do not ', 'does not '][idx] + inf;

    case Past:
        /* I did not see that here */
        return 'did not <<inf>>';

    case Perfect:
        /* I do not see -> I have not seen */
        return ['have not ', 'has not '][idx]
            + pastParticiple(params[2]);
//            

    case PastPerfect:
        /* I do not see -> I had not seen */
        return 'had not <<pastParticiple(params[2])>>';

    case Future:
        /* I do not see -> I will not see */
        return 'will not <<inf>>';

    case FuturePerfect:
        /* I do not see -> I will not have seen */
        return 'will not have <<pastParticiple(params[2])>>';
    }

    return nil;
}


/*
 *   Conjugate 'can', 'can\'t', or 'cannot'.  In the present, these are
 *   variations on "I can"; in the past, "I could"; in all other tenses,
 *   these change to conjugations of "to be able to": I have been able to,
 *   I had been able to, I will be able to, I will have been able to.  
 */
conjugateCan(ctx, params, beFunc, present, past)
{
    switch (Narrator.tense)
    {
    case Present:
        return present;

    case Past:
        return past;

    case Perfect:
    case PastPerfect:
    case Future:
    case FuturePerfect:
        return '<<beFunc(ctx, params)>> able to ';
    }

    return nil;
}

/*
 *   Conjugate "must" plus a verb.  In the present, this is "I must <x>";
 *   in other tenses, this is a conjugation of "to have to <x>": I had to
 *   <x>, I have to have <xed>, I had to have <xed>, I will have to <x>, I
 *   will have to have <xed>.  
 */
conjugateMust(ctx, params)
{
    local inf = params[2].split('[')[1];    
    
    local part = pastParticiple(params[2]);
    local idx = ctx.subj.person == 3 && !ctx.subj.plural ? 2 : 1;

    switch (Narrator.tense)
    {
    case Present:
        return 'must <<inf>>';

    case Past:
        return 'had to <<inf>>';

    case Perfect:
        return ['have to have ', 'has to have '][idx] + part;
        
    case PastPerfect:
        return 'had to have <<part>>';
        
    case Future:
        return 'will have to <<inf>>';
        
    case FuturePerfect:
        return 'will have to have <<part>>';
    }

    return nil;
}


/* 
 *   Language-specific modifications to Action classes principally to enable the
 *   construction of implicit action announcements.
 */
modify Action
     getVerbPhrase(inf, ctx)
     {
        /*
         *   parse the verbPhrase into the parts before and after the
         *   slash, and any additional text following the slash part
         */
        rexMatch('(.*)/(<alphanum|-|squote>+)(.*)', verbRule.verbPhrase);

        /* return the appropriate parts */
        if (inf)
        {
            /*
             *   infinitive - we want the part before the slash, plus the
             *   extra prepositions (or whatever) after the switched part
             */
            return rexGroup(1)[3] + rexGroup(3)[3];
        }
        else
        {
            /* participle - it's the part after the slash */
            return rexGroup(2)[3] + rexGroup(3)[3];
        }
    }
  
    /* 
     *   Flag - do we want to show implicit action reports for this action? By
     *   default we do.
     */
    reportImplicitActions = true
    
    
    /* 
     *   Construct the announcement of an implicit action according to whether
     *   the implict action succeeds (success = true) or fails (success = nil)
     *
     *   [Required]
     */
    buildImplicitActionAnnouncement(success, clearReports = true)
    {
        
        /* 
         *   If we don't want to show implicit action reports for this action,
         *   then don't do anything at all here; simply return an empty string
         *   at once.
         */       
        if(!reportImplicitActions)
            return '';
        
        local rep = '';
        local cur;
        
        
        /* 
         *   If the current action is an implicit action, add it to the list of
         *   implicit action reports, either in the participle form if it's a
         *   success (e.g. 'opening the door') or in the infinitive form
         *   preceded by 'trying' if it's a failure (e.g. 'trying to open the
         *   door')
         */
        if(isImplicit)
        {    
            cur = implicitAnnouncement(success);
            
            if(cur != nil)
                gCommand.implicitActionReports += cur;
        }    
            
        
        /* 
         *   If this implicit action failed we need to report this implicit
         *   action. If we're not an implicit action we need to report the
         *   previous set of implicit actions, if there are any.
         */
        
        if((success == nil || !isImplicit) &&
           gCommand.implicitActionReports.length > 0)
        {
            
            local lst = mergeDuplicates(gCommand.implicitActionReports);
            
            
            /* 
             *   Begin our report with an opening parenthesis and the word
             *   'first'
             */
            rep = BMsg(implicit action report start, '(first ');
            
            /* 
             *   Then go through all the implicit action reports on the current
             *   Command object, adding them to our report string.
             */
            for (cur in lst, local i = 1 ;; ++i)
            {    
                rep += cur;
                
                /* 
                 *   if we haven't reached the last report, add ', then ' to
                 *   separate one report from the next
                 */
                if(i < lst.length)
                    rep += BMsg(implicit action report separator, ' then ');
            }
            
            if(clearReports)
                /* We're done with this list of reports, so clear them out */
                gCommand.implicitActionReports = [];
            
            /* Return the completed implicit action report */
            return rep + BMsg(implicit action report terminator, ')\n');
        }
        
        /* 
         *   if we don't need to report anything, return an empty string, since
         *   this routine may have been called speculatively to see if there was
         *   anything to report.
         */
        
        return '';
    }
    
    /*  
     *   Return a string giving the implicit action announcement for the current
     *   action according to whether it's a success (e.g. "taking the spoon") or
     *   a failure (e.g. "trying to take the spoon"). We make this a separate
     *   method to make it a little easier for game code to customize implicit
     *   action announcements.
     *
     *   A return value of nil will suppress the implicit action report for this
     *   action altogeher.
     */
    implicitAnnouncement(success)
    {
        return success ? getVerbPhrase(nil, nil) : 
              BMsg(implicit action report failure, 'trying to ') 
            + getVerbPhrase(true, nil);
    }
    
    
    
    /* add a space prefix/suffix to a string if the string is non-empty */
    spPrefix(str) { return (str == '' ? str : ' ' + str); }
    spSuffix(str) { return (str == '' ? str : str + ' '); }
    
    /* 
     *   Announce an object (for use to introduce a report on what an action
     *   does to particular object when it's one of a number of objects the
     *   actions is acting upon)
     */
    announceObject(obj)
    {
        "<.announceObj><<obj.name>>:<./announceObj> ";
    }
;

modify TAction
     /* get the verb phrase in infinitive or participle form */
    getVerbPhrase(inf, ctx)
    {
        local dobj;
        local dobjText;
        local dobjIsPronoun;
        local ret;

        /* get the direct object */
        dobj = curDobj;
         
        /* Assume the direct object is not a pronoun */
        dobjIsPronoun = nil;        

        /* get the direct object name */ 
        dobjText = dobj.theName;

        /* get the phrasing */
        ret = getVerbPhrase1(inf, verbRule.verbPhrase, dobjText, dobjIsPronoun);

        /* return the result */
        return ret;
    }

    /*
     *   Given the text of the direct object phrase, build the verb phrase
     *   for a one-object verb.  This is a class method that can be used by
     *   other kinds of verbs (i.e., non-TActions) that use phrasing like a
     *   single object.
     *
     *   'inf' is a flag indicating whether to use the infinitive form
     *   (true) or the present participle form (nil); 'vp' is the
     *   verbPhrase string; 'dobjText' is the direct object phrase's text;
     *   and 'dobjIsPronoun' is true if the dobj text is rendered as a
     *   pronoun.
     */
    getVerbPhrase1(inf, vp, dobjText, dobjIsPronoun)
    {
        local ret;
        local dprep;
        local vcomp;

        /*
         *   parse the verbPhrase: pick out the 'infinitive/participle'
         *   part, the complementizer part up to the '(what)' direct
         *   object placeholder, and any preposition within the '(what)'
         *   specifier
         */
        rexMatch('(.*)/(<alphanum|-|squote>+)(.*) '
                 + '<lparen>(.*?)<space>*?<alpha>+<rparen>(.*)',
                 vp);

        /* start off with the infinitive or participle, as desired */
        if (inf)
            ret = rexGroup(1)[3];
        else
            ret = rexGroup(2)[3];

        /* get the prepositional complementizer */
        vcomp = rexGroup(3)[3];

        /* get the direct object preposition */
        dprep = rexGroup(4)[3];

        /*
         *   if the direct object is not a pronoun, put the complementizer
         *   BEFORE the direct object (the 'up' in "PICKING UP THE BOX")
         */
        if (!dobjIsPronoun)
            ret += spPrefix(vcomp);

        /* add the direct object preposition */
        ret += spPrefix(dprep);

        /* add the direct object, using the pronoun form if applicable */
        ret += ' ' + dobjText;

        /*
         *   if the direct object is a pronoun, put the complementizer
         *   AFTER the direct object (the 'up' in "PICKING IT UP")
         */
        if (dobjIsPronoun)
            ret += spPrefix(vcomp);

        /*
         *   if there's any suffix following the direct object
         *   placeholder, add it at the end of the phrase
         */
        ret += rexGroup(5)[3];

        /* return the complete phrase string */
        return ret;
    }
;

modify TIAction
     /* get the verb phrase in infinitive or participle form */
    getVerbPhrase(inf, ctx)
    {
        local dobj, dobjText, dobjIsPronoun;
        local iobj, iobjText;
        local ret;

        /* get the direct object information */
        dobj = curDobj;
        
        dobjText = dobj.theName;
        dobjIsPronoun = nil;

        /* get the indirect object information */
        iobj = curIobj;

        iobjText = (iobj != nil ? iobj.theName : nil);

        /* get the phrasing */
        ret = getVerbPhrase2(inf, verbRule.verbPhrase,
                             dobjText, dobjIsPronoun, iobjText);

        
        /* return the result */
        return ret;
    }

    /*
     *   Get the verb phrase for a two-object (dobj + iobj) phrasing.  This
     *   is a class method, so that it can be reused by unrelated (i.e.,
     *   non-TIAction) classes that also use two-object syntax but with
     *   other internal structures.  This is the two-object equivalent of
     *   TAction.getVerbPhrase1().
     */
    getVerbPhrase2(inf, vp, dobjText, dobjIsPronoun, iobjText)
    {
        local ret;
        local vcomp;
        local dprep, iprep;

        /* parse the verbPhrase into its component parts */
        rexMatch('(.*)/(<alphanum|-|squote>+)(?:<space>+(<^lparen>*))?'
                 + '<space>+<lparen>(.*?)<space>*<alpha>+<rparen>'
                 + '<space>+<lparen>(.*?)<space>*<alpha>+<rparen>',
                 vp);

        /* start off with the infinitive or participle, as desired */
        if (inf)
            ret = rexGroup(1)[3];
        else
            ret = rexGroup(2)[3];

        /* get the complementizer */
        vcomp = (rexGroup(3) == nil ? '' : rexGroup(3)[3]);

        /* get the direct and indirect object prepositions */
        dprep = rexGroup(4)[3];
        iprep = rexGroup(5)[3];

        /*
         *   add the complementizer BEFORE the direct object, if the
         *   direct object is being shown as a full name ("PICK UP BOX")
         */
        if (!dobjIsPronoun)
            ret += spPrefix(vcomp);

        /*
         *   add the direct object and its preposition, using a pronoun if
         *   applicable
         */
        ret += spPrefix(dprep) + ' ' + dobjText;

        /*
         *   add the complementizer AFTER the direct object, if the direct
         *   object is shown as a pronoun ("PICK IT UP")
         */
        if (dobjIsPronoun)
            ret += spPrefix(vcomp);

        /* if we have an indirect object, add it with its preposition */
        if (iobjText != nil)
            ret += spPrefix(iprep) + ' ' + iobjText;

        /* return the result phrase */
        return ret;
    }
;

/* -------------------------------------------------------------------------- */
/* 
 *   English-language modifications to the various pronoun objects to provide
 *   them with an appropriate English name in their prep properties.
 */

modify LocType
    prep = ''
    intoPrep = prep
;


modify In
    prep = 'in'  
    intoPrep = 'into'
;


modify Outside
    prep = 'part of'
;


modify On
    prep = 'on'    
    intoPrep = 'into'
;

modify Under
    prep = 'under'
;

modify Behind
    prep = 'behind'
;


modify Held
    prep = 'held by'
;


modify Worn
    prep = 'worn by'
;


modify Into
    prep = 'into'
;

modify OutOf
    prep = 'out of'
;

modify Down
    prep = 'down'
;

modify Up
    prep = 'up';
;

modify Through
    prep = 'through';
;

modify Carrier
    prep = 'borne by'
;

/* 
 *   [must define] The language-specific part of CommandTopicHelper. */

property myAction;

class LCommandTopicHelper: object
    
    /* 
     *   builds the action phrase of the command, e.g. 'jump', 'take the red
     *   ball', 'put the blue ball in the basket'. This can be used to help
     *   construct the player char's command to the actor in the topic response,
     *   e.g. "<q>\^<<actionPhrase>>!</q> you cry. "
     */    
    actionPhrase()
    {
        if(myAction == nil || myAction.verbRule == nil)
            return 'do something'; 
        /* 
         *   Find the longest grammar template that starts with the same word at
         *   the verb phrase. This is likely to be the most complete version in
         *   a reasonably canonical form.
         *
         */
        local txt = '';
        
        /*   
         *   Obtain the verb from the first part of the verbPhrase of the
         *   verbRule of the action matched by this CommandTopic.
         */
        local verb = myAction.verbRule.verbPhrase.split('/')[1];
        
        /*  
         *   Go through all the grammar templates associated with the action
         *   matched by this CommandTopic and pick out the longest one that
         *   starts with the verb we've just identified; we'll take this to be
         *   the 'canonical' form (as a rough rule of thumb this works
         *   reasonably well)
         */
        foreach(local cur in myAction.grammarTemplates)
        {
            if(cur.length > txt.length && cur.startsWith(verb))
                txt = cur;
        }
        
        /* 
         *   If the matched action has a direct object, replace the string
         *   'dobj' in our txt string with the name of the direct object
         */
        if(myAction.curDobj != nil)            
            txt = txt.findReplace('(dobj)', getName(myAction.curDobj));
           
        /* 
         *   If the matched action has an indirect object, replacc the string
         *   'iobj' in our txt string with the name of the indirect object
         */
        if(myAction.curIobj != nil)        
            txt = txt.findReplace('(iobj)', getName(myAction.curIobj));
        
        if(gCommand.verbProd.dirMatch)
            txt = txt.findReplace('(direction)',
                                  gCommand.verbProd.dirMatch.dir.name);
        
        return txt;
    }
    
    /* 
     *   Get the appropriate name for an object to use the action phrase of a
     *   CommandTopic.
     */
    getName(obj)
    {
        /* If the object is the player character, it should appear as 'me' */
        if(obj == gPlayerChar)
            return 'me';
        
        /* 
         *   If the object is the actor to whom the command is being addressed,
         *   it should appear as the singular or plural form of the second
         *   person reflexive pronoun
         */
        if(obj == gActor)
            return gActor.plural ? 'yourselves' : 'yourself';
        
        /* Otherwise just use the theName property of the object */
        return obj.theName;   
    }
;
    

/* ------------------------------------------------------------------------ */
/*
 *   Simple yes/no confirmation.  The caller must display a prompt; we'll
 *   read a command line response, then return true if it's an affirmative
 *   response, nil if not.
 */
yesOrNo()
{
    /* switch to no-command mode for the interactive input */
    "<.commandnone>";

    /*
     *   Read a line of input.  Do not allow real-time event processing;
     *   this type of prompt is used in the middle of a command, so we
     *   don't want any interruptions.  Note that the caller must display
     *   any desired prompt, and since we don't allow interruptions, we
     *   won't need to redisplay the prompt, so we pass nil for the prompt
     *   callback.
     */
    local str = inputManager.getInputLine(nil);

    /* switch back to mid-command mode */
    "<.commandmid>";

    /*
     *   If they answered with something starting with 'Y', it's
     *   affirmative, otherwise it's negative.  In reading the response,
     *   ignore any leading whitespace.
     */
    return rexMatch('<space>*[yY]', str) != nil;
}


/* 
 *   In English, Remove X might mean take it off (if we're wearing it) or take
 *   it (if it's simply a free-standing object). We handle this with a Doer in
 *   the English-specific library (a) because this ambiguity may be
 *   language-specific and (b) because remap is now deprecated. */

removeDoer: Doer 'remove Thing'

    execAction(c)
    {
        if(c.dobj.wornBy == c.actor)
            redirect(c, Doff, dobj: c.dobj);
        else
            redirect(c, Take, dobj: c.dobj);
    }    
;

/*  
 *   Make putting something on a Floor object or throwing something at a Floor
 *   object equivalent to dropping it; since this depends on the
 *   English-language grammar of the actions concerned it needs to appear in the
 *   English-specific part of the library.
 */
putOnGroundDoer: Doer 'put Thing on Floor; throw Thing at Floor'
    execAction(c)
    {
        /* 
         *   The player has asked to put something on the ground, so we should
         *   override the actor's location's dropLocation on this occasion to
         *   ensure that that's where the dropped object indeed ends up
         */        
        local oldDropLocation;
        local oldLocation;
        try
        {
            /* Note the original dropLocation */
            oldLocation = gActor.location;
            oldDropLocation = oldLocation.dropLocation;
            
            /* Change the dropLocation to the Room */
            oldLocation.dropLocation = gActor.getOutermostRoom;
            
            /* redirect the action to Drop */
            redirect(c, Drop, dobj: c.dobj);
        }
        finally
        {
            /* Restore the original dropLocation */
            oldLocation.dropLocation = oldDropLocation;
        }
    }
;

/* 
 *   'Get on ground' or 'stand on ground' does nothing if the player is already
 *   directly in a room, so in that case we just display an appropriate message;
 *   otherwise we take the command as equivalent to getting out of the actor's
 *   immediate container.
 */
getOnGroundDoer: Doer 'stand on Floor; get on Floor'
    execAction(c)
    {
        if(gPlayerChar.location.ofKind(Room))
            "{I} {am} standing on {the dobj}. ";
        else
            redirect(c, GetOut);    
    }
;

/*  In English taking a path means going along it */
takePathDoer: Doer 'take PathPassage'
    execAction(c)
    {
        redirect(c, GoThrough);
    }
    
    /* 
     *   But this only applies if the command is actually 'take' and not a
     *   synonymn like 'get' or 'pick up'
     */
    strict = true
    
    /* 
     *   Ignore an error report for this Doer in PreInit, since it only means
     *   that extras.t hasn't been included.
     */
    ignoreError = true
;
/* 
 *   Preparser to catch numbers entered with a decimal point, so that the
 *   decimal point is not treated as terminating a sentence in the command. This
 *   works by wrapping the number in double quote marks, so any code that wants
 *   to do anything with the decimal number will first have to strip off the
 *   quotes.
 */

decimalPreParser: StringPreParser
    doParsing(str, which)
    {
        str = str.findReplace( R'<digit>+<period><digit>+',
                              { match, index, orig: '"'+match+'"' }  );
        
        return str;
    }
;

/* 
 *   PreParser to convert a number input by the player (e.g. 1 or 2) in response to a diambiguation
 *   prompt into the corresponding ordinal (e.g., first or second) so that the parser will recognize
 *   it as choosing one of the options.
 */

disambigPreParser: StringPreParser
    doParsing(str, which)
    {
        /* 
         *   If we are disammguating and the option to enumerate the list of possible responsses is
         *   set, then see if the player has entered a number and convert it to its corresponding
         *   ordinal (e.g. '1' to 'first')
         */
        if(which == rmcDisambig && libGlobal.enumerateDisambigOptions)
        {
            
            /* First strip our any extraneous bracekts the player may have typed. */
            local str2 = str.findReplace(['(', ')'], '');
            
            /* Then try to convert the player's input into an integer. */                       
            local num = tryInt(str2);            
            
            /* 
             *   If we have an integer and it's less than the number of ordinals that we define, and
             *   it's within the allowable range of disambig options then return the ccrresponding
             *   ordinal number.
             */
            if(num && num <= ordinals.length && num > 0)
            {    
                if(num <= libGlobal.disambigLen)
                    return ordinals[num];    
                
                "There were only <<libGlobal.disambigLen>> options.<.p>";
                return nil;
            }
        }       
        
           
        /* return the original string unchanged */
        return str;
    }
    
    /* 
     *   The list of ordinal numbers. We only list the first 20 here since it seems highly unlikely
     *   that a player would be presented with a list of more than twelve diambiguation options. In
     *   any case the parser seems unable to cope with a response of more than 'twentieth'.
     */
    ordinals = ['first', 'second', 'third', 'fourth' ,'fifth', 'sixth', 'seventh',
        'eighth', 'ninth', 'tenth', 'eleventh', 'tweltfh', 'thirteenth', 'fourteenth',
        'fifteenth', 'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth',
        'twentieth'
    ];
;



/* 
 *   Possibly a temporary measure to replace the apostrophe in possessives in
 *   certain words in the player's input with a carat in order to enable
 *   matching vocab.
 */
//apostropheSPreParser: StringPreParser
//    doParsing(str, which)
//    {
//        /* 
//         *   If we haven't created a LookupTable there aren't any words to check
//         *   for, so we can just return the string unaltered.
//         */
//        if(possTab == nil)
//            return str;
//        
//        
//        local lst = str.split(' ');
//        
//        
//        for(local tok in lst, local i=1 ;;i++)
//        {
//            local aposWord = possTab[tok.toLower];
//            if(aposWord != nil)
//                lst[i] = aposWord;
//        }
//    
//        return lst.join(' ');
//    }
//    
//    
//    possTab = nil
//    
//    addEntry(key, val)
//    {
//        if(possTab == nil)
//            possTab = new LookupTable();
//        
//        possTab[key] = val;       
//    }
//;