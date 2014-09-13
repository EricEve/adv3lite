#charset "us-ascii"
#include "advlite.h"

/*----------------------------------------------------------------------------*/
/*
 *   WEIGHT EXTENSION
 *
 *   Extension to track object weights and weight capacities.
 *
 *   Version 1.0
 *
 */

/*  Modifications to Thing class for WEIGHT extension */
modify Thing
    /* Our own weight, not counting the weight of our contents */
    weight = 0
    
    /* Our total weight, including the weight of our contents */
    totalWeight = (weight + getWeightWithin())
    
    /* The total weight of our contents, excluding our own weight. */
    getWeightWithin()
    {       
        return totalWeightIn(contents);
    }    
   
    /* 
     *   The total weight of the items we're carrying, excluding anything worn
     *   or anything fixed in place.
     */    
    getCarriedWeight()
    {
        return totalWeightIn(directlyHeld);        
    }
    
    /*  The total weight we're capable of containing */
    weightCapacity = 100000
    
    /*  The maximum weight of any single item we can contain */
    maxSingleWeight = weightCapacity
    
    
    /*  
     *   Check whether obj can be inserted into us without exceeding our bulk
     *   and weight constraints.
     */
    checkInsert(obj)
    {
        /*  
         *   Carry out the inherited handling, which checks the bulk constraints
         */
        inherited(obj);         
        
        /*   
         *   Cache our total weight in a local variable, since it may involve a
         *   calculation.
         */
        local objWeight = obj.totalWeight;
        
        /* 
         *   If the total weight of obj is greater than the maxSingleWeight this
         *   Thing can bear, or greater than the remaining weight capacity of
         *   this Thing allowing for what it already contains ,then display a
         *   message to say it's too heavy to fit inside ue.
         */
        if(objWeight > maxSingleWeight || objWeight > weightCapacity)
            sayTooHeavy(obj);      
        
        else if(objWeight > weightCapacity - getWeightWithin())
            sayCantBearMoreWeight(obj);
        
    }
    
    /*  Display a message saying that obj is too heavy to be inserted in us. */
    sayTooHeavy(obj)
    {
          /* Create a message parameter substitution. */
        gMessageParams(obj);
        
        DMsg(too heavy, '{The subj obj} {is} too heavy to go {1} {2}. ', 
                 objInPrep, theName);
    }
    
    /*  Display a message saying that we can't bear any more weight. */
    sayCantBearMoreWeight(obj)
    {
        local this = self;
        
          /* Create a message parameter substitution. */
        gMessageParams(obj, this);
        
        DMsg(cant bear more weight, '{The subj this} {can\'t} bear any more
            weight. ');
    }
    
    
    /* Check whether the actor has the bulk and weight capacity to hold us. */
    checkRoomToHold()
    {
        /* Carry out the inherited handling, which checks for bulk capacity. */
        inherited();
        
        /* 
         *   Cache our total weight in a local variable, since it may involve a
         *   calculation.
         */
        local tWeight = totalWeight;       
           
        
        /* 
         *   First check whether this item is individually too heavy for the
         *   actor to carry.
         */
        if(tWeight > gActor.maxSingleWeight || tWeight > gActor.weightCapacity)
            DMsg(too heavy to carry, '{The subj dobj} {is} too heavy for {me} to
                carry. ');
               
        
        /* 
         *   otherwise check that the actor has sufficient spare carrying
         *   capacity.
         */
        else if(tWeight > gActor.weightCapacity - gActor.getCarriedWeight())
            DMsg(cannot carry any more weight, '{I} {can\'t} carry that much
                more weight. ');
    }
    
    /* 
     *   The maximum weight that can be hidden under, behind or in this object,
     *   assuming that the player can put anything there at all. Note that this
     *   only affects what the player can place there with PUT IN, PUT UNDER and
     *   PUT BEHIND commands, not what can be defined there initially or moved
     *   there programmatically.
     */    
    maxWeightHiddenUnder = 100000
    maxWeightHiddenBehind = 100000
    maxWeightHiddenIn = 100000
    
    /* The total weight of items hidden in, under or behind this object */    
    getWeightHiddenUnder = (totalWeightIn(hiddenUnder))
    getWeightHiddenIn = (totalWeightIn(hiddenIn))
    getWeightHiddenBehind = (totalWeightIn(hiddenBehind))
    
    /* Calculate the total weight of the items in lst */
    totalWeightIn(lst)
    {
        local tot = 0;
        for(local cur in valToList(lst))
            tot += cur.totalWeight;
        
        return tot;
    }
    
    /*  
     *   Modifications to PutIn handling to check for weight hidden inside this
     *   item.
     */
    iobjFor(PutIn)
    {
        check()
        {
            /* 
             *   If the inherited handling would cause this action to fail,
             *   there's no need for any additional checks.
             */
            if(gOutStream.watchForOutput({: inherited() }))
                return;
            
            if(contType != In 
               && gDobj.totalWeight > maxWeightHiddenIn - getWeightHiddenIn)
                sayTooHeavyToHide(gDobj, In);
        }
    }
    
    /*  
     *   Modifications to PutUnder handling to check for weight hidden under
     *   this item.
     */
    iobjFor(PutUnder)
    {
        check()
        {
            /* 
             *   If the inherited handling would cause this action to fail,
             *   there's no need for any additional checks.
             */
            if(gOutStream.watchForOutput({: inherited() }))
                return;
            
            if(contType != Under
               && gDobj.totalWeight > maxWeightHiddenUnder - getWeightHiddenUnder)
                sayTooHeavyToHide(gDobj, Under);
        }
    }
    
    /*  
     *   Modifications to PutBehind handling to check for weight hidden behind
     *   this item.
     */
    iobjFor(PutBehind)
    {
        check()
        {
            /* 
             *   If the inherited handling would cause this action to fail,
             *   there's no need for any additional checks.
             */
            if(gOutStream.watchForOutput({: inherited() }))
                return;
            
            if(contType != Behind
               && gDobj.totalWeight > maxWeightHiddenBehind - getWeightHiddenBehind)
                sayTooHeavyToHide(gDobj, Behind);
        }
    }
    
    /* 
     *   Display a message to say that obj is too heavy to fit in/on/under us,
     *   where insType is In, On or Under.
     */
    sayTooHeavyToHide(obj, insType)
    {
        gMessageParams(obj);
        
        DMsg(too heavy to hide, '{The sub obj} {is} too heavy to hide {1} {2}. ',
             insType.prep, theName);
    }
    
;