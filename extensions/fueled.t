#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*
 *   fueled.t
 *
 *   The FUELED LIGHT SOURCE extension is intended for use with the adv3Lite
 *   library. It provides the FueledLightSource mix-in class which can be used
 *   to implement a light source with limited life.
 *
 *   VERSION 1
 *.  21-Jul-13
 *
 *   Usage: include this extension after the adv3Lite library but before your
 *   own game-specific files. Make sure that events.t is also included in your
 *   build.
 */


fueledID: ModuleID
    name = 'Fueled Light Source'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '1'    
;

class FueledLightSource: object
    /* 
     *   The source of our fuel. By default this is self, but it could be an
     *   external source such as a battery
     */
    fuelSource = self
    
    /*   
     *   Our remaining fuel level. The default is a modest level but this can be
     *   overridden on particular instances.
     */
    fuelLevel = 20
    
    /*   A note of our fuelDaemon's ID, if one is running. */
    fuelDaemonID = nil
    
    /*  
     *   Start our fuelDaemon running in a SenseDaemon (so no messages are
     *   displayed if the player character can't see us).
     */
    startFuelDaemon()
    {
        if(fuelDaemonID == nil)
            fuelDaemonID = new SenseDaemon(self, &fuelDaemon, 1);
    }
    
    /*  
     *   Stop the fuelDaemon; first check that we actually have one and then
     *   disable it.
     */
    stopFuelDaemon()
    {
        if(fuelDaemonID != nil)
        {
            fuelDaemonID.removeEvent();
            fuelDaemonID = nil;
        }
    }
    
    /*  The fuelDaemon is executed every turn this object is lit */
    fuelDaemon()
    {
        /* Reduce the fuel level of our fuel source */
        fuelSource.fuelLevel--;
        
        /* Optionally show a warning message if the fuel is running low. */
        showWarning();
        
        /* 
         *   If we're out of fuel, stop the fuelDaemon, make us no longer it,
         *   and display a message explaining that we've just gone out.
         */
        if(fuelSource.fuelLevel < 1)
        {
            stopFuelDaemon();
            isLit = nil;
            sayBurnedOut(true);
        }
    }
    
    /* 
     *   The showWarning() message can be used to display a message warning when
     *   this light source is about to go out. One way to do this would be via a
     *   switch statement that looks at the value of fuelSource.fuelLevel and
     *   displays warning messages when that reaches low values. There's no need
     *   for this message to display anything when the fuelLevel is zero,
     *   however, since that is handled by sayBurnedOut().
     */
    showWarning() { }
    
    /*  The message to display when we run out of fuel */
    sayBurnedOut(fromDaemon?)
    {
        /* Create a convenient message parameter substitution */
        local obj = self;        
        gMessageParams(obj);
        
        /* Say that we've gone out. */
        say(burnedOutMsg);
        
        /* 
         *   If our going out has left the player character in darkness, say so.
         */
        if(!gPlayerChar.location.litWithin && fromDaemon)
            say(plungedIntoDarknessMsg);
        ". ";
    }
    
    burnedOutMsg = BMsg(say burned out, '{The subj obj} {goes} out')
    plungedIntoDarknessMsg = BMsg(plunged into darkness, ', plunging {1} into
        darkness', gPlayerChar.theName)
    
    /* Modifications to the makeLit() method for FueledLightSource */
    makeLit(stat)
    {
        /* 
         *   If someone's trying to make us lit and we don't have a fuel source
         *   or our fuel source is out of fuel, say that we won't light and stop
         *   there.
         */
        if(stat && (fuelSource == nil || fuelSource.fuelLevel < 1))
        {
            say(wontLightMsg);
            return;
        }
        
        /*  
         *   If we're being lit, start our fuelDaemon, otherwise, stop our
         *   fuelDaemon.
         */
        if(stat)
            startFuelDaemon();
        else
            stopFuelDaemon();
        
        /*  Carry out the inherited handling. */
        inherited(stat);        
    }
    
    /*  
     *   The message to display when we can't be lit because we have no fuel.
     *   Most instances will probably want to override this to something more
     *   specific.
     */
    wontLightMsg = BMsg(wont light, '\^{1} {dummy} {won\'t} light. ', theName)
    
    /* 
     *   If we have an external fuel source then removing or disabling it will
     *   have certain consequences, so code that, for example, you can call this
     *   method if a battery is removed from a flashlight.
     */
    removeFuelSource()
    {
        if(isLit)
        {
            isLit = nil;
            stopFuelDaemon();
            sayBurnedOut();           
        }
        fuelSource = nil;
    }
        
;