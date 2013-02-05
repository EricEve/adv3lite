#include "advlite.h"

/* ------------------------------------------------------------------------ */
/*
 *   The English command grammar.  These rules define the overall sentence
 *   syntax its various components.
 *   
 *   We start parsing a new command at firstCommandPhrase (for the first
 *   command on a line) or commandPhrase (for the second and subsequent
 *   commands on the same line).  The difference between the two is that
 *   firstCommandPhrase accepts actor orders (BOB, GO NORTH or TELL BOB TO
 *   OPEN DOOR), while commandPhrase doesn't.  
 *   
 *   Other language modules are NOT required to duplicate the English
 *   grammar tree rule-for-rule.  You must only define the rules marked
 *   with [Required], since these are referenced from the base library
 *   parser.  The [Required] grammar objects must exist and use the given
 *   base names, but the number of rules for a given grammar, the tag
 *   names, and the syntax defined within the rules are all up to the
 *   language module.
 *   
 *   Rules NOT marked [Required] are internal to the English grammar:
 *   they're only referenced from other parts of the English grammar, so
 *   they're not required to exist in other languages.  A language module
 *   is free to use its own completely different structure for the internal
 *   rules, and should - the structure should be based on the natural
 *   grammar of the implemented language, not on how the English rules here
 *   are structured.  
 *   
 *   Note that the base library provides a number of XxxProduction classes
 *   for structural elements that should be common to most or all languages
 *   - NounPhraseProduction, PossessiveProduction, PronounProduction, etc.
 *   As a language implementer, you're NOT required to implement any
 *   grammar rules based on any of these classes.  But you'll probably want
 *   to anyway, because these classes are designed to make your life a lot
 *   easier by doing most of the work for you.  These classes provide code
 *   that translates the information in the syntax tree into the
 *   corresponding semantic information in the parser.  If you don't create
 *   rules based on these classes, you'll have to instead write your own
 *   code in the rules that propagates the required information into the
 *   parser parser.  The XxxProduction classes are designed to be abstract
 *   and language-independent, so if the base library does its job
 *   correctly, it should be straightforward to use these classes at the
 *   appropriate points in the grammar.  
 */

/*
 *   firstCommandPhrase - the root grammar rule for the first command on a
 *   command line.  [Required]
 */
grammar firstCommandPhrase(commandOnly): commandPhrase->cmd_
    : CommandProduction
;

grammar firstCommandPhrase(withActor):
    singleNounOnly->actor_ ',' commandPhrase->cmd_
    : CommandProduction
;

grammar firstCommandPhrase(askTellActorTo):
    ('ask' | 'tell' | 'a' | 't') singleNounOnly->actor_
    'to' commandPhrase->cmd_
    : CommandProduction

    /* 
     *   We're giving orders to the actor in the third person, because
     *   we're doing it indirectly.  The actual imperative predicate here
     *   is the TELL TO: this addresses the parser/narrator, who passes the
     *   command along to the actor at our request.  
     */
    actorPerson = 3
;

/*
 *   commandPhrase - the root grammar rule for the second and subsequent
 *   command on a command line.  [Required]
 */
grammar commandPhrase(definiteConj):
    predicate->cmd_
    | predicate->cmd_ commandOnlyConjunction->conj_ *
    : CommandProduction
;

grammar commandPhrase(ambiguousConj):
    predicate->cmd_ commandOrNounConjunction->conj_
    commandPhrase->cmd2_
    : CommandProduction
;

grammar actorBadCommandPhrase(main):
    singleNounOnly->actor_ ',' miscWordList
    | ('ask' | 'tell' | 'a' | 't') singleNounOnly->actor_ 'to' miscWordList
    : Production
;

grammar commandOnlyConjunction(sentenceEnding):
    '.'
    | '!'
    | '?'
    : Production

    /* 
     *   these end the sentence - meaning that after one of these, you can
     *   address a new actor 
     */
    endOfSentence = true
;

grammar commandOnlyConjunction(nonSentenceEnding):
    'then'
    | 'and' 'then'
    | ',' 'then'
    | ',' 'and' 'then'
    | ';'
    : Production
;

grammar commandOrNounConjunction(main):
    ','
    | 'and'
    | ',' 'and'
    : Production
;

grammar nounConjunction(main):
    ','
    | 'and'
    | ',' 'and'
    : Production
;

grammar nounList(terminal): terminalNounPhrase->np_ : Production
;

grammar nounList(nonTerminal): completeNounPhrase->np_ : Production
;

grammar nounList(list): nounMultiList->lst_ : Production
;

grammar nounList(empty): [badness 500] : EmptyNounProduction
;

grammar nounMultiList(multi):
    nounMultiList->np1_ nounConjunction terminalNounPhrase->np2_
    : NounListProduction
;

grammar nounMultiList(nonterminal): nonTerminalNounMultiList->lst_
    : Production
;

grammar nonTerminalNounMultiList(pair):
    completeNounPhrase->np1_ nounConjunction completeNounPhrase->np2_
    : NounListProduction
;

grammar nonTerminalNounMultiList(multi):
    nonTerminalNounMultiList->np1_ nounConjunction completeNounPhrase->np2_
    : NounListProduction
;

grammar exceptList(main): exceptListBody->lst_ : ExceptListProduction
;

grammar exceptListBody(single): exceptNounPhrase->np_ : Production
;

grammar exceptListBody(list):
    exceptNounPhrase->np1_ nounConjunction exceptListBody->np2_
    : NounListProduction
;

grammar exceptNounPhrase(singleComplete): completeNounPhraseWithoutAll->np_
    : Production
;

grammar exceptNounPhrase(singlePossessive): possessiveNounPhrase->poss_
    : Production
;

/*
 *   The singleNoun grammar rule is for predicate object slots that require
 *   a single noun phrase (as opposed to a list of nouns).  This rule has
 *   to be defined by each language, because the base parser uses it to
 *   check for implicit EXAMINE commands.
 *   
 *   [Required] 
 */

grammar singleNoun(normal): singleNounOnly->np_ : Production
;

grammar singleNoun(empty): [badness 500] : EmptyNounProduction
;

/*
 *   A user could attempt to use a noun list with more than one entry (a
 *   "multi list") where a single noun is required.  This is a semantic
 *   error rather than a grammatical error, so we define a grammar rule for
 *   it (despite the obvious clash with the singleNoun name).  However, we
 *   use the BadListProduction for this match object - this ensures that we
 *   we score it lower than a version with out a list, and that if we make
 *   it to the resolution stage, we'll display a suitable error message.  
 */
grammar singleNoun(multiple):
    [badness 100] nounMultiList->np_
    : BadListProduction
;


grammar singleNounOnly(main):
    terminalNounPhrase->np_
    | completeNounPhrase->np_
    : Production
;

grammar putPrepSingleNoun(main):
    putPrep->prep_ singleNoun->np_
    : Production
;

grammar putPrep(main):
    'in' | 'into' | 'in' 'to'
    | 'on' | 'onto' | 'on' 'to' | 'upon'
    | 'behind'
    | 'under'
    : Production
;

grammar inSingleNoun(main):
     singleNoun->np_ | ('in' | 'into' | 'in' 'to') singleNoun->np_
    : Production
;

grammar forSingleNoun(main):
   singleNoun->np_ | 'for' singleNoun->np_ : Production
;

grammar toSingleNoun(main):
   singleNoun->np_ | 'to' singleNoun->np_ : Production
;

grammar throughSingleNoun(main):
   singleNoun->np_ | ('through' | 'thru') singleNoun->np_
   : Production
;

grammar fromSingleNoun(main):
   singleNoun->np_ | 'from' singleNoun->np_ : Production
;

grammar onSingleNoun(main):
   singleNoun->np_ | ('on' | 'onto' | 'on' 'to') singleNoun->np_
    : Production
;

grammar withSingleNoun(main):
   singleNoun->np_ | 'with' singleNoun->np_ : Production
;

grammar atSingleNoun(main):
   singleNoun->np_ | 'at' singleNoun->np_ : Production
;

grammar outOfSingleNoun(main):
   singleNoun->np_ | 'out' 'of' singleNoun->np_ : Production
;

grammar aboutTopicPhrase(main):
   topicPhrase->np_ | 'about' topicPhrase->np_
   : Production
;

grammar completeNounPhrase(main):
    completeNounPhraseWithAll->np_ | completeNounPhraseWithoutAll->np_
    : Production
;

grammar completeNounPhrase(miscPrep):
    [badness 100] completeNounPhrase->np1_
        ('with' | 'into' | 'in' 'to' | 'through' | 'thru' | 'for' | 'to'
         | 'onto' | 'on' 'to' | 'at' | 'under' | 'behind')
        completeNounPhrase->np2_
    : Production
;

grammar completeNounPhraseWithoutAll(main):
    qualifiedNounPhrase->np_ | pronounPhrase->np_
    : Production
;

grammar pronounPhrase(it):   'it' : PronounProduction
    pronoun = It
;
grammar pronounPhrase(them): 'them' : PronounProduction
    pronoun = Them
;
grammar pronounPhrase(him):  'him' : PronounProduction
    pronoun = Him
;
grammar pronounPhrase(her):  'her' : PronounProduction
    pronoun = Her
;

grammar pronounPhrase(itself): 'itself' : PronounProduction
    pronoun = Itself
;

grammar pronounPhrase(themselves):
    'themself' | 'themselves' : PronounProduction
    pronoun = Themselves
;

grammar pronounPhrase(himself): 'himself' : PronounProduction
    pronoun = Himself
;

grammar pronounPhrase(herself): 'herself' : PronounProduction
    pronoun = Herself
;

grammar pronounPhrase(you):
    'you' | 'yourself' | 'yourselves' : PronounProduction
    pronoun = You
;
grammar pronounPhrase(me): 'me' | 'myself' : PronounProduction
    pronoun = Me
;

grammar pronounPhrase(us): 'us' | 'ourself' | 'ourselves'
    : PronounProduction
    pronoun = Us
;


grammar completeNounPhraseWithAll(main):
    'all' | 'everything'
    : Production

    determiner = All
;

grammar terminalNounPhrase(allBut):
    ('all' | 'everything') ('but' | 'except' | 'except' 'for')
        exceptList->except_
    : Production

    determiner = All
;

grammar terminalNounPhrase(pluralExcept):
    (qualifiedPluralNounPhrase->np_ | detPluralNounPhrase->np_)
    ('except' | 'except' 'for' | 'but' | 'but' 'not') exceptList->except_
    : Production
;

grammar terminalNounPhrase(anyBut):
    'any' nounPhrase->np_
    ('but' | 'except' | 'except' 'for' | 'but' 'not') exceptList->except_
    : Production

    determiner = Indefinite
;

grammar qualifiedNounPhrase(main):
    qualifiedSingularNounPhrase->np_
    | qualifiedPluralNounPhrase->np_
    : Production
;

grammar qualifiedSingularNounPhrase(definite):
    ('the' | 'the' 'one' | 'the' '1' | ) indetSingularNounPhrase->np_
    : Production

    determiner = Definite
;

grammar qualifiedSingularNounPhrase(indefinite):
    ('a' | 'an') indetSingularNounPhrase->np_
    : Production

    determiner = Indefinite
;

grammar qualifiedSingularNounPhrase(arbitrary):
    ('any' | 'one' | '1' | 'any' ('one' | '1')) indetSingularNounPhrase->np_
    : Production

    determiner = Indefinite
;

grammar qualifiedSingularNounPhrase(possessive):
    possessiveAdjPhrase->poss_ indetSingularNounPhrase->np_
    | indetSingularNounPhrase->np_ 'of' possessiveNounPhrase->poss_
    : Production
;

grammar qualifiedSingularNounPhrase(anyPlural):
    ('any' | 'one' | 'any' 'one' | ) 'of' explicitDetPluralNounPhrase->np_
    : Production

    determiner = Indefinite
;

grammar qualifiedSingularNounPhrase(theOneIn):
    'the' 'one' ('that' ('is' | 'was') | 'that' tokApostropheS | )
    locationPrep->prep_ completeNounPhraseWithoutAll->cont_
    : LocationalProduction

    determiner = Definite
;

grammar qualifiedSingularNounPhrase(theOneContaining):
    'the' 'one' contentsPrepOrVerb->prep_ completeNounPhraseWithoutAll->cont_
    : ContentsQualifierProduction

    determiner = Definite
;

grammar qualifiedSingularNounPhrase(anyOneIn):
    ('anything' | 'one') ('that' ('is' | 'was') | 'that' tokApostropheS | )
    locationPrep->prep_
    completeNounPhraseWithoutAll->cont_
    : LocationalProduction

    determiner = Indefinite
;

grammar locationPrep(in):
    'in' | 'inside' | 'inside' 'of'
    : LocationPrepProduction

    locType = In
;

grammar locationPrep(on):
    'on' | 'upon' | 'on' 'top' 'of'
    : LocationPrepProduction

    locType = On
;

grammar locationPrep(from):
    'from'
    : LocationPrepProduction

    locType = nil
;

grammar contentsPrep(main):
    'of' | 'containing'
    : Production
;

grammar contentsPrepOrVerb(main):
    'contains' | 'has' | contentsPrep
    : Production
;

grammar indetSingularNounPhrase(basic):
    nounPhraseWithContents->np_
    : Production
;

grammar indetSingularNounPhrase(locational):
    nounPhraseWithContents->np_
    ('that' ('is' | 'was')
     | 'that' tokApostropheS
     | 'that' ('are' | 'were')
     | ) locationPrep->prep_ completeNounPhraseWithoutAll->cont_
    : LocationalProduction
;

grammar nounPhraseWithContents(basic):
    nounPhrase->np_
    : Production
;

grammar nounPhraseWithContents(contents):
    nounPhraseWithContents->np_ contentsPrep->prep_ nounPhrase->cont_
    : ContentsQualifierProduction
;

grammar qualifiedPluralNounPhrase(determiner):
    'any' detPluralOnlyNounPhrase->np_
    : Production

    determiner = Indefinite
;

grammar qualifiedPluralNounPhrase(anyNum):
    ('any' | ) numberPhrase->quant_ indetPluralNounPhrase->np_
    | ('any' | ) numberPhrase->quant_ 'of' explicitDetPluralNounPhrase->np_
    : QuantifierProduction

    determiner = Indefinite
;

grammar qualifiedPluralNounPhrase(allNum):
    'all' numberPhrase->quant_ indetPluralNounPhrase->np_
    | 'all' numberPhrase->quant_ 'of' explicitDetPluralNounPhrase->np_
    : QuantifierProduction

    /* 
     *   even though the wording is ALL, the number makes this definite:
     *   ALL SEVEN implies that there are EXACTLY seven things we're
     *   talking about 
     */
    determiner = Definite
;

grammar qualifiedPluralNounPhrase(both):
    'both' detPluralNounPhrase->np_
    | 'both' 'of' explicitDetPluralNounPhrase->np_
    : QuantifierProduction

    /* 
     *   BOTH is effectively equivalent to THE TWO - it implies that there
     *   are ONLY two objects we could be talking about 
     */
    determiner = Definite
    numval = 2
;

grammar qualifiedPluralNounPhrase(definiteNum):
    'the' numberPhrase->quant_ indetPluralNounPhrase->np_
    : QuantifierProduction

    determiner = Definite
;

grammar qualifiedPluralNounPhrase(all):
    'all' detPluralNounPhrase->np_
    | 'all' 'of' explicitDetPluralNounPhrase->np_
    : Production

    determiner = All
;

grammar qualifiedPluralNounPhrase(theOnesIn):
    ('the' 'ones' ('that' ('are' | 'were') | )
     | ('everything' | 'all')
       ('that' ('is' | 'was') | 'that' tokApostropheS | ))
    locationPrep->prep_ completeNounPhraseWithoutAll->cont_
    : LocationalProduction

    determiner = All
;

grammar qualifiedPluralNounPhrase(theOnesContaining):
    ('the' 'ones' | 'everything' | 'all')
    contentsPrepOrVerb->prep_ completeNounPhraseWithoutAll->cont_
    : ContentsQualifierProduction

    determiner = All
;

grammar detPluralNounPhrase(main):
    indetPluralNounPhrase->np_ | explicitDetPluralNounPhrase->np_
    : Production
;

grammar detPluralOnlyNounPhrase(main):
    implicitDetPluralOnlyNounPhrase->np_
    | explicitDetPluralOnlyNounPhrase->np_
    : Production
;

grammar implicitDetPluralOnlyNounPhrase(main):
    indetPluralOnlyNounPhrase->np_
    : Production
;

grammar explicitDetPluralNounPhrase(definite):
    'the' indetPluralNounPhrase->np_
    : Production

    determiner = Definite
;

grammar explicitDetPluralNounPhrase(definiteNumber):
    'the' numberPhrase->quant_ indetPluralNounPhrase->np_
    : QuantifierProduction

    determiner = Definite
;

grammar explicitDetPluralNounPhrase(possessive):
    possessiveAdjPhrase->poss_ indetPluralNounPhrase->np_
    | indetPluralNounPhrase->np_ 'of' possessiveNounPhrase->poss_
    : Production
;

grammar explicitDetPluralNounPhrase(possessiveNumber):
    possessiveAdjPhrase->poss_ numberPhrase->quant_ indetPluralNounPhrase->np_
    | 'the' numberPhrase->quant_ indetPluralNounPhrase->np_ 
      'of' possessiveNounPhrase->poss_
    : QuantifierProduction

    /* 
     *   the possessive makes this definite: BOB'S FIVE BOOKS implies that
     *   Bob has EXACTLY five books 
     */
    determiner = Definite
;

grammar explicitDetPluralNounPhrase(possessiveNumber2):
    numberPhrase->quant_ indetPluralNounPhrase->np_
       'of' possessiveNounPhrase->poss_
    : QuantifierProduction

    /* FIVE BOOKS OF BOB'S is indefinite */
    determiner = Indefinite
;

grammar explicitDetPluralOnlyNounPhrase(definite):
    'the' indetPluralOnlyNounPhrase->np_
    : Production

    determiner = Definite
;

grammar explicitDetPluralOnlyNounPhrase(definiteNumber):
    'the' numberPhrase->quant_ indetPluralNounPhrase->np_
    : QuantifierProduction

    determiner = Definite
;

grammar explicitDetPluralOnlyNounPhrase(possessive):
    possessiveAdjPhrase->poss_ indetPluralOnlyNounPhrase->np_
    | indetPluralOnlyNounPhrase->np_ 'of' possessiveNounPhrase->poss_
    : Production
;

grammar explicitDetPluralOnlyNounPhrase(possessiveNumber):
    possessiveAdjPhrase->poss_ numberPhrase->quant_ indetPluralNounPhrase->np_
    | 'the' numberPhrase->quant_ indetPluralNounPhrase->np_
      'of' possessiveNounPhrase->poss_
    : QuantifierProduction

    /* the possessive makes this definite */
    determiner = Definite
;

grammar explicitDetPluralOnlyNounPhrase(possessiveNumber2):
    numberPhrase->quant_ indetPluralNounPhrase->np_
      'of' possessiveNounPhrase->poss_
    : QuantifierProduction

    /* FIVE BOOKS OF BOB'S is indefinite */
    determiner = Indefinite
;

grammar indetPluralNounPhrase(basic):
    pluralPhraseWithContents->np_
    : Production
;

grammar indetPluralNounPhrase(locational):
    pluralPhraseWithContents->np_ ('that' ('are' | 'were') | )
    locationPrep->prep_ completeNounPhraseWithoutAll->cont_
    : LocationalProduction
;

grammar pluralPhraseWithContents(basic):
    pluralPhrase->np_
    : Production
;

grammar pluralPhraseWithContents(contents):
    pluralPhraseWithContents->np_ contentsPrep->prep_ nounPhrase->cont_
    : ContentsQualifierProduction
;

grammar indetPluralOnlyNounPhrase(basic):
    pluralPhrase->np_
    : Production
;

grammar indetPluralOnlyNounPhrase(locational):
    pluralPhrase->np_ ('that' ('are' | 'were') | )
    locationPrep->prep_ completeNounPhraseWithoutAll->cont_
    : LocationalProduction
;

grammar nounPhrase(main): compoundNounPhrase->np_
    : CoreNounPhraseProduction
;

grammar pluralPhrase(main): compoundPluralPhrase->np_
    : CoreNounPhraseProduction
;

grammar compoundNounPhrase(simple): simpleNounPhrase->np_
    : Production
;

grammar compoundNounPhrase(of):
    simpleNounPhrase->np1_ compoundNounPrep->prep_
      compoundNounArticle compoundNounPhrase->np2_
    : Production
;

grammar compoundNounPrep(main):
    'of'->prep_ | 'to'->prep_ | 'for'->prep_ | 'from'->prep_ | 'with'->prep_
    : Production
;

grammar compoundNounArticle(main):
    ('the' | 'a' | 'an' | )
    : Production
;

grammar compoundPluralPhrase(simple): simplePluralPhrase->np_
    : Production
;

grammar compoundPluralPhrase(of):
    simplePluralPhrase->np1_ compoundNounPrep->prep_
      compoundNounArticle->article_ compoundNounPhrase->np2_
    : Production
;

grammar simpleNounPhrase(noun): nounWord->noun_ : Production
;

grammar simpleNounPhrase(list): nounWord->noun_ simpleNounPhrase->np_
    : Production
;

grammar simpleNounPhrase(literal): literalNounPhrase->noun_
    : Production
;

grammar simpleNounPhrase(literalAndList):
    literalNounPhrase->noun_ simpleNounPhrase->np_
    : Production
;

grammar simpleNounPhrase(adjAndOne): noun->noun_ 'one'
    : Production
;

grammar simpleNounPhrase(adjAndOnes): noun->noun_ 'ones'
    : Production
;

grammar simpleNounPhrase(misc):
    [badness 200] miscWordList->lst_ : Production
;

grammar simpleNounPhrase(empty): [badness 600] : EmptyNounProduction
;

grammar literalNounPhrase(number):
    numberPhrase->num_ | poundNumberPhrase->num_
    : Production
;

grammar literalNounPhrase(string): quotedStringPhrase->str_
    : Production
;

grammar nounWord(noun): noun->noun_ : Production
;

grammar nounWord(nounApostS): nounApostS->noun_ tokApostropheS->apost_
    : Production
;

grammar nounWord(nounAbbr): noun->noun_ tokAbbrPeriod->period_
    : Production
;

grammar possessiveAdjPhrase(its): 'its' : PossessiveProduction
    pronoun = It
;
grammar possessiveAdjPhrase(his): 'his' : PossessiveProduction
    pronoun = Him
;
grammar possessiveAdjPhrase(her): 'her' : PossessiveProduction
    pronoun = Her
;
grammar possessiveAdjPhrase(their): 'their' : PossessiveProduction
    pronoun = Them
;
grammar possessiveAdjPhrase(your): 'your' : PossessiveProduction
    pronoun = You
;
grammar possessiveAdjPhrase(my): 'my' : PossessiveProduction
    pronoun = Me
;

grammar possessiveAdjPhrase(npApostropheS):
    nounPhrase->np_ tokApostropheS : PossessiveProduction
;

grammar possessiveAdjPhrase(definiteNpApostropheS):
    'the' nounPhrase->np_ tokApostropheS : PossessiveProduction

    determine = Definite
;

grammar possessiveAdjPhrase(indefiniteNpApostropheS):
    ('a' | 'an') nounPhrase->np_ tokApostropheS : PossessiveProduction

    determiner = Indefinite
;

grammar possessiveNounPhrase(its): 'its': PossessiveProduction
    pronoun = It
;
grammar possessiveNounPhrase(his): 'his': PossessiveProduction
    pronoun = Him
;
grammar possessiveNounPhrase(hers): 'hers': PossessiveProduction
    pronoun = Her
;
grammar possessiveNounPhrase(theirs): 'theirs': PossessiveProduction
    pronoun = Them
;
grammar possessiveNounPhrase(yours): 'yours' : PossessiveProduction
    pronoun = You
;
grammar possessiveNounPhrase(mine): 'mine' : PossessiveProduction
    pronoun = Me
;

grammar possessiveNounPhrase(npApostropheS):
    (nounPhrase->np_ | pluralPhrase->np_) tokApostropheS
    : PossessiveProduction
;

grammar simplePluralPhrase(plural): simpleNounPhrase->noun_ : Production
;

grammar simplePluralPhrase(adjAndOnes): noun->noun_ 'ones'
    : Production
;

grammar simplePluralPhrase(empty): [badness 600] : EmptyNounProduction
;

grammar simplePluralPhrase(misc):
    [badness 300] miscWordList->lst_ : Production
;

grammar topicPhrase(main): singleNoun->np_ : TopicNounProduction
;

grammar topicPhrase(misc): miscWordList->np_ : TopicNounProduction
;

grammar quotedStringPhrase(main): tokString->str_ : Production
   getStringText() { return stripQuotesFrom(str_); }
;

/*
 *   Service routine: strip quotes from a *possibly* quoted string.  If the
 *   string starts with a quote, we'll remove the open quote.  If it starts
 *   with a quote and it ends with a corresponding close quote, we'll
 *   remove that as well.  
 */
stripQuotesFrom(str)
{
    local hasOpen;
    local hasClose;

    /* presume we won't find open or close quotes */
    hasOpen = hasClose = nil;

    /*
     *   Check for quotes.  We'll accept regular ASCII "straight" single
     *   or double quotes, as well as Latin-1 curly single or double
     *   quotes.  The curly quotes must be used in their normal
     */
    if (str.startsWith('\'') || str.startsWith('"'))
    {
        /* single or double quote - check for a matching close quote */
        hasOpen = true;
        hasClose = (str.length() > 2 && str.endsWith(str.substr(1, 1)));
    }
    else if (str.startsWith('`'))
    {
        /* single in-slanted quote - check for either type of close */
        hasOpen = true;
        hasClose = (str.length() > 2
                    && (str.endsWith('`') || str.endsWith('\'')));
    }
    else if (str.startsWith('\u201C'))
    {
        /* it's a curly double quote */
        hasOpen = true;
        hasClose = str.endsWith('\u201D');
    }
    else if (str.startsWith('\u2018'))
    {
        /* it's a curly single quote */
        hasOpen = true;
        hasClose = str.endsWith('\u2019');
    }

    /* trim off the quotes */
    if (hasOpen)
    {
        if (hasClose)
            str = str.substr(2, str.length() - 2);
        else
            str = str.substr(2);
    }

    /* return the modified text */
    return str;
}


grammar literalPhrase(string): quotedStringPhrase->str_ : LiteralNounProduction
;

grammar literalPhrase(miscList): miscWordList->misc_ : LiteralNounProduction
;

grammar literalPhrase(empty): [badness 400]: EmptyNounProduction
;

grammar miscWordList(wordOrNumber):
    tokWord->txt_ | tokInt->txt_ | tokApostropheS->txt_
    | tokPoundInt->txt_ | tokString->txt_ | tokAbbrPeriod->txt_
    : MiscWordListProduction
;

grammar miscWordList(list):
    (tokWord->txt_ | tokInt->txt_ | tokApostropheS->tok_ | tokAbbrPeriod->txt_
     | tokPoundInt->txt_ | tokString->txt_) miscWordList->lst_
    : MiscWordListProduction
;

/*
 *   The top-level disambiguation grammar.  The parser uses this to parse
 *   input that might be an answer to a disambiguation prompt ("Which did
 *   you mean...?").
 *   
 *   We accept whole noun phrases and various fragments of noun phrases in
 *   response to these questions.  We accept fragments because (a) users
 *   are accustomed from lots of other IF games to being able to respond
 *   with a word or two, and (b) all we need is something that
 *   distinguishes one object from another.
 *   
 *   This should use DisambigProduction as the base class for the match
 *   tree item.
 *   
 *   [Required] 
 */
grammar mainDisambigPhrase(main):
    disambigPhrase->dp_
    | disambigPhrase->dp_ '.'
    : DisambigProduction
;

grammar disambigPhrase(all):
    'all' | 'everything' | 'all' 'of' 'them' : Production

    determiner = All
;

grammar disambigPhrase(both): 'both' | 'both' 'of' 'them'
    : QuantifierProduction

    /* BOTH is definite because it implies there are EXACTLY two matches */
    determiner = Definite
    numval = 2
;

grammar disambigPhrase(any): 'any' | 'any' 'of' 'them' : Production
    determiner = Indefinite
;

grammar disambigPhrase(list): disambigList->lst_ : Production
;

grammar disambigPhrase(ordinalList):
    disambigOrdinalList->lst_ 'ones'
    | 'the' disambigOrdinalList->lst_ 'ones'
    : Production

    determiner = Definite
;

grammar disambigPhrase(locational):
    locationPrep->prep_ completeNounPhraseWithoutAll->cont_
    : LocationalProduction

    determiner = Definite
;

grammar disambigOrdinalList(tail):
    disambigOrdinalItem->np1_ ('and' | ',') disambigOrdinalItem->np2_
    : NounListProduction
;

grammar disambigOrdinalList(head):
    disambigOrdinalItem->np1_ ('and' | ',') disambigOrdinalList->np2_
    : NounListProduction
;

dictionary property ordinalWord;
grammar disambigOrdinalItem(main):
    ordinalWord->ord_
    : OrdinalProduction

    determiner = Definite

    /* look up the value of the ordinal word */
    ordval() { return cmdDict.findWord(ord_, &ordinalWord)[1].ordinalVal; }
;

grammar disambigList(single): disambigListItem->np1_ :
    NounListProduction
;

grammar disambigList(list):
    disambigListItem->np1_ commandOrNounConjunction disambigList->np2_
    : NounListProduction
;

grammar disambigListItem(ordinal):
    ordinalWord->ord_
    | ordinalWord->ord_ 'one'
    | 'the' ordinalWord->ord_
    | 'the' ordinalWord->ord_ 'one'
    : OrdinalProduction

    determiner = Definite

    /* look up the value of the ordinal word */
    ordval() { return cmdDict.findWord(ord_, &ordinalWord)[1].ordinalVal; }
;

grammar disambigListItem(noun):
    completeNounPhraseWithoutAll->np_
    | terminalNounPhrase->np_
    : Production
;

grammar disambigListItem(plural):
    pluralPhrase->np_
    : Production

    determiner = Definite
;

grammar disambigListItem(possessive):
    possessiveNounPhrase->poss_
    : Production
;



/*
 *   Ordinal words.  We define a limited set of these, since we only use
 *   them in a few special contexts where it would be unreasonable to need
 *   even as many as define here.
 */
#define defOrdinal(str, val) object ordinalWord=#@str ordinalVal=val

defOrdinal(former, 1);
defOrdinal(first, 1);
defOrdinal(second, 2);
defOrdinal(third, 3);
defOrdinal(fourth, 4);
defOrdinal(fifth, 5);
defOrdinal(sixth, 6);
defOrdinal(seventh, 7);
defOrdinal(eighth, 8);
defOrdinal(ninth, 9);
defOrdinal(tenth, 10);
defOrdinal(eleventh, 11);
defOrdinal(twelfth, 12);
defOrdinal(thirteenth, 13);
defOrdinal(fourteenth, 14);
defOrdinal(fifteenth, 15);
defOrdinal(sixteenth, 16);
defOrdinal(seventeenth, 17);
defOrdinal(eighteenth, 18);
defOrdinal(nineteenth, 19);
defOrdinal(twentieth, 20);
defOrdinal(1st, 1);
defOrdinal(2nd, 2);
defOrdinal(3rd, 3);
defOrdinal(4th, 4);
defOrdinal(5th, 5);
defOrdinal(6th, 6);
defOrdinal(7th, 7);
defOrdinal(8th, 8);
defOrdinal(9th, 9);
defOrdinal(10th, 10);
defOrdinal(11th, 11);
defOrdinal(12th, 12);
defOrdinal(13th, 13);
defOrdinal(14th, 14);
defOrdinal(15th, 15);
defOrdinal(16th, 16);
defOrdinal(17th, 17);
defOrdinal(18th, 18);
defOrdinal(19th, 19);
defOrdinal(20th, 20);

/*
 *   the special 'last' ordinal - the value -1 is special to indicate the
 *   last item in a list
 */
defOrdinal(last, -1);
defOrdinal(latter, -1);


grammar numberObjPhrase(main): numberPhrase->num_ : NumberNounProduction
;

grammar numberPhrase(digits): tokInt->num_ : Production
    numval = (toInteger(num_))
;

grammar numberPhrase(spelled): spelledNumber->num_ : Production
    numval = (num_.numval)
;

grammar poundNumberPhrase(main): tokPoundInt->num_ : Production
;

/*
 *   Number literals.  We'll define a set of special objects for numbers:
 *   each object defines a number and a value for the number.
 */
dictionary property digitWord, teenWord, tensWord;
#define defDigit(num, val) object digitWord=#@num numval=val
#define defTeen(num, val)  object teenWord=#@num numval=val
#define defTens(num, val)  object tensWord=#@num numval=val

defDigit(one, 1);
defDigit(two, 2);
defDigit(three, 3);
defDigit(four, 4);
defDigit(five, 5);
defDigit(six, 6);
defDigit(seven, 7);
defDigit(eight, 8);
defDigit(nine, 9);
defTeen(ten, 10);
defTeen(eleven, 11);
defTeen(twelve, 12);
defTeen(thirteen, 13);
defTeen(fourteen, 14);
defTeen(fifteen, 15);
defTeen(sixteen, 16);
defTeen(seventeen, 17);
defTeen(eighteen, 18);
defTeen(nineteen, 19);
defTens(twenty, 20);
defTens(thirty, 30);
defTens(forty, 40);
defTens(fifty, 50);
defTens(sixty, 60);
defTens(seventy, 70);
defTens(eighty, 80);
defTens(ninety, 90);

grammar spelledSmallNumber(digit): digitWord->num_ : Production
    numval()
    {
        /* look up the units word in the dictionary */
        return cmdDict.findWord(num_, &digitWord)[1].numval;
    }
;

grammar spelledSmallNumber(teen): teenWord->num_ : Production
    numval()
    {
        /* look up the units word in the dictionary */
        return cmdDict.findWord(num_, &teenWord)[1].numval;
    }
;

grammar spelledSmallNumber(tens): tensWord->num_ : Production
    numval()
    {
        /* look up the units word in the dictionary */
        return cmdDict.findWord(num_, &tensWord)[1].numval;
    }
;

grammar spelledSmallNumber(tensAndUnits):
    tensWord->tens_ '-'->sep_ digitWord->units_
    | tensWord->tens_ digitWord->units_
    : Production

    numval = (tens_.numval + units_.numval)
;

grammar spelledSmallNumber(zero): 'zero' : Production
    numval = 0
;

grammar spelledHundred(small): spelledSmallNumber->num_ : Production
    numval = (num_.numval)
;

grammar spelledHundred(hundreds): spelledSmallNumber->hun_ 'hundred'
    : Production

    numval = (hun_.numval*100)
;

grammar spelledHundred(hundredsPlus):
    spelledSmallNumber->hun_ 'hundred' spelledSmallNumber->num_
    | spelledSmallNumber->hun_ 'hundred' 'and'->and_ spelledSmallNumber->num_
    : Production

    numval = (hun_*100 + num_.numval)
;

grammar spelledHundred(aHundred): 'a' 'hundred' : Production
;

grammar spelledHundred(aHundredPlus):
    'a' 'hundred' 'and' spelledSmallNumber->num_
    : Production

    numval = (100 + num_.numval)
;

grammar spelledThousand(thousands): spelledHundred->thou_ 'thousand'
    : Production

    numval = (thou_.numval*1000)
;

grammar spelledThousand(thousandsPlus):
    spelledHundred->thou_ 'thousand' spelledHundred->num_
    : Production

    numval = (thou_.numval*1000 + num_.numval)
;

grammar spelledThousand(thousandsAndSmall):
    spelledHundred->thou_ 'thousand' 'and' spelledSmallNumber->num_
    : Production

    numval = (1000 + num_.numval)
;

grammar spelledThousand(aThousand): 'a' 'thousand' : Production
    numval = 1000
;

grammar spelledThousand(aThousandAndSmall):
    'a' 'thousand' 'and' spelledSmallNumber->num_
    : Production

    numval = (1000 + num_.numval)
;

grammar spelledMillion(millions): spelledHundred->mil_ 'million': Production
    numval = (mil_.numval*1000000)
;

grammar spelledMillion(millionsPlus):
    spelledHundred->mil_ 'million'
    (spelledThousand->nxt_ | spelledHundred->nxt_)
    : Production

    numval = (mil_.numval*1000000 + nxt_.numval)
;

grammar spelledMillion(aMillion): 'a' 'million' : Production
    numval = 1000000
;

grammar spelledMillion(aMillionAndSmall):
    'a' 'million' 'and' spelledSmallNumber->num_
    : Production

    numval = (1000000 + num_.numval)
;

grammar spelledMillion(millionsAndSmall):
    spelledHundred->mil_ 'million' 'and' spelledSmallNumber->num_
    : Production

    numval = (mil_.numval*1000000 + num_.numval)
;

grammar spelledNumber(main):
    spelledHundred->num_
    | spelledThousand->num_
    | spelledMillion->num_
    : Production

    numval = (num_.numval)
;

/*
 *   The main grammar for an OOPS command.  This is separate from the main
 *   command grammar, since OOPS commands are somewhat special (in
 *   particular, they can't be mixed with other commands on an input line).
 *   
 *   The grammar tree for an OOPS command must include one or more
 *   OopsProduction objects.  Each of these must have a '->toks_' property
 *   that gives the sub-production with the literal token list of the
 *   correction.
 *   
 *   [Required] 
 */
grammar oopsCommand(main):
    oopsPhrase->oops_ | oopsPhrase->oops_ '.' : Production
;

grammar oopsPhrase(main):
    'oops' miscWordList->toks_
    | 'oops' ',' miscWordList->toks_
    | 'o' miscWordList->toks_
    | 'o' ',' miscWordList->toks_
    : OopsProduction
;

///* ------------------------------------------------------------------------ */
///*
// *   Direction grammar rules.
// */
class DirectionName : object;

#define DefineLangDir(root, dirNames, backPre) \
grammar directionName(root): dirNames: Production \
   dir = root##Dir \
; \
\
   root##Direction: DirectionName \
   name = #@root \
   backToPrefix = backPre

DefineLangDir(north, 'north' | 'n', 'back to the');
DefineLangDir(south, 'south' | 's', 'back to the');
DefineLangDir(east, 'east' | 'e', 'back to the');
DefineLangDir(west, 'west' | 'w', 'back to the');
DefineLangDir(northeast, 'northeast' | 'ne', 'back to the');
DefineLangDir(northwest, 'northwest' | 'nw', 'back to the');
DefineLangDir(southeast, 'southeast' | 'se', 'back to the');
DefineLangDir(southwest, 'southwest' | 'sw', 'back to the');
DefineLangDir(up, 'up' | 'u', 'back');
DefineLangDir(down, 'down' | 'd', 'back');
DefineLangDir(in, 'in', 'back');
DefineLangDir(out, 'out', 'back');
DefineLangDir(port, 'port' | 'p', 'back to');
DefineLangDir(starboard, 'starboard' | 'sb', 'back to');
DefineLangDir(aft, 'aft', 'back');
DefineLangDir(fore, 'fore' | 'f' ,  'back');
//

/* ------------------------------------------------------------------------ */
/*
 *   Yes or No phrase.  This is a reply to a simple Yes/No question.
 *   
 *   [Required] 
 */
grammar yesOrNoPhrase(yes): 'yes' : YesOrNoProduction
    answer = true
;
grammar yesOrNoPhrase(no): 'no' : YesOrNoProduction
    answer = nil
;


/* ------------------------------------------------------------------------ */
/*
 *   Verb grammar (predicate) rules for English.
 *   
 *   English's predicate syntax is highly positional.  That is, the role of
 *   each word in a predicate is determined largely by its position in the
 *   phrase.  There are a several common patterns to the predicate word
 *   order, but the specific pattern that applies to a given verb is
 *   essentially idiomatic to that verb, especially with respect to
 *   complement words (like the "up" in "pick up").  Our approach to
 *   defining the predicate grammar is therefore to define a separate,
 *   custom syntax rule for each verb.  This makes it easy to add rules for
 *   the odd little idioms in English verbs.
 *   
 *   For verbs that take indirect objects, the indirect object is usually
 *   introduced by a preposition (e.g., PUT KEY IN LOCK).  Since we
 *   consider the preposition in such a case to be part of the verb's
 *   grammatical structure, we write it directly into the grammar rule as a
 *   literal.  This means that we wouldn't be able to parse input that's
 *   missing the whole indirect object phrase (e.g., PUT KEY).  We don't
 *   want to just reject those without explanation, though, which means we
 *   have to define separate grammar rules for the truncated verbs.  Some
 *   of these cases are valid commands in their own right: UNLOCK DOOR and
 *   UNLOCK DOOR WITH KEY are both valid grammatically.  But PUT KEY isn't,
 *   so we need to mark this as missing its indirect object.  We do this by
 *   setting the missingRole property for these rules to the role (usually
 *   IndirectObject) of the phrase that's missing.
 *   
 *   Each VerbRule has several properties and methods that it can or must
 *   define:
 *   
 *   action [Required] - The associated Action that's executed when this
 *   verb is parsed.  The base library requires this property.
 *   
 *   verbPhrase - The message-building template for the verb.  The library
 *   uses this to construct messages to describe the associated action.
 *   The format is 'verb/verbing (dobj) (iobj) (accessory)'.  Each object
 *   role in parentheses consists of an optional preposition and the word
 *   'what' or 'whom'.  For example, 'ask/asking (whom) (about what)'.
 *   Outside of the parentheses, you can also include verb complement words
 *   before the first object or after the last, but never between objects:
 *   for example, 'pick/picking up (what)'.
 *   
 *   missingQ - the template for asking missing object questions.  This
 *   consists of one question per object, separated by semicolons, in the
 *   order dobj, iobj, accessory.  You only need as many questions as the
 *   verb has object slots (i.e., you only need an iobj question if the
 *   verb takes an indirect object).  The question is simply of the form
 *   "what do you want to <verb>", but you can also include the words "it"
 *   and "that" to refer to the "other" object(s) in the verb.  "It" will
 *   be replaced by it/him/her/them as appropriate, and "that" by
 *   that/them.  Use it-dobj, it-iobj, it-acc to specify which other object
 *   you're talking about (which is never necessary for two-object verbs,
 *   since there's only one other object).  Put the entire 'it' phrase,
 *   including prepositions, in parentheses to make it optional; it will be
 *   omitted if the object isn't part of the command input.  This is only
 *   necessary for objects appearing earlier in the verb rule, since it's
 *   resolved left to right.
 *   
 *   missingRole - the object role (DirectObject, etc) that's explicitly
 *   missing from this grammar syntax.  This is for rules that you define
 *   specifically to recognize partial input, like "PUT <dobj>".  The
 *   parser will ask for the missing object when it resolves such a rule.
 *   
 *   answerMissing(cmd, np) - the base library calls this when the player
 *   answers the parser's question asking for the missing noun phrase.
 *   'cmd' is the Command, and 'np' is the noun phrase parsed from the
 *   user's answer to the query.  This is called from the base library but
 *   isn't required, in that it's purely advisory.  The point of this
 *   routine is to let the verb change the command according to the reply.
 *   For example, in English, we have a generic Put <dobj> verb that asks
 *   where to put the dobj.  If the user says "in the box", we can change
 *   the action to Put In; if the user says "on the table", we can change
 *   the action to Put On.
 *   
 *   dobjReply, iobjReply, accReply - the noun phrase production to use for
 *   parsing a reply to the missing-object question for the corresponding
 *   role.  Players sometimes reply to a question like "What do you want to
 *   put it in?" by starting the answer with the same preposition in the
 *   question: "in the box".  To support this, you can specify a noun
 *   phrase production that starts with the appropriate preposition
 *   (inSingleNoun, onSingleNoun, etc). 
 *   
 *   (Note that the base library doesn't place any requirements on exactly
 *   how the verb rules are defined.  In particular, you don't have to
 *   define one rule per verb, the way we do in English.  The English
 *   module's one-verb/one-rule approach might not be a good fit when
 *   implementing a highly inflected language, since such languages are
 *   typically a lot more flexible about word order, creating a wide range
 *   of possible phrasings for each verb.  It might be easier to for such a
 *   language to define a set of universal verb grammar rules that cover
 *   the common structures for all verbs, and then define the individual
 *   verbs as simple vocabulary words that slot into this universal phrase
 *   structure.)  
 */

VerbRule(Take)
    ('take' | 'pick' 'up' | 'get') multiDobj
    | 'pick' multiDobj 'up'
    : VerbProduction
    action = Take
    verbPhrase = 'take/taking (what)'
    missingQ = 'what do you want to take'
;

VerbRule(TakeFrom)
    ('take' | 'get') multiDobj
        ('from' | 'out' 'of' | 'off' | 'off' 'of') singleIobj
    | 'remove' multiDobj 'from' singleIobj
    : VerbProduction
    action = TakeFrom
    verbPhrase = 'take/taking (what) (from what)'
    missingQ = 'what do you want to take;what do you want to take it from'
;

VerbRule(Remove)
    'remove' multiDobj
    : VerbProduction
    action = Remove
    verbPhrase = 'remove/removing (what)'
    missingQ = 'what do you want to remove'
;

VerbRule(Drop)
    ('drop' | 'put' 'down' | 'set' 'down') multiDobj
    | ('put' | 'set') multiDobj 'down'
    : VerbProduction
    action = Drop
    verbPhrase = 'drop/dropping (what)'
    missingQ = 'what do you want to drop'
;

VerbRule(Examine)
    ('examine' | 'inspect' | 'x' | 'look' ('at'|) | 'l' ('at'|)) multiDobj
    : VerbProduction
    action = Examine
    verbPhrase = 'examine/examining (what)'
    missingQ = 'what do you want to examine'
;

VerbRule(Read)
    'read' multiDobj
    : VerbProduction
    action = Read
    verbPhrase = 'read/reading (what)'
    missingQ = 'what do you want to read'
;

VerbRule(LookIn)
    ('look' | 'l') ('in' | 'inside') multiDobj
    : VerbProduction
    action = LookIn
    verbPhrase = 'look/looking (in what)'
    missingQ = 'what do you want to look in'
;

VerbRule(Search)
    'search' multiDobj
    : VerbProduction
    action = Search
    verbPhrase = 'search/searching (what)'
    missingQ = 'what do you want to search'
;

VerbRule(LookThrough)
    ('look' | 'l' | 'peer') ('through' | 'thru' | 'out') multiDobj
    : VerbProduction
    action = LookThrough
    verbPhrase = 'look/looking (through what)'
    missingQ = 'what do you want to look through'
;

VerbRule(LookUnder)
    ('look' | 'l') 'under' multiDobj
    : VerbProduction
    action = LookUnder
    verbPhrase = 'look/looking (under what)'
    missingQ = 'what do you want to look under'
;

VerbRule(LookBehind)
    ('look' | 'l') 'behind' multiDobj
    : VerbProduction
    action = LookBehind
    verbPhrase = 'look/looking (behind what)'
    missingQ = 'what do you want to look behind'
;

VerbRule(Feel)
    ('feel' | 'touch') multiDobj
    : VerbProduction
    action = Feel
    verbPhrase = 'touch/touching (what)'
    missingQ = 'what do you want to touch'
;

VerbRule(Taste)
    'taste' multiDobj
    : VerbProduction
    action = Taste
    verbPhrase = 'taste/tasting (what)'
    missingQ = 'what do you want to taste'
;

VerbRule(SmellSomething)
    ('smell' | 'sniff') multiDobj
    : VerbProduction
    action = SmellSomething
    verbPhrase = 'smell/smelling (what)'
    missingQ = 'what do you want to smell'
;

VerbRule(Smell)
    'smell' | 'sniff'
    : VerbProduction
    action = Smell
    verbPhrase = 'smell/smelling'
;

VerbRule(ListenTo)
    ('hear' | 'listen' 'to' ) multiDobj
    : VerbProduction
    action = ListenTo
    verbPhrase = 'listen/listening (to what)'
    missingQ = 'what do you want to listen to'
;

VerbRule(Listen)
    'listen' | 'hear'
    : VerbProduction
    action = Listen
    verbPhrase = 'listen/listening'
;

VerbRule(PutIn)
    ('put' | 'place' | 'set' | 'insert') multiDobj
        ('in' | 'into' | 'in' 'to' | 'inside' | 'inside' 'of') singleIobj
    : VerbProduction
    action = PutIn
    verbPhrase = 'put/putting (what) (in what)'
    missingQ = 'what do you want to put (in it);what do you want to put it in'
    iobjReply = inSingleNoun
;

VerbRule(PutOn)
    ('put' | 'place' | 'drop' | 'set') multiDobj
        ('on' | 'onto' | 'on' 'to' | 'upon') singleIobj
    | 'put' multiDobj 'down' 'on' singleIobj
    : VerbProduction
    action = PutOn
    verbPhrase = 'put/putting (what) (on what)'
    missingQ = 'what do you want to put (on it);what do you want to put it on'
    iobjReply = onSingleNoun
;

VerbRule(PutUnder)
    ('put' | 'place' | 'set') multiDobj 'under' singleIobj
    : VerbProduction
    action = PutUnder
    verbPhrase = 'put/putting (what) (under what)'
    missingQ = 'what do you want to put (under it);'
             + 'what do you want to put it under'
;

VerbRule(PutBehind)
    ('put' | 'place' | 'set') multiDobj 'behind' singleIobj
    : VerbProduction
    action = PutBehind
    verbPhrase = 'put/putting (what) (behind what)'
    missingQ = 'what do you want to put (behind it);'
    + 'what do you want to put it behind'
;

VerbRule(PutWhere)
    [badness 500] ('put' | 'place') multiDobj
    : VerbProduction
    action = PutIn
    verbPhrase = 'put/putting (what) (in what)'
    missingQ = 'what do you want to put;where do you want to put it'

    missingRole = IndirectObject
    iobjReply = putPrepSingleNoun

    /* 
     *   when the player supplies our missing indirect object by answering
     *   the "where do you want to put it" question, we'll change the
     *   action according to the preposition in the indirect object reply 
     */
    answerMissing(cmd, np)
    {
        /* this only applies to the indirect object */
        if (np.role == IndirectObject && np.prod.prep_ != nil)
        {
            /* get the prepositions they used */
            local preps = np.prod.prep_.getText();

            /* 
             *   look for a template with the same prepositions among the
             *   various Put grammar rules 
             */
            foreach (local action in [PutIn, PutOn, PutBehind, PutUnder])
            {
                if (action.grammarTemplates
                    .indexWhich({ t: t.find(preps) }) != nil)
                {
                    /* found it - use this action */
                    cmd.action = action;
                    return;
                }
            }
        }
    }

    priority = 25
;

VerbRule(Wear)
    ('wear' | 'don' | 'put' 'on') multiDobj
    | 'put' multiDobj 'on'
    : VerbProduction
    action = Wear
    verbPhrase = 'wear/wearing (what)'
    missingQ = 'what do you want to wear'
;

VerbRule(Doff)
    ('doff' | 'take' 'off') multiDobj
    | 'take' multiDobj 'off'
    : VerbProduction
    action = Doff
    verbPhrase = 'take/taking off (what)'
    missingQ = 'what do you want to take off'
;

VerbRule(Kiss)
    'kiss' singleDobj
    : VerbProduction
    action = Kiss
    verbPhrase = 'kiss/kissing (whom)'
    missingQ = 'whom do you want to kiss'
;

VerbRule(Query)
    ('a' | 'ask'|) ('what' ->qtype | 'who' ->qtype | 'where' -> qtype | 'why'
                   ->qtype | 'when' -> qtype| 'how' -> qtype | 'whether' ->
                    qtype | 'if' -> qtype) topicDobj
    : VerbProduction
    action = Query
    verbPhrase = 'ask/asking (what)'
    missingQ = 'what do you want to ask'
    priority = 60
;

VerbRule(QueryAbout)
    ('a' | 'ask'|) singleDobj ('what' ->qtype | 'who' ->qtype | 
                               'where' -> qtype | 'why'
                   ->qtype | 'when' -> qtype| 'how' -> qtype | 'whether' ->
                    qtype | 'if' -> qtype)  topicIobj
    : VerbProduction
    action = QueryAbout
    verbPhrase = 'ask/asking (what)'
    missingQ = 'what do you want to ask'
    priority = 60
;

VerbRule(QueryVague)
    ('a' | 'ask'|) ('what' ->qType | 'who' ->qtype | 'where' -> qtype | 'why'
                   ->qType | 'when' -> qtype| 'how' -> qtype | 'whether' ->
                    qtype | 'if' -> qtype) 
    : VerbProduction
    action = QueryVague
    verbPhrase = 'ask/asking (what)'
    missingQ = 'what do you want to ask'
    priority = 60
;

VerbRule(AuxQuery)
    ('do' | 'does' | 'did' | 'is' | 'are'| 'have' | 'has' |'can' |
     'could' | 'would' | 'should' ) topicDobj
    :VerbProduction
    action = Query
    missingQ = 'what do you want to ask'
    priority = 60
    qtype = 'if'
;

/* 
 *   For queries, turn an apostrophe-s form into the underlying qtype plus is so
 *   that the grammer defined immediately above can be matched.
 */

queryPreParser: StringPreParser
    doParsing(str, which)
    {
        local s = str.toLower();
        
        /* First, check that this looks like a query */
        if(s.startsWith('a ') || s.startsWith('ask ') || s.substr(1, 3) is in
           ('who', 'wha', 'whe', 'why', 'how'))
        {
            str = s.findReplace(['what\'s','who\'s', 'where\'s', 'why\'s',
                'when\'s', 'how\'s'], ['what is', 'who is', 'where is', 'why
                    is', 'when is', 'how is'], ReplaceOnce);        
                       
        
        }

    
        return str;
    }
;

VerbRule(AskFor)
    ('ask' | 'a') singleDobj 'for' topicIobj
    | ('ask' | 'a') 'for' topicIobj 'from' singleDobj
    : VerbProduction
    action = AskFor
    verbPhrase = 'ask/asking (whom) (for what)'
    missingQ = 'whom do you want to ask;what do you want to ask it for'
    dobjReply = singleNoun
    iobjReply = forSingleNoun
;

VerbRule(AskWhomFor)
    ('ask' | 'a') 'for' topicIobj
    : VerbProduction
    action = AskFor
    verbPhrase = 'ask/asking (whom) (for what)'
    missingQ = 'whom do you want to ask;what do you want to ask it for'

    priority = 25
;

VerbRule(AskForImplicit)
    ('a' | 'ask')  'for' topicIobj
    : VerbProduction
    action = AskForImplicit
    verbPhrase = 'ask/asking (whom) (for what)'
    missingQ = 'whom do you want to ask;what do you want to ask it for'
    iobjReply = topicPhrase
    priority = 60
;



VerbRule(AskAbout)
    ('ask' | 'a') singleDobj 'about' topicIobj
    : VerbProduction
    action = AskAbout
    verbPhrase = 'ask/asking (whom) (about what)'
    missingQ = 'whom do you want to ask;what do you want to ask it about'
    dobjReply = singleNoun
    iobjReply = aboutTopicPhrase
;

VerbRule(AskAboutImplicit)
    ('a' | ('ask' | 'tell' 'me') 'about') topicIobj
    : VerbProduction
    action = AskAboutImplicit
    verbPhrase = 'ask/asking (whom) (about what)'
    missingQ = 'whom do you want to ask;what do you want to ask it about'
    iobjReply = topicPhrase
    priority = 60
;

VerbRule(AskAboutWhat)
    [badness 500] 'ask' singleDobj
    : VerbProduction
    action = AskAbout
    verbPhrase = 'ask/asking (whom) (about what)'
    missingQ = 'whom do you want to ask;what do you want to ask it about'

    missingRole = IndirectObject
    iobjReply = aboutTopicPhrase

    priority = 25
;


VerbRule(TellAbout)
    ('tell' | 't') singleDobj 'about' topicIobj
    : VerbProduction
    action = TellAbout
    verbPhrase = 'tell/telling (whom) (about what)'
    missingQ = 'whom do you want to tell;what do you want to tell it about'
    dobjReply = singleNoun
    iobjReply = aboutTopicPhrase
;

VerbRule(TellAboutImplicit)
    't' topicIobj
    : VerbProduction
    action = TellAboutImplicit
    verbPhrase = 'tell/telling (whom) (about what)'
    missingQ = 'whom do you want to tell;what do you want to tell it about'
    iobjReply = topicPhrase
;

VerbRule(TellAboutWhat)
    [badness 500] 'tell' singleDobj
    : VerbProduction
    action = TellAbout
    verbPhrase = 'tell/telling (whom) (about what)'
    missingQ = 'whom do you want to tell;what do you want to tell it about'

    missingRole = IndirectObject
    dobjReply = singleNoun
    iobjReply = aboutTopicPhrase

    priority = 25
;

VerbRule(TellTo)
    'tell' singleDobj 'to' literalIobj
    : VerbProduction
    action = TellTo
    verbPhrase = 'tell/telling (whom) (to what)'
    missingQ = 'whom do you want to tell;what do you want to tell it to do'
    iobjReply = literalPhrase
;

VerbRule(TalkAbout)
    'talk' 'to' singleDobj 'about' topicIobj
    : VerbProduction
    action = TalkAbout
    verbPhrase = 'talk/talking (to whom) (about what)'
    missingQ = 'to whom do you want to talk;what do you want to talk to it about'
    dobjReply = toSingleNoun
    iobjReply = aboutTopicPhrase
;

VerbRule(TalkAboutImplicit)
    'talk' 'about' topicIobj
    : VerbProduction
    action = TalkAboutImplicit
    verbPhrase = 'talk/talking (about what)'
    missingQ = 'what do you want to talk about'
    iobjReply = topicPhrase
;

VerbRule(AskVague)
    [badness 500] 'ask' singleDobj topicIobj
    : VerbProduction
    action = AskAbout
    verbPhrase = 'ask/asking (whom)'
    missingQ = 'whom do you want to ask;what do you want to ask it about'
;

VerbRule(TellVague)
    [badness 500] 'tell' singleDobj topicIobj
    : VerbProduction
    action = TellAbout
    verbPhrase = 'tell/telling (whom)'
    missingQ = 'whom do you want to tell;what do you want to tell it about'
;

VerbRule(TalkTo)
    ('greet' | 'say' 'hello' 'to' | 'talk' 'to') singleDobj
    : VerbProduction
    action = TalkTo
    verbPhrase = 'talk/talking (to whom)'
    missingQ = 'whom do you want to talk to'
    dobjReply = singleNoun
;
//
//VerbRule(TalkToWhat)
//    [badness 500] 'talk'
//    : VerbProduction
//    action = TalkTo
//    verbPhrase = 'talk/talking (to whom)'
//    missingQ = 'whom do you want to talk to'
//
//    missingRole = DirectObject
//    dobjReply = toSingleNoun
//;

VerbRule(Topics)
    'topics'
    : VerbProduction
    action = Topics
    verbPhrase = 'show/showing topics'
;

VerbRule(Hello)
    ('say' | ) ('hello' | 'hallo' | 'hi')
    : VerbProduction
    action = Hello
    verbPhrase = 'say/saying hello'
     /* Give this priority over SAY TOPIC */
    priority = 60
;

VerbRule(Goodbye)
    ('say' | ()) ('goodbye' | 'good-bye' | 'good' 'bye' | 'bye')
    : VerbProduction
    action = Goodbye
    verbPhrase = 'say/saying goodbye'
;

VerbRule(Yes)
    'yes' | 'affirmative' | 'say' 'yes'
    : VerbProduction
    action = SayYes
    verbPhrase = 'say/saying yes'
    /* Give this priority over SAY TOPIC */
    priority = 60
;

VerbRule(No)
    'no' | 'negative' | 'say' 'no'
    : VerbProduction
    action = SayNo
    verbPhrase = 'say/saying no'
    /* Give this priority over SAY TOPIC */
    priority = 60
;

VerbRule(Yell)
    'yell' | 'scream' | 'shout' | 'holler'
    : VerbProduction
    action = Yell
    verbPhrase = 'yell/yelling'
;

VerbRule(GiveTo)
    ('give' | 'offer') multiDobj 'to' singleIobj
    : VerbProduction
    action = GiveTo
    verbPhrase = 'give/giving (what) (to whom)'
    missingQ = 'what do you want to give (to it);whom do you want to give it to'
    iobjReply = toSingleNoun
;

VerbRule(GiveToType2)
    ('give' | 'offer') singleIobj multiDobj
    : VerbProduction
    action = GiveTo
    verbPhrase = 'give/giving (what) (to whom)'
    missingQ = 'what do you want to give (to it);whom do you want to give it to'
    iobjReply = toSingleNoun

    /* this is a non-prepositional phrasing */
    isPrepositionalPhrasing = nil
;

VerbRule(GiveToImplicit)
    ('give' | 'offer') multiDobj
    : VerbProduction
    action = GiveToImplicit
    verbPhrase = 'give/giving (what) (to whom)'
    missingQ = 'what do you want to give (to it);whom do you want to give it to'

    priority = 25
;

VerbRule(ShowTo)
    'show' multiDobj 'to' singleIobj
    : VerbProduction
    action = ShowTo
    verbPhrase = 'show/showing (what) (to whom)'
    missingQ = 'what do you want to show (to it);whom do you want to show it to'
    iobjReply = toSingleNoun
;

VerbRule(ShowToType2)
    'show' singleIobj multiDobj
    : VerbProduction
    action = ShowTo
    verbPhrase = 'show/showing (what) (to whom)'
    missingQ = 'what do you want to show (to it);whom do you want to show it to'
    iobjReply = toSingleNoun

    /* this is a non-prepositional phrasing */
    isPrepositionalPhrasing = nil
;

VerbRule(ShowToImplicit)
    'show' multiDobj
    : VerbProduction
    action = ShowToImplicit
    verbPhrase = 'show/showing (what) (to whom)'
    missingQ = 'what do you want to show (to it);whom do you want to show it to'

    priority = 25
;


VerbRule(Say)
    'say' ('that' |) topicDobj
    : VerbProduction
    action = SayAction
    verbPhrase = 'say/saying (what)'
    missingQ = 'what do you want to say'
;

VerbRule(SayTo)
    'say' ('that' |) topicIobj 'to' singleDobj
    : VerbProduction
    action = SayTo
    verbPhrase = 'say/saying (what) (to whom)'
    missingQ = 'what do you want to say it to; what do you want to say'
;

VerbRule(TellThat)
    'tell' singleDobj 'that' topicIobj
    : VerbProduction
    action = SayTo
    verbPhrase = 'say/saying (what) (to whom)'
    missingQ = 'what do you want to say it to; what do you want to say'
;
    
VerbRule(Think)
    'think' | 'ponder' | 'cogitate'
    : VerbProduction
    action = Think
    verbPhrase = 'think/thinking'
;

VerbRule(ThinkAbout)
    ('think' | 'ponder' | 'cogitate') 'about' topicDobj
    : VerbProduction
    action = ThinkAbout
    verbPhrase = 'think/thinking (about what)'
    missingQ = 'what do you want to think about'
;
    

VerbRule(Throw)
    ('throw' | 'toss') multiDobj
    : VerbProduction
    action = Throw
    verbPhrase = 'throw/throwing (what)'
    missingQ = 'what do you want to throw'
;

VerbRule(ThrowAt)
    ('throw' | 'toss') multiDobj 'at' singleIobj
    : VerbProduction
    action = ThrowAt
    verbPhrase = 'throw/throwing (what) (at what)'
    missingQ = 'what do you want to throw (at it);what do you want to throw it at'
    iobjReply = atSingleNoun
;

VerbRule(ThrowTo)
    ('throw' | 'toss') multiDobj 'to' singleIobj
    : VerbProduction
    action = ThrowTo
    verbPhrase = 'throw/throwing (what) (to whom)'
    missingQ = 'what do you want to throw (to it);whom do you want to throw to it'
    iobjReply = toSingleNoun
;

VerbRule(ThrowToType2)
    'throw' singleIobj multiDobj
    : VerbProduction
    action = ThrowTo
    verbPhrase = 'throw/throwing (what) (to whom)'
    missingQ = 'what do you want to throw (to it);whom do you want to throw it to'
    iobjReply = toSingleNoun

    /* this is a non-prepositional phrasing */
    isPrepositionalPhrasing = nil
;

VerbRule(ThrowDir)
    ('throw' | 'toss') multiDobj ('to' ('the' | ) | ) singleDir
    : VerbProduction
    action = ThrowDir

    verbPhrase = 'throw/throwing (what)'
    missingQ = 'what do you want to throw'
;

/* a special rule for THROW DOWN <dobj> */
VerbRule(ThrowDirDown)
    'throw' ('down' | 'd') multiDobj
    : VerbProduction
    action = ThrowDir
    verbPhrase = ('throw/throwing (what) down')
    missingQ = 'what do you want to throw down'
;

VerbRule(Follow)
    'follow' singleDobj
    : VerbProduction
    action = Follow
    verbPhrase = 'follow/following (whom)'
    missingQ = 'whom do you want to follow'
    dobjReply = singleNoun
;

VerbRule(Attack)
    ('attack' | 'kill' | 'hit' | 'kick' | 'punch') singleDobj
    : VerbProduction
    action = Attack
    verbPhrase = 'attack/attacking (whom)'
    missingQ = 'whom do you want to attack'
    dobjReply = singleNoun
;

VerbRule(AttackWith)
    ('attack' | 'kill' | 'hit' | 'kick' | 'punch' | 'strike')
        singleDobj
        'with' singleIobj
    : VerbProduction
    action = AttackWith
    verbPhrase = 'attack/attacking (whom) (with what)'
    missingQ = 'whom do you want to attack;what do you want to attack it with'
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

VerbRule(Inventory)
    'i' | 'inventory' | 'take' 'inventory'
    : VerbProduction
    action = Inventory
    verbPhrase = 'take/taking inventory'
;
//
//VerbRule(InventoryTall)
//    'i' 'tall' | 'inventory' 'tall'
//    : VerbProduction
//    action = InventoryTall
//    verbPhrase = 'take/taking "tall" inventory'
//;
//
//VerbRule(InventoryWide)
//    'i' 'wide' | 'inventory' 'wide'
//    : VerbProduction
//    action = InventoryWide
//    verbPhrase = 'take/taking "wide" inventory'
//;
//
VerbRule(Wait)
    'z' | 'wait'
    : VerbProduction
    action = Wait
    verbPhrase = 'wait/waiting'
;

VerbRule(Look)
    'look' | 'look' 'around' | 'l' | 'l' 'around'
    : VerbProduction
    action = Look
    verbPhrase = 'look/looking around'
;

VerbRule(Quit)
    'quit' | 'q'
    : VerbProduction
    action = Quit
    verbPhrase = 'quit/quitting'
;

VerbRule(Again)
    'again' | 'g'
    : VerbProduction
    action = Again
    verbPhrase = 'repeat/repeating the last command'
;

//VerbRule(Footnote)
//    ('footnote' | 'note') numberDobj
//    : VerbProduction
//    action = Footnote
//    verbPhrase = 'show/showing a footnote'
//;
//
//VerbRule(FootnotesFull)
//    'footnotes' 'full'
//    : VerbProduction
//    action = FootnotesFull
//    verbPhrase = 'enable/enabling all footnotes'
//;
//
//VerbRule(FootnotesMedium)
//    'footnotes' 'medium'
//    : VerbProduction
//    action = FootnotesMedium
//    verbPhrase = 'enable/enabling new footnotes'
//;
//
//VerbRule(FootnotesOff)
//    'footnotes' 'off'
//    : VerbProduction
//    action = FootnotesOff
//    verbPhrase = 'hide/hiding footnotes'
//;
//
//VerbRule(FootnotesStatus)
//    'footnotes'
//    : VerbProduction
//    action = FootnotesStatus
//    verbPhrase = 'show/showing footnote status'
//;
//
//VerbRule(TipsOn)
//    ('tips' | 'tip') 'on'
//    : VerbProduction
//    action = TipsOn
//
//    stat_ = true
//
//    verbPhrase = 'turn/turning tips on'
//;
//
//VerbRule(TipsOff)
//    ('tips' | 'tip') 'off'
//    : VerbProduction
//    action = TipsOff
//
//    stat_ = nil
//
//    verbPhrase = 'turn/turning tips off'
//;
//
//VerbRule(Verbose)
//    'verbose'
//    : VerbProduction
//    action = Verbose
//    verbPhrase = 'enter/entering VERBOSE mode'
//;
//
//VerbRule(Terse)
//    'terse' | 'brief'
//    : VerbProduction
//    action = Terse
//    verbPhrase = 'enter/entering BRIEF mode'
//;
//
VerbRule(Score)
    'score' | 'status'
    : VerbProduction
    action = Score
    verbPhrase = 'show/showing score'
;

VerbRule(FullScore)
    'full' 'score' | 'fullscore' | 'full'
    : VerbProduction
    action = FullScore
    verbPhrase = 'show/showing full score'
;

VerbRule(Notify)
    'notify'
    : VerbProduction
    action = Notify
    verbPhrase = 'show/showing notification status'
;

VerbRule(NotifyOn)
    'notify' 'on'
    : VerbProduction
    action = NotifyOn
    verbPhrase = 'turn/turning on score notification'
;

VerbRule(NotifyOff)
    'notify' 'off'
    : VerbProduction
    action = NotifyOff
    verbPhrase = 'turn/turning off score notification'
;

VerbRule(Save)
    'save'
    : VerbProduction
    action = Save
    verbPhrase = 'save/saving'
;

VerbRule(SaveString)
    'save' quotedStringPhrase->fname_
    : VerbProduction
    action = Save
    verbPhrase = 'save/saving'
;

VerbRule(Restore)
    'restore'
    : VerbProduction
    action = Restore
    verbPhrase = 'restore/restoring'
;

VerbRule(RestoreString)
    'restore' quotedStringPhrase->fname_
    : VerbProduction
    action = Restore
    verbPhrase = 'restore/restoring'
;

//VerbRule(SaveDefaults)
//    'save' 'defaults'
//    : VerbProduction
//    action = SaveDefaults
//    verbPhrase = 'save/saving defaults'
//;
//
//VerbRule(RestoreDefaults)
//    'restore' 'defaults'
//    : VerbProduction
//    action = RestoreDefaults
//    verbPhrase = 'restore/restoring defaults'
//;

VerbRule(Restart)
    'restart'
    : VerbProduction
    action = Restart
    verbPhrase = 'restart/restarting'
;

VerbRule(Undo)
    'undo'
    : VerbProduction
    action = Undo
    verbPhrase = 'undo/undoing'
;

VerbRule(Version)
    'version'
    : VerbProduction
    action = Version
    verbPhrase = 'show/showing version'
;

VerbRule(Credits)
    'credits'
    : VerbProduction
    action = Credits
    verbPhrase = 'show/showing credits'
;

VerbRule(About)
    'about'
    : VerbProduction
    action = About
    verbPhrase = 'show/showing story information'
;

VerbRule(ScriptOn)
    'script' | 'script' 'on'
    : VerbProduction
    action = ScriptOn
    verbPhrase = 'start/starting scripting'
;

VerbRule(ScriptString)
    'script' quotedStringPhrase->fname_
    : VerbProduction
    action = ScriptOn
    verbPhrase = 'start/starting scripting'
;

VerbRule(ScriptOff)
    'script' 'off' | 'unscript'
    : VerbProduction
    action = ScriptOff
    verbPhrase = 'end/ending scripting'
;

VerbRule(Record)
    'record' | 'record' 'on'
    : VerbProduction
    action = Record
    verbPhrase = 'start/starting command recording'
;

VerbRule(RecordString)
    'record' quotedStringPhrase->fname_
    : VerbProduction
    action = Record
    verbPhrase = 'start/starting command recording'
;

VerbRule(RecordEvents)
    'record' 'events' | 'record' 'events' 'on'
    : VerbProduction
    action = RecordEvents
    verbPhrase = 'start/starting event recording'
;

VerbRule(RecordEventsString)
    'record' 'events' quotedStringPhrase->fname_
    : VerbProduction
    action = RecordEvents
    verbPhrase = 'start/starting command recording'
;

VerbRule(RecordOff)
    'record' 'off'
    : VerbProduction
    action = RecordOff
    verbPhrase = 'end/ending command recording'
;

VerbRule(ReplayString)
    'replay' ('quiet'->quiet_ | 'nonstop'->nonstop_ | )
        (quotedStringPhrase->fname_ | )
    : VerbProduction
    action = Replay
    verbPhrase = 'replay/replaying command recording'

    /* set the appropriate option flags */
    scriptOptionFlags = ((quiet_ != nil ? ScriptFileQuiet : 0)
                         | (nonstop_ != nil ? ScriptFileNonstop : 0))
;
VerbRule(ReplayQuiet)
    'rq' (quotedStringPhrase->fname_ | )
    : VerbProduction
    action = Replay

    scriptOptionFlags = ScriptFileQuiet
;

VerbRule(GoTo)
    ('go' 'to' | 'walk' 'to')
    singleDobj
    : VerbProduction
    action = GoTo
    verbPhrase = 'go/going to (what)'
    missingQ = 'where do you want to go'
    dobjReply = toSingleNoun
;

VerbRule(Continue)
    'continue' | 'c'
    : VerbProduction
    action = Continue
    verbPhrase = 'continue/continuing journey'
;

VerbRule(VagueTravel) 'go' | 'walk' : VerbProduction
    action = VagueTravel
    verbPhrase = 'go/going'

    priority = 25
;

VerbRule(Travel)
    'go' singleDir | singleDir
    : VerbProduction
    action = Travel
    verbPhrase = 'go/going {where)'
;

/*
 *   Create a TravelVia subclass merely so we can supply a verbPhrase.
 *   (The parser looks for subclasses of each specific Action class to find
 *   its verb phrase, since the language-specific Action definitions are
 *   always in the language module's 'grammar' subclasses.  We don't need
 *   an actual grammar rule, since this isn't an input-able verb, so we
 *   merely need to create a regular subclass in order for the verbPhrase
 *   to get found.)  
 */
class EnTravelVia: VerbProduction
    verbPhrase = 'use/using (what)'
    missingQ = 'what do you want to use'
;

VerbRule(In)
    'enter'
    : VerbProduction
    action = GoIn
    verbPhrase = 'enter/entering'
;

VerbRule(Out)
    'exit' | 'leave'
    : VerbProduction
    action = GoOut
    verbPhrase = 'exit/exiting'
;

VerbRule(GoThrough)
    ('walk' | 'go' ) ('through' | 'thru')
        singleDobj
    : VerbProduction
    action = GoThrough
    verbPhrase = 'go/going (through what)'
    missingQ = 'what do you want to go through'
    dobjReply = singleNoun
;


VerbRule(GoBack)
    'back' | 'go' 'back' | 'return'
    : VerbProduction
    action = GoBack
    verbPhrase = 'go/going back'
;

VerbRule(Dig)
    ('dig' | 'dig' 'in') singleDobj
    : VerbProduction
    action = Dig
    verbPhrase = 'dig/digging (in what)'
    missingQ = 'what do you want to dig in'
    dobjReply = inSingleNoun
;

VerbRule(DigWith)
    ('dig' | 'dig' 'in') singleDobj 'with' singleIobj
    : VerbProduction
    action = DigWith
    verbPhrase = 'dig/digging (in what) (with what)'
    missingQ = 'what do you want to dig in;what do you want to dig with'
    dobjReply = inSingleNoun
    iobjReply = withSingleNoun
;

VerbRule(Jump)
    'jump'
    : VerbProduction
    action = Jump
    verbPhrase = 'jump/jumping'
;

VerbRule(JumpOffIntransitive)
    'jump' 'off'
    : VerbProduction
    action = JumpOffIntransitive
    verbPhrase = 'jump/jumping off'
;

VerbRule(JumpOff)
    'jump' 'off' singleDobj
    : VerbProduction
    action = JumpOff
    verbPhrase = 'jump/jumping (off what)'
    missingQ = 'what do you want to jump off'
    dobjReply = singleNoun
;

VerbRule(JumpOver)
    ('jump' | 'jump' 'over') singleDobj
    : VerbProduction
    action = JumpOver
    verbPhrase = 'jump/jumping (over what)'
    missingQ = 'what do you want to jump over'
    dobjReply = singleNoun
;

VerbRule(Push)
    ('push' | 'press') multiDobj
    : VerbProduction
    action = Push
    verbPhrase = 'push/pushing (what)'
    missingQ = 'what do you want to push'
;

VerbRule(Pull)
    'pull' multiDobj
    : VerbProduction
    action = Pull
    verbPhrase = 'pull/pulling (what)'
    missingQ = 'what do you want to pull'
;

VerbRule(Move)
    'move' multiDobj
    : VerbProduction
    action = Move
    verbPhrase = 'move/moving (what)'
    missingQ = 'what do you want to move'
;

VerbRule(MoveTo)
    ('push' | 'move') multiDobj ('to' | 'under') singleIobj
    : VerbProduction
    action = MoveTo
    verbPhrase = 'move/moving (what) (to what)'
    missingQ = 'what do you want to move;where do you want to move it'
    iobjReply = toSingleNoun
;

VerbRule(MoveWith)
    'move' singleDobj 'with' singleIobj
    : VerbProduction
    action = MoveWith
    verbPhrase = 'move/moving (what) (with what)'
    missingQ = 'what do you want to move;what do you want to move it with'
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

VerbRule(Turn)
    ('turn' | 'twist' | 'rotate') multiDobj
    : VerbProduction
    action = Turn
    verbPhrase = 'turn/turning (what)'
    missingQ = 'what do you want to turn'
;

VerbRule(TurnWith)
    ('turn' | 'twist' | 'rotate') singleDobj 'with' singleIobj
    : VerbProduction
    action = TurnWith
    verbPhrase = 'turn/turning (what) (with what)'
    missingQ = 'what do you want to turn;what do you want to turn it with'
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

VerbRule(TurnTo)
    ('turn' | 'twist' | 'rotate') singleDobj
        'to' literalIobj
    : VerbProduction
    action = TurnTo
    verbPhrase = 'turn/turning (what) (to what)'
    missingQ = 'what do you want to turn;what do you want to turn it to'
    dobjReply = singleNoun
;

VerbRule(Set)
    'set' multiDobj
    : VerbProduction
    action = Set
    verbPhrase = 'set/setting (what)'
    missingQ = 'what do you want to set'
;

VerbRule(SetTo)
    'set' singleDobj 'to' literalIobj
    : VerbProduction
    action = SetTo
    verbPhrase = 'set/setting (what) (to what)'
    missingQ = 'what do you want to set;what do you want to set it to'
    dobjReply = singleNoun
;

VerbRule(TypeOn)
    'type' 'on' singleDobj
    : VerbProduction
    action = TypeOnVague
    verbPhrase = 'type/typing (on what)'
    missingQ = 'what do you want to type on'
;

VerbRule(TypeLiteralOn)
    'type' literalDobj 'on' singleIobj
    : VerbProduction
    action = TypeOn
    verbPhrase = 'type/typing (what) (on what)'
    missingQ = 'what do you want to type;what do you want to type that on'
    dobjReply = singleNoun
;

VerbRule(TypeLiteralOnWhat)
    [badness 500] 'type' literalDobj
    : VerbProduction
    action = TypeOn
    verbPhrase = 'type/typing (what) (on what)'
    missingQ = 'what do you want to type;what do you want to type that on'

    missingRole = IndirectObject
    iobjReply = onSingleNoun
;

VerbRule(EnterOn)
    'enter' literalDobj
        ('on' | 'in' | 'in' 'to' | 'into' | 'with') singleIobj
    : VerbProduction
    action = EnterOn
    verbPhrase = 'enter/entering (what) (on what)'
    missingQ = 'what do you want to enter;what do you want to enter that on'
    dobjReply = singleNoun
;
//
//VerbRule(EnterOnWhat)
//    [badness 500] 'enter' literalDobj
//    : VerbProduction
//    action = EnterOn
//    verbPhrase = 'enter/entering (what) (on what)'
//    missingQ = 'what do you want to enter;what do you want to enter that on'
//
//    missingRole = DirectObject
//    dobjReply = singleNoun
//
//    priority = 25
//;

VerbRule(WriteOn)
    'write' literalDobj ('on' | 'in') singleIobj
    : VerbProduction
    action = WriteOn
    verbPhrase = 'write/writing (what) (on what)'
    missingQ = 'what do you want to write;what do you want to write that on'
    dobjReply = singleNoun
;

VerbRule(WriteOnWhat)
    'write' literalDobj
    : VerbProduction
    action = WriteOn
    verbPhrase = 'write/writing (what) (on what)'
    missingQ = 'what do you want to write;what do you want to write that on'

    missingRole = IndirectObject
    iobjReply = onSingleNoun
    
    priority = 25
;

//VerbRule(Consult)
//    'consult' singleDobj : VerbProduction
//    action = Consult
//    verbPhrase = 'consult/consulting (what)'
//    missingQ = 'what do you want to consult'
//    dobjReply = singleNoun
//;

VerbRule(ConsultAbout)
    'consult' singleDobj ('on' | 'about') topicIobj
    | 'search' singleDobj 'for' topicIobj
    : VerbProduction
    action = ConsultAbout
    verbPhrase = 'consult/consulting (what) (about what)'
    missingQ = 'what do you want to consult;what do you want to consult it about'
    dobjReply = singleNoun
;

VerbRule(LookUp)
    (('look' | 'l') ('up' | 'for') | 'find'  | 'search' 'for' | 'read' 'about')
    topicIobj ('in' | 'on') singleDobj
    | ('look' | 'l') topicIobj 'up' ('in' | 'on') singleDobj
    : VerbProduction
    action = ConsultAbout
    verbPhrase = 'look/looking up (what) (in what)'
    missingQ = 'what do you want to look that up in;what do you want to look up'
    dobjReply = singleNoun
;

VerbRule(ConsultWhatAbout)
    (('look' | 'l') ('up' | 'for')
     | 'find'
     | 'search' 'for'
     | 'read' 'about')
    topicIobj
    | ('look' | 'l') topicIobj 'up'
    : VerbProduction
    action = ConsultAbout
    verbPhrase = 'look/looking up (what) (in what)'
    missingQ = 'what do you want to look that up in;what do you want to look up'

    missingRole = DirectObject
    dobjReply = inSingleNoun

    priority = 25
;

VerbRule(Switch)
    'switch' multiDobj
    : VerbProduction
    action = SwitchVague
    verbPhrase = 'switch/switching (what)'
    missingQ = 'what do you want to switch'
;

VerbRule(Flip)
    'flip' multiDobj
    : VerbProduction
    action = Flip
    verbPhrase = 'flip/flipping (what)'
    missingQ = 'what do you want to flip'
;

VerbRule(SwitchOn)
    ('activate' | ('turn' | 'switch') 'on') multiDobj
    | ('turn' | 'switch') multiDobj 'on'
    : VerbProduction
    action = SwitchOn
    verbPhrase = 'turn/turning on (what)'
    missingQ = 'what do you want to turn on'
;

VerbRule(SwitchOff)
    ('deactivate' | ('turn' | 'switch') 'off') multiDobj
    | ('turn' | 'switch') multiDobj 'off'
    : VerbProduction
    action = SwitchOff
    verbPhrase = 'turn/turning off (what)'
    missingQ = 'what do you want to turn off'
;

VerbRule(Light)
    'light' multiDobj
    : VerbProduction
    action = Light
    verbPhrase = 'light/lighting (what)'
    missingQ = 'what do you want to light'
;

VerbRule(Strike)
    'strike' multiDobj
    : VerbProduction
    action = Strike
    verbPhrase = 'strike/striking (what)'
    missingQ = 'what do you want to strike'
;

VerbRule(Burn)
    ('burn' | 'ignite' | 'set' 'fire' 'to') multiDobj
    : VerbProduction
    action = Burn
    verbPhrase = 'burn/burning (what)'
    missingQ = 'what do you want to burn'
;

VerbRule(BurnWith)
    ('light' | 'burn' | 'ignite' | 'set' 'fire' 'to') singleDobj
        'with' singleIobj
    : VerbProduction
    action = Burn
    verbPhrase = 'burn/burning (what) (with what)'
    missingQ = 'what do you want to burn;what do you want to burn it with'
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

VerbRule(Extinguish)
    ('extinguish' | 'douse' | 'put' 'out' | 'blow' 'out') multiDobj
    | ('blow' | 'put') multiDobj 'out'
    : VerbProduction
    action = Extinguish
    verbPhrase = 'extinguish/extinguishing (what)'
    missingQ = 'what do you want to extinguish'
;

VerbRule(Break)
    ('break' | 'ruin' | 'destroy' | 'wreck' | 'smash') multiDobj
    : VerbProduction
    action = Break
    verbPhrase = 'break/breaking (what)'
    missingQ = 'what do you want to break'
;

VerbRule(CutWithWhat)
    [badness 500] 'cut' singleDobj
    : VerbProduction
    action = CutWith
    verbPhrase = 'cut/cutting (what) (with what)'
    missingQ = 'what do you want to cut;what do you want to cut it with'

    missingRole = IndirectObject
    iobjReply = withSingleNoun
;

VerbRule(CutWith)
    'cut' singleDobj 'with' singleIobj
    : VerbProduction
    action = CutWith
    verbPhrase = 'cut/cutting (what) (with what)'
    missingQ = 'what do you want to cut;what do you want to cut it with'
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

VerbRule(Eat)
    ('eat' | 'consume') multiDobj
    : VerbProduction
    action = Eat
    verbPhrase = 'eat/eating (what)'
    missingQ = 'what do you want to eat'
;

VerbRule(Drink)
    ('drink' | 'quaff' | 'imbibe') multiDobj
    : VerbProduction
    action = Drink
    verbPhrase = 'drink/drinking (what)'
    missingQ = 'what do you want to drink'
;

VerbRule(Pour)
    'pour' multiDobj
    : VerbProduction
    action = Pour
    verbPhrase = 'pour/pouring (what)'
    missingQ = 'what do you want to pour'
;

VerbRule(PourInto)
    'pour' multiDobj ('in' | 'into' | 'in' 'to') singleIobj
    : VerbProduction
    action = PourInto
    verbPhrase = 'pour/pouring (what) (into what)'
    missingQ = 'what do you want to pour;what do you want to pour it into'
    iobjReply = inSingleNoun
;

VerbRule(PourOnto)
    'pour' multiDobj ('on' | 'onto' | 'on' 'to') singleIobj
    : VerbProduction
    action = PourOnto
    verbPhrase = 'pour/pouring (what) (onto what)'
    missingQ = 'what do you want to pour;what do you want to pour it onto'
    iobjReply = onSingleNoun
;

VerbRule(Climb)
    'climb' singleDobj
    : VerbProduction
    action = Climb
    verbPhrase = 'climb/climbing (what)'
    missingQ = 'what do you want to climb'
    dobjReply = singleNoun
;

VerbRule(ClimbUp)
    ('climb' | 'go' | 'walk') 'up' singleDobj
    : VerbProduction
    action = ClimbUp
    verbPhrase = 'climb/climbing (up what)'
    missingQ = 'what do you want to climb up'
    dobjReply = singleNoun
;

VerbRule(ClimbUpWhat)
    [badness 200] ('climb' | 'go' | 'walk') 'up'
    : VerbProduction
    action = ClimbUp
    verbPhrase = 'climb/climbing (up what)'
    missingQ = 'what do you want to climb up'
    missingRole = DirectObject
    dobjReply = singleNoun
;

VerbRule(ClimbDown)
    ('climb' | 'go' | 'walk') 'down' singleDobj
    : VerbProduction
    action = ClimbDown
    verbPhrase = 'climb/climbing (down what)'
    missingQ = 'what do you want to climb down'
    dobjReply = singleNoun
;

VerbRule(ClimbDownWhat)
    [badness 200] ('climb' | 'go' | 'walk') 'down'
    : VerbProduction
    action = ClimbDown
    verbPhrase = 'climb/climbing (down what)'
    missingQ = 'what do you want to climb down'
    missingRole = DirectObject
    dobjReply = singleNoun
;

VerbRule(Clean)
    'clean' multiDobj
    : VerbProduction
    action = Clean
    verbPhrase = 'clean/cleaning (what)'
    missingQ = 'what do you want to clean'
;

VerbRule(CleanWith)
    'clean' singleDobj 'with' singleIobj
    : VerbProduction
    action = Clean
    verbPhrase = 'clean/cleaning (what) (with what)'
    missingQ = 'what do you want to clean (with it);'
              + 'what do you want to clean it with'
    iobjReply = withSingleNoun
;

VerbRule(AttachTo)
    ('attach' | 'connect') multiDobj 'to' singleIobj
    : VerbProduction
    action = AttachTo
    iobjReply = toSingleNoun
    verbPhrase = 'attach/attaching (what) (to what)'
    missingQ = 'what do you want to attach (to it);'
               + 'what do you want to attach it to'
;

VerbRule(AttachToWhat)
    [badness 500] ('attach' | 'connect') multiDobj
    : VerbProduction
    action = AttachTo
    verbPhrase = 'attach/attaching (what) (to what)'
    missingQ = 'what do you want to attach (to it);'
               + 'what do you want to attach it to'

    missingRole = IndirectObject
    iobjReply = toSingleNoun
;

VerbRule(DetachFrom)
    ('detach' | 'disconnect') multiDobj 'from' singleIobj
    : VerbProduction
    action = DetachFrom
    verbPhrase = 'detach/detaching (what) (from what)'
    missingQ = 'what do you want to detach (from it);'
              + 'what do you want to detach it from'
    iobjReply = fromSingleNoun
;

VerbRule(Detach)
    ('detach' | 'disconnect') multiDobj
    : VerbProduction
    action = Detach
    verbPhrase = 'detach/detaching (what)'
    missingQ = 'what do you want to detach'
;

VerbRule(Open)
    'open' multiDobj
    : VerbProduction
    action = Open
    verbPhrase = 'open/opening (what)'
    missingQ = 'what do you want to open'
;

VerbRule(Close)
    ('close' | 'shut') multiDobj
    : VerbProduction
    action = Close
    verbPhrase = 'close/closing (what)'
    missingQ = 'what do you want to close'
;

VerbRule(Lock)
    'lock' multiDobj
    : VerbProduction
    action = Lock
    verbPhrase = 'lock/locking (what)'
    missingQ = 'what do you want to lock'
;

VerbRule(Unlock)
    'unlock' multiDobj
    : VerbProduction
    action = Unlock
    verbPhrase = 'unlock/unlocking (what)'
    missingQ = 'what do you want to unlock'
;

VerbRule(LockWith)
    'lock' singleDobj 'with' singleIobj
    : VerbProduction
    action = LockWith
    verbPhrase = 'lock/locking (what) (with what)'
    missingQ = 'what do you want to lock;what do you want to lock it with'
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

VerbRule(UnlockWith)
    'unlock' singleDobj 'with' singleIobj
    : VerbProduction
    action = UnlockWith
    verbPhrase = 'unlock/unlocking (what) (with what)'
    missingQ = 'what do you want to unlock;what do you want to unlock it with'
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

VerbRule(SitOn)
    'sit' ('on' | 'down' 'on' )
        singleDobj
    : VerbProduction
    action = SitOn
    verbPhrase = 'sit/sitting (on what)'
    missingQ = 'what do you want to sit on'
    dobjReply = singleNoun
;

VerbRule(SitIn)
    'sit' ('in' | 'down' 'in')
        singleDobj
    : VerbProduction
    action = SitIn
    verbPhrase = 'sit/sitting (on what)'
    missingQ = 'what do you want to sit on'
    dobjReply = singleNoun
;

VerbRule(Sit)
    'sit' ( | 'down') : VerbProduction
    action = Sit
    verbPhrase = 'sit/sitting down'
;

VerbRule(LieOn)
    'lie' ('on' | 'down' 'on' )
        singleDobj
    : VerbProduction
    action = LieOn
    verbPhrase = 'lie/lying (on what)'
    missingQ = 'what do you want to lie on'
    dobjReply = singleNoun
;

VerbRule(LieIn)
    'lie' ('in' | 'down' 'in')
        singleDobj
    : VerbProduction
    action = LieIn
    verbPhrase = 'lie/lying (on what)'
    missingQ = 'what do you want to lie on'
    dobjReply = singleNoun
;

//
//VerbRule(Lie)
//    'lie' ( | 'down') : VerbProduction
//    action = Lie
//    verbPhrase = 'lie/lying down'
//;
//
VerbRule(StandOn)
    ('stand' ('on' | 'onto' | 'on' 'to' )
     | 'climb' ('on' | 'onto' | 'on' 'to'))
    singleDobj
    : VerbProduction
    action = StandOn
    verbPhrase = 'stand/standing (on what)'
    missingQ = 'what do you want to stand on'
    dobjReply = singleNoun
;

VerbRule(StandIn)
    ('stand' ('in' | 'into' | 'in' 'to')
     | 'climb' ('in' | 'into' | 'in' 'to'))
    singleDobj
    : VerbProduction
    action = StandIn
    verbPhrase = 'stand/standing (on what)'
    missingQ = 'what do you want to stand on'
    dobjReply = singleNoun
;

VerbRule(Stand)
    'stand' | 'stand' 'up' | 'get' 'up'
    : VerbProduction
    action = Stand
    verbPhrase = 'stand/standing up'
;

VerbRule(GetOutOf)
    ('out' 'of' | 'get' 'out' 'of' | 'climb' 'out' 'of' | 'leave' | 'exit')
    singleDobj
    : VerbProduction
    action = GetOutOf
    verbPhrase = 'get/getting (out of what)'
    missingQ = 'what do you want to get out of'
    dobjReply = singleNoun
;

VerbRule(GetOff)
    'get' ('off' | 'off' 'of' | 'down' 'from') singleDobj
    : VerbProduction
    action = GetOff
    verbPhrase = 'get/getting (off of what)'
    missingQ = 'what do you want to get off of'
    dobjReply = singleNoun
;

VerbRule(GetOut)
    'get' 'out'
    | 'get' 'off'
    | 'get' 'down'
    | 'get' 'up'
    | 'disembark'
    | 'climb' 'out'
    : VerbProduction
    action = GetOut
    verbPhrase = 'get/getting out'
    priority = 60
;

VerbRule(Board)
    ('board'
     | ('get' ('on' | 'onto' | 'on' 'to'))
     | ('climb' ('on' | 'onto' | 'on' 'to')))
    singleDobj
    : VerbProduction
    action = Board
    verbPhrase = 'get/getting (in what)'
    missingQ = 'what do you want to get in'
    dobjReply = singleNoun
;

VerbRule(Enter)
    ('enter' | ('walk' | 'go' | 'get' | 'climb')
     ( 'in' | 'in' 'to' | 'into' | 'inside'))
    singleDobj
    : VerbProduction
    action = Enter
    verbPhrase = 'enter/entering (what)'
    missingQ = 'what do you want to enter'
    dobjReply = singleNoun
;

VerbRule(Sleep)
    'sleep'
    : VerbProduction
    action = Sleep
    verbPhrase = 'sleep/sleeping'
;

VerbRule(Fasten)
    ('fasten' | 'buckle' | 'buckle' 'up') multiDobj
    : VerbProduction
    action = Fasten
    verbPhrase = 'fasten/fastening (what)'
    missingQ = 'what do you want to fasten'
;

VerbRule(FastenTo)
    ('fasten' | 'buckle') multiDobj 'to' singleIobj
    : VerbProduction
    action = FastenTo
    verbPhrase = 'fasten/fastening (what) (to what)'
    missingQ = 'what do you want to fasten (to it);'
               + 'what do you want to fasten it to'
    iobjReply = toSingleNoun
;

VerbRule(Unfasten)
    ('unfasten' | 'unbuckle') multiDobj
    : VerbProduction
    action = Unfasten
    verbPhrase = 'unfasten/unfastening (what)'
    missingQ = 'what do you want to unfasten'
;

VerbRule(UnfastenFrom)
    ('unfasten' | 'unbuckle') multiDobj 'from' singleIobj
    : VerbProduction
    action = UnfastenFrom
    verbPhrase = 'unfasten/unfastening (what) (from what)'
    missingQ = 'what do you want to unfasten;'
               + 'what do you want to unfasten it from'
    iobjReply = fromSingleNoun
;
//
//VerbRule(PlugInto)
//    'plug' multiDobj ('in' | 'into' | 'in' 'to') singleIobj
//    : VerbProduction
//    action = PlugInto
//    verbPhrase = 'plug/plugging (what) (into what)'
//    missingQ = 'what do you want to plug (into it);'
//             + 'what do you want to plug it into'
//    iobjReply = inSingleNoun
//;
//
//VerbRule(PlugIntoWhat)
//    [badness 500] 'plug' multiDobj
//    : VerbProduction
//    action = PlugInto
//    verbPhrase = 'plug/plugging (what) (into what)'
//    missingQ = 'what do you want to plug (into it);'
//              + 'what do you want to plug it into'
//
//    missingRole = IndirectObject
//    iobjReply = inSingleNoun
//;
//
//VerbRule(PlugIn)
//    'plug' multiDobj 'in'
//    | 'plug' 'in' multiDobj
//    : VerbProduction
//    action = PlugIn
//    verbPhrase = 'plug/plugging (what) in'
//    missingQ = 'what do you want to plug in'
//;
//
//VerbRule(UnplugFrom)
//    'unplug' multiDobj 'from' singleIobj
//    : VerbProduction
//    action = UnplugFrom
//    verbPhrase = 'unplug/unplugging (what) (from what)'
//    missingQ = 'what do you want to unplug;what do you want to unplug it from'
//    iobjReply = fromSingleNoun
//;
//
//VerbRule(Unplug)
//    'unplug' multiDobj
//    : VerbProduction
//    action = Unplug
//    verbPhrase = 'unplug/unplugging (what)'
//    missingQ = 'what do you want to unplug'
//;
//
VerbRule(Screw)
    'screw' multiDobj
    : VerbProduction
    action = Screw
    verbPhrase = 'screw/screwing (what)'
    missingQ = 'what do you want to screw'
;

VerbRule(ScrewWith)
    'screw' multiDobj 'with' singleIobj
    : VerbProduction
    action = ScrewWith
    verbPhrase = 'screw/screwing (what) (with what)'
    missingQ = 'what do you want to screw;'
               + 'what do you want to screw it with'
    iobjReply = withSingleNoun
;

VerbRule(Unscrew)
    'unscrew' multiDobj
    : VerbProduction
    action = Unscrew
    verbPhrase = 'unscrew/unscrewing (what)'
    missingQ = 'what do you want to unscrew'
;

VerbRule(UnscrewWith)
    'unscrew' multiDobj 'with' singleIobj
    : VerbProduction
    action = UnscrewWith
    verbPhrase = 'unscrew/unscrewing (what) (with what)'
    missingQ = 'what do you want to unscrew;'
               + 'what do you want to unscrew it with'
    iobjReply = withSingleNoun
;

VerbRule(PushTravelDir)
    ('push' | 'pull' | 'drag' | 'move') singleDobj singleDir
    : VerbProduction
    action = PushTravelDir
;

//VerbRule(PushTravelThrough)
//    ('push' | 'pull' | 'drag' | 'move') singleDobj
//    ('through' | 'thru') singleIobj
//    : VerbProduction
//    action = PushTravelThrough
//    verbPhrase = 'push/pushing (what) (through what)'
//    missingQ = 'what do you want to push;what do you want to push it through'
//;
//
//VerbRule(PushTravelEnter)
//    ('push' | 'pull' | 'drag' | 'move') singleDobj
//    ('in' | 'into' | 'in' 'to') singleIobj
//    : VerbProduction
//    action = PushTravelEnter
//    verbPhrase = 'push/pushing (what) (into what)'
//    missingQ = 'what do you want to push;what do you want to push it into'
//;
//
//VerbRule(PushTravelGetOutOf)
//    ('push' | 'pull' | 'drag' | 'move') singleDobj
//    'out' ('of' | ) singleIobj
//    : VerbProduction
//    action = PushTravelGetOutOf
//    verbPhrase = 'push/pushing (what) (out of what)'
//    missingQ = 'what do you want to push;what do you want to push it out of'
//;
//
//
//VerbRule(PushTravelClimbUp)
//    ('push' | 'pull' | 'drag' | 'move') singleDobj
//    'up' singleIobj
//    : VerbProduction
//    action = PushTravelClimbUp
//    verbPhrase = 'push/pushing (what) (up what)'
//    missingQ = 'what do you want to push;what do you want to push it up'
//;
//
//VerbRule(PushTravelClimbDown)
//    ('push' | 'pull' | 'drag' | 'move') singleDobj
//    'down' singleIobj
//    : VerbProduction
//    action = PushTravelClimbDown
//    verbPhrase = 'push/pushing (what) (down what)'
//    missingQ = 'what do you want to push;what do you want to push it down'
//;

VerbRule(Exits)
    'exits'
    : VerbProduction
    action = Exits
    verbPhrase = 'exits/showing exits'
;

VerbRule(ExitsMode)
    'exits' ('on'->on_ | 'all'->on_
             | 'off'->off_ | 'none'->off_
             | ('status' ('line' | ) | 'statusline') 'look'->on_
             | 'look'->on_ ('status' ('line' | ) | 'statusline')
             | 'status'->stat_ ('line' | ) | 'statusline'->stat_
             | 'look'->look_)
    : VerbProduction
    action = ExitsMode
    verbPhrase = 'turn/turning off exits display'
;

VerbRule(ExitsColour)
    ('exits'|'exit') ('color'|'colour') ('on' ->on_| 'off' ->on_ | 
                                         'blue' ->colour_ | 'red' -> colour_ |
                                         'green' -> colour_ | 'yellow' ->
                                         colour_)
    : VerbProduction
    action = ExitsColour
    verbPhrase = 'turn/turning off unvisited exits colouring'
;


VerbRule(HintsOff)
    'hints' 'off'
    : VerbProduction
    action = HintsOff
    verbPhrase = 'disable/disabling hints'
;

VerbRule(Hints)
    'hint' | 'hints'
    : VerbProduction
    action = Hints
    verbPhrase = 'show/showing hints'
;

//VerbRule(Oops)
//    ('oops' | 'o') literalDobj
//    : VerbProduction
//    action = Oops
//    verbPhrase = 'oops/correcting (what)'
//;
//
//VerbRule(OopsOnly)
//    ('oops' | 'o')
//    : VerbProduction
//    action = OopsOnly
//    verbPhrase = 'oops/correcting'
//;


#ifdef __DEBUG

VerbRule(Purloin)
    ('purloin' | 'pn') singleDobj
    : VerbProduction
    action = Purloin
    verbPhrase = 'purloin/purloining (what)'
    missingQ = 'what do you want to purloin'
;

VerbRule(GoNear)
    ('gonear' |'go' 'near'| 'gn') singleDobj
    : VerbProduction
    action = GoNear
    verbPhrase = 'go near/going near (what)'
;


VerbRule(FiatLux)
    'fiat' 'lux' | 'let' 'there' 'be' 'light'
    : VerbProduction
    action = FiatLux
    verbPhrase = 'adjust/adjusting light'
;

VerbRule(Evaluate)
    'eval' literalDobj
    : VerbProduction
    action = Evaluate
    verbPhrase = 'evaluate/evaluating (what)'
;

/* 
 *   If they're not already present, insert quotes round the argument of an eval
 *   command.
 */

evalPreParser: StringPreParser
    doParsing(str, which)
    {
        if(str.toLower.startsWith('eval ') && !str.endsWith('"'))
        {
            str = str.splice(6, 0, '"') + '"';
        }
        return str;
    }
; 

#endif


/* ------------------------------------------------------------------------ */
/*
 *   Additional English grammar properties.
 *   
 *   For each Action, we set up the property grammarTemplates with a list
 *   of all of the possible command input syntax templates that can be used
 *   to generate the action from a user command.  These are of the form
 *   "put (dobj) in (iobj)", which we can easily use to generate messages
 *   or compare to input phrases.  This is sometimes useful for determining
 *   the specific phrasing the player used in input, when a given action
 *   has multiple possible phrasings.
 *   
 *   For each VerbProduction (which is generally the same as a VerbRule
 *   definition), we set the property grammarAlts to a list of the grammar
 *   rules for the verb.  This is useful for finding the specific rule we
 *   matched for a given parsed input.
 *   
 *   These lists, and the procedure for building them, are inherently
 *   specific to the English library.  Other languages might not define
 *   their verb grammars with the same structures, so the assumptions we
 *   make about the grammar trees might not hold in all languages.  These
 *   lists are only used within the English part of the library, since the
 *   generic library can't count on them being available in other
 *   translations.  
 */
property grammarTemplates, grammarAlts, verbRule;


/* ------------------------------------------------------------------------ */
/*
 *   Initialize the DoerParser table.  This populates the given
 *   DoerParserTable with DoerParser objects that describe the syntax
 *   available for use in Doer 'cmd' strings.
 *   
 *   Each DoerParser object simply provides a regular expression for
 *   parsing one action phrasing.  The regular expression defines the
 *   language-specific template for the action phrasing, with the proviso
 *   that each noun phrase is replaced with an object or class name, or a
 *   list of object or class names separated with '|' characters.
 *   
 *   For example, for a Give To command in English, we might define one
 *   DoerParser for each of the following regular expressions:
 *   
 *.     'give (<alphanum|_|vbar>+) to (<alphanum|_|vbar>+)'
 *.     'give (<alphanum|_|vbar>+) (<alphanum|_|vbar>+)'
 *   
 *   After you create a DoerParser, simply call ptab.addParser() to add the
 *   new parser to the table.
 *   
 *   Note that, regardless of the language, you MUST use a verb syntax that
 *   starts with a verb word, because of the way the parser lookup table is
 *   built.  Most languages naturally start an imperative with a verb
 *   anyway, so this is usually what you'd do even without this
 *   requirement.  For a language that uses another word order for
 *   imperatives, though, you'll have to use an unnatural syntax for the
 *   DoerParser syntax, and thus for the Doer 'cmd' string syntax.  This
 *   unnatural syntax is purely internal to the library and games, though -
 *   players won't see it.
 *   
 *   It's up to the language module to determine how to come up with the
 *   list of verb phrases, and how to build the verb regular expression
 *   patterns.  The English library builds the list directly from the
 *   player command grammar - specifically, the syntax token lists defined
 *   for the VerbRule productions.
 *   
 *   This English implementation also takes the opportunity to build
 *   grammar templates for each Action.  This is purely for our own use in
 *   the English library, so other languages don't have to replicate that
 *   functionality.  We do this here because we build these from the same
 *   information that we use to build the DoerParsers.
 *   
 *   [Required] 
 */
initDoerParsers(ptab)
{
    /* set up inherited empty template lists in the base classes */
    VerbProduction.grammarAlts = [];
    Action.grammarTemplates = [];
    Action.verbRule = nil;

    /* run through each predicate rule alternative */
    foreach (local alt in predicate.getGrammarInfo())
    {
        /* get the match object and action */
        local mo = alt.gramMatchObj;
        local action = mo.action;
        
        /* save the alternative info with the match object */
        mo.grammarAlts += alt;
        
        /* build it into a string template and a Doer parser */
        local t = [], pt = [], ptRoles = [];
        foreach (local tok in alt.gramTokens)
        {
            switch (tok.gramTokenType)
            {
            case GramTokTypeProd:
                /* check the target property */
                if (tok.gramTargetProp == &dirMatch)
                {
                    /* it's a direction */
                    t += '(direction)';
                    pt += '<alphanum>+';
                   
                }
                else
                {
                    /* 
                     *   For anything else, assume we have a noun
                     *   phrase.  Look to see if this matches a noun
                     *   phrase role. 
                     */
                    local r = NounRole.all.valWhich(
                        { r: r.matchProp == tok.gramTargetProp });
                    
                    /* if it matches, enter in the template as '(role)' */
                    if (r != nil)
                    {
                        t += '(' + r.name + ')';
                        pt += '(<alphanum|_|vbar|dot|star>+)';
                        ptRoles += r;
                    }
                }
                break;
                
            case GramTokTypeLiteral:
                /* literal - enter in the template directly as it is */
                t += tok.gramTokenInfo;
                pt += tok.gramTokenInfo;
                break;
            }
        }

        /* 
         *   combine the template tokens into a string, and add the
         *   string to the action's template list
         */
        action.grammarTemplates += t.join(' ');
        
        /* 
         *   If the action doesn't already know of an associated verb rule
         *   note that this one belongs to it.
         */
        
        if(action.verbRule == nil)
        {
            action.verbRule = mo;
        }
        
        
        /* add a DoerParser for the verb template to the parser table */
        ptab.addParser(new DoerParser(action, pt[1], pt.join(' '), ptRoles));
    }
}

/* ------------------------------------------------------------------------ */
/*
 *   English-specific VerbProduction additions 
 */
modify VerbProduction
    /*
     *   Get the grammar production for the given noun phrase role, for
     *   answering missing-noun questions ("What do you want to open?").
     *   By default, we'll look in three places:
     *   
     *   1. If we have the "reply" property that corresponds to the role
     *   (dobjReply, iobjReply, etc), we'll return the grammar rule
     *   specified there.
     *   
     *   2. We'll try to find the role's match property in our grammar rule
     *   list.  If we find it, we'll return the production for the first
     *   one we find.
     *   
     *   3. Failing all that, we'll return nounList for a direct object, or
     *   singleNoun for anything else.
     *   
     *   [Required] 
     */
    missingRoleProd(role)
    {
        /* check for a custom setting for the role */
        if (self.(role.missingReplyProp) != nil)
            return self.(role.missingReplyProp);

        /* look for the role in our grammar syntax templates */
        foreach (local alt in grammarAlts)
        {
            /* look for a match for this role, with a sub-production */
            local t = (alt.valWhich(
                { t: t.gramTargetProp == role.matchProp
                     && t.gramTokenType == GramTokTypeProd  }));

            /* if we found it, return the sub-production object */
            if (t != nil)
                return t.gramTokenInfo;
        }

        /* still didn't find it - return a suitable default for the role */
        return (role == DirectObject ? nounList : singleNoun);
    }
;
