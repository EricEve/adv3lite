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
                local dest = loc.(dir.dirProp).getDestination(loc);
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
                local dest = conn.getDestination(loc);
                
                /* 
                 *   if both the location (loc) and the destination (dest) lie
                 *   in the same familiar region, then assume the pc knows
                 *   his/her way between the two rooms and so set
                 *   isDestinationKnown to true
                 */
                
                if(!conn.isDestinationKnown && 
                   loc.regionsInCommonWith(dest).indexWhich(
                       {x: x.isFamiliar(gPlayerChar.knownProp)}) != nil)//                       
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


/* 
 *   An AskConnector is a specialized TravelConnector that leads to more than one possible
 *   destination (e.g., two doors that lie to the east) which player needs to choose between when
 *   trying to travel in the relevant direction. If routefinding finds a route through an
 *   AskConnector, the choice will be made on the player's behalf when executing a GO TO or CONTINUE
 *   commsnd.
 */
class AskConnector: TravelConnector
    
    /* 
     *   The list of conectore (doors, passages, stairways or whatever) that lie in the direction
     *   this AskConnector leads. There should be at least two items in this list.
     */
    options = []
    
    /* 
     *   Our notional destination (which code may fall back on if all else fails). By default we use
     *   the first item in our options list.
     */
    destination = options[1]
    
    /*   Our effective location is the room we lead from. */    
    effectiveLocation = lexicalParent ?? location
    
    /* 
     *   The travel action to be used if when we ask the player to choose one of our options. This
     *   defaults to TravelVia, which is suitable for just about anything, but could be overriden to
     *   GoThrough or Enter if they seen a better choice in any given case.
     */
    travelAction = TravelVia
    
    
    /*   
     *   Our destination normally depends on which of our options the player chooses, but if a route
     *   finder is trying to find a route for us, our destination needs to be whichever of our
     *   options leads to the player's desired destinations. Note that the value returned by this
     *   mathod is relevant only to the poRouteFinder when it's trying to find a path or to the exit
     *   lister when deciding how to colour exits.
     */     
    getDestination(origin)       
    {
         /* Cache a list of the rooms our options lead to. */
        local dests = getDestinations(origin);  
        
        /* 
         *   If the last command wasn't GO TO we're not trying to find a path. The exit lister may
         *   be trying to use us to see if the room we lead to has been visited, so return any
         *   unvisited room if we have one (so the exit lister will show there are still rooms to
         *   visit through us) or else just return the value of our destination property.
         */
        if(gAction != GoTo)
        {
            local dest = dests.valWhich({x:!x.visited});
            
            return dest ?? destination;
        }
       
        
        /* 
         *   If we haven't already got a destination table, create it, and populate with the rooms
         *   our options immediately lead to.
         */
        if(destTab == nil)
        {
            destTab = new LookupTable();
            
            foreach(local dest in dests)            
                destTab[dest] = dest;                        
        }
        
        /* 
         *   Note out target destionation, the room the player is trying to reach via the GO TO
         *   commasnd just issued.
         */
        local target = gDobj.getOutermostRoom;
                
        /* 
         *   If there's already a destination (for this AskConnector) in our destination table for
         *   this target, simply return it.
         */
        local dest = destTab[target];
        
        if(dest)
            return dest;       
                     
        
        /* 
         *   Otherwise recursively run through all the destinations we immediately lead to in order
         *   to establich whether any of them lies on a path to our target. If we find one, return
         *   it.
         */
        foreach(dest in dests)
        {
            local res = findDestFor(dest, target, dest);
            if(res)
                return res;
        }
        
        /* 
         *   If we reach here, none of our destinations is on a path to our target, so simply return
         *   the value of our destination property (which should be irrelevant to the pathfinder's
         *   calculation.
         */
        return destination;
    }
        
        
               

    /* 
     *   Find which of the destinations led to by our options list would be on the route to target
     *   from loc and add any we find to our destTab tablle.
     */
    findDestFor(loc, target, origin)
    {
        for(local dir = firstObj(Direction); dir != nil ; dir = nextObj(dir,
            Direction))
        {
            local dests = new Vector();
            
            /* 
             *   If the direction property points to an object, see if it points
             *   to a valid path.
             */
            if(loc.propType(dir.dirProp) == TypeObject)                
            {
                local conn = loc.(dir.dirProp);
                
                /* 
                 *   If it leads to a non-nil destination that the pc knows, note what that
                 *   destination is.
                 *
                 */    
                local dest = conn.getDestination(loc);
                
                /* 
                 *   if both the location (loc) and the destination (dest) lie
                 *   in the same familiar region, then assume the pc knows
                 *   his/her way between the two rooms and so set
                 *   isDestinationKnown to true
                 */
                
                if(!conn.isDestinationKnown && 
                   loc.regionsInCommonWith(dest).indexWhich(
                       {x: x.isFamiliar(gPlayerChar.knownProp)}) != nil)//                       
                    conn.isDestinationKnown = true;
                
                /* 
                 *   if the connector leads to a known destination that we haven't yet stored in our
                 *   destTab table, then add it to the destTab table (which notes that this dest can
                 *   be reached from origin, which should be one of the destinations led to by the
                 *   connectors in our options list) and append it to the list of destinations that
                 *   could be reached from loc.
                 */
                
                if(dest != nil && destTab[dest] == nil && conn.isDestinationKnown)
                {
                    destTab[dest] = origin;
                    dests.append(dest);
                    
                    /* 
                     *   If this destination is the target we're trying to reach, then return the
                     *   origin room we started out from.
                     */
                    if(dest == target)
                        return origin;
                    
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
                 *   the destination is only of interest if it's not nowhere, the default unknown
                 *   destination, the location we're working out from, the origin we started from or
                 *   the room this AskConnector leads from.
                 *
                 *
                 *   If it's none of these, add it to the list of possible paths (The fact that it's
                 *   none of these implies that the destination is known so we don't need to apply
                 *   any further tests to check that).
                 *
                 */
                if(dest not in (nil, loc, unknownDest_, varDest_, origin, effectiveLocation))                                      
                {           
                    /* 
                     *   If this destination has not yet been noted in out destTab, then add it to
                     *   the destTab and append it to the list of destinations directly accessible
                     *   from this location.
                     */
                    if(destTab[dest] == nil)
                    {
                        destTab[dest] = origin;
                        dests.append(dest);
                    }
                    
                    /* 
                     *   If this is our target destination, then return the origin room we started
                     *   out from (which will be one of the rooms the travel connectors in our
                     *   options list lead to.
                     */
                    if(dest == target)
                        return origin;
                }                
            }
            
            /* 
             *   If the list of (hopefully unvisited) destinations immediatlel leading off from this
             *   location is greater than zero, then iterate through them calling this method
             *   recursively.
             */
            if(dests.length > 0)                
            {
                foreach(local dest in dests)                    
                {                    
                    /* 
                     *   We're not interested in iterating back out to the room this AskConnector
                     *   leads from, so we exclude that, but otherwise we see if we can reach our
                     *   target destination from any of the rooms in the dests list; if we return
                     *   the original room (one of those led to by one of the connectors in our
                     *   options list) to our caller.
                     */
                    if(dest != effectiveLocation)
                    {
                        local res =  findDestFor(dest, target, origin);
                        if(res)
                            return res;
                    }
                }
            }                 
            
        }  
        
        /* 
         *   If we reach here we haven't found a path from out origin room to our destination room,
         *   so we return nil to our caller to signal our failure.
         */
        return nil;
    }
    
    /* Return a list of the rooms the connections listed in our options property lead to, */
    getDestinations(origin)
    {
        return options.mapAll({x: x.getDestination(origin)});
    }
               
    /* 
     *   To execute our travel we first see if the player character is making the next move in
     *   response to a GOTO or CONTINUE command. If so then we select whichever of our options leads
     *   to a room on the way to our destination and choose that, executing its travelVia() method
     *   without any further intervention if we find a suitable choice. Otherwise we display a
     *   message listing our options and ask the player to choose which one to use.
     */
    execTravel(actor, traveler, conn)
    {
        /* 
         *   An AskConnector is not really designed to work directly with Rooms in its list of
         *   options. but should this occur we try to handle it gracefully.
         */
        if(options.indexWhich({x: x.ofKind(Room)}))
        {   
            /* 
             *   We can't handle Rooms and non-Rooms in the same list of options, so if we encounter
             *   this we need to report an error and give up.
             */
            if(options.indexWhich({x: !x.ofKind(Room)}))
            {
                "<b><FONT COLOR='RED'>ERROR:</FONT></b> You cannot mix Rooms and Non-Rooms in the
                options property of an AskConnector\b
                <<list of options>>";
                exit;
            }
            /* 
             *   Otherwise we need to change our travel action to GoTo and mark every room in our
             *   options list as familiar and visited so that the GoTo command will work on it.
             */
            else if(travelAction != GoTo)
            {
                travelAction = GoTo;
                foreach(local o in options)
                {
                    o.familiar = true;
                    o.visited = true;
                }
            }           
        }
        
        /* 
         *   If we have an options property, list the options it contains (e.g., 'that wat lies the
         *   red door and the blue door') and ask the player to specify which one to go through.
         */        
        if(gActionIn(GoTo, Continue))
        {
            /* Get a list of rooms along our route. */
            local rooms = pcRouteFinder.cachedRoute.mapAll({x: x[2]});
            
            
            /* Restrict this to the list that starts from the actor's room */     
            local ri = rooms.indexOf(gActor.getOutermostRoom);
            if(ri)
                rooms = rooms.toList().sublist(ri);
            
            /* 
             *   The connector we want to use is the one among our options whose destination is one
             *   of the rooms along our route.
             */
            
            local connToUse 
                = options.valWhich({x: rooms.indexOf(x.getDestination(effectiveLocation))});
            
            /* 
             *   If we find one, then use its travelVia() method to move the actor, then return,
             *   because we'll be done.
             */
            if(connToUse)
            {
                connToUse.travelVia(actor);
                return;                                         
            }
        }
        
        /* Otherwise ask the player which connector to use. */            
        DMsg(multi destination, 'That way {plural}{lie} {1}. ',  
             makeListStr(options, &theName, 'and', true));
        askForDobjX(travelAction);            
        return;        
    }
    
    /* 
     *   A LookUp table to cache which of our options' immediate destinations this AskConnector
     *   notionally leads to when we're on a path to any given to anu given target destination.
     */
    destTab = nil   
;


