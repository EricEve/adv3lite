#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*
 *   postures.t
 *
 *   The POSTURES extension is intended for use with the adv3Lite library. It
 *   adds handling to keep track of actor posture (standing, sitting or lying)
 *   and for the enforcement of postures in relation to various kinsds of nested
 *   room.
 *
 *   VERSION 1
 *.  20-Jul-13
 *
 *   Usage: include this extension after the adv3Lite library but before your
 *   own game-specific files. This makes it possible to sit, stand and lie in
 *   and on various things, with the posture being tracked.
 */

posturesID: ModuleID
    name = 'Postures'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '1'    
;

/* 
 *   The Posture class is used to define the various postures used in the
 *   POSTURES EXTENSION.
 */
class Posture: object
    /* The participle (e.g. 'standing') relating to the posture. */
    participle = nil
    
    /* 
     *   The property of a potential container that must be true if the actor is
     *   to be allowed to adopt this posture in that container (e.g.
     *   &canStandInMe).
     */
    allowedInProp = nil
    
    /* 
     *   The property of a potential container that must be true if the actor is
     *   to be allowed to adopt this posture on that container (e.g.
     *   &canStandOnMe).
     */
    allowedOnProp = nil
    
    /*  
     *   The property of a potential container that contains the message to
     *   display if we can't adopt this posture in it.
     */
    cannotInMsgProp = nil
    
    /*  
     *   The property of a potential container that contains the message to
     *   display if we can't adopt this posture on it.
     */    
    cannotOnMsgProp = nil
       
    /*   
     *   A method that returns true or nil according to whether an actor can
     *   adopt this posture in/on obj, which depends on the contType of obj.
     */
    canAdoptIn(obj)
    {
        local prop = obj.contType == In ? allowedInProp : allowedOnProp;
        return obj.(prop);
    }
    
    /* 
     *   The verb phrase (subject and verb) corresponding an action that
     *   involves taking this posture.
     */
    verbPhrase = nil
;

/* The standing posture. [POSTURES EXTENSION] */
standing: Posture
    participle = BMsg(standing, 'standing')
    allowedOnProp = &canStandOnMe
    allowedInProp = &canStandInMe
    cannotInMsgProp = &cannotStandInMsg
    cannotOnMsgProp = &cannotStandOnMsg    
    verbPhrase = BMsg(i stand, '{I} {stand}')
;

/* The sitting posture [POSTURES EXTENSION] */
sitting: Posture
    participle = BMsg(sitting, 'sitting')
    allowedOnProp = &canSitOnMe
    allowedInProp = &canSitInMe
    cannotInMsgProp = &cannotSitInMsg
    cannotOnMsgProp = &cannotSitOnMsg   
    verbPhrase = BMsg(i sit, '{I} {sit}')
;

/* The lying posture {POSTURES EXTENSION] */
lying: Posture
    participle = BMsg(lying, 'lying')
    allowedOnProp = &canLieOnMe
    allowedInProp = &canLieInMe
    cannotInMsgProp = &cannotLieInMsg
    cannotOnMsgProp = &cannotLieOnMsg    
    verbPhrase = BMsg(i lie, '{I} {lie}')
;


/* Modifications to Thing needed for the POSTURES EXTENSION. */
modify Thing
    /* 
     *   The posture currently adopted by this Thing. We define this on Thing
     *   rather than Actor mainly because the player character can be a Thing,
     *   but it could also use to describe the metaphorical posture of inanimate
     *   objects (A rug lies on the floor, the jug sits on the rug, the tall
     *   grandfather clock stands by the door).
     *   [DEFINED IN POSTURES EXTENSION]
     */
    posture = standing
    
    /*   
     *   The posture that's adopted by default by an actor entering or boarding
     *   this this. [DEFINED IN POSTURES EXTENSION]
     */
    defaultPosture = standing 
    
    /*   By default we can't stand, sit or lie in anything. */
    canStandInMe = nil
    canSitInMe = nil
    canLieInMe = nil
   
    /*  
     *   Attempt to make this Thing adopt the posture pos (without changing
     *   location). [DEFINED IN POSTURES EXTENSION]
     */
    tryMakingPosture(pos)
    {
        /* 
         *   If my posture is already pos then there's nothing to do, except
         *   display a message explaining the fact.
         */
        if(posture == pos)
            DMsg(posture already adopted, '{I} {am} already {1}. ',
                 pos.participle);
        
        /*  
         *   Otherwise, if I can adopt the posture pos in my location, do so and
         *   report than I've done so.
         */
        else if(pos.canAdoptIn(location))
        {
            posture = pos;
            DMsg(okay adopt posture, 'Okay, {i} {am} {now} {1}. ', 
                 pos.participle); 
        }
        /*  
         *   Otherwise display a message saying I can't adopt the posture pos in
         *   my current location.
         */
        else
        {
            local dobj = location;
            gMessageParams(dobj);
            local prop = contType == In ? &cannotInMsgProp : &cannotOnMsgProp;
            prop = pos.(prop);
            say(self.(prop));
        }
    }
    
    /*  The postures module changes the handling for a number of verbs */
    
    /*  Modification for StandOn handling [DEFINED IN POSTURES EXTENSION] */
    dobjFor(StandOn)
    {
        remap = remapOn
        preCond = [touchObj, actorInStagingLocation]
        
        action()
        {
            /* 
             *   If the actor is already on the dobj, just try to change the
             *   actor's posture to standing.
             */
            if(gActor.location == self)
                gActor.tryMakingPosture(standing);
            else
            {
                /* Otherwise, move the actor into the dobj */
                gActor.actionMoveInto(self);
                
                /* Then change the actor's posture to standing. */
                gActor.posture = standing;                
            }
        }
        
        report()
        {
            say(okayStandOnMsg);
        }
    }
    
    /* [DEFINED IN POSTURES EXTENSION] */
    okayStandOnMsg = BMsg(okay stand on, '{I} {stand} on {1}. ', gActionListStr)
    
    /* 
     * SitOn is handled in much the same way as StandOn 
     * [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(SitOn)
    {
        remap = remapOn
        preCond = [touchObj, actorInStagingLocation]
        
        action()
        {
            if(gActor.location == self)
                gActor.tryMakingPosture(sitting);
            else
            {
                gActor.actionMoveInto(self);
                gActor.posture = sitting;               
            }
        }
        
        report()
        {
            say(okaySitOnMsg);
        }
    }
    
    /* [DEFINED IN POSTURES EXTENSION] */
    okaySitOnMsg = BMsg(okay sit on, '{I} {sit} on {1}. ', gActionListStr)
    
    /* 
     * LieOn is handled much the same way as StandOn 
     * [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(LieOn)
    {
        remap = remapOn
        preCond = [touchObj, actorInStagingLocation]
        
        action()
        {
            if(gActor.location == self)
                gActor.tryMakingPosture(lying);
            else
            {
                gActor.actionMoveInto(self);
                gActor.posture = lying;                
            }
        }
        
        report()
        {
            say(okayLieOnMsg);
        }
    
    }
    
    /* [DEFINED IN POSTURES EXTENSION] */
    okayLieOnMsg = BMsg(okay lie on, '{I} {lie} on {1}. ', gActionListStr)
            
    /* 
     *   If an actor Boards something, we need to know what posture the actor
     *   ends up in.
     *   [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(Board)
    {
        action()
        {
            /* Carry out the inherited action */
            inherited;
            
            /* 
             *   Change the actor's posture to the default posture for the
             *   actor's new location.
             */
            gActor.posture = gActor.location.defaultPosture;
        }
        
        report()
        {
            DMsg(okay get on posture, '{1} on {2}. ', gActor.posture.verbPhrase,
                 gActionListStr);
        }
    }
    
    
    
    /* 
     *   If an actor gets off something, we need to know what posture the actor
     *   ends up in. [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(GetOff)
    {
        action()
        {
            /* Carry out the inherited action. */
            inherited;            
            
            /* 
             *   Change the actor's posture to the default posture for the
             *   actor's new location.
             */
            gActor.posture = gActor.location.defaultPosture;
        }
    }
    
    /* 
     *   Common verify routine for standing, sitting or lying IN something,
     *   where pos is the posture to be adopted.
     *   [DEFINEDS IN POSTURES EXTENSION]
     */
    verifyEnterPosture(pos)
    {
        /* First verify that the actor can enter me */
        verifyDobjEnter();
        
        /* 
         *   Get the property (e.g. &canStandInMe) that determines whether the
         *   actor can adopt the posture pos in me
         */
        local postureProp = pos.allowedInProp;
        
        /* 
         *   Get the property (e.g. &cannotStandInMsg) containing the message to
         *   display is the actor can't adopt the posture pos in me.
         */
        local failureProp = pos.cannotInMsgProp;
        
        /*  
         *   If the actor can't adopt the posture pos in me then rule out the
         *   action as illogical.
         */
        if(!self.(postureProp))
            illogical(self.(failureProp));
    }
    
    /* [MODIFIED FOR POSTURES EXTENSION] */
    dobjFor(StandIn)
    {
        /* If I have a remapIn object, then remap this action to it. */
        remap = remapIn
        
        /* 
         *   Before standing in something, the actor must be able to touch it,
         *   and the actor must be in the appropriate staging location.
         */
        preCond = [touchObj, actorInStagingLocation]
        
        verify()
        {
            /* Verify that the actor can enter me and stand in me */
            verifyEnterPosture(standing);
        }
        
        action()
        {
            /* If the actor is already in me, try making the actor stand. */
            if(gActor.location == self)
                gActor.tryMakingPosture(standing);
            /* Otherwise change location and posture */
            else
            {
                /* Move the actor into me */
                gActor.actionMoveInto(self);
                
                /* Change the actor's posture to standing. */
                gActor.posture = standing;                
            }
        }
        
        report()
        {
            say(okayStandInMsg);
        }
    }
    
    /* [MODIFIED FOR POSTURES EXTENSION] */
    cannotStandInMsg = BMsg(cannot stand in, '{I} {can\'t} stand in {the dobj}.
        ')
        
    /* [MODIFIED FOR POSTURES EXTENSION] */    
    okayStandInMsg = BMsg(okay stand in, '{I} {stand} in {1}. ', gActionListStr)
    
    /* 
     *  SitIn is handled much like StandIn 
     *  [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(SitIn)
    {
        remap = remapIn
        preCond = [touchObj, actorInStagingLocation]
        
        action()
        {
            if(gActor.location == self)
                gActor.tryMakingPosture(sitting);
            else
            {
                gActor.actionMoveInto(self);
                gActor.posture = sitting;                
            }
        }
        
        report()
        {
            say(okaySitInMsg);
        }
    }
    
    /* [MODIFIED FOR POSTURES EXTENSION] */
    okaySitInMsg = BMsg(okay sit in, '{I} {sit} in {1}. ', gActionListStr)
    
    /* [MODIFIED FOR POSTURES EXTENSION] */
    cannotSitInMsg = BMsg(cannot sit in, '{I} {can\'t} sit in {the dobj}. ')
    
    /*
     *  LieIn is handled much like StandIn 
     *  [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(LieIn)
    {
        remap = remapOn
        preCond = [touchObj, actorInStagingLocation]
        
        action()
        {
            if(gActor.location == self)
                gActor.tryMakingPosture(lying);
            else
            {
                gActor.actionMoveInto(self);
                gActor.posture = lying;                   
            }
        }
        
        report()
        {
            say(okayLieInMsg);
        }
    }
    
    /* [MODIFIED FOR POSTURES EXTENSION] */
    okayLieInMsg = BMsg(okay lie in, '{I} {lie} in {1}. ', gActionListStr)
    
    /* [MODIFIED FOR POSTURES EXTENSION] */
    cannotLieInMsg = BMsg(cannot lie in, '{I} {can\'t} lie in {the dobj}. ')
    
    /* 
     *   When an actor enters something we need to determine what posture the
     *   actor ends up in.
     *   [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(Enter)
    {
        action()
        {
            /* Carry out the inherited handling */
            inherited;
            
            /* 
             *   Change the actor's posture to the default posture for the
             *   actor's new location.
             */
            gActor.posture = gActor.location.defaultPosture;
        }
    }
    
    /* 
     *   When an actor gets out of something we need to determine what posture
     *   the actor ends up in.
     *  [MODIFIED FOR POSTURES EXTENSION]
     */
    dobjFor(GetOutOf)
    {
        action()
        {
            /* Carry out the inherited handling */
            inherited;
            
            /* 
             *   Change the actor's posture to the default posture for the
             *   actor's new location.
             */
            gActor.posture = gActor.location.defaultPosture;
        }
    }
    
    /* 
     *   Include the actor's posture in the subheading (e.g. '(sitting on the
     *   chair)')
     *   [MODIFIED FOR POSTURES EXTENSION]
     */
    roomSubhead(pov)
    {
        say(nestedLoc(pov));
    }
    
    /* [MODIFIED FOR POSTURES EXTENSION] */
    nestedLoc(actor)
    {
        return BMsg(actor nested location posture name,  
                             ' (<<actor.posture.participle>>
                             <<actor.location.objInPrep>> 
                             <<actor.location.theName>>)');
    }
;

/* 
 *  Modifications to Room class for use with POSTURES EXTENSION.
 */ 
modify Room
    /* 
     *  By default we assume that an actor can sit, stand or lie in a room 
     *  [DEFINED IN POSTURES EXTENSION]
     */
    canStandInMe = true
    canSitInMe = true
    canLieInMe = true
    
    /*  
     * The name of the room as it appears in the status line. 
     * [MODIFIED FOR POSTURES EXTENSION]
     */
    statusName(actor)
    {
        local nestedLocDesc = '';
        
        /*  
         *   If the actor is not directly in the room we add the actor's
         *   immediate container in parentheses after the room name.
         */
        if(!actor.location.ofKind(Room))
            nestedLocDesc = nestedLoc(actor);
        
        /*  
         *   If the Room is illuminated, display its ordinary room title,
         *   followed by the actor's immediate location if it's not the Room. If
         *   the Room is in darkness, use the darkName instead of the roomTitle.
         */
        if(isIlluminated)
            "<<roomTitle>><<nestedLocDesc>>";
        else
            "<<darkName>><<nestedLocDesc>>";
    }
    
    
;

/* 
 *   A Bed is something an actor can sit, stand or lie on, but is most likely to
 *   lie on and least likely to stand on. [DEFINED IN POSTURES EXTENSION]
 */
class Bed: Platform
    lieOnScore = 120
    standOnScore = 80
    defaultPosture = lying
;

/*   
 *   Chair is something an actor would normally sit on, but could also stand on,
 *   but not lie on. [DEFINED IN POSTURES EXTENSION]
 */
class Chair: Platform
    canLieOnMe = nil
    sitOnScore = 120
    standOnScore = 80
    defaultPosture = sitting
;

/*  
 *   By default we assume that an actor can stand, sit or lie in a Booth. This
 *   can, of course, be overridden in particular instances.
 *   [DEFINED IN POSTURES EXTENSION]
 */
modify Booth
    canStandInMe = true
    canSitInMe = true
    canLieInMe = true
;


/*  
 *   We modify the Stand, Sit and Lie actions so that they now result in the
 *   actor changing posture without changing location.
 *   [MODIFIED IN POSTURES EXTENSION]
 */
modify Stand
    execAction(c)
    {
        gActor.tryMakingPosture(standing);
    }
;

/* [MODIFIED IN POSTURES EXTENSION] */
modify Sit
    execAction(c)
    {
        gActor.tryMakingPosture(sitting);
    }
;

/* [MODIFIED IN POSTURES EXTENSION] */
modify Lie
    execAction(c)
    {
        gActor.tryMakingPosture(lying);
    }
;

