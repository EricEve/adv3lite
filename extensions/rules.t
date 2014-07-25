#charset "us-ascii"
#include "advlite.h"

/* 
 *   RULES EXTENSION by Eric Eve July 2014
 *
 *   The rules.t extension allows Inform7-style rules and rulebooks to be
 *   defined in a TADS 3 game.
 */




/* 
 *   A RuleBook is a container for one or more rules. Calling the follow()
 *   method of a RuleBook causes each of its contained rules to be executed in
 *   turn until one returns a non-null value. That value is then returned to the
 *   caller of the RuleBook. [DEFINED IN RULES EXTENSION]
 */
     
class RuleBook: PreinitObject    
    
    /* A list of rules contained in this rulebook */
    contents = []
    
    /* 
     *   The actor to use for comparison with the who property for rules in this
     *   RuleBook. The default is gPlayerChar, but for some RuleBooks gActor may
     *   be more appropriate.
     */
    actor = gPlayerChar
    
    /* Add a rule to the contents of this rulebook */
    addToContents(ru)
    {
        contents += ru;
    }
    
    /* Remove a rule from the contents of this rulebook */
    removeFromContents(ru)
    {
        contents -= ru;
    }
    
    
    /* 
     *   Follow this Rule. This is the method game code will normally call to
     *   make use of this RuleBook. Each of our rules will be tested to see if
     *   it matches its conditions; we then run through those of our rules that
     *   match their rules in order of precedence until one returns a non-null
     *   value, which we then in turn return to our caller. If no rule returns a
     *   non-null value we return our own default value, which is normally nil.
     *
     *   This method can be called with as many arguments as the game code finds
     *   useful, or with none at all. Our arguments will then be passed on to
     *   each Rule that is called. The first argument will also be stored in our
     *   matchObj property, which our Rules can compare with their own matchObj
     *   condition to see if they match. This allows game code to, for example,
     *   run a RuleBook related to some object that isn't one of the objects
     *   directly involved in the current action.
     */
    follow([args])
    {
        /* 
         *   If we have any arguments at all, store the first one in our
         *   matchObj property for comparison with our Rules' matchObj
         *   conditions.
         */
        if(args.length > 0)
            matchObj = args[1];
        
        /* Carry out any custom initialization required. */
        initBook(args...);
        
        /* 
         *   Make sure that all the Rules in our contents list know that we're
         *   the RuleBook that's currently calling them. This is necessary in
         *   case the same Rule is associated with more than one RuleBook.
         */
        contents.forEach({ r: r.setRulebook(self) });
        
        /* Extract the subset of Rules that match their conditions. */
        local validRules = contents.subset({r: r.matchConditions});
        
        /* Sort the matching rules in descending order of precedence. */
        validRules = validRules.sort(SortDesc, {a, b: a.compareTo(b)} );
        
        /* 
         *   Go through each of the matching rules in turn, calling it's follow
         *   method. If any rule returns a non-null value, stop running through
         *   the rules and return that value to our caller.
         */
        foreach(local ru in validRules)
        {
            local res = ru.follow(args...);
            
            if(res != contValue)
                return res;
        }
        
        /* 
         *   If no rule returned a non-null value, return our own defaultVal to
         *   our caller.
         */
        return defaultVal;
    }
    
    
    /* 
     *   contValue (continue value) is the value that a Rule in this RuleBook
     *   needs to return to avoid the RuleBook stopping at that Rule (rather
     *   than going on to consider more Rules). By default this is null, which
     *   means by default a Rule that does not explicitly return a value (and so
     *   effectivelt returns nil) will stop the RuleBook. If you want the
     *   default behaviour for this RuleBook to be not for Rules to stop the
     *   book, then override this to nil.
     */
    contValue = null
    
    /*  
     *   The default value to return to our caller. By default this is the same
     *   as our contValue , to make it easy to test whether we any rule returned
     *   a non-null value. By default a rule that does something will return
     *   nil, so if no rule does anything we want to return a different value.
     *   By making the defaultValue the same as the contValue, we ensure that we
     *   can tell our caller that no rule was executed (if that is indeed the
     *   case).
     */
    defaultVal = contValue
    
    /*   
     *   The value our associated rules use by default to stop this RuleBook
     *   considering any further rules (when a Rule uses the stop macro). By
     *   default we use a value of true.
     */
    
    stopValue = true
    
    /* 
     *   Game code can use this method to initialize the values of custom
     *   RuleBook properties at the start of the processing of following a
     *   RuleBook.
     */
    initBook([args]) { }
    
    /*   
     *   The object (or any other value) to be matched by our Rule's matchObj
     *   conditions if they have any. This property is set by our follow()
     *   method (from its first argument) and so should not normally be directly
     *   changed from game code.
     */
    matchObj = nil
    
;

/* Preinitializer for Rules. [DEFINED IN RULES EXTENSION]*/
rulePreinit:PreinitObject
    execute()
    {
        /* Initialize all the Rules in the game. */
        for(local ru = firstObj(Rule); ru != nil; ru = nextObj(ru, Rule))
        {
            ru.initializeRule();
        }       
    }
;


/* 
 *   A Rule is an object that defines a set of conditions that need to be met
 *   for it to be executed when its RuleBook is run and a method that's executed
 *   when its conditions are met. A Rule can be associated with one or more
 *   RuleBooks; it starts out in the RuleBook with which it is associated via
 *   its + property (i.e. its location). [DEFINED IN RULES EXTENSION]
 */
class Rule: object
    /* 
     *   Our location is the RuleBook with which we start out being associated.
     *   Normally this will be defined by locating a Rule inside its RukeBook
     *   using the + notation.
     */
    location = nil
    
    /*   
     *   The rulebook that's currently considering us. Normally this will be our
     *   location, but it could be a different RuleBook if we belong to one.
     *   Note that this property is automatically set by the library and so it
     *   should never need to be altered by game code.
     */
    rulebook = location
      
    /*   
     *   Set our current rulebook to r. Note that this method is normally called
     *   by the Rulebook that's running us, and shouldn't normally be used by
     *   game code.
     */
    setRulebook(r) { rulebook = r; }
    
    /*   A list of all the rulebooks this rule is currently associated with. */
    rulebooks = []    
    
    /*   
     *   Initialize this Rule by adding it to the contents list of its location
     *   and calculating its specificity (i.e. how specific its conditions are)
     */
    initializeRule()
    {
        if(location)
        {
            location.addToContents(self);               
            rulebooks += location;
        }
        
        specificity = calcSpecficity();
    }
    
    /* 
     *   Do whatever this Rule needs to do when its conditions are met. This
     *   method will need to be defined on eacg individual Rule in game code.
     */
         
    follow([args])
    {
    }
    
    /* 
     *   The priority of this Rule. This can be used to alter the order in which
     *   this Rule is considered in its RuleBook. If two Rules have different
     *   priorities they will be run in priority order, highest priority first.
     *   The default value is 100.
     */ 
    priority = 100
    
    /*   
     *   Where two Rules have the same priority, the one with the more specific
     *   conditions is taken first. The specificity property holds a measure of
     *   the Rule's specificity which is calculated by the calcSpecificity()
     *   method at PreInit.
     */
    specificity = nil
    
    /* 
     *   Return true if this Rule should always execute after other (despite all
     *   other ranking criteria). By default we return true if and only if other
     *   is in our execAfter list.
     */   
    runAfter(other)
    {
        return valToList(execAfter).indexOf(other) != nil;        
    }
    
    /* 
     *   A list of Rules this Rule should specifically run after; this overrides
     *   all other ranking.
     */
    execAfter = []
    
    /* 
     *   Return true if this Rule should always execute before other (despite all
     *   other ranking criteria). By default we return true if and only if other
     *   is in our execBefore list.
     */
    runBefore(other)
    {
        return valToList(execBefore).indexOf(other) != nil;
    }
    
    /*  
     *   A list of Rules this Rule should specifically run before; this
     *   overrides all other ranking except for runAfter/execAfter.     
     *
     */
    execBefore = []
    
    /*  
     *   A Rule is normally active (that is it will normally be considered when
     *   a RuleBook is being followed) but it can be temporarily disabled by
     *   setting its isActive property to nil.
     */
    isActive = true

    /* Make this Rule active */
    activate() { isActive = true; }
    
    /* Make this Rule inactive */
    deactivate() { isActive = nil; }
    
    /*
     *   Calculate the specificity of this Rule. The principles are (a) Rules
     *   that specify more conditions are more specific than Rule that specify
     *   fewer condition; (b) conditions involving specific objects are more
     *   specific that those relating to classes and (c) Rooms are more specific
     *   than Regions in a where condition.
     */
    calcSpecficity()
    {       
        local p = 0;
       
        /* a 'when' has priority over no 'when' */
        if(propDefined(&when))
            p += 10;
        
        /* 
         *   a 'where' has priority over no 'where', and a where property that
         *   specifies a Room is more specific than one that specifies a Region.
         */
        if(propDefined(&where))
            p += valToList(where).indexWhich({r: r.ofKind(Room)}) ? 10 : 5;
        
        /* a 'during' has priority over no 'during' */
        if(propDefined(&during))
            p += 10;
        
        /* a 'who' has priority over no 'who' */
        if(propDefined(&who))
            p += 10;
        
        /* an 'action' has prioity over no 'action' */
        if(propDefined(&action))
        {
            p += 5;
        }
        
        /* 
         *   A Rule that refers to command objects (direct, indirect and
         *   accessory) is more specific than one that does not, and particular
         *   objects are more specific than classes.
         */
        for(local prop in [&dobj, &iobj, &aobj])
        {
            if(propDefined(prop))
            {
                p += valToList(self.(prop)).indexWhich( {x: !x.isClass()} ) !=
                nil ? 2 : 1;
            }                
        }
        
        /* 
         *   If matchObj is defined, then what we do with it depends on the type
         *   of value(s) it contains.
         */
        if(propDefined(&matchObj))
        {
            switch(propType(&matchObj))
            {
                /* If matchObj is nil, then ignore it. */
            case TypeNil:
                break;
                
                /* 
                 *   If it's an object, increase our specificity by 10, unless
                 *   it's a class, in which case only increase it by 5 (a class
                 *   is less specific than an object).
                 */
            case TypeObject:
                p += (matchObj.isClass ? 5 : 10);
                break;
                /* 
                 *   If it's a list, check what kind of values the list
                 *   contains.
                 */
            case TypeList:
                /*  
                 *   If the first item in the list is an object, assume the
                 *   whole list contains objects, then increase our specificity
                 *   by 10 if any of those objects is not a class, and by 5
                 *   otherwise (classes are less specific than objects).
                 */
                if(matchObj.length > 0 && dataType(matchObj[1]) == TypeObject)
                {
                    if(matchObj.indexWhich({o: !o.isClass}))
                        p += 10;
                    else
                        p += 5;
                }
                /* 
                 *   Otherwise, if it's some other kind of value, simply
                 *   increase our specificity by 10.
                 */
                else
                    p += 10;
                
                break;
                /* 
                 *   For any other kind of value, simply increase our
                 *   specificity by 10.
                 */
            default:
                p += 10;
                break;
                
            }
        }
        
        /* Check if our present property is defined. */
        if(propDefined(&present))
        {
            if(dataType(&present) == TypeObject && present.isClass)
                p += 5;
            else
                p += 10;
        }
           
        
        
        /* Return the result of the calculation. */
        return p;       
    }
    
    
    /*
     *   Get the processing priority sorting order relative to another
     *   Rule. 
     */
    compareTo(other)
    {
        /*  
         *   If we specifically want this Rule to run after other, rank us after
         *   other
         */
        if(runAfter(other))           
            return -1;        
        
        /*   
         *   If we specifically want this Rule to run before other, rank us
         *   before other.
         */
        if(runBefore(other))
            return 1;        
        
        /* 
         *   If the two Rules have different priorities, rank them in order of
         *   priority.
         */
        if(priority != other.priority)   
            return priority > other.priority ? 1 : -1;
        
        /*  
         *   Otherwise, if they have different speficifities, rank them in order
         *   of specificity.
         */
        if(specificity >= other.specificity)
            return specificity > other.specificity ? 1 : -1;
        
        /* 
         *   Failing all else, go by the relative location of the source
         *   code definitions: the definition that appears later in the
         *   source code takes precedence.  If the two are defined in
         *   different modules, the one in the later module takes
         *   precedence.  
         */
        if (sourceTextGroup != other.sourceTextGroup)
            return sourceTextGroup.sourceTextGroupOrder
            - other.sourceTextGroup.sourceTextGroupOrder;

        /* they're in the same module, so the later one takes precedence */
        return sourceTextOrder - other.sourceTextOrder;
        
    }
    
    /* Check whether a Rule matches its where, when, who and during conditions. */    
    matchConditions()    
    {
        /* If this Rule is currently inactive it can't match any conditions. */
        if(!isActive)
            return nil;
        
        /* first check the where condition, if there is one. */
        if(propDefined(&where))
        {
            local whereLst = valToList(where);
                                    
            /* 
             *   if we can't match any item in the where list to the player
             *   char's current location, we don't meet the where condition, so
             *   return nil
             */
            if(whereLst.indexWhich( {loc: gActor.isIn(loc)}) == nil)
                return nil;
        }
        
        /* 
         *   Interpret 'when' as simply a routine that returns true or nil
         *   aocording to some condition defined by the author; so we simply
         *   test whether when returns nil if the property is defined.
         */        
        if(propDefined(&when) && when() == nil)
            return nil;       
        
         /* check the who condition, if there is one. */
        if(propDefined(&who))
        {
            local whoLst = valToList(who);
                        
            
            /* 
             *   If we can't match any item in the who list to the current
             *   actor, we don't meet the who condition, so return nil
             */
            if(whoLst.indexOf(gActor) == nil)
                return nil;
        }
        
        
        /* 
         *   if we're using the scene manager and a during condition is
         *   specified, test whether the scene is currently happening.
         */        
        if(defined(sceneManager) && propDefined(&during))
        {
            local duringList = valToList(during);
            
            if(duringList.indexWhich({s: s.isHappening}) == nil)
                return nil;
        }
        
        /* 
         *   If we've specified an action to match, test whether gAction (the
         *   current action) matches it.
         */
        if(propDefined(&action) 
           && valToList(action).indexWhich({a: gAction.ofKind(a)}) == nil)
            return nil;
        
        
        /*  
         *   If we've specified a dobj, iobj and/or aobj to match, test whether
         *   they match the direct object, indirect object and/or accessory
         *   object of the current action (provided there is one, which there
         *   may not be at startup).
         */
        if(gAction)
        {
            for(local objs in [[&dobj, gDobj], [&iobj, gIobj], [&aobj, gAobj]])
            {
                local prop = objs[1];
                local obj = objs[2];
                
                if(propDefined(prop) 
                   && valToList(self.(prop)).indexWhich({o: obj.ofKind(o)}) == nil)
                    return nil;          
                
            }
        }
        
        /* 
         *   If we have a matchObj defined, test whether it matches our current
         *   rulebook's matchjObj.
         */
        if(propDefined(&matchObj))
        {
            local mList = valToList(matchObj);
            local mo = rulebook.matchObj;
            
            if(mList.length > 0)
            {
                /* 
                 *   If we want to match an object (or class), test whether the
                 *   rulebook's match obj is of the appropriate kind. Since an
                 *   object is always of its own kind, this tests either whether
                 *   the rulebook's matchObj appears in our matchObj list or
                 *   whether it belongs to one of the classes in our matchObh
                 *   list.
                 */
                if(dataType(mList[1]) == TypeObject)
                {
                    if(mList.indexWhich({o: mo.ofKind(o) } ) == nil)
                        return nil;
                }
                /* 
                 *   Otherwise, if we're not testing for an object, simply test
                 *   whether the value of our rulebook's matchObj is equal to
                 *   anyhting in our matchObj property.
                 */
                else if(mList.indexOf(mo) == nil)
                    return nil;               
                    
            }
        }       
        
        /* 
         *   If present is defined, check whether at least one of the items in
         *   the list is in the same room, or can be sensed.
         */
        if(propDefined(&present))
        {
            local pList = valToList(present);
            
            /* 
             *   First test for the special case that the present property
             *   specifies a single class. In which case whether anything in the
             *   location of actor matches that class.
             */            
            if(pList.length == 1 && dataType(pList[1]) == TypeObject &&
               pList[1].isClass())                
            {
                if(actor.getOutermostRoom.allContents.indexWhich(
                    {o: o.ofKind(present) }) == nil)
                    return nil;
            }
            
            /* 
             *   Check whether the first item in list is a property pointer. If
             *   it is we want to use it as a property of the Q object to test
             *   for a sense connection.
             */
            else if(pList.length > 0 && dataType(pList[1]) == TypeProp)
            {
                /* The first item in the list is a property pointer. */
                local prop = pList[1];
                
                /*  
                 *   Reduce the list to its remaining elements, which should all
                 *   be objects.
                 */
                pList = pList.sublist(2);
                
                /*  
                 *   If no item in pList has a sense path from the actor via the
                 *   prop property, we don't match.
                 */
                if(pList.indexWhich({o: Q.(prop)(actor, o) }) == nil)
                   return nil;
            }
            /* 
             *   Otherwise, simply test for the presence of one of the objects
             *   in the actor's room.
             */
            else
            {
                local loc = actor.getOutermostRoom();
                
                if(pList.indexWhich({o: o.isIn(loc)}) == nil)                    
                    return nil;
            }           
        }
        
        
        /* 
         *   If we haven't failed any of the conditions, we're okay to match, so
         *   return true.
         */
        return true;
    }
    
    /* Add this rule to another rulebook */
    addTo(rb)
    {
        if(rb && rb.ofKind(RuleBook))
        {
            rb.addToContents(self);
            rulebooks += rb;
        }
    }
    
    /* Remove this rule from a rulebook */    
    removeFrom(rb)
    {
        if(rb && rb.ofKind(RuleBook))
        {
            rb.removeFromContents(self);
            rulebooks -= rb;
            
            if(location == rb)
                location = nil;
        }
    }
    
    /* 
     *   Move this rule to another rulebook, removing it from all its current
     *   rulebooks. If rb is nil, simply remove this Rule from its current
     *   rulebooks.
     */
     
    moveInto(rb)
    {        
        
        /* 
         *   If rb is actually a RuleBook, add us to its contents and make rb
         *   our current location.
         */
        if(rb && rb.ofKind(RuleBook))
        {
            rb.addToContents(self);
            
            location = rb;
        }
        
        /* 
         *   Remove us from the contents of all our previous rulebook
         */
        rulebooks.forEach({r: r.removeFromContents(self)});
        
        /* Add our new RuleBooks to our list of rulebooks */
        if(rb)
            rulebooks += rb;
        
        /* Make rb our currently active rulebook */
        rulebook = rb;
        
    }
    
    /*  
     *   The value this rule should return when the stop macro is used at the
     *   end of its follow method. By default we use our rulebook's stopValue.
     */
    stopValue = (rulebook.stopValue)
    
    /* 
     *   The actor to use to compare with the who property of this Rule. This
     *   will normally be gPlayerChar, but the value of this property is taken
     *   from our RuleBook's actor property.
     */
    actor = (rulebook == nil ? gPlayerChar : rulebook.actor)
    
    
    /* ------------------------------------------------------------------- */ 
     /* 
      *   One or more of the following properties, if defined, determine what
      *   conditions this Rule needs to match in order to be executed.
      */
      
    /* 
     *   A Room or Region, or a list of Rooms and/or Regions in which our actor
     *   (usually either gActor or gPlayerChar - the latter by default - must be
     *   for this Rule to match.
     */
    // where = []
    
    /*  
     *   A condition that must hold (or a method returning a Boolean value to
     *   determine whether or not appropriate conditions hold) for this Rule to
     *   match. This is only needed if none of the other properties in this
     *   section provide a way of speficifying the required conditions.
     */
    // when() {}
    
    /* 
     *   An actor, or a list of actors, one of whom must be performing the
     *   current action for this Rule to match.
     */
    // who = []
    
    /*  
     *   A Scene, or a list of Scenes, one of which much be currently happening
     *   for this Rule to match.
     */
    // during = []
    
    /* 
     *   An action, or a list of Actions, one of which (e.g. Take or Jump) must
     *   be the current action in order for this Rule to match.
     */
    // action = []
    
    /* 
     *   An object (or class), or a list of objects (and or classes) one of
     *   which of each the direct, indirect and accessory objects of the current
     *   action must match in order for this Rule to match. (The accessory
     *   object is only relevant if the TIAAction extension is in use).
     */
    // dobj = []
    // iobj = []
    // aobj = []
    
    /* 
     *   An object, class, or other value, or a list of objects and/or classes
     *   or of other values, one of which must match the matchObj property of
     *   our rulebook (which is set by the first parameter of a call to that
     *   RuleBooks's follow() method) for this Rule to match.
     */ 
    // matchObj = []
    
    
    /*  
     *   An object in the presence of which the actor must be for this rule to
     *   match. Presence normally means in the same room, but if this property
     *   is defined as a list and the first item in the list is a property
     *   pointer (&canSee, &canHear, &canReach, &canSmell), this property will
     *   be used to test for tne appropriate sense connection between the actor
     *   and at least one of the other items in the list instead.
     */
    // present = []
;
