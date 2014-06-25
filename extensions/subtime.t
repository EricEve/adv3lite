#charset "us-ascii"
#include "advlite.h"
/*
 *   Copyright 2003, 2006 Michael J. Roberts
 *
 *   Lightly adapted for use with adv3Lite by Eric Eve
 *   
 *   "Subjective Time" module.  This implements a form of in-game
 *   time-keeping that attempts to mimic the player's subjective
 *   experience of time passing in the scenario while still allowing for
 *   occasional, reasonably precise time readings, such as from a
 *   wristwatch in the game world.
 *   
 *  
 */

property gameStartTime;

clockManager: PreinitObject
    /*
     *   Get the current game-clock time.  This returns a list in the same
     *   format as ClockEvent.eventTime: [day,hour,minute].
     *   
     *   Remember that our time-keeping scheme is a sort of "Schrodinger's
     *   clock" [see footnote 1].  Between time checks, the game time
     *   clock is in a vague, fuzzy state, drifting along at an
     *   indeterminate pace from the most recent check.  When this method
     *   is called, though, the clock manager is forced to commit to a
     *   particular time, because we have to give a specific answer to the
     *   question we're being asked ("what time is it?").  As in quantum
     *   mechanics, then, the act of observation affects the quantity
     *   being observed.  Therefore, you should avoid calling this routine
     *   unnecessarily; call it only when you actually have to tell the
     *   player what time it is - and don't tell the player what time it
     *   is unless they ask, or there's some other good reason.
     *   
     *   If you want a string-formatted version of the time (as in
     *   '9:05pm'), you can call checkTimeFmt().  
     */
    checkTime()
    {
        local turns;
        local mm;
        local sdmm;
        
        /* 
         *   Determine how many turns it's been since we last committed to
         *   a specific wall-clock time.  This will give us the
         *   psychological "scale" of the amount of elapsed wall-clock the
         *   user might expect.  
         */
        turns = libGlobal.totalTurns - turnLastCommitted;

        /* 
         *   start with the base scaling factor - this is the number of
         *   minutes of game time we impute to a hundred turns, in the
         *   absence of the constraint of running up against the next event
         */
        mm = (turns * baseScaleFactor) / 100;
        
        /* If the timeManager exists, see what it reckons the time should be */
        if(defined(timeManager))            
        {
            /* 
             *   If we don't have a nextEvent, let the timeManager decide the
             *   time.
             */
            if(nextEvent == nil)
            {
                /* Get the clock time from the timeManager. */
                return getClockTime(timeManager.currentTime);               
            }
            
            
            /* 
             *   The number of minutes elapsed according to the timeManager is
             *   the difference between the timeManager's currentTime and our
             *   last event date multiplied by the number of minutes in a day.
             */                 
            local tMmm = (timeManager.currentTime - lastEventDate()) * 1440;
           
            /* Convert this number to an integer. */
            tMmm = toInteger(tMmm);
            
            /* 
             *   Calculate the number of seconds the timeManager currently
             *   thinks the current action will take.
             */
            local secs = 0;
            
            if(gAction)
            {
                secs = replacementTime == nil ? 
                    gAction.timeTaken + timeManager.additionalTime : 
                timeManager.replacementTime;
            }
            
            /* 
             *   Add the current turn time to the timeManager's reckoning of
             *   time
             */
            tMmm += secs/60;
            
            /* 
             *   If the subjective time estimate is greater than the
             *   timeManager's reckoning, or if there's no nextTime, use the
             *   timeManager's reckoning of elapsed minutes.
             */
            if(mm > tMmm || nextTime == nil)
                mm = tMmm;
            
        }
        
        /*
         *   If the base scaled time would take us within sdmm of the next event
         *   time, slow the clock down from our base scaling factor so that we
         *   always leave ourselves room to advance the clock further on the
         *   next check.  Reduce the passage of time in proportion to our
         *   reduced window - so if we have only 60 minutes left, advance time
         *   at half the normal pace.
         */
        if (nextTime != nil)
        {
            /*   
             *   In Mike Roberts's version of subtime, the clock is slowed down
             *   if the base scaled time would take us within two hours of the
             *   next event time, but this may be inappropriate if the game is
             *   working to a much shorter or longer timescale. So we instead
             *   compute the time at which slowing down should occur in a
             *   separate method to make it easy for game code to override it.
             *   By default, the slow-down time will be half-way between the
             *   previous event and the next one.
             */
            sdmm = slowDownTime();
            
            /* get the minutes between now and the next scheduled event */
            local delta = diffMinutes(nextTime, curTime);

            /* check to see if the raw increment would leave under sdmm minutes */
            if (delta - mm < sdmm)
            {
                /*
                 *   The raw time increment would leave us under sdmm minutes
                 *   away.  If we have under sdmm to go before the
                 *   next event, scale down the rate of time in proportion
                 *   to our share under sdmm.  (Note that we might
                 *   have more than sdmm to go and still be here,
                 *   because the raw adjusted time leaves under sdmm minutes.)  
                 */
                if (delta < sdmm)
                    mm = (mm * delta) / sdmm;

                /* 
                 *   In any case, cap it at half the remaining time, to
                 *   ensure that we won't ever make it to the next event
                 *   time until the next event occurs.
                 */
                if (mm > delta / 2)
                    mm = delta / 2;
            }
        }

        /* 
         *   If our calculation has left us with no passage of time, simply
         *   return the current time unchanged, and do not treat this as a
         *   commit point.  We don't consider this a commit point because
         *   we treat it as not even checking again - it's effectively just
         *   a repeat of the last check, since it's still the same time.
         *   This ensures that we won't freeze the clock for good due to
         *   rounding - enough additional turns will eventually accumulate
         *   to nudge the clock forward.  
         */
        if (mm == 0)
            return curTime;

        /* add the minutes to the current time */
        curTime = addMinutes(curTime, mm);

        /* the current turn is now the last commit point */
        turnLastCommitted = gTurns;
                
         /*   If the timeManager exists, synchronize its time with ours. */
        syncTime(curTime);
        
        /* return the new time */
        return curTime;
    }

    /* 
     *   Compute the time remaining until the next event at which we start to
     *   slow down the clock. By default we make this half the time from the
     *   previous event to the next. Game code can override if some other value
     *   is preferred.
     */
    slowDownTime()
    {
        /*  
         *   If we have a lastEvent, get its eventTime; otherwise assume the
         *   last event was at midnight on day 1.
         */
        local lastEventTime = lastEvent == nil ? [1,0,0] : lastEvent.eventTime;
        
        /*   
         *   Return half the difference between the next event time and the last
         *   event time.
         */
        return diffMinutes(nextTime, lastEventTime)/2;
    }
    
    
    /*
     *   The base scaling factor: this is the number of minutes per hundred
     *   turns when we have unlimited time until the next event.  This number is
     *   pretty arbitrary, since we're depending so much on the player's
     *   uncertainty about just how long things take, and also because we'll
     *   adjust it anyway when we're running out of time before the next event.
     *   Even so, you might want to adjust this value up or down according to
     *   your sense of the pacing of your game.
     *
     *   In Mike Roberts's implementation, the baseScaleFactor was defined as a
     *   constant value of 60. This is still the default value, but if there is
     *   a next event we take the scale factor from that event's scaleFactor so
     *   that we can vary the pace of time according to the spacing of events if
     *   we wish.
     */
    baseScaleFactor = (nextEvent == nil ? 60 : nextEvent.scaleFactor)

    /*
     *   Get the current game-clock time, formatted into a string with the
     *   given format mask - see formatTime() for details on how to write a
     *   mask string.
     *   
     *   Note that the same cautions for checkTime() apply here - calling
     *   this routine commits us to a particular time, so you should call
     *   this routine only when you're actually ready to display a time to
     *   the player.  
     */
    checkTimeFmt(fmt) { return formatTime(checkTime(), fmt); }
    
    /* 
     *   Get a formatted version of the given wall-clock time.  The time is
     *   expressed as a list, in the same format as ClockEvent.eventTime:
     *   [day,hour,minute], where 'day' is 1 for the first day of the game,
     *   2 for the second, and so on.
     *   
     *   The format string consists of one or more prefixes, followed by a
     *   format mask.  The prefixes are flags that control the formatting,
     *   but don't directly insert any text into the result string:
     *   
     *   24 -> use 24-hour time; if this isn't specified, a 12-hour clock
     *   is used instead.  On the 24-hour clock, midnight is hour zero, so
     *   12:10 AM is represented as 00:10.
     *   
     *   [am][pm] -> use 'am' as the AM string, and 'pm' as the PM string,
     *   for the 'a' format mask character.  This lets you specify an
     *   arbitrary formatting for the am/pm marker, overriding the default
     *   of 'am' or 'pm'.  For example, if you want to use 'A.M.' and
     *   'P.M.'  as the markers, you'd write a prefix of [A.M.][P.M.].  If
     *   you want to use ']' within the marker string itself, quote it with
     *   a '%': '[[AM%]][PM%]]' indicates markers of '[AM]' and '[PM]'.
     *   
     *   Following the prefix flags, you specify the format mask.  This is
     *   a set of special characters that specify parts of the time to
     *   insert.  Each special character is replaced with the corresponding
     *   formatted time information in the result string.  Any character
     *   that isn't special is just copied to the result string as is.  The
     *   special character are:
     *   
     *   h -> hour, no leading zero for single digits (hence 9:05, for
     *   example)
     *   
     *   hh -> hour, leading zero (09:05)
     *   
     *   m -> minutes, no leading zero (9:5)
     *   
     *   mm -> minutes with a leading zero (9:05)
     *   
     *   a -> AM/PM marker.  If an [am][pm] prefix was specified, the 'am'
     *   or 'pm' string from the prefix is used.  Otherwise, 'am' or 'pm'
     *   is literally inserted.
     *   
     *   % -> quote next character (so %% -> a single %)
     *   
     *   other -> literal
     *   
     *   Examples:
     *   
     *   'hh:mma' produces '09:05am'
     *.  '[A.M][P.M]h:mma' produces '9:05 P.M.'
     *.  '24hhmm' produces '2105'.  
     */
    formatTime(t, fmt)
    {
        local hh = t[2];
        local mm = t[3];
        local pm = (hh >= 12);
        local use24 = nil;
        local amStr = nil;
        local pmStr = nil;
        local ret;
        local match;
            
        /* check flags */
        for (;;)
        {
            local fl;
            
            /* check for a flag string */
            match = rexMatch(
                '24|<lsquare>(<^rsquare>|%%<rsquare>)+<rsquare>', fmt, 1);

            /* if we didn't find another flag, we're done */
            if (match == nil)
                break;

            /* pull out the flag text */
            fl = fmt.substr(1, match);
            fmt = fmt.substr(match + 1);

            /* check the match */
            if (fl == '24')
            {
                /* note 24-hour time */
                use24 = true;
            }
            else
            {
                /* it's an am/pm marker - strip the brackets */
                fl = fl.substr(2, fl.length() - 2);

                /* change any '%]' sequences into just ']' */
                fl = fl.findReplace('%]', ']', ReplaceAll, 1);

                /* set AM if we haven't set it already, else set PM */
                if (amStr == nil)
                    amStr = fl;
                else
                    pmStr = fl;
            }
        }

        /* if we didn't select an AM/PM, use the default */
        amStr = (amStr == nil ? 'am' : amStr);
        pmStr = (pmStr == nil ? 'pm' : pmStr);

        /* adjust for a 12-hour clock if we're using one */
        if (!use24)
        {
            /* subtract 12 from PM times */
            if (pm)
                hh -= 12;

            /* hour 0 on a 12-hour clock is written as 12 */
            if (hh == 0)
                hh = 12;
        }

        /* run through the format and build the result string */
        for (ret = '', local i = 1, local len = fmt.length() ; i <= len ; ++i)
        {
            /* check what we have */
            match = rexMatch(
                '<case>h|hh|m|mm|a|A|am|AM|a%.m%.|A.%M%.|24|%%', fmt, i);
            if (match == nil)
            {
                /* no match - copy this character literally */
                ret += fmt.substr(i, 1);
            }
            else
            {
                /* we have a match - check what we have */
                switch (fmt.substr(i, match))
                {
                case 'h':
                    /* add the hour, with no leading zero */
                    ret += toString(hh);
                    break;

                case 'hh':
                    /* add the hour, with a leading zero if needed */
                    if (hh < 10)
                        ret += '0';
                    ret += toString(hh);
                    break;

                case 'm':
                    /* add the minute, with no leading zero */
                    ret += toString(mm);
                    break;
                    
                case 'mm':
                    /* add the minute, with a leading zero if needed */
                    if (mm < 10)
                        ret += '0';
                    ret += toString(mm);
                    break;
                    
                case 'a':
                    /* add the am/pm indicator */
                    ret += (pm ? pmStr : amStr);
                    break;
                    
                case '%':
                    /* add the next character literally */
                    ++i;
                    ret += fmt.substr(i, 1);
                    break;
                }

                /* skip any extra characters in the field */
                i += match - 1;
            }
        }

        /* return the result string */
        return ret;
    }

    /* pre-initialize */
    execute()
    {
        local vec;
        
        /* build a list of all of the ClockEvent objects in the game */
        vec = new Vector(10);
        forEachInstance(ClockEvent, {x: vec.append(x)});

        /* sort the list by time */
        vec.sort(SortAsc, {a, b: a.compareTime(b)});

        /* store it */
        eventList = vec.toList();

        /* 
         *   The earliest event is always the marker for the beginning of
         *   the game.  Since it's now the start of the game, mark the
         *   first event in our list as reached.  (The first event is
         *   always the earliest we find, by virtue of the sort we just
         *   did.)  
         */
        vec[1].eventReached();
        
        /*  
         *   If the events module is present, set up a PromptDaemon to check
         *   each turn whether a new ClockEvent has been reached.
         */
        if(defined(eventManager))
            new PromptDaemon(self, &reachCheck);
        
        /*  
         *   If the gameMain object defines a gameStartTime, use it to set our
         *   baseDate.
         */
        if(gameMain.propDefined(&gameStartTime))
        {
            local gst = gameMain.gameStartTime;
            
            if(dataType(gst) == TypeList)
                baseDate = new Date(gst[1], gst[2], gst[3]);
            
            if(dataType(gst) == TypeObject && gst.ofKind(Date))
                baseDate = gst;
        }
        
        /* 
         *   If the timeManager exists, synchronize its current start time with
         *   ours, if we have one.
         */
        if(defined(timeManager) && lastEvent)
            timeManager.currentTime = lastEventDate();
    }

    /* 
     *   Receive notification from a clock event that an event has just
     *   occurred.  (This isn't normally called directly from game code;
     *   instead, game code should usually call the ClockEvent object's
     *   eventReached() method.)  
     */
    eventReached(evt)
    {
        local idx;
        
        /* find the event in our list */
        idx = eventList.indexOf(evt);

        /* 
         *   Never go backwards - if events fire out of order, keep only
         *   the later event.  (Games should generally be constructed in
         *   such a way that events can only fire in order to start with,
         *   but in case a weird case slips through, we make this extra
         *   test to ensure that the player doesn't see any strange
         *   retrograde motion on the clock.) 
         */
        if (lastEvent != nil && lastEvent.compareTime(evt) > 0)
            return;
        
        /* note the current time */
        curTime = evt.eventTime;
        
        /* note the event that's just been reached */
        lastEvent = evt;

        /* 
         *   if there's another event following, note the next time and the next
         *   event, and get the next event to calculate its scale factor.
         */
        if (idx < eventList.length())
        {
            nextEvent = eventList[idx + 1];
            nextTime = nextEvent.eventTime;
            nextEvent.calcScaleFactor();
        }
        else
        {
            nextEvent = nil;
            nextTime = nil;
        }

        /* 
         *   we're committing to an exact wall-clock time, so remember the
         *   current turn counter as the last commit point 
         */
        turnLastCommitted = gTurns;
        
        /*   Note that the event has been reached */
        evt.hasBeenReached = true;
        
        /*   If the timeManager exists, synchronize its time with ours. */
        syncTime(curTime);
    }

    /* add minutes to a [dd,hh,mm] value, returning a new [dd,hh,mm] value */
    addMinutes(t, mm)
    {
        /* add the minutes; if that takes us over 60, carry to hours */
        if ((t[3] += mm) >= 60)
        {
            local hh;
            
            /* we've passed 60 minutes - figure how many hours that is */
            hh = t[3] / 60;

            /* keep only the excess-60 minutes in the minutes slot */
            t[3] %= 60;

            /* add the hours; if that takes us over 24, carry to days */
            if ((t[2] += hh) >= 24)
            {
                local dd;
                
                /* we've passed 24 hours - figure how many days that is */
                dd = t[2] / 24;

                /* keep only the excess-24 hours in the hours slot */
                t[2] %= 24;

                /* add the days */
                t[1] += dd;
            }
        }

        /* return the adjusted time */
        return t;
    }

    /* get the difference in minutes between two [dd,hh,mm] values */
    diffMinutes(t1, t2)
    {
        local mm;
        local hh;
        local dd;
        local bhh = 0;
        local bdd = 0;
        
        /* get the difference in minutes; if negative, note the borrow */
        mm = t1[3] - t2[3];
        if (mm < 0)
        {
            mm += 60;
            bhh = 1;
        }

        /* get the difference in hours; if negative, note the borrow */
        hh = t1[2] - t2[2] - bhh;
        if (hh < 0)
        {
            hh += 24;
            bdd = 1;
        }

        /* get the difference in days */
        dd = t1[1] - t2[1] - bdd;

        /* add them all together to get the total minutes */
        return mm + 60*hh + 60*24*dd;
    }

    /* 
     *   Check each turn whether another ClockEvent has been reached. Note that
     *   this requires the events.t module to be present to work.
     */
    reachCheck()
    {
        /* Go through every ClockEvent in our eventList */
        foreach(local cur in eventList)
        {
            /* 
             *   If we find one that hasn't been reached before, but whose
             *   reachedWhen condition is now true, note that it has now been
             *   reached.
             */
            if(!cur.hasBeenReached && cur.reachedWhen)
            {
                eventReached(cur);
                
                /* 
                 *   Don't continue searching for ClockEvents on this turn; we
                 *   don't want more than one ClockEvent to be reached at a
                 *   time.
                 */
                break;
            }
        }
    }
    
    /* 
     *   our list of clock events (we build this automatically during
     *   pre-initialization) 
     */
    eventList = nil

    /* the current game clock time */
    curTime = nil

    /* the most recent event that we reached */
    lastEvent = nil

    /* the next event's game clock time */
    nextTime = nil

    /* the next event we're due to reach */
    nextEvent = nil
    
    
    /* 
     *   The turn counter (Schedulable.gameClockTime) on the last turn
     *   where committed to a specific time.  Each time we check the time,
     *   we look here to see how many turns have elapsed since the last
     *   time check, and we use this to choose a plausible scale for the
     *   wall-clock time change.  
     */
    turnLastCommitted = 0
    
    /*   
     *   The base date (year, month, day) our game is meant to start on,
     *   expressed as a Date object. Often this doesn't matter if we're only
     *   interested in the time of day. By default we make it Jan 1, 2000. If
     *   gameMain.gameStartDate is defines it will instead be taken from there.
     */    
    baseDate = static new Date(2000, 1, 1)
    
    /*  Return the date of t as a Date object. */
    eventDate(t)
    {
        /* If t is nil, return nil */
        if(t == nil)
            return nil;
               
        /* Get the date only part of the base date */
        local bd = baseDate.getDate();
        
        /* Create a Date object representing midnight on our base date */
        local curDate = new Date(bd[1], bd[2], bd[3]);
        
        /* 
         *   Advance this date by the number of days the lastEventTime is from
         *   the starting time, which is usually day 1
         */
        curDate = curDate.addInterval([0, 0, t[1] - 1]);
        
        /* Extract the date part again */
        curDate = curDate.getDate();     
        
        /* Return the date and time as a Date object */
        return new Date(curDate[1], curDate[2], curDate[3], t[2], t[3], 0, 0);
    }

    /* Retutn the date and time of the last event as a Date object. */
    lastEventDate()
    {
        return lastEvent ? eventDate(lastEvent.eventTime) : nil;
    }

    /* Get the time in our [d, h, m, s] format from a Date object. */
    getClockTime(dat)
    {
        /* Get the time element of the Date object */
        local t = dat.getClockTime();
        
        /* Get the number of days between the Date object and our baseDate */
        local days = toInteger(dat - baseDate);
        
        /* 
         *   return the resultant time in [d, h, m, s] format
         *
         *   NOTE: There appears to be a bug in the getClockTime method of the
         *   Date class, so the expression below has to be "wrong" (according to
         *   the description of Date in the System Manual) to compensate.
         */
        
        return [days + 1, t[2], t[3]];
        
    }
    
    
    /* Synchronize the timeManager's time with our time, if it exists. */
    syncTime(t)
    {
        if(defined(timeManager))
        {
            /* Set the timeManager's time to our time. */
            timeManager.currentTime = eventDate(t);
            
            /* 
             *   Try to prevent the current turn from advancing the
             *   timeManager's time beyond our time.
             */
            takeTime(0);
        }
    }
;

// Try an alternative implementation based on the Date class throughout

clockManager2: InitObject
    /*
     *   Get the current game-clock time.  This returns a list in the same
     *   format as ClockEvent.eventTime: [day,hour,minute].
     *   
     *   Remember that our time-keeping scheme is a sort of "Schrodinger's
     *   clock" [see footnote 1].  Between time checks, the game time
     *   clock is in a vague, fuzzy state, drifting along at an
     *   indeterminate pace from the most recent check.  When this method
     *   is called, though, the clock manager is forced to commit to a
     *   particular time, because we have to give a specific answer to the
     *   question we're being asked ("what time is it?").  As in quantum
     *   mechanics, then, the act of observation affects the quantity
     *   being observed.  Therefore, you should avoid calling this routine
     *   unnecessarily; call it only when you actually have to tell the
     *   player what time it is - and don't tell the player what time it
     *   is unless they ask, or there's some other good reason.
     *   
     *   If you want a string-formatted version of the time (as in
     *   '9:05pm'), you can call checkTimeFmt().  
     */
    checkTime()
    {
        local turns;
        local mm;
        local sdmm;
        
        /* 
         *   Determine how many turns it's been since we last committed to
         *   a specific wall-clock time.  This will give us the
         *   psychological "scale" of the amount of elapsed wall-clock the
         *   user might expect.  
         */
        turns = libGlobal.totalTurns - turnLastCommitted;

        /* 
         *   start with the base scaling factor - this is the number of
         *   minutes of game time we impute to a hundred turns, in the
         *   absence of the constraint of running up against the next event
         */
        mm = (turns * baseScaleFactor) / 100;
        
        /* If the timeManager exists, see what it reckons the time should be */
        if(defined(timeManager))            
        {
            /* 
             *   If we don't have a nextEvent, let the timeManager decide the
             *   time.
             */
            if(nextEvent == nil)
            {
                /* Get the clock time from the timeManager. */
                return getClockTime(timeManager.currentTime);               
            }
            
            
            /* 
             *   The number of minutes elapsed according to the timeManager is
             *   the difference between the timeManager's currentTime and our
             *   last event date multiplied by the number of minutes in a day.
             */                 
            local tMmm = (timeManager.currentTime - lastEventDate()) * 1440;
           
            /* Convert this number to an integer. */
            tMmm = toInteger(tMmm);
            
            /* 
             *   Calculate the number of seconds the timeManager currently
             *   thinks the current action will take.
             */
            local secs = 0;
            
            if(gAction)
            {
                secs = replacementTime == nil ? 
                    gAction.timeTaken + timeManager.additionalTime : 
                timeManager.replacementTime;
            }
            
            /* 
             *   Add the current turn time to the timeManager's reckoning of
             *   time
             */
            tMmm += secs/60;
            
            /* 
             *   If the subjective time estimate is greater than the
             *   timeManager's reckoning, or if there's no nextTime, use the
             *   timeManager's reckoning of elapsed minutes.
             */
            if(mm > tMmm || nextTime == nil)
                mm = tMmm;
            
        }
        
        /*
         *   If the base scaled time would take us within sdmm of the next event
         *   time, slow the clock down from our base scaling factor so that we
         *   always leave ourselves room to advance the clock further on the
         *   next check.  Reduce the passage of time in proportion to our
         *   reduced window - so if we have only 60 minutes left, advance time
         *   at half the normal pace.
         */
        if (nextTime != nil)
        {
            /*   
             *   In Mike Roberts's version of subtime, the clock is slowed down
             *   if the base scaled time would take us within two hours of the
             *   next event time, but this may be inappropriate if the game is
             *   working to a much shorter or longer timescale. So we instead
             *   compute the time at which slowing down should occur in a
             *   separate method to make it easy for game code to override it.
             *   By default, the slow-down time will be half-way between the
             *   previous event and the next one.
             */
            sdmm = slowDownTime();
            
            /* get the minutes between now and the next scheduled event */
            local delta = diffMinutes(nextTime, curTime);

            /* check to see if the raw increment would leave under sdmm minutes */
            if (delta - mm < sdmm)
            {
                /*
                 *   The raw time increment would leave us under sdmm minutes
                 *   away.  If we have under sdmm to go before the
                 *   next event, scale down the rate of time in proportion
                 *   to our share under sdmm.  (Note that we might
                 *   have more than sdmm to go and still be here,
                 *   because the raw adjusted time leaves under sdmm minutes.)  
                 */
                if (delta < sdmm)
                    mm = (mm * delta) / sdmm;

                /* 
                 *   In any case, cap it at half the remaining time, to
                 *   ensure that we won't ever make it to the next event
                 *   time until the next event occurs.
                 */
                if (mm > delta / 2)
                    mm = delta / 2;
            }
        }

        /* 
         *   If our calculation has left us with no passage of time, simply
         *   return the current time unchanged, and do not treat this as a
         *   commit point.  We don't consider this a commit point because
         *   we treat it as not even checking again - it's effectively just
         *   a repeat of the last check, since it's still the same time.
         *   This ensures that we won't freeze the clock for good due to
         *   rounding - enough additional turns will eventually accumulate
         *   to nudge the clock forward.  
         */
        if (mm == 0)
            return curTime;

        /* add the minutes to the current time */
        curTime = addMinutes(curTime, mm);

        /* the current turn is now the last commit point */
        turnLastCommitted = gTurns;
                
         /*   If the timeManager exists, synchronize its time with ours. */
        syncTime(curTime);
        
        /* return the new time */
        return curTime;
    }

    /* 
     *   Compute the time remaining until the next event at which we start to
     *   slow down the clock. By default we make this half the time from the
     *   previous event to the next. Game code can override if some other value
     *   is preferred.
     */
    slowDownTime()
    {
        /*  
         *   If we have a lastEvent, get its eventTime; otherwise assume the
         *   last event was at midnight on day 1.
         */
        local lastEventTime = lastEvent == nil ? [1,0,0] : lastEvent.eventTime;
        
        /*   
         *   Return half the difference between the next event time and the last
         *   event time.
         */
        return diffMinutes(nextTime, lastEventTime)/2;
    }
    
    
    /*
     *   The base scaling factor: this is the number of minutes per hundred
     *   turns when we have unlimited time until the next event.  This number is
     *   pretty arbitrary, since we're depending so much on the player's
     *   uncertainty about just how long things take, and also because we'll
     *   adjust it anyway when we're running out of time before the next event.
     *   Even so, you might want to adjust this value up or down according to
     *   your sense of the pacing of your game.
     *
     *   In Mike Roberts's implementation, the baseScaleFactor was defined as a
     *   constant value of 60. This is still the default value, but if there is
     *   a next event we take the scale factor from that event's scaleFactor so
     *   that we can vary the pace of time according to the spacing of events if
     *   we wish.
     */
    baseScaleFactor = (nextEvent == nil ? 60 : nextEvent.scaleFactor)

    /*
     *   Get the current game-clock time, formatted into a string with the
     *   given format mask - see formatTime() for details on how to write a
     *   mask string.
     *   
     *   Note that the same cautions for checkTime() apply here - calling
     *   this routine commits us to a particular time, so you should call
     *   this routine only when you're actually ready to display a time to
     *   the player.  
     */
    checkTimeFmt(fmt) { return formatTime(checkTime(), fmt); }
    
    /* 
     *   Get a formatted version of the given wall-clock time.  The time is
     *   expressed as a list, in the same format as ClockEvent.eventTime:
     *   [day,hour,minute], where 'day' is 1 for the first day of the game,
     *   2 for the second, and so on.
     *   
     *   The format string consists of one or more prefixes, followed by a
     *   format mask.  The prefixes are flags that control the formatting,
     *   but don't directly insert any text into the result string:
     *   
     *   24 -> use 24-hour time; if this isn't specified, a 12-hour clock
     *   is used instead.  On the 24-hour clock, midnight is hour zero, so
     *   12:10 AM is represented as 00:10.
     *   
     *   [am][pm] -> use 'am' as the AM string, and 'pm' as the PM string,
     *   for the 'a' format mask character.  This lets you specify an
     *   arbitrary formatting for the am/pm marker, overriding the default
     *   of 'am' or 'pm'.  For example, if you want to use 'A.M.' and
     *   'P.M.'  as the markers, you'd write a prefix of [A.M.][P.M.].  If
     *   you want to use ']' within the marker string itself, quote it with
     *   a '%': '[[AM%]][PM%]]' indicates markers of '[AM]' and '[PM]'.
     *   
     *   Following the prefix flags, you specify the format mask.  This is
     *   a set of special characters that specify parts of the time to
     *   insert.  Each special character is replaced with the corresponding
     *   formatted time information in the result string.  Any character
     *   that isn't special is just copied to the result string as is.  The
     *   special character are:
     *   
     *   h -> hour, no leading zero for single digits (hence 9:05, for
     *   example)
     *   
     *   hh -> hour, leading zero (09:05)
     *   
     *   m -> minutes, no leading zero (9:5)
     *   
     *   mm -> minutes with a leading zero (9:05)
     *   
     *   a -> AM/PM marker.  If an [am][pm] prefix was specified, the 'am'
     *   or 'pm' string from the prefix is used.  Otherwise, 'am' or 'pm'
     *   is literally inserted.
     *   
     *   % -> quote next character (so %% -> a single %)
     *   
     *   other -> literal
     *   
     *   Examples:
     *   
     *   'hh:mma' produces '09:05am'
     *.  '[A.M][P.M]h:mma' produces '9:05 P.M.'
     *.  '24hhmm' produces '2105'.  
     */
    formatTime(t, fmt)
    {
        local hh = t[2];
        local mm = t[3];
        local pm = (hh >= 12);
        local use24 = nil;
        local amStr = nil;
        local pmStr = nil;
        local ret;
        local match;
            
        /* check flags */
        for (;;)
        {
            local fl;
            
            /* check for a flag string */
            match = rexMatch(
                '24|<lsquare>(<^rsquare>|%%<rsquare>)+<rsquare>', fmt, 1);

            /* if we didn't find another flag, we're done */
            if (match == nil)
                break;

            /* pull out the flag text */
            fl = fmt.substr(1, match);
            fmt = fmt.substr(match + 1);

            /* check the match */
            if (fl == '24')
            {
                /* note 24-hour time */
                use24 = true;
            }
            else
            {
                /* it's an am/pm marker - strip the brackets */
                fl = fl.substr(2, fl.length() - 2);

                /* change any '%]' sequences into just ']' */
                fl = fl.findReplace('%]', ']', ReplaceAll, 1);

                /* set AM if we haven't set it already, else set PM */
                if (amStr == nil)
                    amStr = fl;
                else
                    pmStr = fl;
            }
        }

        /* if we didn't select an AM/PM, use the default */
        amStr = (amStr == nil ? 'am' : amStr);
        pmStr = (pmStr == nil ? 'pm' : pmStr);

        /* adjust for a 12-hour clock if we're using one */
        if (!use24)
        {
            /* subtract 12 from PM times */
            if (pm)
                hh -= 12;

            /* hour 0 on a 12-hour clock is written as 12 */
            if (hh == 0)
                hh = 12;
        }

        /* run through the format and build the result string */
        for (ret = '', local i = 1, local len = fmt.length() ; i <= len ; ++i)
        {
            /* check what we have */
            match = rexMatch(
                '<case>h|hh|m|mm|a|A|am|AM|a%.m%.|A.%M%.|24|%%', fmt, i);
            if (match == nil)
            {
                /* no match - copy this character literally */
                ret += fmt.substr(i, 1);
            }
            else
            {
                /* we have a match - check what we have */
                switch (fmt.substr(i, match))
                {
                case 'h':
                    /* add the hour, with no leading zero */
                    ret += toString(hh);
                    break;

                case 'hh':
                    /* add the hour, with a leading zero if needed */
                    if (hh < 10)
                        ret += '0';
                    ret += toString(hh);
                    break;

                case 'm':
                    /* add the minute, with no leading zero */
                    ret += toString(mm);
                    break;
                    
                case 'mm':
                    /* add the minute, with a leading zero if needed */
                    if (mm < 10)
                        ret += '0';
                    ret += toString(mm);
                    break;
                    
                case 'a':
                    /* add the am/pm indicator */
                    ret += (pm ? pmStr : amStr);
                    break;
                    
                case '%':
                    /* add the next character literally */
                    ++i;
                    ret += fmt.substr(i, 1);
                    break;
                }

                /* skip any extra characters in the field */
                i += match - 1;
            }
        }

        /* return the result string */
        return ret;
    }

    /* pre-initialize */
    execute()
    {
        local vec;
        
        /* build a list of all of the ClockEvent objects in the game */
        vec = new Vector(10);
        forEachInstance(ClockEvent, {x: vec.append(x)});

        /* sort the list by time */
        vec.sort(SortAsc, {a, b: a.compareTime(b)});

        /* store it */
        eventList = vec.toList();

        /* 
         *   The earliest event is always the marker for the beginning of
         *   the game.  Since it's now the start of the game, mark the
         *   first event in our list as reached.  (The first event is
         *   always the earliest we find, by virtue of the sort we just
         *   did.)  
         */
        vec[1].eventReached();
        
        /*  
         *   If the events module is present, set up a PromptDaemon to check
         *   each turn whether a new ClockEvent has been reached.
         */
        if(defined(eventManager))
            new PromptDaemon(self, &reachCheck);
        
        /*  
         *   If the gameMain object defines a gameStartTime, use it to set our
         *   baseDate.
         */
        if(gameMain.propDefined(&gameStartTime))
        {
            local gst = gameMain.gameStartTime;
            
            if(dataType(gst) == TypeList)
                baseDate = new Date(gst[1], gst[2], gst[3]);
            
            if(dataType(gst) == TypeObject && gst.ofKind(Date))
                baseDate = gst;
        }
        
        /* 
         *   If the timeManager exists, synchronize its current start time with
         *   ours, if we have one.
         */
        if(defined(timeManager) && lastEvent)
            timeManager.currentTime = lastEventDate();
    }

    /* 
     *   Receive notification from a clock event that an event has just
     *   occurred.  (This isn't normally called directly from game code;
     *   instead, game code should usually call the ClockEvent object's
     *   eventReached() method.)  
     */
    eventReached(evt)
    {
        local idx;
        
        /* find the event in our list */
        idx = eventList.indexOf(evt);

        /* 
         *   Never go backwards - if events fire out of order, keep only
         *   the later event.  (Games should generally be constructed in
         *   such a way that events can only fire in order to start with,
         *   but in case a weird case slips through, we make this extra
         *   test to ensure that the player doesn't see any strange
         *   retrograde motion on the clock.) 
         */
        if (lastEvent != nil && lastEvent.compareTime(evt) > 0)
            return;
        
        /* note the current time */
        curTime = evt.eventTime;
        
        /* note the event that's just been reached */
        lastEvent = evt;

        /* 
         *   if there's another event following, note the next time and the next
         *   event, and get the next event to calculate its scale factor.
         */
        if (idx < eventList.length())
        {
            nextEvent = eventList[idx + 1];
            nextTime = nextEvent.eventTime;
            nextEvent.calcScaleFactor();
        }
        else
        {
            nextEvent = nil;
            nextTime = nil;
        }

        /* 
         *   we're committing to an exact wall-clock time, so remember the
         *   current turn counter as the last commit point 
         */
        turnLastCommitted = gTurns;
        
        /*   Note that the event has been reached */
        evt.hasBeenReached = true;
        
        /*   If the timeManager exists, synchronize its time with ours. */
        syncTime(curTime);
    }

    /* add minutes to a [dd,hh,mm] value, returning a new [dd,hh,mm] value */
    addMinutes(t, mm)
    {
        /* add the minutes; if that takes us over 60, carry to hours */
        if ((t[3] += mm) >= 60)
        {
            local hh;
            
            /* we've passed 60 minutes - figure how many hours that is */
            hh = t[3] / 60;

            /* keep only the excess-60 minutes in the minutes slot */
            t[3] %= 60;

            /* add the hours; if that takes us over 24, carry to days */
            if ((t[2] += hh) >= 24)
            {
                local dd;
                
                /* we've passed 24 hours - figure how many days that is */
                dd = t[2] / 24;

                /* keep only the excess-24 hours in the hours slot */
                t[2] %= 24;

                /* add the days */
                t[1] += dd;
            }
        }

        /* return the adjusted time */
        return t;
    }

    /* get the difference in minutes between two [dd,hh,mm] values */
    diffMinutes(t1, t2)
    {
        local mm;
        local hh;
        local dd;
        local bhh = 0;
        local bdd = 0;
        
        /* get the difference in minutes; if negative, note the borrow */
        mm = t1[3] - t2[3];
        if (mm < 0)
        {
            mm += 60;
            bhh = 1;
        }

        /* get the difference in hours; if negative, note the borrow */
        hh = t1[2] - t2[2] - bhh;
        if (hh < 0)
        {
            hh += 24;
            bdd = 1;
        }

        /* get the difference in days */
        dd = t1[1] - t2[1] - bdd;

        /* add them all together to get the total minutes */
        return mm + 60*hh + 60*24*dd;
    }

    /* 
     *   Check each turn whether another ClockEvent has been reached. Note that
     *   this requires the events.t module to be present to work.
     */
    reachCheck()
    {
        /* Go through every ClockEvent in our eventList */
        foreach(local cur in eventList)
        {
            /* 
             *   If we find one that hasn't been reached before, but whose
             *   reachedWhen condition is now true, note that it has now been
             *   reached.
             */
            if(!cur.hasBeenReached && cur.reachedWhen)
            {
                eventReached(cur);
                
                /* 
                 *   Don't continue searching for ClockEvents on this turn; we
                 *   don't want more than one ClockEvent to be reached at a
                 *   time.
                 */
                break;
            }
        }
    }
    
    /* 
     *   our list of clock events (we build this automatically during
     *   pre-initialization) 
     */
    eventList = nil

    /* the current game clock time */
    curTime = nil

    /* the most recent event that we reached */
    lastEvent = nil

    /* the next event's game clock time */
    nextTime = nil

    /* the next event we're due to reach */
    nextEvent = nil
    
    
    /* 
     *   The turn counter (Schedulable.gameClockTime) on the last turn
     *   where committed to a specific time.  Each time we check the time,
     *   we look here to see how many turns have elapsed since the last
     *   time check, and we use this to choose a plausible scale for the
     *   wall-clock time change.  
     */
    turnLastCommitted = 0
    
    /*   
     *   The base date (year, month, day) our game is meant to start on,
     *   expressed as a Date object. Often this doesn't matter if we're only
     *   interested in the time of day. By default we make it Jan 1, 2000. If
     *   gameMain.gameStartDate is defines it will instead be taken from there.
     */    
    baseDate = static new Date(2000, 1, 1)
    
    /*  Return the date of t as a Date object. */
    eventDate(t)
    {
        /* If t is nil, return nil */
        if(t == nil)
            return nil;
               
        /* Get the date only part of the base date */
        local bd = baseDate.getDate();
        
        /* Create a Date object representing midnight on our base date */
        local curDate = new Date(bd[1], bd[2], bd[3]);
        
        /* 
         *   Advance this date by the number of days the lastEventTime is from
         *   the starting time, which is usually day 1
         */
        curDate = curDate.addInterval([0, 0, t[1] - 1]);
        
        /* Extract the date part again */
        curDate = curDate.getDate();     
        
        /* Return the date and time as a Date object */
        return new Date(curDate[1], curDate[2], curDate[3], t[2], t[3], 0, 0);
    }

    /* Retutn the date and time of the last event as a Date object. */
    lastEventDate()
    {
        return lastEvent ? eventDate(lastEvent.eventTime) : nil;
    }

    /* Get the time in our [d, h, m, s] format from a Date object. */
    getClockTime(dat)
    {
        /* Get the time element of the Date object */
        local t = dat.getClockTime();
        
        /* Get the number of days between the Date object and our baseDate */
        local days = toInteger(dat - baseDate);
        
        /* 
         *   return the resultant time in [d, h, m, s] format
         *
         *   NOTE: There appears to be a bug in the getClockTime method of the
         *   Date class, so the expression below has to be "wrong" (according to
         *   the description of Date in the System Manual) to compensate.
         */
        
        return [days + 1, t[2], t[3]];
        
    }
    
    
    /* Synchronize the timeManager's time with our time, if it exists. */
    syncTime(t)
    {
        if(defined(timeManager))
        {
            /* Set the timeManager's time to our time. */
            timeManager.currentTime = eventDate(t);
            
            /* 
             *   Try to prevent the current turn from advancing the
             *   timeManager's time beyond our time.
             */
            takeTime(0);
        }
    }
;


/*
 *   Clock-setting plot event.  This object represents a plot point that
 *   occurs at a particular time in the story world.  Create one of these
 *   for each of your plot events.  The Clock Manager automatically builds
 *   a list of all of these objects during pre-initialization, so you don't
 *   have to explicitly tell the clock manager about these.
 *   
 *   Whenever the story reaches one of these events, you should call the
 *   eventReached() method of the event object.  This will set the clock
 *   time to the event's current time, and take note of how long we have
 *   until the next plot event.  
 */
class ClockEvent: object
    /*
     *   The time at which this event occurs.  This is expressed as a list
     *   with three elements: the day number, the hour (on a 24-hour
     *   clock), and the minute.  The day number is relative to the start
     *   of the game - day 1 is the first day of the game.  So, for
     *   example, to express 2:40pm on the second day of the game, you'd
     *   write [2,14,40].  Note that 12 AM is written as 0 (zero) on a
     *   24-hour clock, so 12:05am on day 1 would be [1,0,5].  
     */
    eventTime = [1,0,0]

    /* get a formatted version of the event time */
    formatTime(fmt) { return clockManager.formatTime(eventTime, fmt); }

    /* 
     *   Compare our event time to another event's time.  Returns -1 if our
     *   time is earlier than other's, 0 if we're equal, and 1 if we're
     *   after other. 
     */
    compareTime(other)
    {
        local a = eventTime;
        local b = other.eventTime;
        
        /* compare based on the most significant element that differs */
        if (a[1] != b[1])
            return a[1] - b[1];
        else if (a[2] != b[2])
            return a[2] - b[2];
        else
            return a[3] - b[3];
    }

    /*
     *   Notify the clock manager that this event has just occurred.  This
     *   sets the game clock to the event's time.  The game code must call
     *   this method when our point in the plot is reached.  
     */
    eventReached()
    {
        /* notify the clock manager */
        clockManager.eventReached(self);
    }
    
    /*   
     *   This is the number of minutes per hundred turns when we have unlimited
     *   time until this next event.  This number is pretty arbitrary, since
     *   we're depending so much on the player's uncertainty about just how long
     *   things take, and also because we'll adjust it anyway when we're running
     *   out of time before the next event.  Even so, you might want to adjust
     *   this value up or down according to your sense of the pacing of your
     *   game.
     *
     *   Alternatively you can define the turnsToEvent property (see below) and
     *   the game will calculate an appropriate scaleFactor for you.
     */
    scaleFactor = 60
    
    /*   
     *   Optional: if specified this should contain an estimate of the number of
     *   turns a player is typically likely to take to get to this event from
     *   the previous one; the game will then calculate an appropriate
     *   scaleFactor. Alternatively this can be left at nil and the scaleFactor
     *   specified directly.
     */       
    turnsToEvent = nil
    
    /* 
     *   If the turnsToEvent property is not nil and the clockManager has
     *   recorded a previous event, calculate the scaleFactor for this event.
     */
    calcScaleFactor()
    {        
        if(turnsToEvent && clockManager.lastEvent)
        {
            /* 
             *   Calculate the number of minutes between this event and the
             *   previous event.
             */
            local delta = clockManager.diffMinutes(
                eventTime, clockManager.lastEvent.eventTime);
            
            /*  
             *   Calculate the scaleFactor such that 100 turns will take
             *   scaleFactor minutes.
             */
            scaleFactor = (delta * 100)/turnsToEvent;
            
        }
    }
    
    /* 
     *   A condition (or a method that returns true or nil) that causes this
     *   event to be reached when it becomes true. This provides an alternative
     *   way of reaching events (instead of calling the eventReached method).
     */
    reachedWhen = nil
    
    /*   
     *   Flag: has this event been reached? This is used internally by the
     *   library and shouldn't normally be changed in game code.
     */
    hasBeenReached = nil
;

/* ------------------------------------------------------------------------ */
/*
 *   [Footnote 1]
 *   
 *   "Schrodinger's cat" is a famous thought experiment in quantum
 *   physics, concerning how a quantum mechanical system exists in
 *   multiple, mutually exclusive quantum states simultaneously until an
 *   observer forces the system to assume only one of the states by the
 *   act of observation.  The thought experiment has been popularized as
 *   an illustration of how weird and wacky QM is, but it's interesting to
 *   note that Schrodinger actually devised it to expose what he saw as an
 *   unacceptable paradox in quantum theory.
 *   
 *   The thought experiment goes like this: a cat is locked inside a
 *   special box that's impervious to light, X-rays, etc., so that no one
 *   on the outside can see what's going on inside.  The box contains,
 *   apart from the cat, a little radiation source and a radiation
 *   counter.  When the counter detects a certain radioactive emission, it
 *   releases some poison gas, killing the cat.  The radioactive emission
 *   is an inherently quantum mechanical, unpredictable process, and as
 *   such can (and must) be in a superposition of "emitted" and "not
 *   emitted" states until observed.  Because the whole system is
 *   unobservable from the outside, the supposition is that everything
 *   inside is "entangled" with the quantum state of the radioactive
 *   emission, hence the cat is simultaneously living and dead until
 *   someone opens the box and checks.  It's not just that no one knows;
 *   rather, the cat is actually and literally alive and dead at the same
 *   time.
 *   
 *   Schrodinger's point was that this superposition of the cat's states
 *   is a necessary consequence of the way QM was interpreted at the time
 *   he devised the experiment, but that it's manifestly untrue, since we
 *   know that cats are macroscopic objects that behave according to
 *   classical, deterministic physics.  Hence a paradox, hence the
 *   interpretation of the theory must be wrong.  The predominant
 *   interpretation of QM has since shifted a bit so that the cat would
 *   now count as an observer - not because it's alive or conscious or
 *   anything metaphysical, but simply because it's macroscopic - so the
 *   cat's fate is never actually entangled with the radioactive source's
 *   quantum state.  Popular science writers have continued to talk about
 *   Schrodinger's cat as though it's for real, maybe to make QM seem more
 *   exotic to laypersons, but most physicists today wouldn't consider the
 *   experiment to be possible as literally stated.  Physicists today
 *   might think of it as a valid metaphor to decribe systems where all of
 *   the components are on an atomic or subatomic scale, but no one today
 *   seriously thinks you can create an actual cat that's simultaneously
 *   alive and dead.  
 */

