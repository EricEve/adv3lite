#charset "us-ascii"
#include "advlite.h"



class RoomPart: MultiLoc, Decoration
    initialLocationClass = Room
    
    examineStatus()
    {
        inherited;
        
        local lst = gPlayerChar.getOutermostRoom.contents.subset(
            { o: o.roomPart == self });
        
        foreach(local cur in lst)
            cur.roomPartDesc;
    }
;


class DefaultWall: RoomPart 'wall'
    isInitiallyIn(obj) { return obj.wallObjs.indexOf(self) != nil; }
    
;

modify Room
    ceilingObj = defaultCeiling
    wallObjs = [defaultNorthWall, defaultEastWall, defaultSouthWall,
        defaultWestWall]
;

class OutdoorRoom: Room
    ceilingObj = defaultSky
    wallObjs = []
;


defaultNorthWall: DefaultWall 'north +; (n)';
defaultEastWall: DefaultWall 'east +; (e)';
defaultSouthWall: DefaultWall 'south +; (s)';
defaultWestWall: DefaultWall 'west +; (w)';

Ceiling: RoomPart
    isInitiallyIn(obj) { return obj.ceilingObj == self; }
;

modify Floor
    examineStatus()
    {
        delegated RoomPart;
    }
;

modify Thing
    /* 
     *   Note, the following two properties only take effect if the Thing is
     *   directly in its enclosing Room
     */
    roomPart = nil
    roomPartDesc = nil
    
    actionMoveInto(dest)
    {
        inherited(dest);
        
        /* If I'm moved I'm no longer associated with my original room part */
        roomPart = nil;
    }
;

defaultCeiling: Ceiling 'ceiling';
defaultSky: Ceiling 'sky'
    notImportantMsg = '{The subj cobj} {is} way beyond {my} reach. '
;

//field: OutdoorRoom 'Field' 'field'
//;
//
//sun: MultiLoc, Distant 'sun'
//    initialLocationClass = OutdoorRoom
//    
//    roomPart = defaultSky
//    roomPartDesc = "The sun is shining brightly in the sky. "
//;