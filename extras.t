#charset "us-ascii"
#include "advlite.h"


/*
 *   ***************************************************************************
 *   extras.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve
 *
 *
 *
 *
 *   This file contains a number of (in principle) optional classes that can be
 *   used in addition to Thing. A game does not need to use any of these classes
 *   since authors can always just set the appropriate properties on thing, but
 *   some authors may find them a convenience, or may find that using them
 *   improves the clarity of their code.
 */

property tooFarAwayToHearMsg;
property tooFarAwayToSmellMsg;
property smellSize;
property soundSize;

/* 
 *   An Odor is an object representing a smell (as opposed to the object that
 *   might be emitting that smell). The desc property of an Odor is displayed in
 *   response to EXAMINE or SMELL; any other action is responded to with the
 *   notImportantMsg.
 */
class Odor: Thing
    /* 
     *   Treat an Odor as a decoration so that it responds only to a limited
     *   number of actions
     */
    isDecoration = true
    
    /*  An Odor responds to EXAMINE SOMETHING or SMELL SOMETHING */
    decorationActions = [Examine, SmellSomething]
    
    /*  
     *   The message to display when any other action is attempted with an Odor
     */
    notImportantMsg = BMsg(only smell, '{I} {can\'t} do that to a smell. ')
    
    /*   Treat Smelling an Odor as equivalent to Examining it. */
    dobjFor(SmellSomething) asDobjFor(Examine)   
    
    dobjFor(Examine) { preCond = [objSmellable] }
    
    /* 
     *   Since we turn SMELL into EXAMINE we want our sightSize to be our
     *   smellSize.
     */
    sightSize = smellSize
    
    /*   
     *   For the same reason we want to use our tooFarAwayToSmellMsg for our
     *   tooFarWayToSeeDetailMsg.
     */
    tooFarAwayToSeeDetailMsg = tooFarAwayToSmellMsg    
    
    isOdor = true
;


/* 
 *   A Noise is an object representing a sound (as opposed to the object that
 *   might be emitting that sound). The desc property of a Noise is displayed in
 *   response to EXAMINE or LISTEN TO; any other action is responded to with the
 *   notImportantMsg.
 */
class Noise: Thing
    /* 
     *   Treat a Noise as a decoration so that it responds only to a limited
     *   number of actions
     */
    isDecoration = true
    
    /*  A Noise responds to EXAMINE SOMETHING or LISTEN TO SOMETHING */
    decorationActions = [Examine, ListenTo]
    
    /*  
     *   The message to display when any other action is attempted with a Noise
     */
    notImportantMsg = BMsg(only listen, '{I} {can\'t} do that to a sound. ')
    
    /*   Treat Listening to a Noise as equivalent to Examining it. */
    dobjFor(ListenTo) asDobjFor(Examine)    
    
    dobjFor(Examine) { preCond = [objAudible] }
    
    /* 
     *   Since we turn LISTEN TO into EXAMINE we want our sightSize to be our
     *   soundSize.
     */
    sightSize = soundSize
    
    /*   
     *   For the same reason we want to use our tooFarAwayToHearlMsg for our
     *   tooFarWayToSeeDetailMsg.
     */
    tooFarAwayToSeeDetailMsg = tooFarAwayToHearMsg
    
    isNoise = true
;

/* A Container is a Thing that other things can be put inside */
class Container: Thing
    /* Containers are open by default */
    isOpen = true
    
    /* 
     *   The containment type of a container is In; i.e. things located in a
     *   Container are considered to be in it.
     */
    contType = In
;

/*  An OpenableContainer is a Container that can be opened and closed. */
class OpenableContainer: Container
    
    /* Most OpenableContainers start out closed. */
    isOpen = nil
    
    /* An OpenableContainer is openable */
    isOpenable = true
;

/*  
 *   A LockableContainer is an OpenableContainer that can be locked and unlocked
 *   without the aid of a key.
 */
class LockableContainer: OpenableContainer
    lockability = lockableWithoutKey
    
    /* We usually want a LockableContainer to start out locked. */
    isLocked = true
;

/*  
 *   A KeyedContainer is an OpenableContainer that can be locked and unlocked
 *   only with the aid of a key.
 */
class KeyedContainer: OpenableContainer
    lockability = lockableWithKey
    
    /* We usually want a KeyedContainer to start out locked. */
    isLocked = true
;

/*  A Surface is a Thing that other things can be placed on top of */
class Surface: Thing
    
    /* The contents of a Surface are considered to be on the Surface */
    contType = On
    
    /* 
     *   Searching a Surface may involve look for what's on it as well as what's
     *   in it.
     *
     *   We put this code here rather than checking for contType == On on a
     *   Thing to avoid burdening Thing with overcomplicated code for a rather
     *   special case.
     */
    
    dobjFor(Search)
    {
        preCond = [objVisible, touchObj]
        verify() {}
        check() {}
        action()
        {
            if(hiddenIn.length == 0 
               && contents.countWhich({x: x.searchListed}) == 0)
            {
                say(nothingOnMsg);
                return;
            }
            
            local onList = contents.subset({x: x.searchListed});
            
            if(onList.length > 0)
                listContentsOn(onList);
            
            if(hiddenIn.length > 0)            
                findHidden(&hiddenIn, In);
        }
    }
    
    nothingOnMsg = BMsg(nothing on, '{I} {find} nothing of interest on
        {the dobj}. ')
    
    /* 
     *   List what's on me. We put this in a separate method to make it easier
     *   to customise on a per object basis.
     */
    listContentsOn(lst)
    {
        lookInLister.show(lst, self, true);
    }    
;

/* 
 *   A Plaftorm is a Surface that the player character (and other actors) can
 *   get on.
 */
class Platform: Surface
    isBoardable = true
;

/*   
 *   A Booth is a Container that the player character (and other actors) can get
 *   in.
 */
class Booth: Container
    isEnterable= true
;


/*  An Underside is a Thing that other things can be put under */
class Underside: Thing
    
    /* The contents of an Underside are considered to be under it. */
    contType = Under
;

/*  An RearContainer is a Thing that other things can be put behind */
class RearContainer: Thing
    
    /* The contents of an RearContainer are considered to be behind it. */
    contType = Behind
;

/*  A Wearable is a Thing that can be worn */
class Wearable: Thing
    isWearable = true
;

/*  A Food is a Thing that can be eaten */
class Food: Thing
    isEdible = true
;

/*  
 *   A Fixture is a Thing that can't be picked up and carried around (and so
 *   can't be put anywhere either).
 */
class Fixture: Thing
    isFixed = true
;

/*   
 *   A Decoration is a Fixture that can only be EXAMINEd. Any other action
 *   results in the display of its notImportantMsg. It's normally used for
 *   objects that are purely scenery.
 */
class Decoration: Fixture
    isDecoration = true
;

/* 
 *   A Component is an object that's (usually permanently) part of something
 *   else, like the handle of a suitcase or a dial on a safe.
 */
class Component: Fixture    
    cannotTakeMsg = BMsg(cannot take component, '{I} {can\'t} have {that dobj},
        {he dobj}{\'s} part of {1}. ', location.theName)
    
    locType = PartOf
;


/*  
 *   A Distant is a Decoration that's considered too far away to be interacted
 *   with by any command other than EXAMINE
 */
class Distant: Decoration
   
    /* Message to say that this object is too far away. */
    notImportantMsg = BMsg(distant, '{The subj cobj} {is} too far away. ')
    
    /* 
     *   The base Decoration class includes GoTo as a decorationAction. For a
     *   Distant object (e.g. the sun or moon or a distanct mountain) this will
     *   often be inappropriate. Where an object is 'locally distant' as it
     *   were, i.e. a sign mounted high up on a wall, you may want to override
     *   decorationActions to include GoTo, since GO TO SIGN would then be a
     *   reasonable way for the player to get to the location of the sign.
     */
    decorationActions = [Examine]
;

/* An Unthing is an object that represents the absence of a thing */
class Unthing: Decoration
    
    /* An Unthing can't respond to any actions, as it isn't there */
    decorationActions = []
    
    /* 
     *   The message to display when the player character tries to interact with
     *   this object; by default we just say it isn't there, but game code will
     *   normally want to override this message to explain the reason for the
     *   absence.
     */  
    notImportantMsg = BMsg(unthing absent, '{The subj cobj} {isn\'t} {here}. ')
                   
    /* 
     *   Users coming from adv3 may be used to Unthings having a notHereMsg, so
     *   we'll define this to be the same as the notImportantMsg
     */
    notHereMsg = notImportantMsg
    
    
    /* An Unthing should never be included in ALL */
    hideFromAll(action) { return true; }
    
    /* 
     *   A player is more likely to be trying to refer to something that is
     *   present than something that isn't, so we give Unthings a substantially
     *   reduced vocabLikelihood
     */
    vocabLikelihood = -100
             
    /* 
     *   If there's anything else in the match list, remove myself from the
     *   matches
     */
    filterResolveList(np, cmd, mode)
    {
        if(np.matches.length > 1)
            np.matches = np.matches.subset({m: m.obj != self});
    }
    
    
    /* Make Unthings verify with the lowest possible score */         
    dobjFor(Default)
    {
        verify()
        {
            inaccessible(notHereMsg);               
        }
    }
    
    iobjFor(Default)
    {
        verify()
        {
            inaccessible(notHereMsg);               
        }
    }
;

/*  
 *   A CollectiveGroup is a an object that can represent a set of other objects
 *   for particular actions. For any of the objects in the myObjects list the
 *   CollectiveGroup will handle any of the actions in the myActions list; all
 *   the other actions will be handled by the individual objects.
 */
class CollectiveGroup: Fixture
    
    /* 
     *   The list of actions this CollectiveGroup will handle; all the rest will
     *   be handled by the individual objects.
     */
    collectiveActions = [Examine]
    
    /* 
     *   Is action to be treated as a collective action by this group (i.e.
     *   handled by this CollectiveGroup object); by default it is if it's one
     *   of the actions listed in our collectiveActions property.
     */
    isCollectiveAction(action)
    {
        return collectiveActions.indexWhich({a: action.ofKind(a)}) != nil;
    }
    
    /* 
     *   If the current action is one of the collective Actions, then filter all
     *   myObjects from the resolve list; otherwise filter myself out from the
     *   resolve list.
     */
    filterResolveList(np, cmd, mode)
    {
        /* If there are fewer than two matches, don't do any filtering */
        if(np.matches.length < 2)
            return;
        
        if(isCollectiveAction(cmd.action))
           np.matches = np.matches.subset(
               {m: valToList(m.obj.collectiveGroups).indexOf(self) == nil});
        else
            np.matches = np.matches.subset({m: m.obj != self });           
           
    }    
    
    /* Obtain the list of the objects belonging to me that are in scope. */
    myScopeObjects()
    {
        return Q.scopeList(gActor).toList.subset(
            {o: valToList(o.collectiveGroups).indexOf(self) != nil});
    }
    
    /* 
     *   The default descriptions of a CollectiveGroup: By default we just list
     *   those of our members that are in scope.
     */
    desc()
    {
        /* 
         *   Get a list of all the objects in scope that belong to this
         *   Collective Group.
         */
        local lst = myScopeObjects();
        
        /*  
         *   Obtain the sublist of these that are currently held by the player
         *   character
         */
        local heldLst = lst.subset({o: o.isIn(gPlayerChar)});
        
        /*  
         *   Subtract the list of held items from the list of in-scope items to
         *   obtain a list of other items in scope.
         */
        lst -= heldLst;
        
        /*   If none of our items are in scope, say so */
        if(nilToList(lst).length == 0 && nilToList(heldLst).length == 0)
            DMsg(collective group empty, 'There{\'s} no {1} {here}. ', name);
        
        /*  
         *   Otherwise display lists of which of my members the player character
         *   is carrying and which others are also present.
         */
        else
        {
            if(heldLst.length > 0)
                DMsg(carrying collective group, '{I} {am} carrying {1}. ',
                     makeListStr(heldLst));
            
            if(lst.length > 0)            
                DMsg(collective group members, 'There{\'s} {1} {here}. ',       
                     makeListStr(lst));
        }
    }
    
    /* A CollectiveGroup isn't normally listed as an item in its own right. */
    isListed = nil
;


/* 
 *   A Heavy is a Fixture that's too heavy to be picked up. We make Heavy a
 *   Fixture rather than an Immovable since it should normally be obvious that
 *   something is too heavy to be moved.
 */

class Heavy: Fixture
    cannotTakeMsg = BMsg(too heavy, '{The subj dobj} {is} too heavy to move. ')
    
;

/*  
 *   An Immovable is something that can't be picked up, although it may not be
 *   immediately obvious that it can't be moved. For that reason we rule out
 *   taking an Immovable at the check stage rather than the verify stage (this
 *   is what distinquished an Immovable from a Fixture).
 */
class Immovable: Thing
    
    /* Respond to an attempt to TAKE by ruling it out at the check stage. */
    dobjFor(Take)
    {
        check() { say(cannotPutMsg); }                
    }
    
    /* The message to display to explain why this object can't be taken. */
    cannotTakeMsg = BMsg(cannot take immovable, '{I} {cannot} take {the dobj).
        ')
;


/*  
 *   A StairwayUp is Thing the player character can climb up. It might represent
 *   an upward staircase, but it could also represent a tree, mast or hillside,
 *   for example. A StairwayUp is also a TravelConnector so it can be defined on
 *   the appropriate direction property of its enclosing room.
 */
class StairwayUp: TravelConnector, Thing
    
    /* Climbing a StairwayUp is equivalent to travelling via it. */
    dobjFor(Climb)
    {        
        action() { travelVia(gActor); }        
    }
    
    /* Climbing up a Stairway up is the same as Climbing it. */
    dobjFor(ClimbUp) asDobjFor(Climb)
    
    /* A StairwayUp is usually something fixed in place. */
    isFixed = true
    
    /*  A StairwayUp is climbable */
    isClimbable = true
    
    /* 
     *   The appropriate PushTravelAction for pushing something something up a
     *   StairwayUp.
     */
    PushTravelVia = PushTravelClimbUp
    
    /*  
     *   Display message announcing that traveler (typically an NPC whose
     *   departure is witnessed by the player character) has left via this
     *   staircase.
     */
    sayDeparting(traveler)
    {
        gMessageParams(traveler);
        DMsg(say departing up stairs, '{The subj traveler} {goes} up
            {1}. ', theName);
    }
    
    
    /* 
     *   Display message announcing that follower is following leader up
     *   this staircase.
     */
    sayActorFollowing(follower, leader)
    {
        /* Create message parameter substitutions for the follower and leader */
        gMessageParams(follower, leader);  
        
        DMsg(say following up staircase, '{The subj follower} follow{s/ed} {the
            leader} up {1}. ', theName);
    }
    
    traversalMsg = BMsg(traverse stairway up, 'up {1}', theName)
;


/*  
 *   A StairwayDown is Thing the player character can climb down. It might
 *   represent an downward staircase, but it could also represent a tree, mast
 *   or hillside, for example. A StairwayDown is also a TravelConnector so it
 *   can be defined on the appropriate direction property of its enclosing room.
 */
class StairwayDown: TravelConnector, Thing
    
    /* Climbing down a StairwayDown is equivalent to travelling via it. */
    dobjFor(ClimbDown)
    {       
        action { travelVia(gActor); }
    }
    
    /* A StairwayDown is usually something fixed in place. */
    isFixed = true
    
    /*  A StairwayDown is something one can climb down */
    canClimbDownMe = true
    
    /* 
     *   The appropriate PushTravelAction for pushing something something down a
     *   StairwayDown.
     */
    PushTravelVia = PushTravelClimbDown
    
    /*  
     *   Display message announcing that traveler (typically an NPC whose
     *   departure is witnessed by the player character)has left via this
     *   staircase.
     */
    sayDeparting(traveler)
    {
        gMessageParams(traveler);
        DMsg(say departing down stairs, '{The subj traveler} {goes} down
            {1}. ', theName);
    }
    
    /* 
     *   Display message announcing that follower is following leader down
     *   this staircase.
     */
    sayActorFollowing(follower, leader)
    {
        /* Create message parameter substitutions for the follower and leader */
        gMessageParams(follower, leader);  
        
        DMsg(say following down staircase, '{The subj follower} follow{s/ed}
            {the leader} down {1}. ', theName);
    }
    
    traversalMsg = BMsg(traverse stairway down, 'down {1}', theName)
;


/* A Passage represents a physical object an actor can travel through, like a
     passage or portal. A Passage is also a TravelConnector so it
 *   can be defined on the appropriate direction property of its enclosing room.
 */
class Passage: TravelConnector, Thing

    /* Going through a Passage is equivalent to travelling via it. */
    dobjFor(GoThrough)
    {        
        action() { travelVia(gActor); }
    }
    
    /* Entering a Passage is the same as going through it */
    dobjFor(Enter) asDobjFor(GoThrough)
    
    /* A Passage is usually something fixed in place. */
    isFixed = true
    
    /*  A Passage is something one can go through */
    canGoThroughMe = true
    
    /* 
     *   The appropriate PushTravelAction for pushing something something
     *   through a Passage.
     */
    PushTravelVia = PushTravelThrough
;

/*  
 *   A PathPassage is a Passage that represents a path, so that following it or
 *   going down it is equivalent to going through it.
 */
class PathPassage: Passage
    dobjFor(Follow) asDobjFor(GoThrough)
    dobjFor(ClimbDown) asDobjFor(GoThrough)
    
    /* One most naturally talks of going 'down' a path */
    traversalMsg = BMsg(traverse path passage, 'down {1}', theName)
;

/*  
 *   An Enterable is a Thing one can go inside. It is usually used to represent
 *   the exterior of an object like a building, so that going inside will take
 *   the actor to a new location representing the interior.
 */
class Enterable: Fixture
    
    /* To enter an Enterable the actor must travel via its connector. */
    dobjFor(Enter)
    {
        verify() {}
        action() { connector.travelVia(gActor); }
    }
    
    /* The handling of an attempt to push something inside this object */
    iobjFor(PushTravelEnter)
    {
        /* 
         *   To push something inside this object we must be able to touch this
         *   object.
         */
        preCond = [touchObj]
        
        /* Check whether our connector allows push travel through it */
        check() { connector.checkPushTravel(); }
        
        /* Carry out the attempt to push something inside us. */
        action()
        {
            /* 
             *   If our connector defines a PushTravelVia action, use that
             *   action to push the direct object via our connector. The use of
             *   replaceAction means that the handling will end there.
             */
            if(connector.PushTravelVia)
                replaceAction(connector.PushTravelVia, gDobj, connector);
            
            
            /* Otherwise, make our direct object travel vis our connector */
            connector.travelVia(gDobj);
            
            /* 
             *   If the push travel attempt was successful, which we assume it
             *   was if the direct object ended up in our connector's
             *   destination, display a message to say the push travel succeeded
             *   and make the actor travel via our connector.
             */
            if(gDobj.isIn(connector.destination))
            {
                say(okayPushIntoMsg);
                connector.travelVia(gActor);
            }           
        }
    }
    
    /*   
     *   Our connector is the TravelConnector via which an actor travels on
     *   entering this object. This may be a Room, or some other TravelConnector
     *   object such as a Door on our outside through which the actor must pass
     *   to get inside.
     *
     *   We set connector = destination since on occasion it may seem more
     *   natural to authors to set the destination property (when it leads
     *   straight to a room) and sometimes more natural to set the connector
     *   property (when it's a door, say). With connector = (destination) by
     *   default, it should work either way.
     */
    connector = (destination)
    
    /*   
     *   If entering this object leads straight to another room, it may seem
     *   more natural to define a destination property; provided we don't
     *   override connector as well, this has the same effect as pointing
     *   connector directly to the room.     
     */
    destination = nil
    
    /* An Enterable is usually enterable */
    isEnterable = true
    
;

/* 
 *   A SecretDoor is a Door that doesn't appear to be a door when it's closed,
 *   and which must be opened by some external mechanism (other than by an OPEN
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

/* A Switch is a Thing than can be turned on and off */
class Switch: Thing
    
    /* A Switch is switchable */
    isSwitchable = true
    
    /* FLIP SWITCH is equivalent to SWITCH SWITCH */
    dobjFor(Flip) asDobjFor(SwitchVague)
;

/*  
 *   A Flashlight is a light source that can be turned on and off; in other
 *   words it's a Switch that's lit when on.
 */
class Flashlight: Switch
    
    /* Turning a Flashlight on and off makes it lit or unlit */
    makeOn(stat)
    {
        inherited(stat);
        makeLit(stat);
    }
    
    /* Lighting a Flashlight is equivalent to switching it on */
    dobjFor(Light) asDobjFor(SwitchOn)
    
    /* Extinguishing a Flashlight is equivalent to switching it off */
    dobjFor(Extinguish) asDobjFor(SwitchOff)
;

/* 
 *   A ContainerDoor can be used as part of a multiply-containing object to
 *   represent the door of the container-like object defined on its remapIn
 *   property. A ContainerDoor is open or closed if the underlying container is
 *   open or closed, and remaps all container-appropriate actions to the remapIn
 *   object of its location.
 */
class ContainerDoor: Fixture
    /* We're open if our location's container is open */
    isOpen = (location.remapIn.isOpen)
    
    /* 
     *   Redirect all container-appropriate actions to the remapIn object of our
     *   location, so that opening, closing, locking and unlocking this door
     *   will perform the equivalent action on our container object.
     */
    remapIn = location.remapIn
    
    cannotTakeMsg = BMsg(cannot take container door, '{I} {can\'t} have {the
        dobj}; {he dobj}{\'s} part of {1}. ', location.theName)
;








 