#charset "us-ascii"
#include "advlite.h"

/*
 *   ****************************************************************************
 *    topicEntry.t 
 *    This module forms part of the adv3Lite library 
 *    (c) 2012-13 Eric Eve
 */

/* 
 *   TopicEntry is the base class for ConsultTopics and various kinds of
 *   Conversation Topics. It can be used to match a particular topic and output
 *   an appropriate response.
 */
class TopicEntry: object     
    
    /* 
     *   Determine how well this TopicEntry matches top (a Topic or Thing). If
     *   it doesn't match at all we return nil, otherwise we return a numerical
     *   score indicating the strength of the match so that a routine that's
     *   looking for the best match can choose the one with the highest score.
     */
    matchTopic(top)
    {
        /* 
         *   Note the topic we're trying to match so that topicResponse() can
         *   make use if it, if it wants to.
         */
        topicMatched = top;
        
        /* 
         *   If top is nil we're programmatically passing a topic that will
         *   match anything. Otherwise test if top matches the matchObj, where
         *   match means that top is one of items in the matchObj list or else
         *   belongs to a class in the list. If we have a match, return the sum
         *   of our matchScore and our scoreBoost.
         */        
        if(top == nil || 
           valToList(matchObj).indexWhich({x: top.ofKind(x)}) != nil)
            return matchScore + scoreBooster();
     
        /* 
         *   Next test to see if we should match a regular expression. This will
         *   be the case if we have a matchPattern to match and our top object
         *   is a Topic (which the parser will have created to encapsulate the
         *   text our matchPattern needs to match).
         */
        if(matchPattern != nil && top.ofKind(Topic))
        {    
            local txt;

            /* 
             *   There's no match object; try matching our regular
             *   expression to the actual topic text.  Get the actual text.
             */
            txt = top.getTopicText();

            /* 
             *   If they don't want an exact case match, convert the
             *   original topic text to lower case 
             */
            if (!matchExactCase)
                txt = txt.toLower();

            /* if the regular expression matches, we match */
            if (rexMatch(matchPattern, txt) != nil)
                return matchScore + scoreBoost;
        }
        
        /* If we haven't found a match, return nil */
        return nil;
    }
    
    /* Initialize this Topic Entry (actually carried out at pre-init */
    initializeTopicEntry()
    {
        /* if we have a location, add ourselves to its topic database */
        if (location != nil)
            location.addTopic(self);
    }
    
    /* 
     *   Output our response to the topic. This can be typically be overridden
     *   to a double-quoted string or method to output the required response.
     */
    topicResponse()
    {
        /* 
         *   If we're not overridden, then if this TopicEntry is also some kind
         *   of Script (normally because it also includes an EventList class in
         *   its superclass list), then call its doScript() method to display
         *   the next item in the list.
         */
        if(ofKind(Script))
            doScript();
    }
    
    /* 
     *   Our matchScore is the base score we return if we match the topic
     *   requested; this is used to determine whether we're the best match under
     *   the circumstances. By default we use a value of 100.
     */
    matchScore = 100    
    
    /* 
     *   The object, topic or list of objects/topics that this TopicEntry
     *   matches.
     */
    matchObj = nil
    
    /*   
     *   The topic that this TopicEntry actually matched (set by matchTopic()).
     */
    topicMatched = nil
    
    /*  
     *   A regular expression that this TopicEntry might match, if it doesn't
     *   match a matchObj. We don't need to define this if we've defined a
     *   matchObj.
     */
    matchPattern = nil
    
    /* 
     *   Do we want to restrict this TopicEntry to an exact case match with its
     *   matchPattern? By default we don't.
     */
    matchExactCase = nil
    
    /*
     *   The set of database lists we're part of.  This is a list of one or more
     *   property pointers, giving the TopicDatabase properties of the
     *   lists we participate in. 
     */
    includeInList = []
    
    
    /* 
     *   A method or property that can be used to dynamically alter our score
     *   according to circumstances if needed.
     */
    scoreBoost = 0
    
    scoreBooster()
    {
        local sb;
        
        /* Add any boost from our location */
        sb = location.propDefined(&scoreBooster) ? location.scoreBooster() : 0;
        
        /* Add our own scoreBoost. */
        return sb + scoreBoost;
    }
    
    /*  
     *   Is this TopicEntry currently active? Game code can set a condition here
     *   so that a TopicEntry only becomes active (i.e. available) under
     *   particular circumstances.
     */
    isActive = true    
    
    /*  
     *   The active property is used internally by the library to determine
     *   whether a TopicEntry is currently available for use. On the base
     *   TopicEntry class a topic entry is active if its isActive property is
     *   true, but this is not necessarily the case on the ActorTopicEntry
     *   subclass defined in actor.t, which needs to distinguish between these
     *   properties.
     *
     *   Game code should not normally need to override the active property.
     */
    active = isActive
    
    /*  
     *   If something located in us wants us to add it to our topic database,
     *   pass the request up to our location (this is used by AltTopic).
     */
    addTopic(top) { location.addTopic(top); }
    
    /* Our notional actor is our location's actor. */
    getActor = location.getActor
;


/*  
 *   A TopicDatabase is a container for TopicEntries that provides a method for
 *   determining the TopicEntry that best matches a list of topics
 */
class TopicDatabase: object
    
    /* 
     *   Find the topic entry among those supplied in myList that best matches
     *   at least one of the topics passed in requestedList.
     */
    getBestMatch(myList, requestedList)
    {        
        local bestMatch = nil;
        local bestScore = 0;
        
        /* 
         *   The implementation of the Actor Conversation system requires a
         *   property pointer to be passed as the first parameter in the
         *   corresponding method. To prevent accidents, we check whether we
         *   have a property pointer here and if so convert it to the
         *   corresponding list.
         */
        if(dataType(myList) == TypeProp)
            myList = self.(myList);
        
        /* Remove any inactive topic entries from the list to search */
        myList = myList.subset({c: c.active});
        
        /* 
         *   For each topic in our requested list of topics, see if we can find
         *   a topic entry that's a better match than any we've found so far.
         */
        foreach(local req in valToList(requestedList))
        {    
            /* Go through every topic entry in our list */
            foreach(local top in myList)
            {
                /* 
                 *   Compute the score that indicates how well the topic entry
                 *   matches the topic (top) we're currently testing for.
                 */
                local score = top.matchTopic(req);
                
                /*   
                 *   If we found a match (the score is non-nil) and the score is
                 *   greater than the best score we've found so far, note our
                 *   new best score and best matching topic entry.
                 */
                if(score != nil && score > bestScore)
                {
                    bestScore = score;
                    bestMatch = top;
                }
            }
        
        }
        
        /* Return the best match. */
        return bestMatch;
    }
    
    /* Add a topic entry to the appropriate list or list on this TopicDatabase. */
    addTopic(top)
    {
        /* 
         *   Go through each property pointer in the topic entry's includeInList
         *   and add the topic entry to the corresponding list.
         */
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
   
    /* The list of ConsultTopics associated with this Consultable */
    consultTopics = []
    
    /* A Consultable is indeed consultable */
    isConsultable = true
    
    /* Our handling of the ConsultAbout action when we're the direct object */
    dobjFor(ConsultAbout)
    {       
        
        action()
        {
            /* 
             *   We don't want this action to be construed as conversational from the point of view
             *   of revealing information to bystsanders, so we first store the identity of the
             *   current interlocutor and then set the current interlocutor to ni.
             */
            local interlocutor = gPlayerChar.currentInterlocutor;
            gPlayerChar.currentInterlocutor = nil;
            
            try
            {
                /* 
                 *   Find the topic we're meant to be matching by getting the best match to the list
                 *   of topics contained in the indirect object
                 */
                local matchedTopic = getBestMatch(consultTopics, gIobj.topicList);
                
                /* If we don't find a match, display a message explaining that */
                if(matchedTopic == nil)
                    say(noMatchedTopicMsg);
                
                /* 
                 *   Otherwise display the topic response of the ConsultTopic we matched.
                 */
                else
                    matchedTopic.topicResponse();
                
                /* 
                 *   Boost our currentConsultableScore in recognition that we were the last item to
                 *   be consulted.
                 */
                currentConsultableScore = 20;
            }
            
            finally
            {
                /* Restore the current interlocutor */
                gPlayerChar.currentInterlocutor = interlocutor;
            }
        }
    }
    
    noMatchedTopicMsg = BMsg(no matched topic, '{The subj dobj} {has} nothing to
        say on that. ')
    
    /* 
     *   Modify our score (from the point of view of the parser matching this
     *   Consultable) if we've been recently consulted (on the assumption that
     *   other things being equal, if we've been consulted recently, we're quite
     *   likely to be the object the player wants to consult again)
     */
    scoreObject(cmd, role, lst, m) 
    {
        /* Carry out the inherited handlind */
        inherited(cmd, role, lst, m); 
        
        /* 
         *   If the parser is looking to match a ConsultAbout action, boost our
         *   score if we've been consulted recently.
         */
        if(cmd.action == ConsultAbout && role == DirectObject)
            m.score += currentConsultableScore;
    }
    
    /* 
     *   The additional score we add in our scoreObject() method if we've been
     *   recently consulted.
     */
    currentConsultableScore = 0
    
    afterAction()
    {
        /* 
         *   Decrement out currentConsultableScore if we weren't one of the
         *   objects for the current action, but don't decrement it below zero.
         */
        
        if(gIobj != self && gDobj != self && currentConsultableScore > 0)
            currentConsultableScore-- ;
    }
    

    /* 
     *   A list of the ConsultTopics we want to create, each item in the list should be a
     *   two-element list in the form of [match, topic-response], where match is what we want the
     *   ConsultTopic to match and topic-responsse is what we want the ConsultTopic's topicResponse
     *   to be. match can be an object (Topic or Thing), a list of objects, or a match patter.
     *   topic-response will normally be a single-quoted string but could be a function pointer or
     *   floating method. A third entry can be supplied, which will be used as the matchScore, but
     *   this is probably seldom useful.
     */
    topicEntryList = nil
    
    /* Modifications to allow the automatic creation of ConsultTopics from our topicList. */
    preinitThing()
    {
        /* Carry out the inherited handling. */
        inherited();
        
        /* 
         *   Loop through our topicList to create a corresponding ConsultTopic for every item
         *   therein.
         */
        foreach(local item in valToList(topicEntryList))
            preinitTopic(item);
        
    }
    
    /* Create a ConsultTopic corrersponding to item */
    preinitTopic(item)
    {
        /* Make sure that item is expressed as a list. */
        item = valToList(item);
        
        /* Set up a local variable to contain our new ConsultTopic */
        local top;
        
        /* 
         *   Set up a local variable to hold the object, list of objects, or matchPattern our new
         *   ConscultTopic is to match.
         */
        local topkey;
        
        /*  If the first entry in out item list in 'default', create a new DefaultTopicEntry. */
        if(item[1] == 'default')        
        {
            top = new DefaultConsultTopic;
            topkey = nil;
        }
        
        else
        {
            /* Otherwise create a new ConsultTopic */
            top = new ConsultTopic;
            
            /* And note what it is to match on */
            topkey = item[1];
        }
        
        /* Set the new ConsultTopic's entry to ourself. */
        top.location = self;
        
        /* Carry out the initializing of our new TopicEntry */
        top.initializeTopicEntry();
            
        /* 
         *   Assign our matchObj or match pattern to the appropriate property of our new
         *   ConsultTopic.
         */
        switch(dataType(topkey))
        {
            /*If it's an object or list, assign it to the matcchObj property. */
        case TypeObject:
        case TypeList:
            top.matchObj = topkey;
            break;
            /* If it's a single-quoted string, assign it to the matchPattern property. */
        case TypeSString:
            top.matchPattern = topkey;
            break;
            /* If it's nil (as it will be for a DefaultConsultTopic) do nothing */
        case TypeNil:
            break;
            
        };
        
        /* 
         *   Provided we have a second entry in our item list, assign in to the new ConsultTopic's
         *   topicResponse property.
         */
        if(item.length > 1)      
        {
            local txt = item[2];
            
            setTopicResponse(top, topkey, txt);
                        
                 
        }
        
        /* Should we have a third item, assign it to the new ConsultTopic's matchScore */
        if(item.length > 2 && dataType(item[3]) == TypeInt)           
            top.matchScore = item[3];         
        
        
    }
    
    setTopicResponse(top, topkey, txt)
    {
        top.setMethod(&topicResponse, txt);   
    }
    
    /* We're our own 'actor' in the sense of being the source of any information we supply. */
    getActor = self
;

/* 
 *   A ConsultTopic is a kind of TopicEntry used in conjunction with a
 *   Consultable, and represents something the Consultable can be successfully
 *   consulted about.
 */
class ConsultTopic: TopicEntry       
    
    /* 
     *   ConsultTopics are listed in the consultTopics property of the
     *   Consultable that contains them.
     */
    includeInList = [&consultTopics]
;


/* 
 *   A DefaultConsultTopic is used to provide a response when a Consultable is
 *   consulted about something not otherwise provided for.
 */
class DefaultConsultTopic: ConsultTopic
    
    /* A DefaultConsultTopic matches anything, so just return our matchScore */
    matchTopic(top)
    {
        /* Note the Topic we matched. */
        topicMatched = top;
        
        /* 
         *   Since we can match anything, simply return the sum of our
         *   matchScore and our scoreBoost.
         */
        return matchScore + scoreBooster();
    }
    
    /* 
     *   A DefaultConsultTopic has the lowest possible matchScore so that any
     *   matching ConsultTopic will always take precedence.
     */
    matchScore = 1
    
    /* A DefaultConsultTopic is normally active */
    isActive = true
;

/* Preinitializer for ConsultTopics */
consultablePreinit: PreinitObject
    execute()
    {
        /* Initialize every ConsultTopic */
        forEachInstance(ConsultTopic, {c: c.initializeTopicEntry()} );
    }
;
