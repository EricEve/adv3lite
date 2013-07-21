#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*  
 *   EXERCISE 22 - ATTACHMENT
 *
 *   A demonstration of adv3Lite Attachable classes.
 *
 *   Handling Attachables is not always straightforward, to say the least, so
 *   this is the most complex of the demo games. If you have not already done
 *   so, you may want to become familiar with the other demo games first.
 *
 *   Attachables are complicated because there is so many different ways in
 *   which they could behave that the library classes can only provide a general
 *   framework which the game author must customize to suit each particular
 *   case. For example, if I attach a rope to a heavy box lying on the floor and
 *   then try to walk out of the room still holding the rope, a number of
 *   different things might happen, including:
 *
 *   (1)    I walk into the next room, still holding the rope, dragging the box
 *   along behind me.
 *
 *   (2)    I walk into the next room, still holding the rope, but it becomes
 *   detached from the box.
 *
 *   (3)    I walk into the next room, still holding the rope, which is so long
 *   that it has not yet become taut.
 *
 *   (4)    I am jerked to a halt by the rope, which has become taut, and cannot
 *   leave the room while I am holding the rope.
 *
 *   (5)    I walk into the room, but am forced to let go of the rope in the
 *   process.
 *
 *   And those are just the possibilitis involving a rope attached to a box;
 *   many other kind of attachment relationships are possible.
 *
 *   Given the vast number of possibilities, this demonstration game cannot hope
 *   to cover them all, and will only attempt a small range by way of
 *   illustration.
 *
 *   Also, because this game is already quite complex enough, and is intended
 *   primarily to illustrate the use of Attachables, this comments in the source
 *   code will be largely restricted to those parts of the code relating to the
 *   implementation of Attachable objects.
 *
 *   Finally, in adv3Lite the Attachable classes all descend from
 *   SimpleAttachable which implements simpler cases of attachment.
 */

versionInfo: GameID
    IFID = '7aa136e2-0442-4c01-9d0b-2cf9ad94a903'
    name = 'Exercise 22 - Attachment'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A demonstration of adv3Lite Attachable classes.'
    htmlDesc = 'A demonstration of adv3Lite Attachable classes.'
    
    showAbout()
    {
        "This is primarily a demonstration of adv3Lite Attachables. The game can
        be played through to a winning conclusion (or a losing one!), but it has
        been designed with demonstrating Attachables in mind rather than
        creating something that is a particularly great game.\b
        If you do want to play through the game and find you get stuck, remember
        that this is demonstration of attachable objects. Most of the things you
        need to do in this game will involve attaching (or detaching) objects to
        one another.<.p>";
    }
;

gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    showIntro()
    {
        "You weren't keen on being the one ordered outside to go and fix the
        transmission aerial, but that space-walk probably saved your life.\b
        The Federation warship (at least, you assume it was a Federation
        warship) appeared as if from nowhere and struck without warning, holing
        the tiny spy-ship with a single blast of its laser canon, and throwing
        you from your precarious perch. You very much doubt anyone inside the
        ship could have survived -- no one else was suited up and the
        decompression would have killed them almost instantly.\b
        Fortunately the hostile warship vanished as suddenly as it appeared,
        assuming its work was done and not even bothering to check for
        survivors. There very nearly weren't any; it took you over an hour to
        work your way back to the ship and in through the airlock, by which
        time the oxygen in your tank was all but exhausted. Removing your
        helmet you gasped gratefully at the air in the airlock, remembering to
        switch off your helmet lamp as it, too, was starting to dim.\b
        But it seems your troubles are far from over yet.\b";
    }
;


/*  
 *   The game takes place entirely aboard a spaceship, so compass directions
 *   will have no meaning. We therefore override Room to disallow movement in
 *   compass directions, and provide players with an explanation of the
 *   directions that can be used for moving around the ship.
 */

modify Room
    /* 
     *   Compass directions are not allowed (because they have no meaning)
     *   aboard the ship.
     */
    allowCompassDirections = nil
    
    /* On the other hand we want to allow shipboard directions everywhere */
    allowShipboardDirections = true
    
    /* 
     *   A custom property representing the air pressure in the room (in 
     *   bar). In this game this will be either 0 or 1.
     */
    pressure = 0
    
    /* At the start of the game the power is off and all rooms are dark. */
    isLit = (powerSwitch.isOn)
;

modify Floor
    vocab = 'deck;;floor ground'
;

CustomMessages
    messages = [
        Msg(no compass directions, 'That direction has no meaning here; aboard
            ship you can go port (P), starboard (SB), fore (F) or aft (A). ')
    ]
;


/* Define a message that'll be shown just before the first command prompt. */

InitObject
    execute()
    {
        new OneTimePromptDaemon(self, &introMessage);
    }
    
    introMessage = "The airlock light just went out, another casualty of the
        damage inflicted by the Federation warship. The artificial gravity still
        seems to be working, though, so some backup batteries must still have
        some charge left in them. In the meantime, you instinctively finger
        your helmet lamp. "
;

/*  
 *   A Custom class for Doors that are opened and closed by an external 
 *   mechanism, not by using OPEN and CLOSE commands.
 */

class IndirectDoor: Door
//    dobjFor(Open) { verify { illogical (cannotOpenMsg); } }
//    dobjFor(Close) { verify { illogical(cannotCloseMsg); } }
//    dobjFor(Lock) { verify { illogical(cannotLockMsg); } }
//    dobjFor(LockWith) { verify { illogical(cannotLockMsg); } }
//    dobjFor(Unlock) { verify { illogical(cannotUnlockMsg); } }
//    dobjFor(UnlockWith) { verify { illogical(cannotUnlockMsg); } }
    
    isOpenable = nil
    lockability = notLockable
    
    cannotOpenMsg = '{The subj dobj} {is} operated with a lever. '
    cannotCloseMsg = (cannotOpenMsg)
    cannotLockMsg = '{The subj dobj} {has} no lock. '
    cannotUnlockMsg = (cannotLockMsg)
    
;

/*  
 *   DoorLever is custom class we use for the code common to the two levers 
 *   that control the doors in the airlock.
 */
class DoorLever: Lever, Fixture
    
    /* A custom property - the other lever (used for various purposes). */
    otherLever = nil
    
    /* The door controlled by this lever. */
    myDoor = nil
    
    dobjFor(Pull)
    {
        verify()
        {
            
            inherited;
            /* 
             *   This lever can't be pulled when the other one is, since we 
             *   shouldn't have both airlock doors open at once.
             */
            local other = otherLever;
            gMessageParams(other);
            if(otherLever.isPulled)
                illogicalNow('{The subj dobj} {is} temporarily locked in place
                    while {the subj other} {is} pulled down, to prevent
                    both airlock doors being opened at once. ');
        }
        
        check()
        {
            inherited();
            /* 
             *   Don't let the player open a door if there's a vacuum on the 
             *   other side and the player is not wearing both suit and 
             *   helmet, since that would be fatal.
             */            
            if((helmet.wornBy != gActor || spaceSuit.wornBy != gActor)
               && myDoor.destination.pressure == 0)
                "Opening <<myDoor.theName>>  would be fatal to you
                    right now. ";
        }
    }
    
    /* Pulling the lever opens the corresponding door; pushing it closes it. */
    
    makePulled(stat)
    {
        inherited(stat);
        myDoor.makeOpen(stat);
        "\^<<myDoor.theName>> slides <<stat ? 'open' : 'closed'>>. ";
        if(stat && airlock.pressure != myDoor.destination.pressure)
        {   
            "There's a sudden rush of air. ";
            airlock.pressure = myDoor.destination.pressure;
        }
    }
    
    
    cannotTakeMsg = '{The subj dobj} is firmly fitted to the bulkhead. '
;
    

//------------------------------------------------------------------------------

/* The starting location. */

airlock: Room 'Main Airlock'
    "This small airlock, on the port side of the ship, is just about large
    enough for one man to stand in -- two would be uncomfortably cosy. A pair
    of levers control the airlock doors, and a trio of dials indicate the air
    pressure inside and outside the airlock. "
    starboard = innerDoor
    port = outerDoor
    pressure = 1
    out asExit(starboard)
    roomBeforeAction()
    {
        if(gActionIs(GoOut) && outerDoor.isOpen)
            goInstead(port);    
    }
;

+ redLever: DoorLever 'red lever'
    "It's marked <q>Outer Door</q>. "
    otherLever = greenLever
    myDoor = outerDoor
    collectiveGroups = [leverGroup]

;

+ greenLever: DoorLever 'green lever'
    "It's marked <q>Inner Door</q>. "
    otherLever = redLever
    myDoor = innerDoor
    
    dobjFor(Push)
    {
        verify()
        {
            if(hawser.isIn(airlock))
                illogicalNow('You can\'t close the inner door while the hawser
                    is running through it. ');
            inherited;
        }
    }
    collectiveGroups = [leverGroup]
;

+ leverGroup: CollectiveGroup, Fixture 'levers'
    "There's a red lever (controlling the outer door), and a green lever
    (controlling the inner door). "
;

+ portDial: Fixture 'port dial'
    "The port dial shows the air pressure beyond the port (outer) door;  i.e.
    outside the ship; it currently registers 0 bar"
    collectiveGroups = [dialGroup]
;

+ centreDial: Fixture 'central dial; center centre middle'     
    "The central dial shows the air pressure inside the airlock; it currently
    registers <<airlock.pressure>> bar. "
    collectiveGroups = [dialGroup]
;

+ starboardDial: Fixture 'starboard dial'
    "The starboard dial shows the air pressue beyond the starboard (inner)
    door, it currenly registers <<storageCompartment.pressure>> bar."
    collectiveGroups = [dialGroup]
;

+ dialGroup: CollectiveGroup, Fixture 'dials'
   "The port dial indicates that air pressure beyond the port (outer) door is
   currenly 0 bar. The central dial shows that the air pressure inside the
   airlock is currently <<airlock.pressure>> bar. The starboard dial shows that
   the air pressure beyond the starboard (inner) door, i.e. outside the ship is
   currently <<storageCompartment.pressure>> bar. "
;

+ innerDoor: IndirectDoor -> airlockDoor 'inner door' 
;

+ outerDoor: IndirectDoor 'outer door'    
    
    destination: Room { pressure = 0 }
    otherSide = self
    canTravelerPass(traveler) { return nil; }
    explainTravelBarrier(traveler)
    {
        "You don't want to go back out there again; you've had quite
        enough space-walking for now. ";
    }
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

/*  
 *   SIMPLE ATTACHABLE
 *
 *   SimpleAttachable is a custom class defined in the accompanying file. 
 *
 *   We make the spaceSuit a SimpleAttachable so that an OxygenTank can be 
 *   attached to it.
 *
 *   SimpleAttachable is designed to model an asymmetric attachment, where 
 *   one of the attached objects is the major attachment and all the others 
 *   are its minor attachments (we'd consider a limpet mine to be attached 
 *   to a battleship, not the other way round - the battleship would be the 
 *   major attachment and the mine the minor attachment). If the major 
 *   attachment is moved, its minor attachments move with it. If a minor 
 *   attachment is moved (e.g. by the player character taking it) it becomes 
 *   detached from the major attachment (think of a magnet attached to a 
 *   fridge). 
 *
 *   By default, a SimpleAttachment is designed to be used with other 
 *   SimpleAttachments: both the major attachment and its minor attachments 
 *   should be of class SimpleAttachable.
 */
++ spaceSuit: SimpleAttachable, Wearable 'spacesuit; dark blue (space); suit'     
    "It's dark blue, the colour of a naval uniform. "
    wornBy = me
    owner = me
     
    /* 
     *   The space suit is the major attachable here (any oxygen tank 
     *   attached to it will move round with it). We set it up as the major 
     *   attachments by listing the minor attachments that can be attached 
     *   to it.
     */
    allowableAttachments = [emptyTank, fullTank]    
    
    
    /* Prevent the player removing the space suit in a vacuum. */
    dobjFor(Doff)
    {
        check()
        {
            if(gActor.getOutermostRoom.pressure == 0)
                "That would be fatal; there\s no air in this place. ";
                    
        }
    }
;


/*       
 *   OxygenTank is a custom class defined below; it inherits from 
 *   SimpleAttachable. By locating emptyTank in spaceSuit we ensure that the 
 *   empty tank starts out attached to the space suit at the start of the 
 *   game.
 */

+++ emptyTank : OxygenTank 'empty +'    
    airLevel = 4
    
    attachedTo = spaceSuit
;


/*  
 *   The helmet is another SimpleAttachable so we can attach a lamp to it 
 *   (and detach the lamp from it.
 */

++ helmet: SimpleAttachable, Wearable 'helmet; standard (space)'
    "Its a standard issue space helmet. "
    
    /* The lamp is the only object that can be attached to the helmet. */
    allowableAttachments = [lamp]
    
    
    /* 
     *   While the player character is wearing the helmet, he's dependent on 
     *   the air it contains (or can get from the oxygen cylinder) to 
     *   breathe, so we need to model the breathing and air supply. We do 
     *   this with a DAEMON.
     */    
    breathingDaemonID = nil
    
    breathingDaemon()
    {
        /* Reduce the airLevel by one each turn the helmet is worn. */
        airLevel --;
        
        /* 
         *   If there's an oxygen tank attached to the space suit and the 
         *   tank contains enough air, refresh the air supply in the helmet.
         */
        if(myTank && myTank.airLevel > 0)
        {
            local newAir = min(myTank.airLevel, maxLevel - airLevel);
            if(newAir > 1)
                "There's a sudden rush of fresh oxygen into your helmet. ";
            airLevel += newAir;
            myTank.airLevel -= newAir;
        }
        
        /* 
         *   If the air in the helmet is running out, display a warning 
         *   message.
         */
        switch(airLevel)
        {
            case 4: "The air inside your helmet is starting to feel very stale.
                "; break;
            case 3: "The air in your helmet is scarcely breathable. "; break;
            case 2: "The air in your helmet is so stale you are beginning to
                faint. "; break;
            case 1: "You can scarcely breathe at all; you are about to pass out.
                "; break;
            
            /* 
             *   Once there's no air left, the player character dies of 
             *   asphyxiation.
             */
            case 0: "For want of breathable air, you lose consciousness. "; 
            finishGameMsg(ftDeath, [finishOptionUndo] );           
        }
        
    }
    
    /* 
     *   A custom property defining which oxygen tank the helmet is getting 
     *   its air supply from. This will be the tank attached to the suit. 
     */
    myTank = (spaceSuit.attachments.valWhich({x: x.ofKind(OxygenTank) }))
    
    /* The amount of air in the helmet (a custom property). */
    airLevel = 5
    
    /* The maximum amount of air the helment can hold. */
    maxLevel = 5
    
    dobjFor(Wear)
    {
        action()
        {            
            inherited;
            /* 
             *   When the helmet is put on, it starts full of air, but we 
             *   then need to start the breathing daemon.
             */
            airLevel = maxLevel;
            breathingDaemonID = new Daemon(self, &breathingDaemon, 1);
        }
        
    }
    
    dobjFor(Doff)
    {
        check()
        {
            /* 
             *   Don't allow the player character to remove the helmet in a 
             *   vacuum.
             */
            if(gActor.getOutermostRoom.pressure == 0)
                "That would be certain death; your location is unpressurised. ";
        }
        
        action()
        {
            inherited;
            
            /* When the helmet is removed, stop the breathing daemon. */
            if(breathingDaemonID)
            {
                breathingDaemonID.removeEvent();
                breathingDaemonID = nil;
            }
            
        }
    }
;


/*  
 *   PLUG ATTACHABLE
 *
 *   PlugAttachable is a mix-in class for use with other Attachable classes 
 *   to make PLUG INTO and UNPLUG FROM behave like ATTACH TO and DETACH FROM.
 *
 *   We make the lamp a PlugAttachable so it can be plugged into a charging 
 *   socket. 
 *
 *   It's also a SimpleAttachable. It can be attached either to the helmet 
 *   or to the charging socket, but that's defined on them.
 */

+++ lamp: PlugAttachable, SimpleAttachable, Flashlight 'lamp; (helmet)'
    "It's designed to be attached to the helmet, but can be detached for
    charging. It can also be turned on and off. "    
    
    /*  
     *   Make it visible in the dark when off so it's still in scope for the 
     *   player to turn it on.
     */
    visibleInDark = true
    
    /*  
     *   When the lamp is attached to the socket, it is charged up again. We 
     *   control this with a charging daemon, so that the longer it's plugged
     *   in, the more charge it receives.
     */
    chargeDaemonID = nil
    
    attachTo(other)
    {
        inherited(other);
        
        /* Start the charging daemon when we're plugged into the socket. */
        if(other == chargingSocket)
        {
            chargeDaemonID = new Daemon(self, &chargeDaemon, 1);
            if(fuelLevel < 10)
            {
                "The lamp starts to shine more brightly as soon as it's plugged
                in. ";
                fuelLevel = 10;
            }
        }
    }
    
    detachFrom(other)
    {
        inherited(other);
        
        /* Stop the charging daemon when we're removed from the socket. */
        if(other == chargingSocket)
        {
            chargeDaemonID.removeEvent();
            chargeDaemonID = nil;
        }            
    }
    
    chargeDaemon()
    {
        /* Increase the charge in the lamp each turn it's plugged in. */
        if(fuelLevel < maxCharge)
            fuelLevel += 20;
    }
    
    /* 
     *   fuelDaemon() is a custom method we use to track the amount of charge
     *   left in the lamp.
     */
    
    fuelDaemon()
    {           
        switch(fuelLevel--)
        {
            case 5: "The lamp is definitely dimmer. "; break;
            case 4: "The lamp starts to flicker. "; break;
            case 3: "The lamp seems very dim now. "; break;
            case 2: "The lamp is about to go out. "; break;
            case 1: "The lamp gives its final flicker. "; break;
        case 0:
            "The lamp goes out. ";
            makeOn(nil);
            fuelLevel = 0;
            if(!getOutermostRoom.isIlluminated)
                "You are plunged into darkness. ";
            break;
            
        }
        
    }
    
    fuelDaemonID = nil
    
    makeOn(stat)
    {
        inherited(stat);
        
        /* 
         *   In addition to the standard (inherited) handling for turning a
         *   Flashlight on or off we need to start or stop the Daemon that
         *   consumes the lamp's "fuel" (or charge) each turn it's on.
         */
        if(stat && fuelDaemonID == nil)
            fuelDaemonID = new SenseDaemon(self, &fuelDaemon, 1);
        if(!stat && fuelDaemonID != nil)
            fuelDaemonID.removeEvent();
        
    }
      
    dobjFor(SwitchOn)
    {
        check()
        {
            if(fuelLevel < 1)
                "The lamp is fully discharged; it won't light up. ";
        }
    }
    
    maxCharge = 100000
    
    fuelLevel = 15
    
    attachedTo = helmet
;


//==============================================================================
/*  
 *   Define the custom OxygenTank class. 
 *
 *   It's another SIMPLE ATTACHABLE, but it's made a bit more complicated by 
 *   the fact that only one OxygenTank can be attached to the space suit at 
 *   a time.
 */
class OxygenTank: SimpleAttachable 'oxygen tank; silver metal air; cylinder'
     
    /* 
     *   If there's another OxygenCylinder attached to the space suit when 
     *   the player tries to attach this one, insist that the other one is 
     *   detached first. 
     */    
    dobjFor(AttachTo)
    {
        check()
        {
            if(gIobj == spaceSuit && gIobj.attachments.indexWhich({x:
            x.ofKind(OxygenTank) && x != self }) != nil)
                "You'll have to remove the other tank first. ";
        }        
    }
;



//------------------------------------------------------------------------------

storageCompartment: Room 'Storage Compartment'
    "<<first time>>This area seems to have been largely undamaged by the blast
    from the enemy warship, although anything not nailed down was probably swept
    away by the explosive decompression elsewhere in the ship, since there was
    no time for the bulkheads to seal. <<only>>The equipment locker looks
    secure, as does the food freezer. The airlock door is to port, controlled by
    a red button, while the engine room lies aft and the living quarters are
    foreward. There's a charging socket on the bulkhead, and a winch off to one
    side (normally used to haul supplies aboard the ship). " 
    
    aft = engineRoom
    port = airlockDoor
    fore = livingQuarters    
;

+ airlockDoor: Door ->innerDoor 'airlock door'
    lockability = indirectLockable
;

+ Button 'red button' 
    dobjFor(Push)
    {
        
        action()
        {
            if(hawser.isIn(airlock) && airlockDoor.isOpen)
                "You can't close the airlock door while the cable is running
                through it. ";
            
            airlockDoor.makeOpen(!airlockDoor.isOpen);
            "The airlock door slides <<airlockDoor.isOpen ? 'open' : 'closed'>>.
              ";            
        }
    }
;

+ Container, Fixture 'rack' 
;

/* OxygenTank is a custom class defined below. */

++ fullTank: OxygenTank 'full +' 
    initSpecialDesc = "A single oxygen tank remains in the rack by the airlock;
        you hope it's still full. "
    airLevel = 5000
;

/* 
 *   PLUG ATTACHABLE, SIMPLE ATTACHABLE 
 *
 *   The charging socket is both a PlugAttachable (so we can plug things into
 *   it) and a SimpleAttachable (which means anything attached to it will 
 *   be moved into it, as we'll make it the major attachment).
 */

+ chargingSocket: PlugAttachable, SimpleAttachable, Fixture     
    'charging socket' 
    "<< powerSwitch.isOn ? 'With the power back on, there should be no
        difficulty getting a charge from the socket' : 'Although the main power
            is off, the charging socket has a backup battery which should
            hopefully have retained enough charge for your purposes' >>."
    
    /* The list of items that can be attached to the charging socket. */
    allowableAttachments = [lamp, blackCable]
;
    
+ equipmentLocker: LockableContainer, Fixture 'equipment locker' 
;

++ Decoration 'pieces of equipment;;;them'
   "<<notImportantMsg>>"
    notImportantMsg = (livingQuarters.seen ? 'There\'s nothing else you
        need here right now. ' : 'Once you\'ve assessed the damage you\'ll know
            what you need to repair it. ')
    isListed = true
    isListedInContents = true
    
    aName = ('various ' + name)
;

/*  
 *   CableConnector (NEARBY ATTACHABLE)
 *
 *   A CableConnector is another custom class (defined below). As can be seen
 *   below, CableConnector subclasses from NearbyAttachable. The purpose of 
 *   CableConnectors is to join two lengths of cable together.
 *
 */

++ redConnector: CableConnector 'red +' 
    isHidden = true
;

++ yellowConnector: CableConnector 'yellow +'     
    isHidden = true
;

/*  
 *   PLUG ATTACHABLE
 *
 *   The black cable is a PlugAttachable so it can be plugged into things. 
 *   It's also of class Cable, which is defined below. Cable derives from 
 *   NearbyAttachable, which creates a slight complication in that we also 
 *   want to be able to attach the black cable to the charging socket, which 
 *   is a SimpleAttachable. This is dealt with in the canAttachTo() method.
 */

++ blackCable: PlugAttachable, Attachable, Cable 'length of black cable[n]'
    "It's a standard electrical cable, about a couple of metres long. "
    isHidden = true
    
    
    /*  
     *   After every ATTACH TO action involving an ElectricalConnector (a custom
     *   class defined below), check to see whether the action has completed an
     *   electrical connection between the two sections of cable that need to be
     *   re-connected.
     */    
    afterAction()
    {
        if(gActionIs(AttachTo) && gDobj.ofKind(ElectricalConnector) &&
           aftCable.isElectricallyConnectedTo(foreCable))
            "You complete the connection between the fore and aft sections of
            the severed cable. ";
    }
;


++ roll: Thing 'roll of hull repair fabric; grey gray'
    "The fabric is grey with a faintly metallic appearance. It can be used to
    make temporary repairs to breaches in the hull. It won't protect against
    impact from large objects or weapons fire, but it's good enough to keep out
    light dust to shield against harmful cosmic radiation. It's also good
    enough to make an airtight seal so that the ship can be repressurized. "
    
    isHidden = true
    dobjFor(Take)
    {
        check()
        {
            if(fabric.moved)
                "You don\'t need any more of the fabric right now. ";
        }
        action()
        {
            fabric.actionMoveInto(gActor);
            "You unroll the fabric, cut of a square of the size you need,
            and return the roll to the locker. ";
        }
    }
;


+ freezer: LockableContainer, Fixture 'freezer; large'
    "It's a large freezer; it needs to be in order to supply provisions to the
    crew for several weeks. "
;

++ Decoration 'some food' 
    "There's plenty of food, at any rate; whatever else kills you, it won't be
    starvation. "
    isListedInContents = true
    isListed = true
    
    notImportantMsg = ( helmet.wornBy == me ? 'You can\'t eat while
        you\'re wearing your helmet, so you may as well leave the food alone for
        now. ' : 'You can worry about eating once you\'ve got the ship away from
            here. ')       
   
;

/*  
 *   PLUG ATTACHABLE     SIMPLE ATTACHABLE
 *
 *   We make the winch a PlugAttachable and the SimpleAttachable so the black
 *   cable can be plugged into it.
 */
+ winch: PlugAttachable, SimpleAttachable, Fixture 'winch;;casing'
    "The winch, fixed firmly to the floor, is used for moving heavy loads
    around the ship. It is controlled by the blue button on its casing. "
    allowableAttachments = [blackCable]
    
    socketCapacity = 2
;

++ Button, Component 'blue button'
     dobjFor(Push)
    {
        action()
        {
            /*  
             *   If power hasn't been restored, the only way to get the 
             *   winch to work is to connect it to the charging socket with 
             *   the black cable. For this connection to be made the black 
             *   cable must be attached both to the winch and to the socket.
             */            
            if(!powerSwitch.isOn && !(blackCable.isAttachedTo(winch) &&
                                      blackCable.isAttachedTo(chargingSocket)))
            {
                "Nothing happens, presumably because the winch has no power. ";
                return;
            }
            
            if(hawser.isIn(storageCompartment))
                "The winch emits a short whine and the hawser twitches a couple
                of times, but since the hawser is just about fully rewound, no
                more happens. ";
            else if(hawser.isAttachedTo(debris))
            {
                "The winch whines and the hawser goes taut. The pitch of the
                whine rises as the winch strains to move the hawser. For a
                moment or two nothing more happens, but then there's a loud
                scraping noise up forward, and the hawser slowly drags a mass of
                debris back into the storage chamber. ";
                debris.actionMoveInto(storageCompartment);
            }
            else
            {
                "The winch springs into life, rewinding the hawser all the way
                back into the storage compartment. ";
                hawser.moveInto(storageCompartment);
            }
        }
    }
;


/*  
 *   SIMPLE ATTACHABLE 
 *
 *   We make the hawser a SimpleAttachable so that (a) we can attach it to 
 *   things (in this game, only the debris) and (b) so it moves with whatever
 *   its attached to).
 */
+ hawser: SimpleAttachable 
    'hawser; winch loose free of[prep]; length cable end' 
    "<<specialDesc>>"
    
    /* Vary the description of the hawser depending on where it is. */
    specialDesc()
    {
        switch(getOutermostRoom)
        {
            case storageCompartment: "A short length of hawser dangles from the
                winch. "; break;
        case bridge:
            case livingQuarters: "The hawser runs aft. "; break;
            case engineRoom: "The hawser runs off for'ard. "; break;
        case airlock:
            case cabin: "The hawser runs out through the door to port. "; break;
        }
    }
    specialDescBeforeContents = nil
    specialDescListingOrder = 100
    getFacets = [proxyHawser1, proxyHawser2]
    aName = (theName)
;

/* 
 *   If the hawser object is not in the storage compartment, there must be a 
 *   length of hawser running from the the winch to wherever the other end 
 *   of the hawser is. In that case we need a proxy object to describe the 
 *   length of hawser that's visible inside the storage compartment.
 *   ProxyHawser is a custom class defined below.
 */
+ proxyHawser1: ProxyHawser 'hawser; winch of[prep];length cable'
    "The hawser from the winch runs <<cableDir()>>. "
    
    /* 
     *   We want this length of hawser to be visible only when the real 
     *   hawser object is elsewhere.
     */
    isHidden = (hawser.isIn(storageCompartment))
      
    /* 
     *   Describe which way the hawser runs depending on where the other end 
     *   of the hawser is.
     */
    cableDir()
    {
        switch(hawser.getOutermostRoom)
        {
            case engineRoom: "aft"; break;
            case airlock: "port, into the airlock"; break;
            default: "foreward"; break;
        }
    }
    
    /* 
     *   The other objects that can represents sections of the hawser are 
     *   facets of this object.
     */
    getFacets = [hawser, proxyHawser2]
    
;


//------------------------------------------------------------------------------
/*  
 *   Define our custom CABLE CONNECTOR class.
 *
 *   This descends from our custom ElecticalConnector class (defined below), 
 *   which in turn descends from NearbyAttachable.
 */
class CableConnector: ElectricalConnector 
    'cable connector; plastic; ring'    
    "In appearance, it lools like a plastic ring. Its function is to join one
    length of cable to another. "
    
    /* 
     *   The getNearbyAttachmentLocs() method is defined in the library for 
     *   NearbyAttachable. It controls where a NearbyAttachable ends up when 
     *   its attached to something. For a full description, see the comment 
     *   in blackCable above. 
     *
     *   In this case we need the two cable connectors to end up connected 
     *   to the two segments of cable in the conduit, so if what we're 
     *   connecting to is in the conduit, that's where we want everything to 
     *   end up. We define getNearbyAttachmentLocs accordingly. 
     */
    getNearbyAttachmentLocs(other)
    {
        if (other.isIn(conduit))
        {
            /* the other is where we want it, so use its location */
            return [other.location, other.location, 5];
        }
        else
        {
            /* 
             *   the other can be moved, so use our own location.
             */
            return [location, location, 0];
        }
    }    
    
    allowableAttachments = [blackCable]
;

/* 
 *   Definition of the custom CABLE class.
 *
 *   Cable derives from our custom ElectricalConnector class (defined 
 *   immediately below). The only customizetion required on this class is to 
 *   define what a Cable can connect to: Cables can connect to 
 *   CableConnectors.
 */
class Cable: ElectricalConnector
    allowAttach(obj)
    {
        return obj.ofKind(CableConnector);                        
    }   
;

/*   
 *   ELECTRICAL CONNECTOR     NEARBY ATTACHABLE
 *
 *   Our custom ElectricalConnector class derives from the library's 
 *   NearbyAttachable class. A NearbyAttachable is an Attachable that 
 *   enforces the condition that the attached objects must be in a 
 *   particular location. By default this is the location that one of the 
 *   objects is already in, but this can be customised by overriding 
 *   getNearbyAttachmentLocs(). 
 */
class ElectricalConnector: NearbyAttachable
    
    /* 
     *   isElectricallyConnectedTo() is a custom method to test whether an 
     *   electrical connection exists between two ElectricalConnectors. An 
     *   electrical connection exists if the two ElectricalConnectors are 
     *   directly or indirectly attached; they're indirectly attached if 
     *   there's a chain of attached objects between them.    
     */    
    isElectricallyConnectedTo(obj)
    {
        local vec = new Vector(10, [self]);
        local i = 0, cur;
               
        while(i < vec.length)           
        {
            cur = vec[++i];
            vec.appendUnique(cur.attachments);
            vec.appendUnique(cur.attachedToList);
            if(vec.indexOf(obj))
                return true;                       
        } 
        
        return nil;
    }
    
    /* 
     *   movedWhileAttached() is a library method defined on the Attachable 
     *   class. It's overridden on the NearbyAttachable class to detach 
     *   objects if one of them is moved while they're attached to each 
     *   other. This could be irritating in this game: if, for example the 
     *   player first attached the cable connectors to the black cable and 
     *   then tried to attach the cable connectors to the cable ends in the 
     *   counduit, the cable connectors would become detached from the black 
     *   cable. In this case we'd rather the cable connectors remained 
     *   attached to the black cable and the black cable moved into the 
     *   conduit along with the cable connectors, so we override 
     *   moveWhileAttached() accordingly. 
     */    
    moveWhileAttached(movedObj, newCont)
    {
        /* 
         *   If anything is being moved into the conduit, move its 
         *   attachments there as well, because that's where we want them 
         *   all to end up.
         */
        if(newCont == conduit)
        {
            if(movedObj != self)
                /* Don't trigger any more movement notifications! */
                moveInto(newCont);
        }
        else
            inherited(movedObj, newCont);
        
    }
    
    
;

//------------------------------------------------------------------------------
engineRoom: Room 'Engine Room'
    "The engine room also looks undamaged. So far as you can tell from a quick
    scan of the instruments, the main engine is undamaged. <<controls.desc>> "
    fore = storageCompartment
    out asExit(fore)
;

+ controls: Decoration 'instruments; of[prep]; mass controls; them' 
    "There's a mass of instruments and controls here, but
    \v<<controls.notImportantMsg>>"
    
    notImportantMsg = 'The only ones that concern you right now are the large
        red switch controlling the ship\'s power, the yellow lever
        controlling its air supply, and the pressure gauge showing the air
        pressure inside the ship.'
;

+ powerSwitch: Switch, Fixture 'large red switch' 
    "The switch is currently <<if isOn>> on<<else>> off<<end>>. "
    makeOn(stat)
    {
        if(stat)
        {
            if(!aftCable.isElectricallyConnectedTo(foreCable))
            {
                "'The switch snaps back into the off position; as a safety
                measure it won't stay on when there's a major fault somewhere in
                the system. ";
                exit;
            }
            "The lights come on all over the ship. "; 
        }
        else
            "The ship's lighting goes off again. ";
    
        inherited(stat);
    }
;

+ airLever: Lever, Fixture 'yellow lever'
    dobjFor(Pull)
    {
        check()
        {
            if(!lqWall.repaired)
                "If you turn on the air supply without first repairing
                    the damage to the hull, you'll simply waste all the air; 
                    it\'ll rush out though the breach in the hull as fast as it
                    tries to fill the ship. ";
        }
    }
    
    makePulled(stat)
    {
        inherited(stat);
        if(stat && location.pressure == 0)
        {
            "There's a hiss of air rushing from vents all over the ship, and
            the needle in the pressure gauge starts to rise. ";
            forEachInstance(Room, { loc: loc.pressure = 1 } );
        }
    }
;

+ Fixture 'pressure gauge;;needle'
    "The needle on the gauge indicates that the pressure inside the ship is
    currently <<location.pressure>> bar. "
;

//------------------------------------------------------------------------------
livingQuarters: Room 'Living Quarters'
    "It was obviously this area that took the brunt of the laser blast. If that
    wasn't immediately apparent from the gaping hole in the hull where the
    starboard cabins should be, it's apparent from the wreckage of what was once
    the crew lounge, although it looks as if one of the sleeping cabins to port
    might still be usable. The storage compartment lies aft, while the way
    foreward leads to the bridge. <<first time>>
    
    \bThere's no sign of any other members of the crew. They were almost
    certainly all sucked out through the hole in the hull by the rapid
    decompression. <<equipmentLocker.contents.forEach({o:
        o.discover})>><<only>>"
    
    aft = storageCompartment
    port = cabinDoor
    fore = bridge
 
;

/*  
 *   SIMPLE ATTACHABLE
 *
 *   SimpleAttachable is the base class for all the other Attachable classes we 
 *   have seen. 
 *
 *   Here we use it to define a wall to which something (namely, a piece of 
 *   fabric) can be attached.
 */ 
+ lqWall: SimpleAttachable, Fixture 'hull; starboard; wall'
    desc = "<<repaired ? 'The starboard hull now looks airtight' : 'There\'s a
        gaping hole in the hull'>>. "
    
    /* 
     *   The starboard hull is always 'the starboard hull', never 'a 
     *   starboard hull'
     */
    aName = (theName)
    

    allowableAttachments = [fabric]
    
    /*  
     *   repaired is a custom property to indicate when the wall has been 
     *   repaired by attaching the piece of fabric.
     */
    repaired = (isAttachedTo(fabric))
;

+ gapingHole: Component 'gaping hole' 
    "It's roughly circular, and about a metre in diameter. "
    
    /* 
     *   Make ATTACH FABRIC TO HOLE equivalent to ATTACH FABRIC TO STARBOARD 
     *   WALL.
     */
    iobjFor(AttachTo) { remap = lqWall }
    
    /* Once the hull is repaired, the hole is no longer visible. */
    isHidden = lqWall.repaired
;


/*  
 *   DOOR
 */

+ cabinDoor:  SimpleAttachable, Door ->cabinDoorInside 'cabin door; pale; patch' 
    "<<unless sign.isIn(self)>>A slightly paler patch on the door indicates
    where something may have dropped off.<<end>> "
    
    lockability = lockableWithoutKey
    
    /*  
     *   Normally making both sides of a Door a Lockable (as opposed to 
     *   LockableWithKey or IndirectLockable) doesn't achieve much, since 
     *   the door is simply unlocked with an implicit action when it's 
     *   opened. In this case, however, we can achieve a significant effect 
     *   by using a check condition to restrict unlocking the door - the 
     *   door won't unlock until the ship has been pressurized.
     */         
    dobjFor(Unlock)
    {
        check() 
        {
            if(location.pressure == 0)
            {
                "The cabin door won't unlock; it must be the only pressure seal
                that's holding, in which case you won't get the door open
                until you restore pressure to the ship. That may be just as
                well, of course; if there's someone still in the cabin that
                pressure seal may be the only thing keeping them alive. ";
            }
        }
    }
    
    
    /* The door can't be closed if there's a hawser running through it. */
    dobjFor(Close)
    {
        verify()
        {
            if(hawser.isIn(cabin))
                illogicalNow('You can\'t close the door while the cable\'s
                    running through it. ');
            inherited;
        }
    }    
    
    allowableAttachments = [sign]
;

/*  
 *   ATTACHABLE COMPONENT
 *
 *   An AttachableComponent is something that would normally be part of
 something else, but which may either start out detached from it or may later
 become detached (such as a handle that can be unscrewed, perhaps). For this
 example we use a sign that would normally be fixed to a door.  
 */
     


+ sign: AttachableComponent 'sign' 
    "The sign says <q>CAPTAIN</q>. "    
    
    initSpecialDesc = "A sign lies on the floor, seemingly dislodged from its
        normal place by the blast. "
    initiallyAttached = nil
;


+ conduit: Container, Fixture 'cable conduit' 
    
    isInInitState = (!aftCable.isElectricallyConnectedTo(foreCable))
    initSpecialDesc = "Amongst other things, the blast has exposed the main
        power conduit running along the floor, showing that part of the main
        power cable has been burned away completely. <<unless debris.moved>>
          Unfortunately, it looks as if the debris from the blast might make
          it difficult to get at the conduit. <<end>>"
    
    
    /*  
     *   Customise the way our contents are listed, so that when the cables 
     *   are all joined up our listing says so.
     */
    examineLister: descContentsLister 
    {
        showListSuffix(lst, pl, paraCnt)
        { lexicalParent.showListSuffix(); }              
    }

    showListSuffix()
    {
        "<< isInInitState ? '' : ', with all the cables now joined together in
            a continuous run'>>. ";
    }
    
    /* 
     *   The conduit starts off covered with debris that makes it difficult to
     *   get at, although we can see what's inside. To simulate that we use the
     *   checkReachIn method to display a message prohibiting access until the
     *   debris is moved.
     */    
    
    checkReachIn(actor, target?)  
    {
        if(!debris.moved)
            "The debris covering the conduit blocks your access to it. ";
            
    }
;


/* 
 *   FixedCable is a custom class defined below (inheriting from 
 *   NearbyAttachable). Since the fore and aft sections of the cable are 
 *   meant to be a couple of metres apart, the same CableConnector can't be 
 *   simultaneously attached to both the foreCable and the aftCable.
 */
++ aftCable: FixedCable 'aft +' 
    "It's a short length of cable running from the aft end of the conduit until
    it ends about two metres short of the fore end, the central part of the
    cable having been burned away. "

    initSpecialDesc = "At either end of the conduit you see the severed ends
        of the cable running fore and aft. <<exclude foreCable>>"
    isInInitState = (location.isInInitState)
    
    specialDescBeforeContents = true
;

++ foreCable: FixedCable 'fore +' 
    "It's a short length of cable running from the forward end of the conduit
    until it ends about two metres short of the aft end, the central part of
    the cable having been burned away. "

    
;

/*  
 *   SIMPLE ATTACHABLE 
 *
 *   The debris is a SimpleAttachable so we can attach the hawser to it to 
 *   drag it out of the way using the winch. We also make it of class Heavy 
 *   so we can't move it by hand.
 */

+ debris: SimpleAttachable, Heavy 'pile of debris; metal fused; mass wreckage'    
    "It's a mass of metal fused together by the laser blast that holed the ship;
    at a rough guess it's what's left of the wardroom table plus parts of the
    starboard side cabins. "
    
    /* Allow the hawser to be attached to the debris. */
    allowableAttachments = [hawser]
    
    specialDesc = "A mass of fused metal debris is strewn over the deck. "
;


/* 
 *   As with proxyHawser1 above, we need an object to represent the section 
 *   of hawser running through the living quarters if the end of the hawser 
 *   has been taken beyond the living quarters to either the bridge or the 
 *   cabin. ProxyHawser is a custom class defined below.
 */
+ proxyHawser2: ProxyHawser
    desc = "The hawser runs aft back to the storage compartment and
        <<cableDir()>>. "
    isHidden = !(hawser.isIn(bridge) || hawser.isIn(cabin))
    
    cableDir()
    {
        switch(hawser.getOutermostRoom)
        {
            case bridge: "foreward to the bridge"; break;
            case cabin: "port, into the cabin"; break;
            default: "foreward"; break;
        }
    }
    getFacets = [hawser, proxyHawser1]   
;


/*  
 *   Define the custom ProxyHawser class to represent lengths of hawser 
 *   passing through a location when the free end of the hawser is elsewhere.
 */
class ProxyHawser: Fixture 'hawser; winch of[prep]; length cable'
    specialDescBeforeContents = nil
    specialDesc = (desc)
    
    cannotTakeMsg = 'There\'s not much point picking up the middle of the
        hawser. '
    dobjFor(Pull)
    {
        verify() {}
        check()
        {
            if(hawser.isAttachedTo(debris))
               "You can't pull the hawser by hand; the load at its far end is
               too heavy. ";
        }
        
        action()
        {            
            hawser.moveInto(gActor.location);
            "You keep pulling the hawser until its loose end appears. ";           
        }
    }
;

/*  
 *   Define the custom FixedCable class, used to define the two ends of the 
 *   cable left in the conduit.
 */
class FixedCable: Cable, Fixture 'cable end; of[prep] severed; section'
   
    isListedInContents = true
    isListed = true
    aName = theName
;

//------------------------------------------------------------------------------

cabin: Room 'Sleeping Cabin'
    "This cabin seems to have escaped any serious damage, and there's a bunk
    you can sleep in if you ever get time for sleep, with a bedside cabinet
    placed conveniently next to it. "
    starboard = cabinDoorInside
    out asExit(starboard)
;

+ cabinDoorInside: Door -> cabinDoor 'cabin door'
    /* We can\'t close the door if the hawser is running through it. */
    dobjFor(Close)
    {
        verify()
        {
            if(hawser.isIn(cabin))
                illogicalNow('You can\'t close the door while the cable\'s
                    running through it. ');
            inherited;
        }
    }
;

+ Platform, Fixture 'bunk;;bed'
;

+ Fixture 'bedside cabinet; small metal'
    "It's a small metal cabinet with a door. "
    remapOn: SubComponent {}
    remapIn: SubComponent, LockableContainer 
    { 
        dobjFor(Open) { preCond = [touchObj, objUnlocked]}
    }
;

++ ContainerDoor 'cabinet door'
    
;

/* 
 *   SIMPLE ATTACHMENT
 *
 *   This one really is simple. 
 */

++ securityCard: SimpleAttachable, Thing    
    'security card; white purple; markings' 
    "It's a plain white card, about 8cm by 4cm, with purple markings. "
    subLocation = &remapIn
;


//------------------------------------------------------------------------------


bridge: Room 'Bridge'
    "<q>Bridge</q> is perhaps a grandiose title for this small control cabin,
    but it's functionally the bridge, since this is where the ship is flown
    from. A single chair, firmly attached to the floor, faces a bank of
    instruments; there used to be another chair for the person watching the spy
    scans, but it must have been sucked out by the decompression, since the way
    out aft lies open. "
    aft = livingQuarters
    out asExit(aft)
    
;

+ bridgeChair: Platform, Fixture 'pilot\'s chair; large' 
    "It's a large chair, arranged to face the bank of instruments used to fly
    the ship. "
    
   
    cannotTakeMsg = 'The chair is securely attached to the floor; that\'s
        why it\'s still there despite the decompression. '
    
    canLieOnMe = nil
       
;

+ Decoration 'bank of instruments; multicoloured; control dispays screens 
    buttons/switches knobs dials readouts panel; it them'
    
    "There are multicoloured displays, screens, buttons, switches, knobs, dials
    and readouts aplenty, none of them active. The whole lot can be turned on
    by pressing the green button right in the middle of the control
    panel<<conditions()>>."
    
    conditions()
    {
        local cardOK = (securityCard.isAttachedTo(cardReader));
        if(powerSwitch.isOn && cardOK)
            return;
        
        ", but nothing will happen until ";
        if(!powerSwitch.isOn)
            "the main power supply is switched on <<cardOK ? '' : 'and '>>";
        if(!cardOK)
            "a security card is attached to the card reader";         
        
    }
    
    notImportantMsg = 'At this point, only the green button and the card reader
        need concern you. '
    
;


+ greenButton: Button  'green button' 
    dobjFor(Push)
    {
        action()
        {
            if(!powerSwitch.isOn)
                "Nothing happens; there's no power. ";
            else if(!securityCard.isAttachedTo(cardReader))
                "Nothing happens; this model of ship won't respond to the
                controls unless a security card is attached to the card reader.
                ";
            else
            {
                "The instruments spring to life, indicating that the ship is
                ready to fly. It's unlikely that the Federation warship that
                attacked before will come back for a second look, but there's no
                point hanging around, so you set course for the nearest imperial
                world and head back for safety.\b";
                finishGameMsg(ftVictory, [finishOptionUndo]);
            }
        }
    }
;

/* 
 *   SIMPLE ATTACHMENT 
 *
 *   Another SimpleAttachment that's actuall simple. We just define the 
 *   minorAttachementItems property to contain the list of things that can be
 *   attached to it: in this case, just the securityCard.
 */
+ cardReader: SimpleAttachable, Fixture 'card reader' 
    "It's about 8cm by 4cm. "
    allowableAttachments = [securityCard]
;

//==============================================================================


/*  
 *   SIMPLE ATTACHABLE
 *
 *   The piece of fabric used to repair the ship's hull can be handled quite 
 *   simply with a SimpleAttachable.
 */
fabric: SimpleAttachable 'square of fabric; dull grey gray metallic; patch'     
    "It's just over a metre square, and of a dull metallic grey colour.
    <<isAttachedTo(lqWall) ? 'Now that' : 'When'>> it\'s attached to the
    starboard hull, covering the hole, it should provide an airtight seal. "
    
    
    
    /* 
     *   attachTo() is a standard library method of SimpleAttachable that
     *   handles the effects of attaching one object to another. Here we carry
     *   out the inherited handling and then explain what happened.
     */    
    attachTo(other)
    {
        inherited(other);
        if(other == lqWall)
        {            
            "You place the fabric over the hole, covering it completely. The
            outer edges of the fabric cling to the inner hull, making a seal
            that should be air-tight enough for you to repressurize the ship. ";
        }
    }
    
    /* 
     *   Once the patch has been fixed to the wall, we don't want it to be
     *   detached again.
     */
    isDetachable = nil
    
    /* Explain why we can't detach the fabric from the wall. */
    cannotDetachMsg = 'Now that you\'ve covered the hole you don\'t want to
        expose it again. '
    
;







