#charset "us-ascii"
#include "advlite.h"

/*---------------------------------------------------------------------------*/
/*   
 *   MobileCollective Group Extension
 *
 *   This extension requires events.t and extras.t to be present also.
 */


/* 
 *   A MobileCollectiveGroup is a CollectiveGroup that can be used to represent
 *   a collection of portable objects, different members of which may be in
 *   scope at any given moment. A MobileCollectiveGroup is moved into the
 *   player's location if more than one of its members is visible at the start
 *   of any turn and moved into nil otherwise.
 */

class MobileCollectiveGroup: PreinitObject, CollectiveGroup
    execute()
    {
        /* Set up a daemon to execute every turn */
        myDaemon = new Daemon(self, &scopeCheck, 1);
        
        /* 
         *   Give the daemon a high event order so that it runs after other
         *   events if possible.
         */
        myDaemon.eventOrder = 10000;
        
        /* Set up a prompt daemon to execute just before the first turn */
        new OneTimePromptDaemon(self, &scopeCheck);
        
        /* Create a new vector */
        local vec = new Vector;
        
        /* 
         *   Populate the vector with all the Things in the game that include
         *   this MobileCollectiveGroup in their collectiveGroups property.
         */
        for(local obj = firstObj(Thing); obj != nil; obj = nextObj(obj, Thing))
        {
            if(valToList(obj.collectiveGroups).indexOf(self))
                vec.append(obj);
        }
        
        /* 
         *   Convert the vector to a list and store the result in the myObjs
         *   property.
         */
        myObjs = vec.toList;
    }
    
    /*  
     *   If the player can see more than one of the objects that belong to this
     *   CollectiveGroup, move it to the player's location (so that it can stand
     *   in for those objects when required); otherwise move this
     *   CollectiveGroup out of the way.
     */
    scopeCheck()
    {
        if(myObjs.countWhich({x: gPlayerChar.canSee(x)}) > 1)
            moveInto(gPlayerChar.location);
        else
            moveInto(nil);        
    }
    
    /* 
     *   The list of objects belonging to this MobileCollectiveGroup; this is
     *   created automatically at PreInit.
     */
    myObjs = nil
    
    /* 
     *   Store a reference to the Daemon used to update the location of this
     *   MobileCollectiveGroup.
     */
    myDaemon = nil
;