#charset "us-ascii"
#include "advlite.h"


class PreCondition: object
/*
     *   Check the condition on the given object (which may be nil, if
     *   this condition doesn't apply specifically to one of the objects
     *   in the command).  If it is possible to meet the condition with an
     *   implicit command, and allowImplicit is true, try to execute the
     *   command.  If the condition cannot be met, report a failure and
     *   return nil to terminate the command.
     *   
     *   If allowImplicit is nil, an implicit command may not be
     *   attempted.  In this case, if the condition is not met, we must
     *   simply report a failure and use 'exit' to terminate the command.
     */
    checkPreCondition(obj, allowImplicit) { return true; }

    /*
     *   Verify the condition.  This is called during the object
     *   verification step so that the pre-condition can add verifications
     *   of its own.  This can be used, for example, to add likelihood to
     *   objects that already meet the condition.  Note that it is
     *   generally not desirable to report illogical for conditions that
     *   checkPreCondition() enforces, because doing so will prevent
     *   checkPreCondition() from ever being reached and thus will prevent
     *   checkPreCondition() from attempting to carry out implicit actions
     *   to meet the condition.
     *   
     *   'obj' is the object being checked.  Note that because this is
     *   called during verification, the explicitly passed-in object must
     *   be used in the check rather than the current object in the global
     *   current action.  
     */
    verifyPreCondition(obj) { }

    /*
     *   Precondition execution order.  When we execute preconditions for a
     *   given action, we'll sort the list of all applicable preconditions
     *   in ascending execution order.
     *   
     *   For the most part, the relative order of two preconditions is
     *   arbitrary.  In some unusual cases, though, the order is important,
     *   such as when applying one precondition can destroy the conditions
     *   that the other would try to create but not vice versa.  When the
     *   order doesn't matter, this can be left at the default setting.  
     */
    preCondOrder = 100
;
    

containerOpen: PreCondition
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   if we have a non- nil remapIn property, that's the container
         *   representing us, so we need to use it instead.
         */
        
        if(obj.remapIn != nil)
            obj = obj.remapIn;
        
        
        /* 
         *   if the object is already open, we're already done; also there's
         *   nothing to be done if we're not a container (in the sense of
         *   something objects can be put in).
         */
               
        if (obj == nil || obj.contType != In || obj.isOpen)
            return true;
        
        if(allowImplicit && tryImplicitAction(Open, obj))
        {
            return obj.isOpen;
        }
        
        return nil;        
    }
    
;


objOpen: PreCondition
    
    verifyPreCondition(obj)
    {
        if(!obj.isOpen)
            logicalRank(90);
    }
    
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   if the object is already open, we're already done.
         */
        if (obj == nil || obj.isOpen)
            return true;
        
        if(allowImplicit && tryImplicitAction(Open, obj))
        {
            return obj.isOpen;
        }
        
        return nil;        
    }
    
;

objClosed: PreCondition
    
    verifyPreCondition(obj)
    {
        if(obj.isOpen)
            logicalRank(90);
    }
    
    
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   if the object is already closed, we're already done.
         */
        if (obj == nil || ! obj.isOpen)
            return true;
        
        if(allowImplicit && tryImplicitAction(Close, obj))
        {
            return !obj.isOpen;
        }
        
        return nil;        
    }
    
;  
    
    

objHeld: PreCondition
    
    verifyPreCondition(obj)
    {
        /* 
         *   If the object is fixed in place it can't be picked up, so there's
         *   no point in trying. BUT we also have to check for the case that the
         *   object is directly in the player (perhaps because a body part).
         */
        
        if(obj.isFixed && !obj.isDirectlyIn(gActor))
            illogical(obj.cannotTakeMsg);
        
        
        /* 
         *   If the actor isn't carrying the object it's slightly less likely to
         *   be the one the player means.
         */
          
        
        if(!obj.isIn(gActor))
            logicalRank(90);
        
    }
    
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   if the object is already held, we're already done.
         */
        if (obj == nil || obj.isDirectlyIn(gActor))
            return true;
        
        if(allowImplicit && tryImplicitAction(Take, obj))
        {
            return obj.isDirectlyIn(gActor);
        }
        
        return nil;        
    }
;

objNotWorn: PreCondition
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   if the object is not being worn, we're already done.
         */
        if (obj == nil || obj.wornBy != gActor)
            return true;
        
        if(allowImplicit && tryImplicitAction(Doff, obj))
        {
            return obj.wornBy == nil;
        }
        
        return nil;        
    }
    
;

objVisible: PreCondition
    verifyPreCondition(obj)
    {
        /* If it's too dark to see then we can't examine the object */
        
        if(!(gActor.outermostVisibleParent().isIlluminated || obj.visibleInDark))
            inaccessible(obj.tooDarkToSeeMsg);
        
        if(!Q.canSee(gActor, obj))
            inaccessible(BMsg(cannot see obj, '{I} {can\'t} see {1}. ',
                         obj.theName));
    }   
;

objAudible: PreCondition
    verifyPreCondition(obj)
    {
       
        local lst = Q.soundBlocker(gActor, obj);
        
              
        if(!Q.canHear(gActor, obj) && lst.length > 0)
        {
            local errMsg;
            gMessageParams(obj);
            
            if(lst[1].ofKind(Room))
                errMsg = BMsg(too far away to hear, '{The subj obj} {is} too far
                    away to hear. ');
            else           
                errMsg = BMsg(cannot hear, '{I} {can\'t} hear {1} 
                through {2}. ', obj.theName, lst[1].theName);
                
            inaccessible(errMsg);
        }
        
    }
;



touchObj: PreCondition
    verifyPreCondition(obj)
    {
       
        local lst = Q.reachBlocker(gActor, obj);
        
        /* 
         *   If the blocking object is the one we're trying to reach, then
         *   presumably we can reach it after all (e.g. an actor inside a closed
         *   box.
         */
        
        if(lst.length > 0 && lst[1] != obj)
        {
            local errMsg;
            gMessageParams(obj);
            
            if(lst[1].ofKind(Room))
                errMsg = BMsg(too far away, '{The subj obj} {is} too far away.
                    ');
            
            else          
                errMsg = BMsg(cannot reach, '{I} {can\'t} reach {1} 
                through {2}. ', obj.theName, lst[1].theName);
                
            inaccessible(errMsg);
        }
        
        
        obj.verifyReach(gActor);
    }
    
    
    
    checkPreCondition(obj, allowImplicit)
    {
        /* 
         *   First check whether the actor is in a nested room that does not
         *   contain the object being reached, and if said nested room does not
         *   allow reaching out.
         */
        
        local loc = gActor.location;
        local str = nil;
        
        
        while(loc != gActor.getOutermostRoom)
        {
            if(!obj.isOrIsIn(loc) && !loc.allowReachOut(obj))
            {
                if(allowImplicit && loc.autoGetOutToReach 
                   && tryImplicitAction(GetOutOf, loc))
                {
                    if(gActor.isIn(loc))
                        return nil;
                }
                else
                {
                    gMessageParams(obj, loc);
                    DMsg(cannot reach out, '{I} {can\'t} reach {the obj} from
                        {the loc}. ');
                    return nil;
                }
                    
            }
            
            loc = loc.location;
        }
        
        
        str = gOutStream.watchForOutput({:obj.checkReach(gActor)});
        
        if(str != nil)
            return nil;
        
        local cPar = gActor.commonInteriorParent(obj);
        
        for(local item = obj.location; item != cPar; item = item.location)
        {
            if(gOutStream.watchForOutput({: item.checkReachIn(gActor)}))
                return nil;
                
        }
        
        return true;
    }
    
;

/* Declare attachedTo as a property since the attachables module is optional. */

property attachedTo;

objDetached: PreCondition
    verifyPreCondition(obj)
    {
        if(obj.attachedTo != nil)
            logicalRank(90);
    }
 
    checkPreCondition(obj, allowImplicit)
    {
        /* If the object isn't attached, we're done */
        if(obj.attachedTo == nil)
            return true;
        
        if(allowImplicit && tryImplicitAction(DetachFrom, obj, obj.attachedTo))
        {
            return obj.attachedTo == nil;
        }
        
        return nil;  
    }
;
