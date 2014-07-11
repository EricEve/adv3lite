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
 *   caller of the RuleBook.
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
    
    nullValue = nil
    
    follow([args])
    {
        if(args.length > 0)
            matchObj = args[1];
        
        initBook(args...);
        
        local validRules = contents.subset({r: r.matchConditions});
        
        validRules = validRules.sort(SortDesc, {a, b: a.compareTo(b)} );
        
        foreach(local ru in validRules)
        {
            local res = ru.doRule(args...);
            if(res != nullValue)
                return res;
        }
        
        return nullValue;
    }
    
    /* 
     *   Game code can use this method to initialize the values of custom
     *   RuleBook properties at the start of the processing of following a
     *   RuleBook.
     */
    initBook([args]) { }
    
    matchObj = nil
    
;

rulePreinit:PreinitObject
    execute()
    {
        for(local ru = firstObj(Rule); ru != nil; ru = nextObj(ru, Rule))
        {
            ru.initializeRule();
        }       
    }
;



class Rule: object
    location = nil
    
    initializeRule()
    {
        if(location)
        {
            location.addToContents(self);
            
            null = location.nullValue;    
        }
        
        specificity = calcSpecficity();
    }
    
    doRule([args])
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
     *   A Rule is normally active (that is it will normally be considered when
     *   a RuleBook is being followed) but it can be temporarily disabled by
     *   setting its isActive property to nil.
     */
    isActive = true

    /*
     *   Calculate the specificity of this 
     *   Rule. 
     */
    calcSpecficity()
    {       
        local p = 0;
       
        /* a 'when' has priority over no 'when' */
        if(propDefined(&when))
            p += 10;
        
        /* a 'where' has priority over no 'where' */
        if(propDefined(&where))
            p += 10;
        
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
        
        if(propDefined(&matchObj))
        {
            switch(propType(&matchObj))
            {
            case TypeNil:
                break;
            case TypeObject:
                p += (matchObj.isClass ? 5 : 10);
                break;
            case TypeList:
                if(matchObj.length > 0 && dataType(matchObj[1]) == TypeObject)
                {
                    if(matchObj.indexWhich({o: !o.isClass}))
                        p += 10;
                    else
                        p += 5;
                }
                else
                    p += 10;
                
                break;
            default:
                p += 10;
                break;
                
            }
        }
        
        return p;       
    }
    
    
    /*
     *   Get the processing priority sorting order relative to another
     *   Rule. 
     */
    compareTo(other)
    {
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
            if(whoLst.indexOf(actor) == nil)
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
        
        if(propDefined(&action) 
           && valToList(action).indexWhich({a: gAction.ofKind(a)}) == nil)
            return nil;
        
        for(local objs in [[&dobj, gDobj], [&iobj, gIobj], [&aobj, gAobj]])
        {
            local prop = objs[1];
            local obj = objs[2];
            
            if(propDefined(prop) 
                && valToList(self.(prop)).indexWhich({o: obj.ofKind(o)}) == nil)
                return nil;          
                            
        }
        
        if(propDefined(&matchObj))
        {
            local mList = valToList(matchObj);
            local mo = location.matchObj;
            
            if(mList.length > 0)
            {
                if(dataType(mList[1]) == TypeObject)
                {
                    if(mList.indexWhich({o: mo.ofKind(o) } ) == nil)
                        return nil;
                }
                else if(mList.indexOf(mo) == nil)
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
            rb.addToContents(self);
    }
    
    /* Remove this rule from a rulebook */    
    removeFrom(rb)
    {
        if(rb && rb.ofKind(RuleBook))
        {
            rb.removeFromContents(self);
            
            if(location == rb)
                location = nil;
        }
    }
    
    moveTo(rb)
    {
        local loc = location;
        
        if(rb && rb.ofKind(RuleBook))
        {
            rb.addToContents(self);
            
            location = rb;
        }
        
        if(loc && loc.ofKind(RuleBook))
            loc.removeFromContents(self);
        
        
    }
    
    /* 
     *   The null property holds the value that should be returned by a Rule
     *   that does not want to stop processing of the RuleBook. This is taken
     *   from the value of the parent RuleBook's nullValue property (by default
     *   nil) and shouldn't normally be changed by game code.
     */
    null = nil
    
    stopValue = true
    
    /* 
     *   The actor to use to compare with the who property of this Rule. This
     *   will normally be gPlayerChar, but the value of this property is taken
     *   from our RuleBook's actor property.
     */
    actor = (location == nil ? gPlayerChar : location.actor)
;
