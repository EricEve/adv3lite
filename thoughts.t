#charset "us-ascii"
#include "advlite.h"

/* This file adds support for a THINK about command */

/* 
 *   The base clase for a thought manager object. To use this in a game create a
 *   single object of this class and locate a number of Thought objects in it
 *   (with the + notation) to represent responses to THINK ABOUT
 */

class ThoughtManager: PreinitObject, TopicDatabase
    execute()
    {
        libGlobal.thoughtManagerObj = self;
        forEachInstance(Thought, new function(t) {
            if(t.location == self)
                addTopic(t);
        });
    }   
    
    handleTopic(top)
    {
        local match = getBestMatch(thoughtList, top);
        if(match == nil)
            say(noThoughtMsg);
        else
            match.topicResponse();
    }
    
    thoughtList = []
    
    noThoughtMsg = BMsg(no thoughts, '{I} {have} no thoughts on that particular
        topic.')
;


/* 
 *   A kind of TopicEntry that responds to a THINK ABOUT command when located in
 *   a ThoughtManager object. These can be defined just like any other topic
 *   entry objects, and work in just the same way as ConsultTopics.
 */
class Thought: TopicEntry
    includeInList = [&thoughtList]
;

class DefaultThought: Thought
    matchTopic(top)
    {
        return matchScore + scoreBoost;
    }
    
    matchScore = 1
;
