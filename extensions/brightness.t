#charset "us-ascii"
#include "advlite.h"

/*
 *.   Brightness Exteension for adv3Lite
 *.   Version 1.0   29-Oct-22
 *.   Eric Eve
 *.
 *   This extension provides much of the adv3 ligthting levels functionality in a slightly different
 *   form for the adv3Lite library.
 *
 *   It adds brightness and opacity properties to the Thing class, as well as a brightnessWithin()
 *   method which returns the current brightness within a room or booth (which is taken to be the
 *   brightness of its brightest available light source). The opacity property takes effect only on
 *   a container that is defined as transparent, in which case the opacity is the loss of brightness
 *   for a light source shining in or out of that container.
 *
 *   The extension is set up to mimic the adv3 brightness scale, in that a brightness of 0 equates
 *   to darkness, a brightness of 1 is a self-illuminating object (or isVisibleInDark) that doesn't
 *   illuminate anything else, a brightness of 2 provides dim light that's sufficient for examining
 *   one's environment but not enough to read by, a brightness of 3 is normal light, and a
 *   brightness of 4 is an especially bright light, but game code can implement a differnent scale
 *   if desired.
 *
 *   There are limitations to the realism of this brightness model, for example it doesn't
 *   accumulate the brightness of multiple light sources, and offers only limited handling of light
 *   sources in remote locations in the same SenseRegion. Also, apart from imposing a minimum
 *   brightness level required for reading and providing the means to model loss of brightness at a
 *   distance or through a semi-transparent medium, it has very little impact on game behaviour out
 *   of the box; for the most part, it is up to game code to decide what it wants to do with the
 *   brightness mechanism provided.
 */

modify Thing
    
    /* Our brightness when lit [BRIGHTNESS EXTENSION] */
    brightnessOn = 3
    
    /* 
     *   Our brightness when unlit. This would normally be 0, but if we're visible in the dark it
     *   will be 1. [BRIGHTNESS EXTENSION]
     */
    brightnessOff = (visibleInDark ? 1 : 0)
    
    
    /*
     *   [BRIGHTNESS EXTENSION]
     *
     *   The strength of the light the object is giving off, if indeed it is giving off light.  This
     *   value should be one of the following:
     *
     *   0: The object is giving off no light at all.
     *
     *   1: The object is self-illuminating, but doesn't give off enough light to illuminate any
     *   other objects.  This is suitable for something like an LED digital clock.
     *
     *   2: The object gives off dim light.  This level is bright enough to illuminate nearby
     *   objects, but not enough to go through obscuring media, and not enough for certain
     *   activities requiring strong lighting, such as reading.
     *
     *   3: The object gives off medium light.  This level is bright enough to illuminate nearby
     *   objects, and is enough for most activities, including reading and the like.  Traveling
     *   through an obscuring medium reduces this level to dim (2).
     *
     *   4: The object gives off strong light.  This level is bright enough to illuminate nearby
     *   objects, and travel through an obscuring medium reduces it to medium light (3).
     *
     *   There is nothing to stop game code using a higher value still to model a a super-powerful
     *   light source if that seems suitable to the situation being modelled in the game, but this
     *   probably will only rarely be necessary.
     *
     *   Note that the special value -1 is reserved as an invalid level, used to flag certain events
     *   (such as the need to recalculate the ambient light level from a new point of view).
     *
     *   Most objects do not give off light at all.
     *
     *   Return the appropriate on/off brightness, depending on whether or not we're currently lit
     */
    brightness = (isLit ? brightnessOn : brightnessOff)
    
    /*   
     *   [BRIGHTNESS EXTENSION]
     *
     *   Our opacity is the extent to which we reduce the brightness of any light that passes
     *   through us. An opacity of 4 or more will cut off the brightest light, while an opacity of 0
     *   means we're transparent. By default we have an opacity of 0 if we're transparent and 4
     *   otherwise.
     *
     *   Note that if we want any light to penetrate us at all we should set transparency to true
     *   (we're at least somewhat light permeable) and then set opacity to some suitable value (if
     *   we don't want it to be zero, which is otherwise the default for a transparent object).
     */     
    opacity = (isTransparent ? 0 : 4)
    
    /*
     *   [BRIGHTNESS EXTENSION]
     *
     *   Our remote brightness when viewed from pov, where pov is in a remote location. By default
     *   we just return our brightness, but game code may wish to override when, for example, we're
     *   a torch/flashlight that's been dropped on the far side of a field at night.
     */
    remoteBrightness(pov)
    {
        return brightness;
    }
    
    /*   
     *   How bright is it within us (assuming, in practice, that we're either a Room or an enterable
     *   container (aka Booth)? [BRIGHTNESS EXTENSION]
     */
    brightnessWithin()
    {        
        /* Move a light probe inside us. */
        lightProbe_.moveInto(self);
        
        try
        {
            /* Set up a local variable to hold our brightness within and initialize it to zero. */
            local bw = 0;
            
            /* 
             *   Set up a local variable to hold a list of available light sources, for possible use
             *   by game code which wants to develop an algorithm for accumulating the overall
             *   brightness of multiple sources.
             */
            local lightSources_ = new Vector(10);
            
            /* Cache the scopeList of our lightProbe object. */
            local sl = Q.scopeList(lightProbe_).toList();
            
            /* 
             *   If we've included the SensseRegion extension and our enclosing room is in at least
             *   one SenseRegion, then add all the potential light sources in all the rooms in all
             *   the SenseRegions we're located in to our scope list.
             */
            if(defined(QSenseRegion) 
               && valToList(lightProbe_.getOutermostRoom().regions).indexWhich(
                   {r: r.ofKind(SenseRegion)}))
            {
                foreach(local reg in getOutermostRoom.regions)
                {
                    if(reg.ofKind(SenseRegion) && reg.canSeeAcross)
                    {
                        foreach(local rm in reg.roomList)
                        {
                            foreach(local o in rm.allContents)
                            {
                                if(o.remoteBrightness(lightProbe_) > 1)
                                    sl = sl.appendUnique([o]);
                            }
                        }
                    }
                       
                }
            }
            
            
            
            /* Iterate over the light probe's scope list */
            foreach(local obj in sl)
            {
                /* 
                 *   Note the object's brightness, which is simply the value of its brightness
                 *   property if its in the same room as us, or otherwise the value returned by its
                 *   remote brightness method.
                 */
                local bt = obj.isIn(getOutermostRoom) ? obj.brightness : obj.remoteBrightness(self);
                
                /* 
                 *   Create a local variable to contain a list of objects that might potentially
                 *   come between the obj and the light probe.
                 */
                local blockers;
                
                /* 
                 *   If obj has a brightness (adjusted for remoteness if necessary)) that's greater
                 *   than our illuminationThreshold and the obj is in the same room as the light
                 *   probe, then we need to look for objects that might intervene in the sight path.
                 */
                if(bt > illuminationThreshold && obj.isIn(lightProbe_.getOutermostRoom))
                {                   
                    /* 
                     *   First get the lists of objects that might lie between obj and the light
                     *   probe.
                     */
                    blockers = lightProbe_.containerPath(obj);
                    
                    /*   
                     *   If we have the same container (blocker[2] == self] then no objects
                     *   intervene and there's nothing more we need to do, so we only need to do
                     *   more if we have different containers.
                     */
//                    if(blockers[2] != self)
                    {
                        /* 
                         *   Iterate outwards over all the objects that might intervene between the
                         *   lightProbe and obj up to their common container.
                         */
                        foreach(local cur in blockers[1])
                        {
                            /* We're only interested in objects that are closed containers */
                            if(cur.contType == In && !cur.isOpen)
                                
                                /* 
                                 *   if we find one, deduct its opacity from the brightness
                                 *   lightProbe_ picks up from obj.
                                 */
                                bt -= cur.opacity;
                        }
                        
                        /* Then do the same iterating inwards. */
                        foreach(local cur in blockers[3])
                        {
                            if(cur.contType == In && !cur.isOpen)
                                bt -= cur.opacity;
                        }
                    }
                }
                /* 
                 *   Otherwise, if obj is in a remote location but has a remote brightness > 1,
                 *   interate outwards from obj to its containing room and inwards from the
                 *   lightprobe's containing room to the light probe.
                 */
                else if(bt > 1)
                {
                    blockers = obj.containerPath(obj.getOutermostRoom);
                    
                    foreach(local cur in blockers[1])
                    {
                        if(cur.contType == In && !cur.isOpen)
                                bt -= cur.opacity;
                    }
                    
                    blockers = getOutermostRoom.containerPath(lightProbe_);
                   
                    foreach(local cur in blockers[3])
                    {
                        if(cur.contType == In && !cur.isOpen)
                                bt -= cur.opacity;
                    }
                    
                }
                
                /* 
                 *   If we've found a brightness that's greater than that of any previous object's
                 *   brightness, update our potential brightness within to that object's brightness.
                 */
                if(bt > bw)
                    bw = bt;
                
                /*   
                 *   Add both the object and its adjusted brightness to our list of lightSources,
                 *   provided the adjusted brightness exceeds our brightness threshold.
                 */
                if(bt > illuminationThreshold)
                    lightSources_ += [obj, bt];
                
            }
            
            /* 
             *   Convert the lightSources_ Vector to a list and store it in our lightSources
             *   property.
             */
            lightSources = lightSources_.toList();
            
            /* 
             *   Provided the highest brightness level we've found is greater than zero, return that
             *   brightness level, otherwise return zero
             .*/
            return (bw > 0 ? bw : 0);
        }
        
        /* Clean up by ensuring we remove the light probe from the game map. */
        finally
        {
            lightProbe_.moveInto(nil);
        }
    }
        
    /* 
     *   The list of lightSources and their adjusted (for opacity and/or distance) brightness
     *   generated by the most recent call to brightnessWithin(). Each element in the list is itself
     *   a two-element list of the form [obj, adjustedBrightness] where obj is the object providing
     *   light and adjustedBrightness is the brightness of that object adjusted for transmission
     *   through distance or partial opacity. [BRIGHTNESS EXTENSION]
     */
    lightSources = []
    
    
    /*
         [BRIGHTNESS EXTENSION]
         
         This is little more than a hook for user code to provide its own means of accumulating the
         brightness from multiple light sources. 
     */
    accumulatedBrightnessWithin()
    {
        /* 
         *   First call the brightessWithin() method to ensure we update the lightSources property
         *   and also so we can store the value as it returns as the maximum brightness of any
         *   individual available light source.
         */
        local maxBrightness = brightnessWithin();
        
        /*  
         *   Return the value of our accumlateBrightness() method. By default this will simply be
         *   our maxBrightness.
         */
        return accumulateBrightness(maxBrightness);
    }
        
    
    /* 
     *   [BRIGHTNESS EXTENSION] The accumulateBrightness() method is a stub (or hook) for a
     *   user-defined algorithm for accumulating the brightness of multiple ligjt sources if this is
     *   desired. By default we simply return the value of the maxBrightness parameter that is
     *   passed to us (which is the brightness returned by the latest call to brightnessWithin()),
     *   but game code can override this method to provide some other calculation of accumulated
     *   brightness by iterating over the list of objects and their adjusted brightnesses in our
     *   lightSources property.
     *
     *   Note that accumulateBrightness is provided to allow it to be readily overridden by game
     *   code, but is not designed to be directly called from game code, which should  call it only
     *   via accumulatedBrightnessWithin();
     */
    accumulateBrightness(maxBrightness)
    {
        return maxBrightness;
    }
    
    /* 
     *   [BRIGHTNESS EXTENSION]
     *
     *   Change the definition of having sufficient light to see by to have an accumulated brightess
     *   within greater than our illumination threshold. We only do this if the light probe is
     *   off-stage, however, since otherwise we'll cause a stack overflow via a circular reference
     *   while the brightnessWithin is being calculated; if the lightProbe_ is in use we accordingly
     *   fall back on the inherited handling. (This will need looking at since it prevents
     *   recogition of a light source in a remote location in the same SenseRegion).
     */
    isIlluminated()
    {
        if(lightProbe_.location == nil)        
            return accumulatedBrightnessWithin() > illuminationThreshold;
        else
            return inherited();
    }    
    
    /* 
     *   For the purposes of the BRIGHTNESS EXTENSION, litWithin() should return the same result as
     *   isIlluminated.
     */    
    litWithin()
    {
        return isIlluminated();
    }
    
    
    /* 
     *   [BRIGHTNESS EXTENSION]
     *
     *   The illumination threshold is the available brightness (returned by the brightnessWithin
     *   method) that needs to be exceeded in our interior to be able to examine objects or look
     *   around or satisfy other visibility criteris (mostly where the objVisible precondition is
     *   applies to the current action). The default illuminationThreshold is 1, which mimics the
     *   behaviour of both the adv3 library and the adv3Lite library in the absence of this
     *   extension. 
     */
    illuminationThreshold = 1
    /*  
     *   The brightness needed for us to be able to read this object (as opposed to merely examine
     *   it) By default we'll set this at 3 (the brightness used by adv3) but game code can overrife
     *   this to some other value if desired. [BRIGHTNESS EXTENSION]
     */
    brightnessForReading = 3
    
    /*   
     *   If the available light is less than the light we need to read this item (its
     *   brightnessForReading) then stop the read action at the check stage by displaying our
     *   tooDarkToReadMsg.
     */
    dobjFor(Read)
    {        
        check()
        {
            inherited();
            
            if(interiorParent.accumulatedBrightnessWithin() < brightnessForReading)
                say (tooDarkToReadMsg);
        }
    }
    
    /* The message to display if there's not enough light to read this item. [BRIGHTNESS EXTENSION]*/
    tooDarkToReadMsg = BMsg(too dark to read, 'There{\'s} not enough light {here} to read 
        {the dobj}. ');
;

/* 
 *   Test object used in the measurement of the brightness level within a container. [BRIGHTNESS
 *   EXTENSION]
 */
lightProbe_:Thing
;