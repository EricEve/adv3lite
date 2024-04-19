#charset "us-ascii"
#include "advlite.h"

/* 
 *   FACT RELATIONS EXTENSION by Eric Eve
 *
 *   Version 1.0 18th April 2024
 *
 *   The factrel.t extension defines and uses relations involviing Facts. It must be included after
 *   tha main library and the relations.t extension.
 */

/* 
 *   The concerning relation tracks relations between Facta and the topics they reference (via their
 *   topics property).
 */
concerning: DerivedRelation 'concerns' 'referenced by' @manyToMany
     /* A Fact concerns all the topics listed in its topics property. */
    relatedTo(a)
    {
        return gFact(a).topics;        
    }
    
    /* 
     *   List all the possible values of everything that can enter into the left-hand side of the
     *   relation "a concerns b", which is the list of all the Facts define in the game. Since we
     *   don't expect this to change during the course of the game we can calculate this once and
     *   then replace this method with the resulting list of
     Facts.*/
    listKeys()
    {
        /* Set up a new Vector for working storage. */
        local vec = new Vector();
        
        /* Iterate through every fact in the game. */
        for(local fact = firstObj(Fact); fact != nil; fact = nextObj(fact, Fact))
        {
            /* Add each fact to our vector. */
            vec.append(fact.name);
        }
        
        /* Convert the vector to a list. */
        local lst = vec.toList();
        
        /* Store the resulting list in this listKeys() property. */
        listKeys = lst;
        
        /* Then return the list. */
        return lst;
    }
    
    /* A topic a is inversely related to a fact b if it occurs in b's topics property. */
    isInverselyRelated(a, b)
    {
        return gFact(b).topics.find(a);
    }
    
    
;

/* A Fact abuts another Fact if the two Facts share (concern) at least one topic in common. */
abutting: DerivedRelation 'abuts' @manyToMany 
    reciprocal = true

    /* Fact a abuts Fact b if their topics lists have any topics in common. */
    isRelated(a, b)
    {
        return gFact(a).topics.overlapsWith(gFact(b).topics);  
    }
    
    /* 
     *   The possible values that can appear on either side of this reciprocal relation a abuts b
     *   are all the Facts defined in the game.
     */
    listKeys()
    {
         /* Set up a new Vector for working storage. */
        local vec = new Vector();
        
        /* Iterate through every fact in the game. */
        for(local fact = firstObj(Fact); fact != nil; fact = nextObj(fact, Fact))
        {
            /* Add each fact to our vector. */
            vec.append(fact.name);
        }
        
        /* Convert the vector to a list. */
        local lst = vec.toList();
        
        /* Store the resulting list in this listKeys() property, since it shouldn't change. */
        listKeys = lst;
        
        /* Then return the list. */
        return lst;
    }   
;
   

/* 
 *   contradicting is a reciprocal relationship between Facts that are defined to contratdict each
 *   other. The library cannot determine which these are, so only provides the bare framework here.
 *   Game code then needs to define which facts oontradict by listing them on the contradicting
 *   relation's relTab property, e.g.
 *.
 *.  relTab = [
 *.       'lisbon-capital' -> ['madrid-capital'],
 *.       'jumping-silly' -> ['jumping-healthy']
 *.   ]
 */
contradicting: Relation 'contradicts'  @manyToMany +true       
;

/* 
 *   A FactAgendaItem is a specialization of a ConvAgendaItem that seeks a path from the current
 *   state of an ongoing conversation towards a target Fact or topic the associated actor wishes to
 *   reach and then attempts to follow that conversational path whenever the NPC gets the chance to
 *   take the conversational initiative.
 */
class FactAgendaItem: ConvAgendaItem
    /* The topic or fact our actor wishes to reach */
    target = nil
    
    /* Get the fact we want out path calculation to start from. */
    getStart()
    {
        local startFact = gLastFact;
        
        /* If we can't find a last mentioned fact, try starting from the last mentioned topic .*/
        if(startFact == nil)
        {
            /* 
             *   If there's no last mentioned topic, there's nothing more we can try, so return nil.
             */
            if(gLastTopic == nil)
                return nil;
            
            /* Obtained a list of facts that reference this topic. */
            local fList = related(gLastTopic, 'referenced by');
            
            /* If we succeed in obtaining such a list, return its first element. */
            if(fList && fList.length() > 0)
                startFact = fList[1];           
        }
        
        /* Return whatever start fact we found */           
        return startFact;
    }
    
    
    /* Get a path from the last fact mentioned to our target, if we can. Return nil if we can't. */
    getPath() 
    {
        /* Set up a local variable to cache our path. */
        local path = nil;
        
        /* Make our starting fact (the beginning of our path) the last fact mentioned. */
        local startFact = getStart();                 
        
       
        /* 
         *   We can only go ahead with calculating a path if we have a starting fact to calculate it
         *   from.
         */
        if(startFact)
        {
            /* 
             *   If our target is an object (Topic or Thing used as a topic) we need to find the
             *   appropriate fact to start from.
             */
            if(dataType(target) == TypeObject)                
                path = getPathToTopic(startFact);            
            
            /* 
             *   Otherwise, our target is a fact, and we simply set path to the optimum path from
             *   our starting fact to our target fact.
             */
            else                 
                path = relationPath(startFact, relations, target);
        }     
        
        /* 
         *   Save a copy of our path, including any relations it ran through if we defined the
         *   relation property as a list.
         */
        fullPath = path;
        /* If our path contains a list of lists, transform it into a simple list of facts. */
        if(path && dataType(path[1]) == TypeList)
            path = path.mapAll({x: x[2]});
        
        /* Either way, return the path we've just found. */
        return path;        
    }
    
    
    /* Get the path from a topic to our target */
    getPathToTopic(startFact)
    {
        /* First obtain a list of all the facts that reference this topic. */
        local facts = related(target, 'referenced by');
        
        /* 
         *   We want to select the fact that gives us the shortest path, so we start with a very
         *   long maximum path length to be sure that any path we find will be shorter than this.
         */
        local maxLen = 100000;
        
        /* Set uo a local variable for the path we're looking for. */
        local path = nil;
        
        /* 
         *   Iterate through all the related facts we found to identify the one that gives us the
         *   shortest path to our target
         .*/
        foreach(local fact in facts)
        {                        
            /* 
             *   Find the optimum path from the last fact mentioned to this potential target fact
             *.
             */
            local newPath = relationPath(startFact, relations, fact);
            
            /*  
             *   If we've found a path and it's shorter than any previous path, make it our
             *   provisionally chosen path and reduce the maximum path length to its path length.
             */
            if(newPath && newPath.length < maxLen)
            {
                maxLen = newPath.length;
                
                path = newPath;
            }                      
        }
        
        /* Return whatever path we found. */
        return path;
    }
    
    /* The current conversational path we're pursuing. */
    curPath = nil
    
    /* The full path, including the relationships used. */
    fullPath = nil
    
    /* 
     *   The relation or a list of relations we want to use for proximity of facts when calculating
     *   our path.
     */
    relations = abutting
   
    /* 
     *   The next step along our current path. If we have a path of at least two elemeents, the next
     *   step is the second element, otherwise we don't have a next step.
     */
    nextStep = ((curPath && curPath.length > 1) ? curPath[2] : nil)
    
    /* 
     *   Are we ready to execute? By default we are if our inherited conditions are matched and
     *   there's a next step we can take, unless we don't have a target defined, in which case just
     *   use the inherited handling.
     */
    isReady()
    {
        /* 
         *   If we have a target defined, store it in our curPath property (so we won't need to
         *   calculate it again this turn.
         */
        if(target)
            curPath = getPath();
        
        /* otherwise return our inherited value. */
        else 
            return inherited();
        
        /* We're ready is we meet the inherited conditions and we have an available next step. */
        return inherited() && nextStep != nil;
       
    }
    
    /* 
     *   We provide a default topicResponse() that triggers an appropriate InitiateTopic for the
     *   next step along our fact path, and marks this FactAgendaItem as done once we've reached the
     *   final step. Game code is free to override if you want to handle this actor's goal-seeking
     *   conversational agenda in some other way.
     */
    
    /* 
     *   By defaut we trigger the InitiateTopic corresponding to our next step, but game code can
     *   ovverride to do somethng different here is required.
     */
    invokeItem()
    {
        getActor.initiateTopic(nextStep);
    }
    
    
    /* 
     *   Our endCondition is the state we must reach for us to have reached our goal, so that we can
     *   set our isDone to true. By default this is when we've reached the end of our path, which is
     *   when our next step would be the one at the end of our path. Game could override this, say,
     *   to either gRevaled(target) or gInformed(target) or some similar condition.
     */
    endCondition = (curPath && curPath[curPath.length] == nextStep)
    
;

/* 
 *   Modification in the FACT RELATIONS Extension to allow contradictions between listed Facts to be
 *   noted. We may no attempt to say precisely where any contradictions occur, since that seems best
 *   left to the player to spot.
 */
modify FactHelper
    /* 
     *   Add a message noting contradictions (as defined by the contradicting Relation) between any
     *   two facts just listed in our response.
     */
    topicResponse()
    {
        /* Carry out the inherited handling. */
        inherited();
        
        /* 
         *   If the contradicting relation has no conflicting facts defined or we don't want to note
         *   (report on) contradictions there's nothing for us to do.
         */
        if(contradicting.relTab == nil || noteContradictions == nil)
            return;
        
        /* Set up a local variable to keep track of the number of contraditions. */
        local contradictionCount = 0;
        
        /* 
         *   Iterate through every fact in our tagList, which will be every Fact we've just
         *   displayed.
         */
        foreach(local fact in tagList)
        {
            /* 
             *   If any facts contradicting the current fact occur in our tagList, incremenent our
             *   contradiction count.
             */
            if(valToList(related(fact, contradicting)).overlapsWith(tagList))
                contradictionCount ++;
            
            /*  
             *   If we've found more than one contradiction we can stop looking (it's possible that
             *   we might want to know whether there was one or several).
             */
            if(contradictionCount > 1)
                break;
        }
        
        /* If we found any contradications, display a message to that effect. */
        if(contradictionCount > 0)
            DMsg(contradiction, '<.p>There would seem to be some contradiction {here}.<.p>');
        
        
    }
    
    /* 
     *   Do we actually want to note (i.e. report on) the presence of contradictions here? By
     *   default we do but game code can override.
     */
    noteContradictions = true
;

modify ActorTopicEntry
    
    /* 
     *   If we like, we can specify a particuler FactAgendaItem to use in conjunction with this
     *   ActorTopicEntry. But note that if autoUseAgenda is true the AgendaItem we specify here will
     *   be ignored unless useAgenda() can't find a suitable AgendaItem.
     */
    agenda = nil
    
    /* 
     *   Do we want the ActorTopicEntry to find an appropriate FactAgendaItem for us? By default we
     *   don't. This should only be set to true on ActorTopicEntries that are going to make use of
     *   FactAgendaItem path information.
     */
    autoUseAgenda = nil
    
    useAgenda()
    {
        /* Don't do anything here if we don't want to reference an associated FactAgendaItem */
        if(agenda == nil && autoUseAgenda == nil)
            return nil;
        
        /* Setup the starting position for our agenda's path calculation. */
        if(objOfKind(topicMatched, Topic) || objOfKind(topicMatched, Thing))
            libGlobal.lastTopicMentioned = topicMatched;
        
        local formerFact = libGlobal.lastFactMentioned;
        
        try 
        {
            /* 
             *   Ensure it uses the latest topic rather than any legacy fact matched, unless the
             *   last fact matched is referenced by the topic we just matched, in which case we may
             *   as well retain it.
             */             
            if(related(gLastFact, 'referenced by').indexOf(topicMatched) == nil)
                libGlobal.lastFactMentioned = nil;
            
            /* 
             *   If we don't want to find a suitable AgendaItem automatically, use the one defined
             *   on our agenda property.
             */
            if(!autoUseAgenda)
                return agenda;
            
            /* 
             *   Obtain a ready FactAgendaItem from our actor's agendaList (in all likelihood there
             *   won't be more than one at any one time).
             */
            local ag = getActor().agendaList.valWhich({x: x.ofKind(FactAgendaItem) && x.isReady});
            
            /* 
             *   If we found a suitable FactAgendaItem, return it, otherwise return the AgendaItems
             *   specified on our agenda property.
             */                
            return ag ?? agenda;
        }
        finally
        {
            libGlobal.lastFactMentioned = formerFact;
        }
            
    }
    
    baseHandleTopic()
    {
        if(agenda || autoUseAgenda)
        {
            /* Obtain the AgendaItem we wish to use with this ActorTopicEntry */
            local ag = useAgenda();
            
            /* Check that ag is a FactAgendaItem before trying to work with it. */
            if(objOfKind(ag, FactAgendaItem))
            {                
                /* 
                 *   If ag can provide a path from our topic to its target, set our own next step
                 *   and agendaPath to those of ag.
                 */
                agendaPath = ag.getPath();
                    
                nextStep = ag.nextStep;   
            }
            else
            {
                /* Otherwise reset our nextStep and agendaPath to nil */
                nextStep = nil;
                
                agendaPath = nil;                
            }
        }
        
        inherited();
    }
    
    /* 
     *   The next step (next fact) our associated FactAgendaItem would like us to use. We can use
     *   this to tailor our topicResponse as we see fit, which could include responding with our
     *   nextStep's description, or could be something more subtle.
     */
    nextStep = nil
    
    /* 
     *   The path out associated FactAgendaItem wants to take. This will be a list of fact name
     *   tags.
     */
    agendaPath = nil
;

/* Modifications to AltTopic to work with FACT RELATIONS modifications to ActorTopicEntry */
modify AltTopic
    agenda = location.agenda
    autoUseAgenda = location.autoUseAgenda
;

/* Modification to Actor to work better with Fact Relations extension */
modify Actor
    /* 
     *   We need to update gLastTopic so that any FactAgendaItem can reference it when checking its
     *   isReady property before any TopicEntry has handled the topic.
     */
    handleTopic(prop, topic, defaultProp = &noResponseMsg)
    {
        /* Store a referece to topic, which will be a list at this stage */
        local top = topic;
        
        /* topic has probably been passed as a list. */
        if(dataType(topic) == TypeList)
        {
            /* If so prefer an element of the list that hasn't just been created by the parser. */
            top = topic.valWhich({t:!t.newlyCreated});
            
            /* If we found one, choose it, otherwwise select the first element in the list. */
            top = top ?? topic[1];
        }
         
        /* Updte gLastTopic */
        gLastTopic = top;
        
        /* Then carry out the inherited handling and return the result. */ 
        return inherited(prop, topic, defaultProp);
    }
;