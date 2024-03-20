#charset "us-ascii"
#include "advlite.h"

/* 
 *   The Scenery Class allows a number of Decoration objects to be created on one master Scenery
 *   object, potentially saving having to create several or many Decoration objects manually. It is
 *   intended principally for Decorations for which we just want a description.
 *
 *   Note that we shouldn't define any vocab or description on the Scenery object itself, but we
 *   should put it in the location where we want the Decoration objects it creates to be lccated.
 */
 
 
class Scenery: Decoration
    /* 
     *   The list of vocab, descriptions and optionally notImportantMsgs for each of our Decoratio
     *   objects. Each item in the list should be a list of two or three items of the form
     *.
     *   [vocab, desc]
     *.       or
     *   [vocab, desc, notImportantMsg]
     *.
     *   vocab and notImportantMsg must be supplied as single-quoted strings. desc can be either at
     *   single-quoted string or an anonymous method or function. The vocab string should be defined
     *   as for the vocab string of a normal Thing.
     *.
     *   The scenList property can be defined through the Scenery template.
     */
    scenList = []
    
    /* A list of the Decoration objects created by this Scenery object at preInit. */
    myObjs = []
    
    /* 
     *   PreInitialization of a Scenery object creates the Decoration objects defined in our
     *   ScenList property.
     */
    preinitThing()
    {
        /* Iterate through every item in our scenList to create a Decoration object based on it. */
        foreach(local item in scenList)
        {
            /* Store a reference to the vocab we want to give the current object. */
            local voc = item[1];
            
            /* 
             *   Store a reference to the description we want to give the current object. This can
             *   be either a single-quoted string or an anonymous method or function.
             */
            local des = item[2];
                        
            /*  
             *   Create a mew ScenItem Decoration object and store a reference to it. We delegate
             *   this to a separate method so subclasses can override.
             */
            local obj = newObj();
            
            
            /* 
             *   What we so with des depends on whether it's a single-quoted string or an anonymous
             *   method or function.
             */
            switch(dataTypeXlat(des))
            {
                /* If it's a single-quoted string, copy it to our new object's descStr property. */
            case TypeSString:
                obj.descStr = des;
                break;
                
                /* 
                 *   If it's an anonymous method or function, assign it to our new objects desc
                 *   method.
                 */
            case TypeFuncPtr:
                obj.setMethod(&desc, des);
                break;
                
                            
            }
            
            /* Copy our vocab to our new object's vocab property. */
            obj.vocab = voc;
            
            /* 
             *   Initialize our new object's vocab (and other propertites such as its name) from its
             *   vocab string.
             */
            obj.initVocab();
            
            /*  Store a reference to the new object in our myObjs list. */
            myObjs += obj;
            
            /*  Store a reference to ourself in our new object's masterObj property. */
            obj.masterObj = self;
            
            /* 
             *   Initialize the location of our new object. We delegate this to a separate method so
             *   sublcasses can override.
             */
            initLocation(obj);
             
            /*  Assign a notImportantMsg to our new item, if we have defined one. */
            if(item.length > 2)               
                obj.notImportantMsg = item[3];
        }
    }
    
    /* 
     *   For the base Scenery claas, create a new object of the ScenItem class and returnb a
     *   reference to it.
     */
    newObj() { return new ScenItem; }
    
    /*   For the base Scenery class, move our new object into our own location. */
    initLocation(obj) {obj.moveInto(location); }
;

/* 
 *   A Scenery object we want to act like a MultiLoc, that is one that creates a series of MultiLoc
 *   Scenery object. Note that a MultiLccScenery object is *not* itself a MultiLoc, so cannot be
 *   defined as MultiLoc, Scenery. Rather it is an object that creates a set of MultiLoc Scenery
 *   objects (of the MultiScenItem class), which will take there locations from our location
 *   properties.
 *
 */
class MultiLocScenery: Scenery
    newObj() { return new MultiScenItem; }
    
    /* 
     *   Initialze the location or set of locations each of the decorationa we are to create is to
     *   appear in.
     */
    initLocation(obj)
    { 
        /* Copy our locationList to our new object's */  
        obj.locationList = locationList;
        
        /* Copy our initialLocationList to our new object's */
        obj.initialLocationList = initialLocationList;
        
        /* Copy our locationClass to our new object's */
        obj.initialLocationClass = initialLocationClass;
        
        /* Copy our exceptions to our new object's */
        obj.exceptions = exceptions;
        
        /* 
         *   Call our new object's addToLocation method to add to the contents of each of its
         *   locations, as defined by the previous properties.
         */
        obj.addToLocations();  
        
    }
    
    /* 
     *   Our locationList, initialLocationList, initialLocationClass, and exceptions properties have
     *   the same meaning as they do on a MultiLoc but will be applied to the MultiScenItem objects
     *   we create, not directly to ourself.
     */
    locationList = nil
    initialLocationList = nil
    initialLocationClass = nil
    exceptions = []
    
    /*
     *   Test an object for inclusion in our initial location list.  By default, we'll simply return
     *   true to include every object.  We return true by default so that an instance can merely
     *   specify a value for initialLocationClass in order to place this object in every instance of
     *   the given class. The MultiLoc objects we create will use our version of this method.
     */
    isInitiallyIn(obj) { return true; }
    
    
    /* 
     *   We can call moveIntoAdd() on us to call it on each of the MultiLoc decorations we have
     *   created.
     */
    moveIntoAdd(loc)
    {
        foreach(local obj in myObjs)
            obj.moveIntoAdd(loc);
    }
    
     /* 
     *   We can call moveIOutOf() on us to call it on each of the MultiLoc decorations we have
     *   created.
     */
    moveOutOf(loc)
    {
        /* 
         *   Let the new location handle it, so it will work whether the new
         *   location is a Thing, a Room or a Region.         
         */
        foreach(local obj in myObjs)
            loc.moveMLOutOf(obj);        
    }
    
     /* 
     *   We can call moveInto() on us to call it on each of the MultiLoc decorations we have
     *   created.
     */
    moveInto(loc)
    {
        foreach(local obj in myObjs)
            obj.moveInto(loc);
    }
;

/* 
 *   A ScenItem is a special kind of Decoration created by the Scenery class. Note that there is
 *   probably no good reason to define a ScenItem object directly in game code.
 */
class ScenItem: Decoration
    /* 
     *   Our description. We just display out descStr. This can be overridden if our masterObj's
     *   scenList created us with an anonymous method or function for our description, in which case
     *   that method or function will be assigned to our desc() property.
     */
    desc() { say(descStr); }
    
    /* 
     *   A single-quoted string that gives our description. This is assigned by the Scenery object
     *   that created us.
     */
    descStr = ''
    
     /* The Scenery item that created us. */
    masterObj = nil
;


/* 
 *   A MultiScenItem is a MultiLoc Decoration created by a MultiLocScenery object. Note that there
 *   is probably no good reason for defining one of these objects directly in game code.
 */
class MultiScenItem: MultiLoc, ScenItem    
   
    
    /*
     *   Test an object for inclusion in our initial location list.  By default, we'll simply return
     *   true to include every object.  We return true by default so that an instance can merely
     *   specify a value for initialLocationClass in order to place this object in every instance of
     *   the given class. We return the value of our masterObj's isInitiallyIn() method. 
     */
    isInitiallyIn(obj) { return masterObj.isInitiallyIn(obj); }
;