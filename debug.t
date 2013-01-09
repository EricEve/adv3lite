#include "advlite.h"

#ifdef __DEBUG

DebugCtl: object
    /*
     *   Debug mode options.  Each debug function has an associated ID key,
     *   which is just a string identifying it.  This is a lookup table
     *   that keeps a true/nil value for each key, saying whether the
     *   function is enabled or disabled.  This lets the developer turn
     *   debugging displays on and off individually, so that you don't have
     *   to look at piles of debug output not relevant to the task you're
     *   currently working on.  
     */
    enabled = static (new LookupTable(32, 64))

    /* list of all debugging options */
    all = ['spelling', 'messages', 'actions']

    /* show the current status */
    status()
    {
        "Debugging options:\n";
        local opts = all.sort(SortAsc);
        foreach (local opt in opts)
            "\t<<opt>> = <<enabled[opt] ? 'on' : 'off'>>\n";
    }
;

/*
 *   Debug options.  This is the general verb for performing various
 *   debugging operations while running the game.  The Debug Action parses
 *   the options string to carry out the command.  
 */
VerbRule(Debug)
    'debug' literalDobj
    : VerbProduction
    action = Debug
    verbPhrase = 'debug/debugging'
    missingQ = 'which debug option do you want to set'
;

Debug: Action
    exec(cmd)
    {
        
    }
;

#endif
