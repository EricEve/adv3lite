#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*
 *   *************************************************************************** thoughtsuggs.t
 *
 *   This module provides the Thought Sugestions extension for the adv3Lite library (c) 2024 Eric
 *   Eve
 *
 *   Version 1.0  07-Dec-2024
 *
 *   The Thought Suggestions extension changes the function of the THINK command so that it suggests
 *   a list of topics the player can THINK ABOUT (as the TOPICS command does for conversation
 *   topics). For this to work the Thoughts the player can think about must be located in a
 *   ThoughtManager object and provided with a name property.
 *
 *   The thoughtsuggs.t required thoughts.t and actor.t to be present in the game.
 *
 */


/* 
 *   The Thought Suggestions extension modifies the behaviour of the THINK action to display a list
 *   of suggeste topics the player could think about.
 */
modify Think
    execAction(cmd)
    {
        /* Note our current interlocutor. */
        local interlocutor = gPlayerChar.currentInterlocutor;
        
        try
        {
            /* Set the current interlocutor to nil. */
            gPlayerChar.currentInterlocutor = nil;            
            
            /* 
             *   If a TboughtManager object has been defined in this game, call its
             *   showSuggections() method to list suggested topics to think about.
             */
            if(libGlobal.thoughtManagerObj != nil)
                libGlobal.thoughtManagerObj.showSuggestions();
            else
                /* Otherwise carry out the intherited action of the THINK command. */
                inherited(cmd);
        }
        finally
        {
            /* Restore the current interlocutor. */
            gPlayerChar.currentInterlocutor = interlocutor;
        }       
    } 
;

/* 
 *   The Lister for listing suggested topics to THINK ABOUT. We base it on suggestedTopicLister,
 *   since most of the logic is the same.
 */
thoughtSuggestionLister: suggestedTopicLister
    /* The message to display if there are no thought topics to suggest. */
    showListEmpty(explicit)  
    { 
        gCommand.actor = gPlayerChar;
        if(explicit)
            DMsg(no thought in mind, '{I} {have} nothing in mind to think about just {then}. ');
    }
    
    /* 
     *   Override suggestedTopicLister's list of TypeInfo to the values relevant to Thoughts.
     *.
     *   The first element of the list is a pointer to the list property to use on this
     *   lister object to hold the particular sublist. The second element of each list is a property
     *   pointer used to identify which sublist a Thought belongs in, according to its own
     *   includeInList property. The third element is the type of topic entry a topic entry should
     *   be suggested as if it is explicitly requested in its suggestAs property. The fourth element
     *   is the text to use when introducing the corresponding section of the list (or nil if no
     *   introductory text is required).
     */
    typeInfo = [
        [&thoughtList, &thoughtTopics, Thought, &thinkPrefix]
    ]
        
    /* Our list of Thoughts to suggest. This will be built by thoughtSuggestionLister. */
    thoughtList = []
 
    /* The text to introduce our list of suggested Thoughts, following "You could ". */
    thinkPrefix = BMsg(think about, 'think about ')
    
;

/* 
 *   Modifications to the TboughtManager class to allow it to work witht the Tbought Suggestions
 *   extenstion.
 */
modify ThoughtManager
    
    /* Display a list of topics the player can THINK ABOUT */
    showSuggestions()    
    {       
        /* Set up a local lst variable to hold the list of Think Abouts we want to display. */
        local lst = [];
        
        /* 
         *   Get a list of all our active thoughts whose curiosity has been aroused but not
         *   satisfied.
         */
        lst = thoughtList.subset({x: x.isActive && x.curiosityAroused && !x.curiositySatisfied});
        
        /* Reduce the list to topics the PlayerCharacter knows about */        
        lst = lst.subset({x: x.matchObj == nil || valToList(x.matchObj)[1].known});                    
                
        /* 
         *   Use the thoughtSuggestionLister to list the thourhs the player might want to ask about.
         */
        thoughtSuggestionLister.show(lst);      
        
    }
    
    /* Carry out our Preinitialization. */
    execute()
    {
        /* Carry out our inherited Preinitialization. */
        inherited(); 
        
        /* Initialize all our Thoughts. */
        foreach(local t in thoughtList)
            t.initializeTopicEntry();
    }
;

modify Thought
    /* 
     *   A Thought should be suggested as a Thought by thoughtSuggestionLister; we need to specify
     *   that here since suggestedTopicLister, from which thoughtSuggestionLister inhgerits, needs
     *   this information.
     */
    suggestAs = Thought
    
    /* 
     *   The listOrder can be used to determine the order in which Thought suggestions are listed.
     *   Thoughts with a lower listOrder will be listed before Tboughts with a higher listOrder. By
     *   default we give all Thoughts a listOrder of 100.
     */
    listOrder = 100
    
    /* 
     *   An expression that should evaluate to true when we want this Thought to be suggested. Note
     *   that both curiosityAroused and curiositySatisfied need to be overridden by expressions or
     *   methods) in game code if something other then their default values (or true and nil
     *   respectively) are needed.
     */
    curiosityAroused = true
    
    /* 
     *   An expression that should evaluate to true when we no lomger want this Thought to be
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
    
    
    /* Initialize this Thought (this is actually called at preinit) */
    initializeTopicEntry()
    {            
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

enumTboughtSuggestionsPreparser: StringPreParser
    doParsing(str, which)   
    {
        /* 
         *   We only want to modify str here if this is a new command and a conversation is in
         *   progress and the suggestedTopicLister's enumerateSuggestions property is set to true.
         */
        if(which == rmcCommand && thoughtSuggestionLister.enumerateSuggestions)
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