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
 *   This file forms part of the adv3Lite library by Eric Eve (c) 2012, 2013
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
     *   Is it possible to hear sounds (but not necessarily converse) in one
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
    
    /*  
     *   Use this method to carry out some additional initialization useful to
     *   SenseRegions
     */
    setFamiliarRooms()
    {
        /* Carry out the inherited handling. */
        inherited();
                
        /* 
         *   Also take the opportunity to build each room's list of
         *   sensory-connected rooms.
         */        
        
        /* Go through each room in our room list */
        foreach(local rm in roomList)
        {
            /* 
             *   If we can see into remote rooms from here, append our list of
             *   visible rooms to the other room's list of visible rooms,
             *   excluding itself.
             */
            if(canSeeAcross)
                rm.visibleRooms = rm.visibleRooms.appendUnique(roomList - rm);
            
            /* And so on for the other senses */
            if(canHearAcross)
                rm.audibleRooms = rm.audibleRooms.appendUnique(roomList - rm);
            
            if(canSmellAcross)
                rm.smellableRooms = rm.smellableRooms.appendUnique(roomList - rm);
            
            if(canTalkAcross)
                rm.talkableRooms = rm.talkableRooms.appendUnique(roomList - rm);
            
            if(canThrowAcross)
                rm.throwableRooms = rm.throwableRooms.appendUnique(roomList - rm);
            
            rm.linkedRooms = rm.linkedRooms.appendUnique(roomList - rm);      
            
            /* 
             *   Sort each room's sensory room lists in ascending orfer of their
             *   remoteRoomListOrder(pov) from the pov of that room.
             */
            rm.visibleRooms = rm.sortRoomSublist(rm.visibleRooms, rm);
            rm.audibleRooms = rm.sortRoomSublist(rm.audibleRooms, rm);
            rm.smellableRooms = rm.sortRoomSublist(rm.smellableRooms, rm);
            
            
        }
        
    }      
    
    /* 
     *   Add everything to scope for all the rooms that belong to this
     *   SenseRegion. We do this by sending a senseProbe into each of the rooms
     *   and adding what would be in scope for that probe.
     */    
    addExtraScopeItems(action)
    {
        /* Carry out the inherited handling */
        inherited(action);
        
        /* Initialize a new vector for our extra scope items */
        local extraScope = new Vector(30);
        
        /* Go through every room in our list */
        foreach(local rm in roomList)
        {
            /* Move the scopeProbe_ object into the room */
            scopeProbe_.moveInto(rm);
            
            /* 
             *   Add to our scope everything that's in scope for our scopeProbe_
             *   while it's in the other room.
             */
            extraScope.appendAll(Q.scopeList(scopeProbe_).toList);
        }
        
        /*  
         *   Restrict the extra scope items to those that the actor knows about.
         */
        extraScope = extraScope.subset({o: gActor.knowsAbout(o)} );
              
        
        /* 
         *   Append our list of extra scope items to the action's scope list,
         *   removing any duplicates.
         */
        action.scopeList = action.scopeList.appendUnique(extraScope.toList -
            scopeProbe_);
        
        /* Remove the scopeProbe_ from the map */
        scopeProbe_.moveInto(nil);
    }   
    
    /* 
     *   Since the PC should be able to see round the whole of a SenseRegion,
     *   presumably the PC should also be able to find their way around a
     *   SenseRegion once any of its rooms has been visited, even if the PC is
     *   yet to visit the other rooms. We can achieve this effect by making the
     *   SenseRegion familiar once any of its rooms has been visited, provided
     *   there's line of sight across the rooms in the SenseRegion and the PC is
     *   in a room in the SenseRegion which has light.
     */
    familiar()
    {
        local fam = nil;
        local loc = gPlayerChar.getOutermostRoom;
        
        if(canSeeAcross && loc.isIn(self) && loc.isIlluminated)
            fam = true;
        
        /* 
         *   Once our familiar property becomes true it should never become nil
         *   again, so we can simply convert familiar to the constant value true
         *   and avoid the need to keep recalculating it.
         */
        if(fam)
            familiar = fam;
        
        return fam;
    }
    
    /* 
     *   Flag: do we want the touchObj PreCondition to move the actor from one
     *   Room in the SenseRegion to another by implicit action to allow an actio
     *   to proceed? By default we set this to the value of contSpace, since if
     *   contSpace is true (i.e. we're using this SenseRegion to model a fairly
     *   small continuous space, such as a room) it probably makes sense for
     *   autoGoTo to be true as well, but it's nonetheless perfectly all right
     *   to override the values of autoGoTo and contSpace independently.
     */
    autoGoTo = contSpace
    
    /*   
     *   If our autoGoTo flag is set, our fastGoTo flag should normally also be
     *   set so that autoGoTo works smoothly without breaks for CONTINUE
     *   commands impeding the workings of an implicit GoTo. Note, however, that
     *   it's perfectly okay to override fastGoTo to true on a SenseRegion for
     *   which autoGoTo is nil; it just may not be such a good idea to do it the
     *   other way round.
     */
    fastGoTo = autoGoTo
    
    
    /* 
     *   Flag, do we want this SenseRegion to act as a continuous space (e.g.
     *   representing parts of the same room, so that moving from one room to
     *   another within this SenseRegion does not trigger a new room
     *   description, thereby creating the impression that we have moved within
     *   the same room rather than to another. This should probably be used
     *   sparingly and only for SenseRegions representing a relatively small
     *   area, otherwise the lack of a new room description (i.e. a LOOK AROUND)
     *   could be confusing to the player.
     */
    contSpace = nil
    
    
    
;
    

/* 
 *   modifications to Room to allow SenseRegions to work.
 */
modify Room
    
    /* 
     *   The list of rooms that are visible from this room. Ordinarily this list
     *   is constructed at Preinit by any Sense Regions this room belongs to, so
     *   shouldn't normally be manually adjusted by game code. It's conceivable
     *   that game code could tweak these lists after Preinit, though, perhaps
     *   to create a one-way connection (e.g. to model a high room that
     *   overlooks lower ones)
     */         
    visibleRooms = []
    
    /* 
     *   The lists of rooms we can smell, hear, talk or throw from/into from
     *   this room.
     */
    audibleRooms = []
    smellableRooms = []
    talkableRooms = []
    throwableRooms = []

    /*  
     *   The list of rooms to which we're linked by virtue of being in the same
     *   SenseRegion.
     */
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
     *   the subsequent methods to use. pov is the point of view object
     *   (typically the player character) from whose point of view the list is
     *   being constructed.
     */
    showFirstRemoteSpecials(pov)
    {
        /* 
         *   The list of items whose specialDescs are to be displayed before the
         *   list of miscellaneous items.
         */
        local specialVec1 = new Vector(10);
        
        /* 
         *   The list of items whose specialDescs are to be displayed after the
         *   list of miscellaneous items.
         */
        local specialVec2 = new Vector(10);
        
        /*   The list of miscellaneous items */
        local miscVec = new Vector(10);
        
        /* 
         *   Reduce our list to that subset of the list that is visible to the
         *   pov object.
         */
        local lst = contents.subset({o: o.isVisibleFrom(pov) && !o.isHidden
                                    && gActor.canSee(o)});
        
        /* 
         *   Sort the objects to be listed into three separate lists: those with
         *   specialDescs to be shown before the lists of miscellaneous items,
         *   the list of miscellaneous items, and the list of objects with
         *   specialDescs to be listed after the miscellaneous items.
         */
        foreach(local obj in lst)
        {            
            /* 
             *   See if obj defines an initSpecialDesc property or specialDesc
             *   property that is currently in use.
             */
            if((obj.propType(&initSpecialDesc) != TypeNil &&
               obj.useInitSpecialDesc()) ||
               (obj.propType(&specialDesc) != TypeNil && obj.useSpecialDesc()))
            {
                /* 
                 *   If so, and obj's specialDesc is to be shown before any
                 *   miscellaneous contents, add obj to the first specials list
                 */
                if(obj.specialDescBeforeContents)
                    specialVec1.append(obj);
                /* 
                 *   If obj's specialDesc is to be shown after this list of
                 *   miscellaneous context, add obj to the second list of
                 *   specials.
                 */
                else
                    specialVec2.append(obj);
            }
            /* 
             *   Otherwise, if obj doesn't define a currently usable specialDesc
             *   or initSpecialDesc, add it to the list of miscellaneous items.
             */
            else 
                miscVec.append(obj);
        }
        
        /* Sort the first list of specials in specialDescOrder */        
        specialVec1.sort(nil, {a, b: a.specialDescOrder - b.specialDescOrder});
        
        /* Sort the second list of specials in specialDescOrder */
        specialVec2.sort(nil, {a, b: a.specialDescOrder - b.specialDescOrder});
                       
        /* 
         *   Show the items in the first list, i.e. the list of items with
         *   specialDescs to be shown before the miscellaneous items.
         */
        foreach(local obj in specialVec1)        
        {
            obj.showRemoteSpecialDesc(pov);      
            listRemoteContents(obj.contents, remoteSubContentsLister, pov);
        }
        
        
        
        /* Store the other two lists for later use by other methods. */
        remoteSecondSpecialList = specialVec2.toList();
        remoteMiscContentsList = miscVec.toList().subset({o:
            o.location.ofKind(Room)});
    }
    
    /* Show the removeSpecialDesc of each item in the second list of specials */
    showSecondRemoteSpecials(pov)
    {
        foreach(local obj in remoteSecondSpecialList)
        {
            obj.showRemoteSpecialDesc(pov); 
            listRemoteContents(obj.contents, remoteSubContentsLister, pov);
        }
    }
    
    /* List the miscellaneous list of items in this remote location */
    showRemoteMiscContents(pov)
    {        
        remoteContentsLister.show(remoteMiscContentsList, inRoomName(pov));  
        listRemoteContents(remoteMiscContentsList, remoteSubContentsLister,
                           pov);
    }
    
    /* 
     *   The contents lister to use to list this room's miscellaneous contents
     *   when viewed from a remote location.
     */
    remoteContentsLister = remoteRoomContentsLister
    
    /* 
     *   Reset the contents of all the remote rooms visible from this room to
     *   not having been mentioned.
     */
    unmentionRemoteContents()
    {
        foreach(local rm in visibleRooms)
            unmention(rm.allContents);
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
    
    /* 
     *   The following six methods take effect only if there would otherwise be
     *   a sensory connection between the current room and loc due to their
     *   being in the same SenseRegion.
     *
     *   Can we see into this room from loc?
     */    
    canSeeInFrom(loc) { return canSeeOutTo(loc); }
    
    /*   Can we see out of this room to loc? */
    canSeeOutTo(loc) { return true; }
    
    /*   
     *   Can we hear into this room from loc (i.e. can an actor in loc hear
     *   something in this room?
     */
    canHearInFrom(loc) { return canHearOutTo(loc); }
    
    /*   
     *   Can we hear out from this room to loc (i.e. can an actor in this room
     *   hear something in loc)?
     */
    canHearOutTo(loc) { return true; }
    
    /*   
     *   Can we smell into this room from loc (i.e. can an actor in loc smell
     *   something in this room?
     */
    canSmellInFrom(loc) { return canSmellOutTo(loc); }
    
    /*   
     *   Can we hear out from this room to loc (i.e. can an actor in this room
     *   hear something in loc)?
     */
    canSmellOutTo(loc) { return true; }    
    
    /* 
     *   Should we look around on entering this room? Normally we should, unless
     *   both the room obj is travelling from and the room it's travelling to
     *   (normally this room) both belong in a SenseRegion whose contSpace
     *   property is true.
     */
    lookOnEnter(obj)
    {
        return obj.getOutermostRoom.regionsInCommonWith(destination).indexWhich(
            { reg: reg.contSpace } ) == nil;
    }
    
    /* 
     *   listOrder is inherited from Thing with a default value of 100. For a Room in a SenseRegion
     *   it can control the order in which other rooms in the SenseRegion have their contents
     *   described (higher = later), although this can be adjusted via the remoteRoomListOrder(pov)
     *   method.
     */
    // listOrder = 100
    
    
    /*   
     *   For a Room in a SenseRegion return the order in which other rooms in the SenseRegion have
     *   their contents described (higher = later) from the point of view of the pov object, which
     *   will normally be the room from which the viewing, smelling or listening is being performed.
     *   By default we just return the Room's listOrder.
     */
    remoteRoomListOrder(pov)
    {
        return listOrder;
    }
    
    /* 
     *   Sort a sublist of rooms in ascending order of their remoteRoomListOrder(pov) and return the
     *   result.
     */
    sortRoomSublist(sublist, pov)
    {
        /* 
         *   If our sublist contains less than two elements return our sublist unchanged.
         */
        if(sublist.length < 2)
            return sublist;
               
        
        return sublist.sort(nil, {a, b: a.remoteRoomListOrder(pov) - b.remoteRoomListOrder(pov) });
    }
    
    /* 
     *   Our description when we're examined by an actor in a remote location. By default we just
     *   display our description.
     */
    remoteDesc(pov)
    {
        desc;
    }
    
    /* 
     *   If we're ezamined from a remote location, display our remoteDesc rather than look around
     *   within us.
     */
    dobjFor(Examine)
    {
        action()
        {
            if(gActor.isIn(self))
                inherited();
            else
                remoteDesc(gActor);
                
        }
    }
          
;

    
/* 
 *   The default Lister for listing miscellaneous objects in a remote location.
 */
remoteRoomContentsLister: ItemLister
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed && !obj.isHidden; }    
    
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
    
    contentsListedProp = &contentsListedInLook
;

/* 
 *   The default Lister for listing the miscellaneous contents of objects in a
 *   remote location.
 */
remoteSubContentsLister: ItemLister
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed && !obj.isHidden; }    
    
    /* 
     *   Show the list prefix. The irName parameter is the inRoomName(pov)
     *   passed from Room.showRemoteMiscContents(pov).
     */
    showListPrefix(lst, pl, inParentName)  
    {        
        DMsg(remote subcontents prefix, '<.p>\^{1} <<pl ? '{plural}
                {is}' : '{dummy} {is}'>> ', inParentName); 
    }
    
    showListSuffix(lst, pl, irName)  
    { 
        DMsg(remote subcontents suffix, '. '); 
    }
    
    contentsListedProp = &contentsListedInLook
;


/* 
 *   Modifications to Thing to support the other mods required for use with
 *   SenseRegion.
 */
modify Thing
       
   /* 
    *   Show our remoteSpecialDesc, i.e. the version of our specialDesc that
    *   should be seen when this item is viewed from a remote location.
    */     
    showRemoteSpecialDesc(pov)
    {
        /* If we've already been mentioned, don't do anything */
        if(mentioned)
            return;
        /* 
         *   Otherwise note that we've now been mentioned before doing anything
         *   else.
         */
        else
            mentioned = true;
        
        /* 
         *   If we have a non-nil initSpecialDesc and our useInitSpecialDesc
         *   property is true, show our remoteInitSpecialDesc from pov's point
         *   of view.
         */
        if(propType(&initSpecialDesc) != TypeNil && useInitSpecialDesc)
            remoteInitSpecialDesc(pov);
        
        /* Otherwise show our remoteSpecialDesc() */
        else if (propType(&remoteSpecialDesc) != TypeNil )
            remoteSpecialDesc(pov);
           
        /* Then add a paragraph break */
        "<.p>";
        
        /* Note that we've been seen */
        noteSeen();
    }
    
    /* List contents as seen from a remote location */
    listRemoteContents(lst, lister, pov)
    {
        local contList = lst.subset({o: o.isVisibleFrom(pov) && !o.isHidden});
        
        /* 
         *   Sort the contList in listOrder. Although we're listing the contents
         *   of each item in the contList, it seems good to mention each item's
         *   contents in the listOrder order of the item. Amongst other things
         *   this helps give a consistent ordering for the listing of 
         *   SubComponents.
         */
        contList = contList.sort(nil, {a, b: a.listOrder - b.listOrder});
                     
        
        foreach(local obj in contList)           
        {
             /* Note that the object has been seen by the pc. */
            obj.noteSeen();
            
            /* 
             *   Don't list the inventory of any actors, or of any items that don't want their
             *   contents listed, or any items we can't see in, or of any items that don't have any
             *   contents to list, or of any items whose contents isn't visible remotely from pov.
             */
            if(obj.contType == Carrier 
               || obj.(lister.contentsListedProp) == nil
               || obj.canSeeIn() == nil
               || obj.contents.length == 0
               || obj.contentsVisibleFrom(pov)  == nil)
                continue;
            
                      
            /* 
             *   Don't list any items that have already been mentioned or which
             *   aren't visible from the pov.
             */ 
            local objList = obj.contents.subset({x: x.mentioned == nil &&
                                                x.isVisibleFrom(pov)});
            
            
            /* 
             *   Extract the list of items that have active specialDescs or
             *   initSpecial Descs
             */
            local firstSpecialList = objList.subset(
                {o: (o.propType(&specialDesc) != TypeNil && o.useSpecialDesc())
                || (o.propType(&initSpecialDesc) != TypeNil &&
                    o.useInitSpecialDesc() )
                }
                );
            
            
            /* 
             *   Remove items with specialDescs or initSpecialDescs from the
             *   list of miscellaneous items.
             */
            objList = objList - firstSpecialList;
            
            
            /*   
             *   From the list of items with specialDescs, extract those whose
             *   specialDescs should be listed after any miscellaneous items
             */
            local secondSpecialList = firstSpecialList.subset(
                { o: o.specialDescBeforeContents == nil });
            
            
            /* 
             *   Remove the items whose specialDescs should be listed after the
             *   miscellaneous items from the list of all items with
             *   specialDescs to give the list of items with specialDescs that
             *   should be listed before the miscellaneous items.
             */
            firstSpecialList = firstSpecialList - secondSpecialList;
            
            /*   
             *   Sort the list of items with specialDescs to be displayed before
             *   miscellaneous items by specialDescOrder
             */
            firstSpecialList = firstSpecialList.sort(nil, {a, b: a.specialDescOrder -
                b.specialDescOrder});
            
            /*   
             *   Sort the list of items with specialDescs to be displayed after
             *   miscellaneous items by specialDescOrder
             */
            secondSpecialList = secondSpecialList.sort(nil, {a, b: a.specialDescOrder -
                b.specialDescOrder});
            
            
            /*  
             *   Show the specialDescs of items whose specialDescs should be
             *   shown before the list of miscellaneous items.
             */
            foreach(local cur in firstSpecialList)                    
                cur.showRemoteSpecialDesc(pov); 
            
            
            /*   List the miscellaneous items */
            if(objList.length > 0)   
            {
                lister.show(objList, obj.remoteObjInName(pov),
                            paraBrksBtwnSubcontents);                      
                objList.forEach({o: o.mentioned = true });
            }
            
            /* 
             *   If we're not putting paragraph breaks between each subcontents
             *   listing sentence, insert a space instead.
             */
            if(!paraBrksBtwnSubcontents)
                " ";
            
            
            /*  
             *   Show the specialDescs of items whose specialDescs should be
             *   shown after the list of miscellaneous items.
             */
            foreach(local cur in secondSpecialList)        
                cur.showRemoteSpecialDesc(pov); 
            
            
            /* 
             *   Recursively list the contents of each item in this object's
             *   contents, if it has any; but don't list recursively for an
             *   object that's just been opened.
             */
            if(obj.contents.length > 0 && lister != openingContentsLister)
                listRemoteContents(obj.contents, lister, pov);     
            
           
            
        }
        
         
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
     *   location.By default we just show our ordinary initSpecialDesc, but in
     *   practice we'll normally want to override this.
     */    
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
     // remoteDesc(pov) { desc; }
    
    
    
    /*  
     *   Define the remoteListenDesc() property to define the description of
     *   this item as it should be displayed when the item is listened to from
     *   the remote location containing the pov object. Note that defining this
     *   property nullifies the distinction between a medium and a large
     *   soundSize, since the remoteListenDesc will be used in either case.
     */
     // remoteListenDesc(pov) { listenDesc; }
    
    
    /*  
     *   Define the remoteSmellDesc() property to define the description of this
     *   item as it should be displayed when the item is smelled from the remote
     *   location containing the pov object. Note that defining this property
     *   nullifies the distinction between a medium and a large smellSize, since
     *   the remoteSmellDesc will be used in either case.
     */
     // remoteSmellDesc(pov) { smellDesc; }
    
    
    
    
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
            /* 
             *   If the actor doing the examining is in the same room as this
             *   object, simply carry out the inherited handling.
             */
            if(isIn(gActor.getOutermostRoom))
                inherited;
            
            /* Otherwise, if we're being examined from a remote location... */
            else
            {
                /* 
                 *   If this Thing defines the remoteDesc() property, display
                 *   our remoteDesc() from the pov of the examining actor.
                 */
                if(propDefined(&remoteDesc))
                {
                    remoteDesc(gActor);
                    "<.p>";
                }
                
                /* 
                 *   Otherwise if our sightSize is large, carry out the standard
                 *   (inherited) handling
                 */
                else if(sightSize == large)
                    inherited;
                
                /* 
                 *   Otherwise say this object is too far away for the actor to
                 *   see any detail.
                 */
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
            /* 
             *   If the actor doing the listening is in the same room as this
             *   object, simply carry out the inherited handling.
             */
            if(isIn(gActor.getOutermostRoom))
                inherited;
            
            /* Otherwise, if we're being listened to from a remote location... */
            else
            {
                /* 
                 *   If this Thing defines the remoteListenDesc() property,
                 *   display our remoteListenDesc() from the pov of the
                 *   examining actor.
                 */
                if(propDefined(&remoteListenDesc))
                {
                    remoteListenDesc(gActor);
                    "<.p>";                   
                }
                
                /* 
                 *   Otherwise if our soundSize is large, carry out the standard
                 *   (inherited) handling
                 */
                else if(soundSize == large)
                    inherited;
                
                /* 
                 *   Otherwise say this object is too far away for the actor to
                 *   hear.
                 */
                else
                {
                    say(tooFarAwayToHearMsg);
                    "<.p>";
                }
            }
        }
    }

    tooFarAwayToHearMsg = BMsg(too far away to hear, '{The subj dobj} {is} too
        far away to hear distinctly. ')

    
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
            /* 
             *   If the actor doing the smelling is in the same room as this
             *   object, simply carry out the inherited handling.
             */
            if(isIn(gActor.getOutermostRoom))
                inherited;
            
            /* Otherwise, if we're being smelled from a remote location... */
            else
            {
                /* 
                 *   If this Thing defines the remoteSmellDesc() property,
                 *   display our remoteSmellDesc() from the pov of the
                 *   examining actor.
                 */                
                if(propDefined(&remoteSmellDesc))
                {
                    remoteSmellDesc(gActor);
                    "<.p>";
                }
                
                /* 
                 *   Otherwise if our smellSize is large, carry out the standard
                 *   (inherited) handling
                 */
                else if(smellSize == large)
                    inherited;
                
                /* 
                 *   Otherwise say this object is too far away for the actor to
                 *   smell.
                 */
                else
                {
                    say(tooFarAwayToSmellMsg);
                    "<.p>";
                }
            }
        }
    }
    
    tooFarAwayToSmellMsg = BMsg(too far away to smell, '{The subj dobj} {is} too
        far away to smell distinctly. ')
    
    /* Modify the effects of throwing something at this object */
    iobjFor(ThrowAt)
    {
        action()
        {
            /* 
             *   If the Query object reckons that the throw is possible, carry
             *   out the inherited handling.
             */
            if(Q.canThrowTo(gActor, self))
                inherited;
            
            /* 
             *   Otherwise move the direct object to the throwing actor's room
             *   and display a message saying it fell short of its target.
             */
            else
            {
                gDobj.moveInto(gActor.getOutermostRoom);
                say(throwFallsShortMsg);
            }
        }
    }    
    
    /*         
     *   For certain actions like EXAMINE there's no point trying to carry them
     *   out on something that can't be seen (remotely) if there are other
     *   things that can be seen that matched the player's command.
     */
    filterResolveList(np, cmd, mode) 
    { 
        inherited(np, cmd, mode);
        
        local loc = gActor.getOutermostRoom, prop;
        
        /* 
         *   If we haven't been picked up by a general command that may not have
         *   been intended to apply specifically to us, or we're in the same
         *   room as the actor, we don'd need to do any filtering, so stop here.
         */
        if(mode != All || isIn(loc))
            return;        
        
        /*   
         *   Determine which precondition property we need to look at according
         *   to our object role.
         */
        switch(np.role)
        {
        case DirectObject:
            prop = cmd.action.preCondDobjProp;
            break;
        case IndirectObject:
            prop = cmd.action.preCondIobjProp;
            break;
        case AccessoryObject:
            prop = cmd.action.preCondIobjProp;
            break;
        default:
            prop = cmd.action.preCondDobjProp;
        }
            
            
        /* 
         *   If the current action requires the object to be visible, and we're
         *   not in the same room as the actor, and the actor can't see us, but
         *   the actor can see something else among the possible matches, remove
         *   us from the list of matches.
         */
        if(valToList(self.(prop)).indexOf(objVisible)             
           && !gActor.canSee(self)
           && np.matches.indexWhich({m: gActor.canSee(m.obj)}))
           np.matches = np.matches.subset({m: m.obj != self});   
        
        
        /* 
         *   If the current action requires the object to be touchabble, and
         *   we're not in the same room as the actor, and the actor can't reach
         *   us, but the actor can reach something else among the possible
         *   matches, remove us from the list of matches.
         */
        if(valToList(self.(prop)).indexOf(touchObj)
           && np.matches.indexWhich({m: m.obj.isIn(loc)}))
           np.matches = np.matches.subset({m: m.obj != self}); 
        
    }
    
    /* 
     *   Are our contents visible remotely from pov? By default we'll assume they are, but in some
     *   case they mignt not be, for example if the remote viewing location is too far away or the
     *   viewing angle from the remote location wouldn't allow seeing into us.
     */
    contentsVisibleFrom(pov) { return true; }
    
    /* 
     *   Should our contents be listed in an examine command from a remote location? They should be
     *   if we meet the inherited conditions (normally contentsListedInExamine == true) and our
     *   contents are visible remotely from the actor's POV or the actor is in the same room as us.
     */
    areContentsListedInExamine()
    {
        return inherited && (contentsVisibleFrom(gActor) || getOutermostRoom ==
                             gActor.getOutermostRoom);
    }
     
    dobjFor(LookIn)
    {
        check()
        {
            inherited();
            
            /* 
             *   The actor can't look into us from a remote location if our contents aren't visible
             *   from their POV.
             */
            if(gActor.getOutermostRoom != getOutermostRoom &&
               ! contentsVisibleFrom(gActor))
                DMsg(cant see in from here, '{I} {can\'t} see in {the dobj} from {here}.');
        }
    }
    
    
;


/* 
 *   The scopeProbe_ is a dummy object used by the SenseRegion class to add
 *   items from Pther rooms in the SenseRegion to scope.
 */
scopeProbe_: Thing
;

/* 
 *   Modifications to the (intransitive) Smell and Listen actions to list remote
 *   smells and sounds
 */
modify Smell
    /* 
     *   Return a list of items in remote locations that can be smelt from the
     *   current actor's location.
     */
    getRemoteSmellList() 
    { 
        /* Note the actor's location */
        local loc = gActor.getOutermostRoom;
        
        /* Create a new vector */
        local vec = new Vector(10);
        
        /* 
         *   Go through all the rooms that can be smelled from the actor's
         *   location
         */
        foreach(local rm in loc.smellableRooms)
        {
            
            /* 
             *   Create a list of objects that are in rm that can be smelt by
             *   the actor.
             */
            local sList = rm.allContents.subset({o: Q.canSmell(gActor, o)});
            
            /* 
             *   Create a sublist of that list containing all the items with a
             *   large smellSize that also define a non-nil smellDesc, plus all
             *   the items that define a remoteSmellDesc, in each case provided
             *   that the item's isProminentSmell is true. Remove any item (i.e.
             *   MultiLoc) that's also in the actor's location, so that it's not
             *   duplicated. Then append this sublist to our vector.
             */
            vec.appendUnique(sList.subset({o: ((o.smellSize == large &&
                                            o.checkDisplay(&smellDesc) != nil) ||
                                       o.propDefined(&remoteSmellDesc))
                                       && o.isProminentSmell
                                          && !o.isOrIsIn(loc)} ));
        }
        
        
        /* Convert the vector to a list and return it. */
        return vec.toList();
    }
    
    /* List smells in remote locations */
    listRemoteSmells(lst) 
    { 
        local somethingDisplayed = nil;
        local remoteDisplayed = nil;
        
        /* For each item in lst */
        foreach(local cur in lst)
        {
            /* If the item defined a remoteSmellDesc property, display it */
            if(cur.propDefined(&remoteSmellDesc))
            {
                remoteDisplayed = gOutStream.watchForOutput(
                    {:
                    cur.remoteSmellDesc(gActor)
                    });
                
                if(remoteDisplayed)
                {
                    somethingDisplayed = true;
                    
                    /* 
                     *   If the actor is the player character, the player
                     *   character now knows of the existence of this object.
                     */
                    if(gActor == gPlayerChar)
                        setKnown(cur);
                }
                
            }
            
            /* Othewise display its smellDesc */
            else
            {
                if(cur.display(&smellDesc))
                {
                    somethingDisplayed = true;
                    
                    /* 
                     *   If the actor is the player character, the player
                     *   character now knows of the existence of this object.
                     */
                    if(gActor == gPlayerChar)
                        setKnown(cur);
                }
            }
        }
        
        /* Tell our caller whether we actually displayed anything */
        return somethingDisplayed;
    }
    
    
;

    /* 
     *   Return a list of items in remote locations that can be heard from the
     *   current actor's location.
     */

modify Listen
    /* 
     *   Return a list of items in remote locations that can be heard from the
     *   current actor's location.
     */    
    getRemoteSoundList() 
    { 
        /* Note the actor's location */
        local loc = gActor.getOutermostRoom;
        
        /* Create a new vector */
        local vec = new Vector(10);
        
        /* 
         *   Go through all the rooms that can be heard from the actor's
         *   location
         */
        foreach(local rm in loc.audibleRooms)
        {
           
            /* 
             *   Create a list of objects in the room that can be heard by the
             *   actor.
             */
            local sList = rm.allContents.subset({o: Q.canHear(gActor, o)});
            
            /* 
             *   Create a sublist of that list containing all the items with a
             *   large soundSize that also define a non-nil listenDesc, plus all
             *   the items that define a remoteListenDesc, in each case provided
             *   that the item's isProminentNoise is true. Remove any item (i.e.
             *   MultiLoc) that's also in the actor's location, so that it's not
             *   duplicated. Then append this sublist to our vector.
             */
            vec.appendUnique(sList.subset({o: ((o.soundSize == large &&
                                       o.checkDisplay(&listenDesc) != nil) ||
                                       o.propDefined(&remoteListenDesc))
                                       && o.isProminentNoise
                                          && !o.isOrIsIn(loc)} ));
        }
        
       
        /* Convert the vector to a list and return it. */
        return vec.toList();
    }
    
    
    
    /* List smells in remote locations */
    listRemoteSounds(lst) 
    { 
        local somethingDisplayed = nil;
        local remoteDisplayed = nil;
        
         /* For each item in lst */
        foreach(local cur in lst)
        {
            /* If the item defined a remoteListenDesc property, display it */
            if(cur.propDefined(&remoteListenDesc))
            {
                remoteDisplayed = gOutStream.watchForOutput(
                    {:
                    cur.remoteListenDesc(gActor)
                    });
                
                if(remoteDisplayed)
                {
                    somethingDisplayed = true;
                    
                    /* 
                     *   If the actor is the player character, the player
                     *   character now knows of the existence of this object.
                     */
                    if(gActor == gPlayerChar)
                        setKnown(cur);
                }
            }
            
            /* Othewise display its listenDesc */
            else
            {
                if(cur.displayAlt(&listenDesc))
                {
                    somethingDisplayed = true;
                    
                    /* 
                     *   If the actor is the player character, the player
                     *   character now knows of the existence of this object.
                     */
                    if(gActor == gPlayerChar)
                        setKnown(cur);
                }
            }
        }
        
        /* Tell our caller whether we actually displayed anything */
        return somethingDisplayed;
    }      
;

modify SmellSomething
    /* Add any Odors the actor can smell */
    addExtraScopeItems(whichRole?)
    {
        inherited(whichRole);
        
        local odorList = [];
        for(local rm in gActor.getOutermostRoom.smellableRooms)            
            odorList += rm.allContents.subset(
            { o: o.ofKind(Odor) && Q.canSmell(gActor, o) } );
        
        scopeList = scopeList.appendUnique(odorList);
    }
;

modify ListenTo
    /* Add any Noises the actor can hear */
    addExtraScopeItems(whichRole?)
    {
        inherited(whichRole);
        
        local noiseList = [];
        for(local rm in gActor.getOutermostRoom.audibleRooms)            
            noiseList += rm.allContents.subset(
            { o: o.ofKind(Noise) && Q.canHear(gActor, o) } );
        
        scopeList = scopeList.appendUnique(noiseList);
    }
;

/* 
 *   This Special redefines canHear, canSee, canSmell, canTalkTo and canThrowTo
 *   to take account of possible sensory connections across rooms in a
 *   SenseRegion
 */
QSenseRegion: Special
    
    /* 
     *   Gives this Special a slightly higher priority than QDefaults, so that
     *   it takes priority.
     */
    priority = 2

    /* This Special should be active whenever this module is included. */
    active = true

     
    /*
     *   Can A see B?  We return true if and only if B is in light and
     *   there's a clear sight path from A to B.  
     */
    canSee(a, b)
    {
        /* 
         *   If either a or b is not on the map, assume we can't see from A to
         *   B and return nil (otherwise we'd probably get a run-time error
         *   further down the line). Also A can't see B if B is hidden.
         */
        if(a.isIn(nil) || b.isIn(nil) || b.isHidden)
            return nil;
        
        /* 
         *   Construct a list of objects that might block the sight path from A
         *   to B.
         */
        local blockList = Q.sightBlocker(a, b);
        
        /* 
         *   A can't see B if B isn't in the light or there's something other
         *   than a room or A or B blocking the sight path between them
         */
        if(!(inLightFor(a, b))
           || blockList.indexWhich({x: x not in (a, b) && !x.ofKind(Room)} ) != nil)            
            return nil;
        
              
        /* 
         *   A can see B if A and B are in the same room or if B is in one of
         *   the rooms in A's room's visibleRoom's list and B can be seen
         *   remotely from A's pov.
         */           
        local ar = a.getOutermostRoom(), br = b.getOutermostRoom();    
       
        /* 
         *   If a and b are in different rooms and b is in a container whose contents can't be seen
         *   remotely, then a can't see b.
         */
        if(ar != br && sightBlockingContainer(a, b))
            return nil;
        
        
        return b.isOrIsIn(ar) || (b.isVisibleFrom(a) &&
                             ar.visibleRooms.indexOf(br)
                                  && ar.canSeeOutTo(br)
                                  && br.canSeeInFrom(ar));
               
        
    }

    /* Is b in a container whose contents can't be viewed remotely from a's location? */
    sightBlockingContainer(a, b)
    {
        local loc = b.location;
        
        while(loc && !loc.ofKind(Room))        
        {
            if(!loc.contentsVisibleFrom(a))
                return loc;
            
            loc = loc.location;
        }
        
        return nil;
    }
    
    inLight(a) { return next(); }
    
    
    /* is B lit from the perspect of A, who may be inside B. */
    inLightFor(a, b)
    {
        return next();
    }
    
    /*
     *   Can A hear B?  We return true if there's a clear sound path from A
     *   to B.  
     */
    canHear(a, b)
    {
        /* 
         *   If either a or b is not on the map, assume A can't hear B and
         *   return nil (otherwise we'd probably get a run-time error further
         *   down the line.
         */
         if(a.isIn(nil) || b.isIn(nil))
            return nil;        
        
        /* 
         *   Construct a list of objects that might block the sound path from A
         *   to B.
         */
        local blockList = Q.soundBlocker(a, b);      
        
        
        /* 
         *   A can't hear B if B there's something other than a room  or A or B blocking
         *   the sound path between them
         */
        if(blockList.indexWhich({x: !x.ofKind(Room) && x not in (a, b)} ) != nil)            
            return nil;
        
        
        /* 
         *   A can hear B if A and B are in the same room or if B is in one of
         *   the rooms in A's room's audibleRoom's list and B can be heard
         *   remotely from A's pov.
         */           
        local ar = a.getOutermostRoom(), br = b.getOutermostRoom();    
             
        
        return b.isOrIsIn(ar) || (b.isAudibleFrom(a) &&
                             ar.audibleRooms.indexOf(br)
                                  && ar.canHearOutTo(br)
                                  && br.canHearInFrom(ar));
    }

    

    /*
     *   Can A smell B?  We return true if there's a clear scent path from
     *   A to B.  
     */
    canSmell(a, b)
    {
        /* 
         *   If either a or b is not on the map, assume A can't smell B and
         *   return nil (otherwise we'd probably get a run-time error further
         *   down the line.
         */
         if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        /* 
         *   Construct a list of objects that might block the scent path from A
         *   to B.
         */
         local blockList = Q.scentBlocker(a, b);
        
        /* 
         *   A can't smell B if B there's something other
         *   than a room blocking the scent path between them
         */
        if(blockList.indexWhich({x: !x.ofKind(Room) && x not in (a, b)}) != nil)            
            return nil;
        
        
        /* 
         *   A can smell B if A and B are in the same room or if B is in one of
         *   the rooms in A's room's smelablelRoom's list and B can be seen
         *   remotely from A's pov.
         */           
        local ar = a.getOutermostRoom(), br = b.getOutermostRoom();    
             
        
        return b.isOrIsIn(ar) || (b.isSmellableFrom(a) &&
                             ar.smellableRooms.indexOf(br)
                                  && ar.canSmellOutTo(br)
                                  && br.canSmellInFrom(ar));
        
        
    }

    /* 
     *   For A to be able to talk to B, A must both be able to hear B and either
     *   be in the same room as B or in a room that's close enough to be able to
     *   converse with B
     */
    
    canTalkTo(a, b)
    {
        /* 
         *   If either a or b is not on the map, assume A can't talk to B and
         *   return nil (otherwise we'd probably get a run-time error further
         *   down the line.
         */
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        /* Note which room A is in */
        local c = a.getOutermostRoom();
        
        /* 
         *   A can talk to B if A can hear B and B's location is in C's list of
         *   rooms where conversation can take place from C, or if B is in C.
         */
        return Q.canHear(a, b) 
            && (b.isIn(c) 
                || c.talkableRooms.indexOf(b.getOutermostRoom) != nil);
    }
   
    /* Can A throw an object to B? */
    canThrowTo(a, b)
    {        
        /* 
         *   If either a or b is not on the map, assume A can't throw anything
         *   to B and return nil (otherwise we'd probably get a run-time error
         *   further down the line.
         */
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        /* Note which room A is in */
        local c = a.getOutermostRoom();
        
        /* 
         *   A can throw something to B if B's location is in C's list of rooms
         *   into which objects can be thrown from C, or if B is in C.
         */
        return b.isOrIsIn(c) 
            || c.throwableRooms.indexOf(b.getOutermostRoom) != nil; 
    }
    
    /*
     *   Determine if A can reach B, and if not, what stands in the way. Returns
     *   a list of containers along the path between A and B that obstruct the
     *   reach.  If the two objects are in separate rooms, the top-level room
     *   containing A is in the list to represent the room separation.  If
     *   there's no obstruction, we return an empty list.
     */
    reachBlocker(a, b)
    {
        local blockList = a.containerPathBlock(b, &canReachOut, &canReachIn);
        
        /* 
         *   ignore any blocking objects that are Rooms in the same SenseRegion
         *   where the SenseRegion's autoGoTo property is true.
         */
        blockList = blockList.subset({o: nonBlocker(o, b) == nil });
        
        
        return blockList;
    }
     
    /* 
     *   Is o the kind of object that would block movement from one room to the
     *   room containing b? It is unless o is a room and the room and b are both
     *   in a SenseRegion for which autoGoTo is true.
     */
    nonBlocker(o, b)
    {
        /* If o isn't a Room, it's something that blocks movement */
        if(!o.ofKind(Room))
            return nil;
        
        /* Get the Room in which b is located. */
        local bLoc = b.getOutermostRoom;
        
        /* Get the list of Regions containing both o and bLoc. */
        local regList = o.regionsInCommonWith(bLoc);
        
        /* Reduce it to the list of Regions for which autoToGo is true */
        regList = regList.subset({r: r.autoGoTo} );
        
        /* 
         *   If this list is not empty, we're a non-blocker so return true,
         *   otherwise return nil
         */
        return regList.length > 0;
        
    }
    
    /* 
     *   Prepend a ReachProblemRemote to move the actor to the location of the
     *   target object if it's in a remote location, then add any issues we
     *   would have obtained from the next Special in line.
     */
//    reachProblemCheck(a, b)
//    {
//        local issues = [];
//        
//        if(a.getOutermostRoom != b.getOutermostRoom)
//            issues += new ReachProblemRemote(a, b);
//        
//        return issues + next();
//    }
;

/* 
 *   The ReachProblemRemote should only be brought into play when an actor in
 *   one room in a SenseRegion tries to touch an object in another room in the
 *   SenseRegion when the SenseRegion defines autoGoTo as true. The
 *   ReachProblemRemote will then be responsible for trying to move the actor
 *   into the room containing the target object.
 */
class ReachProblemRemote: ReachProblem
    construct(a, b)
    {
        origRoom = a.getOutermostRoom;
        destRoom = b.getOutermostRoom;
        target = b;
    }
    
    origRoom = nil
    destRoom = nil
    target = nil
    
    /* 
     *   This check method may be called by the checkPreCondition method of the
     *   touchObj PreCondition. Its effect is to try to move the actor into the
     *   location of the object the actor is trying to touch.
     */
    check(allowImplicit)   
    {
        /* 
         *   If the actor is already in the location of the target object,
         *   there's nothing to do here. This should never be the case when this
         *   method is called, but we include the check just to be sure.
         */
        if(origRoom == destRoom)
            return true;    
        
        
        
        /* 
         *   If implicit actions are allowed, try moving the actor to the
         *   destination room (the room containing the object to be touched).
         */
        if(allowImplicit && sayGoTo(destRoom) &&
           tryImplicitAction(GoTo, destRoom))
        {
            /* 
             *   If the actor isn't in the destination room, return nil to tell
             *   our caller we failed.
             */
            if(!gActor.isIn(destRoom))
                return nil;               
        }
        else
        {
            /* 
             *   If the implicit GoTo action can't be attempted, simply display
             *   a message to say that the target object is too far away.
             */
            say(tooFarAwayMsg);
            
            /* Then return nil to tell our caller we failed. */
            return nil;
        }
        
        /* 
         *   If we reached this point, all is well, so return true to tell our
         *   caller we succeeded.
         */
        return true;
        
        
    }
    
    /* 
     *   The failure message to display if we can't attempt an implicit GoTo
     *   action to move the actor.
     */
    tooFarAwayMsg()
    {
        /* Let the actor's room provide the message. */
        return origRoom.cannotReachTargetMsg(target);              
    }
    
    /* 
     *   Report that we are trying to head to destRoom via an implicit action.
     *   We do this separately from the normal implicit action report mechanism
     *   so that this report is display before travel begins, not at the end of
     *   it as it otherwise would be.
     */
    sayGoTo(destRoom)
    {        
        DMsg(implicit go, '(first heading for {1})\n', destRoom.theName);
        return true;
    }
;

modify touchObj
    checkPreCondition(obj, allowImplicit)
    {
        /* 
         *   We first try moving to a new room as a separate exercise before
         *   checking for any other obstacles, since if the move is successful
         *   it may change the status of other potential obstacles.
         */
        local remoteCheck = new ReachProblemRemote(gActor, obj);
        
        if(!remoteCheck.check(allowImplicit))
            return nil;
        
        return inherited(obj, allowImplicit);
    }
;