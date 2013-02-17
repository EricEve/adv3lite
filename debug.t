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

actionTab: PreinitObject
    symbolToVal(val)
    {
        return ctab[val];        
    }
    
    ctab = [* -> '???']
        
    execute()
    {
        t3GetGlobalSymbols().forEachAssoc( new function(key, value)
        {
            if(dataType(value) == TypeObject && value.ofKind(Action))
                ctab[value] = key;
        });
    }
;

DefineTAction(Purloin)    
    againRepeatsParse = true
    addExtraScopeItems(whichRole?)
    {
        makeScopeUniversal();
    }
    beforeAction() { }
    afterAction() { }
    turnSequence() { }
    
;    

DefineTAction(GoNear)   
    againRepeatsParse = true
    addExtraScopeItems(whichRole?)
    {
        makeScopeUniversal();
    }  
    beforeAction() { }
    afterAction() { }
    turnSequence() { }
;

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

DefineLiteralAction(Evaluate)
    exec(cmd)
    {
        try
        {
            local res = Compiler.eval(stripQuotesFrom(cmd.dobj.name));
            say(toString(res));
        }
        catch (CompilerException cex)
        {
            cex.displayException();
        }
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


symTab: PreinitObject
    symbolToVal(val)
    {
        return ctab[val];        
    }
    
    ctab = [* -> '???']
        
    execute()
    {
        t3GetGlobalSymbols().forEachAssoc( new function(key, value)
        {
            if(dataType(value) == TypeObject && value.isClass)
                ctab[value] = key;
        });
    }
;

modify TadsObject
    objToString()
    {
        if(isClass)
            return symTab.symbolToVal(self);
        
        local str;
        
        if(name != nil)
            str = name + ' ';
        
        str  += '(' + getSuperclassList + ')';
        
        return str;
    }
    
;


#endif
