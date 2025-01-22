#charset "us-ascii"
#include "advlite.h"

/*
 *   ****************************************************************************
 *    newbie.t 
 *    This module forms part of the adv3Lite library 
 *    (c) 2012-13 Eric Eve
 */
#include "advlite.h"

/* 
 *   Many of the ideas in this file are based on Emily Short's 
 *   NewbieGrammar.h extension for Inform 6, itself based on observation of 
 *   some of the non-standard things newcomers to IF tend to type. The idea 
 *   is to get the parser to recognize these commands, at least to the 
 *   extent of giving the player who issues them some help towards typing 
 *   more useful commands rather than giving a standard (and probably 
 *   unhelpful) parser error message
 *
 *   We also provide some helpful brief IF playing instructions for newbies, 
 *   a sample transcript they can view to get the general idea, and a 
 *   mechanism to check whether someone is entering an excessive number of 
 *   invalid commands (so that we can then offer more help).
 */


helpMessage: object
    printMsg {
        "<<if defined(Instructions)>>If you\'re new to interactive fiction, you
        can type <<aHref('INSTRUCTIONS', 'INSTRUCTIONS', 'Show full
            instructions')>> at the prompt for a full explanation of how to
        interact with the software and the story; for<<else>>For<<end>> a brief
        introduction to playing this type of game type <<aHref('INTRO', 'INTRO',
            'Show a brief introduction')>>, or <<aHref('SAMPLE', 'SAMPLE', 'Show
                a short sample transcript')>> to show a short sample transcript.
        <<if gHintManager != nil>>If you\'re having trouble moving forward and
        need help solving a puzzle, type <<aHref('HINT', 'HINT', 'Show
            hints')>>.<<end>> ";
        
        if(defined(extraHintManager))
           extraHintManager.explainExtraHints();
        
        if(versionInfo.propDefined(&showAbout, PropDefDirectly))
           "For more information specific to this game, type <<aHref('ABOUT',
               'ABOUT', 'Show information about this game')>>. ";
    }
    
    briefIntro()
    {
        "You play this kind of game by entering brief commands (try to use as
        few words as possible). Examples include:\b
        WEST\n
        X KEYS\n  
        TAKE BOOK\n
        READ BOOK\n
        DROP BOOK\n
        PUT BOOK ON TABLE\n
        OPEN DOOR\b
        To move around use compass directions: NORTH, EAST, SOUTH etc. These may
        be abbreviated to N, E, S, W, NE, NW, SE, SW.
        You can also use IN, OUT, UP and DOWN.\b 
        EXAMINE (= LOOK AT) can be abbreviated to X; X BOOK, EXAMINE BOOK and
        LOOK AT BOOK all mean the same thing.\b
        The command INVENTORY (or simply I) will give you a list of what you're
        carrying.\n
        Use LOOK or L to repeat the description of your current location.\n
        AGAIN or G repeats the previous command.\b
        For full instructions, use the <<aHref('INSTRUCTIONS', 'INSTRUCTIONS',
                                              'Show full Instructions')>>
        command.\n
        To see a sample transcript, use the <<aHref('SAMPLE', 'SAMPLE', 'See
            sample transcript')>> command. ";
    }

    showSample()
    {
        "A typical game (not this particular one) might start something like
        this:\b";
        inputManager.pauseForMore();
        "<b>>x me</b>\n
        You\'re a handsome enough young lad.\b
        <b>>i</b>\n
        You're carrying a flashlight and a treasure map.\b
        <b>>x map</b>\n
        So far as you can tell, the map indicates that some treasure was hidden
        underground somewhere on Horatio Bumblespoon\'s property.\b
        <b>>l</b>\n
        <b>Bumblespoon's Back Yard</b>\n
        Suffering from years of neglect, this back yard has been thoroughly
        overgrown with a tangle of weeds and briars. A path leads north round
        the side of the house, and you can just make out a narrow staircase
        leading down into the darkness.\b
        <b>>x weeds</b>\n
        The weeds aren\'t important.\b
        <b>>down</b>\n
        <b>In the Dark</b>\n
        It is pitch dark in here.\b
        <b>>switch on flashlight</b>\n
        <b>Damp Cellar</b>\n
        Green mould covers the walls, and a pile of rusty junk clutters one
        corner. The only way out appears to be back up the stairs.\b
        <b>>x junk</b>\n
        It\'s mostly bits of broken gardening equipment, together with the
        remains of a metal bed-frame. But underneath it all you can just make
        out what looks like a large chest.\b
        <b>>x chest</b>\n
        It\'s a large wooden chest, reinforced with steel bands. It\'s closed.\b
        <b>>open chest</b>\n
        You can\'t really get at it with all that junk in the way.\b
        <b>>move junk</b>\n
        You manage to move quite a bit of the junk, clearing your access to
        the wooden chest beneath.\b
        <b>>open chest</b>\n
        (first trying to unlock the wooden chest)\n
        The wooden chest seems to be locked.\b
        <b>>unlock chest</b>\n
        What do you want to unlock it with?\b
        <b>>key</b>\n
        You see no key here.\b
        At this point the player knows he or she has to go in search of the key,
        and presumably that\'s how this game would continue.\b";
        inputManager.pauseForMore();
        "And now back to the game you\'re actually playing....\b";
        gPlayerChar.getOutermostRoom.lookAroundWithin();      
        
    }
;

/* Declare these two properties in case the hintsys module isn't present */
property extraHintsExist;
property explainExtraHints;

 /* 
  *   The playerHelper is an object that starts a daemon at start of play. 
  *   This daemon checks whether the player is making any progress at all, 
  *   and also watches the ratio of commands the parser rejects to the 
  *   number of turns. If this ratio becomes too high (as defined by the 
  *   errorThreshold property) we offer the player a HELP command. If it 
  *   becomes very low (as defined by the ceaseCheckingErrorLevel property) 
  *   we cease checking (i.e. stop the daemon) on the grounds that the 
  *   player doesn't appear to need the kind of help we want to offer. We 
  *   first perform a check after firstCheckAfter turns to see if the player 
  *   is making any progress, and then after each errorCheckInterval turns 
  *   to see if the player is having difficulty entering valid commands. 
  *
  *   The idea is to keep offering HELP to an inexperienced player who 
  *   clearly needs it, even if the player declined to read any help text at 
  *   the start of the game.
  */
playerHelper: InitObject
    
    /* 
     *   Set up the firstCheck() Fuse and note the player character's starting
     *   location.
     */
    execute()
    {
        new Fuse(self, &firstCheck, firstCheckAfter);       
        
        startLocation = gPlayerChar.location;
    }
    
    /* 
     *   The location the playerCharacter starts out in at the beginning of the
     *   game. It may be useful to know this in the firstCheckCriterion method.
     */
    startLocation = nil
    
    /*  
     *   The number of turns that must elapse before we test the
     *   firstCheckCriterion to see if the player appears to be stuck.
     */
    firstCheckAfter = 10
    
    /*   
     *   The message to display if the player seems to be stuck at the start of
     *   the game.
     */
    firstCheckMsg =  "<.p>You don't seem to be making much progress. If you
        feel you could use a little help, enter the
        command <<aHref('HELP', 'HELP', 'Requesting help')>>. "
    
    /* 
     *   The number of turns between each check on whether the player is
     *   entering too many erroneous commands.
     */
    errorCheckInterval = 20
    
    /* 
     *   The proportion of rejected commands to turns (i.e. accepted 
     *   commands) that will trigger an offer of help. We express this 
     *   number as a percentage.
     */
    errorThreshold = 50
    
    /* 
     *   The proportion of rejected commands to turns, expressed as a
     *   percentage, below which we stop checking for errors. The default is 5
     *   (in other words if less than 5 per cent of the player's commands are
     *   being rejected, the player presumably knows what s/he's doing, so we
     *   don't need to keep checking)
     */
    ceaseCheckingErrorLevel = 5
    
    /* 
     *   The criterion to apply to see whether the player is making any progress
     *   at the start of the game. This method should return true if the player
     *   seems to be stuck. By default we simply return nil as there's no way of
     *   knowing how to measure 'stuckness' for games in general, so specific
     *   games will need to override this method. A game involved exploration
     *   might set the condition to gLocation == startLocation (meaning the
     *   player character hasn't moved) for example.
     */
    firstCheckCriterion()
    {
        return nil;
    }
    
    /*  
     *   Check whether the player appears to be making any progress at the start
     *   of the game. If not, display a message offering help and start the
     *   error checking daemon.
     */
    firstCheck()
    {
        /* 
         *   If the player is still in the starting location (and so hasn't 
         *   visited the endOfDriveway, which would trigger its doScript 
         *   method) after 5 turns, s/he may be a novice who's getting stuck, 
         *   so we'll offer help.
         */
        if(firstCheckCriterion())
        {
            /* Display a message offering help. */
            firstCheckMsg;
            /* 
             *   We've just offered help, so we'll wait another 
             *   errorCheckInterval turns before seeing whether to offer it 
             *   again.
             */
            new Fuse(self, &startErrorDaemon, errorCheckInterval);
        }
        else
            startErrorDaemon();
    }
    
    startErrorDaemon() { errorDaemonID = new Daemon(self, &errorCheck, 1); }
    
    /* Watch for a high percentage of errors in user input */
    errorCheck()
    {
        local errorPercent = (100 * errorCount)/libGlobal.totalTurns;
        
        if(errorPercent > errorThreshold)
        {
            "<.p>Please type <<aHref('HELP', 'HELP', 'Requesting help')>> if you
            need help with this game.<.p>";
            /* 
             *   We don't want to keep showing this message every turn, so 
             *   we'll turn the daemon off for twenty turns.
             */
            
            stopErrorDaemon();
            new Fuse(self, &startErrorDaemon, errorCheckInterval);
            
        }
        
        /* 
         *   If there are very few input errors, we're probably not needed 
         *   any more
         */
        if(errorPercent < ceaseCheckingErrorLevel)
            stopErrorDaemon();  
        
    }
    
    /* Stop the error check daemon from running */
    stopErrorDaemon()
    {
        if(errorDaemonID != nil)
            errorDaemonID.removeEvent();
        
        errorDaemonID = nil;
    }
       
    /* 
     *   The offerHelp() method asks whether the player has played this kind of
     *   game before and accepts a Y or N answer. if the answer is NO then it
     *   goes on to display a message suggesting sources of help.
     *
     *   This method can usefully be called at the end of the
     *   gameMain.showIntro() method, but it's up to game authors to incluse it
     *   there if they want it/
     */
    offerHelp()
    {
        "Have you played this kind of game before? (<b>y</b> or <b>n</b>) >";
        if(!yesOrNo())
        {
            "\b";
            helpMessage.printMsg();            
        }
        "\b";
    }
    
    /* 
     *   For internal use only: the ID of the currently running error check
     *   Daemon (if there is one)
     */
    errorDaemonID = nil
    
    /*   
     *   For internal use only: the number of badly formed commands the player
     *   has entered.
     */
    errorCount = 0
;

/* 
 *   This game may be played by novice players. We'll try to keep track of 
 *   how many not-understood commands they enter, in case it helps us decide 
 *   whether they need help. The playerHelper object will use this 
 *   information to decide whether to offer help. 
 */

modify NotUnderstoodError
    display()
    {
        inherited;
        playerHelper.errorCount++;
    }
;

modify UnknownWordError
    display()
    {
        inherited;
        playerHelper.errorCount++;
    }
;

modify EmptyNounError
    display()
    {
        inherited;
        playerHelper.errorCount++;
    }
;


//-------------------------------------------------------------------------------
/* 
 *   More newbie-helpful bits and pieces, based on work by Emily Short for I6
 *
 *   The idea is to trap the kind of invalid input a newcomer to IF might 
 *   type and respond with something a bit more helpful than a standard 
 *   parser error message. In some cases we'll execute the command the 
 *   player probably meant, and in others we'll just explain why the command 
 *   failed.
 */

/*  First, trap attempts to refer to body parts */

bodyParts: MultiLoc, Unthing 'body; (my) (your) (his) (her) (this) (left)
    (right); head hand ear fist finger thumb arm leg foot eye face nose mouth
    tooth tongue lip knee elbow; it them' 
    
    notHereMsg = 'Generally speaking, there is no need to refer to your
        body parts individually in interactive fiction.  WEAR SHOES ON FEET will
        not necessarily be implemented, for instance; WEAR SHOES is enough.  And
        unless you get some hint to the contrary, you probably cannot OPEN DOOR
        WITH FOOT or PUT THE SAPPHIRE RING IN MY MOUTH. '

    /* 
     *   By default we want this bodyParts object to be available everywhere (since the player may
     *   try to refer to the PC's bodyparts anywhere, but if your game defines its own body parts
     *   (or items that share vocab with body parts such as the hands of a clock or the legs of a
     *   chair) you may occasionally get unwanted results from having the bodyParts objects present
     *   too. In such a case you can banish the bodyParts object by setting its initialLocationClass
     *   to nil, or otherwise restrict where it turns up.
     */
    initialLocationClass = Room
  
;

/* Trap the use of vague words like 'someone' or 'something' or 'anyone' */
somethingPreParser: StringPreParser
    doParsing(str, which)
    {
        local ret = rexSearch(pat, str);
        if(ret != nil)
        {
            /* first check whether the word occurs in the dictionary */
            local lst = cmdDict.findWord(ret[3]);
            
            /* then see if it matches any objects in scope. */
            lst = lst.intersect(Q.scopeList(gPlayerChar));
            
            /* if not, display a helpful message */
            if(lst.length == 0)
            {
                "It's usually better not to use vague words like
                <q><<ret[3]>></q> in your commands, because the game won't be
                able to guess what you mean. Be more specific and refer to the
                objects in your vicinity. ";
                playerHelper.errorCount++;
                return nil;
            }
        }
        return str;
    }
    pat = static new RexPattern('<NoCase>%<(someone|something|anyone|anything)%>')

   isActive = (gPlayerChar.currentInterlocutor == nil)
;

/* 
 *   Trap commands like LOOK HERE or SEARCH THERE. We'll actually carry out 
 *   a LOOK command, but we'll also tell the player just to use LOOK in 
 *   future.
 */
DefineIAction(LookHere)
    execAction(cmd)
    {
        gActor.getOutermostRoom.lookAroundWithin();
        playerHelper.errorCount++;
        "<.p>[For future reference, you don't need to refer to places in the
        game with words like <q><<cmd.verbProd.placeName>></q>; a simple LOOK
        command will suffice]<.p>";
    }
;
    
VerbRule(LookHere)
    ('l' | 'look' | 'search') ('here'->placeName|'there'->placeName)
    : VerbProduction
    action = LookHere
    verbPhrase = 'look/looking'
;

/* 
 *   Trap the words KINDLY and PLEASE in a player's command, and explain that
 *   they shouldn't be used, giving examples of the kind of commands to use
 *   instead. (But don't do this in conversation, where these words might be
 *   part of valid conversational exchange)
 */
pleasePreParser: StringPreParser
    doParsing(str, which)
    {
        if(rexMatch(pat, str) && gPlayerChar.currentInterlocutor == nil)
        {
            "That's very polite of you, but there's really no need to use words
            like <q>please</q> and <q>kindly</q>; you'll find the game
            will understand you far better if you stick to simple imperatives
            like GO NORTH, or X KEYS or PUT BOX ON TABLE. <.p>";
            playerHelper.errorCount++;
            return nil;
        }
        return str;
    }
    pat = static new RexPattern('<NoCase>%<(please|kindly)%>')
;

/* 
 *   Trap any command beginning with USE, telling the player to be more specific, unless the game
 *   code defines its own Use action.
 */
usePreParser: StringPreParser
    doParsing (str, which)
    {
        if(str.toLower.startsWith('use ') && !(defined(Use) && Use.ofKind(Action)))        
        {
            "<.p>I don't recognize the command USE, because it's a bit too
            vague; please be more specific about what you want to do.<.p>";
            playerHelper.errorCount++;
            return nil;
        }
        
        return str;
    }
;

/* 
 *   Trap commands like KEEP GOING NORTH or CONTINUE HEADING WEST. We'll 
 *   carry out the directional movement command obviously intended, but 
 *   advise the player on the standard form of such commands.
// */
KeepGoing: TravelAction
    execAction(cmd)
    {
        local action = Go.createInstance();
        cmd.dobj = cmd.verbProd.dirMatch.dir;
        
        action.execAction(cmd);
        "[In most Interactive Fiction, it is necessary as well as easier to
        phrase commands like this as simple directions: GO NORTH, NORTH (or
        just N), etc., rather than KEEP GOING NORTH, HEAD BACK NORTH,
        etc.]<.p>";
    }
;

VerbRule(KeepGoing)
    ('keep' | 'continue') ('going'|'walking'|'running'|'heading') singleDir
    | 'head' ('back' | ) singleDir
    : VerbProduction
    action = KeepGoing
    verbPhrase = 'go/going (where)'
;

/* 
 *   Trap commands that start with a pronoun (e.g. I AM LOST or YOU ARE SILLY)
 *   and advise the player that they are likely to be unproductive, suggesting
 *   the format of commands that are more likely to work.
 *
 *   Note that we have to make exceptions that allow valid commands starting
 *   with I where I is an abbreviation for INVENTORY, such as I itself, I TALL
 *   and I WIDE. We also have to make exceptions when a conversation is in
 *   progress, since the command could be a valid SayTopic.
 */
pronounUsePreParser: StringPreParser
    doParsing(str, which)
    {
        if(rexMatch(pat3, str) || gPlayerChar.currentInterlocutor != nil)
            return str;
        
        if(rexMatch(pat, str) || rexMatch(pat2, str))
        {
            "If the game is not understanding you, try issuing your commands in
            the imperative: e.g., THROW THE KNIFE, but not I WOULD REALLY LIKE
            TO THROW THE KNIFE.  Chatty sentences such as YOU ARE A VERY STUPID
            GAME will only prove themselves true.\b
            If you really feel that the game is looking for a word that is not
            a verb (as the solution to a riddle, eg.) try some variations, such
            as SAY FLOOBLE.\b
            If you need more help, try the <<aHref('HELP','HELP', 'Ask for
                help')>> command.<.p>";
            playerHelper.errorCount++;
            return nil;
        }
        return str;
    }
    pat = static new RexPattern('<NoCase>^(you|he|she|it|they|we|its|theyre' 
                                + '|youre|hes|shes)<Space|squote>')    
    
    pat2 = static new RexPattern('<NoCase>^(i|im|i<squote>m)<Space>+%w')
    
    pat3 = static new RexPattern('<NoCase>^i<Space>+(wide|tall|hybrid|split)')
;



/* 
 *   Trap commands like WHERE CAN I GET HELP. Print a suitable Help message, 
 *   and then explain the use of the HELP command.
 */
DefineSystemAction(WhereHelp)
    execAction(cmd)
    {
        "[A simple HELP would do]<.p>";
        helpMessage.printMsg();
    }
;

VerbRule(WhereHelp)
    'where' ('can' | 'do' | 'does' | 'should') 
    ('i' | 'we' | 'one' | 'anyone'| 'someone') 
    ('get' | 'find' | 'obtain')
    ('help' | 'assistance' | 'instructions')
    (literalDobj | )
    : VerbProduction
    action = WhereHelp
    verbPhrase = 'request/requesting help'
    priority = 80
    
    /* 
     *   Don't match this grammar if the player char is in conversation, since
     *   in that case the player may be attempting a valid conversational
     *   command)
     */
    isActive = (gPlayerChar.currentInterlocutor == nil)
;

DefineSystemAction(Help)
    execAction(cmd)   {   helpMessage.printMsg();   }
;

/* Provide grammar to understand a fairly wide variety of requests for help */

VerbRule(Help)
    ('help' | 'assist' | 'assistance' ) |
    'how' ('do' | 'can' | 'does' | 'will' | 'shall' | 'could' | 'should' | 'may'
           | 'must') 
    ('i' | 'me' | 'he' | 'she' | 'it' | 'we' | 'you' | 'they' | 'person' | 'one'
     | 'someone' | 'anyone' | 'somebody' | 'anybody') literalDobj
    
    : VerbProduction
    action = Help
    verbPhrase = 'help/helping with the software'
    
    priority = 80
    
    /* 
     *   Don't match this grammar if the player char is in conversation, since
     *   in that case the player may be attempting a valid conversational
     *   command)
     */
    isActive = (gPlayerChar.currentInterlocutor == nil)
;

VerbRule(WhatNext)
    'what' ('next' | 'now') |
    'what' ('should' | 'can' | 'do' | 'does' | 'am' | 'is') 
    ('i' | 'one' |'anyone' | 'someone') 
    (('meant' 'to')|) ('do' | 'try') ('next' | 'now'|)
    : VerbProduction
    action = Help
    verbPhrase = 'help/helping with the software'
    
    priority = 80
    
    /* 
     *   Don't match this grammar if the player char is in conversation, since
     *   in that case the player may be attempting a valid conversational
     *   command)
     */
    isActive = (gPlayerChar.currentInterlocutor == nil)
;


/* 
 *   Provide a command to display a brief introduction to playing IF (as an 
 *   alternative to the full INSTRUCTIONS menu provided by the TADS 3 library)
 */
DefineSystemAction(Intro)
    execAction(cmd) { helpMessage.briefIntro(); }
;

VerbRule(Intro)
    ('show'|'view'|) ('brief'|) ('intro' | 'introduction')
    : VerbProduction
    action = Intro
    verbPhrase = 'show/showing brief introduction'    
;

/* Provide a command to show the player a sample transcript */
DefineSystemAction(Sample)
    execAction(cmd) { helpMessage.showSample(); }
;

VerbRule(Sample)
    ('show'|'view'|) 'sample' ('transcript' | )
    : VerbProduction
    action = Sample
    verbPhrase = 'show/showing sample transcript'
;



/* 
 *   Make WHAT IS X behave like EXAMINE X, but then explain the standard 
 *   phrasing of an EXAMINE command. 
 */

VerbRule(WhatIsNoun)
    ('whats' | 'what' ('is'|'are')) multiDobj
    : VerbProduction
    action = Examine
    verbPhrase = 'examine/examining (what)'
    
    priority = 80
    
    /* 
     *   Don't match this grammar if the player char is in conversation, since
     *   in that case the player may be attempting a valid conversational
     *   command)
     */
    isActive = (gPlayerChar.currentInterlocutor == nil)
;

modify Examine
    execAction(cmd)
    {
        inherited(cmd);        
        if(cmd.verbProd.grammarTag == 'WhatIsNoun')
        {
            local obj = cmd.dobj;
            "[You can do this in future by using <<aHref('X '+ obj.name.toUpper,
                'X ' + obj.name.toUpper, 'Examine ' + obj.theName)>>, which is
            quicker and more standard.]\b";
            playerHelper.errorCount++;
        }            
    }   
;

/* 
 *   Trap variants on WHAT AM I CARRYING that should be turned into an INVENTORY
 *   command.
 */

VerbRule(WhatAmICarrying)
    'what' ('am'|'are') ('i'|'we'|'you') ('carrying' | 'holding')
    | 'what' 'do' ('i'|'we'|'you') 'have'
    | 'what' 'have' ('i'|'we'|'you') 'got'
    : VerbProduction
    action = Inventory
    verbPhrase = 'take/taking inventory'
    priority = 80
    isActive = (gPlayerChar.currentInterlocutor == nil)
;

modify Inventory
    execAction(cmd)
    {
        inherited(cmd);        
        if(cmd.verbProd.grammarTag == 'WhatAmICarrying')
        {            
            "[You can do this in future by using <<aHref('INVENTORY',
                'INVENTORY', 'Take Inventory')>> or just
            <<aHref('I', 'I', 'Take Inventory')>>, which is
            quicker and more standard.]\b";
            playerHelper.errorCount++;
        }            
    } 
;


/* 
 *   Trap a variety of commands of the sort WHAT IS GAME ABOUT or WHATS THE 
 *   POINT and respond by showing the game's ABOUT text.
 */
VerbRule(WhatsThePoint)
    ('whats' | 'what' 'is') ('the'|) ('point' | 'idea' | 'goal' | 'purpose')
    (literalDobj | )
    : VerbProduction
    action = About
    verbPhrase = 'ask/asking about the point of the game'
    
    priority = 80
    
    /* 
     *   Don't match this grammar if the player char is in conversation, since
     *   in that case the player may be attempting a valid conversational
     *   command)
     */
    isActive = (gPlayerChar.currentInterlocutor == nil)
;

VerbRule(WhatThisGame)
    ('whats' | 'what' ('is'|'are')) ('the' | 'these' | 'this' |)
    ('game' | 'story' | 'program' | 'games' | ('interactive' 'fiction')) 
        ('for' | 'about' | )
    : VerbProduction
    action = About
    verbPhrase = 'ask/asking what the game is about'
    
    priority = 80
    
    /* 
     *   Don't match this grammar if the player char is in conversation, since
     *   in that case the player may be attempting a valid conversational
     *   command)
     */
    isActive = (gPlayerChar.currentInterlocutor == nil)
;


/* 
 *   Trap a variety of vague travel commands like GO SOMEWHERE or WALK 
 *   AROUND or TURN RIGHT and explain how movement commands should be 
 *   phrased. Then display a list of available exits from the current 
 *   location.
 */
DefineIAction(GoSomewhere)
    execAction(cmd)
    {
        "If you want to go somewhere, use one of the compass directions (NORTH,
        EAST, SW, W, S etc). ";
        
        playerHelper.errorCount++;
        
        if(defined(exitLister) &&
           exitLister.cannotGoShowExits(gActor, gActor.getOutermostRoom));        
    }
    actionTime = 0
;

VerbRule(GoSomewhere)
    (('go' | 'walk' |  'proceed' | 'run') ( | ('to' 'the') )
    ('left' | 'right' | 'on' | 'onwards' | 'onward' | 'forward' | 'forwards' |
     'around' | 'somewhere' | (('straight'| ) 'ahead'))) | ('turn'
         ('left'|'right'))
    : VerbProduction
    action = GoSomewhere
    verbPhrase = 'go/going somewhere'
;

modify VagueTravel
    execAction(cmd)  {  delegated GoSomewhere(cmd);  }
;

/*  
 *   Trap commands like WHERE AM I or WHERE ARE WE or WHAT IS HERE. Perform 
 *   a LOOK command but explain that LOOK is the phrasing to use.
 */
DefineIAction(WhereAmI)
    execAction(cmd)
    {
        gActor.getOutermostRoom.lookAroundWithin();
        "<.p>[In future, just use the <<aHref('LOOK','LOOK', 'Look around')>>
        command]<.p>";
    }
     
;

VerbRule(WhereAmI)
    'where' ('are' | 'am' | 'is') ('i' | 'we')
    : VerbProduction
    action = WhereAmI
    verbPhrase = 'look/looking'
    
    priority = 80
    isActive = (gPlayerChar.currentInterlocutor == nil)
;

VerbRule(WhatsHere)
    'what' 'is' 'here'
    | 'whats' 'here'
    : VerbProduction
    action = WhereAmI
    verbPhrase = 'ask/asking what\'s here'
    
    priority = 80
    isActive = (gPlayerChar.currentInterlocutor == nil)
;  

/* 
 *   Provide a response to WHO AM I. We provide a brief explanation and then 
 *   perform an EXAMINE ME command to add any game-specific player character 
 *   description. 
 */
DefineIAction(WhoAmI)
    execAction(cmd)
    {
        "[You're the main character of the game.  Of course, the game author
        may have given you a description.  You can see this description in the
        future by typing <<aHref('X ME','X ME','Examine me')>>], which is
        quicker and more standard.]\b";
        replaceAction(Examine, gPlayerChar);
        playerHelper.errorCount++;
    }
;

VerbRule(WhoAmI)
    ('who'| 'what') ('am'|'is') ('i'|'me')
    : VerbProduction
    action = WhoAmI
    verbPhrase = 'ask/asking who I am'
    
    priority = 80
    isActive = (gPlayerChar.currentInterlocutor == nil)
;


/* 
 *   Trap commands like WHERE CAN I GO. Perform an EXITS command to list the 
 *   exits, but then tell the player to use the wording EXITS in future.
 */
DefineIAction(WhereGo)
    execAction(cmd)
    {
        nestedAction(Exits);
        "<.p>[In future, just use the EXITS command]<.p>";
    }
;

VerbRule(WhereGo)
    'where' ('can' | 'do' | 'does' | 'should') ('i' | 'we' | 'one'| 'anyone') 
    'go'
    : VerbProduction
    action = WhereGo
    verbPhrase = 'show/showing exits'
    
    priority = 80
    isActive = (gPlayerChar.currentInterlocutor == nil)
;



/*  
 *   The StringPreparser and the TopicAction which follows are designed to 
 *   deal with command like LOOK FOR X, FIND Y or SEARCH FOR Z. The 
 *   complication is that in the standard library these are all forms of 
 *   LOOK UP X, which prompt the response "What do you want to look that up 
 *   in?". This is likely to confuse new players.
 *
 *   The StringPreparser checks to see if there's a Consultable in the 
 *   current location. If so, then we use the standard library handling, on 
 *   the assumption that the player is trying to looking something up in it. 
 *   If not we change the command to SEEK X in order to invoke the new 
 *   SeekAction defined below.
 */

seekPreParser: StringPreParser
    doParsing(str, which) 
    {        
        local doReplacement = true;
        
        if(defined(Consultable) && firstObj(Consultable))
        {
            doReplacement = nil; 
        }
        
        if(doReplacement && rexMatch(pat, str))  
           str = rexReplace(pat, str, 'seek', ReplaceOnce); 
        
        return str;
    }
    pat = static new RexPattern('^<NoCase>%<(find|look for|search for|hunt for)%>')
;

/*  
 *   SeekAction is designed to handle of commands FIND X, LOOK FOR Y or 
 *   SEARCH FOR Z, when they don't seem to be intended as attempts to look 
 *   something up in a Consultable. We make it a TopicAction so that it will 
 *   match whatever the player types, and so not give away any premature 
 *   spoilery information by the nature of the parser's response.
 *
 *   The appropriate response then depends on the player character's state of
 *   knowledge. In the most general case the player is simply given 
 *   instructions on how to go about looking for things. This hardly seems 
 *   appropriate, however if the object requested is in plain sight, in 
 *   which case we point this out to the player. As a courtesy to the 
 *   player, we also remind him or her of where an object was last seen, if 
 *   it has been seen.
 *
 *   One or two complications need to be dealt with. If the player finds 
 *   something like FIND SMELL or FIND NOISE then we should describe it as 
 *   having been smelt or heard elsewhere, not seen. We also want to make 
 *   sure that the command never matches an Unthing in preference to a 
 *   Thing, and that if an Unthing is matched it is not described as being 
 *   present.
 */    

DefineTopicAction(Seek)
    execAction(cmd)
    {
        local obj = getBestMatch(cmd);
        gMessageParams(obj);
        if(obj && obj.ofKind(Unthing))
        {
            say(obj.notImportantMsg);
            return;
        }
           
        if(obj == gPlayerChar)
        {
            "If you've managed to lose your player character, things must be
            desperate! But don't worry, {I}{\'m} right {here}. ";
            return;
        }
        
        if(obj && obj.ofKind(Thing) && gActor.hasSeen(obj))
        {
            local loc = obj.location;
            if(loc == nil)
            {
                if(obj.isIn(gActor.getOutermostRoom))
                    loc = gActor.getOutermostRoom;
                else if(obj.ofKind(MultiLoc) && obj.locationList.length > 0)
                    loc = obj.locationList[1];
            }
            
            
            if(obj.isIn(gActor))
                "{I} {am} carrying {him obj}. ";
            else if(gActor.canSee(obj) && loc != nil)
            {
                "{The subj obj} {is} ";
                if(loc == gActor.getOutermostRoom)
                    "right {here}. ";
                else 
                    "<<obj.isIn(gActor.getOutermostRoom) ? '' : 'nearby, '>>
                    <<locDesc(obj, loc)>>. ";
            }
            else
                "{I} {|had} last <<senseDesc(obj)>> {the obj}
                <<locDesc(obj, obj.lastSeenAt)>>. ";
        }
        else
            "If you want to find something you can\'t see, you'll have to hunt
            for it. If you think it may be in your current location, try
            examining things, searching things, opening things that open, or
            looking in, under and behind things. If what you\'re looking for
            could be elsewhere, you may have to go elsewhere to find it. ";
           
    }
    
    /* 
     *   gTopic.getBestMatch() may not give the best results for our 
     *   purposes. The following code is designed to prefer Things to 
     *   Unthings, and then to prioritize what the player char can see over 
     *   what s/he has seen, and both over what s/he only knows about. If 
     *   none of these find a match, we then revert to gTopic.getBestMatch.
     */
    
    getBestMatch(cmd)
    {
        local lst = valToList(cmd.dobj.topicList);
        
        /* 
         *   First see if our topic list includes anything the actor can see
         *   that's not an Unthing.
         */
        local obj = lst.valWhich({x: x.ofKind(Thing) && gActor.canSee(x) 
                                 && !x.ofKind(Unthing)});
        if(obj != nil)
            return obj;
        
        /* 
         *   Next see if there's anything in our topic list that the actor has
         *   previously seen.
         */
        obj = lst.valWhich({x: gActor.hasSeen(x) && !x.ofKind(Unthing)});
        if(obj != nil)
            return obj;
        
        /* 
         *   Next see if there's anything in our topic list that the actor
         *   knows about.
         */
        obj = lst.valWhich({x: x.ofKind(Thing) && gActor.knowsAbout(x)});        
        
        if(obj != nil)
            return obj;
        
        /* 
         *   Finally, if all else fails, just return the ResolvedTopic's idea of
         *   a best match.
         */   
        return cmd.dobj.getBestMatch();
        
    }
    
    locDesc(obj, loc)
    {
        if(obj.ofKind(Noise) || obj.ofKind(Odor))
            "coming from <<loc.theName>>";       
        else
            "<<loc.objInName>>";
    }
    
    senseDesc(obj)
    {
        if(obj.ofKind(Noise))
            return 'heard';
        if(obj.ofKind(Odor))
            return 'smelt';
        return '{saw|seen}';           
    }
 
;

VerbRule(Seek)
    ('seek' | ('hunt' 'for')) topicDobj
    : VerbProduction
    action = Seek
    verbPhrase = 'seek/seeking (what)'
    missingQ = 'what do you want to seek'
    dobjReply = topicPhrase
;
