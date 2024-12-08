#charset "us-ascii"
#include "advlite.h"


/*
 *   *************************************************************************
 *   thoughts.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve
 *
 *
 *   This file adds support for a THINK about command
 */

property thinkDesc;

/* 
 *   The base clase for a thought manager object. To use this in a game create a
 *   single object of this class and locate a number of Thought objects in it
 *   (with the + notation) to represent responses to THINK ABOUT
 */
class ThoughtManager: PreinitObject, TopicDatabase
    
    /* Carry out the ThoughtManager's preinitialization */
    execute()
    {
        /* Register this object as the game's intial thoughtManager object. */
        if(thinker == nil || thinker == gameMain.initialPlayerChar)
        {
            libGlobal.thoughtManagerObj = self;
                        
            gPlayerChar.myThoughtManager = self;
        }
        else if(thinker)
            thinker.myThoughtManager = self;
          
        /* 
         *   Add every Thought object that's located in us to our topic entry
         *   list
         */
        forEachInstance(Thought, new function(t) {
            if(t.location == self)
                addTopic(t);
        });
    }   
    
    /*  Handle a THINK ABOUT command. */    
    handleTopic(top)
    {
        /* First get the best match to the topic we want to think about */
        local match = getBestMatch(thoughtList, top);
        
        /* If we didn't find a match, display a message to that effect. */
        if(match == nil)
            say(noThoughtMsg);
        
        /* Otherwise have our best match display its reponse. */
        else
            match.handleResponse();
    }
    
    
    
    /* The list of Thoughts associated with this ThoughtManager object */
    thoughtList = []
    
    /* The message to display when we don't find a matching Thought */
    noThoughtMsg = BMsg(no thoughts, '{I} {have} no thoughts on that particular
        topic.')
    
    /* Our actor is the actor who's doing the thinking. */
    getActor = (gActor)
    
    /* 
     *   The person whose thoughts are located in this ThoughtManager. If the player character never
     *   changes in this game and/or you only define one ThoughtManager, this can be left at nil;
     *   otherwise you should override this property to point to the actor whose thoughta are being
     *   managed by this object.
     */
    thinker = nil    
;


/* 
 *   A kind of TopicEntry that responds to a THINK ABOUT command when located in
 *   a ThoughtManager object. These can be defined just like any other topic
 *   entry objects, and work in just the same way as ConsultTopics.
 */
class Thought: TopicEntry
    includeInList = [&thoughtList]
    
    /* 
     *   On a Thought our handleResponse() method simply calls out topicResponse() method. We
     *   separate the two to allow DefaultThought to do something different.
     */
    handleResponse() { topicResponse(); } 
;

/* 
 *   A DefaultThought is a Thought that matches any THINK ABOUT command with a
 *   very low match score, so that any more specific Thought that's matched will
 *   take precedence. Game code can use this to provide a fall-back response
 *   when no more specific response is available.
 */
class DefaultThought: Thought
    
    matchObj = [Thing, Topic ]
    
    matchTopic(top)
    {
        /* Note the Topic we matched. */
        topicMatched = top;
        
        /* 
         *   Since we can match anything, simply return the sum of our matchScore and our
         *   scoreBoost.
         */
        return matchScore + scoreBooster();
    }
    
    matchScore = 1
    
    
    handleResponse()    
    {
        /* 
         *   If the topic we matched defines a thinkDesc property, use that thinkDesc property to
         *   preovide our response. Otherwise use our own topicResponse.
         */
        if(topicMatched.propDefined(&thinkDesc) && topicMatched.propType(&hinkDesc) != TypeNil)
            topicMatched.displayAlt(&thinkDesc, &topicResponse);
        else
            topicResponse();
    }
    
    /* 
     *   By default, take our topicResponse from our thoughtManager's noThoughtMsg. Game code can
     *   override to provide a different response here.
     */
    topicResponse() { "<<location.noThoughtMsg>>"; }
;
