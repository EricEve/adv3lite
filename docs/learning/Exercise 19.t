#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*   
 *   EXERCISE 19 - LOCKS AND GADGETS
 *
 *   A demonstration of Locks, Keys, Gadgets and Controls.
 *
 *   This is a complete game insofar as there is an objective and it's 
 *   possible to win, but it's not really complete in terms of implementing 
 *   everything that ought to be implemented in a real game. It's basically 
 *   a coding demonstration.
 *
 *   The main purpose of this demo is to illustrate the use of the various 
 *   Lockable, Key, gadget and control-type classes. It has, of course, been 
 *   necessary to include some objects from various other class-families as 
 *   well in order to make a coherent game, but in the main these have been 
 *   kept to a minimum.
 */


/*
 *   VERSION INFO
 *
 *   Our game credits and version information.  This object isn't required 
 *   by the system, but our GameInfo initialization above needs this for 
 *   some of its information.
 *
 *   You'll have to customize some of the text below, as marked: the name of 
 *   your game, your byline, and so on.
 */
versionInfo: GameID
    IFID = '49d00c5d-5706-4d5d-a55d-8a80fb003aa1'
    name = 'Exercise 19 - Locks and Gadgets'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A demo of adv3Lite Locks, Keys, Gadgets and Controls'
    htmlDesc = 'A demo of adv3Lite Locks, Keys, Gadgets and Controls'
;

/*
 *   GAME MAIN
 *
 *   The "gameMain" object lets us set the initial player character and 
 *   control the game's startup procedure.  Every game must define this 
 *   object.  For convenience, we inherit from the library's GameMainDef 
 *   class, which defines suitable defaults for most of this object's 
 *   required methods and properties.  
 */
gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    showIntro()
    {
        "Baron Lothar von Erpresser is out; you know because you arranged for
        him to be sent an invitation to the reception at the Patagonian
        embassy, which he was unable to resist. His house will be empty for the
        next few hours, affording you the best opportunity to recover that
        unfortunate letter. You're not prepared to pay the price he's asking
        for it, and if he carries out his threat to send it to your betrothed
        your marriage prospects will be seriously compromised.\b
        You're pretty sure he's keeping the incriminating letter in a safe in
        his study. You're well equipped to recover it; all you need to do now
        is enter the house, recover the letter, and make a quick getaway. The
        baron has such a poor memory for numbers that you feel sure he'll have
        written down the combination somewhere. \b";
    }
;

/*  
 *   ENUMERATOR
 *
 *   We can define an enumerator with whatever names we like. Here we'll 
 *   define a couple of values to keep track of the nationality of the player
 *   (character).
 */

enum british, american;


/*   We'll modify Thing to give every portable object a default bulk of 1 */

modify Thing
    bulk = (isFixed ? 0 : 1)
;


/* 
 *   OUTDOOR ROOM
 *
 *   Starting location - we'll use this as the player character's initial 
 *   location.  The name of the starting location isn't important to the 
 *   library, but note that it has to match up with the initial location for 
 *   the player character, defined in the "me" object below.
 *
 *   Our definition defines two strings.  The first string, which must be in 
 *   single quotes, is the "name" of the room; the name is displayed on the 
 *   status line and each time the player enters the room.  The second 
 *   string, which must be in double quotes, is the "description" of the 
 *   room, which is a full description of the room.  This is displayed when 
 *   the player types "look around," when the player first enters the room, 
 *   and any time the player enters the room when playing in VERBOSE mode.
 *
 */
drive: Room 'Front Drive'
    "Langtree House, a sprawling Edwardian mansion, lies before you just to the
    south, while to the north the drive leads back down to the road. "
    south = frontDoorOutside
    in asExit(south)
    
    north: TravelConnector {        
        
        /* 
         *   We prevent the player character from leaving towards the road 
         *   until s/he is carrying the letter. When the player character 
         *   does leave for the road, we'll end the game.
         */
        canTravelerPass(traveler) { return letter.isIn(traveler); }
        explainTravelBarrier(traveler)
        {
            "You're <i>not</i> leaving without that letter! ";            
        }
        
        /*  
         *   Once the PC travels via this connector, the game is won, so we 
         *   end the game in victory (i.e. display a YOU HAVE WON message 
         *   and end the game.
         */
        
        noteTraversal(traveler)
        {
            "As you walk down the drive you tuck the letter safely inside your
            coat. The baron won't be back for hours yet; by the time he finds
            the letter has gone it'll have been burned to cinders in your
            hearth. And what can he do then? Report the theft to the police?\b
            You chuckle merrily at the thought as you walk out into the
            road.\b";
            finishGameMsg(ftVictory, [finishOptionUndo, finishOptionAmusing]);
        }
    }
;

/* 
 *   The player character object. This doesn't have to be called me, but me is a
 *   convenient name. If you change it to something else, rememember to change
 *   gameMain.initialPlayerChar accordingly.
 */

+ me: Player 'you'   
    "You are dressed all in black, as befits a burglar. "    
    
    /*  
     *   A custom property that will be used later on. The possible values 
     *   are british and american.
     */
    nationality = british
;

/*  
 *   FLASHLIGHT
 *
 *   A Flashlight is both a gadget and a Light Source, being a special kind of 
 *   Switch.  
 *
 *   The ostensible purpose of this torch/flashlight is to allow the player 
 *   character to see in the darkened hall, and it is indeed the kind of 
 *   thing one might expect some intended burglary to be carrying. The real 
 *   purpose is to guess when the player is more comfortable with British or 
 *   American English. A British player will most likely call this device a 
 *   'grey torch' while an American will be more likely to refer to it is a 
 *   'gray flashlight'.
 */

++ torch: Flashlight 'plastic tube; plastic grey gray; switch torch flashlight
    torch' 
    "<<if name == 'plastic tube'>>It's a plastic tube of a colour midway between
    black and white, with a switch than can be turned on and off to produce
    light. <<else>>It's a plastic <<name>>. "
       
    
    /*  
     *   The normal purpose of matchNameCommon() is to decide whether we 
     *   want to interfere with the parser's choice of this object as match 
     *   for what the player typed. We don't interfere with that here at 
     *   all; instead we take advantage of the fact that this routine is 
     *   called whenever the player refers to this object to see what words 
     *   the player used to refer to it.
     */
    
    matchNameCommon(tokens, phrases, excludes)
    {
        
        
        /* 
         *   Don't worry too much if the next statement looks like a piece of
         *   arcane mumbo-jumbo. The adjustedTokens parameter will contain a
         *   list that looks something like ['grey', &adjective, 'torch', 
         *   &noun]. What the following statement does is to ensure that all 
         *   the string values in the list are converted to lower case while 
         *   leaving the others untouched. This makes it easier to see 
         *   whether words like 'torch' or 'flashlight' occur in the list 
         *   without worrying whether the player typed them in upper or 
         *   lower case.
         */
        
        local lst = tokens.mapAll({x: dataType(x) == 
                                          TypeSString ? x.toLower() : x});
        
        /* 
         *   Test first to see if the player has used the word 'torch' or 
         *   'flashlight', and if so use that to determine the name of this 
         *   object (and the nationality of the player). Otherwise see if 
         *   'grey' or 'gray' has been used.
         */
        
        if(lst.indexOf('torch'))        
            name = britishName;
        else if (lst.indexOf('flashlight'))
            name = americanName;
        else if(lst.indexOf('grey'))
            name = britishName;
        else if(lst.indexOf('gray'))
            name = americanName;
               
        /* 
         *   Now set the nationality of the player according to the name of 
         *   this object. Note that if the player refers to us a plastic 
         *   tube we can't make a decision on nationality and so we won't 
         *   change it.
         */
        
        if(name == britishName)
            me.nationality = british;
        if(name == americanName)
            me.nationality = american;
            
        return inherited(tokens, phrases, excludes);
    }
    britishName = 'grey torch'
    americanName = 'gray flashlight'
;

/*  
 *   LOCKABLE CONTAINER
 *
 *   This is a basic LockableContainer; it has a lock but no key is needed to
 *   unlock it, and opening the case will perform an implicit unlock 
 *   action, so the lock performs virtually no function in practice. We'll 
 *   meet some more challenging lockable containers below.
 */

++ LockableContainer 'small black case' 
    "It's very small, not big enough to impede your movements, just large
    enough to contain some essential equipment for the job. "
    
    /* 
     *   We've described the case as very small, so let's make its 
     *   bulkCapacity match that.
     */
    bulkCapacity = 3
    bulk = 3
;

/*   
 *   KEY
 *
 *   As its name implies, this skeleton key will be able to open just about 
 *   any keyed lock in the game. This will be used to illustrate that one 
 *   key can open several locks, and that several keys can be defined as 
 *   opening the same lock.
 */

+++ skeletonKey: Key 'skeleton key; thin  metal'
    "It's a thin metal key, with cunningly designed teeth. "
    
    /* The skeleton key works in a number of locks. */
    actualLockList = [frontDoorOutside, frontDoorInside, whiteBox]
;


/*  
 *   ENTERABLE
 *
 *   We use an Enterable to represent the house and point its connector 
 *   property to the front door (so that ENTER HOUSE will attempt to take 
 *   the PC through the front door.
 */

+ Enterable 'house; langtree edwardian sprawling; mansion'     
    "It looks a little gloomy and intimidating in the twilight, but most of all
    you resent its occupancy by a man who makes his money in so vile a fashion.
    "
    
    connector = frontDoorOutside
;



/*
 *   A DOOR THAT CAN BE LOCKED WITH A KEY
 *
 *   A door is an obvious thing to lock and unlock with a key, and here we 
 *   provide a simple example. The description provides a hint for a 
 *   combination to be used just inside. Since the door describes itself as 
 *   hard to break, we provide a corresponding custom shouldNotBreakMsg to 
 *   respond to an attempt to break the door.
 */

+ frontDoorOutside: Door 'front door; solid oak; lintel' 
    "The date carved on the lintel, 1908, confirms that the house is indeed
    Edwardian. The door itself is of solid oak; there's no way you're going to
    break it down. "
    
    otherSide = frontDoorInside
    
    shouldNotBreakMsg = 'It\'s made of solid oak; there\'s no way you can break
        it down. '
    
    lockability = lockableWithKey
    
    isLocked = true     
;

/*   
 *   KEY HIDDEN UNDER POT
 *
 *   Hiding a key under a pot just by the door hardly constitutes an exciting
 *   puzzle, but here the point is simply to provide an example of two keys 
 *   opening the same door.
 */

+ pot: Thing 'flowerpot; old flower; pot'
    initSpecialDesc = "An old flowerpot rests on the ground near the front door.
        "
    
    hiddenUnder = [doorKey]
;


/*  
 *   KEY
 *
 *   This is the other key that will unlock the front door. 
 */

doorKey: Key 'small brass key'
    actualLockList = [frontDoorOutside, frontDoorInside]
;


//------------------------------------------------------------------------------
/*  
 *   TRAVEL BARRIER
 *
 *   We define this TravelBarrier object here so that we can go on to use it 
 *   on three different connectors inside the house. The idea is to prevent 
 *   the PC from going beyond the hall until s/he's turned off the burglar 
 *   alarm.
 */

alarmBarrier: TravelBarrier
    canTravelerPass(traveler, connector) { return !alarmPanel.isOn; }
    explainTravelBarrier(traveler, connector)
    {
        "You daren't go further into the house until you've disabled the
        alarm. ";
    }
;

hall: Room 'Hall'
    "The hall reflects a kind of fading grandeur, as if struggling to recall
    the happier days of imperial spendour in which it was built, long before it
    fell into the hands of a dastardly blackmailing foreigner. The way to the
    dastard's study is immediately to the east. The gloomy hall continues
    southwards towards the kitchen while a broad flight of stairs leads up to the
    floor above. The front door lies to the north, with an incongruously modern
    white box set on the wall just by it. "
    
    north = frontDoorInside
    out asExit(north)
    
    /* 
     *   This ONE WAY ROOM CONNECTOR is in place simply so we can put the 
     *   alarm barrier on it. The player can't go east from the hall until 
     *   the alarm has been switched off.
     */
    
    east: TravelConnector
    {
        destination = study
        travelBarriers = [alarmBarrier]
    }
    
    /*   
     *   This fake TRAVEL CONNECTOR exists simply to make the house appear
     *   bigger than the number of rooms we're actually implementing (since we
     *   described it as a sprawling mansion from the outside). Note that the PC
     *   can't actually travel via this connector under any circumstances, but
     *   that different reasons will be given depending on whether the alarm is
     *   on or off; while the alarm is on the travelBarrier will take precedence
     *   over the travelDesc message.
     */
    
    south: TravelConnector 
    { 
        travelDesc = "<<one of>>You find that that <<or>>That <<stopping>> way
            leads to the kitchen, but you don't need to eat just at the
            moment. " 
        travelBarriers = [alarmBarrier]
        destination = hall
    }
    up = hallStairs
    
    isLit = nil
;


/*  
 *   DOOR LOCKABLE WITH KEY, DOOR 
 *
 *   This is the other side of the outside of the front door, defined above; 
 *   and the definition is much the same.
 */

+ frontDoorInside: Door 'front door' 
    otherSide = frontDoorOutside
    lockability = lockableWithKey
    isLocked = true    
;

/*  
 *   FAKE STAIRWAY UP
 *
 *   We can use StairwayUp to make a staircase that will never be climbed. While
 *   the alarm is on the alarmBarrier will take precedence for explaining why
 *   not, but once it's off the travelDesc will provide the expanation.
 *
 *   Again, the purpose of this staircase is simply to suggest that the house is
 *   larger inside than we've really made it.
 */

+ hallStairs: StairwayUp 'flight of stairs;;;it them'
   travelDesc = "Upstairs you'll find only bedrooms and bathrooms, and you
       don't want to sleep or wash right now. "      
    
    travelBarriers = [alarmBarrier]
;

/*   
 *   KEYED CONTAINER
 *
 *   A KeyedContainer does need a key to lock it and unlock it. We define 
 *   this one so that either the skeleton key or the silver key will unlock 
 *   it.
 */

+ whiteBox: KeyedContainer, Fixture 'white box; incongruously small modern'
    "It's quite small, and is fitted at about shoulder height just next to the
    front door. "
    cannotTakeMsg = 'The box is firmly fixed to the wall. '
        
    /* 
     *   Listening to the box should give the sound of the beep, but only if the
     *   alarm panel is on.
     */
    listenDesc()
    {
        if(alarmPanel.isOn)
            beep.desc;
    }
;

/*  
 *   FIXTURE
 *
 *   This panel object is used to represent the innards of the burglar alarm 
 *   control box. Note that we override isListedInContents and isListed so 
 *   that this panel is clearly announced as being in the box once the box is
 *   opened.
 */

++ alarmPanel: Fixture 'alarm panel;;keypad' 
    "It has a keypad with ten buttons, numbered 0 to 9. <<isOn ? 'A red light
        is flashing on the panel' : 'The red light is off'>>. "
    isListedInContents = true
    isListed = true
    
    /* 
     *   Here we provide the code for turning off the alarm by typing the 
     *   correct code on the keypad. Note that the combination matches the 
     *   date on the door lintel outside, but by defining a custom 
     *   combination property we make it easy to change it to anything we 
     *   like.
     */
    
    combination = '1908'
    dobjFor(TypeOn)
    {
        verify() {}
        
        /*  
         *   Since the keypad is described as having buttons numbered 0 to 9 
         *   we need to rule out the attempt to type any other characters on 
         *   it.
         */
        
        check()
        {                        
            for(local i=1; i <= gLiteral.length; i++)                
            {
                local cur = gLiteral.substr(i, 1);
                if(cur < '0' || cur > '9')
                {
                    "You can only type numbers on the keypad; <q><<cur>></q>
                    isn\'t a number. ";
                }
            }
        }
        
        /*  
         *   If what the player types matches the combination, turn off the 
         *   alarm.
         */        
        action()
        {
            "Okay, you type <<gLiteral>> on the keypad";
            if(gLiteral == combination)
            {
                "; the red light stops flashing and the beeping stops";
                alarmPanel.isOn = nil;
            }
            ". ";
        }
    }
    isOn = true
    
    /* Make ENTER XXXX ON KEYPAD equivalent to TYPE XXX ON KEYPAD */
    
    dobjFor(EnterOn) asDobjFor(TypeOn)

;

/*  
 *   BUTTON
 *
 *   Our example of the Button class has a couple of little tricks to it. 
 *   First of all, when it's pressed all it does is to tell the player to 
 *   try typing on the keypad instead (so instead of typing PUSH BUTTON 1, 
 *   PUSH BUTTON 9, PUSH BUTTON 0, PUSH BUTTON 8, they just need to type 
 *   TYPE 1908 ON KEYPAD). Secondly we make one Button object represent all 
 *   10 buttons. As we've defined the vocabWords below our button will match 
 *   BUTTON 0, BUTTON 1, and so on all the way up to BUTTON 9. So whichever 
 *   (valid) button the player tries to press s/he'll be told to type on the 
 *   keypad instead.
 */

+++ Button 'button; small 0 1 2 3 4 5 6 7 8 9; key' 
    
    "There are ten small buttons, numbered 0 to 9. "
    
    makePushed = "Instead of pushing individual buttons, just TYPE number ON
        KEYPAD. "    
;

/*   
 *   COMPONENT
 *
 *   This simply represents the red light that's mentioned in the 
 *   description of the alarm panel.
 */

+++ redLight: Component 'red light' 
    "It's <<alarmPanel.isOn ? 'flashing' : 'off'>>. "
;

/*  
 *   NOISE
 *
 *   Until the alarm is switched off it beeps continuously. The Noise represents
 *   the beep. Until the alarm is switched off the player will be told that "A
 *   beeping comes from the white box" on every turn. This will also be the
 *   response to LISTEN, or LISTEN TO BEEP or LISTEN TO BOX.
 *
 *   Note that in this case we don't locate the beep in the box, or it will be
 *   out of scope when the box is closed.
 */

+ beep: Noise 'beeping sound;;beep' 
    "A beeping sound comes from the white box. "
      
    /*  We want this sound to stop once the alarm is switched off. */
    isEmanating = (alarmPanel.isOn)
    
    /*  
     *   We want this sound to be mentioned every turn that the alarm is on.
     *   Here we'll just use the beep's afterAction method to do the trick; a
     *   more sophisticated implementation could make use of the sensory
     *   extension.
     */
    afterAction()
    {
        if(!gActionIn(Listen, ListenTo) && isEmanating)
            desc;
    }
;

/*  
 *   IMMOVABLE
 *
 *   The hatstand provides a rather implausible excuse for illustrating a 
 *   spring lever (see below). We make it Immovable rather than a Fixture, 
 *   say, because it's not clearly impossible for the PC to take the 
 *   hatstand, we'll just rule it out as pointless instead.
 */


+ hatStand: Immovable 'hat-stand; tall old wooden (hat); stand hatstand'   
    "It's a tall wooden stand, with a number of pegs for hanging hats on. There
    are no hats on the stand at the moment, but closer examination suggests that
    one of the pegs is hinged. "
    
    specialDesc = "An old wooden hat-stand lurks to one side. "
    
    cannotTakeMsg = 'You don\'t want to be encumbered with it, so you may as
        well leave it where it is. '
;

/*  
 *   SPRING LEVER
 *
 *   As Spring Lever is a lever that returns to its original position when it 
 *   is released, making it functionally equivalent to a Button. This 
 *   somewhat contrived example of a Spring Lever drops the alarm box key 
 *   onto the floor when it is first pulled. It hardly matters if the player 
 *   doesn't discover this since the skeleton key in the black case will do 
 *   the job just as well.
 */

++ peg: Lever, Component 'hinged peg'
    dobjFor(Pull)
    {
        action()
        {
            if(silverKey.isIn(nil))
            {
                "When you pull the peg a silver key drops onto the floor. ";
                silverKey.moveInto(hall);
            }
            else
                "You pull the peg but it springs back into place when you let
                go again. ";
        }
    }
    
;

/*  
 *   Another KEY. 
 */

silverKey: Key 'small silver key'    
    actualLockList = [whiteBox]
;


//------------------------------------------------------------------------------
/*  ROOM */

study: Room 'Study'
    "A large wooden desk stands in the middle of the room, facing a television
    in the corner. The way out to the hall lies west, but to the north a
    door-sized panel has been set into the wall. "
    west = hall
    out asExit(west)
    north = panel
;

/*  
 *   INDIRECT LOCKABLE, DOOR
 *
 *   An Indirect Lockable is something that is locked and unlocked by some
 *   mechanism other than a key. We'll meet the odd mechanism for unlocking this
 *   door below.
 *
 *   Note the use of ->cubbyPanel in the template. This is an alternative way of
 *   defining the otherSide property.
 */

+ panel: Door ->cubbyPanel 'panel; door-sized'
    "It's about the shape and size of a door, but there's no handle or lock --
    at least, none visible. "
    
    lockability = indirectLockable
;

/*  
 *   SURFACE, HEAVY
 *
 *   A study ought to have a desk it it, if nothing else, so we'll provide 
 *   one. This desk will have a drawer that contains a clue to finding the 
 *   safe and opening it.
 */

+ Surface, Heavy 'desk; large wooden desk; top' 
    "The baron must have very tidy working habits, since the top of his desk
    looks <<contents.length() > 0 ? 'almost' : ''>> entirely bare. You note,
    however, that the desk has a drawer. "
    
    /* 
     *   Redirect opening, closing, locking, unlocking and looking in to the 
     *   drawer.
     */
    remapIn = drawer
;

/*  
 *   KEYED CONTAINER
 *
 *   The drawer is another KeyedContainer. Again it can be unlocked either with
 *   its own key or with the PC's skeleton key. This time we'll show the other
 *   way of defining the relationship between locks and keys by listing the keys
 *   that can unlock it in its keyList property.
 */

++ drawer: KeyedContainer, Component 'drawer; small'
    "It's not very big. "
    
    keyList = [skeletonKey, drawerKey]
    dobjFor(Pull) asDobjFor(Open)
    dobjFor(Push) asDobjFor(Close)
    
;

/*  
 *   AN OPENABLE NOTEBOOK
 *
 *   Most openable objects will be either doors or containers, but a few 
 *   other things can be opened as well, such as books. To illustrate this 
 *   we'll make this notebook openable.
 */

+++ notebook: Thing 'small red notebook;; book'
    "It's a small red notebook. "
    readDesc = "Most of the pages are blank, but towards the back you find
        someone has written <q><<tvDial.advertising>> is safe:
        <<dial.combination>></q>"
    
    isOpenable = true
    dobjFor(Read) { preCond = [objHeld, objOpen] }
;



/*  
 *   MULTIPLEX CONTAINER
 *
 *   The small wooden box is going to be used to illustrate the Settable 
 *   class (in the form of a slider used to unlock it). Note that we have to 
 *   make the box a Multiplex Container, because we're going to add an external 
 *   component; if we made smallBox an lockable container directly (a very 
 *   easy trap to fall into) we'd find that the external component (the 
 *   slider) actually ended up locked up inside the box, where it would be 
 *   permanently inaccessible.
 */

++ smallBox: Thing 'small wooden box; carved'
    "It is delicately carved, and has a strange slider on one side. "
    
    /* 
     *   INDIRECT LOCKABLE
     *
     *   The subContainer provides an example of an IndirectLockable 
     *   OpenableContainer, that is a container locked and unlocked by some 
     *   means other than a key.
     */
    
    remapIn: SubComponent, OpenableContainer
    {
        bulkCapacity = 2
        lockability = indirectLockable
    }
;

/*  
 *   KEY
 *
 *   Inside the small wooden box we put the key to the desk drawer. Since we've
 *   listed this key in the keyList property of the drawer, we don't need to
 *   define this key's actualLockList property.
 */

+++ drawerKey: Key 'small gold key' 
    subLocation = &remapIn    
;

/*   
 *   SETTABLE
 *
 *   As an example of the base Settable class we'll implement a slider on the
 *   outside of the box that's used to unlock it. To unlock the box the 
 *   player must spell out OPEN with the initial letters of the composers' 
 *   names. It doesn't matter here that this isn't a particularly fair 
 *   puzzle (a) because the player can always use the skeleton key instead 
 *   and (b) this is only a demo, after all, and the point is to illustrate 
 *   the Setter class, not to create a great puzzle.
 *
 *   It's more important that Settable only provides a framework, so that to 
 *   make it work as a slider we shall have to do quite a bit of the work 
 *   ourselves.
 */
 

+++ slider: Settable, Component 'slider;;pointer' 
    "The slider has a pointer which can be set to one of the names engraved
    along its length (which all seem to be names of composers): Elgar, Nielsen,
    Offenbach or Pachabel. It's currently set to <<curSetting>>. "
    
    curSetting = 'Elgar'
    
    /* 
     *   This is not a standard library property on Settable (although it is 
     *   on some of Settable's subclasses); it's one we're defining for 
     *   ourselves.
     */
    validSettings = ['Elgar', 'Nielsen', 'Offenbach', 'Pachabel']
    
    
    /*  
     *   We define a custom settingHistory property to contain a record of 
     *   the initial letters of the last four settings the player moved the 
     *   slider to (so we can check if this ever spells 'OPEN')
     */
    
    settingHistory = ''
    
    makeSetting(val)
    {
        inherited(val);
        
        /* Add the first letter of the setting string to the settingHistory */
        settingHistory += val.substr(1,1);
        
        /* 
         *   If settingHistory is longer than four letters, keep only the 
         *   last four letters
         */
        if(settingHistory.length() > 4)
            settingHistory = settingHistory.substr(-1, 4);
            
    }
    
    /* Make the setting initially capitalized */
    canonicalizeSetting(val)
    {
        return val.substr(1,1).toUpper() + val.substr(2).toLower();
    }
    
    dobjFor(SetTo)
    {
        action()
        {
                        
            inherited();
            
            /* 
             *   If the latest setting makes the last four settings 
             *   (including the latest) spell OPEN then unlock the box; 
             *   otherwise lock it.
             */
            if(settingHistory == 'open')
            {
                smallBox.remapIn.makeLocked(nil);
                "As you set the pointer to <<curSetting>> you hear a faint click
                from the box. ";
            }
            else
            {
                "You set the pointer to <<curSetting>>. ";
                smallBox.remapIn.makeLocked(true);
            }
        }
                
    }
;


/*  
 *   HEAVY 
 *
 *   A television may seem a highly unlikely device for opening a door, but 
 *   Baron von Epresser is a bit of a weirdo, and the TV allows us to 
 *   illustrate a few more devices and contraptions.
 */

+ tv: Heavy 'television;; tv telly screen' 
    "Beneath the screen the TV has a switch and a dial. <<tvSwitch.isOn ?
      reportResponse(tvDial.curSetting, nil) : 'The screen is currently
          blank. '>>"
    
    /* 
     *   The reportResponse() method shows what's on the TV screen when the 
     *   dial is turned to val. If trigger is true it also unlocks and opens 
     *   the panel when val is 'advertising' (we don't want this effect when 
     *   reportResponse() is called from desc(), i.e. when the player is 
     *   simply examining the TV).
     */
    
    reportResponse(val, trigger)
    {
        
        "The screen shows ";
        switch(val.toLower())
        {
            case 'sport': 
            case 'sports': "a football match. "; break;
            case 'soap': "episode 34,954,221,345 of the world's longest running
                soap-opera, in which the Amoeba family are still quarreling
                over evolutionary challenges. ";
            break;
            case 'news': "a news broadcast that looks even more depressing than
                usual: your least favourite political party is 12 points ahead
                in the polls, interest rates are set to double, and every key
                public sector worker is going on strike indefinitely pending the
                grant of the unions' demands for 53 weeks' holiday a year."; 
            break;
            case 'weather': "the latest weather forecast: scattered showers,
                sunny periods, hail, snow, heatwave, drought, and floods at
                various times and sundry odd places. "; break;
            case 'drama': "a particularly gory production of <i>Hamlet</i>. "; break;
            case 'music': "a classical concert -- one of Mahler's extra-long
                symphonies by the look of it. "; break;
            case 'advertising': 
            case 'home shopping': "a series of advertisements for useless items
                you never knew you wanted and certainly can't afford. "; 
            if(trigger)
            {
                "The panel slides <<panel.isOpen ? 'shut' : 'open'>>. ";
                panel.makeLocked(!panel.isLocked);
                panel.makeOpen(!panel.isOpen);                    
            }
            
            break;
            default: "little of interest. "; break;
        }
    }
    
    dobjFor(SwitchOn) { remap = tvSwitch }
    dobjFor(SwitchOff) { remap= tvSwitch }
;


/*  
 *   SWITCH 
 *
 *   We could simply have made the TV a switch, since most people will 
 *   probably try to turn it on an off directly (which we also allow through 
 *   the remap statements above). But since the description of the TV refers 
 *   to it as a separate object we may as well implement it separately.
 *
 *   Note that Switch is a subclass of OnOffControl and behaves almost 
 *   identically except that it also responds to the commands SWITCH and 
 *   FLIP, which toggle it between its on and off states. Since the two 
 *   classes are so similar we shall not provide a separate example of an 
 *   OnOffControl.
 */

++ tvSwitch: Switch, Component 'switch; on-off'
    "It's just a simple on-off switch. "
    makeOn(val)
    {
        inherited(val);
        if(val)
            tv.reportResponse(tvDial.curSetting, true);
        else
            "The screen goes blank. ";
    }
;


/*  
 *   DIAL
 *
 *   A Dial is a specialization of Settable, representing a dial that 
 *   can be turned to a number of author-defined settings. 
 */

++ tvDial: Dial, Component 'dial'
    "The dial can be turned to <<listSettings()>>; it's currently turned to
    <<curSetting>>. "
    
    /* 
     *   validSettings is a library property on LabeledDial, but we need to 
     *   define what the valid settings are.
     *
     *   Note that while five of the settings have been defined with literal 
     *   strings, two have been defined with properties of the dial object. 
     *   This incidentally shows that properties and strings can safely be 
     *   mixed in a list such as this, but it also shows how we might make 
     *   the list adaptive.
     */
    validSettings = [sport, 'soap', 'news', 'weather', 'drama',
        advertising, 'music' ]
    
    
    curSetting = validSettings[1]
    
    /*  
     *   listSettings() is a custom method we are defining here so that the 
     *   description of the dial will automatically (and accurately) reflect 
     *   the validSettings defined above.
     */
    listSettings()
    {
        foreach(local cur in validSettings)                
        {            
            if(validSettings.indexOf(cur) == validSettings.length())
                "or <<cur>>";
            else
                "<<cur>>, ";
        }
    }
    makeSetting(val)
    { 
        inherited(val);
        
        /* 
         *   If the TV is on, we need to change what it displays in 
         *   accordance with the new setting, and report the change.
         */
        if(tvSwitch.isOn)
            tv.reportResponse(val, true);
    }    
    
    /*  
     *   We define these two settings through properties since British and 
     *   American players might expect to see them described differently.
     */
    
    advertising = (me.nationality == british ? 'advertising' : 'home shopping')
    sport = ( me.nationality == british ? 'sport' : 'sports')
;


//------------------------------------------------------------------------------
/* ROOM */

cubbyHole: Room 'Cubby Hole'
    "This really is no more than a tiny cubby hole, with fully half the space
    taken up with a huge safe. The only other feature of interest here is the
    green lever set in the wall, next to the sliding panel to the south. "
    south = cubbyPanel
    out asExit(south)
;

/*  
 *   INDIRECT LOCKABLE, DOOR
 *
 *   The cubby panel represents the other side of the panel in the study. It 
 *   too is an indirect lockable, but we'll provide a different (and simpler)
 *   mechanism for locking and unlocking it from this side.
 */

+ cubbyPanel: Door  ->panel 'panel; sliding'
;

/*   
 *   LEVER
 *
 *   A Lever can be in one of two states: pushed and pulled. It can then be 
 *   pulled and pushed respectively to change states. Here we use a Lever to 
 *   provide a simple mechanism for opening/unlocking and closing/locking the
 *   sliding panel from inside the cubby hole.
 */

+ Lever, Fixture 'green lever' 
    "It's set at a convenient height in the wall. "
    makePulled(stat)
    {
        cubbyPanel.makeOpen(stat);
        cubbyPanel.makeLocked(!stat);
        "The panel slides <<stat ? 'open' : 'closed'>>. ";
    }
;



/*  
 *   MULTIPLEX CONTAINER
 *
 *   Like the small wooden box on the desk above, the safe needs to be 
 *   implemented as a Mutiplex Container since it has an exterior component, in
 *   this case the dial used to unlock it.
 */

+ safe: Heavy 'safe; huge; door' 
    "Apart from looking huge and impregnable, the most interesting feature of
    the safe is the black dial set in the middle of its door. " 
    
    remapOn: SubComponent { }
    remapIn: SubComponent, OpenableContainer 
    {
        cannotLockMsg = 'Presumably, you have to use the dial. '
        cannotUnlockMsg = (cannotLockMsg)
        lockability = indirectLockable
    }
    
;

/*   
 *   NUMBERED DIAL
 *
 *   NumberedDial is a specialization of Dial. As its name suggests it can be
 *   used to represent a dial that can be turned to a range of mumeric values.
 *   Here we use it for a classic combination lock.
 */


++ dial: NumberedDial, Component 'black dial' 
    "It's a black dial which can be turned to any number from 0 to 99; it's
    currently turned to <<curSetting>>. "
    
    /* 
     *   The following three properties are standard library properties for a
     *   NumberedDial. Note the oddity that while minSetting and maxSetting 
     *   have to be defined with integer values, curSetting has to be 
     *   defined (and used) as a string.
     */
    minSetting = 0
    maxSetting = 99
    curSetting = '15'
    
    /*   
     *   Since we're using the dial as a combination lock, we'd better give 
     *   it a combination. Again, this is a string property (since it will be
     *   matched against values of curSetting, which is a string). 
     */
    combination = '239756'
    
    /*   
     *   We also need a property to store the numbers to which the dial has 
     *   been turned, so that we can tell when the correct combination has 
     *   been entered.
     */
    numbersDialled = ['0','0','0']
    
    
    dobjFor(SetTo)
    {
        action()
        {
            inherited;
            
            /* Keep a record of the last three numbers dialled */
            numbersDialled[1] = numbersDialled[2];
            numbersDialled[2] = numbersDialled[3];
            numbersDialled[3] = curSetting;
            
            /* 
             *   If the last three numbers dialled match the combination, 
             *   unlock the safe, otherwise lock it if it is closed.
             */
            
            if(numbersDialled[1] + numbersDialled[2] + numbersDialled[3] ==
               combination)
            {
                safe.remapIn.makeLocked(nil);
                "As you turn the dial to <<curSetting>>, a satisfying
                <i>click</i> comes from the safe. ";
            }
            else if(!safe.remapIn.isOpen)
            {
                safe.remapIn.makeOpen(nil);
            }
        }
        
    }
;

/*   
 *   READABLE 
 *
 *   Finally, we implement the letter the PC has come to retrieve. In a real 
 *   game we'd doubtless want to put other things in the safe as well, but 
 *   since this is a demo the letter alone will do.
 */

++ letter: Thing 'letter; love incriminating; love-letter'
    "One glance suffices to tell you that this is the letter you came to
    recover: a youthful indiscretion, written to an inappropriate lover. You
    have no desire to read it through; merely remembering it is quite
    embarrassing enough. Once you're out of here you'll destroy it. "
    subLocation = &remapIn
    
    readDesc = "You have no desire to read it right now. You know all too well
        what it says. "
;

//==============================================================================

modify finishOptionAmusing
    doOption()
    {
        if(!me.hasSeen(skeletonKey))
            "Try looking in the black case you're carrying.\b";
        
        if(!me.hasSeen(doorKey))
            "Try looking under the flowerpot.\b";
        
        if(torch.name == 'plastic tube')
            "Try calling the plastic tube by its proper name next time. ";
        
        if(torch.name == torch.britishName)
            "Next time, see what happens if you call the torch a flashlight.\b";
        
        if(torch.name == torch.americanName)
            "Next time, see what happens if you call the flashlight a torch.\b";
        
        if(!me.hasSeen(silverKey))
            "Try taking a closer look at the hat-stand in the hall and see if
            there's anything you can pull on it.\b";
        
        if(!me.hasSeen(drawerKey))
            "Take a closer look at the box on the desk and see if you can get
            it to OPEN.\b";
        
        "Try turning the dial on the TV to see what's on the various
        channels.\b";
        
        
        /* 
         *   We need to return true to tell the caller that we've done with 
         *   this option and we want to display the list of options again.
         */
        return true;
    }
;
    



