#charset "us-ascii"
#include "advlite.h"

/*--------------------------------------------------------*/
/*
 *   SIGNAL EXTENSION Still at an experimental stage
 *
 *   To use this extension, include the relations extensions before it.
 */

/* 
 *   A Signal is a kind of Relation that can be used to send a signal from a
 *   sender to all the objects related to that sender via this Signal Relation.
 *
 *   For a signal to be sent from a sender to a receiver, a relationship first
 *   needs to be set up between them with a statement like:
 *
 *   connect(sender, signal, receiver);
 *
 *   Where signal is either the programmatic name or the string name of the
 *   signal we want sent.
 *
 *   To break the link subsequently we can use:
 *
 *   unconnect(sender, signal, receiver);
 */
Signal: Relation
    /* Signals can potentially relate many things to many other things. */
    relationType = manyToMany
    
    /* 
     *   Notify every object related to sender by us to handle us as a signal
     *   from sender.
     *
     *   If additional args are supplied, they can take one of two forms. Either
     *   values, which are then assigned in turn to the properties listed in our
     *   propList property, or two-element lists of the form [prop, val] where
     *   prop is a property pointer and val is the value to be assigned to this
     *   property. Note that these two forms cannot be mixed in the same call to
     *   this method, unless all the list form arguments come at the end.
     */
    emit(sender, [args])   
    {
        local prop, val;
        
        /* 
         *   Clear out any property values left over from a previous call. We
         *   use null rather than nil as the 'cleared' value, since in some
         *   cases (e.g. in a moveSignal) nil could be a significant value.
         */
        propList.forEach({p: self.(p) = null });
        
        /* Assign additional arguments to properties. */
        for(local arg in args, local i=1;; i++)       
        {           
            /* 
             *   If each arg is a list, then the first item in the list is a
             *   property pointer, and the second is the value to assign to that
             *   property.
             */
            if(dataType(arg) == TypeList)
            {
               prop = arg[1];
               val = arg[2];
            }
            /*  
             *   Otherwise arg is just a value, which is assigned to the
             *   property found in the next element of propList.
             */
            else
            {
                val = arg;
                prop = propList[i];
            }
            self.(prop) = val;
        }
        
        relatedTo(sender).forEach({ obj: obj.dispatchSignal(sender, self) });
    }
    
    /* 
     *   A list of pointers to the properties to which additional arguments to
     *   our emit method should be assigned.
     */
    propList = []
    
    dispatchTab = nil
    
    addHandler(sender, receiver, handler)
    {
        if(dispatchTab == nil)
            dispatchTab = new LookupTable();
        
        dispatchTab[[sender, receiver]] = handler;
    }
    
    removeHandler(sender, receiver)
    {
        if(dispatchTab != nil)
        {
            dispatchTab.removeElement([sender, receiver]);
        }
    }
    
;



/* Signals to handle common state changes on Thing */
DefSignal(lit, lit);
DefSignal(unlit, unlit);
DefSignal(discover, discovered);
DefSignal(undiscover, lost);
DefSignal(lock, locked);
DefSignal(unlock, unlocked);
DefSignal(on, turned on);
DefSignal(off, turned off);
DefSignal(worn, worn);
DefSignal(doff, doffed);
DefSignal(move, moved) destination = nil propList= [&destination];
DefSignal(seen, seen) location = nil propList = [&location];
DefSignal(examine, examine) actor = nil propList = [&actor];
DefSignal(take, take) actor = nil propList = [&actor];
DefSignal(drop, drop) actor = nil propList = [&actor];
DefSignal(open, open);
DefSignal (close, closed);


modify TadsObject
    /* Emit a signal */
    emit(signal, [args])
    {
        /* Simply call the signal's emit method with ourselves as the sender. */
        signal.emit(self, args...);
    }
    
    /* 
     *   Handle a signal from sender; game code will need to override particular
     *   instances. Note that this is a catch-all handler for signals we don't
     *   recognize or for which more specific handlers haven't been defined.
     */
    handle(sender, signal)
    {
    }   
    
        
    dispatchSignal(sender, signal)
    {
        local prop;       
        
        if(signal.dispatchTab != nil && signal.dispatchTab[[sender, self]] != nil)
            prop = signal.dispatchTab[[sender, self]];
        
        else if(signal.propDefined(&handleProp) && signal.handleProp)
            prop = signal.handleProp;
        else
            prop = &handle;
        
        if(propDefined(prop))
            self.(prop)(sender, signal);
        else
            handle(sender, signal);
    }
;  
    
   
    
    
    
 modify Thing  
    /*  
     *   Make various common state changes and actions emit the appropriate
     *   signals.
     */
    makeLit(stat)
    {
        inherited(stat);
        emit(stat ? litSignal : unlitSignal);
    }
    
    discover(stat = true)
    {
        inherited(stat);
        emit(stat ? discoverSignal : undiscoverSignal);
    }
    
    makeLocked(stat)
    {
        inherited(stat);
        emit(stat ? lockSignal : unlockSignal);       
    }
    
    makeOn(stat)
    {
        inherited(stat);
        emit(stat ? onSignal: offSignal);
    }
    
    makeWorn(stat)
    {
        inherited(stat);
        emit(stat? wornSignal : doffSignal);
    }
    
    moveInto(newCont)
    {
        inherited(newCont);
        
        emit(moveSignal, newCont);
    }
    
    noteSeen()
    {
        inherited();
        
        emit(seenSignal, location);
    }
    
    dobjFor(Examine)
    {
        action()
        {
            inherited();
            
            emit(examineSignal, gActor);
        }
    }
    
    dobjFor(Take)
    {
        action()
        {
            inherited();
            
            emit(takeSignal, gActor);
        }
    }
    
    dobjFor(Drop)
    {
        action()
        {
            inherited();
            
            emit(dropSignal, gActor);
        }
    }
    
    makeOpen(stat)
    {
        inherited(stat);
        emit(stat ? openSignal : closeSignal);
    }
;
    
 

connect(sender, signal, receiver, handler?)
{
    signal = relationTable.getRelation(signal)[1];
    
    relate(sender, signal, receiver);
    if(handler)
        signal.addHandler(sender, receiver, handler);
}

unconnect(sender, signal, receiver)
{
    signal = relationTable.getRelation(signal)[1];
    unrelate(sender, signal, receiver);
    
    if(receiver.propDefined(&removeSenderHandler))
       signal.removeHandler(sender, receiver);
}