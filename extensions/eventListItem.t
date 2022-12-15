#charset "us-ascii"
#include "advlite.h"

/*
 *   EventListItem Extension
 *.  Version 1.0 15-Dec-2022
 *.  By Eric Eve based on work by Zohn Ziegler
 */


/* 
 *   An EventListItem is an object that can be used within an EventList but is only used when
 *   certain conditions are met (its isReady property evaluates to true, the game clock time is at
 *   or after any next firing time we have defined, and it hasn't already been used for any maximum
 *   number of times we care to define).
 *
 *   EventListItems can be added to a regular EventList object by locating them within that object
 *   using the + notation. [EVENTLISTITEM EXTENSION]
 *
 */
class EventListItem: PreinitObject
    /* 
     *   Add this EventListItem to the eventList of the EventList object with which is is to be
     *   associated.
     */
    execute()
    {
        /*
         *   if myListObj is defined, add us to that EventList object. whichList is by default
         *   &eventList, but this could be changed to &firstEvents or some other custom property
         */
        if(myListObj) 
            myListObj.(whichList) += self;
        
        /* 
         *   if we don't specify myListObj but we have a location, add us to our
         *   location.(whichList)
         */
        else if(location && 
                location.propDefined(whichList) && 
                location.(whichList)!=nil && 
                location.(whichList).ofKind(Collection)) 
        {
            location.(whichList) += self;
            myListObj = location; 
        }
    }
    
    /* 
     *   we usually want to add objects to a ShuffledEventList's eventList property, but
     *   items/subclasses could change this to be added to firstEvents or some other alternate list
     *   within the EventList object
     */
    whichList = &eventList
    
    /* 
     *   The EventList object to which we are to belong. If this is left at nil, our location will
     *   be used.
     */
    myListObj = nil
    
    /* 
     *   When the event list to which we've been added gets to us, it will call our doScript()
     *   method, so we use that to define what happens.
     */
    doScript()
    {
        /* If we're in a position to fire, then carry out our invocation. */
        if(canFire())
        {
            _invokeItem();
            
            /* If we've been mixed in with an EventList class, call the inherited handling. */
            if(ofKind(Script))
                inherited();
        }
        
        /* Otherwise, use our fallback routine. */
        else
            fallBack();
    }
    
    
    _invokeItem() 
    { 
        invokeItem(); 
        
        //keep track of how many times this item has shown
        ++fireCt;
        
        //keep track of when we fired last
        lastClock = gTurns;
        
        // automatically remove if we have exceeded our maxFireCt
        if(maxFireCt && fireCt >= maxFireCt) 
            setDone(); 
    }
    
    /* 
     *   Here goes the code (or a double-quoted string) that carries out what we do when we're
     *   invoked. Game code will need to define what should happen here.
     */
    invokeItem()
    {
    }
    
    
    /* 
     *   The method that defines what this EventListItem does if it's invoked when it's not ready to
     *   fire.
     */
    fallBack()
    {
        /* 
         *   If possible, get our myListObj to use the next item in its list, so that it behaves as
         *   if we werem't here. However, we need to make sure it's safe to do that without getting
         *   into an infinite loop, so to be on the safe side we check (1) that there's at least one
         *   item in the list which our myListObj could invoke (i.e. something that's not an
         *   EventListItem that can't fire) and (2) that myListOnj is not a StopEventList that's
         *   reached its end, which might then repeatedly try to invoke us.
         */
        if(myListObj.(whichList).indexWhich({x: !(x.ofKind(EventListItem) && !x.canFire())})
           && !(myListObj.ofKind(StopEventList)&& myListObj.curScriptState >= eventListLen))        
            myListObj.doScript();
        
        /* Otherwise, use our fallBackResponse */
        else
            fallBackResponse();
    }
    
    /* 
     *   The response to use if all else fails, that is if there we cannot fire ourselves and there
     *   is no non-EventListItem (which could be used in our place) in the eventList to which we
     *   belong. This could, for exmple, display another message or it could just do nothing, which
     *   is the default.
     */
    fallBackResponse() { }
    
    
    /* 
     *   Is this EventListItem ready to fire? Note that this is addition to its not being done and
     *   having reached its ready time.
     */
    isReady = true
    
    /*  
     *   Can this EventListItem item fire? By default it can if its isReady condition is true and it
     *   is not already done (isDone != true) and the turn count exceeds its ready time.
     */
    canFire()
    {
        return isReady && !isDone && gTurns > readyTime;
    }
    
    /* Have we finished with this EventListItem? */
    isDone = nil
    
    /* Set this EventListItem as having been done */
    setDone() 
    { 
        isDone = true; 
        
        if(removeOnDone)
            myListObj.removeItem(self, whichList);
    }
    
    /* 
     *   Should we remove this item from its eventList once it's done? This probably isn't necessary
     *   unless we're using a large number of EventListItems in any given eventList, and it may not
     *   always be desirable, so we'll set the default to nil, but game code can override this to
     *   true if needed for performance reasons with large numbers of EventListItems.
     */
    removeOnDone = nil
    
    /* The number of times this EventListItem has fired. */
    fireCt = 0
    
    
    
    
    /* 
     *   The maximum number of times we want this EventListItem to fire. The default value of nil
     *   means that this EventListItem can fire an unlimited unmber of times. For an EventListItem
     *   that fires only once, set maxFireCt to 1 or use the ELI1 subclass.
     */
    maxFireCt = nil
    
    /* The last turn on which this EventListItem fired */
    lastClock = 0
    
    /* 
     *   The turn count that must be reached before we're ready to fire. By default this is 0, but
     *   game code can use this or set the setDelay() method to set/reset it.
     */
    readyTime = 0
    
    /*   
     *   Set the number of turns until this EventListItem can be used again. This could, for
     *   example, be called from invokeItem() to set a minimum interval before this EventListItem is
     *   repeated.
     */
    setDelay(turns)    
    {
        readyTime = gTurns + turns;
        return self;    
    }
    
    /* Get the actor with which we're associated if we have one. */
    getActor 
    { 
        local obj = [location, myListObj].valWhich({x:x && (x.ofKind(ActorState) || 
            x.ofKind(Actor) || x.ofKind(AgendaItem)) });
        if(obj) 
            return obj.getActor;
        else 
            return nil; 
    }
;



/* 
 *   Short form EventListItem class names for the convenience of game authors who want to save
 *   typing. */

class ELI: EventListItem;


/* A one-off EventListItem */
class ELI1: EventListItem
    maxFireCt = nil
;


/* Mofiications to EventList for EventListItem extension */
modify EventList
    removeItem(item, listProp)
    {
        /* remove item from the appropriate list */
        self.(listProp) -= item;
        
        /* cache the new length */
        if(listProp == &eventList)
            eventListLen = eventList.length();      
        
    }
;

/* Mofiications to ShuffledEventList for EventListItem extension */
modify ShuffledEventList
    removeItem(item, listProp)
    {
        /* call the inherited handling */
        inherited(item, listProp);
        
        /* 
         *   create a new shuffled integer list - we'll use these shuffled integers as indices into
         *   our event list
         */
        shuffledList_ = new ShuffledIntegerList(1, eventListLen);
        
        /* apply our suppressRepeats option to the shuffled list */
        shuffledList_.suppressRepeats = suppressRepeats;
    }
;
