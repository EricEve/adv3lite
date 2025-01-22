#charset "us-ascii"
#include <tads.h>
#include "advlite.h"

/*
 *   **********************************************************************************
 *
 *   This module provides the LookDir extension for the adv3Lite library (c) 2024 Eric Eve
 *
 *   Version 1.0  09-Dec-2024
 *
 *   The LookDir extension provides handling of a new LookDir action, which handles cdmmands of the
 *   form LOOK <DIR>, e.g., LOOK NORTH.
 *
 *   To use it, define xxxLook properties on each room where you want to provide a view in the xxx
 *   direction, for example:
 *
 *   northLook = "To the north you see a long row of pines marching into the middle distance. "
 */

    

modify LookDir
//    baseActionClaas = LookDir    
       
//    execAction(cmd)
//    {   
//        /* Get the direction the player typed in their LOOK <DIR> command. */
//        direction = cmd.verbProd.dirMatch.dir;        
//        
//        /* Let the actor's outermost visible location handle looking in that direction. */
//        gActor.outermostVisibleParent().lookDir(direction);        
//    }
    
    /* Override the handleLook() method in the main library to use our special handling. */
    handleLook()
    {
        if(!inherited))
            /* 
             *   If our inherited handling doesn't handle it, let the actor's outermost visible
             *   location handle looking in that direction.
             */
            gActor.outermostVisibleParent().lookDir(direction); 
        
    }
    
    direction = nil
    
    
;

/* Modifications to Room for the LookDir extension. */
modify Room
    lookDir(dir)
    {
        /* We can only carry out this action is there's enough light to see by. */
        if(isIlluminated)
        {
            /* Obtain the zzzLook property corresponding to the direction we want to look in. */
            local prop = dir.lookProp;
            
            /* If out location defines this property and it;s not nil, display it. */
            if(propDefined(prop) && propType(prop) != TypeNil)
                display(prop);
            /* Otherwise say there's nothing sopecial to see that way. */
            else                
                sayNothingSpecialThatWay(dir);
        }
        /* If we're in the dark, say there's not enough light to see by. */
        else
            DMsg(too dark to look that way, 'There{\'s} not enough light to see that way. ' );
    }
    
//    /* By default, translate LOOK DOWN into examining our floor object if we have one. */
//    downLook()
//    {
//        /* If we have a floor objecgt, examine it. */
//        if(floorObj)
//            doInstead(Examine, floorObj);
//        /* Otherwise say there's nothing special to see. */
//        else
//            sayNothingSpecialThatWay(downDir);
//    }
    
    /* 
     *   The command LOOK IN without an object is unlikely to make sense, so we ask the player to
     *   supply the missing direct object,
     */
    inLook()  { askForDobj(LookIn); }    
;

/* 
 *   We make some simple modifications to the Booth class to handle looking around in an enclosed
 *   Booth.
 */
modify Booth
    lookDir(dir)  {  delegated Room(dir); }
    sayNothingSpecialThatWay(dir) { delegated Room(dir); }    
    inLook() { delegated Room(); }
;
    

/* 
 *   Add a lookProp propeery to each Direction object and populate it with a pointer to the
 *   appropriate xxxLook property.
 */
modify northDir lookProp = &northLook;
modify eastDir lookProp = &eastLook;
modify southDir lookProp = &southLook;
modify westDir lookProp = &westLook;
modify northeastDir lookProp = &northeastLook;
modify southeastDir lookProp = &southeastLook;
modify southwestDir lookProp = &southwestLook;
modify northwestDir lookProp = &northwestLook;

modify starboardDir lookProp = &starboardLook;
modify portDir lookProp = &portLook;
modify foreDir lookProp = &foreLook;
modify aftDir lookProp = &aftLook;

modify upDir lookProp = &upLook;
modify downDir lookProp = &downLook;
modify inDir lookProp = &inLook;
modify outDir lookProp = &outLook;
