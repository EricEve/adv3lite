#charset "us-ascii"
#include "advlite.h"



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
//    try
//    {
//        /* restore the global default settings */
//        settingsManager.restoreSettings();
//    }
//    catch (Exception exc)
//    {
//        /* 
//         *   ignore any errors restoring defaults - it's not critical that
//         *   we restore this file automatically 
//         */
//    }
//
    
    
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

    /* run the scheduling loop until the game ends */
    mainCommandLoop();
}

/* ------------------------------------------------------------------------ */

mainCommandLoop()
{
//    local cmd, tokList;
//    local parsedCmd;
//    local pCommands;
    local txt;

    gActor = gPlayerChar;
    
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
            "<.p>";
            "<.inputline>>";
            txt = inputManager.getInputLine();
            "<./inputline>\n";   
            
            txt = StringPreParser.runAll(txt, nil);
            
            if(txt == nil)
                continue;
            
            
            Parser.parse(txt);
        }
        catch(TerminateCommandException tce)
        {
            
        }
        
        statusLine.showStatusLine();
        
    } while (true);
       
    
}





ExitSignal: Exception
;

AbortImplicitSignal: Exception
;

AbortActionSignal: Exception
;

ExitActionSignal: Exception  
;

TerminateCommandException: Exception
;

