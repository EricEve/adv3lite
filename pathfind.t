#charset "us-ascii"
#include "advlite.h"

/* Abstract pathfinder */
class Pathfinder: object
    
    /* 
     *   When populated the pathsFound will contain a Vector of path Vectors,
     *   each path Vector comprising a series of two element lists, the first
     *   element describing the route taken and the second the destination
     *   arrived at (e.g. [northDir, hall] meaning go north to reach the hall).
     */
    
    pathsFound = nil
    
    /* 
     *   The number of steps we have tried so far. We start with 1, being the
     *   null step to our starting point.
     */
    steps = 1
    
    /* 
     *   A Vector containing all the nodes we have visited so far in our attempt
     *   to find a route. This enables us to cull paths that lead somewhere
     *   we've already been.
     */
    
    nodesVisited = nil
    
    
    findPath(start, target)
    {
        /* 
         *   Initiate the search by setting up the Vectors we need and
         *   populating them with the null route to our starting point.
         */
            
        cachedRoute = nil;
        currentDestination = target;
        
        pathsFound = new Vector(20);
        nodesVisited = new Vector(20);
        local newPath = new Vector(2);
        newPath.append([nil, start]);
        pathsFound.append(newPath);
        nodesVisited.append(start);
        steps = 1;
        if(start == target)
            return newPath;
        
        
        /* 
         *   To find the path we take a step out from our starting point through
         *   all available routes. We note the route we took and where we
         *   arrived at as a set of new paths building on our existing paths. We
         *   then discard all paths that are shorter than the number of steps we
         *   have now taken and look for one among the remainder that arrives at
         *   our target destination. If we find one, we return it. If not, we
         *   remove all paths that lead to destinations we have visited before,
         *   and then try taking another step, noting the destinations to which
         *   it leads. Repeat until we either find a path to our target or we
         *   run out of new paths to try.
         */
        
        while(pathsFound.length > 0)
        {
            takeOneStep();
            
            /* cull all paths that are shorter than steps long */
            
            pathsFound = pathsFound.subset({x: x.length == steps});
            
            /* see if any of the paths we've found lead to our target */
            local pathFound = pathsFound.valWhich({x: x[steps][2] == target} );
            if(pathFound != nil)
            {
                cachedRoute = pathFound;
                return pathFound;
            }
            
            /* remove all paths that end in nodes we've already visited */
            pathsFound = pathsFound.subset({x: nodesVisited.indexOf(x[steps][2])
                                           == nil});
                
                /* note which nodes have now been visited */
                
            foreach(local cur in pathsFound)
                nodesVisited.append(cur[steps][2]);
            
            
         }
        
        return nil;
    }
    
    takeOneStep()
    {
        /* Note that we've taken another step out from our starting point */
        steps ++;
        
        /* 
         *   Copy the existing paths into a temporary Vector, since we're about
         *   to add to them and we only want to iterate over the existing list.
         */
        local temp = new Vector(pathsFound);
        
        /* 
         *   For each existing route, see what happens if we advance one more
         *   step in every available direction and add the new routes to our
         *   list of paths.
         */
        foreach(local cur in temp)
            findDestinations(cur);
    }
    
    /* Find all the destinations one step away from cur */
    findDestinations(cur)
    {
        /* Specific instances must define how this is done */
    }
    
    /* The most recently calculated route */
    cachedRoute = nil
    
    /* The destination of the most recently calculated route. */
    currentDestination = nil
    
;

/* 
 *   A Pathfinder specialized for finding a route through the game map. Note
 *   that this can only find a route through TravelConnector objects (which
 *   includes direction properties attached to Rooms, Doors and other
 *   TravelConnectors).
 */
routeFinder: Pathfinder    
    
    findDestinations(cur)
    {
        /* Note the location our current path leads to */
        local loc = cur[steps - 1][2];
        
        /* See what leads in every available direction from this location */
        for(local dir = firstObj(Direction); dir != nil ; dir = nextObj(dir,
            Direction))
        {
            local newPath = new Vector(cur);
            
            /* 
             *   If the direction property points to an object, see if it points
             *   to a valid path.
             */
            if(loc.propType(dir.dirProp) == TypeObject)
            {
                local obj = loc.(dir.dirProp);
                
                /* 
                 *   if the object is a locked door and we want to exclude
                 *   locked doors, or if there's some other reason the actor
                 *   cannot pass this way, we can't use this path.
                 */
                
                if(excludeLockedDoors &&
                    (obj.isLocked 
                      || obj.canTravelerPass(gActor) == nil
                      || valToList(obj.travelBarriers).indexWhich(
                          { b: !b.canTravelerPass(gActor, obj)}) != nil))
                    return;
                
                
                /* 
                 *   If it leads to a non-nil destination note the path to this
                 *   object. This will be the path that got us to this location
                 *   plus the one additional step.
                 */    
                local dest = loc.(dir.dirProp).destination;
                if(dest != nil)
                {
                    newPath.append([dir, dest]);
                    pathsFound.append(newPath);
                }
            }
            
            /*  
             *   if the direction property points to code, see if it provides a
             *   valid path.
             */
            
            if(loc.propType(dir.dirProp) == TypeCode)
            {
                /* first look up the destination this code takes the actor to */
                local dest = libGlobal.extraDestInfo[[loc, dir]];
                
                /* 
                 *   the destination is only of interest if it's not nowhere,
                 *   the default unknown destination, or the location we're
                 *   trying to leave.
                 *
                 *
                 *   if it's none of these, add it to the list of possible paths
                 *
                 */
                if(dest not in (nil, loc, unknownDest_, varDest_))                   
                {
                    newPath.append([dir, dest]);
                    pathsFound.append(newPath);
                }
                
            }
            
        }
    }   
    
    excludeLockedDoors = true
;

/* 
 *   The pcRouteFinder works exactly the same as the more general routeFinder
 *   except that it finds routes only through TravelConnectors whose
 *   destinations are known.
 */
pcRouteFinder: Pathfinder
    findDestinations(cur)
    {
        /* Note the location our current path leads to */
        local loc = cur[steps - 1][2];
        
        /* See what leads in every available direction from this location */
        for(local dir = firstObj(Direction); dir != nil ; dir = nextObj(dir,
            Direction))
        {
            local newPath = new Vector(cur);
            
            /* 
             *   If the direction property points to an object, see if it points
             *   to a valid path.
             */
            if(loc.propType(dir.dirProp) == TypeObject)                
            {
                local conn = loc.(dir.dirProp);
                
                /* 
                 *   If it leads to a non-nil destination that the pc knowns,
                 *   note the path to this object. This will be the path that
                 *   got us to this location plus the one additional step.
                 */    
                local dest = conn.destination;
                
                /* 
                 *   if both the location (loc) and the destination (dest) lie
                 *   in the same familiar region, then assume the pc knows
                 *   his/her way between the two rooms and so set
                 *   isDestinationKnown to true
                 */
                
                if(!conn.isDestinationKnown && 
                   loc.regionsInCommonWith(dest).indexWhich(
                       {x: x.familiar}) != nil)
                    conn.isDestinationKnown = true;
                
                /* 
                 *   if the connector leads to a known destination then add the
                 *   direction and its destination to a new path
                 */
                
                if(dest != nil && conn.isDestinationKnown)
                {
                    newPath.append([dir, dest]);
                    pathsFound.append(newPath);
                }
            }
            /*  
             *   if the direction property points to code, see if it provides a
             *   valid path.
             */
            
            if(loc.propType(dir.dirProp) == TypeCode)
            {
                /* first look up the destination this code takes the actor to */
                local dest = libGlobal.extraDestInfo[[loc, dir]];
                
                /* 
                 *   the destination is only of interest if it's not nowhere,
                 *   the default unknown destination, or the location we're
                 *   trying to leave.
                 *
                 *
                 *   if it's none of these, add it to the list of possible paths
                 *   (The fact that it's none of these implies that the
                 *   destination is known so we don't need to apply any further
                 *   tests to check that).
                 *
                 */
                if(dest not in (nil, loc, unknownDest_, varDest_))                                      
                {
                    newPath.append([dir, dest]);
                    pathsFound.append(newPath);
                }                
            }
        }  
        
    }
;


