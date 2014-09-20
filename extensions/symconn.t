#charset "us-ascii"
#include "advlite.h"

/*---------------------------------------------------------------------------*/
/*
 *   SYMMETRICAL CONNECTOR (SYMCONN) EXTENSION
 */

/* Modification to Room for SymConn (symmetrical connector) extension */
modify Room
    /* 
     *   Modified for SymConn extension to set up symmetrical connectors at
     *   preinit.
     */
    preinitThing()
    {
        /* Carry out the inherited handling. */
        inherited();
        
        /* 
         *   Go through each direction property listed in the
         *   Direction.opposites LookupTable.
         */
        foreach(local dir in Direction.allDirections)
        {
                   
            /* 
             *   If this direction property on this room points to an object,
             *   then we mat need to do some setting up.
             */
            if(propType(dir.dirProp) == TypeObject)
            {
                /* Note the object this property is attached to */
                local obj = self.(dir.dirProp);
                
                /* Note the property pointer for the reverse direction. */
                local revProp = Direction.oppositeProp(dir.dirProp);
                
                /* 
                 *   If the object is a Room and its reverse direction property
                 *   is nil, then point that other room's reverse direction
                 *   property to us, to make a symmetrical connection.
                 */
                if(obj.ofKind(Room) && obj.propType(revProp) == TypeNil)
                    obj.(revProp) = self;
                                
                /*  
                 *   If the object is a SymConnector we need to carry out a
                 *   different kind of initialization.
                 */
                if(obj.ofKind(SymConnector))
                {
                    /* First get the object to initialize itself. */
                    obj.initConnector(self);
                    
                    /* 
                     *   Note the destination to which the SymConnector should
                     *   lead from the current room.
                     */
                    local dest = (obj.room2 == self ? obj.room1 : obj.room2);
                    
                    /*  
                     *   If that destination's reverse direction property isn't
                     *   already set, set it to point to the SymConnector.
                     */
                    if(dest.propType(revProp) == TypeNil)
                        dest.(revProp) = obj;
                }
            }
            
        }
    }
;

/* 
 *   A Symmetrical Connector is a special type of TravelConnector between rooms
 *   that can be traversed in either direction and that, optionally, can largely
 *   set itself up so that if the dir property of room1 points to this
 *   SymConnector, the reverse dir property of room2 also points to this
 *   SymConnector.
 */
class SymConnector: TravelConnector
    
    /* 
     *   The room from/to which this SymConnector leads. Note we can leave this
     *   to be set up by our initConnector() method.
     */
    room1 = nil
    
     /* 
      *   The room to/from which this SymConnector leads.
      */
    room2 = nil
     
    
    /*   
     *   Our destination depends on our origin.
     */
    getDestination(origin)
    {
        /* If we start out from room1 then this connector leads to room2 */
        if(origin == room1)
            return room2;
        
        /* If we start out from room2 then this connector leads to room1 */
        if(origin == room2)
            return room1;
        
        /* Otherwise, it doesn't lead anywhere. */
        return nil;
    }
    
    /*  
     *   Our notional destination (if this is defined it will be copied to room2
     *   at preinit).
     */
    destination = nil
        

    /*  Execute travel through this connector. */
    execTravel(actor, traveler, conn)
    {
        /* Note the actor's starting location. */
        local loc = actor.getOutermostRoom();
        
        /* 
         *   Carry out the inherited handling (which delegates most of the work
         *   to our destination).
         */
        inherited(actor, traveler, conn);        
        
        
        /*  
         *   If the actor carrying out the travel is the player character, note
         *   that the player character now knows where both sides of the
         *   connector lead to.
         */
        if(actor == gPlayerChar && actor.isIn(getDestination(loc)))        
        {             
            isDestinationKnown = true;
        }
    }
    
    /*   
     *   By default the player character doesn't start off knowing where this
     *   connector leads. Once the pc has been through the connector in either
     *   direction this becomes true on both sides of the connector.
     */
    isDestinationKnown = nil
    
    /*   A SymConnector is usually open. */
    isOpen = true
    
    /*  
     *   Initialize this SymConnector. This method is normally called from the
     *   preinitThing() method of the room that first defines this connector.
     */
    initConnector(loc)
    {
        /*  
         *   If room1 hasn't been defined yet, set it to loc (the room whose
         *   preinitThing() method has called this method).
         */
        if(room1 == nil)
            room1 = loc;
        
        /*  
         *   If our destination property has been set to an object (which should
         *   be a room), carry out some further setting up.
         */
        if(propType(&destination) == TypeObject && room2 == nil)
        { 
            /* Set our room2 property to our destination */
            room2 = destination;          
        }
    }
;

/* 
 *   A Symmetrical Passage is a single passage object that can be traversed in
 *   either direction and exists in both the locations it connects.
 */
class SymPassage: MultiLoc, SymConnector, Thing
    
    /* 
     *   By default we can vary the description of the passage according to the
     *   location of the actor (and hence, according to which side it's viewed
     *   from), but if we want the passage to be described in the same way from
     *   both sides then we can simply override the desc property with a single
     *   description.
     */
    desc() 
    {
        if(gActor.isIn(room1))
            room1desc;
        else
            room2desc;
    }
    
    /*  Our description as seen from room1 */
    room1desc = nil
    
    /*  Our description as seen from room2 */
    room2desc = nil
    
    /*  A passage is generally something fixed in place. */
    isFixed = true
    
     /*  Going through a passage is the same as traveling via it. */
    dobjFor(GoThrough)
    {
        action() { travelVia(gActor); }
    }
    
    /*  Entering a passage is the same as going through it. */
    dobjFor(Enter) asDobjFor(GoThrough)
        
    
     /*   A Passage is something it makes sense to go through. */
    canGoThroughMe = true
    
    /*  
     *   The appropriate action for pushing an object via a passage is
     *   PushTravelThrough
     */
    PushTravelVia = PushTravelThrough
    
    /*   Initialize this passage (called at preinit from Room.preinitThing) */
    initConnector(loc)
    {
        /* Carry out the inherited (SymConnector) handling. */
        inherited(loc);
        
        /* 
         *   Move this passage into the two locations where it has a physical
         *   presence.
         */
        moveIntoAdd(room1);
        moveIntoAdd(room2);
    }
    
    /*  
     *   Display message announcing that traveler has left via this door. The
     *   traveler would normally be an NPC visible to the player character.
     */
    sayDeparting(traveler)
    {
        delegated Door(traveler);       
    }
    
    /* 
     *   Display message announcing that follower is following leader through
     *   this door.
     */
    sayActorFollowing(follower, leader)
    {
        delegated Door(follower, leader);        
    }
    
    
    traversalMsg = delegated Door
    
    /* 
     *   Returns the direction property to which this passage is connected in
     *   the player character's current location, e.g. &west. This is used by
     *   DirState to add the appropriate adjective (e.g. 'west') to our vocab,
     *   so that the player can refer to us by the direction in which we lead.
     *   If you don't want this direction to be included in the vocab of this
     *   object, override attachedDir to nil.
     */
    attachedDir()
    {
        /* Get the player character's current room location. */
        local loc = gPlayerChar.getOutermostRoom;
        
        /*  
         *   Get the direction object whose dirProp corresponds to the dirProp
         *   on the room which points to this object (we do this because
         *   Direction.allDirections provides the only way to get at a list of
         *   every dirProp).
         */
        local dir = Direction.allDirections.valWhich(
            { d: loc.propType(d.dirProp) == TypeObject 
            && loc.(d.dirProp) == self });
        
        /* 
         *   Return the direction property of that location which points to this
         *   passage.
         */
        return dir == nil ? nil : dir.dirProp;         
    }
    
;

/*  
 *   A Symmetrical Door is a door that can be traversed in either direction and
 *   exists in both the locations it connects. It behaves much like a regular
 *   Door, except that it uses only one object, not two, to represent the door.
 */
class SymDoor: SymPassage
    /* A door is usually openable. */
    isOpenable = true
    
    /* A door usually starts out closed. */
    isOpen = nil
    
    /* 
     *   Although SymDoor doesn't inherit from Door, it needs to use Door's
     *   checkTravelBarriers() method to attempt to open the door via an
     *   implicit action if an attempt is made to go through it when it's
     *   closed.
     */
    checkTravelBarriers(traveler)
    {
        return delegated Door(traveler);
    }
    
    /*  
     *   If we can't go through the door, use Door's version of the appropriate
     *   method.
     */
    cannotGoThroughClosedDoorMsg = delegated Door
    
;
    
    
/* 
 *   The noExit object can be used to block an exit that would otherwise be set
 *   as a reciprocal exit by Room.preinitThing(). This can be used to prevent
 *   this extension from creating symmetrical exits in cases where you don't
 *   want them. E.g. if north from the smallCave leads to largeCave, but south
 *   from largeCave doesn't lead anywhere (because the notional passage between
 *   the caves curves round, say), then you can set largeCave.south to noExit to
 *   prevent this extension from setting it to smallCave.
 *
 *   The noExit object is thus a TravelConnector that simulates the effect of a
 *   nil exit in situations where a nil value might get overwritten by this
 *   extension.
 */
noExit: TravelConnector
    /* 
     *   Since we're mimicking the absence of an exit, we don't want to be
     *   listed as one.
     */
    isConnectorListed = nil
    
    /*   We're not a real exit, so no actor can pass through us. */
    canTravelerPass(actor) { return nil; }
    
    /*   
     *   In order to behave just as a nil exit would, we call the actor's
     *   location's cannotGoThatWay() method to explain why travel isn't
     *   possible.
     */
    explainTravelBarrier(actor) 
    {
        actor.getOutermostRoom.cannotGoThatWay(gAction.direction);
    }
;


