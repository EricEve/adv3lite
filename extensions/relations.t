#charset "us-ascii"
#include "advlite.h"

/* 
 *   RELATIONS EXTENSION by Eric Eve July 2014
 *
 *   The relations.t extension allows Inform7-style relations to be
 *   defined in a TADS 3 game.
 */

   
class BaseRelation: object
    name = nil
    
    reverseName = nil
    
    isRelated(a, b) { }
    
;

class Relation: BaseRelation, PreinitObject
    relatedTo = nil
    
    isRelated(a ,b)
    {
        if(relatedTo == nil)
            return nil;
        
        return valToList(relatedTo[a]).indexOf(b) != nil;
    }
    
    inverselyRelatedTo(a)
    {
        local lst = relatedTo.keysToList();
        local vec = new Vector;
        
        foreach(local cur in lst)
        {
            if(valToList(relatedTo[cur]).indexOf(a))
                vec.append(cur);
        }
        
        return vec.toList();
    }
    
    /* objs should be supplied as a two-element list */
    addRelation(objs)
    {
        if(relatedTo == nil)
        {
            relatedTo = new LookupTable;
            relatedTo.setDefaultValue([]);
            
            
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
                foreach(local cur in relatedTo[key])
                    relatedTo[cur] = relatedTo[cur] - key;
            }
            
            relatedTo.removeElement(key);
            return;
        }
        
        local existing = relatedTo[key];
        
        switch(relationType)
        {
        case oneToOne:
            relatedTo[key] = [val];           
            makeUnique(key, val);
            
            if(reciprocal)       
            {
                relatedTo[val] = [key];                          
                makeUnique(val, key);
            }
            break;
        case oneToMany:   

            /* Deliberate fall-through */
        case manyToMany:
            relatedTo[key] = (nilToList(existing)).appendUnique([val]);
            if(reciprocal)
                relatedTo[val] = nilToList(relatedTo[val]).appendUnique([key]);
            break;          
            
        case manyToOne:
            relatedTo[key] = [val];
            
            break;
        }
    }
    
    makeUnique(key, val)
    {
        local lst = relatedTo.keysToList();
        foreach(local cur in lst)
        {
            if(cur != key && relatedTo[cur] == [val])
                relatedTo.removeElement(cur);            
            
        }
    }
    
    removeRelation(objs)
    {
        if(relatedTo == nil)
            return;
        
        local key = objs[1];
        local val = objs[2];
        
        switch(relationType)
        {
        case oneToOne:
        case manyToOne:
            relatedTo.removeElement(key);
            if(reciprocal)
                relatedTo.removeElement(val);
            break;
            
        case oneToMany:    
        case manyToMany:
            relatedTo[key] = relatedTo[key] - val;
            if(reciprocal)
                relatedTo[val] = relatedTo[val] - key;
            break;
        }
        
    }
    
    relationType = oneToOne
    
    reciprocal = nil
    
    operator []=(b, c)
    {
        addRelation([b, c]);
        return self;
    }
    
    operator [] (b)
    {
        return relatedTo[b];
    }
    
   
    
       
;

relationTable: PreinitObject
   nameTab = static new LookupTable
    
    execute()
    {
        for(local rel = firstObj(BaseRelation); rel != nil; rel = nextObj(rel,
            BaseRelation))
        {
            if(rel.name)
                nameTab[rel.name] = [rel, 0];
            if(rel.reverseName)
                nameTab[rel.reverseName] = [rel, 1];
         
            
        }
    }

    getRelation(rel)
    {
        if(dataType(rel) == TypeSString)
            return nameTab[rel];
        
        return [rel, 0];
    }
;





relate(a, rel, b)
{
    local relData = relationTable.getRelation(rel);
    if(relData)
    {
        if(relData[2] == 0)
            relData[1].addRelation([a, b]);
        
        if(relData[2] == 1)
            relData[1].addRelation([b, a]);
    }   
}

unrelate(a, rel, b)
{
    local relData = relationTable.getRelation(rel);
    if(relData)
    {
        if(relData[2] == 0)
            relData[1].removeRelation([a, b]);
        
        if(relData[2] == 1)
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
    local lst;
    local relData = relationTable.getRelation(rel);
    
    
    if(b != nil && relData[2] == 0)
        return relData[1].isRelated(a, b);
    
    
        
    
    if(relData[2] == 0)
        lst = relData[1].relatedTo[a];
    else if(b == nil)
        lst = relData[1].inverselyRelatedTo(a);
    else
    {
        lst = relData[1].relatedTo[b];
        b = a;
    }     
         
    
    if(b)
        return valToList(lst).indexOf(b) != nil;
    else
        return lst;
    
}

/* 
 *   A DerivedRelation is a Relation that exists by virtue of another Relation
 *   and can be derived from it by user-define rules. E.g. the children of the
 *   same parents are siblings.
 */
class DerivedRelation: BaseRelation
    
    isRelated(a, b) { return relationList(a).indexOf(b) != nil; }
    
    relationList(a) { return []; }
    
    isInverselyRelated(a, b) 
    { return inverseRelationList(a).indexOf(b) != nil; }
    
    inverseRelationList(a) { return []; }
;