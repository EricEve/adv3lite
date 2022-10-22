#charset "us-ascii"


/* include the library header */
#include "advlite.h"

/*---------------------------------------------------------------------------*/
/*
 *   cmdHelp Extension
 *.  by Eric Eve
 *
 *   Experimental extension to give help to players who enter a empty command.
 */


/* Modifications to Parser for CMDHELP EXTENSION */
modify Parser
    
    /* 
     *   Overridden for CMDHELP EXTENSION. If our autoHelp property is true then
     *   respond to an empty command by displaying a brief menu of command
     *   options.
     */
    emptyCommand()
    {
        if(autoHelp)
            CmdMenu.showOptions();
        else
            inherited();
    }
    
    /* 
     *   Flag: Do we want to show a menu of command options in response to an
     *   empty command? By default we do since that's the purpose of this
     *   CMDHELP EXTENSION.
     */
    autoHelp = true    
;

/ *[CMDHELP EXTENSION] */
DefineSystemAction(CmdMenu)
    showOptions()
    {
        DMsg(cmdhelp show options,
        'What would you like to do?\b
        <<aHref('1','1')>>. Go to another location\n
        <<aHref('2','2')>>. Investigate your surroundings\n
        <<aHref('3','3')>>. Relocate something\n
        <<aHref('4','4')>>. Manipulate something\n');
        
        if(defined(Actor))
        {
            for(local a = firstObj(Actor); a != nil ; a = nextObj(a, Actor))
            {
                if(a != gPlayerChar && Q.canTalkTo(gPlayerChar, a))
                {
                    DMsg(cmdhelp talk to someone, '<<aHref('5','5')>>. 
                        Talk to someone\n');
                    break;
                }
            }
        }
        // "6. Something else\b";        
        "<.p>";
    }
    
    /* 
     *   Show a list of possible actions, where cmd_str is the name of the
     *   action and lst a list of objects on which it might be tried.
	 *	[CMDHELP EXTENSION]
     */
    showList(lst, cmd_str)
    {       
        local cmdstr;
        
        /* 
         *   Replace any commonly abbreviated commands with their common
         *   abbreviations in the command we send to the command line, so that
         *   players get used to the common abbreviations.
         */
        switch(cmd_str)
        {
        case 'examine ':
            cmdstr = 'x ';
            break;
        default:
            cmdstr = cmd_str;
            break;
        }
        
        /*  
         *   Output a hyperlinked list of commands for each object in the list,
         *   but stop after at most maxObj objects, so we don't overwhelm the
         *   player with choices.
         */
        for(local cur in lst, local i = 1; i <= maxObjs; i++)
        {
            local str = cmd_str + cur.name;
            local str1 = cmdstr + cur.name;
            "<<aHref(str1, str)>>\ \ \ ";
        }
    }
    
    /* 
     *   Carry out this action. This is the response to the player entering a
     *   number at the command prompt. 
	 *   [CMDHELP EXTENSION]
     */
    execAction(cmd)
    {
        /* Get the number the player typed .*/        
        local num = cmd.dobj.numVal;
        
        /* Note the player character's current location. */
        local loc = gPlayerChar.getOutermostRoom();
        
        /* 
         *   If the player typed a number out of range, re-display the options
         *   and end there.
         */
        if(num < 1 || num > 6)
        {
            showOptions();
            return;
        }
        
        /* Option 1: The Player wants to go to another location. */
        if(num == 1)
        {
            /* Ask the player where s/he wants to go. */
            DMsg(cmdhelp where go, 'Where would you like to go?\n
            The possible exits are: ');
            
            /* 
             *   If we have an exit lister, use it to display the list of exits.
             */
            if(gExitLister)
                gExitLister.showExits(gPlayerChar);
            /*  Otherwise create our own list of exits. */
            else
            {
                /* Set up a flag to record if we actually found any exits. */
                local dirFound = nil;
                foreach(local dir in Direction.allDirections)
                {
                    /* 
                     *   Assume an exit exists if the corresponding direction
                     *   property points to a method or an object.
                     */
                    if(loc.propType(dir.dirProp) is in (TypeCode, TypeObject))
                    {
                        "<<aHref(dir.name, dir.name)>>\ \ ";
                        dirFound = true;
                    }
                }
                /* If we didn't find any exits, say so. */
                if(dirFound == nil)
                    DMsg(cmdhelp no exit, 'None ');
            }
            "<.p>";
            
            /* 
             *   If the routeFinder is present we can also offer the player of
             *   travelling to another location via the GO TO command.
             */
            if(defined(pcRouteFinder))
            {
                /* Get a list of rooms the player knows about. */
                local rmList = Q.knownScopeList.subset({o: o.ofKind(Room)});
                
                /* Remove the player's current location from the list. */
                rmList -= loc;
                
                /* Sort the list in alphabetical order. */
                rmList = rmList.sort(SortAsc, {a, b:
                                     a.name.compareIgnoreCase(b.name) });
                
                /* 
                 *   Don't offer the option unless there are any rooms to offer.
                 */
                if(rmList.length > 0)
                {
                    /* Introduce the list. */
                    DMsg(cmdhelp go to, 'Or you could: ');
                    
                    /* 
                     *   Display a hyperlinked GO TO ROOM command for every room
                     *   in the list.
                     */
                    foreach(local rm in rmList)
                    {
                        local str = 'go to ' + rm.name;
                        "<<aHref(str, str)>>\ \ ";
                    }
                }
                
            }         
            
            /* We're done. */
            return;
            
        }
        
        /* 
         *   If we reach this point the player may want to deal with specific
         *   objects, so we need to get a list of those in scope.
         */
        local scope_lst = World.scope.toList().subset({o:
            Q.canSee(gPlayerChar, o)});
        
        /*  Remove Unthings and Rooms from the list. */
        scope_lst = scope_lst.subset({o: !o.ofKind(Unthing) 
                                     && !o.ofKind(Room) });
        
        /* Option 2: the Player wants to investigate their environment. */
        if(num == 2)
        {
            /* First offer the basic set of intransitive commands. */
            DMsg(cmdhelp investigate, 'Here are some suggestions (other
                actions may also be possible):\n');
            "<<aHref('look', 'look', 'Look around the room')>>\ \ 
            <<aHref('listen', 'listen')>>\ \
            <<aHref('smell', 'smell')>>\ \ 
            <<aHref('I', 'inventory', 'See what you\'re carrying')>>\b"; 
            
           
            /* 
             *   Get a list of things that could be examined. In the first
             *   instance, sort them alphabetically.
             */
            local exa_lst = scope_lst.sort(SortAsc, 
                                           {a, b: a.name.compareIgnoreCase(b.name)});
            
            /* 
             *   If the list of things we could examine has too many items, sort
             *   the list in the order of the turn number on which the items
             *   were last examined, so that those that were examined longest
             *   ago come to the front of the list.
             */            
            if(exa_lst.length() > maxObjs)
                exa_lst = exa_lst.sort(SortAsc,{a, b: a.turnLastExamined -
                                       b.turnLastExamined});
            
            /* Show the list of EXAMINE suggestions. */                       
            showList(exa_lst, 'examine ');
                        
            "<.p>";
            
            /* 
             *   Get a list of READ suggestions by taking the subset of examine
             *   suggestions for items that have a non-nil readDesc.
             */
            local read_lst = exa_lst.subset({o: o.propType(&readDesc) !=
                                            TypeNil });
            
            /*  Show the list of READ suggestions. */
            showList(read_lst, 'read ');
            "<.p>";
            
            /* Get a list of thing we could look inside. */
            local li_lst = exa_lst.subset(
                {o: (o.contType == In && !o.isLocked)
                || (o.remapIn != nil && !o.remapIn.isLocked)});
            
            /*  
             *   Show a list of LOOK IN suggestions. Note we don't do the same
             *   for LOOK UNDER or LOOK BEHIND since these are much rarer, and
             *   handling them would either flood the player with useless
             *   suggestions (if we took a maximalist view of what to include)
             *   or create potential spoilers (if we took a minimalist view)
             */
            showList(li_lst,'look in ');
            
            "<.p>";
            
            /* 
             *   Get a list of things we could listen to; these are objects with
             *   a non-nil listenDesc.
             */
            local listen_lst = scope_lst.subset({o: o.propType(&listenDesc) !=
                                               TypeNil});
            
            /* Display the list of LISTEN TO suggestions. */
            showList(listen_lst, 'listen to ');
            
            
            /* 
             *   Get a list of things we could smell; these are objects with a
             *   non-nil smellDesc.
             */
            local smell_lst = scope_lst.subset({o: o.propType(&smellDesc) !=
                                               TypeNil});
            
            /*  Display the list of SMELL suggestions. */
            showList(smell_lst, 'smell ');
            
            /* We're done. */
            return;
        }
        
        /* 
         *   From this point on we're suggesting commands to manipulate objects
         *   in various ways, so we'll reduce the scope list to things the
         *   player character can actually touch.
         */
        
        scope_lst = scope_lst.subset({o:  Q.canReach(gPlayerChar, o)});
        
        /* Things can be moved if they're not fixed in place. */
        local move_lst = scope_lst.subset({o: !o.isFixed });
        
        /* Option 3: The player wants to move things around. */
        if(num == 3)
        {
            /* Display an introductory message. */         
            DMsg(cmdhelp relocate, 'Here are some suggestions (there may well
                be several other possibilities):\n');
            
            /* 
             *   First deal with things the player can TAKE. We need to set
             *   gAction since verify() routines will assume it has been set
             *   correctly.
             */                 
            gAction = Take;
            
            /*   
             *   Get a list of things than can be taken. This will be the subset
             *   of potentially moveable objects that pass verifyDobjTake().
             */
            local take_lst = move_lst.subset({o: Take.verify(o,
                DirectObject).allowAction});            
            
            /*   
             *   Also exlude any objects that would fail the TAKE action at the
             *   check() stage, if the excludeCheckFailures option is set.
             */
            if(excludeCheckFailures)
                take_lst = take_lst.subset({o: passCheck(Take, o) });
            
                       
            /*  
             *   If we have too many objects, sort them in the order in which they
             *   were last moved.
             */
            if(take_lst.length > maxObjs)
                take_lst = take_lst.sort(SortAsc, {a, b: a.turnLastMoved -
                                         b.turnLastMoved});
            
            /*  Display a list of TAKE suggestions */
            showList(take_lst, 'take ');            
            
            /*  
             *   If there's more than one thing that can be taken, also offer
             *   the TAKE ALL command.
             */
            if(take_lst.length > 1)
                "<<aHref('take all', 'take all')>>";
                        
            "<.p>";
            
            /*  
             *   Now suggest things that can be DROPped. Again we must set
             *   gAction for the sake of the verify method.
             */
            gAction = Drop;
            
            /*   
             *   Get a list of moveable objects directly located in the player
             *   character.
             */
            local drop_lst = move_lst.subset({o: o.isDirectlyIn(gPlayerChar)});
            
            /*  
             *   If we have too many objects, sort them in ascending order of
             *   the turn on which they were last moved.
             */
            if(drop_lst.length > maxObjs)
                 drop_lst = drop_lst.sort(SortAsc, {a, b: a.turnLastMoved -
                                         b.turnLastMoved});
            
            /* Display a list of DROP suggestions. */
            showList(drop_lst, 'drop ');            
            
            /* 
             *   If more than one object could be dropped, offer the DROP ALL
             *   option.
             */
            if(drop_lst.length > 1)
                "<<aHref('drop all', 'drop all')>>";
            
            "<.p>";
            
            /*   
             *   Now suggest PUT IN, PUT ON, PUT UNDER, PUT BEHIND. First set
             *   the list of objects that can be put anywhere to the list of
             *   moveable objects.
             */
            local put_lst = move_lst;
                        
            /*   
             *   If there are too many objects, sort them in ascending order of
             *   the turn on which they were last moved.
             */
            if(put_lst.length > maxObjs)
                 put_lst = drop_lst.sort(SortAsc, {a, b: a.turnLastMoved -
                                         b.turnLastMoved});
            
            
            /*  
             *   Set up PUT IN suggestions. First set gAction to PutIn so that
             *   any routines we call that depend on the value of gAction will
             *   work as expected.
             */
            gAction = PutIn;
            
            /*  
             *   Get the list of items into which things can be out. This is the
             *   list of unlocked objects with a contType of In plus the list of
             *   objects with an unlocked remapIn object.
             */
            local put_in_lst = scope_lst.subset({o: (o.contType == In &&
                !o.isLocked) || (o.remapIn != nil && !o.isLocked)});
            
            /*   
             *   Sort the resulting list into ascending order of the turn on
             *   which items last had anything inserted into them.
             */
            put_in_lst = put_in_lst.sort(SortAsc, {a, b: a.turnLastMovedInto -
                                         b.turnLastMovedInto });
            
            /*   
             *   Set up a counter to keep track of how many suggestions we've
             *   made.
             */
            local i = 1;
            
        in_loop:
            /* 
             *   Go through every item in our put_lst (potential direct objects
             *   of a PUT IN COMMAND).
             */
            for(local cur in put_lst)
            {
                /* 
                 *   For each potential direct object of a PUT IN command, go
                 *   through all the potential indirect objects of a PUT IN
                 *   command.
                 */
                foreach(local dest in put_in_lst)
                {
                    /* 
                     *   If the potential direct object is neither in the
                     *   potential indirect object nor identical to the
                     *   potential direct object, and if inserting the direct
                     *   object into the indirect object would pass the
                     *   checkInsert() test, then suggest putting this direct
                     *   object into this indirect object.
                     */
                    if(!cur.isOrIsIn(dest) 
                       && (!excludeCheckFailures || checkInsert(cur, dest,
                           PutIn)))
                    {
                        /* 
                         *   Create the relevant string version of the command
                         *   and output a hyperlinked version of it.
                         */
                        local str = 'put ' + cur.name + ' in ' + dest.name;
                        "<<aHref(str, str)>>\ \ ";
                        
                        /* 
                         *   Increment our number-of-suggestions counter. If it
                         *   exceeds maxObjs, break out of both loops.
                         */
                        if(++i > maxObjs)
                            break in_loop;
                    }
                }
            }
            "<.p>";
            
            /* 
             *   Now handle the PUT ON suggestions. The logic is the same as for
             *   PUT IN.
             */
            gAction = PutOn;
            put_in_lst =  scope_lst.subset({o: o.contType == On || 
                o.remapOn != nil});
            
            put_in_lst = put_in_lst.sort(SortAsc, {a, b: a.turnLastMovedInto -
                                         b.turnLastMovedInto });
            
            
            i = i;
        on_loop:
            for(local cur in put_lst)
            {
                foreach(local dest in put_in_lst)
                {
                    if(!cur.isOrIsIn(dest) 
                       && (!excludeCheckFailures || checkInsert(cur, dest,
                           PutOn)))
                    {
                        local str = 'put ' + cur.name + ' on ' + dest.name;
                        "<<aHref(str, str)>>\ \ ";
                        
                        if(++i > maxObjs)
                            break on_loop;
                    }
                }
            }                                    
            "<.p>"; 
            
            /* 
             *   Now handle the PUT UNDER suggestions. The logic is the same as
             *   for PUT IN.
             */
            gAction = PutUnder;
            put_in_lst =  scope_lst.subset({o: o.contType.canPutUnderMe || 
                (o.remapUnder != nil && o.remapUnder.canPutUnderMe) });
            
            put_in_lst = put_in_lst.sort(SortAsc, {a, b: a.turnLastMovedInto -
                                         b.turnLastMovedInto });
            
            
            i = 1;
        under_loop:
            foreach(local cur in put_lst)
            {
                foreach(local dest in put_in_lst)
                {
                    if(!cur.isOrIsIn(dest) 
                       && (!excludeCheckFailures || checkInsert(cur, dest,
                           PutUnder)))
                    {
                        local str = 'put ' + cur.name + ' under ' + dest.name;
                        "<<aHref(str, str)>>\ \ ";
                        
                        if(++i > maxObjs)
                            break under_loop;
                    }
                }
            } 
            "<.p>";                               
            
            /* 
             *   Now handle the PUT BEHIND suggestions. The logic is the same as
             *   for PUT IN.
             */
            gAction = PutBehind;
            put_in_lst =  scope_lst.subset({o: o.contType.canPutBehindMe || 
                (o.remapBehind != nil && o.remapBehind.canPutBehindMe) });
            
            put_in_lst = put_in_lst.sort(SortAsc, {a, b: a.turnLastMovedInto -
                                         b.turnLastMovedInto });
            
            i = 1;
            
        behind_loop:
            foreach(local cur in put_lst)
            {
                foreach(local dest in put_in_lst)
                {
                    if(!cur.isOrIsIn(dest) 
                       && (!excludeCheckFailures || checkInsert(cur, dest,
                           PutBehind)))
                    {
                        local str = 'put ' + cur.name + ' behind ' + dest.name;
                        "<<aHref(str, str)>>\ \ ";
                        
                         if(++i > maxObjs)
                            break behind_loop;
                    }
                }
            } 
            "<.p>";
        }
        
        /* 
         *   OPTION 4: The player wants to manipulate objects in their
         *   surroundings, which is a catch-all term for actions not covered
         *   above.
         */
        if(num == 4)
        {
            /* Display an introductory message. */
            DMsg(cmdhelp manipulate, 'Some things you could try include (there
                may be many other possibilities):\b');
            
            /* Go through every action in out manipulationActions list */
            foreach(local act in manipulationActions)
            {               
                /* 
                 *   Set gAction to the current action, so that routines such as
                 *   verify that depend on its value will work properly.
                 */
                gAction = act;
                
                /*   Set gActor to the player character for the same reason. */
                gActor = gPlayerChar;
                
                /*   
                 *   Get the list of objects in scope that would pass the verify
                 *   stage for this action.
                 */
                local lst = scope_lst.subset({o: act.verify(o,
                    DirectObject).allowAction});
                
                /*  
                 *   If we want to exclude objects that would fail at the check
                 *   stage, reduce our list to those objects that would pass
                 *   this action at the check stage.
                 */
                if(excludeCheckFailures)
                    lst = lst.subset({o: passCheck(act, o) });
                
                /*  
                 *   Get the name of the action from the grammarTemplates
                 *   property of the current action. This will be a string in
                 *   the form 'clean (dobj)', so we want to remove '(dobj)' from
                 *   the string to just leave the command name.
                 */
                local str = act.grammarTemplates[1].findReplace('(dobj)', '');
                
                /*  Display a list of commands for this action. */
                showList(lst, str);            
            }    
            
            /* 
             *   If the gadgets module is present the player could also try
             *   pushing and pulling buttons and levers. PUSH and PULL aren't
             *   included in manipulationActions as they would result in the
             *   suggestion of too many pointless commands.
             */
            if(defined(Button))
            {
                "<.p>";
                /* Get a list of all the buttons and levers in scope. */
                local lst = scope_lst.subset({o: o.ofKind(Button) ||
                                             o.ofKind(Lever)});
                
                /* Set gAction and gActor for the PUSH action. */
                gAction = Push;
                gActor = gPlayerChar;
                
                /* 
                 *   Restrict our list to actions that would pass the verify
                 *   stage of a PUSH action.
                 */
                lst = lst.subset({o: Push.verify(o, DirectObject).allowAction});
                
                /*   Display a list of suggested actions. */
                showList(lst, 'push ');
                
                /* Get a list of levers in scope. */
                lst = scope_lst.subset({o: o.ofKind(Lever) });
                
                /* Set gAction and gActor for the PULL action. */
                gAction = Pull;
                gActor = gPlayerChar;
                
                /* 
                 *   Get a subset of levers that would pass the verify stage for
                 *   PULL.
                 */
                lst = lst.subset({o: Pull.verify(o, DirectObject).allowAction});
                
                /*  Show a list of suggested PULL commands. */
                showList(lst, 'pull ');
                
            }
            
            /* LockWith and UnlockWith actions on lockableWithKey items */
            
            /* 
             *   Get a list of objects that can be locked or unlocked with a
             *   key, remembering to include those with lockable remapIn
             *   objects.
             */
            local lockLst = scope_lst.subset({o: o.lockability == lockableWithKey
                                            || (o.remapIn &&
                                                o.remapIn.lockability ==
                                                lockableWithKey)});
            
            /* Go through every object in our list. */
            foreach(local lock in lockLst)
            {
                /* 
                 *   Get a list of keys that might lock/unlock the current
                 *   object. These will be Keys in scope for which the current
                 *   object appears in the plausibleLockList.
                 */
                local key_lst = scope_lst.subset(
                    {o: o.ofKind(Key) &&
                    o.plausibleLockList.indexOf(lock) });
                
                /*  
                 *   Set the description of the suggested action to 'unlock' or
                 *   'lock' depending on whether the current object is locked or
                 *   unlocked.
                 */
                local actstr = lock.isLocked ? 'unlock ' : 'lock ';
                
                /* Go through every possibly usable key we found */
                foreach(local key in key_lst)
                {
                    /* 
                     *   Suggest locking or unlocking the current object with
                     *   that key.
                     */
                    local str = actstr + lock.name + ' with ' + key.name;
                    "<<aHref(str, str)>>\ \ ";
                }
                    
            }
            
            
        }
        
        /* OPTION 5: The player wants to talk with an NPC. */
        if(num == 5)
        {
            /* Set up a list of available actors. */
            local actor_lst = [];
            
            /* 
             *   We can only populate the list if the actor.t module is present.
             */
            if(defined(Actor))
            {
                /* 
                 *   Get a list of all the actors in scope who aren't the player
                 *   character.
                 */
                actor_lst = scope_lst.subset({o: o.ofKind(Actor) && o !=
                                             gPlayerChar});
            }
            
            /* If we didn't find any, say so. */
            if(actor_lst.length == 0)                  
                DMsg(cmdhelp no one to talk to, 'Sorry, but there\'s no one here 
                    to talk to right now.\b');
            /* 
             *   Otherwise, if we only found one and the player character is
             *   already talking to him or her, suggest the use of the TOPICS
             *   command.
             */
            else if(actor_lst.length == 1 && actor_lst[1] ==
                    gPlayerChar.currentInterlocutor)
                "<<aHref('topics', 'topics')>> ";
            /*  Otherwise display a list of actors to talk to. */
            else    
                showList(actor_lst, 'talk to ');
            
        }
        
        /* At the moment OPTION 6 isn't included in the suggestions menu */
        if(num == 6)
        {
            "Some other actions you could try include:\b
            <<aHref('JUMP', 'JUMP')>>\ \ <<aHref('THINK', 'THINK')>>
            \ \ <<aHref('WAIT', 'WAIT')>>, <<aHref('YELL', 'YELL')>>
            \ \ <<aHref('SLEEP', 'SLEEP')>>\b";
        }
        
        gAction = self;
    }
    
   
    
    
    /* 
     *   A list of the actions we'll potentially suggest for option 4,
     *   "Manipulate thing". Note that these must all be TActions.
     */
    manipulationActions = [Open, Close, Lock, Unlock, Break, Cut,
        SwitchOn, SwitchOff, Burn, Wear, Doff, Climb, ClimbUp, ClimbDown,
        Board, Enter, GetOff, GetOutOf, Light, Extinguish, Eat, Drink,
        Clean, Dig, Attach, Detach, Fasten, Unfasten, Unplug, JumpOff,
        JumpOver, Pour, Screw, Unscrew, GoThrough] 
 
    /* 
     *   We in any case rule out combinations of actions and objects that would
     *   fail at the verify stage; flag - should we also rule out combinations
     *   that fail at the check stage? By default we do.
     */
    excludeCheckFailures = true
    
    /*  Determine whether obj would pass the check stage of the act action. */
    passCheck(act, obj)
    {
        /* Set obj to the current direct object of act/ */
        act.curDobj = obj;
        
        /* See if running the check routine would output any text. */
        local str = gOutStream.captureOutput(
            {: act.check(obj, act.checkDobjProp)});
        
        /* 
         *   If any text would have been output, we failed the check stage;
         *   otherwise we passed.
         */
        return  str == '';
    }
    
    
    /* 
     *   Check whether obj can be inserted in cont with the action act (which
     *   will be one of PutIn, PutOn, PutUnder or PutBehind). 
     */
    checkInsert(obj, cont, act)
    {
        /* If the container has a remapIn object, use that instead */
        if(cont.remapIn != nil)
            cont = cont.remapIn;
         
        /* Set gAction to the appropriate action */
        gAction = act;
        gDobj = obj;
        
        /* 
         *   Get the property for running the check() method on the indirect
         *   object of prop,
         */
        local prop = act.checkIobjProp;
        
        /*   Capture the output from running this method. */
        local str = gOutStream.captureOutput( {: cont.(prop) });
        
        /* 
         *   If there was any output, we failed the check stage; otherwise we
         *   passed.
         */
        return str == '';
    }
    
    /* 
     *   The maximum number of objects in a list before we try to reduce that
     *   list.
     */
    maxObjs = 10   
;


/* [CMDHELP EXTENSION] */
VerbRule(CmdMenu)
    numericDobj
    : VerbProduction
    action = CmdMenu
    
    isActive = Parser.autoHelp
;
    

/* Modifications to Thing for the CMDHELP EXTENSION */
modify Thing
    turnLastMoved = 0
    turnLastMovedInto = 0
    
    /* 
     *   Modified for CMDHELP EXTENSION. Note the last turns on which this
     *   object was moved and on which something was moved into this object.
     */
    actionMoveInto(dest)
    {
        inherited(dest);
        turnLastMoved = gTurns;
        dest.turnLastMovedInto = gTurns;
        if(dest.ofKind(SubComponent) && dest.lexicalParent)
            dest.lexicalParent.turnLastMovedInto = gTurns;
    
    }
    
    turnLastExamined = 0
    
    /* 
     *   Modified for CMDHELP EXTENSION. Note the last turn on which this
     *   object was examined.
     */
    dobjFor(Examine)
    {
        action()
        {
            inherited();
            turnLastExamined = gTurns;
        }
    }
;

/* Modify suggestedTopicLister to hyperlink suggestions for the CMDHELP EXTENSION */
modify suggestedTopicLister
    
    /* 
     *   Turn on the topic suggestion hyperlinking if the Parser autoHelp is
     *   enabled.
     */
    hyperlinkSuggestions = Parser.autoHelp    
;