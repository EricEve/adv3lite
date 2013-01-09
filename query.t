#include "advlite.h"

/* ------------------------------------------------------------------------ */
/*
 *   Q is the general-purpose global Query object.  Its various methods are
 *   used to ask questions about the game state.
 *   
 *   For any query, there are two sources of answers.  First, there's the
 *   standard answer based on the basic "physics" of the adventure world
 *   model.  Second, there are any number of custom answers from Special
 *   objects, which define customizations that apply to specific
 *   combinations of actors, locations, objects, times, or just about
 *   anything else that the game can model.
 *   
 *   The standard physics-based answer is the default.  It provides the
 *   answer if there are no active Special objects that provide custom
 *   answers.
 *   
 *   If there are active Specials, the only ones that matter for a
 *   particular query are the ones that define that query's method.  If
 *   there are any active Special objects that define a query method,
 *   calling Q.foo() actually calls the highest-priority Special's version
 *   of the foo() method.  That Special method can in turn call the next
 *   lower priority Special using next().  If there are no active Special
 *   objects defining a query method, the default handler in QDefaults will
 *   be used automatically.  
 */
Q: object
    /*
     *   Get the list of objects that are in scope for the given actor.
     *   Returns a ScopeList object containing the scope.  You can convert
     *   the ScopeList to an ordinary list of objects via toList().  
     */
    scopeList(actor)
        { return Special.first(&scopeList).scopeList(actor); }
    
    
    knownScopeList()
        { return Special.first(&knownScopeList).knownScopeList;}
    
    topicScopeList()
        { return Special.first(&topicScopeList).topicScopeList;}

    /*
     *   Is A in the light?  This determines if there's light shining on
     *   the exterior surface of A.  
     */
    inLight(a)
        { return Special.first(&inLight).inLight(a); }

    /*
     *   Can A see B?
     */
    canSee(a, b)
        { return Special.first(&canSee).canSee(a, b); }

    /*
     *   Determine if there's anything blocking the sight path from A to B.
     *   Returns a list of objects blocking sight; if there's no
     *   obstruction, returns an empty list.  If the two objects are in
     *   separate rooms, the outermost room containing 'a' represents the
     *   room separation.  If there's no obstruction, returns an empty
     *   list.  
     */
    sightBlocker(a, b)
        { return Special.first(&sightBlocker).sightBlocker(a, b); }

    /*
     *   Can we reach from A to B?  We return true if there's nothing in
     *   the way, nil otherwise.  
     */
    canReach(a, b)
        { return Special.first(&canReach).canReach(a, b); }

    /*
     *   Determine if A can reach B, and if not, what stands in the way.
     *   Returns a list of containers along the path between A and B that
     *   obstruct the reach.  If the two objects are in separate rooms, the
     *   top-level room containing A is in the list to represent the room
     *   separation.  If there's no obstruction, we return an empty list.  
     */
    reachBlocker(a, b)
        { return Special.first(&reachBlocker).reachBlocker(a, b); }

    /*
     *   Can A hear B?  
     */
    canHear(a, b)
        { return Special.first(&canHear).canHear(a, b); }

    /*
     *   Determine if A can hear B, and if not, what stands in the way.  We
     *   return a list of the obstructions to sound between A and B.  If
     *   the two objects are in separate rooms, the top level room
     *   containing A represents the room separation.  If there are no
     *   sound obstructions, returns an empty list.  
     */
    soundBlocker(a, b)
        { return Special.first(&soundBlocker).soundBlocker(a, b); }
    
    /*
     *   Can A smell B?  
     */
    canSmell(a, b)
        { return Special.first(&canSmell).canSmell(a, b); }

    /*
     *   Determine if A can smell B, and if not, what stands in the way.
     *   Returns a list of obstructions to scent between A and B.  If the
     *   two objects are in separate rooms, the outermost room containing A
     *   represents the room separation.  If there are no obstructions,
     *   returns an empty list.  
     */
    scentBlocker(a, b)
        { return Special.first(&scentBlocker).scentBlocker(a, b); }
    
    
    /*  Determine if A can talk to B. */
    
    canTalkTo(a, b)
        { return Special.first(&canTalkTo).canTalkTo(a, b); }
    
    /*  Determine if A can Throw something to B. */
    canThrowTo(a, b)
        { return Special.first(&canThrowTo).canThrowTo(a, b); }
; 

/*
 *   Query Defaults.  This provides the default handlers for all query
 *   methods.  These are the results that you get using the basic adventure
 *   game "physics" model to answer the questions, ignoring any special
 *   exceptions defined by the game.
 *   
 *   This is the lowest-ranking Special object, and is always active.  
 */
QDefaults: Special
    /* this is the defaults object, so it has the lower priority */
    priority = 0

    /* this is the defaults object, so it's always active */
    active = true

    /*
     *   Get the list of objects that are in scope for the given actor.
     *   Returns a ScopeList object containing the scope.  You can convert
     *   the ScopeList to an ordinary list of objects via toList().  
     */
    scopeList(actor)
    {
        /* start a new scope list */
        local s = new ScopeList();

        /* everything the actor is directly holding is in scope */
        s.addAll(actor.directlyHeld);
        
        local c = actor.outermostVisibleParent();

        /* 
         *   If we're in a lighted area, add the actor's outermost visible
         *   container and its contents.  In the dark, add the actor's
         *   immediate container only (not its contents), on the assumption
         *   that the actor is in physical contact with it and thus can
         *   refer to it and manipulate it even without seeing it.  
         */
        if (inLight(actor))
        {
            /* lit area - add the outermost container and its contents */
            
            s.addOnly(c);
            s.addWithin(c);
        }
        else
        {
            /* in the dark - add only the immediate container */
            s.addOnly(actor.location);
            
            /* plus anything that's self illuminating */
            s.addSelfIlluminatingWithin(c);
        }

        /* close the scope */
        s.close();

        /* return the ScopeList we've built */
        return s;
    }
    
    /* Get a list of all objects that are known to the player char */
    
    knownScopeList()
    {
        local vec = new Vector(30);
        for(local obj = firstObj(Thing); obj != nil; obj = nextObj(obj, Thing))
        {
            if(obj.known)
                vec += obj;
        } 
        
        return vec.toList;
    }

    /* 
     *   Get a list of all known mentionable objects, which we assume will
     *   include both known Things and known Topics
     */    
    topicScopeList()
    {        
        return World.universalScope.subset({o: o.known});
    }
    /*
     *   Is A in the light?  This determines if there's light shining on
     *   the exterior surface of A.  
     */
    inLight(a)
    {
        /* A is lit if it's a Room and it's illuminated */
        if(a.ofKind(Room))
            return a.isIlluminated;
        
        /* A is lit if its enclosing parent is lit within */
        local par = a.interiorParent();
        return par != nil && par.litWithin();
    }

    /*
     *   Can A see B?  We return true if and only if B is in light and
     *   there's a clear sight path from A to B.  
     */
    canSee(a, b)
    {
        
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        /* we can see it if it's in light and there's a clear path to it */
        return inLight(b) && sightBlocker(a, b).length() == 0;
    }

    /*
     *   Determine if there's anything blocking the sight path from A to B.
     *   Returns a list of objects blocking sight; if there's no
     *   obstruction, returns an empty list.  If the two objects are in
     *   separate rooms, the outermost room containing 'a' represents the
     *   room separation.  If there's no obstruction, returns an empty
     *   list.  
     */
    sightBlocker(a, b)
    {
        /* scan for sight blockages along the containment path */
        return a.containerPathBlock(b, &canSeeOut, &canSeeIn); // TODO
//        return [];
    }

    /*
     *   Can we reach from A to B?  We return true if there's a clear reach
     *   path from A to B.  
     */
    canReach(a, b)
    {
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        local blocker = Q.reachBlocker(a, b);
        
        /* 
         *   A cannot reach B if there are any obstacles between A and B besides
         *   B itself (e.g. the actor is inside a closed box)
         */
        
        if (blocker.length() > 0 && blocker[1] != b)
            return nil;
        
        /* 
         *   Finally we need to check whether there's anything along the path
         *   from A to B that rules out touching in a checkReach() or
         *   checkReachIn() method.
         */
        
        if(gOutStream.captureOutput({: b.checkReach(a)}) not in (nil, ''))
            return nil;
        
        local cpar = b.commonInteriorParent(a);
        
        if(cpar != nil)
        {
            for(local loc = b.location; loc != cpar; loc = loc.location)
            {
                if(gOutStream.captureOutput({: loc.checkReachIn(a)}) not in
                   (nil, ''))
                    return nil;
            }
            
        }
        
        
        return true;
    }
    
    /*
     *   Determine if A can reach B, and if not, what stands in the way. Returns
     *   a list of containers along the path between A and B that obstruct the
     *   reach.  If the two objects are in separate rooms, the top-level room
     *   containing A is in the list to represent the room separation.  If
     *   there's no obstruction, we return an empty list.
     */
    reachBlocker(a, b)
    {
        return a.containerPathBlock(b, &canReachOut, &canReachIn);
    }
    
    /*
     *   Can A hear B?  We return true if there's a clear sound path from A to
     *   B.
     */
    canHear(a, b)
    {
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        return soundBlocker(a, b).length() == 0;
    }

    /*
     *   Determine if A can hear B, and if not, what stands in the way.  We
     *   return a list of the obstructions to sound between A and B.  If
     *   the two objects are in separate rooms, the top level room
     *   containing A represents the room separation.  If there are no
     *   sound obstructions, returns an empty list.  
     */
    soundBlocker(a, b)
    {
        return a.containerPathBlock(b, &canHearOut, &canHearIn);
    }

    /*
     *   Can A smell B?  We return true if there's a clear scent path from
     *   A to B.  
     */
    canSmell(a, b)
    {
        if(a.isIn(nil) || b.isIn(nil))
            return nil;
        
        return scentBlocker(a, b).length() == 0;
    }

    /*
     *   Determine if A can smell B, and if not, what stands in the way.
     *   Returns a list of obstructions to scent between A and B.  If the
     *   two objects are in separate rooms, the outermost room containing A
     *   represents the room separation.  If there are no obstructions,
     *   returns an empty list.  
     */
    scentBlocker(a, b)
    {
        return a.containerPathBlock(b, &canSmellOut, &canSmellIn);
    }

    
    /*  
     *   Determine if A can talk to B. In the base situation A can talk to B if
     *   A can hear B.
     */
    
    canTalkTo(a, b)
    {
        return Q.canHear(a, b);
    }
    
    /*  
     *   Determine if A can throw something to B. In the base situation A can
     *   throw to B if A can reach B.
     *
     */
    
    canThrowTo(a, b)
    {
        return canReach(a, b);
    }
;

/* ------------------------------------------------------------------------ */
/*
 *   A Special defines a set of custom overrides to standard Query
 *   questions that apply under specific conditions.
 *   
 *   At any given time, a Special is either active or inactive.  This is
 *   determined by the active() method.  
 */
class Special: object
    /*
     *   Am I active?  Each instance should override this to define the
     *   conditions that activate the Special.  
     */
    active = nil

    /*
     *   My priority.  This is an integer value that determines which
     *   Special takes precedence when two or more Specials are active at
     *   the same time, and they both/all define a given query method.  In
     *   such a situation, Q calls the active Specials in ascending
     *   priority order (lowest first, highest last), and takes the last
     *   one's answer as the true answer to the question.  This means that
     *   the Special with the highest priority takes precedence, and can
     *   override any lower-ranking Special that's active at the same time.
     *   
     *   The library uses the following special priority values:
     *   
     *   0 = the basic library defaults.  The defaults must have the lowest
     *   priority, meaning that all Special objects defined by a game or
     *   extension must use priorities higher than 0.
     *   
     *   Other than the special priorities listed above, the priority is
     *   simply a relative ordering, so games and extensions can use
     *   whatever range of values they like.
     *   
     *   Note that priorities can't change while running.  This is a
     *   permanent feature of the object.  We take advantage of this to
     *   avoid re-sorting the active list every time we build it.  We sort
     *   the master list at initialization and assume it stays sorted, so
     *   that any subset is inherently sorted.  If it's important to the
     *   game to dynamically change priorities, you just need to re-sort
     *   the allActive_ list at appropriate times.  If priorities can only
     *   change when the game-world state changes, you can simply sort the
     *   list in allActive() each time it's rebuilt.  If priorities can
     *   change at other times (which doesn't seem like it'd be useful, but
     *   just in case), you'd need to re-sort the list on every call to
     *   allActive(), even when the list isn't rebuilt.  
     */
    priority = 1

    /*
     *   Call the same method in the next lower priority Special.  This can
     *   be used in any Special query method to invoke the "default"
     *   version that would have been used if the current Special had not
     *   been active.
     *   
     *   This is analogous to using 'inherited' to inherit the superclass
     *   version of a method from an overriding version in a subclass.  As
     *   with 'inherited', you can only call this directly from the method
     *   that you want to pass to the default handling, because this
     *   routine determines what to call based on the caller.  
     */
    next()
    {
        /* get the caller's stack trace information */
        local stk = t3GetStackTrace(2);
        local prop = stk.prop_;
        
        /* find the 'self' object in the currently active Specials list */
        local slst = Special.allActive();
        local idx = slst.indexOf(stk.self_);

        /* get the next Special that defines the method */
        while (!slst[++idx].propDefined(prop)) ;
        
        /* call the query method in the next Special, returning the result */
        return slst[idx].(prop)(stk.argList_...);
    }

    /*
     *   Get the first active Special (the one with the highest priority)
     *   that defines the given method.  This is used by the Q query
     *   methods to invoke the correct current Special version of the
     *   method.  
     */
    first(prop)
    {
        /* get the active Specials */
        local slst = Special.allActive();

        /* find the first definer of the method */
        local idx = 0;
        while (!slst[++idx].propDefined(prop)) ;

        /* return the one we found */
        return slst[idx];
    }

    /* Class method: get the list of active Specials. */
    allActive()
    {
        local a;
        
        /* if the cache is empty, rebuild it */
        if ((a = allActive_) == nil)
            a = allActive_ = all.subset({ s: s.active() });

        /* return the list */
        return a;
    }

    /*
     *   Class property: cache of all currently active Specials.  This is
     *   set whenever someone asks for the list and it's not available, and
     *   is cleared whenever an Effect modifies the game state.  (Callers
     *   shouldn't access this directly - this is an internal cache.  Use
     *   the allActive() method instead.)  
     */
    allActive_ = nil

    /* during initialization, build the list of all Specials */
    classInit()
    {
        /* build the list of all Specials */
        local v = new Vector(128);
        forEachInstance(Special, { s: v.append(s) });

        /* 
         *   Sort it in ascending priority order.  Since we assume that
         *   priorities are fixed, this eliminates the need to sort when
         *   creating active subsets - the subsets will automatically come
         *   up in priority order because they're taken from a list that
         *   starts in priority order. 
         */
        v.sort(SortDesc, { a, b: a.priority - b.priority });

        /* save it as a list */
        all = v.toList();
    }

    /*
     *   Class property: the list of all Special objects throughout the
     *   game.  This is set up during preinit.
     */
    all = []
;

/* ------------------------------------------------------------------------ */
/*
 *   A ScopeList is a helper object used to build the list of objects in
 *   scope.  This object provides methods for the common ways of adding
 *   objects to scope.
 *   
 *   The ScopeList isn't a true Collection object, but it mimics one by
 *   providing most of the standard methods.  You can use length() and the
 *   [] operator to scan the list, perform a foreach or for..in loop with a
 *   ScopeList to iterate over the items in scope, you can use find() to
 *   check if a given object is in scope, and you can use subset() to get a
 *   list of in-scope objects satisfying some condition.
 */
class ScopeList: object
    /*
     *   Add an object and its contents to the scope. 
     */
    add(obj)
    {
        /* 
         *   if we've already visited this object in full-contents mode,
         *   there's no need to repeat all that
         */
        local tstat = status_[obj];
        if (tstat == 2)
            return;

        /* if the object isn't already in the list at all, add it */
        if (tstat == nil)
            vec_.append(obj);

        /* promote it to status 2: added with contents */
        status_[obj] = 2;

        /* 
         *   if we can see in, add all of the contents, interior and
         *   exterior; otherwise add just the exterior contents 
         */
        if (obj.canSeeIn)
            addAll(obj.contents);
        else
            addAll(obj.extContents);
    }

    /*
     *   Add all of the objects in the given list 
     */
    addAll(lst)
    {
        for (local i = 1, local len = lst.length() ; i <= len ; ++i)
            add(lst[i]);
    }

    /*
     *   Add the interior contents of an object to the scope.  This adds
     *   only the contents, not the object itself.  
     */
    addWithin(obj)
    {
        /* add each object in the interior contents */
        addAll(obj.intContents);
    }

    
    /* add each self-illuminating object in the interior contents */
    addSelfIlluminatingWithin(obj)
    {
        addAll(obj.intContents.subset({x: x.visibleInDark}));
    }
    
    /*
     *   Add a single object to the scope.  This doesn't add anything
     *   related to the object (such as its contents) - just the object
     *   itself.  
     */
    addOnly(obj)
    {
        /* 
         *   If this object is already in the status table with any status,
         *   there's no need to add it again.  We also don't want to change
         *   its existing status, because if we've already added it with
         *   its contents, adding it redundantly by itself doesn't change
         *   the fact that we've added its contents.
         */
        if (status_[obj] != nil)
            return;

        /* add it to the vector */
        vec_.append(obj);

        /* set the status to 1: we've added only this object */
        status_[obj] = 1;
    }

    /* "close" the scope list - this converts the vector to a list */
    close()
    {
        vec_ = vec_.toList();
        status_ = nil;
    }

    /* get the number of items in scope */
    length() { return vec_.length(); }

    /* get an item from the list */
    operator[](idx) { return vec_[idx]; }

    /* is the given object in scope? */
    find(obj) { return status_[obj] != nil; }

    /* get the subset of the objects in scope matching the given condition */
    subset(func) { return vec_.subset(func); }

    /* return the scope as a simple list of objects */
    toList() { return vec_; }

    /* create an iterator, for foreach() */
    createIterator() { return vec_.createIterator(); }

    /* create a live iterator */
    createLiveIterator() { return vec_.createLiveIterator(); }

    /* a vector with the objects in scope */
    vec_ = perInstance(new Vector(50))

    /* 
     *   A LookupTable with the objects already added to the list.  We use
     *   this to avoid redundantly scanning containment trees for objects
     *   that we've already added.  For each object, we set status_[obj] to
     *   a status indicator:
     *   
     *.    nil (unset) - the object has never been visited
     *.    1 - we've added the object only, not its contents
     *.    2 - we've added the object and its contents
     */
    status_ = perInstance(new LookupTable(64, 128))
;

