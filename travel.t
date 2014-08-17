#charset "us-ascii"
#include "advlite.h"


/*
 *   ****************************************************************************
 *    room.t 
 *    This module forms part of the adv3Lite library 
 *    (c) 2012-13 Eric Eve
 */

property lastTravelInfo;
property cannotGoShowExits;

/* 
 *   A Room is a top location in which the player character, other actors and
 *   other objects may be located. It may represent any discrete unit of space,
 *   not necessarily a room in a building. Normally actors may only interact
 *   with objects in the same room as themselves, but the senseRegion module
 *   allows us to define sensory connections between rooms.
 */     
class Room: TravelConnector, Thing
    
    
    /*  
     *   The direction properties (north, south, etc.) define what happens when
     *   travel is attempted in the corresponding direction. A direction
     *   property may be defined as another Room (in which case traveling in the
     *   corresponding direction takes the actor directly to that Room), or to a
     *   TravelConnector (including a Door or Stairway), or to a single-quoted
     *   or double-quoted string (which is then simply displayed) or to a method
     *   (which is then executed). It is recommended that methods only be used
     *   when the effect of attempted travel is something other than ordinary
     *   travel; to impose conditions on travel or define the side-effects of
     *   travel it's usually better to use a TravelConnector object.
     */
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
    
    /*
     *   Are compass directions allowed for travel from this room? By default
     *   we'll allow thema anywhere, but game code may wish to override this for
     *   rooms that are aboard a vessel.
     */
    allowCompassDirections = true
    
    /*
     *   Are shipboard directions meaningful in this room? By default we'll make
     *   them so if and  only if this room defines at least one shipboard
     *   directional exit. Game code may wish to modify this, for example, on
     *   the hold of a ship that only defines an up direction but where
     *   shipboard directions would still in principle be meaningful.
     */
    allowShipboardDirections()
    {
        for(local dir in ShipboardDirection.shipboardDirections)
        {
            if(propType(dir.dirProp) != TypeNil)
                return true;
        }
        
        return nil;
    }
    
	
	
    /* 
     *   A Room is normally lit, but if we want a dark room we can override
     *   isLit to nil.
     */   
    isLit = true
    
    /*   A Room is always fixed in place. */
    isFixed = true
    
    /*   A Room is always open */
    isOpen = true
    
    /*   
     *   A Room is lit within it it's illuminated (it's either lit itself or
     *   contains a light source
     */
    litWithin()
    {
        return isIlluminated;
    }
    
    
    /*   
     *   Since a Room provides the TravelConnector interface, we need to define
     *   where it leads to when one attempts to travel via it; a Room always
     *   leads to itself (i.e. traveling via a Room takes one to that Room).
     */
    destination { return self; }
    
    /* By default our destination is known if we've been visited */
    isDestinationKnown = (visited)
    
    /* Has this room been visited? */
    visited = nil
 
    /* 
     *   Although we don't define room parts in general, we do give every Room a
     *   floor so that the parser can refer to objects 'on the ground' when
     *   asking disambiguation questions. By default we supply every Room with
     *   the defaultGround MultiLoc object to represent its floor. You can if
     *   you like replace this with a custom floor object in particular rooms,
     *   but it's highly recommended that you define your custom floor to be of
     *   the Floor class. It's also legal to define floorObj as nil on a Room
     *   that represents an obviously floorless place, such as the top of a mast
     *   or tree.
     */
    floorObj = defaultGround       
    
    /* 
     *   When travelling via a room we move the traveler into the room. Then, if
     *   the traveler is the player char we perform a look around in the room,
     *   provided we should look around on entering the room.
     */    
    execTravel(obj)
    {        
        local lookAroundOnEntering = lookOnEnter(obj);
        obj.actionMoveInto(destination);
        if(gPlayerChar.isOrIsIn(obj) && lookAroundOnEntering)
           destination.lookAroundWithin();
    }
    
    /* 
     *   Should we look around on entering this room? By default we should; this
     *   is overridden in senseRegion.t to provide for the possibility of a
     *   "continuous space" implementation.
     */
    lookOnEnter(obj)
    {
        return true;
    }
    
    
    
    /*  A Room's outermost room is itself. */
    getOutermostRoom { return self; }
    
    /* 
     *   The Message to display if travel is disallowed in any given direction
     *   (because the corresponding direction property of the Room is nil).
     */    
    cannotGoThatWayMsg = BMsg(cannot go, '{I} {can\'t} go that way. ' )
    
    /*   
     *   The method that is called when travel is attempted in a direction
     *   (given the dir parameter) for which nothing is defined. By default we
     *   simply display the cannotGoThatWayMsg followed by a list of exits, but
     *   this can be overridden if desired, and different responses given for
     *   different directions. Note that the dir parameter will be passed as a
     *   direction object. e.g. northDir.
     */
    cannotGoThatWay(dir)
    {
        "<<cannotGoThatWayMsg>>";
        if(gExitLister != nil)
            gExitLister.cannotGoShowExits(gActor, self);
        
        "<.p>";
    }
    
    /*  
     *   The message to display when travel is attempted in the dark, either in
     *   a direction for which no destination (or other handling) is defined, or
     *   in a direction in which the exit is not visible in the dark.
     */
    cannotGoThatWayInDarkMsg = BMsg(cannot go in dark, 'It{dummy}{\'s} too dark
        to see where {i}{\'m} going. ')
    
    
    /*   
     *   The method that's called when travel is attempted by an undefined or
     *   invisible exit in the dark. By default we display the
     *   cannotGoThatWayInDarkMsg followed by a list of visible exits, but game
     *   code can override this.
     */
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
    
       
    
    /* Call the before action notifications on this room and its regions */
    notifyBefore()
    {
        /* Call our own roomBeforeAction() */
        roomBeforeAction();
        
        /* 
         *   Notify all the regions we're in of the action that's about to take
         *   place.
         */
        foreach(local reg in valToList(regions))
            reg.notifyBefore();
    }
    
    /* Call the after action notifications on this room and its regions */
    notifyAfter()
    {
        /* Call our own roomAfterAction() */
        roomAfterAction();
        
        /* 
         *   Notify all the regions we're in of the action that's just taken
         *   place.
         */
        foreach(local reg in valToList(regions))
            reg.notifyAfter();
    }
    
    
    /* 
     *   roomBeforeAction and roomAfterAction are called just before and after
     *   the action phases of the current action. Individual instances can
     *   override to react to the particular actions.     */
    
    roomBeforeAction() { }
    roomAfterAction() { }
   
    
    /*   
     *   beforeTravel(traveler, connector) is called on a the room traveler is
     *   in just as traveler is about to attempt travel via connector (a
     *   TravelConnector object).
     */
    beforeTravel(traveler, connector) { }
    
    /*   
     *   afterTravel(traveler, connector) is called on a room traveler has just
     *   arrived in via connector.
     */
    afterTravel(traveler, connector) { }
    
    
    /* show the exit list in the status line */
    showStatuslineExits()
    {
        /* if we have a global exit lister, ask it to show the exits */
        if (gExitLister != nil)
            gExitLister.showStatuslineExits();
    }

    
    /*  The name of the room as it appears in the status line. */
    statusName(actor)
    {
        local nestedLoc = '';
        
        /*  
         *   If the actor is not directly in the room we add the actor's
         *   immediate container in parentheses after the room name.
         */
        if(!actor.location.ofKind(Room))
            nestedLoc = BMsg(actor nested location name,  
                             ' (<<actor.location.objInPrep>> 
                <<actor.location.theName>>)');
        
        /*  
         *   If the Room is illuminated, display its ordinary room title,
         *   followed by the actor's immediate location if it's not the Room. If
         *   the Room is in darkness, use the darkName instead of the roomTitle.
         */
        if(isIlluminated)
            "<<roomTitle>><<nestedLoc>>";
        else
            "<<darkName>><<nestedLoc>>";
    }
    
    /*  
     *   Anything in the Room is deemed to be inside it (this sounds
     *   tautologous, but it's why we give Room a contType of In).
     */
    contType = In
    
    /* 
     *   This method is invoked on the player char's current room at the end of
     *   every action. By default we run our doScript() method if we're also a
     *   Script (that is, if the Room has been mixed in with an EventList
     *   class), thereby facilitating the display of atmospheric messages.
     */    
    roomDaemon() 
    {
        if(ofKind(Script))
            doScript();
    }
    
    
    /* 
     *   This room can optionally be in one or more regions. The regions
     *   property hold the region or a list of regions I'm in.
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
    
    /* 
     *   Carry out the notifications for a traveler leaving this room to go to
     *   dest.
     */
    notifyDeparture(traveler, dest)
    {
        /* Notify the current room of the impending departure */
        travelerLeaving(traveler, dest);
        
                
        /* 
         *   Notify any regions the traveler is about to leave of the impending
         *   departure         */
        
        local commonRegs = regionsInCommonWith(dest);
        
        /* 
         *   The regions I'm about to leave are all the regions this room is in
         *   less those that this room has in common with my destination.
         */
        local regsLeft = allRegions - commonRegs;
        
        
        /*   
         *   Notify all the regions that the traveler is leaving that the
         *   traveler is leaving to go to dest.
         */
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
            reg.travelerEntering(traveler, self);
        
        /* notify the destination room of the impending arrival */        
        dest.travelerEntering(traveler, self);
    }
    
    
    /* 
     *   This method is invoked when traveler is about to leave this room and go
     *   to dest.
     */
    travelerLeaving(traveler, dest) { }
    
    /* 
     *   This method is invoked when traveler is about to enter this room 
     *   from origin.
     */
    travelerEntering(traveler, origin) { }
    
   
    /*    A Room has no interiorParent since it's a top-level container. */
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
        /* 
         *   Append the extra scope items defined on this Room to the action's
         *   scope list.
         */
        action.scopeList =
            action.scopeList.appendUnique(valToList(extraScopeItems));
        
        /*  Add any extra scope items defined on any regions we're in. */
        foreach(local reg in valToList(regions))
            reg.addExtraScopeItems(action);
        
        /* 
         *   By default we'll also add our floor object to scope if we have one
         *   and it isn't already in scope.
         */        
        if(floorObj != nil)
            action.scopeList = action.scopeList.appendUnique([floorObj]);
    }
    
    /*  
     *   A list of extra items to be added to scope when an action is carried
     *   out in this room.
     */
    extraScopeItems = []
    
    /*   The location at which a Room was last seen is always itself. */
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
    
    /* 
     *   The getDirection method returns the direction by which one would need
     *   to travel from this room to travel via the connector conn (or nil if
     *   none of the room's direction properties point to conn).
     */
    getDirection(conn)
    {
        for(local dir = firstObj(Direction); dir != nil; dir = nextObj(dir,
            Direction))
        {
            if(propType(dir.dirProp) == TypeObject && self.(dir.dirProp) == conn)
                return dir;
        }
        
        return nil;
    }
    
    /* 
     *   By default we don't want the examineStatus method of a Room to do
     *   anything except displaying the stateDesc, should we have defined one.
     *   In particular we don't want it to list the contents of the Room, since
     *   Looking Around will do this anyway.
     */
    examineStatus() { display(&stateDesc); }

    /*  Examining a Room is the same as looking around within it. */
    dobjFor(Examine)
    {
        action() { lookAroundWithin(); }
    }

    /*  Going out of a Room is the same as executing an OUT command */
    dobjFor(GetOutOf)
    {
        action() { GoOut.execAction(gCommand); }
    }
    
    /*  
     *   Pushing an object out of a Room is the same as pushing it via the OUT
     *   exit.
     */
    iobjFor(PushTravelGetOutOf)
    {
        action()
        {
            gCommand.verbProd.dirMatch = object { dir = outDir; };
            gAction = PushTravelDir;
            PushTravelDir.execAction(gCommand);
        }
    }
 
    /* 
     *   Optional method that returns a single-quoted string explaining why
     *   target (normally an object in a remote location) cannot be reached from
     *   this room. By default we just return the target's tooFarAwayMsg but
     *   this can be overridden, for example, to return the same format of
     *   message for every target that can't be reached from this room (e.g.
     *   "You can't reach [the target] from the meadow. ") ]
     */        
        
    cannotReachTargetMsg(target)
    { 
        return target.tooFarAwayMsg;
    }
;

/* 
 *   A Door is something that can be open and closed (and optionally locked),
 *   and which must be open to allow travel through. Doors are defined in pairs,
 *   with each Door representing one side of the door and pointing to the other
 *   side via its otherSide property. */

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
        if(destination != nil && transmitsLight)
            return destination.isIlluminated;
        
        return nil;
    }
    
    /*   A Door is something it makes sense to go through. */
    canGoThroughMe = true
    
    /*   Make a Door open (stat = true) or closed (stat = nil) */
    makeOpen(stat)
    {
        /*  Carry out the inherited handling. */
        inherited(stat);
        
        /*  
         *   If we have an otherSide, make it open or closed at the same time so
         *   both sides of the Door stay in sync.
         */
        if(otherSide != nil)
        {
            otherSide.isOpen = stat;
            if(stat)
                otherSide.opened = true;
        }
    }
    
    /*  Make a Door locked (stat = true) or unlocked (stat = nil) */
    makeLocked(stat)
    {
        /* Carry out the inherited handling. */
        inherited(stat);
        
        /* 
         *   If we have an otherSide, make it locked or unlocked at the same
         *   time so both sides of the Door stay in sync.
         */
        if(otherSide != nil)
            otherSide.isLocked = stat;
    }
    
    /*  Carry out travel via this Door */
    execTravel(actor)
    {
        /*  If the Door isn't open, try to open it via an implicit action. */
        if(!isOpen)
        {
            if(tryImplicitAction(Open, self))
               "<<gAction.buildImplicitActionAnnouncement(true)>>";
            
            /* 
             *   If we're not allowed to open this door via an implicit action
             *   (because opening it is marked as dangerous or nonObvious at the
             *   verify stage) display a message explaining why the travel can't
             *   be carried out.
             */
            else
            {
                local obj = self;
                gMessageParams(obj);
                say(cannotGoThroughClosedDoorMsg);
            }
        }
        
        /*  
         *   If the Door isn't open, the failure to open it will have been
         *   reported by the implicit action. If it is open, attempt to travel
         *   through it.
         */
        if(isOpen)
        {
            /*  
             *   If the Door has no destination, there's nowhere for the actor
             *   to go to, so simply report that travel isn't possible.
             */
            if(destination == nil)
                DMsg(leads nowhere, 'Unfortunately {1} {dummy} {doesn\'t lead}
                    anywhere. ', theName);
            
            /*  
             *   Otherwise, attempt travel via the Door's destination (which in
             *   virtually every case will mean travel to the Door's
             *   destination, i.e. the room to which the Door leads).
             */
            else
            {    
                /* Carry out any side-effects of the travel */
                noteTraversal(actor);
                
                /* Move the traveler to our destination. */
                destination.travelVia(actor, dontChainNotifications);     
                
                /* 
                 *   if we travel through this door successfully then presumably
                 *   we now know where its other side leads and where it leads.
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
   
    /*  
     *   The message to display if travel is attempted through this door when
     *   it's closed and we're not allowed to open it via an implicit action.
     */
    cannotGoThroughClosedDoorMsg =  BMsg(cannot go through closed door, 
                                         '{The subj obj} {is} in the way. ')
    
    /*   
     *   By default the player character doesn't start off knowing where this
     *   door leads. Once the pc has been through the door in either direction
     *   this becomes true on both sides of the door.
     */
    isDestinationKnown = nil
   
    /*   Preinitialize a door */
    preinitThing()
    {
        /*  Carry out the inherited handling */
        inherited;
        
        /* 
         *   in addition to carrying out Thing's preinitialization, carry out
         *   some additional housekeeping to ensure that this door is in sync
         *   with its other side.
         */        
        if(otherSide == nil)
        {
            /* 
             *   If the otherSide hasn't been defined and we're compiling for
             *   debugging, display a warning message.
             */
            #ifdef __DEBUG
            "WARNING!!! <<theName>> in << getOutermostRoom != nil ?
              getOutermostRoom.name : 'nil'>> has no otherside.<.p>";           
            
            #endif
        }
        else
        {
            /* 
             *   If our otherSide doesn't already point to us, make it do so.
             *   This allows game authors to get away with only specifying one
             *   side of the connection.
             */
            if(otherSide.otherSide != self)
                otherSide.otherSide = self;
            
            /*   
             *   If we've made one side of the door locked, the chances are we
             *   intend the other side of the door to start out locked too.
             */
            if(isLocked)
                otherSide.isLocked = true;
            
            
            /*   
             *   Likewise, if we've made one side of the door open, the chances
             *   are we intend the other side of the door to start out open too.
             */
            if(isOpen)
                otherSide.isOpen = true;
            
            /*  Add the other side to our list of facets. */
            getFacets += otherSide;
            
        }       
    }
    
    /*  The destination is the room to which this door leads. */
    destination()
    {
        /*  If we don't have an other side, then we don't lead anywhere. */
        if(otherSide == nil)
            return nil;
            
        
        /* Otherwise this door leads to the room containing its other side */
        return otherSide.getOutermostRoom;
    }
    
    /*  Going through a door is the same as traveling via it. */
    dobjFor(GoThrough)
    {
        action() { travelVia(gActor); }
    }
    
    /*  Entering a door is the same as going through it. */
    dobjFor(Enter) asDobjFor(GoThrough)
    
    /*  
     *   The appropriate action for push an object via a door is
     *   PushTravelThrough
     */
    PushTravelVia = PushTravelThrough
    
    /*  
     *   Display message announcing that traveler has left via this door. The
     *   traveler would normally be an NPC visible to the player character.
     */
    sayDeparting(traveler)
    {
        gMessageParams(traveler);
        DMsg(say departing through door, '{The subj traveler} {leaves} through
            {1}. ', theName);
    }
    
    /* 
     *   Display message announcing that follower is following leader through
     *   this door.
     */
    sayActorFollowing(follower, leader)
    {
        /* Create message parameter substitutions for the follower and leader */
        gMessageParams(follower, leader);  
        
        DMsg(say following through door, '{The subj follower} follow{s/ed} {the
            leader} through {1}. ', theName);
    }
    
    traversalMsg = BMsg(traverse door, 'through {1}', theName)
;

  /* 
   *   A TravelConnector is an object that can be attached to the directional
   *   exit property of a room to facilitate (or optionally block) travel in the
   *   associated direction and carry out any side-effects of that travel. A
   *   TravelConnector may be used as an abstract object to implement travel, or
   *   a subclass of TravelConnector such as Door, Passage, StairwayUp or
   *   StairwayDown may be used to represent a physical object via which travel
   *   occurs. The Room class also inherits from TravelConnector.
   *
   *   Whether the base TravelConnector class or one of its subclasses is used,
   *   travel is carried out via a TravelConnector by calling its travelVia()
   *   method.
   */
class TravelConnector: object    
    
    /* 
     *   Is this connector apparent? That is, would it be apparent to an
     *   observer under normal lighting conditions, as opposed to being
     *   concealed? By default we'll suppose a TravelConnector is apparent
     *   unless it's explicitly hidden.
     */
    isConnectorApparent = !isHidden
    
    /* 
     *   Should this exit be shown in the exit lister? By default we'll assumed
     *   it should be it it's visible. 
     */
    isConnectorListed = isConnectorVisible
    
    /*   
     *   Does light pass through this TravelConnector from its destination (so
     *   that it's visible in the dark even its location is dark.).
     */
    transmitsLight = true
    
    /*  
     *   A TravelConnector (or at least, the exit it represents) is visible if
     *   it's apparent (i.e. not concealed in some way) and if the lighting
     *   conditions are adequate, or if it's visible in the dark.
     */
    isConnectorVisible = (isConnectorApparent && 
                          (gPlayerChar.getOutermostRoom.isIlluminated
                              || (destination != nil &&
                                  destination.isIlluminated
                                  && transmitsLight)
                           || visibleInDark))
    
    /* The room to which this TravelConnector leads when it is traversed */    
    destination = nil
    
    /* 
     *   Does the player char know where this travel connector leads? By default
     *   s/he doesn't until s/he's visited its destination, but this could be
     *   overridden for an area the PC is supposed to know well when the game
     *   starts, such as their own house.
     */    
    isDestinationKnown = (destination != nil && destination.visited)
    
    /*   A travel connector is usually open. */
    isOpen = true
    
    /* 
     *   Carrier out travel via this connector. First check that travel through
     *   this connector is permitted for this actor (or other traveler). If it
     *   is, then send the before travel notifications, display any travelDesc
     *   for the player char, if the player char is doing the traveling,  note
     *   where the player char is travelling. Then execute the actual travel and
     *   then finally issue the after travel notifications.
     *
     *   The actor is the actor doing the traveling.
     */    
    travelVia(actor, suppressBeforeNotifications?)
    {
        /* 
         *   The traveler is the object actually doing the travelling; usually
         *   it's just the actor, but if the actor is in a vehicle, it will be
         *   the vehicle.
         */
        local traveler = getTraveler(actor);       
        
        /* 
         *   Check the travel barriers on this TravelConnector to ensure that
         *   travel is permitted
         */
        if(checkTravelBarriers(traveler))
        {
            /* 
             *   Note the traveler's current location, so we can check
             *   subsequently whether travel actually took place.
             */
            local oldLoc = traveler.getOutermostRoom();
            
            /*  
             *   Carry out the before travel notifications provided
             *   suppressBeforeNotifications is nil. The normal reason for
             *   suppressing before notification would be if this
             *   TravelConnector is the second or subsequent travel connector in
             *   a chain, for example a room connected to by a door, since in
             *   that case we wouldn't normally want to see two or more sets of
             *   travel notifications triggered for the same travel action.
             */
            if(!suppressBeforeNotifications)
                beforeTravelNotifications(traveler);
                    
            /* 
             *   Note the actor's old travel info in case we have to restore it
             *   after a failed travel attempt.
             */
            if(actor != gPlayerChar)
                local oldTravelInfo = actor.lastTravelInfo;
            
            if(actor == gPlayerChar)
            {                  
                /* 
                 *   Before carrying out the travel make a note of the room the
                 *   player character is about to leave.
                 */
                libGlobal.lastLoc = oldLoc;                               
            }
            /* 
             *   Otherwise if the player character can see the actor traverse
             *   this connector, note the fact on the actor, so that the
             *   information is available should the player character wish to
             *   follow the actor.
             */
            else if(Q.canSee(gPlayerChar, actor) &&
                    !suppressBeforeNotifications)
                actor.lastTravelInfo = [oldLoc, self];
            
                           
            
            /* Carry out the travel */
            execTravel(traveler);
            
            /*  
             *   Execute the after travel notifications, provided this connector
             *   actually went somewhere to notify and that the actor actually
             *   ended up in a new location.
             */
            if(destination != nil && actor.getOutermostRoom != oldLoc)
            {               
                afterTravelNotifications(traveler);
            }
            
            /* 
             *   If we're not the player character and we failed to go anywhere,
             *   restore our old travel info.
             */
            if(actor != gPlayerChar && actor.getOutermostRoom == oldLoc)
                actor.lastTravelInfo = oldTravelInfo;
                
        }        
    }
    
    /* 
     *   Get the traveler associated with this actor. Normally the traveler will
     *   be the same as the actor, but if the actor is in a vehicle, then the
     *   traveler will be the vehicle.
     */
    getTraveler(actor)
    {
        
        local loc = actor.location;
        
        while(loc != nil && !loc.ofKind(Room))
        {
            if(loc.isVehicle)
                return loc;
            
            loc = loc.location;
        }
        
        
        return actor;
    }
    
    
    
    
    /*  
     *   If the actor doing the traveling is the player character, display the
     *   travelDesc. Note that although this might normally be a simple
     *   description of the travel, the travelDesc method could also be used to
     *   carry out any other side-effects of the travel via this connector.
     */
    noteTraversal(actor)
    {
        if(actor == gPlayerChar)
        {                
            travelDesc;
            "<.p>";
        }
    }
    
    
    /* Carry out the before travel notifications for this actor. */
    beforeTravelNotifications(actor)
    {
        /* 
         *   Call the before travel notifications on every object that's in
         *   scope for the actor.
         */
        Q.scopeList(actor).toList.forEach({x: x.beforeTravel(actor, self)});
        
        /*  
         *   If this TravelConnector has a destination that's a Room (so that
         *   executing the travel should take the actor out of his/her current
         *   room) notify the current room that the actor is about to depart.
         */
        if(destination && destination.ofKind(Room))
           actor.getOutermostRoom.notifyDeparture(actor, destination);
        
        
         /* 
          *   Finall, carry out before travel notifications in all the regions
          *   the traveler starts out in.
          */
        foreach(local reg in actor.getOutermostRoom.allRegions)
            reg.regionBeforeTravel(actor, self);
    }
    
    /* Carry out the after travel notifications for this actor */
    afterTravelNotifications(actor)
    {
        /* 
         *   Call the after travel notification for every object that's in scope
         *   for this actor.
         */
        Q.scopeList(actor).toList.forEach({x: x.afterTravel(actor, self)});
        
        /*   
         *   Finally, carry out after travel notifications in all the regions
         *   the traveler ends up in.
         */
        foreach(local reg in actor.getOutermostRoom.allRegions)
            reg.regionAfterTravel(actor, self); 
        
    }

    /* 
     *   If this travel connector points to another (e.g. a Room), we probably
     *   don't want to trigger the before notifications on the second connector
     *   (the Room) as well as this one.
     */
    dontChainNotifications = true
    
    /*  Execute the travel for this actor via this connector */
    execTravel(actor)
    {
        /* 
         *   If this travel connector has a destination (which would normally be
         *   a room), carry out travel via that destination (which, if the
         *   destination is a room, would normally mean travel to that
         *   destination).
         */
        if(destination != nil)
        {
            /*   
             *   Note that actor is traversing this Travel Connector. This can
             *   be used to carry out any side-effects of the travel, such as
             *   describing it.
             */             
            
            noteTraversal(actor);   
            
            destination.travelVia(actor, dontChainNotifications);
        }
    }
    
    /*  
     *   Method that should return true is actor is allowed to pass through this
     *   TravelConnector and nil otherwise. We allow travel by default but this
     *   could be overridden to block travel under certain conditions.
     */
    canTravelerPass(actor) { return true; }
    
    
    /*  
     *   If canTravelerPass returns nil explainTravelBarrier should display a
     *   message explaining why travel has been prohibited.
     */
    explainTravelBarrier(actor) { }
    
    /*   
     *   Carry out any side effects of travel if the traveler is the player
     *   character. Typically we might just display some text describing the
     *   travel here, but this method could be used for any side-effects of the
     *   travel. If the TravelConnector is mixed in with an EventList class then
     *   the default behaviour is to call the doScript() method here to drive
     *   the EventList.
     */
    travelDesc() 
    { 
        if(ofKind(Script))
            doScript();
    }
    
    /* 
     *   an additional TravelBarrier or a list of TravelBarriers to check on
     *   this TravelConnector to see if travel is allowed.
     */
    travelBarriers = nil
       
    
    /* 
     *   Check all the travel barriers associated with this connector to
     *   determine whether the traveler is allowed to pass through this travel
     *   connector.
     */
    checkTravelBarriers(traveler)
    {
        /* first check our own built-in barrier test. */
        if(!canTravelerPass(traveler))
        {
            /* 
             *   If travel is not permitted display a message explaining why and
             *   then return nil to cancel the travel.
             */
            explainTravelBarrier(traveler);
            return nil;
        }
        
        /* Then check any additional travel barrier objects */
        if(valToList(travelBarriers).indexWhich({b: b.checkTravelBarrier
                                                (traveler,  self) == nil}))
            return nil;
        
        /* 
         *   If we've reached this point then no travel barrier is objecting to
         *   the traveler traveling to this connector, so return true to signal
         *   that travel is permitted.
         */
        return true;   
    }
    
    
    /* 
     *   Display a message to say that an actor is departing via this connector.
     *   On the base class the default behaviour is to describe the departure
     *   via a compass direction. The actor in question would normally be an NPC
     *   visible to the player character.
     */
    sayDeparting(traveler)
    {       
        /* Create a message parameter substitution for the traveler */
        gMessageParams(traveler);        
        
        /* Find the direction to which this connector is attached. */
        local depdir = getDepartingDirection(traveler);
        
        if(depdir == nil)
            DMsg(say departing vague, '<.p>{The subj traveler} {leaves} the
                area. ');
        else        
            DMsg(say departing dir, '<.p>{The subj traveler} {goes} {1}. '
                 , depdir.departureName);
                        
    }
    
    /* 
     *   Display a message to say that follower is following leader in the
     *   direction of this connector.
     */
    sayActorFollowing(follower, leader)
    {
        /* Create a message parameter substitution for the traveler */
        gMessageParams(follower, leader);        
        
        /* Find the direction to which this connector is attached. */
        local depdir = getDepartingDirection(follower);
        
        if(depdir == nil)
            DMsg(say following vague, '<.p>{The subj follower} follow{s/ed} {the
                leader}. ');
        else        
            DMsg(say following dir, '<.p>{The subj follower} follow{s/ed} {the
                leader} {1}. ', depdir.departureName);
        
    }
    
    /* 
     *   Create a phrase describing the direction of travel through this
     *   connector (e.g. 'to the north')
     */
    traversalMsg()
    {
        local depDir = getDepartingDirection(gActor);
        
        return  BMsg(traverse connector, '{1}', depDir.departureName);
    }
    
   
    /* 
     *   Get the direction traveler needs to go in to traverse this connector
     *   from traveler's current location.
     */
    getDepartingDirection(traveler)
    {                
        /* Note what room the traveler is in prior to departure */
        local room = traveler.getOutermostRoom;
        
        /* Return the direction to which this connector is attached. */
        return room.getDirection(self);
    }
;

/* 
 *   An UnlistedProxyConnector is a special kind of TravelConnector created by
 *   the asExit macro to make one exit do duty for another. There is probably
 *   never any need for this class to be used explicitly in game code, since
 *   game authors will always use the asExit macro instead.
 */
class UnlistedProxyConnector: TravelConnector
    
    /* An UnlistedProxyConnector is never listed as an exit in its own right. */
    isConnectorListed = nil
    
    /* 
     *   We'll assume an UnlistedProxyListedConnector is always 'visible', since
     *   it's a proxy for some other connector which will handle the actual
     *   visibility conditions.
     */
    isConnectorVisible = true
    
    /* Carry out travel via this connector. */
    travelVia(actor)
    {
        /* Set up a new travel action. */
        local action = new TravelAction;
        
        /* 
         *   Set the direction of travel of our new travel action to be the
         *   direction defined on this UnlistedProxyConnector.
         */
        action.direction = direction;
        
        /*   
         *   Get the travel action to carry out the travel in the direction just
         *   defined.
         */
        action.doTravel();
    }
    
    /* Construct a new UnlistedProxyConnector. */
    construct(dir_)
    {
        /* Note the direction this connector is a proxy for. */
        direction = dir_;        
        
    }
    
  
    /* 
     *   We don't want an UnlistedProxyConnector to trigger any travel
     *   notifications since these will be triggered - if appropriate - on the
     *   real connector we point to.     */
    
    beforeTravelNotifications(actor) {}    
    afterTravelNotifications(actor) {}
    

;

/* 
 *   A TravelBarrier is an object that can optionally be associated with one or
 *   more TravelConnectors to define additional conditional (or even
 *   unconditional) barriers preventing travel.
 */
class TravelBarrier: object
    
    /* 
     *   This method should return true to permit the traveler to travel via
     *   connector and nil to prohibit travel. By default we simply allow travel
     *   but particular instances will need to override this method to specify
     *   the conditions under which travel is or is not permitted.
     */
    canTravelerPass(traveler, connector)
    {
        return true;
    }
    
    /*  
     *   Display some text explaining why traveler is not permitted to travel
     *   via connector when canTravelerPass() returns nil.
     */
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

/* 
 *   A Direction object represents a direction in which an actor might attempt
 *   to travel. The library defines eight compass directions (north, south,
 *   etc.) and a further eight special directions (in, out, up, down, port,
 *   starboard, fore and aft), but game code can define additional directions if
 *   required.
 *
 *   The convention that should be followed in naming a Direction object is to
 *   use the name of the direction followed by Dir; e.g. the Direction object
 *   corresponding to north is called northDir. Custom directions should follow
 *   the same convention, since it is assumed by the goInstead() and goNested()
 *   macros.
 */
class Direction: object
    
    /* 
     *   The exit property of a room association with this Direction, e.g.
     *   &north (corresponding to northDir).
     */
    dirProp = nil
    
    /*  
     *   The name of this direction, e.g. 'north'. This is the name that appears
     *   in the exit lister.
     */
    name = nil
    
    /*   Class property: a LookupTable matching names to direction objects. */
    nameTab = static new LookupTable()
    
    /*  
     *   The name to use when departing via this direction, e.g. 'to the north'
     */
    departureName = nil
    
    /*
     *   Initialize.  We'll use this routine to add each Direction instance to
     *   the master direction list (Direction.allDirections) during
     *   pre-initialization. 
     */
    initializeDirection()
    {
        /* add myself to the master direction list */
        Direction.allDirections.append(self);
        
        /* add myself to the master direction table */
        Direction.nameTab[name] = self;			  
    }

    /*
     *   Class initialization - this is called once on the class object.
     *   We'll build our master list of all of the Direction objects in
     *   the game, and then sort the list using the sorting order.  
     */
    classInit()
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
    
    /* 
     *   A Class property containing a Vector of all the directions defined in
     *   the game (the 16 defined in the library plus any additionasl custom
     *   directions defined in game code)
     */
    allDirections = static new Vector(12)
    
	
;

/* The compass directions */
class CompassDirection: Direction
    initializeDirection()
	{
	   /* Carry out the inherited handling */
	   inherited();
	   
	   /* Add myself to the list of compass directions */
	   CompassDirection.compassDirections.append(self);
	}
	
	/* 
	  * A Class property containing a Vector of all the compass
	  * directions defined in the game.
	  */
	compassDirections = static new Vector(8)
;

/*  The sixteen directions defined in the library */
northDir: CompassDirection
    dirProp = &north
    name = BMsg(north, 'north')
    departureName = BMsg(depart north, 'to the north')
    sortingOrder = 1000
;

eastDir: CompassDirection
    dirProp = &east
    name = BMsg(east, 'east')
    departureName = BMsg(depart east, 'to the east')
    sortingOrder = 1100
;

southDir: CompassDirection
    dirProp = &south
    name = BMsg(south, 'south')
    departureName = BMsg(depart south, 'to the south')
    sortingOrder = 1200
;

westDir: CompassDirection
    dirProp = &west
    name = BMsg(west, 'west')
    departureName = BMsg(depart west, 'to the west')
    sortingOrder = 1300
;

northeastDir: CompassDirection
    dirProp = &northeast
    name = BMsg(northeast, 'northeast')
    departureName = BMsg(depart northeast, 'to the northeast')
    sortingOrder = 1400
;

northwestDir: CompassDirection
    dirProp = &northwest
    name = BMsg(northwest, 'northwest')
    departureName = BMsg(depart northwest, 'to the northwest')
    sortingOrder = 1500
;

southeastDir: CompassDirection
    dirProp = &southeast
    name = BMsg(southeast, 'southeast')
    departureName = BMsg(depart southeast, 'to the southeast')
    sortingOrder = 1600
;

southwestDir: CompassDirection
    dirProp = &southwest
    name = BMsg(southwest, 'southwest')
    departureName = BMsg(depart southwest, 'to the southwest')
    sortingOrder = 1700
;

downDir: Direction
    dirProp = &down
    name = BMsg(down, 'down')
    departureName = BMsg(depart down, 'down')
    sortingOrder = 2000
;

upDir: Direction
    dirProp = &up
    name = BMsg(up, 'up')
    departureName = BMsg(depart up, 'up')
    sortingOrder = 2100
;

inDir: Direction
    dirProp = &in
    name = BMsg(in, 'in')
    departureName = BMsg(depart in, 'inside')
    sortingOrder = 3000
;

outDir: Direction
    dirProp = &out
    name = BMsg(out, 'out')
    departureName = BMsg(depart out, 'out')
    sortingOrder = 3100
;

/* Directions for use aboard a vessel such as a ship */
class ShipboardDirection: Direction
    initializeDirection()
	{
	   /* Carry out the inherited handling */
	   inherited();
	   
	   /* Add myself to the list of shipboard directions */
	   ShipboardDirection.shipboardDirections.append(self);
	} 
    

    /* 
	  * A Class property containing a Vector of all the shipboard
	  * directions defined in the game.
	  */
	shipboardDirections = static new Vector (4)
;

portDir: ShipboardDirection
    dirProp = &port
    name = BMsg(port, 'port')
    departureName = BMsg(depart port, 'to port')
    sortingOrder = 4000
;

starboardDir: ShipboardDirection
    dirProp = &starboard
    name = BMsg(starboard, 'starboard')
    departureName = BMsg(depart starboard, 'to starboard')
    sortingOrder = 4100
;

foreDir: ShipboardDirection
    dirProp = &fore
    name = BMsg(forward, 'forward')
    departureName = BMsg(depart forward, 'forward')
    sortingOrder = 4200
;

aftDir: ShipboardDirection
    dirProp = &aft
    name = BMsg(aft, 'aft')
    departureName = BMsg(depart aft, 'aft')
    sortingOrder = 4300
;

/*  
 *   A Region is an object representing several rooms or even several other
 *   Regions.
 */
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
    
    /*  Is this Region either itself region or contained within in region */
    isOrIsIn(region)
    {
        return region == self || isIn(region); 
    }
    
    /* 
     *   A list of all the regions this Region is within; in addition to any
     *   regions this Region is directly in (defined on its regions property)
     *   this will include all the regions it's indirectly in (i.e. any regions
     *   the regions it's in are in and so forth).
     */
    allRegions()
    {
        /* Start with a vector of all the regions we're directly in */
        local thisRegions = new Vector(valToList(regions));
        
        /* 
         *   For each of the regions we're directly in, append all the regions
         *   they're in.
         */
        foreach(local reg in valToList(regions))
            thisRegions.appendUnique(reg.allRegions);
        
        /*   Convert the Vector to a list and return it. */
        return thisRegions.toList();
    }
    
    /* 
     *   A list of all the rooms in this region. This is built automatically at
     *   preinit and shouldn't be altered by the user/author.
     */    
    roomList = nil
    
    /*   
     *   A user-defined list of the rooms in this region. At Preinit this will
     *   be used along with the regions property of any rooms to build the
     *   roomList of this Region.
     */
    rooms = nil
       
    /* 
     *   Build the list of regions in all the rooms in this this region by going
     *   through every room defined in the roomList and adding us to its list of
     *   regions. Note that this is provided as an alternative way to define
     *   what rooms start out in which regions.     
     */
    
    makeRegionLists()
    {       
        if(rooms != nil)
        {
            foreach(local r in rooms)
                r.regions = valToList(r.regions).appendUnique([self]);
        }       
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
            /* 
             *   If this Region is familiar then go through each room in the
             *   list of rooms in the Region and mark it as familiar.
             */
            foreach(local rm in valToList(roomList))
            {
                rm.familiar = true;                
            }
        }
    }
    
        
    /* 
     *   To add an object to our contents we need to add it to the contents of
     *   every room in this region. If the optional vec parameter is supplied it
     *   must be a vector; the rooms will then be added to the vector as well.
     *   The vec parameter is primarily for use by the MultiLoc class.
     */    
    addToContents(obj, vec?)
    {
        foreach(local cur in roomList)
        {
            cur.addToContents(obj, vec);
        }
    }
    
    /* 
     *   To remove an object from our contents we need to remove it from the
     *   contents of every room in the region. If the optional vec parameter is
     *   supplied it must be a vector; the rooms will then be removed from the
     *   vector as well.
     */         
    removeFromContents(obj, vec?)
    {
        foreach(local cur in roomList)
        {
            cur.removeFromContents(obj, vec);
        }
    }
    
    /* 
     *   Add an additional room (passed as the rm parameter) to our list of
     *   rooms. This method is intended for internal library use at PreInit
     *   only.
     */
    addToRoomList(rm)
    {
        /* 
         *   Add rm to our existing roomList, making sure we don't duplicate an
         *   existing entry, and converting the roomList from nil to a list if
         *   isn't a list already.
         */
        roomList = nilToList(roomList).appendUnique([rm]);
        
        /*  Add rm to the room list of all the regions we're in */
        foreach(local cur in valToList(regions))
            cur.addToRoomList(rm);
    }
    
    /* 
     *   Put extra items in scope when action is carried out in any room in this
     *   region.
     */
    addExtraScopeItems(action)
    {
        /* 
         *   Add our list of extraScopeItems to the existing scopeList of the
         *   action, avoiding creating any duplicate entries.
         */
        action.scopeList =
            action.scopeList.appendUnique(valToList(extraScopeItems));
        
        /* 
         *   Add any further additional scope items from any of the regions
         *   that this region is in.
         */
        foreach(local reg in valToList(regions))
            reg.addExtraScopeItems(action);
    }
    
    /* 
     *   A list of items that should be added to the standard scope list for
     *   actions carried out in any room in this region.
     */
    extraScopeItems = []
    
     /* 
      *   This method is invoked when traveler is about to leave this region and
      *   go to dest (the destination room).
      */
    travelerLeaving(traveler, dest) { }
    
     /* 
      *   This method is invoked when traveler is about to enter this region
      *   from origin (the room traveled from.
      */    
    travelerEntering(traveler, origin) { }
    
    /* Carry out before notifications on the region */
    notifyBefore()
    {
        /* First call our own regionBeforeAction() method */
        regionBeforeAction();
        
        /* 
         *   Then call the beforeAction notification on all the regions we're
         *   in.
         */
        foreach(local reg in valToList(regions))
            reg.notifyBefore();
    }
    
    /* 
     *   This method is called just before an action takes places in this
     *   region.
     */
    regionBeforeAction() { }
    
    /* Carry out after notifications on the region */
    notifyAfter()
    {
        /* First call our own regionAfterAction() method */
        regionAfterAction();
        
        /* 
         *   Then call the afterAction notification on all the regions we're
         *   in.
         */
        foreach(local reg in valToList(regions))
            reg.notifyAfter();
    }
    
    /* Method called just after an action has taken place in this region. */
    regionAfterAction() { }
    
    /* 
     *   This method is called just before travel takes places in this
     *   region (when traveler is about to travel via connector).
     */
    regionBeforeTravel(traveler, connector) { }       
   
    
    /* 
     *   Method called just after travel has taken place in this region (when
     *   traveler has just traveled via connector).
     */
    regionAfterTravel(traveler, connector) { }
    
    /*   
     *   Should the fastGoTo option be used in this region (i.e. traveling from
     *   one room in the region to another is all done in one turn without the
     *   need for CONTINUE, even if several steps are involved)? Note that the
     *   value of this setting has no effect if gameMain.fastGoTo is true, since
     *   then the fastGoTo setting is always in effect.
     */
    fastGoTo = nil
    
    /* 
     *   Move a MultiLoc (ml) into this region, by moving it into every room in
     *   this Region.
     */
    moveMLIntoAdd(ml)
    {
        roomList.forEach({r: ml.moveIntoAdd(r)});
    }
    
    /*  
     *   Move a MultiLoc (ml) out of this region, by moving it out of every room
     *   in the Region.
     */
    moveMLOutOf(ml)
    {
        roomList.forEach({r: ml.moveOutOf(r)});
    }
;

/* 
 *   Go through each room and add it to every regions it's (directly or
 *   indirectly) in. Then if the region is familiar, mark all its rooms as
 *   familiar.
 */
regionPreinit: PreinitObject    
    execute()
    {
        forEachInstance(Region, {r: r.makeRegionLists });
        
        forEachInstance(Room, {r: r.addToRegions()} );
        
        forEachInstance(Region, { r: r.setFamiliarRooms() } );
    }
    
;