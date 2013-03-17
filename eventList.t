#charset "us-ascii"
#include "advlite.h"

/*
 *   ************************************************************************
 *   eventList.t This module forms an optional part of the adv3Lite library.
 *   
 *
 *   (c) 2012-13 Eric Eve (but based largely on code borrowed from the adv3
 *   library Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved.
 *   Lightly adapted by Eric Eve for use in the advLite library
 *
 *   adv3Lite Library - EventLists
 *
 *   This module contains definitions of various types of EventLists. These are
 *   defined in a separate module so that games that don't require EventLists
 *   can exclude this module from the build. The Script class, from which all
 *   EventLists inherits is defined in misc.t to allow other modules to test for
 *   an object being ofKind(Script) even when this EventList module is not
 *   present.
 */


/*
 *   Random-Firing script add-in.  This is a mix-in class that you can add
 *   to the superclass list of any Script subclass to make the script
 *   execute only a given percentage of the time it's invoked.  Each time
 *   doScript() is invoked on the script, we'll look at the probability
 *   settings (see the properties below) to determine whether we really
 *   want to execute the script this time; if so, we'll proceed with the
 *   scripted event, otherwise we'll just return immediately, doing
 *   nothing.
 *   
 *   Note that this must be used in the superclass list *before* the Script
 *   subclass:
 *   
 *   myScript: RandomFiringScript, EventList
 *.    // ...my definitions...
 *.  ;
 *   
 *   This class is especially useful for random atmospheric events, because
 *   it allows you to make the timing of scripted events random.  Rather
 *   than making a scripted event happen on every single turn, you can use
 *   this to make events happen only sporadically.  It can often feel too
 *   predictable and repetitious when a random background event happens on
 *   every single turn; firing events less frequently often makes them feel
 *   more realistic.  
 */
class RandomFiringScript: object
    /* 
     *   Percentage of the time an event occurs.  By default, we execute an
     *   event 100% of the time - meaning every time that doScript() is
     *   invoked.  If you set this to a lower percentage, then each time
     *   doScript() is invoked, we'll randomly decide whether or not to
     *   execute an event based on this percentage.  For example, if you
     *   want an event to execute on average about a third of the time, set
     *   this to 33.
     *   
     *   Note that this is a probabilistic frequency.  Setting this to 33
     *   does *not* mean that we'll execute exactly every third time.
     *   Rather, it means that we'll randomly execute or not on each
     *   invocation, and averaged over a large number of invocations, we'll
     *   execute about a third of the time.  
     */
    eventPercent = 100

    /* 
     *   Random atmospheric events can get repetitive after a while, so we
     *   provide an easy way to reduce the frequency of our events after a
     *   while.  This way, we'll generate the events more frequently at
     *   first, but once the player has seen them enough to get the idea,
     *   we'll cut back.  Sometimes, the player will spend a lot of time in
     *   one place trying to solve a puzzle, so the same set of random
     *   events can get stale.  Set eventReduceAfter to the number of times
     *   you want the events to be generated at full frequency; after we've
     *   fired events that many times, we'll change eventPercent to
     *   eventReduceTo.  If eventReduceAfter is nil, we won't ever change
     *   eventPercent.  
     */
    eventReduceAfter = nil
    eventReduceTo = nil

    /*
     *   When doScript() is invoked, check the event probabilities before
     *   proceeding.  
     */
    doScript()
    {
        /* process the script step only if the event odds allow it */
        if (checkEventOdds())
            inherited();
    }

    /*
     *   Check the event odds to see if we want to fire an event at all on
     *   this invocation.  
     */
    checkEventOdds()
    {
        /* 
         *   check the event odds to see if we fire an event this time; if
         *   not, we're done with the script invocation 
         */
        if (rand(100) >= eventPercent)
            return nil;

        /* 
         *   we're firing an event this time, so count this against the
         *   reduction limit, if there is one 
         */
        if (eventReduceAfter != nil)
        {
            /* decrement the limit counter */
            --eventReduceAfter;
            
            /* if it has reached zero, apply the reduced frequency */
            if (eventReduceAfter == 0)
            {
                /* apply the reduced frequency */
                eventPercent = eventReduceTo;
                
                /* we no longer have a limit to look for */
                eventReduceAfter = nil;
            }
        }

        /* indicate that we do want to fire an event */
        return true;
    }
;

/* ------------------------------------------------------------------------ */
/*
 *   An "event list."  This is a general-purpose type of script that lets
 *   you define the scripted events separately from the Script object.
 *   
 *   The script is driven by a list of values; each value represents one
 *   step of the script.  Each value can be a single-quoted string, in
 *   which case the string is simply displayed; a function pointer, in
 *   which case the function is invoked without arguments; another Script
 *   object, in which case the object's doScript() method is invoked; a
 *   property pointer, in which case the property of 'self' (the EventList
 *   object) is invoked with no arguments; or nil, in which case nothing
 *   happens.
 *   
 *   This base type of event list runs through the list once, in order, and
 *   then simply stops doing anything once we pass the last event.  
 */
class EventList: Script
    construct(lst) { eventList = lst; }

    /* the list of events */
    eventList = []

    /* cached length of the event list */
    eventListLen = (eventList.length())

    /* advance to the next state */
    advanceState()
    {
        /* increment our state index */
        ++curScriptState;
    }

    /* by default, start at the first list element */
    curScriptState = 1

    /* process the next step of the script */
    doScript()
    {
        /* get our current event state */
        local idx = getScriptState();

        /* get the list (evaluate it once to avoid repeated side effects) */
        local lst = eventList;

        /* cache the length */
        eventListLen = lst.length();

        /* if it's a valid index in our list, fire the event */
        if (idx >= 1 && idx <= eventListLen)
        {
            /* carry out the event */
            doScriptEvent(lst[idx]);
        }

        /* perform any end-of-script processing */
        scriptDone();
    }

    /* carry out one script event */
    doScriptEvent(evt)
    {
        /* check what kind of event we have */
        switch (dataTypeXlat(evt))
        {
        case TypeSString:
            /* it's a string - display it */
            say(evt);
            break;
            
        case TypeObject:
            /* it must be a Script object - invoke its doScript() method */
            evt.doScript();
            break;
            
        case TypeFuncPtr:
            /* it's a function pointer - invoke it */
            (evt)();
            break;
            
        case TypeProp:
            /* it's a property of self - invoke it */
            self.(evt)();
            break;
            
        default:
            /* do nothing in other cases */
            break;
        }
    }

    /*
     *   Perform any end-of-script processing.  By default, we advance the
     *   script to the next state.
     *   
     *   Some scripts might want to override this.  For example, a script
     *   could be driven entirely by some external timing; the state of a
     *   script could vary once per turn, for example, or could change each
     *   time an actor pushes a button.  In these cases, invoking the
     *   script wouldn't affect the state of the event list, so the
     *   subclass would override scriptDone() so that it does nothing at
     *   all.  
     */
    scriptDone()
    {
        /* advance to the next state */
        advanceState();
    }
;

/*
 *   An "external" event list is one whose state is driven externally to
 *   the script.  Specifically, the state is *not* advanced by invoking the
 *   script; the state is advanced exclusively by some external process
 *   (for example, by a daemon that invokes the event list's advanceState()
 *   method).  
 */
class ExternalEventList: EventList
    scriptDone() { }
;

/*
 *   A cyclical event list - this runs through the event list in order,
 *   returning to the first element when we pass the last element.  
 */
class CyclicEventList: EventList
    advanceState()
    {
        /* go to the next state */
        ++curScriptState;

        /* if we've passed the end of the list, loop back to the start */
        if (curScriptState > eventListLen)
            curScriptState = 1;
    }
;

/*
 *   A stopping event list - this runs through the event list in order,
 *   then stops at the last item and repeats it each time the script is
 *   subsequently invoked. 
 *   
 *   This is often useful for things like ASK ABOUT topics, where we reveal
 *   more information when asked repeatedly about a topic, but eventually
 *   reach a point where we've said everything:
 *   
 *.  >ask bob about black book
 *.  "What makes you think I know anything about it?" he says, his
 *   voice shaking.
 *   
 *   >again
 *.  "No! You can't make me tell you!"
 *   
 *   >again
 *.  "All right, I'll tell you what you want to know!  But I warn you,
 *   these are things mortal men were never meant to know.  Your life, your
 *   very soul will be in danger from the moment you hear these dark secrets!"
 *   
 *   >again
 *.  [scene missing]
 *   
 *   >again
 *.  "I've already told you all I know."
 *   
 *   >again
 *.  "I've already told you all I know."
 */
class StopEventList: EventList
    advanceState()
    {
        /* if we haven't yet reached the last state, go to the next one */
        if (curScriptState < eventListLen)
            ++curScriptState;
    }
;

/*
 *   A synchronized event list.  This is an event list that takes its
 *   actions from a separate event list object.  We get our current state
 *   from the other list, and advancing our state advances the other list's
 *   state in lock step.  Set 'masterObject' to refer to the master list
 *   whose state we synchronize with.  
 *   
 *   This can be useful, for example, when we have messages that reflect
 *   two different points of view on the same events: the messages for each
 *   point of view can be kept in a separate list, but the one list can be
 *   a slave of the other to ensure that the two lists are based on a
 *   common state.  
 */
class SyncEventList: EventList
    /* my master event list object */
    masterObject = nil

    /* my state is simply the master list's state */
    getScriptState() { return masterObject.getScriptState(); }

    /* to advance my state, advance the master list's state */
    advanceState() { masterObject.advanceState(); }

    /* let the master list take care of finishing a script step */
    scriptDone() { masterObject.scriptDone(); }
;

/*
 *   Randomized event list.  This is similar to a regular event list, but
 *   chooses an event at random each time it's invoked.
 */
class RandomEventList: RandomFiringScript, EventList
    /* process the next step of the script */
    doScript()
    {
        /* check the odds to see if we want to fire an event at all */
        if (!checkEventOdds())
            return;
        
        /* get our next random number */
        local idx = getNextRandom();

        /* cache the list and its length, to avoid repeated side effects */
        local lst = eventList;
        eventListLen = lst.length();
        
        /* run the event, if the index is valid */
        if (idx >= 1 && idx <= eventListLen)
            doScriptEvent(lst[idx]);
    }
    
    /*
     *   Get the next random state.  By default, we simply return a number
     *   from 1 to the number of entries in our event list.  This is a
     *   separate method to allow subclasses to customize the way the
     *   random number is selected.  
     */
    getNextRandom()
    {
        /*   
         *   Note that rand(n) returns a number from 0 to n-1 inclusive;
         *   since list indices run from 1 to list.length, add one to the
         *   result of rand(list.length) to get a value in the proper range
         *   for a list index.  
         */
        return rand(eventListLen) + 1;
    }
;

/*
 *   Shuffled event list.  This is similar to a random event list, except
 *   that we fire our events in a "shuffled" order rather than an
 *   independently random order.  "Shuffled order" means that we fire the
 *   events in random order, but we don't re-fire an event until we've run
 *   through all of the other events.  The effect is as though we were
 *   dealing from a deck of cards.
 *   
 *   For the first time through the main list, we normally shuffle the
 *   strings immediately at startup, but this is optional.  If shuffleFirst
 *   is set to nil, we will NOT shuffle the list the first time through -
 *   we'll run through it once in the given order, then shuffle for the
 *   next time through, then shuffle again for the next, and so on.  So, if
 *   you want a specific order for the first time through, just define the
 *   list in the desired order and set shuffleFirst to nil.
 *   
 *   You can optionally specify a separate list of one-time-only sequential
 *   strings in the property firstEvents.  We'll run through these strings
 *   once.  When we've exhausted them, we'll switch to the main eventList
 *   list, showing it one time through in its given order, then shuffling
 *   it and running through it again, and so on.  The firstEvents list is
 *   never shuffled - it's always shown in exactly the order given.  
 */
class ShuffledEventList: RandomFiringScript, EventList
    /* 
     *   a list of events to go through sequentially, in the exact order
     *   specified, before firing any events from the main list
     */
    firstEvents = []

    /*
     *   Flag: shuffle the eventList list before we show it for the first
     *   time.  By default, this is set to true, so that the behavior is
     *   random on each independent run of the game.  However, it might be
     *   desirable in some cases to always use the original ordering of the
     *   eventList list the first time through the list.  If this is set to
     *   nil, we won't shuffle the list the first time through.  
     */
    shuffleFirst = true

    /*
     *   Flag: suppress repeats in the shuffle.  If this is true, it
     *   prevents a given event from showing up twice in a row, which could
     *   otherwise happen right after a shuffle.  This is ignored for lists
     *   with one or two events: it's impossible to prevent repeats in a
     *   one-element list, and doing so in a two-element list would produce
     *   a predictable A-B-A-B... pattern.
     *   
     *   You might want to set this to nil for lists of three or four
     *   elements, since such short lists can result in fairly
     *   un-random-looking sequences when repeats are suppressed, because
     *   the available number of permutations drops significantly.  
     */
    suppressRepeats = true

    /* process the next step of the script */
    doScript()
    {
        /* cache the lists to avoid repeated side effects */
        local firstLst = firstEvents;
        local firstLen = firstLst.length();
        local lst = eventList;
        eventListLen = lst.length();

        /* process the script step only if the event odds allow it */
        if (!checkEventOdds())
            return;

        /* 
         *   States 1..N, where N is the number of elements in the
         *   firstEvents list, simply show the firstEvents elements in
         *   order.
         *   
         *   If we're set to shuffle the main eventList list initially, all
         *   states above N simply show elements from the eventList list in
         *   shuffled order.
         *   
         *   If we're NOT set to shuffle the main eventList list initially,
         *   the following apply:
         *   
         *   States N+1..N+M, where M is the number of elements in the
         *   eventList list, show the eventList elements in order.
         *   
         *   States above N+M show elements from the eventList list in
         *   shuffled order.  
         */
        local evt;
        if (curScriptState <= firstLen)
        {
            /* simply fetch the next string from firstEvents */
            evt = firstEvents[curScriptState++];
        }
        else if (!shuffleFirst && curScriptState <= firstLen + eventListLen)
        {
            /* fetch the next string from eventList */
            evt = lst[curScriptState++ - firstLen];
        }
        else
        {
            /* we're showing shuffled strings from the eventList list */
            evt = lst[getNextRandom()];
        }

        /* execute the event */
        doScriptEvent(evt);
    }


    /*
     *   Get the next random event.  We'll pick an event from our list of
     *   events using a ShuffledIntegerList to ensure we pick each value
     *   once before re-using any values.  
     */
    getNextRandom()
    {
        /* if we haven't created our shuffled list yet, do so now */
        if (shuffledList_ == nil)
        {
            /* 
             *   create a shuffled integer list - we'll use these shuffled
             *   integers as indices into our event list 
             */
            shuffledList_ = new ShuffledIntegerList(1, eventListLen);

            /* apply our suppressRepeats option to the shuffled list */
            shuffledList_.suppressRepeats = suppressRepeats;
        }

        /* ask the shuffled list to pick an element */
        return shuffledList_.getNextValue();
    }

    /* our ShuffledList - we'll initialize this on demand */
    shuffledList_ = nil
;

/* ------------------------------------------------------------------------ */
/*
 *   Shuffled List - this class keeps a list of values that can be returned
 *   in random order, but with the constraint that we never repeat a value
 *   until we've handed out every value.  Think of a shuffled deck of
 *   cards: the order of the cards handed out is random, but once a card is
 *   dealt, it can't be dealt again until we put everything back into the
 *   deck and reshuffle.  
 */
class ShuffledList: object
    /* 
     *   the list of values we want to shuffle - initialize this in each
     *   instance to the set of values we want to return in random order 
     */
    valueList = []

    /*
     *   Flag: suppress repeated values.  We mostly suppress repeats by our
     *   very design, since we run through the entire list before repeating
     *   anything in the list.  However, there's one situation (in a list
     *   with more than one element) where a repeat can occur: immediately
     *   after a shuffle, we could select the last element from the
     *   previous shuffle as the first element of the new shuffle.  If this
     *   flag is set, we'll suppress this type of repeat by choosing again
     *   any time we're about to choose a repeat.
     *   
     *   Note that we ignore this for a list of one element, since it's
     *   obviously impossible to avoid repeats in this case.  We also
     *   ignore it for a two-element list, since this would produce the
     *   predictable pattern A-B-A-B..., defeating the purpose of the
     *   shuffle.  
     */
    suppressRepeats = nil

    /* create from a given list */
    construct(lst)
    {
        /* remember our list of values */
        valueList = lst;
    }

    /* 
     *   Get a random value.  This will return a randomly-selected element
     *   from 'valueList', but we'll return every element of 'valueList'
     *   once before repeating any element.
     *   
     *   If we've returned every value on the current round, we'll
     *   automatically shuffle the values and start a new round.  
     */
    getNextValue()
    {
        local i;
        local ret;
        local justReshuffled = nil;

        /* if we haven't initialized our vector, do so now */
        if (valuesVec == nil)
        {
            /* create the vector */
            valuesVec = new Vector(valueList.length(), valueList);

            /* all values are initially available */
            valuesAvail = valuesVec.length();
        }

        /* if we've exhausted our values on this round, start over */
        if (valuesAvail == 0)
        {
            /* shuffle the elements */
            reshuffle();

            /* note that we just did a shuffle */
            justReshuffled = true;
        }

        /* pick a random element from the 'available' partition */
        i = rand(valuesAvail) + 1;

        /*
         *   If we just reshuffled, and we're configured to suppress a 
         *   repeat immediately after a reshuffle, and we chose the first 
         *   element of the vector, and we have at least three elements, 
         *   choose a different element.  The first element in the vector is 
         *   always the last element we return from each run-through, since 
         *   the 'available' partition is at the start of the list and thus 
         *   shrinks down until it contains only the first element. 
         *
         *   If we have one element, there's obviously no point in trying to 
         *   suppress repeats.  If we have two elements, we *still* don't 
         *   want to suppress repeats, because in this case we'd generate a 
         *   predicatable A-B-A-B pattern (because we could never have two 
         *   A's or two B's in a row).
         */
        if (justReshuffled && suppressRepeats && valuesAvail > 2)
        {
            /* 
             *   we don't want repeats, so choose anything besides the
             *   first element; keep choosing until we get another element 
             */
            while (i == 1)
                i = rand(valuesAvail) + 1;
        }

        /* remember the element we're returning */
        ret = valuesVec[i];

        /*
         *   Move the value at the top of the 'available' partition down
         *   into the hole we're creating at 'i', since we're about to
         *   reduce the size of the 'available' partition to reflect the
         *   use of one more value; that would leave the element at the top
         *   of the partition homeless, so we need somewhere to put it.
         *   Luckily, we also need to delete element 'i', since we're using
         *   this element.  Solve both problems at once by moving element
         *   we're rendering homeless into the hole we're creating.  
         */
        valuesVec[i] = valuesVec[valuesAvail];

        /* move the value we're returning into the top slot */
        valuesVec[valuesAvail] = ret;

        /* reduce the 'available' partition by one */
        --valuesAvail;

        /* return the result */
        return ret;
    }

    /*
     *   Shuffle the values.  This puts all of the values back into the
     *   deck (as it were) for a new round.  It's never required to call
     *   this, because getNextValue() automatically shuffles the deck and
     *   starts over each time it runs through the entire deck.  This is
     *   provided in case the caller has a reason to want to put all the
     *   values back into play immediately, before every value has been
     *   dealt on the current round.  
     */
    reshuffle()
    {
        /* 
         *   Simply reset the counter of available values.  Go with the
         *   original source list's length, in case we haven't initialized
         *   our internal vector yet. 
         */
        valuesAvail = valueList.length();
    }

    /*
     *   Internal vector of available/used values.  Elements from 1 to
     *   'valuesAvail', inclusive, are still available for use on this
     *   round.  Elements above 'valuesAvail' have already been used.  
     */
    valuesVec = nil
    
    /* number of values still available on this round */ 
    valuesAvail = 0
;

/*
 *   A Shuffled Integer List is a special kind of Shuffled List that
 *   returns integers in a given range.  Like an ordinary Shuffled List,
 *   we'll return integers in the given range in random order, but we'll
 *   only return each integer once during a given round; when we exhaust
 *   the supply, we'll reshuffle the set of integers and start over.  
 */
class ShuffledIntegerList: ShuffledList
    /* 
     *   The minimum and maximum values for our range.  Instances should
     *   define these to the range desired. 
     */
    rangeMin = 1
    rangeMax = 10

    /* initialize the value list on demand */
    valueList = nil

    /* construct with the given range */
    construct(rmin, rmax)
    {
        rangeMin = rmin;
        rangeMax = rmax;
    }

    /* get the next value */
    getNextValue()
    {
        /* 
         *   If we haven't set up our value list yet, do so now.  This is
         *   simply a list of integers from rangeMin to rangeMax.  
         */
        if (valueList == nil)
        {
            local ele = rangeMin;
            valueList = List.generate({i: ele++}, rangeMax - rangeMin + 1);
        }

        /* use the inherited handling to select from our value list */
        return inherited();
    }
;


