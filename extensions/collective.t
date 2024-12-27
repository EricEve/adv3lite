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
 *   [COLLECTIVE EXTENSION]
 */
class Collective: Thing
    /* 
     *   A list of one or more tokens, any of which might be used to refer to me
     *   as a plural object. E.g. if the Collective is a bunch of grapes,
     *   pluralTokes might be ['grapes']. This is used so that I'm chosen in
     *   preference to individual objects (e.g. grapes) when the player's
     *   command includes one of these plural tokens, but an individual object
     *   (e.g. a grape) is preferred otherwise.
     *
     *   By default (if this is left as nil by the user) the library populates
     *   this list from our name property, which in the majority of cases should
     *   achieve what's needed. This property only needs to be user-defined in
     *   cases where using the name won't work, even in conjunction with the
     *   extraToks property.
     */
    collectiveToks = nil
   
    /*   
     *   A list of additional tokens added to our collectiveToks at preInit.
     *   This might be needed, for example, if a Collective called 'stack of
     *   cans' also answers to 'pile of tins' (i.e., if it has 'pile' and 'tins'
     *   defined as additional nouns it its vocab property), in which case we'd
     *   need to defined these tokens ['pile', 'tins'] here.
     */
    extraToks = nil
    
    
    /* Did the player's command match any of our collectiveToks ? [COLLECTIVE EXTENSION] */
    collectiveDobjMatch = nil
    
	/* Did the player's command match any of our collectiveToks ? [COLLECTIVE EXTENSION] */
    collectiveIobjMatch = nil
    
    /* The number of dispensible items being requested. */
    numberWanted = 0
    
	/* For the COLLECTIVE EXTENSION  decide whether to select the collective object (ourselves) or an individual item. */
    filterResolveList(np, cmd, mode)
    {
        /* Carry out any inherited handling */
        inherited(np, cmd, mode);
        
        local num = np.quantifier == nil ? 1 : np.quantifier;
        
        local collectiveMatch = np.tokens.overlapsWith(collectiveToks) 
            && num == 1;
        
        /* 
         *   Note whether we have a collective match in the particular role
         *   being considered.
         */
        if(np.role == DirectObject)
        {
            collectiveDobjMatch = collectiveMatch;
            
            /* Note the numberWanted */
            numberWanted = num;
        }
        if(np.role == IndirectObject)
            collectiveIobjMatch = collectiveMatch;
        
        /* Go through each of the NPMatch objects in our list. */
        foreach(local cur in np.matches)
        {
            /* 
             *   Only worry about it if the NPMatch object's associated object
             *   is one for which we're a collective. If it is, we need to make
             *   a decision.
             */
            if(isCollectiveFor(cur.obj))
            {
                /*  
                 *   If the player's command included one of our collectiveToks,
                 *   then we're the preferred object to use, so remove cur from
                 *   the list of possible matches.
                 */
                if(collectiveMatch || collectiveAction(np, cmd))
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
	 *
	 *   [COLLECTIVE EXTENSION]
     */     
    isCollectiveFor(obj) { return nil; }
    
    
    collectiveAction(np, cmd) { return nil; }
    
    /* Overidden for COLLECTIVE EXTENSION */
    preinitThing
    {
        inherited();
        
        /* 
         *   If collectiveToks hasn't been defined, populate it with tokens
         *   drawn from our name plus any user-defined extraToks.
         */
        if(collectiveToks == nil)
            collectiveToks = name.toLower.split(' ') + valToList(extraToks);
    }
;

/*   
 *   A DispensingCollective is a Collective that dispenses objects when the
 *   player takes from it; e.g. a bunch of grapes that dispenses grapes.
 *   [COLLECTIVE EXTENSION]
 */
class DispensingCollective: Collective
    
    /*  
     *   If definesd the class of object that is created and dispensed when an
     *   actor takes from this DispensingCollective. [COLLECTIVE EXTENSION]
     */
    dispensedClass = nil
    
    /*   
     *   Alternatively, a list of objects that are taken in turn when we take
     *   from this DispensingCollective. [COLLECTIVE EXTENSION]
     */
    dispensedObjs = nil
    
    /*   The number of objects we have dispensed so far. [COLLECTIVE EXTENSION] */
    dispensedCount = 0
    
    /*   
     *   The total number of objects we can dispense. If this is nil, there is
     *   no limit. [COLLECTIVE EXTENSION]
     */
    maxToDispense = nil
    
    /*   
     *   The number of objects we have left to dispense. This is updated by the
     *   canDispense method, and shouldn't be overridden by user code. It may,
     *   however, for use code to consult this property, e.g. to vary our
     *   description. [COLLECTIVE EXTENSION]
     */         
    numLeft = 0
    
    /*  
     *   In principle a DispensingCollective can supply additional items on
     *   demand. This property is used by the parser to prevent it from throwing
     *   an error when the player asks for more of the items we dispense than
     *   are currently in scope. [COLLECTIVE EXTENSION]
     */
    canSupply = true
    
    /*   Is it possible (or allowed) to dispense any more objects from us? [COLLECTIVE EXTENSION] */
    canDispense()
    {
        /* 
         *   If we have a list of dispensedObjs, we can continue to dispense
         *   until we reach the end of the list.
         */
        if(dispensedObjs)
        {
            numLeft = valToList(dispensedObjs).length - dispensedCount;       
        }
        
        /*  
         *   Otherwise, if we have a dispensed class we can continue to dispense
         *   either if there is no limit to the number we can dispense
         *   (maxToDispense = nil) or until we have dispensed maxToDispense
         *   objects.
         */
        if(dispensedClass)
        {
            /* 
             *   There's no limit to the number we can dispense, so simply
             *   return true.
             */
            if(maxToDispense == nil)
                return true;
            
            numLeft = maxToDispense - dispensedCount;     
        }
        
        /*  
         *   We can dispense the number of objects asked provided that number
         *   is no greater than the number we have left.
         */
        return numberWanted <= numLeft;;           
    }
    
    /*  Dispense an object from this DispensingCollective. [COLLECTIVE EXTENSION]*/
    dispenseObj()
    {
        for(local i in 1..numberWanted)
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
             *   Check that the actor has room to hold obj, and stop the action
             *   if not.
             */
            if(gOutStream.watchForOutput({: obj.checkRoomToHold() }))
                exit;
            
            /*  Move the object into the actor's inventory. */
            obj.actionMoveInto(gActor);           
            
            
            /*  
             *   If we have now dispensed all the objects we can, carry out any
             *   appropriate adjustments
             */
            
            if(dispensedCount == maxToDispense)
                exhaustDispenser();
        }
        
         /*  Say that we have dispensed the object. */
        sayDispensed(obj);
    }
    
    /* Display a message saying that the actor has taken an object from us. [COLLECTIVE EXTENSION]*/
    sayDispensed(obj)
    {               
        local objDesc = numberWanted == 1 ? obj.aName :
        spellNumber(numberWanted) + ' ' + obj.pluralNameFrom(obj.name);
        
        DMsg(say dispensed, '{I} {take} {1} from {2}. ', objDesc, dispenserName);
        
    }
    
    /* 
     *   The name to use when reporting that something has been dispensed (i.e. taken) from us.
     *   Normally this will simply be our theName but this can be overridden in game code, e.g. to
     *   'one of the apple trees' when the dispenser is the apples on the tree.
     */
    dispenserName = theName
    
    /* 
     *   The name to use when reportingt that we can't take any more items from us. Normally this
     *   will be our dispenser name, but particularl where the DispensingCollective represents a
     *   plural, such as trees in an orchard, we might want to use something different, e.g. 'any of
     *   the apple trees'.
     */
    exhaustedName = dispenserName
    
    /*  
     *   Game code can override this method on specific objects to carry out the
     *   effects of dispensing the maximum number of objects we're going to
     *   dispense, e.g. by changing the description, or replacing a bunch of
     *   bananas by a single banana (when it's the last one left). We do nothing
     *   here in the library, since what's needed will vary with the specifics
     *   of the game. [COLLECTIVE EXTENSION]
     */
    exhaustDispenser()
    {
    }
    
    /* 
     *   The TAKE action applied to a DispensingCollective might mean one of two
     *   things: it might be an attempt to take the DispensingCollective (e.g.
     *   the bunch of grapes) itself, or it may be an attempt to take a single
     *   item (e.g. a single grape from the bunch). We assume it's the former if
     *   what the player typed matches the plural vocab (e.g. 'grapes') and the
     *   latter otherwise. [COLLECTIVE EXTENSION]
     */
    dobjFor(Take)
    {
        verify()
        {
            /* 
             *   If it's an attempt to take us, rather than an item from us, use
             *   the inherited handling.
             */
            if(collectiveDobjMatch)
                inherited;
        }
        
        check()
        {
            /* 
             *   If it's an attempt to take us, rather than an item from us, use
             *   the inherited handling.
             */
            if(collectiveDobjMatch)
                inherited;
            
            /*  
             *   Otherwise see if we're able to dispense another item and
             *   complain if we can't.
             */
            else if(!canDispense)
                sayCannotDispense();
        }
        
        action()
        {
            /* 
             *   If it's an attempt to take us, rather than an item from us, use
             *   the inherited handling.
             */
            if(collectiveDobjMatch)
                inherited;
            
            /*  
             *   Otherwise, dispense an item (e.g. take a single grape from the
             *   bunch of grapes.
             */
            else
                dispenseObj();
        }
    }
    
    /*  
     *   We need to be able to handle commands like TAKE GRAPE FROM BUNCH where
     *   the DispensingCollective represents both objects in the command (since
     *   until we actually take the grape - or whatever the dispensed object is
     *   to be - it doesn't yet exist in scope to be the object of the command.)
	 *   [COLLECTIVE EXTENSION]
     */
    iobjFor(TakeFrom)
    {
        verify()
        {
            if(dispensedObjs && gTentativeDobj.overlapsWith(dispensedObjs))
                logical;
            
            else if(dispensedClass && gTentativeDobj.indexWhich({o:
                o.ofKind(dispensedClass) } ))
                logical;
            
            else if(gTentativeDobj.indexOf(self))
                logicalRank(120);    
            
            else
                illogical(cannotTakeFromHereMsg);                   
        }
    }
    
    /*	[COLLECTIVE EXTENSION] */
    cannotTakeFromHereMsg = BMsg(cant take from dispenser, '{I} {can\'t} take {a
        dobj} from {1}. ', exhaustedName)
    
    /*	[COLLECTIVE EXTENSION] */
    dobjFor(TakeFrom)
    {
        verify()
        {
            if(gIobj == self)
                logicalRank(120);
            else
                inherited;
        }
        
        check() { checkDobjTake(); }
        action() { actionDobjTake(); }
    }
    
    /* [COLLECTIVE EXTENSION] */
    sayCannotDispense()
    {
        if(numLeft < 1)
            say(cannotDispenseMsg);
        else
            say(notEnoughLeftMsg);
    }
    
    /* The message to display when there's no more items to dispense from us. [COLLECTIVE EXTENSION]*/
    cannotDispenseMsg = BMsg(cannot dispense, '{I} {can\'t} take any more from
        {1}. ', exhaustedName )
    
    /* 
     *   The message to display when the player has asked us for more items than
     *   we have left. [COLLECTIVE EXTENSION]
     */
    notEnoughLeftMsg = BMsg(not that many left, 'There{plural} {aren\'t} that
        many left to take. ')
    
    /* Are we the Collective for obj? [COLLECTIVE EXTENSION] */
    isCollectiveFor(obj) 
    {         
        
        /* We are not the Collective for obj if obj */
        if(dispensedObjs && valToList(dispensedObjs).indexOf(obj) != nil)
            return true;
        
        if(dispensedClass && obj.ofKind(dispensedClass))
            return true;
             
        return nil; 
    
    }
    
    /* The TakeFrom action should always act on us, the Collective. [COLLECTIVE EXTENSION] */
    collectiveAction(np, cmd) 
    { 
        return cmd.action == TakeFrom; 
    }
    
    /* Overidden for COLLECTIVE EXTENSION */
    preinitThing
    {
        inherited();
        
        /* 
         *   Force an initial calculation of our numLeft property, the
         *   number of items we have left to dispense.
         */
        canDispense();
    }
;

