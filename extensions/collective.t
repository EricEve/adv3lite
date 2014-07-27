#charset "us-ascii"
#include "advlite.h"


/* 
 * COLLECTIVE EXTENSION
 * 
 */

/* ------------------------------------------------------------------------ */
/*
 *   Collective - this is an object that can be used to refer to a group of
 *   other (usually equivalent) objects collectively.  In most cases, this
 *   object will be a separate game object that contains or can contain the
 *   individuals: a bag of marbles can be a collective for the marbles, or
 *   a book of matches can be a collective for the matchsticks.
 *   
 *   A collective object is usually given the same plural vocabulary as its
 *   individuals.  When we use that plural vocabulary, we will filter for
 *   or against the collective, as determined by the noun phrase
 *   production, when the player uses the collective term. 
 */
class Collective: Thing
    /* 
     *   A list of one or more tokens, any of which might be used to refer to me
     *   as a plural object. E.g. if the Collective is a bunch of grapes,
     *   pluralTokes might be ['grapes']. This is used so that I'm chosen in
     *   preference to individual objects (e.g. grapes) when the player's
     *   command includes one of these plural tokens, but an individual object
     *   (e.g. a grape) is preferred otherwise.
     */
    pluralToks = []
   
    /* Did the player's command match any of our pluralToks ? */
    pluralMatch = nil
    
    filterResolveList(np, cmd, mode)
    {
        /* Carry out any inherited handling */
        inherited(np, cmd, mode);
        
        pluralMatch = np.tokens.overlapsWith(pluralToks);
        
        /* Go through each of the NPMatch objects in our list. */
        foreach(local cur in np.matches)
        {
            /* 
             *   Only worry about it if the NPMatch objects associated object is
             *   one for which we're a collective. If it is, we need to make a
             *   decision.
             */
            if(isCollectiveFor(cur.obj, np, cmd))
            {
                /*  
                 *   If the player's command included one of our pluralToks,
                 *   then we're the preferred object to use, so remove cur from
                 *   the list of possible matches.
                 */
                if(pluralMatch)
                    np.matches -= cur;
                
                /*  Otherwise prefer the individual item. */
                else
                {                    
                    /* So remove our NPMatch object from the list of matches. */
                    np.matches = np.matches.subset({m: m.obj != self});
                    
                    /* 
                     *   Then stop looping through the match list, since there's
                     *   no more to do.
                     */
                    break;
                }
            }
        }
        
    }
    
    /*
     *   Determine if I'm a collective object for the given object.
     *
     *   In order to be a collective for some objects, an object must have
     *   vocabulary for the plural name, and must return true from this method
     *   for the collected objects.
     *
     *   The cmd parameter can be use to determine the current action
     *   (cmd.action), in case we want to vary our decision according to the
     *   action.
     *
     *   The np parameter can be used, inter alia, to determine the role
     *   (np.role), e.g. as DirectObject or IndirectObject.
     */     
    isCollectiveFor(obj, np, cmd) { return nil; }
;

/*   
 *   A DispensingCollective is a Collective that dispenses objects when the
 *   player takes from it; e.g. a bunch of grapes that dispenses grapes.
 */
class DispensingCollective: Collective
    
    /*  
     *   If defines, the class of object that is created and dispensed when an
     *   actor takes from this DispensingCollective/
     */
    dispensedClass = nil
    
    /*   
     *   Alternatively, a list of objects that are taken in turn when we take
     *   from this DispensingCollective.
     */
    dispensedObjs = nil
    
    /*   The number of objects we have dispensed so far. */
    dispensedCount = 0
    
    /*   
     *   The total number of objects we can dispense. If this is nil, there is
     *   no limit.
     */
    maxToDispense = nil
    
    /*   Is it possible (or allowed) to dispense any more objects from us? */
    canDispense()
    {
        /* 
         *   If we have a list of dispensedObjs, we can continue to dispense
         *   until we reach the end of the list.
         */
        if(dispensedObjs)
            return valToList(dispensedObjs).length > dispensedCount;
        
        /*  
         *   Otherwise, if we have a dispensed class we can continue to dispense
         *   either if there is no limit to the number we can dispense
         *   (maxToDispense = nil) or until we have dispensed maxToDispense
         *   objects.
         */
        if(dispensedClass)
            return(maxToDispense == nil || dispensedCount < maxToDispense);
        
        /*  
         *   If we have neither a dispensedObjs list nor a dispensedClass we
         *   can't dispense anything.
         */
        return nil;           
    }
    
    /*  Dispense an object from this DispensingCollective. */
    dispenseObj()
    {
        /* Increase the count of the number of objects dispensed. */
        dispensedCount++;
        
        /* If we have a list of dispensedObjs, select the next one. */
        if(dispensedObjs)
        {
            obj = valToList(dispensedObjs)[dispensedCount];            
        }
        /*  Otherwise create a new object of our dispensedClass class. */
        else
            obj = dispensedClass.createInstance();
        
        
        /* 
         *   Check that the actor has room to hold obj, and stop the action if
         *   not.
         */
        if(gOutStream.watchForOutput({: obj.checkRoomToHold() }))
            exit;
        
        /*  Move the object into the actor's inventory. */
        obj.actionMoveInto(gActor);       
        
        /*  Say that we have dispensed the object. */
        sayDispensed(obj);        
    }
    
    /* Display a message saying that the actor has taken an object from us. */
    sayDispensed(obj)
    {
        gMessageParams(obj);
        DMsg(say dispensed, '{I} {take} {a obj} from {1}. ', theName);
    }
    
    
    dobjFor(Take)
    {
        verify()
        {
            if(pluralMatch)
                inherited;
        }
        
        check()
        {
            if(pluralMatch)
                inherited;
            
            else if(!canDispense)
                say(cannotDispenseMsg);
        }
        
        action()
        {
            if(pluralMatch)
                inherited;
            
            else
                dispenseObj();
        }
    }
    
    iobjFor(TakeFrom)
    {
        verify()
        {
            if(dispensedObjs && gTentativeDobj.overlapsWith(dispensedObjs))
                logical;
            
            else if(dispensedClass && gTentativeDobj.indexWhich({o:
                o.ofKind(dispensedClass) } ))
               logical;
            
            else
                logicalRank(80);                   
        }
    }
    
    dobjFor(TakeFrom)
    {
        verify()
        {
            
        }
        
        check() { checkDobjTake(); }
        action() { actionDobjTake(); }
    }
    
    cannotDispenseMsg = BMsg(cannot dispense, '{I} {can\'t} take any more from
        {the dobj}. ')
    
    isCollectiveFor(obj, np, cmd) 
    { 
        if(cmd.action == TakeFrom)
            return nil;
        
        if(dispensedObjs && valToList(dispensedObjs).indexOf(obj) == nil)
            return nil;
        
        if(dispensedClass && !obj.ofKind(dispensedClass))
            return nil;
        
        
        
        return true; 
    
    }
;

