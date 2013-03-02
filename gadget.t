#charset "us-ascii"
#include "advlite.h"

/* 
 *   This module contains definitions for various control gadgets like buttons,
 *   levers and dials.
 */


class Button: Thing
    /* a button is usually fixed to something */
    isFixed = true
    dobjFor(Push)
    {
        verify() { logicalRank(120); }
        action() { makePushed(); }
        report() { DMsg(click, 'Click!'); }
    }
    
    /* Carry out the effects of pushing the button here */
    makePushed() { }
;

/* 
 *   A Lever is object that can be in one of two positions: pulled (isPulled =
 *   true) or pushed (isPulled = nil).
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
    
    /* Carry out pushing or pulling the lever */
    makePulled(stat)
    {
        isPulled = stat;
    }
    
    dobjFor(Pull)
    {
        verify()
        {
            if(isPulled)
                illogicalNow(alreadyPulledMsg);
        }
        
        action() { makePulled(true); }
        report() { DMsg(okay pulled, 'Done|{I} {pull} {1}', gActionListStr); }
        
    }
    
    alreadyPulledMsg = BMsg(already pulled, '{The subj dobj} {is} already in the
        pulled position. ')
    
    dobjFor(Push)
    {
        verify()
        {
            if(isPushed)
                illogicalNow(alreadyPushedMsg);
        }
        
        action() { makePulled(nil); }
        report() { DMsg(okay pushed, 'Done|{I} {push} {1}', gActionListStr); }
    }
    
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
     *   case the player types it in.
     */
    
    canonicalizeSetting(val)
    {
        return val.toLower();
    }
    
    makeSetting(val)
    {
        curSetting = canonicalizeSetting(val);
    }
    
    /* Check whether the proposed setting is valid */
    
    isValidSetting(val)
    {
        val = canonicalizeSetting(val);
        return validSettings.indexOf(val) != nil;
    }
    
    canSetMeTo = true
    
    dobjFor(SetTo)
    {
        
        check()
        {
            
            if(curSetting == canonicalizeSetting(gLiteral))
                say(alreadySetMsg); 
            
            if(!isValidSetting(gLiteral))
                say(invalidSettingMsg);
        }
        
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
    
    minSetting = 0
    maxSetting = 100
    
    isValidSetting(val)
    {                
        /* if it doesn't look like a number, it's not valid */
        if (rexMatch('<digit>+', val) != val.length())
            return nil;
        
        val = toInteger(val);
        return val >= minSetting && val <= maxSetting;            
    }
        
;