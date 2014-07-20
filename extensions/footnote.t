#charset "us-ascii"

/* 
 *   FOOTNOTE EXTENSION
 *
 *   Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved. 
 *   
 *   TADS 3 Library - footnotes
 *   
 *   This module defines objects related to footnotes.  
 *
 *   Slightly modified for use with adv3Lite by Eric Eve
 */

/* include the library header */
#include "advlite.h"


/* ------------------------------------------------------------------------ */
/*
 *   Footnote - this allows footnote references to be generated in
 *   displayed text, and the user to retrieve the contents of the footnote
 *   on demand.
 *   
 *   Create an instance of Footnote for each footnote.  For each footnote
 *   object, define the "desc" property as a double-quoted string (or
 *   method) displaying the footnote's contents.
 *   
 *   To display a footnote reference in a passage of text, call
 *   <<x.noteRef>>, where x is the footnote object in question.  That's all
 *   you have to do - we'll automatically assign the footnote a sequential
 *   number (so that footnote references are always seen by the player in
 *   ascending order, regardless of the order in which the player
 *   encounters the sources of the footnotes), and the NOTE command will
 *   automatically figure out which footnote object is involved for a given
 *   footnote number.
 *   
 *   This class also serves as a daemon notification object to receive
 *   per-command daemon calls.  The first time we show a footnote
 *   reference, we'll show an explanation of how footnotes work.  
 *
 *   [ONLY IN FOOTNOTE EXTENSION]
 */
class Footnote: object
    /* 
     *   Display the contents of the footnote - this will be called when
     *   the user asks to show the footnote with the "NOTE n" command.
     *   Each instance must provide suitable text here.  
     */
    desc = ""

    /*
     *   Get a reference to the footnote for use in a passage of text.
     *   This returns a single-quoted string to display as a reference to
     *   the footnote.  
     */
    noteRef
    {
               
        /* 
         *   if we haven't already assigned a number to this footnote,
         *   assign one now 
         */
        if (footnoteNum == nil)
        {
            /* 
             *   Allocate a new footnote number and remember it as our
             *   own.  Note that we want the last footnote number for all
             *   footnotes, so use the Footnote class property
             *   lastFootnote. 
             */
            footnoteNum = ++(Footnote.lastFootnote);

            /* 
             *   add myself to the class's list of numbered notes, so we
             *   can find this footnote easily again given its number 
             */
            Footnote.numberedFootnotes.append(self);

            /* note that we've generated a footnote reference */
            Footnote.everShownFootnote = true;
        }

        /* 
         *   If we're allowed to show footnotes, return the library
         *   message text to display given the note number.  If all
         *   footnotes are being hidden, or if we're only showing new
         *   footnotes and we've already read this one, return an empty
         *   string.  
         */
        switch(footnoteSettings.showFootnotes)
        {
        case FootnotesFull:
            /* we're showing all footnotes unconditionally */
            return footnoteRef(footnoteNum);

        case FootnotesMedium:
            /* we're only showing unread footnotes */
            return footnoteRead ? '' : footnoteRef(footnoteNum);

        case FootnotesOff:
            /* we're hiding all footnotes unconditionally */
            return '';
        }

        /* 
         *   in case the status is invalid and we fall through, return an
         *   empty string as a last resort
         */
        return '';
    }

    /* get the string to display for a footnote reference */
    footnoteRef(num)
    {
        /* set up a hyperlink for the note that enters the "note n" command */
        return BMsg(footnote ref, '<sup>[<<aHref('footnote ' + num, 
                                                 toString(num))>>]</sup>');
    }
    
    
    /*
     *   Display a footnote given its number.  If there is no such
     *   footnote, we'll display an error message saying so.  (This is a
     *   class method, so it should be called directly on Footnote, not on
     *   instances of Footnote.)  
     */
    showFootnote(num)
    {
        /* 
         *   if there's a footnote for this number, display it; otherwise,
         *   display an error explaining that the footnote number is
         *   invalid 
         */
        if (num >= 1 && num <= lastFootnote)
        {
            local fn;

            /* 
             *   it's a valid footnote number - get the footnote object
             *   from our vector of footnotes, simply using the footnote
             *   number as an index into the vector
             */
            fn = numberedFootnotes[num];

            /* show its description by calling 'desc' method */
            fn.desc;

            /* note that this footnote text has been read */
            fn.footnoteRead = true;
        }
        else
        {
            /* there is no such footnote */
             DMsg(no such footnote, '<.parser>The story has never referred to
                 any such footnote.<./parser> ');
        }
    }

    /* SettingsItem tracking our current status */
    footnoteSettings = footnoteSettingsItem

    /* 
     *   my footnote number - this is assigned the first time I'm
     *   referenced; initially we have no number, since we don't want to
     *   assign a number until the note is first referenced 
     */
    footnoteNum = nil

    /* 
     *   Flag: this footnote's full text has been displayed.  This refers
     *   to the text of the footnote itself, not the reference, so this is
     *   only set when the "FOOTNOTE n" command is used to read this
     *   footnote.  
     */
    footnoteRead = nil

    /*
     *   Static property: the highest footnote number currently in use.
     *   We start this at zero, because zero is never a valid footnote
     *   number.  
     */
    lastFootnote = 0

    /*
     *   Static property: a vector of all footnotes which have had numbers
     *   assigned.  We use this to find a footnote object given its note
     *   number.  
     */
    numberedFootnotes = static new Vector(20)

    /* static property: we've never shown a footnote reference before */
    everShownFootnote = nil

    /* static property: per-command-prompt daemon entrypoint */
    checkNotification()
    {
        /*
         *   If we've ever shown a footnote, show the footnote
         *   notification now.  Note that we know we've never shown a
         *   notification before simply because we're still running - we
         *   remove this daemon as soon as it shows its notification.  
         */
        if (everShownFootnote)
        {
            /* show the first footnote notification */
            DMsg(first footnote,  'A number in [square brackets] like the one
                above refers to a footnote, which you can read by typing
                FOOTNOTE followed by the number: <<aHref('footnote 1',
                    'FOOTNOTE 1', 'Show footnote [1]')>>, for example.
                Footnotes usually contain added background information that
                might be interesting but isn&rsquo;t essential to the story. If
                you&rsquo;d prefer not to see footnotes at all, you can control
                their appearance by typing <<aHref('footnotes', 'FOOTNOTES', 
                                                   'Control footnote
        appearance')>>.');

            /* 
             *   We only want to show this notification once in the whole
             *   game, so we can cancel this daemon now.  Since we're the
             *   event that's running, we can just tell the event manager
             *   to remove the current event from receiving further
             *   notifications.  
             */
            eventManager.removeCurrentEvent();
        }
    }
;

/* our FOOTNOTES settings item [FOOTNOTE EXTENSION]*/
footnoteSettingsItem: object
    /* our current status - the factory default is "medium" */
    showFootnotes = FootnotesMedium
   
    /* 
     * get the setting's external file string representation 
     * [FOOTNOTE EXTENSION]  
     */
    settingToText()
    {
        switch(showFootnotes)
        {
        case FootnotesMedium:
            return 'medium';
            
        case FootnotesFull:
            return 'full';
            
        default:
            return 'off';
        }
    }

    settingFromText(str)
    {
        /* convert to lower-case and strip off spaces */
        if (rexMatch('<space>*(<alpha>+)', str.toLower()) != nil)
            str = rexGroup(1)[3];
        
        /* check the keyword */
        switch (str)
        {
        case 'off':
            showFootnotes = FootnotesOff;
            break;
            
        case 'medium':
            showFootnotes = FootnotesMedium;
            break;
            
        case 'full':
            showFootnotes = FootnotesFull;
            break;
        }
    }
;

/* 
 * pre-initialization - set up the footnote explanation daemon 
 * [FOOTNOTE EXTENSION]
 */
footnotePreinit: PreinitObject
    execute()
    {
        /* since we're available, register as the global footnote handler */
        libGlobal.footnoteClass = Footnote;

        /* initialize the footnote notification daemon */
        new PromptDaemon(Footnote, &checkNotification);
    }
;

/*  
 *  This VerbRule is defined directly in the FOOTNOTE
 *  extension.
 *
 *  Note to translators: the following VerbRules are defined directly in
 *  the FOOTNOTES extension file since it would be awkward to put them
 *  anywhere else. When translating, define an additional language-specific
 *  file (e.g. footnotes_fr.t or footnotes_de.t) and in it include (a)
 *  your language-specific modifications to the following VerbRules
 *  (using modify VerbRule) and (b) a CustomMessages object containing
 *  translations of any DMsg and BMsg text used in this extension. Then
 *  instruct users to include your language-specific file after this one.
 */
VerbRule(Footnote)
    ('footnote' | 'note') literalDobj
    : VerbProduction
    action = FootnoteAction
    verbPhrase = 'show/showing a footnote'
;


VerbRule(FootnotesFull)
    'footnotes' 'full'
    : VerbProduction
    action = FootnotesFullAction
    verbPhrase = 'enable/enabling all footnotes'
;

VerbRule(FootnotesMedium)
    'footnotes' 'medium'
    : VerbProduction
    action = FootnotesMediumAction
    verbPhrase = 'enable/enabling new footnotes'
;

VerbRule(FootnotesOff)
    'footnotes' 'off'
    : VerbProduction
    action = FootnotesOffAction
    verbPhrase = 'hide/hiding footnotes'
;

VerbRule(FootnotesStatus)
    'footnotes'
    : VerbProduction
    action = FootnotesStatus
    verbPhrase = 'show/showing footnote status'
;




/*
 *   Footnote -   
 */
DefineSystemAction(FootnoteAction)
    execAction(c)
    {
        /* ask the Footnote class to do the work */
        if (libGlobal.footnoteClass != nil)
        {
            local num = tryInt(c.dobj.name);
            if(num)
               libGlobal.footnoteClass.showFootnote(num);
            else
                DMsg(invalid footnote number, '<q>\^{1}</q> is not a valid
                    footnote number. ', c.dobj.name);
        }
        else
            commandNotPresent();
    }

    /* there's no point in including this in undo */
    includeInUndo = nil
;


/* base class for FOOTNOTES xxx commands */
DefineSystemAction(Footnotes)
    execAction(c)
    {
        if (libGlobal.footnoteClass != nil)
        {
            /* set my footnote status in the global setting */
            libGlobal.footnoteClass.footnoteSettings.showFootnotes =
                showFootnotes;

            /* acknowledge it */
            acknowledgeFootnoteStatus(showFootnotes);
        }
        else
            commandNotPresent();
    }

    /* 
     *   the footnote status I set when this command is activated - this
     *   must be overridden by each subclass 
     */
    showFootnotes = nil
    
    acknowledgeFootnoteStatus(stat)
    {
        DMsg(acknowledge footnote status, '<.parser>The setting is now {1}.
            <./parser>', shortFootnoteStatus(stat));
    }

    /* show the footnote status, in short form */
    shortFootnoteStatus(stat)
    {
        local msg = BMsg(footnotes, 'FOOTNOTES ');
        
        msg += (stat == FootnotesOff ? BMsg(footnote off, 'OFF')
          : stat == FootnotesMedium ? BMsg(footnote medium, 'MEDIUM')
          : BMsg(footnote full, 'FULL'));
        
        return msg;
    }
;

DefineAction(FootnotesFullAction, Footnotes)
    showFootnotes = FootnotesFull
;

DefineAction(FootnotesMediumAction, Footnotes)
    showFootnotes = FootnotesMedium
;

DefineAction(FootnotesOffAction, Footnotes)
    showFootnotes = FootnotesOff
;

DefineSystemAction(FootnotesStatus)
    execAction(c)
    {
        /* show the current status */
        if (libGlobal.footnoteClass != nil)
            showFootnoteStatus(libGlobal.footnoteClass.
                                            footnoteSettings.showFootnotes);
        else
            commandNotPresent();
    }

    /* there's no point in including this in undo */
    includeInUndo = nil
    
    showFootnoteStatus(stat)
    {
        "The current setting is FOOTNOTES ";
        switch(stat)
        {
        case FootnotesOff:
            DMsg(show footnotes off,
            'OFF, which hides all footnote references.
            Type <<aHref('footnotes medium', 'FOOTNOTES MEDIUM',
                         'Set footnotes to Medium')>> to
            show references to footnotes except those you&rsquo;ve
            already seen, or <<aHref('footnotes full', 'FOOTNOTES FULL',
                                     'Set footnotes to Full')>>
            to show all footnote references. ');
            break;

        case FootnotesMedium:
            DMsg(show footnotes medium,
            'MEDIUM, which shows references to unread footnotes, but
            hides references to those you&rsquo;ve already read.  Type
            <<aHref('footnotes off', 'FOOTNOTES OFF',
                    'Turn off footnotes')>> to hide
            footnote references entirely, or <<aHref(
                'footnotes full', 'FOOTNOTES FULL',
                'Set footnotes to Full')>> to show every reference, even to
            notes you&rsquo;ve already read. ');
            break;

        case FootnotesFull:
            DMsg(show footnotes full,
            'FULL, which shows every footnote reference, even to
            notes you&rsquo;ve already read.  Type <<aHref('footnotes medium',
            'FOOTNOTES MEDIUM', 'Set footnotes to Medium')>> to show
            only references to notes you
            haven&rsquo;t yet read, or <<
              aHref('footnotes off', 'FOOTNOTES OFF', 'Turn off footnotes')>>
            to hide footnote references entirely. ');
            break;
        }
    }
;

