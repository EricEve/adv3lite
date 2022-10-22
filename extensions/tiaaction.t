#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/* 
 *   TIAACTION EXTENSION
 *
 *   Adds the TIAAction class to adv3Lite
 *
 *   A TIA Action is an action involving three objects: Direct Object, Indirect
 *   Object and Accessory Object
 */


tiaactionID: ModuleID
    name = 'TIA Action'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '1'    
;

/*
 *   DEFINED IN TIAACTION EXTENSION. A TIAAction is one that has three objects
 *   (direct, indirect and indirect), such as PUT COIN IN SLOT WITH TWEEZERS.   
 */
class TIAAction: TIAction
    /* The current accessory object of this action. */
    curAobj = nil
    
    
    /* The various methods to call on the accessory object of this action. */
    verAobjProp = nil
    checkAobjProp = nil
    actionAobjProp = nil
    preCondAobjProp = nil
    reportAobjProp = nil
    
    /* 
     *   A list of the accessory objects that this actually actually ends up
     *   acting on at the action stage. [TIAACTION EXTENSION]
     */
    aoActionList = []
    
    /* Reset the action variables to their initial state, including the accessory object. */
    reset()
    {
        inherited;
        curAobj = nil;
        aoActionList = [];
    }
    
    /* execute this action, noting the accessory object in addition to the other two. */
    execAction(cmd)
    {
        /* 
         *   Note the current direct object of this command from the Command
         *   object.
         */
        curDobj = cmd.dobj;
        
        /* 
         *   Note the current indirect object of this command from the Command
         *   object.
         */
        curIobj = cmd.iobj;
        
        /* 
         *   Note the current accessory object of this command from the Command
         *   object.
         */
        curAobj = cmd.acc;
        
        /* Note all three objects as possible pronoun antecedents. [TIAACTION EXTENSION] */
        notePronounAntecedent(curDobj, curIobj, curAobj);
        
        /* execute the resolved action. */
        execResolvedAction();
    }
    
     /* 
      * [TIAACTION EXTENSION]
	  * Carry out the check phase for this command on all three objects involved in the command. 
	  */   
    checkAction(cmd)
    {
        
        /* 
         *   If we don't pass the check stage on both the iobj and the dobj's
         *   preconditions, then return nil to tell our caller we've failed this
         *   stage.
         */
        if(!(checkPreCond(curIobj, preCondIobjProp) 
             && checkPreCond(curDobj, preCondDobjProp)
             &&  checkPreCond(curAobj, preCondAobjProp)))           
            return nil;
        
        /* 
         *   Return the result of running the check phase on both the indirect
         *   and the direct objects.
         */        
        return check(curIobj, checkIobjProp) && check(curDobj, checkDobjProp)
            && check(curAobj, checkAobjProp);
        
        
    }
    
    
    /* Set all three resolved objects for this action. [TIAACTION EXTENSION] */
    setResolvedObjects(dobj, iobj, aobj)
    {
        curDobj = dobj;
        curIobj = iobj;
        curAobj = aobj;
    }
    
    /* 
     *   Test whether the direct, the indirect and the accessory objects for
     *   this action are in scope. [TIAACTION EXTENSION]
     */
    resolvedObjectsInScope()
    {
        buildScopeList();
        return scopeList.indexOf(curDobj) != nil 
            && scopeList.indexOf(curIobj) != nil
            && scopeList.indexOf(curAobj) != nil;
    }
    
    /* 
     *   Carry out the report phase for this action. If there's anything in the
     *   aoActionList and we're not an implicit action, call the report method
     *   on the indirect, then the indirect object and finally on the accessory
     *   object). Note that this method is called by
     *   the current Command object once its finished iterating over all the
     *   objects involved in the command. [TIAACTION EXTENSION]
     */
    reportAction()
    {       
        
        /* 
         *   Carry out the inherited handling, which executes the report stage
         *   on the direct object.
         */
        inherited;
        /* 
         *   If we're not an implicit action and there's something to report on,
         *   carry out the report stage on our indirect object.
         */
        if(!isImplicit && aoActionList.length > 0)
            curAobj.(reportAobjProp);
    }
    
    /* Get the message parameters relating to this action for all three objects. */
    getMessageParam(objName)
    {
        switch(objName)
        {
        case 'aobj':
        case 'acc':
            /* return the current indirect object */
            return curAobj;
            
        default:
            /* inherit default handling */
            return inherited(objName);
        }
    }
    
    /* 
     *   Execute this action as a resolved action, that is once its direct, 
     *   indirect and accessory objects are known. [TIAACTION EXTENSION]
     */
    execResolvedAction()
    {        
        try
        {
            /* 
             *   If the indirect object was resolved first (before the direct
             *   object) then we run the verify stage on the indirect object
             *   first. If it fails, return nil to tell the caller it failed.
             */             
            if(resolveIobjFirst && !verifyObjRole(curIobj, IndirectObject))
                return nil;
            
            /* 
             *   Run the verify routine on the direct object next. If it
             *   disallows the action, stop here and return nil.
             */
            if(!verifyObjRole(curDobj, DirectObject))
                return nil;
            
            /* 
             *   If the indirect object was resolved after the direct object,
             *   run the verify routines on the indirect object now, and return
             *   nil if they disallow the action.
             */
            if(!resolveIobjFirst && !verifyObjRole(curIobj, IndirectObject))
                return nil;
            
            /*
			 * Run the verify routines on the accessory object and return nil if
			 * they disallow the action.
			 */
            if(!verifyObjRole(curAobj, AccessoryObject))
                return nil;
            
            
            /* 
             *   If gameMain defines the option to run before notifications
             *   before the check stage, run the before notifications now.
             */
            if(gameMain.beforeRunsBeforeCheck)
                beforeAction();
            
            /* 
             *   Try the check stage on all three objects. If either disallows
             *   the action return nil to stop the action here.
             */
            if(!checkAction(nil))
                return nil;
            
            /* 
             *   If gameMain defines the option to run before notifications
             *   after the check stage, run the before notifications now.
             */            
            if(!gameMain.beforeRunsBeforeCheck)
                beforeAction();
            
            /* Carry out the action stage on one set of objects */
            doActionOnce();
            
            /* Return true to tell our caller the action was a success */
            return true;    
        }
        
        catch (ExitActionSignal ex)            
        {
            
            actionFailed = true;
            
            return nil;
        }   
        
    }
        
    /* 
     *   Execute the action phase of the action on both objects. Note that
     *   although some TIAActions can operate on multiple direct objects, none
     *   defined in the library acts on multiple indirect objects, so there's
     *   only minimal support for the latter possibility. [TIAACTION EXTENSION]
     */
    doActionOnce()
    {
        
        local msgForDobj, msgForIobj, msgForAobj;
        
        /* 
         *   If we're iterating over several objects and we're the kind of
         *   action which wants to announce objects in this context, do so.
         */        
        if(announceMultiAction && gCommand.dobjs.length > 1)
            announceObject(curDobj);
        
        
        
        /* 
         *   Note that the current object we're dealing with is the direct
         *   object.
         */
        curObj = curDobj;     
        
        /*  
         *   If we're an implicit action add us to the list of implicit actions
         *   to be reported.
         */
        if(isImplicit)
            buildImplicitActionAnnouncement(true, nil);
        
        try
        {
            /* 
             *   Add the ImplicitActionFilter to the current output stream so
             *   that any pending implicit action reports are prepended to any
             *   action reports output at this stage.
             */
            gOutStream.addOutputFilter(ImplicitActionFilter);
            
            /* 
             *   Run the action routine on the current direct object and capture
             *   the output for later use. If the output is null direct object
             *   can be added to the list of objects to be reported on at the
             *   report stage, provided the iobj action routine doesn't report
             *   anything either.
             *
             *   NOTE TO SELF: Don't try making this work with captureOutput();
             *   it creates far more hassle than it's worth!!!!
             */
            msgForDobj =
                gOutStream.watchForOutput({:curDobj.(actionDobjProp)});
            
            
            
            /* Note that we've acted on this direct object. */
            actionList += curDobj;
            
            /* Note that the current object is now the indirect object. */
            curObj = curIobj;
            
            /* 
             *   Execute the action method on the indirect object. If it doesn't
             *   output anything, add the current indirect object to
             *   ioActionList in case the report phase wants to do anything with
             *   it, and add the dobj to the reportList if it's not already
             *   there so that a report method on the dobj can report on actions
             *   handled on the iobj.
             */        
            msgForIobj =
                gOutStream.watchForOutput({:curIobj.(actionIobjProp)});
            
            /* Note that the current object is now the indirect object. */
            curObj = curAobj;
            
            /* 
             *   Execute the action method on the accessory object. If it
             *   doesn't output anything, add the current accessory object to
             *   aoActionList in case the report phase wants to do anything with
             *   it, and add the dobj to the reportList if it's not already
             *   there so that a report method on the dobj can report on actions
             *   handled on the iobj.
             */        
            msgForAobj =
                gOutStream.watchForOutput({:curAobj.(actionAobjProp)});
        }
        
        finally
        {
            /* Remove any implicit action announcement from the output stream */
            
            gOutStream.removeOutputFilter(ImplicitActionFilter);
        }
        
        /* 
         *   If neither the action stage for the direct object nor the action
         *   stage for the direct object nor the action stage for the accessory
         *   obect produced any output then add the indirect and accessory
         *   objects to the list of indirect and accessory objects that could be
         *   reported on, and add the current direct object to the list of
         *   direct objects to be reported on at the report stage.
		 *   [TIAACTION EXTENSION]
         */
        if(!(msgForDobj) && !(msgForIobj) && !(msgForAobj))
        {
            ioActionList += curIobj;
            aoActionList += curAobj;    
            reportList = reportList.appendUnique([curDobj]);            
        }    
        else if(!isImplicit)
        {
            /* 
             *   Otherwise, if we're not an implicit action, clear out the
             *   implicit action reports which we should now have displayed.
             */
            gCommand.implicitActionReports = [];              
        }
        
        
        /* 
         *   Return true to tell our caller we completed the action
         *   successfully.
         */      
        return true;
    }
    
    
;

/*
 *  MODIFICATION TO THING FOR TIAACTION EXTENSION
 */ 
modify Thing
     /* Defined on TIAAction extension. */
    aobjFor(Default)
    {
        verify()
        {
            illogical(notImportantMsg);
        }
    }
;