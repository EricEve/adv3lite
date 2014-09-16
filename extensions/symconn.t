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
        foreach(local dirProp in Direction.opposites.keysToList)
        {
            /* 
             *   If this direction property on this room points to an object,
             *   then we mat need to do some setting up.
             */
            if(propType(dirProp) == TypeObject)
            {
                /* Note the object this property is attached to */
                local obj = self.(dirProp);
                
                /* Note the property pointer for the reverse direction. */
                local revProp = Direction.opposites[dirProp];
                
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
                    local dest = obj.room2;
                    
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
      *   The room to/from which this SymConnector leads. Note we can leave this
      *   to be set up by our initConnector() method.
      */
    room2 = nil
    
    /* 
     *   The room from which travel through this connector is notionally
     *   originating. Various interested routines store this value in
     *   libGlobal.curLoc.
     */
    origin = (libGlobal.curLoc)
    
    /*   
     *   Our destination depends on our origin, but note that user code can
     *   simply override this property with a room and leave our initConnector
     *   to sort everything out from there.
     */
    destination = (destFrom(origin))
    
    /*  
     *   Get the destination this SymConnector leads to when we start out from
     *   loc.
     */
    destFrom(loc)
    {
        /* If we start out from room1 then this connector leads to room2 */
        if(loc == room1)
            return room2;
        
        /* If we start out from room2 then this connector leads to room1 */
        if(loc == room2)
            return room1;
        
        /* Otherwise, it doesn't lead anywhere. */
        return nil;
    }
    
    isConnectorVisible()
    {
        /* 
         *   Cache the player character's room in libGlobal.curLoc so that we
         *   can calculate whether this connector is visible from the point of
         *   view of the player character.
         */
        libGlobal.curLoc = gPlayerChar.getOutermostRoom;
        
        /*  Then carry out the inherited handling. */
        return inherited;
    }
        
    
    travelVia(actor)
    {
        /* 
         *   Cache the player character's room in libGlobal.curLoc so that we
         *   know where we're starting from.
         */
        libGlobal.curLoc = gPlayerChar.getOutermostRoom;
        
        /*  Then carry out the inherited handling. */
        inherited(actor);
    }
    
    /*  Execute travel through this door. */
    execTravel(actor, traveler, conn)
    {
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
        if(actor == gPlayerChar && actor.isIn(destination))        
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
        if(propType(&destination) == TypeObject )
        { 
            /* Set our room2 property to our destination */
            room2 = destination;
            
            /* 
             *   Change our destination property to a method that calculates our
             *   destination based on where the traveler is starting out from.
             */
            setMethod(&destination, destMethod);            
        }
    }
;

/*  The method to be attached to the destination property of a SymConnector. */
method destMethod()
{
    /* Let our destFrom() method calculate the result. */
    return destFrom(origin);
}


class SymPassage: MultiLoc, SymConnector, Thing
    desc() 
    {
        if(gActor.isIn(room1))
            room1desc;
        else
            room2desc;
    }
    
    room1desc = nil
    room2desc = nil
    
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
    
    initConnector(loc)
    {
        inherited(loc);
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
    
    attachedDir()
    {
        local loc = gPlayerChar.getOutermostRoom;
        
        return Direction.opposites.keysToList.valWhich({d: loc.(d) == self });         
    }
    
;


class SymDoor: SymPassage
    isOpenable = true
    
    isOpen = nil
    
    checkTravelBarriers(traveler)
    {
        return delegated Door(traveler);
    }
    
    cannotGoThroughClosedDoorMsg = delegated Door
    
;


modify Direction
    opposites = [
      &east -> &west, &west -> &east, &north -> &south, &south -> &north,
        &southeast -> &northwest, &northwest -> &southeast, 
        &southwest -> &northeast, &northeast -> &southwest,
        &up -> &down, &down -> &up, &in -> &out, &out -> &in,
        &port -> &starboard, &starboard -> &port, &fore -> &aft, &aft -> &fore
    ]
;
    
    
noExit: TravelConnector
    isConnectorListed = nil
    
    canTravelerPass(actor) { return nil; }
    
    explainTravelBarrier(actor) 
    {
        actor.getOutermostRoom.cannotGoThatWay(gAction.direction);
    }
;


