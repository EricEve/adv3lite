#charset "us-ascii"
#include "advlite.h"

class Room: TravelConnector, Thing
    
    north = nil
    east = nil
    south = nil
    west = nil
    up = nil
    down = nil
    in = nil
    out = nil
    southeast = nil
    southwest = nil
    northeast = nil
    northwest = nil
    port = nil
    starboard = nil
    aft = nil
    fore = nil

    
       
    
    isLit = true
    isFixed = true
    isOpen = true
    
    litWithin()
    {
        return isIlluminated;
    }
    
    destination { return self; }
    
    /* By default our destination is known if we've been visited */
    isDestinationKnown = (visited)
    
    /* Has this room been visited? */
    visited = nil
 
    floorObj = defaultGround       
    
    /* 
     *   When travelling via a room we move the traveler into the room. Then, if
     *   the traveler is the player char we perform a look around in the room
     */
    
    execTravel(obj)
    {
        obj.actionMoveInto(destination);
        if(obj == gPlayerChar)
           destination.lookAroundWithin();
    }
    
    getOutermostRoom { return self; }
    
    /* Messages to show if travel is disallowed. */
    
    cannotGoThatWayMsg = BMsg(cannot go, '{I} {can\'t} go that way. ' )
    cannotGoThatWay(dir)
    {
        "<<cannotGoThatWayMsg>>";
        if(gExitLister != nil)
            gExitLister.cannotGoShowExits(gActor, self);
        
        "<.p>";
    }
    
    cannotGoThatWayInDarkMsg = BMsg(cannot go in dark, 'It{dummy}{\'s} too dark
        to see where {i}{\'m} going. ')
    
    cannotGoThatWayInDark(dir)
    {
        "<<cannotGoThatWayInDarkMsg>><.p>";
        if(gExitLister != nil)
            gExitLister.cannotGoShowExits(gActor, self);
        
        "<.p>";
    }
                                    
    
    /* 
     *   Normally we don't allow travel from this location if both it and the
     *   destination are in darkness. To allow travel from this location in any
     *   case set allowDarkTravel to true.
     */
    
    allowDarkTravel = nil
    
    
    /* 
     *   roomBeforeAction and roomAfterAction are called just before and after
     *   the action phases of the current action. Individual instances can
     *   override to react to the particular actions.
     */
    
    roomBeforeAction() { }
    roomAfterAction() { }
    
    beforeTravel(traveler, connector) { }
    afterTravel(traveler, connector) { }
    
    
    /* show the exit list in the status line */
    showStatuslineExits()
    {
        /* if we have a global exit lister, ask it to show the exits */
        if (gExitLister != nil)
            gExitLister.showStatuslineExits();
    }

    
    
    statusName(actor)
    {
        local nestedLoc = '';
        
        if(!actor.location.ofKind(Room))
            nestedLoc = ' (<<actor.location.objInPrep>> 
                <<actor.location.theName>>)';
        
        if(isIlluminated)
            "<<roomTitle>><<nestedLoc>>";
        else
            "<<darkName>><<nestedLoc>>";
    }
    
    contType = In
    
    /* 
     *   This method is invoked on the player char's current room at the end of
     *   every action.
     */
    
    roomDaemon() { }
    
    
    /* 
     *   This room can optionally be in one or more regions. The regions
     *   property hold the region or a the list of regions I'm in.
     */
    
    regions = nil
    
    /* 
     *   A Room can't be in another Room or a Thing, but it can notionally be in
     *   a Region, so we check to see if we're in the list of our regions.
     */
    
    isIn(region)
    {
        return valToList(regions).indexWhich({x: x.isOrIsIn(region)}) != nil;
    }
    
    /* Add this room to the room list of all the regions it's in */
    
    addToRegions()
    {
        foreach(local reg in valToList(regions))
            reg.addToRoomList(self);
    }
    
    /* 
     *   The list of all the regions this room belongs to. This is calculated
     *   the first time this property is queried and then stored in the
     *   property.
     */
    
    allRegions()
    {
        local ar = getAllRegions();
        allRegions = ar;
        return ar;        
    }
    
    /* Calculate a list of all the regions this room belongs to */
    getAllRegions()
    {
        local thisRegions = new Vector(valToList(regions));
        foreach(local reg in valToList(regions))
            thisRegions.appendUnique(reg.allRegions);
        
        return thisRegions.toList();
    }
    
    
    /* return a list of regions that both this room and other are common to. */
    
    regionsInCommonWith(other)
    {
        return allRegions.subset({x: x.roomList.indexOf(other) != nil});        
    }
    
    notifyDeparture(traveler, dest)
    {
        /* Notify the current room of the impending departure */
        travelerLeaving(traveler, dest);
        
                
        /* 
         *   Notify any regions the traveler is about to leave of the impending
         *   departure
         */
        
        local commonRegs = regionsInCommonWith(dest);
        
        /* 
         *   The regions I'm about to leave are all the regions this room is in
         *   less those that this room has in common with my destination.
         */
        local regsLeft = allRegions - commonRegs;
        
        foreach(local reg in regsLeft)
            reg.travelerLeaving(traveler, dest);
        
        /* 
         *   The regions I'm about to enter are all the regions the destination
         *   room is in, less those this room has in common with the
         *   destination.
         */
        
        local regsEntered = dest.allRegions - commonRegs;
        
        
        /* Notify any regions I'm about to enter of my impending arrival. */
        foreach(local reg in regsEntered)
            reg.travelerEntering(traveler, dest);
        
        /* notify the destination room of the impending arrival */
        
        dest.travelerEntering(traveler, dest);
    }
    
    
    /* 
     *   This method is invoked when traveler is about to leave this room and go
     *   to dest.
     */
    travelerLeaving(traveler, dest) { }
    
    /* 
     *   This method is invoked when traveler is about to enter this room and go
     *   to dest.
     */
    travelerEntering(traveler, dest) { }
    
    /*
     *   Find the nearest common interior parent of self and other.  This finds
     *   the nearest parent that both self and other are inside of. For a room
     *   that's self if the other is in me and nil otherwise.
     */
//    commonInteriorParent(other)
//    {        
//        return other.isIn(self) ? self : nil;
//    }
    
    interiorParent()
    {
        return nil;
    }
    
    /* 
     *   Add extra items into scope for the action. By default we simply add the
     *   items from our extraScopeItems list together with those of any regions
     *   we're it. This allows commonly visible items such as the sky to be
     *   added to scope in dark outdoor rooms, for instance.
     */
    
    addExtraScopeItems(action)
    {
        action.scopeList =
            action.scopeList.appendUnique(valToList(extraScopeItems));
        
        foreach(local reg in valToList(regions))
            reg.addExtraScopeItems(action);
    }
    
    extraScopeItems = []
    
    lastSeenAt = (self)
    
    /* 
     *   Convenience method to set information about the destination dirn from
     *   this room. The dirn parameter should be specified as a direction object
     *   (e.g. northDir) and the dest parameter as a room. Note this is only
     *   meaningful for direction properties specified as methods (as opposed to
     *   Rooms, Doors or other TravelConnectors or as strings), and is only
     *   useful for priming the route finder at the start of the game before the
     *   player has tried to go in this direction from this room. Once the
     *   player tries this direction the dest info table will be overwritten
     *   with information about where it actually leads.
     */
    
    setDestInfo(dirn, dest)
    {
        libGlobal.addExtraDestInfo(self, dirn, dest);
    }

    
    dobjFor(Examine)
    {
        action() { lookAroundWithin(); }
    }

    dobjFor(GetOutOf)
    {
        action() { GoOut.execAction(gCommand); }
    }
    
;

/* 
 *   A Door is something that can be open and closed (and optionally locked),
 *   and which must be open to allow travel through. Doors are defined in pairs,
 *   with each Door representing one side of the door and pointing to the other
 *   side via its otherSide property.
 */

class Door: TravelConnector, Thing
    
    /* A door is generally openable */
    isOpenable = true
    
    /* Most doors start out closed. */
    isOpen = nil
    
    /* Doors generally aren't listed separately in room descriptions. */
    isListed = nil
    
    /* 
     *   A door is something fixed in place, not something that can be picked up
     *   and carried around.
     */
    isFixed = true
    
    /* 
     *   By default we leave game authors to decide if and how they want to
     *   report whether a door is open or closed.
     */
    openStatusReportable = nil
    
    
    /* 
     *   A physical door is represented by two objects in code, each
     *   representing one side of the door and each present in one of the two
     *   locations the door connects. Each side needs to point to the other side
     *   through its otherSide property.
     */
    
    otherSide = nil

    /* 
     *   We're visible in the dark if the room on the other side of us is
     *   illuminated
     */
    
    visibleInDark
    {
        if(destination != nil)
            return destination.isIlluminated;
        
        return nil;
    }
    
    makeOpen(stat)
    {
        inherited(stat);
        if(otherSide != nil)
            otherSide.isOpen = stat;
    }
    
    makeLocked(stat)
    {
        inherited(stat);
        if(otherSide != nil)
            otherSide.isLocked = stat;
    }
    
//    travelVia(actor, suppressBeforeNotifications?)
//    {
//        if(!isOpen)
//        {
//            tryImplicitAction(Open, self);
//            "<<gAction.buildImplicitActionAnnouncement(true)>>";
//        }
//        
//        inherited(actor, suppressBeforeNotifications);
//    }
    
    execTravel(actor)
    {
        
        if(!isOpen)
        {
            tryImplicitAction(Open, self);
            "<<gAction.buildImplicitActionAnnouncement(true)>>";
        }
        
        if(isOpen)
        {
            if(destination == nil)
                DMsg(leads nowhere, 'Unfortunately {1} {dummy} {does}n\'t lead
                    anywhere. ', theName);
            else
            {    
                destination.travelVia(actor, dontChainNotifications);     
                
                /* 
                 *   if we travel through this door successfully then presumably
                 *   we know where its other side leads and where it leads.
                 */
                
                if(otherSide != nil && actor == gPlayerChar &&
                   actor.isIn(destination))
                { 
                    otherSide.isDestinationKnown = true;
                    isDestinationKnown = true;
                }
            }
        }
    }
    
    isDestinationKnown = nil
   
    
    preinitThing()
    {
        inherited;
        
        /* 
         *   in addition to carrying out Thing's preinitialization, carry out
         *   some additional housekeeping to ensure that this door is in sync
         *   with its other side.
         */
        
        if(otherSide == nil)
        {
            #ifdef __DEBUG
            "WARNING!!! <<theName>> in << getOutermostRoom != nil ?
              getOutermostRoom.name : 'nil'>> has no otherside.<.p>";           
            
            #endif
        }
        else
        {
            if(otherSide.otherSide != self)
                otherSide.otherSide = self;
            
            if(isLocked)
                otherSide.isLocked = true;
            
        }
       
        
        
    }
    
    destination()
    {
        if(otherSide == nil)
            return nil;
        
        return otherSide.getOutermostRoom;
    }
    
    
    dobjFor(GoThrough)
    {
        verify() { logical; }
        action() { travelVia(gActor); }
    }
    
    dobjFor(Enter) asDobjFor(GoThrough)
;


class TravelConnector: object
    isConnectorApparent = (isConnectorListed && 
                           (gPlayerChar.getOutermostRoom.isIlluminated
                              || (destination != nil &&
                                  destination.isIlluminated)))
    
    isConnectorListed = true
    
    destination = nil
    
    /* 
     *   Does the player char know where this travel connector leads? By default
     *   s/he doesn't until s/he's visited its destination, but this could be
     *   overridden for an ares the PC is supposed to know well when the game
     *   starts, such as their own house.
     */
        
    
    isDestinationKnown = (destination != nil && destination.visited)
    
    /* 
     *   Carrier out travel via this connector. First check that travel through
     *   this connector is permitted for this actor (or other traveler). If it
     *   is, then send the before travel notifications, display any travelDesc
     *   for the player char, if the player char is doing the traveling,  note
     *   where the player char is travelling. Then execute the actual travel and
     *   then finally issue the after travel notifications.
     */
    
    travelVia(actor, suppressBeforeNotifications?)
    {
        if(checkTravelBarriers(actor))
        {
            if(!suppressBeforeNotifications)
                beforeTravelNotifications(actor);
                                   
            if(actor == gPlayerChar)
            {                
                travelDesc;
                "<.p>";
                
                
                libGlobal.lastLoc = gPlayerChar.getOutermostRoom;                               
            }
                
            execTravel(actor);
            
            afterTravelNotifications(actor);
        }        
    }
    
    beforeTravelNotifications(actor)
    {
        Q.scopeList(actor).toList.forEach({x: x.beforeTravel(actor, self)});
        
        if(destination && destination.ofKind(Room))
           actor.getOutermostRoom.notifyDeparture(actor, destination);
    }
    
    afterTravelNotifications(actor)
    {
        Q.scopeList(actor).toList.forEach({x: x.afterTravel(actor, self)});
    }

    /* 
     *   If this travel connector points to another (e.g. a Room), we probably
     *   don't want to trigger the before notifications on the second connector
     *   (the Room) as well as this one.
     */
    dontChainNotifications = true
    
    execTravel(actor)
    {
        if(destination != nil)
            destination.travelVia(actor, dontChainNotifications);
    }
    
    canTravelerPass(actor) { return true; }
    explainTravelBarrier(actor) { }
    travelDesc {}
    
    /* 
     *   an additional TravelBarrier or a list of TravelBarriers to check on
     *   this TravelConnector to see if travel is allowed.
     */
    travelBarriers = nil
    
    /* Determine whether traveler can pass through this connector */
    
    
    checkTravelBarriers(traveler)
    {
        /* first check our own built-in barrier test. */
        if(!canTravelerPass(traveler))
        {
            explainTravelBarrier(traveler);
            return nil;
        }
        
        /* then check any additional travel barrier objects */
        if(valToList(travelBarriers).indexWhich({b: b.checkTravelBarrier
                                                (traveler,  self) == nil}))
            return nil;
        
        return true;   
    }
    
;

/* 
 *   An UnlistedProxyConnector is a special kind of TravelConnector created by
 *   the asExit macro to make one exit do duty for another. There is probably
 *   never any need for this class to be used explicitly in game code, since
 *   game authors will always use the asExit macro instead.
 */

class UnlistedProxyConnector: TravelConnector
    isConnectorListed = nil
    
    isConnectorApparent = (gPlayerChar.getOutermostRoom.isIlluminated
                              || (destination != nil &&
                                  destination.isIlluminated))
    
    travelVia(actor)
    {
        local action = new TravelAction;
        action.direction = direction;
        action.doTravel();
    }
    
    construct(dir_)
    {
        direction = dir_;
    }
    
  
    /* 
     *   We don't want an UnlistedProxyConnector to trigger any travel
     *   notifications since these will be triggered - if appropriate - on the
     *   real connector we point to.
     */
    
    beforeTravelNotifications(actor) {}    
    afterTravelNotifications(actor) {}
    

;

class TravelBarrier: object
    canTravelerPass(traveler, connector)
    {
        return true;
    }
    
    explainTravelBarrier(traveler, connector)
    {
    }
    
    /* 
     *   Check whether traveler can pass through this connector. If it can,
     *   return true; otherise explain why travel is disallowed and return nil.
     */
    
    checkTravelBarrier(traveler, connector)
    {
        if(canTravelerPass(traveler, connector))
            return true;
        
        explainTravelBarrier(traveler, connector);
        return nil;
    }
;


class Direction: object
    dirProp = nil
    name = nil
     /*
     *   Initialize.  We'll use this routine to add each Direction
     *   instance to the master direction list (Direction.allDirections)
     *   during pre-initialization.  
     */
    initializeDirection()
    {
        /* add myself to the master direction list */
        Direction.allDirections.append(self);
    }

    /*
     *   Class initialization - this is called once on the class object.
     *   We'll build our master list of all of the Direction objects in
     *   the game, and then sort the list using the sorting order.  
     */
    initializeDirectionClass()
    {
        /* initialize each individual Direction object */
        forEachInstance(Direction, { dir: dir.initializeDirection() });

        /* 
         *   sort the direction list according to the individual Directin
         *   objects' defined sorting orders 
         */
        allDirections.sort(SortAsc, {a, b: a.sortingOrder - b.sortingOrder});
    }

    /* 
     *   Our sorting order in the master list.  We use this to present
     *   directions in a consistent, aesthetically pleasing order in
     *   listings involving multiple directions.  The sorting order is
     *   simply an integer that gives the relative position in the list;
     *   the list of directions is sorted from lowest sorting order to
     *   highest.  Sorting order numbers don't have to be contiguous,
     *   since we simply put the directions in an order that makes the
     *   sortingOrder values ascend through the list.  
     */
    sortingOrder = 1
    
    allDirections = static new Vector(12)
    
;

northDir: Direction
    dirProp = &north
    name = 'north'
    sortingOrder = 1000
;

eastDir: Direction
    dirProp = &east
    name = 'east'
    sortingOrder = 1100
;

southDir: Direction
    dirProp = &south
    name = 'south'
    sortingOrder = 1200
;

westDir: Direction
    dirProp = &west
    name = 'west'
    sortingOrder = 1300
;

northeastDir: Direction
    dirProp = &northeast
    name = 'northeast'
    sortingOrder = 1400
;

northwestDir: Direction
    dirProp = &northwest
    name = 'northwest'
    sortingOrder = 1500
;

southeastDir: Direction
    dirProp = &southeast
    name = 'southeast'
    sortingOrder = 1600
;

southwestDir: Direction
    dirProp = &southwest
    name = 'southwest'
    sortingOrder = 1700
;

downDir: Direction
    dirProp = &down
    name = 'down'
    sortingOrder = 2000
;

upDir: Direction
    dirProp = &up
    name = 'up'
    sortingOrder = 2100
;

inDir: Direction
    dirProp = &in
    name = 'in'
    sortingOrder = 3000
;

outDir: Direction
    dirProp = &out
    name = 'out'
    sortingOrder = 3100
;

class ShipboardDirection: Direction;

portDir: ShipboardDirection
    dirProp = &port
    name = 'port'
    sortingOrder = 4000
;

starboardDir: ShipboardDirection
    dirProp = &starboard
    name = 'starboard'
    sortingOrder = 4100
;

foreDir: ShipboardDirection
    dirProp = &fore
    name = 'forward'
    sortingOrder = 4200
;

aftDir: ShipboardDirection
    dirProp = &aft
    name = 'aft'
    sortingOrder = 4300
;

class Region: object
    
    /* 
     *   This region can optionally be in one or more regions. The regions
     *   property hold the region or a the list of regions I'm in.
     */
    
    regions = nil
    
    /* 
     *   A Room can't be in another Room or a Thing, but it can notionally be in
     *   a Region, so we check to see if we're in the list of our regions.
     */
    
    isIn(region)
    {               
        return valToList(regions).indexWhich({x: x.isOrIsIn(region)}) != nil;
    }
    
    isOrIsIn(region)
    {
        return region == self || isIn(region); 
    }
    
    allRegions()
    {
        local thisRegions = new Vector(valToList(regions));
        foreach(local reg in valToList(regions))
            thisRegions.appendUnique(reg.allRegions);
        
        return thisRegions.toList();
    }
    
    /* 
     *   A list of all the rooms in this region. This is built automatically at
     *   preinit and shouldn't be altered by the user/author. 
     */
    
    roomList = nil
    
    /* 
     *   Build the list of rooms in this region by going through every room
     *   defined in the game and adding it if it's (directly or indirectly) in
     *   this region.
     */
    
    buildRoomList()
    {
        local vec = new Vector(20);
        
        for(local r = firstObj(Room) ; r != nil; r = nextObj(r, Room))
        {
            if(r.isIn(self))
                vec.append(r);
        }
        
        roomList = vec.getUnique().toList();
    }
    
    /* 
     *   Is the player char familiar with every room in this region. This should
     *   be set to true for a region whose geography the PC starts out familiar
     *   with, such as the layout of his own house.
     */
    
    familiar = nil
    
    /* 
     *   Go through all the rooms in this region setting them to familiar if the
     *   region is familiar.
     */
    
    setFamiliarRooms()
    {
        if(familiar)
        {
            foreach(local rm in valToList(roomList))
            {
                rm.familiar = true;                
            }
        }
    }
    
    
    
    /* 
     *   To add an object to our contents we need to add it to the contents of
     *   every room in this region.
     */
    
    addToContents(obj, vec?)
    {
        foreach(local cur in roomList)
        {
            cur.addToContents(obj, vec);
        }
    }
    
    removeFromContents(obj, vec?)
    {
        foreach(local cur in roomList)
        {
            cur.removeFromContents(obj, vec);
        }
    }
    
    addToRoomList(rm)
    {
        roomList = nilToList(roomList).appendUnique([rm]);
        
        foreach(local cur in valToList(regions))
            cur.addToRoomList(rm);
    }
    
    addExtraScopeItems(action)
    {
        action.scopeList =
            action.scopeList.appendUnique(valToList(extraScopeItems));
        
        foreach(local reg in valToList(regions))
            reg.addExtraScopeItems(action);
    }
    
    extraScopeItems = []
    
     /* 
      *   This method is invoked when traveler is about to leave this region and
      *   go to dest (the destination room).
      */
    travelerLeaving(traveler, dest) { }
    
     /* 
      *   This method is invoked when traveler is about to enter this region and
      *   go to dest (the destination room).
      */    
    travelerEntering(traveler, dest) { }
;

/* 
 *   Go through each room and add it to every regions it's (directly or
 *   indirectly) in. Then if the region is familiar, mark all its rooms as
 *   familiar.
 */

regionPreinit: PreinitObject
    
    execute()
    {
        forEachInstance(Room, {r: r.addToRegions()} );
        
        forEachInstance(Region, { r: r.setFamiliarRooms() } );
    }
    
;