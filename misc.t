#charset "us-ascii"

/* 
 *   Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved. 
 *   Adapted for adv3Lite by Eric Eve
 *   
 *   adv3Lite Library - miscellaneous definitions
 *   
 *   This module contains miscellaneous definitions that don't have a
 *   natural grouping with any larger modules, and which aren't complex
 *   enough to justify modules of their own.  
 */

/* include the library header */
#include "advlite.h"


/* ------------------------------------------------------------------------ */
/*
 *   When a call is made to a property not defined or inherited by the
 *   target object, the system will automatically invoke this method.  The
 *   method will be invoked with a property pointer as its first argument,
 *   and the original arguments as the remaining arguments.  The first
 *   argument gives the property that was invoked and not defined by the
 *   object.  A typical definition in an object would look like this:
 *   
 *   propNotDefined(prop, [args]) { ... }
 *   
 *   If this method is not defined by the object, the system simply
 *   returns nil as the value of the undefined property evaluation or
 *   method invocation.
 */
property propNotDefined;
export propNotDefined;


/* ------------------------------------------------------------------------ */
/*
 *   We refer to some properties defined primarily in score.t - that's an
 *   optional module, though, so make sure the compiler has heard of these. 
 */
property calcMaxScore, runScoreNotifier;


/* ------------------------------------------------------------------------ */
/*
 *   The library base class for the gameMain object.
 *   
 *   Each game MUST define an object called 'gameMain' to define how the
 *   game starts up.  You can use GameMainDef as the base class of your
 *   'gameMain' object, in which case the only thing you're required to
 *   specify in your object is the 'initialPlayerChar' property - you can
 *   inherit everything else from the GameMainDef class if you don't
 *   require any further customizations.  
 */
class GameMainDef: object
    /*
     *   The initial player character.  Each game's 'gameMain' object MUST
     *   define this to refer to the Actor object that serves as the
     *   initial player character. 
     */
    initialPlayerChar = nil

    /*
     *   Show the game's introduction.  This routine is called by the
     *   default newGame() just before entering the main command loop.  The
     *   command loop starts off by showing the initial room description,
     *   so there's no need to do that here.
     *   
     *   Most games will want to override this, to show a prologue message
     *   setting up the game's initial situation for the player.  We don't
     *   show anything by default.  
     */
    showIntro() { }

    /*
     *   Show the "goodbye" message.  This is called after the main command
     *   loop terminates.
     *   
     *   We don't show anything by default.  If you want to show a "thanks
     *   for playing" type of message as the game exits, override this
     *   routine with the desired text.  
     */
    showGoodbye() { }

    /*
     *   Begin a new game.  This default implementation shows the
     *   introductory message, calls the main command loop, and finally
     *   shows the goodbye message.
     *   
     *   You can override this routine if you want to customize the startup
     *   protocol.  For example, if you want to create a pre-game options
     *   menu, you could override this routine to show the list of options
     *   and process the user's input.  If you need only to customize the
     *   introduction and goodbye messages, you can simply override
     *   showIntro() and showGoodbye() instead.  
     */
    newGame()
    {
        /*   Create an action context in case any startup code needs it */
        gAction = Look.createInstance();
        gActor = initialPlayerChar;

        
        /* 
         *   Show the statusline before we display our introductory.  This
         *   will help minimize redrawing - if we waited until after
         *   displaying some text, we might have to redraw some of the
         *   screen to rearrange things for the new screen area taken up by
         *   the status line, which could be visible to the user.  By
         *   setting up the status line first, we'll probably have less to
         *   redraw because we won't have anything on the screen yet when
         *   figuring the layout.  
         */
        statusLine.showStatusLine();

        /* show the introduction */
        showIntro();

        /* run the game, showing the initial location's full description */
        runGame(true);

        /* show the end-of-game message */
        showGoodbye();
    }

    /*
     *   Restore a game and start it running.  This is invoked when the
     *   user launches the interpreter using a saved game file; for
     *   example, on a Macintosh, this happens when the user double-clicks
     *   on a saved game file on the desktop.
     *   
     *   This default implementation bypasses any normal introduction
     *   messages: we simply restore the game file if possible, and
     *   immediately start the game's main command loop.  Most games won't
     *   need to override this, but you can if you need some special effect
     *   in the restore-at-startup case.  
     */
    restoreAndRunGame(filename)
    {
        local succ;

        /* mention that we're about to restore the saved position */
        DMsg(note main restore, 'Game restored.<.p>');

        /* try restoring it */
        succ = Restore.startupRestore(filename);

        /* show a blank line after the restore result message */
        "<.p>";

        /* if we were successful, run the game */
        if (succ)
        {
            /* 
             *   Run the command loop.  There's no need to show the room
             *   description, since the RESTORE action will have already
             *   done so. 
             */
            runGame(nil);

            /* show the end-of-game message */
            showGoodbye();
        }
    }

    /*
     *   Set the interpreter window title, if applicable to the local
     *   platform.  This simply displays a <TITLE> tag to set the title to
     *   the string found in the versionInfo object.  
     */
    setGameTitle()
    {
        /* write the <TITLE> tag with the game's name */
        "<title><<versionInfo.name>></title>";
    }

    /*
     *   Set up the HTML-mode about-box.  By default, this does nothing.
     *   Games can use this routine to show an <ABOUTBOX> tag, if desired,
     *   to set up the contents of an about-box for HTML TADS platforms.
     *   
     *   Note that an <ABOUTBOX> tag must be re-initialized each time the
     *   main game window is cleared, so this routine should be called
     *   again after any call to clearScreen().  
     */
    setAboutBox()
    {
        /* we don't show any about-box by default */
    }

    /*
     *   Build a saved game metadata table.  This returns a LookupTable
     *   containing string key/value pairs that are stored in saved game
     *   files, providing descriptive information that can be displayed to
     *   the user when browsing a collection of save files.  This is called
     *   each time we execute a SAVE command, so that we store the current
     *   context of the game.
     *   
     *   Some interpreters display information from this table when
     *   presenting the user with a list of files for RESTORE.  The
     *   contents of the table are intentionally open-ended to allow for
     *   future extensions, but at the moment, the following keys are
     *   specifically defined (note that capitalization must be exact):
     *   
     *   UserDesc - descriptive text entered by the user (this should
     *   simply be the contents of the 'userDesc' parameter).  This is
     *   treated as ordinary plain text (i.e., no HTML or other markups are
     *   interpreted in this text).
     *   
     *   AutoDesc - descriptive text generated by the game to describe the
     *   saved position.  This text can contain the simple HTML markups
     *   <b>..</b>, <i>..</i>, and <br> for formatting.
     *   
     *   Return nil if you don't want to save any metadata information.  
     *   
     *   'userDesc' is an optional string entered by the user via the Save
     *   Game dialog.  Some interpreters let the user enter a description
     *   for a saved game via the file selector dialog; the descriptive
     *   text is separate from the filename, and is intended to let the
     *   user enter a more free-form description than would be allowed in a
     *   filename.  This text, if any, is passed to use via the 'userDesc'
     *   parameter.  
     */
    getSaveDesc(userDesc)
    {
        /* create the lookup table */
        local t = new LookupTable();

        /* store the user description, if provided */
        if (userDesc != nil)
            t['UserDesc'] = userDesc;

        /* start our auto description with the current room name */
        desc = gPlayerChar.outermostVisibleParent().roomTitle + '; ';
        
        /* if we're keeping score, include the score */
        if (libGlobal.scoreObj != nil)
            desc += toString(libGlobal.scoreObj.totalScore) + ' points in ';

        /* add the number of turns so far */
        desc += toString(libGlobal.totalTurns) + ' moves';

        /* add the auto description */
        t['AutoDesc'] = desc;

        /* return the table */
        return t;
    }

    /*
     *   The gameMain object also specifies some settings that control
     *   optional library behavior.  If you want the standard library
     *   behavior, you can just inherit the default settings from this
     *   class.  Some games might want to select non-default variations,
     *   though.  
     */

    /* 
     *   The maximum number of points possible in the game.  If the game
     *   includes the scoring module at all, and this is non-nil, the SCORE
     *   and FULL SCORE commands will display this value to the player as a
     *   rough indication of how much farther there is to go in the game.
     *   
     *   By default, we initialize this on demand, by calculating the sum
     *   of the point values of the Achievement objects in the game.  The
     *   game can override this if needed to specify a specific maximum
     *   possible score, rather than relying on the automatic calculation.
     */
    maxScore()
    {
        local m;
        
        /* ask the score module (if any) to compute the maximum score */
        m = (libGlobal.scoreObj != nil
             ? libGlobal.scoreObj.calcMaxScore : nil);

        /* supersede this initializer with the calculated value */
        maxScore = m;

        /* return the result */
        return m;
    }

    /*
     *   The score ranking list - this provides a list of names for
     *   various score levels.  If the game provides a non-nil list here,
     *   the SCORE and FULL SCORE commands will show the rank along with
     *   the score ("This makes you a Master Adventurer").
     *   
     *   This is a list of score entries.  Each score entry is itself a
     *   list of two elements: the first element is the minimum score for
     *   the rank, and the second is a string describing the rank.  The
     *   ranks should be given in ascending order, since we simply search
     *   the list for the first item whose minimum score is greater than
     *   our score, and use the preceding item.  The first entry in the
     *   list would normally have a minimum of zero points, since it
     *   should give the initial, lowest rank.
     *   
     *   If this is set to nil, which it is by default, we'll simply skip
     *   score ranks entirely.  
     */
    scoreRankTable = nil

    
    /*  
     *   If this flag is true then room description listings and examine
     *   listings use a parenthetical style to show subcontents (e.g. "On the
     *   table you see a box (in which is a brass key)") instead of showing each
     *   item and its contents in a separate paragraph.
     */    
    useParentheticalListing = nil
    
    /* 
     *   If this flag is true then room description listings will include a
     *   paragraph break between each set of subcontents listings (i.e. the
     *   listing of the contents of each item in the room that has visible
     *   contents). If it is nil the subcontents listings will all be run into a
     *   single paragraph. Note that the global setting defined here can be
     *   overridden on individual rooms.
     */
    paraBrksBtwnSubcontents = true
        

    /*
     *   Option flag: allow ALL to be used for every verb.  This is true by
     *   default, which means that players will be allowed to use ALL with
     *   any command - OPEN ALL, EXAMINE ALL, etc.
     *   
     *   Some authors don't like to allow players to use ALL with so many
     *   verbs, because they think it's a sort of "cheating" when players
     *   try things like OPEN ALL.  This option lets you disable ALL for
     *   most verbs; if you set this to nil, only the basic inventory
     *   management verbs (TAKE, TAKE FROM, DROP, PUT IN, PUT ON) will
     *   allow ALL, and other verbs will simply respond with an error
     *   ("'All' isn't allowed with that verb").
     *   
     *   If you're writing an especially puzzle-oriented game, you might
     *   want to set this to nil.  It's a trade-off though, as some people
     *   will think your game is less player-friendly if you disable ALL.  
     */
    allVerbsAllowAll = true

    
    /*
     *   Should the "before" notifications (beforeAction, roomBeforeAction, and
     *   actorAction) run before or after the "check" phase?
     *
     *   In many ways it's more logical and useful to run "check" first.  That
     *   way, you can consider the action to be more or less committed by the
     *   time the "before" notifiers are invoked.  Of course, a command is never
     *   truly* committed until it's actually been executed, since a "before"
     *   handler could always cancel it.  But this is relatively rare - "before"
     *   handlers usually carry out side effects, so it's very useful to be able
     *   to know that the command has already passed all of its own internal
     *   checks by the time "before" is invoked - that way, you can invoke side
     *   effects without worrying that the command will subsequently fail.
     */
    beforeRunsBeforeCheck = nil
    
    /* 
     *   Flag, should this game be in the past tense. By default the game is in
     *   the present tense.
     *
     *   For a wider selection of tenses override Narrator.tense instead.
     */
    usePastTense = nil
        
    /*   
     *   The AGAIN command could be interpreted in two different ways. It could
     *   repeat the resolved action (using precisely the same objects as
     *   before), or it could act as if the player had retyped the command and
     *   then parse it again from scratch (which might result in a different
     *   interpretation of the command, or different objects being selected).
     *   The former interpretation is used if againRepeatsParse is nil; the
     *   latter if it's true.
     */    
    againRepeatsParse = true
    
    /*   
     *   Flag. If this is true the game attempts to switch the againRepeatsParse
     *   flag between true and nil to give the contextually better
     *   interpretation of AGAIN. This should be regarded as somewhat
     *   experimental for now.
     */
    autoSwitchAgain = true    
    
    /* 
     *   Is this game in verbose mode? By default we make it so, but players can
     *   change this with the BRIEF/TERSE command.
     */
    verbose = true
    
    /* 
     *   Is this game in fast GO TO mode? By default we make it not, so that the
     *   GO TO command moves the player character only one step of the way at a
     *   time, but if this is set to true the GO TO command will keep moving the
     *   player until either the destination is reached or an obstacle is
     *   encountered.
     */
    fastGoTo = nil
      
;

/* ------------------------------------------------------------------------ */
/*
 *   Clear the main game window.  In most cases, you should call this
 *   rather than calling the low-level clearScreen() function directly,
 *   since this routine takes care of a couple of chores that should
 *   usually be done at the same time.
 *   
 *   First, we flush the transcript to ensure that no left-over reports
 *   that were displayed before we cleared the screen will show up on the
 *   new screen.  Second, we call the low-level clearScreen() function to
 *   actually clear the display window.  Finally, we re-display any
 *   <ABOUTBOX> tag, to ensure that the about-box will still be around;
 *   this is necessary because any existing <ABOUTBOX> tag is lost after
 *   the screen is cleared.  
 */
cls()
{    /* clear the screen */
    aioClearScreen();
}




/* ------------------------------------------------------------------------ */
/*
 *   Determine if the given object overrides the definition of the given
 *   property inherited from the given base class.  Returns true if the
 *   object derives from the given base class, and the object's definition
 *   of the property comes from a different place than the base class's
 *   definition of the property.  
 */
overrides(obj, base, prop)
{
    return (obj.ofKind(base)
            && (obj.propDefined(prop, PropDefGetClass)
                != base.propDefined(prop, PropDefGetClass)));
}

/* ------------------------------------------------------------------------ */
/*
 *   Library Pre-Initializer.  This object performs the following
 *   initialization operations immediately after compilation is completed:
 *   
 *   - adds each defined Thing to its container's contents list
 *   
 *   - adds each defined Sense to the global sense list
 *   
 *   This object is named so that other libraries and/or user code can
 *   create initialization order dependencies upon it.  
// */
adv3LibPreinit: PreinitObject
    execute()
    {

        /* set the initial player character, as specified in gameMain */
        gPlayerChar = gameMain.initialPlayerChar;
        

        

        /* 
         *   Attach the command sequencer output filter, the
         *   language-specific message parameter substitution filter, the
         *   style tag formatter filter, and the paragraph filter to the
         *   main output stream.  Stack them so that the paragraph manager
         *   is at the bottom, since the library tag filter can produce
         *   paragraph tags and thus needs to sit atop the paragraph
         *   filter.  Put the command sequencer above those, since it
         *   might need to write style tags.  Finally, put the sense
         *   context filter on top of those.  
         */
        mainOutputStream.addOutputFilter(typographicalOutputFilter);
        mainOutputStream.addOutputFilter(mainParagraphManager);
        mainOutputStream.addOutputFilter(styleTagFilter);        
        mainOutputStream.addOutputFilter(cquoteOutputFilter);

        mainOutputStream.addOutputFilter(commandSequencer);

        /* 
         *   Attach our message parameter filter and style tag filter to
         *   the status line streams.  We don't need most of the main
         *   window's filters in the status line.  
         */
        statusTagOutputStream.addOutputFilter(styleTagFilter);


        statusLeftOutputStream.addOutputFilter(styleTagFilter);
        statusLeftOutputStream.addOutputFilter(cquoteOutputFilter);
        statusRightOutputStream.addOutputFilter(styleTagFilter);

    }


;
//
/* ------------------------------------------------------------------------ */
/*
 *   Library Initializer.  This object performs the following
 *   initialization operations each time the game is started:
 *   
 *   - sets up the library's default output function 
 */
adv3LibInit: InitObject
    execute()
    {
        /* 
         *   Set up our default output function.  Note that we must do
         *   this during run-time initialization each time we start the
         *   game, rather than during pre-initialization, because the
         *   default output function state is not part of the load-image
         *   configuration. 
         */
        t3SetSay(say);
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   Generic script object.  This class can be used to implement a simple state
 *   machine.
 *
 *   We define Script in misc.t rather than eventList.t so that other parts of
 *   the library can safely test whether something is ofKind(Script) even it
 *   eventList.t is not present. The various types and subclasses of script are
 *   defined in eventList.t to allow them to be optionally excluded from the
 *   build if they're not needed in a particular game.
 */
class Script: object
    /* 
     *   Get the current state.  This returns a value that gives the
     *   current state of the script, which is usually simply an integer.  
     */
    getScriptState()
    {
        /* by default, return our state property */
        return curScriptState;
    }

    /*
     *   Process the next step of the script.  This routine must be
     *   overridden to perform the action of the script.  This routine's
     *   action should call getScriptState() to get our current state, and
     *   should update the internal state appropriately to take us to the
     *   next step after the current one.
     *   
     *   By default, we don't do anything at all.  
     */
    doScript()
    {
        /* override to carry out the script */
    }

    /* 
     *   Property giving our current state.  This should never be used
     *   directly; instead, getScriptState() should always be used, since
     *   getScriptState() can be overridden so that the state depends on
     *   something other than this internal state property. The meaning of
     *   the state identifier is specific to each subclass.  
     */
    curScriptState = 0
;
/* ------------------------------------------------------------------------ */
/*
 *   Library global variables 
 */
libGlobal: object
   
    /*
     *   The current library messages object.  This is the source object
     *   for messages that don't logically relate to the actor carrying out
     *   the comamand.  It's mostly used for meta-command replies, and for
     *   text fragments that are used to construct descriptions.
     *   
     *   This message object isn't generally used for parser messages or
     *   action replies - most of those come from the objects given by the
     *   current actor's getParserMessageObj() or getActionMessageObj(),
     *   respectively.
     *   
     *   By default, this is set to libMessages.  The library never changes
     *   this itself, but a game can change this if it wants to switch to a
     *   new set of messages during a game.  (If you don't need to change
     *   messages during a game, but simply want to customize some of the
     *   default messages, you don't need to set this variable - you can
     *   simply use 'modify libMessages' instead.  This variable is
     *   designed for cases where you want to *dynamically* change the
     *   standard messages during the game.)  
     */
    libMessageObj = libMessages    
   
    /*
     *   The current player character 
     */
    playerChar = nil   

    /*   The name of the current player character */
    playerCharName = nil
    
    /* 
     *   The global score object.  We use a global for this, rather than
     *   referencing libScore directly, to allow the score module to be
     *   left out entirely if the game doesn't make use of scoring.  The
     *   score module should set this during pre-initialization.  
     */
    scoreObj = nil

    /* 
     *   The global Footnote class object.  We use a global for this,
     *   rather than referencing Footnote directly, to allow the footnote
     *   module to be left out entirely if the game doesn't make use of
     *   footnotes.  The footnote class should set this during
     *   pre-initialization.  
     */
    footnoteClass = nil

    /* the total number of turns so far */
    totalTurns = 0

    /* 
     *   flag: the parser is in 'debug' mode, in which it displays the
     *   parse tree for each command entered 
     */
    parserDebugMode = nil

    /*
     *   Most recent command, for 'undo' purposes.  This is the last
     *   command the player character performed, or the last initial
     *   command a player directed to an NPC.
     *   
     *   Note that if the player directed a series of commands to an NPC
     *   with a single command line, only the first command on such a
     *   command line is retained here, because it is only the first such
     *   command that counts as a player's turn in terms of the game
     *   clock.  Subsequent commands are executed by the NPC's on the
     *   NPC's own time, and do not count against the PC's game clock
     *   time.  The first command counts against the PC's clock because of
     *   the time it takes the PC to give the command to the NPC.  
     */
    lastCommandForUndo = ''

    /* 
     *   Most recent target actor phrase; this goes with
     *   lastCommandForUndo.  This is nil if the last command did not
     *   specify an actor (i.e., was implicitly for the player character),
     *   otherwise is the string the player typed specifying a target
     *   actor.  
     */
    lastActorForUndo = ''
    
    /*   The text of the last command to be repeated by Again */    
    lastCommandForAgain = ''

    /*
     *   Current command information.  We keep track of the current
     *   command's actor and action here.  
     */
    curActor = nil
    curIssuingActor = nil
    curAction = nil
    
    /* The current Command object */
    curCommand = nil

    /* The last action to be performed. */
    lastAction = nil
    
    /* The previous Command object */
    lastCommand = nil
    
    /* the exitLister object, if included in the build */
    exitListerObj = nil

    /* the hint manager, if included in the build */
    hintManagerObj = nil
    
    /* the extra hint manager, if included in the build */
    extraHintManagerObj = nil

    /*
     *   The game's IFID, as defined in the game's main module ID object.
     *   If the game has multiple IFIDs in the module list, this will store
     *   only the first IFID in the list.  NOTE: the library initializes
     *   this automatically during preinit; don't set this manually.  
     */
    IFID = nil

    /*
     *   Command line arguments.  The library sets this to a list of
     *   strings containing the arguments passed to the program on the
     *   command line.  This list contains the command line arguments
     *   parsed according to the local conventions for the operating system
     *   and C++ library.  The standard parsing procedure used by most
     *   systems is to break the line into tokens delimited by space
     *   characters.  Many systems also allow space characters to be
     *   embedded in tokens by quoting the tokens.  The first argument is
     *   always the name of the .t3 file currently executing.  
     */
    commandLineArgs = []

    /*
     *   Retrieve a "switch" from the command line.  Switches are options
     *   specifies with the conventional Unix "-xxx" notation.  This
     *   searches for a command option that equals the given string or
     *   starts with the given substring.  If we find it, we return the
     *   part of the option after the given substring - this is
     *   conventionally the value of the switch.  For example, the command
     *   line might look like this:
     *   
     *.    t3run mygame.t3 -name=MyGame -user=Bob
     *   
     *   Searching for '-name=' would return 'MyGame', and searching for
     *   '-user=' would return' Bob'.
     *   
     *   If the switch is found but has no value attached, the return value
     *   is an empty string.  If the switch isn't found at all, the return
     *   value is nil.  
     */
    getCommandSwitch(s)
    {
        /* search from argument 2 to the last switch argument */
        local args = commandLineArgs;
        for (local i in 2..args.length())
        {
            /* 
             *   if this isn't a switch, or is the special "-" last switch
             *   marker, we're done
             */
            local a = args[i];
            if (!a.startsWith('-') || a == '-')
                return nil;

            /* check for a match */
            if (a.startsWith(s))
                return a.substr(s.length() + 1);
        }

        /* didn't find it */
        return nil;
    }

    /* 
     *   The last location visited by the player char before a travel action.
     *   Noted to allow travel back.
     */    
    lastLoc = nil
    
   
    /* 
     *   A lookup table to store information about the destinations of direction
     *   properties not connected to objects (i.e. direction properties defined
     *   as strings or methods
     */    
    extraDestInfo = static [ * -> unknownDest_ ]

    /* 
     *   Add an item to the extraDestInfo table keyed on the source room plus
     *   the direction taken, with the value being the destination arrived at
     *   (which most of the time will probably be the same as the source, since
     *   in most cases where we create one of these records, no travel will have
     *   taken place.
     */    
    addExtraDestInfo(source, dirn, dest)
    {
        if(extraDestInfo == nil)
            extraDestInfo = [ * -> unknownDest_ ];
        
        /* 
         *   Record the extra dest info in the extraDestInfo table unless it's
         *   already set to nil, which is a signal that we don't want the
         *   pathfinder or other code to use this information.
         */
        
        if(extraDestInfo[[source, dirn]] not in (nil, varDest_))
           extraDestInfo[[source, dirn]] = dest;
            
    }
    
    /*
     *   Mark a tag as revealed.  This adds an entry for the tag to the
     *   revealedNameTab table.  We simply set the table entry to 'true'; the
     *   presence of the tag in the table constitutes the indication that the
     *   tag has been revealed.
     *
     *   (Games and library extensions can use 'modify' to override this and
     *   store more information in the table entry.  For example, you could
     *   store the time when the information was first revealed, or the location
     *   where it was learned.  If you do override this, just be sure to set the
     *   revealedNameTab entry for the tag to a non-nil and non-zero value, so
     *   that any code testing the presence of the table entry will see that the
     *   slot is indeed set.)
     *
     *   We put the revealedNameTab table and the setRevealed method here rather
     *   than on conversationManager so that it's available to games that don't
     *   include actor.t.
     */
    setRevealed(tag)
    {
        revealedNameTab[tag] = true;
    }

    /* 
     *   The global lookup table of all revealed keys.  This table is keyed
     *   by the string naming the revelation; the value associated with
     *   each key is not used (we always just set it to true).  
     */
    revealedNameTab = static new LookupTable(32, 32)
    
    /*  
     *   The symbol table for every game object.
     */    
    objectNameTab = nil
 
    /* The thought manager object, if it exists. */    
    thoughtManagerObj = nil
    
    /* The object last written on */
    lastWrittenOnObj = nil
       
    /* The object last typed on */
    lastTypedOnObj = nil
    
    /* 
     *   our name table for parameter substitutions - a LookupTable that we set
     *   up during preinit
     */
    nameTable_ = static new LookupTable()  
    
;



/* object representing an unknown destination */
unknownDest_: Room 'unknown'
;


/* object representing a variable destination */
varDest_: Room 'unknown'
;

/* ------------------------------------------------------------------------ */
/*
 *   FinishType objects are used in finishGameMsg() to indicate what kind
 *   of game-over message to display.  We provide a couple of standard
 *   objects for the most common cases. 
 */
class FinishType: object
    /* the finishing message, as a string or library message property */
    finishMsg = nil
;

/* 'death' - the game has ended due to the player character's demise */
ftDeath: FinishType finishMsg = BMsg(finish death, 'YOU HAVE DIED');

/* 'victory' - the player has won the game */
ftVictory: FinishType finishMsg = BMsg(finish victory,'YOU HAVE WON');

/* 'failure' - the game has ended in failure (but not necessarily death) */
ftFailure: FinishType finishMsg = BMsg(finish failure, 'YOU HAVE FAILED');

/* 'game over' - the game has simply ended */
ftGameOver: FinishType finishMsg = BMsg(finish game over, 'GAME OVER');

/*
 *   Finish the game, showing a message explaining why the game has ended.
 *   This can be called when an event occurs that ends the game, such as
 *   the player character's death, winning, or any other endpoint in the
 *   story.
 *   
 *   We'll show a message defined by 'msg', using a standard format.  The
 *   format depends on the language, but in English, it's usually the
 *   message surrounded by asterisks: "*** You have won! ***".  'msg' can
 *   be:
 *   
 *.    - nil, in which case we display nothing
 *.    - a string, which we'll display as the message
 *.    - a FinishType object, from which we'll get the message
 *   
 *   After showing the message (if any), we'll prompt the user with
 *   options for how to proceed.  We'll always show the QUIT, RESTART, and
 *   RESTORE options; other options can be offered by listing one or more
 *   FinishOption objects in the 'extra' parameter, which is given as a
 *   list of FinishOption objects.  The library defines a few non-default
 *   finish options, such as finishOptionUndo and finishOptionCredits; in
 *   addition, the game can subclass FinishOption to create its own custom
 *   options, as desired.  
 */
finishGameMsg(msg, extra)
{
    local lst;

    
    /*
     *   Explicitly run any final score notification now.  This will ensure
     *   that any points awarded in the course of the final command that
     *   brought us to this point will generate the usual notification, and
     *   that the notification will appear at a reasonable place, just
     *   before the termination message. 
     */
    if (libGlobal.scoreObj != nil)
    {
        "<.p>";
        libGlobal.scoreObj.runScoreNotifier();
    }

    /* translate the message, if specified */
    if (dataType(msg) == TypeObject)
    {
        /* it's a FinishType object - get its message property or string */
        msg = msg.finishMsg;

        /* if it's a library message property, look it up */
        if (dataType(msg) == TypeProp)
            msg = gLibMessages.(msg);
    }

    /* if we have a message, display it */
    if (msg != nil)
        DMsg(show finish msg, '\b*** {1} ***\b\b', msg);
        

    /* if the extra options include a scoring option, show the score */
    if (extra != nil && extra.indexWhich({x: x.showScoreInFinish}) != nil)
    {
        "<.p>";
        libGlobal.scoreObj.showScore();
        "<.p>";
    }
    gActor = gPlayerChar;

    /* start with the standard options */
    lst = [finishOptionRestore, finishOptionRestart];

    /* add any additional options in the 'extra' parameter */
    if (extra != nil)
        lst += extra;

    /* always add 'quit' as the last option */
    lst += finishOptionQuit;

    /* process the options */
    processOptions(lst);
}

/* finish the game, offering the given extra options but no message */
finishGame(extra)
{
    finishGameMsg(nil, extra);
}

/*
 *   Show failed startup restore options.  If a restore operation fails at
 *   startup, we won't just proceed with the game, but ask the user what
 *   they want to do; we'll offer the options of restoring another game,
 *   quitting, or starting the game from the beginning.  
 */
failedRestoreOptions()
{
    /* process our set of options */
    processOptions([restoreOptionRestoreAnother, restoreOptionStartOver,
                    finishOptionQuit]);
}

/*
 *   Process a list of finishing options.  We'll loop, showing prompts and
 *   reading responses, until we get a response that terminates the loop.  
 */
processOptions(lst)
{
    /* keep going until we get a valid response */
promptLoop:
    for (;;)
    {
        local resp;
        
        /* show the options */
        finishOptionsLister.show(lst, 0);

        /* 
         *   update the status line, in case the score or turn counter has
         *   changed (this is especially likely when we first enter this
         *   loop, since we might have just finished the game with our
         *   previous action, and that action might well have awarded us
         *   some points) 
         */
        statusLine.showStatusLine();

        /* read a response */       
        ">";
        resp = inputManager.getInputLine();


        /* check for a match to each of the options in our list */
        foreach (local cur in lst)
        {
            /* if this one matches, process the option */
            if (cur.responseMatches(resp))
            {
                /* it matches - carry out the option */
                if (cur.doOption())
                {
                    /* 
                     *   they returned true - they want to continue asking
                     *   for more options
                     */
                    continue promptLoop;
                }
                else
                {
                    /* 
                     *   they returned nil - they want us to stop asking
                     *   for options and return to our caller 
                     */
                    return;
                }
            }
        }

        /*
         *   If we got this far, it means that we didn't get a valid
         *   option.  Display our "invalid option" message, and continue
         *   looping so that we show the prompt again and read a new
         *   option.  
         */       
        DMsg(invalid finish option, '<q>{1}</q> was not one of the
            options.<.p>', resp);
    }
}

/*
 *   Finish Option class.  This is the base class for the abstract objects
 *   representing options offered by finishGame.  
 */
class FinishOption: object
    /* 
     *   The description, as displayed in the list of options.  For the
     *   default English messages, this is expected to be a verb phrase in
     *   infinitive form, and should show the keyword accepted as a
     *   response in all capitals: "RESTART", "see some AMUSING things to
     *   do", "show CREDITS". 
     */
    desc = ""

    /* 
     *   By default, the item is listed.  If you want to create an
     *   invisible option that's accepted but which isn't listed in the
     *   prompt, just set this to nil.  Invisible options are sometimes
     *   useful when the output of one option mentions another option; for
     *   example, the CREDITS message might mention a LICENSE command for
     *   displaying the license, so you want to make that command available
     *   without cluttering the prompt with it.  
     */
    listed = true

    /* our response keyword */
    responseKeyword = ''

    /* 
     *   a single character we accept as an alternative to our full
     *   response keyword, or nil if we don't accept a single-character
     *   response 
     */
    responseChar = nil
    
    /* 
     *   Match a response string to this option.  Returns true if the
     *   string matches our response, nil otherwise.  By default, we'll
     *   return true if the string exactly matches responseKeyword or
     *   exactly matches our responseChar (if that's non-nil), but this
     *   can be overridden to match other strings if desired.  By default,
     *   we'll match the response without regard to case.
     */
    responseMatches(response)
    {
        /* do all of our work in lower-case */
        response = response.toLower();

        /* 
         *   check for a match the full response keyword or to the single
         *   response character 
         */
        return (response == responseKeyword.toLower()
                || (responseChar != nil
                    && response == responseChar.toLower()));
    }

    /*
     *   Carry out the option.  This is called when the player enters a
     *   response that matches this option.  This routine must perform the
     *   action of the option, then return true to indicate that we should
     *   ask for another option, or nil to indicate that the finishGame()
     *   routine should simply return.  
     */
    doOption()
    {
        /* tell finishGame() to ask for another option */
        return true;
    }

    /* 
     *   Flag: show the score with the end-of-game announcement.  If any
     *   option in the list of finishing options has this flag set, we'll
     *   show the score using the same message that the SCORE command
     *   uses. 
     */
    showScoreInFinish = nil
;

/*
 *   QUIT option for finishGame.  The language-specific code should modify
 *   this to specify the description and response keywords.  
 */
finishOptionQuit: FinishOption
    doOption()
    {
        /* 
         *   carry out the Quit action - this will signal a
         *   QuittingException, so this call will never return 
         */
        throw new QuittingException;
    }
    listOrder = 100
    
;

/*
 *   RESTORE option for finishGame. 
 */
finishOptionRestore: FinishOption
    doOption()
    {
        /* 
         *   Try restoring.  If this succeeds (i.e., it returns true), tell
         *   the caller to stop looping and to proceed with the game by
         *   returning nil.  If this fails, tell the caller to keep looping
         *   by returning true.
         */
        if (Restore.askAndRestore())
        {
            /* 
             *   we succeeded, so we're now restored to some prior game
             *   state - terminate any remaining processing in the command
             *   that triggered the end-of-game options
             */

            abort;
        }
        else
        {
            /* it failed - tell the caller to keep looping */
            return true;
        }
    }
    
    listOrder = 90
;

/*
 *   RESTART option for finishGame 
 */
finishOptionRestart: FinishOption
    doOption()
    {
        /* 
         *   carry out the restart - this will not return, since we'll
         *   reset the game state and re-enter the game at the restart
         *   entrypoint 
         */
        Restart.doRestartGame();
    }
    
   listOrder = 10
;

/*
 *   START FROM BEGINNING option for failed startup restore.  This is just
 *   like finishOptionRestart, but shows a different option name.  
 */
restoreOptionStartOver: finishOptionRestart
;

/* 
 *   RESTORE ANOTHER GAME option for failed startup restore.  This is just
 *   like finishOptionRestore, but shows a different option name. 
 */
restoreOptionRestoreAnother: finishOptionRestore
;

/*
 *   UNDO option for finishGame 
 */
finishOptionUndo: FinishOption
    doOption()
    {
        /* try performing the undo */
        if (Undo.execAction(nil))
        {
            
            
            gPlayerChar.outermostVisibleParent().lookAroundWithin();
            
            
            /* 
             *   Success - terminate the current command with no further
             *   processing.
             */
            throw new TerminateCommandException();
        }
        else
        {
            /* 
             *   failure - show a blank line and tell the caller to ask
             *   for another option, since we couldn't carry out this
             *   option 
             */
            "<.p>";
            return true;
        }
    }
    listOrder = 20
;

/*
 *   FULL SCORE option for finishGame
 */
finishOptionFullScore: FinishOption
    doOption()
    {
        /* show a blank line before the score display */
        "\b";

        /* run the Full Score action */
        FullScore.showFullScore();

        /* show a paragraph break after the score display */
        "<.p>";

        /* 
         *   this option has now had its full effect, so tell the caller
         *   to go back and ask for a new option 
         */
        return true;
    }

    /* 
     *   by default, show the score with the end-of-game announcement when
     *   this option is included 
     */
    showScoreInFinish = true
    listOrder = 30
   
;

/*
 *   Option to show the score in finishGame.  This doesn't create a listed
 *   option in the set of offered options, but rather is simply a flag to
 *   finishGame() that the score should be announced along with the
 *   end-of-game announcement message. 
 */
finishOptionScore: FinishOption
    /* show the score in the end-of-game announcement */
    showScoreInFinish = true

    /* this is not a listed option */
    listed = nil

    /* this option isn't selectable, so it has no effect */
    doOption() { }
    
    listOrder = 40
;

/*
 *   CREDITS option for finishGame 
 */
finishOptionCredits: FinishOption
    doOption()
    {
        /* show a blank line before the credits */
        "\b";

        /* run the Credits action */
        versionInfo.showCredit();

        /* show a paragraph break after the credits */
        "<.p>";

        /* 
         *   this option has now had its full effect, so tell the caller
         *   to go back and ask for a new option 
         */
        return true;
    }
    
    listOrder = 50
;  

/*
 *   AMUSING option for finishGame 
 */
finishOptionAmusing: FinishOption
    /*
     *   The game must modify this object to define a doOption method.  We
     *   have no built-in way to show a list of amusing things to try, so
     *   if a game wants to offer this option, it must provide a suitable
     *   definition here.  (We never offer this option by default, so a
     *   game need not provide a definition if the game doesn't explicitly
     *   offer this option via the 'extra' argument to finishGame()).  
     */
   listOrder = 60
;


/* -------------------------------------------------------------------------- */
/*
 *   Utility functions 
 */

/* 
 *   Try converting val to an integer. If this results in an integer value,
 *   return it, otherwise return nil.
 */

tryInt(val)
{
    /* 
     *   If the value passed to the function is neither an integer nor a string
     *   nor a BigNumber, return nil, since there can be no valid integer
     *   representation of it.
     */    
    if(dataType(val) not in (TypeInt, TypeSString, TypeObject)
       || (dataType(val) == TypeObject && !(val.ofKind(BigNumber))))
        return nil;
    
    /* Try converting val to an integer. */
    local res = toInteger(val);
   
    /*   
     *   If val is a string then res is a valid number if val is a string that
     *   contains one or more zeroes perhaps preceded by + or -.
     */
    
    if(dataType(val) == TypeSString)    
    {
        /* 
         *   Strip out all the spaces from val.         
         */
        val = val.findReplace(' ', '').trim();
        
        if(val.match(R'(<plus>|-)?<digit>+$'))
            return res;       
        
    }
    
       
    /* 
     *   If val is a BigNumber or an integer, this is also a valid result, so
     *   return it. Note that we need only test for whether val is an object,
     *   since if it was any other kind of object than a BigNumber, this
     *   function would have returned nil at the first test.
     */     
    if(dataType(val) is in (TypeInt, TypeObject))
        return res;
    
   
    
    /* 
     *   We can't find a valid interpretation of val as a number, so return nil.
     */
    return nil;
}

/* 
 *   Try converting val to a number (integer or BigNumber); return the number if
 *   there is one, otherwise return nil.
 */
tryNum(val)
{
     /* 
     *   If the value passed to the function is neither an integer nor a string
     *   nor a BigNumber, return nil, since there can be no valid numerical
     *   representation of it.
     */    
    if(dataType(val) not in (TypeInt, TypeSString, TypeObject)
       || (dataType(val) == TypeObject && !val.ofKind(BigNumber)))
        return nil;
    
    /* If val is already a BigNumber, return it unchanged. */
    if(dataType(val) == TypeObject && val.ofKind(BigNumber))
        return val;
    
   

    /*  
     *   If val is a string then test whether it matches a valid numerical
     *   pattern.
     */
    if(dataType(val) == TypeSString)
    {
        val = stripQuotesFrom(val.findReplace(' ',''));
        
        /* Try converting val to a number */
        local res = toNumber(val);
        
        if(val.match(R'(<plus>|-)?<digit>+$'))
            return res;
        
        if(val.match(R'(<plus>|-)?<digit>*<dot><digit>+$'))
            return res;
        
        if(val.match(R'(<plus>|-)?<digit>+(<dot><digit>+)?[eE]<digit>?+$'))
            return res;
    }
    

    /* Otherwise use the tryInt() function to return the result */
    return tryInt(val);
}





/*
 *   nilToList - convert a 'nil' value to an empty list.  This can be
 *   useful for mix-in classes that will be used in different inheritance
 *   contexts, since the classes might or might not inherit a base class
 *   definition for list-valued methods such as preconditions.  This
 *   provides a usable default for list-valued methods that return nothing
 *   from superclasses. 
 */
nilToList(val)
{
    return (val != nil ? val : []);
}

/*      
 *   val to list - convert any value to a list. If it's already a list, simply
 *   return it. If it's nil return an empty list. If it's a singleton value,
 *   return a one-element list containing it.
 */
valToList(val)
{
    switch (dataType(val))
    {
    case TypeNil:
        return [];
    case TypeList:
        return val;
    case TypeObject:
        if(val.ofKind(Vector))
            return val.toList;
        else
            return [val];
    default:
        return [val];
    }
}

/*  
 *   Set the mentioned property of obj to true. If obj is supplied as a list,
 *   set every object's mentioned property in the list to true. This can be used
 *   in room and object descriptions to mark an object as mentioned so it won't
 *   be included in the listing.
 */
makeMentioned(obj)
{
    foreach(local cur in valToList(obj))
        cur.mentioned = true;
}


/* 
 *   partitionList - partition a list into a pair of two lists, the first
 *   containing items that match the predicate 'fn', the second containing
 *   items that don't match 'fn'.  'fn' is a function pointer (usually an
 *   anonymous function) that takes a single argument - a list element -
 *   and returns true or nil.
 *   
 *   The return value is a list with two elements.  The first element is a
 *   list giving the elements of the original list for which 'fn' returns
 *   true, the second element is a list giving the elements for which 'fn'
 *   returns nil.
 *   
 *   (Contributed by Tommy Nordgren.)  
 */
partitionList(lst, fn)
{
    local lst1 = lst.subset(fn);
    local lst2 = lst.subset({x : !fn(x)});
    
    return [lst1, lst2];
}

/*
 *   Determine if list a is a subset of list b.  a is a subset of b if
 *   every element of a is in b.  
 */
isListSubset(a, b)
{
    /* a can't be a subset if it has more elements than b */
    if (a.length() > b.length())
        return nil;
    
    /* check each element of a to see if it's also in b */
    foreach (local cur in a)
    {
        /* if this element of a is not in b, a is not a subset of b */
        if (b.indexOf(cur) == nil)
            return nil;
    }

    /* 
     *   we didn't find any elements of a that are not also in b, so a is a
     *   subset of b 
     */
    return true;
}


/* 
 *   Find an existing Topic whose vocab is voc. If the cls parameter
 *   is supplied it can be used to find a match in some other class, such as
 *   Thing or Mentionable.
 */
findMatchingTopic(voc, cls = Topic)
{
    for(local cur = firstObj(cls); cur != nil; cur = nextObj(cur, cls))
    {
        if(cur.vocab == voc)
            return cur;
    }
    
    return nil;
}

/* 
 *   Set the player character to another actor. If the optional second parameter
 *   is supplied, it sets the person of the player character; otherwise it
 *   defaults to the second person.
 */
setPlayer(actor, person = 2)
{    
    /* Note the old player character */
    local other = gPlayerChar;
    
    /* Note the name of the actor the pc is about to become */
    local newName = actor.theName;
    
    /* Change the player character to actor */
    gPlayerChar = actor;
    
    /* Change the player character person to person. */
    gPlayerChar.person = person;
    
    /* Change the person of the previous player character to 3 */
    other.person = 3;
    
    /* 
     *   Change the names of both actors involved in the swap to nil, so that
     *   they can be reinitialized.
     */
    other.name = nil;
    gPlayerChar.name = nil;
    
    /*   
     *   Reinitialize the names of both actors, so that the player character can
     *   become 'I' or 'You' as appropriate, and the previous PC acquires
     *   his/her third-person name.
     */
    other.initVocab();
    gPlayerChar.initVocab();
    
    /*   Note the name (e.g. 'Bob' or 'Mary') of the new player character */
    libGlobal.playerCharName = newName;
    
    /*   Make the current actor the new player character */
    gActor = gPlayerChar;
    gCommand.actor = gPlayerChar;
    
    /* Return the (third-person) name of the new player character */
    return newName;
}

/* ------------------------------------------------------------------------ */
/*
 *   Add some methods to the base Object that make it *somewhat*
 *   interchangeable with lists and vectors.  Certain operations that are
 *   normally specific to the collection types have obvious degenerations
 *   for the singleton case.  In particular, a singleton can be thought of
 *   as a collection consisting of one value, so operations that iterate
 *   over a collection degenerate to one iteration on a singleton.  
 */
modify Object
    /* mapAll for an object simply applies a function to the object */
    mapAll(func)
    {
        return func(self);
    }

    /* forEach on an object simply calls the function on the object */
    forEach(func)
    {
        return func(self);
    }

    /* create an iterator */
    createIterator()
    {
        return new SingletonIterator(self);
    }

    /* 
     *   create a live iterator (this allows 'foreach' to be used with an
     *   arbitrary object, iterating once over the loop with the object
     *   value) 
     */
    createLiveIterator()
    {
        return new SingletonIterator(self);
    }

    /*
     *   Call an inherited method directly.  This has the same effect that
     *   calling 'inherited cl.prop' would from within a method, but allows
     *   you to do this from an arbitrary point *outside* of the object's
     *   own code.  I.e., you can say 'obj.callInherited(cl, &prop)' and
     *   get the effect that 'inherited c.prop' would have had from within
     *   an 'obj' method.  
     */
    callInherited(cl, prop, [args])
    {
        delegated cl.(prop)(args...);
    }
;

/*
 *   A SingletonIterator is an implementation of the Iterator interface for
 *   singleton values.  This allows 'foreach' to be used with arbitrary
 *   objects, or even primitive values.  The effect of iterating over a
 *   singleton value with 'foreach' using this iterator is simply to invoke
 *   the loop once with the loop variable set to the singleton value.  
 */
class SingletonIterator: object
    /* construction: save the singleton value that we're "iterating" over */
    construct(val) { val_ = val; }

    /* get the next value */
    getNext()
    {
        /* note that we've consumed the value */
        more_ = nil;

        /* return the value */
        return val_;
    }

    /* is another item available? */
    isNextAvailable() { return more_; }

    /* reset: restore the flag that says the value is available */
    resetIterator() { more_ = true; }

    /* get the current key; we have no keys, so use a fake key of nil */
    getKey() { return nil; }

    /* get the current value */
    getCurVal() { return val_; }
    
    /* the singleton value we're "iterating" over */
    val_ = nil
    
    /* do we have any more values to fetch? */
    more_ = true
;

/*
 *   Add some convenience methods to String. 
 */
modify String
    /*
     *   Trim spaces.  Removes leading and trailing spaces from the string.
     */
    trim()
    {
        return findReplace(trimPat, '');
    }

    /* regular expression for trimming leading and trailing spaces */
    trimPat = R'^<space>+|<space>+$'

    /* get the first character */
    firstChar() { return substr(1, 1); }

    /* get the last character */
    lastChar() { return substr(length()); }

    /* remove the first character */
    delFirst() { return substr(2); }

    /* remove the last character */
    delLast() { return substr(1, length() - 1); }

    /* leftmost n characters; if n is negative, leftmost (length-n) */
    left(n) { return n >= 0 ? substr(1, n) : substr(1, length() + n); }

    /* rightmost n characters; if n is negative, rightmost (length-n) */
    right(n) { return n >= 0 ? substr(-n) : substr(n + length()); }    
    ;

/* A string is empty if it's nil or if when trimmed it's '' */
isEmptyStr(str) {  return (str == nil || str.trim() == ''); }


/*
 *   Add a couple of handy utility functions to Vector 
 */
modify Vector
    /* is the vector empty? */
    isEmpty() { return length() == 0; }

    /* clear the vector */
    clear() 
    {
        if (length() > 0)
            removeRange(1, length()); 
    }

    /* get the "top" item, treating the vector as a stack */
    getTop() { return self[length()]; }

    /* push a value (append it to the end of the vector) */
    push(val) { append(val); }

    /* pop a value (remove and return the value at the end of the vector) */
    pop()
    {
        local l = length();
        if (l > 0)
        {
            /* get the last value */
            local ret = self[l];

            /* remove the element */
            removeElementAt(l);

            /* return it */
            return ret;
        }
        else
        {
            /* intentionally cause an out-of-bounds error */
            return self[1];
        }
    }

    /* unshift a value (insert it at the start of the Vector) */
    unshift(val) { prepend(val); }

    /* shift a value (remove and return the first value) */
    shift()
    {
        local l = length();
        if (l > 0)
        {
            /* get the first value */
            local ret = self[1];

            /* remove the element */
            removeElementAt(1);

            /* return it */
            return ret;
        }
        else
        {
            /* intentionally cause an out-of-bounds error */
            return self[1];
        }
    }

    /*
     *   Perform a "group sort" on the vector.  This sorts the items into
     *   groups, then sorts by an ordering value within each group.
     *   
     *   The groups are determined by group keys, which are arbitrary
     *   values.  Each group is simply the set of objects with a like value
     *   for the key.  Within the group, we sort by an integer ordering
     *   key.
     *   
     *   'func' is a function that takes two parameters: func(entry, idx),
     *   where 'entry' is a list element and 'idx' is an index in the list.
     *   This returns a list, [group, order], giving the group key and
     *   ordering key for the entry.  
     */
    groupSort(func)
    {
        /* note our length */
        local len = length();

        /* 
         *   set up a lookup table for the group keys - we want to assign
         *   each one an arbitrary integer value so that we can sort by it 
         */
        local groups = new LookupTable(16, 32);
        local gnxt = 1;
        
        /* decorate each entry with its group index and ordering key */
        for (local i = 1 ; i <= len ; ++i)
        {
            /* get this element */
            local ele = self[i];

            /* get the group info via the callback */
            local info = func(ele, i);

            /* look up or assign this group key's number */
            local gnum = groups[info[1]];
            if (gnum == nil)
                groups[info[1]] = gnum = gnxt++;

            /* store the group number and sorting order in the list */
            self[i] = [gnum, info[2], ele];
        }

        /* do the sort */
        sort(SortAsc, new function(a, b) {
            /* 
             *   if the groups are the same, sort by the order within the
             *   group; otherwise sort by the group number 
             */
            if (a[1] == b[1])
                return a[2] - b[2];
            else
                return a[1] - b[1];
        });

        /* remove the extra information from the list */
        for (local i = 1 ; i <= len ; ++i)
            self[i] = self[i][3];
    }

    /* find a list element - synonym for indexOf */
    find(ele) { return indexOf(ele); }

    /* shuffle the elements of the vector into a random order */
    shuffle()
    {
        /*
         *   The basic algorithm for shuffling is that we put all of the
         *   elements into a bag, and one by one we withdraw an element at
         *   random and add it to the result list.  To withdraw a random
         *   element, we simply pick a random number from 1 to the number
         *   of items left in the bag.
         *   
         *   With a vector, we can do this without allocating any more
         *   memory.  We partition the vector into two parts: the "result"
         *   part and the "bag" part.  Initially, the whole vector is the
         *   bag, and the result part is empty.  We next pick a random
         *   element from the bag, and swap it with element #N.  This
         *   effectively deletes the chosen element from the bag and fills
         *   in the hole with the bag element that was formerly at slot #N.
         *   (If we chose the element at slot #N, that's fine - it just
         *   stays put.)  Slot #N is now part of the result set, and the
         *   bag is now slots #1 to #N-1.  We next pick a random element
         *   from the bag - 1..N-1 - and swap it with slot #N-1.  Now slot
         *   #N-1 is in the result set, and the bag is from #1 to #N-2.
         *   Repeat until we've chosen slot 2.  (We don't have to
         *   explicitly pick anything for slot 1, since at that point we're
         *   down to a single element in the bag, and it's already at the
         *   proper position to just redefine it as a result.)  
         */
        for (local len = length(), local n = len ; n > 1 ; --n)
        {
            /* the bag is slots 1..n - pick a random element in that range */
            local r = rand(n) + 1;

            /* swap the random element with element #n */
            local val = self[r];
            self[r] = self[n];
            self[n] = val;
        }

        /* in case the caller wants the shuffled object, return self */
        return self;
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   Add some utility methods to List. 
 */
modify List
    /*
     *   Check the list against a prototype (a list of data types).  This
     *   is useful for checking a varargs list to see if it matches a given
     *   prototype.  Each prototype element can be a TypeXxx type code, to
     *   match a value of the given native type; an object class, to match
     *   an instance of that class; 'any', to match a value of any type; or
     *   the special value '...', to match zero or more additional
     *   arguments.  If '...' is present, it must be the last prototype
     *   element.  
     */
    matchProto(proto)
    {
        /* compare each value against the prototype */
        local plen = proto.length(), vlen = length();
        for (local i = 1 ; i <= plen ; ++i)
        {
            /* get this prototype element (i.e., a type code) */
            local t = proto[i];

            /* if this is a varargs indicator, we have a match */
            if (t == '...')
                return true;

            /* if we're past the end of the values, it's no match */
            if (i > vlen)
                return nil;

            /* get the value */
            local v = self[i];

            /* check the type */
            if (t == 'any')
            {
                /* 'any' matches any value, so this one is a match */
            }
            else if (dataType(t) == TypeInt)
            {
                /* check that we match the given native type */
                if (dataTypeXlat(v) != t)
                    return nil;
            }
            else
            {
                /* otherwise, we have to match the object class */
                if (dataType(v) not in (TypeObject, TypeList, TypeSString)
                    || !v.ofKind(t))
                    return nil;
            }
        }

        /* 
         *   We reached the end of the prototype without finding a
         *   mismatch.  The only remaining check is that we don't have any
         *   extra arguments in the value list.  As long as the lengths
         *   match, we have a match. 
         */
        return plen == vlen;
    }

    /* toList() on a list simply returns the same list */
    toList() { return self; }

    /* find a list element - synonym for indexOf */
    find(ele) { return indexOf(ele); }

    /* 
     *   shuffle the list: return a new list with the elements of this list
     *   rearranged into a random order 
     */
    shuffle()
    {
        /* 
         *   Since a list is immutable, we can't shuffle the elements in
         *   place, which means we have to construct a new list.  One way
         *   would be to use the Vector.shuffle algorithm, appending each
         *   element chosen from the bag to a new result list under
         *   construction.  That would construct length()-1 intermediate
         *   lists, though, so it's pretty inefficient memory-wise.  The
         *   easier and more efficient way is to create a Vector with the
         *   same elements as the list, shuffle the Vector, and then
         *   convert the result back to a list.  This creates only the one
         *   intermediate value (the Vector), and it's very simple to code,
         *   so we'll take that approach.  
         */
        return new Vector(length(), self).shuffle().toList();
    }
    
    /* Determine whether this list has any elements in common with lst */    
    overlapsWith(lst)
    {
        return intersect(valToList(lst)).length > 0;
    }
        
    /*  Returns the ith member of the list if there is one, or nil otherwise */
    element(i)
    {
        return length >= i ? self[i] : nil;
    }
    
    /*  
     *   Compare two lists of strings using the cmp StringComparator; return
     *   true if all the corresponding strings in the two lists are the same
     *   (according to cmp) and nil otherwise.
     */
    strComp(lst, cmp)
    {
        if(lst.length != length)
            return nil;
        
        for(local i in 1 .. lst.length)
        {
            if(cmp.matchValues(self[i], lst[i]) == 0)
                return nil;
        }
        return true;
    }
;

/* Add a method to Date as a workaround for a library bug */
modify Date
    /* 
     *   Get the Hours, Minutes, Seconds and Milliseconds of the current time as
     *   a four-element list; Date.getClockTime() is meant to do this, but
     *   doesn't work properly.
     */
    getHMS()
    {
        local hh = toInteger(formatDate('%H'));
        local mm = toInteger(formatDate('%M'));
        local ss = toInteger(formatDate('%S'));
        local ms = toInteger(formatDate('%N'));
        
        return [hh, mm, ss, ms];
    }
    
;

/* ------------------------------------------------------------------------ */
/*
 *   Library error.  This is a base class for internal errors within the
 *   library.  
 */
class LibraryError: Exception
    construct()
    {
        /* do the inherited work */
        inherited();

        /* 
         *   As a debugging aid, break into the debugger, if it's running.
         *   This makes it easier during development to track down where
         *   errors are occurring.  This has no effect during normal
         *   execution in the interpreter, since the interpreter ignores
         *   this call when the debugger isn't present. 
         */
        t3DebugTrace(T3DebugBreak);
    }
    display = "Library Error"
;

/*
 *   A generic "argument mistmatch" error.  The library uses this for
 *   functions that use matchProto() to handle multiple argument list
 *   variations: when none of the allowed argument lists are found, the
 *   function throws this error. 
 */
class ArgumentMismatchError: LibraryError
    display = "Wrong arguments in function or method call"
;



/* ------------------------------------------------------------------------ */
/*
 *   LCS - class that computes the Longest Common Subsequence for two lists
 *   or vectors.
 *   
 *   The LCS is most frequently used as a differencing tool, to compute a
 *   description of how two data sets differ.  This is at the core of tools
 *   like "diff", which shows the differences between two versions of a
 *   file.  The LCS is the part of the two sets that's the same, so
 *   everything in one of the sets that's not in the LCS is unique to that
 *   set.  The standard diff algorithm computes the LCS, then generates a
 *   list of edits by specifying a "delete" operation on each item in the
 *   "new" set that's not in the LCS, and an "insert" operation on each
 *   item in the "old" set that's not in the LCS.  Merge and sort the two
 *   edit lists and you have basically the standard Unix "diff" output.
 *   (Some diff utilities make the report more readable by combining
 *   overlapping edit and insert operations into "update" operations.  But
 *   it's really the same thing, of course.)
 *   
 *   The constructor does all the work: use 'new' to create an instance of
 *   this class, providing the two lists to be compared as arguments.  The
 *   resulting object contains the LCS information.
 *   
 *   Note that you can use this class to generate a character-by-character
 *   LCS for two strings, simply by using toUnicode() to convert each
 *   string to a list of character values.  
 */
class LCS: object
    construct(a, b)
    {
        local i, j, ka, kb;

        /* get the input list lengths */
        local alen = a.length(), blen = b.length();

        /* set up the length array, alen x blen, initialized with 0s */
        local c = new Vector(alen+1).fillValue(nil, 1, alen+1);
        c.applyAll({ ele: new Vector(blen+1).fillValue(0, 1, blen+1) });

        /* set up the arrow array, alen x blen */
        local arr = new Vector(alen+1).fillValue(nil, 1, alen+1);
        arr.applyAll({ ele: new Vector(blen+1).fillValue(nil, 1, blen+1) });

        /* apply the standard LCS algorithm */
        for (i = 1 ; i <= alen ; ++i)
        {
            for (j = 1 ; j <= blen ; ++j)
            {
                if (a[i] == b[j])
                {
                    /* up-left */
                    c[i+1][j+1] = c[i][j] + 1;
                    arr[i+1][j+1] = 3;
                }
                else if (c[i][j+1] >= c[i+1][j])
                {
                    /* up */
                    c[i+1][j+1] = c[i][j+1];
                    arr[i+1][j+1] = 2;
                }
                else
                {
                    /* left */
                    c[i+1][j+1] = c[i+1][j];
                    arr[i+1][j+1] = 1;
                }
            }
        }

        /* build the LCS list */
        local la = new Vector(alen), lb = new Vector(blen);
        for (i = alen+1, j = blen+1, ka = alen, kb = blen ; i > 0 && j > 0 ; )
        {
            if (arr[i][j] == 3)
            {
                la[ka--] = i-1;
                lb[kb--] = j-1;
                --i;
                --j;
            }
            else if (arr[i][j] == 2)
                --i;
            else
                --j;
        }

        /* save the LCSs, truncating the used portions */
        lcsA = la.toList().sublist(ka+1);
        lcsB = lb.toList().sublist(kb+1);
    }

    /* the LCS, as lists of character indices into the respective strings */
    lcsA = nil
    lcsB = nil
;


/* ------------------------------------------------------------------------ */
/*
 *   Change the case (upper/lower) of a given new string to match the case
 *   pattern of the given original string.
 *   
 *   We recognize four patterns:
 *   
 *   - If the original string has at least one capital letter and no
 *   minuscules, we convert the new string to all caps.  For example,
 *   matchCase('ALPHA-1', 'omicron-7') yields 'OMICRON-7'.
 *   
 *   - If the original string has at least one lower-case letter and no
 *   capitals, we convert the new string to all lower case.  E.g.,
 *   matchCase('alpha-1', 'OMICRON-7') yields 'omicron-7'.
 *   
 *   - If the original string starts with a capital letter, and has at
 *   least one lower-case letter and no other capitals, we capitalize the
 *   first letter of the new string and lower-case everything else. E.g.,
 *   matchCase('Alpha-1', 'OMICRON-7') yields 'Omicron-7'.
 *   
 *   - Otherwise, we match the case pattern of the input string letter for
 *   letter: for each upper-case letter in the original, we capitalize the
 *   letter at the corresponding character index in the new string, and
 *   likewise with lower-case letters in the original.  We leave other
 *   characters unchanged.  E.g., matchCase('AlPhA-1', 'omicron-7') yields
 *   'OmIcRon-7'.  
 */
matchCase(newTok, oldTok)
{
    /* 
     *   If the old token is all lower-case or all upper-case, it's easy.
     *   Only assume all upper-case if the original token has at least two
     *   capitals - for something like "I" we can't assume we want an
     *   all-caps word. 
     */
    if (rexMatch(R'<^upper>*<lower>+<^upper>*', oldTok) != nil)
        return newTok.toLower();
    if (rexMatch(R'<^lower>*<upper>+<^lower>*<upper>+<^lower>*', oldTok) != nil)
        return newTok.toUpper();
    
    /* another common and easy pattern is title case (initial cap) */
    if (rexMatch(R'<upper><^upper>*<lower>+<^upper>*', oldTok) != nil)
        return newTok.firstChar().toUpper() + newTok.delFirst().toLower();
    
    /* do everything else letter by letter */
    local ret = '';
    for (local i = 1, local len = newTok.length() ; i <= len ; ++i)
    {
        local cn = newTok.substr(i, 1);
        local co = oldTok.substr(i, 1);
        
        if (rexMatch(R'<upper>', co) != nil)
            ret += cn.toUpper();
        else if (rexMatch(R'<lower>', co) != nil)
            ret += cn.toUpper();
        else
            ret += cn;
    }
    
    /* return the result */
    return ret;
}


/* ------------------------------------------------------------------------ */
/*
 *   Static object and class initializer.
 *   
 *   During startup, we'll automatically call the classInit() method for
 *   each class object, and we'll call the default constructor for each
 *   static object instance.  ("Static" objects are those defined directly
 *   in the source code, as opposed to objects created dynamically with
 *   'new'.)  This makes it easier to write initialization code by making
 *   the process more uniform across static and dynamic objects.
 *   
 *   The first step is to call classInit() on each class.  We call this
 *   method only each class that *directly* defines the method (i.e., we
 *   don't call it on classes that only inherit the method from another
 *   class).  We cycle through the objects in arbitrary order.  However,
 *   you can control the relative order when there's a dependency by
 *   setting the 'classInitFirst' property to a list of one or more classes
 *   to initialize first.  When we encounter a class with this property,
 *   we'll call the listed classes' classInit() methods before calling the
 *   given class's classInit().
 *   
 *   The second step is to call constructStatic() or construct() on each
 *   regular (non-class) object.  We only call this on *static* objects:
 *   objects defined directly in the source code, as opposed to created
 *   dynamically with 'new'.  As with classInit(), we visit the objects in
 *   arbitrary order.  You can control dependencies using the
 *   'constructFirst' method: set this to a list of objects to be
 *   initialized before self.
 *   
 *   If an object defines or inherits a constructStatic() method, we'll
 *   call it instead of construct().  Otherwise, if it defines or inherits
 *   a construct() method with no arguments, we'll call it.  Otherwise
 *   we'll do nothing.
 *   
 *   Note that it's possible for a base class to have a compatible
 *   zero-argument constructor, but for a subclass to override this with a
 *   constructor that takes arguments.  In this case, we'll search the
 *   class tree for an inherited zero-argument constructor.  If we find
 *   one, we'll call the inherited constructor.
 *   
 *   We can only call zero-argument construct() methods because we have no
 *   basis for providing other arguments.  
 */
libObjectInitializer: PreinitObject
    execBeforeMe = []
    execute()
    {
        /* build the reverse symbol table (indexed by object value) */
        local gtab = t3GetGlobalSymbols();
        local otab = new LookupTable(128, 256);
        gtab.forEachAssoc({ key, val: otab[val] = key });

        /* save it in the PreinitObject class */
        PreinitObject.reverseGlobalSymbols = otab;

        /* create a lookup table tracking which objects we've initialized */
        _initedTab = new LookupTable(256, 1024);

        /* call classInit() on all classes */
        for (local o = firstObj(TadsObject, ObjClasses) ; o != nil ;
             o = nextObj(o, TadsObject, ObjClasses))
        {
            /* if this class directly defines a classInit() method, call it */
            if (o.propDefined(&classInit, PropDefGetClass) == o)
                callConstructor(o, &classInit, &classInitFirst);
        }

        /* call construct() or constructStatic() on all object instances */
        for (local o = firstObj(TadsObject, ObjInstances) ; o != nil ;
             o = nextObj(o, TadsObject, ObjInstances))
        {
            /* 
             *   Only call static objects - these will all have
             *   sourceTextOrder properties assigned by the compiler.
             *   
             *   Note that modified objects will inherit sourceTextOrder
             *   from a class - they're the only objects that do this,
             *   since the compiler only assigns sourceTextOrder initially
             *   to ordinary objects, but then class-ifies the base object
             *   when modifying it.  The only way that an object can
             *   inherit sourceTextOrder from a class is that the class is
             *   the original modified object, and the instance is the
             *   modifier.  
             */
            local cl = o.propDefined(&sourceTextOrder, PropDefGetClass);
            if (cl == o || cl != nil && cl.isClass())
            {
                /* 
                 *   It's a static object.  If it has a constructStatic()
                 *   method, call that.  Otherwise, if it has a construct()
                 *   method, call that.
                 */
                if (o.propDefined(&constructStatic))
                {
                    /* it has constructStatic() */
                    callConstructor(o, &constructStatic, &constructFirst);
                }
                else if (o.propDefined(&construct))
                {
                    /* call construct() */
                    callConstructor(o, &construct, &constructFirst);
                }
            }
        }

        /* 
         *   done with the lookup table - explicitly remove it so that it
         *   doesn't take up space in the final compiled image 
         */
        _initedTab = nil;

        /* likewise the reverse global symbol table */
        reverseGlobalSymbols = otab;
    }

    /* call the given object's constructor */
    callConstructor(obj, conProp, preProp)
    {
        /* if obj has already been initialized, skip it */
        if (_initedTab[obj])
            return;

        /* 
         *   mark this object as visited (do this first, before handling
         *   prerequisites, to break circular dependencies: if a
         *   prerequisite of ours lists us as a prerequisite, we'll see
         *   that we've already been initialized and stop the loop) 
         */
        _initedTab[obj] = true;

        /* call constructors on any prerequisites */
        if (obj.propDefined(preProp))
        {
            foreach (local p in obj.(preProp))
                callConstructor(p, conProp, preProp);
        }

        /* 
         *   if the given constructor is zero-argument constructor, call it
         *   directly; otherwise, look for an inherited constructor 
         */
        if (obj.getPropParams(conProp) == [0, 0, nil])
        {
            /* call the constructor */
            obj.(conProp)();
        }
        else
        {
            /* 
             *   Search the class tree for an inherited version of the
             *   constructor that takes zero arguments.  
             */
            for (local cl = obj.propDefined(conProp, PropDefGetClass) ;
                 cl != nil ;
                 cl = obj.propInherited(conProp, obj, cl, PropDefGetClass))
            {
                /* if this is a zero-argument version, call it */
                if (cl.getPropParams(conProp) == [0, 0, nil])
                {
                    /* invoke it */
                    obj.callInherited(cl, conProp);

                    /* we're done looking */
                    break;
                }
            }
        }
    }

    /* table of objects we've already initialized */
    _initedTab = nil
;

/*
 *   Our static object and class initializer should generally run before
 *   any other initializers.  
 */
modify PreinitObject
    /* execute the basic library initializer before any other initializers */
    execBeforeMe = [libObjectInitializer]

    /* 
     *   class property: reverse lookup symbol table (a version of the
     *   global symbol table keyed by value, yielding the name of each
     *   global object, function, etc) 
     */
    reverseGlobalSymbols = nil
;


