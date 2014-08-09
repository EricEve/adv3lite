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


modify Parser
    emptyCommand()
    {
        CmdMenu.showOptions();
    }
    
    
    
;

DefineSystemAction(CmdMenu)
    showOptions()
    {
        "What would you like to do?\b
        1. Go to another location\n
        2. Investigate your surroundings\n
        3. Relocate something\n
        4. Manipulate something\n";
        
        for(local a = firstObj(Actor); a != nil ; a = nextObj(a, Actor))
        {
            if(a != gPlayerChar && Q.canTalkTo(gPlayerChar, a))
            {
                "5. Talk to someone\n ";
                break;
            }
        }
        // "6. Something else\b";        
        "<.p>";
    }
    
    /* 
     *   Show a list of possible actions, where cmd_str is the name of the
     *   action and lst a list of objects on which it might be tried.
     */
    showList(lst, cmd_str)
    {
        for(local cur in lst, local i = 1; i <= maxObjs; i++)
        {
            local str = cmd_str + cur.name;
            "<<aHref(str, str)>>\ \ ";
        }
    }
    
    execAction(cmd)
    {
        local num = cmd.dobj.numVal;
        local loc = gPlayerChar.getOutermostRoom();
        
        if(num < 1 || num > 6)
        {
            showOptions();
            return;
        }
        
        if(num == 1)
        {
            "Where would you like to go?\n
            The possible exits are: ";
            
//            if(gExitLister)
//                gExitLister.showExits(gPlayerChar);
//            else
//            {
             
                local dirFound = nil;
                foreach(local dir in Direction.allDirections)
                {
                    if(loc.propType(dir.dirProp) is in (TypeCode, TypeObject))
                    {
                        "<<aHref(dir.name, dir.name)>>\ \ ";
                        dirFound = true;
                    }
                }
                
                if(dirFound == nil)
                    "None ";
//            }
            "<.p>";
            
            if(defined(pcRouteFinder))
            {
                local rmList = Q.knownScopeList.subset({o: o.ofKind(Room)});
                rmList -= gPlayerChar.getOutermostRoom();
                if(rmList.length > 0)
                {
                    "Or you could: ";
                    foreach(local rm in rmList)
                    {
                        local str = 'go to ' + rm.name;
                        "<<aHref(str, str)>>\ \ ";
                    }
                }
                
            }                                  
            
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
        
        if(num == 2)
        {
            "Here's a few things you could try:\n";
            "<<aHref('LOOK', 'LOOK', 'Look around the room')>>\ \ 
            <<aHref('LISTEN', 'LISTEN')>>\ \
            <<aHref('SMELL', 'SMELL')>>\ \ 
            <<aHref('I', 'INVENTORY', 'See what you\'re carrying')>>\b"; 
            
           
            
            local exa_lst = scope_lst.sort(SortAsc, 
                                           {a, b: a.name.compareIgnoreCase(b.name)});
            
            /* 
             *   If the list of things we could examine has more than ten items,
             *   cut out the things we have already examined.
             */
            
            if(exa_lst.length() > maxObjs)
                exa_lst = exa_lst.subset({o: !o.examined});
            
            /*  
             *   If the list of things we could examine still has more than ten
             *   items, cut out any decorations.
             */
            if(exa_lst.length() > maxObjs)
                exa_lst = exa_lst.subset({o: !o.isDecoration});
            
            
            showList(exa_lst, 'examine ');
                        
            "<.p>";
            
            local read_lst = exa_lst.subset({o: o.propType(&readDesc) !=
                                            TypeNil });
            
            showList(read_lst, 'read ');
            "<.p>";
            
            /* Get a list of thing we could look inside. */
            local li_lst = exa_lst.subset({o: o.contType == In || o.remapIn !=
                                          nil});
            
            showList(li_lst,'look in ');
            
            "<.p>";
            
            /* Get a list of things we could listen to */
            local listen_lst = scope_lst.subset({o: o.propType(&listenDesc) !=
                                               TypeNil});
            
            showList(listen_lst, 'listen to ');
            
            
            /* Get a list of things we could smell. */
            local smell_lst = scope_lst.subset({o: o.propType(&smellDesc) !=
                                               TypeNil});
            
            showList(smell_lst, 'smell ');
        
            
            
        }
        
        /* 
         *   From this point on we're suggesting commands to manipulate objects
         *   in various ways, so we'll reduce the scope list to things the
         *   player character can actually touch.
         */
        
        scope_lst = scope_lst.subset({o:  Q.canReach(gPlayerChar, o)});
        
        /* Things can be moved if they're not fixed in place. */
        local move_lst = scope_lst.subset({o: !o.isFixed });
        
        
        if(num == 3)
        {
                     
            "Some possibilities include:\n";
            
            gAction = Take;
            
            local take_lst = move_lst.subset({o: Take.verify(o,
                DirectObject).allowAction});            
            
            if(excludeCheckFailures)
                take_lst = take_lst.subset({o: passCheck(Take, o) });
            
            /* 
             *   If we still have too many in the list, exclude any that have
             *   already been moved.
             */
            if(take_lst.length > maxObjs)
                take_lst = take_lst.subset({o: !o.moved});
            
            /*  
             *   If we still have too many, sort them in the order in which they
             *   were last moved.
             */
            if(take_lst.length > maxObjs)
                take_lst = take_lst.sort(SortAsc, {a, b: a.turnLastMoved -
                                         b.turnLastMoved});
            
            
            showList(take_lst, 'take ');            
            
            if(take_lst.length > 1)
                "<<aHref('take all', 'take all')>>";
                        
            "<.p>";
            
            gAction = Drop;
            
            local drop_lst = move_lst.subset({o: o.isDirectlyIn(gPlayerChar)});
            
            if(drop_lst.length > maxObjs)
                 drop_lst = drop_lst.sort(SortAsc, {a, b: a.turnLastMoved -
                                         b.turnLastMoved});
            
            showList(drop_lst, 'drop ');            
            
            if(drop_lst.length > 1)
                "<<aHref('drop all', 'drop all')>>";
            
            "<.p>";
            
            local put_lst = move_lst;
            
            if(put_lst.length() > maxObjs)
                put_lst = put_lst.subset({o: !o.moved});
            
            if(put_lst.length > maxObjs)
                 put_lst = drop_lst.sort(SortAsc, {a, b: a.turnLastMoved -
                                         b.turnLastMoved});
            
            gAction = PutIn;
            local put_in_lst = scope_lst.subset({o: (o.contType == In &&
                !o.isLocked) || (o.remapIn != nil && !o.isLocked)});
            
            put_in_lst = put_in_lst.sort(SortAsc, {a, b: a.turnLastMovedInto -
                                         b.turnLastMovedInto });
            
            
            local i = 1;
            
        in_loop:
            for(local cur in put_lst)
            {
                foreach(local dest in put_in_lst)
                {
                    if(!cur.isOrIsIn(dest) 
                       && (!excludeCheckFailures || checkInsert(cur, dest,
                           PutIn)))
                    {
                        local str = 'put ' + cur.name + ' in ' + dest.name;
                        "<<aHref(str, str)>>\ \ ";
                        
                        if(++i > maxObjs)
                            break in_loop;
                    }
                }
            }
            "<.p>";
            
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
        
        if(num == 4)
        {
            "Some things you could try include:\b";
            
            foreach(local act in manipulationActions)
            {               
                gAction = act;
                gActor = gPlayerChar;
                
                local lst = scope_lst.subset({o: act.verify(o,
                    DirectObject).allowAction});
                
                if(excludeCheckFailures)
                    lst = lst.subset({o: passCheck(act, o) });
                
                local str = act.grammarTemplates[1].findReplace('(dobj)', '');
                
                showList(lst, str);            
            }    
            
            /* 
             *   If the gadgets module is present the player could also try
             *   pushing and pulling buttons and levers.
             */
            if(defined(Button))
            {
                "<.p>";
                local lst = scope_lst.subset({o: o.ofKind(Button) ||
                                             o.ofKind(Lever)});
                
                gAction = Push;
                gActor = gPlayerChar;
                lst = lst.subset({o: Push.verify(o, DirectObject).allowAction});
                
                showList(lst, 'push ');
                
                lst = scope_lst.subset({o: o.ofKind(Lever) });
                
                gAction = Pull;
                gActor = gPlayerChar;
                lst = lst.subset({o: Pull.verify(o, DirectObject).allowAction});
                
                showList(lst, 'pull ');
                
            }
            
            /* LockWith and UnlockWith actions on lockableWithKey items */
            
            local lockLst = scope_lst.subset({o: o.lockability == lockableWithKey
                                            || (o.remapIn &&
                                                o.remapIn.lockability ==
                                                lockableWithKey)});
            
            foreach(local lock in lockLst)
            {
                local key_lst = scope_lst.subset(
                    {o: o.ofKind(Key) &&
                    o.plausibleLockList.indexOf(lock) });
                
                local actstr = lock.isLocked ? 'unlock ' : 'lock ';
                foreach(local key in key_lst)
                {
                    local str = actstr + lock.name + ' with ' + key.name;
                    "<<aHref(str, str)>>\ \ ";
                }
                    
            }
            
            
        }
        
        if(num == 5)
        {
            local actor_lst = scope_lst.subset({o: o.ofKind(Actor) && o !=
                                               gPlayerChar});
            
            if(actor_lst.length == 0)                  
                "Sorry, but there's no one here to talk to right now!\b";
            else    
                showList(actor_lst, 'talk to ');
            
        }
        
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
    
    passCheck(act, obj)
    {
        act.curDobj = obj;
        
        local str = gOutStream.captureOutput({: act.checkAction(nil)});
        
        return  str == '';
    }
    
    
    /* Check whether obj can be inserted in cont */
    checkInsert(obj, cont, act)
    {
        /* If the container has a remapIn object, use that instead */
        if(cont.remapIn != nil)
            cont = cont.remapIn;
                
        gAction = act;
        gDobj = obj;
        local prop = act.checkIobjProp;
        
        local str = gOutStream.captureOutput( {: cont.(prop) });
        
        return str == '';
    }
    
    /* 
     *   The maximum number of objects in a list before we try to reduce that
     *   list.
     */
    maxObjs = 10
    
    
;



VerbRule(CmdMenu)
    numericDobj
    : VerbProduction
    action = CmdMenu
;
    

modify Thing
    turnLastMoved = 0
    turnLastMovedInto = 0
    
    actionMoveInto(dest)
    {
        inherited(dest);
        turnLastMoved = gTurns;
        dest.turnLastMovedInto = gTurns;
        if(dest.ofKind(SubComponent) && dest.lexicalParent)
            dest.lexicalParent.turnLastMovedInto = gTurns;
    
    }
;