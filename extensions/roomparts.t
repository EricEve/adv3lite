#charset "us-ascii"
#include "advlite.h"

/* 
 *   roomparts.t
 *
 *   The ROOMPARTS extension is intended for use with the adv3Lite library. It
 *   adds walls and a ceiling to every Room. It also adds an OutdoorRoom class
 *   that has only ground and sky. It also allows Things to be associated with
 *   particular room parts, such as a picture hanging on a wall.
 *
 *   VERSION 1
 *.  20-Jul-13
 *
 *   Usage: include this extension after the adv3Lite library but before your
 *   own game-specific files. This will add four walls and a ceiling to every
 *   Room in your game. For outdoor rooms that have only sky and ground, use the
 *   OutdoorRoom class defined below.
 */

roomPartID: ModuleID
    name = 'Room Parts'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '1'    
;


/* 
 *   The RoomPart class is used to define room parts (walls, ceiling, sky)
 *   common to many locations.
 */
class RoomPart: MultiLoc, Decoration
    initialLocationClass = Room
    
    /* 
     *   When examining a room part we list all the roomPartDescs of all the
     *   items in the room associated with this RoomPart.
     */
    examineStatus()
    {
        /* Carry out the inherited handling */
        inherited;
        
        /* 
         *   Construct a list of all the items directly in the current room for
         *   whom we're the associated roomPart.
         */
        local lst = gPlayerChar.getOutermostRoom.contents.subset(
            { o: o.roomPart == self });
        
        /* Show the roomPartDesc for every item in our list. */
        foreach(local cur in lst)
            cur.roomPartDesc;
    }
;

/* The class used for room parts that represent walls. */
class DefaultWall: RoomPart 'wall'
    isInitiallyIn(obj) { return obj.wallObjs.indexOf(self) != nil; }
    
;

/* 
 *   Modifications to the Room class to allow for room parts. Note that the
 *   standard adv3Lite library already supplies a foor in every room defined via
 *   its floorObj property.
 */
modify Room
    /* 
     *   The ceilingObj property defines the object to be used for this Room's
     *   ceiling. By default we use the defaultCeiling object defined below.
     */
    ceilingObj = defaultCeiling
    
    /* 
     *   The wallObjs property defines the list of walls in this Room. By
     *   default we define use the four default walls. Particular rooms that
     *   don't have four walls (e.g. a length of passage) or which want to use
     *   custom wall objects can override this.
     */
    wallObjs = [defaultNorthWall, defaultEastWall, defaultSouthWall,
        defaultWestWall]
;

/* An OutdoorRoom is a room that has no walls and a sky instead of a ceiling */
class OutdoorRoom: Room
    ceilingObj = defaultSky
    wallObjs = []
;

/* The four default walls */
defaultNorthWall: DefaultWall 'north +; (n)';
defaultEastWall: DefaultWall 'east +; (e)';
defaultSouthWall: DefaultWall 'south +; (s)';
defaultWestWall: DefaultWall 'west +; (w)';

/* The class for ceiling/sky objects */
class Ceiling: RoomPart
    isInitiallyIn(obj) { return obj.ceilingObj == self; }
;

/* The default ceiling that appears in every Room */
defaultCeiling: Ceiling 'ceiling';

/* The default sky that appeares in every OutsideRoom */
defaultSky: Ceiling 'sky'    
    notImportantMsg = BMsg(sky beyond reach, '{The subj cobj} {is} way beyond
        {my} reach. ')
;

/* 
 *   The Floor class is defined in the standard adv3Lite library. Here we modify
 *   it to use the RoomPart version of examineStatus.
 */
modify Floor
    examineStatus()
    {
        delegated RoomPart;
    }
;

/*  
 *   Modifications to Thing to allow things to be associated with room parts.
 *   Note that a Thing associated with a room part should be directly located in
 *   the room, not in the room part.
 */
modify Thing
    /* 
     *   Note, the following two properties only take effect if the Thing is
     *   directly in its enclosing Room
     */
    
    /* 
     *   The room part (e.g. defaultNorthWall) with which we're notionally
     *   associated.
     */
    roomPart = nil
    
    /*  
     *   The description of ourselves to be displayed when our associated
     *   roomPart is examined.
     */
    roomPartDesc = nil
    
    /* 
     *   We modify actionMoveInto here so that an action that results in moving
     *   an object (e.g. taking a picture that's notionally hanging on a wall)
     *   removes the association between the object and its room part.
     */
    actionMoveInto(dest)
    {
        /* carry out the inherited handling. */
        inherited(dest);
        
        /* If I'm moved I'm no longer associated with my original room part */
        roomPart = nil;
    }
;


