#charset "us-ascii"
#include "advlite.h"

/*
 *   ***************************************************************************
 *   attachables.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve
 *
 *
 *
 *   The attachables file provides a framework for simple and common case
 *   attachables.
 *
 *   It treats attachment as an asymmetric relationship. ATTACH A TO B is not
 *   the same as ATTACH B TO A. It also treats it as a many-to-one relationship:
 *   the object that is attached can only be attached to one object at a time,
 *   but the object it's attached to can have multiple objects attached to it.
 *
 */

/* 
 *   A SimpleAttachabe is a Thing that can be attached to other things or have
 *   other things attached to it in the special case in which the attached
 *   objects are located in the object to which they are attached.
 *   SimpleAttachable is also the base class for other types of attachable.
 */
class SimpleAttachable: Thing
    
    /* 
     *   Can an object be attached to this one? By default we return true if obj
     *   is on our list of allowableAttachments.
     */
    allowAttach(obj)
    {
        return valToList(allowableAttachments).indexWhich(
            {o: o.ofKind(obj) != nil});
    }
    
    /* A list of the objects or classes of objects that can be attached to me */
    allowableAttachments = []
    
    /* A list of the objects that are attached to me */
    attachments = []
    
    /* A SimpleAttachable can be attached to (some) other things. */
    isAttachable = true
    
    /* A SimpleAttachable can have (some) other things attached to it */
    canAttachToMe = true
    
    /* A SimpleAttachable can have (some) other things detached from it */
    canDetachFromMe = true    
    
    /* The list of things I'm currentl attached to */
    attachedToList = []
    
    /* The object, if any, I'm currently attached to*/
    attachedTo = (attachedToList == [] ? nil : attachedToList[1])
    
    /* 
     *   The object, if any, to which I'm initially attached (if I start out attached to anything).
     *   If this is defined, it should be another SimpleAttachable or subclass thereof.
     */
    initiallyAttachedTo = nil
    
    
    /* 
     *   The location this object should be moved to when it's attached to
     *   another object. A SimpleAttachment should normally be moved into the to
     *   which it's attached.
     */
    attachedLocation = (attachedTo)
    
    /*   
     *   The location this object should be moved to when it's detached. A
     *   SimpleAttachment should normally be moved into the location of the
     *   object it's just been detached from.
     */
    detachedLocation = (attachedTo.location)
    
    /* Attach this object to obj */
    attachTo(obj)
    {
        /* Note that we're now attached to the iobj of the attach action */
        makeAttachedTo(obj);         
        
        /* Add us to the iobj's list of attachments. */
        obj.attachments = obj.attachments.appendUnique([self]);
        
        /* 
         *   If we're already in our attached location, there's no need to move,
         *   otherwise move us into our attached location.
         */
        if(location != attachedLocation)
            actionMoveInto(attachedLocation);
    }
    
    /* Add the object we're now attached to to our attachedToList */
    makeAttachedTo(obj)
    {
        attachedToList = attachedToList.appendUnique([obj]);
    }
    
    /* Detach this item from obj */
    detachFrom(obj)
    {
        /* If we're not attached to obj, then there's nothing to do */
        if(!isAttachedTo(obj))
            return;
        
        /* If we're not already in our detachedLocation, move us there. */
        if(location != detachedLocation)
            moveInto(detachedLocation);
        
        /* 
         *   Remove us from the list of attachements of the object to which we
         *   were formerly attached.
         */
        obj.attachments -= self;
        
        /* Note that we're no longer attached to obj. */
        makeDetachedFrom(obj);
    }
    
    /* FRemove obj the list of objeccts attached to us */
    makeDetachedFrom(obj)
    {
        attachedToList -= obj;
    }
    
    
    /*  Handling for the ATTACH TO action */
    dobjFor(AttachTo)
    {
        preCond = [objHeld]
        
        verify()
        {
            /* Carry out the inherited handling. */
            inherited; 
            
            /* We can't be attached while we're already attached */
            if(attachedTo == gVerifyIobj)
                illogicalNow(alreadyAttachedMsg);
            else if(attachedTo != nil)
                illogicalNow(cannotAttachToMoreMsg);
        }
        
        action()
        {            
            attachTo(gIobj);
        }
        
        report()
        {
            say(okayAttachMsg);
        }
    }
    
   
    
    
    okayAttachMsg = BMsg(okay attach, '{I} attach{es/ed} {1} to {the iobj}. ',
                         gActionListStr) 
    
    alreadyAttachedMsg = BMsg(already attached, '{The subj dobj} {is} already
        attached to {1}. ', attachedTo.theName)
    
    cannotAttachToMoreMsg = BMsg(cannot attach to more, '{I} {can\'t} attach
        {the dobj} to anything else while {he dobj}{\'s} attached to {1}. ',
                                 makeListStr(attachedToList, &theName))      
    
    iobjFor(AttachTo)
    {
        preCond = [touchObj]
        
        verify()
        {
            /* Carry out the inherited handling. */
            inherited;
            
            /* 
             *   If we don't allow the dobj to be attached to us, rule out the
             *   attachment.
             */
            if(!allowAttach(gVerifyDobj))
                illogical(cannotBeAttachedMsg);
        }
    }
    
    notAttachedMsg = BMsg(not attached, '{The subj dobj} {is}n\'t attached to
        anything. ')
    
    dobjFor(Detach)
    {
        verify()
        {                   
            /* We can't be detached if we're not attached to anything */
            if(attachedToList.length == 0)
                illogicalNow(notAttachedMsg);           
        
            /* We can't be detached if we're not detachable */
            else if(!isDetachable)
                implausible(cannotDetachMsg);
        }
        
        action()
        { 
            for(local cur in attachedToList)
               detachFrom(cur);                   
        }
        
        report()   {  say(okayDetachMsg);   }
        
    }
    
    okayDetachMsg = BMsg(okay detach, '{I} detach{es/ed} {1}. ', gActionListStr)
    
    
    dobjFor(DetachFrom)
    {
        verify()
        {
            /* 
             *   We can't be detached from anything if we're not attached to
             *   anything.
             */
            if(attachedToList.length == 0)
                illogicalNow(notAttachedMsg);  
            
            /* We can't be detached from the iobj if we're not attached to it */
            else if(!isAttachedTo(gVerifyIobj))
                illogicalNow(notAttachedToThatMsg);
            
            /* Carry out the inherited handling. */
            inherited;
        }
        
        
        
        action()
        {
            detachFrom(gIobj);            
        }
        
        report()
        {
            say(okayDetachFromMsg);            
        }
    }
    
    okayDetachFromMsg = BMsg(okay detach from, '{I} detach{es/ed} {1} from
        {the iobj}. ',  gActionListStr)
    
    cannotDetachMsg = BMsg(cannot detach this, '{The subj dobj} {cannot} be
        detached from {1}. ', location.theName)
    
    iobjFor(DetachFrom)
    {
        verify()
        {
            /* 
             *   Since we resolve the iobj first we can't tell whether the dobj
             *   is attached, but we can check whether anything at all is
             *   attached to this object.
             */
            if(attachments.length == 0)
                illogicalNow(nothingAttachedMsg);
            
            /* 
             *   Otherwise we can check whether our list of attachments overlaps with the list of
             *   tentative direct objects; if it does, we're probably a good choice of indirect
             *   object.             
             */
            
            else if(attachments.overlapsWith(gTentativeDobj))
                logicalRank(120);
            
                
            /* Carry out the inherited handling */
            inherited;
                
        }
    }
    
    cannotDetachFromMsg = BMsg(cannot detach from this , '{The {ubj dobj}
        {can\'t} be detached from {the iobj}. ')
    
    notAttachedToThatMsg = BMsg(not attached to that, '{The subj dobj} {isn\'t}
        attached to {the iobj}. ')
    
    nothingAttachedMsg = BMsg(nothing attached, 'There {dummy} {isn\'t} anything
        attached to {the iobj}. ')

    /* Treat Fasten and Unfasten as equivalent to Attach and Detach */
    dobjFor(FastenTo) asDobjFor(AttachTo)
    iobjFor(FastenTo) asIobjFor(AttachTo)
    dobjFor(UnfastenFrom) asDobjFor(DetachFrom)
    iobjFor(UnfastenFrom) asIobjFor(DetachFrom)
    dobjFor(Unfasten) asDobjFor(Detach)
    
    /* 
     *   We can't take this object while it's attached. Note that this is
     *   assymetric: it applies only to the attached object (the one for which
     *   attachedTo != nil) not to the object it's attached to (which can be
     *   taken with the attached object still attached to it.
     */    
    dobjFor(Take)
    {
        preCond = [objDetached]
    }
                                
 
    /* 
     *   Check while any of my attachments object to my being moved while they
     *   are attached to me. If so, prevent the attempt to move me as the result
     *   of a player command.
     */        
    actionMoveInto(loc)
    {
       /* 
        *   See if there's an object among our attachments that objects to our
        *   being moved while we're attached to it.
        */
          
        local other = attachments.valWhich({o:
                                           !o.allowOtherToMoveWhileAttached});
        
        /* 
         *   If there is, display a message saying we can't be moved while the
         *   object object is attached, then stop the action. 
         */
        if(other != nil)
        {            
            sayCannotMoveWhileAttached(other);
            exit;
        }
        
        
        
        /* Carry out the inherited handling */   
        inherited(loc);
    }
    
    /* 
     *   Display a message saying we can't be moved while we're attached to
     *   other.
     */
    sayCannotMoveWhileAttached(other)
    {
        gMessageParams(other);            
        DMsg(cannot move while attached, '{The subj cobj} {cannot} be moved
            while {he cobj} {is} attached to {the other}. ');   
    }
    
    
    cannotBeAttachedMsg = BMsg(cannot be attached, '{The subj dobj} {cannot} be
        attached to {the iobj}. ')
    
    
    
    /* 
     *   By default I'm not listed as a separate object if I'm attached to
     *   something else.
     */
    isListed = (attachedTo == nil && inherited)
    
    /* 
     *   Is obj attached to me? By default it is if it's in my list of
     *   attachements.
     */
    isAttachedToMe(obj)
    {
        return attachments.indexOf(obj) != nil;
    }
    
    
    /* 
     *   Is there an attachment relationship between myself and obj; there is
     *   either is obj is attached to me or if I'm attached to obj.
     */
    isAttachedTo(obj)
    {
        return isAttachedToMe(obj) || attachedTo == obj;
    }
    
    
    /* Our locType is Attached if we're attached so something. */
    locType()
    {
        if(attachedTo != nil)
            return Attached;
        else
            return inherited;
    }
    
    /* 
     *   If anything's attached to us, list our attachements when we're
     *   examined.
     */    
    examineStatus()
    {
        /* Carry out the inherited handling. */
        inherited;
        
        /* List our attachments, if we have any. */
        if(attachments.length > 0)
            attachmentLister.show(attachments, self);
    }
    
    /* The lister to be used for listing our attachments. */
    attachmentLister = simpleAttachmentLister
    
    /* 
     *   If I'm attached, do I become firmly attached (so that I can't be
     *   removed without an explicit detachment)?
     */
    isFirmAttachment = true
    
    /*   
     *   Allow detachment through a simple DETACH command. (If this is nil
     *   detachment might still be programatically possible, e.g. by UNSCREWing
     *   something).
     */    
    isDetachable = true
    
    /*   
     *   Determine whether the object I'm attached to can be moved while I'm
     *   attached to it. For a SimpleAttachable we normally do allow this, since
     *   I simply move with the other object.
     */    
    allowOtherToMoveWhileAttached = true
    
 
    /* Preinitialize a SimpleAttachable */
    preinitThing()
    {
        /* carry out the inherited handling */
        inherited();
        
        /* if I'm attached to anything, add me to its attachment list */
        if(initiallyAttachedTo != nil)
        {
            /* 
             *   Ensure that the object we're attached to has an attachements property defined as a
             *   list so we don't get a runtime error if our initiallyAttachedTo object isn't a
             *   SimpleAttachable, although it should be.)
             */
            if(initiallyAttachedTo.attachments == nil)
                initiallyAttachedTo.attachments = [];
            
            /* Attach us to the other object. */
            attachTo(initiallyAttachedTo);          
        }
    }
;

/* 
 *   An AttachableComponent is an item that effectively becomes a component of
 *   the object it's attached to, or is treated as a component if it starts out
 *   attached.
 */
class AttachableComponent: SimpleAttachable
   
    /* A Component is firmly attached to its parent. */
    isFirmAttachment = true
    
    /* A Component's locType is PartOf while it's attached */
    locType()
    {
        if(attachedTo != nil)
            return PartOf;
        else
            return inherited;
    }
    
    /* Preinitialize a Component. */
    preinitThing()
    {
        /* Carry out the inherited handling. */
        inherited Thing;
        
        /* 
         *   If we start out initiallyAttached, note that we're attached to our
         *   location and add us to our location's list of attachments.
         */
        if(initiallyAttached)
        {
            /* A Component is attached to its immediate location. */
            attachedToList = [location];
            
            /* 
             *   It's possible that we're a component of something that isn't an
             *   Attachable and doesn't provide the attachments property; in
             *   which case, initialize its attachments property now.
             */
            if(location.attachments == nil)
                location.attachments = [];
            
            /* Add ourselves to our locations list of attachments. */
            location.attachments = location.attachments.appendUnique([self]);
        }
    }
    
    /* 
     *   We can't normally detach a Component with a straightforward DETACH
     *   command.
     */
    isDetachable = nil
    
    /* 
     *   A Component is generally fixed in place (i.e. not separately takeable)
     *   if it's attached to something.
     */
    isFixed = (attachedTo != nil)
    
    /* 
     *   Assume that most components start out attached to their containers
     */    
    initiallyAttached = true
    
       
    cannotTakeMsg = (delegated Component) 
    
;

/* 
 *   A NearbyAttachable is (optionally) placed in the same location as the
 *   object to which it is attached, and moves with the object it's attached to
 *   (or, alternatively, can prevent the other object being moved while it's
 *   attached to it).
 */
class NearbyAttachable: SimpleAttachable
    
    /* 
     *   Our location when attached; by default this is the location of the item
     *   we're attached to (if there is one)
     */
    attachedLocation = (attachedTo == nil ? location : attachedTo.location)
    
    
    /*  
     *   Our location when detached; by default this is simply the location of
     *   the item to which we're attached, if there is one.
     */         
    detachedLocation = (attachedTo == nil ? location : attachedTo.location)
    
    /* 
     *   Before any action takes place when we're in scope, make a note of our
     *   current location if we're attached to anything
     */
    beforeAction()
    {
        if(attachedTo != nil)
            oldLocation = location;
    }
    
    /*  
     *   After any action takes place when we're attached to something, move us
     *   into our attachedLocation if we're not already there.
     */
    afterAction()
    {
        if(attachedTo != nil && attachedLocation != oldLocation)
            moveInto(attachedLocation);
    }
    
    /* 
     *   Our location just before an action takes place when we're attached to
     *   something.
     */
    oldLocation = nil
;

/* 
 *   An Attachable is a NearbyAttachable that can be attached to more than one
 *   thing at a time, like a length of cable connecting two devices.
 */
class Attachable: NearbyAttachable
    
    /* 
     *   The maximum number of things I can be attached to at once. By default
     *   this is 2, since probably the most commonly use for an Attachable is to
     *   join or link two other things, but this can easily be overridden as
     *   required. If you want there to be no limit to the number of things I
     *   can be attached to at once, make maxAttachedTo nil.
     */
    maxAttachedTo = 2
   
    
    /* 
     *   Since an ATTACHABLE could potentially be in a many-to-many
     *   relationship, we may sometimes want to control the order of connection
     *   (i.e. which is considered to be the connected object and which the
     *   object it's connected to). If reverseConnect(obj) returns true then
     *   we'll turn CONNECT obj TO self into CONNECT self TO obj.
     */
    reverseConnect(obj)
    {
        return nil;
    }
    
    /*   
     *   We allow attachment to another obj either for the inherited reason
     *   (that obh is in my list of allowable attachements) or, if we want to
     *   reverse the connection with obj, that obj can be attached to us.
     */
    allowAttach(obj)
    {
        return inherited(obj) 
            || (reverseConnect(obj) && obj.allowAttach(self));
    }
    
    dobjFor(AttachTo)
    {
        preCond = [touchObj]
        
        verify()
        {
            inherited Thing;  
            
            if(isAttachedTo(gVerifyIobj))
            {                            
                illogicalNow(alreadyAttachedToIobjMsg);
            }
            
            else if(maxAttachedTo != nil && attachedToList.length >= maxAttachedTo)
                illogical(cannotAttachToMoreMsg);
        }       
        
    }        
   
                      
    
    alreadyAttachedToIobjMsg = BMsg(alreadt attached to iobj, '{The subj dobj} {is} already
        attachd to {1}. ', gVerifyIobj.theName) 
    
    /* 
     *   I'm attached to obj in the broad sense of having an attachement
     *   relationship with obj either if obj is attached to me or if obj is in
     *   the list of things to which I'm attached.
     */
    isAttachedTo(obj)
    {
        return isAttachedToMe(obj) || attachedToList.indexOf(obj);
    }
    
    /* 
     *   By default an Attachable can be plugged into more than one thing at a
     *   time
     */
    multiPluggable = true
;

reverseAttachableDoer: Doer 'attach SimpleAttachable to Attachable'
    execAction(c)
    {
        if(gIobj.reverseConnect(gDobj))
            doInstead(Attach, gIobj, gDobj);
        else
            inherited(c);            
    }    
;


/* 
 *   PlugAttachable is a mix-in class for use in conjunction with either
 *   SimpleAttachable or NearbyAttachable, enabling the commands PLUG X INTO Y,
 *   UNPLUG X FROM Y, PLUG X IN and UNPLUG X, treating ATTACH and DETACH
 *   commands as equivalent to these, and describing an object's attachments as
 *   being plugged into it.
 */
class PlugAttachable: object
    
    /* A PlugAttachable can be plugged into things. */
    isPlugable = true
    
    /* A PlugAttachable can have other things plugged into it. */
    canPlugIntoMe = true
    
    /* 
     *   Objects attached to this object should be described as plugged into it,
     *   so we need to use the appropriate lister.
     */
    attachmentLister = plugAttachableLister
    
    /*   
     *   Plugable objects could either be implemented so that an explicit socket
     *   needs to be specified (e.g. PLUG CABLE INTO SOCKET) or so that the
     *   socket can be left unspecified (e.g. PLUG TV IN). For the former case,
     *   make this property true; for the latter, make it nil.
     */
    needsExplicitSocket = true
    
    /*   Is this item plugged in to anything? */
    isPluggedIn = nil    
    
    /*   
     *   If this object represents the socket side of a plug-and-socket
     *   relationship, then the socketCapacity defines the total number of items
     *   that can be plugged into it once. By default we'll assume that a socket
     *   can only have one thing plugged into it at a time, but this can readily
     *   be overridded for items that can take more.
     */
    socketCapacity = 1
    
    /* Note whether we're plugged our unplugged. */
    makePlugged(stat)
    {
        isPluggedIn = stat;
    }
    
    dobjFor(PlugInto)    
    {
        verify()
        {
            /* Carry out the inherited handling. */
            inherited;
            
            /* We can't be plugged in if we're already plugged in. */
            if(isPluggedIn && !multiPluggable)
                illogicalNow(alreadyAttachedMsg);
            
        }
        
        action() 
        { 
            /* 
             *   Carry out the action to attach us to the object we're being
             *   attached to.
             */
            actionDobjAttachTo(); 
            
            /* Note that we're now plugged in. */
            makePlugged(true);
        }
        
        report() { reportDobjAttachTo(); }        
    }
    
    okayAttachMsg = BMsg(okay plug, '{I} plug{s/?ed} {1} into {the iobj}. ',
                         gActionListStr) 
    
    alreadyAttachedMsg = BMsg(already plugged in, '{The subj dobj} {is} already
        plugged into {1}. ', attachedTo.theName)
    
    alreadyPluggedInMsg = BMsg(already plugged in vague, '{The subj {dobj} {is}
        already plugged in. ')
    
    iobjFor(PlugInto)
    {
        preCond = [touchObj]     
        
        verify()
        {
            /* Carry out the inherited handling. */
            inherited;
            
            /* 
             *   If the direct object is not one that can be plugged into us,
             *   rule out the action with an appropriate message.
             */                 
            if(!allowAttach(gVerifyDobj))
                illogical(cannotBeAttachedMsg);
        }
        
        check()
        {
            /* 
             *   If plugging anything else into us would exceed our
             *   socketCapacity, rule out the action with an appropriate
             *   message,
             */
            if(attachments.length >= socketCapacity)
                say(cannotPlugInAnyMoreMsg);
        }
    }
    
    cannotPlugInAnyMoreMsg = BMsg(cannot plug in any more, '{I} {can\'t} plug
        any more into {the iobj}. ')
    
    
    iobjFor(AttachTo)
    {
        check()
        {
            /* Carry out the inherited handling. */
            inherited;
            
            /* 
             *   Make sure we don't exceed our socketCapacity if the player uses
             *   ATTACH TO rather than PLUG INTO; use the check method for
             *   PlugInto.
             */
            checkIobjPlugInto();
        }
    }
    
    cannotBeAttachedMsg = BMsg(cannot be plugged in, '{The subj dobj} {can\'t}
        be plugged into {the iobj}. ')
    
    
    dobjFor(UnplugFrom)
    {
        verify()
        {
            /*  Carry out the inherited checks */
            inherited;
            
            /*  If we're not plugged in we can't be unplugged from anything. */
            if(!isPluggedIn)
                illogicalNow(notAttachedMsg);  
            
            /*  
             *   If we're not attached to the direct object of the command, we
             *   can't be unplugged from it.
             */
            else if(attachedTo != gVerifyIobj)
                illogicalNow(notAttachedToThatMsg);
            
        }
        
        action() 
        { 
            /* Carry out the action handling for detaching from. */
            actionDobjDetachFrom(); 
            
            /* Note that we're no longer plugged in to anything. */
            makePlugged(nil);
        }
        report() { reportDobjDetachFrom(); }
    }
    
    okayDetachFromMsg = BMsg(okay unplug from, '{I} unplug{s/?ed} {1} from
        {the iobj}. ', gActionListStr)
    
    notAttachedMsg = BMsg(not plugged in, '{The subj dobj} {isn\'t} plugged into
        anything. ') 
    
    notAttachedToThatMsg = BMsg(not plugged into that, '{The subj dobj} {isn\'t}
        plugged into {the iobj}. ')
    
    
    dobjFor(Unplug)
    {
        verify()
        {
            /* Carry out the inherited checks. */
            inherited;
            
            /* If we're not plugged into anything, we can't be unplugged. */
            if(!isPluggedIn)
                illogicalNow(notAttachedMsg);   
        }
        
        action()
        {
            /* Note that we're no longer plugged in. */
            makePlugged(nil);
            
            /* 
             *   If plugging/unplugging this item requires an explicit socket to
             *   plug into/unplug from, then detach this item from whatever it's
             *   currently attached to.
             */
            if(needsExplicitSocket)
                actionDobjDetach();
        }
        
        report() { say(okayDetachMsg); }
    }
    
    okayDetachMsg = BMsg(okay unplug, '{I} unplug{s/?ed} {1}. ', gActionListStr)
    
    dobjFor(PlugIn)
    {
        verify()
        {
            /* Carry out the inherited handling. */
            inherited;
            
            /* 
             *   If we're already plugged in we can't be plugged in now, but the
             *   message to display depends on whether we require a specific
             *   socket to be plugged into.
             */
            if(isPluggedIn)
                illogicalNow(needsExplicitSocket ? alreadyAttachedMsg :
                             alreadyPluggedInMsg);
        }        
                
        
        action()
        {
            /* 
             *   If we need to specify a specific socket for this item to be
             *   plugged into, convert this action into a PlugInto action and
             *   ask for its indirect object (i.e. the socket to plug into).
             */
            if(needsExplicitSocket)
                askForIobj(PlugInto);
            
            /* Otherwise simply note that we're now plugged in. */
            else
                makePlugged(true);          
            
        }
        
        report() { DMsg(okay plug in, '{I} plug{s/?ed} in {1}. ', gActionListStr); }
        
    }
        
    /* If we're detached from something we're no longer plugged into it. */
    makeDetachedFrom(obj)
    {
        inherited(obj);
        
        makePlugged(nil);
    }
    
    /* If we're attached to something we're considered to be plugged into it. */
    attachTo(obj)
    {
        inherited(obj);
        
        makePlugged(true);
    }
;

