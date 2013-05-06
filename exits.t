#charset "us-ascii"

/* 
 *   Based on Copyright (c) 2002, 2006 by Michael J. Roberts
 *   
 *   Based on exitslister.t, copyright 2002 by Steve Breslin and
 *   incorporated by permission.  
 *   
 *   TADS 3 Library - Exits Lister
 *   
 *   This module provides an automatic exit lister that shows the apparent
 *   exits from the player character's location.  The automatic exit lister
 *   can optionally provide these main features:
 *   
 *   - An "exits" verb lets the player explicitly show the list of apparent
 *   exits, along with the name of the room to which each exit connects.
 *   
 *   - Exits can be shown automatically as part of the room description.
 *   This extra information can be controlled by the player through the
 *   "exits on" and "exits off" command.
 *   
 *   - Exits can be shown automatically when an actor tries to go in a
 *   direction where no exit exists, as a helpful reminder of which
 *   directions are valid.  
 */

/* include the library header */
#include "advlite.h"


/* ------------------------------------------------------------------------ */
/*
 *   The main exits lister.
 */
exitLister: PreinitObject
    /* preinitialization */
    execute()
    {
        /* install myself as the global exit lister object */
        gExitLister = self;
    }
    
    /*
     *   Flag: use "verbose" listing style for exit lists in room
     *   descriptions.  When this is set to true, we'll show a
     *   sentence-style list of exits ("Obvious exits lead east to the
     *   living room, south, and up.").  When this is set to nil, we'll use
     *   a terse style, enclosing the message in the default system
     *   message's brackets ("[Obvious exits: East, West]").
     *   
     *   Verbose-style room descriptions tend to fit well with a room
     *   description's prose, but at the expense of looking redundant with
     *   the exit list that's usually built into each room's custom
     *   descriptive text to begin with.  Some authors prefer the terse
     *   style precisely because it doesn't look like more prose
     *   description, but looks like a separate bit of information being
     *   offered.
     *   
     *   This is an author-configured setting; the library does not provide
     *   a command to let the player control this setting.  
     */
    roomDescVerbose = nil

    /* 
     *   Flag: show automatic exit listings on attempts to move in
     *   directions that don't allow travel.  Enable this by default,
     *   since most players appreciate having the exit list called out
     *   separately from the room description (where any mention of exits
     *   might be buried in lots of other text) in place of an unspecific
     *   "you can't go that way".  
     *   
     *   This is an author-configured setting; the library does not provide
     *   a command to let the player control this setting.  
     */
    enableReminder = true

    /*
     *   Flag: enable the automatic exit reminder even when the room
     *   description exit listing is enabled.  When this is nil, we will
     *   NOT show a reminder with "can't go that way" messages when the
     *   room description exit list is enabled - this is the default,
     *   because it can be a little much to have the list of exits shown so
     *   frequently.  Some authors might prefer to show the reminder
     *   unconditionally, though, so this option is offered.  
     *   
     *   This is an author-configured setting; the library does not provide
     *   a command to let the player control this setting.  
     */
    enableReminderAlways = nil

    /*
     *   Flag: use hyperlinks in the directions mentioned in room
     *   description exit lists, so that players can click on the direction
     *   name in the listing to enter the direction command. 
     */
    enableHyperlinks = true

    /* flag: we've explained how the exits on/off command works */
    exitsOnOffExplained = nil

    /*
     *   Determine if the "reminder" is enabled.  The reminder is the list
     *   of exits we show along with a "can't go that way" message, to
     *   reminder the player of the valid exits when an invalid one is
     *   attempted.  
     */
    isReminderEnabled()
    {
        /*   
         *   The reminder is enabled if enableReminderAlways is true, OR if
         *   enableReminder is true AND exitsMode.inRoomDesc is nil.  
         */
        return (enableReminderAlways
                || (enableReminder && !exitsMode.inRoomDesc));
    }

    /*
     *   Get the exit lister we use for room descriptions. 
     */
    getRoomDescLister()
    {
        /* use the verbose or terse lister, according to the configuration */
        return roomDescVerbose
            ? lookAroundExitLister
            : lookAroundTerseExitLister;
    }
    
    /* perform the "exits" command to show exits on explicit request */
    showExitsCommand()
    {
        /* show exits for the current actor */
        showExits(gActor);

        /* 
         *   if we haven't explained how to turn exit listing on and off,
         *   do so now 
         */
        if (!exitsOnOffExplained)
        {
            DMsg(explain exits on off, 
                 '<.p>Exit Listing can be adjusted with the following
        commands:\n
        EXITS ON -- show exits in both the status line and in room
        descriptions.\n
        EXITS OFF -- show exits neither in the status line nor in room
        descriptions.\n
        EXITS STATUS -- show exits in the status line only.\n
        EXITS LOOK -- show exits in room descriptions only.\n
        EXITS COLOR ON -- show unvisited exits in a different colour.\n
        EXITS COLOR OFF -- don\'t show unvisited exits in a different colour.\n
        EXITS COLOR RED / BLUE / GREEN / YELLOW -- show unvisted exits in the
        specified colour. 
        <.p>');           

            exitsOnOffExplained = true;
        }
    }

    /* 
     *   Perform an EXITS ON/OFF/STATUS/LOOK command.  'stat' indicates
     *   whether we're turning on (true) or off (nil) the statusline exit
     *   listing; 'look' indicates whether we're turning the room
     *   description listing on or off. 
     */
    exitsOnOffCommand(stat, look)
    {
        /* set the new status */
        exitsMode.inStatusLine = stat;
        exitsMode.inRoomDesc = look;

        /* confirm the new status */
        DMsg(exits on off okay, 'Okay. Exit listing in the status line is now 
            <<stat ? 'ON' : 'OFF'>>, while exit listing in room descriptions is
            now <<look ? 'ON' : 'OFF'>>. ');
        
        /* 
         *   If we haven't already explained how the EXITS ON/OFF command
         *   works, don't bother explaining it now, since they obviously
         *   know how it works if they've actually used it.  
         */
        exitsOnOffExplained = true;
    }
    
    /* show the list of exits from an actor's current location */
    showExits(actor)
    {
        /* show exits from the actor's location */
        showExitsFrom(actor, actor.getOutermostRoom);
    }

    /* show an exit list display in the status line, if desired */
    showStatuslineExits()
    {
        /* if statusline exit displays are enabled, show the exit list */
        if (exitsMode.inStatusLine)
            showExitsWithLister(gPlayerChar, gPlayerChar.getOutermostRoom,
                                statuslineExitLister,
                                gPlayerChar.location
                                .wouldBeLitFor(gPlayerChar));
    }

    /* 
     *   Calculate the contribution of the exits list to the height of the
     *   status line, in lines of text.  If we're not configured to display
     *   the exits list in the status line, then the contribution is zero;
     *   otherwise, we'll estimate how much space we need to display the
     *   exit list.  
     */
    getStatuslineExitsHeight()
    {
        /* 
         *   if we're enabled, our standard display takes up one line; if
         *   we're disabled, we don't contribute anything to the status
         *   line's vertical extent 
         */
        if (exitsMode.inStatusLine)
            return 1;
        else
            return 0;
    }

    /* show exits as part of a room description */
    lookAroundShowExits(actor, loc, illum)
    {
        /* if room exit displays are enabled, show the exits */
        if (exitsMode.inRoomDesc)
            showExitsWithLister(actor, loc, getRoomDescLister, illum);
    }

    /* show exits as part of a "cannot go that way" error */
    cannotGoShowExits(actor, loc)
    {
        /* if we want to show the reminder, show it */
        if (isReminderEnabled())
            showExitsWithLister(actor, loc, explicitExitLister,
                                loc.wouldBeLitFor(actor));
    }

    /* show the list of exits from a given location for a given actor */
    showExitsFrom(actor, loc)
    {
        /* show exits with our standard lister */
        showExitsWithLister(actor, loc, explicitExitLister,
                            loc.wouldBeLitFor(actor));
    }

    /* 
     *   Show the list of exits using a specific lister.
     *   
     *   'actor' is the actor for whom the display is being generated.
     *   'loc' is the location whose exit list is to be shown; this need
     *   not be the same as the actor's current location.  'lister' is the
     *   Lister object that will show the list of DestInfo objects that we
     *   create to represent the exit list.
     *   
     *   'locIsLit' indicates whether or not the ambient illumination, for
     *   the actor's visual senses, is sufficient that the actor would be
     *   able to see if the actor were in the new location.  We take this
     *   as a parameter so that we don't have to re-compute the
     *   information if the caller has already computed it for other
     *   reasons (such as showing a room description).  If the caller
     *   hasn't otherwise computed the value, it can be easily computed as
     *   loc.wouldBeLitFor(actor).  
     */
    showExitsWithLister(actor, loc, lister, locIsLit)
    {
        local destList;

        local options;
       

        /* we have no option flags for the lister yet */
        options = 0;

        /* run through all of the directions used in the game */
        destList = new Vector(Direction.allDirections.length());
        
        foreach(local dir in Direction.allDirections)
        {
            local conn = nil;           
            
            switch(loc.propType(dir.dirProp))
            {
            case TypeNil:
            case TypeSString:
            case TypeDString:
                break;
                        
                
            case TypeObject:
                conn = loc.(dir.dirProp);
                if(conn.isConnectorVisible && conn.isConnectorListed)
                    destList.append(new DestInfo(dir, conn.destination));
                break;
                
                /* 
                 *   If the property points to code then presumably something
                 *   happens if the player goes this way, so we'll list the
                 *   exit, unless the extraDestInfo table explicitly lists the
                 *   destination as nil.
                 */
                
            case TypeCode:    
                if(locIsLit)
                {
                    local dest = libGlobal.extraDestInfo[[loc, dir]];
                    if(dest != nil)
                       destList.append(new DestInfo(dir, dest));
                }
                break;
            }
            
        }
        
        /* show the list */
        lister.showListAll(destList.toList(), options, 0);
    }
    
   
    
;


ExitLister: Lister
    showListAll(lst, options, indent)
    {
        local cnt = lst.length;
        
        if(cnt == 0)
        {
            showListEmpty(nil, nil);
            return;
        }
        
        showListPrefixWide(1, nil, nil);
        
        for(local obj in lst, local i = 1 ; ; ++i)
        {
            showListItem(obj, nil, nil, nil);
            showListSeparator(nil, i, cnt);
           
        }
        
        showListSuffixWide(cnt, nil, nil);
        
    }
    
    listerShowsDest = nil
    
    exitsPrefix = BMsg(exits, 'Exits:');
;


statuslineExitLister: ExitLister
    showListEmpty(pov, parent)
    {
        "<<statusHTML(3)>><b><<exitsPrefix>></b> <i>None</i><<statusHTML(4)>>";
    }
    showListPrefixWide(cnt, pov, parent)
    {
        "<<statusHTML(3)>><b><<exitsPrefix>></b> ";
    }
    showListSuffixWide(cnt, pov, parent)
    {
        "<<statusHTML(4)>>";
    }
    showListItem(obj, options, pov, infoTab)
    {
        if(highlightUnvisitedExits && (obj.dest_ == nil || !obj.dest_.seen))
            htmlSay('<FONT COLOR="<<unvisitedExitColour>>">');
        "<<aHref(obj.dir_.name, obj.dir_.name, 'Go ' + obj.dir_.name,
                 AHREF_Plain)>>";
        if(highlightUnvisitedExits && (obj.dest_ == nil || !obj.dest_.seen))
            htmlSay('</FONT>');
    }
    showListSeparator(options, curItemNum, totalItems)
    {
        /* just show a space between items */
        if (curItemNum != totalItems)
            " &nbsp; ";
    }

    /* this lister does not show destination names */
    listerShowsDest = nil
    
    highlightUnvisitedExits = true
    
    unvisitedExitColour = 'green'
;

lookAroundExitLister: ExitLister
    showListEmpty(pov, parent)
    {        
        DMsg(no exits from here, 'There {plural} {are} no exits from {here}. ');
    }
    
    showListPrefixWide(cnt, pov, parent)
    {
        "<<exitsPrefix>> ";
    }
    showListSuffixWide(cnt, pov, parent)
    {
        ".";
    }
    showListItem(obj, options, pov, infoTab)
    {
        
        "<<obj.dir_.name>>";
        
    }
    showListSeparator(options, curItemNum, totalItems)
    {
        if(curItemNum == totalItems - 1)
            " and ";
        if(curItemNum < totalItems - 1)
            ", ";
    }
;

lookAroundTerseExitLister: ExitLister
    showListEmpty(pov, parent)
    {        
        DMsg(no exits, 'Exits: none. ');
    }
    
    showListPrefixWide(cnt, pov, parent)
    {
        "<<exitsPrefix>> ";
    }
    showListSuffixWide(cnt, pov, parent)
    {
        ".";
    }
    showListItem(obj, options, pov, infoTab)
    {
         htmlSay('<<aHref(obj.dir_.name, obj.dir_.name, 'Go ' + obj.dir_.name,
                 0)>>');
        
        
    }
    showListSeparator(options, curItemNum, totalItems)
    {
        if(curItemNum == totalItems - 1)
            " and ";
        if(curItemNum < totalItems - 1)
            ", ";
    }
;

explicitExitLister: ExitLister
    showListEmpty(pov, parent)
    {       
        DMsg(no clear exits, 'It{dummy}{\'s} not clear where {i} {can} go from
            {here}. ');
    }
    
    showListPrefixWide(cnt, pov, parent)
    {
        DMsg(exits from here, 'From {here} {i} could go ');
    }
    showListSuffixWide(cnt, pov, parent)
    {
        ".";
    }
    showListItem(obj, options, pov, infoTab)
    {
        
      htmlSay('<<aHref(obj.dir_.name, obj.dir_.name, 'Go ' + obj.dir_.name,
                 0)>>');
        
    }
    showListSeparator(options, curItemNum, totalItems)
    {
        if(curItemNum == totalItems - 1)
            " or ";
        if(curItemNum < totalItems - 1)
            ", ";
    }
    
;


/*
 *   A destination tracker.  This keeps track of a direction and the
 *   apparent destination in that direction. 
 */
class DestInfo: object
    construct(dir, dest, destName?, destIsBack?)
    {
        /* remember the direction, destination, and destination name */
        dir_ = dir;
        dest_ = dest;
    }

    /* the direction of travel */
    dir_ = nil

    /* the destination room object */
    dest_ = nil

    /* the name of the destination */
    destName_ = nil

    /* flag: this is the "back to" destination */
    destIsBack_ = nil

    /* list of other directions that go to our same destination */
    others_ = []
;

/*
     *   Settings item - show defaults in status line [SettingsItem)
 */
exitsMode: object
    /* our ID */
    settingID = 'adv3.exits'

    /* show our description */
    settingDesc()
    {
        DMsg(current exit settings, 'Exits are listed 
            <<if(inStatusLine && inRoomDesc)>>
            both in the status line and in room descriptions. 
            <<else if(inStatusLine && !inRoomDesc)>>
            in the status line only. 
            <<else if(!inStatusLine && inRoomDesc)>>
            in room descriptions only. 
            <<else if(!inStatusLine && !inRoomDesc)>>
            "neither in the status line nor in room descriptions. <<end>>');
    }
        

    /* convert to text */
    settingToText()
    {
        /* just return the two binary variables */
        return (inStatusLine ? 'on' : 'off')
            + ','
            + (inRoomDesc ? 'on' : 'off');
    }

    settingFromText(str)
    {
        /* parse out our format */
        if (rexMatch('<space>*(<alpha>+)<space>*,<space>*(<alpha>+)',
                     str.toLower()) != nil)
        {
            /* pull out the two variables from the regexp groups */
            inStatusLine = (rexGroup(1)[3] == 'on');
            inRoomDesc = (rexGroup(2)[3] == 'on');
        }
    }

   
    
    
    /* 
     *   Our value is in two parts.  inStatusLine controls whether or not
     *   we show the exit list in the status line; inRoomDesc controls the
     *   exit listing in room descriptions.  
     */
    inStatusLine = true
    inRoomDesc = nil
;
