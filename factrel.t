#charset "us-ascii"
#include "advlite.h"

/* 
 *   FACT RELATIONS EXTENSION by Eric Eve July 2014
 *
 *   The relations.t extension allows Inform7-style relations to be
 *   defined in a TADS 3 game.
 */


concerning: DerivedRelation 'concerns' 'referenced by' @manyToMany
    relatedTo(a)
    {
        return gFact(a).topics;        
    }
    
    listKeys()
    {
        local vec = new Vector();
        
        for(local fact = firstObj(Fact); fact != nil; fact = nextObj(fact, Fact))
        {
            vec.append(fact.name);
        }
        local lst = vec.toList();
        
        listKeys = lst;
        
        return lst;
    }
    
    isInverselyRelated(a, b)
    {
        return gFact(b).topics.find(a);
    }
    
    
;

/* A Fact abuts another Fact if the two Facts share (concern) at least one topic in common. */
abutting: DerivedRelation 'abuts' @manyToMany 
    reciprocal = true

    
    isRelated(a, b)
    {
        return gFact(a).topics.overlapsWith(gFact(b).topics);  
    }
    
    listKeys()
    {
        local vec = new Vector();
        
        for(local fact = firstObj(Fact); fact != nil; fact = nextObj(fact, Fact))
        {
            vec.append(fact.name);
        }
        local lst = vec.toList();
        
        listKeys = lst;
        
        return lst;
    }
    
   
;

contradicting: Relation 'contradicts'  @manyToMany +true
       
;


class FactAgendaItem: ConvAgendaItem
    /* The topic or fact our actor wishes to reach */
    target = nil
    
     
    /* Get a path from the last fact mentioned to our target, if we can. Return nil if we can't. */
    getPath()
    {
        /* Set up a local variable to cache our path. */
        local path = nil;
        
        /* Make our starting fact (the beginning of our path) the last fact mentioned. */
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
            local fList = related(startFact, 'referenced by');
            
            /* If we succeed in obtaining such a list, return its first element. */
            if(fList && fList.length() > 0)
                startFact = fList[1];
            
            /* Otherwise there's nothing more we can try, so return nil. */
            else
                return nil;
        }
            
        
        /* 
         *   If our target is an object (Topic or Thing used as a topic) we need to find the
         *   appropriate fact to start from.
         */
        if(dataType(target) == TypeObject)
        {
            /* First obtain a list of all the facts that reference this topic. */
            local facts = related(target, 'referenced by');
                      
            /* 
             *   We want to select the fact that gives us the shortest path, so we start with a very
             *   long maximum path length to be sure that any path we find will be shorter than
             *   this.
             */
            local maxLen = 100000;
            
            /* 
             *   Iterate through all the related facts we found to identify the one that gives us
             *   the shortest path to our target
             .*/
            foreach(local fact in facts)
            {
                /* 
                 *   Find the optimum path from the last fact mentioned to this potential target
                 *   fact
                 *.
                 */
                local newPath = relationPath(startFact, abutting, fact);
                
                /*  
                 *   If we've found a path and it's shorter than any previous path, make it our
                 *   provisionally chosen path and reduce the maximum path length to its path
                 *   length.
                 */
                if(newPath && newPath.length < maxLen)
                {
                    maxLen = newPath.length;
                    
                    path = newPath;
                }                      
            }
        }
        /* 
         *   Otherwise, our target is a fact, and we simply set path to the optimum path from our
         *   starting fact to our target fact.
         */
        else
        {
            path = relationPath(gLastFact, abutting, target);
        }
        
        /* Either way, return the path we've just found. */
        return path;
        
    }
    
    /* The current conversational path we're pursuing. */
    curPath = nil
    
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
    invokeItem()
    {
        /* If we have a current path and we've reached its final step, we're done. */
        if(curPath && curPath.length == 1)
            isDone = nil;
        
        /* Otherwise trigger the InitiateTopic corresponding to our next step. */
        else
            getActor.initiateTopic(nextStep);
        
        /* If our next step is also the last one, we're done. */
        if(endCondition)
           isDone = true;
        
    }
    
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
    
