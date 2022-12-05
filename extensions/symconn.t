#charset "us-ascii"
#include "advlite.h"

/*---------------------------------------------------------------------------*/
/*
 *   SYMMETRICAL CONNECTOR (SYMCONN) EXTENSION
 */


symconnID: ModuleID
    name = 'Symconn'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '2'    
;

/* Modification to Room for SymConn (symmetrical connector) extension */
modify Room
    /* 
     *   Modified for SYMCOMM EXTENSION to set up symmetrical connectors at
     *   preinit.
     */
    preinitThing()
    {
        /* Carry out the inherited handling. */
        inherited();
        
        /* 
         *   Go through each direction property listed in the Direction.opposites LookupTable.
         */
        foreach(local dir in Direction.allDirections)
        {
            
            /* 
             *   If this direction property on this room points to an object, then we may need to do
             *   some setting up.
             */
            if(propType(dir.dirProp) == TypeObject)
            {
                /* Note the object this property is attached to */
                local obj = self.(dir.dirProp);
                
                /* Note the property pointer for the reverse direction. */
                local revProp = Direction.oppositeProp(dir.dirProp);             
                
                /* 
                 *   If the object is a Room and its reverse direction property is nil, and the room
                 *   has no connection back to us, then point that other room's reverse direction
                 *   property to us, to make a symmetrical connection, provided we want reverse
                 *   connections set up automatically.
                 */
                if(obj.ofKind(Room) && obj.propType(revProp) == TypeNil
                   && autoBackConnections && !obj.getDirectionTo(self))
                    obj.(revProp) = self;
                
                /*  
                 *   If the object is a SymConnector we need to carry out a different kind of
                 *   initialization.
                 */
                if(obj.ofKind(SymConnector))
                {
                    /* First get the object to initialize itself. */
                    obj.initConnector(self, dir);
                    
                    /* 
                     *   Note the destination to which the SymConnector should lead from the current
                     *   room. This may be nil if we're initializing this SymConnector from both its
                     *   rooms and we haven't initialized it from the other side yet.
                     */
                    local dest = (obj.room2 == self ? obj.room1 : obj.room2);
                    
                    dest = dest ?? obj.destination;
                    
                    /*  
                     *   If we have a destination and that destination's reverse direction property
                     *   isn't already set, and the destination has no other direction set to the
                     *   SymConnector, and we want to set up reverse directions automatically, then
                     *   set the reverse direction to point to the SymConnector.
                     */
                    if(dest && dest.propType(revProp) == TypeNil && !dest.getDirection(obj)
                       && autoBackConnections)
                    {
                        dest.(revProp) = obj;
                        
                        if(obj.room1 == self && obj.room2Dir == nil)
                            obj.room2Dir = Direction.allDirections.valWhich({d: d.dirProp ==
                                revProp});
                    }
                    
                                         
                }
                /* 
                 *   If we're attached to a TravelConnector that's neither a SymmConnector nor a
                 *   Room, and autoBackConnection is true, and it's not a Door, try
                 *   to set the reverse connection if it does not already exist.
                 */
                else if(obj.ofKind(TravelConnector) && autoBackConnections && !obj.ofKind(Room) 
                        && !obj.ofKind(Door))
                {
                    /* Note the destination to which this TravelConnector leads. */
                    local dest = obj.getDestination(self);
                    
                    /* 
                     *   If we have a destination and there's no way back from it to here and the
                     *   reverse direction property of our destination is nil, then set that
                     *   property to point back to us.
                     */
                    if(dest && !dest.getDirectionTo(self) && dest.propType(revProp) == TypeNil)
                    {
                        dest.(revProp) = self;                        
                    }                   
                }                
                
                /* 
                 *   Ensure that any UnlistedProxyConnectors - usually defined by means of the
                 *   asExit(macro) - are matched by an UnlistedProxyConnector in the opposite
                 *   direction in destination room where the direction in question is either up or
                 *   down, provided we want to create automatic back connections.
                 */
                if(obj.ofKind(UnlistedProxyConnector) && dir.dirProp is in (&up, &down)
                    && autoBackConnections)
                {
                    local dest;
                    
                    /* 
                     *   obtain the direction property for which the 
                     *   UnlistedProxyConnector is a proxy.
                     */
                    local proxyProp = obj.direction.dirProp;
                    
                    /*  
                     *   If this direction property points to an object, get its destination
                     *   (assuming it's a TravelConnector or Room).
                     */
                    if(propType(proxyProp) == TypeObject)
                        dest = self.(proxyProp).getDestination(self);
                    
                    /*  
                     *   If we've found a destination, and its corresponding down or up property is
                     *   undefined, then set up an UnlistedProxyConnector accordingly.
                     */
                    if(dest && dest.propType(revProp) == TypeNil)
                    {
                        local backDir = dest.getDirectionTo(self);                        
                        
                        if(backDir)
                            dest.(revProp) = new UnlistedProxyConnector(backDir);
                    }
                    
                }           
                              
            }            
        }   
        
    }
    
    /* 
     *   Flag - do we want the library (specifically the preInit method of Thing) to automatically
     *   create connections back (in the reverse direction) from any rooms our direction properties
     *   (directlt, or indirectly via a TravelConnector) point to? By default we do (since that was
     *   the part of the original purpose of the SymmConn extension) but game code can set this to
     *   nil (either on the Room class or on individual rooms) to suppress it if it's not wanted -
     *   which may be the case if the this extension is being used for SymmConnectors rather than
     *   automated back connections.     */
         
    autoBackConnections = true
    
    /* 
     *   update the vocab of any SymPassages in our contents list that have seperate room1Vocab and
     *   room2Vocab
     */
    updateSymVocab()
    {
        /* loop through our contents */
        foreach(local obj in contents)            
        {
            /* 
             *   We're only interested in SymPassages (and subclasses thereof) that define both
             *   their room1Vocab and room2Vocab properties as single-quoted strings.
             */
            if(obj.ofKind(SymPassage) && obj.propType(&room1Vocab) == TypeSString 
               && obj.propType(&room2Vocab) == TypeSString)
            {
                /* 
                 *   The new vocab we want to update this obj with is is room1Vocab if we're in its
                 *   room1 and its room2Vocab otherwise.
                 */
                local newVocab = (obj.room1 == self ? obj.room1Vocab : obj.room2Vocab);
                
                /*   Update the vocab on obj. */
                obj.replaceVocab(newVocab);
            
            }
        }
    }
    
    /*  
     *   Modified in SYMCONN EXTENSION to update the vocab on any SymPassages in our destination.
     */
    notifyDeparture(traveler, dest)
    {
        /* first carry out the inherited handling */
        inherited(traveler, dest);
        
        /* then update the vocab on our destination's SymPassages */        
        if(gPlayerChar.isOrIsIn(traveler))
            dest.updateSymVocab();
    }
;

/* Modification to DirState for SymConn (symmetrical connector) extension */
modify DirState    
    /* 
     *   We exclude SymStairway because including 'up' or 'down' in its vocab confuses the parser's
     *   interpretation of CLIMB UP and CLIMB DOWN.
     */
    appliesTo(obj)
    {
        return inherited(obj) && ! obj.ofKind(SymStairway);
    }
;

/* 
 *   Ensure that the vocab of any SymPassages located in the player character's starting location
 *   have the vocab appropriate to the side from which they're viewed.
 */
symVocabPreinit: PreinitObject
    exec()
    {
        gPlayerChar.getOutermostRoom.updateSymVocab();
    }
    
    /* 
     *   The updateSymVocab() method depends on MultiLocs (which includes SymPassages) having
     *   already been added to their locations' contents list, so we need to ensure that the
     *   initialization of MultiLocs has been carried out first.
     */
    execBeforeMe = [multiLocInitiator]
;


/* 
 *   A Symmetrical Connector is a special type of TravelConnector between rooms that can be
 *   traversed in either direction and that, optionally, can largely set itself up so that if the
 *   dir property of room1 points to this SymConnector, the reverse dir property of room2 also
 *   points to this SymConnector. [SYMCOMM EXTENSION]
 *
 *   SymConnector is a type of TravelConnector (from which it descends by inheritance). A
 *   SymConnector can be traversed in both directions, and defining a SymConnector on a direction
 *   property of one room automatically attaches it to the reverse direction property of the room to
 *   which it leads. Otherwise, a SymConnector behaves much like any other TravelConnector, and can
 *   be used to define travel barriers or the side-effects of travel in much the same way.
 *
 *   Internally a SymConnector defines a room1 property and a room2 property, room1 and room2 being
 *   the two rooms reciprocally connected by the SymConnector. The room1 and room2 can be set by the
 *   extension at preinit if the connector's destination is specified, but it's probably clearer and
 *   safer to explictly set the room1 and room2 properties.
 */
class SymConnector: TravelConnector
    
    /* 
     *   The room from/to which this SymConnector leads. Note we can leave this
     *   to be set up by our initConnector() method. [SYMCOMM EXTENSION] 
     */
    room1 = nil
    
     /* 
      *   The room to/from which this SymConnector leads. [SYMCOMM EXTENSION] 
      */
    room2 = nil
     
    /* 
     *   The direction an actor needs to travel in to travel via us from room1. This is set up in
     *   Room initObj();
     */
    room1Dir = nil
    
    /* 
     *   The direction an actor needs to travel in to travel via us from room2. This is set up in
     *   Room initObj();
     */
    room2Dir = nil
    
    /*   
     *   The name of our direction of travel from the point of view of the player character
     *   depending on whether the pc is in room1 or room2.
     */
    dirName = inRoom1 ? room1Dir.name : room2Dir.name
    
    /*   
     *   Our destination depends on our origin. [SYMCOMM EXTENSION] 
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
     *   at preinit). [SYMCOMM EXTENSION] 
     */
    destination = nil
        
    
    /*  
     *   Execute travel through this connector. The difference for the SYMCOMM EXTENSION is that an
     *   actor travelling through this connector ends up knowing where both sides lead to.
     */
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
	 *   [SYMCOMM EXTENSION] 
     */
    isDestinationKnown = nil
    
    /*   A SymConnector is usually open. [SYMCOMM EXTENSION] */
    isOpen = true
    
    /*   
     *   The rooms property provides an alternative and slightly shorthand way of defining our two
     *   rooms. If defined, it must contain exactlty two rooms in the order [room1, room2].
     */
    rooms = []
    
    /*  
     *   Initialize this SymConnector by setting up its room1 and room2 properties if they are not
     *   already defined. This method is normally called from the preinitThing() method of the room
     *   that first defines this connector. [SYMCOMM EXTENSION]
     */
    initConnector(loc, dir)
    {
        
        /* 
         *   Check if room1 and room2 have been defined on our rooms list property, and assign
         *   them if so.
         */
        
        rooms = valToList(rooms);
 
        
        if(rooms.length > 1)
        {
            room1 = rooms[1];
            room2 = rooms[2];
        }
        
        
        /*  
         *   If room1 hasn't been defined yet, set it to loc (the room whose
         *   preinitThing() method has called this method), provided loc isn't room2.
         */
        if(room1 == nil && room2 != loc)
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
        
        
        if(room1 == loc)
            room1Dir = dir;
        
        if(room2 == loc)
            room2Dir = dir;
    }    
    
    /* Short service methods that can be used to abbreviate game code */
    /* Test whether the player character is in our room1 */
    inRoom1 = (room1 && gPlayerChar.isIn(room1))
    
    /* Test whether the player character is in our room2 */
    inRoom2 = (room2 && gPlayerChar.isIn(room2)) 
               
    /* return a or b depending on which room the player char is in */
    byRoom(args) { return inRoom1 ? args[1] : args[2]; }
    
    
;

/* 
 *   A Symmetrical Passage is a single passage object that can be traversed in either direction and
 *   exists in both the locations it connects. [SYMCOMM EXTENSION]
 *
 *   A SymPassage is very like a SymDoor, except that it can't be opened or closed (at least, not
 *   via player commands). The SymPassage class can be used to define passage-like objects such as
 *   passageways and archways that connect one location to another. A SymPassage is otherwise
 *   defined in exactly the same way as a SymDoor; from a player's perspective it is functionally
 *   equivalent to a Passage, the differences from the game author's point of view being that it can
 *   be defined using one game object instead of two and that this extension automatically takes
 *   care of setting up the connection in the reverse direction.
 */
class SymPassage: MultiLoc, SymConnector, Thing
    
    /* 
     *   By default we can vary the description of the passage according to the
     *   location of the actor (and hence, according to which side it's viewed
     *   from), but if we want the passage to be described in the same way from
     *   both sides then we can simply override the desc property with a single
     *   description. [SYMCOMM EXTENSION] 
     */
    desc() 
    {
        if(gActor.isIn(room1))
            room1Desc;
        else
            room2Desc;
    }
    
    /*  Our description as seen from room1 [SYMCOMM EXTENSION]  */
    room1Desc = nil
    
    /*  Our description as seen from room2 [SYMCOMM EXTENSION] */
    room2Desc = nil
    
    /*  A passage is generally something fixed in place.[SYMCOMM EXTENSION]  */
    isFixed = true
    
     /*  Going through a passage is the same as traveling via it.[ SYMCOMM EXTENSION]  */
    dobjFor(GoThrough)
    {
        action() { travelVia(gActor); }
    }
    
    /*  Entering a passage is the same as going through it. [SYMCOMM EXTENSION] */
    dobjFor(Enter) asDobjFor(GoThrough)
    
     /* Going along a Passage is the same as going through it */
    dobjFor(GoAlong) asDobjFor(GoThrough)
        
    
     /*   A Passage is something it makes sense to go through. [SYMCOMM EXTENSION] */
    canGoThroughMe = true
        
    
    /*  
     *   The appropriate action for pushing an object via a passage is
     *   PushTravelThrough [SYMCOMM EXTENSION] 
     */
    PushTravelVia = PushTravelThrough
    
    /*   Initialize this passage (called at preinit from Room.preinitThing) [SYMCOMM EXTENSION]  */
    initConnector(loc, dir)
    {
        /* Carry out the inherited (SymConnector) handling. */
        inherited(loc, dir);
        
        /* 
         *   Move this passage into the two locations where it has a physical
         *   presence. Note that if this is being called from sides of the connector
         *   then the first time it's called either room1 or room2 may not yet be defined,
         *   so we need to test that room1 and room2 are not nil.
         */
        if(room1)
            moveIntoAdd(room1);
        
        if(room2)
            moveIntoAdd(room2);
        
        /*
         *   Initialize either room1Vocab or room2Vocab to our initial vocab (as defined on the
         *   object in game code) if either room2Vocab or room1Vocab respectively has been
         *   overridden to contain a single quoted string.
         */
        if(propType(&room2Vocab) == TypeSString)
            room1Vocab = vocab;
        else if(propType(&room1Vocab) == TypeSString)
            room2Vocab = vocab;
        
    }
    
    /*  
     *   Display message announcing that traveler has left via this door. The
     *   traveler would normally be an NPC visible to the player character.
	 *   [SYMCOMM EXTENSION] 
     */
    sayDeparting(traveler)
    {
        delegated Door(traveler);       
    }
    
    /* 
     *   Display message announcing that follower is following leader through
     *   this door. [SYMCOMM EXTENSION] 
     */
    sayActorFollowing(follower, leader)
    {
        delegated Door(follower, leader);        
    }
    
    /* [SYMCOMM EXTENSION] delegate our traversal message to the Door class. */
    traversalMsg = delegated Door
    
    /* 
     *   Returns the direction property to which this passage is connected in
     *   the player character's current location, e.g. &west. This is used by
     *   DirState to add the appropriate adjective (e.g. 'west') to our vocab,
     *   so that the player can refer to us by the direction in which we lead.
     *   If you don't want this direction to be included in the vocab of this
     *   object, override attachedDir to nil. [SYMCOMM EXTENSION] 
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
    
    /* 
     *   We're visible in the dark if the room on either side of us is
     *   illuminated [SYMCOMM EXTENSION] 
     */    
    visibleInDark
    {
        if(transmitsLight && room1 && room2)
            return room1.isIlluminated || room2.isIlluminated;
        
        return nil;
    }
    
    /* 
     *   Our vocab when viewed from room1. If we want different vocab (including different names) on
     *   each side of this passage or door, we don't need to define both room1Vocab and room2Vocab
     *   since whichever we don't define will be initialized by the SYMCONN EXTENSION to our initial
     *   vocab. So we do need to ensure that our initial vocab will be that which applies to this
     *   passage/door on the side the player first encounters.
     */
    room1Vocab = nil
    
    /*   
     *   Our vocab from the perspective of room2, if we want different vocab to apply to the two
     *   sides of this passage/door.
     */
    room2Vocab = nil
    
;    

/*  
 *   A Symmetrical Door is a door that can be traversed in either direction and exists in both the
 *   locations it connects. It behaves much like a regular Door, except that it uses only one
 *   object, not two, to represent the door. [SYMCOMM EXTENSION]
 *
 *   You'd typically use it by pointing the appropriate direction property of one room to point to
 *   it and then defining its room2 property as the room to which it leads, for example:
 *
 *.  redRoom: Room 'Red Room'
 *.  "A door leads south. "
 *.
 *.   south = blackDoor
 *. ;
 *.
 *. blackDoor: SymDoor 'black door'
 *.   "It's black. "
 *.   room2 = greenRoom
 *. ;
 *.
 *. greenRoom: Room 'Green Room'
 *.   "A door leads north. "
 *. ;
 *
 *   Note that a Symdoor is a MultiLoc, so we don't use the + notation to set its location when
 *   defining it; it exists in both locations. The SYMCOMMN EXTENSION will automatically set the
 *   north property of room2 (here greenRoom) to point to the same door (here blackDoor).
 *
 *   Both sides of a SymDoor must have the same name ('black door' in the example above). You can,
 *   however, give the two sides of a SymDoor different descriptions if you wish by defining its
 *   room1Desc and room2Desc properties instead of its desc property (as you would expect, room1Desc
 *   and room2Desc will then be the descriptions of the door as seen from room1 and room2
 *   respectively, where room1 and room2 have the same meaning as they have on a SymConnector). You
 *   can also give the two sides of the SymDoor different lockabilities by defining room1Lockability
 *   and room2Lockability separately. Alternatively, if you want both sides to have the same locking
 *   behaviour, just override the lockability property. The one thing you can't do (without some
 *   clever extra coding of your own) is to define different keys for each side of a SymDoor.
 *
 *   It's sometimes convenient to refer to a door by the direction it leads in (e.g. "The west door"
 *   or "The north door"). The symconn extension takes care of this for you automatically. For
 *   example, the black door in the example above can be referred to by the player as 'south door'
 *   when the player character is in redRoom and as 'north door' when the player character is
 *   greenRoom and the game will know which door is meant, without the game author having to take
 *   any steps to make this happen. If, however, you want to suppress this behaviour on a particular
 *   SymDoor, you can do so simply by overriding its attachDir property to nil (attachDir is a
 *   method that works out which direction property a SymDoor is attached to in the player
 *   character's location, which is used by the DirState State object to add the appropriate
 *   direction name adjectives, such as 'north', to the SymDoor's vocab).
 */
class SymDoor: SymPassage
    /* A door is usually openable. [SYMCOMM EXTENSION] */
    isOpenable = true
    
    /* A door usually starts out closed. [SYMCOMM EXTENSION]  */
    isOpen = nil
    
    /* 
     *   Although SymDoor doesn't inherit from Door, it needs to use Door's
     *   checkTravelBarriers() method to attempt to open the door via an
     *   implicit action if an attempt is made to go through it when it's
     *   closed. [SYMCOMM EXTENSION] 
     */
    checkTravelBarriers(traveler)
    {
        return delegated Door(traveler);
    }
    
    /*  
     *   If we can't go through the door, use Door's version of the appropriate
     *   method. [SYMCOMM EXTENSION] 
     */
    cannotGoThroughClosedDoorMsg = delegated Door
    
    /* 
     *   By default we leave game authors to decide if and how they want to
     *   report whether a door is open or closed. [SYMCOMM EXTENSION] 
     */
    openStatusReportable = nil
    
    /*  
     *   Flag, do we want to attempt to unlock this door via an implicit action
     *   if someone attempts to open it while it's locked? [SYMCOMM EXTENSION] 
     */
    autoUnlock = nil
    
    /*
     *   The lockability of this Door (notLockable, lockableWithKey, lockableWithoutKey, or
     *   indirectLockable). This can be different for each side of the door, in which case set
     *   room1Lockability and room2Lockability individually and the game will use the lockability
     *   appropriate to the location of the current actor. If you want the same lockability for both
     *   sides of the door, simply override lockability accordingly. [SYMCONN EXTENSION]
     */
    lockability = (gActor.getOutermostRoom == room1 ? room1Lockability : room2Lockability)
    
    /*
     *   Our lockability on the room1 side of the door. [SYMCONN EXTENSION]
     */
    room1Lockability = notLockable
    
    /*
     *   Our lockability on the room2 side of the door. [SYMCONN EXTENSION]
     */    
    room2Lockability = notLockable
    
    dobjFor(GoThrough)
    {
        preCond = [travelPermitted, touchObj, objOpen]
    }
    
    iobjFor(PushTravelThrough)
    {
        preCond = [travelPermitted, touchObj, objOpen]
    }
;
    
/* 
 *   A SymStairway is aingle object representing a stairway up from its lower end and a stairway
 *   down from its upper end. At the minimum we need to point a direction property of the room at
 *   one end of the SymStairway to point to the SymStairway and define the SymStairwa's room2 or
 *   destination propety to be its other end.
 *
 *   If the SymStairway is defined on the up or down property of either of its ends, either
 *   directtly or indirectly, then this extension can work out which end of the Stairway is which
 *   (even if the up or down property points to the SymStairway indirectly via an asExit() macro)
 *   Otherwise game code needs to define at least one of the SymStairway's upperEnd or lowerEnd
 *   properties to point to the appropriate room.
 *
 *   [THE SYMCONN EXIENSION must be present in your project if you want to use a SymStairway]
 */


class SymStairway: SymPassage
    
    /* The room at the upper end of this staircase */
    upperEnd = nil
    
    /* The room at the lower end of this staircase */
    lowerEnd = nil
    
    /* 
     *   initialise this SymStairway by first carrying out the inherited initialization and then
     *   trying to determine which end of the stairway is the upperEnd and which the lowerEnd.
     */
    initConnector(loc, dir)
    {
        /* Carry out the inherited handling. */
        inherited(loc, dir);
        
        /* 
         *   If the lower end is not yet defined and room1 points to us on its up property, then our
         *   lower end must be room 1.
         */
        if(lowerEnd == nil && room1 && room1.getConnector(&up) == self)        
            lowerEnd = room1;
        
        /* 
         *   If the upper end is not yet defined and room1 points to us on its down property, then
         *   our upper end must be room 1.
         */
        if(upperEnd == nil && room1 && room1.getConnector(&down) == self)        
            upperEnd = room1;
        
        /* 
         *   If the lower end is not yet defined and room2 points to us on its up property, then our
         *   lower end must be room 2.
         */
        if(lowerEnd == nil && room2 && room2.getConnector(&up) == self)        
            lowerEnd = room2;
        
        /* 
         *   If the upper end is not yet defined and room2 points to us on its down property, then
         *   our upper end must be room 2.
         */
        if(upperEnd == nil && room2 && room2.getConnector(&down) == self)        
            upperEnd = room2;
        
        /* 
         *   If the upper end is not yet defined but the lower end is, then our upper end must be
         *   whichever room isn't the lower end.
         */       
        if(upperEnd == nil && lowerEnd)
            upperEnd = lowerEnd == room1 ? room2 : room1;
        
        /* 
         *   If the lower end is not yet defined but the upper end is, then our lower end must be
         *   whichever room isn't the upper end.
         */ 
        if(lowerEnd == nil && upperEnd)
            lowerEnd = upperEnd == room1 ? room2 : room1;           
        
    }
    
    /* Climbing a stairway is equivalent to climbimg up it. */
    dobjFor(ClimbUp) asDobjFor(Climb)
    
    /* Climbing down a SymStairway is equivalent to travelling via it. */
    dobjFor(ClimbDown)
    {       
        action { travelVia(gActor); }
    }
    
    /* Climbing up SymStairway is equivalent to travelling via it. */
    dobjFor(Climb)
    {       
        action { travelVia(gActor); }
    }
    
    /* We can climb up this stairway if and only if we're at its lower end. */
    isClimbable = location.isOrIsIn(lowerEnd)
    
    /* We can climb down this stairway if and only if we're at its upper end. */
    canClimbDownMe = location.isOrIsIn(upperEnd)
    
    /* Use Thing's cannotDownMsg */
    cannotClimbDownMsg = (delegated StairwayUp)
    
    cannotClimbMsg = (delegated StairwayDown)
    
       
    /* 
     *   The appropriate PushTravelAction for pushing something something up or down a
     *   SymStairway.
     */
    PushTravelVia = location.isOrIsIn(lowerEnd) ? PushTravelClimbUp : PushTravelClimbDown
    
    /*  
     *   Display message announcing that traveler (typically an NPC whose
     *   departure is witnessed by the player character) has left via this
     *   staircase. 
     */
    sayDeparting(traveler)
    {
        if(location.isOrIsIn(lowerEnd))
            delegated StairwayUp(traveler);
        else
            delegated StairwayDown(traveler);
    }
    
    /* 
     *   Display message announcing that follower is following leader up
     *   this staircase.
     */
    sayActorFollowing(follower, leader)
    {
        /* Create message parameter substitutions for the follower and leader */
        if(location.isOrIsIn(lowerEnd))
            delegated StairwayUp(follower, leader);
        else
            delegated StairwayDown(follower, leader);
    }
    
    /* The message for traversing this stairway - we delegate to Thing's message. */
    traversalMsg = location.isOrIsIn(lowerEnd) ? delegated StairwayUp : delegated StairwayDown
    
    
    /* a trio of short service methods to provide convenient abbreviations in game code */
    
    /* Is the player character in our upper end room? */
    inUpper = (upperEnd && gPlayerChar.isIn(upperEnd))
    
    /* Is the player character in our lower end room? */
    inLower = (lowerEnd && gPlayerChar.isIn(lowerEnd))
    
    /* 
     *   Return a or b depending on whether or not the player character is in our upperEnd room.
     *   This is primarily intended to ease the writing of descriptions or travelDescs which vary
     *   slightly according to which end we're at, e.g. "The stairs lead steeply <<byUpLo('down',
     *   'up')>> "
     */
    byEnd(arg) { return inUpper ? arg[1] : arg[2]; }
    
    /* 
     *   Retuen 'down' or 'up' depending on whether we're at the upper or lower end of the stairway.
     */
    upOrDown = inUpper ? downDir.name : upDir.name
;

/*  
 *   A SympPathPassage is a SymPassage that represents a path (or road or track or the like). so
 *   that following it or going down it is equivalent to going through it.
 */
class SymPathPassage: SymPassage
    
    /* Make followinng a path the same as going through it. */
    dobjFor(Follow) asDobjFor(GoThrough)
    
    /* Make going down a path the same as going through it. */
    dobjFor(ClimbDown) asDobjFor(GoThrough)
    
    /* Make going up a path the same as going through it. */
    dobjFor(ClimbUp) asDobjFor(GoThrough)
    
    
    /* 
     *   One most naturally talks of going 'down' a path; by default we use the message from the
     *   PathPassage class.
     */
    traversalMsg = delegated PathPassage
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
 *   extension. [SYMCOMM EXTENSION]
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
