#charset "us-ascii"
#include "advlite.h"

/*
 *   ************************************************************************
 *   actor.t This module forms part of the adv3Lite library
 *.  (c) 2012-13 Eric Eve.
 *.  Based substantially on input.t in the adv3 library
 *.  Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved.
 *
 *
 *
 *   This modules defines functions and objects related to reading input from
 *   the player.
 */



/* ------------------------------------------------------------------------ */
/*
 *   Keyboard input parameter definition. 
 */
class InputDef: object
    /* 
     *   The prompt function.  This is a function pointer (which is
     *   frequently given as an anonymous function) or nil; if it's nil,
     *   we won't show any prompt at all, otherwise we'll call the
     *   function pointer to display a prompt as needed. 
     */
    promptFunc = nil

    
    /* 
     *   Begin the input style.  This should do anything required to set
     *   the font to the desired attributes for the input text.  By
     *   default, we'll simply display <.inputline> to set up the default
     *   input style.  
     */
    beginInputFont() { "<.inputline>"; }

    /* 
     *   End the input style.  By default, we'll close the <.inputline>
     *   that we opened in beginInputFont(). 
     */
    endInputFont() { "<./inputline>"; }
;

/*
 *   Basic keyboard input parameter definition.  This class defines
 *   keyboard input parameters with the real-time status and prompt
 *   function specified via the constructor.  
 */
class BasicInputDef: InputDef
    construct(promptFunc)   
    {
        self.promptFunc = promptFunc;
    }
;


/* ------------------------------------------------------------------------ */
/*
 *   Keyboard input manager. 
 */
inputManager: PostRestoreObject
    /*
     *   Read a line of input from the keyboard.
     *
     *   promptFunc can either be a callback function to invoke to display the
     *   prompt, or a single-quoted string containing the prompt. Of course, the
     *   caller can simply display the prompt before calling this routine rather
     *   than passing in a prompt callback, if desired.
     *
     *   If we're in HTML mode, this will switch into the 'tads-input' font
     *   while reading the line, so this routine should be used wherever
     *   possible rather than calling inputLine() or inputLineTimeout()
     *   directly.
     */
    getInputLine(promptFunc?)
    {
        /* read input using a basic InputDef for the given parameters */
        return getInputLineExt(new BasicInputDef(promptFunc));
    }

    /*
     *   Read a line of input from the keyboard - extended interface,
     *   using the InputDef object to define the input parameters.
     *   'defObj' is an instance of class InputDef, defining how we're to
     *   handle the input.  
     */
    getInputLineExt(defObj)
    {

        /* 
         *   If a previous input was in progress, cancel it - this must be
         *   a recursive entry from a real-time event that's interrupting
         *   the enclosing input attempt. Simply cancel out the enclosing
         *   read attempt entirely in this case; if and when we return to
         *   the enclosing reader, that reader will start over with a
         *   fresh read attempt at that point.  
         */
        cancelInputInProgress(true);
        
        /* 
         *   Keep going until we finish reading the command.  We might
         *   have to try several times, because our attempts might be
         *   interrupted by real-time events. 
         */
        for (;;)
        {
            local result;
            local timeout;


            /* show the prompt and any pre-input codes */
            inputLineBegin(defObj);

        getInput:
            /* 
             *   Read the input.  (Note that if our timeout is nil, this
             *   will simply act like the ordinary untimed inputLine.)  
             */
            result = aioInputLineTimeout(timeout);

            
            /* check the event code from the result list */
            switch(result[1])
            {
            case InEvtNoTimeout:
                /* 
                 *   the platform doesn't support timeouts - note it for
                 *   future reference so that we don't ask for input with
                 *   timeout again, then go back to try the input again
                 *   without a timeout 
                 */
                noInputTimeout = true;
                timeout = nil;
                goto getInput;
            
            case InEvtLine:
                /* we've finished the current line - end input mode */
                inputLineEnd();

                /* return the line of text we got */
                return result[2];
            
            case InEvtTimeout:
                /* 
                 *   We got a timeout without finishing the input line.
                 *   This means that we've reached the time when the next
                 *   real-time event is ready to execute.  Simply continue
                 *   looping; we'll process all real-time events that are
                 *   ready to go, then we'll resume reading the command.  
                 *   
                 *   Before we proceed, though, notify the command
                 *   sequencer (via the command-interrupt pseudo-tag) that
                 *   we're at the start of output text after an interrupted
                 *   command line input 
                 */
                "<.commandint>";
                break;
            
            case InEvtEof:
                /* 
                 *   End of file - this indicates that the user has closed
                 *   down the application, or that the keyboard has become
                 *   unreadable due to a hardware or OS error.
                 *   
                 *   Write a blank line to the display in an attempt to
                 *   flush any partially-entered command line text, then
                 *   throw an error to signal the EOF condition.  
                 */
                "\b";
                throw new EndOfFileException();

            case InEvtEndQuietScript:
                /* 
                 *   End of "quiet" script - this indicates that we've
                 *   been reading input from a script file, but we've now
                 *   reached the end of that file and are about to return
                 *   to reading from the keyboard.
                 *   
                 *   "Quiet script" mode causes all output to be hidden
                 *   while the script is being processed.  This means that
                 *   we won't have displayed a prompt for the current
                 *   line, or updated the status line.  We'll
                 *   automatically display a new prompt when we loop back
                 *   for another line of input, but we have to mark the
                 *   current input line as actually ended now for that to
                 *   happen.  
                 */
                inputLineInProgress = nil;
                inProgressDefObj = nil;

                /* 
                 *   update the status line, since the quiet script mode
                 *   will have suppressed all status line updates while we
                 *   were reading the script, and thus the last update
                 *   before this prompt won't have been shown 
                 */
                statusLine.showStatusLine();

                /* back for more */
                break;

            case 'newGuest':
                /* 
                 *   Synthetic "new guest" event from the Web UI.  This
                 *   indicates that a new user has joined the session.  The
                 *   parameter is the new user's screen name.  Announce the
                 *   new user's arrival as a real-time event, and go back
                 *   to reading input.  
                 */
                "<.commandint>";
                libMessages.webNewUser(result[2]);
                break;

            case 'logError':
                /*
                 *   Synthetic "log error" event from the Web UI.  The UI
                 *   posts this type of an event when an error occurs in an
                 *   asynchronous task, where it's not possible to display
                 *   an error message directly. 
                 */
                "<.commandint>\b<<result[2]>>\b";
                break;
            }
        }
    }

    /*
     *   Pause for a MORE prompt.            
     */
    pauseForMore()
    {
        /* run the MORE prompt */
        aioMorePrompt();
    }

    /*
     *   Ask for an input file. 
     */
    getInputFile(prompt, dialogType, fileType, flags)
    {
       
        /* ask for a file */
        local result = aioInputFile(prompt, dialogType, fileType, flags);

        /* return the result from inputFile */
        return result;
    }

    /*
     *   Ask for input through a dialog.    The arguments are the same as for
     *   the built-in inputDialog() function.
     */
    getInputDialog(icon, prompt, buttons, defaultButton, cancelButton)
    {       
        /* show the dialog */
        local result = aioInputDialog(icon, prompt, buttons,
                                      defaultButton, cancelButton);

        /* return the dialog result */
        return result;
    }
    

    /*
     *   Read a keystroke, processing real-time events while waiting.
     *   'promptFunc' works the same way it does with getInputLine().
     */
    getKey(promptFunc?)
    {
        local evt;
        
        /* get an event */
        evt = getEventOrKey(promptFunc, true);

        /* 
         *   the only event that getEventOrKey will return is a keystroke,
         *   so return the keystroke from the event record 
         */
        return evt[2];
    }

    /*
     *   Read an event, processing real-time events while waiting, if
     *   desired.  'allowRealTime' and 'promptFunc' work the same way they
     *   do with getInputLine().  
     */
    getEvent(promptFunc?)
    {
        /* read and return an event */
        return getEventOrKey(promptFunc, nil);
    }

    /*
     *   Read an event or keystroke.  'promptFunc' works the same way it does in
     *   getInputLine().  If 'keyOnly' is true, then we're only interested in
     *   keystroke events, and we'll ignore any other events entered.
     *
     *   Note that this routine is not generally called directly; callers should
     *   usually call the convenience routines getKey() or getEvent(), as
     *   needed.
     */
    getEventOrKey(promptFunc, keyOnly)
    {
        
        /* 
         *   Cancel any in-progress input.  If there's an in-progress
         *   input, a real-time event must be interrupting the input,
         *   which is recursively invoking us to start a new input. 
         */
        cancelInputInProgress(true);
        
        /* keep going until we get a keystroke or other event */
        for (;;)
        {
            local result;
            local timeout;


            /* show the prompt and any pre-input codes */
            inputEventBegin(promptFunc);

        getInput:
            /* 
             *   Read the input.  (Note that if our timeout is nil, this
             *   will simply act like the ordinary untimed inputLine.)  
             */
            result = aioInputEvent(timeout);
           

            /* check the event code from the result list */
            switch(result[1])
            {
            case InEvtNoTimeout:
                /* 
                 *   the platform doesn't support timeouts - note it for
                 *   future reference so that we don't ask for input with
                 *   timeout again, then go back to try the input again
                 *   without a timeout 
                 */
                noInputTimeout = true;
                timeout = nil;
                goto getInput;
            
            case InEvtTimeout:
                /* 
                 *   We got a timeout without finishing the input line.
                 *   This means that we've reached the time when the next
                 *   real-time event is ready to execute.  Simply continue
                 *   looping; we'll process all real-time events that are
                 *   ready to go, then we'll restart the event wait.
                 */
                break;
            
            case InEvtEof:
                /* 
                 *   End of file - this indicates that the user has closed
                 *   down the application, or that the keyboard has become
                 *   unreadable due to a hardware or OS error.
                 *   
                 *   Write a blank line to the display in an attempt to
                 *   flush any partially-entered command line text, then
                 *   throw an error to signal the EOF condition.  
                 */
                "\b";
                throw new EndOfFileException();

            case InEvtKey:
                /* keystroke - finish the input and return the event */
                inputEventEnd();
                return result;

            case InEvtHref:
                /* 
                 *   Hyperlink activation - if we're allowed to return
                 *   events other than keystrokes, finish the input and
                 *   return the event; otherwise, ignore the event and keep
                 *   looping.  
                 */
                if (!keyOnly)
                {
                    inputEventEnd();
                    return result;
                }
                break;

            default:
                /* ignore other events */
                break;
            }
        }
    }

    /*
     *   Cancel input in progress.
     *   
     *   If 'reset' is true, we'll clear any input state saved from the
     *   interrupted in-progress editing session; otherwise, we'll retain
     *   the saved editing state for restoration on the next input.
     *   
     *   This MUST be called before calling tadsSay().  Games should
     *   generally never call tadsSay() directly (call the library
     *   function say() instead), so in most cases authors will not need
     *   to worry about calling this on output.
     *   
     *   This MUST ALSO be called before performing any keyboard input.
     *   Callers using inputManager methods for keyboard operations won't
     *   have to worry about this, because the inputManager methods call
     *   this routine when necessary.  
     */
    cancelInputInProgress(reset)
    {
        /* cancel the interpreter's internal input state */
        aioInputLineCancel(reset);

        /* if we were editing a command line, terminate the editing session */
        if (inputLineInProgress)
        {
            /* do our normal after-input work */
            inputLineEnd();
        }

        /* if we were waiting for event input, note that we are no longer */
        if (inputEventInProgress)
        {
            /* do our normal after-input work */
            inputEventEnd();
        }
    }

    

    /*
     *   Begin reading key/event input.  We'll cancel any report gatherer
     *   so that prompt text shows immediately, and show the prompt if
     *   desired.  
     */
    inputEventBegin(promptFunc)
    {
        /* if we're not continuing previous input, show the prompt */
        if (!inputEventInProgress)
        {
            inputBegin(promptFunc);

            /* note that we're in input mode */
            inputEventInProgress = true;
        }
    }

    /*
     *   End keystroke/event input.
     */
    inputEventEnd()
    {
        /* if input is in progress, terminate it */
        if (inputEventInProgress)
        {
            /* note that we're no longer reading an event */
            inputEventInProgress = nil;
        }
    }

    /*
     *   Begin command line editing.  If we're in HTML mode, we'll show
     *   the appropriate codes to establish the input font.  
     */
    inputLineBegin(defObj)
    {
        /* notify the command sequencer that we're reading a command */
        "<.commandbefore>";
        
        /* if we're not resuming a session, set up a new session */
        if (!inputLineInProgress)
        {
            /* begin input */
            inputBegin(defObj.promptFunc);
            
            /* switch to input font */
            defObj.beginInputFont();

            /* note that we're in input mode */
            inputLineInProgress = true;

            /* remember the parameter object for this input */
            inProgressDefObj = defObj;
        }
    }

    /*
     *   End command line editing.  If we're in HTML mode, we'll show the
     *   appropriate codes to close the input font.  
     */
    inputLineEnd()
    {
        /* if input is in progress, terminate it */
        if (inputLineInProgress)
        {
            /* note that we're no longer reading a line of input */
            inputLineInProgress = nil;

            /* end input font mode */
            inProgressDefObj.endInputFont();

            /* notify the command sequencer that we're done reading */
            "<.commandafter>";

            /* 
             *   tell the main text area's output stream that we just
             *   ended an input line 
             */
            mainOutputStream.inputLineEnd();

            /* forget the parameter object for the input */
            inProgressDefObj = nil;
        }
    }

    /*
     *   Begin generic input.  Cancels command report list capture, and
     *   shows the prompt if given.  
     */
    inputBegin(promptFunc)
    {        
        switch(dataTypeXlat(promptFunc))
        {
            /* if we have a prompt, display it */
        case TypeSString:
            say(promptFunc);
            break;
        case TypeFuncPtr:         
            (promptFunc)();
            break;
        default:
            /* Do nothing */
            break;
        }
    }
    
    /* receive post-restore notification */
    execute()
    {
        /* 
         *   Reset the inputLine state.  If we had any previously
         *   interrupted input from the current interpreter session, forget
         *   it by canceling and resetting the input line.  If we had an
         *   interrupted line in the session being restored, forget about
         *   that, too.  
         */
        aioInputLineCancel(true);
        inputLineInProgress = nil;
        inputEventInProgress = nil;

        /* 
         *   Clear the inputLineTimeout disabling flag - we might be
         *   restoring the game on a different platform from the one where
         *   the game started, so we might be able to use timed command
         *   line input even if we didn't when we started the game.  By
         *   clearing this flag, we'll check again to see if we can
         *   perform timed input; if we can't, we'll just set the flag
         *   again, so there will be no harm done.  
         */
        noInputTimeout = nil;
    }

    /* 
     *   Flag: command line input is in progress.  If this is set, it means
     *   that we interrupted command-line editing by a timeout, so we
     *   should not show a prompt the next time we go back to the keyboard
     *   for input.  
     */
    inputLineInProgress = nil

    /* the InputDef object for the input in progress */
    inProgressDefObj = nil

    /* flag: keystroke/event input is in progress */
    inputEventInProgress = nil

    /*
     *   Flag: inputLine does not support timeouts on the current platform.
     *   We set this when we get an InEvtNoTimeout return code from
     *   inputLineTimeout, so that we'll know not to try calling again with
     *   a timeout.  This applies to the current interpreter only, so we
     *   must ignore any value restored from a previously saved game, since
     *   the game might have been saved on a different platform.
     *   
     *   Note that if this value is nil, it means only that we've never
     *   seen an InEvtNoTimeout return code from inputLineEvent - it does
     *   NOT mean that timeouts are supported locally.
     *   
     *   We assume that the input functions are uniform in their treatment
     *   of timeouts; that is, we assume that if inputLineTimeout supports
     *   timeout, then so does inputEvent, and that if one doesn't support
     *   timeout, the other won't either.  
     */
    noInputTimeout = nil
;



/* ------------------------------------------------------------------------ */
/*
 *   End-of-file exception - this is thrown when readMainCommand()
 *   encounters end of file reading the console input. 
 */
class EndOfFileException: Exception
;


/* ------------------------------------------------------------------------ */
/*
 *   'Quitting' exception.  This isn't an error - it merely indicates that
 *   the user has explicitly asked to quit the game. 
 */
class QuittingException: Exception
;

/* ------------------------------------------------------------------------ */
/*
 *   Base class for command input string preparsers.
 *   
 *   Preparsers must be registered in order to run.  During
 *   preinitialization, we will automatically register any existing
 *   preparser objects; preparsers that are created dynamically during
 *   execution must be registered explicitly, which can be accomplished by
 *   inheriting the default constructor from this class.  
 */
class StringPreParser: PreinitObject
    /*
     *   My execution order number.  When multiple preparsers are
     *   registered, we'll run the preparsers in ascending order of this
     *   value (i.e., smallest runOrder goes first).  
     */
    runOrder = 100

    /*
     *   Do our parsing.  Each instance should override this method to
     *   define the parsing that it does.
     *   
     *   'str' is the string to parse, and 'which' is the rmcXxx enum
     *   giving the type of command we're working with.
     *   
     *   This method returns a string or nil.  If the method returns a
     *   string, the caller will forget the original string and work from
     *   here on out with the new version returned; this allows the method
     *   to rewrite the original input as desired.  If the method returns
     *   nil, it means that the string has been fully handled and that
     *   further parsing of the same string is not desired.  
     */
    doParsing(str, which)
    {
        /* return the original string unchanged */
        return str;
    }

    /* 
     *   construction - when we dynamically create a preparser, register
     *   it by default
     */
    construct()
    {
        /* register the preparser */
        StringPreParser.registerPreParser(self);
    }

    /* run pre-initialization */
    execute()
    {
        /* register the preparser if it's not already registered */
        StringPreParser.registerPreParser(self);
    }

    /* register a preparser */
    registerPreParser(pp)
    {
        /* if the preparser isn't already in our list, add it */
        if (regList.indexOf(pp) == nil)
        {
            /* append this new item to the list */
            regList.append(pp);

            /* the list is no longer sorted */
            regListSorted = nil;
        }
    }

    /*
     *   Class method - Run all preparsers.  Returns the result of
     *   successively calling each preparser on the given string.  
     */
    runAll(str, which)
    {
        /* 
         *   if the list of preparsers isn't sorted, sort it in ascending
         *   order of execution order number
         */
        if (!regListSorted)
        {
            /* sort the list */
            regList.sort(SortAsc, {x, y: x.runOrder - y.runOrder});
            
            /* the list is now sorted */
            regListSorted = true;
        }

        /* run each preparser */
        foreach (local cur in regList)
        {
            /* run this preparser, provided it's active */
            if(cur.isActive)
                str = cur.doParsing(str, which);

            /* 
             *   if the result is nil, it means that the string has been
             *   fully handled, so we need not run any further preparsing 
             */
            if (str == nil)
                return nil;
        }

        /* return the result of the series of preparsing steps */
        return str;
    }

    /* class property containing the list of registered parsers */
    regList = static new Vector(10)

    /* class property - the registration list has been sorted */
    regListSorted = nil
    
    /* Flag, is this PreParser active? */
    isActive = true
;

/* ------------------------------------------------------------------------ */
/*
 *   The "comment" pre-parser.  If the command line starts with a special
 *   prefix string (by default, "*", but this can be changed via our
 *   commentPrefix property), this pre-parser intercepts the command,
 *   treating it as a comment from the player and otherwise ignoring the
 *   entire input line.  The main purpose is to give players a way to put
 *   comments into recorded transcripts, as notes to themselves when later
 *   reviewing the transcripts or as notes to the author when submitting
 *   play-testing feedback.  
 */
commentPreParser: StringPreParser
    doParsing(str, which)
    {
        /* get the amount of leading whitespace, so we can ignore it */
        local sp = rexMatch(leadPat, str);
        
        /* 
         *   if the command line starts with the comment prefix, treat it
         *   as a comment 
         */
        if (str.substr(sp + 1, commentPrefix.length()) == commentPrefix)
        {
            /*
             *   It's a comment.
             *   
             *   If a transcript is being recorded, simply acknowledge the
             *   comment; if not, acknowledge it, but with a warning that
             *   the comment isn't being saved anywhere 
             */
            if (scriptStatus.scriptFile != nil)
                DMsg(note with script, 'Comment recorded. ');
            else if (warningCount++ == 0)
                DMsg(note without script warning, 'Comment NOT recorded. ');
            else
                DMsg(note without script, 'Comment NOT recorded. ');

            /* 
             *   Otherwise completely ignore the command line.  To do this,
             *   simply return nil: this tells the parser that the command
             *   has been fully handled by the preparser. 
             */
            return nil;
        }
        else
        {
            /* it's not a command - return the string unchanged */
            return str;
        }
    }

    /* 
     *   The comment prefix.  You can change this to any character, or to
     *   any sequence of characters (longer sequences, such as '//', will
     *   work fine).  If a command line starts with this exact string (or
     *   starts with whitespace followed by this string), we'll consider
     *   the line to be a comment.  
     */
    commentPrefix = '*'
    
    /* 
     *   The leading-whitespace pattern.  We skip any text that matches
     *   this pattern at the start of a command line before looking for the
     *   comment prefix.
     *   
     *   If you don't want to allow leading whitespace before the comment
     *   prefix, you can simply change this to '' - a pattern consisting of
     *   an empty string always matches zero characters, so it will prevent
     *   us from skipping any leading charactres in the player's input.  
     */
    leadPat = static new RexPattern('<space>*')

    /* warning count for entering comments without SCRIPT in effect */
    warningCount = 0

    /*
     *   Use a lower execution order than the default, so that we run
     *   before most other pre-parsers.  Most other pre-parsers are written
     *   to handle actual commands, so it's usually just a waste of time to
     *   have them look at comments at all - and can occasionally be
     *   problematic, since the free-form text of a comment could confuse a
     *   pre-parser that's expecting a more conventional command format.
     *   When the comment pre-parser detects a comment, it halts any
     *   further processing of the command - so by running ahead of other
     *   pre-parsers, we'll effectively bypass other pre-parsers when we
     *   detect a comment.  
     */
    runOrder = 50
;


