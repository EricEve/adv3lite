#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/* 
 *   VIEWPORT EXTENSION
 *
 *   Adds the Viewport mix-in class to adv3Lite
 *
 *   A Viewport is an object that allows you to look into one room from another
 *   when you examine it or look through it (say); this can be used to model
 *   windows or CCTV monitors and the like.
 *
 *   VERSION 1
 *.  27-Jul-13
 *
 *   Usage: include this extension after the adv3Lite library but before your
 *   own game-specific files. The senseRegion.t module must also be present.
 */


viewportID: ModuleID
    name = 'Viewport'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '1'    
;

/*  
 *   Viewport is a mix-in class which can be added to an object representing a
 *   window or TV screen or the like to describe the remote location viewable
 *   via the viewport.
 *   [DEFINED ON VIEWPORT EXTENSION]
 */
class Viewport: object   
    
    /* 
     *   Method to display a description of the rooms and contents visible by
     *   means of me. [VIEWPORT EXTENSION]
     */
    describeVisibleRooms()
    {
       
        foreach(local rm in valToList(visibleRooms))
        {
            rm.describeRemotely();
            
            /*  Note that this room has now been viewed. */
            getOutermostRoom.roomsViewed = 
                getOutermostRoom.roomsViewed.appendUnique([rm]);
        }
        
    }
        
    /* 
     *   A list of rooms that are made visible by looking through or at this
     *   viewport. [VIEWPORT EXTENSION]
     */
    visibleRooms = []  
    
    
    /*   Set the list of visible rooms to lst [VIEWPORT EXTENSION] */
    setRooms(lst)
    {
        /* Ensure that lst is actually a list. */
        lst = valToList(lst);
        
        local loc = getOutermostRoom();
        
        /* 
         *   Provided we have an outermost room, set its roomsViewed property to
         *   the list of rooms roomsViewed has in common with list; this ensures
         *   that only those rooms that this Viewport continues to overlook
         *   remain in scope.
         */
        if(loc)
            loc.roomsViewed = loc.roomsViewed.intersect(lst);
        
        /* Change the list of visible rooms to lst. */
        visibleRooms = lst;
    }
    
    
    /*   
     *   Flag: can I see into the visibleRooms by looking through this object?
     *   This should normally be true for a window-type object but probably nil
     *   for a CCTV monitor. {VIEWPORT EXTENSION]
     */
    lookThroughToView = true
    
    /*   
     *   Flag: should examining this object display a description of the visible
     *   rooms and their contents? By default it should. [VIEWPORT EXTENSION]
     */
    examineToView = true
    
    /*  
     *   Is the Viewport currently available for viewing through (it may not be
     *   if windows cover the curtain, or the CCTV screen has been turned off).
	 *   [VIEWPORT EXTENSION]
     */
    isViewing = true
    
	/*
	 *  For the VIEWPORT EXTENSION add desribing rooms visible through this viewport 
	 *  to the inherited behaviour 
	 */
    dobjFor(LookThrough)
    {
        action()
        {
            if(lookThroughToView && isViewing)
                describeVisibleRooms();
            else
                inherited;
        }
    }
    
    /* 
     *   If examining this Viewport should describe what it shows, add a
     *   description of the rooms it overlooks. [VIEWPORT EXTENSION]
     */
    examineStatus()
    {
       if(examineToView && isViewing)
            describeVisibleRooms();
        else
            inherited;       
    }        
;

/*  
 *   A SwitchableViewport is one that only brings its remote rooms into view
 *   when it's switched on. [DEFINED ON VIEWPORT EXTENSION]
 */
class SwitchableViewport: Viewport
    isSwitchable = true
    isViewing = (isOn)
    
    makeOn(stat)
    {
        /* 
         *   When we turn a SwitchableViewport off we must remove its list from
         *   rooms viewed from its locations list of visibleRooms, since they're
         *   no longer visible.
         */
        if(!stat)
            getOutermostRoom.roomsViewed -= visibleRooms;
        
        inherited(stat);
    }
    
    /* 
     *   Since a SwitchableViewport will typically be used to implement
     *   something like a CCTV screen, by default it's not something we'd look
     *   through in order to view the remote locations.
     */
    lookThroughToView = nil
;


/*  Modifications to Room class for VIEWPORT EXTENSION */
modify Room
    /* 
     *   The roomRemoteDesc() is the description of the room as seen via a
     *   Viewport from pov. [DEFINED ON VIEWPORT EXTENSION]
     */
    roomRemoteDesc(pov) {  }
    
    /*   
     *   The list of rooms viewed from Viewports from within this room. This
     *   enables the player to refer to objects in rooms that have been viewed.
     *   [DEFINED ON VIEWPORT EXTENSION]
     */
    roomsViewed = []
    
    /*  
     *   Reset the list of rooms viewed when the player character leaves the
     *   room. [MODIFIED FOR VIEWPORT EXTENSION]
     */
    notifyDeparture(traveler, dest)
    {
        inherited(traveler, dest);
        
        if(traveler == gPlayerChar)
            roomsViewed = [];
    }
    
    /*  
     *   Once the player character has viewed remote rooms and their contents
     *   via a Viewport, the player may want to refer to them in commands, if
     *   only to examine them, so we need to add them to scope.
     *   [MODIFIED FOR VIEWPORT EXTENSION]
     */
    addExtraScopeItems(action)
    {
        inherited(action);
        
        local remotes = new Vector(10);
        
        foreach(local rm in valToList(roomsViewed))
        {
            remotes.appendAll(rm.allContents.subset(
                {o: o.isVisibleFrom(gActor) }));
            
            remotes.append(rm);
        }
        
        action.scopeList = action.scopeList.appendUnique(remotes);                           
    }
    
    /*  [MODIFIED FOR VIEWPORT EXTENSION] */
    dobjFor(Examine)
    {
        action()
        {
            if(gActor.isIn(self))
                inherited;
            else
                describeRemotely();
        }
        
    }
    
    /* 
     *  [DEFINED ON VIEWPORT EXTENSION] Used for describing a Room when seen through
     *  a Viewport.
     */
    describeRemotely()
    {
        /* Begin by showing the room's roomRemoteDes() */
        roomRemoteDesc(gActor);
        
        /* 
         *   Unmention all the room's contents so they will be included in any
         *   listing of contents.
         */
        unmention(allContents);
        
        /*   Display a list of the room's contents. */
        showFirstRemoteSpecials(gActor);
        showRemoteMiscContents(gActor);
        showSecondRemoteSpecials(gActor);
    }
;

/* 
 *   This Special allows the player character to see objects in remote rooms
 *   once they have been viewed via a Viewport. [DEFINED ON VIEWPORT EXTENSION]
 */
QViewport: Special
   /*
    * When the VIEWPORT EXTENSION is in use, make objects in remote rooms visisble
	* once they have been viewed via a Viewport. 
 	*/
    canSee(a, b)
    {
        local ar = a.getOutermostRoom, br = b.getOutermostRoom;
        if(ar && ar.roomsViewed.indexOf(br) && b.isVisibleFrom(a))
            return true;
        
        return next();
    }
    priority = 4
    active = true
;