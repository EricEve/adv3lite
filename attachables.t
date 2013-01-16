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
    
    isAttachable = true
    canAttachToMe = true
    canDetachFromMe = true
    
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
            moveInto(gIobj);
            attachedTo = gIobj;
        }
        
        report()
        {
            DMsg(okay attach, '{I} {attach} {1} to {the iobj}. ', 
                 gActionListStr);
        }
    }
    
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
        }
        
        check()
        {
            if(!isDetachable)
                say(cannotDetachMsg);
        }
        
        action()
        {            
            actionMoveInto(attachedTo.location);
            attachedTo = nil;
        }
        
        report()
        {
            DMsg(okay detach, '{I} detach {1}. ', gActionListStr);
        }
        
    }
    
    dobjFor(DetachFrom)
    {
        verify()
        {
            if(attachedTo == nil)
                illogicalNow(notAttachedMsg);  
            
            if(attachedTo != gIobj)
                illogicalNow(notAttachedToThatMsg);
            
            inherited;
        }
        
        
        
        action()
        {
            attachedTo = nil;
            actionMoveInto(gIobj.location);
        }
        
        report()
        {
            DMsg(okay detach from, '{I} detach {1} from {the iobj}. ', 
                 gActionListStr);
        }
    }
    
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
        if(contents.countWhich({x: x.locType == Attached}) > 0)
            simpleAttachmentLister.show(contents, 0);
    }
    
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
    
    /* 
     *   For a SimpleAttachment we build the list of attachments by looking for
     *   things in our contents and our immediate location that are attached to
     *   us.
     */
    attachments()
    {
        local vec = new Vector(contents.subset({x: x.attachedTo == self}));
        
        vec += location.contents.subset({x: x.attachedTo == self});
        
//        if(attachedTo != nil)
//            vec.append(attachedTo);
        
        return vec.toList;                   
    }
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
            attachedTo = location;
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
 *   A NearbyAttachable is placed in the same location as the object to which it
 *   is attached, and moves with the object it's attached to (or, alternatively,
 *   can prevent the other object being moved while it's attached to it).
 */

class NearbyAttachable: SimpleAttachable
    dobjFor(AttachTo)
    {
        action()
        {
            actionMoveInto(gIobj.location);
            attachedTo = gIobj;
            oldLocation = location;
        }
    }
    
    beforeAction()
    {
        if(attachedTo != nil)
            oldLocation = attachedTo.location;
    }
    
    afterAction()
    {
        if(attachedTo != nil && attachedTo.location != oldLocation)
            moveInto(attachedTo.location);
    }
    
    oldLocation = nil
;
