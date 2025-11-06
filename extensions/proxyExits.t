#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/* 
 *   PROXYEXITS EXTENSION
 *
 *   Adds a number of predefined ProxyExit objects to adv3Lite, together with their associated
 *   SpecialTravelActions
 *
 *   This extension provides the code for doorways, passageways, paths and archways that may be
 *   mentioned in room descriptions but don't otherwise needs to be defined with separate objects
 *   (Doors, Passages, or PathPassages). Instead you can just define a TravelConnector, Room, method
 *   or string on the relevant non-directional property (doorway, passageway, pathway or archway) of
 *   the room in question, or else use the multiXXXway property of the room to say there are
 *   multiple such doors or whatever.
 */

DefSpecialTravel(Doorway, &doorway, 'doorway' | 'door'); 

/* 
 *   The doorwayProxy object places itself in every Room that defines the doorway property to handle
 *   commands aimed at generic doors/doorways mentioned in room descriptions. 
 */
doorwayProxy: ProxyExit 
    vocab = BMsg(doorway vocab, 'doorway;ordinary;door')
    desc = DMsg(doorway desc, 'A doorway is just an ordinary doorway. ')
    exitProp = &doorway
    travelAction = Doorway
    decorationActions = inherited + [Open, Close]
    cannotOpenMsg = BMsg(open doorway, 'No need in this case')
    cannotCloseMsg = BMsg(close doorway, 'No need in this case.')
    notImportantMsg = BMsg(door not important, 'There\'s no need to fiddle with such an ordinary door.
        ')
    
;

DefSpecialTravel(Passageway, &passageway, 'passageway' | 'passage'); 

/* 
 *   The passagewayProxy object places itself in every Room that defines the passageway property to
 *   handle commands aimed at generic passages mentioned in room descriptions.
 */
passagewayProxy: ProxyExit 
    vocab = BMsg(passageway vocab, 'passageway;ordinary wide narrow straight;passage')
    desc = DMsg(passageway desc, 'A passage is just an ordinary passage. ')
    exitProp = &passageway
    travelAction = Passageway
    decorationActions = inherited + [ClimbUp, ClimbDown, GoAlong, Follow]
    dobjFor(ClimbUp) asDobjFor(TravelVia)
    dobjFor(ClimbDown) asDobjFor(TravelVia)
    dobjFor(Follow) asDobjFor(TravelVia)
    dobjFor(GoAlong) asDobjFor(TravelVia)
    notImportantMsg = BMsg(passage not important, 'There\'s no need to fiddle with such an ordinary
        passage. ')
;

DefSpecialTravel(Pathway, &pathway, 'pathway' | 'path'); 

/* 
 *   The pathwayProxy object places itself in every Room that defines the pathway property to handle
 *   commands aimed at generic paths/pathways mentioned in room descriptions. 
 */
pathwayProxy: ProxyExit
    vocab = BMsg(pathway vocab, 'pathway;ordinary narrow wide broad straight windy crooked;path')
    desc = DMsg(pathway desc, 'A path is just an ordinary path. ')
    exitProp = &pathway
    travelAction = Pathway
    decorationAction = inherited + [Take, Climb, ClimbUp, ClimbDown, GoAlong, Follow]
    
    
    
    /* TAKE PATH is equivalent to GO ALONG PATH */
    dobjFor(Take)
    {
        verify()
        {
            if(!gVerbWord == 'take')
                illogical(cannotTakeMsg);           
        }
        action() { doInstead(TravelVia); }
    }
    
    dobjFor(Climb) asDobjFor(TravelVia)
     dobjFor(ClimbUp) asDobjFor(TravelVia)
    dobjFor(ClimbDown) asDobjFor(TravelVia)
    dobjFor(Follow) asDobjFor(TravelVia)
    dobjFor(GoAlong) asDobjFor(TravelVia)
    
    notImportantMsg = BMsg(path not important, 'There\'s no need to fiddle with such an ordinary
        path. ')
;

DefSpecialTravel(Archway, &archway, 'archway' | 'arch'); 

/* 
 *   The archwayProxy object places itself in every Room that defines the archway property to handle
 *   commands aimed at generic arches/archways mentioned in room descriptions. 
 */
archwayProxy: ProxyExit 
    vocab = BMsg(archway vocab, 'archway;ordinary; large small arch')
    desc = DMsg(archway desc, 'An archway is just an ordinary archway. ')
    exitProp = &archway
    travelAction = Archway    
    notImportantMsg = BMsg(arch not important, 'There\'s no need to fiddle with such an ordinary
        archway. ')
;


/* 
 *   The following multiXXXMsgs can be defined on the relevant properties of rooms that have more
 *   than one doorway/pasaage/path and/or archway mentioned in their room description.
 */
modify Room
    /* 
     *   This can be attached to the doorway property of a Room with multiple doors to explain that
     *   the player has to choose which way to go.
     */
    multiDoorMsg = DMsg(multi door, 'More than one doorway leads off from here; you\'ll have to say
        which way you want to go. ')
    
    /* 
     *   This can be attached to the pasageway property of a Room with multiple pasaages to explain
     *   that the player has to choose which way to go.
     */
    multiPassageMsg = DMsg(multi passage, 'More than one pasageway leads off from here; you\'ll have
        to say which way you want to go. ')
    
    /* 
     *   This can be attached to the pathway property of a Room with multiple paths to explain that
     *   the player has to choose which way to go.
     */
    multiPathMsg = DMsg(multi path, 'More than one path leads off from here; you\'ll have to say
        which way you want to go. ')
    
    /* 
     *   This can be attached to the archway property of a Room with multiple archways to explain
     *   that the player has to choose which way to go.
     */
    multiArchMsg = DMsg(multi arch, 'More than one archway leads off from here; you\'ll have to say
        which way you want to go. ')   
;
