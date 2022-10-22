#charset "us-ascii"
#include "advlite.h"

/*--------------------------------------------------------*/
/*
 *   SIGNALS EXTENSION Still at an experimental stage
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
 *
 *   [SIGNALS EXTENSION]
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
	 *
	 *   [SIGNALS EXTENSION]
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
     *   our emit method should be assigned. [SIGNALS EXTENSION]
     */
    propList = []
    
	/*
	 *   A LookupTable liniking objects that might emit this signal (potential senders) to potential
	 *   receivers of this signal, so that notifications can be sent from the former to the latter.
	 *   Game code should not need to manipulate this table directly; it should instead be updated via
	 *   the supplied connect() and unconnect() functions.
	 *   
	 *   [SIGNALS EXTENSION]
	 */
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



/* Signals to handle common state changes on Thing  [SIGNALS EXTENSION] */
DefSignal(lit, lit);
DefSignal(unlit, unlit);
DefSignal(discover, discovered);
DefSignal(undiscover, lost);
DefSignal(lock, locked);
DefSignal(unlock, unlocked);
DefSignal(on, turned on);
DefSignal(off, turned off);
DefSignal(worn, worn) wearer = nil propList = [&wearer];
DefSignal(doff, doffed);
DefSignal(move, moved) destination = nil propList= [&destination];
DefSignal(actmove, action moved) destination = nil propList= [&destination];
DefSignal(seen, seen) location = nil propList = [&location];
DefSignal(examine, examine) actor = nil propList = [&actor];
DefSignal(take, take) actor = nil propList = [&actor];
DefSignal(drop, drop) actor = nil propList = [&actor];
DefSignal(open, open);
DefSignal (close, closed);
DefSignal(push, push);
DefSignal(pull, pull);
DefSignal(feel, feel);


 /*
  * MODIFICATIONS TO TadsObject for SIGNALS EXTENSION
  *
  * Add handling for emiting, handling and dispatching signals. 
  */
modify TadsObject
    /* Emit a signal  [SIGNALS EXTENSION] */
    emit(signal, [args])
    {
        /* Simply call the signal's emit method with ourselves as the sender. */
        signal.emit(self, args...);
    }
    
    /* 
     *   Handle a signal from sender; game code will need to override particular
     *   instances. Note that this is a catch-all handler for signals we don't
     *   recognize or for which more specific handlers haven't been defined.
	 *   [SIGNALS EXTENSION]
     */
    handle(sender, signal)
    {
    }   
    
    /*
	 *   Dispatch a signal to the appropriate handler method on this object.
     *   We look up the property pointer to use on the signal's dispatchTab
	 *   LookupTable. If we find one and the property is defined on this object
	 *   then we use that property to handle the signal. Otherwise, we simply
	 *   use our catch-all generic handle(sender, signal) method.
	 *  
	 *   [SIGNALS EXTENSION] 
     */    
    dispatchSignal(sender, signal)
    {
        local prop;       
        
        if(signal.dispatchTab != nil && signal.dispatchTab[[sender, self]] != nil)
            prop = signal.dispatchTab[[sender, self]];
        
        else if(signal.propDefined(&handleProp) 
                && signal.propType(&handleProp) == TypeProp)
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
     *   signals. [SIGNALS EXTENSION]
     */
	 
	/*
	 *  emit a litSignal or unlitSignal when this object is lit or unlit.
	 *  [SIGNALS EXTENSION]
	 */
    makeLit(stat)
    {
        inherited(stat);
        emit(stat ? litSignal : unlitSignal);
    }
    
	/*
	 *  emit a discoverSignal or undiscoverSignal when this object is discovered or undiscovered.
	 *  SIGNALS EXTENSION]
	 */
    discover(stat = true)
    {
        inherited(stat);
        emit(stat ? discoverSignal : undiscoverSignal);
    }
    
	/*
	 *  emit a lockSignal or unlockSignal when this object is locked or unlocked.
	 *  [SIGNALS EXTENSION]
	 */
    makeLocked(stat)
    {
        inherited(stat);
        emit(stat ? lockSignal : unlockSignal);       
    }
    
	/*
	 *  emit an onSignal or offSignal when this object is turned on or off
	 *  [SIGNALS EXTENSION]
	 */
    makeOn(stat)
    {
        inherited(stat);
        emit(stat ? onSignal: offSignal);
    }
    
	/*
	 *  emit a wornSignal or doffSignal when this object is worn or doffed (taken off).
	 *  [SIGNALS EXTENSION]
	 */
    makeWorn(stat)
    {
        inherited(stat);
        if(stat)
            emit(wornSignal, stat);
        else
            emit(doffSignal);
    }
    
	/*
	 *  emit a moveSignal when this object is moved.
	 *  [SIGNALS EXTENSION]
	 */
    moveInto(newCont)
    {
        inherited(newCont);
        
        emit(moveSignal, newCont);
    }
    
	/*
	 *  emit a actmoveSignal or unlitSignal when this object moved as part of action handling.
	 *  [SIGNALS EXTENSION]
	 */
    actionMoveInto(newCont)
    {
        inherited(newCont);
        
        emit(actmoveSignal, newCont);
    }
    
    /*
	 *  emit a seenSignal or unlitSignal when this object is seen.
	 *  [SIGNALS EXTENSION]
	 */
    noteSeen()
    {
        inherited();
        
        emit(seenSignal, location);
    }
        
    /*
	 *  emit an openSignal or closeSignal when this object is open or closed.
	 *  [SIGNALS EXTENSION]
	 */
    makeOpen(stat)
    {
        inherited(stat);
        emit(stat ? openSignal : closeSignal);
    }
;
    
 
/*
 *  Function to set up a signalling relation between sender and receiver via the signal Signal. 
 *  This first created a relation between sender and receiver [using the RELATIONS extension)
 *  And then, if the handler parameter is supplied, adds an appropriate entry to the signal's 
 *  dispatchTab table to register that this is the handler to use on the receiver when signal is
 *  sent to receiver from sender.
 *  [SIGNALS EXTENSION]
 */
connect(sender, signal, receiver, handler?)
{
    signal = relationTable.getRelation(signal)[1];
    
    relate(sender, signal, receiver);
    if(handler)
        signal.addHandler(sender, receiver, handler);
}


/*
 * Function to remove the signalling relationship between sender and receiver via the signal
 * Signal. [SIGNALS EXTENSION]
 */
unconnect(sender, signal, receiver)
{
    signal = relationTable.getRelation(signal)[1];
    unrelate(sender, signal, receiver);
    
    if(receiver.propDefined(&removeSenderHandler))
       signal.removeHandler(sender, receiver);
}

modify TAction
    /*
	 * The signal (if any) )o be emitted by the direct object of this action.
	 * [SIGNALS EXTENSION]
     */	
    signal = nil
    
	/*
	 * If this action defines an associated signal, then have the direct object emit the signal
	 * after carrrying out out inherited handling. [SIGNALS EXTENSION]
	 */
    doAction()
    {
        inherited();
        if(signal)
            curDobj.emit(signal);
    }
;

modify Take
   /* [SIGNALS EXTENSION] */  
    signal = takeSignal
;

modify Drop
/* [SIGNALS EXTENSION] */  
    signal = dropSignal
;

modify Examine
/* [SIGNALS EXTENSION] */  
    signal = examineSignal
;

modify Push
/* [SIGNALS EXTENSION] */  
    signal = pushSignal
;

modify Pull
/* [SIGNALS EXTENSION] */  
    signal = pullSignal
;

modify Feel
/* [SIGNALS EXTENSION] */  
    signal = feelSignal
;

