#charset "us-ascii"
#include "advlite.h"

/* 
 *   RELATIONS EXTENSION by Eric Eve July 2014
 *
 *   The relations.t extension allows Inform7-style relations to be
 *   defined in a TADS 3 game.
 */

 

class Relation: PreinitObject
    /* 
     *   A string name that can be used to refer to this relation, e.g. 'loves'
     *   or 'is the parent of'
     */
    name = nil
    
    /*   
     *   A string name that can be used to refer to this relation in reverse,
     *   e.g. 'loved by' or 'is a child of'
     */
    reverseName = nil
    
    /* 
     *   The type of relation we are; this can be one of oneToOne, oneToMany,
     *   manyToOne or manyToMany.
     */
    relationType = oneToOne
    
    /*   
     *   Flag: are we a reciprocal relation (i.e. does x relation b imply b
     *   relation x)? Note that only oneToOne and manyToMany relations can be
     *   reciprocal.
     */
    reciprocal = nil
    
    /*  
     *   A LookupTable to hold data about the items related via this relation.
     *   This is maintained by the library code and shouldn't normally be
     *   directly accessed via game code.
     */
    relTab = nil
    
    /*   Return a list of items related to a via this relation. */
    relatedTo(a)
    {       
        return relTab == nil ? [] : relTab[a];           
    }
    
    /*   Test whether a is related to b via this relation. */
    isRelated(a, b)
    {       
        return relatedTo(a).indexOf(b) != nil;
    }
    
    /*   
     *   Return a list of items inverselty related to a via this relation (e.g.
     *   if this is loving relation, return a list of the people a is loved by.
     */
    inverselyRelatedTo(a)
    {
        /* 
         *   If we're a reciprocal relationship, then asking whether we're
         *   inversely related to a is the same as asking whether we're related
         *   to a, which is a far quicker calculation.
         */
        if(reciprocal)
            return relatedTo(a);
        
        /*  
         *   Otherwise we need to iterate over our LookUpTable to find key
         *   values that correspond to values of a.
         */
        
        local lst = relTab ? relTab.keysToList() : [];
        local vec = new Vector;
        
        foreach(local cur in lst)
        {
            if(valToList(relTab[cur]).indexOf(a))
                vec.append(cur);
        }
        
        return vec.toList();
    }
    
    /* Test whether a is inversely related to b via this relation. */
    isInverselyRelated(a, b)
    {
        /* 
         *   Simply turn the question round; asking if a is loved by b is
         *   exactly the same as asking if b loves a.
         */
        return isRelated(b, a);
    }
    
    /* objs should be supplied as a two-element list */
    addRelation(objs)
    {
        if(relTab == nil)
        {
            relTab = new LookupTable;
            relTab.setDefaultValue([]);
            
            
            if(reciprocal && relationType is in (oneToMany, manyToOne))
            {
                "<b>ERROR!</b> The <<name>> relation cannot be both <<if
                  relationType == oneToMany>>one-to-many<<else>>many to
                one<<end>> and reciprocal. ";
                
                return;
            }
            
            
        }
        
        local key = objs[1];
        local val = objs[2];
        
        
        /* 
         *   if val is nil we're saying we don't want key to be related to
         *   anything, so remove it from the table
         */
        if(val == nil)
        {
            if(reciprocal)
            {
                foreach(local cur in relTab[key])
                    relTab[cur] = relTab[cur] - key;
            }
            
            relTab.removeElement(key);
            return;
        }
        
        /* 
         *   if key is nil we're saying the reverse relation no longer applies
         *   to val, so we need to remove val wherever it appears.
         */
        if(key == nil)
        {
            if(reciprocal)
                relTab.removeElement[val];
            
            local lst = relTab.keysToList();
            foreach(local cur in lst)
            {
                local curVal = relTab[cur];
                relTab[cur] = curVal - val;
            }
            
            return;
        }
        
        local existing = relTab[key];
        
        switch(relationType)
        {
        case oneToOne:
            relTab[key] = [val];           
            makeUnique(key, val);
            
            if(reciprocal)       
            {
                relTab[val] = [key];                          
                makeUnique(val, key);
            }
            break;
        case oneToMany:   

            /* Deliberate fall-through */
        case manyToMany:
            relTab[key] = (nilToList(existing)).appendUnique([val]);
            if(reciprocal)
                relTab[val] = nilToList(relTab[val]).appendUnique([key]);
            break;          
            
        case manyToOne:
            relTab[key] = [val];
            
            break;
        }
    }
    
    makeUnique(key, val)
    {
        local lst = relTab.keysToList();
        foreach(local cur in lst)
        {
            if(cur != key && relTab[cur] == [val])
                relTab.removeElement(cur);            
            
        }
    }
    
    removeRelation(objs)
    {
        if(relTab == nil)
            return;
        
        local key = objs[1];
        local val = objs[2];
        
        switch(relationType)
        {
        case oneToOne:
        case manyToOne:
            relTab.removeElement(key);
            if(reciprocal)
                relTab.removeElement(val);
            break;
            
        case oneToMany:    
        case manyToMany:
            relTab[key] = relTab[key] - val;
            if(reciprocal)
                relTab[val] = relTab[val] - key;
            break;
        }
        
    }
    
    
    
    operator []=(b, c)
    {
        addRelation([b, c]);
        return self;
    }
    
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
 */
DerivedRelation: Relation
    
    /* 
     *   Instances need to override to provide a method that returns a list of
     *   items related to a via this relationship, on the basis of whatever
     *   criteria are appropriate.
     */
    relatedTo(a) { return []; }
    
    inverselyRelatedTo(a) { return []; }
    
    addRelation(objs)
    {
        DMsg(cannot add to derived relation, 'ERROR! You cannot explicitly
            relate items via a derived relation (%1). ', name);
    }
    
    removeRelation(objs)
    {
        DMsg(cannot remove from derived relation, 'ERROR! You cannot explicitly
            remove a derived relation (%) between items. ', name);
    }
;


relationTable: PreinitObject
   nameTab = static new LookupTable
    
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

    getRelation(rel)
    {
        if(dataType(rel) == TypeSString)
            return nameTab[rel];
        
        return [rel, normalRelation];
    }
;




/* 
 *   Make a related to b via the rel relation. The rel parameter can be
 *   specified either as an object (in which case its the relevant relation
 *   object) or as a single-quoted string (in which cast it's either the name or
 *   the reverseName of a relation object.
 */
relate(a, rel, b)
{
    local relData = relationTable.getRelation(rel);
    if(relData)
    {
        if(relData[2] == normalRelation)
            relData[1].addRelation([a, b]);
        
        if(relData[2] == reverseRelation)
            relData[1].addRelation([b, a]);
    }   
}

/* Remove the rel relation between a and b */
unrelate(a, rel, b)
{
    local relData = relationTable.getRelation(rel);
    if(relData)
    {
        if(relData[2] == normalRelation)
            relData[1].removeRelation([a, b]);
        
        if(relData[2] == reverseRelation)
            relData[1].removeRelation([b, a]);
    } 
    
}


/* 
 *   If two arguments are supplied (e.g. related(a, knows)) returns a list of
 *   items related to a via the rel relation. If three arguments are supplied
 *   (e.g. related(a, knows, b)) then return true if a is related to b via the
 *   knows relation and b otherwise.
 */

related(a, rel, b?)
{    
    local relData = relationTable.getRelation(rel);
    if(relData == nil)
    {
        DMsg(no such relation, 'ERROR, there is no such relation as {%1}. ',
             rel);
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
 */ 
relationPathfinder: Pathfinder
    findPath(start, rel, target)
    {
        if(rel == nil)
            return nil;
        
        relation = rel;       
        
        local res = inherited(start, target);
        
        return res == nil ? nil : res.mapAll({e: e[2]});
    }
    
    findDestinations(cur)
    {
        /* Note the object our current path leads to */
        local obj = cur[steps - 1][2];
        
        /* Find everything related to this object via relation. */
        local lst = related(obj, relation);
        
        /* Find everything related to everything in the list. */
        foreach(local dest in lst)
        {
            local newPath = new Vector(cur);
            newPath.append([obj, dest]);
            pathsFound.append(newPath);
        }
        
    }
    
    relation = nil
   
;

relationPath(start, rel, target)
{
    local relData = relationTable.getRelation(rel);
    local lst;
    if(relData == nil)
        return nil;
    
    if(relData[2] == normalRelation)           
        lst = relationPathfinder.findPath(start, relData[1], target);
    else
        lst = relationPathfinder.findPath(target, relData[1], start);
    
        
    return (relData[2] == normalRelation || lst == nil)
        ? lst : lst.sort(true, { a, b: lst.indexOf(a) - lst.indexOf(b) });
}