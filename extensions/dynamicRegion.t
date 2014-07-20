#charset "us-ascii"
#include <tads.h>
#include "advlite.h"

/*
 *  DYNAMIC REGION EXTENSION
 *
 * A DynamicRegion is a Region that can be expanded or contracted during the
 * course of play, but which comes with certain restrictions; in particular a
 * DynamicRegion cannot be part of any other Region.
 */
class DynamicRegion: Region
    
    /*
     * A DynamicRegion cannot be part of any other Region, so any value given
     * to this property in game code will be ignored.
     */
    regions = nil
    
    /* A DynamicRegion cannot be in any other region, so we simply return nil */
    
    
    isIn(region)
    {
        return nil;
    }
    
    /* The list of regions a DynamicRegion is in is simply an empty list. */
    allRegions = []
    
    
    /*
     * Add an additional room (passed as the rm parameter) to our list of
     * rooms. This method is intended for internal library use at PreInit
     * only.
     */
    addToRoomList(rm)
    {
        /*
         *   Add rm to our existing roomList, making sure we don't duplicate an
         *   existing entry, and converting the roomList from nil to a list if
         *   isn't a list already.
         */
        roomList = nilToList(roomList).appendUnique([rm]);
        
    }
    
     /*
     * Put extra items in scope when action is carried out in any room in this
     * region.
     */
    addExtraScopeItems(action)
    {
        /*
         * Add our list of extraScopeItems to the existing scopeList of the
         * action, avoiding creating any duplicate entries.
         */
        action.scopeList =
            action.scopeList.appendUnique(valToList(extraScopeItems));
        
    }
    
     /* Carry out before notifications on the region */
    notifyBefore()
    {
        /* Just call our own regionBeforeAction() method */
        regionBeforeAction();
    }
    
     /* Carry out after notifications on the region */
    notifyAfter()
    {
        /* Just call our own regionAfterAction() method */
        regionAfterAction();
    }
    
    /*
     * Expand this region by adding rm to it. rm may be a single Room or a
     * list of Rooms or a single Region or a list of Regions or a list of
     * Rooms and Regions. Note, however, that the effect of specifying Regions
     * as an argument to this method is only a shorthand way of specifying the
     * rooms the Regions contain; no permanent relationship is created between
     * a DynamicRegion and any other Regions added to it.
     */
    expandRegion(rm)
    {
        /* Convert rm to a list if it isn't one already */
        rm = valToList(rm);
        
        foreach(local cur in rm)
        {
            
            if(cur.ofKind(Region))
            {
                roomList = valToList(roomList).appendUnique(cur.roomList);
                foreach(local r in cur.roomList)
                    r.regions = valToList(r.regions).appendUnique([self]);
            }
            else
            {
                roomList = valToList(roomList).appendUnique([cur]);
                cur.regions = valToList(cur.regions).appendUnique([self]);
                cur.allRegions = valToList(cur.allRegions).appendUnique([self]);
            }
        }
        
        /* Carry out any extra adjustments needed. */
        extraAdjustments(rm, true);
    }
    
    /*
     * Remove rm from this Region. The rm parameter has the same meaning as
     * for expandRegion(rm).
     */
    contractRegion(rm)
    {
         /* Convert rm to a list if it isn't one already */
        rm = valToList(rm);
        
        foreach(local cur in rm)
        {
            if(cur.ofKind(Region))
            {
                roomList = valToList(roomList) - cur.roomList;
                foreach(local r in cur.roomList)
                    r.regions = valToList(r.regions) - self;
            }
            else
            {
                roomList = valToList(roomList) - cur;
                cur.regions = valToList(cur.regions) - self;
                cur.allRegions = valToList(cur.allRegions) - self;
            }
        }
        
        /* Carry out any extra adjustments needed. */
        extraAdjustments(rm, nil);
    }
    
    /*
     * Carry out any additional adjustments that need to be made as
     * side-effects to adding or removing rooms. By default we do nothing here
     * but game code can override as necessary. The rm parameter is the list
     * of rooms/regions that have just been added (if expanding is true) or
     * subtracted (if expanded is nil) from this region.
     */
    extraAdjustments(rm, expanded) { }
;

/* 
 * Modifications to Region to work safely with DynamicRegion 
 * [DYNAMICREGION EXTENSION */
 */
modify Region
    /*
     *    A DynamicRegion cannot contain other regions 
     *    [DYNAMIC REGION EXTENSION]
     */
    isIn(region)
    {
        if(region && region.ofKind(DynamicRegion))
            return nil;
        
        return inherited(region);
    }
    
    
    /*
     * A Region is not allowed to be part of a DynamicRegion, so clear out any
     * DynamicRegions from our list of Regions at PreInit.
     * [DYNAMIC REGION EXTENSION]
     */
    makeRegionLists()
    {
        regions = valToList(regions).subset({r: !r.ofKind(DynamicRegion) });
        
        inherited();
    }
    
    /*
     * Tests whether this room is currently contained within region in the
     * sense that all our rooms are also in region.
     * [DYNAMIC REGION EXTENSION]
     */
    isCurrentlyWithin(region)
    {
        return (roomList.intersect(region.roomList).length == roomList.length);
    }
;

