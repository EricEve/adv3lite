#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

class Posture: object
    participle = nil
    allowedInProp = nil
    allowedOnProp = nil
    cannotInMsgProp = nil
    cannotOnMsgProp = nil
    
    canAdoptIn(obj)
    {
        local prop = obj.contType == In ? allowedInProp : allowedOnProp;
        return obj.(prop);
    }
    
    
;

standing: Posture
    participle = BMsg(standing, 'standing')
    allowedOnProp = &canStandOnMe
    allowedInProp = &canStandInMe
    cannotInMsgProp = &cannotStandInMsg
    cannotOnMsgProp = &cannotStandOnMsg
    
    
;

sitting: Posture
    participle = BMsg(sitting, 'sitting')
    allowedOnProp = &canSitOnMe
    allowedInProp = &canSitInMe
    cannotInMsgProp = &cannotSitInMsg
    cannotOnMsgProp = &cannotSitOnMsg
;

lying: Posture
    participle = BMsg(lying, 'lying')
    allowedOnProp = &canLieOnMe
    allowedInProp = &canLieInMe
    cannotInMsgProp = &cannotLieInMsg
    cannotOnMsgProp = &cannotLieOnMsg
;


modify Thing
    posture = standing
    canStandInMe = nil
    canSitInMe = nil
    canLieInMe = nil
   
    tryMakingPosture(pos)
    {
        if(posture == pos)
            DMsg(posture already adopted, '{I} {am} already {1}. ',
                 pos.participle);
        else if(pos.canAdoptIn(location))
        {
            posture = pos;
            DMsg(okay adopt posture, 'Okay, {i} {am} {now} {1}. ', 
                 pos.participle); 
        }
        else
        {
            local dobj = location;
            gMessageParams(dobj);
            local prop = contType == In ? &cannotInMsgProp : &cannotOnMsgProp;
            prop = pos.(prop);
            say(self.(prop));
        }
    }
    
    dobjFor(StandOn)
    {
        remap = remapOn
        
        action()
        {
            if(gActor.location == self)
                gActor.tryMakingPosture(standing);
            else
            {
                gActor.actionMoveInto(self);
                gActor.posture = standing;
                "{I} {stand} on {the dobj}. ";
            }
        }
    }
    
    dobjFor(SitOn)
    {
        remap = remapOn
        
        action()
        {
            if(gActor.location == self)
                gActor.tryMakingPosture(sitting);
            else
            {
                gActor.actionMoveInto(self);
                gActor.posture = sitting;
                "{I} {sit} on {the dobj}. ";
            }
        }
    }
    
    dobjFor(LieOn)
    {
        remap = remapOn
        
        action()
        {
            if(gActor.location == self)
                gActor.tryMakingPosture(lying);
            else
            {
                gActor.actionMoveInto(self);
                gActor.posture = lying;
                "{I} {lie} on {the dobj}. ";
            }
        }
    }
;

modify Room
    canStandInMe = true
    canSitInMe = true
    canLieInMe = true
    
    /*  The name of the room as it appears in the status line. */
    statusName(actor)
    {
        local nestedLoc = '';
        
        /*  
         *   If the actor is not directly in the room we add the actor's
         *   immediate container in parentheses after the room name.
         */
        if(!actor.location.ofKind(Room))
            nestedLoc = BMsg(actor nested location posture name,  
                             ' (<<actor.posture.participle>>
                             <<actor.location.objInPrep>> 
                <<actor.location.theName>>)');
        
        /*  
         *   If the Room is illuminated, display its ordinary room title,
         *   followed by the actor's immediate location if it's not the Room. If
         *   the Room is in darkness, use the darkName instead of the roomTitle.
         */
        if(isIlluminated)
            "<<roomTitle>><<nestedLoc>>";
        else
            "<<darkName>><<nestedLoc>>";
    }
;

modify Stand
    execAction(c)
    {
        gActor.tryMakingPosture(standing);
    }
;

modify Sit
    execAction(c)
    {
        gActor.tryMakingPosture(sitting);
    }
;

modify Lie
    execAction(c)
    {
        gActor.tryMakingPosture(lying);
    }
;

