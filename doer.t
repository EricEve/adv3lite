#charset "us-ascii"
#include "advlite.h"


/*
 *   **************************************************************************
 *   doer.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve, but is
 *   heavily based on parts of the Mercury library (c) 2012 Michael J. Roberts.
 */

/*  
 *   A Redirector is an object that can redirect one action to another via a
 *   doInstead wrapper method that provides a common interface. Subclasses are
 *   responsible for implementing the redirect method.
 *
 *   We begin this module by defing the Redirector class since in adv3Lite
 *   (though not in Mercury) Redirector is the base class for Doer.
 */
class Redirector: object
    
    /* 
     *   doInstead() turns the current action into altAction with the objects
     *   specified in args, and executes altAction as a replacement for the
     *   current action.
     */
    doInstead(altAction, [args])
    {
        doOtherAction(true, altAction, args...);
    }
    
    /* 
     *   doNested() executes altAction with the objects specified in args,
     *   executins altAction as part of the current action.
     */
    doNested(altAction, [args])
    {
        doOtherAction(nil, altAction, args...);
    }
    
    /* 
     *   Execute altAction on the objects specified in the args parameter. If
     *   isReplacement is true make altAction a replacement for the current
     *   action.
     */
    doOtherAction(isReplacement, altAction, [args])
    {
        
        /* Extract our dobj and our iobj from the args parameter. */
        local dobj = args.element(1);
        local iobj = args.element(2);    
        local aobj = args.element(3);
        
        /* 
         *   If the action involves a Literal argument and one of the arguments
         *   is supplied as a single-quoted string, wrap it in a LiteralObject
         *   before passing it.
         */
        if(altAction.ofKind(LiteralAction) || altAction.ofKind(LiteralTAction)
           || aobj != nil)
        {
            if(dataType(dobj) == TypeSString)
                dobj = new LiteralObject(dobj);
            if(dataType(iobj) == TypeSString)
                iobj = new LiteralObject(iobj);
            if(dataType(aobj) == TypeSString)
                aobj = new LiteralObject(aobj);
        }
        
        /*  
         *   If the action involves a Topic object and one of the argumnets is
         *   supplied as a single-quoted string, wrap it in a Topic before using
         *   it.
         */                
        if(altAction.ofKind(TopicAction) || altAction.ofKind(TopicTAction)
           || aobj != nil)
        {
            if(dataType(dobj) == TypeSString)
                dobj = new Topic(dobj);
            if(dataType(iobj) == TypeSString)
                iobj = new Topic(iobj);
            if(dataType(aobj) == TypeSString)
                aobj = new Topic(aobj);
        }
        
        /*   
         *   If the action is a TopicTAction check that the appropriate object
         *   (usually but not necessarily the indirect object) has been passed
         *   as a ResolvedTopic; if not, wrap it in a new Resolved Topic object.
         */
        if(altAction.ofKind(TopicTAction))
        {
            if(altAction.topicIsGrammaticalIobj && !iobj.ofKind(ResolvedTopic))
                iobj = new ResolvedTopic([iobj], iobj.name.split(' '));
            
            if(!altAction.topicIsGrammaticalIobj && !dobj.ofKind(ResolvedTopic))
                dobj = new ResolvedTopic([dobj], dobj.name.split(' '));
            
//            if(!altAction.topicIsGrammaticalAobj && !aobj.ofKind(ResolvedTopic))
//                dobj = new ResolvedTopic([aobj], aobj.name.split(' '));
        }
        
        
               
        /*  
         *   If the new action is of a kind that requires two objects, call the
         *   redirect method with both objects
         */
        if(altAction.ofKind(TIAction) || altAction.ofKind(LiteralTAction) ||
           altAction.ofKind(TopicTAction))
        {
            redirect(gCommand, altAction, dobj: dobj, iobj: iobj, aobj: aobj,
                     isReplacement: isReplacement);
            return;
        }
        
        /*   
         *   If the action is a TopicAction check that its object has been
         *   passed as a ResolvedTopic; if not, wrap it in a new Resolved Topic
         *   object.
         */
        if(altAction.ofKind(TopicAction) && !dobj.ofKind(ResolvedTopic))
        {
            dobj = new ResolvedTopic([dobj], dobj.name.split(' '));
        }
        
        /*  
         *   If the new action requires a single object, call redirect with the
         *   direct object.
         */
        if(altAction.ofKind(TAction) || altAction.ofKind(LiteralAction) ||
           altAction == Go || altAction.ofKind(TopicAction))
        {
            redirect(gCommand, altAction, dobj: dobj, isReplacement:
                     isReplacement);
            return;
        }      
        
        /*  
         *   Otherwise call redirect with the new action alone (it's some form
         *   of intransitve action).
         */
        redirect(gCommand, altAction, isReplacement: isReplacement);
    }
    
    
;


/* ------------------------------------------------------------------------ */
/*
 *   A Doer is a command handler for a specific action acting on particular
 *   objects under a given set of conditions.  We use these for all of the
 *   levels of customization in command handling.
 *   
 *   Doer objects are inherently static.  All Doer objects should be
 *   defined at compile time; they're not designed to be created
 *   dynamically during execution.  Rather than creating and removing Doer
 *   objects as conditions in the game change, use the Doer conditions to
 *   define when a given Doer is active and when it's dormant.  
 */
class Doer: Redirector
    /*
     *   The command that the object handles.  This is a string describing
     *   the action and object combination that this handler recognizes.
     *   
     *   The command string specifies a verb and its objects, generally
     *   using the same verb phrase syntax that a player would use to enter
     *   a command to the game.  The exact verb syntax is up to the
     *   language library to define; for English, we replicate the same
     *   verb phrases used to parse command input.
     *   
     *   The verb phrase syntax is generally the same as for regular player
     *   commands, but the noun syntax is different.  Each noun is written
     *   as the SOURCE CODE name of a game object or class.  That is, not a
     *   noun-and-adjective phrase as the player would type it, but the
     *   program symbol name as it appears in the source code.  If you use
     *   a class name, the command matches any object of the class.  For
     *   example, to handle putting any treasure in any container:
     *   
     *.    cmd = 'put Treasure in Container'
     *   
     *   You can match multiple objects or classes in a single noun slot
     *   (and you can freely mix objects and classes).  For example, to
     *   handle putting any treasure or magic item in a container:
     *   
     *.    cmd = 'put Treasure|Magical in Container'
     *   
     *   You can't use the '|' syntax with verbs, because the verb syntax
     *   covers the entire phrase.  You can match multiple verbs by writing
     *   out the entire phrasing for each verb, separating each phrase with
     *   a semicolon:
     *   
     *.    cmd = 'take skull; put skull in Thing'
     *   
     *   You can also write a command that matches ANY verb, by using "*"
     *   as the verb.  You can follow the "*" with any number of objects;
     *   the first is the direct object, the second is the indirect, and
     *   the third is the accessory.  This phrasing will match any verb
     *   that matches the given objects AND the given number of objects.
     *   For example, '* Thing' will match any verb with a direct object
     *   that's of class Thing, but it won't match verbs without any
     *   objects or verbs with an indirect object.  Using "*" as a noun
     *   will match any object as well as no object at all.  So to write a
     *   handler for every possible command, you'd write:
     *   
     *.    cmd = '* * * *'
     *   
     *   That is, match any verb, with or without any direct object,
     *   indirect object, and accessory object.  
     */
    cmd = ''

    /*
     *   The priority of this handler.  You can use this when it's
     *   necessary to override the default precedence order, which is
     *   figured according to the specialization rules described below.
     *   
     *   Most of the time, you shouldn't need to set a priority manually.
     *   If you don't, the library determines the precedence automatically
     *   according to the degree of specialization.  However, the way the
     *   library figures specialization is a heuristic, so it's not always
     *   right.  In cases where the heuristic produces the wrong results,
     *   you can bypass the rules by setting a priority manually.  A manual
     *   priority takes precedence over all of the standard rules.
     *   
     *   Our basic approach is to process Doers in order from most specific
     *   to most general.  This creates a natural hierarchy of handlers
     *   where more specific rules override the generic, default handlers.
     *   Here are the degrees of specialization, in order of importance:
     *   
     *   1. A Doer with a higher 'priority' value takes precedence over one
     *   with a lower value. 
     *   
     *   2. A Doer with a 'when' condition is more specific than a Doer
     *   without one.  A 'when' condition means that the Doer is designed
     *   to operate only at specific times, so it's inherently more
     *   specialized than one that always operates.
     *   
     *   3. A Doer with a 'where' condition is more specific than a Doer
     *   without one.  A 'where' condition means that the Doer only applies
     *   to a limited geographical area.
     *   
     *   4. A Doer that matches a particular Action is more specific than
     *   one that matches any Action.
     *   
     *   5. If two Doer commands are for the same Action, the Doer that
     *   matches a more specialized subclass (or just a single object
     *   instance) for a noun phrase is more specific than one that matches
     *   a base class for the same noun phrase.  For example, 'take
     *   Container' is more specific than 'take Thing', because Container
     *   is a subclass of Thing, and 'take backpack' (where the 'backpack'
     *   is a Container) is more specific than either.  This type of
     *   specialization applies in the canonical object role order: direct
     *   object, indirect object, accessory.  For example, we consider 'put
     *   Container in Thing' to be more specific than 'put Thing in
     *   Container', because we look at the direct object by itself before
     *   we even consider the indirect object.  This rule only applies when
     *   the Action is the same: 'put Thing in Container' and 'open Door'
     *   are equal for the purposes of this rule.
     *   
     *   It's important to understand that each degree of specialization is
     *   considered independently of the others, in the order above.  For
     *   example, if you have a Doer with just a 'when' condition, and
     *   another with only a 'where' condition, the one with the 'when'
     *   condition has higher priority.  This is because we look at the
     *   presence of a 'when' condition first, before even considering
     *   whether there's a 'where' condition.
     *   
     *   The library has no way to gauge the specificity of a 'when' or
     *   'where' condition, so there's no finer-grained priority to the
     *   conditions than simply their presence or absence.
     *   
     *   If two Doers have the same priority based on the rules above, the
     *   one that's defined LATER in the source code has priority.  This
     *   means that Doers defined in the game take priority over library
     *   definitions.  
     */
    priority = 100

    /*
     *   Execute the command. 
     */
    
    /* 
     *   ECSE ADDED a curCmd parameter (the command being added) to give the Doer
     *   access to what it's meant to be acting on, together with a default
     *   handling (execute the action associated with the current command).
     */
    exec(curCmd)
    {        
        /*
         *   If the command specifies a direction, check that the direction is
         *   valid for the actor's location. This will rule out meaningless
         *   commands like THROW BALL PORT, GO AFT or PUSH TROLLEY STARBOARD
         *   when we're not aboard a vessel.
         */
        if(curCmd.verbProd && curCmd.verbProd.dirMatch != nil)
            checkDirection(curCmd);
	
        /*   
         *   Temporarily set gDobj and gIobj to the dobj and iobj of the curCmd
         *   so that they're available to be passed as parameters
         */        
        gAction.curDobj = curCmd.dobj;
        gAction.curIobj = curCmd.iobj;
        
        /* 
         *   If the command is an action to be carried out by the player
         *   character, execute the action in the normal manner.
         */
        if(curCmd.actor == gPlayerChar)
            execAction(curCmd); 
        
        /* 
         *   If the command is directed to another actor (or object) let the
         *   actor or object in question handle it.
         */
        else
            curCmd.actor.handleCommand(curCmd.action);
    }
    
    /* 
     *   We separate out execAction() as a separate method from exec() so that
     *   custom Doers can readily override this for the player character while
     *   leaving commands directed to other actors (or objects) to be handle by
     *   their handleCommand() method.     */
    
    execAction(curCmd)
    {
        /* 
         *   Our default behaviour is to let the current action handle the
         *   command.
         */
        curCmd.action.exec(curCmd);
    }
    
    /* 
     *   Check whether the direction associatated with this command is valid for
     *   the actor's current location.
     */
    checkDirection(curCmd)
    {
        local dirn = curCmd.verbProd.dirMatch.dir;
        local loc = curCmd.actor.getOutermostRoom();
        
        /* 
         *   Rule out a command involving a shipboard direction where shipboard
         *   directions aren't allowed.
         */
        if(dirn.ofKind(ShipboardDirection) && !loc.allowShipboardDirections())
        {
            DMsg(no shipboard directions, 'Shipboard directions {plural} {have}
                no meaning {here}, ');
            abort;
        }
        
        
        /*
         *   Rule out a command involving a compass direction where compass
         *   directions aren't allowed.
         */
        if(dirn.ofKind(CompassDirection) && !loc.allowCompassDirections)
        {
            DMsg(no compass directions, 'Compass directions {plural} {have}
                no meaning {here}, ');
            abort;
        }
        
        /* 
         *   Set the direction property of the current Command's association
         *   Action object to the direction determined by its
         *   verbProd.dirMatch.dir property in case the game author tries to use
         *   action.direction to get at the direction entered.
         */
        curCmd.action.direction = dirn;
        
    }
    
    /* 
     *   Utility method that can be called from execAction() to redirect the
     *   command to a new action with the same (or new) objects. This will
     *   normally be called via the doInstead()/doNested() interface defined on
     *   our Redirector superclass.
     */    
    redirect(curCmd, altAction, dobj: = 0, iobj: = 0, aobj: = 0,
             isReplacement: = true)
    {
        
        /* 
         *   We use a default value of 0 for the dobj and iobj parameters to
         *   mean 'keep the current value' so that we can explicitly pass nil
         *   values if we want to.
         */             
        dobj = dobj == 0 ? curCmd.dobj : dobj;
        iobj = iobj == 0 ? curCmd.iobj : iobj;
        aobj = iobj == 0 ? curCmd.acc : aobj;
        
        /* 
         *   Get the current command to change its current action to altAction
         *   performed on dobj and iobj. Note that this will change gAction to
         *   altAction.
         */
        curCmd.changeAction(altAction, dobj, iobj, aobj);
        
        /* Execute the command on our new action. */
        gAction.exec(curCmd);
    }
    
    /* 
     *   Set this property to true for this Doer to match only if the wording
     *   corresponds (and not just the action). At the moment the check is
     *   only on the first word of the command, but this may usually be enough
     */
    
    strict = nil
    
    /*  
     *   Flag, do we want to ignore (i.e. not report) an error in the
     *   construction of this Doer. We may want to do this when the error is
     *   simply due to the exclusion of a module like extras.t
     */
    ignoreError = nil
;

/* Define isHappening as a property in case the scenes module is not included */
property isHappening;

/* ------------------------------------------------------------------------ */
/*
 *   A DoerCmd is a helper object that stores a single command match
 *   template for a Doer object.  A given Doer can match multiple commands;
 *   each match is represented by one of these objects.  
 */
class DoerCmd: object
    /* construction */
    construct(d, c)
    {
        doer = d;
        cmd = c;
    }

    /* the Doer I'm associated with */
    doer = nil

    /* 
     *   The parsed command template.  This is a list consisting of the
     *   Action we match plus the objects or classes we match for the noun
     *   phrases, in the canonical order (direct object, indirect object,
     *   accessory).  The action can also be the Action class itself, to
     *   indicate that we match all actions.  We only match a command with
     *   the same number of noun phrases as in the template.  
     */
    cmd = []

    /*
     *   My global sequence number.  During initialization, we set this to
     *   reflect our position in the global list of DoerCmd objects after
     *   the list is sorted into priority order.  This makes it easy to
     *   sort a new list of DoerCmd objects into the original priority
     *   order.  
     */
    seqno = 0

    /*
     *   Class member: the master table of DoerCmd objects.  The library
     *   builds this automatically during preinitialization.  This is a
     *   lookup table indexed by Action.  Each Action entry has a list of
     *   DoerCmd objects associated with that Action.  Note that the
     *   generic all-verb handlers are listed under Action.  
     */
    doerTab = nil

    /*
     *   Class method: Get a list of Doer objects matching the given
     *   command.  'cmdLst' is the command's action and object list in
     *   canonical format: [action, dobj, iobj, accessory].  
     */
    findDoers(cmdLst)
    {
        /* 
         *   Start with a list of the DoerCmd objects that could *possibly*
         *   match this command.  This includes all of the DoerCmds listed
         *   in the master table under the command's action, plus all of
         *   the wildcard "any action" DoerCmds, which are listed in the
         *   table under Action.  
         */
        local lst = nilToList(doerTab[cmdLst[1]])
            + nilToList(doerTab[Action]);

        /* keep only the elements that match the command's objects */
        lst = lst.subset({ d: d.matchCmd(cmdLst) });
        
        /* 
         *   keep only the elements whose where and when conditions don't
         *   exclude them.
         */
        
        lst = lst.subset({ d: d.matchConditions() } );

        /* sort the combined list into the original priority order */
        lst = lst.sort(SortAsc, { a, b: a.seqno - b.seqno });

        /* pull out the list of Doers that the DoerCmds map to */
        lst = lst.mapAll({ d: d.doer });

        /* 
         *   It's conceivable that a given Doer is listed more than once,
         *   since the same Doer could have more than one matching command
         *   template.  In such cases we'd still only want to process each
         *   Doer once, so eliminate any duplicates. 
         */
        lst = lst.getUnique();

        /* return the result */
        return lst;
    }

    /*
     *   Check for a match to a command list.  'cmdLst' is the command
     *   object list in canonical format: [action, dobj, iobj, ...].  This
     *   routine determines if our Doer is a handler for the given command.
     */
    matchCmd(cmdLst)
    {
        /*
         *   The first element of the template is the action.  For the
         *   template to match, the Command's action must either exactly
         *   match the template action, or it must be an instance of the
         *   template action class.  
         */
        if (cmdLst[1] != cmd[1] && !cmdLst[1].ofKind(cmd[1]))
            return nil;

        /*   
         *   If the strict property is set we want the doer to match not only
         *   the command but the wording of the command, or rather, at least the
         *   first word, so that, for example, 'go through junk' would not be
         *   treated as matching 'walk through junk' (in English idiom the first
         *   but not the second might be treated as meaning 'search junk').
         */
           
        
        if (gCommand != nil && doer.strict && gCommand.verbProd.tokenList !=
            nil)
        {
            local cmdToks = gCommand.verbProd.tokenList.mapAll( {x:
                getTokVal(x) });
            local doerToks = doer.cmd.split(' ');
            
            if(cmdToks[1] != doerToks[1])
                return nil;        
        }
        
        /* 
         *   The rest of the template is the list of noun roles, in
         *   canonical order (direct object, indirect object, accessory).
         *   The Command must have the same number of objects, and each
         *   object in the Command must match the corresponding template
         *   object or be an instance of the template object class.
         *   (There's one special case: if the template object is nil, we
         *   match anything.)
         *   
         *   First, check that we have the same number of objects.  
         */
        if (cmdLst.length() != cmd.length())
            return nil;

        /* now check each object */
        for (local i = 2, local len = cmd.length() ; i <= len ; ++i)
        {
            /* get the object from the Command and template */
            local cobj = cmdLst[i];
            local tobj = cmd[i];

            /* 
             *   if the template object is non-nil, we have to match the
             *   object or class 
             */
            if (tobj != nil && cobj != tobj && !cobj.ofKind(tobj))
                return nil;
        }

        /* everything matches, so this Command matches this template */
        return true;
    }

    /*
     *   Get the processing priority sorting order relative to another
     *   DoerCmd.  (See Doer.priority for a discussion of the priority
     *   rules.)
     */
    compareTo(other)
    {
        local p, a, b;
        
        /* the explicitly priority takes precedence over all other rules */
        if (doer.priority != other.doer.priority)
            return doer.priority - other.doer.priority;

        /* a 'when' has priority over no 'when' */
        p = doer.propDefined(&when);
        if (p != other.doer.propDefined(&when))
            return p ? 1 : -1;

        /* a 'where' has priority over no 'where' */
        p = doer.propDefined(&where);
        if (p != other.doer.propDefined(&where))
            return p ? 1 : -1;

         /* a 'who' has priority over no 'where' */
        p = doer.propDefined(&who);
        if (p != other.doer.propDefined(&who))
            return p ? 1 : -1;
        
        /* a 'during' has priority over no 'during' */
        p = doer.propDefined(&during);
            if (p != other.doer.propDefined(&during))
            return p ? 1 : -1;
        
        /* get each command's Action */
        a = cmd[1];
        b = other.cmd[1];
        
        /* 
         *   a 'direction' has priority over no 'direction' for a Travel
         *   command.
         */        
        if(a == Travel)
        {
            p = doer.propDefined(&direction);
            if (p != other.doer.propDefined(&direction))
                return p ? 1 : -1;
        }

        /* 
         *   if one is a specific Action and the other is the generic
         *   'Action' class (a wildcard that matches all actions), the
         *   specific action takes precedence 
         */
        if (a != Action && b == Action)
            return 1;
        if (a == Action && b != Action)
            return -1;

        /* if the actions are the same, compare the objects */
        if (a == b && cmd.length() == other.cmd.length())
        {
            /* 
             *   Check each object role in turn, in canonical order.  The
             *   first one where the precedence differs determines the
             *   overall precedence. 
             */
            for (local i = 2 ; i < cmd.length() ; ++i)
            {
                /* get the two objects */
                a = cmd[i];
                b = other.cmd[i];

                /* 
                 *   if one is a subclass of the other, the subclass takes
                 *   precedence because it's more specialized
                 */
                if (a == nil || b == nil)
                {
                    if (a != nil)
                        return 1;
                    if (b != nil)
                        return -1;
                }
                else
                {
                    if (a.ofKind(b))
                        return 1;
                    if (b.ofKind(a))
                        return -1;
                }
            }
        }

        /* 
         *   Failing all else, go by the relative location of the source
         *   code definitions: the definition that appears later in the
         *   source code takes precedence.  If the two are defined in
         *   different modules, the one in the later module takes
         *   precedence.  
         */
        if (doer.sourceTextGroup != other.doer.sourceTextGroup)
            return doer.sourceTextGroup.sourceTextGroupOrder
            - other.doer.sourceTextGroup.sourceTextGroupOrder;

        /* they're in the same module, so the later one takes precedence */
        return doer.sourceTextOrder - other.doer.sourceTextOrder;
    }
    
    /* Check whether a Doer matches its where, when, who and during conditions. */    
    matchConditions()    
    {
        /* first check the where condition, if there is one. */
        if(doer.propDefined(&where))
        {
            local whereLst = valToList(doer.where);
                                    
            /* 
             *   if we can't match any item in the where list to the player
             *   char's current location, we don't meet the where condition, so
             *   return nil
             */
            if(whereLst.indexWhich( {loc: gPlayerChar.isIn(loc)}) == nil)
                return nil;
        }
        
        /* 
         *   Interpret 'when' as simply a routine that returns true or nil
         *   aocording to some condition defined by the author; so we simply
         *   test whether doer.when returns nil if the property is defined.
         */        
        if(doer.propDefined(&when) && doer.when() == nil)
            return nil;       
        
         /* check the who condition, if there is one. */
        if(doer.propDefined(&who))
        {
            local whoLst = valToList(doer.who);
                        
            
            /* 
             *   If we can't match any item in the who list to the current
             *   actor, we don't meet the who condition, so return nil
             */
            if(whoLst.indexOf(gCommand.actor) == nil)
                return nil;
        }
        
        
        /* 
         *   if we're using the scene manager and a during condition is
         *   specified, test whether the scene is currently happening.
         */        
        if(defined(sceneManager) && doer.propDefined(&during))
        {
            local duringList = valToList(doer.during);
            
            if(duringList.indexWhich({s: s.isHappening}) == nil)
                return nil;
        }
        
        /* 
         *   If the command is a travel action and a direction has been
         *   specified, check that we match the direction.
         */
        if(doer.propDefined(&direction) && cmd[1] is in (Travel,
            PushTravelDir, ThrowDir))
            return valToList(doer.direction).indexOf(
                gCommand.verbProd.dirMatch.dir) != nil;
        
        /* 
         *   If we haven't failed any of the conditions, we're okay to match, so
         *   return true.
         */
        return true;
    }
;



/* ------------------------------------------------------------------------ */
/*
 *   A DoerParser is a helper object we use during initialization for
 *   parsing Doer 'cmd' strings and turning them into action description
 *   lists.  The language-specific library creates these for us based on
 *   the language grammar.
 *   
 *   These objects are only used during initialization, since they're only
 *   needed to set up the internal representation of a Doer command
 *   template string.  During normal play we only need that internal
 *   representation.  
 */
class DoerParser: object
    /*
     *   Construction.  The language library should create one of these
     *   objects for each verb phrasing it wants to define for use in
     *   writing Doer 'cmd' strings.  
     */
    construct(action, v, pat, roles)
    {
        action_ = action;
        verb_ = v;
        pat_ = new RexPattern('<space>*' + pat + '<space>*$');
        roles_ = roles;
    }

    /* The Action object for the verb. */
    action_ = nil

    /* 
     *   The main verb word.  This is simply the first word of the verb's
     *   token list.  This is essentially a hash, to reduce the number of
     *   regular expressions we have to test individually.  This saves us a
     *   lot of compute time, since it's very quick to pull out the first
     *   word and get a list of the small set of rules with the same first
     *   word.  We then test each of those potential matches by doing the
     *   full regular expression comparison.  
     */
    verb_ = nil

    /* 
     *   The regular expression for the verb rule.  The verb initializer
     *   sets this up to contain the literal text of the verb rule's
     *   literal tokens, and to substitute a parenthesized group wildcard
     *   pattern for each noun slot.  For example, for English, a Give To
     *   rule might look like 'give (.+) to (.+)'.  
     */
    pat_ = nil

    /* 
     *   The list of object roles.  This is a list of NounRole objects.
     *   The list entries correspond positionally to the parenthesized
     *   groups in the regular expression string, so roles_[1] is the noun
     *   role for the first parenthesized group, roles_[2] is the noun role
     *   for the second group, and so on.  
     */
    roles_ = []
;


/* ------------------------------------------------------------------------ */
/*
 *   DoerParser Table.  This stores a lookup table of DoerParser objects,
 *   indexed by the first word (the verb) of the command template.  
 */
class DoerParserTable: object
    /* add a parser to the table */
    addParser(p)
    {
        /* get the verb from the parser */
        local v = p.verb_;

        /* make sure there's a list at the verb entry */
        if (ptab[v] == nil)
            ptab[v] = [];

        /* add this parser to the list for its verb */
        ptab[v] += p;
    }

    /* get the list of parsers for a given verb word */
    getParsers(v)
    {
        /* look up the list */
        local lst = ptab[v];

        /* return the list, or an empty list if the verb is unknown */
        return (lst != nil ? lst : []);
    }

    /* the lookup table */
    ptab = perInstance(new LookupTable(64, 128))
;

/*
 *   Initialize the Doer objects.  This parses each Doer's command string
 *   to generate a list of command templates.  
 */
doerPreinit: PreinitObject
    execute()
    {              
               
        /* initialize the DoerParser objects */
        local ptab = new DoerParserTable();
        initDoerParsers(ptab);

        /* get the global symbols */
        local gtab = t3GetGlobalSymbols();

        /* get the predicate noun phrase list */
        local roles = NounRole.allPredicate;

        /* 
         *   Add the special "any verb" wildcard verbs.  Add one for each
         *   subset of the roles list.  (The role subsets are always
         *   cumulative, because we don't ever have a later role without
         *   also including all of the earlier roles.  E.g., if a verb
         *   takes an indirect object, it must take a direct object as
         *   well.)  
         */
        local pat = '<star>';
        local npat = ' (<alphanum|_|vbar|star>+)';
        for (local i = 0 ; i <= roles.length() ; ++i, pat += npat)
        {
            ptab.addParser(new DoerParser(
                Action, '*', pat, roles.sublist(1, i)));
        }
        
        /* set up an empty list of command template (DoerCmd) objects */
        local tlst = new Vector(100);

        /* call the language-specific parser for each Doer's command string */
        forEachInstance(Doer, new function(d)
        {
            /* get the string to parse */
            local c = d.cmd;

            /* 
             *   split it into commands - a given Doer might match multiple
             *   commands 
             */
            local clst = c.split(';');
  
                        
            /* process each command */
            foreach (c in clst)
            {
                /* check for direction names in the command */
                local tokList = c.split(R'<space|vbar>');
                
                foreach(local tok in tokList)
                {
                    local dir = Direction.nameTab[tok];
                    if(dir != nil)
                    {                        
                        d.direction = valToList(d.direction) + dir;
                    }
                }
                
                /* pull out the first word of the command */
                rexMatch(R'<space>*(<alphanum|star>+)', c);

                /* match it against each template with the same first word */
                local found = nil;
                foreach (local p in ptab.getParsers(rexGroup(1)[3]))
                {
                    /* if we match this item's template, this is the one */
                    if (rexMatch(p.pat_, c))
                    {
                        /* 
                         *   It matches.  Set up the initial action template
                         *   with just the action. 
                         */
                        local tpl = [p.action_];
                        
                        /* 
                         *   Add each noun slot.  Note that we need to add
                         *   the nouns in the canonical order: dobj, iobj,
                         *   accessory.  This might differ from the order
                         *   of the noun phrases in the verb; for example,
                         *   Give To in English can be phrased as "give
                         *   dobj to iobj" or as "give iobj dobj" - the
                         *   second form uses the reverse of the canonical
                         *   order.  We must always use the canonical
                         *   ordering for the template, regardless of how
                         *   the verb is phrased.  
                         */
                        foreach (local r in roles)
                        {
                            /* 
                             *   find this role in the template list order
                             *   - this tells us which parenthesized group
                             *   it matches in the regular expression for
                             *   the verb template 
                             */
                            local idx = p.roles_.indexOf(r);
                            
                            /* 
                             *   If the role isn't in the verb, we're done.
                             *   A verb with an indirect object always has
                             *   a direct object, and a verb with an
                             *   accessory always has direct and indirect
                             *   objects, so if this role isn't in the
                             *   verb's list, we know there are no more
                             *   roles to find.  
                             */
                            if (idx == nil)
                                break;
                            
                            /* get the regular expression match */
                            local n = rexGroup(idx)[3];

                            /* add it to the template list */
                            tpl += n;
                        }

                        /* expand "noun|noun" constructions */
                        expandNounLists(gtab, d, tlst, tpl, 2);

                        /* we found a match, so we can stop looking */
                        found = true;
                        break;
                    }
                }

                /* if we didn't a match, note the error */
                if (!found && d.ignoreError == nil)
                {
                    "Error in Doer command phrase \"<<d.cmd>>\": this
                    command syntax doesn't match any known verb grammar.";
                }
            }
        });

        /* sort the DoerCmd list by descending precedence */
        tlst.sort(SortDesc, { a, b: a.compareTo(b) });

        /* build the master table of DoerCmd objects */
        local dtab = DoerCmd.doerTab = new LookupTable(64, 128);
        local seqno = 1;
        foreach (local d in tlst)
        {
            /* 
             *   Set this item's global sequence number.  This lets us
             *   quickly sort into the original priority order when we
             *   combine two lists. 
             */
            d.seqno = seqno++;

            /* get this item's Action - it's the first template item */
            local action = d.cmd[1];

            /* make sure this entry has a list */
            if (dtab[action] == nil)
                dtab[action] = [];

            /* add this item to this action entry's list */
            dtab[action] += d;
        }
    }

    /*
     *   Expand an initial template list.  This takes a list of the form
     *   [action, 'a|b|c', 'd|e|f'], and converts it into multiple lists
     *   with an individual noun in each slot.  
     */
    expandNounLists(gtab, d, tlst, tpl, idx)
    {
        /* 
         *   if we've run out of slots, we have a fully expanded template,
         *   so simply add the current template to the results and return 
         */
        if (idx > tpl.length())
        {
            tlst.append(new DoerCmd(d, tpl));
            return;
        }

        /* process the list of elements for the current item */
        foreach (local item in tpl[idx].split('|'))
        {
            /* look up the object name in the symbol table */
            local obj = gtab[item];

            /* if we didn't find it, note the error */
            if (obj == nil && item != '*')
            {
                /* explain the problem */
                if(!d.ignoreError)
                    "Error in Doer command phrase \"<<d.cmd>>\": the word \"<<
                      item>>\" is not a known object or class name.
                    Each noun must be the source code name of an object
                    or class.\n";

                /* abort processing this template */
                return;
            }

            /* build the simplified list with the current single item */
            local stpl = tpl;
            stpl[idx] = obj;

            /* recursively process the rest of the list */
            expandNounLists(gtab, d, tlst, stpl, idx + 1);
        }
    }
    
    
;

/* 
 *   Define four DefaultDoers that between them will match any command unless a
 *   more specialized Doer intervenes. This allows most commands to be executed
 *   by the appropriate action.
 */

default4Doer: Doer
    cmd = '* * * *'
;

default3Doer: Doer
    cmd = '* * *'
;

default2Doer: Doer
    cmd = '* *'
;

default1Doer: Doer
    cmd = '*'
;
