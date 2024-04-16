#charset "us-ascii"
#include "advlite.h"

/* 
 *   RELATIONS EXTENSION by Eric Eve July 2014
 *
 *   The relations.t extension allows Inform7-style relations to be
 *   defined in a TADS 3 game.
 */

 
/* 
 *   The Relation class is used to define any kind of binary relation you like
 *   between objects, or between items of any other kind, e.g. x love y, or a is
 *   the father of b, or c knows d.
 *
 *   REQUIRES THE RELATIONS EXTENSION.
 */
class Relation: PreinitObject
    /* 
     *   A string name that can be used to refer to this relation, e.g. 'loves'
     *   or 'is the parent of' [RELATIONS EXTENSION]
     */
    name = nil
    
    /*   
     *   A string name that can be used to refer to this relation in reverse,
     *   e.g. 'loved by' or 'is a child of' [RELATIONS EXTENSION]
     */
    reverseName = nil
    
    /* 
     *   The type of relation we are; this can be one of oneToOne, oneToMany,
     *   manyToOne or manyToMany. [RELATIONS EXTENSION]
     */
    relationType = oneToOne
    
    /*   
     *   Flag: are we a reciprocal relation (i.e. does x relation b imply b
     *   relation x)? Note that only oneToOne and manyToMany relations can be
     *   reciprocal. [RELATIONS EXTENSION]
     */
    reciprocal = nil
    
    /*  
     *   A LookupTable to hold data about the items related via this relation.
     *   This is maintained by the library code and shouldn't normally be
     *   directly accessed via game code. [RELATIONS EXTENSION]
     */
    relTab = nil
    
    /*   Return a list of items related to a via this relation. [RELATIONS EXTENSION] */
    relatedTo(a)
    {       
        /* Get the list of things we're related to from our relation table. */
        local lst = valToList(relTab == nil ? [] : relTab[a]); 
        
        /* 
         *   If our list is empty and we're a reciprocal relation, try getting the list of the
         *   inverse relation's list.
         */
        if(lst == [] && reciprocal)
            lst = inverselyRelatedTo(a);
        
        /* Return our list. */
        return lst;
            
    }
    
    /*   Test whether a is related to b via this relation. [RELATIONS EXTENSION] */
    isRelated(a, b)
    {       
        return relatedTo(a).indexOf(b) != nil;
    }
    
    /*   
     *   Return a list of items inverselty related to a via this relation (e.g.
     *   if this is loving relation, return a list of the people a is loved by.
	 *   [RELATIONS EXTENSION]
     */
    inverselyRelatedTo(a)
    {
        /*  
         *   Iterate over our LookUpTable to find key values that correspond to values of a. We call
         *   our listKeys method to do so.
         */        
        local lst = listKeys();
        
        /* Set up a Vector as a temporary store for our results. */
        local vec = new Vector;
        
        /* 
         *   Go through each key in the relTab LookupTable to see if a occurs in
         *   its corresponding value (which should be a list). If so append cur
         *   to our vector.
         */
        foreach(local cur in lst)
        {            
            if(isInverselyRelated(a, cur))
                vec.append(cur);
        }
        
        /* Convert the vector to a list and return the result. */
        return vec.toList();
    }
    
    /* Test whether a is inversely related to b via this relation. [RELATIONS EXTENSION] */
    isInverselyRelated(a, b)
    {
        /* 
         *   We're inversely related to a if we occur in the list of items to which a is related.         
         */
        return (valToList(relTab[b]).indexOf(a) != nil) || 
            ( reciprocal && valToList(relTab[a]).indexOf(b) != nil);
    }
    
    /* 
     *   Make two objects related via this relation. The objs should be supplied
     *   as a two-element list (e.g. [a, b]) such that a will be related to b.
	 *   [RELATIONS EXTENSION]
     */
    addRelation(objs)
    {
        
        /* 
         *   If we do not already have a LookupTable associated with our relTab
         *   property, perform some sanity checks and then create one if all is
         *   okay.
         */
        if(relTab == nil)   
        {
            
            /* 
             *   Check whether the setting of the reciprocal property on this
             *   relation conflicts with the setting of the relationType
             *   property. Neither a oneToMany nor a manyToOne relation can be
             *   reciprocal (since oneToMany and manyToOne both imply an
             *   asymmetry), so issue a warning if there's a conflict.
             */
            if(reciprocal && relationType is in (oneToMany, manyToOne))
            {
                "<b>ERROR!</b> The <<name>> relation cannot be both <<if
                  relationType == oneToMany>>one-to-many<<else>>many to
                one<<end>> and reciprocal. ";
                
                return;
            }
            
            /* 
             *   If we do not yet have a LookupTable attached to our relTab,
             *   create it now.
             */
            relTab = new LookupTable;
            relTab.setDefaultValue([]);
        }
        
        /* 
         *   The obs parameter should have been supplied as a two element list,
         *   [a, b]. When we add this to our relTab LookupTable the virst item
         *   in the list will be a key in the table and the second will be a
         *   value.
         */
        local key = objs[1];
        local val = objs[2];
        
        
        /* 
         *   if val is nil we're saying we don't want key to be related to
         *   anything, so remove it from the table
         */
        if(val == nil)
        {   
            /* 
             *   If we're a reciprocal relation then we also need to remove the
             *   other side of the relation; if a is no longer related to b then
             *   b is no longer related to a in a reciprocal relationship.
             */
            if(reciprocal)
            {
                /* 
                 *   relTab[key] should evaluate a list of the items to which
                 *   key is related. For each of these item remove key from the
                 *   list of items to which they in turn are related.
                 */
                foreach(local cur in relTab[key])
                    relTab[cur] = relTab[cur] - key;
            }
            
            /* 
             *   Simce key is no longer related to anything, we can remove it
             *   from the relTab LookupTable.
             */
            relTab.removeElement(key);
            
            /*   Then we're done. */
            return;
        }
        
        /* 
         *   If key is nil we're saying the reverse relation no longer applies
         *   to val, so we need to remove val wherever it appears.
         */
        if(key == nil)
        {
            /* 
             *   If we've a reciprocal relation, val is no longer related to
             *   anything, so we can remove the val entry from the relTab.
             */
            if(reciprocal)
                relTab.removeElement[val];
            
            /* Get a list of the keys in relTab */
            local lst = relTab.keysToList();
            
            /* 
             *   Iterate over that list removing val from the list of values
             *   associated with every key.
             */
            foreach(local cur in lst)
            {
                local curVal = relTab[cur];
                relTab[cur] = curVal - val;
            }
            
            /* Then we're done. */
            return;
        }
        
        /*  Note the current value associated with key in relTab. */
        local existing = relTab[key];
        
        /*  What happens next depends on our relationType */
        switch(relationType)
        {
            
        case oneToOne:
            /* 
             *   If we're a one-to-one relation, we can simply set the new value
             *   corresponding to key to [val], either thereby creating a new
             *   entry in the relTab LookupTable or overwriting the existing
             *   one. We make [val] a list since this is how the relTab
             *   LookupTable stores its values.
             */
            relTab[key] = [val];          
            
            /*  
             *   Ensure that val is not a value for any other key in the table,
             *   since in a one-to-one relationship each key can be related to
             *   at most one val, and each val to at most one key.
             */
            makeUnique(key, val);
            
            /*   
             *   If we're a reciprocal relationship we need to enter the same
             *   pair of items in relTab the other way round as well.
             */
            if(reciprocal)       
            {
                relTab[val] = [key];                          
                makeUnique(val, key);
            }
            break;
        case oneToMany:   
            
            /* Deliberate fall-through */
        case manyToMany:
            /* 
             *   In the case of a one-to-many or many-to-many relationships,
             *   several values can be associated with each key, so we append
             *   the new val to the list of values already associated with key.
             */            
            relTab[key] = (nilToList(existing)).appendUnique([val]);
            
            /*  
             *   If we're a reciprocal relationship we must also be a
             *   many-to-many one, or else we would not have reached this point
             *   (the block beginning if(relTab == nil) above would have
             *   prevented it). So, if we're reciprocal, we also add key to the
             *   list of values associated with val.
             */
            if(reciprocal)
                relTab[val] = nilToList(relTab[val]).appendUnique([key]);
            break;          
            
        case manyToOne:
            /* 
             *   For a many-to-one relationship, simply make [val] the new value
             *   corresponding to key.
             */
            relTab[key] = [val];
            
            break;
        }
    }
    
    /*  
     *   Ensure that key is the only entry in relTab with a value of [val].
	 *   [RELATIONS EXTENSION]
     *
     */
    makeUnique(key, val)
    {
        /* Get a list of all the keys in the relTab LookupTable. */
        local lst = relTab.keysToList();
        
        /* 
         *   Go through all the keys in relTab, deleting all that value a value
         *   of [val] apart from key.
         */
        foreach(local cur in lst)
        {
            if(cur != key && relTab[cur] == [val])
                relTab.removeElement(cur);            
            
        }
    }
    
    /*  
     *   Remove this relation between the items specified in objs, which should
     *   be supplied as a two-element list [a, b], where a is the item that is
     *   no longer related to b. [RELATIONS EXTENSION]
     */     
    removeRelation(objs)
    {
        /* 
         *   If relTab hasn't been set up yet we've nothing to do, since no
         *   objects are yet related via this relation.
         */
        if(relTab == nil)
            return;
        
        /*  Extract the key and val values from our two-element objs list. */
        local key = objs[1];
        local val = objs[2];
        
        /*  
         *   What happens next depends on what kind of relation we are. Note
         *   that if we have a non-nil relTab at all, we'll already have checked
         *   we can only be a reciprocal relation if we're a one-to-one or
         *   many-to-many relation.
         */         
        switch(relationType)
        {
        case oneToOne:
        case manyToOne:
            /* 
             *   If the key can only be related to one value, simply remove the
             *   key from relTab.
             */
            relTab.removeElement(key);
            
            /*   
             *   If this relation is reciprocal, remove val from relTab as well,
             *   since if this relation no longer holds one way round, it can no
             *   hold the other way round either.
             */
            if(reciprocal)
                relTab.removeElement(val);
            break;
            
        case oneToMany:    
        case manyToMany:
            /* 
             *   If the key can be related to many values, remove val from the
             *   list of values it's related to.
             */            
            relTab[key] = relTab[key] - val;
            
            /*  
             *   If this relation is reciprocal, remove key from the list of
             *   values corresponding to val.
             */
            if(reciprocal)
                relTab[val] = relTab[val] - key;
            break;
        }
        
    }
    
    /* 
     *   Liat the keys (the items to which this relation applies). By default we list the keys in
     *   our relTab.
     */
    listKeys()
    {
        return relTab ? relTab.keysToList() : [];
    }
    
    
    /* Make relation[b] = c work like relate(b, relation, c) [RELATIONS EXTENSION] */
    operator []=(b, c)
    {
        addRelation([b, c]);
        return self;
    }
    
    /* make relation[b] work like related(b, relation) [RELATIONS EXTENSION] */
    operator [] (b)
    {
        return relatedTo(b);
    }      
;

/* 
 *   A DerivedRelation is one that doesn't maintain its own table of what it
 *   related to what, but works out what is related to what on the basis of some
 *   other relation(s) (e.g. a sibling relation might work by testing for common
 *   parents).
 *
 *   REQUIRES THE RELATIONS EXTENSION
 */
DerivedRelation: Relation
    
    /* 
     *   Especially if listKeys() hasn't been defined on this DerivedRelation, instances may need to
     *   override to provide a method that returns a list of items related to a via this
     *   relationship, on the basis of whatever criteria are appropriate.
     */
    relatedTo(a) 
    { 
        /* Construct a list from our listKeys() method less a. */
        local lst = listKeys() - a;
        
        /* Se up a new Vector as working storage. */
        local vec = new Vector();
        
        /* Loop through every fact in our list. */
        foreach(local fact in lst)
        {
            /* if a is related to fact, add a to our Vector of related items. */
            if(isRelated(a, fact))
                vec.appendUnique(fact);
        }
        
        /* Convert the vector to a list and return the result. */
        return vec.toList();    
    }
    
    /* 
     *   Game code must override this method to determine whether a is inversely related to b unless
     *   it either overrides inverselyRelatedTo() to return a list of items to which a is inversely
     *   related or the relation is a reciprocal one.
     */
    isInverselyRelated(a, b)
    {
        /* 
         *   If this relation defines its own inverselyRelatedTo property, check whether b occurs in
         *   the list of things related to a.
         */
        if(propDefined(&inverselyRelatedTo, PropDefDirectly)) 
            return inverselyRelatedTo(a).find(b);
        
        /* Otherwise if we're reciprocal check whether b is related to a. */
        if(reciprocal)
            return isRelated(b, a);       
        
        /* Otherwise return an empty list */
        return [];
    }
    
    /* 
     *   If relatedTo has not been overriden to provide a list, instances need to override
     *   isRelated to provide a method that returns true or nil according to whether this
     *   DerivedRelationship holds between a and b. 
     */
    isRelated(a, b)
    {
        /* 
         *   If this relation has overridden its relatedTo method, assume that it has done so to
         *   generate its own list of items that are related, in which case use the inherited
         *   handling, which checks whether b is in the list of items to which a is related.
         */
        if(propDefined(&relatedTo, PropDefDirectly))          
            return inherited(a, b);
        
        /* 
         *   Is this relation hasn't overridden its related method it should have overridden its
         *   isRalated method; as a fallback we just return nil, but this should never happen if
         *   this DerivedRelation has been properly set up.
         */
        return nil;
    }   
    
    /* 
     *   By default we don't permit the direct addition of relationships via
     *   this relation, since this is a relation dependent upon external
     *   conditions.
     */
    addRelation(objs)
    {
        DMsg(cannot add to derived relation, 'ERROR! You cannot explicitly
            relate items via a derived relation (%1). ', name);
    }
    
    /* 
     *   By default we don't permit the direct removal of relationships via
     *   this relation, since this is a relation dependent upon external
     *   conditions.
     */
    removeRelation(objs)
    {
        DMsg(cannot remove from derived relation, 'ERROR! You cannot explicitly
            remove a derived relation (%) between items. ', name);
    }
    
    /* 
     *   We don't have any entries listed in the relTable, but there may be another way of building
     *   a list of the key values to which this DerivedRelalation applies; if so, particular
     *   instances can override this method to supply it here.
     */        
    listKeys()
    {
        return [];
    }   
   
;


/* 
 *   Used internally by the RELATIONS EXTENSION to keep track of which relations
 *   correspond to which (string) names.
 */
relationTable: PreinitObject
    /* 
     *   LookupTable to restore data relating names to relations. Each key is a
     *   string containing a relation name. Each corresponding value is a
     *   two-item list [rel, type] where rel is the name of the corresponding
     *   relation object and type is either normalRelation or reverseRelation.
     */
    nameTab = static new LookupTable
    
    /*  
     *   Go through all the relations in the game and add their names and
     *   reverseNames to our nameTab.
     */
    execute()
    {
        for(local rel = firstObj(Relation); rel != nil; rel = nextObj(rel,
            Relation))
        {
            if(rel.name)
                nameTab[rel.name] = [rel, normalRelation];
            if(rel.reverseName)
                nameTab[rel.reverseName] = [rel, reverseRelation];           
        }
    }

    /* 
     *   Get the relation corresponding to a string version of its name. Return
     *   a two-item list [rel, type] where rel is the name of the corresponding
     *   relation object and type is either normalRelation or reverseRelation.     *
         
     */
    getRelation(rel)
    {
        if(dataType(rel) == TypeSString)
            return nameTab[rel];
        /*
         *   If the rel argument is not supplied as a string, it's presumably
         *   the name of a relation object.
         */
        return [rel, normalRelation];
    }
    
    /* 
     *   Message to display when there's no relation in our nameTab
     *   corresponding to the name rel.
     */
    sayNoSuchRelation(rel)
    {
        DMsg(no such relation, 'ERROR, there is no such relation as <q>{1}</q>. ',
             rel);
    }
;




/* 
 *   Make a related to b via the rel relation. The rel parameter can be
 *   specified either as an object (in which case its the relevant relation
 *   object) or as a single-quoted string (in which cast it's either the name or
 *   the reverseName of a relation object.
 *
 *   PART OF THE RELATIONS EXTENSION
 */
relate(a, rel, b)
{
    /* Get the relation referred to by the rel parameter. */
    local relData = relationTable.getRelation(rel);
    
    /* Check that we actually found a relation before trying to use it. */
    if(relData == nil)
    {
        relationTable.sayNoSuchRelation(rel);
        return;
    }
    
    
    /* 
     *   If it's a normal relation, then use the addRelation method of the
     *   relation object to create a relation between a and b.
     */
    if(relData[2] == normalRelation)
        relData[1].addRelation([a, b]);
    
    /*  
     *   If it's a reverse relation (e.g. 'child of' when the relation is
     *   fatherOf) swap the a and b arguments round when calling the relation's
     *   addRelation() method (e.g. to make a the child of b using the fatherOf
     *   relation, we make b the father of a).
     */
    if(relData[2] == reverseRelation)
        relData[1].addRelation([b, a]);
    
}

/* 
 *   Remove the rel relation between a and b
 *
 *   PART OF THE RELATIONS EXTENSION
 */
unrelate(a, rel, b)
{
    /* Get the relation referred to by the rel parameter. */
    local relData = relationTable.getRelation(rel);
    
    /* Check that we actually found a relation before trying to use it. */
    if(relData == nil)
    {
        relationTable.sayNoSuchRelation(rel);
        return;
    }    
    
    /* 
     *   If it's a normal relation, then use the removeRelation method of the
     *   relation object to remove the relation between a and b.
     */
    if(relData[2] == normalRelation)
        relData[1].removeRelation([a, b]);
    
    /*  
     *   If it's a reverse relation (e.g. 'child of' when the relation is
     *   fatherOf) swap the a and b arguments round when calling the relation's
     *   removeRelation() method (e.g. to make a no longer the child of b using
     *   the fatherOf relation, we make b no longer the father of a).
     */
    if(relData[2] == reverseRelation)
        relData[1].removeRelation([b, a]);  
    
}


/* 
 *   If two arguments are supplied (e.g. related(a, knows)) returns a list of
 *   items related to a via the rel relation. If three arguments are supplied
 *   (e.g. related(a, knows, b)) then return true if a is related to b via the
 *   knows relation and b otherwise.
 *
 *   PART OF THE RELATIONS EXTENSION
 */
related(a, rel, b?)
{    
     /* Get the relation referred to by the rel parameter. */
    local relData = relationTable.getRelation(rel);
    
    
    /* Check that we actually found a relation before trying to use it. */
    if(relData == nil)
    {
        relationTable.sayNoSuchRelation(rel);
        return nil;
    }
 
    /* 
     *   If b has not been supplied, we've been asked to supply a list of
     *   objects related to a via rel.
     */
    if(b == nil)
    {
        if(relData[2] == normalRelation)
            return relData[1].relatedTo(a);
        else
            return relData[1].inverselyRelatedTo(a);
           
    }
    
    /* 
     *   Otherwise, if b has been supplied, we're being asked if a is related to
     *   b.
     */
    else
    {
        if(relData[2] == normalRelation)
            return relData[1].isRelated(a, b);
        else
            return relData[1].isInverselyRelated(a, b);
    }
}

/* 
 *   The relationPathfinder tries to find a path from start to target via the
 *   rel relation. If it finds one it returns the shortest posssible list of
 *   items starting with start and ending with target, in which each item in the
 *   list is related to the next via the rel relation. E.g. if John is the
 *   father of Jo, and Jo is the father of Jim, and Jim is the father of Jeremy,
 *   relationPathfinder.findPath(John, fatherOf, Jeremy) should return a list
 *   like [John, Jo, Jim, Jeremy] (assuming the appropriate definition of the
 *   fatherOf relationship).
 *
 *   PART OF THE RELATIONS EXTENSION
 */ 
relationPathfinder: Pathfinder
    
    /* 
     *   Find a path from start to target via the rel relation. The rel
     *   parameter may be supplied as a relation object, a relation string name
     *   or reverseName, or a list of any of these, in which case any of the
     *   relations contained in the list may be used to step from one object to
     *   the next.
     */
    findPath(start, rel, target)
    {
                
        local vec = new Vector();
        local relation;
        
        /* Go through every relation supplied in the rel parameter. */
        foreach(local cur in valToList(rel))
        {
            /* If it's an object, add it to our Vector as a normal relation. */
            if(dataType(cur) == TypeObject)
                vec.append([cur, normalRelation]);
            
            /* If it's a string, look it up in the relationTable. */
            if(dataType(cur) == TypeSString)
            {
                relation = relationTable.getRelation(cur);
                
                /* 
                 *   If we can't find the string in the relationTable, give up
                 *   and return nil, since there's an error in the rel
                 *   parameter. Also issue a warning message.
                 */
                if(relation == nil)
                {
                    relationTable.sayNoSuchRelation(rel);
                    return nil;
                }
                    
                /* If we found the relation, add it to our vector. */
                vec.append(relationTable.getRelation(cur));
            }
        }
        
        /* 
         *   Convert our vector to a list and store it in our relationList
         *   property.
         */
        relationList = vec.toList();       
        
        /*   
         *   Use the inherited handling to find the path and store it in a local
         *   variable.
         */
        local res = inherited(start, target);
        
        /* 
         *   If the result was nil, simply return nil to indicate that no path
         *   was found. Otherwise, if the rel parameter was passed as a list,
         *   return the resulting path list unchanged. Otherwise (if rel was
         *   passed as a single relation), return a list consisting of the
         *   objects (or other items) on the path only, since the relation
         *   information for each step would be redundant.
         *
         *   Thus, if rel was passes as a list, the return value might resemble,
         *   [[nil, john], ['child of', mark], ['sibling', mary]], whereas if it
         *   was passed as a single relation the return value might resemble
         *   [johh, mark, alan].
         */
        return res == nil ? nil : 
        (dataType(rel) == TypeList ? res : res.mapAll({e: e[2]})).toList(); 
    }
    
    findDestinations(cur)
    {
        /* Note the object our current path leads to */
        local obj = cur[steps - 1][2];
        
        /* Find everything related to this object via relation. */
        local lst = [];
        
        foreach(local rel in relationList)
        {
            local rname;
            
            if(rel[2] == normalRelation)
            {
                lst += rel[1].relatedTo(obj);
                rname = rel[1].name;
            }
            else
            {
                lst += rel[1].inverselyRelatedTo(obj);
                rname = rel[1].reverseName;
            }
            
            /* Find everything related to everything in the list. */
            foreach(local dest in lst)
            {
                local newPath = new Vector(cur);
                newPath.append([rname, dest]);
                pathsFound.append(newPath);
            }
        }
        
        
        
    }
    
    /* 
     *   Property used internally to hold the list of relations we're finding a
     *   route through.
     */
    relationList = nil
   
;

/* 
 *   Find a path from start to target via the rel relation, where rel can be a
 *   single relation or a list of relations, and can be specified either via a
 *   relation object name or a string name (or reverseName). We provide this as
 *   a convenient wrapper for the more verbose method call.
 *
 *   PART OF THE RELATIONS EXTENSION.
 */
relationPath(start, rel, target)
{
    return relationPathfinder.findPath(start, rel, target);    
}


#ifdef __DEBUG
/*  Debugging commands for RELATIONS EXTENSION */

/* List relations defined in the game [RELATIONS EXTENSION] */
DefineSystemAction(ListRelations)
    execAction(c)
    {
        /* Get a list of relations defined in the relation table */
        local lst = relationTable.nameTab.keysToList();
        
        /* If the list is empty, say so and exit. */
        if(lst.length == 0)
        {
            DMsg(no relations defined, 'No relations are defined in this game.
                ');
        }
        
        /* Sort the list in order of name */
        lst = lst.sort(SortAsc, {a, b: a.compareIgnoreCase(b)});
        
        /* Go through every item in the list */
        foreach(local cur in lst)
        {
            /* Get the value relating to the name cur */
            local val = relationTable.nameTab[cur];
            
            /* 
             *   Only report it if it's a normalRelation (so that we don't
             *   duplicate relations in our list by also listing them with their
             *   reverseName.
             */
            if(val[2] == normalRelation)
            {
                /* The relation is the first item in val */
                local rel = val[1];
                
                /* Show the details of this relation. */
                showRelation(rel);
            }
        }
    }
    
    /* Show the details of relation rel. */
    showRelation(rel)
    {
        /* First display the programmatic object name */
        "<b><<symTab.ctab[rel]>></b> ";
        
        /* If it's a DerivedRelation, say so. */
        if(rel.ofKind(DerivedRelation))
            "<i>(DerivedRelation)</i> ";
        
        /* Then show the relationType (an enum). */
        "<<symTab.ctab[rel.relationType]>>: ";
        
        /* If rel is a reciprocal relation, say so. */
        if(rel.reciprocal)
            "(reciprocal): ";
        
        /* Show the (string) name of the relation. */
        "<i>name</i> = '<<rel.name>>' ";
        
        /* If the relation has a reverseName, show that too. */
        if(rel.reverseName)
            "<i>reverseName</i> = '<<rel.reverseName>>' ";
        
        /* Move to the next line. */
        "\n";
    }
;

VerbRule(ListRelations)
    ('list'|) 'relations'
    :VerbProduction
    action = ListRelations
    verbPhrase = 'list/listing relations'
;

/* Debugging action to list what a relation currently relates [RELATIONS EXTENSION]*/
DefineSystemAction(RelationDetails)
    execAction(c)
    {
        /* Note the literal string associated with this command. */
        literal = c.dobj.name;
        
        /* 
         *   Try to get the relation associated with this string value from the
         *   relationTable.
         */
        local relInfo = relationTable.getRelation(literal);
        
        /*  Set up a local variable to hold the relation object. */
        local rel;
        
        local lst = [];
        
        if(relInfo == nil)
        {
            /* 
             *   If we didn't find anything in the relationTable, it may be the
             *   tester entered the programmatic name instead of the string name
             *   of the relation; try looking up the programatic name of the
             *   relation in the global symbol table.
             */
            rel = t3GetGlobalSymbols()[literal];
            
            /*   
             *   If we didn't find anything, or what we found wasn't a Relation,
             *   say there's no such relation and exit.
             */
            if(rel == nil || dataType(rel) != TypeObject ||
               !rel.ofKind(Relation))
            {
                DMsg(no such relation, 'There is no such relation in the game as
                    {1}. ', literal);
                return;
            }
        }
        /* 
         *   Otherwise, if we found an entry in the relationTable, the relation
         *   we want is the first item in the list returned from that table.
         */
        else            
            rel = relInfo[1];        
        
        /*  Show the details of what that relation is. */
        ListRelations.showRelation(rel);
        
        
        
        /*  
         *   If it's a DerivedRelation, say so and exit; we can't list what a
         *   DerivedRelation relates.
         */
        if(rel.ofKind(DerivedRelation))
        {
            //            DMsg(cant list derived relation, '<i>Since {1} is a DerivedRelation,
            //                any items it relates cannot be listed.</i> ', valToSym(rel));
            
            //            local vec = new Vector();
            
            
            
            lst = rel.listKeys();
            //           
        }
        else
            
            /* 
             *   Get a list of the keys in our relation's reltab table (which may be nil).
             */
            lst = rel.relTab == nil ? [] : rel.relTab.keysToList();
        
        
        /*  If the list is empty, say so and exit. */
        if(lst.length == 0)
        {
            DMsg(no relations defined, '<i>no relations defined</i> ');
            return;
        }
        
        /* Sort the list in ascending key order. */
        lst = lst.sort(SortAsc, {a, b:
                       symTab.ctab[a].compareIgnoreCase(symTab.ctab[b])});
        
        /* 
         *   Go through each key in the list. This will be the object (or other
         *   value) that relates to other objects via this relation.
         */
        foreach(local cur in lst)
        {
            /* 
             *   Display the name of the current object and list the items to which it relates.
             */
            local name1 = valToSym(cur);
            
            "<<name1>> -> <<valToSym(rel.relatedTo(cur))>>\n";           
        }
        
    }
    
    literal = nil
;

/* [RELATIONS EXTENSION] List relation details */
VerbRule(RelationDetails)
    ('relation' | 'relations' | 'rel') literalDobj
    : VerbProduction
    action = RelationDetails
    verbPhrase = 'list/listing relation details'
;

#endif