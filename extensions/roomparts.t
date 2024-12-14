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
 *   common to many locations. [DEFINED IN ROOMPARTS EXTENSION]
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

/* 
 * The class used for room parts that represent walls. 
 * [DEFINED IN ROOMPARTS EXTENSION]
 */
class DefaultWall: RoomPart 'wall'
    isInitiallyIn(obj) { return obj.wallObjs.indexOf(self) != nil; }
    
;

/* 
 *   Modifications to the Room class to allow for room parts. Note that the
 *   standard adv3Lite library already supplies a foor in every room defined via
 *   its floorObj property. [MODIFIED FOR ROOMPARTS EXTENSION]
 */
modify Room
    /* 
     *   The ceilingObj property defines the object to be used for this Room's
     *   ceiling. By default we use the defaultCeiling object defined below.
     *   [DEFINED IN ROOMPARTS EXTENSION]
     */
    ceilingObj = defaultCeiling
    
    /* 
     *   The wallObjs property defines the list of walls in this Room. By
     *   default we use the four default walls. Particular rooms that don't
     *   have four walls (e.g. a length of passage) or which want to use
     *   custom wall objects can override this.
     *  [DEFINED IN ROOMPARTS EXTENSION]
     */
    wallObjs = [defaultNorthWall, defaultEastWall, defaultSouthWall,
        defaultWestWall]
;

/* 
 *  An OutdoorRoom is a room that has no walls and a sky instead of a ceiling 
 *  [DEFINED IN ROOMPARTS EXTENSION]
 */
class OutdoorRoom: Room
    ceilingObj = defaultSky
    wallObjs = []
;

/* 
 * The four default walls 
 * [DEFINED IN ROOMPARTS EXTENSION]
 */
defaultNorthWall: DefaultWall 'north +; (n)';

/* [DEFINED IN ROOMPARTS EXTENSION] */
defaultEastWall: DefaultWall 'east +; (e)';

/* [DEFINED IN ROOMPARTS EXTENSION] */
defaultSouthWall: DefaultWall 'south +; (s)';

/* [DEFINED IN ROOMPARTS EXTENSION] */
defaultWestWall: DefaultWall 'west +; (w)';

/* 
 * The class for ceiling/sky objects 
 * [DEFINED IN ROOMPARTS EXTENSION]
 */
class Ceiling: RoomPart
    isInitiallyIn(obj) { return obj.ceilingObj == self; }
;

/* 
 * The default ceiling that appears in every Room 
 * [DEFINED IN ROOMPARTS EXTENSION]
 */
defaultCeiling: Ceiling 'ceiling';

/* 
 *  The default sky that appears in every OutsideRoom 
 * [DEFINED IN ROOMPARTS EXTENSION]
 */
defaultSky: Ceiling 'sky'    
    notImportantMsg = BMsg(sky beyond reach, '{The subj cobj} {is} way beyond
        {my} reach. ')
;

/* 
 *   The Floor class is defined in the standard adv3Lite library. Here we modify
 *   it to use the ROOMPART EXTENSIONS's version of examineStatus.
 */
modify Floor
    /* [MODIFIED IN ROOMPARTS EXTENSION to use the ROOMPART EXTENSIONS's version of examineStatus] */
    examineStatus()
    {
        delegated RoomPart;
    }
;

/*  
 *   Modifications to Thing to allow things to be associated with room parts.
 *   Note that a Thing associated with a room part should be directly located in
 *   the room, not in the room part. [MODIFIED FOR ROOMPARTS EXTENSION]
 */
modify Thing
    /* 
     *   Note, the following two properties only take effect if the Thing is
     *   directly in its enclosing Room
     */
    
    /* 
     *   The room part (e.g. defaultNorthWall) with which we're notionally
     *   associated. [DEFINED IN ROOMPARTS EXTENSION]
     */
    roomPart = nil
    
    /*  
     *   The description of ourselves to be displayed when our associated
     *   roomPart is examined. [DEFINED IN ROOMPARTS EXTENSION]
     */
    roomPartDesc = nil
    
    /* 
     *   We modify actionMoveInto here so that an action that results in moving
     *   an object (e.g. taking a picture that's notionally hanging on a wall)
     *   removes the association between the object and its room part.
     *   [MODIFIED FOR ROOMPARTS EXTENSION]
     */
    actionMoveInto(dest)
    {
        /* carry out the inherited handling. */
        inherited(dest);
        
        /* If I'm moved I'm no longer associated with my original room part */
        roomPart = nil;
    }
;


