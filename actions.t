#charset "us-ascii"
#include "advlite.h"

property handleTopic;
property showSuggestions;

DefineSystemAction(Quit)
   
    
    execAction(cmd)
    {
        local ans;
        DMsg(quit query, '<.p>Do you really want to quit? (y/n)?\n>');
        ans = inputManager.getInputLine();
        if(ans.toLower.startsWith('y'))
            throw new QuittingException;
        
    }
;

DefineSystemAction(Undo)
   
    
    execAction(cmd)
    {
        if(undo())
        {
            DMsg(undo okay, 'One turn undone: {1}', 
                 libGlobal.lastCommandForUndo);
            
            /* notify all PostUndoObject instances */
            PostUndoObject.classExec();
            
            return true;
        }
        else
        {
            DMsg(undo failed, 'Undo failed. ');
            return nil;
        }
    }
    
;

DefineSystemAction(Restart)
    
    
    execAction(cmd)
    {
        DMsg(restart query, 
             'Do you really want to start again from the beginning (y/n)?\n>');
        
        if(inputManager.getInputLine().toLower.startsWith(affirmativeLetter))
            doRestartGame();
        
    }
    
    affirmativeLetter = 'y'
    
    doRestartGame()
    {
        /* before restarting, notify anyone interested of our intentions */
        PreRestartObject.classExec();

        /* 
         *   Throw a 'restart' signal; the main entrypoint loop will catch
         *   this and actually perform the restart.
         *   
         *   Note that we *could* do the VM reset (via restartGame()) here,
         *   but there's an advantage to doing it in the main loop: we
         *   won't be in the stack context of whatever command we're
         *   performing.  If we did the restart here, it's possible that
         *   some useless objects would survive the VM reset just because
         *   they're referenced from within a caller's stack frame.  Those
         *   objects would immediately go out of scope when we get back to
         *   the main loop, but they might survive long enough to create
         *   apparent inconsistencies.  In particular, if we did a
         *   firstObj/nextObj loop, we could discover those objects and
         *   re-establish more lasting references to them, which we
         *   certainly don't want to do.  By deferring the VM reset until
         *   we get back to the main loop, we'll ensure that objects won't
         *   survive the reset just because they're on the stack
         *   momentarily here.  
         */
        throw new RestartSignal();
        
    }
;

DefineSystemAction(Credits)
    
    
    execAction(cmd)
    {
        versionInfo.showCredit();
        "<.p>";
    }
;

DefineSystemAction(About)
    execAction(cmd)
    {
        versionInfo.showAbout();
        "<.p>";
    }
;

DefineSystemAction(Version)
    execAction(cmd)
    {
        local lst = ModuleID.getModuleList();
        foreach(local cur in lst)    
           cur.showVersion();
        
        "<.p>";          
    }
;

DefineSystemAction(Exits)
    execAction(cmd)
    {
        if(gExitLister == nil)
            DMsg(no exit lister, 'Sorry, that command is not available in this
                game, since there\'s no exit lister. ');
        else
            gExitLister.showExitsCommand();
    }
;

DefineSystemAction(ExitsMode)
    execAction(cmd)
    {
        if(gExitLister == nil)
        {
             DMsg(no exit lister, 'Sorry, that command is not available in this
                game, since there\'s no exit lister. ');
            return;
        }
        
        if(cmd.verbProd.on_ != nil)
            gExitLister.exitsOnOffCommand(true, true);
        
        if(cmd.verbProd.off_ != nil)
            gExitLister.exitsOnOffCommand(nil, nil);
        
        if(cmd.verbProd.look_ != nil)
            gExitLister.exitsOnOffCommand(nil, true);
        
        if(cmd.verbProd.status_ != nil)
            gExitLister.exitsOnOffCommand(true, nil);
    }
    
;

DefineSystemAction(ExitsColour)
    execAction(cmd)
    {
        if(gExitLister == nil)
        {
             DMsg(no exit lister, 'Sorry, that command is not available in this
                game, since there\'s no exit lister. ');
            return;
        }
        
        if(cmd.verbProd.on_ != nil)
        {
            statuslineExitLister.highlightUnvisitedExits = 
                (cmd.verbProd.on_ == 'on');
            
            DMsg(exit color onoff, 'Okay, colouring of unvisited exits is now
                {1}.<.p>', cmd.verbProd.on_);
        }
        
        if(cmd.verbProd.colour_ != nil)
        {
            statuslineExitLister.unvisitedExitColour = cmd.verbProd.colour_;
            statuslineExitLister.highlightUnvisitedExits = true;
            DMsg(exit color change, 'Okay, unvisited exits in the status line
                will now be shown in {1}. ', cmd.verbProd.colour_);
        }
    }
;

DefineSystemAction(Score)
    execAction(cmd)
    {
        /* show the simple score */
        if (libGlobal.scoreObj != nil)
        {
            /* show the score */
            libGlobal.scoreObj.showScore();

            /* 
             *   Mention the FULL SCORE command to the player if we haven't
             *   already.  Note that we only want to mention 
             */
            if (!mentionedFullScore)
            {
                /* explain about it */
                gLibMessages.mentionFullScore;

                /* don't mention it again */
                Score.mentionedFullScore = true;
            }
        }
        else
            gLibMessages.scoreNotPresent;
    }
    
    mentionedFullScore = nil
;

DefineSystemAction(FullScore)
    execAction(cmd)
    {
        /* show the full score in response to an explicit player request */
        showFullScore();

        /* this counts as a mention of the FULL SCORE command */
        Score.mentionedFullScore = true;
    }

    /* show the full score */
    showFullScore()
    {
        /* show the full score */
        if (libGlobal.scoreObj != nil)
            libGlobal.scoreObj.showFullScore();
        else
            gLibMessages.scoreNotPresent;
    }
   
;

DefineSystemAction(Notify)
    execAction(cmd)
    {
        /* show the current notification status */
        if (libGlobal.scoreObj != nil)
            gLibMessages.showNotifyStatus(
                libGlobal.scoreObj.scoreNotify.isOn);
        else
            gLibMessages.commandNotPresent;
    }
;

DefineSystemAction(NotifyOn)
    execAction(cmd)
    {
        /* turn notifications on, and acknowledge the status */
        if (libGlobal.scoreObj != nil)
        {
            libGlobal.scoreObj.scoreNotify.isOn = true;
            gLibMessages.acknowledgeNotifyStatus(true);
        }
        else
            gLibMessages.commandNotPresent;
    }
;

DefineSystemAction(NotifyOff)
    execAction(cmd)
    {
        /* turn notifications off, and acknowledge the status */
        if (libGlobal.scoreObj != nil)
        {
            libGlobal.scoreObj.scoreNotify.isOn = nil;
            gLibMessages.acknowledgeNotifyStatus(nil);
        }
        else
            gLibMessages.commandNotPresent;
    }
;

DefineSystemAction(Hints)
    execAction(cmd)
    {
        if(gHintManager == nil)
            DMsg(hints not present, '<.parser>Sorry, this story doesn&rsquo;t
                have any built-in hints.<./parser> ');
        else        
            gHintManager.showHints();
        
    }
;
        

DefineSystemAction(HintsOff)
    execAction(cmd)
    {
        if(gHintManager == nil)
            DMsg(no hints to disable, '<.parser>This game doesn\'t have any
                hints to turn off. ');
        else
            gHintManager.disableHints();
    }
;


DefineIAction(Inventory)
    execAction(cmd)
    {
        /* 
         *   If splitListing is true, we potentially need to display two lists,
         *   one of what the actor is wearing and one of what the actor is
         *   carrying.
         */
        if(splitListing)
        {
            /* Construct a list of what the actor is wearing */
            local wornList = gActor.contents.subset({o: o.wornBy == gActor });
            
            /* Construst a list of what the actor is carrying */
            local carriedList = gActor.contents.subset({o: o.wornBy == nil });

            /* 
             *   If anything is being worn, get a list of it minus the final
             *   paragraph break and then display it.
             */
            if(wornList.length > 0)
            {
//                local wList = wornLister.buildList(wornList);
//                say(wList);
                
                wornLister.show(wornList, 0, nil);
                
                /* 
                 *   If nothing is being carried, terminate the list with a full
                 *   stop and a paragraph break.
                 */
                if(carriedList.length == 0)
                    ".<.p>";
                
                /*  
                 *   Otherwise prepare to append the list of what's being
                 *   carried.
                 */
                else
                    DMsg(inventory list conjunction, ', and \v');
                
            }
            /* 
             *   If something's being carried or nothing's being worn, display
             *   an inventory list of what's being carried. If nothing's being
             *   worn or carried, this will display the "You are empty-handed"
             *   message.
             */
            if(carriedList.length > 0 || wornList.length == 0)
                inventoryLister.show(carriedList, 0);
        }
        else
        {
            inventoryLister.show(gActor.contents, 0);
        }
        
        /* Mark eveything just listed as having been seen. */
        gActor.contents.forEach({x: x.noteSeen()});
    }
   
    /* Do we want separate lists of what's worn and what's carried? */
    splitListing = true
;

DefineIAction(Look)
    execAction(cmd)
    {
        gActor.outermostVisibleParent().lookAroundWithin();
    }

;

DefineIAction(Wait)
    execAction(cmd)
    {
        DMsg(wait, 'Time {dummy} {passes}. ');
    }
   
;

DefineIAction(Jump)
    execAction(cmd)
    {
        DMsg(jump, '{I} {jump} on the spot, fruitlessly. ');
    }
;

DefineIAction(Yell)
    execAction(cmd)
    {
        DMsg(yell, '{I} {shout} very loudly. ');
    }
;

DefineIAction(Smell)
    execAction(cmd)
    {
        local s_list = Q.scopeList(gActor).toList.subset(
            {x: Q.canSmell(gActor,x) && x.propDefined(&smellDesc) && 
            x.propType(&smellDesc) != TypeNil && x.isProminentSmell});
        
        local r_list = getRemoteSmellList();
        
        if(s_list.length + r_list.length == 0)
            DMsg(smell nothing, '{I} {smell} nothing out of the ordinary.<.p>');
        else
        {
            foreach(local cur in s_list)
            {
                cur.display(&smellDesc);               
            }
            
            listRemoteSmells(r_list);
        }
    }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    getRemoteSmellList() { return []; }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    listRemoteSmells(lst) { }
;


DefineIAction(Listen)
    execAction(cmd)
    {
        local s_list = Q.scopeList(gActor).toList.subset(
            {x: Q.canHear(gActor,x) && x.propType(&listenDesc) != TypeNil &&
            x.isProminentNoise});
        
        local r_list = getRemoteSoundList();
        
        if(s_list.length + r_list.length == 0)
            DMsg(hear nothing, '{I} {hear} nothing out of the ordinary.<.p>');
        else
        {
            foreach(local cur in s_list)
            {
                cur.display(&listenDesc);               
            }
            
            listRemoteSounds(r_list);
        }
    }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    getRemoteSoundList() { return []; }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    listRemoteSounds(lst) { }
;

DefineIAction(Sleep)
    execAction(cmd)
    {
        DMsg(no sleeping, 'This {dummy} {is} no time for sleeping. ');
    }
;

//
//DefaultAction: TAction
//    verDobjProp = &verDobjExamine
//    remapDobjProp = &remapDobjExamine
//    preCondDobjProp = &preCondDobjExamine
//    checkDobjProp = &checkDobjExamine
//    actionDobjProp = &actionDobjExamine
//    reportDobjProp = &reportDobjExamine
//;


GoIn: TravelAction
    direction = inDir
    predefinedDirection = true
;

GoOut: TravelAction
    direction = outDir
    predefinedDirection = true
    
    execAction(cmd)
    {
        if(!gActor.location.ofKind(Room))
            replaceAction(GetOff, gActor.location);
        else
        {
            "<<buildImplicitActionAnnouncement(true)>>";
            doTravel();
        }
    }
;

DefineIAction(GetOut)
    execAction(cmd)
    {        
        GoOut.execAction(cmd);
    }
;

/* 
 *   We'll take STAND to be a request to get out of the actor's immediate
 *   container, unless the actor is directly in a room in which case we'll
 *   simply say that he is standing.
 */

DefineIAction(Stand)
    execAction(cmd)
    {
        if(!gActor.location.ofKind(Room))
            replaceAction(GetOff, gActor.location);
        else
        {
            DMsg(already standing, '{I} {am} standing. ');
        }
        
    }
;


DefineIAction(Sit)
    execAction(cmd)
    {
        /* 
         *   We'll take SIT to be a request to sit in or on any suitable object
         *   in scope
         */
        
        /*  
         *   So, if the actor is already in an enclosing object that's not a
         *   room, simply say so and end the action.
         */
        local loc = gActor.location;
        if(!loc.ofKind(Room))
        {
            gMessageParams(loc);
            DMsg(already seated, '{I}{\'m} sitting {in loc}.  ');
            return;
        }
        
        buildScopeList;
//        local obj = scopeList.valWhich({o: (o.isBoardable || o.isEnterable) 
//                                          && Q.canReach(gActor, o)});
        
        /* 
         *   Rather complex experimental code to find the best object in scope
         *   to sit in or on.
         */
        
        local matchList = scopeList.subset({o: Q.canReach(gActor, o)});
        matchList = wrapObjectsNP(matchList);
        
        local sitOnMatches = matchList.subset({o: o.obj.isBoardable}); 
        local sitInMatches = matchList.subset({o: o.obj.isEnterable});
        
        if(sitOnMatches.length > 0)
        {
            cmd.action = SitOn;
            SitOn.scoreObjects(cmd, DirectObject, sitOnMatches);
            sitOnMatches = sitOnMatches.sort(SortDesc, {a, b: a.score - b.score});
        }
        
        if(sitInMatches.length > 0)
        {
            cmd.action = SitIn;
            SitIn.scoreObjects(cmd, DirectObject, sitInMatches);            
            sitInMatches = sitInMatches.sort(SortDesc, {a, b: a.score - b.score});
        }
        
        local obj = nil;
        
        if(sitOnMatches.length > 0 && sitOnMatches[1].obj.isBoardable)
            obj = sitOnMatches[1].obj;
        
        if(sitInMatches.length > 0 && sitInMatches[1].obj.isEnterable
           && (obj == nil || sitOnMatches.length == 0 || sitInMatches[1].score >
               sitOnMatches[1].score))
            obj = sitInMatches[1].obj;
        
        if(obj == nil)
            DMsg(nowhere to sit, 'There{dummy}{\'s} nothing suitable to sit on
                {here}. ');
        else
        {
            gMessageParams(obj);
            DMsg(announce sit object, '({in obj})\n');
            if(obj.isBoardable)
                replaceAction(SitOn, obj);
            else
                replaceAction(SitIn, obj);
        }
        
    }
;


Travel: TravelAction
    direction = (dirMatch.dir)
;

DefineIAction(VagueTravel)
    execAction(cmd)
    {
        DMsg(vague travel, '{I} {need} to be more specific about where {i}
            want to go. ');
    }
;


DefineIAction(GoBack)
    execAction(cmd)
    {
        local pathBack = nil;
        
        if(libGlobal.lastLoc == nil)
        {
            DMsg(nowhere back, '{I} {have} nowhere to go back to. ');
            return;            
        }
        
        pathBack = defined(routeFinder) ? 
             routeFinder.findPath(gActor.getOutermostRoom,
                libGlobal.lastLoc) : nil;
               
        
        if(pathBack == nil)
        {
            DMsg(no way back, 'There{dummy}{\'s} no way back. ');
            return;
        }
        
        if(pathBack.length == 1)
        {
            DMsg(already there, '{I}{\'m} already there. ');
            return;
        }
        
        local dir = pathBack[2][1];
        
        DMsg(going dir, '(going {1})\n', dir.name);
        
        gActor.getOutermostRoom.(dir.dirProp).travelVia(gActor);
        
    }
;

DefineTAction(GoTo)
    
    /* Add all known items to scope */
    addExtraScopeItems(whichRole?)
    {
       scopeList = scopeList.appendUnique(Q.knownScopeList);
    }
;

DefineIAction(Continue)
    execAction(cmd)
    {
        local path;
        path = defined(pcRouteFinder) ? pcRouteFinder.cachedRoute : nil;
        if(path == nil)
        {
            DMsg(no journey, '{I}{\'m} not going anywhere. ');
        }
        
        local idx = path.indexWhich({x: x[2] == gActor.getOutermostRoom});
        
        if(idx == nil)
        {
            path = defined(pcRouteFinder) ?
                pcRouteFinder.findPath(gActor.getOutermostRoom,
                                       pcRouteFinder.currentDestination) : nil;
            
            if(path == nil)
            {
                DMsg(off route, '{I}{\'m} no longer on {my} route. Use the GO TO
                    command to set up a new route. ');
                return;
            }
            else
                idx = 1;                
        }
        
        if(idx == path.length)
        {
            DMsg(already there, '{I}{\'m} already there. ');
            return;
        }
        
        local dir = path[idx + 1][1];
        
        takeStep(dir, path[path.length][2]);
        
        
    }
    
    takeStep(dir, dest)
    {
        DMsg(going dir, '(going {1})\n', dir.name);
        
        gActor.getOutermostRoom.(dir.dirProp).travelVia(gActor);
        
        if(!gActor.isIn(dest))
        {
            local contMsg = BMsg(explain continue, 'To continue the journey
                use the command
                <<aHref('Continue','CONTINUE','Continue')>> or C. ');
            htmlSay(contMsg);
        }
    }
    
;

DefineSystemAction(Topics)
    execAction(cmd)
    {
        local otherActor = gPlayerChar.currentInterlocutor;
        
        if(otherActor == nil)
            DMsg(no interlocutor, '{I}{\'m} not talking to anyone. ');
        else
        {            
            otherActor.showSuggestions(true, otherActor.suggestionKey);
        }
    }
    
    afterAction() {}
;
    

DefineTAction(Examine)
    announceMultiAction = true
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }

;

/* 
 *   The ExamineOrGoTo action is used as the default action by the Parser; it is
 *   not an action the player can directly command. If the player enters a room
 *   (and nothing else) on the command line, and the room is known to the player
 *   character, and the player character is not already in the room, the command
 *   will be treated as a GoTo action; otherwise it will be treated as an
 *   Examine action.
 */
   
DefineTAction(ExamineOrGoTo)
    exec(cmd)
    {
        local obj = cmd.dobj;
        if(defined(pcRouteFinder) && obj.ofKind(Room) && !cmd.actor.isIn(obj))        
            cmd.action = GoTo;
        else
            cmd.action = Examine;
        
        gAction = cmd.action;
        gAction.reset();
        gAction.exec(cmd);     
    }
    
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(Q.knownScopeList.subset({x:
            x.ofKind(Room)}));
    }
;

DefineTAction(Follow)
;


DefineTAction(Read)
    announceMultiAction = true
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }

;

DefineTAction(SmellSomething)
    announceMultiAction = true
    
;

DefineTAction(ListenTo)
    announceMultAction = true
;

DefineTAction(Taste)
    announceMultiAction = true
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }
;

DefineTAction(Feel)
    announceMultiAction = true
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }
;

DefineTAction(Take)
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.isDirectlyIn(cmd.actor) && !x.isFixed});
    }
    
    
    announceMultiAction = nil
    allowAll = true
;

DefineTAction(Drop)
   
    announceMultiAction = nil    
    allowAll = true
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.isDirectlyIn(cmd.actor) && !x.isFixed});
    }
   
;

DefineTAction(Throw)
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.isFixed});
    }
;


DefineTAction(Attack)
;

DefineTAction(Strike)
;

DefineTAction(Open)   
;

DefineTAction(Close)    
;

DefineTAction(LookIn)   
;

DefineTAction(LookUnder)    
;

DefineTAction(LookBehind)
;

DefineTAction(LookThrough)
;

DefineTAction(Unlock)
;

DefineTAction(Lock)    
;

DefineTAction(SwitchOn)    
;

DefineTAction(SwitchOff)    
;

DefineTAction(Turn)    
;

DefineTAction(Wear)   
;

DefineTAction(Doff)    
    allowAll = true
;

DefineTAction(Break)
;

DefineTAction(Climb)    
;

DefineTAction(ClimbUp)    
;

DefineTAction(ClimbDown)    
;

DefineTAction(Board)    
;

DefineTAction(StandOn)
;

DefineTAction(SitOn)
;

DefineTAction(LieOn)
;


DefineTAction(StandIn)
;

DefineTAction(SitIn)
;

DefineTAction(LieIn)
;

DefineTAction(Enter)
;

DefineTAction(GetOff)    
;

DefineTAction(GetOutOf)
;
    
DefineTAction(GoThrough)
;

DefineTAction(Push)
;

DefineTAction(Pull)
;

DefineTAction(Search)
;

DefineTAction(Remove)
;

DefineTAction(Move)
;
    
DefineTAction(Light)
;

DefineTAction(Extinguish)
;

DefineTAction(Eat)
;

DefineTAction(Drink)
;

DefineTAction(Clean)
;

DefineTAction(Dig)
;

DefineTAction(Kiss)
;

DefineTAction(Detach)
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.attachedTo != nil});
    }
;

DefineTIAction(DigWith)
    resolveIobjFirst = nil
;

DefineTIAction(CleanWith)
    resolveIobjFirst = nil
;

DefineTIAction(MoveTo)
    resolveIobjFirst = nil
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.isMoveable});
    }
;

DefineTIAction(MoveWith)
    resolveIobjFirst = nil
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.isMoveable});
    }
    
;

DefineTIAction(PutOn)   
        
    announceMultiAction = nil
    allowAll = true
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.isFixed
                                && (curIobj == nil || (!x.isIn(iobj)))});
    }
;


DefineTIAction(PutIn)      
    announceMultiAction = nil
    allowAll = true
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.isFixed
                                && (curIobj == nil || (!x.isIn(iobj)))});
    }
        
; 

DefineTIAction(PutUnder)     
    announceMultiAction = nil
    allowAll = true
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.isFixed
                                && (curIobj == nil || (!x.isIn(iobj)))});
    }
;

DefineTIAction(PutBehind)  
    nnounceMultiAction = nil
    allowAll = true
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.isFixed
                                && (curIobj == nil || (!x.isIn(curIobj)))});
    }
;



DefineTIAction(UnlockWith)    
    resolveIobjFirst = nil
;

DefineTIAction(LockWith)   
    resolveIobjFirst = nil
;

DefineTIAction(AttachTo)
    resolveIobjFirst = nil
;

DefineTIAction(DetachFrom)
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.attachedTo == curIobj});
    }
;

DefineTIAction(FastenTo)  
    resolveIobjFirst = nil
;

DefineTIAction(TurnWith)
    resolveIobjFirst = nil
;

DefineTIAction(CutWith)
    resolveIobjFirst = nil
;

DefineTIAction(TakeFrom)
    
    /* 
     *   If the command matched ALL filter out dobjs that aren't in the iobj by
     *   not executing the command for them.
     */
    
    exec(cmd)
    {
        if(!cmd.matchedAll || cmd.iobj.notionalContents.indexOf(cmd.dobj) != nil)
            inherited(cmd);
        
        /* Otherwise note the current dobj in any case */
        else 
            curDobj = cmd.dobj;
    }
    
    reportAction()
    {
        if(reportList.length > 0)
            inherited;
        
        /* 
         *   If the player tried to TAKE ALL FRMO IOBJ and there was nothing to
         *   take we need to report this
         */
        else if(gCommand.matchedAll)
            DMsg(nothing to take, 'There{dummy}{\'s} nothing available to
                    take from {1}. ', gCommand.iobj.theName);
    }
    
    getAll(cmd, role)
    {        
        return scopeList.subset({ x: !x.isFixed});
    }
    
    allowAll = true
    
    
;

DefineTIAction(ThrowAt)
    resolveIobjFirst = nil
;

DefineTIAction(ThrowTo)
    resolveIobjFirst = nil
;

DefineTIAction(AttackWith)
    resolveIobjFirst = nil
;

DefineTAction(ThrowDir)
    execAction(cmd)
    {
        direction = cmd.verbProd.dirMatch.dir;
        inherited(cmd);
    }
    
    direction = nil
;

DefineIAction(JumpOffIntransitive)
    execAction(cmd)
    {
        if(gActor.location.contType == On)
            replaceAction(JumpOff, gActor.location);
        else
            DMsg(not on anything, '{I}{\'m} not on anything. ');
    }
;

DefineTAction(JumpOff)
;

DefineTAction(JumpOver)
;


DefineLiteralTAction(TurnTo)
;

DefineLiteralTAction(SetTo)
;

DefineTAction(Set)
;

DefineTAction(TypeOnVague)
;

DefineLiteralTAction(TypeOn)
;

DefineLiteralTAction(EnterOn)
;

DefineLiteralTAction(WriteOn)
;

DefineTopicTAction(ConsultAbout)
;

DefineTAction(SwitchVague)
;

DefineTAction(Flip)
;

DefineTAction(Fasten)
;


DefineTAction(Burn)
;

DefineTIAction(BurnWith)
    resolveIobjFirst = nil
;

DefineTAction(Pour)
;

DefineTIAction(PourOnto)
    resolveIobjFirst = nil
;

DefineTIAction(PourInto)
    resolveIobjFirst = nil
;

DefineTAction(Screw)
;

DefineTIAction(ScrewWith)
    resolveIobjFirst = nil
;
    
DefineTAction(Unscrew)
;

DefineTIAction(UnscrewWith)
    resolveIobjFirst = nil
;

DefineTAction(Unfasten)
;

DefineTIAction(UnfastenFrom)
;

DefineTAction(PushTravelDir)
    execAction(cmd)
    {
        travelAllowed = nil;
        direction = cmd.verbProd.dirMatch.dir;
        inherited(cmd);
        if(travelAllowed)
        {
           local oldLoc = gActor.getOutermostRoom; 
           if(oldLoc.propType(direction.dirProp) == TypeObject)
           {
                local conn = oldLoc.(direction.dirProp);
                if(!conn.canTravelerPass(curDobj))
                {
                    explainTravelBarrier(curDobj);
                    return;
                }
            
           }
           delegated TravelAction(cmd);
           if(oldLoc != gActor.getOutermostRoom)
           {
                curDobj.moveInto(gActor.getOutermostRoom);
                DMsg(push travel, '{I} {push} {the dobj} into {1}. ',
                     gActor.getOutermostRoom.name != nil ?
                     gActor.getOutermostRoom.theName : 'the area');
           }
        }
    }
    
    travelAllowed = nil
    direction = nil
;


DefineTAction(TalkTo)
;

class MiscConvAction: IAction
    execAction(cmd)
    {
        if(gPlayerChar.currentInterlocutor == nil 
           || !Q.canTalkTo(gPlayerChar, gPlayerChar.currentInterlocutor))
             DMsg(not talking, '{I}{\'m} not talking to anyone. ');
        else
        {           
            curObj = gPlayerChar.currentInterlocutor;
            gPlayerChar.currentInterlocutor.handleTopic(responseProp, 
                [topicObj]);
        }
            
    }
    curObj = nil
    
    getMessageParam(objName)
    {
        switch(objName)
        {
        case 'dobj':
            /* return the current direct object */
            return curObj;
            
        case 'cobj':
            /* return the current object */
            return curObj;

        default:
            /* inherit default handling */
            return inherited(objName);
        }
    }
    
    responseProp = nil
    topicObj = nil
;

SayYes: MiscConvAction
    baseActionClass = SayYes
    responseProp = &miscTopics
    topicObj = yesTopicObj
;

SayNo: MiscConvAction
    baseActionClass = SayNo
    responseProp = &miscTopics
    topicObj = noTopicObj
;

QueryVague: MiscConvAction
    baseActionClass = QueryVague
    execAction(cmd)
    {
        qType = cmd.verbProd.qtype;
        inherited(cmd);
    }
    
    qType = nil
    responseProp = &queryTopics
;

Goodbye: IAction
    baseActionClass = Goodbye
    
    execAction(cmd)
    {
        curObj = gPlayerChar.currentInterlocutor;
    
        if(gPlayerChar.currentInterlocutor == nil ||
           !Q.canTalkTo(gPlayerChar, gPlayerChar.currentInterlocutor))	
             DMsg(not talking, '{I}{\'m} not talking to anyone. ');
        else
            gPlayerChar.currentInterlocutor.endConversation(endConvBye);
    }    
    
    curObj = nil
    
    
;

Hello: IAction
    baseActionClass = Hello
    
    execAction(cmd)
    {
        /* first build the scope list so we know which actors are in scope */
        buildScopeList();
        
        /* 
         *   if the pc isn't already talking to someone then this is an attempt
         *   to engage a new interlocutor in conversation.
         */
        if(gPlayerChar.currentInterlocutor == nil)
        {
            /* 
             *   Ascertain how many actors other than the player char are in
             *   scope (and thus potentially greetable.
             */

            local greetList = scopeList.subset(
                    { x: x.ofKind(Actor) && x != gPlayerChar });
            
            local greetCount = greetList.length;
            
            /* If there are no other actors in scope, say so. */            
            if(greetCount == 0)
            {
                DMsg(no one here, 'There{dummy}{\'s} no one {here} to talk to.
                    ');
            }
            /* 
             *   Otherwise construct a list of all the actors in scope and greet
             *   all of them (rather than asking the player to disambiguate -
             *   after all the pc may have just said 'hello' to a room full of
             *   people and there's no reason why they shouldn't all respond).
             */
            else
            {               
                foreach(local greeted in greetList)
                {
                    curObj = greeted;
                    greeted.sayHello();
                }
            }
        }
        /* 
         *   If the player char is currently talking to someone, say so and
         *   carry out a repeat greeting.
         */
        else
        {
            DMsg(already talking, '{I}{\'m} already talking to {1}. ',
                 gPlayerChar.currentInterlocutor.theName);
            
            gPlayerChar.currentInterlocutor.sayHello();
        }
    }
    
    curObj = nil
    
    
;

DefineLiteralTAction(TellTo)
    exec(cmd)
    {
        /* 
         *   Take a command of the form of TELL FOO TO BAR, turn it into FOO,
         *   BAR and then send it back to parser to execute
         */
        local str = cmd.dobj.theName + ', ' + cmd.iobj.name;
        Parser.parse(str);
    }
    afterAction() {}
;


DefineTopicTAction(AskAbout)
;

DefineTopicTAction(AskFor)
;

DefineTopicTAction(TellAbout)
;

DefineTopicTAction(TalkAbout)
;

DefineTopicTAction(QueryAbout)
    execAction(cmd)
    {
        qType = cmd.verbProd.qtype;

        inherited(cmd);
    }
    qType = nil
    
    #ifdef __DEBUG    
    iqinfo = (gCommand.verbProd.qtype)
    #endif
    
;

DefineTopicTAction(SayTo)
;

DefineTIAction(GiveTo)
    giveReport = nil
    
    execAction(cmd)
    {
        giveReport = nil;
        inherited(cmd);
    }
;

DefineTIAction(ShowTo)
    giveReport = nil
    
    execAction(cmd)
    {
        giveReport = nil;
        inherited(cmd);
    }
;

ThinkAbout: TopicAction
    baseActionClass = ThinkAbout
    
    execAction(cmd)
    {
        if(libGlobal.thoughtManagerObj != nil)
            libGlobal.thoughtManagerObj.handleTopic(cmd.dobj.topicList);
        else
            Think.execAction(cmd);
    }
;

DefineIAction(Think)
    execAction(cmd)
    {
        DMsg(think, '{I} {think}, therefore {i} {am}. ');
    }
;

class ImplicitConversationAction: TopicAction
    execAction(cmd)
    {
        if(cmd.iobj == nil && cmd.dobj != nil)
        {
            if(cmd.dobj.ofKind(ResolvedTopic))
                topics = cmd.dobj.topicList;
            else
                topics = cmd.dobj;
        }
        else if (cmd.dobj == nil && cmd.iobj != nil)
        {
            if(cmd.iobj.ofKind(ResolvedTopic))
                topics = cmd.iobj.topicList;
            else
                topics = cmd.iobj;
        }
        
        if(gPlayerChar.currentInterlocutor == nil ||
           !Q.canTalkTo(gPlayerChar, gPlayerChar.currentInterlocutor))	
            DMsg(not talking, '{I}{\'m} not talking to anyone. ');
        else
        {
            resolvePronouns();
            curObj = gPlayerChar.currentInterlocutor;
            gPlayerChar.currentInterlocutor.handleTopic(topicListProperty, 
                topics);
        }
    }
    
    /* 
     *   This is a bit of a kludge to deal with the fact that the Parser doesn't
     *   seem able to resolve pronouns within ResolvedTopics. We do it here
     *   instead.
     */
    
    resolvePronouns()
    {
        local actor = gPlayerChar.currentInterlocutor;
        for(local cur in topics, local i = 1;; ++i)
        {
            if(cur == Him && actor.isHim)
                topics[i] = actor;
            
            if(cur == Her && actor.isHer)
                topics[i] = actor;
            
            if(cur == It && actor.isIt)
                topics[i] = actor;
        }
    }
    
    
    topicListProperty = nil
    topics = nil
;

//DefineTopicAction(AskAboutImplicit)
//    execAction(cmd)
//    {
//        if(gPlayerChar.currentInterlocutor == nil)
//            DMsg(not talking, '{I}{\'m} not talking to anyone. ');
//        else
//            gPlayerChar.currentInterlocutor.handleTopic(&askTopics, 
//                cmd.iobj.topicList);;
//    }
//;
        
AskAboutImplicit: ImplicitConversationAction
    baseActionClass = AskAboutImplicit
    topicListProperty = &askTopics
;

TellAboutImplicit: ImplicitConversationAction
    baseActionClass = TellAboutImplicit
    topicListProperty = &tellTopics
;

TalkAboutImplicit: ImplicitConversationAction
    baseActionClass = TalkAboutImplicit
    topicListProperty = &talkTopics
;

Query: ImplicitConversationAction
    baseActionClass = Query
    execAction(cmd)
    {
        qType = cmd.verbProd.qtype;
//        "<q><<cmd.verbProd.qtype>> <<cmd.dobj.topicList[1].name>></q>";
        inherited(cmd);
    }
    qType = nil
    topicListProperty = &queryTopics
    
    #ifdef __DEBUG
    dqinfo = (gCommand.verbProd.qtype)
    #endif
;

SayAction: ImplicitConversationAction
    baseActionClass = SayAction
    topicListProperty = &sayTopics
;



//DefineTopicAction(SayAction)
//    execAction(cmd)
//    {
//        "<q><<cmd.dobj.topicList[1].name>></q>";
//    }
//;
//

/*
 *   A state object that keeps track of our logging (scripting) status.
 *   This is transient, because logging is controlled through the output
 *   layer in the interpreter, which does not participate in any of the
 *   persistence mechanisms.  
 */
transient scriptStatus: object
    /*
     *   Script file name.  This is nil when logging is not in effect, and
     *   is set to the name of the scripting file when a log file is
     *   active. 
     */
    scriptFile = nil

    /* RECORD file name */
    recordFile = nil

    /* have we warned about using NOTE without logging in effect? */
    noteWithoutScriptWarning = nil
;



/* 
 *   Property: object is a web temp file.  The Web UI uses this to flag
 *   that a file we're saving to is actually a temp file that will be
 *   offered as a downloadable file to the client after the file is written
 *   and closed. 
 */
property isWebTempFile;

/*
 *   A base class for file-oriented actions, such as SCRIPT, RECORD, and
 *   REPLAY.  We provide common handling that prompts interactively for a
 *   filename; subclasses must override a few methods and properties to
 *   carry out the specific subclassed operation on the file.  
 */
class FileOpAction: SystemAction
    /* our file dialog prompt message */
    filePromptMsg = ''

    /* the file dialog open/save type */
    fileDisposition = InFileSave

    /* the file dialog type ID */
    fileTypeID = FileTypeLog

    /* show our cancellation mesage */
    showCancelMsg = ""

    /* 
     *   Carry out our file operation.
     *   
     *   'desc' is an optional named argument giving a description string
     *   entered by the user via the Save Game dialog.  Some versions of
     *   the Save Game dialog let the user enter this additional
     *   information, which can be stored as part of the saved game
     *   metadata.  
     */
    performFileOp(fname, ack, desc:?)
    {
        /* 
         *   Each concrete action subclass must override this to carry out
         *   our operation.  This is called when the user has successfully
         *   selected a filename for the operation.  
         */
    }

    execAction(cmd)
    {
        /* 
         *   ask for a file and carry out our action; since the command is
         *   being performed directly from the command line, we want an
         *   acknowledgment message on success 
         */
        setUpFileOp(true);
    }

    /* ask for a file, and carry out our operation is we get one */
    setUpFileOp(ack)
    {
        local result;
//        local origElapsedTime;

        /* ask for a file */
        result = getInputFile(filePromptMsg, fileDisposition, fileTypeID, 0);

        /* check the inputFile result */
        switch(result[1])
        {
        case InFileSuccess:
            /* carry out our file operation */
            if (result.length >= 3)
                performFileOp(result[2], ack, desc:result[3]);
            else
                performFileOp(result[2], ack);
            break;

        case InFileFailure:
            /* advise of the failure of the prompt */
            if (result.length() > 1)
                gLibMessages.filePromptFailedMsg(result[2]);
            else
                gLibMessages.filePromptFailed();
            break;

        case InFileCancel:
            /* acknowledge the cancellation */
            showCancelMsg();
            break;
        }

        
    }

    /* we can't include this in undo, as it affects external files */
    includeInUndo = nil

    /* don't allow repeating with AGAIN */
    isRepeatable = nil
;

/*
 *   Turn scripting on.  This creates a text file that contains a
 *   transcript of all commands and responses from this point forward.
 */
DefineAction(ScriptOn, FileOpAction)
    /* our file dialog parameters - ask for a log file to save */
    filePromptMsg = (gLibMessages.getScriptingPrompt())
    fileTypeID = FileTypeLog
    fileDisposition = InFileSave

    /* show our cancellation mesasge */
    showCancelMsg() { gLibMessages.scriptingCanceled(); }

    /* 
     *   set up scripting - this can be used to set up scripting
     *   programmatically, in the course of carrying out another action 
     */
    setUpScripting(ack) { setUpFileOp(ack); }

    /* turn on scripting to the given file */
    performFileOp(fname, ack)
    {
        /* turn on logging */
        local ok = nil, exc = nil;
        try
        {
            ok = aioSetLogFile(fname, LogTypeTranscript);
        }
        catch (Exception e)
        {
            exc = e;
        }
        if (ok)
        {
            /* remember that scripting is in effect */
            scriptStatus.scriptFile = fname;

            /* 
             *   forget any past warning that we've issued about NOTE
             *   without a script in effect; the next time scripting isn't
             *   active, we'll want to issue a new warning, since they
             *   might not be aware at that point that the scripting we're
             *   starting now has ended 
             */
            scriptStatus.noteWithoutScriptWarning = nil;

            /* note that logging is active, if acknowledgment is desired */
            if (ack)
            {
                if (fname.isWebTempFile)
                    gLibMessages.scriptingOkayWebTemp();
                else
                    gLibMessages.scriptingOkay();
            }
        }
        else
        {
            /* scripting is no longer in effect */
            scriptStatus.scriptFile = nil;

            /* show an error, if acknowledgment is desired */
            if (ack)
            {
                if (exc != nil)
                    gLibMessages.scriptingFailedException(exc);
                else
                    gLibMessages.scriptingFailed;
            }
        }
    }
;

/*
 *   Subclass of Script action taking a quoted string as part of the
 *   command syntax.  The grammar rule must set our fname_ property to a
 *   quotedStringPhrase subproduction. 
 */
DefineAction(ScriptString, ScriptOn)
    execAction(cmd)
    {
        /* if there's a filename, we don't need to prompt */
        if (fname_ != nil)
        {
            /* set up scripting to the filename specified in the command */
            performFileOp(fname_.getStringText(), true);
        }
        else
        {
            /* there's no filename, so prompt as usual */
            inherited();
        }
    }
;

/*
 *   Turn scripting off.  This stops recording the game transcript started
 *   with the most recent SCRIPT command. 
 */
DefineSystemAction(ScriptOff)
    execAction(cmd)
    {
        /* turn off scripting */
        turnOffScripting(true);
    }

    /* turn off scripting */
    turnOffScripting(ack)
    {
        /* if we're not in a script file, ignore it */
        if (scriptStatus.scriptFile == nil)
        {
            gLibMessages.scriptOffIgnored();
            return;
        }

        /* cancel scripting in the interpreter's output layer */
        aioSetLogFile(nil, LogTypeTranscript);

        /* remember that scripting is no longer in effect */
        scriptStatus.scriptFile = nil;

        /* acknowledge the change, if desired */
        if (ack)
            gLibMessages.scriptOffOkay();
    }

    /* we can't include this in undo, as it affects external files */
    includeInUndo = nil
;

/*
 *   RECORD - this is similar to SCRIPT, but stores a file containing only
 *   the command input, not the output. 
 */
DefineAction(Record, FileOpAction)
    /* our file dialog parameters - ask for a log file to save */
    filePromptMsg = (gLibMessages.getRecordingPrompt())
    fileTypeID = FileTypeCmd
    fileDisposition = InFileSave

    /* show our cancellation mesasge */
    showCancelMsg() { gLibMessages.recordingCanceled(); }

    /* 
     *   set up recording - this can be used to set up scripting
     *   programmatically, in the course of carrying out another action 
     */
    setUpRecording(ack) { setUpFileOp(ack); }

    /* turn on recording to the given file */
    performFileOp(fname, ack)
    {
        /* turn on command logging */
        local ok = nil, exc = nil;
        try
        {
            ok = aioSetLogFile(fname, logFileType);
        }
        catch (Exception e)
        {
            exc = e;
        }
        if (ok)
        {
            /* remember that recording is in effect */
            scriptStatus.recordFile = fname;

            /* note that logging is active, if acknowledgment is desired */
            if (ack)
                gLibMessages.recordingOkay();
        }
        else
        {
            /* recording failed */
            scriptStatus.recordFile = nil;

            /* show an error if acknowledgment is desired */
            if (ack)
            {
                if (exc != nil)
                    gLibMessages.recordingFailedException(exc);
                else
                    gLibMessages.recordingFailed();
            }
        }
    }

    /* the log file type - by default, we open a regular command log */
    logFileType = LogTypeCommand
;

/* subclass of Record action that sets up an event script recording */
DefineAction(RecordEvents, Record)
    logFileType = LogTypeScript
;

/* subclass of Record action taking a quoted string for the filename */
DefineAction(RecordString, Record)
    execAction(cmd)
    {
        /* set up scripting to the filename specified in the command */
        performFileOp(fname_.getStringText(), true);
    }
;

/* subclass of RecordString action that sets up an event script recording */
DefineAction(RecordEventsString, RecordString)
    logFileType = LogTypeScript
;

/*
 *   Turn command recording off.  This stops recording the command log
 *   started with the most recent RECORD command.  
 */
DefineSystemAction(RecordOff)
    execAction(cmd)
    {
        /* turn off recording */
        turnOffRecording(true);
    }

    /* turn off recording */
    turnOffRecording(ack)
    {
        /* if we're not recording anything, ignore it */
        if (scriptStatus.recordFile == nil)
        {
            gLibMessages.recordOffIgnored();
            return;
        }

        /* cancel recording in the interpreter's output layer */
        aioSetLogFile(nil, LogTypeCommand);

        /* remember that recording is no longer in effect */
        scriptStatus.recordFile = nil;

        /* acknowledge the change, if desired */
        if (ack)
            gLibMessages.recordOffOkay();
    }

    /* we can't include this in undo, as it affects external files */
    includeInUndo = nil
;

/*
 *   REPLAY - play back a command log previously recorded. 
 */
DefineAction(Replay, FileOpAction)
    /* our file dialog parameters - ask for a log file to save */
    filePromptMsg = (gLibMessages.getReplayPrompt())
    fileTypeID = FileTypeCmd
    fileDisposition = InFileOpen

    /* show our cancellation mesasge */
    showCancelMsg() { gLibMessages.replayCanceled(); }

    /* script flags passed to setScriptFile */
    scriptOptionFlags = 0

    /* replay the given file */
    performFileOp(fname, ack)
    {
        /* 
         *   Note that we're reading from the script file if desired.  Do
         *   this before opening the script, so that we display the
         *   acknowledgment even if we're in 'quiet' mode. 
         */
        if (ack)
            gLibMessages.inputScriptOkay(
                fname.ofKind(TemporaryFile) ? fname.getFilename() : fname);

        /* activate the script file */
        local ok = nil, exc = nil;
        try
        {
            ok = setScriptFile(fname, scriptOptionFlags);
        }
        catch (Exception e)
        {
            exc = e;
        }
        if (!ok)
        {
            if (exc != nil)
                gLibMessages.inputScriptFailed(exc);
            else
                gLibMessages.inputScriptFailed();
        }
    }
;

/* subclass of Replay action taking a quoted string for the filename */
DefineAction(ReplayString, Replay)
    execAction(cmd)
    {
        /* 
         *   if there's a string, use the string as the filename;
         *   otherwise, inherit the default handling to ask for a filename 
         */
        if (fname_ != nil)
        {
            /* set up scripting to the filename specified in the command */
            performFileOp(fname_.getStringText(), true);
        }
        else
        {
            /* inherit the default handling to ask for a filename */
            inherited();
        }
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   Special "save" action.  This command saves the current game state to
 *   an external file for later restoration. 
 */
DefineAction(Save, FileOpAction)
    /* the file dialog prompt */
    filePromptMsg = (gLibMessages.getSavePrompt())

    /* we're asking for a file to save, or type t3-save */
    fileDisposition = InFileSave
    fileTypeID = FileTypeT3Save

    /* cancel message */
    showCancelMsg() { gLibMessages.saveCanceled(); }
    
    /* perform a save */
    performFileOp(fname, ack, desc:?)
    {
        /* before saving the game, notify all PreSaveObject instances */
        PreSaveObject.classExec();
        
        /* 
         *   Save the game to the given file.  If an error occurs, the
         *   save routine will throw a runtime error.  
         */
        try
        {
            /* try saving the game */
            saveGame(fname, gameMain.getSaveDesc(desc));
        }
        catch (StorageServerError sse)
        {
            /* the save failed due to a storage server problem - explain */
            gLibMessages.saveFailedOnServer(sse);

            /* done */
            return;
        }
        catch (RuntimeError err)
        {
            /* the save failed - mention the problem */
            gLibMessages.saveFailed(err);
            
            /* done */
            return;
        }
        
        /* note the successful save */
        gLibMessages.saveOkay();
    }

    /* 
     *   Saving has no effect on game state, so it's irrelevant whether or
     *   not it's undoable; but it might be confusing to say we undid a
     *   "save" command, because the player might think we deleted the
     *   saved file.  To avoid such confusion, do not include "save"
     *   commands in the undo log.  
     */
    includeInUndo = nil

    /* 
     *   Don't allow this to be repeated with AGAIN.  There's no point in
     *   repeating a SAVE immediately, as nothing will have changed in the
     *   game state to warrant saving again.  
     */
    isRepeatable = nil
;

/*
 *   Subclass of Save action that takes a literal string as part of the
 *   command.  The filename must be a literal enclosed in quotes, and the
 *   string (with the quotes) must be stored in our fname_ property by
 *   assignment of a quotedStringPhrase production in the grammar rule.  
 */
DefineAction(SaveString, Save)
    execAction(cmd)
    {
        /* 
         *   Perform the save, using the filename given in our fname_
         *   parameter, trimmed of quotes.  
         */
        performFileOp(fname_.getStringText(), true);
    }
;

DefineSystemAction(Restore)
    execAction(cmd)
    {
        /* ask for a file and restore it */
        askAndRestore();

        /* 
         *   regardless of what happened, abandon any additional commands
         *   on the same command line 
         */
        throw new TerminateCommandException();
    }

    /*
     *   Ask for a file and try to restore it.  Returns true on success,
     *   nil on failure.  (Failure could indicate that the user chose to
     *   cancel out of the file selector, that we couldn't find the file to
     *   restore, or that the file isn't a valid saved state file.  In any
     *   case, we show an appropriate message on failure.)  
     */
    askAndRestore()
    {
        local succ;        
        local result;
//        local origElapsedTime;

        /* presume failure */
        succ = nil;

        /* note the current elapsed game time */
//        origElapsedTime = realTimeManager.getElapsedTime();

        /* ask for a file */
        result = getInputFile(gLibMessages.getRestorePrompt(), InFileOpen,
                              FileTypeT3Save, 0);

        /* 
         *   restore the real-time clock, so that the time spent in the
         *   file selector dialog doesn't count against the game time 
         */
//        realTimeManager.setElapsedTime(origElapsedTime);

        /* check the inputFile response */
        switch(result[1])
        {
        case InFileSuccess:
            /* 
             *   try restoring the file; use code 2 to indicate that the
             *   restoration was performed by an explicit RESTORE command 
             */
            if (performRestore(result[2], 2))
            {
                /* note that we succeeded */
                succ = true;
            }
            else
            {
                /* 
                 *   failed - in case the failed restore took some time,
                 *   restore the real-time clock, so that the file-reading
                 *   time doesn't count against the game time 
                 */
//                realTimeManager.setElapsedTime(origElapsedTime);
            }

            /* done */
            break;

        case InFileFailure:
            /* advise of the failure of the prompt */
            if (result.length() > 1)
                gLibMessages.filePromptFailedMsg(result[2]);
            else
                gLibMessages.filePromptFailed();
            break;

        case InFileCancel:
            /* acknowledge the cancellation */
            gLibMessages.restoreCanceled();
            break;
        }

        /* 
         *   If we were successful, clear out the AGAIN memory.  This
         *   avoids any confusion about whether we're repeating the RESTORE
         *   command itself, the command just before RESTORE from the
         *   current session, or the last command before SAVE from the
         *   restored game. 
         */
        if (succ)
            Again.clearForAgain();

        /* return the success/failure indication */
        return succ;
    }

    /*
     *   Restore a game on startup.  This can be called from mainRestore()
     *   to restore a saved game directly as part of loading the game.
     *   (Most interpreters provide a way of starting the interpreter
     *   directly with a saved game to be restored, skipping the
     *   intermediate step of running the game and using a RESTORE
     *   command.)
     *   
     *   Returns true on success, nil on failure.  On failure, the caller
     *   should simply exit the program.  On success, the caller should
     *   start the game running, usually using runGame(), after showing any
     *   desired introductory messages.  
     */
    startupRestore(fname)
    {
        /* 
         *   try restoring the game, using code 1 to indicate that this is
         *   a direct startup restore 
         */
        if (performRestore(fname, 1))
        {
            /* success - tell the caller to proceed with the restored game */
            return true;
        }
        else
        {
            /* 
             *   Failure.  We've described the problem, so ask the user
             *   what they want to do about it. 
             */
            try
            {
                /* show options and read the response */
                failedRestoreOptions();

                /* if we get here, proceed with the game */
                return true;
            }
            catch (QuittingException qe)
            {
                /* quitting - tell the caller to terminate */
                return nil;
            }
        }
    }
    

    /*
     *   Restore a file.  'code' is the restoreCode value for the
     *   PostRestoreObject notifications.  Returns true on success, nil on
     *   failure.  
     */
    performRestore(fname, code)
    {
        try
        {
            /* restore the file */
            restoreGame(fname);
        }
        catch (StorageServerError sse)
        {
            /* failed due to a storage server error - explain the problem */
            gLibMessages.restoreFailedOnServer(sse);

            /* indicate failure */
            return nil;
        }
        catch (RuntimeError err)
        {
            /* failed - check the error to see what went wrong */
            switch(err.errno_)
            {
            case 1201:
                /* not a saved state file */
                gLibMessages.restoreInvalidFile();
                break;
                
            case 1202:
                /* saved by different game or different version */
                gLibMessages.restoreInvalidMatch();
                break;
                
            case 1207:
                /* corrupted saved state file */
                gLibMessages.restoreCorruptedFile();
                break;
                
            default:
                /* some other failure */
                gLibMessages.restoreFailed(err);
                break;
            }

            /* indicate failure */
            return nil;
        }

        /* note that we've successfully restored the game */
        gLibMessages.restoreOkay();
        
        /* set the appropriate restore-action code */
        PostRestoreObject.restoreCode = code;

        /* notify all PostRestoreObject instances */
        PostRestoreObject.classExec();

        /* 
         *   look around, to refresh the player's memory of the state the
         *   game was in when saved 
         */
        "\b";
        libGlobal.playerChar.outermostVisibleParent().lookAroundWithin();

        /* indicate success */
        return true;
    }
    
    /* 
     *   There's no point in including this in undo.  If the command
     *   succeeds, it's not undoable itself, and there won't be any undo
     *   information in the newly restored state.  If the command fails, it
     *   won't make any changes to the game state, so there won't be
     *   anything to undo.  
     */
    includeInUndo = nil
;

/*
 *   Subclass of Restore action that takes a literal string as part of the
 *   command.  The filename must be a literal enclosed in quotes, and the
 *   string (with the quotes) must be stored in our fname_ property by
 *   assignment of a quotedStringPhrase production in the grammar rule.  
 */
DefineAction(RestoreString, Restore)
    execAction(cmd)
    {
        /* 
         *   Perform the restore, using the filename given in our fname_
         *   parameter, trimmed of quotes.  Use code 2, the same as any
         *   other explicit RESTORE command.  
         */
        performRestore(fname_.getStringText(), 2);

        /* abandon any additional commands on the same command line */
        throw new TerminateCommandException();
    }
;


DefineSystemAction(Again)
    
    exec(cmd)
    {
        if((gameMain.againRepeatsParse && libGlobal.lastCommandForAgain is in
           ('',nil)) || (!gameMain.againRepeatsParse && libGlobal.lastCommand is
           in ('', nil)))
        {
            DMsg(no repeat, 'Sorry, there is no action available to repeat. ');
        }
        else if (gameMain.againRepeatsParse)
        {
            Parser.parse(libGlobal.lastCommandForAgain);
        }
        else
        {
            libGlobal.lastCommand.exec();
        }
    }
    
    clearForAgain()
    {
        libGlobal.lastAction = nil;
        libGlobal.lastCommand = nil;
    }
    
;

/* Dummy action to provide an action context. */

DefineTIAction(DoNothing)
    curDobj = gPlayerChar
    curIobj = gPlayerChar.location
    curObj = curDobj
    grammarTemplates = ['do nothing']
;


/* Debugging Actions */

#ifdef __DEBUG
 
DefineTAction(Purloin)    
    addExtraScopeItems(whichRole?)
    {
        makeScopeUniversal();
    }
    beforeAction() { }
    afterAction() { }
    turnSequence() { }
    
;    

DefineTAction(GoNear)    
    addExtraScopeItems(whichRole?)
    {
        makeScopeUniversal();
    }  
    beforeAction() { }
    afterAction() { }
    turnSequence() { }
;

DefineIAction(FiatLux)
    execAction(cmd)
    {
        gPlayerChar.isLit = !gPlayerChar.isLit;
        DMsg(fiat lux, '{I} suddenly {1} glowing. ', gPlayerChar.isLit ? 'start'
             :  'stop' );
    }
    
    beforeAction() { }    
    turnSequence() { }
;

DefineLiteralAction(Evaluate)
    exec(cmd)
    {
        try
        {
            local res = Compiler.eval(stripQuotesFrom(cmd.dobj.name));
            say(toString(res));
        }
        catch (CompilerException cex)
        {
            cex.displayException();
        }
        catch (Exception ex)
        {
            ex.displayException();
        }
        
    }
    includeInUndo = true
    afterAction() {}
    beforeAction() { }    
    turnSequence() { }
;


symTab: PreinitObject
    symbolToVal(val)
    {
        return ctab[val];        
    }
    
    ctab = [* -> '???']
        
    execute()
    {
        t3GetGlobalSymbols().forEachAssoc( new function(key, value)
        {
            if(dataType(value) == TypeObject && value.isClass)
                ctab[value] = key;
        });
    }
;

modify TadsObject
    objToString()
    {
        if(isClass)
            return symTab.symbolToVal(self);
        
        local str;
        
        if(name != nil)
            str = name + ' ';
        
        str  += '(' + getSuperclassList + ')';
        
        return str;
    }
    
;

#endif