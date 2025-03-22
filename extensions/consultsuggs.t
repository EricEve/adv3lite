#charset "us-ascii"
#include "advlite.h"

//------------------------------------------------------------------------------------------
/*
 *   consultsuggs.t
 *
 *   Version 1.0
 *
 *   Allows a Consultable's ConsultTopics to be suggested. For the list of suggested topics to be
 *   displayed you need to give each ConsultTopic to be suggested a name and to call the
 *   Consultable's showSuggestions() method at some suitable point in your game code, for example:
 *.
 *.
 *.    blackBook: Consultable 'big black book' @startroom
 *.
 *.      readDesc()
 *.      {
 *.          "Ir's a book in which you could look up a variety of topics.<.p>";
 *.
 *.          showSuggestions();
 *.      }
 *.
 *.    ;
 *.
 *.   + ConsultTopic @tCarrots
 *.      "They're an orange root vegetable. "
 *.
 *.       name = 'carrots'
 *.   ;
 *.
 *.    + ConsultTopic @tTomatoes
 *.    "They're a round red fruit, but they're usually used as a vegetable. "
 *.
 *.       name = 'tomatoes'
 *.   ;
 *.
 *.
 *.   tCarrots: Topic 'carrots';
 *.   tTomatoes: Topic 'tomatoes';
 *
 */

/* 
 *   The Lister for listing suggested topics to THINK ABOUT. We base it on suggestedTopicLister,
 *   since most of the logic is the same.
 */
consultableSuggestionLister: suggestedTopicLister
    /* 
     *   The message to display if there are no thought topics to suggest. By default we do nothing
     *   here for suggested ConsultTopics but game code can override as required.
     */
    showListEmpty(explicit)  { }
  
    
    
    /* 
     *   Override suggestedTopicLister's list of TypeInfo to the values relevant to ConsultTopics.
     *.
     *   The first element of the list is a pointer to the list property to use on this
     *   lister object to hold the particular sublist. The second element of each list is a property
     *   pointer used to identify which sublist a ConsultTopixc belongs in, according to its own
     *   includeInList property. The third element is the type of topic entry a topic entry should
     *   be suggested as if it is explicitly requested in its suggestAs property. The fourth element
     *   is the text to use when introducing the corresponding section of the list (or nil if no
     *   introductory text is required).
     */
    typeInfo = [
        [&consultList, &consultTopics, ConsultTopic, &consultPrefix]
    ]
        
    /* Our list of ConsultTopics to suggest. This will be built by consultableSuggestionLister. */
    consultList = []   
    
    /* The text to introduce our list of suggested ConsultTopics, following "You could ". */
    consultPrefix = (source && source.customPrefix) ? source.customPrefix + ' ' : 
       BMsg(look up, 'look up ')
    
    /* 
     *   The Consultable object whose showSuggestions method has just been called to generating a
     *   suggestion list with this lister.
     */
    source = nil
;


modify Consultable
/* Display a list of topics the player can CONSULT ABOUT */
    showSuggestions()    
    {       
        /* Set up a local lst variable to hold the list of Think Abouts we want to display. */
        local lst = [];
        
        /* 
         *   Get a list of all our active thoughts whose curiosity has been aroused but not
         *   satisfied.
         */
        lst = consultTopics.subset({x: x.isActive && x.curiosityAroused && !x.curiositySatisfied});
        
        /* Reduce the list to topics the PlayerCharacter knows about */        
        lst = lst.subset({x: x.matchObj == nil || valToList(x.matchObj)[1].known});                    
           
        /* Tell our suggestion lister that we are the source of ConsultTopics to be listed. */
        mySuggestionLister.source = self;
        
        /* 
         *   Use the thoughtSuggestionLister to list the thourhs the player might want to ask about.
         */
        mySuggestionLister.show(lst);      
        
        /* 
         *   If we've just listed our suggested ConsultTopics then we're most likely going to be the
         *   Consultable the player intends to use on a subsequent turn.
         */
        currentConsultableScore = 20;
        
    }
    
    /* Carry out our Preinitialization. */
    execute()
    {
        /* Carry out our inherited Preinitialization. */
        inherited(); 
        
        /* Initialize all our ConsultTopics. */
        foreach(local t in consultList)
            t.initializeTopicEntry();
    }
    
    /* The suggestion lister to use for listing suggested ConsultTopics. */
    mySuggestionLister = consultableSuggestionLister
    
    /* 
     *   An optional custom prefix for our suggestionLister to use in place of the default, e.g.
     *   'consult the black book about '. If we define something here this must result in a valid
     *   command string when combined with the suggested ConsultTopic. e.g. 'consult the black book
     *   about carrots'. Alternatively, we can simply set useVerbosePrefix to true to generate the
     *   more verbose form 'consult the black book about' - this may be useful in situations where
     *   several Consultables may be in scope as once and we want to avoid disambiguation
     *   difficulties.
     */
    customPrefix = useVerbosePrefix ? verbosePrefix : nil    
    
    /* A more verbose form of the suggestion prefix, e.g., 'consult the black book about' */
    verbosePrefix = BMsg(verbose consult prefix, 'consult ' + theName + ' about')
    
    /* Flag, do we want this Consultable to use the more verbose prefix? By default we don't */
    useVerbosePrefix = nil  
    
;

modify ConsultTopic
    /* 
     *   A ConsultTopic should be suggested as a ConsultTopic by consultableSuggestionLister; we
     *   need to specify that here since suggestedTopicLister, from which
     *   consultableSuggestionLister inherits, needs this information.
     */
    suggestAs = ConsultTopic
    
    /* 
     *   The listOrder can be used to determine the order in which ConsultTopic suggestions are
     *   listed. Thoughts with a lower listOrder will be listed before Tboughts with a higher
     *   listOrder. By default we give all Thoughts a listOrder of 100.
     */
    listOrder = 100
    
    /* 
     *   An expression that should evaluate to true when we want this ConsultTopic to be suggested.
     *   Note that both curiosityAroused and curiositySatisfied need to be overridden by expressions
     *   or methods) in game code if something other then their default values (or true and nil
     *   respectively) are needed.
     */
    curiosityAroused = true
    
    /* 
     *   An expression that should evaluate to true when we no lomger want this ConsultTopic to be
     *   suggested. This needs to be overriden by game code if desired; the extension makes no
     *   attempt to update curiositySatisifed to true when, say, a Thought topic has been suggested
     *   once or so many times, as each game will probably want to handle this in a different way.
     */
    curiositySatisfied = nil
    
    /* 
     *   The name to be displayed if you want this Thought to be suggested in response to a THINK
     *   command. This should be something that would match the vocab of the Topic associated with
     *   this Thought. Alternatively, autoName can be set to true to have the name set to the name
     *   of the Topic (or Thing) this Thought matches.
     */
    name = nil
    
    
    /* 
     *   If autoName is true, the library will attempt to define the name property from our
     *   associated Topic, provided name hasn't already been defined.
     */
    autoName = nil
    
    
    /* Initialize this ConsultTopic (this is actually called at preinit) */
    initializeTopicEntry()
    {            
        inherited();
        
        /*  
         *   If our autoname property is true, construct our name (for use in
         *   suggesting this TopicEntry) provided we have something to construct
         *   it from.
         */
        if(autoName && matchObj != nil && name is in (nil, ''))
            buildName();
    }
    
    
     /* 
     *   Construct the name of this ActorTopicEntry by using the theName
     *   property of our first matchObj.     
     */
    buildName() { name = valToList(matchObj)[1].theName; }
;


/* 
 *   A PreParsr that traps numerical input (e.g. a command consisting purely of an integer, such as
 *   2), and translates it into the THINK ABOUT command in the latest list of enumerated thought
 *   suggesstions.
 */ 

enumConsultableSuggestionsPreparser: StringPreParser
    doParsing(str, which)   
    {
        /* 
         *   We only want to modify str here if this is a new command 
         *   suggestedTopicLister's enumerateSuggestions property is set to true.
         */
        if(which == rmcCommand && consultableSuggestionLister.enumerateSuggestions)
        {
            /* Try converting str to an integer */
            local num = toInteger(str);
            
            /* 
             *   If we have a number and that number is in the range of the number of topic
             *   suggestions listed then replace str with the corresponding conversational command.
             */
            if(num && num <= suggestionEnumerator.count && num > 0)
            {
                /* 
                 *   Change str to the corresponding item in suggestionEnumerator's suggestion list.
                 */
                str = suggestionEnumerator.suggestionList[num];
                
                /* 
                 *   Echo the new command back to the player so the player can see what's now being
                 *   executed.
                 */
                "<.inputline>\^<<str>><./inputline>\n";
            }            
        }       
        
        /* Return our string, modified or unmodified as the case may be. */
        return str;
    }    
;

