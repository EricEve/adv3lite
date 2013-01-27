#charset "us-ascii"
#include "advlite.h"


/* Base class for ConsultTopics and Conversation Topics */

class TopicEntry: object     
    matchTopic(top)
    {
        /* 
         *   if top is nil we're programmatically passing a topic that will
         *   match anything. Otherwise test if top matches the matchObj, where
         *   match means that top is one of items in the matchObj list or else
         *   belongs to a class in the list.
         */
        
        if(top == nil || 
           valToList(matchObj).indexWhich({x: top.ofKind(x)}) != nil)
            return matchScore + scoreBoost();
     
        if(matchPattern != nil && top.ofKind(Topic))
        {    
            local txt;

            /* 
             *   There's no match object; try matching our regular
             *   expression to the actual topic text.  Get the actual text.
             */
            txt = top.getTopicText();

            /* 
             *   if they don't want an exact case match, convert the
             *   original topic text to lower case 
             */
            if (!matchExactCase)
                txt = txt.toLower();

            /* if the regular expression matches, we match */
            if (rexMatch(matchPattern, txt) != nil)
                return matchScore + scoreBoost;
        }
        
        return nil;
    }
    
    initializeTopicEntry()
    {
        /* if we have a location, add ourselves to its topic database */
        if (location != nil)
            location.addTopic(self);
    }
    
    topicResponse()
    {
        if(ofKind(Script))
            doScript();
    }
    
    matchScore = 100    
    matchObj = nil
    matchPattern = nil
    matchExactCase = nil
    
     /*
     *   The set of database lists we're part of.  This is a list of
     *   property pointers, giving the TopicDatabase properties of the
     *   lists we participate in. 
     */
    includeInList = []
    
    
    /* 
     *   A method that can be used to dynamically alter our score according to
     *   circumstances if needed
     */
    scoreBoost = 0
    
    isActive = true    
    
    active = isActive
    
;

class TopicDatabase: object
    getBestMatch(myList, requestedList)
    {        
        local bestMatch = nil;
        local bestScore = 0;
        
        myList = myList.subset({c: c.active});
        foreach(local req in valToList(requestedList))
        {    
            foreach(local top in myList)
            {
                local score = top.matchTopic(req);
                if(score != nil && score > bestScore)
                {
                    bestScore = score;
                    bestMatch = top;
                }
            }
        
        }
        
        return bestMatch;
    }
    
    addTopic(top)
    {
        foreach(local prop in valToList(top.includeInList))
            self.(prop) += top;
    }
;


/* 
 *   A Consultable is an object like a book, timetable or computer that can be
 *   used to look things up in through commands such as LOOK UP SELVAGEE IN
 *   DICTIONARY or CONSULT BLUE BOOK ABOUT RABBITS
 */

class Consultable: TopicDatabase, Thing
    
    consultTopics = []
    
    isConsultable = true
    
    dobjFor(ConsultAbout)
    {    
        
        action()
        {
            local matchedTopic = getBestMatch(consultTopics, gIobj.topicList);
            if(matchedTopic == nil)
                DMsg(no matched topic, '{The subj dobj} {has} nothing to say
                    on that. ');
            else
                matchedTopic.topicResponse();
        }
    }
    
   
;


class ConsultTopic: TopicEntry       
       
    includeInList = [&consultTopics]
;


class DefaultConsultTopic: ConsultTopic
    matchTopic(top)
    {
        return matchScore;
    }
    
    matchScore = 1
    
    isActive = true
;


consultablePreinit: PreinitObject
    execute()
    {
        forEachInstance(ConsultTopic, {c: c.initializeTopicEntry()} );
    }
;
