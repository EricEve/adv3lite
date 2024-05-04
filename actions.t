#charset "us-ascii"
#include "advlite.h"

property handleTopic;
property showSuggestions;
property sayHello;
property showScore;
property scoreNotify;
property showHints;
property disableHints;
property activated;
property extraHintsExist;
property showExitsCommand;
property exitsOnOffCommand;
property isOdor;
property isNoise;
property enumerateSuggestions;
property hyperlinkSuggestions;


DefineSystemAction(Quit)
   
    
    execAction(cmd)
    {        
        DMsg(quit query, '<.p>Do you really want to quit? (y/n)?\n>');
       
        if(yesOrNo())
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
            sayNoExitLister();
        else
            gExitLister.showExitsCommand();
    }
;

DefineSystemAction(ExitsMode)
    execAction(cmd)
    {
        if(gExitLister == nil)
        {
            sayNoExitLister();
            return;
        }
        
        if(cmd.verbProd.on_ != nil)
            gExitLister.exitsOnOffCommand(true, true);
        
        if(cmd.verbProd.off_ != nil)
            gExitLister.exitsOnOffCommand(nil, nil);
        
        if(cmd.verbProd.look_ != nil)
            gExitLister.exitsOnOffCommand(nil, true);
        
        if(cmd.verbProd.stat_ != nil)
            gExitLister.exitsOnOffCommand(true, nil);
    }
        
;

DefineSystemAction(ExitsColour)
    execAction(cmd)
    {
        if(gExitLister == nil)
        {
            sayNoExitLister(); 
            return;
        }
        
        if(defined(statuslineExitLister) && cmd.verbProd.on_ != nil)
        {
            statuslineExitLister.highlightUnvisitedExits = 
                (cmd.verbProd.on_ == 'on');
            
            DMsg(exit color onoff, 'Okay, colouring of unvisited exits is now
                {1}.<.p>', cmd.verbProd.on_);
        }
        
        if(defined(statuslineExitLister) && cmd.verbProd.colour_ != nil)
        {
            statuslineExitLister.unvisitedExitColour = cmd.verbProd.colour_;
            statuslineExitLister.highlightUnvisitedExits = true;
            DMsg(exit color change, 'Okay, unvisited exits in the status line
                will now be shown in {1}. ', cmd.verbProd.colour_);
        }
    }
;

sayNoExitLister()
{
    DMsg(no exit lister, 'Sorry, that command is not available in this
                game, since there\'s no exit lister. ');    
}


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
                htmlSay(BMsg(mention full score, 'To see your complete list of
                    achievements, use the <<aHref('full score', 'FULL SCORE',
                                                  'show full score')>> command. 
                    '));

                /* don't mention it again */
                Score.mentionedFullScore = true;
            }
        }
        else
            /* this game doesn't use scoring */
            scoreNotPresent(); 
        
    }
    
    scoreNotPresent()
    {
          DMsg(score not present, '<.parser>This story doesn&rsquo;t use
               scoring.<./parser> ');            
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
            Score.scoreNotPresent;
    }
   
;

DefineSystemAction(Notify)
    execAction(cmd)
    {
        /* show the current notification status */
        if (libGlobal.scoreObj != nil)
            showNotifyStatus(libGlobal.scoreObj.scoreNotify.isOn);        
        else
            commandNotPresent;
    }
    
      /* show the current score notify status */
    showNotifyStatus(stat)
    {
        DMsg(show notify status, '<.parser>Score notifications are
        currently <<stat ? 'on' : 'off'>>.<./parser> ');
    }
;

DefineSystemAction(NotifyOn)
    execAction(cmd)
    {
        /* turn notifications on, and acknowledge the status */
        if (libGlobal.scoreObj != nil)
        {
            libGlobal.scoreObj.scoreNotify.isOn = true;
            acknowledgeNotifyStatus(true);
        }
        else
            commandNotPresent;
    }
;

DefineSystemAction(NotifyOff)
    execAction(cmd)
    {
        /* turn notifications off, and acknowledge the status */
        if (libGlobal.scoreObj != nil)
        {
            libGlobal.scoreObj.scoreNotify.isOn = nil;
            acknowledgeNotifyStatus(nil);
        }
        else
            commandNotPresent;
    }
;

DefineSystemAction(ToggleDisambigEnumeration)    
    execAction(cmd)
    {
        if(libGlobal.enumerateDisambigOptions)
        {
            libGlobal.enumerateDisambigOptions = nil;
            DMsg(disambig enum off, 'Enumeration of disambiguation choices is now off. ');
        }
        else
        {
            libGlobal.enumerateDisambigOptions = true;
            DMsg(disambig enum off, 'Enumeration of disambiguation choices is now on. ');
        }
    }
;

DefineSystemAction(EnumerateSuggestions)
    execAction(cmd)
    {
        if(defined(suggestedTopicLister))
        {
            suggestedTopicLister.enumerateSuggestions = !suggestedTopicLister.enumerateSuggestions;
            
            DMsg(toggle suggestion enum, 'Enumeration of topic suggestions is now 
                <b><<suggestedTopicLister.enumerateSuggestions ? 'on' : 'off'>></b>.<.p>');          
        }
        if(!defined(suggestedTopicLister))
            DMsg(no suggestions present, 'Topic suggestions are not present in this game');
    }
;

DefineSystemAction(HyperlinkSuggestions)
    execAction(cmd)       
    {
        /* First check that the player's interpreter is capable of displaying hyperlinks. */
        if(systemInfo(SysInfoInterpClass) != SysInfoIClassHTML)
        {
            DMsg(needs html terp, 'This feature requires an HTML interpreter. ');
            abort;
        }
        
        if(defined(suggestedTopicLister))
        {
            suggestedTopicLister.hyperlinkSuggestions = !suggestedTopicLister.hyperlinkSuggestions;
            
            DMsg(toggle suggestion enum, 'Hyperlinking of topic suggestions is now 
                <b><<suggestedTopicLister.hyperlinkSuggestions ? 'on' : 'off'>></b>.<.p>');
        }
        if(!defined(suggestedTopicLister))
            DMsg(no suggestions present, 'Topic suggestions are not present in this game');
    }
;

DefineSystemAction(Hints)
    execAction(cmd)
    {
        if(gHintManager == nil)
            sayHintsNotPresent();
        else        
            gHintManager.showHints();
        
    }
    
    sayHintsNotPresent() 
    {
        DMsg(hints not present, '<.parser>Sorry, this story doesn&rsquo;t
                have any built-in hints.<./parser> ');
    }
;
        

DefineSystemAction(HintsOff)
    execAction(cmd)
    {
        if(gHintManager == nil)
            DMsg(no hints to disable, '<.parser>This game doesn\'t have any
                hints to turn off.<./parser> ');
        else
            gHintManager.disableHints();
    }
;

DefineSystemAction(ExtraHints)
    execAction(cmd)
    {
        if(gExtraHintManager == nil || !gExtraHintManager.extraHintsExist())
        {
            DMsg(no extra hints, 'Sorry, there are no extra hints in this game.
                ');
            return;
        }
        
        onOff = cmd.verbProd.onOff;
        
        if(onOff == nil)
        {
            showExtraHintStatus();
            
            return;
                    
        }
        onOff = onOff.toLower();
        
        if(onOff == hintsOff)
            gExtraHintManager.deactivate();
        else
            gExtraHintManager.activate();
        
        DMsg(extra hints on or off, 'Okay; extra hints are now {1}. ', onOff );
    }
    
    /* 
     *   Routine to display message saying that extra hints are on or off.
     *   Translators may want to override this method to display a message if it
     *   can't readily be done in a CustomMessages object.
     */
    showExtraHintStatus()
    {
        local cmdstr = extraHintsCmd + onOrOff(!extraHintsActive).toUpper();
        
        DMsg(extra hints status,            
            'Extra hints are currently <<onOrOff(extraHintsActive)>>. To turn
            them <<onOrOff(!extraHintsActive)>> use the command <<aHref(cmdstr,
                cmdstr, 'Turn extra hints ' + onOrOff(!extraHintsActive))>>. ',
                 cmdstr);
            return;
    }
    
    extraHintsActive = (gExtraHintManager != nil && gExtraHintManager.activated)
    
    onOrOff(stat) { return stat ? hintsOn : hintsOff; }
    
    onOff = nil
    
    hintsOff = BMsg(extra hints off, 'off')
    hintsOn = BMsg(extra hints on, 'on')
    
    extraHintsCmd = BMsg(extra hints command, 'EXTRA ')
;

DefineSystemAction(Brief)
    execAction(cmd)
    {
        if(gameMain.verbose)
        {
            gameMain.verbose = nil;
            DMsg(game now brief, 'The game is now in BRIEF mode. <<first
                  time>>Full room descriptions will now only be shown on the
                first visit to a room or in response to an explicit
                <<aHref('LOOK', 'LOOK', 'Look
                    around')>> command.<<only>> ');
        }
        else
            DMsg(game already brief, 'The game is already in BRIEF mode. ');
    }
;

DefineSystemAction(Verbose)
    execAction(cmd)
    {
        if(gameMain.verbose)            
            DMsg(game already verbose, 'The game is already in VERBOSE mode. ');        
        else
        {
            gameMain.verbose = true;
            DMsg(game now verbose, 'The game is now in VERBOSE mode. <<first
                  time>>Full room descriptions be shown each time a room is
                visited.<<only>> ');
        }            
    }
;


/* Set Inventory to TALL format */
DefineSystemAction(InventoryTall)
    execAction(cmd)
    {
        /* Register with libGlobal that inventory listing should now be in tall format. */
        libGlobal.inventoryTall = true;
        
        /* Display a confirmation that this change has just taken place. */
        DMsg(inventory tall, 'Inventory Listing is now set to TALL');
    }
;
  
/* Set Inventory to WIDE format */
DefineSystemAction(InventoryWide)        
    execAction(cmd)
    {
        /* Register with libGlobal that inventory listing should now be in wide format. */
        libGlobal.inventoryTall = nil;
        
        /* Display a confirmation that this change has just taken place. */
        DMsg(inventory wide, 'Inventory Listing is now set to WIDE');
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
            local carriedList = gActor.contents.subset({o: o.wornBy == nil &&
                o.isFixed == nil});
            
            /* Note whether we've displayed the worn list */
            local wornListShown = 0;
            
            /* 
                 *   If anything is being worn, get a list of it minus the final
             *   paragraph break and then display it.
             */
            if(wornList.length > 0)
            {               
                gActor.myWornLister.show(wornList, 0, nil);
                
                /* 
                 *   If nothing is being carried, terminate the list with a full
                 *   stop and a paragraph break.
                 */
                if(carriedList.length == 0)
                    ".<.p>";
                
                /*  
                 *   Note that the worn list has been shown.                 
                 */
                wornListShown = 1;
                
            }
            /* 
             *   If something's being carried or nothing's being worn, display
             *   an inventory list of what's being carried. If nothing's being
             *   worn or carried, this will display the "You are empty-handed"
             *   message.
             */
            if(carriedList.length > 0 || wornList.length == 0)
                gActor.myInventoryLister.show(carriedList, wornListShown);
        }
        else
        {
            gActor.myInventoryLister.show(gActor.contents, 0);
        }
        
        /* Mark eveything just listed as having been seen. */
        gActor.contents.forEach({x: x.noteSeen()});
    }
   
        
    /* 
     *   Do we want separate lists of what's worn and what's carried?  By default we do unless we're
     *   doing a tall inventory listing
     */
    splitListing = !libGlobal.inventoryTall
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
        DMsg(wait, 'Time {dummy} pass{es/ed}. ');
    }
   
;

DefineIAction(Jump)
    execAction(cmd)
    {
        DMsg(jump, '{I} jump{s/ed} on the spot, fruitlessly. ');
    }
    
    preCond = (gActor.location && gActor.location.getOutToJump ?
    [actorOutOfNested]: nil)
;

DefineIAction(Yell)
    execAction(cmd)
    {
        DMsg(yell, '{I} shout{s/ed} very loudly. ');
    }
;

DefineIAction(Smell)
    execAction(cmd)
    {
        /* 
         *   Build a list of all the objects in scope that both (1) define a
         *   smellDesc property that will display something and (2) whose
         *   isProminentSmell property is true
         */
        local s_list = gActor.getOutermostRoom.allContents.subset(
            {x: Q.canSmell(gActor, x)  &&  x.isProminentSmell});
        
        /* Include the current room in the list. */
        s_list += gActor.getOutermostRoom;
        
        s_list = s_list.getUnique();
        
        /*  Obtain the corresponding list for remote rooms */
        local r_list = getRemoteSmellList().getUnique() - s_list;
               
        /* 
         *   Create a local variable to keep track of whether we've displayed
         *   anything.
         */
        local somethingDisplayed = nil;
        
        
        /* 
         *   Display the smellDesc of every item in our local smell list,
         *   keeping track of whether anything has actually been displayed as a
         *   result.
         */
        foreach(local cur in s_list)
        {
            if(cur.displayAlt(&smellDesc))
                somethingDisplayed = true;
        }
        
        /* Then list any smells from remote locations */
        if(listRemoteSmells(r_list))
            somethingDisplayed = true;
        
        
        /*  If nothing has been displayed report that there is nothing to smell */        
        if(!somethingDisplayed)            
            DMsg(smell nothing intransitive, '{I} {smell} nothing out of the
                ordinary.<.p>');

    }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    getRemoteSmellList() { return []; }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    listRemoteSmells(lst) { return nil; }
;


DefineIAction(Listen)
    execAction(cmd)
    {
        /* 
         *   I may be able to hear things that aren't technically in scope,
         *   since they may be hidden in containers that allow sound through.
         */        
        local s_list = gActor.getOutermostRoom.allContents.subset(
            {x: Q.canHear(gActor,x) && x.isProminentNoise});
        
        /* Include the current room in the list. */
        s_list += gActor.getOutermostRoom;
        
        s_list = s_list.getUnique();
        
        local r_list = getRemoteSoundList().getUnique() - s_list;
        
        /* 
         *   Create a local variable to keep track of whether we've displayed
         *   anything.
         */
        local somethingDisplayed = nil;
        
        foreach(local cur in s_list)
        {
            if(cur.displayAlt(&listenDesc))
                somethingDisplayed = true;
        }
        
        if(listRemoteSounds(r_list))
            somethingDisplayed = true;
        
        
        if(!somethingDisplayed)
            DMsg(hear nothing listen, '{I} hear{s/d} nothing out of the
                ordinary.<.p>');

        
    }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    getRemoteSoundList() { return []; }
    
    /* Do nothing in the core library; senseRegion.t will override if present */
    listRemoteSounds(lst) { return nil; }
;

DefineIAction(Sleep)
    execAction(cmd)
    {
        DMsg(no sleeping, 'This {dummy} {is} no time for sleeping. ');
    }
;




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
        {
            local getOffAction;
            getOffAction = gActor.location.contType == On ? GetOff : GetOutOf;
            replaceAction(getOffAction, gActor.location);
        }
        else
        {
            "<<buildImplicitActionAnnouncement(true)>>";
            doTravel();
        }
    }
;

/* 
 *   The GO action is never triggered directly by a player command but can be
 *   used to synthesize a travel action in the direction supplied by the dobj.
 */

Go: TravelAction
    predefinedDirection = true
    
    execAction(cmd)
    {
        direction = cmd.dobj;
        inherited(cmd);
    }
    
    /* Define this so that this action can be called from execNestedAction */
    resolvedObjectsInScope() { return true; }

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
        askForDobj(SitOn);          
    }
;

DefineIAction(Lie)
    execAction(cmd)
    {
        askForDobj(LieOn);
    }   
;


Travel: TravelAction
    direction = (dirMatch.dir)
;

DefineIAction(VagueTravel)
    execAction(cmd)
    {
        DMsg(vague travel, 'Which way do you want to go? ');       
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
            DMsg(already back there, '{I}{\'m} already there. ');
            return;
        }
        
        local dir = pathBack[2][1];
        
        DMsg(going back dir, '(going {1})\n', dir.name);
        
        gActor.getOutermostRoom.(dir.dirProp).travelVia(gActor);
        
    }
;

DefineTAction(GoTo)
    
    /* Add all known items to scope */
    addExtraScopeItems(whichRole?)
    {
       scopeList = scopeList.appendUnique(Q.knownScopeList);
    }
    
    againRepeatsParse = nil
    
    reportImplicitActions = nil
;

DefineIAction(Continue)
    execAction(cmd)
    {
        local path;
        path = defined(pcRouteFinder) ? pcRouteFinder.cachedRoute : nil;
        if(path == nil)
        {
            DMsg(no journey, '{I}{\'m} not going anywhere. ');
            return;
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
            say(gActor.getOutermostRoom.alreadyThereMsg);
            return;
        }
        
        local dir = path[idx + 1][1];
        
        takeStep(dir, path[path.length][2]);
        
        
    }
    
    takeStep(dir, dest, fastGo?)
    {
        DMsg(going dir, '(going {1})\n', dir.name);
        
        gActor.getOutermostRoom.(dir.dirProp).travelVia(gActor);
        
        if(!gActor.isIn(dest) && !fastGo)           
            htmlSay(contMsg);
        
    }
    
    contMsg =  BMsg(explain continue, 'To continue the journey
                use the command
                <<aHref('Continue','CONTINUE','Continue')>> or C. ')
    
    
;

DefineSystemAction(Topics)
    execAction(cmd)
    {
        local otherActor = gPlayerChar.currentInterlocutor;
        
        if(otherActor == nil)
            DMsg(no interlocutor, '{I}{\'m} not talking to anyone. ');
        else
        {            
            otherActor.showSuggestions(true);
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

    againRepeatsParse = nil
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
        if(defined(pcRouteFinder) && cmd.dobj.ofKind(Room)
           && !cmd.actor.isIn(cmd.dobj))        
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
    againRepeatsParse = nil   
;


DefineTAction(Read)
    announceMultiAction = true
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }

    againRepeatsParse = nil
;

DefineTAction(SmellSomething)
    announceMultiAction = true
    againRepeatsParse = nil
    
    /* Add any Odors the actor can smell */
    addExtraScopeItems(whichRole?)
    {
        if(defined(Odor))
        {
            local odorList = gActor.getOutermostRoom.allContents.subset(
                { o: o.isOdor && Q.canSmell(gActor, o) } );
            
            scopeList = scopeList.appendUnique(odorList);
        }
    }
    
;

DefineTAction(ListenTo)
    announceMultiAction = true
    againRepeatsParse = nil
    
    /* Add any Noises the actor can hear */
    addExtraScopeItems(whichRole?)
    {
        if(defined(Noise))
        {
            local noiseList = gActor.getOutermostRoom.allContents.subset(
                { n: n.isNoise && Q.canHear(gActor, n) } );
            
            scopeList = scopeList.appendUnique(noiseList);
        }
    }    
    
;

DefineTAction(Taste)
    announceMultiAction = true
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }
    againRepeatsParse = nil
;

DefineTAction(Feel)
    announceMultiAction = true
    getAll(cmd, role)
    {
        return scopeList.subset({ x: !x.ofKind(Room)});
    }
    againRepeatsParse = nil
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
    againRepeatsParse = nil
;

DefineTAction(Strike)
    againRepeatsParse = nil
;

DefineTAction(Open)       
;

DefineTAction(Close)        
;

DefineTAction(LookIn)  
    againRepeatsParse = nil
;

DefineTAction(LookUnder)    
    againRepeatsParse = nil
;

DefineTAction(LookBehind)
    againRepeatsParse = nil
;

DefineTAction(LookThrough)
    againRepeatsParse = nil
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
    againRepeatsParse = nil
;

DefineTAction(Wear)       
;

DefineTAction(Doff)    
    allowAll = true    
;

DefineTAction(Break)
    againRepeatsParse = nil
;

DefineTAction(Climb)       
;

DefineTAction(ClimbUp)      
;

DefineTAction(ClimbDown)        
;

DefineIAction(ClimbUpVague)
    execAction(cmd)  { askForDobj(ClimbUp); }
;    

DefineIAction(ClimbDownVague)
    execAction(cmd)  { askForDobj(ClimbDown); }
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

DefineTAction(GoAlong)    
;

DefineTAction(TravelVia)
;

DefineTAction(Push)
    againRepeatsParse = nil
;

DefineTAction(Pull)
    againRepeatsParse = nil
;

DefineTAction(Search)
    againRepeatsParse = nil
;

DefineTAction(Remove)
    againRepeatsParse = nil
;

DefineTAction(Move)
    againRepeatsParse = nil
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
    againRepeatsParse = nil
;

DefineTAction(Dig)
    againRepeatsParse = nil
;

DefineTAction(Kiss)
    againRepeatsParse = nil
;

DefineTAction(Detach)
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.attachedTo != nil});
    }
;

DefineTIAction(DigWith)
    resolveIobjFirst = nil
    againRepeatsParse = nil
;

DefineTIAction(CleanWith)
    resolveIobjFirst = nil
    againRepeatsParse = nil
;

DefineTIAction(MoveTo)
    resolveIobjFirst = nil
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.isMoveable});
    }
    againRepeatsParse = nil
;

DefineTIAction(MoveWith)
    resolveIobjFirst = nil
    
    getAll(cmd, role)
    {
        return scopeList.subset({ x: x.isMoveable});
    }
    againRepeatsParse = nil
;

DefineTIAction(PutOn)       
    announceMultiAction = nil
    allowAll = true
    getAll(cmd, role)   
    {
        return putAllScope(curIobj, scopeList);
    }
;

/* 
 *   Return a suitable list of direct objects for a PUT ALL PREP XXX command,
 *   where iobj is the indirect object of the command and slist is the full
 *   scopelist for the action.
 *
 *   Ideally we want to return a list of all the objects that can be put in
 *   iobj, namely all the objects in scope that are portable and not already in
 *   iobj, and not the iobj. But if no objects fit the bill we have to fall back
 *   on first, all portable objects in scope and, failing that, all objects in
 *   scope except the room and the actor.
 */

putAllScope(iobj, slist)
{
    /* Get a list of all the portable objects in scope. */
    local portables = slist.subset({x: !x.isFixed});
    
    /* If there are none, return the scope list less the actor and any rooms */
    if(portables.length < 1)
        return slist.subset({x: !x.ofKind(Room) && x != gActor});
    
    /* 
     *   Get a list of suitable objects, i.e. portable objects that are not in
     *   the iobj and are not the iobj.
     */
    local suitables = portables.subset({x: iobj == nil || !x.isOrIsIn(iobj)});
    
    /* if there's anything in this list, return it */
    if(suitables.length > 0)
        return suitables;
    
    /* Otherwise return the list of portable objects. */
    
    return portables;
}


DefineTIAction(PutIn)          
    announceMultiAction = nil
    allowAll = true
    
    getAll(cmd, role)   
    {
        return putAllScope(curIobj, scopeList);
    }
    
; 




DefineTIAction(PutUnder)      
    announceMultiAction = nil
    allowAll = true
    
    getAll(cmd, role)   
    {
        return putAllScope(curIobj, scopeList);
    }
;

DefineTIAction(PutBehind)      
    nnounceMultiAction = nil
    allowAll = true
    
    getAll(cmd, role)   
    {
        return putAllScope(curIobj, scopeList);
    }
;



DefineTIAction(UnlockWith)      
    resolveIobjFirst = nil
;

DefineTIAction(LockWith)      
    resolveIobjFirst = nil
;

DefineTAction(Attach)
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
    againRepeatsParse = nil
;

DefineTAction(Cut)
;

DefineTIAction(CutWith)
    resolveIobjFirst = nil
    againRepeatsParse = nil
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
    againRepeatsParse = nil
;

DefineTAction(ThrowDir)
    execAction(cmd)
    {
        direction = cmd.verbProd.dirMatch.dir;
        inherited(cmd);
    }
    
    direction = nil
    againRepeatsParse = nil
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
    againRepeatsParse = nil
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
    againRepeatsParse = nil   
    
    doActionOnce()
    {
        libGlobal.lastTypedOnObj = curDobj;
        return inherited();
    }
;

DefineLiteralAction(Type)
    againRepeatsParse = nil
    
    execAction(cmd) { askForIobj(TypeOn); }
;

DefineLiteralTAction(EnterOn)
    againRepeatsParse = nil
;

DefineLiteralTAction(WriteOn)
    againRepeatsParse = nil
    
    doActionOnce()
    {
        libGlobal.lastWrittenOnObj = curDobj;
        return inherited();
    }
;

DefineLiteralAction(Write)
    againRepeatsParse = nil

    execAction(cmd) { askForIobj(WriteOn); }
;

DefineTopicTAction(ConsultAbout)
    againRepeatsParse = nil
;

DefineTopicAction(ConsultWhatAbout)
    execAction(cmd)
    {
        askForDobj(ConsultAbout);
    }
;

DefineTAction(SwitchVague)
    againRepeatsParse = nil
;

DefineTAction(Flip)
    againRepeatsParse = nil
;

DefineTAction(Fasten)   
;


DefineTAction(Burn)   
;

DefineTIAction(BurnWith)
    resolveIobjFirst = nil
;

DefineTAction(Pour)
    againRepeatsParse = nil
;

DefineTIAction(PourOnto)    
    resolveIobjFirst = nil
    againRepeatsParse = nil
;

DefineTIAction(PourInto)
    resolveIobjFirst = nil
    againRepeatsParse = nil
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

DefineTIAction(PlugInto)   
    resolveIobjFirst = nil
;

DefineTAction(PlugIn)    
;

DefineTIAction(UnplugFrom)        
;

DefineTAction(Unplug)    
;


DefineTAction(PushTravelDir)
    
    isPushTravelAction = true
    
    execAction(cmd)
    {
        local conn;
        
        /* Note whether travel is allowed. This can be adjusted by the dobj */
        travelAllowed = nil;
        
        /* Get the direction of travel from the command */
        direction = cmd.verbProd.dirMatch.dir;
        
        /* Note the actor's location. */
        local loc = gActor.getOutermostRoom; 
        
//        /* Note whether we meed the lighting conditions to permit travel */
//        local illum = loc.allowDarkTravel || loc.isIlluminated;
        
        /* 
         *   first find out what our direction might take us to; if it's an object that defines the
         *   PushTravlVia property, change the action to PushTravelVia that connector
         */
        
    retry:
        /* 
         *   See if the direction we're due to go in points to an object and if so process it
         *   accordingly.
         */
        if(loc.propType(direction.dirProp) == TypeObject)
        {
            /* Note the connector object in the relevant direction */
            conn = loc.(direction.dirProp); 
            
            /* 
             *   If this connector is an UnlistedProxy Connector we need to carry out the rest of
             *   the processing on whatever it's a proxy for.
             */
            if(conn.ofKind(UnlistedProxyConnector))
            {
                /* Reset our direction to that of the UnlistedProxyConnector. */
                direction = conn.direction;
                
                /* Start over again with our new direction. */
                goto retry;                  
            }
            
            /*  
             *   If the connector object defines a PushTravelVia action, then replace the current
             *   action with that PushTravelVia action (e.g. PushTravelGoThrough or
             *   PushTravelClimbUp).
             */
            if(conn.PushTravelVia)
                replaceAction(conn.PushTravelVia, gDobj, conn);
            
            /* 
             *   Maybe conn looks like an object but is actually an anonymous or dynamic function,
             *   in which case we can try to execute it.
             */
            if(dataTypeXlat(conn) == TypeFuncPtr)
            {
                try
                {
                    conn();                    
                }
                catch (Exception ex)
                {
                    "Problem with function object attached to the <<direction.name>> property of
                    <<loc.name>>.<.p>";
                    
                    ex.displayException();
                }
            }
            else        
                
            /* 
             *   if we reach this point, there must be something fishy going on, since we really
             *   shouldn't have any other kind of object attached to a direction property, so
             *   display a message saying so.
             */                
                "<b>ERROR!</b> Illegal object <<conn>> attached to the <<direction.name>> property 
                of <<loc.name>>. ";
            
        }
        /* 
         *   If our direction isn't attached to an object, it must be to a method or string that's
         *   going to display a message explaining why we can't travel. So call the nonTravel()
         *   function to handle it.            
         */
        else
            nonTravel(loc, direction);
    }
    
    

    travelAllowed = nil
    direction = nil
    curIobj = nil
    
    
    doTravel() { delegated TravelAction(); }
;

DefineTIAction(PushTravelThrough)
    viaMode = Through
    
    isPushTravelAction = true
    
    addExtraScopeItems(role)
    {
        /* 
         *   If our indirect object is a TravelConnector it may not be a physical object that would
         *   normally be considered in scope, so we need to add it to our scope list.
         */        
        if(objOfKind(curIobj, TravelConnector))
            scopeList = scopeList.appendUnique(valToList(curIobj));
        
        /* 
         *   Append the extra scope items defined on this Room to the action's
         *   scope list.
         */
        inherited(role);
    }
;

DefineTIAction(PushTravelEnter)
    viaMode = Into
    
    isPushTravelAction = true
;

DefineTIAction(PushTravelGetOutOf)
    viaMode = OutOf
    
    isPushTravelAction = true
;

DefineTIAction(PushTravelClimbUp)
    viaMode = Up
    
    isPushTravelAction = true
;

DefineTIAction(PushTravelClimbDown)
    viaMode = Down
    
    isPushTravelAction = true
;





DefineTAction(TalkTo)
    isConversational = true
;

class MiscConvAction: IAction
    execAction(cmd)
    {
        if(gPlayerChar.currentInterlocutor == nil 
           || !Q.canTalkTo(gPlayerChar, gPlayerChar.currentInterlocutor))
            sayNotTalking();
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
    
    isConversational = true
;

sayNotTalking()
{
    DMsg(not talking, '{I}{\'m} not talking to anyone. ');
}


/* 
 *   Singleton object used to trigger a YesTopic; we must make it familiar so
 *   that YesTopics can be listed as suggested topics. We define this as
 *   noTopicObj in actions.t rather than actor.t so that the SayYes and SayNo
 *   actions in actions.t will compile even if actor.t is absent from the build.
 */
yesTopicObj: object familiar = true;

/* Singleton object used to trigger a NoTopic */
noTopicObj: object familiar = true;

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
        qType = cmd.verbProd.qType;
        /* 
         *   Mark this as a special Topic designed to match a QueryTopic of the appropriate type.
         */
        topicObj = new Topic(qType + '!');
        
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
            sayNotTalking();
        else if(defined(endConvBye) &&
            gPlayerChar.currentInterlocutor.endConversation(endConvBye));
    }    
    
    curObj = nil   
    
    isConversational = true
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

            local greetList;
            
            /* 
             *   We do this a slightly roundabout way to avoid compilation
             *   errors and warnings when actor.t is omitted from the build.
             */
            local cls = (defined(Actor) ? Actor : nil);
            
            if(cls)                
                greetList = scopeList.subset(
                    { x: x.ofKind(cls) && x != gPlayerChar });            
            else
                greetList = [];
            
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
            gPlayerChar.currentInterlocutor.sayHello();
        }
    }
    
    curObj = nil
    
    isConversational = true
;

DefineLiteralTAction(TellTo)
    exec(cmd)
    {
        /* 
         *   Take a command of the form of TELL FOO TO BAR, turn it into FOO,
         *   BAR and then send it back to parser to execute
         */
        local str = cmd.dobj.name + ', ' + cmd.iobj.name;
        Parser.parse(str);
    }
    afterAction() {}
    
    isConversational = true
;


DefineTopicTAction(AskAbout)    
    isConversational = true
;

DefineTopicTAction(AskFor)    
    isConversational = true
;

DefineTopicTAction(TellAbout)   
    isConversational = true
;

DefineTopicTAction(TalkAbout)    
    isConversational = true
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
    
    isConversational = true
;

DefineTopicTAction(SayTo)    
    isConversational = true
;

DefineTIAction(GiveTo)     
    /* 
     *   The summaryReport can be set by a GiveTopic to a single-quoted string in
     *   BMsg format, with {1} standing in for gActionListStr, in order to
     *   report on a whole set of objects given at once; e.g. '{I} {give} Bob
     *   {1}. '
     */
    summaryReport = nil
    
    /* 
     *   The summaryProp can be a propertyPointer to a method on the Actor being
     *   conversed with that's called at once a whole set of objects has been
     *   given. It will normally be set by a gAction.summaryProp = &prop
     *   statement in a GiveTopic.
     */
    summaryProp = nil
    
    /* 
     *   Reset the summaryReport and the summaryProp to nil for the whole group
     *   of objects this action may act on, so that they're only used if they're
     *   explicitly requested this turn.
     */
    execGroup(cmd) 
    { 
        summaryReport = nil; 
        summaryProp = nil;
    }
;

DefineTIAction(ShowTo)   
    showReport = nil
    summaryProp = nil
    
    /* 
     *   Reset the showReport to nil for the whole group of objects this action
     *   may act on.
     */
    execGroup(cmd) 
    { 
        summaryReport = nil; 
        summaryProp = nil;
    }
    
    isConversational = true
;

ThinkAbout: TopicAction
    baseActionClass = ThinkAbout
    
    execAction(cmd)
    {
        /* 
         *   We don't want this action treated as conversational if it results in the use of reveal
         *   tags, so we store the current interlocutor and then set the current interlocutor to nil
         *   before proceeding.
         */                 
        local interlocutor = gPlayerChar.currentInterlocutor;
        
        try
        {
            
            gPlayerChar.currentInterlocutor = nil;            
            
            if(libGlobal.thoughtManagerObj != nil)
                libGlobal.thoughtManagerObj.handleTopic(cmd.dobj.topicList);
            else
                Think.execAction(cmd);
        }
        finally
        {
            /* Restore the current interlocutor. */
            gPlayerChar.currentInterlocutor = interlocutor;
        }
    }
    againRepeatsParse = nil
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
            
            curTopic = cmd.dobj;
        }
        else if (cmd.dobj == nil && cmd.iobj != nil)
        {
            if(cmd.iobj.ofKind(ResolvedTopic))
                topics = cmd.iobj.topicList;
            else
                topics = cmd.iobj;
            
            curTopic = cmd.iobj;
        }
        
        if(gPlayerChar.currentInterlocutor == nil ||
           !Q.canTalkTo(gPlayerChar, gPlayerChar.currentInterlocutor))	
            sayNotTalking();
        else
        {
            notePronounAntecedent(gPlayerChar.currentInterlocutor);
            resolvePronouns();
            curObj = gPlayerChar.currentInterlocutor;
            gPlayerChar.currentInterlocutor.handleTopic(topicListProperty, 
                topics, defaultProperty);
        }
    }
    
    /* The default property to call on the Actor if there's not matching TopicEntry */
    defaultProperty = &noResponseMsg
    
    
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
            
            if(cur == Them && actor.plural)
                topics[i] = actor;
        }
    }
    
    
    topicListProperty = nil
    topics = nil
    
    isConversational = true
;

        
AskAboutImplicit: ImplicitConversationAction
    baseActionClass = AskAboutImplicit
    topicListProperty = &askTopics
;

AskForImplicit: ImplicitConversationAction
    baseActionClass = AskForImplicit
    topicListProperty = &askForTopics
;

TellAboutImplicit: ImplicitConversationAction
    baseActionClass = TellAboutImplicit
    topicListProperty = &tellTopics
;

TalkAboutImplicit: ImplicitConversationAction
    baseActionClass = TalkAboutImplicit
    topicListProperty = &talkTopics
;

DefineTAction(ShowToImplicit)
    showReport = nil
    
    /* 
     *   The summaryProp can be a propertyPointer to a method on the Actor being
     *   conversed with that's called at once a whole set of objects has been
     *   given. It will normally be set by a gAction.summaryProp = &prop
     *   statement in a ShowTopic.
     */
    summaryProp = nil
    
    /* 
     *   Reset the showReport to nil for the whole group of objects this action
     *   may act on.
     */
    execGroup(cmd) 
    { 
        summaryReport = nil; 
        summaryProp = nil;
    }
;

DefineTAction(GiveToImplicit)
    showReport = nil
    
    /* 
     *   The summaryProp can be a propertyPointer to a method on the Actor being
     *   conversed with that's called at once a whole set of objects has been
     *   given. It will normally be set by a gAction.summaryProp = &prop
     *   statement in a GiveTopic.
     */
    summaryProp = nil
    /* 
     *   Reset the showReport to nil for the whole group of objects this action
     *   may act on.
     */
    execGroup(cmd) 
    { 
        summaryReport = nil; 
        summaryProp = nil;
    }
;
              

Query: ImplicitConversationAction
    baseActionClass = Query
    execAction(cmd)
    {
        qType = cmd.verbProd.qtype;

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
    defaultProperty = &defaultSayResponse
;

/* 
 *   A Special Action is one that's been triggered from a SpecialAction object to cover cases where
 *   there's no other existing action in the game it can divert to.
 */
DefineTAction(SpecialAction)
    specialPhrase = nil
;


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
                filePromptFailedMsg(result[2]);
            else
                filePromptFailed();
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
    filePromptMsg = (BMsg(get scripting prompt, 'Please select a name for the
        new script file'))
    
    fileTypeID = FileTypeLog
    fileDisposition = InFileSave

    /* show our cancellation mesasge */
    showCancelMsg() { DMsg(scripting canceled, '<.parser>Canceled.<./parser>'); }

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
                    htmlSay(scriptingOkayWebTemp);                  
                else
                    htmlSay(scriptingOkay);
                    
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
                    DMsg(scripting failed exception, '<.parser>Failed; 
                        <<exc.displayException>><./parser>');
                    
                else
                    DMsg(scripting failed, '<.parser>Failed; an error occurred
                        opening the script file.<./parser> ');
                   
            }
        }
    }
    
    scriptingOkayWebTemp = BMsg(scripting okay web temp,
                                '<.parser>The transcript will be saved.
                                Type <<aHref('script off', 'SCRIPT OFF', 
                                             'Turn off scripting')>>
                                to discontinue scripting and download the saved
                                transcript.<./parser> ')
    
    scriptingOkay = BMsg(scripting okay, '<.parser>The transcript will
                        be saved to the file. Type <<aHref('script off', 
                            'SCRIPT OFF', 'Turn off scripting')>> to
                        discontinue scripting.<./parser> ')
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
            DMsg(script off ignored, '<.parser>No script is currently being
                        recorded.<./parser>');

            return;
        }

        /* cancel scripting in the interpreter's output layer */
        aioSetLogFile(nil, LogTypeTranscript);

        /* remember that scripting is no longer in effect */
        scriptStatus.scriptFile = nil;

        /* acknowledge the change, if desired */
        if (ack)
            DMsg(script off okay, '<.parser>Scripting ended.<./parser>');
           
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
    filePromptMsg = (BMsg(get recording prompt, 'Please select a name for the 
        new command log file'))
    
    fileTypeID = FileTypeCmd
    fileDisposition = InFileSave

    /* show our cancellation mesasge */
    showCancelMsg() { DMsg(recording canceled, '<.parser>Canceled.<./parser> '); }

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
                 htmlSay(BMsg(recording okay, 
                              '<.parser>Commands will now be recorded.  Type
                     <<aHref('record off', 'RECORD OFF',
                             'Turn off recording')>>
                              to stop recording commands.<./parser> '));                
                
        }
        else
        {
            /* recording failed */
            scriptStatus.recordFile = nil;

            /* show an error if acknowledgment is desired */
            if (ack)
            {
                if (exc != nil)
                    DMsg(recording failed exception, '<.parser>Failed; 
                        <<exc.displayException()>><./parser>');
                    
                else
                    DMsg(recording failed, '<.parser>Failed; an error occurred
                        opening the command recording file.<./parser>');
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
            DMsg(record off ignored, '<.parser>No command recording is currently
                being made.<./parser> ');
           
            return;
        }

        /* cancel recording in the interpreter's output layer */
        aioSetLogFile(nil, LogTypeCommand);

        /* remember that recording is no longer in effect */
        scriptStatus.recordFile = nil;

        /* acknowledge the change, if desired */
        if (ack)
            DMsg(record off okay, '<.parser>Command recording ended.<./parser> ');
    }

    /* we can't include this in undo, as it affects external files */
    includeInUndo = nil
;

/*
 *   REPLAY - play back a command log previously recorded. 
 */
DefineAction(Replay, FileOpAction)
    /* our file dialog parameters - ask for a log file to save */
    filePromptMsg = (BMsg(get replay prompt, 'Please select the command log file
        to replay'))
    
    fileTypeID = FileTypeCmd
    fileDisposition = InFileOpen

    /* show our cancellation mesasge */
    showCancelMsg() { DMsg(replay canceled, '<.parser>Canceled.<./parser> '); }

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
            inputScriptOkay(
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
                DMsg(input script failed exception, '<.parser>Failed; 
                    <<exc.displayException>><./parser>');               
            else
                DMsg(input script failed, '<.parser>Failed; the script input
                    file could not be opened.<./parser>');
              
        }
    }
    
    /* acknowledge starting an input script */
    inputScriptOkay(fname)
    {
        DMsg(input script okay, '<.parser>Reading commands from <q><<
          File.getRootName(fname).htmlify()>></q>...<./parser>\n ');
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
    filePromptMsg = (BMsg(get save prompt, 'Save game to file'))

    /* we're asking for a file to save, or type t3-save */
    fileDisposition = InFileSave
    fileTypeID = FileTypeT3Save

    /* cancel message */
    showCancelMsg() { DMsg(save cancelled, '<.parser>Canceled.<./parser> '); }
    
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
            DMsg(save failed on server, '<.parser>Failed, because of a problem
                accessing the storage server:
                <<makeSentence(sse.errMsg)>><./parser>');

            /* done */
            return;
        }
        catch (RuntimeError err)
        {
            /* the save failed - mention the problem */
            DMsg(save failed, '<.parser>Failed; your computer might be running
                low on disk space, or you might not have the necessary
                permissions to write this file.<./parser>');            
            
            /* done */
            return;
        }
        
        /* note the successful save */
        DMsg(save okay, '<.parser>Saved.<./parser> ');
        
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


        /* presume failure */
        succ = nil;

        /* ask for a file */
        result = getInputFile(BMsg(get restore prompt, 'Restore game from file'), 
                              InFileOpen, FileTypeT3Save, 0);

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
           
            /* done */
            break;

        case InFileFailure:
            /* advise of the failure of the prompt */
            if (result.length() > 1)
                filePromptFailedMsg(result[2]);
            else
                filePromptFailed();
            break;

        case InFileCancel:
            /* acknowledge the cancellation */
            DMsg(restore canceled, '<.parser>Canceled.<./parser> ');            
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
            DMsg(restore failed on server,'<.parser>Failed, because of a problem
                accessing the storage server:
                <<makeSentence(sse.errMsg)>><./parser>');            

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
                DMsg(restore invalid file, '<.parser>Failed: this is not a valid
                    saved position file.<./parser> ');                
                break;
                
            case 1202:
                /* saved by different game or different version */
                DMsg(restore invalid match, '<.parser>Failed: the file was not
                    saved by this story (or was saved by an incompatible version
                    of the story).<./parser> ');               
                break;
                
            case 1207:
                /* corrupted saved state file */
                DMsg(restore corrupted file, '<.parser>Failed: this saved state
                    file appears to be corrupted.  This can occur if the file
                    was modified by another program, or the file was copied
                    between computers in a non-binary transfer mode, or the
                    physical media storing the file were damaged.<./parser> ');                
                break;
                
            default:
                /* some other failure */
                DMsg(restore failed, '<.parser>Failed: the position could not be
                    restored.<./parser>');                
                break;
            }

            /* indicate failure */
            return nil;
        }

        /* note that we've successfully restored the game */
        DMsg(restore okay, '<.parser>Restored.<./parser> ');
               
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
    
    /* error showing the input file dialog (or character-mode equivalent) */
    filePromptFailed()
    {
        DMsg(file prompt failed, '<.parser>A system error occurred asking for a
            filename. Your computer might be running low on memory, or might
            have a configuration problem.<./parser> ');
    }

    /* error showing the input file dialog, with a system error message */
    filePromptFailedMsg(msg)
    {
        DMsg(file prompt failed msg, '<.parser>Failed:
            <<makeSentence(msg)>><./parser> ');
    }
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


