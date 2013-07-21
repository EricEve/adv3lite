#charset "us-ascii"
#include "advlite.h"


/*
 *   *************************************************************************
 *   events.t This module forms an optional part of the adv3Lite library. Note,
 *   however, that it must be present for certain other modules such as actor.t
 *   and scene.t to function properly, so it must be included if any of them
 *   are.
 *
 *   (c) 2012-13 Eric Eve (but based largely on code borrowed from the adv3
 *   library (c) Michael J. Roberts).
 */

/* 
 *   The eventManager is the object that manages the execution of Events such as
 *   Fuses and Daemons.
 */
eventManager: object
    
    /* Add an event to the list of events to be executed. */
    addEvent(event)
    {
        eventList.append(event);
    }
    
    /* Remove an event from the list of events to be executed. */
    removeEvent(event)
    {
        eventList.removeElement(event); 
    }
    
     /* 
     *   Remove events matching the given object and property combination.
     *   We remove all events that match both the object and property
     *   (events matching only the object or only the property are not
     *   affected).
     *   
     *   This is provided mostly as a convenience for cases where an event
     *   is known to be uniquely identifiable by its object and property
     *   values; this saves the caller the trouble of keeping track of the
     *   Event object created when the event was first registered.
     *   
     *   When a particular object/property combination might be used in
     *   several different events, it's better to keep a reference to the
     *   Event object representing each event, and use removeEvent() to
     *   remove the specific Event object of interest.
     *   
     *   Returns true if we find any matching events, nil if not.  
     */
    removeMatchingEvents(obj, prop)
    {
        local found;
        
        /* 
         *   Scan our list, and remove each event matching the parameters.
         *   Note that it's safe to remove things from a vector that we're
         *   iterating with foreach(), since foreach() makes a safe copy
         *   of the vector for the iteration. 
         */
        found = nil;
        foreach (local cur in eventList)
        {
            /* if this one matches, remove it */
            if (cur.eventMatches(obj, prop))
            {
                /* remove the event */
                removeEvent(cur);

                /* note that we found a match */
                found = true;
            }
        }

        /* return our 'found' indication */
        return found;
    }

    /* 
     *   Remove the current event - this is provided for convenience so
     *   that an event can cancel itself in the course of its execution.
     *   
     *   Note that this has no effect on the current event execution -
     *   this simply prevents the event from receiving additional
     *   notifications in the future.  
     */
    removeCurrentEvent()
    {
        /* remove the currently active event from our list */
        removeEvent(curEvent_);
    }
  
     /*
     *   Execute a turn.  We'll execute each fuse and each daemon that is
     *   currently schedulable.  
     */
    executeTurn()
    {
        local lst;
        
        /* 
         *   first execute all the 'Schedulables' that need to run each turn. In
         *   practice this will be all the actor takeTurn routines that will be
         *   registered by the actor module if present.
         */
        executeList(schedulableList);
        
        
        /* 
         *   build a list of all of our events with the current game clock time
         *   - these are the events that are currently schedulable. Also include
         *   any events that have never been executed but whose next run time is
         *   greater than the current turn count (otherwise these events will
         *   never be executed).
         */
        lst = eventList.subset({x: x.getNextRunTime() == libGlobal.totalTurns
                               || (x.executed == nil 
                                   && x.getNextRunTime() > libGlobal.totalTurns)
                                   });

        /* execute the items in this list */
        executeList(lst);

        /* no change in scheduling priorities */
        return true;
    }

    /*
     *   Execute a command prompt turn.  We'll execute each
     *   per-command-prompt daemon. 
     */
    executePrompt()
    {
        /* execute all of the per-command-prompt daemons */
        executeList(eventList.subset({x: x.isPromptDaemon}));
    }

    /*
     *   internal service routine - execute the fuses and daemons in the
     *   given list, in eventOrder priority order 
     */
    executeList(lst)
    {
        /* sort the list in ascending event order */
        lst = lst.toList()
              .sort(SortAsc, {a, b: a.eventOrder - b.eventOrder});

        /* run through the list and execute each item ready to run */
        foreach (local cur in lst)
        {
            /* remember our old active event, then establish the new one */
            local oldEvent = curEvent_;
            curEvent_ = cur;

            /* make sure we restore things on the way out */
            try
            {
                /* execute the event */
                cur.executeEvent();
                
                /* note that the event has been executed */
                cur.executed = true;

            }
            catch (Exception exc)
            {
                /* 
                 *   If an event throws an exception out of its handler,
                 *   remove the event from the active list.  If we were to
                 *   leave it active, we'd go back and execute the same
                 *   event again the next time we look for something to
                 *   schedule, and that would in turn probably just
                 *   encounter the same exception - so we'd be stuck in an
                 *   infinite loop executing this erroneous code.  To
                 *   ensure that we don't get stuck, remove the event. 
                 */
                removeCurrentEvent();

                /* re-throw the exception */
                throw exc;
            }
            finally
            {
                /* restore the enclosing current event */
                curEvent_ = oldEvent;
            }
        }
    }

    
    curEvent_ = nil
    
    eventList = static new Vector(20)
    
    /* 
     *   A list of 'schedulables'. These are objects whose executeEvent() method
     *   should be called each turn prior to other events such as Fuses and
     *   Daemons. The main use for this in the library is to provide a mechanism
     *   for the takeTurn method of each Actor to be called before Fuses and
     *   Daemons are run, mainly in case an AgendaItem sets up a Fuse or Daemon
     *   that may need to execute on the same turn, or if a Scene wants to do
     *   so.
     */
    schedulableList = []
;

/* 
 *   An Event is an object such as a Fuse or Daemon that is executed according
 *   to certain conditions. Game code will normally use one of its subclasses
 *   rather than the Event class directly.
 */
class Event: object
   
    /* Construct a new Event */
    construct(obj, prop)
    {
        /* 
         *   Note the object we refer to and the property of that object to
         *   execute.
         */
        obj_ = obj;
        prop_ = prop;
        
        /* Add this Event to the eventManager's list of events/ */
        eventManager.addEvent(self);
    }
    
    /* The object we're associated with */    
    obj_ = nil
    
    /* A pointer to the property of that object to execute */
    prop_ = nil
    
    /* The interval at which this Event is to be executed. */
    interval_ = nil
    
    /* 
     *   Get the next run time, i.e. the next turn on which this Event should
     *   execute obj_.(prop_).
     */
    getNextRunTime()
    {
        return nextRunTime;
    }
    
    /* delay our scheduled run time by the given number of turns */
    delayEvent(turns) { nextRunTime += turns; }
    
     /* 
     *   Execute the event.  This must be overridden by the subclass to
     *   perform the appropriate operation when executed.  In particular,
     *   the subclass must reschedule or unschedule the event, as
     *   appropriate. 
     */
    executeEvent() { }

    /* does this event match the given object/property combination? */
    eventMatches(obj, prop) { return obj == obj_ && prop == prop_; }
    
    /* 
     *   Event order - this establishes the order we run relative to other
     *   events scheduled to run at the same game clock time.  Lowest
     *   number goes first.  By default, we provide an event order of 100,
     *   which should leave plenty of room for custom events before and
     *   after default events.  
     */
    eventOrder = 100
    
    /* 
     *   our next execution time, expressed in game clock time; by
     *   default, we'll set this to nil, which means that we are not
     *   scheduled to execute at all 
     */
    nextRunTime = nil

    /* by default, we're not a per-command-prompt daemon */
    isPromptDaemon = nil   
    
    /* Call the method this Event should execute when it's ready to do so */
    callMethod()
    {
        /* 
         *   If we don't define a senseObj_ or the player character can sense
         *   our senseObj_ via the appropriate sense, simply execute the prop_
         *   method on our obj_. This check allows game code to ensure that the
         *   player doesn't see messages relating to events the player character
         *   cannot perceive.
         */
        if(senseObj_ == nil || Q.(senseProp_)(gPlayerChar, senseObj_))
            obj_.(prop_);
        
        /* Otherwise capture the output from executing obj_.(prop_) */
        else
        {
            captureText = gOutStream.captureOutput({: obj_.(prop_) });
            
            /* 
             *   It's possible that executing the Event changes the sensory
             *   context, so we need to check whether the object in question can
             *   now be sensed, and if so, display the text we've just captured.
             */            
            if(Q.(senseProp_)(gPlayerChar, senseObj_))
                say(captureText);
        }
    }
    
    /* Remove this event from the eventManager's list of events. */
    removeEvent()
    {
        eventManager.removeEvent(self);
    }
    
    /* 
     *   If the senseObj_ property is defined (normally via our constructor),
     *   the player character must be able to sense the senseObj_ via the sense
     *   defined in senseProp_ for any textual output from obj_.(prop_) to be
     *   displayed when this Event is executed.
     */
    senseObj_ = nil
    
    /*   
     *   The sense via which we test whether senseObj_ can be sensed by the
     *   player character. This must be given as an appropriate property of the
     *   Query object, e.g. &canSee or &canHear.
     */
    senseProp_ = nil
    
    /*   Text captured from callMethod() */
    captureText = nil
    
    /*   Flag - has this event ever been executed */
    executed = nil
;

/*
 *   Fuse.  A fuse is an event that fires once at a given time in the
 *   future.  Once a fuse is executed, it is removed from further
 *   scheduling.  
 */
class Fuse: Event
    /* 
     *   Creation.  'turns' is the number of turns in the future at which
     *   the fuse is executed; if turns is 0, the fuse will be executed on
     *   the current turn.  
     */
    construct(obj, prop, interval)
    {
        /* inherit the base class constructor */
        inherited(obj, prop);

        /* 
         *   set my scheduled time to the current game clock time plus the
         *   number of turns into the future 
         */
        nextRunTime = libGlobal.totalTurns + interval;
    }

    /* execute the fuse */
    executeEvent()
    {
        /* call my method */
        callMethod();

        /* a fuse fires only once, so remove myself from further scheduling */
        eventManager.removeEvent(self);
    }
;

/* 
 *   A SenseFuse is just like a Fuse except that any text produced during its
 *   execution is only displayed if the player char is able to sense the
 *   relevant object either at the start or at the end of the Fuse's execution.
 */
class SenseFuse: Fuse
    
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

/*  A Daemon is an Event that executes once every defined number of turns. */
class Daemon: Event
     /*
     *   Creation.  'interval' is the number of turns between invocations
     *   of the daemon; this should be at least 1, which causes the daemon
     *   to be invoked on each turn.  The first execution will be
     *   (interval-1) turns in the future - so if interval is 1, the
     *   daemon will first be executed on the current turn, and if
     *   interval is 2, the daemon will be executed on the next turn.  
     */
    construct(obj, prop, interval)
    {
        /* inherit the base class constructor */
        inherited(obj, prop);

        /* 
         *   an interval of less than 1 is meaningless, so make sure it's
         *   at least 1 
         */
        if (interval < 1)
            interval = 1;

        /* remember my interval */
        interval_ = interval;

        /* 
         *   set my initial execution time, in game clock time 
         */
        nextRunTime = libGlobal.totalTurns + interval - 1;
    }
    
    /* execute the daemon */
    executeEvent()
    {
        /* call my method */
        callMethod();

        /* advance our next run time by our interval */
        nextRunTime += interval_;
    }

    /* our execution interval, in turns */
    interval_ = 1
    
    
;


/* 
 *   A SenseDaemon is just like a Daemon except that any text produced during
 *   its execution is only displayed if the player char is able to sense the
 *   relevant object either at the start or at the end of the Daemon's
 *   execution.
 */
class SenseDaemon: Daemon
    
    /* 
     *   Creation: in addition to the parameters passed to Daemon's constructor,
     *   senseObj is the object which must be sensed for this Daemon's text to
     *   be displayed. senseProp is one of &canSee, &canReach, &canHear,
     *   &canSmell. If these parameters are omitted then the senseObj will be
     *   the same as the obj whose prop property is executed by the Daemon, and
     *   the senseProp will be &canSee, probably the most common case.
     */
    construct(obj, prop, interval, senseProp = &canSee, senseObj = obj)
    {
        inherited(obj, prop, interval);
        
         senseObj_ = senseObj;
         senseProp_ = senseProp;       
            
    }  
    
;

/*
 *   Command Prompt Daemon.  This is a special type of daemon that
 *   executes not according to the game clock, but rather once per command
 *   prompt.  The system executes all of these daemons just before each
 *   time it prompts for a command line.  
 */
class PromptDaemon: Event
    /* execute the daemon */
    executeEvent()
    {
        /* 
         *   call my method - there's nothing else to do for this type of
         *   daemon, since our scheduling is not affected by the game
         *   clock 
         */
        callMethod();
    }

    /* flag: we are a special per-command-prompt daemon */
    isPromptDaemon = true
;

/*
 *   A one-time-only prompt daemon is a regular command prompt daemon,
 *   except that it fires only once.  After it fires once, the daemon
 *   automatically deactivates itself, so that it won't fire again.
 *   
 *   Prompt daemons are occasionally useful for non-recurring processing,
 *   when you want to defer some bit of code until a "safe" time between
 *   turns.  In these cases, the regular PromptDaemon is inconvenient to
 *   use because it automatically recurs.  This subclass is handy for these
 *   cases, since it lets you schedule some bit of processing for a single
 *   deferred execution.
 *   
 *   One special situation where one-time prompt daemons can be handy is in
 *   triggering conversational events - such as initiating a conversation -
 *   at the very beginning of the game.  Initiating a conversation can only
 *   be done from within an action context, but no action context is in
 *   effect during the game's initialization.  An easy way to deal with
 *   this is to create a one-time prompt daemon during initialization, and
 *   then trigger the event from the daemon's callback method.  The prompt
 *   daemon will set up a daemon action environment just before the first
 *   command prompt is displayed, at which point the callback will be able
 *   to trigger the event as though it were in ordinary action handler
 *   code.  
 */
class OneTimePromptDaemon: PromptDaemon
    executeEvent()
    {
        /* execute as normal */
        inherited();

        /* remove myself from the event list, so that I don't fire again */
        removeEvent();
    }
;
