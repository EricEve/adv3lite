#charset "us-ascii"
#include "advlite.h"


/* Objective Time module */



timeManager: InitObject
    
    /* 
     *   In case the game doesn't specify a starting date we default to midnight
     *   on January 1st 2000.
     */
    currentTime = static new Date(2000, 1, 1)
    
    execute()
    {
        /* 
         *   Get our starting time from the gameMain object, unless we're
         *   getting it from the clockManager.
         */
        if(defined(clockManager) && clockManager.lastEvent)
            ;
        else if(gameMain.propType(&gameStartTime) == TypeList)
            currentTime = new Date(gameMain.gameStartTime...);
        else if(gameMain.propType(&gameStartTime) == TypeObject 
                && gameMain.gameStartTime.ofKind(Date))
            currentTime = gameMain.gameStartTime;
        
        /* Set up the PromptDaemon to reset certain values each turn. */
        new PromptDaemon(self, &reset);
    }
    
    reset()
    {
        /* Reset the additional time to 0. */
        additionalTime = 0;
            
        /* Reset the replacement time to nil */
        replacementTime = nil;       
    }
    
    /* 
     *   The number of seconds to add to the time taken on the current turn in
     *   addition to the standard time for this action.
     */
    additionalTime = 0
    
    /*   
     *   If this is not nil, use this as the number of seconds taken by the
     *   current turn instead of the number computed from the action plus
     *   additionalTime.
     */
    replacementTime = nil
    
    /* 
     *   Advance the time at the end of a turn (during the afterAction
     *   processing).
     */
    advanceTime(secs)
    {
        /* 
         *   If we have set a replacementTime (via a call from takeTime()) then
         *   use that as the length of the action. Otherwise use the time from
         *   the action plus any time that's been added (or subtracted) via the
         *   addTime() function.
         */        
        secs = replacementTime == nil ? secs + additionalTime : replacementTime;
        
        /* 
         *   Don't allow time to go into reverse. Provided secs is positive, add
         *   secs seconds to the current time.
         */
        if(secs > 0)
            currentTime = currentTime.addInterval([0,0,0,0,0,secs]);
    }
    
    /* 
     *   Return a string containing the current date and time formatted by fmt,
     *   where fmt is one of the strings specified in the SystemManual entry for
     *   Date.
     */
    formatDate(fmt)
    {
        return currentTime.formatDate(fmt);
    }
    
    /* 
     *   Set the current date and time. The possible arguments are those
     *   described for the Date constructor in the System Manual.
     */
    setTime([args])
    {
        /* 
         *   If the only argument supplied is a single string, add a nil
         *   timezone and the current date to make the reference date come out
         *   as the current date; this ensures that if the string specifies a
         *   time it will be interpreted as a time on the current in-game date,
         *   rather than the real-world date.
         */
        if(args.length == 1 && dataType(args[1] == TypeSString))
            currentTime = new Date(args[1], nil, currentTime);
        /* 
         *   Otherwise just pass all the arguments straight through to the Date
         *   constructor
         */
        else
            currentTime = new Date(args...);
    }
    
   /* 
    *   Adjust the currentDate by interval, where interval is specified as for
    *   the interval argument for the addInterval method of the Date class, i.e.
    *   as a list in the format [years, months, days, hours, minutes, seconds],
    *   from which trailing zeroes may be omitted.
    *
    *   interval may also be specified as an integer (in which case it will be
    *   taken as the number of minutes to advance) or as a BigNumber (in which
    *   case it will be taken as the number of hours).
    */    
    addInterval(interval)
    {   
        /* 
         *   If the interval is specified as a BigNumber, take that to be the
         *   number of hours.
         */
        if(dataType(interval) == TypeObject && interval.ofKind(BigNumber))
           interval = [0, 0, 0, interval];
        
        /* 
         *   If the interval is specified as an integer, take that to be the
         *   number of hours.
         */
        if(dataType(interval) == TypeInt)
            interval = [0, 0, 0, 0, interval];
           
        
        currentTime = currentTime.addInterval(interval);
    }
;

modify GameMainDef
    /* 
     *   The date and time at which this game notionally starts. This should be
     *   specified as a list of numbers in the format [year, month, day, hour,
     *   minute, second, millisecond]. Trailing zero elements may be omitted. We
     *   default to midnight on 1st January 2000, but game code should generally
     *   override this.
     */
    
    gameStartTime = [2000, 1, 1, 0, 0, 0, 0]
;

modify Action
    afterAction()
    {
        /* Advance the game clock */
        advanceTime();
        
        /* Carry out the inherited handling. */
        inherited();
    }
    
    /* Advance the notional game time */
    advanceTime()
    {
        if(advanceOnFailure || !actionFailed)
        {
            timeManager.advanceTime(timeTaken);
        } 
    }
       
    
    /* 
     *   Flag: should the game time be advanced if this action fails? By default
     *   we allow it to advance, but this can be overridden to nil for actions
     *   that should take no time if they're not carried out.
     */
    advanceOnFailure = true

    /*   
     *   The number of seconds it takes to carry out this action. By default we
     *   assume every action takes one minute, but this can be overridden either
     *   globally on the Action class or individually on each actiom.
     */
    timeTaken = 60
    
    /*   
     *   The number of seconds to carry out this action as an implicit action.
     *   By default we don't take any, since the normal convention seems to be
     *   to count implicit actions as part of the main action, but this could be
     *   overridden to be, say, the same as timeTaken if zero-time implicit
     *   actions were felt to give an unfair advantage to timed puzzles.
     */
    implicitTimeTaken = 0
    
    /*  Add our implicitTimeTaken to the total time taken for the turn. */
    addImplicitTime() 
    { 
        addTime(implicitTimeTaken);
    }
    
;

/*  
 *   A TimeFuse is a Fuse that executes either at a set time or after a set time
 *
 *   obj and prop are the same as for Fuse, i.e. when the Fuse fires it will
 *   call the prop property of obj.
 *
 *   interval may be speficied as a list, an integer, a BigNumber, a Date or a
 *   single-quoted string. A string or a Date specifies the time at which the
 *   Fuse will execute. Anything else specifies the time after which the Fuse
 *   will execute.
 *
 *   If interval is a list it should be in the form [years, months, days, hours,
 *   minutes, seconds] (trailing elements can be omitted if they are zero). The
 *   Fuse will then execute after the interval
 *
 *   If interval is an integer then it specifies the number of minutes into the
 *   future that the Fuse will execute.
 *
 *   If interval is a BigNumber than it specifies the number of hours into the
 *   future that the Fuse will execute. E.g. 1.0 specifies 1 hour, while 2.5
 *   specifies 2 hours 30 minutes.
 *
 *   If interval is a single-quoted String, then it specifies the time at which
 *   the Fuse will execute. The format may be any of the formats recognized by
 *   Date.parseDate (for which see the System Manual). For example '15:34' would
 *   specify that the Fuse is to execute at 15:34 on the current day, while
 *   '2014:06:22 15:34:00' would specify that the Fuse is to execute at 15:34 on
 *   22nd June 2014 (game time, not real time).
 */

class TimeFuse: Fuse
    construct(obj, prop, interval)
    {
        inherited Event(obj, prop);
        
        switch(dataType(interval))
        {
        case TypeInt:
            interval = [0, 0, 0, 0, interval];
            /* Fall through deliberately */
        case TypeList:
            eventTime = timeManager.currentTime.addInterval(interval);
            break;
        case TypeSString:
            eventTime = Date.parseDate(interval, nil,
                                       timeManager.currentTime)[1];
            break;
        case TypeObject:
            if(interval.ofKind(BigNumber))
            {
                eventTime = timeManager.currentTime.addInterval(
                    [0, 0, 0, interval]);
                break;                    
            }
            if(interval.ofKind(Date))
            {
                eventTime = interval;
                break;
            }
                       
            
            /* Fall through deliberately if we're some other kind of object */
        default:
            DMsg(time fuse interval error, 'Bad interval <<interval>> supplied
                to TimeFuse constructor. ');
            break;              
            
        }        
    }
    
    /* The time (as a Date object) at which this Fuse is set to activate */
    eventTime = nil
    
    /* 
     *   If our eventTime is still in the future, return a turn count well into
     *   the future so we don't execute yet; otherwise return the current turn
     *   count so we do execute on this turn.
     */
    getNextRunTime()
    {
        if(eventTime > timeManager.currentTime)
            return gTurns + 100;
        else
            return gTurns;
    }
    
;

class SenseTimeFuse: TimeFuse
   
    /* 
     *   senseObj is the object which must be sensed for this Fuse's text to be
     *   displayed. senseProp is one of &canSee, &canReach, &canHear, &canSmell.
     *   If these parameters are omitted then the senseObj will be the same as
     *   the obj whose prop property is executed by the Fuse, and the senseProp
     *   will be &canSee, probably the most common case.
     */
    construct(obj, prop, interval,  senseProp = &canSee, senseObj = obj)
    {
        inherited(obj, prop, interval);
        
         senseObj_ = senseObj;
         senseProp_ = senseProp;                   
    }
    
;

modify TravelConnector
    /* 
     *   The number of seconds it takes to traverse this connector (in addition
     *   to any that come from the Travel action).
     */
    traversalTime = 0
    
    /*  
     *   If we want to vary the time to go through this TravelConnector
     *   depending on where the traveler is starting from (only really relevant
     *   for rooms), we can override this method instead.
     */
    traversalTimeFrom(origin)
    {
        return traversalTime;
    }
    
    travelVia(actor, suppressBeforeNotifications?)
    {
        /* Note the actor's starting location */
        local origin = actor.getOutermostRoom();
        
        /* Carry out the inherited handling */
        inherited(actor, suppressBeforeNotifications);
        
        /* 
         *   Add our traversal time to the time it takes to carry out this
         *   travel, but not if we're in a chain of travel connectors, since we
         *   don't want to count the travel time twice.
         */
        if(!suppressBeforeNotifications)
            addTime(traversalTimeFrom(origin));
    }
    
;
    


/* Add a certain number of seconds to the current action time. */
addTime(secs)
{
    timeManager.additionalTime += secs;
}
    
/* 
 *   Make the current action take secs time in total; this overrides any
 *   previously calcuated time for this action.
 */     
takeTime(secs)
{
    timeManager.replacementTime = secs;
}