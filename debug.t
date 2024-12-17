#charset "us-ascii"
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
    
    /* LookupTable used to avoid duplicate debug message reports */
    messageIDs = static (new LookupTable(32, 64))    
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
            if(DebugCtl.all.indexOf(gLiteral))
            {
                DebugCtl.enabled[gLiteral] = !DebugCtl.enabled[gLiteral];
                DebugCtl.status();               
            }
            else                
                "That is not a valid option. The valid DEBUG options are DEBUG
                MESSAGES, DEBUG SPELLING, DEBUG ACTIONS, DEBUG DOERS,
                DEBUG OFF or DEBUG STOP (to turn off all options) or
                just DEBUG by itself to break into the debugger. ";
            break;
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
    
    /* The Purloin action should work even on a hidden item  */
    unhides = true
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
    
    /* The GoNear action should work even on a hidden item  */
    unhides = true
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
    
    /* 
     *   Do we want to use Compiler.compile rather than Compiler.eval()? By default we do since this
     *   circumvents a bug on FrobTADS for Limux users.
     */
    
    useCompile = true
    
    exec(cmd)
    {
        try
        {
            /* 
             *   Try using the Compiler object to evaluate the expression
             *   contained in the name property of the direct object of this
             *   command (i.e. the string literal it was executed upon).
             */
            local res;
            local str = stripQuotesFrom(cmd.dobj.name);
            
            if(useCompile)
            {
                local func = Compiler.compile(str);
                res = func();
            }
            else           
               res = Compiler.eval(str);
            
            if(dataType(res) == TypeEnum)
            {
                local str = enumTabObj.enumTab[res];
                if(str) res = str;
            }
            
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

/* An object to store class and object names */
symTab: PreinitObject
    symbolToVal(val)
    {
        return ctab[val];        
    }
    
    ctab = [* -> '???']
    
    /* 
     *   Store a string equivalent of the name of every identifier defined in the
     *   game (and the library)
     */
    execute()
    {
        t3GetGlobalSymbols().forEachAssoc( new function(key, value)
        {
//            if(dataType(value) == TypeObject && value.isClass)
//                ctab[value] = key;
//            
//            if(dataType(value) == TypeObject && (value.ofKind(Region)))               
//                ctab[value] = key;
//            
//            if(defined(Actor) && dataType(value) == TypeObject &&
//               (value.ofKind(ActorState) || value.ofKind(AgendaItem)))
//                ctab[value] = key;
            ctab[value] = key;
        });
    }
;


/* Take a string and return the object whose programmatic name it refers to */
symToVal(val)
{    
    return t3GetGlobalSymbols()[val];      
}
    
/* Take a value and return the string representation of its programmatic name */
valToSym(val)
{
    local str;
    switch(dataType(val))
    {
    case TypeSString:        
        return val;
    case TypeInt:
        return toString(val);
    case TypeObject:
        str = symTab.ctab[val]; 
        if(str == '???' && val.propDefined(&name)) str = val.name;
        return str;
        
    case TypeEnum:
        local enumStr = enumTabObj.enumTab[val];
        if(enumStr) return enumStr;    
        /* Fallthrough deliberate */
    case TypeProp:  
        return symTab.ctab[val]; 
//        return str;   
    case TypeNil:
        return 'nil';
    case TypeTrue:
        return 'true';
    case TypeList:
        str = '[';
        for(local cur in val, local i=1, local len=val.length;; i++)
        {
            str += valToSym(cur);
            if(i < len)
                str += ', ';            
        }
        str += ']';
        return str;
        
    }
    
    return '?';
}


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
        
        local str = '';
        
        /* 
         *   If the object has a name property, start the string with this
         *   object's name
         */
        if(name != nil)
            str = name + ' ';
        /* 
         *   Otherwise if we have an identifier for this object stored in our
         *   symbol table, use that
         */
        else if(symTab.symbolToVal(self) != '???')
            str = symTab.symbolToVal(self) + ' ';
        
        /*  Append this object's superclass list in parentheses*/
        str  += '(' + getSuperclassList + ')';
        
        /*  Return the result */
        return str;
    }
    
;


/* 
 *   Adaptation for use with adv3Lite of the tests extension based on work by
 *   Ben Cressy, Eric Eve, and N.R.Turner
 */

/*
 *   To use this facility, define Test objects like so:
 *
 *. foo: Test
 *.    testName = 'foo'
 *.    testList =
 *.    [
 *.        'x me',
 *.        'i'
 *.    ]
 *. ;
 *
 *. bar: Test
 *.     testName = 'bar'
 *.     testList =
 *.     [
 *.         'look',
 *.         'listen'
 *.     ]
 *. ;
 *
 *. allTests: Test
 *.     testName = 'all'
 *.     testList =
 *.     [
 *.         'test foo',
 *.         'test bar'
 *.     ]
 *   ;
 *
 *   Alternatively,  use the template structure to create your test objects more
 *   conveniently:
 *
 *.  someTest: Test 'foo' ['x me', 'i'];
 *
 *   Unless you're planning to refer to the Test object in some other part of
 *   your code, you can save a bit of typing by making it an anonymous object:
 *
 *. Test 'foo' ['x me', 'i'];
 *
 */
    
/*
 *   The 'list tests' and 'list tests fully' commands can be used to list your
 *   test scripts from within the running game.
 */   
DefineSystemAction(ListTests)
    execAction(cmd)
    {

        if(allTests.lst.length == 0)
        {
            DMsg(no test scripts, 'There are no test scripts defined in this
                game. ');
            exit;
        }

        fully = cmd.verbProd.fully;
        
        foreach(local testObj in allTests.lst)
        {
            "<<testObj.testName>>";
            if(gAction.fully)               
            {
                ": ";
                foreach(local txt in testObj.testList)
                    "<<txt>>/";
            }
            "\n";
        }
    }
    fully = nil
;

VerbRule(ListTests)
    ('list' | 'l') 'tests' (| 'fully' -> fully)
    : VerbProduction
    action = ListTests
    verbPhrase = 'list/listing test scripts'
;

/*
 *   The 'test X' command can be used with any Test object defined in the source
 *   code:
 */
DefineLiteralAction(DoTest)
    /* 
     *   We override exec() rather than exeAction() here, since we want to skip
     *   all the normal turn sequence routines such as before and after
     *   notifications and advancing the turn count.
     */
    exec(cmd)
    {
        local target = cmd.dobj.name.toLower();
        local script = allTests.valWhich({x: x.testName.toLower == target});
        if (script)
            script.run();
        else
            DMsg(test sequence not found, 'Test sequence not found. ');
    }
    
    /* Do nothing after the main action */
    afterAction() { }
      
    turnSequence() { }
;

VerbRule(Test)
    'test' literalDobj
    : VerbProduction
    action = DoTest
    verbPhrase = 'test/testing (what)'
    missingQ = 'which sequence do you want to test'
;

/* 
 *   A Test object can be used to create a series of testing commands in your
 *   game, for example:
 *
 *.  Test 'foo' ['x me', 'i', 'wear uniform'] [uniform];
 *
 *   Would cause the uniform to be moved into the player character's inventory
 *   and then the commands X ME and then I and WEAR UNIFORM to be executed in
 *   response to TEST FOO.
 */     
class Test: object
    /* The name of this test */
    testName = 'nil'
    
    /* The list commands to be executed when running this test. */
    testList = [ 'z' ]
    
    /* 
     *   The location to move the player character to before running the test
     *   script
     */
    location = nil
	
    /* 
     *   Flag: Do we want to report any change of location by looking around in
     *   the new one? By default we will.
     */
    reportMove = true
    
    /*   
     *   The objects to move into the player character's inventory before
     *   running the test script.
     */
    testHolding = []
    
    /*  
     *   Flag: do we want to report on what items were added to inventory? By
     *   default we do.
     */
    reportHolding = true
    
    
    /* Move everything in the testHolding list into the actor's inventory */
    getHolding()
    {
        testHolding.forEach({x: x.moveInto(gActor)});
        
        /* 
         *   If we want to report on the effect of moving additional items into
         *   the player character's inventory, and if we specified any items to
         *   move, report that the actor is now holding those items.
         */
        if(reportHolding && testHolding.length > 0)
            DMsg(debug test now holding, '{I} {am} {now} holding {1}.\n',
                 makeListStr(testHolding, &theName));
    }
    
    /* 
     *   Run this test by passing the commands in testList through
     *   Parser.parse().
     */
    run()
    {
        "Testing sequence: \"<<testName>>\".\n";
        
        /* 
         *   If a location is specified, first move the actor into that
         *   location.
         */
        if (location && gActor.location != location)
        {
            gActor.moveInto(location);	
            
            /* If we want to report the move, show the new room description */
            if(reportMove)
                gActor.getOutermostRoom.lookAroundWithin();
        }
        
        /*   Move any required objects into the actor's inventory */
        getHolding();
        
        /*   Convert the list to a Vector to prevent possible stack overflow with a long list of commands. */        
        local testVec = new Vector(testList);

        /*   Preparse and execute each command in the list */
        testVec.forEach(new function(x)  {
            /* Display the command to be executed */
            "<b>><<x>></b>\n";
            
            /* Preparse the command */
            x = StringPreParser.runAll(x, rmcCommand);                          
            
            /* 
             *   Execute the preparsed command if it is not nil after preparsing
             */
            if(x)
              Parser.parse(x);
        });
    }
;

/* 
 *   The allTests object contains a list of Test objects for listing via the
 *   LIST TESTS command, and for finding the test that corresponds to a
 *   particular testName.
 */
allTests: object
   lst()
   {
      if (lst_ == nil)
         initLst();
      return lst_;
   }

   initLst()
   {
      lst_ = new Vector(50);
      local obj = firstObj();
      while (obj != nil)
      {
         if(obj.ofKind(Test))
            lst_.append(obj);
         obj = nextObj(obj);
      }
      lst_ = lst_.toList();
   }

   valWhich(cond)
   {
      if (lst_ == nil)
         initLst();
      return lst_.valWhich(cond);
   }

   lst_ = nil
;


#endif // __DEBUG


