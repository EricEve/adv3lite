#charset "us-ascii"
#include "advlite.h"


/* 
 *   This file contains a number of (in principle) optional classes that can be
 *   used in addition to Thing. A game does not need to use any of these classes
 *   since authors can always just set the appropriate properties on thing, but
 *   some authors may find them a convenience, or may find that using them
 *   improves the clarity of their code.
 */

class Odor: Thing
    isDecoration = true
    decorationActions = [Examine,SmellSomething]
    notImportantMsg = BMsg(only smell, '{I} {can\'t} do that to a smell. ')
    dobjFor(SmellSomething) asDobjFor(Examine)    
;

class Noise: Thing
    isDecoration = true
    decorationActions = [Examine,ListenTo]
    notImportantMsg = BMsg(only listen, '{I} {can\'t} do that to a sound. ')
    dobjFor(ListenTo) asDobjFor(Examine)    
;

class Container: Thing
    isOpen = true
    contType = In
;

class OpenableContainer: Container
    isOpen = nil
    isOpenable = true
;

class LockableContainer: OpenableContainer
    lockability = lockableWithoutKey
;

class KeyedContainer: OpenableContainer
    lockability = lockableWithKey
;


class Surface: Thing
    contType = On
;

class Platform: Surface
    isBoardable = true
;

class Booth: Container
    isEnterable= true
;

class Underside: Thing
    contType = Under
;

class RearContainer: Thing
    contType = Behind
;

class Wearable: Thing
    isWearable = true
;

class Food: Thing
    isEdible = true
;

class Fixture: Thing
    isFixed = true
;


class Decoration: Fixture
    isDecoration = true
;

class Distant: Decoration
    notImportantMsg = BMsg(distant, '{The subj cobj} {is} too far away. ')
;

/* 
 *   Make Heavy a Fixture rather than an Immovable since it should normall be
 *   obvious that something is too heavy to be moved.
 */

class Heavy: Fixture
    cannotTakeMsg = BMsg(too heavy, '{The subj dobj} {is} too heavy to move. ')
    
;

class Immovable: Thing
    dobjFor(Take)
    {
        check() { say(cannotTakeMsg); }                
    }
    
    cannotTakeMsg = BMsg(cannot take immovable, '{I} {cannot} take {the dobj).
        ')
;

class StairwayUp: TravelConnector, Thing
    dobjFor(Climb)
    {        
        action() { travelVia(gActor); }        
    }
    dobjFor(ClimbUp) asDobjFor(Climb)
    
    isFixed = true
    isClimbable = true
;

class StairwayDown: TravelConnector, Thing
    dobjFor(ClimbDown)
    {       
        action { travelVia(gActor); }
    }
    
    isFixed = true
    isClimbDownable = true
;

class Passage: TravelConnector, Thing
    dobjFor(GoThrough)
    {        
        action() { travelVia(gActor); }
    }
    
    dobjFor(Enter) asDobjFor(GoThrough)
    isFixed = true
    isGoThroughable = true
;

class PathPassage: Passage
    dobjFor(Follow) asDobjFor(GoThrough)
    dobjFor(ClimbDown) asDobjFor(GoThrough)
;

class Enterable: Fixture
    dobjFor(Enter)
    {
        verify() {}
        action() { connector.travelVia(gActor); }
    }
    
    /* 
     *   We set connector = destination since on occasion it may seem more
     *   natural to authors to set the destination property (when it leads
     *   straight to a room) and sometimes more natural to set the connector
     *   property (when it's a door, say). With connector = (destination) by
     *   default, it should work either way.
     */
    connector = (destination)
    destination = nil
;

class Switch: Thing
    isSwitchable = true
    dobjFor(Flip) asDobjFor(SwitchVague)
;

class Flashlight: Switch
    makeOn(stat)
    {
        inherited(stat);
        makeLit(stat);
    }
    
    dobjFor(Light) asDobjFor(SwitchOn)
    dobjFor(Extinguish) asDobjFor(SwitchOff)
;






 