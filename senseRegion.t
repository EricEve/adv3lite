#charset "us-ascii"
#include "advlite.h"

/*----------------------------------------------------------------------------*/
/*  
 *   senseRegion.t
 *
 *   This file defines the senseRegion class and the modifications to other
 *   classes needed to support it. It can be omitted from games that don't need
 *   the functionality it provides.
 *
 *   This file forms part of the adv3Lite library by Eric Eve
 *
 */


/* 
 *   A SenseRegion is a special kind of Region allowing sensory connection
 *   between rooms
 */
class SenseRegion: Region
    
    /* Is it possible to see from one room to another in this SenseRegion? */
    canSeeAcross = true
    
    /* 
     *   Is it possible to hear (but not necessarily converse) sounds in one
     *   room from another in this SenseRegion?
     */
    canHearAcross = true
    
    /*   Do smells travel from one room to another in this SenseRegion? */
    canSmellAcross = true  
    
    /* 
     *   By default actors have to be in the same room to be able to converse.
     *   Even if sound can travel from one location to another that doesn't
     *   necessarily mean that one could converse over that distance. The only
     *   exception might be where a senseRegion models a relatively small area,
     *   like two ends of a room.
     *
     *   Note that if canHearAcross is nil setting canTalkAcross to true will
     *   have no effect.
     */
    canTalkAcross = nil
    
    
    /*   
     *   Are rooms in this SenseRegion close enough together to allow objects to
     *   be thrown from one room to another; by default we'll assume not.
     */
    
    canThrowAcross = nil
    
    setFamiliarRooms()
    {
        inherited();
        
        /* 
         *   Also take the opportunity to build each room's list of
         *   sensory-connected rooms.
         */
        
        foreach(local rm in roomList)
        {
            if(canSeeAcross)
                rm.visibleRooms = rm.visibleRooms.appendUnique(roomList - rm);
            
            if(canHearAcross)
                rm.audibleRooms = rm.audibleRooms.appendUnique(roomList - rm);
            
            if(canSmellAcross)
                rm.smellableRooms = rm.smellableRooms.appendUnique(roomList - rm);
            
            if(canTalkAcross)
                rm.talkableRooms = rm.talkableRooms.appendUnique(roomList - rm);
            
            if(canThrowAcross)
                rm.throwableRooms = rm.throwableRooms.appendUnique(roomList - rm);
            
            rm.linkedRooms = rm.linkedRooms.appendUnique(roomList - rm);
        }
        
    }      
    
    /* 
     *   Add everything to scope for all the rooms that belong to this
     *   SenseRegion. We do this by sending a senseProbe into each of the rooms
     *   and adding what would be in scope for that probe.
     */
    
    addExtraScopeItems(action)
    {
        inherited(action);
        
        local extraScope = new Vector(30);
        
        foreach(local rm in roomList)
        {
            scopeProbe_.moveInto(rm);
            extraScope.appendAll(Q.scopeList(scopeProbe_).toList);
        }
        
        action.scopeList = action.scopeList.appendUnique(extraScope.toList -
            scopeProbe_);
        
        scopeProbe_.moveInto(nil);
    }
    
    
;
    

/* 
 *   modifications to Room to allow SenseRegions to work.
 */
modify Room
    
    /* 
     *   The list of rooms that are visible from this room. Ordinarily this list
     *   is constructed at Preinit by any Sense Regions this room belongs to, o
     *   shouldn't normally be manually adjusted by game code. It's conceivable
     *   that game code could tweak these lists after Preinit, though, perhaps
     *   to create a one-way connection (e.g. to model a high room that
     *   overlooks lower ones)
     */
         
    visibleRooms = []
    audibleRooms = []
    smellableRooms = []
    talkableRooms = []
    throwableRooms = []

    linkedRooms = []
    
    /* 
     *   Show the specialDescs of any items in the other rooms in our
     *   SenseRegions, where specialDescBeforeContents is true
     */
    showFirstConnectedSpecials(pov)
    {
        foreach(local rm in visibleRooms)
            rm.showFirstRemoteSpecials(pov);
    }
    
    
    /* 
     *   Show the specialDescs of any items in the other rooms in our
     *   SenseRegions, where specialDescBeforeContents is nil
     */
    showSecondConnectedSpecials(pov)    
    {
        foreach(local rm in visibleRooms)
            rm.showSecondRemoteSpecials(pov);        
    }
    
    /* List the miscellaneous contents of a remote room */ 
    
    showConnectedMiscContents(pov)
    {
        foreach(local rm in visibleRooms)
            rm.showRemoteMiscContents(pov);
    }
    
    /* 
     *   These properties are for the internal use of the remote listing
     *   routines, and should normally be left alone by game code.
     */
    remoteSecondSpecialList = nil
    remoteMiscContentsList = nil
    
    /* 
     *   In additional to showing the first (i.e. pre-miscellaneous) list of
     *   items with specialDescs in remote locations, the
     *   showFirstRemoteSpecials() method builds the other lists of objects for
     *   the subsequent methods to use.
     */
    showFirstRemoteSpecials(pov)
    {
        local specialVec1 = new Vector(10);
        local specialVec2 = new Vector(10);
        local miscVec = new Vector(10);
        local lst = contents.subset({o: o.isVisibleFrom(pov)});
        
        /* 
         *   Sort the objects to be listed into three separate lists: those with
         *   specialDescs to be shown before the lists of miscellaneous items,
         *   the list of miscellaneous items, and the list of objects with
         *   specialDescs to be listed after the miscellaneous items.
         */
        foreach(local obj in lst)
        {            
            if((obj.propType(&initSpecialDesc) != TypeNil &&
               obj.useInitSpecialDesc()) ||
               (obj.propType(&specialDesc) != TypeNil && obj.useSpecialDesc()))
            {
                if(obj.specialDescBeforeContents)
                    specialVec1.append(obj);
                else
                    specialVec2.append(obj);
            }
            else if(obj.lookListed)
                miscVec.append(obj);
        }
        
        
        
        specialVec1.sort(nil, {a, b: a.specialDescOrder - b.specialDescOrder});
                 
        specialVec2.sort(nil, {a, b: a.specialDescOrder - b.specialDescOrder});
                       
        /* 
         *   Show the items in the first list, i.e. the list of items with
         *   specialDescs to be shown before the miscellaneous items.
         */
        foreach(local obj in specialVec1)        
            obj.showRemoteSpecialDesc(pov);      
        
        
        /* Store the other two lists for later use by other methods. */
        remoteSecondSpecialList = specialVec2.toList();
        remoteMiscContentsList = miscVec.toList();
    }
    
    
    showSecondRemoteSpecials(pov)
    {
        foreach(local obj in remoteSecondSpecialList)
            obj.showRemoteSpecialDesc(pov); 
    }
    
    showRemoteMiscContents(pov)
    {        
        remoteContentsLister.show(remoteMiscContentsList, inRoomName(pov));        
    }
    
    /* 
     *   The contents lister to use to list this room's miscellaneous contents
     *   when viewed from a remote location.
     */
    remoteContentsLister = remoteRoomContentsLister
    
    /* Reset the contents of all the remote rooms visible from this room */
    unmentionRemoteContents()
    {
        foreach(local rm in visibleRooms)
            unmention(rm.contents);
    }
    
    /* 
     *   The name that's used to introduce a list of miscellaneous objects in
     *   this room when viewed from a remote location containing the pov object
     *   (normally the player character).
     */
    inRoomName(pov)
    {
        return BMsg(in room name, 'in {1}', theName);
    }
    
    
    
;
    
/* 
 *   The default Lister for listing miscellaneous objects in a remote location.
 */
remoteRoomContentsLister: Lister
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed; }    
    
    /* 
     *   Show the list prefix. The irName parameter is the inRoomName(pov)
     *   passed from Room.showRemoteMiscContents(pov).
     */
    showListPrefix(lst, pl, irName)  
    { 
        DMsg(remote contents prefix, '<.p>\^{1} {i} {see} ', irName); 
    }
    
    showListSuffix(lst, pl, irName)  
    { 
        DMsg(remote contents suffix, '. '); 
    }
;




/* modifications to Thing to support other mods above. */

modify Thing
       
   /* 
    *   Show our remoteSpecialDesc, i.e. the version of our specialDesc that
    *   should be seen when this item is viewed from a remote location.
    */ 
   
    
    showRemoteSpecialDesc(pov)
    {
        if(mentioned)
            return;
        else
            mentioned = true;
        
        if(propType(&initSpecialDesc) != TypeNil && useInitSpecialDesc)
            remoteInitSpecialDesc(pov);
        else
            remoteSpecialDesc(pov);
           
        "<.p>";
    }
    
    /* 
     *   Our remoteSpecialDesc is the paragraph describing this item in a room
     *   description when viewed from a remote location containing the pov
     *   object. By default we just show our ordinary specialDesc, but in
     *   practice we'll normally want to override this.
     */    
    remoteSpecialDesc(pov) { specialDesc; }
    
    /*  
     *   Our remoteInitSpecialDesc, used when viewing this item from a remote
     *   location.     */
    
    remoteInitSpecialDesc(pov) { initSpecialDesc; }
    
    /* 
     *   Is this item visible from the remote location containing pov? By
     *   default it is if it's sightSize is not small, but this can be
     *   overridden, for example to vary with the pov.
     */
    isVisibleFrom(pov) { return sightSize != small; }
    
    
    /* 
     *   Is this item audible from the remote location containing pov? By
     *   default it is if it's soundSize is not small, but this can be
     *   overridden, for example to vary with the pov.
     */
    isAudibleFrom(pov) { return soundSize != small; }
    
    /* 
     *   Is this item smellable from the remote location containing pov? By
     *   default it is if it's smellSize is not small, but this can be
     *   overridden, for example to vary with the pov.
     */
    isSmellableFrom(pov) { return smellSize != small; }
    
    
    /* 
     *   Assuming this item is readable at all, is it readable from the remote
     *   location containing pov? By default we assume this is the case if and
     *   only if the item's sightSize is large, but this can be overridden, for
     *   example for a large item with small lettering.
     */
    isReadableFrom(pov) { return sightSize == large; }
           
    /*   
     *   The sightSize can be small, medium or large and controls how visible
     *   this object is from a remote location. If it's small, it can't be seen
     *   from a remote location at all. It it's medium, the object can be seen,
     *   but it's not possible to discern any detail. If it's large, it can be
     *   seen and described. Note that this behaviour is only the default,
     *   however, since it can be changed by overriding the isVisibleFrom() and
     *   remoteDesc() methods. Note also that sightSize is not related to the
     *   bulk property (unless you override sightSize to make it so).
     */
    sightSize = medium
    
    /* 
     *   The soundSize can be small, medium or large. By default something is
     *   audible from a remote location either if its soundSize is large or if
     *   it soundSize is not small and its remoteListenDesc() method has been
     *   defined. Overriding isAudibleFrom(pov) may change these rules.
     */         
    soundSize = medium
    
    /* 
     *   The smellSize can be small, medium or large. By default something is
     *   smellable from a remote location either if its smellSize is large or if
     *   it smellSize is not small and its remoteSmellDesc() method has been
     *   defined. Overriding isSmellableFrom(pov) may change these rules.
     */
    smellSize = medium
    
    
    /* 
     *   The following three properties only take effect on objects on which
     *   they're explicitly defined.
     */
    
    /*  
     *   Define the remoteDesc() property to define the description of this item
     *   as it should be displayed when the item is examined from the remote
     *   location containing the pov object. Note that defining this property
     *   nullifies the distinction between a medium and a large sightSize, since
     *   the remoteDesc will be used in either case.
     */
//    remoteDesc(pov) { desc; }
    
    
    
    /*  
     *   Define the remoteListenDesc() property to define the description of
     *   this item as it should be displayed when the item is listened to from
     *   the remote location containing the pov object. Note that defining this
     *   property nullifies the distinction between a medium and a large
     *   soundSize, since the remoteListenDesc will be used in either case.
     */
//    remoteListenDesc(pov) { listenDesc; }
    
    
    /*  
     *   Define the remoteSmellDesc() property to define the description of this
     *   item as it should be displayed when the item is smelled from the remote
     *   location containing the pov object. Note that defining this property
     *   nullifies the distinction between a medium and a large smellSize, since
     *   the remoteSmellDesc will be used in either case.
     */
//    remoteSmellDesc(pov) { smellDesc; }
    
    
    /* 
     *   Modify the effect of Examine to show the remoteDesc if appropriate, or
     *   else our regular desc if our sightSize is large, or else a message to
     *   say we're too far away to see any detail. If we're in the same room as
     *   the actor, simply carry out the regular (inherited) method.
     */
    dobjFor(Examine)
    {
        action()
        {
            if(isIn(gActor.getOutermostRoom))
                inherited;
            else
            {
                if(propDefined(&remoteDesc))
                {
                    remoteDesc(gActor);
                    "<.p>";
                }
                else if(sightSize == large)
                    inherited;
                else
                {
                    say(tooFarAwayToSeeDetailMsg);
                    "<.p>";
                }
            }
        }
    }
    
    tooFarAwayToSeeDetailMsg = BMsg(too far away to see detail, '{The subj dobj}
        {is} too far away to make out any detail. ')
    
    /* 
     *   Modify the effect of ListenTo to show the remoteListenDesc if
     *   appropriate, or else our regular listenDesc if our soundSize is large,
     *   or else a message to say we're too far away to hear. If we're in the
     *   same room as the actor, simply carry out the regular (inherited)
     *   method.
     */
    dobjFor(ListenTo)
    {
        action()
        {
            if(isIn(gActor.getOutermostRoom))
                inherited;
            else
            {
                if(propDefined(&remoteListenDesc))
                {
                    remoteListenDesc(gActor);
                    "<.p>";
                }
                else if(soundSize == large)
                    inherited;
                else
                {
                    say(tooFarAwayToHearMsg);
                    "<.p>";
                }
            }
        }
    }

    tooFarAwayToHearMsg = BMsg(too far away to hear, '{The subj dobj} {is} too
        far away to hear. ')

    
    /* 
     *   Modify the effect of a Read action to prevent this item being read from
     *   a remote location unless isReadableFrom(gActor) is true.
     */
    
    dobjFor(Read)
    {
        verify()
        {
            inherited;
            
            if(!isIn(gActor.getOutermostRoom) && !isReadableFrom(gActor))
                illogicalNow(tooFarAwayToReadMsg);
        }
    }
    
    tooFarAwayToReadMsg = BMsg(too far away to read, '{The subj dobj} {is} too
        far away to read. ')

    /* 
     *   Modify the effect of SmellSomething to show the remoteSmellDesc if
     *   appropriate, or else our regular smellDesc if our smellSize is large,
     *   or else a message to say we're too far away to smell. If we're in the
     *   same room as the actor, simply carry out the regular (inherited)
     *   method.
     */
    dobjFor(SmellSomething)
    {
        action()
        {
            if(isIn(gActor.getOutermostRoom))
                inherited;
            else
            {
                if(propDefined(&remoteSmellDesc))
                {
                    remoteSmellDesc(gActor);
                    "<.p>";
                }
                else if(smellSize == large)
                    inherited;
                else
                {
                    say(tooFarAwayToSmellMsg);
                    "<.p>";
                }
            }
        }
    }
    
    tooFarAwayToSmellMsg = BMsg(too far away to smell, '{The subj dobj} {is} too
        far away to smell. ')
    
    iobjFor(ThrowAt)
    {
        action()
        {
            if(Q.canThrowTo(gActor, self))
                inherited;
            else
            {
                gDobj.moveInto(gActor.getOutermostRoom);
                say(throwFallsShortMsg);
            }
        }
    }
    
    throwFallsShortMsg = BMsg(throw falls short, '{The subj dobj} {lands} far
        short of {the iobj}. ')
    
;

modify Actor
    iobjFor(ThrowTo)
    {
        /* Only allow the throw to succeed if the actor is in range. */
        action()
        {
            if(Q.canThrowTo(gActor, self))
                inherited;
            else
            {
                gDobj.moveInto(gActor.getOutermostRoom);
                say(throwFallsShortMsg);
            }
        }
    }
    
;


/* 
 *   The scopeProbe_ is a dummy object used by the SenseRegion class to add
 *   items from other rooms in the SenseRegion to scope.
 */
scopeProbe_: Thing
;

/* 
 *   Modifications to the Smell and Listen (intransitive) actions to list remote
 *   smells and sounds
 */


modify Smell
    /* 
     *   Return a list of items in remote locations that can be smelt from the
     *   current actor's location.
     */
    getRemoteSmellList() 
    { 
        local loc = gActor.getOutermostRoom;
        local vec = new Vector(10);
        
        foreach(local rm in loc.smellableRooms)
        {
            scopeProbe_.moveInto(rm);
            local sList = (Q.scopeList(scopeProbe_).toList).subset(
                {o: Q.canSmell(gActor, o)});
            
            vec.appendAll(sList.subset({o: ((o.smellSize == large &&
                                            o.propType(&smellDesc) != TypeNil) ||
                                       o.propDefined(&remoteSmellDesc))
                                       && o.isProminentSmell} ));
        }
        
        
        scopeProbe_.moveInto(nil);
        return vec.toList();
    }
    
    /* List smells in remote locations */
    listRemoteSmells(lst) 
    { 
        foreach(local cur in lst)
        {
            if(cur.propDefined(&remoteSmellDesc))
            {
                cur.remoteSmellDesc(gActor);
            }
            else
            {
                cur.display(&smellDesc);                
            }
        }
    }
;

    /* 
     *   Return a list of items in remote locations that can be heard from the
     *   current actor's location.
     */

modify Listen
    
    getRemoteSoundList() 
    { 
        local loc = gActor.getOutermostRoom;
        local vec = new Vector(10);
        
        foreach(local rm in loc.audibleRooms)
        {
            scopeProbe_.moveInto(rm);
            local sList = (Q.scopeList(scopeProbe_).toList).subset(
                {o: Q.canHear(gActor, o)});
            
            vec.appendAll(sList.subset({o: ((o.soundSize == large &&
                                       o.propType(&listenDesc) != TypeNil) ||
                                       o.propDefined(&remoteListenDesc))
                                       && o.isProminentNoise} ));
        }
        
        
        scopeProbe_.moveInto(nil);
        return vec.toList();
    }
    
    
    
    /* List smells in remote locations */
    listRemoteSounds(lst) 
    { 
        foreach(local cur in lst)
        {
            if(cur.propDefined(&remoteListenDesc))
            {
                cur.remoteListenDesc(gActor);
            }
            else
            {
                cur.display(&listenDesc);                
            }
        }
    }      
;



/* 
 *   This Special redefines canHear, canSee and canSmell to take account of
 *   possible sensory connections across rooms in a SenseRegion
 */

QSenseRegion: Special
    
    priority = 2

    
    active = true

   
   
    /*
     *   Can A see B?  We return true if and only if B is in light and
     *   there's a clear sight path from A to B.  
     */
    canSee(a, b)
    {
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        local blockList = Q.sightBlocker(a, b);
        
        /* 
         *   A can't see B if B isn't in the light or there's something other
         *   than a room blocking the sight path between them
         */
        if(!Q.inLight(b) || blockList.indexWhich({x: !x.ofKind(Room)} ) != nil)            
            return nil;
        
        
        /* 
         *   A can see B if A and B are in the same room or if B is in one of
         *   the rooms in A's room's visibleRoom's list and B can be seen
         *   remotely from A's pov.
         */   
        
        local c = a.getOutermostRoom();
        
        return b.isOrIsIn(c) || (b.isVisibleFrom(a) &&
                             c.visibleRooms.indexOf(b.getOutermostRoom));
        
        
        
    }

    

    

    /*
     *   Can A hear B?  We return true if there's a clear sound path from A
     *   to B.  
     */
    canHear(a, b)
    {
         if(a.isIn(nil) || b.isIn(nil))
            return nil;        
        
        local blockList = Q.soundBlocker(a, b);      
        
        
        /* 
         *   A can't hear B if B there's something other
         *   than a room blocking the sound path between them
         */
        if(blockList.indexWhich({x: !x.ofKind(Room)} ) != nil)            
            return nil;
        
        
        /* 
         *   A can see B if A and B are in the same room or if B is in one of
         *   the rooms in A's room's audibleRoom's list and B can be heard
         *   remotely from A's pov.
         */   
        
        local c = a.getOutermostRoom();
        
        return b.isOrIsIn(c) || (b.isAudibleFrom(a) &&
                             c.audibleRooms.indexOf(b.getOutermostRoom));
    }

    

    /*
     *   Can A smell B?  We return true if there's a clear scent path from
     *   A to B.  
     */
    canSmell(a, b)
    {
         if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
         local blockList = Q.scentBlocker(a, b);
        
        /* 
         *   A can't smell B if B there's something other
         *   than a room blocking the scent path between them
         */
        if(blockList.indexWhich({x: !x.ofKind(Room)} ) != nil)            
            return nil;
        
        
        /* 
         *   A can smell B if A and B are in the same room or if B is in one of
         *   the rooms in A's room's smelablelRoom's list and B can be seen remotely
         *   from A's pov.
         */   
        
        local c = a.getOutermostRoom();
        
        return b.isOrIsIn(c) || (b.isSmellableFrom(a) &&
                             c.smellableRooms.indexOf(b.getOutermostRoom));
    }

    /* 
     *   For A to be able to talk to B, A must both be able to hear B and either
     *   be in the same room as B or in a room that's close enough to be able to
     *   converse with B
     */
    
    canTalkTo(a, b)
    {
         if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        local c = a.getOutermostRoom();
        
        return Q.canHear(a, b) 
            && (b.isIn(c) 
                || c.talkableRooms.indexOf(b.getOutermostRoom) != nil);
    }
   
    
    canThrowTo(a, b)
    {
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        local c = a.getOutermostRoom();
        
        return b.isOrIsIn(c) 
            || c.throwableRooms.indexOf(b.getOutermostRoom) != nil; 
    }
;


