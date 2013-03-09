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
    PushTravelVia = PushTravelClimbUp
    
    /*  Display message announcing that traveler has left via this staircase. */
    sayDeparting(traveler)
    {
        gMessageParams(traveler);
        DMsg(say departing up stairs, '{The subj traveler} {leaves} up
            {1}. ', theName);
    }
;

class StairwayDown: TravelConnector, Thing
    dobjFor(ClimbDown)
    {       
        action { travelVia(gActor); }
    }
    
    isFixed = true
    canClimbDownMe = true
    PushTravelVia = PushTravelClimbDown
    
    /*  Display message announcing that traveler has left via this staircase. */
    sayDeparting(traveler)
    {
        gMessageParams(traveler);
        DMsg(say departing down stairs, '{The subj traveler} {leaves} down
            {1}. ', theName);
    }
;

class Passage: TravelConnector, Thing
    dobjFor(GoThrough)
    {        
        action() { travelVia(gActor); }
    }
    
    dobjFor(Enter) asDobjFor(GoThrough)
    isFixed = true
    canGoThroughMe = true
    PushTravelVia = PushTravelThrough
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
    
    iobjFor(PushTravelEnter)
    {
        preCond = [touchObj]
        
        check() { connector.checkPushTravel(); }
        
        action()
        {
            if(connector.PushTravelVia)
                replaceAction(connector.PushTravelVia, gDobj, connector);
            
            connector.travelVia(gDobj);
            if(gDobj.isIn(connector.destination))
            {
                say(okayPushIntoMsg);
                connector.travelVia(gActor);
            }           
        }
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
    isEnterable = true
    
;

/* 
 *   A SecretDoor is a Door that doesn't appear to be a door when it's closed,
 *   and which must be opened by some external mechanism (other than an OPEN
 *   command)
 */
class SecretDoor: Door
    /* You can only go through a SecretDoor when it's open */
    canGoThroughMe = isOpen
    
    /* A SecretDoor only functions as a TravelConnector when it's open */
    isConnectorApparent = isOpen   
    
    /* 
     *   We can't use an OPEN command to open a SecretDoor, but by default we'll
     *   allow a CLOSE command to close it. To disallow this override isOpenable
     *   to nil
     */
    isOpenable = isOpen
    
    /*   
     *   The vocab string (including the name) that applies to this SecretDoor
     *   when it's open. This might be somewhat different from that which
     *   applies when it's closed. For example, opening a bookcase might turn it
     *   into a passage or an opening. If you don't want to the vocab to change
     *   when this SecretDoor is opened and closed, leave vocabWhenOpen as nil.
     */
     
    vocabWhenOpen = nil
    
    /*  
     *   The vocab string (including the name) that applies to this SecretDoor
     *   when it's closed. If the SecretDoor starts out closed there's no need
     *   to define this explicitly as it will be copied from the vocab property
     *   at preInit.
     *
     *   To define a SecretDoor that's effectively invisible when closed, give
     *   it a vocab property comprising an empty string (i.e. '', not nil); this
     *   will make it impossible for the player to refer to it when it's closed.
     */
    vocabWhenClosed = nil
    
    /*   Preinitialize a SecretDoor */
    preinitThing()
    {
        /* Carry out the inherited handling */
        inherited();
        
        /* 
         *   If the door starts out open, copy its initial vocab to its
         *   vocabWhenOpen property.
         */
        if(isOpen)
            vocabWhenOpen = vocab;
        
        /*  
         *   If the door starts out closed, copy its initial vocab to its
         *   vocabWhenClosed property.
         */
        else
            vocabWhenClosed = vocab;
    }
    
    /* Carry out opening or closing a SecretDoor */
    makeOpen(stat)
    {
        /* Perform the inherited handling */
        inherited(stat);
        
        /* 
         *   If we're opening the SecretDoor and it has a non-nil vocabWhenOpen
         *   property and its vocabWhenOpen property is different from its
         *   current vocab, then reinitialize its vocab from the vocabWhenOpen
         *   property.
         */
        if(stat && vocabWhenOpen && vocab != vocabWhenOpen)
            replaceVocab(vocabWhenOpen);
        
        /* 
         *   If we're closing the SecretDoor and it has a non-nil
         *   vocabWhenClosed property and its vocabWhenClosed property is
         *   different from its current vocab, then reinitialize its vocab from
         *   the vocabWhenClosed property.
         */
        if(!stat && vocabWhenClosed && vocab != vocabWhenClosed)
            replaceVocab(vocabWhenClosed);
    }
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






 