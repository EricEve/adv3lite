#charset "us-ascii"
#include "advlite.h"


/*
 *   ***************************************************************************
 *   precond.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve
 *
 *   Based on code in the adv3 library (c) Michael J. Roberts.
 */

/* 
 *   A PreCondition encapsulate a condition that must be fulfilled in order for
 *   an action to be fulfilled (e.g. a container must be open before we can put
 *   anything in it). A PreCondition may also try to bring about the fulfilment
 *   of the condition it enforces via an implicit action.
 */
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
     *   simply report a failure return nil to terminate the command.
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
    
/* 
 *   A precondition to check whether a container is open. If this is defined on
 *   the action handling of an object, it only takes effect if that object
 *   behaves like a container, in which case either it, or its remapIn object,
 *   must be open for the action to proceed.
 */
containerOpen: PreCondition
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   if we have a non-nil remapIn property, that's the container
         *   representing us, so we need to use it instead.
         */        
        if(obj.remapIn != nil)
            obj = obj.remapIn;
        
        
        /* 
         *   If the object is already open, we're already done; also there's
         *   nothing to be done if we're not a container (in the sense of
         *   something objects can be put in).
         */               
        if (obj == nil || obj.contType != In || obj.isOpen)
            return true;
        
        /* If we're allowed to try an implicit action, then try opening obj */
        if(allowImplicit) 
        {
            /* 
             *   Try opening obj via an implicit action and note whether tha
             *   action was actually attempted.
             */                
            local tried = tryImplicitAction(Open, obj);
            
            /* 
             *   If obj is now open, this precondition has been met, so return
             *   true.
             */
            if(obj.isOpen)
                return true;
            
            /* 
             *   Otherwise if we tried but failed to open obj, return nil to
             *   signal that we haven't met this precondition so the main action
             *   can't go ahead. The attempt to open obj will have reported the
             *   reason why it failed, so there's no need to display anything
             *   else.
             */
            if(tried)
                return nil;
        }
        
        /* 
         *   If we reach here obj is closed and we weren't allowed to try to
         *   open it; display a message explaining the problem.
         */
        gMessageParams(obj);
        DMsg(container needs to be open, '{The subj obj} need{s/ed} to be open
            for that. ');
        
        /* Then return nil to indicate that the precondition hasn't been met. */
        return nil;        
    }
    
;

/* A PreCondition to check whether an object is open. */
objOpen: PreCondition
    
    verifyPreCondition(obj)
    {
        /* 
         *   If the object isn't open already, make it a slightly less logical
         *   choice of object for this command.
         */
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
        
        /* 
         *   If we're allowed to attempt an implicit action, try opening obj
         *   implicitly and see if we succeed.
         */
        if(allowImplicit) 
        {
            /* 
             *   Try opening obj implicitly and note if we were allowed to make
             *   the attempt.
             */
            local tried = tryImplicitAction(Open, obj);
            
            /*  
             *   If obj is now open return true to signal that this precondition
             *   has now been met.
             */
            if(obj.isOpen)
                return true;
            
            /* 
             *   Otherwise, if we tried but failed to open obj, return nil to
             *   signal that this precondition can't be met (so the main action
             *   cannot proceed). The attempt to open obj will have explained
             *   why it failed, so there's no need for any further explanation
             *   here.
             */
            if(tried)
                return nil;
        }
        
        /* 
         *   If we reach here obj is closed and we weren't allowed to try to
         *   open it; display a message explaining the problem.
         */
        gMessageParams(obj);
        DMsg(object needs to be open, '{The subj obj} need{s/ed} to be open for
            that. ');
        
        /* Then return nil to indicate that the precondition hasn't been met. */
        return nil;        
    }
    
;


/* A PreCondition to check whether an object is closed. */
objClosed: PreCondition
    
    verifyPreCondition(obj)
    {
        /* 
         *   If the object is open, make it a slightly less logical choice of
         *   object for this command.
         */
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
        
        
        /* 
         *   If we're allowed to attempt an implicit action, try closing obj
         *   implicitly and see if we succeed.
         */
        if(allowImplicit) 
        {
            /* 
             *   Try closing obj implicitly and note if we were allowed to make
             *   the attempt.
             */
            local tried = tryImplicitAction(Close, obj);
            
             /*  
              *   If obj is now closed return true to signal that this
              *   precondition has now been met.
              */            
            if(!obj.isOpen)
                return true;
            
            /* 
             *   Otherwise, if we tried but failed to open obj, return nil to
             *   signal that this precondition can't be met (so the main action
             *   cannot proceed). The attempt to close obj will have explained
             *   why it failed, so there's no need for any further explanation
             *   here.
             */
            if(tried)
                return nil;
        }
        
        
        /* 
         *   If we reach here obj is open and we weren't allowed to try to
         *   close it; display a message explaining the problem.
         */
        gMessageParams(obj);        
        DMsg(obj needs to be closed, '{The subj obj} need{s/ed} to be closed for
            that. ');
        
        /* Then return nil to indicate that the precondition hasn't been met. */
        return nil;        
    }
    
;  
    
/* 
 *   A PreCondition to check whether an object is unlocked, and to attempt to
 *   unlock it if it seems possible to do so.
 */
objUnlocked: PreCondition
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   If the object is already unlocked, we're already done. If the
         *   object is neither lockableWithKey nor lockableWithoutKey there's
         *   nothing we can do here.
         */
        if (obj == nil || ! obj.isLocked 
            || obj.lockability not in (lockableWithoutKey, lockableWithKey) )
            return true;
        
        /* 
         *   If the object can be unlocked without a Key, try unlocking it
         *   implicitly
         */
        if(allowImplicit && obj.lockability == lockableWithoutKey)
        {
            /* 
             *   Try unlocking obj implicitly and note if we were allowed to make
             *   the attempt.
             */
            local tried = tryImplicitAction(Unlock, obj);
            
             /*  
              *   If obj is now unlocked return true to signal that this
              *   precondition has now been met.
              */            
            if(!obj.isLocked)
                return true;
            
            /* 
             *   Otherwise, if we tried but failed to unlock obj, return nil to
             *   signal that this precondition can't be met (so the main action
             *   cannot proceed). The attempt to unlock obj will have explained
             *   why it failed, so there's no need for any further explanation
             *   here.
             */
            if(tried)
                return nil;
        }
        
        
        /* 
         *   If the object needs a key to unlock it, attempt to unlock it with a
         *   plausible key if there is one, otherwise return true to let the
         *   OPEN action go ahead and fail.
         */
        
        if(allowImplicit && obj.lockability == lockableWithKey)
        {
            /* 
             *   Try to find a key held by the actor that may unlock this
             *   object; the result will be stored in the useKey_ property of
             *   the object.
             */
            obj.findPlausibleKey(true);
            
            /* 
             *   If we don't find a key, return TRUE to let the OPEN action go
             *   ahead and report that the object is locked, since there's
             *   nothing else we can do here.
             */
            if(obj.useKey_ == nil)
                return true;
            
            /* 
             *   Try unlocking obj with useKey_ implicitly and note if we were
             *   allowed to make the attempt.
             */
            local tried = tryImplicitAction(UnlockWith, obj, obj.useKey_);
            
             /*  
              *   If obj is now unlocked return true to signal that this
              *   precondition has now been met.
              */            
            if(!obj.isLocked)
                return true;
            
            /* 
             *   Otherwise, if we tried but failed to unlock obj, return nil to
             *   signal that this precondition can't be met (so the main action
             *   cannot proceed). The attempt to unlock obj will have explained
             *   why it failed, so there's no need for any further explanation
             *   here.
             */
            if(tried)
                return nil;
        }
        
        /* 
         *   Although the PreCondition hasn't been met, we'll return true at
         *   this point to let the OPEN action go ahead and report the problem.
         */
        
        return true;
    }
;

    
/* A PreCondition to check whether an object is currently held by the actor. */
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
        
        
        /* 
         *   If we're allowed to attempt an implicit action, try taking obj
         *   implicitly and see if we succeed.
         */
        if(allowImplicit) 
        {    
            /* 
             *   Try taking obj implicitly and note if we were allowed to make
             *   the attempt.
             */
            local tried = tryImplicitAction(Take, obj);
            
            /*  
             *   If obj is now held by the actor return true to signal that this
             *   precondition has now been met.
             */
            if(obj.isDirectlyIn(gActor))
              return true;   
            
            /* 
             *   Otherwise, if we tried but failed to take obj, return nil to
             *   signal that this precondition can't be met (so the main action
             *   cannot proceed). The attempt to take obj will have explained
             *   why it failed, so there's no need for any further explanation
             *   here.
             */
            if(tried)
                return nil;            
        }
        
        /* 
         *   If we reach here obj isn't being held by the actor and we weren't
         *   allowed to try to take it; display a message explaining the
         *   problem.
         */
        gMessageParams(obj);
        DMsg(need to hold, '{I} need{s/ed} to be holding {the obj} to do that. ');
        
        /* Then return nil to indicate that the precondition hasn't been met. */
        return nil;        
    }
;

/* A PreCondition to check that an object isn't being worn. */
objNotWorn: PreCondition
    checkPreCondition(obj, allowImplicit) 
    { 
        /* 
         *   if the object is not being worn, we're already done.
         */
        if (obj == nil || obj.wornBy != gActor)
            return true;
        
        /* 
         *   If we're allowed to attempt an implicit action, try taking off obj
         *   implicitly and see if we succeed.
         */        
        if(allowImplicit) 
        {
            /* 
             *   Try taking off obj implicitly and note if we were allowed to
             *   make the attempt.
             */
            local tried = tryImplicitAction(Doff, obj);
            
            /*  
             *   If obj is now not being worn return true to signal that this
             *   precondition has now been met.
             */
            if(obj.wornBy == nil)
                return true;
            
            /* 
             *   Otherwise, if we tried but failed to take obj off, return nil
             *   to signal that this precondition can't be met (so the main
             *   action cannot proceed). The attempt to take off obj will have
             *   explained why it failed, so there's no need for any further
             *   explanation here.
             */
            if(tried)
                return nil;
            
        }
        
        /* 
         *   If we reach here obj is still being worn and we weren't allowed to
         *   try to take it off; display a message explaining the problem.
         */
        gMessageParams(obj);
        DMsg(cannot do that while wearing, '{I} {can\'t} do that while
            {he actor}{\'m} wearing {the obj). ');
        
        /* Then return nil to indicate that the precondition hasn't been met. */
        return nil;        
    }
    
;

/* A PreCondition to check that an object is visible. */
objVisible: PreCondition
    verifyPreCondition(obj)
    {
        /* If it's too dark to see then we can't examine the object */        
        if(!(gActor.outermostVisibleParent().isIlluminated || obj.visibleInDark))
            inaccessible(obj.tooDarkToSeeMsg);
        
        /* If the actor can't see the obj then we can't examine the object. */
        if(!Q.canSee(gActor, obj))
            inaccessible(BMsg(cannot see obj, '{I} {can\'t} see {1}. ',
                         obj.theName));
    }   
;

/* A PreCondition to check that an object is audible. */
objAudible: PreCondition
    verifyPreCondition(obj)
    {
       /* 
        *   Construct a list of objects that are blocking the sound path between
        *   the actor and obj.
        */
        local lst = Q.soundBlocker(gActor, obj);
        
        /* 
         *   If the actor cannot hear obj and there's at least one object
         *   blocking the sound path between them, construct an appropriate
         *   error message and block the action.
         */      
        if(!Q.canHear(gActor, obj) && lst.length > 0)
        {            
            local errMsg;
            gMessageParams(obj);
         
            /* 
             *   If the blocking object is a Room, then obj is in a remote
             *   location, so the reason the actor can't hear it is that it's
             *   too far away.
             */
            if(lst[1].ofKind(Room))
                errMsg = BMsg(too far away to hear obj, '{The subj obj} {is} too
                    far away to hear. ');
            
            /* 
             *   Otherwise the reason the actor can't hear obj is that the first
             *   blocking object is in the way.
             */
            else           
                errMsg = BMsg(cannot hear, '{I} {can\'t} hear {1} 
                through {2}. ', obj.theName, lst[1].theName);
                
            /* Declare obj to be inaccessible to hearing. */
            inaccessible(errMsg);
        }        
    }
;

/* A PreCondition to check that an object is smellable. */
objSmellable: PreCondition
    verifyPreCondition(obj)
    {
       /* 
        *   Construct a list of objects that are blocking the scent path between
        *   the actor and obj.
        */
        local lst = Q.scentBlocker(gActor, obj);
        
        /* 
         *   If the actor cannot hear obj and there's at least one object
         *   blocking the sound path between them, construct an appropriate
         *   error message and block the action.
         */      
        if(!Q.canSmell(gActor, obj) && lst.length > 0)
        {            
            local errMsg;
            gMessageParams(obj);
         
            /* 
             *   If the blocking object is a Room, then obj is in a remote
             *   location, so the reason the actor can't hear it is that it's
             *   too far away.
             */
            if(lst[1].ofKind(Room))
                errMsg = BMsg(too far away to smell obj, '{The subj obj} {is}
                    too far away to smell. ');
            
            /* 
             *   Otherwise the reason the actor can't hear obj is that the first
             *   blocking object is in the way.
             */
            else           
                errMsg = BMsg(cannot smell, '{I} {can\'t} smell {1} 
                through {2}. ', obj.theName, lst[1].theName);
                
            /* Declare obj to be inaccessible to hearing. */
            inaccessible(errMsg);
        }        
    }
;

/* 
 *   A PreCondition to check that an object can be touched (which is likely to
 *   be needed for any action that manipulated the object). This Precondition
 *   farms out as much of the detailed checking as possible to the Query object. 
 */
touchObj: PreCondition
    
    
    verifyPreCondition(obj)
    {
        /* 
         *   Store any issues that the Query object finds with reaching obj from
         *   gActor
         */
        local reachIssues = Q.reachProblemVerify(gActor, obj);
        
        /*  Run the verify method of any issues we found */
        foreach(local issue in reachIssues)        
            issue.verify();        
    }
    
    
    
    checkPreCondition(obj, allowImplicit)
    {
        /* 
         *   Obtain any issues the Query object finds with reaching obj from
         *   gActor at the check stage.
         */
        
        local reachIssues = Q.reachProblemCheck(gActor, obj);
        
        /* 
         *   Go through each stored issue in turn running its check method; if
         *   any of the check methods return nil, exit and return nil.
         */        
        foreach(local issue in reachIssues)
        {
            if(issue.check(allowImplicit) == nil)
                return nil;
        }
               
        /* 
         *   If we reach here we've passed all the checks, so return true to
         *   indicate success.
         */
        return true;
    }
    
    
    preCondOrder = 80    
;

/* Declare attachedTo as a property since the attachables module is optional. */
property attachedTo;
property attachedToList;


/* A PreCondition to check that an object isn't attached to anything. */
objDetached: PreCondition
    verifyPreCondition(obj)
    {
        /* 
         *   An object that is attached may be a slightly less logical choice
         *   for this action.
         */
        if(obj.attachedTo != nil)
            logicalRank(90);
    }
 
    checkPreCondition(obj, allowImplicit)
    {
        /* If the object isn't attached, we're done */
        if(obj.attachedToList.length == 0)
            return true;
        
         /* 
          *   If we're allowed to attempt an implicit action, try detaching obj
          *   implicitly and see if we succeed.
          */
        if(allowImplicit)            
        {
            /* 
             *   Try detaching obj implicitly and note if we were allowed to
             *   make the attempt.
             */
            local tried = nil;
                
            foreach(local cur in obj.attachedToList)
                tried = tryImplicitAction(DetachFrom, obj, cur);
            
            /*  
             *   If obj is now not attached to anything return true to signal
             *   that this precondition has now been met.
             */
            if(obj.attachedToList.length == 0)
               return true;
            
            /* 
             *   Otherwise, if we tried but failed to detach obj, return nil to
             *   signal that this precondition can't be met (so the main action
             *   cannot proceed). The attempt to detach obj will have explained
             *   why it failed, so there's no need for any further explanation
             *   here.
             */
            if(tried)
                return nil;
        }
        
        /* 
         *   If we reach here obj is still attached to something and we weren't
         *   allowed to try to detach it; display a message explaining the
         *   problem.
         */
        local att = obj.attachedTo;
        gMessageParams(obj, att);
        
        DMsg(cannot do that while attached, '{I} {can\'t} do that while {the subj
            obj} is attached to {the att). ');
        
        /* Then return nil to indicate that the precondition hasn't been met. */
        return nil;  
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   A pre-condition that applies to a specific, pre-determined object,
 *   rather than the direct/indirect object of the command.
 */
class ObjectPreCondition: PreCondition
    construct(obj, cond)
    {
        /* 
         *   remember the specific object I act upon, and the underlying
         *   precondition to apply to that object 
         */
        obj_ = obj;
        cond_ = cond;
    }

    /* route our check to the pre-condition using our specific object */
    checkPreCondition(obj, allowImplicit)
    {
        /* check the precondition */
        return cond_.checkPreCondition(obj_, allowImplicit);
    }

    /* route our verification check to the pre-condition */
    verifyPreCondition(obj)
    {
        cond_.verifyPreCondition(obj_);
    }

    /* use the same order as our underlying condition */
    preCondOrder = (cond_.preCondOrder)

    /* the object we check with the condition */
    obj_ = nil

    /* the pre-condition we check */
    cond_ = nil
;

/* -------------------------------------------------------------------------- */

actorInStagingLocation: PreCondition
    checkPreCondition(obj, allowImplicit)
    {
        local loc = gActor.location;
        local stagingLoc = obj.stagingLocation;
        local action;
        
        /* If the actor's location is the staging location then we're done. */
        if(loc == stagingLoc)
            return true;
        
        if(stagingLoc == nil)
        {
            gMessageParams(obj);
            DMsg(no staging loc, '{The subj obj} {can\'t} be reached. ');
            return nil;
        }
        
        if(allowImplicit)
        {
            local tried = nil;
            
            while(!stagingLoc.isOrIsIn(loc))
            {
                action = loc.contType == In ? GetOutOf : GetOff;
                tried = tryImplicitAction(action, loc);
                if(gActor.location == loc)
                    break;
                
                loc = gActor.location;
            }
                                  
            if(stagingLoc == loc)
                return true;
            
            local path = [];
            local step = stagingLoc;
            
            while(step != loc)
            {
                path = [step] + path;
                step = step.stagingLocation;
            }
            
            foreach(step in path)
            {
                action = step.contType == In ? Enter : Board;
                tried = tryImplicitAction(action, step);                
                if(gActor.location != step)
                    break;
            }
            
            if(stagingLoc == gActor.location)
                return true;
            
            if(tried)
                return nil;
            
            
        }
        
        gMessageParams(stagingLoc);
        
        DMsg(not in staging location, '{I} need{s/ed} to be <<if
              stagingLoc.ofKind(Room)>> directly <<end>>
            {in stagingloc} to do that. ');
    
         /* Then return nil to indicate that the precondition hasn't been met. */
        return nil;  
        
    }    
;
