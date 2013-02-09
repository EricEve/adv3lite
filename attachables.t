#charset "us-ascii"
#include "advlite.h"

   
/* 
 *   The attachables file provides a framework for simple and common case
 *   attachables.
 *
 *   It treats attachment as an asymmetric relationship. ATTACH A TO B is not
 *   the same as ATTACH B TO A. It also treats it as a many-to-one relationship:
 *   the object that is attached can only be attached to one object at a time,
 *   but the object it's attached to can have multiple objects attached to it.
 *
 */

class SimpleAttachable: Thing
    allowAttach(obj)
    {
        return valToList(allowableAttachments.indexOf(obj)) != nil;
    }
    
    /* A list of the objects that can be attached to me */
    allowableAttachments = []
    
    /* A list of the objects that are attached to me */
    attachments = []
    
    isAttachable = true
    canAttachToMe = true
    canDetachFromMe = true
    
    
    /* 
     *   The location this object should be moved to when it's attached. A
     *   SimpleAttachment should normally be moved into the object it's attached
     *   to.
     */
    attachedLocation = (attachedTo)
    
    /*   
     *   The location this object should be moved to when it's detached. A
     *   SimpleAttachment should normally be moved into the location of the
     *   object it's just been detached from.
     */
    detachedLocation = (attachedTo.location)
    
    
    dobjFor(AttachTo)
    {
        preCond = [objHeld]
        
        verify()
        {
            inherited; 
            
            if(attachedTo != nil)
                illogicalNow(alreadyAttachedMsg);
        }
        
        action()
        {            
            attachedTo = gIobj;
            
            /* 
             *   If we're already in our attached location, there's no need to
             *   move, otherwise move us into our attached location.
             */
            if(location != attachedLocation)
                actionMoveInto(attachedLocation);
            
            gIobj.attachments += self;
        }
        
        report()
        {
            say(okayAttachMsg);
        }
    }
    
    okayAttachMsg = BMsg(okay attach, '{I} {attach} {1} to {the iobj}. ',
                         gActionListStr) 
    
    alreadyAttachedMsg = BMsg(already attached, '{The subj dobj} {is} already
        attached to {1}. ', attachedTo.theName)
    
    iobjFor(AttachTo)
    {
        preCond = [touchObj]
        
        verify()
        {
            inherited;
            
            if(!allowAttach(gDobj))
                illogical(cannotBeAttachedMsg);
        }
    }
    
    notAttachedMsg = BMsg(not attached, '{The subj dobj} {is}n\'t attached to
        anything. ')
    
    dobjFor(Detach)
    {
        verify()
        {                        
            if(attachedTo == nil)
                illogicalNow(notAttachedMsg);           
        
            else if(!isDetachable)
                implausible(cannotDetachMsg);
        }
        
        action()
        { 
            /* 
             *   If we're already in our detached location, there's no need to
             *   move, otherwise move us into our detached location
             */
            
            if(location != detachedLocation)
                moveInto(detachedLocation);
            attachedTo.attachments -= self;
            attachedTo = nil;          
        }
        
        report()   {  say(okayDetachMsg);   }
        
    }
    
    okayDetachMsg = BMsg(okay detach, '{I} detach {1}. ', gActionListStr)
    
    dobjFor(DetachFrom)
    {
        verify()
        {
            if(attachedTo == nil)
                illogicalNow(notAttachedMsg);  
            
            else if(attachedTo != gIobj)
                illogicalNow(notAttachedToThatMsg);
            
            inherited;
        }
        
        
        
        action()
        {
            if(location != detachedLocation)
               moveInto(detachedLocation);
            
            attachedTo.attachments -= self;
            attachedTo = nil;
            
        }
        
        report()
        {
            say(okayDetachFromMsg);            
        }
    }
    
    okayDetachFromMsg = BMsg(okay detach from, '{I} {detach} {1} from {the iobj}. ', 
                 gActionListStr)
    
    cannotDetachMsg = BMsg(cannot detach this, '{The subj dobj) {cannot} be
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
            
            inherited;
                
        }
    }
    
    cannotDetachFromMsg = BMsg(cannot detach from this , 'The {subj dobj}
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
        local other = attachments.valWhich({o:
                                           !o.allowOtherToMoveWhileAttached});
        if(other != nil)
        {            
            gMessageParams(other);            
            DMsg(cannot move while attached, '{The subj cobj} {cannot} be moved
                while {he cobj} {is} attached to {the other}. ');
            exit;
        }
        
           
        inherited(loc);
    }
    
    
    cannotBeAttachedMsg = BMsg(cannot be attached, '{The subj dobj} {cannot} be
        attached to {the iobj}. ')
    
    /* Am I currently attached to anything? */
    attachedTo = nil
    
    /* 
     *   By default I'm not listed as a separate object if I'm attached to
     *   something else.
     */
    isListed = (attachedTo == nil && inherited)
    
    isAttachedToMe(obj)
    {
        return attachments.indexOf(obj) != nil;
    }
    
    
    
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
        inherited;
        if(attachments.length > 0)
            attachmentLister.show(attachments, self);
    }
    
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
    
    
;

/* 
 *   A component is an item that effectively becomes a component of
 *   the object it's attached to, or is treated as a component if it starts out
 *   attached.
 */

class Component: SimpleAttachable
    
    isFirmAttachment = true
    
    locType()
    {
        if(attachedTo != nil)
            return PartOf;
        else
            return inherited;
    }
    
    preinitThing()
    {
        inherited;
        if(initiallyAttached)
        {
            attachedTo = location;
            location.attachments += self;
        }
    }
    
    allowDetach = nil
    isFixed = (attachedTo != nil)
    
    /* 
     *   Assume that most components start out attached to their containers
     */
    
    initiallyAttached = true
    
    attachedTo = nil
    
    cannotTakeMsg = BMsg(cannot take component, '{I} {can\'t} have {that dobj},
        {he dobj}{\'s} part of {1}. ', location.theName)    
    
;

/* 
 *   A NearbyAttachable is (optionallyplaced in the same location as the object
 *   to which it is attached, and moves with the object it's attached to (or,
 *   alternatively, can prevent the other object being moved while it's attached
 *   to it).
 */

class NearbyAttachable: SimpleAttachable
    
    attachedLocation = (attachedTo == nil ? nil : attachedTo.location)
    detachedLocation = (attachedTo == nil ? location : attachedTo.location)
    
    
    beforeAction()
    {
        if(attachedTo != nil)
            oldLocation = location;
    }
    
    afterAction()
    {
        if(attachedTo != nil && attachedLocation != oldLocation)
            moveInto(attachedLocation);
    }
    
    oldLocation = nil
;

/* 
 *   PlugAttachable is a mix-in class for use in conjunction with either
 *   SimpleAttachable or NearbyAttachable, enabling the commands PLUG X INTO Y,
 *   UNPLUG X FROM Y, PLUG X IN and UNPLUG X, treating ATTACH and DETACH
 *   commands as equivalent to these, and describing an object's attachments as
 *   being plugged into it.
 */

class PlugAttachable: object
    isPlugable = true
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
    
    
    makePlugged(stat)
    {
        isPluggedIn = stat;
    }
    
    dobjFor(PlugInto)    
    {
        verify()
        {
            inherited;
            
            if(isPluggedIn)
                illogicalNow(alreadyAttachedMsg);
            
        }
        
        action() 
        { 
            actionDobjAttachTo(); 
            makePlugged(true);
        }
        
        report() { reportDobjAttachTo(); }        
    }
    
    okayAttachMsg = BMsg(okay plug, '{I} {plug} {1} into {the iobj}. ',
                         gActionListStr) 
    
    alreadyAttachedMsg = BMsg(already plugged in, '{The subj dobj} {is} already
        plugged into {1}. ', attachedTo.theName)
    
    alreadyPluggedInMsg = BMsg(already plugged in vagaue, '{The subj {dobj} {is}
        already plugged in. ')
    
    iobjFor(PlugInto)
    {
        preCond = [touchObj]     
        
        verify()
        {
            inherited;
            
            if(!allowAttach(gDobj))
                illogical(cannotBeAttachedMsg);
        }
        
        check()
        {
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
            inherited;
            checkIobjPlugInto();
        }
    }
    
    cannotBeAttachedMsg = BMsg(cannot be plugged in, '{The subj dobj} {can\'t}
        be plugged into {the iobj}. ')
    
    
    dobjFor(UnplugFrom)
    {
        verify()
        {
            inherited;
            
            if(!isPluggedIn)
                illogicalNow(notAttachedMsg);  
            
            else if(attachedTo != gIobj)
                illogicalNow(notAttachedToThatMsg);
            
        }
        
        action() 
        { 
            actionDobjDetachFrom(); 
            makePlugged(nil);
        }
        report() { reportDobjDetachFrom(); }
    }
    
    okayDetachFromMsg = BMsg(okay unplug from, '{I} {unplug} {1} from {the iobj}. ', 
                 gActionListStr)
    
    notAttachedMsg = BMsg(not plugged in, '{The subj dobj} {isn\'t} plugged into
        anything. ') 
    
    notAttachedToThatMsg = BMsg(not plugged into that, '{The subj dobj} {isn\'t}
        plugged into {the iobj}. ')
    
    
    dobjFor(Unplug)
    {
        verify()
        {
            inherited;
            
            if(!isPluggedIn)
                illogicalNow(notAttachedMsg);   
        }
        
        action()
        {
            makePlugged(nil);
            if(needsExplicitSocket)
                actionDobjDetach();
        }
        
        report() { say(okayDetachMsg); }
    }
    
    okayDetachMsg = BMsg(okay unplug, '{I} {unplug} {1}. ', gActionListStr)
    
    dobjFor(PlugIn)
    {
        verify()
        {
            inherited;
            
            if(isPluggedIn)
                illogicalNow(needsExplicitSocket ? alreadyAttachedMsg :
                             alreadyPluggedInMsg);
        }
        
                
        
        action()
        {
            
            if(needsExplicitSocket)
                askForIobj(PlugInto);
            else
                makePlugged(true);          
            
        }
        
        report() { DMsg(okay plug in, '{I} {plug} in {1}. ', gActionListStr); }
        
    }


;

