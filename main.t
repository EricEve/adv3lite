#charset "us-ascii"
#include "advlite.h"


/*
 *   **************************************************************************
 *   main.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve. Based
 *   in part on code in the adv3 Library (c) Michael J. Roberts.
 */

/*
 *   Main program entrypoint.  The core run-time start-up code calls this
 *   after running pre-initialization and load-time initialization.  This
 *   entrypoint is called when we're starting the game normally; when the
 *   game is launched through a saved-position file, mainRestore() will be
 *   invoked instead.  
 */
main(args)
{
    libGlobal.commandLineArgs = args;
    mainCommon(&newGame);
}

/*
 *   Main program entrypoint for restoring a saved-position file.  This is
 *   invoked from the core run-time start-up code when the game is launched
 *   from the operating system via a saved-position file.  For example, on
 *   Windows, double-clicking on a saved-position file on the Windows
 *   desktop launches the interpreter, which looks in the save file to find
 *   the game executable to run, then starts the game and invokes this
 *   entrypoint.  
 */
mainRestore(args, restoreFile)
{
    libGlobal.commandLineArgs = args;
    mainCommon(&restoreAndRunGame, restoreFile);
}

/*
 *   Common main entrypoint - this handles starting a new game or restoring
 *   an existing saved state. 
 */
mainCommon(prop, [args])
{
    
    try
    {
        /* at the start of the session, set up the UI subsystem */
        if (mainGlobal.restartID == 0)
        {
            /* initialize the UI */
            initUI();

            /* 
             *   tell the system library to call our UI shutdown function
             *   at program exit 
             */
            mainAtExit.addHandler(terminateUI);
        }

        /* initialize the display */
        initDisplay();

       
        
        /* call the appropriate gameMain method */
        gameMain.(prop)(args...);
    }
    catch (QuittingException q)
    {
        /* 
         *   This exception is a signal to quit the game, which we will now
         *   proceed to do by returning from this function, which exits the
         *   program. 
         */
    }
}


/* ------------------------------------------------------------------------ */
/*
 *   Run the game.  We start by showing the description of the initial
 *   location, if desired, and then we read and interpret commands until
 *   the game ends (via a "quit" command, winning, death of the player
 *   character, or any other way of terminating the game).
 *   
 *   This routine doesn't return until the game ends.
 *   
 *   Before calling this routine, the caller should already have set the
 *   global variable gPlayerChar to the player character actor.
 *   
 *   'look' is a flag indicating whether or not to look around; if this is
 *   true, we'll show a full description of the player character's initial
 *   location, as though the player were to type "look around" as the first
 *   command.  
 */
runGame(look)
{
    /* show the starting location */
    if (look)
    {
        gActor = gPlayerChar;
        /* run the initial "look around" in a dummy command context */
        gPlayerChar.outermostVisibleParent().lookAroundWithin();
    }

    /* run the main command loop until the game ends */
    mainCommandLoop();
}

/* ------------------------------------------------------------------------ */
/* 
 *   The main command loop. This repeatedly prompts the player for a command and
 *   then processes the command until the game ends.
 */

mainCommandLoop()
{

    local txt;

    /* 
     *   Set the current actor to the player character at the start of the game
     *   (to ensure we have a current actor defined).
     */
    gActor = gPlayerChar;
    
    /* 
     *   Repeat this loop, which asks for a command and then parses it, until
     *   the game comes to an end.
     */
    do
    {
        /* Display score notifications if the score module is included. */
        if(defined(scoreNotifier) && scoreNotifier.checkNotification())
            ;
        
        /* run any PromptDaemons if the events module is included */
        if(defined(eventManager) && eventManager.executePrompt())
            ;
        
        try
        {
            /* Output a paragraph break */
            "<.p>";
            
            /* Read a new command from the keyboard. */
            "<.inputline>>";
            txt = inputManager.getInputLine();
            "<./inputline>\n";   
            
            /* Pass the command through all our StringPreParsers */
            txt = StringPreParser.runAll(txt, nil);
            
            /* 
             *   If the txt is now nil, a StringPreParser has fully dealt with
             *   the command, so go back and prompt for another one.
             */        
            if(txt == nil)
                continue;
            
            /* Parse and execute the command. */
            Parser.parse(txt);
        }
        catch(TerminateCommandException tce)
        {
            
        }
        
        /* Update the status line. */
        statusLine.showStatusLine();
        
    } while (true);    
    
}



