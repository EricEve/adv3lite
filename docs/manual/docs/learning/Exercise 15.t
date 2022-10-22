#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*   
 *   EXERCISE 15 - BOMB DISPOSAL
 *
 *   This game is primarily intended as a demonstration of FUSES and DAEMONS,
 *   but this these classes can hardly be demonstrated in the abstract, so 
 *   we embed the demonstration in a brief game. We also take the 
 *   opportunity to demonstrate the INITOBJECT, PREINITOBJECT, 
 *   COLLECTIVEGROUP and CONSULTABLE classes, all of which fit neatly in the 
 *   game, but don't obviously fit in any other demo.
 */




versionInfo: GameID
    IFID = 'a78974ac-6485-414a-92bc-72411c1a81f1'
    name = 'Exercise 15 - Bomb Disposal'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A demonstration of Fuse and Daemon classes (and also InitObject,
        PreinitObject, CollectiveGroup and Consultable).'
    htmlDesc = 'A demonstration of Fuse and Daemon classes (and also
        InitObject, PreinitObject, CollectiveGroup and Consultable).'
;

gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    showIntro()
    {
        "There was another air raid on London last night. Many houses were
        damaged, but in this one the bomb failed to explode. Your job is to
        disarm it before it does. \b";
    }
;

/*   
 *   INITOBJECT
 *
 *   An InitObject is an object with an execute() method that's automatically
 *   invoked when the game starts, so it can be a useful place to put code 
 *   we want to execute at the start of the game. InitObject can be used as a
 *   standalone, or mixed in with some other class (typically to add 
 *   initialization behaviour to an object).
 *
 *   An InitObject is a good place to set up a Daemon we want to start at the
 *   beginning of the game, which is how we're using it here. In this case 
 *   we mix InitObject with a ShuffledEventList we'll use to display random 
 *   atmosphere strings. There are only two rooms in this game, and we want 
 *   these strings to be displayed in both of them, so this provides a good 
 *   alternative to using the atmosphereList properties of the individual 
 *   rooms.  
 */

InitObject, ShuffledEventList
    [
        'There\'s a loud jangling from a fire-engine hurrying down the street.
        ',
        'Your sergeant pokes his head round the door to see how you\'re getting
        on. You send him away again; there\'s no need the two of you getting
        blown up if this goes wrong. ',
        'An aeroplane drones overhead. ',
        'A siren wails in the distance. ',
        'Somewhere in the distance, a dog barks. ',
        'You hear the sound of running feet outside the house. ',
        'Outside the house a policeman shouts to a group of children to stand
        clear. '
    ]
    
    /*  
     *   DAEMON
     *
     *   The execute method is called when the game starts. The code in this 
     *   execute() method creates a Daemon that will run every turn. What 
     *   this Daemon will do is to call the doScript() method on self (i.e. 
     *   this object) every turn. We don't need to store a reference to this 
     *   Daemon since it will carry on running for as long as the game 
     *   continues.
     */
    
    execute() { new Daemon(self, &doScript, 1); }
        
    /*   
     *   Once we've displayed all these messages once, reduce their 
     *   frequency to 50%. We make the compiler do the work of counting the 
     *   number of items in the eventList; using the static keyword means 
     *   that the compiler will compute the value and store it in the 
     *   eventReduceAfter property, so the expression won't need to be 
     *   evaluated each time during game-play.
     */    
    eventReduceTo = 50
    eventReduceAfter =  static eventList.length()
;


/*   
 *   ONE_TIME_PROMPT_DAEMON
 *
 *   A PromptDaemon is a special kind of Daemon that runs every turn just 
 *   before the command prompt is displayed. A OneTimePromptDaemon is a 
 *   special kind of PromptDaemon that runs only once (and then disables 
 *   itself); it's useful to make something happen at the very end of a 
 *   single turn, or, as here, just before the first command prompt (after 
 *   the opening text and the room description have been displayed). Here We 
 *   use an InitObject to set up a OneTimePromptDaemon that displays a 
 *   message just before the first command prompt.
 */
InitObject
    execute() { new OneTimePromptDaemon(self, &toolMessage); }
    toolMessage = "You left your bag of tools out in the hall; you'll need to
        collect them once you've taken a quick look at the bomb. "
;


/* 
 *   Starting location - we'll use this as the player character's initial
 *   location.  The name of the starting location isn't important to the
 *   library, but note that it has to match up with the initial location
 *   for the player character, defined in the "me" object below.
 *   
 *   Our definition defines two strings.  The first string, which must be
 *   in single quotes, is the "name" of the room; the name is displayed on
 *   the status line and each time the player enters the room.  The second
 *   string, which must be in double quotes, is the "description" of the
 *   room, which is a full description of the room.  This is displayed when
 *   the player types "look around," when the player first enters the room,
 *   and any time the player enters the room when playing in VERBOSE mode.
 *   
 *   The name "startRoom" isn't special - you can change this any other
 *   name you'd prefer.  The player character's starting location is simply
 *   the location where the "me" actor is initially located.  
 */
startRoom: Room 'Living Room'
    "The living room is a shambles. A layer of dust and debris covers
    everything, presumably showered down from the gaping hole in the ceiling. "
    north = lrDoor
    out asExit(north)
;

/* 
 *   The player character object. This doesn't have to be called me, but me is a
 *   convenient name. If you change it to something else, rememember to change
 *   gameMain.initialPlayerChar accordingly.
 */

+ me: Thing 'you'   
    isFixed = true       
    person = 2  // change to 1 for a first-person game
    contType = Carrier    
;

+ lrDoor: Door 'door'
    otherSide = hallDoor
;


/*   
 *   INITOBJECT
 *
 *   Here we use InitObject combined with a physical game object to set up a 
 *   couple of Fuses associated with it.
 *
 *   A Fuse in adv3Lite is an event that executes at some specified number of 
 *   turns after it is first set up. Unlike a Daemon which executes every 
 *   turn (or every so many turns) it executes only once and is then removed.
 *
 *   Although a Fuse can be used for anything, the term naturally conjurs up 
 *   the idea of an explosion, and that's how we're using it here -- in 
 *   conjunction with a bomb!
 */
+ bomb: InitObject, Surface, Immovable 
    'bomb; unexploded black smooth; casing uxb' 
    "It's a long beast, with a smooth black casing. <<cap.isIn(self) ? 'At one
        end is the cap that covers the detonator. ' : ''>>"
    
    /*  This method will be called when the game starts. */
    execute()
    {
        /*   
         *   FUSE
         *
         *   The next statement sets up a Fuse that will call the explode() 
         *   method on the bomb in 25 turns from now. We need to store a 
         *   reference to the Fuse since we'll want to stop it if the player 
         *   succeeds in disabling the bomb before it explodes.
         *
         *   There are only two rooms in the game, and the player character 
         *   will be equally aware of the bomb exploding (and equally dead 
         *   as a result) whichever of the two rooms he's in when it goes 
         *   off, so a simple Fuse will do here (as opposed to a SenseFuse).
         */
        fuseID = new Fuse(self, &explode, 25);
        
        
        /*
         *   SENSEFUSE
         *
         *   A SenseFuse is much like a Fuse, except that anything it tries 
         *   to display when it executes is only displayed if the PC is in a 
         *   position to sense it. In this case we will make the bomb start 
         *   to tick louder after 20 turns (as a hint to the player that 
         *   time is running out), but obviously the player character won't 
         *   hear that unless he's in the same room as the bomb, so we use a 
         *   SenseFuse to ensure that the output from the Fuse is only 
         *   displayed if the player can hear the bomb at that point (this 
         *   is what the final two parameters define: self -- the object to 
         *   be sensed, and sound -- the sense in question). The first three 
         *   parameters have the same meaning as before; unless it's 
         *   disabled first this senseFuse will call ticking.louden() in 20 
         *   turns from the start of the game.
         */             
        senseFuseID = new SenseFuse(ticking, &louden, 20, &canHear);        
    }
    
    /*   
     *   fuseID and senseFuseID are custom properties we use to store 
     *   references to the Fuse and the SenseFuse. We need to store them 
     *   both so we can disable both fuses if the player succeeds in 
     *   defusing the bomb.
     */
    fuseID = nil
    senseFuseID = nil
    
    
    /*  
     *   A custom method which describes the explosion of the bomb and ends 
     *   the game in the PC's death when the bomb explodes. Note that this 
     *   can be called either as a result of the Fuse executing or as a 
     *   result of the PC cutting the wrong wire when attempting to defuse 
     *   the bomb.
     */
    explode()
    {
        "With a loud roar and a cloud of smoke and flying debris the bomb
        explodes!\b";
        finishGameMsg(ftDeath, [finishOptionUndo]);
    }
    
    /*   
     *   The makeSafe() method is a custom method that disables both fuses 
     *   if and when the player manages to defuse the bomb.
     */    
    makeSafe()
    {
        fuseID.removeEvent();
        senseFuseID.removeEvent();
        fuseID = nil;
        senseFuseID = nil;
        
        /*   
         *   PROMPT DAEMON
         *
         *   A PromptDaemon is a special kind of Daemon that's called each 
         *   turn, just before the command prompt is displayed. Here we set 
         *   up a PromptDaemon to display a message to prompt the player to 
         *   leave the house (and so end the game) once the bomb has been 
         *   defused.
         */
        new PromptDaemon(self, &safeMessage);
    }
    
    /*   The message to display each turn once the bomb has been defused. */
    safeMessage = "<.p>Now that you've disabled the bomb, you'd better go out
        and tell everyone it's safe. "
     
    
    specialDesc = "An unexploded bomb lies in the middle of the room. "
    listenDesc = ticking.desc
    
    /*   
     *   The lookUnderMsg is displayed in response to the command LOOK 
     *   UNDER THE BOMB. The manual (implemented below) provides hints that 
     *   the player needs to find this model number somewhere on the bomb 
     *   casing.
     */
    lookUnderMsg = 'On the underside of the casing you can just make out the
        characters ZP640. '
;

/*  We'll give this bomb a suitably menacing tick. */
++ ticking: Noise 'faint ticking sound' 
    "<<if isEmanating>>A <<name>> is coming from the bomb<<else>>The bomb has
    fallen silent<<end>>. "
    
    /*  
     *   The ticking stops once the bomb has been defused. In adv3Lite
     *   isEmanating is a custom property we've defined for this object, not a
     *   property defined in the library
     */
    isEmanating = (bomb.fuseID != nil)
    
    /*  
     *   Make the ticking get louder. Change the name to 'loud ticking 
     *   sound' and amend the vocabulary to suit, then display a message to 
     *   say that the ticking has got louder.
     */
    louden()
    {
        replaceVocab('loud ticking sound');
       
        "The bomb suddenly starts ticking louder. ";
    }
   
    /* 
     *   If the ticking sound is still emanating and the player didn't
     *   explicitly issue a Listen command we'll display a message about the
     *   ticking of the bomb on each turn.
     */
    afterAction()
    {
        if(isEmanating && !gActionIn(Listen, ListenTo))
            desc;
    }
;


/*  To get at the detonator the PC first has to remove this cap. */
++ cap: Fixture 'cap; round black metal detonator' 
    "It's a round metal cap, black like the rest of the bomb. "
    
    /* 
     *   To remove the cap the player character needs to turn it with his 
     *   spanner, so we need custom handling for the TurnWith handling.
     */
    dobjFor(TurnWith)
    {        
        verify() {}
        action()
        {
            "You turn {the dobj} with {the iobj}, and remove it from the
            bomb, revealing the detonator compartment (in which you can see five
            wires: one red, one yellow, one green, one blue, and one black). ";
            
            /*  
             *   Since the cap behaves rather differently once it's been 
             *   removed from the bomb, it's easier to implement it as two 
             *   different game objects (which will look like the same 
             *   object to the player). It would be possible to use a single 
             *   object, but probably messier and more bug-prone.
             *
             *   So when the cap is unscrewed, we need to replace it with the
             *   object representing the unscrewed cap.
             */
            moveInto(nil);
            cap2.moveInto(gActor);
        }
    }
 
    
    /*  
     *   Provide custom messages for some obvious actions that might be 
     *   tried on this cap.
     */
    cannotUnscrewMsg = 'You can\'t do that with your bare hands. '
    cannotTurnMsg = (cannotUnscrewMsg)
    cannotTakeMsg = 'You can\'t; it\'s tightly screwed on. '
    cannotOpenMsg = 'You need to unscrew it. '
    cannotPushMsg = (cannotOpenMsg)
    cannotPullMsg = (cannotOpenMsg)
    cannotMoveMsg = (cannotOpenMsg)
    
    isTurnable = nil
    
    /*  
     *   So far as the player is concerned, cap and cap2 are the same 
     *   object, so we make sure the parser knows this. This ensures that if 
     *   the player types TURN CAP WITH SPANNER followed by X IT, the 
     *   EXAMINE command will still work, even though cap will have been 
     *   replaced by cap2 in the course of carrying out the first command.
     */
    getFacets = [cap2]
;

/*  
 *   Implementing a container-like object that only becomes accessible (and 
 *   indeed, visible) once a cap or lid is removed is just a little tricky. 
 *   Here we do it with something that's a mix of several classes.
 *
 *   We're also making this an InitObject so that it can make a random 
 *   choice of which is the safe wire to cut at the start of the game.
 *
 *   We make the detonator a RestrictedContainer so that it can contain, and 
 *   if necessarily conceal, its existing contents (five wires), without 
 *   allowing anything else to be put in it.
 */
++ detonator: InitObject, Fixture, Container 
    'detonator compartment' 
    
    /*  
     *   The detonator compartment becomes accessible when the cap is removed.
     *   We can simulate that by making it hidden while the cap is on the bomb.
     */
    isHidden = (cap.isIn(bomb))
    
    /*  
     *   By making this Container open only when it is discovered, we ensure 
     *   that its contents are inaccessible only when the cap is removed. 
     *   Note that a Container can have an isOpen property even if it is not 
     *   an OpenableContainer; it can still be opened and closed under 
     *   program control, though not by the player issuing OPEN and CLOSE 
     *   commands.
     */
    isOpen = (!isHidden)

    /*  Choose a random wire to be the right one to cut. */
    execute()
    {
        /* 
         *   Normally we'd want this random choice to give a different 
         *   result each time, so we'd call randomize() to re-seed the 
         *   random number generator. But when we're testing it's useful if 
         *   the 'random' results are the same each time through, so we'll 
         *   exclude the call to randomize() from the debug build.
         */
      #ifndef __DEBUG
        randomize();
      #endif
        
        safeWire = rand(redWire, blueWire, greenWire, yellowWire, blackWire);
        safeWire.safeToCut = true;
    }
    
    safeWire = nil
    
    notifyInsert(obj)
    {
        "You'd better not put anything in there; you might set the bomb off! ";
        exit;
    }

;

/*  
 *   The contents of this detonator are fairly basic: we just put five 
 *   coloured wires there. The Wire class is defined below. 
 */

+++ redWire: Wire 'red +'
;

+++ blueWire: Wire 'blue +'
;

+++ greenWire: Wire  'green +'
;

+++ yellowWire: Wire 'yellow +'      
;

+++ blackWire: Wire 'black +'
;

/*   
 *   COLLECTIVE GROUP
 *
 *   We can use a CollectiveGroup to stand in for all five wires when the 
 *   player uses a command including the plural WIRES. This can often give a 
 *   better response than having the parser list a response for each 
 *   individual wire. 
 *
 *   We define wireGroup with only the plural vocabulary for wires. 
 */

+++ wireGroup: CollectiveGroup 'wires'
    "There are five wires in the detonator: one red, one yellow, one green, one
    blue, and one black. <<detonator.safeWire.hasBeenCut ? '\^' +
      detonator.safeWire.theName + ' has been cut.' : ''>>"
    
    /*  
     *   Define which actions we want this CollectiveGroup to handle when the
     *   player directs a command to WIRES in the plural; all other commands
     *   will be handled by each of the individual wires.
     *
     *   We'll handle EXAMINE, CUTWITH, PULL, BREAK, MOVE, PUSH and TAKE
     */    
    
    collectiveActions = [Examine, CutWith, Pull, Break, Move, Push, Take]
    
    dobjFor(CutWith) 
    { 
        verify()         
        {
            /*  Warn the player that cutting all the wires would be fatal. */
            illogical('If you cut all the wires you\'ll certainly detonate the
                bomb. ');
        }
    }
    
    /*  
     *   Provide a suitable message refusing to TAKE WIRES, MOVE WIRES, PUSH 
     *   WIRES, PULL WIRES or BREAK WIRES. This is much neater than having 
     *   the parser respond with the same message five times over, once for 
     *   each wire.
     */
    dobjFor(Take) { verify() { illogical(Wire.cannotTakeMsg); } }
    dobjFor(Move) { verify() { illogical(Wire.cannotTakeMsg); } }
    dobjFor(Push) { verify() { illogical(Wire.cannotTakeMsg); } }
    dobjFor(Pull) { verify() { illogical(Wire.cannotTakeMsg); } }
    dobjFor(Break) { verify() { illogical(Wire.cannotTakeMsg); } }
;

/*   Define the custom Wire class. */
class Wire: Immovable 'wire'
    "\^<<theName>> <<hasBeenCut ? 'has been cut' : 'is intact'>>. "
    
    cannotTakeMsg = 'You know perfectly well that messing with any of those
        wires could set the bomb off. '
    
    cannotCutMsg = 'You can\'t cut {the dobj} with your bare hands. '
    
    /* This is set on the 'right' wire to cut at the start of the game. */
    safeToCut = nil
    
    /* 
     *   Keep track of whether this wire has been cut so it can describe 
     *   itself accordingly.
     */
    hasBeenCut = nil    
    
    /*   Define the custom handling for CUT whichever WIRE (with cutter) */
    dobjFor(CutWith)
    {
        preCond = [touchObj]
        verify()
        {
            /*  
             *   Once it's been cut, there's no point in trying to cut it 
             *   again.
             */
            if(hasBeenCut)
                illogicalNow('{The subj dobj} has already been cut. ');
        }
        action()
        {
            hasBeenCut = true;
            
            /*  
             *   If we're the safe wire, say so and make the bomb safe (stop 
             *   the fuses).
             */
            if(safeToCut)
            {
                "You cut {the dobj} and the bomb stops ticking. ";
                bomb.makeSafe();
            }
            else
                /* Otherwise, the bomb explodes. */
                bomb.explode();
        }
    }        
    
    /*  
     *   Although this is a Immovable, we want the wires to be listed 
     *   in response to LOOK IN DETONATOR.
     */
    isListedInContents = true
    
    /*  The CollectiveGroup object for all Wires. */
    collectiveGroups = [wireGroup]
;


+ Decoration 'some debris;;dust'
    "A layer of dust and debris covers everything in the room. "
;

+ Decoration 'furniture; grey gray; chairs sofa table; it them' 
    "Whatever the furniture was like before the bomb, it's all grey with dust
    now: table, chairs and sofa all equally ruined. "
;

+ Distant 'ceiling; gaping; hole' 
    "A gaping hole in the ceiling indicates where the bomb fell through before
    it landed on the floor and failed to explode. "
    
    specialDesc = "There's a gaping hole in the ceiling. "
;


   
    /*  Treat UNSCREW CAP WITH X as equivalent to TURN CAP WITH X */

Doer 'unscrew cap with Thing'
    execAction(c)
    {
        doInstead(TurnWith, cap, gIobj);
    }
;

//------------------------------------------------------------------------------


hall: Room 'Hall'
    "This small, cramped hall is in keeping with the modest proportions of the
    house. The front door is to the north, while other doors lead to west, east
    and south, and a flight of stairs runs up to the floor above. "
    
    east() { "There's no need to go into any other part of the house; the bomb
        you're concerned with is in the living room, just to the south. "; }
    west() { east; }
    south = hallDoor    
    up = hallStairs
    north = frontDoor
    out asExit(north)
    in asExit(south)
    
    
;

+ hallDoor: Door 'living room door'
    otherSide = lrDoor
;

+ frontDoor: Door 'front door'
    /* Don't let the PC leave until the bomb has been defused. */
    canTravelerPass(traveler)  {  return bomb.fuseID == nil; }
    explainTravelBarrier(traveler)
    {
        "You're not leaving until you're sure that bomb is safe! ";
    }
    
    /*  Once the player goes through the door, the game is over (and won). */
    noteTraversal(traveler)
    {
        "You leave the house knowing that you've done a good job. You're also
        quite glad to be getting out alive!\b";
        finishGameMsg(ftVictory, [finishOptionUndo]);
    }
    
    /* 
     *   This door doesn't really go anywhere, but to satisfy the library and to
     *   allow the noteTraversal() method to execute to end the game, we can
     *   employ the trick of making this door its own other side.
     */
    otherSide = self
;

/*  
 *   StairwayUp with canTravelerPass restriction to make a flight of stairs that
 *   can't actually be climbed.
 */
+ hallStairs: StairwayUp 
    'flight of stairs;;; it them'
    
    canTravelerPass(traveler) { return nil; }
    explainTravelBarrier(traveler)
    {
        "There's no telling what damage the bomb did when it fell through the
        house, so it's probably not safe to go upstairs; but in any case, you
        don't need to. ";    
    }
;

/*   
 *   We put a rat in the hall to provide an example of a SenseDaemon, 
 *   although in practice if we really wanted a rat like this we'd probably 
 *   implement it a little differently (see the NPC demo: what we'd probably 
 *   do is to give the rat a HermitActorState that was also a 
 *   ShuffledEventList and we'd get the SenseDaemon behaviour for free.  
 */
+ rat: InitObject, Thing, ShuffledEventList     
    'rat; small grey gray; rodent animal mammal' 
    "It's a small grey mammal. "
    
    /*   
     *   SENSEDAEMON
     *
     *   We use a SenseDaemon to display the messages describing what the 
     *   rat is doing since we only want these messages to appear when the 
     *   rat is in the same room as the PC.
     *
     *   Since rat is also an InitObject, its execute() method will be 
     *   called on the first turn. This method sets up a SenseDaemon (we 
     *   don't actually need to store a reference to it here, but we'll just 
     *   illustrate how it's done). The SenseDaemon will call the rat's 
     *   doScript method every turn, but will only display the output when 
     *   the rat can be seen by the PC.     
     */         
    execute() { daemonID = new SenseDaemon(self, &doScript, 1); }
    daemonID = nil
    
    eventList =
    [
        'The rat glances up at you curiously. ',
        'The rat scuttles into a corner. ',
        'The rat scratches at the front door. ',
        'The rat gnaws at the floor. ',
        'The rat lies down. ',
        'The rat approaches you, sniffing curiously. ',
        'The rat runs round the room, as if being chased by a phantom cat. ',
        'The rat tries to hide in a shadow. '
    ]
    eventReduceAfter = static eventList.length()
    eventReduceTo = 50
    
    /*  
     *   The following method will display "A rat has found its way into the 
     *   hall" the first time the rat is mentioned in the room description 
     *   and "The rat is still in the hall" each time thereafter.
     */
    specialDesc = "<<one of>>A rat has found its way into <<or>>The rat is still
        in <<stopping>> the hall. " 
    
    cannotTakeMsg = 'The rat scuttles away, evading your grasp. '
    
    /* 
     *   It's not illogical to attempt to attack a rat; we'll just make it
     *   futile
     */
    isAttackable = true
    futileToAttackMsg = (cannotTakeMsg)
;

/*  The PC's bag of tools. */
+ blackBag: OpenableContainer 'black bag'
    "It's the bag you always carry your bomb disposal kit around in. "
    owner = me
    specialDesc = "Your black bag lies in the middle of the hall, just where you
        left it. "
;

++ spanner: Thing 'spanner; adjustable; wrench' 
    "It's adjustable, and you find that it usually turns anything that can be
    turned at all. "
    iobjFor(TurnWith)
    {
        preCond =[objHeld]
        verify() {}
    }
;

++ wireCutter: Thing 'wire cutter'
    "You've cut many a wire with it and it hasn't let you down yet. "
    iobjFor(CutWith)
    {
        preCond = [objHeld]
        verify() {}
    }
;


/*   
 *   CONSULTABLE
 *
 *   A Consultable is something we can look things up in, using commands like
 *   CONSULT MANUAL ABOUT BOMB or LOOK UP BOMBS IN MANUAL. It's an ideal 
 *   class to use for something like a bomb-disposal manual.
 *
 *   We also givee the manual a readDesc, both because it's obviously 
 *   something that the player might try to read, and also so that reading 
 *   can provide information on how to use it. 
 */
++ manual: Consultable 'bomb disposal manual; dark thick blue; book'      
    "It's a thick blue book that gets thicker by the week as you and your
    colleagues learn more and more about the bombs the Luftwaffe keep dropping
    on Britain. "
    
    readDesc =  "The manual emphasizes that the Luftwaffe keep changing the
        detonators on their bombs with each new model with the express purpose
        of making life difficult -- precarious even -- for people like you.
        It's vital that you establish what model of bomb it is before
        attempting any action, otherwise you'll probably blow yourself up. Once
        you've established the model of bomb you can look up the procedure for
        disabling it in this manual. "
    
    /* 
     *   We'll make it that the PC has to hold the manual to read it (or look
     *   things up in it).
     */
    dobjFor(Read) { preCond = [objHeld] }
    dobjFor(ConsultAbout) { preCond = [objHeld] }     
        
;

/*   
 *   CONSULT TOPIC
 *
 *   We use ConsultTopics to implement the various items of information 
 *   contained in a Consultable (just as we use TopicEntries - AskTopic and 
 *   the like - to provide conversational responses for an NPC.
 *
 *   LOOK UP BOMB is an obvious thing for the player to try, so we'll start 
 *   by provided a response to that. We do that by matching this 
 *   ConsultTopic to the bomb object. We'll then simply repeat the response 
 *   you'd get from READ MANUAL. 
 */     
+++ ConsultTopic @bomb
    "<<manual.readDesc>>"
;

/*  
 *   Reading the manual tells the player that it's necessary to discover 
 *   which model of bomb we're dealing with, so the player might try LOOK UP 
 *   BOMB MODEL or LOOK UP MODEL OF BOMB or some variant of that. We'll 
 *   provide a response to this by matching this ConsultTopic on the tModel 
 *   topic (defined below). The response should nudge the player towards 
 *   trying to find a bomb model number on the casing.
 */     
+++ ConsultTopic @tModel
    "According to the manual, the model number of a bomb should be stamped or
    engraved somewhere on its casing. " 
;


/*  
 *   LOOK UNDER BOMB reveals the model number to be ZP640, so we need to 
 *   provide a response to that which tells the player which wire to cut. We 
 *   could create another topic to match on, but instead we'll demonstrate 
 *   matching on a regular expression. If the regular expression syntax is a 
 *   bit baffling, don't worry about it too much: this one will match on 
 *   ZP640, or TYPE ZP640 or MODEL ZP640
 */
+++ ConsultTopic '(type|model){0,1}<space>*zp640'
    "The manual suggests than on a type ZP640 bomb you need to cut
    <<detonator.safeWire.theName>>. "
;

/*  
 *   We can also use regular expressions to match more general patterns. This
 *   ConsultTopic will match any purely numeric entry (e.g. LOOK UP 12345) 
 *   and display a response explaining that purely numeric codes are not used.
 */
+++ ConsultTopic +70 '^<digit>+$'
    "There's no entry for that. The Germans don't seem to be using purely
    numerical codes for their bombs; their codes tend to be either a few letters
    follows by a few numbers or a few numbers followed by a few letters. "
;

/*   
 *   PREINIT OBJECT
 *
 *   The manual is described as being a thick one, so we might expect to find
 *   entries for bomb codes other than ZP640. This ConsultTopic will match 
 *   on any pattern consisting of 1-4 letters followed by 1-4 numbers, or 1-4
 *   numbers followed by 1-4 letters, so that the manual will seem to have 
 *   entries for a vast range of codes. It will then assign a random 
 *   description to the wire that would need to be cut for that kind of bomb.
 *
 *   One complication is that we don't want this ConsultTopic to match 
 *   ZP640, so we give it a lower matchScore than the ZP640 ConsultTopic (80 
 *   instead of the default 100, which is what the +80 in the template means).
 *
 *   The second complication is that if the player enters the same code 
 *   twice, s/he ought to see the same response. If we kept returning a 
 *   random description, then repeatedly looking up, say, PTR534 would tell 
 *   the player first to cut the green wire, then the pink wire, and then 
 *   the long wire (say) and this would look wrong. We therefore store the 
 *   random response this ConsultTopic gives in a LookupTable, so that if 
 *   the player subsequently looks up the same code, this ConsultTopic will 
 *   give the same response. 
 *
 *   That's where the PreinitObject comes in -- we use the execute() method 
 *   of PreinitObject to set up the LookupTable. A PreinitObject is much 
 *   like an InitObject except that its execute() method is run as the last 
 *   stage of compilation rather than at game setup. This means that the 
 *   results of the PreinitObject's execute() method are stored in the game 
 *   image file and don't have to be recomputed each time the game starts. 
 *   PreinitObjects can't be used to display anything or start up Fuses or 
 *   Daemons, but they can be used to perform calculations or, as here, set 
 *   up data structures. 
 */


+++ PreinitObject, ConsultTopic +80 
    '^(<alpha>{1,4}<digit>{1,4}|<digit>{1,4}<alpha>{1,4})$'
    "The manual indicates that the proper procedure for disabling a type
    <<gTopicText.toUpper>> bomb is to cut the <<wireDesc(gTopicText.toUpper)>>
    wire. "
    
    /* 
     *   The custom method we define to return an appropriate description of 
     *   the wire that needs to be cut for this type of bomb.
     */
    wireDesc(txt)
    {
        /* 
         *   First see if we've already stored an entry for this type of 
         *   bomb in our LookupTable.
         */
        local resp = descTab[txt];
        
        /*   
         *   If not, pick a random description from the list and enter it 
         *   into the LookupTable against this kind of bomb.
         */
        if(resp == nil)
        {
            resp =  rand('green', 'red', 'blue', 'orange', 'mauve', 'black', 
                         'white', 'grey', 'pink', 'short', 'long', 'thick', 
                         'thin', 'straight', 'curly');
            
            descTab[txt] = resp;
        }
        
        /*  Either way, then return the result. */
        return resp;
    }
    
    descTab = nil
    
    /*   
     *   Set up the LookupTable in Preinit and then populate it with a few 
     *   sample values.
     */
    execute()
    {
        descTab = new LookupTable(10, 20);
        /*  
         *   We don't really need these entries, but this illustrates how we 
         *   can set up data at Preinit; it also illustrates how a 
         *   LookupTable is used. We store an entry into a table by setting 
         *   tab[key] = value, and then retrieve it by asking for tab[key]. 
         */
        descTab['A1'] = 'best';
        descTab['M25'] = 'orbital';
        descTab['K9'] = 'dog-eared';
    }
;

/*  
 *   We've allowed MODEL ZP640 or TYPE ZP640 in addition to just ZP640 as a 
 *   possible target of a LookUp command that references the bomb we actually
 *   need. The following ConsultTopic uses a regular expression to trap 
 *   LOOK UP MODEL/TYPE anything else and show a message telling the player 
 *   simply to enter the code (and the format of codes expected) without 
 *   preceding it with MODEL or TYPE. We don't want this ConsultTopic to 
 *   match TYPE ZP640 or MODEL ZP640, though, so we give it a matchScore of 
 *   90 (lower than the default of 100 used on the ZP640 ConsultTopic).
 */
+++ ConsultTopic +90 '^(model|type).+'
    "There's no need to include MODEL or TYPE, just look up the code, e.g, LOOK
    UP RD99; note that the model number of these German bombs is normally one
    to four digits followed by one to four letters, or one to four letters
    followed by one to four digits. "
;

/*   
 *   DEFAULT CONSULT TOPIC
 *
 *   Finally, we provide a DefaultConsultTopic to respond to anything not 
 *   covered by the foregoing ConsultTopics, e.g. LOOK UP GLOBAL WARMING or 
 *   CONSULT MANUAL ABOUT BAKED BEANS.
 */
+++ DefaultConsultTopic
    "The manual doesn't have anything useful to say about that. "
;

/*   The Topic object used above. */
tModel: Topic '(bomb) model;; models number';






//------------------------------------------------------------------------------

/*   
 *   The other object representing the cap, once it's been removed from the 
 *   detonator. For the most part it's just an ordinary Thing, which is given
 *   the same description as the cap.
 */
cap2: Thing 'cap; metal (detonator)'
    "<<cap.desc>>"
    
    /* Let the parser know we're really the same physical object as cap. */
    getFacets = [cap]
    
    /* 
     *   Assume that PUT CAP ON BOMB means replace it on the detonator; in 
     *   which case we move the original cap object back to the bomb and 
     *   move cap2 back into nil.
     */
    dobjFor(PutOn)
    {
        action()
        {
            if(gIobj == bomb)
            {
                "You replace the cap on the bomb. ";
                moveInto(nil);
                cap.moveInto(bomb);
            }
        }
    }
;