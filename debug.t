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
 *   Ben Cressy, Eric Eve, and N.R.Turner with substantial enhancements by 
 *   Mitch Mlinar
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
 *   Assertion-based testing
 *   assertPlayerInRoom room: Fails test when not in room; does nothing otherwise
 *   assertPlayerHasItem item(s): Fails test/script when not in possession
 *   assertPlayerLacksItem item(s): Fails test/script when in possession
 *   assertPlayerRoomHasItem item(s): Fails test/script when not in possession
 *   assertPlayerRoomLacksItem item(s): Fails test/script when in possession
 *   assertMsg text: Fails if text is not within prior text output messages; clears after
 *                   and, by default, before each non-assert message
 *   assertMsgClear: Clears assertMsg buffer
 *
 * 
 *   Usage:
 *
 *   test <name>
 *   testall [nostop]
 *   list tests [fully|sorted]
 *
 *
 *   Usage:
 *
 *   test <name>
 *   testall
 *   list tests [fully|sorted]
 *
 */

/////////////////////////////////////
// Mitch's assertion extensions
///////////////////////////////////


/* 
 *   The code below references an everything object that it didn't previously define. I assume the
 *   definition should he aa follows:
 */

/*
 *   MM: Eric -- this everything object was part of the original Test file; and I did not
 *   change it as it seemed to work
 */

everything: object
    lst()
    {
        local obj = firstObj(Thing);
        
        /* Create a vector to store our results. */
        local vec = new Vector;
        
        /* Go through every Thing in the game and add it to our vector. */
        do
        {
            vec.append(obj);
            obj = nextObj(obj, Thing);
        } while (obj!= nil);
        
        lst = vec.toList();
        return lst;
    }
    
;

DefineSystemAction(AssertPlayerInRoom)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst().subset({x:
            x.ofKind(Room)}));
    }

    execAction(cmd)
    {
        if (gActor.isPlayerChar && gRoom != gDobj) {
            allNewTests.fail('Expected player in room "<<gDobj>>" but was located in "<<gRoom>>"
                instead');
        }
        else
            allNewTests.succeed();
    }  
;

VerbRule(AssertPlayerInRoom)
	'assertPlayerInRoom' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerInRoom (what)'
    action = AssertPlayerInRoom
    missingQ = 'what room is player supposed to be in'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerHasItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{       
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allNewTests.fail('INVALID: Can never have item "<<gDobj>>"!<.p>');
        }
		else if (gActor.isPlayerChar && !gDobj.isIn(me)) {
            allNewTests.fail('Expected player to have item \"<<gDobj>>\" but does not!');
		}
        else
            allNewTests.succeed();
	}
;

VerbRule(AssertPlayerHasItem)
	'assertPlayerHasItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerHasItem (what)'
    action = AssertPlayerHasItem
    missingQ = 'what item is player supposed to have in possession'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerLacksItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{       
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allNewTests.fail('INVALID: Can never have item "<<gDobj>>"!');
        }
		else if (gActor.isPlayerChar && gDobj.isIn(me)) {
            allNewTests.fail('Expected player to NOT have item \"<<gDobj>>\" but
                does!');
		}
        else
            allNewTests.succeed();
	}
;

VerbRule(AssertPlayerLacksItem)
	'assertPlayerLacksItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerLacksItem (what)'
    action = AssertPlayerLacksItem
    missingQ = 'what item is player NOT supposed to have in possession'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerRoomHasItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allNewTests.fail('INVALID: Can never have item "<<gDobj>>"!<.p>');
        }
		else if (gActor.isPlayerChar && !gDobj.isIn(gActor.location)) {
            allNewTests.fail('Expected player\'s room to have item \"<<gDobj>>\" but does not!');
		}
        else
            allNewTests.succeed();
	}
;

VerbRule(AssertPlayerRoomHasItem)
	'assertPlayerRoomHasItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerRoomHasItem (what)'
    action = AssertPlayerRoomHasItem
    missingQ = 'what item is player\'s room supposed to contain'
;

///////////////////////////////////////////////

DefineSystemAction(AssertPlayerRoomLacksItem)
    
    /* For this action to work all known rooms also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(everything.lst());
    }

	execAction(cmd)
	{       
        if(gDobj.ofKind(Fixture) || gDobj.ofKind(Immovable) || gDobj.ofKind(Decoration)) {
            allNewTests.fail('INVALID: Can never have item "<<gDobj>>"!');
        }
		else if (gActor.isPlayerChar && gDobj.isIn(gActor.location)) {
            allNewTests.fail('Expected player\'s room not to have item \"<<gDobj>>\" but
                it does!');
		}
        else
            allNewTests.succeed();
	}
;

VerbRule(AssertPlayerRoomLacksItem)
	'assertPlayerRoomLacksItem' singleDobj
	: VerbProduction
	verbPhrase = 'assertPlayerRoomLacksItem (what)'
    action = AssertPlayerRoomLacksItem
    missingQ = 'what item should not be in player\'s room'
;

///////////////////////////////////////////////

DefineSystemAction(Assert)
    exec(cmd)
    {
        /* Recreate the literal text */
        local f = gCommandToks.cdr();
        local expr = f.join('');
        local msg = 'assert FAILED';
        local res = nil;
        expr = stripQuotesFrom(expr);
//        "Expr:<<expr>>:\n";
        try
        {
            /* 
             *   Try using the Compiler object to evaluate the expression
             *   contained in the name property of the direct object of this
             *   command (i.e. the string literal it was executed upon).
             */
            
            res = Compiler.eval(expr);
        }
        /* 
         *   If the attempt to evaluate the expression caused a compiler error,
         *   display the exception message.
         */
        catch (CompilerException cex)
        {           
            msg += ' with compiler exception';
        }
        
        /* 
         *   If the attempt to evaluate the expression caused any other kind of
         *   error, display the exception message.
         */
        catch (Exception ex)
        {
            msg += ' with unknown exception';
        }
        
        if(res == nil) {
            msg += ': <<expr>>';
            allNewTests.fail(msg);
        } else {
            // if do not clear this out, it processes the next token
            cmd.nextTokens = [];
            allNewTests.succeed();
        }
    }
;


VerbRule(Assert)
    'assert' literalDobj
    : VerbProduction
    action = Assert
    verbPhrase = 'assert (expression)'
    missingQ = 'what expression should be true'
;

///////////////////////////////////////////////

DefineSystemAction(AssertMsgClear)
    exec(cmd)
    {
        "Done.\n";
        allNewTests.lastMsg = '';
    }
;

VerbRule(AssertMsgClear)
    'assertMsgClear'
    : VerbProduction
    action = AssertMsgClear
    verbPhrase = 'assertMsgClear'
;

///////////////////////////////////////////////

DefineSystemAction(AssertMsg)
    exec(cmd)
    {
        local f = gCommandToks.cdr();
        local expr = f.join(' ').toLower();
        local fnd = allNewTests.lastMsg.toLower();

        if(fnd == nil) {
            allNewTests.fail('No message to check for "<<expr>>"');
        }
        else if(!fnd.find(expr)) {
            local msg = 'Message string mismatch:\n  found "<<fnd>>"\n';
            msg += '  expected "<<expr>>"';
            allNewTests.fail(msg);
        }
        else
            allNewTests.succeed();

        // message is CLEARED after testing so you don't stumble upon old messages
        allNewTests.lastMsg = '';
    }
;

VerbRule(AssertMsg)
    'assertMsg' literalDobj
    : VerbProduction
    action = AssertMsg
    verbPhrase = 'assertMsg (expression)'
    missingQ = 'what expression should be true'
;

///////////////////////////////////////////////
///////////////////////////////////////////////

/* 
 * Based upon the Test object in the TADS library, this overhauls it to actually work
 * and provide needed functionality for actually ASSERTing if something is correct
 * Moreover, the Test did not work and had issues with "leftovers" where each subsequent
 * test depended upon the results of the previous test!
 * 
 *
 *.  Test 'foo' ['x me', 'i', 'wear uniform'] [uniform] @location;
 *
 *   Would cause the uniform to be moved into the player character's inventory
 *   and then the commands X ME and then I and WEAR UNIFORM to be executed in
 *   response to TEST FOO.  Both the location and the inventory entries are optional
 */

class Test: object
    /* The name of this test */
    testName = 'nil'
    
    /* The list commands to be executed when running this test. */
    testList = [ 'z' ]
    
    /*   
     *   The objects to move into the player character's inventory before
     *   running the test script.
     */
    testHolding = []    // objects to move
    
    /* 
     *   The location to move the player character to before running the test
     *   script
     */
    location = nil
    
    /*  
     *   Flag: do we want to report on what items were added to inventory? By
     *   default we do.
     */
    reportHolding = true
	
    /* 
     *   Flag: Do we want to report any change of location by looking around in
     *   the new one? By default we will.
     */
    reportMove = true
    
    /*
     *   Restore game to where it was before this test.  
     *   The default value is nil.
     */   
    restoreStartStateAfterTest = nil
    
    /*
     *   If you need to restart the game BEFORE running the test
     *   activity and values
     */   
    restartBeforeTest = nil
    
    /*
     *   By default, we want to clear out the message buffer before each non-assert
     *   command, but you can change that for each test
     */   
    clearAssertBufferBeforeCmd = true

    /////////////////////
    
    /* Move everything in the testHolding list into the actor's inventory */
    getHolding()
    {
        foreach (local x in testHolding) {
            x.moveInto(gActor);
            x.isHidden = nil;   // otherwise cannot see or interact with it

        }
        
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
     *   Run this test by passing the commands into a script file to replay
     */
    run()
    {        
        "====================================\n";
        "Test: \"<<testName>>\"\n";

        if(restartBeforeTest) {
            local hld = allNewTests.savedState();
            if(allNewTests.restoregame(&restartSaveFile) == nil) {
                allNewTests.isTesting = nil;    // failed so quit the test
                return;
            }
            allNewTests.restoreState(hld);
        }

        /* we save the entire game at this point by default to restore it */
        if(restoreStartStateAfterTest)
            allNewTests.savegame(&revertSaveFile); // save the current state

        /* 
         *   If a location is specified, first move the actor into that
         *   location.
         */
        if (location && gPlayerChar.location != location)
        {
            gPlayerChar.moveInto(location);	
            
            /* If we want to report the move, show the new room description */
            if(reportMove)
                gPlayerChar.getOutermostRoom.lookAroundWithin();
        }
        
        /*   Move any required objects into the actor's inventory */
        getHolding();

        /* Export a file to use */
        local txt;
        local temp = new TemporaryFile();
        local f = File.openTextFile(temp, FileAccessWrite, 'ascii');

        local testVec = new Vector(testList);

        /*   Preparse and execute each command in the list */
        local linecnt = 0;
        testVec.forEach(new function(x)  {
            local c = x.trim();
            f.writeFile('><<c>>\n');
            ++linecnt;
        });
        f.closeFile();
        allNewTests.isTesting = true;
        setScriptFile(temp,ScriptFileNonstop);
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
                "<.inputline>";
                DMsg(command prompt, '>');
                txt = inputManager.getInputLine();
                "<./inputline>\n";   
                
                if(clearAssertBufferBeforeCmd && !txt.startsWith('assert'))
                    allNewTests.lastMsg = '';
                
                
                /* Pass the command through all our StringPreParsers */
                txt = StringPreParser.runAll(txt, Parser.rmcType());
                
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
 
        } while (--linecnt > 0 && allNewTests.isTesting);

        if(restoreStartStateAfterTest) {

            local hld = allNewTests.savedState();
            allNewTests.restoregame(&revertSaveFile); // restore the saved state
            allNewTests.restoreState(hld);
        }
        // this means an error happened so this script needs to go away
        if(!allNewTests.isTesting)
            setScriptFile(nil);
        temp.deleteFile();
    }
    
    /* 
     *   The test all command will run tests in ascending order of their test order. By default we
     *   use the sourceTextOrder.
     */
    testOrder = sourceTextOrder
;
    
/*
 *   The 'list tests' and 'list tests fully' commands can be used to list your
 *   test scripts from within the running game.
 */   
DefineSystemAction(GListTests)
    execAction(cmd)
    {
        if(allNewTests.lst.length == 0)
        {
            DMsg(no test scripts, 'There are no test scripts defined in this
                game. ');
            exit;
        }

        local fully = cmd.verbProd.fully;
        local sorted = cmd.verbProd.sorted;
        
        local testlist = allNewTests.lst;
        if(sorted) {
            testlist = testlist.sort(nil, { a, b: a.testName.compareTo(b.testName) });
        }
        
        foreach(local testObj in testlist)
        {
            "<<testObj.testName>>: ";
            if(fully)               
            {
                foreach(local txt in testObj.testList)
                    "<<txt>>/";
                "\n";
            } else {
                "restoreAfter=<<yesNo(testObj.restoreStartStateAfterTest)>>, ";
                "firstRestart=<<yesNo(testObj.restartBeforeTest)>>, ";
                "clearAssertBuff=<<yesNo(testObj.clearAssertBufferBeforeCmd)>>\n";
            }
        }
    }
    
    yesNo(bval) { return bval? 'yes' : 'no'; }
;

VerbRule(GListTests)
    ('list' | 'l') 'tests' (| 'fully' -> fully | 'sorted' -> sorted)
    : VerbProduction
    action = GListTests
    verbPhrase = 'list/listing test scripts'
;

/*
 *   The 'test X' command can be used with any Test object defined in the source
 *   code:
 */
DefineLiteralAction(GTest)
    /* 
     *   We override exec() rather than exeAction() here, since we want to skip
     *   all the normal turn sequence routines such as before and after
     *   notifications and advancing the turn count.
     */
    exec(cmd)
    {
        local target = cmd.dobj.name.toLower();
        local script = allNewTests.valWhich({x: x.testName.toLower == target});
        if (script) {
            allNewTests.totasserts = 0;
            allNewTests.fasserts = 0;
            script.run();
        }
        else
            DMsg(test sequence not found, 'Test sequence not found. ');
    }
    
    /* Do nothing after the main action */
    afterAction() { }
      
    turnSequence() { }
;

VerbRule(GTest)
    'test' literalDobj
    : VerbProduction
    action = GTest
    verbPhrase = 'test/testing (what)'
    missingQ = 'which sequence do you want to test'
;


////////////////////////////////////////////////

DefineSystemAction(TestAll)
    execAction(cmd)
    {
        if(allNewTests.lst.length == 0)
        {
            DMsg(no test scripts, 'There are no test scripts defined in this
                game. ');
            exit;
        }

        allNewTests.totasserts = 0;
        allNewTests.fasserts = 0;        
        
        local testenostop = cmd.verbProd.testnostop;
        local defstop = allNewTests.stopOnFail; // what it was
        if(testenostop)
            allNewTests.stopOnFail = nil;
        local cntr = 0;

        foreach(local testObj in allNewTests.lst)
        {
            ++cntr;
            testObj.run();
            if(allNewTests.stopOnFail && !allNewTests.isTesting)  // Houston, we have a problem
                break;
            allNewTests.isTesting = nil;
        }
        if(testenostop)
            allNewTests.stopOnFail = defstop;   // restore prior setting

        "===========================\n";
        "===========================\n";
        "Total tests: \ \ \ \ \ <<cntr>>\n";
        "Total asserts: \ \ <<allNewTests.totasserts>>\n";
        "Failed asserts: <<allNewTests.fasserts>>\n";
        "===========================<.p>";
    }
;

VerbRule(TestAll)
    'testall' (| 'nostop' -> testnostop)
    : VerbProduction
    action = TestAll
    verbPhrase = 'testall test scripts'
;


////////////////////////////////////////////////

/* 
 *   The allTests object contains a list of Test objects for listing via the
 *   LIST TESTS command, and for finding the test that corresponds to a
 *   particular testName.
 */
allNewTests: object
    
    // when set (the default), quit testing when failed assertion encountered
    stopOnFail = true
    
   lst()
   {
      if (lst_ == nil)
         initLst();
      return lst_;
   }

    initLst()
    {
        lst_ = new Vector(100);
        local obj = firstObj(Test);
        while (obj != nil)
        {
            lst_.append(obj);
            obj = nextObj(obj, Test);
        }
        lst_ = lst_.toList().sort(SortAsc, {x, y: x.testOrder - y.testOrder});
    }

   valWhich(cond)
   {
      return lst().valWhich(cond);
   }
    
    isTesting = nil     // indicator to tadsSay() about copying outcome here as well
    // last message(s) to copy here; reset before each non-test cmd or after assertMsg
    lastMsg = ''
    
    // counter of failed asserts and total asserts
    totasserts = 0
    fasserts = 0

    setLastMsg(msg) {
        msg = msg.specialsToText().trim();
        msg = msg.findReplace('\n',' ',ReplaceAll);
        msg = msg.findReplace('\b',' ',ReplaceAll).trim();
        // solves situation of multiple-multiple spaces
        while(msg.find('  ') != nil)
            msg = msg.findReplace('  ',' ',ReplaceAll);
        lastMsg += ' <<msg>>';  // just keep concantenating with space between
    }
    
    fail(msg) {
        ++totasserts;
        ++fasserts;
        isTesting = nil;        // signals the end of THIS test
        "<.p>###  <<msg>><.p>";
    }
    
    succeed(msg?) {
        if(msg == nil || msg == '')
            msg = 'Valid!';     // need to say something
        ++totasserts;
        "<<msg>><.p>";
    }

    // when undo() happens, it reverts all values to what they were prior to savepoint!
    savedState() { return [totasserts,fasserts,isTesting,restartSaveFile,revertSaveFile]; }
    restoreState(lst) {
        totasserts = lst[1];
        fasserts = lst[2];
        isTesting = lst[3];
        restartSaveFile = lst[4];
        revertSaveFile = lst[5];        
    }

    restartSaveFile = nil       // this gets created at the start of the game
    revertSaveFile = nil        // and this gets created during testing
    
//    init() { savegame(&restartSaveFile); }
    
    // exit with error if game cannot be saved
    savegame(fprop) {
        // only want to create temp file once per property per game
        local f = self.(fprop);
        
        if(f == nil)
            f = new TemporaryFile();
        try {
            saveGame(f);
        }
        catch (StorageServerError sse)
        {
            /* the save failed due to a storage server problem - explain */           
            DMsg(save failed on server, '<.parser>Failed, because of a problem
                accessing the storage server:
                <<makeSentence(sse.errMsg)>><./parser>');

            /* done */
            return;
        }
        catch (RuntimeError err)
        {
            /* the save failed - mention the problem */
            DMsg(save failed, '<.parser>Failed; your computer might be running
                low on disk space, or you might not have the necessary
                permissions to write this file.<./parser>');            
            
            /* done */
            return;
        }
        self.(fprop) = f;    // it worked
    }
   
    // return true if restored game ok, else nil
    restoregame(fprop) {
        if(self.(fprop) == nil) {
            "<.p>### No save file created!<.p>";
            return nil;
        }
        try
        {
            /* restore the file */
            restoreGame(self.(fprop));
        }
        catch (StorageServerError sse)
        {
            /* failed due to a storage server error - explain the problem */
            DMsg(restore failed on server,'<.parser>Failed, because of a problem
                accessing the storage server:
                <<makeSentence(sse.errMsg)>><./parser>');            

            /* indicate failure */
            return nil;
        }
        catch (RuntimeError err)
        {
            /* failed - check the error to see what went wrong */
            switch(err.errno_)
            {
            case 1201:
                /* not a saved state file */
                DMsg(restore invalid file, '<.parser>Failed: this is not a valid
                    saved position file.<./parser> ');                
                break;
                
            case 1202:
                /* saved by different game or different version */
                DMsg(restore invalid match, '<.parser>Failed: the file was not
                    saved by this story (or was saved by an incompatible version
                    of the story).<./parser> ');               
                break;
                
            case 1207:
                /* corrupted saved state file */
                DMsg(restore corrupted file, '<.parser>Failed: this saved state
                    file appears to be corrupted.  This can occur if the file
                    was modified by another program, or the file was copied
                    between computers in a non-binary transfer mode, or the
                    physical media storing the file were damaged.<./parser> ');                
                break;
                
            default:
                /* some other failure */
                DMsg(restore failed, '<.parser>Failed: the position could not be
                    restored.<./parser>');                
                break;
            }

            /* indicate failure */
            return nil;
        }
               
        /* set the appropriate restore-action code */
        PostRestoreObject.restoreCode = 2;  // user restore

        /* notify all PostRestoreObject instances */
        PostRestoreObject.classExec();

        /* Ensure the current actor is defined. */
        gActor = gActor ?? gPlayerChar;
        
        return true;
    }
   
    lst_ = nil  // the tests that are found
;

/* Modificatiion to allow assert to test for the presence of particular strings in game output. */
modify aioSay(txt)
{
    if(allNewTests.isTesting)
    {       
        allNewTests.setLastMsg(txt);        
    }
    
    replaced(txt);
}

/* Create a save file at game startup to allow a Test to restore before running. */
testInit: InitObject
   testRestart = true
   execute()
   {
      if(testRestart)
          allNewTests.savegame(&restartSaveFile);
   }
;



#endif // __DEBUG


