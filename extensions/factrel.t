#charset "us-ascii"
#include "advlite.h"

/* 
 *   FACT RELATIONS EXTENSION by Eric Eve
 *
 *   Version 1.1 22nd April 2024
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
        if(gFact(a) == nil)
            return [];
        
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
        if(gFact(b) == nil)
            return nil;
        
        return gFact(b).topics.find(a);
    }    
;

/* A Fact abuts another Fact if the two Facts share (concern) at least one topic in common. */
abutting: DerivedRelation 'abuts' @manyToMany 
    reciprocal = true

    /* Fact a abuts Fact b if their topics lists have any topics in common. */
    isRelated(a, b)
    {
        if(!gFact(a) || !gFact(b) )
            return nil;
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
 *   BeliefRelation is the base class for a group of six relations that test whether Actors (and/or
 *   Consultables) assess the facts they know about in particular ways.
 */
BeliefRelation: DerivedRelation
    /* 
     *   Actor a is related to fact b if b is present as a key in a's informedNameTab with a value
     *   of status (true, likely, dubious, unlikely, or untruy). The a parameter is the Thing (Actor
     *   or Consultable) that potentially knows of the fact in question and b is the fact string-tag
     *   representing the fact.
     */
    isRelated(a, b)
    {
        return a.informedNameTab && a.informedNameTab[b] == status;
    }
    
    /* a is inversely  related to b if b is related to a. */
    isInverselyRelated(a, b)
    {
        return isRelated(b, a);
    }
    
    /* 
     *   We can make this relation hold between obj{1] and obj{2] if we set obj{2} to status on
     *   obj{1].
     */
    addRelation(objs)
    {
        objs[1].setInformed(objs[2], status);
    }
    
    /* 
     *   Obtain the list of fact tags related  to a, which is the subset of keys in a's
     *   informedNameTab for which a is related to be.
     */
    relatedTo(a) 
    {         
        return a.informedNameTab.keysToList().subset({b: isRelated(a, b)});
    }
    
    /* Obtain the list of Things that are inversely related to fact tag a */
    inverselyRelatedTo(a)
    {
        /* Set up a new vector for working storage of the list we're building. */
        local vec = new Vector();
        
        /* Interate through every Thing in the game. */
        for(obj = firstObj(Thing); obj != nil; obj = nextObj(obj, Thing))
        {
            /* If obj (the current Thing) is related to a, add it to our Vector. */
            if(isRelated(obj, a))
                vec.append(obj);
        }
        
        /* Convert our vector to a list and return the result. */
        return vec.toList();
    }
    
    /* 
     *   The belief status (true, likely, dubious, unlikely, or untrue) that we want this relation
     *   to test for.
     */
    status = nil
;


/* Tests relation between Actors/Consultables and the facts they believe to be true. */
believing:BeliefRelation 'believes' 'believed by' @manyToMany
   status = true   
;

/* Tests relation between Actors/Consultables and the facts they believe to be untrue. */
disbelieving:BeliefRelation 'disbelieves' 'disbelieved by' @manyToMany
    status = untrue    
;

/* Tests relation between Actors/Consultables and the facts they believe to be likely. */
consideringLikely: BeliefRelation 'considers likely' 'considered likely by' @manyToMany
    status = likely
;

/* Tests relation between Actors/Consultables and the facts they believe to be dubious. */
doubting: BeliefRelation  'doubts' 'doubted by' @manyToMany
    status = dubious
;

/* Tests relation between Actors/Consultables and the facts they believe to be unlikely. */
consideringUnlikely: BeliefRelation 'considers unlikely' 'considered unlikely by' @manyToMany
    status =  unlikely
;

/* 
 *   Tests relation between Actors/Consultables and the facts they believe to be uncertain, i.e.,
 *   likely, dubious or unlikely.
 */ 
wondering: BeliefRelation 'wonders if' 'wondered about' @manyToMany
    /* 
     *   Actor or Consultable is related to fact b through this relation if the value corresponding
     *   to key b on a's informedNameTab is either likely, dubious, or unlikely.
     */
    isRelated(a, b)
    {
        return a.informedNameTab && a.informedNameTab[b] is in (likely, dubious, unlikely);
    }
    
    addRelation(objs)
    {
        inherited DerivedRelation(objs);
    }  
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
//    nextStep = ((curPath && curPath.length > 1) ? curPath[2] : nil)
    
    /* 
     *   If we have been called by a DefaultAgendaTopic, it will be neater if what we display is
     *   related to the topic the DefaultAgendaTopic just matched, so we attempt to find a nextStep
     *   that meets this condition.
     */
    nextStep()
    {
        /* We need only try to do this if we've just been called by a DefaultAgendaTopic */
        if(calledBy && calledBy.ofKind(DefaultAgendaTopic))
        {
            /* 
             *   Try to find the latest step (fact name) in our current path that relates to the
             *   topic just matched by our caller.
             */
            local step = curPath.lastValWhich({x: gFact(x).topics.indexOf(calledBy.topicMatched)});
            
            /*  If we found one, return it. */
            if(step)
                return step;
        }
        
        /* Otherwise, return the next step along our path. */
        return ((curPath && curPath.length > 1) ? curPath[2] : nil);
    }
    
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
    
    /* The object that called us */
    calledBy = nil
    
    invokeItemBase(caller)
    {
        /* Store a reference to our called */
        calledBy = caller;
        
        /* Carry out the inherited handling. */
        inherited(caller);
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
 
    /* 
     *   Reset this FactAgendaItem so that it can be used again. If the optional target_ parameter
     *   is supplied, we'll set the our target to the new target_.
     */
    reset(target_?)
    {
        /* 
         *   Provided that isDone is simply true (rather than a method or expression that might
         *   evaluate to true) reset it to nil.
         */
        if(propType(&isDone) == TypeTrue)
            isDone = nil;
        
        /* If the target_ parament has been supplied, set our target property to target_ .*/
        if(target_)
            target = target_;
    }
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
        local agenda_ = agenda;
        try
        {
            if(agenda || autoUseAgenda)
            {
                /* Obtain the AgendaItem we wish to use with this ActorTopicEntry */
                local ag = useAgenda();
                
                /* Check that ag is a FactAgendaItem before trying to work with it. */
                if(objOfKind(ag, FactAgendaItem))
                {                
                    /* 
                     *   If ag can provide a path from our topic to its target, set our own next
                     *   step and agendaPath to those of ag.
                     */
                    agendaPath = ag.getPath();
                    
                    nextStep = ag.nextStep;   
                    
                    agenda = ag;
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
        finally
        {
            agenda = agenda_;
        }
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
    
    tryNextStep()
    {
        if(nextStep)
        {
            if(getActor.initiateTopic(nextStep))
                return true;            
        }
        return nil;
    }
    
    tryAgenda()
    {
        return getActor.executeAgenda();
    }
    
    
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

modify Thing
    setInformed(tag, val?)
    {
        /* Carry out the inherited handling */
        inherited(tag, val);       
        
        /* 
         *   Then check for contradictions betwen the new piece of information (tag) and information
         *   we already know about.
         */
        checkForContradictions(tag, val);
    }
    
    /* 
     *   Check for contradictions betwen the new piece of information (tag) and information we
     *   already know about.
     */
    checkForContradictions(tag, val)
    {
        /* Get the fact corresponding to tag. */
        local fact = gFact(tag);
        
        /* If we don't find a fact or our informedTab is empty, there's nothing left to do. */
        if(fact == nil || informedNameTab == nil)
            return;
        
        /* Obtain a list of all the facts we've been informed of. */
        local factList = informedNameTab.keysToList().subset({x: informedNameTab[x] != nil});
        
        /* 
         *   Reduce this to the list of facts that contradict tag (the new fact name we've just been
         *   informed of.
         */
        factList = factList.subset({x: related(tag, contradicting, x) });
        
        /* If we found any, mark tag as dubious and call our notifyContrediction method. */
        if(factList.length > 0 && val == nil)
        {
            /* Mark this item of information as dubious */
//            informedNameTab[tag] = dubious;   
            
            markContradiction(tag, factList);
            
            /* Call our notifyContradiction method. */
            notifyContradiction(tag, factList);
        }
    }
    /* 
     *   Mark the incoming 'fact' denoted by tag as either untrue, unlikely, or dubious, depending
     *   on what it contradicts .
     */
    markContradiction(tag, factList)
    {
        /* 
         *   If tag contradicts a fact we believe to be true, we presumably believe tag to be untrue
         */
        if(factList.indexWhich({x: informedNameTab[x] == true}))
            informedNameTab[tag] = untrue;
        else
        {
            /* 
             *   Otherwise if tag contradicts a fact we believe to be likely, we presumably believe
             *   tag to be unlikely.
             */
            if(factList.indexWhich({x: informedNameTab[x] == likely}))
                informedNameTab[tag] = unlikely;
            else
                /* 
                 *   Otherwise we consiser tag to be dubious (that tag contradcts a fact we regard
                 *   as either dubious, unlikely or untrue says little about how we regard tag - two
                 *   muutally contradictory facts could easily both be untrue, unlikely, or dubious.
                 */
                informedNameTab[tag] = dubious;
        }
    }
    
    /* 
     *   Receive a notification that we've just been informed of a Fact that contradicts another
     *   fact we already know or have been informed of. We don't do anything here by default; it's
     *   up to game code to impelement any response required.
     */
    notifyContradiction(fact, factList)
    {
    }
;