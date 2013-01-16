#charset "us-ascii"
#include "advlite.h"

/*
 *   ****************************************************************************
 *    action.t 
 *    This module forms part of the adv3Lite library 
 *    (c) 2012 Eric Eve
 */


/* 
 *   The library doesn't yet provide any support for actions that take three
 *   objects (TIAActions, as they might hypothetically be called), but since the
 *   Mercury parser does we provide a number of hooks that other code could use.
 *   To this end we need to define the properties a TIAAction might use so the
 *   compiler recognizes them.
 */
property curAobj, verAobjProp, preCondAobjProp, remapAobjProp;
property verifyAobjDefault, preCondAobjDefault;

class Action: object
    
    /* 
     *   Flag; should this action be considered a failure? This should be reset
     *   to true at the start of the action processing cycle but can be tested
     *   later to prevent, e.g., inappropriate reporting.
     */
    actionFailed = nil
    
    
    /* 
     *   The execGroup() method is called by the current Command object before
     *   it calls the action on individual objects, to allow processing of the
     *   group of objects as a whole. By default we do nothing here in the
     *   library.
     */
    execGroup(cmd) { }
           
    /* 
     *   The checkAction() method calls the check routines on the objects
     *   involved in the command (where there are objects). Subclasses such as
     *   TAction and TIAction need to override this to carry out the appropriate
     *   handling.
     */
    checkAction() { }
    
    
    /* 
     *   The main routine for handling an action. This is the method called by
     *   the command object; the cmd parameter gives the calling Command object.
     */
    exec(cmd)
    {                
        
        /* Resest actionFailed to nil */
        actionFailed = nil;
        
        /* Resent the scope list */
        scopeList = [];
        
        /* Note the current actor */
        libGlobal.curActor = cmd.actor;
        
        /* Note the location of the current actor */
        oldRoom = gActor.getOutermostRoom;
        
        /* 
         *   Note whether the current actor's location starts out illuminated;
         *   we need to know this so we can display a notification if the
         *   illumination changes.
         */
        
        wasIlluminated = oldRoom.isIlluminated();
        
        
        /* execute the action-processing cycle */
        execCycle(cmd);     
            
    }
    
    /* 
     *   The action-processing cycle carries out the before action
     *   notifications, then executes the action. This needs to be overridden on
     *   various subclasses since the beforeAction notifications can occur at
     *   different points in different kinds of action.
     */
    execCycle(cmd)
    {
        try
        {            
            IfDebug(actions, 
                    "[Executing <<actionTab.symbolToVal(baseActionClass)>> 
                    << if cmd.dobj != nil>> : <i><<dqinfo>></i>
                    <<cmd.dobj.name>><<end>>
                    << if cmd.iobj != nil>> : <i><<iqinfo>></i>
                    <<cmd.iobj.name>><<end>> ]" );
            
            /* Carry out the before action notifications. */
            beforeAction();
            
            /* Execute the main action handling. */
            execAction(cmd);
            
            /* 
             *   If the action is repeatable, make a note of it in case the
             *   player issues an AGAIN command.
             */
            if(isRepeatable)
                libGlobal.lastAction = self.createClone();
            
            
        }
        catch(ExitActionSignal ex)
        {
           
        }
        /* If an exit signal is issued we skip to here. */
        catch(ExitSignal ex)
        {
            /* 
             *   If the exit macro is used in the course of the command,
             *   consider the command a failure.
             */
            actionFailed = true;
        }
        
    }
    
    /* The main action handler. Subclasses must override. */
    execAction(cmd)
    {
    }
    
    /* The room the actor was in when the action started */
    oldRoom = nil
    
    /* Flag to indicate whether the actor's location started out illuminated */
    wasIlluminated = nil
    
    beforeAction()
    {
        /* 
         *   Call the before action handling on the current actor (in its
         *   capacity as actor/
         */
        gActor.actorAction();
        
        /* Call roomBeforeAction() on the current actor's location. */        
        gActor.getOutermostRoom.roomBeforeAction();
        
        /* 
         *   If we don't already have a scope list for the current action, build
         *   it now.
         */
        if(nilToList(scopeList).length == 0)
            buildScopeList;
            
        
        /* Call the beforeAction method of every action in scope. */
        foreach(local cur in scopeList)
        {
            cur.beforeAction();
        }
    }
    
    /* 
     *   Carry out the post-action processing. This first checks to see if
     *   there's been a change in illumination. If there has we either show a
     *   room description (if the actor's location is now lit) or announce the
     *   onset of darkness. We then call the after action notifications first on
     *   the actor's current room and then on every object in scope.
     *
     *   Note that afterAction() is called from the current Command object.
     */
    afterAction()
    {
        /* 
         *   If the current action is considered a failure, we don't carry out
         *   any after action handling, since in this case there's no action to
         *   react to.
         */
        if(actionFailed)
            return;
        
        
        /* 
         *   If the actor is still in the same room s/he started out in, check
         *   whether the current illumination level has changed, and, if so,
         *   either show a room description or announce the onset of darkness,
         *   as appropriate.
         */
        if(oldRoom == gActor.getOutermostRoom)
        {
            if(oldRoom.isIlluminated)
            {
                if(!wasIlluminated)
                {   
                    "<.p>";
                    oldRoom.lookAroundWithin();
                }
            }
            else if(wasIlluminated)
            {
                DMsg(onset of darkness, '\n{I} {am} plunged into darkness. ');
            }
        }
        "<.p>";
        
        /* Call the afterAction notification on the current room. */
        gActor.getOutermostRoom.roomAfterAction();
        
        /* 
         *   Call the afterAction notification on every object in scope. Note
         *   that we have to recalculate the scope list here in case the action
         *   has changed it.
         */
        foreach(local cur in Q.scopeList(gActor))
        {
            cur.afterAction();
        }
        
    }
    
    /* 
     *   The turnSequence() method is called from the current Command object. It
     *   first executes any current daemons (apart from any PromptDaemons) and
     *   then advances the turn counter. We define this on the Action class
     *   principally to make it simple for certain kinds of Action such as
     *   SystemActions to do nothing here (since they don't count as actions
     *   within the game world).
     */
    
    turnSequence()
    {
        "<.p>";
        /* Execute the player character's current location's roomDaemon. */
        gPlayerChar.getOutermostRoom.roomDaemon();                 
        
        /* 
         *   If the events.t module is included, execute all current Daemons and
         *   Fuses/
         */
        if(defined(eventManager) && eventManager.executeTurn())          
            ;
               
        /* Advance the turn counter */
        libGlobal.totalTurns += turnsTaken;           
    }
   
    /* 
     *   The number of turns this action is counted as taking. Normally, this
     *   will be 1.
     */
    turnsTaken = 1
    
    /* Flag: is this an implicit action? By default it isn't. */
    isImplicit = nil
    
    /* Can this action be Undone? By default most actions can. */
    includeInUndo = true
    
    /* 
     *   Is this action repeatable (with an AGAIN command)? Most actions are so
     *   the default is true but subclasses can override to exclude actions
     *   (such as certain system actions) that it would make no sense to repeat.
     */
    isRepeatable = true
    
    
    /* 
     *   Report on the action. This is only relevant where the action has more
     *   or one objects, so TAction must override. This is called from the
     *   current Command object once all the objects have been acted on (in a
     *   case where multiple direct objects have been specified, as in TAKE ALL
     *   or TAKE RED BALL AND GREEN PEN). This allows the report routine to
     *   summarize the action for all the objects acted upon instead of
     *   displaying an individual report for each one.
     */
    reportAction()  { }
    
   
    /* 
     *   Do we have a parent action, and if so what is it? The parent action
     *   would be the action that's using us as an implicit action or nested
     *   action.
     */
    parentAction = nil
    
    
    /* 
     *   Remap the current action to a completely new one according to the
     *   values passed in the list parameter remapList. The first item in the
     *   list should be the new action class, the second item the new direct
     *   object (if any) and the third the indirect object (if any).
     *
     *   NOTE: this may be removed in future versions of the library, since it
     *   might be cleaner simply to call redirect on a Doer to achieve the same
     *   effect. This feature should therefore be regareded as deprecated.
     */
    
    remapAction(remapList)
    {
        
        local action;
        
        action = remapList[1];
        if(action == nil)
            return nil;
        
        
        action.parentAction = self;
        
        
        /* 
         *   The remapping of a two-object action might take place before the
         *   other object involved in the command has been resolved. If the
         *   remapping references either the dobj or the iobj of the command
         *   when they're still nil then we need to resolve the appropriate
         *   object before proceeding. To maintain compatibility with the adv3
         *   library we also allow the enums DirectObject, IndirectObject and
         *   OtherObject to be used to specify the other object to be used in a
         *   remapped command. These are then replaced with the appropriate
         *   object.
         */
        
        if(remapList.length > 1)
        {
            action.reportList = [];
            action.curDobj = remapList[2];
            if(action.curDobj == DirectObject)
                action.curDobj = curDobj;
            
            if(action.curDobj is in (IndirectObject, OtherObject))
                action.curDobj = curIobj;
                                         
               
        }
        
        if(remapList.length > 2)
        {
            action.curIobj = remapList[3];
            
             if(action.curIobj == IndirectObject)
                action.curIobj = curIobj;
            
            if(action.curIobj is in (DirectObject, OtherObject))
                action.curIobj = curDobj;
                    
            
        }
        
        action.isImplicit = isImplicit;
        action.afterReports = afterReports;
        action.buildScopeList();
        
        if (!action.resolvedObjectsInScope())
           return nil;
        
        gAction = action;  
        gCommand.action = action;
        gCommand.dobj = curDobj;
        gCommand.iobj = curIobj;
        
        
        gAction.execResolvedAction();       
        exit;
    }
    
    /* 
     *   Carry out the verification stage for this object in this role, and
     *   carry out any remapping needed. This needs to be defined on Action
     *   since there might be verification of the ActorRole.
     */


    verify(obj, role)
    {
        local remapResult;
        local verifyProp;
        local preCondProp;
        local remapProp;
        
        
        /* Clear out any previous verify results */
        verifyTab = nil;
        
        /* 
         *   Note which properties to use according to which role we're
         *   verifying for. (No actions in the adv3Lite library currently use an
         *   Accessory object but the possibility is included here to ease
         *   subsequent extension).
         */
        
        switch(role)
        {
        case DirectObject:            
            verifyProp = verDobjProp;
            preCondProp = preCondDobjProp;
            remapProp = remapDobjProp;
            break;        
            
        case IndirectObject:            
            verifyProp = verIobjProp;
            preCondProp = preCondIobjProp;
            remapProp = remapIobjProp;
            break;
            
        case AccessoryObject:
            verifyProp = verAobjProp;
            preCondProp = preCondAobjProp;
            remapProp = remapAobjProp;
            break;
        case ActorRole:
            verifyProp = &verifyActor;
            remapProp = &remapActor;
            preCondProp = &preCondActor;
                
        } 
            
        /* first check if we need to remap this action. */
        
        remapResult = obj.(remapProp);
        
        /* 
         *   the object's remap routine can return an object or a list (if it
         *   returns anything else we ignore it). If it returns an object use
         *   that object in place of the one we were about to verify for the
         *   remainder of this action. If it returns a list, the list should
         *   contain the details of an action that is to replace the current
         *   action, so run the remapped action instead.
         */
        
        switch(dataType(remapResult))
        {
        case TypeObject:
            obj = remapResult;
            break;
        case TypeList:
            /* 
             *   If the remap result is a list, then we'll need to remap the
             *   action to another one, but we'll leave that until all the
             *   objects have been resolved. For the purpose of verifying this
             *   object we'll just return a standard logical verify result to
             *   allow the remapping to proceed at a later stage.
             */
            
            return new VerifyResult(100, '', true, obj);                     
            
             
        default:
            break;
        }
        
        /* 
         *   Note which object we're currently verifying in the Action's
         *   verifyObj property so other routines can find it (particularly a
         *   verify routine called from a preCondition).
         */
        verifyObj = obj;
        curObj = obj;
        
        switch(role)
        {
            
        case DirectObject:
            curDobj = obj;
            break;
            
        case IndirectObject:            
            curIobj = obj;
            break;
            
        case AccessoryObject:
            curAobj = obj;
            break;
        }
        /* 
         *   if the object is a decoration then we use the catchall Default
         *   prop, unless we're an action that bypasses it.
         */
        
        if(obj.isDecoration 
           && obj.decorationActions.indexWhich({x: self.ofKind(x)}) == nil)
        {
            switch(role)
            {
                
            case DirectObject:
                verifyProp =  &verifyDobjDefault;            
                preCondProp = &preCondDobjDefault;
                break;
                
            case IndirectObject:            
                verifyProp = &verifyIobjDefault;            
                preCondProp = &preCondIobjDefault;
                break;
                
            case AccessoryObject:
                verifyProp = &verifyAobjDefault;            
                preCondProp = &preCondAobjDefault;
                break;
            }          
        }

        /* Execute the appropriate verify routine on the object */
        obj.(verifyProp);
        
        /* If we don't already have a verify table, create it */
        if(verifyTab == nil)
            verifyTab = new LookupTable;
        
        /* 
         *   If executing this verify routine didn't create an entry for this
         *   object in the verify table, create one now with a default 'logical'
         *   verify result.
         */        
        if(verifyTab.isKeyPresent(obj) == nil)
            verifyTab[obj] = new VerifyResult(100, '', true, obj);
        
        
        /* 
         *   Next run through all the items in our precondition list and execute
         *   their verify methods.
         */
        foreach(local cur in valToList(obj.(preCondProp)))
            cur.verifyPreCondition(obj);        
        
        
        /* 
         *   Return the entry for this object in our verify table (which may
         *   have been altered by one of the preconditions above).
         **/
        return verifyTab[obj];
    }
    
    /* 
     *   Run the verify routine on the current object in the current role to see
     *   whether it will allow the action. If it won't, display any pending
     *   implicit action announcements, then display the message explaining why
     *   the action is disallowed, and finally return nil to tell our caller to
     *   halt the action. If the verify stage does allow the action to go ahead,
     *   return true to tell our caller that this routine has no objection.
     */
    
    verifyObjRole(obj, role)
    {
        local verResult;
        local verMsg;
        
        /* Make sure we start with a clean new verify table */
        verifyTab = new LookupTable;
        
        verResult = verify(obj, role);
        
        /* 
         *   If the verify result is one that disallows the action then display
         *   the failure message, along with any failed implicit action message.
         */
        if(!verResult.allowAction)
        {
             /* Note our failure message */
            verMsg = verResult.errMsg;
            
            /* 
             *   If this is the direct object of the command and there's more
             *   than one, and if the option to announce objects in verify
             *   messages is true, then announce the name of this object to make
             *   it clear which one is being referred to.
             */
            if(announceMultiVerify && role == DirectObject &&
               gCommand.dobjs.length > 1)
                announceObject(obj);
            
            /* 
             *   If we're an implicit action add a failed implicit action report
             *   ('trying to...').
             */
            if(isImplicit)
                "<<buildImplicitActionAnnouncement(nil)>>";
            
            /* 
             *   Display the failure message, unless it's identical to the
             *   previous one.
             */
            
            if(verMsg != lastVerifyMsg || announceMultiVerify)
            {
                say(verMsg);
                "\n";
                lastVerifyMsg = verMsg;
            }
            
            /* Note that this action has failed. */
            actionFailed = true;
            
            /* 
             *   Stop the processing of the action here by telling our caller
             *   we've failed.
             */
            return nil;
        }
        
        /* 
         *   Otherwise return true to tell our caller we're not objecting to the
         *   action.
         */
        return true;
    }
    
    /* The object currently being verified */
    
    verifyObj = nil
    
    /*
     *   Get a message parameter object for the action.  Each action
     *   subclass defines this to return its objects according to its own
     *   classifications.  The default action has no objects, but
     *   recognizes 'actor' as the current command's actor.  
     */
    getMessageParam(objName)
    {
        switch(objName)
        {
        case 'pc':
            /* return the player character */
            return gPlayerChar;
            
        case 'actor':
            /* return the current actor */
            return gActor;
            
        case 'cobj':
            /* return the current object, if there is one */
            return curObj;

        default:
            /* 
             *   if we have an extra message parameters table, look up the
             *   parameter name in the table 
             */
            if (extraMessageParams != nil)
                return extraMessageParams[objName];

            /* we don't recognize other names */
            return nil;
        }
    }

    /*
     *   Define an extra message-specific parameter.  Message processors
     *   can use this to add their own special parameters, so that they
     *   can refer to parameters that aren't involved directly in the
     *   command.  For example, a message for "take <dobj>" might want to
     *   refer to the object containing the direct object.
     */
    setMessageParam(objName, obj)
    {
        /* 
         *   if we don't yet have an extra message parameters table,
         *   create a small lookup table for it 
         */
        if (extraMessageParams == nil)
            extraMessageParams = new LookupTable(8, 8);

        /* add the parameter to the table, indexing by the parameter name */
        extraMessageParams[objName.toLower()] = obj;
    }

    /*
     *   For convenience, this method allows setting any number of
     *   name/value pairs for message parameters. 
     */
    setMessageParams([lst])
    {
        /* set each pair from the argument list */
        for (local i = 1, local len = lst.length() ; i+1 <= len ; i += 2)
            setMessageParam(lst[i], lst[i+1]);
    }

    /*
     *   Synthesize a global message parameter name for the given object.
     *   We'll store the association and return the synthesized name. 
     */
    synthMessageParam(obj)
    {
        local nm;
        
        /* synthesize a name */
        nm = 'synth' + toString(synthParamID++);

        /* store the association */
        setMessageParam(nm, obj);

        /* return the synthesized name */
        return nm;
    }

    /* synthesized message object parameter serial number */
    synthParamID = 1

    /*
     *   Extra message parameters.  If a message processor wants to add
     *   special message parameters of its own, we'll create a lookup
     *   table for the extra parameters.  Message processors might want to
     *   add their own special parameters to allow referring to objects
     *   other than the main objects of the command.  
     */
    extraMessageParams = nil

  
    /* 
     *   Get a list of all the objects that this action should act on if the
     *   player typed ALL for role (DirectObject, IndirectObject, or perhaps in
     *   some future version of the library, AccessoryObject.
     */
    getAll(cmd, role)
    {
        /* by default, return everything in scope */
        return World.scope.toList();
    }
    
     /*
     *   Score a set of objects in a given noun role in the action, in
     *   order to resolve an ambiguous command.  Our job, in brief, is to
     *   READ THE PLAYER'S MIND: we want to figure out which object or
     *   objects the player is actually referring to when their words are
     *   ambiguous.
     *   
     *   'cmd' is the Command object describing the command.  The various
     *   object lists (dobjs, iobjs, accs) have been filled in with the
     *   in-scope objects that match the noun phrase, but these haven't
     *   been disambiguated yet, so there might be more objects listed than
     *   will actually be used in the final command.
     *   
     *   'role' tells us the noun phrase role that we're scoring
     *   (DirectObject, IndirectObject, AccessoryObject, TopicRole,
     *   LiteralRole).
     *   
     *   'lst' is the match list.  This is a Vector containing NPMatch
     *   objects.  There's one NPMatch for each object that we're
     *   considering as a match for the player's noun phrase.
     *   
     *   For each item in the match list, we must set the NPMatch object's
     *   'score' property to a number indicating how likely we think it is
     *   that the player is referring to this object.  The higher the
     *   score, the more likely we think it is.  The score value is purely
     *   relative - the caller will pick the object or objects with the
     *   highest score.
     *   
     *   
     *   
     *   We run through the verify routine for each object, which in turn
     *   runs through the preconditions of that object. We take the returned
     *   verify score to be the score for the object (or its replacement if
     *   remapping took place).
     *   
     *   Next, we do any verb-specific adjustments via self.actionScore().
     *   
     *   Finally, we call each object's scoreObject() routine to give the
     *   object a chance to make any adjustments for special affinities (or
     *   aversions).  
     */
    
    scoreObjects(cmd, role, lst)
    {
        local bestScore = 0;
        local bestResult = nil;
        local verResult;
        
        gAction = cmd.action;
        gActor = cmd.actor;
        foreach (local i in lst)
        {
            /* get this object */
            local obj = i.obj;
            verResult = cmd.action.verify(obj, role);
            i.score = verResult.resultRank;
            
            if(verResult.resultRank > bestScore)
            {
                bestScore = verResult.resultRank;
                bestResult = verResult;
            }
            
            /* 
             *   The verify process could result in the remapping of the
             *   original object to a new one.
             */
            i.obj = verResult.myObj;
        }
        
        /* 
         *   Make a note of which came out best in case it's needed when we come
         *   to verify the other object.
         */
        
        if(role == DirectObject)        
            curDobj = bestResult.myObj;
        
        if(role == IndirectObject)
            curIobj = bestResult.myObj;
        
        if(role == AccessoryObject)
            curAobj = bestResult.myObj;
        
        
        /* apply verb-specific adjustments */
        foreach (local i in lst)
            scoreObject(cmd, role, lst, i);
        
        /* apply object-specific adjustments */
        foreach (local i in lst)
            i.obj.scoreObject(cmd, role, lst, i);
        
    }
    
    
    /* 
     *   Wraps a list of objects in NPMatch objects so they can be run through
     *   the scoreObjects method.
     */
    wrapObjectsNP(lst)
    {
        local nplist = [];
        
        foreach(local cur in lst)        
        {            
            nplist += new NPMatch(nil, cur, 0);
        }
        
        return nplist;
    }
    
    /* Build the scope list for this action. */
    buildScopeList(whichRole = DirectObject)
    {
        /* Start with the scope list supplied by the Query object */
        scopeList = Q.scopeList(gActor).toList();
        
        /* Add any additional items to scope as special cases if desired. */
        addExtraScopeItems(whichRole);
    }
       
    
    
    /* 
     *   Add extra scope items if this action needs a wider definition of scope
     *   than normal. By default we simply allow the current actor's current
     *   location to add additional items to scope if it wishes to.
     */
    
    addExtraScopeItems(role?)
    {
        gActor.getOutermostRoom.addExtraScopeItems(self);
    }
    
    /* Our currently cached list of items in scope for this action. */         
    scopeList = []
    
    /* Used by Mercury's spelling corrector code. */
    spellingPriority = 10
    
    /* 
     *   Can ALL be used with this action? By default we take our value from
     *   gameMain.allVerbsAllowAll, though basic inventory-handling actions in
     *   the library will override this. This property is really only relevant
     *   on TAction and its descendents, but we define it here just to make sure
     *   no cases are missed.
     */
    allowAll = (gameMain.allVerbsAllowAll)
    
    /* 
     *   If we've been redirected here from another action, store a reference to
     *   that action.
     */
    redirectParent = nil
    
    parentAllowAll = (redirectParent ? redirectParent.allowAll : nil)
;


/* 
 *   The SystemAction class is for actions not affecting the game world but
 *   rather acting on the game session, such as SAVE, RESTORE and QUIT.
 */
class SystemAction: Action
    /* A SystemAction is not normally undo-able */
    includeInUndo = nil
    
    /* A SystemAction is not normally repeatable */
    isRepeatable = nil
    
    /* 
     *   Since a SystemAction isn't an action in the game world, we don't want
     *   it to trigger any after action notifications.
     */
    afterAction() { }
    
    /* 
     *   Since a SystemAction isn't an action in the game world, we don't want
     *   it to count as a turn, so we don't run any Daemons or Fuses and we
     *   don't advance the turn count.
     */
    turnSequence() { }
    
    /* 
     *   A SystemAction doesn't take any turns (this is a bit belt-and-braces
     *   since turnSequence does nothing in any case).
     */
    turnsTaken = 0
    
    /* 
     *   Since this isn't an action within the game world we bypass all the
     *   normal pre-action handling and just execute a reduced cycle.
     */
    exec(cmd) { execCycle(cmd); }
    
    /* 
     *   There's no before notifications for a SystemAction so we simply execute
     *   the action and, if we should define it as repeatable, make a note of it
     *   in case the player issues an AGAIN command on the next turn.
     */
    execCycle(cmd)
    {
        try
        {           
            IfDebug(actions, 
                    "[Executing <<actionTab.symbolToVal(baseActionClass)>> ]" );
            
            execAction(cmd);
            
            if(isRepeatable)
                libGlobal.lastAction = self.createClone();
        }
        catch(ExitActionSignal ex)
        {
        }
        
        catch(ExitSignal ex)
        {
            actionFailed = true;
        }
        
    }
    
     /*
      *   Ask for an input file.  We call the input manager, which displays the
      *   appropriate local file selector dialog. This is used for SystemActions
      *   that need a file to act on, such as SAVE, RESTORE and QUIT.
      */
    getInputFile(prompt, dialogType, fileType, flags)
    {
        return inputManager.getInputFile(prompt, dialogType, fileType, flags);
    }
;

/* 
 *   An IAction is an Action that doesn't directly act on any objects. At least
 *   in this version of the library it works just like the base Action class.
 */

class IAction: Action
  
;

/* 
 *   A TravelAction is one that moves (or at least tries to move) the player
 *   character from one place to another via a command like GO NORTH, or EAST.
 */

class TravelAction: Action
    
    baseActionClass = TravelAction
    
    /* 
     *   Use the inherited handling but first make a note of the direction the
     *   actor wants to travel in.
     */
    execCycle(cmd)
    {
        /* 
         *   Obtain the direction from the verbProd of the current command
         *   object, unless this TravelAction already defines its direction
         */
        if(!predefinedDirection)
           direction = cmd.verbProd.dirMatch.dir; 
        
        IfDebug(actions, 
                    "[Executing <<actionTab.symbolToVal(baseActionClass)>> 
                    <<direction.name>>]" );
        
        /* Carry out the inherited handling. */
        inherited(cmd);
    }
    
    
    /* 
     *   Does this TravelAction already define a set direction on its direction
     *   property (so we don't need to look to what direction object the command
     *   refers)?
     */
    predefinedDirection = nil
    
    /* 
     *   Execute the travel command, first carrying out any implicit actions
     *   needed to facilitate travel
     */
    
    execAction(cmd)
    {        
        
        /* 
         *   If the actor is not directly in the room, treat OUT as a request to
         *   get out of the immediate container.
         */
        if(!gActor.location.ofKind(Room) && direction == outDir)
        {
            replaceAction(GetOff, gActor.location);
            return;
        }
             
        /* 
         *   If the actor is not directly in the room, make him/her get out of
         *   his immediate container(s) before attempting travel.
         */
        
        while(!gActor.location.ofKind(Room))
        {
            /* Note the actor's current location. */
            local loc = gActor.location;
            
            /* 
             *   Try to get the actor out of his/her current location with an
             *   implicit action.
             */
            tryImplicitAction(GetOff, loc);
            
            /* Note and if necessary display the implicit action report. */
            "<<buildImplicitActionAnnouncement(true)>>";
            
            
            /*
             *   if the command didn't work, quit the loop or we'll be stuck in
             *   it forever.
             */
            if(gActor.location == loc)
                exit;
            
        }
        
        /* 
         *   Note and if necessary display any other implicit action reports
         *   that may have been generated prior to executing this action.
         */
        "<<buildImplicitActionAnnouncement(true)>>";
              
        /* Carry out the actual travel. */
        doTravel();
    }
    
    /* 
     *   Carry out travel in direction. For this purpose we first have to define
     *   what the corresponding direction property of the actor's current
     *   location refers to. If it's nil, no travel is possible, and we simply
     *   display a refusal message. If it's an object we execute its travelVia()
     *   method for the current actor. If it's a double-quoted string or a
     *   method we execute it and make a note of where the actor ends up, if the
     *   actor is the player character. If it's a single-quoted string we
     *   display it.
     *
     *   Note that we only display the various messages announcing failure of
     *   travel if the actor is the player character. We presumably don't want
     *   to see these messages as the result of NPCs trying to move around the
     *   map.
     */
    
    doTravel()
    {
        /* Note the actor's current location. */
        local loc = gActor.getOutermostRoom;
        local conn;
        
        /* 
         *   Note whether the current location is located, or whether it permits
         *   travel in the dark (in which case we treat it as illuminated for
         *   the purposes of allowing travel).
         */
        local illum = loc.allowDarkTravel || loc.isIlluminated;
        
        
        /* 
         *   Find out what's attached to the direction property of the direction
         *   in which the actor wants to travel and respond accordingly.
         */
        switch (loc.propType(direction.dirProp))
        {
            /* 
             *   If there's nothing there, simply display the appropriate
             *   message explaining that travel that way isn't possible.
             */
        case TypeNil:
            if(illum && gActor == gPlayerChar)
                loc.cannotGoThatWay(direction);
            else if(gActor == gPlayerChar)
                loc.cannotGoThatWayInDark(direction);            
            break;
            
            /* 
             *   If the direction property points to an object, assume it's some
             *   kind of TravelConnector (which also includes Rooms and Doors)
             *   and then attempt travel via that object.
             */
        case TypeObject:     
            /* Note our connector */
            conn = loc.(direction.dirProp);
            
            /* 
             *   If the connector is apparent to the actor then attempt travel
             *   via the connector.
             */
            if(conn.isConnectorApparent)
                conn.travelVia(gActor);
            
            /* 
             *   Otherwise if there's light enough to travel and the actor is
             *   the player character, display the standard can't travel message
             *   (as if the connector wasn't there.
             */
            else if(illum && gActor == gPlayerChar)
                loc.cannotGoThatWay(direction);
            
            /* 
             *   Otherwise if the actor is the player character, display the
             *   standard message forbidding travel in the dark.
             */
            else if(gActor == gPlayerChar)
                loc.cannotGoThatWayInDark(direction);
            break;       
            
            /* 
             *   If the direction property points to a double-quoted method or a
             *   string, then provided the illumination is right, we display the
             *   string or execute the method. Otherwise show the message saying
             *   we can't travel that way in the dark.
             */            
        case TypeDString:
        case TypeCode:
            if(illum)
            {
                loc.(direction.dirProp);
                
                /* 
                 *   If we've just executed a method, it may have moved the
                 *   actor to a new location, so if the actor is the player
                 *   character note where the method took the actor to so that
                 *   the pathfinder can find a route via this exit.
                 */
                if(gActor == gPlayerChar)
                    libGlobal.addExtraDestInfo(loc, direction,
                                           gActor.getOutermostRoom);
            }
            else if(gActor == gPlayerChar)
                loc.cannotGoThatWayInDark(direction);
            break;
            
            /* 
             *   If the direction property points to a single-quoted string,
             *   simply display the string if the illumination is sufficient,
             *   otherwise display the message saying we can't go that way in
             *   the dark. If the actor isn't the player character, do nothing.
             */
        case TypeSString:
            if(gActor == gPlayerChar)
            {
                conn = loc.(direction.dirProp);
                if(illum)
                {
                    say(conn);
                    libGlobal.addExtraDestInfo(loc, direction,
                                               gActor.getOutermostRoom); 
                }
                else
                    loc.cannotGoThatWayInDark(direction);
            }    
            break;
            
        }
        
       
        
    }
    
    /* 
     *   The direction the actor wants to travel in. This is placed here by the
     *   execCycle method and takes the form of A Direction object, e.g.
     *   northDir.
     */
    direction = nil
    
    /* It's generally possible to undo a travel command. */
    canUndo = true
;



/* 
 *   A TAction is an action that applies to a single direct object. Other action
 *   classes that apply to more than one object, such as TIAction, inherit from
 *   this class so some of the code needs to take that into account.
 */
class TAction: Action    
   
    /* 
     *   A list of the direct objects of this action that make it to the report
     *   stage.
     */
    reportList = []
    
    /* 
     *   A list of the direct objects of this action that make it to the action
     *   stage.
     */
    actionList = []
    
    /* 
     *   A LookupTable containing the verify results for this action. This is
     *   keyes on the object being verified, with the value being the worst
     *   verify result encountered for that object so far.
     */
    verifyTab = nil
        
    
    /*   
     *   Store the last verify failure message so that if we get several
     *   identical ones in a row, we don't keep repeating them
     */
    lastVerifyMsg = nil
    
    /* 
     *   set this property to true if you want to announce the object before the
     *   action result when there's more than one object. If the action routine
     *   summarizes the result at the end you don't want to do this so you
     *   should then set this to nil.
     */
    announceMultiAction = nil
    
    /* The current direct object of this action */    
    curDobj = nil
    
    /* A method that returns ther current direct object of this action. */
    getDobj { return curDobj; }
    
    /* 
     *   The current object being processed (in a TAction, always the curDObj;
     *   in a TI Action either the curDobj or the curIOoj).
     */
    curObj = nil
    
    /* 
     *   Reset values to their starting state when an action is used to execute
     *   a new command.
     */
    
    reset()
    {
        scopeList = [];
        reportList = [];
        actionList = [];
        verifyTab = nil;
        isImplicit = nil;
        curDobj = nil;
        curObj = nil;
        lastVerifyMsg = nil;
        redirectParent = nil;
    }
    
    
    /* 
     *   Information to allow the DEBUG ACTIONS command to express a complete
     *   topic phrase
     */
    #ifdef __DEBUG
    dqinfo = ''
    iqinfo = ''
    #endif
    
    /* 
     *   Execute the command cycle for this action. This differs from the base
     *   Action class in not calling beforeAction directly, since the
     *   beforeAction() notifications occur within the execResolvedAction
     *   method.
     */
    
    
    execCycle(cmd)
    {
        
        IfDebug(actions, 
                "[Executing <<actionTab.symbolToVal(baseActionClass)>> :
                    <<dqinfo>> <<cmd.dobj.name>> <<if cmd.iobj != nil>>
                    : <i><<iqinfo>></i> <<cmd.iobj.name>> <<end>>]\n" );
        
        /* 
         *   Disallow ALL (e.g. EXAMINE ALL) if the action does not permit it.
         *   Since we don't want to block plural matches (for which
         *   cmd.matchedAll is also true) we all test for the presence of 'all'
         *   among the command tokens.
         */
        
        if(cmd.matchedAll && !(allowAll || parentAllowAll) && mentionsAll(cmd))
        {
            DMsg(all not allowed, 'Sorry; ALL is not allowed with this command.
                ');
            abort;
        }
        
        try
        {            
            execAction(cmd);
            
            if(isRepeatable)
                libGlobal.lastAction = self.createClone();
          
        }
                
        catch(ExitSignal ex)
        {
            actionFailed = true;
        }
        
    }
    
    /* Execute this action */
    
    execAction(cmd)
    {
        /* 
         *   Note the current direct object, which should be the direct object
         *   supplied by the current Command object.
         */        
        curDobj = cmd.dobj;
        
        /* 
         *   Note the current direct object as a possible antecedent for
         *   pronouns.
         */
        notePronounAntecedent(curDobj);
        
        /* Execute the action with the current direct object. */
        execResolvedAction();
    }
    
 
    
    /* 
     *   Call this method when there's no need to resolve the objects used in
     *   the command but we still want it to pass through every stage
     */
    
    execResolvedAction()
    {
               
        /* Create a new LookupTable for our verify results. */
        verifyTab = new LookupTable;
        
        /* 
         *   We shouldn't really need to catch any signals here, but the author
         *   might put an exitAction macro in a check method, say, so we need to
         *   be able to handle it.
         */
        try
        {
            /* 
             *   Obtain the verify result for the current direct object. Note at
             *   this point the objects have already been resolved so we're only
             *   interested in whether the verify command is going to allow the
             *   action to go ahead. If it doesn't allow the action return nil
             *   to stop it here.
             */
            
            if(!verifyObjRole(curDobj, DirectObject))
               return nil; 
               
            
            
            /* Carry out any remapping of this action on the direct objec. */
            remap(DirectObject);
            
            /* 
             *   If gameMain defines the option to run the before notifications
             *   before the check stage, run the before notifications now.
             */            
            if(gameMain.beforeRunsBeforeCheck)
                beforeAction();
            
            /* 
             *   Try the check stage. If the action fails the check stage, stop
             *   the action here and return nil to tell our caller this action
             *   has failed.
             */            
            if(!checkAction(cmd))
                return nil;            
            
            /* 
             *   If gameMain defines the option to run the before notifications
             *   after the check stage, run the before notifications now.
             */
            if(!gameMain.beforeRunsBeforeCheck)
                beforeAction();
            
            /* Carry out the action on a single direct object. */
            doActionOnce();
 
            /* Return true to tell our caller the action succeeded. */
            return true;
                
        }
        catch (ExitActionSignal ex)
        {                
            return nil;
        }         
        
    }
    
    /* 
     *   Flag: do we want the object name to appear before a check stage failure
     *   message if multiple objects are involved in the action. By default we
     *   do, otherwise it might not be clear which object the message referes
     *   to.
     */
        
    announceMultiCheck = true
    
    /* 
     *   Run the check phase of the action, both on the direct object and on any
     *   preconditions.
     */
    
    checkAction(cmd)
    {
        /* 
         *   Try the check method on the current direct object. If it fails
         *   return nil to indicate failure of the entire check stage.
         */        
        if(!check(curDobj, checkDobjProp))
            return nil;
        
        /* 
         *   Finally try the check phase of any preconditions and return the
         *   result.
         */
        
        return checkPreCond(curDobj, preCondDobjProp);          
                
    }
    
    /* 
     *   Call the check method (checkProp) on the appropriate object (obj).
     *   Return true to indicate that the action succeeds or nil otherwise
     */
    check(obj, checkProp)
    {
        local checkMsg = nil;
        
        /* Note which object is the current object of the command. */
        curObj = obj;
        
        /* Run the check method on the object and capture its output */
        try
        {
            checkMsg = gOutStream.captureOutput({: obj.(checkProp)});
        }
        
        /* 
         *   Game authors aren't meant to use the exit macro in check methods,
         *   but in case they do we handle it here.
         */
        catch (ExitSignal ex)
        {
            /* 
             *   If for some reason a check method uses exit without displaying
             *   a method, we supply a dummy failure message at this point.
             */
            if(checkMsg is in (nil, ''))
               checkMsg = gLibMessages.failCheckMsg;
        }
               
        /* 
         *   If the check method tried to display something then it wants to
         *   block the action, so we display the failure message and stop the
         *   action.
         */
        if(checkMsg not in (nil, ''))
        {           
            
            if(announceMultiCheck && gCommand.dobjs.length > 1)
                announceObject(obj);
            
            /* 
             *   If we're an implicit action then add a failure message to our
             *   implicit action list and display the list ("first trying
             *   to...")
             */
            if(isImplicit)
                "<<buildImplicitActionAnnouncement(nil)>>";
            
            /* Display our failure message */
            say(checkMsg);
            "\n";
            
            /* Note that the action failed. */
            actionFailed = true;
            
            /* 
             *   Return nil to tell our caller this action failed the check
             *   stage
             */
            return nil;
        }
        
        /* 
         *   Return true to tell our our caller this action passed the check
         *   stage on this object.
         */
        return true;
    }
    
    /* Run the check stage on the preCondProp of obj */
    
    checkPreCond(obj, preCondProp)
    {
        local preCondList;
        local checkOkay = true;
        
        /* Note which object we're checking */
        curObj = obj;
        
        /* 
         *   Construct a list or preCondition objects on the appropriate object
         *   property.
         */
        preCondList = valToList(obj.(preCondProp));
        
        /* Sort the list in preCondOrder */
        preCondList = preCondList.sort(nil,
                                       {a, b: a.preCondOrder - b.preCondOrder});
        
        /* Iterate through the list to see if all the checks are satisfied */
        foreach(local cur in preCondList)              
        {          
            /* 
             *   If we fail the check method on any precondition object, note
             *   the failure and stop the iteration.
             */
            if(cur.checkPreCondition(obj, true) == nil)
            {
                checkOkay = nil;
                break;
            }                
        }
        
        /* 
         *   If the check method failed on any of our precondition objects note
         *   that the action is a failure.
         */
        if(checkOkay == nil)
            actionFailed = true;
        
        /* Return our overall check result. */
        return checkOkay;
    }
    
    /* Carry out the action phase on the direct object */
    doActionOnce()
    {
        
        /* 
         *   If we're iterating over several objects and we're the kind of
         *   action which wants to announce objects in this context, do so.
         */
        
         if(announceMultiAction && gCommand.dobjs.length > 1)
            announceObject(curDobj);
        
        /* 
         *   If we're an implicit action, add this action to the list of
         *   implicit actions to be reported in due course. If we're not, show
         *   the list of implicit actions (if any) leading to this action.
         */
            "<<buildImplicitActionAnnouncement(true)>>";        
        
        /* Note that the current object is the direct object */
         curObj = curDobj;
        
        /* 
         *   If the action method displays anything then we don't add this
         *   object to the list of objects to be reported on at the report
         *   stage, on the assumption that the action stage has either produced
         *   its own report for this object or reported on the failure of the
         *   action. If, however, the action is carried out silently then we'll
         *   add this object to the list to objects to be reported on at the
         *   report stage.
         */    
        
        if(!gOutStream.watchForOutput({:curDobj.(actionDobjProp)}))
            reportList += curDobj;       
        
        /* Note that we've carried out the action on this object. */
        actionList += curDobj;
        
        return true;
    }
    
    
    /* 
     *   Flag, do we want to announce the object name before the verify message
     *   in cases where there's more direct object in the command? By default we
     *   don't since verify messages generally make it clear enough which
     *   objects they refer to.
     */
    announceMultiVerify = nil
    
    
        
    
    /* Carry out any remapping required for this role. */
    
    remap(role)
    {
        local remapProp;
        local remapResult;
        local obj;
        
        /* 
         *   First determine which properties we need to use according to the
         *   current object's role in the action.
         */
        switch(role)
        {
        case DirectObject:
            remapProp = remapDobjProp;
            obj = curDobj;
            break;
           
        case IndirectObject:
            remapProp = remapIobjProp;
            obj = curIobj;
            break;
            
        case AccessoryObject:
            remapProp = remapAobjProp;
            obj = curAobj;
        }
        
                       
        /* then check if we need to remap this action in this role. */
        
        remapResult = obj.(remapProp);
        
        /* We only need to do anything here if the remapResult is a list. */
        
        if(dataType(remapResult) == TypeList && remapResult.length > 0)
            remapAction(remapResult);
        
    }
    
      
    /* 
     *   Return a list of direct objects corresponding to the word ALL in the
     *   player's command. By default we return everything in scope that isn't a
     *   a Room.
     */
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }
    
    /* 
     *   Add a verify result to this action's verify table. This method is
     *   normally called by one of the macros (logical, illogical, logicalRank,
     *   etc.) use in an object's verify routine.
     */
    
    addVerifyResult(verRes)
    {
        /* Note the object to which this verify result relates. */
        local obj = verRes.myObj;
        
        /* 
         *   If it isn't the object we're currently meant to be verifying,
         *   adjust it.
         */
        if(obj != verifyObj)
        {
            obj = verifyObj;
            verRes.myObj = obj;
        }
        
        /* 
         *   If we don't currently have a verify table for this action, create
         *   one
         */
        if(verifyTab == nil)
            verifyTab = new LookupTable();
        
        /* 
         *   Add this verify result to this action's verify table only if it
         *   doesn't already contain a verify result for the same object with a
         *   lower resultRank.
         */
        if(!verifyTab.isKeyPresent(obj) ||        
            verRes.resultRank < verifyTab[obj].resultRank)   
            verifyTab[obj] = verRes;       
    } 

    
    /* 
     *   reportAction() is called only after all the action routines have been
     *   run and the list of dobjs acted on is known. It is also called only if
     *   the action is not implicit. It can thus be used to summarize a list of
     *   identical actions carried out on every object in reportList or to print
     *   a report that is not wanted if the action is implicit. By default we
     *   call the dobj's reportDobjProp to handle the report.
     *
     *   Note that this method is usually called from the current Command object
     *   after its finished iterated over all the direct objects involved in the
     *   command.
     */
    
    reportAction()
    {
        if(!isImplicit && reportList.length > 0)
            curDobj.(reportDobjProp);    
        

    }
    
    /* install the resolved objects in the action */
    setResolvedObjects(dobj)
    {
        curDobj = dobj;
    }
    
    /* Check whether the resolved objects for this action are in scope */
    resolvedObjectsInScope()
    {
        buildScopeList();
        return scopeList.indexOf(curDobj) != nil;
    }

    /*
     *   Get a message parameter object for the action.  We define 'dobj'
     *   as the direct object, in addition to any inherited targets.  
     */
    getMessageParam(objName)
    {
        switch(objName)
        {
        case 'dobj':
            /* return the current direct object */
            return curDobj;
            
        case 'cobj':
            /* return the current object */
            return curObj;

        default:
            /* inherit default handling */
            return inherited(objName);
        }
    }
    
    /* 
     *   A convenience method for putting every game object in scope, which may
     *   be appropriate for certain commands (not least, certain debugging
     *   commands). It's intended to be called from addExtraScopeItems when
     *   needed.
     */
    
    makeScopeUniversal()
    {
        local obj = firstObj(Thing);
        local vec = new Vector;
        do
        {
            vec.append(obj);
            obj = nextObj(obj, Thing);
        } while (obj!= nil);
        
        scopeList = scopeList.appendUnique(vec.toList());
    }
   
;

/* 
 *   A TIAction is an action that applies to both a direct object and an
 *   indirect object. Since it inherits from TAction we only need to define the
 *   additional methods and properties relating to the handling of indirect
 *   objects
 */

class TIAction: TAction
    
    /* The current indirect object of this action. */
    curIobj = nil
    
    /* A method that returns the current indirect object of this action. */
    getIobj { return curIobj; }
    
    /* The various methods to call on the indirect object of this action. */
    verIobjProp = nil
    checkIobjProp = nil
    actionIobjProp = nil
    preCondIobjProp = nil
    
    /* 
     *   A list of the indirect objects that this actually actually ends up
     *   acting on at the action stage.
     */
    ioActionList = []
    
    /* 
     *   Flag: should we resolve the indirect object of this action before the
     *   direct object?
     */
    resolveIobjFirst = true
    
    /* Reset the action variables to their initial state. */
    reset()
    {
        inherited;
        curIobj = nil;
        ioActionList = [];
    }
    
    /* execute this action. */
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
        
        /* Note both objects as possible pronoun antecedents. */
        notePronounAntecedent(curDobj, curIobj);
        
        /* execute the resolved action. */
        execResolvedAction();
    }
    
    /* Carry out the check phase for this command. */   
    checkAction(cmd)
    {
           
        /* 
         *   If we don't pass the check phase on both the indirect and the
         *   direct objects, then return nil to tell our caller we've failed
         *   this stage.
         */
        if(!((check(curIobj, checkIobjProp) && check(curDobj,
            checkDobjProp))))
            return nil;
        
        /* 
         *   Return the result of running the check stage on both the iobj and
         *   the dobj
         */
        
        return checkPreCond(curIobj, preCondIobjProp) 
            && checkPreCond(curDobj, preCondDobjProp);
        

    }
    
    
    /* Set the resolved objects for this action. */
    setResolvedObjects(dobj, iobj)
    {
        curDobj = dobj;
        curIobj = iobj;
    }
   
    /* 
     *   Test whether both the direct and the indirect objects for this action
     *   are in scope.
     */
    resolvedObjectsInScope()
    {
        buildScopeList();
        return scopeList.indexOf(curDobj) && scopeList.indexOf(curIobj) != nil;
    }
    
    
    /* 
     *   Carry out the report phase for this action. If there's anything in the
     *   ioActionList and we're not an implicit action, call the report method
     *   on the indirect object. Then carry out the inherited handling (which
     *   does the same on the direct object). Note that this method is called by
     *   the current Command object once its finished iterating over all the
     *   objects involved in the command.
     */
    reportAction()
    {
        if(!isImplicit && ioActionList.length > 0)
            curIobj.(reportIobjProp);
        
        inherited;
        
    }
    
    /* Get the message parameters relating to this action */
    getMessageParam(objName)
    {
        switch(objName)
        {
        case 'iobj':
            /* return the current indirect object */
            return curIobj;
            
        default:
            /* inherit default handling */
            return inherited(objName);
        }
    }
    
    
    
    execResolvedAction()
    {
        
        try
        {
            /* 
             *   If we want to resolve the indirect object first (before the
             *   direct object) then we run the verify stage on the indirect
             *   action first. If it fails, return nil to tell the caller it
             *   failed.
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
             *   If we want to resolve the indirect object after the direct
             *   object, run the verify routines on the indirect object now, and
             *   return nil if they disallow the action.
             */
            if(!resolveIobjFirst && !verifyObjRole(curIobj, IndirectObject))
                return nil;
            
            /* Carry out any remapping needed on the direct object. */           
            remap(IndirectObject);
            
            /* Carry out any remapping needed on the indirect object. */  
            remap(DirectObject);
            
            /* 
             *   If gameMain defines the option to run before notifications
             *   before the check stage, run the before notifications now.
             */
            if(gameMain.beforeRunsBeforeCheck)
                beforeAction();
            
            /* 
             *   Try the check stage on both objects. If either disallows the
             *   action return nil to stop the action here.
             */
            if(!checkAction(nil))
                return nil;
            
            /* 
             *   If gameMain defines the option to run before notifications
             *   after the check stage, run the before notifications now.
             */
            
            if(!gameMain.beforeRunsBeforeCheck)
                beforeAction();
            
            /* Carry out the action stage */
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
     *   although some TIActions can operate on multiple direct objects, none
     *   defined in the library acts on multiple indirect objects, so there's
     *   only minimal support for the latter possibility.
     */
    doActionOnce()
    {
        
        /* 
         *   If we're iterating over several objects and we're the kind of
         *   action which wants to announce objects in this context, do so.
         */
        
        if(announceMultiAction && gCommand.dobjs.length > 1)
            announceObject(curDobj);
        
        /* Display any pending implicit action announcements. */
         "<<buildImplicitActionAnnouncement(true)>>";
        
        /* 
         *   Note that the current object we're dealing with is the direct
         *   object.
         */
        curObj = curDobj;     
        
        
        /* 
         *   Run the action routine on the current direct object. If it doesn't
         *   display anything add the direct object to the list of objects to be
         *   reported on at the report stage.
         */
        if(!gOutStream.watchForOutput({:curDobj.(actionDobjProp)}))
           reportList += curDobj;
        
        /* Note that we've acted on this direct object. */
        actionList += curDobj;
        
        /* Note that the current object is now in the indirect object. */
        curObj = curIobj;
        
        /* 
         *   Execute the action method on the indirect object. If it doesn't
         *   output anything, add the current indirect object to ioActionList in
         *   case the report phase wants to do anything with it.
         */
        if(!gOutStream.watchForOutput({:curIobj.(actionIobjProp)}))
           ioActionList += curIobj;
              
        return true;
    }
    
   
;

/* 
 *   A LiteralAction is an action that acts on a single literal object, e.g.
 *   TYPE HELLO
 */
class LiteralAction: Action
    exec(cmd)
    {
        /* Note the literal string associated with this command. */
        literal = cmd.dobj.name;
        
        /* carry out the inherited handling. */
        inherited(cmd);
    }
 
    literal = nil
;



/* 
 *   A LiteralTAction is an action that involves one physical object and one
 *   string, e.g. TYPE HELLO ON TERMINAL.
 */
class LiteralTAction: TAction
    execAction(cmd)
    {
        
        /* 
         *   determine which is the object and which is the literal value and
         *   plug each into the right slot (so that the Thing ends up as the
         *   direct object of the command and the string as the literal).
         */
        
        if(cmd.dobj.ofKind(Thing))
        {        
            curDobj = cmd.dobj;
            literal = cmd.iobj.name;
        }
        else
        {
            curDobj = cmd.iobj;
            literal = cmd.dobj.name;
        }
        
        /* Note the direct object as an antecedent for pronouns */
        notePronounAntecedent(curDobj);

        /* Execute the resolved action (as for a TAction) */
        execResolvedAction();
        
    }
    
    /* 
     *   Whichever object slot a verify routine is notionally trying to verify
     *   for given the grammatical form of the command, in practice only the
     *   direct object (the thing involved in the command) can be verified. E.g.
     *   for WRITE FOO ON BALL we treat BALL as the direct object of the command
     *   and FOO as the literal, even if the Parser thinks it needs to verify
     *   the Indirect Object to disambiguate BALL.
     */
    
    verify(obj, role)
    {
        return inherited(obj, DirectObject);
    }
    
    
    /* The literal value associated with this command */
    literal = nil
;


/* 
 *   A TopicTAction is an action involving one physical object and one topic,
 *   e.g. ASK BOB ABOUT TOWER.
 */

class TopicTAction: TAction
    execAction(cmd)
    {
        
        /* 
         *   determine which is the object and which is the literal value and
         *   plug each into the right slot. We ensure that the physical object
         *   (the Thing) ends up as the direct object and the ResolvedTopic as
         *   the indirect object.
         */
        
        if(cmd.dobj.ofKind(Thing))
        {        
            curDobj = cmd.dobj;
            curIobj = cmd.iobj;
        }
        else
        {
            curDobj = cmd.iobj;
            curIobj = cmd.dobj;
        }
        
        /* Note the direct object as a potential pronoun antecedent. */
        notePronounAntecedent(curDobj);

        /* Attempt to resolve any pronouns within the ResolvedTopic */
        resolvePronouns();
        
        /* Execute the action as for a TAction */
        execResolvedAction();       
        
    }
    
    /* 
     *   Although we don't have an indirect object in the conventional sense, we
     *   use the curIobj property to store the ResolvedTopic involved in the
     *   command.
     */
    curIobj = nil
    
    getIobj() { return curIobj; }
    
    /* 
     *   This is a bit of a kludge to deal with the fact that the Parser doesn't
     *   seem able to resolve pronouns within ResolvedTopics. We do it here
     *   instead.
     */
    
    resolvePronouns()
    {
        for(local cur in curIobj.topicList, local i = 1;; ++i)
        {
            if(cur == Him && curDobj.isHim)
                curIobj.topicList[i] = curDobj;
            
            if(cur == Her && curDobj.isHer)
                curIobj.topicList[i] = curDobj;
            
            if(cur == It && curDobj.isIt)
                curIobj.topicList[i] = curDobj;
        }
    }
    
    /* 
     *   Whichever object slot a verify routine is notionally trying to verify
     *   for given the grammatical form of the command, in practice only the
     *   direct object (the thing involved in the command) can be verified. E.g.
     *   for WRITE FOO ON BALL we treat BALL as the direct object of the command
     *   and FOO as the literal, even if the Parser thinks it needs to verify
     *   the Indirect Object to disambiguate BALL.
     */
    
    verify(obj, whichObj)
    {
        return inherited(obj, DirectObject);
    }
;

/* 
 *   A TopicAction is an action referring to a single Topic (e.g. TALK ABOUT THE
 *   TOWER). It behaves almost exactly like an IAction.
 */

class TopicAction: IAction
    
;

/* Try action as an implicit action with [objs] as its objects */

_tryImplicitAction(action, [objs])
{
         
    
    local oldAction;
//    local wasImplicit = gAction.isImplicit;
     
    action = action.createInstance();
    action.isImplicit = true;
    
    oldAction = gAction;
    
    /* install the resolved objects in the action */
    action.setResolvedObjects(objs...);
    
    
    
    /* 
     *   For an implicit action, we must check the objects involved to make
     *   sure they're in scope.  If any of the objects aren't in scope,
     *   there is no way the actor would know to perform the command, so
     *   the command would not be implied in the first place.  Simply fail
     *   without trying the command.  
     */
    if (!action.resolvedObjectsInScope())
        return nil;
    
    
    action.parentAction = gAction;
    
    gAction = action;
    
    try
    {
        action.execResolvedAction();
        return true;
    }
    
    catch (AbortImplicitSignal ex)
    {
        return nil;
    }
    
    finally
    {
        gAction = oldAction;
//        gAction.afterReports += action.afterReports;
        
    }
    
}


/* ------------------------------------------------------------------------ */
/*
 *   Run a replacement action. 
 */
_replaceAction(actor, action, [objs])
{
    
    
    /* run the replacement action as a nested action */
    _nestedAction(true, actor, action, objs...);

    /* the invoking command is done */
    exit;
}


_nestedAction(isReplacement, actor, action, [objs])
{
//    local action;
//
    /* create an instance of the desired action class */
    action = action.createInstance();

    /* install the resolved objects in the action */
    action.setResolvedObjects(objs...);

    if(isReplacement)
    {
        gCommand.action = action;
//        gCommand.dobj = action.curDobj;
//        gCommand.iobj = action.curIobj;
    }
    
    /* execute the new action */
    execNestedAction(isReplacement, nil, actor, action);
}
    



/*
 *   Execute a fully-constructed nested action.
 *   
 *   'isReplacement' indicates whether the action is a full replacement or
 *   an ordinary nested action.  If it's a replacement, then we use the
 *   game time taken by the replacement, and set the enclosing action
 *   (i.e., the current gAction) to take zero time.  If it's an ordinary
 *   nested action, then we consider the nested action to take zero time,
 *   using the current action's time as the overall command time.  
 *   
 *   'isRemapping' indicates whether or not this is a remapped action.  If
 *   we're remapping from one action to another, this will be true; for
 *   any other kind of nested or replacement action, this should be nil.  
 */
execNestedAction(isReplacement, isRemapping, actor, action)
{
    local oldAction;
    
    /* prepare the nested action */
    prepareNestedAction(isReplacement, isRemapping, action);

       
    action.isImplicit = gAction.isImplicit;
    
    /* If our objects aren't in scope we can't proceed with the action. */ 
    if (!action.resolvedObjectsInScope())
        return nil;
    

    oldAction = gAction;
    gAction = action;
    
    try
    {
        action.execResolvedAction();
        return true;
    }
    
    catch (AbortImplicitSignal ex)
    {
        return nil;
    }
        
    
    finally
    {
        /* 
         *   If we're not a replacement action we need to restore the old
         *   gAction when we're done; but if we're a nested action and not
         *   implicit, then we should show our action reports (if any) before
         *   handing back to the main action.
         */
        if(!isReplacement)
        {
            /* report the action */
            gAction.reportAction();
            
            /* 
             *   Clear out the reportList to make sure we don't display the same
             *   report again
             */
            gAction.reportList = [];
            
            /* restore the old gAction */
            gAction = oldAction;
        }

    }
}

/*
 *   Prepare a nested or replacement action for execution. 
 */
prepareNestedAction(isReplacement, isRemapping, action)
{
    action.parentAction = gAction;
    
    
}

//------------------------------------------------------------------------------

/*  
 *   Verify Results: objects of this class are created by macros like
 *   logicalRank() and illogical() that are used in verify routines and stored
 *   in the verTab table of the current action.
 */
class VerifyResult: object
    /* 
     *   Our resultRank; the lower this number the less likely it is that this
     *   action could succeed, or the more illogical it is.
     */
    resultRank = 0
    
    /* 
     *   The error message to display if this verify result prevents an action
     *   from going ahead.
     */
    errMsg = ''
    
    /* Is the action allowed to proceed according to this verify result? */
    allowAction = true
    
    /* Can this action be performed as an implicit action? */
    allowImplicit = true
    
    /* The object to which this verify result refers */
    myObj = nil
    
    /* The constructor for creating a new verify result. */
    construct(score_, errmsg_, allowAction_, myObj_, allowImplicit_ = true)
    {
        resultRank = score_;
        errMsg = errmsg_;
        allowAction = allowAction_;
        myObj = myObj_;
        allowImplicit = allowImplicit_;
    }
;

//------------------------------------------------------------------------------

/* Note the objects in objlist as potential pronoun antecedents */
notePronounAntecedent([objlist])
{
    local itList = [];
    local themList = [];
    local himList = [];
    local herList = [];
    
    /* 
     *   Go through each object in objlist and add it to the appropriate pronoub
     *   list
     */
    foreach(local cur in objlist)
    {
        /* 
         *   If we refer to a SubComponent, we're really referring to its
         *   location
         */
        
        if(cur.ofKind(SubComponent) && cur.location)
            cur = cur.location;
        
        if(cur.plural)
            themList += cur;
        if(cur.isHim)
            himList += cur;
        if(cur.isHer)
            herList += cur;
        if(cur.isIt)
            itList += cur;        
        
    }
    
    
    if(themList.length > 0)
        Them.setAntecedents(themList);
    if(itList.length > 0)
        It.setAntecedents(itList);
    if(herList.length  > 0)
        Her.setAntecedents(herList);
    if(himList.length > 0)
        Him.setAntecedents(himList);
        
    
}

/* The remainder of this file contains code  "borrowed" from the adv3 library */

/* ------------------------------------------------------------------------ */
/*
 *   PreSaveObject - every instance of this class is notified, via its
 *   execute() method, just before we save the game.  This uses the
 *   ModuleExecObject framework, so the sequencing lists (execBeforeMe,
 *   execAfterMe) can be used to control relative ordering of execution
 *   among instances.  
 */
class PreSaveObject: ModuleExecObject
    /*
     *   Each instance must override execute() with its specific pre-save
     *   code. 
     */
;

/*
 *   PostRestoreObject - every instance of this class is notified, via its
 *   execute() method, immediately after we restore the game. 
 */
class PostRestoreObject: ModuleExecObject
    /* 
     *   note: each instance must override execute() with its post-restore
     *   code 
     */

    /*
     *   The "restore code," which is the (normally integer) value passed
     *   as the second argument to restoreGame().  The restore code gives
     *   us some idea of what triggered the restoration.  By default, we
     *   define the following restore codes:
     *   
     *   1 - the system is restoring a game as part of interpreter
     *   startup, usually because the user explicitly specified a game to
     *   restore on the interpreter command line or via a GUI shell
     *   mechanism, such as double-clicking on a saved game file from the
     *   desktop.
     *   
     *   2 - the user is explicitly restoring a game via a RESTORE command.
     *   
     *   Games and library extensions can use their own additional restore
     *   codes in their calls to restoreGame().  
     */
    restoreCode = nil
;

/*
 *   PreRestartObject - every instance of this class is notified, via its
 *   execute() method, just before we restart the game (with a RESTART
 *   command, for example). 
 */
class PreRestartObject: ModuleExecObject
    /* 
     *   Each instance must override execute() with its specific
     *   pre-restart code.  
     */
;

/*
 *   PostUndoObject - every instance of this class is notified, via its
 *   execute() method, immediately after we perform an 'undo' command. 
 */
class PostUndoObject: ModuleExecObject
    /* 
     *   Each instance must override execute() with its specific post-undo
     *   code.  
     */
;

