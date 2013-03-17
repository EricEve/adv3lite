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
        report() { DMsg(okay pulled, 'Done|{I} {pull} {1}', gActionListStr); }
        
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
        report() { DMsg(okay pushed, 'Done|{I} {push} {1}', gActionListStr); }
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
class Settable: Fixture
    
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
     *   case the player types the desired setting in.
     */    
    canonicalizeSetting(val)
    {
        return val.toLower();
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
    
    okaySetMsg =  BMsg(okay set, '{I} {set} {the dobj} to {1}. ', curSetting)
    
    alreadySetMsg = BMsg(already set, '{The subj dobj} {is} already set to {1}.
        ', curSetting)
    
    /*  
     *   Most gadgets of this sort are part of or attached to something else, so
     *   we make them fixed in place by default
     */
    isFixed = true
;


/* A Dial is Simply a Settable we can turn as well as set */
class Dial: Settable
    dobjFor(TurnTo) asDobjFor(SetTo)
    canTurnMeTo = true
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
    
    /* Is val a valid setting for this dial? */
    isValidSetting(val)
    {                
        /* if it doesn't look like a number, it's not valid */
        if (rexMatch('<digit>+', val) != val.length())
            return nil;
        
        /* Convert val to an integer */
        val = toInteger(val);
        
        /* 
         *   Val is valid if it lies between our minimum and maximum settings
         *   (inclusively)
         */
        return val >= minSetting && val <= maxSetting;            
    }        
;