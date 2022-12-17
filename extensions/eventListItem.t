#charset "us-ascii"
#include "advlite.h"

/*
 *   EventListItem Extension
 *.  Version 1.1 17-Dec-2022
 *.  By Eric Eve based on work by John Ziegler
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
        
        // automatically remove if we have exceeded our maxFireCt or met our doneWhen condition
        if((maxFireCt && fireCt >= maxFireCt) || doneWhen)
            setDone(); 
        
        /*  Delay our next use until at least minInterval turns have elapsed. */
        setDelay(minInterval);
        
        /* Reset our missed turn flag to nil as we haven't missed this turn. */
        missedTurn = nil;
    }
    
    /* 
     *   Here goes the code (or a double-quoted string) that carries out what we do when we're
     *   invoked. Game code will need to define what should happen here.
     */
    invokeItem()
    {
    }
    
    /* 
     *   This first turn on which we came up in our EventList but were unable to fire, or nil if we
     *   have either not missed or turn or fired on the previous occasion we could.
     */
    missedTurn = nil
    
    
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
        
        /* 
         *   Unless we're done or we've already noted a missed turn, note that we missed our chance
         *   to fire with our own response this turn.
         */
        if(!isDone && missedTurn == nil)
            missedTurn = gTurns;
    }
    
    /* 
     *   The response to use if all else fails, that is if there we cannot fire ourselves and there
     *   is no non-EventListItem (which could be used in our place) in the eventList to which we
     *   belong. This could, for exmple, display another message or it could just do nothing, which
     *   is the default. We only need to supply something here if we belong to an EventList that
     *   should display something every turn, for example as a response to a DefaultTopic or else if
     *   we are or may be the final item in a StopEventList.
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
        return isReady && !isDone && gTurns >= readyTime;
    }
    
    /* Have we finished with this EventListItem? */
    isDone = nil
    
    /* Set this EventListItem as having been done */
    setDone() 
    { 
        isDone = true;                    
    }
           
    /* The number of times this EventListItem has fired. */
    fireCt = 0
     
    /* 
     *   Flag: can this EventListItem be removed from its eventList once isDone = true? By default
     *   it can, but note that this flag only has any effect when our EventList's resetEachCycle
     *   property is true. We might want to set this to nil if isDone might become nil again on this
     *   EventListItem, to avoid it being cleared out of its eventList.
     */
    canRemoveWhenDone = true
    
    /* 
     *   The maximum number of times we want this EventListItem to fire. The default value of nil
     *   means that this EventListItem can fire an unlimited unmber of times. For an EventListItem
     *   that fires only once, set maxFireCt to 1 or use the ELI1 subclass.
     */
    maxFireCt = nil
    
    /*   
     *   An alternative condition (which could be defined as a method) which, if true, causes this
     *   EventListItem to be finished with (set to isDone = true). Note that isDone will be set to
     *   try either if this EventListItem exceeds its maaFireCt or if its doneWhen method/property
     *   evaluates to true.
     */
    doneWhen = nil
    
    /* The last turn on which this EventListItem fired */
    lastClock = 0
    
    /* 
     *   The turn count that must be reached before we're ready to fire. By default this is 0, but
     *   game code can use this or set the setDelay() method to set/reset it.
     */
    readyTime = 0
    
    /*  The minimum interval (in number of turns) between repeated occurrences of this item. */
    minInterval = 0
    
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
    
    /* 
     *   Has this EventListItem been underused? By default it has if it hasn't been used at all or
     *   it missed out the last time it was called by not being ready, but game code can override if
     *   it wants to employ some other condition, such as the number of times we've been used in
     *   relation to other items in our listObj. The purpose of this is to allow RandomFiringScripts
     *   to prioritize underused EventListItems once they become ready to fire.
     */
    underused()
    {
        /* 
         *   By default we're underused if we've we've missed a turn on which we would have fired
         *   had we been ready to, but game code can override this to some other condition if
         *   desired, such as testing whether fireCt == 0
         */
        return (missedTurn != nil);
    }
    
    
    /* 
     *   Add this EventListItem to the whichList list of myListObj_. If specificied, whichList must
     *   be supplied as a property, and otherwise defaults to &eventList. A minimium interval
     *   between firings of this EventList item can optionally be specified in the minInterval_
     *   parameter, but there is no need to do this if this EventList already defines its own
     *   minInterval or doesn't require one.
     */
    addToList(myListObj_, whichList_ = &eventList, minInterval_?)
    {
        /* Store our parameters in the appropriate properties. */
        myListObj = myListObj_;
        
        whichList = whichList_;
        
        if(minInterval_)
            minInterval = minInterval_;
        
        /* Get our list object to add us to its appropriate list property. */
        myListObj.addItem(self, whichList);
               
    }
;



/* 
 *   Short form EventListItem class names for the convenience of game authors who want to save
 *   typing.
 */
class ELI: EventListItem;


/* A one-off EventListItem */
class ELI1: EventListItem
    maxFireCt = 1
;


modify EventList
    
    /* 
     *   Game code can call this method to remove all EventListItems that have been finished with
     *   (isDone = true) from the eventList of this EventList. This probably isn't necessary unless
     *   there are likely to be a large number of such items slowing down execution.
     */
    resetList()
    {
        /* 
         *   Reduce our eventList to exclude items that are EventListItems for which isDone is true
         *   and the canRemoveWhenDone flag is true.
         */        
        self.eventList = self.eventList.subset({x: !(objOfKind(x, EventListItem) && x.isDone &&
            x.canRemoveWhenDone)});
        
        /* Recache our eventList's new length. */
        eventListLen = eventList.length();                                                
    }
    
    /* 
     *   Flag, do we want to reset the list each time we've run through all our items? By default we
     *   don't, but this might ba en appropriate place to call resetList() if we do want to call it.
     *   Note that this is in any case irrelevant on the base EventList class but may be relevant on
     *   some of its subclaases (CyclicEventList, RandomEventList and ShuffledEventList).
     */
    resetEachCycle = nil
    
    /* 
     *   Add an item to prop (usually eventList) property of this EventList, where prop should be
     *   supplied as a property pointer,
     */
    addItem(item, prop)
    {
        /* Add the item to the specified list. */
        self.(prop) += item;
        
        /* Chache our new eventList length. */
        eventListLen = eventList.length;
    }
       
;

modify CyclicEventList
    advanceState()
    {
        /* 
         *   If we want to reset our eventList each cycle to clear out any spent EventListItems and
         *   our current script state has reache our eventList's length (so that we're at the end of
         *   a cycle), then call our resetList() method.
         */
        if(resetEachCycle && curScriptState >= eventListLen)
            resetList();
        
        
        /* Carry out the inherited handling */
        inherited();
    }
;

/* Mofiications to ShuffledEventList for EventListItem extension */
modify ShuffledEventList
        
    /* 
     *   For the EventListItem extenstion we modify this method so that it first chooses any as yet
     *   unused EventListItem from our eventList that's now ready to fire. If none is found, we use
     *   the inherited behaviour to select the next item indicated by our shuffledList_ .
     */
    getNextRandom()
    {       
        /* 
         *   If we want to clear up isDone items and we have a shuffledList_ and that list has no
         *   more values available, then reset our list to remove the isDone items.
         */
        if(resetEachCycle && shuffledList_ && shuffledList_.valuesAvail == 0)
            resetList();           
        
        
        /* 
         *   If we have an underused EventListItem that's ready to fire, choose that.
         */          
        local idx = underusedReadyELIidx();
        
        /* 
         *   If we found a suitable value and idx is not nil, return idx. Otherwise use the
         *   inherited value
         */
        return idx ?? inherited();
    }
    
    /* 
     *   Reset our eventList to clear out EventListItems that are done with (isDone = true). This is
     *   not called from any library code by default, but can be called from game code if game
     *   authors are worried about an accumulation of too many spent EventListItems in any given
     *   eventList. For many games, this probably won't be necessary.
     *
     *   One potentially good place to call this from as at the end of each iteration of a
     *   ShuffledEventList, when the items are about to be reshuffled in any case. You can make this
     *   happen by setting the resetOnReshuffle property to true,
     */
    resetList()
    {
        /* Carry out the inherited handling */
        inherited();
        
        /* 
         *   recreate our shuffled integer list, since the existing one may index items that no
         *   lomger exist in our eventList.
         */
        shuffledList_ = new ShuffledIntegerList(1, eventListLen);
        
        /* apply our suppressRepeats option to the shuffled list */
        shuffledList_.suppressRepeats = suppressRepeats;
    }
    
    
    addItem(item, prop)
    {
        /* Carry out the inherited handling */
        inherited(item, prop);
        
        /* Reset our list to include the item we've just added and clear out any spent ones. */
        resetList();
    }
    
;


modify RandomEventList
    /*
     *   Get the next random state.  By default, we simply return a number from 1 to the number of
     *   entries in our event list.  This is a separate method to allow subclasses to customize the
     *   way the random number is selected. However, if we have an unused EventListItem that's ready
     *   to fire, we select that instead, to make sure it gets a look-in at the earliest possible
     *   opportunity.
     */
    getNextRandom()
    {
        /* 
         *   For a RandomEventList we regard a 'cycle' as being the firing of the number of items in
         *   the eventList (regardless of whether each individual item has been fired). So we
         *   increment our fireCt each time we're called, and then reset it to zero once it reaches
         *   our eventLiatLen. Then, if thie RandeomEventList wants to resetEachCycle, we clear out
         *   any spent EventListItems.
         */         
        if(++fireCt >= eventListLen)
        {
            /* Reset our fireCt to zero */
            fireCt = 0;
            
            /* 
             *   Call resetList() to clear out any spent EventListItems if we want to reset each
             *   cycle.
             */
            if(resetEachCycle)
                resetList();
        }
        
        /* 
         *   If we have an underused EventListItem that's ready to fire, choose that
         */        
        local idx = underusedReadyELIidx();
        
         /* 
          *   If we found a suitable value and idx is not nil, return idx. Otherwise use the
          *   inherited value
          */
        return idx ?? inherited();
    }
    
    /* The number of times we have fired on this 'cycle '*/
    fireCt = 0
;

modify RandomFiringScript    
    /* 
     *   Return the index within our eventList of any as yet unused EventListItem that's ready to
     *   fire. This is principally for the use of our RandomEventList and ShuffledEventList
     *   subclasses.
     */
    underusedReadyELIidx()    
    {
        /* Extract a subset list of EventListItems that can fire and are underused. */
        local lst = eventList.subset({x: objOfKind(x, EventListItem) && x.canFire()
                                        && x.missedTurn && x.underused()});
        
        /* If the list is empty, we have no underused EventListItem ready to fire, so return nil. */
        if(lst.length < 1)
            return nil;
        
        /* Sort the list in ascendcing order of their missedTurns. */
        lst = lst.sort({a, b: a.missedTurn - b.missedTurn});
        
        /* 
         *   Return the index of the first element in the list, which will be the one that missed
         *   its turn longest ago.
         */
        return eventList.indexOf(lst[1]); 
    }           
;