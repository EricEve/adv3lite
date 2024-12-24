#charset "us-ascii"
#include "advlite.h"



/*
 *   ***************************************************************************
 *   gadget.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve
 *
 *
 *
 *   This module contains definitions for various control gadgets like buttons,
 *   levers and dials.
 */

/*  A Button is an object that does something when pressed */
class Button: Thing
    
    /* a button is usually fixed to something */
    isFixed = true
    
    /* Handle the Push command */
    dobjFor(Push)
    {
        /* A Button is a good choice for a PUSH command */
        verify() { logicalRank(120); }
        
        /* Execute our makePushed method when we're pushed */
        action() { makePushed(); }
        
        /* If nothing else happens, just say 'Click!' */
        report() { DMsg(click, 'Click!'); }
    }
    
    /* 
     *   Carry out the effects of pushing the button here. Particular Button
     *   objects will need to override this method to carry out the effect of
     *   pushing the button.
     */
    makePushed() { }
;

/* 
 *   A Lever is an object that can be in one of two positions: pulled (isPulled
 *   = true) or pushed (isPulled = nil), and which can be pulled and pushed
 *   between those two positions.
 */
class Lever: Thing
    
    /* a lever is usually fixed to something */
    isFixed = true
    
    /* is this lever in the pulled or pushed position. */
    isPulled = nil
    
    /* 
     *   By default we make isPushed the opposite of isPulled, but we defined
     *   them as separate properties in case we want a lever that can be in more
     *   than two positions, and so might be in an intermediate position that is
     *   neither pushed nor pulled.
     */
    isPushed = (!isPulled)
    
    /* 
     *   Carry out pushing or pulling the lever. Note that this would need to be
     *   overridden on a Lever that can be in more than two states.
     */
    makePulled(stat)
    {
        /* Set isPulled to stat */
        isPulled = stat;
    }
    
    /* Handle Pulling this Lever */
    dobjFor(Pull)
    {
        verify()
        {
            /* 
             *   A Lever can't be pulled any further if it's already in the
             *   pulled position
             */
            if(isPulled)
                illogicalNow(alreadyPulledMsg);
        }
        
        /* Use the makePulled() method to handle pulling the lever */
        action() { makePulled(true); }
        
        /* The default report to display after pulling one or more levers */
        report() { DMsg(okay pulled, 'Done. |{I} pull{s/ed} {1}. ', gActionListStr); }
        
    }
    
    /* The message to display when we can't be pulled any further */
    alreadyPulledMsg = BMsg(already pulled, '{The subj dobj} {is} already in the
        pulled position. ')
    
    /* Handle Pushing this Lever */
    dobjFor(Push)
    {
        verify()
        {
            /* 
             *   A Lever can't be pushed any further if it's already in the
             *   pushed position
             */             
            if(isPushed)
                illogicalNow(alreadyPushedMsg);
        }
        
        /* Use the makePulled() method to handle pushing the lever */
        action() { makePulled(nil); }
        
        /* The default report to display after pushing one or more levers */
        report() { DMsg(okay pushed, 'Done. |{I} push{es/ed} {1}. ', gActionListStr); }
    }
    
    /* The message to display when we can't be pushed any further */
    alreadyPushedMsg = BMsg(already pushed, '{The subj dobj} {is} already in the
        pushed position. ');
    
;

/* 
 *   A Settable is anything that can be set to particular values, such as a
 *   slider control or a dial. Various types of dial descending from Settable
 *   are defined below.
 */
class Settable: Thing
      
    /* 
     *   a list of the valid settings this Settable can have, given as list of
     *   single-quoted strings.
     */
    validSettings = []

    /* our current setting */
    curSetting = nil
    
    /* 
     *   Put the setting into a standard form so it can be checked for validity.
     *   By default we turn it into lower case so that it doesn't matter what
     *   case the player types the desired setting in. We also strip any
     *   enclosing quotes that might have been used to pass an awkward value
     *   like "1.4" that the parser would otherwise misinterpret.
     */    
    canonicalizeSetting(val)
    {
        return stripQuotesFrom(val.toLower());
    }
    
    /*  Set this Settable to its new setting, val */
    makeSetting(val)
    {
        /* Update our current setting to the canonicalized version of val */
        curSetting = canonicalizeSetting(val);
    }
    
    /* 
     *   Check whether the proposed setting is valid. By default it is if the
     *   canonicalized version of val is present in our list of valid settings.
     */    
    isValidSetting(val)
    {
        /* Convert val into its canonicalized equivalent. */
        val = canonicalizeSetting(val);
        
        /* 
         *   Determine whether val is present in our list of valid settings and
         *   return true or nil accordingly
         */
        return validSettings.indexOf(val) != nil;
    }
    
    /* A Settable is something that can be set to various values */
    canSetMeTo = true
    
    /* Handle a SET TO command targeted at this Settable */
    dobjFor(SetTo)
    {    
        /* Check whether we're being set to a valid setting */
        check()
        {            
            /* 
             *   If the player is trying to set us to our current setting,
             *   display a message to that effect (which will halt the action).
             */
            if(curSetting == canonicalizeSetting(gLiteral))
                say(alreadySetMsg); 
            
            /*   
             *   If the player is trying to set us to an invalid setting,
             *   display a message to that effect (which will halt the action).
             */
            if(!isValidSetting(gLiteral))
                say(invalidSettingMsg);
        }
        
        /* Note that the action() handling for SET TO is defined on Thing */
    }
    
    invalidSettingMsg = BMsg(invalid setting, 'That {dummy} {is} not a valid
        setting for {the dobj}. ')
    
    alreadySetMsg = BMsg(already set, '{The subj dobj} {is} already set to {1}.
        ', curSetting)
    
    /*  
     *   Most gadgets of this sort are part of or attached to something else, so
     *   we make them fixed in place by default
     */
    isFixed = true
    
    dobjFor(Set)
    {
        action() { askMissingLiteral(SetTo); }
    }   
;


/* A Dial is Simply a Settable we can turn as well as set */
class Dial: Settable
    dobjFor(TurnTo) asDobjFor(SetTo)
    canTurnMeTo = true
    
    dobjFor(Turn) 
    {
        action() {askMissingLiteral(TurnTo); }
    }
;


/* 
 *   A Numbered Dial is a Dial that can be turned to any integer in a defined
 *   range of numbers.
 */
class NumberedDial: Dial
    
    /* The lowest number to which this dial can be turned. */
    minSetting = 0
    
    /* The highest number to which this dial can be turned. */
    maxSetting = 100
    
    /* 
     *   If the spelledToInt() function is defined then allow the dial to be
     *   turned to a spelt-out number as well as a number given in digits, e.g.
     *   TURN DIAL TO FORTY-THREE as well as TURN DIAL TO 43.
     */
    canonicalizeSetting(val)
    {
        /* Get the inherited value */
        val = inherited(val);
        
        /* Try to convert it to a number */
        local num = defined(spelledToInt) ? spelledToInt(val) : nil;
        
        /* 
         *   If the conversion was successful, convert val to a string
         *   representation of the number (e.g. '43').
         */
        if(num)
            val = toString(num);
        
        /* Return val, changed as need be. */
        return val;
    }
    
    /* Is val a valid setting for this dial? */
    isValidSetting(val)
    {   
        /* Convert val into its canonicalized equivalent. */
        val = canonicalizeSetting(val);
        
        /* 
         *   Try converting val to either a real number or an integer depending
         *   on whether allowDecimal is true or nil.
         */        
        val = allowDecimal ? tryNum(val) : tryInt(val);
        
        /* 
         *   Val is valid if it lies between our minimum and maximum settings
         *   (inclusively)
         */
        return val != nil && (val >= minSetting && val <= maxSetting);            
    }        
    
    allowDecimal = nil
;


/* 
 *   Mix-in class to help with inventory management. A BagOfHolding can be mixed
 *   in with a Container (or, less usually, Surface, RearContainer or Underside)
 *   to provide an object which, if held by the player character, will be used
 *   to move objects in the player character's inventory to if his/her hands
 *   become too full to pick up another object.
 */
class BagOfHolding: object
    
    /* 
     *   The affinity for this BagOfHolding for obj. This can be used to
     *   determined how 'willing' a particular BagOfHolding is to contain obj. A
     *   value of less than 1 means that the BagOfHolding can't contain obj at
     *   all. The higher the affinity, the better the choice this BagOfHolding
     *   is for obj. The default value is 100, or 0 for a BagOfHolding's
     *   affinity for itself.
     */
    affinityFor(obj)
    {
        return obj == self ? 0 : 100;
    }
    
    /* 
     *   To be suitable to contain obj a BagOfHolding must have enough spare
     *   capacity for it. If it has, its suitability is its affinity for obj;
     *   otherwise it's 0. A BagOfHolding is also unsuitable if it's locked.
     */
    suitabilityFor(obj)
    {
        if(obj.bulk > bulkCapacity - getBulkWithin || obj.bulk > maxSingleBulk
           || isLocked || obj.isFixed)
            return 0;
        
        return affinityFor(obj);
    }
    
    /* 
     *   Class method to determine whether the actor is carrying a suitable
     *   BagOfHolding that could be used to move something from his inventory
     *   into, and then to move items from the actor's inventory into an
     *   appropriate bag of holding.
     */
    tryHolding(obj)
    {
        /* Obtain a Vector containing the BagsOfHolding carried by the actor. */
        local bohVec = gActor.contents.subset({x: x.ofKind(BagOfHolding)});
        
        /* 
         *   If the actor is not carrying a BagOfHolding, there's nothing more
         *   we can do, so just stop here.
         */
        if(bohVec.length == 0)
            return;
        
        /*  The amount of bulk we need to free up */
        local bulkToFree = gActor.getCarriedBulk + obj.bulk -
            gActor.bulkCapacity;
        
           
        
        local idx = 1;
        
        /* The number of items we need to free up */
        local carriedList = gActor.directlyHeld;
        
         /* The number of items we need to free up */
        local itemsToFree = gActor.directlyHeld.length() - gActor.maxItemsCarried + 1;
        
        while((bulkToFree > 0  || itemsToFree > 0) && carriedList.length >= idx)
        {
            local objToMove = carriedList[idx];
            
            /* 
             *   If we have more than one BagOfHolding available, sort our
             *   vector of BagsOfHolding in descending order of suitability
             */
            if(bohVec.length > 1)
                bohVec.sort(SortDesc, {a, b: a.suitabilityFor(objToMove) -
                            b.suitabilityFor(objToMove) });
            
            /* 
             *   Choose the first one in the Vector, which will be the most
             *   suitable.
             */
            local bagToUse = bohVec[1];
            
            /* 
             *   If the most suitable bag of holding for the object we're trying
             *   to move isn't suitable, try again with another object.
             */
            if(bagToUse.suitabilityFor(objToMove) < 1)
            {
                idx++;
                continue;
            }
            
            /* 
             *   Get the action needed to move an object into the selected
             *   BagOfHolding.
             */
            local action = bagToUse.moveAction();
            
            /*  
             *   If the action is nil, then there's something wrong with the
             *   selected BagOfHolding. Break of of the loop so we don't get
             *   stuck in an infinite loop.
             */
            
            if(action == nil)
                break;
            
            /* 
             *   Try moving the selected object into the selected bag using the
             *   appropriate action depending on the bag's contType
             */
            tryImplicitAction(action, objToMove, bagToUse);
            
            /* 
             *   Reset the index into the contents list to 1 so that if we need
             *   to select another object we start from the beginning again.
             */
            idx = 1;
            
            /* 
             *   Remove objToMove from the carried list. (Even if it wasn't
             *   actually moved for any reason, we don't want to try moving it
             *   again).
             */
            carriedList -= objToMove;
            
            /*  Recalculate the amount of bulk left to free */
            
            bulkToFree = gActor.getCarriedBulk + obj.bulk -
            gActor.bulkCapacity;        
            
            /* Recalculate the number of items we need to free */
            itemsToFree = gActor.directlyHeld.length() - gActor.maxItemsCarried + 1;
            
            
        }
        
    }
    
    /* The action needed to move an object into me. */
    moveAction()
    {
        switch(contType)
        {
        case In:
            return PutIn;
        case On:
            return PutOn;
        case Under:
            return PutUnder;
        case Behind:
            return PutBehind;
        }
        
        if(remapIn)
            return PutIn;
        if(remapOn)
            return PutOn;
        if(remapUnder)
            return PutUnder;
        if(remapBehind)
            return PutBehind;
        
        return nil;
    }
       
    /* 
     *   A BagOfHolding carried by the actor allows its contents to be dropped (via an implicit
     *   TakeFrom) without the actor havign to perform an explicit take.
     */
    canDropContents = true
    
;

