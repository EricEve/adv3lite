#include "advlite.h"

/*
 *   ************************************************************************
 *   debug.t This module forms part of the adv3Lite library, and defines a
 *   number of commands that can be used for debugging purposes.
 *
 *   (c) 2012-13 Eric Eve (but based partly on code borrowed from the Mercury
 *   library (c) Michael J. Roberts).
 *
 *
 */


/* We only include any of the code in this module in debug builds */
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
    all = ['spelling', 'messages', 'actions', 'doers']

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

/* The Debug Action with various options */
DefineSystemAction(Debug)
    execAction(cmd)
    {
        gLiteral = cmd.dobj.name.toLower;
        switch(gLiteral)
        {
        case 'messages':
        case 'spelling':
        case 'actions':
        case 'doers':
            DebugCtl.enabled[gLiteral] = !DebugCtl.enabled[gLiteral];
            /* Deliberately omit break to allow fallthrough */
        case 'status':
            DebugCtl.status();
            break;
        case 'off':
        case 'stop':    
            foreach(local opt in DebugCtl.all)
                DebugCtl.enabled[opt] = nil;
            DebugCtl.status();
            break;
        default:
            "That is not a valid option. The valid DEBUG options are DEBUG
            MESSAGES, DEBUG SPELLING, DEBUG ACTIONS, DEBUG DOERS,
            DEBUG OFF or DEBUG STOP (to turn off all options) or
            just DEBUG by itself to break into the debugger. ";
        }
        
    }
;

/* DEBUG without any options simply breaks into the debugger, as in adv3 */
DefineSystemAction(DebugI)
    execAction(cmd)
    {
        /* if the debugger is present, break into it */
        if (t3DebugTrace(T3DebugCheck))
            t3DebugTrace(T3DebugBreak);
        else
            DMsg(debugger not present, 'Debugger not present. ');
    }
;

VerbRule(DebugI)
    'debug' 
    : VerbProduction
    action = DebugI
    verbPhrase = 'debug/debugging'
    missingQ = 'which debug option do you want to set'
;

/* 
 *   The actionTab object holds a table providing the names (as strings)
 *   corresponding to the various Action objects, for use with the DEBUG ACTIONS
 *   option.
 */
actionTab: PreinitObject
    
    /* 
     *   To return the string val corresponding to the Action val, simply look
     *   it up in out ctab table
     */
    symbolToVal(val)
    {
        return ctab[val];        
    }
    
    /* A LookupTable of Actions and their corresponding string names */
    ctab = [* -> '???']
        
    execute()
    {
        /* 
         *   Populate our ctab table by going through the global symbol table at
         *   preinit and storing the value and associated name of every Action
         *   object.
         */
        t3GetGlobalSymbols().forEachAssoc( new function(key, value)
        {
            if(dataType(value) == TypeObject && value.ofKind(Action))
                ctab[value] = key;
        });
    }
;

/* 
 *   The Purloin Action allows a game author to take any object in the game
 *   while testing
 */
DefineTAction(Purloin)    
    againRepeatsParse = true
    
    /* The PURLOIN action requires universal scope */
    addExtraScopeItems(whichRole?)
    {
        makeScopeUniversal();
    }
    beforeAction() { }
    afterAction() { }
    turnSequence() { }
    
;    

/* 
 *   The GONEAR action allows the game author to move the player character to
 *   anywhere on the map, while testing.
 */
DefineTAction(GoNear)   
    againRepeatsParse = true
    
    /* The GONEAR action requires universal scope */
    addExtraScopeItems(whichRole?)
    {
        makeScopeUniversal();
    }  
    beforeAction() { }
    afterAction() { }
    turnSequence() { }
;

/*  
 *   The FIAT LUX Action can be used to light up the player character (thus
 *   bringing light to a dark location). Repeating the FIAT LUX action removes
 *   the light from the player character
 */
DefineIAction(FiatLux)
    execAction(cmd)
    {
        gPlayerChar.isLit = !gPlayerChar.isLit;
        DMsg(fiat lux, '{I} suddenly {1} glowing. ', gPlayerChar.isLit ? 'start'
             :  'stop' );
    }
    
    beforeAction() { }    
    turnSequence() { }
;

/* The EVALUATE action allows any expression to be evaluated */
DefineLiteralAction(Evaluate)
    exec(cmd)
    {
        try
        {
            /* 
             *   Try using the Compiler object to evaluate the expression
             *   contained in the name property of the direct object of this
             *   command (i.e. the string literal it was executed upon).
             */
            local res = Compiler.eval(stripQuotesFrom(cmd.dobj.name));
            
            /* Display a string version of the result */
            say(toString(res));
        }
        /* 
         *   If the attempt to evaluate the expression caused a compiler error,
         *   display the exception message.
         */
        catch (CompilerException cex)
        {           
            cex.displayException();
        }
        
        /* 
         *   If the attempt to evaluate the expression caused any other kind of
         *   error, display the exception message.
         */
        catch (Exception ex)
        {
            ex.displayException();
        }
        
    }
    includeInUndo = true
    afterAction() {}
    beforeAction() { }    
    turnSequence() { }
;

/* An object to store class names */
symTab: PreinitObject
    symbolToVal(val)
    {
        return ctab[val];        
    }
    
    ctab = [* -> '???']
    
    /* 
     *   Store a string equivalent of the name of every class defined in the
     *   game (and the library)
     */
    execute()
    {
        t3GetGlobalSymbols().forEachAssoc( new function(key, value)
        {
            if(dataType(value) == TypeObject && value.isClass)
                ctab[value] = key;
        });
    }
;

/* 
 *   Provide TadsObject with an objToString() method so that the EVALUATE
 *   command can display some kind of name of the object via the toString()
 *   function
 */
modify TadsObject
    objToString()
    {
        /* If this object is a class, return the name of the class */
        if(isClass)
            return symTab.symbolToVal(self);
        
        local str;
        
        /* 
         *   If the object has a name property, start the string with this
         *   object's name
         */
        if(name != nil)
            str = name + ' ';
        
        /*  Append this object's superclass list in parentheses*/
        str  += '(' + getSuperclassList + ')';
        
        /*  Return the result */
        return str;
    }
    
;

#endif
