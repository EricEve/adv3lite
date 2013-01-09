#charset "us-ascii"

/*
 *   Copyright (c) 1999, 2002 by Michael J. Roberts.  Permission is
 *   granted to anyone to copy and use this file for any purpose.  
 *   
 *   This is a starter T3 source file.  This is designed for a project
 *   that doesn't require any of the standard TADS 3 adventure game
 *   libraries.
 *   
 *   To compile this game in TADS Workbench, open the "Build" menu and
 *   select "Compile for Debugging."  To run the game, after compiling it,
 *   open the "Debug" menu and select "Go."
 *   
 *   This starter file is intended for people who want to use T3 to create
 *   projects that don't fall into the usual TADS 3 adventure game
 *   patterns, so it doesn't include any of the standard libraries.  If
 *   you want to create a more typical Interactive Fiction project, you
 *   might want to create a new project, and select the "introductory" or
 *   "advanced" option when the New Project Wizard asks you what kind of
 *   starter game you'd like to create.  
 */

#include "advlite.h"

versionInfo: GameID
    IFID = '0D9D2F69-90D5-4BDA-A21F-5B64C878D0AB'
    name = 'Fire!'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">
                  Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A test game for the advlite library.'
    htmlDesc = ''
    
    showAbout()
    {
        "This is a demonstration/test game for the advlite library. It should
        be possible to reach a winning solution using a basic subset of common
        IF commands.<.p>";
    }
    
    showCredit()
    {
        "adv3lite libary by Eric Eve with substantial chunks borrowed from the
        Mercury and adv3 libraries by Mike Roberts. ";
    }
;


gameMain: GameMainDef
    initialPlayerChar = me
    
    showIntro()
    {       
        cls();
        new OneTimePromptDaemon(self, &daemon); 
        
        george.startFollowing;
        
        "<b><font color='red'>FIRE!</font></b>  You woke up just now, choking
            from the smoke that was already starting to fill your bedroom,
            threw something on and hurried downstairs -- narrowly missing
            tripping over the beach ball so thoughtgfully left on the landing
            by your <i>dear</i> nephew Jason -- you <i>knew</i> having him to
            stay yesterday would be trouble -- perhaps he's even responsible
            for the fire (not that he's around any more to blame -- that's one
            less thing to worry about anyway).\b
            So, here you are, in the hall, all ready to dash out of the house
            before it burns down around you. There's just one problem: in your
            hurry to get downstairs you left your front door key in your
            bedroom.<.p>";
    }
    
    daemon() 
    {
        "<.p>But then another thought occurs to you: there's always the back
        door...";
    }
        
    
//    storeObjectSymbolTable = true
;
//
//Doer 'examine me'
//    exec(curCmd)
//    {
//        "Don't be so narcissistic!<.p>";
//    }
//    
//    where = downstairs
//;
//
//Doer 'go north'
//    exec(curCmd)
//    {
//        "The blue ball doesn't like going north. ";
//    }
//
//    when = (blueBall.isIn(me))
//    during = kitchenVisit
//    direction = northDir
//;
//
//kitchenVisit: Scene
//    startsWhen = (me.isIn(kitchen))
//    
//    endsWhen = (me.isIn(study))
//    
//    whenStarting = "kitchenVisit starting"
//    whenEnding = "kitchenVisit ending"
//;
//    

InitObject
    execute()
    {
        new Daemon(saucepan, &temperatureDaemon, 1);
//        hall.setDestInfo(downDir, nil);
    }
;


downstairs: Region
    regions = indoors
;

upstairs: Region
    regions = indoors
;

indoors: Region
    /* The pc is presumably familiar with the layout of his own house */
    familiar = true
;

outdoors: Region
   
;

hall: Room, ShuffledEventList 'Hall' 'hall'   
    "<<one of>>At least the fire hasn't reached the ground floor yet. The hall
    is still blessedly clear of smoke, though you can see the smoke billowing
    around at the top of the stairs you've just come down. The front door
    leading out to the safety of the drive is just a few paces to the west -- if
    only you'd remembered that key! Otherwise all seems normal: \v<<or>>At a
    less troubled time you'd feel quite proud of this hall. A fine oak staircase
    sweeps up to the floor above, matching the solid front door that stands just
    to the west. <<stopping>>The pictures you bought last year look totally
    oblivious of the flames that might engulf them, and since so far the fire
    seems confined to the top floor there's nothing blocking your path north to
    the lounge, east to the kitchen, or south to the study.  "
    
    south = study
    north = lounge
    east = kitchen
    up = landing
    west = frontDoor
    out asExit(west)
    
//    down { "You lack burrowing equipment. "; }
    
    roomDaemon  { doScript; }
    
    eventList = 
    [
        'Wisps of smoke drift down the stairs. ',
        
        'You momentarily catch sight of the smoke billowing at the top of the
        staircase. ',
        
        'There\'s an ominous creak upstairs. ',
        
        'You fancy you feel a wave of hot air gush about your face. '
    ]
    
    regions = downstairs
    
    listenDesc = "There's a disturbing crackling of flames somewhere upstairs. "
;

+ me: Thing 'me ;; you yourself myself'   
    "You look as bedraggled as you feel. "
    isListed  = nil
    isFixed = true
    name = 'you'
    proper = true
    ownsContents = true
    person = 2
    isHim = true
    contType = Carrier
//    bulkCapacity = 10
    
;

++ blueBall: Thing 'blue ball; large beach; beachball'
    "It's a large blue beach ball. "  
    vocabPlural = 'balls'   
    bulk = 5
        
//    beforeAction()
//    {
//        if(gActionIs(Take) && gDobj == redBall)
//            "The blue ball really doesn't like that!<.p>";
//    }
;

+ redBall: Thing 'red ball; small cricket'
    "It's a small red cricket ball. "
    vocabPlural = 'balls'
    
    
    initSpecialDesc = "A small red ball lies abandoned on the ground; no doubt
        something else Jason forgot to take with him. "
    bulk = 2
    
    allowPushTravel = true
;

+ frontDoor: Door 'front door; solid oak' 
    "It's a solid oak front door, strong enough to resist a siege. "
    
    otherSide = frontDoorOutside
    lockability = lockableWithKey
    isLocked = true
    
;

+ Thing 'pictures;bland old;landscapes'
    "They're just some bland old landscapes you picked up in a charity shop. "
    
    isDecoration = true
    
    plural = true
    
    dobjFor(Examine)
    {
        action()
        {
            inherited;
            new SenseDaemon(self, &doFuse, 1); 
        }
    }
    
    
;

/* A do-it-yourself staircase */

+ Thing 'stairs; fine oak; flight staircase' 
    isFixed = true
    plural = true
   
    dobjFor(Climb)
    {
        verify() { }
        action()
        {
            "You climb the stairs up to the landing.<.p>";
            landing.travelVia(gActor);
        }
    }
    
    dobjFor(ClimbUp) asDobjFor(Climb)
    
;

drive: Room 'Front Drive' 'front drive'
    "The front drive sweeps round from the northwest and comes to an end just in
    front of the house, which stands directly to the east. A narrow path runs
    round the side of the house to the southeast. "
    
    east = frontDoorOutside
    southeast = sidePath
    
    northwest()
    {
        "You stride off down the drive to safety. ";
        finishGameMsg(ftVictory, [finishOptionUndo]);
    }
    
    regions = outdoors
;

+ frontDoorOutside: Door 'front door' 
    
    otherSide = frontDoor
    lockability = lockableWithKey
    isLocked = true
;

+ Fixture 'house'
    
    dobjFor(Enter)
    {
        remap = frontDoorOutside
    }
    
;

study: Room 'Study' 'study'   
    "This is your favourite room in the whole house, where you do your best
    work, think your best thoughts, and read your best books. The way out is to
    the north. "
    
    north = hall
    out asExit(north)
    
    west = "Unfortunately you can't get the window open. "
    
    regions = downstairs
;

+ desk: Thing 'desk; fine old'
    "It's a fine old desk. "
    
    specialDesc = "A fine old desk stands in the middle of the room. "
    
    isFixed = true
    cannotTakeMsg = 'The desk is too heavy for one person to move around. '
        
    
    
    contType = On
    
    remapIn = deskDrawer
    
    globalParamName = 'desk'
;

++ redBox: Thing 'red box; small'
    "It's a smallish box you keep odds and ends in. "
    
    isOpenable = true
    isOpen = nil
    isLocked = true
    lockability = lockableWithKey
    contType = In
    
    bulk = 3
    bulkCapacity = 3
    
    lockedMsg = '\^<<theNameIs>> locked; you keep it that way to stop thieving
        little hands pinching your odds and ends. '
    
   
;

+++ battery: Thing 'battery' 
    bulk = 1
    achievement: Achievement { +1 "finding the battery" }
    
    dobjFor(Take)
    {
        action()
        {
            inherited;
            achievement.awardPointsOnce();
        }
    }
;

++ deskDrawer: Thing 'drawer; desk' 
    
    
    contType = In
    isOpenable = true
    isOpen = nil
    isFixed = true
    
    bulkCapacity = 6
    maxSingleBulk = 3
;

+++ brownFile: Thing 'brown file; large brown; manuscript'
    "The file contains the manuscript of an exceedingly boring book a colleague
    sent you to read so you can offer your comments on it. Frankly if it
    perished in the flames that threaten to engulf your house you wouldn't
    regard it as much of a loss. "
    
    hiddenUnder = [silverKey]
    
    dobjFor(Open) asDobjFor(Read)
    
    readDesc = "Flicking through the file for ten seconds is enough to remind
        you why this rubbish would be best consigned to the flames. "
    
    isListed = true
      
;

+ Window
;

silverKey: Key 'silver key; small'
    "It's very small. "
    actualLockList = [redBox]
    plausibleLockList = [redBox]
    bulk = 1    
    vocabPlural = 'keys'
;


kitchen: Room 'Kitchen' 'kitchen'
    "This kitchen is equipped much as you'd expect, with, for example, a sink
    over by the window, a large table in the middle of the room, and an oven
    over by the back door to the east, not far from the fridge. The other exits
    are west to the hall, north to the dining-room and down to the cellar. "
    
    north = diningRoom
    west = hall
    down = cellar
    east = backDoor
    
    regions = downstairs
;

+ backDoor: Door 'back door' 
    "It's a solid door -- all the outside doors in this house are solid, you
    made sure of that to make the place burglar-proof. <<unless
      backDoorKey.isIn(hook)>> Normally the back door key should be hanging on
    the hook right next to it, but it's not there now<<first time>>, maybe
    that's something else Jason moved<<only>>.<<end>>"
    otherSide = backDoorOutside
    
    lockability = lockableWithKey
    isLocked = true
    
;

+ hook: Thing 'hook' 
    isFixed = true
    objInPrep = 'on'
    contType = On
    bulkCapacity = 1
;


+ kitchenTable: Thing 'table; battered old kitchen'
    "The table is a battered old thing with a single drawer. "
    isFixed = true
    isListed = nil
    isEnterable = true
    contType = On
    remapIn = kitchenDrawer
;

++ kitchenDrawer: Thing 'drawer' 
    
    contType = In
    objInPrep = 'in'
    isFixed = true
    isListed = nil
    isOpenable = true
;

+ kitchenSink: Thing 'sink; kitchen large stainless steel' 
    "It's a large stainless steel sink with a single tap. "
    
    contType = In
    objInPrep = gInPrep
    isFixed = true
    isOpen = true
    bulkCapacity = 30
    
    iobjFor(PutIn)
    {
        check()
        {
            inherited();
            if(kitchenTap.isOn && gDobj is in (battery, torch, brownFile))
            {
                "Putting {the dobj/him} in the sink while the tap is running
                might not do it much good. ";
            }
                
        }
        
    }
    
    notifyInsert(obj)
    {
        if(obj == blanket && kitchenTap.isOn)
        {
            blanket.makeWet(true);
            reportAfter('The running water at once soaks the blanket. ');
        }
    }
;
    
+ kitchenTap: Thing 'tap;silver;faucet'
    "It's a silver coloured tap of the kind you can turn on and off. "
    iobjFor(PutUnder) remapTo(PutIn, DirectObject, kitchenSink)
    isFixed = true
    isSwitchable = true
    
    stateDesc = (isOn ? 'A steady stream of water flows from the tap. ' : 'The
        tap is currently turned off. ')
    
    makeOn(stat)
    {
        local rep;
        inherited(stat);
        if(stat)
        {
            water.moveInto(kitchen);
            rep = 'Water starts gushing from the tap';
            if(blanket.isIn(kitchenSink))
            {    
                rep += ', soaking the blanket in the process';
                blanket.makeWet(true);              
            }            
            rep += '. ';
            if(bucket.isIn(kitchenSink))
            {
                if(blanket.isIn(bucket))
                    rep += 'The blanket stems the flow of water from the bucket
                        only for an few seconds before the water leaks out of
                        the hole in the bottom of the bucket. ';
                else
                    rep += 'The water runs into the bucket only to run straight
                        out of the hole in its bottom. ';             
            }
            reportAfter(rep);
        }
        else
        {
            reportAfter('The water stops flowing from the tap and rapidly drains
                away from the sink. ');
            water.moveInto(nil);
        }
        
        
    }
    
    dobjFor(SwitchOn)
    {
        check()
        {
            local lst = [];
            foreach (local cur in kitchenSink.contents)
            {
                if(cur is in (torch, battery, brownFile))
                    lst += cur;
            }
            
            if(lst.length > 0)
                "Turning on the tap while <<makeListStr(lst, &theName)>> <<if
                  lst.length > 1>>are<<else>>is<<end>> in the sink might not do
                <<if lst.length > 1>>them<<else>>it<<end>> too much good. ";
        }
    }
    
    dobjFor(Turn)
    {
        remap()
        {
            if(isOn)
                return [SwitchOff, self];
            else
                return [SwitchOn, self];
        }
    }
    
    
;

    



+++ torch: Thing 'large black torch;;flashlight' 
    "It's a large black torch, which can be opened at one end to insert a
    battery. "
    
    isSwitchable = true
    isLightable = true
    isOn = nil
    isListed = true
    contType = In
    
    bulkCapacity = 1
    isOpenable = true
    
    
    makeOn(stat)
    {
        inherited(stat);
        isLit = stat;
        if(stat)
            achievement.awardPointsOnce();
    }
    
    dobjFor(SwitchOn)
    {
        check()
        {
            if(!battery.isIn(self))
                "Nothing happens; probably because the torch needs a battery. ";
            else if(isOpen)
                "You probably have to close the torch for the battery to make an
                electrical contact. ";
        }        
    }
    
    dobjFor(Open)
    {
        action()
        {
            inherited;
            if(isOn)
            {
                "\nThe torch goes out.<.p>";
                makeOn(nil);
            }
        }
    }
    
    dobjFor(Light) asDobjFor(SwitchOn)
    dobjFor(Extinguish) asDobjFor(SwitchOff)
    
    achievement: Achievement { +2 "getting the torch to work" }
;

+ cooker: Thing 'cooker;blackened;oven stove top'
    "Normally, you keep it in pretty good shape (or your cleaner does) but right
    now it's looking suspiciously blackened, especially round the top. "    
    
    isFixed = true
    isSwitchable = true
    isOn = true
    
    smellDesc = "There's a distinct smell of burning from the cooker. "
    
    remapIn: SubComponent
    {
        isOpenable = true
        bulkCapacity = 6
    }
    
    remapOn: SubComponent
    {
       
    }
;



++ saucepan: Thing 'saucepan;;pan'
    "It's absolutely blackened. It was obviously left on the stove too long --
    perhaps that's what started the fire. "
   
    subLocation = &remapOn
    contType = In
    
    temperature = 100
    
    temperatureDaemon()
    {
        if(location == cooker.remapOn && cooker.isOn && temperature < 100)
            temperature++;
        
        if((location != cooker.remapOn || !cooker.isOn) && temperature > 15)
            temperature--;
    }
    
    checkReach(obj)
    {
        if(temperature > 70)
        {
            "The saucepan is <<if temperature > 90>>far <<else if temperature
            < 80>> just<<end>> too hot to touch!<.p>";
            return nil;
        }
        return true;
    }
    
    cannotBurnMsg = 'The saucepan\'s quite burnt enough already! '
;




+ Odor 'smell of burning; acrid distinct'
    "It smells quite acrid. "   
;
    

+ Thing 'ceiling;scorched;mark'
    "There's a scorched mark, a <i>badly</i> scorched mark, just above the stove.
    "
    
    isDecoration = true
    notImportantMsg = 'The ceiling is out of reach. '
;

+ Window
;

+ fridge: SimpleAttachable 'fridge; large white; refrigerator door'
    "It's a large, white floor-standing refrigerator. "
    remapIn: SubComponent { isOpenable = true }
    allowableAttachments = [magnet]
    isFixed = true
    isListed = nil
;

++ magnet: SimpleAttachable 'small magnet; red maple; leaf'
    "It's red and shaped like a maple-leaf. You must have picked it up on your
    last trip to Canada. "
    attachedTo = fridge
;

++ cheese: Thing 'piece of cheese; strong; cheddar'
    
    isEdible = true
    tasteDesc = "It's a strong cheddar. "
    smellDesc = "The cheese smells quite strong. "
    subLocation = &remapIn
;

water: Thing 'water; flowing'
    "The water flows steadily from the tap. "
    article = 'some'
    isFixed = true
    cannotTakeMsg = 'The water simply runs through your fingers. '
    
    dobjFor(SwitchOff)
    {
        remap = kitchenTap
    }
    
    dobjFor(Drink)
    {
        verify() {}
        action()
        {
            "You catch some of the water in the palm of your cupped hand and
            scoop it into your mouth. ";
        }
    }
   
;

cellar: Room 'Cellar' 'cellar'
    "It's not a pleasant place at the best of times, dark, dank and smelly, with
    piles of old junk strewn all over the place waiting for you to find time to
    sort them out (which you probably never will). "
    
    isLit = nil
    darkName = 'Cellar (in the dark)'
    darkDesc = "It's too dark to see anything down here, but you could just
        about find your way back up to the kitchen. "
    up = kitchen
    
    regions = downstairs
;

+ blanket: Thing 'blanket; worn old grey '
    "The old blanket may have been blue once, but it's gone grey with age. "
    isListed = true
    isWet = nil
    isWearable = true
    initSpecialDesc = "An old blanket covers a further pile of junk over in the
        corner. "
    
    hiddenUnder = [bucket]
    
    stateDesc = (isWet ? ' The blanket is now quite wet. ' : '')

    makeWet(stat)
    {        
        if(stat && !isWet)
        {
            name = 'wet blanket';
//            vocabWords = 'soaking wet ' + vocabWords;
            vocab = 'wet ' + vocab;
            initVocab();
            isWet = true;
        }
    }
    
    dobjFor(PutIn)
    {
        
        report()
        {
            inherited;
            if(isWet)
                name = 'wet blanket';
        }
    }
;

+ junk: Thing 'junk; old; pile detritus piles'
    "The half-forgotten detritus of years, piled up waiting the time that will
    never come when you feel like sorting it all out. "
    isDecoration = true
    isPlural = true
    notImportantMsg = 'You really don\'t have time to mess around with that old
        junk right now. '
    
    decorationActions = [Examine, LookIn]
;


/* 
 *   This should now  be set up to match GO THROUGH JUNK but not WALK THROUGH
 *   JUNK
 */

Doer 'go through junk'
    
    strict = true
    
    exec(curCmd)
    {
        redirect(curCmd, LookIn);
    }
;

bucket: Thing 'rusty bucket; old; hole bottom'
    "It's a rusty old bucket which, on closer inspection, turns out to have a
    hole in the bottom. "
    
    objInPrep = 'in'
    contType = In
;    

lounge: Room 'Lounge' 'lounge'
    south = hall
    east = diningRoom
    regions = downstairs
;


+ Window
;


diningRoom: Room 'Dining Room' 'dining room'
    "It's a decent-sized room, large enough to entertain a dozen people at the
    table without feeling at all crowded. The kitchen lies conveniently to the
    south and the lounge just as conveniently to the west. "
    
    south = kitchen
    west = lounge
    regions = downstairs
;

+ diningCabinet: Thing 'glass-fronted cabinet;large glass fronted'

    isFixed = true
    isOpenable = true
    contType = In
    transparent = true
    
    specialDesc = "A large glass-fronted cabinet stands against the wall. "
    
    hiddenBehind = [napkin, biro]
;
    
++ silverDish: Thing 'silver dish'
    
    contType = On
    bulk = 4
    bulkCapacity = 4
;

+ Window
;

napkin: Thing 'red paper napkin'
;

biro: Thing 'broken biro'
;
   
landing: Room 'Landing' 'landing'
    "The smoke is already becoming so thick here that it's hard to see much.
    Your bedroom lies to the north -- if you can make your way through the
    smoke. Most of the other upstairs rooms are down the passage the other way,
    to the south, but the worst of the smoke seems to be coming from there. "
    
    down = landingStairs
    
    north: TravelConnector
    {
        destination = bedroom
        
        travelDesc = "You manage to force your way through the smoke, coughing
            and choking as you go. ";
        
        canTravelerPass(actor)
        {
            return blanket.wornBy == actor && blanket.isWet;
        }
        
        explainTravelBarrier(actor)
        {
            if(blanket.wornBy == actor)
                "You take a few steps down the corridor but the smoke forces you
                back as the blanket starts to get singed. ";
            else
                "The smoke is too thick; you find yourself coughing and choking
                after the first step and are forced to retreat. ";
        }
    }
    
    
    south  { "The smoke is too thick that way; you almost choke to death
        with the first step south you take. Well, it's not as if there's
        anything down there you really need all that much right now. "; }
    
    regions = upstairs
;

/* A pre-built staircase from extras.t */

+ landingStairs: StairwayDown 'stairs;fine oak;flight staircase'
    
    travelDesc = "You retreat back down to the hall. "
    destination = hall
;

bedroom: Room 'Bedroom' 'bedroom'
    "Your bedroom is fast filling up with smoke, but so far as you can see
    nothing's damaged yet. Your bed is just as you left it, as is your little
    bedside cabinet. The only way out is to the south. "
    
     south = landing
    
    regions = upstairs
//    vocabWords = 'bedroom'
;

+ bed: Thing 'bed' 
    "It looks rather messy as you had to get out of it in something of a hurry
    just now. "
    
    isFixed = true
    isEnterable = true
    
    objInPrep = 'on'
    contType = On
    
    cannotTakeMsg = 'The bed is far too heavy for you to start trying to move it
        around right now. '
;

+ bedsideCabinet: Thing  'cabinet; small square white bedside '
    "It's a small, square, white cabinet with a single drawer. "
    
    isFixed = true
    contType = On
    objInPrep = 'on'
    remapIn = bedsideDrawer           
    
;


++ bedsideDrawer: Thing 'drawer' 
    
    isFixed = true
    isOpenable = true
    objInPrep = 'in'
    contType = In
            
;

+++ brassKey: Key 'brass key' 
    
    vocabPlural = 'keys'
    
    plausibleLockList = [frontDoor, frontDoorOutside, backDoor, backDoorOutside]
    actualLockList = [frontDoor, frontDoorOutside]
;

backYard: Room 'Back Yard' 'back yard'
    "It's very dark out here. The back door stands <<if backDoorOutside.isOpen>>
    open <<else>> closed <<end>> just to the west, and you're aware that the
    bulk of your garden lies off to the east, though you can't see any of it. A
    narrow path snakes round the side of the house to the southwest. "
   
    darkDesc = "Despite the light seeping out through the back door just to the
        west, it is virtually pitch black out here. "
        
    darkName = 'Back Yard (in near total darkness)'
    west = backDoorOutside
    southwest = sidePath
    east { "Your garden lies that way, but it's so dark you'd rather not venture
        into it right now. "; }
    
    
    regions = outdoors
    isLit = nil
;

+ backDoorOutside: Door 'back door' 
     otherSide = backDoor
    isLocked = true
;


sidePath: Room 'Path Round Side of House' 'path'
    "This narrow path runs round the side of the house from the main drive to
    the northwest to the back yard to the northeast. "
    
    darkName = 'Narrow Path (in the dark)'
    darkDesc = "You can see little on this dark, narrow path apart from a faint
        glow from the northwest. "
    
    northwest = drive
    northeast = backYard
    
    isLit = nil
    
    regions = outdoors
;

backDoorKey: Key 'dull metal key' 
    
    vocabPlural = 'keys'
    plausibleLockList = [frontDoor, frontDoorOutside, backDoor, backDoorOutside]
    actualLockList = [backDoor, backDoorOutside]
    
;

moon: MultiLoc, Thing 'moon; bright full'
    "It's a bright full moon. "
    isDecoration = true
    notImportantMsg = 'The moon is far too far away'
    locationList = [outdoors]
    
    visibleInDark = true
;

/* Cheap room parts */

sky: MultiLoc, Distant 'sky; dark night; stars'
    "The dark night sky is full of stars. "
    locationList = [outdoors]
    
    visibleInDark = true
;

ground: MultiLoc, Decoration 'ground'
    
    locationList = [outdoors]
    
    visibleInDark = true
;


floor: MultiLoc, Decoration 'floor;;ground'
    
    locationList = [indoors]
;

MultiLoc, Decoration 'ceiling'
 
    locationList = [indoors]
    exceptions = [kitchen]
;

class Window: Thing 'window;toughened;glass'
    "The window is closed, and gazes out onto the blackness of the night. "
    isFixed = true
    isOpenable = true
    lockability = lockableWithKey
    isLocked = true
    
    lockedMsg = '{The subj dobj} {is} locked<<one of>>. All the windows in this
        house are kept for security purposes (your insurers insist on it),
        but<<or>> and <<stopping>> you can never remember where you keep those
        fiddly little keys. '
    
    shouldNotBreakMsg = 'It\'s made of toughened glass -- a precaution against
        burglary. So far it has proved very effective at keeping burglars out
        but it seems to be equally effective at keeping you in. '
    
    shouldNotAttackMsg = (shouldNotBreakMsg)
    
    nothingThroughMsg = 'All you can see through the window is the blackness of
        the night outside. '
    
    iobjFor(ThrowAt)
    {
        action()
        {
            gDobj.moveInto(getOutermostRoom);
            "{The subj dobj} {bounces} off the toughened glass and {lands} on
            the ground. ";
        }
    }
    
;

nowhere: Room 'Nowhere' 'nowhere'
;

blueBook: Consultable 'blue book;;dictionary' @desk
    "It's your trusty dictionary. "
    
    readDesc = "It's not the sort of book you'd want to read from cover to
        cover; it's more for looking things up in. "
;

+ ConsultTopic @tLemons    
    "Apparently they're yellow and sour. "
;

+ ConsultTopic 'oranges'
    "They're round and juicy. "
;

+ ConsultTopic @Door
    "Doors can be opened and closed, and when open you can go through them. "
;

+ DefaultConsultTopic
    topicResponse = "You thumb through the blue book in vain for any
        interesting information on that topic. "
;


tLemons: Topic 'lemons'
;

tHappened: Topic 'it happened;did happen'
;

george: Actor 'George; tall thin; man' @hall
    "He's a tall thin man. "
    isHim = true
    specialDesc = "George is standing just across 
        <<getOutermostRoom.theName>>. "
    
    actorBeforeTravel(traveler, connector)
    {
        if(traveler == gPlayerChar)
            "<.p>George starts after you.<.p>";
    }
;

/* 
 *   The <.agenda fireAgenda> tag adds fireAgenda to the agendaList of George
 *   and all his DefaultAgendaTopics
 */
+ HelloTopic
    "<q>Hello,</q> you say.\b
    <q>Hi there!</q> George replies. <.agenda fireAgenda> "
;

+ AskTopic @redBall
    "<q>What do you know about this red ball?</q> you ask.\b
    <q>It was left there by your nephew, I believe,</q> he tells you. "
    name = 'the red ball'
;

+ AskTopic @tLemons
    "<q>Do you like lemons?</q> you ask.\b
    <q>No, they're too sour for me,</q> he complains. "
    name = 'lemons'
;


/* 
 *   The <.state georgeSulking> tag switches George's ActorState to
 *   georgeSulking.
 */
+ AskTopic @tMistress
    "<q>Why don't you tell me about your mistress?</q> you ask.\b
    George pouts. <q>Shan't!</q> he cries. <.state georgeSulking> "
    
    name = 'his mistress'
;

/* 
 *   The <.activate> tag does not actually switch to a ConvNode, because there's
 *   no such thing in this library, but it produces a similar effect by
 *   activating all topics with a convKeys of 'age-node'.
 */
+ QueryTopic 'how' @tHowOld
    "<q>How old are you?</q> you ask.\b
    <q>None of your damned business,</q> he replies. <q>Would you like someone
    asking you about your age?</q><.convnode age-node> "
    
    /* 
     *   specifying the askMatchObj property allows George to respond to ASK
     *   GEORGE ABOUT HIS AGE in the same well as ASK GEORGE HOW OLD HE IS.
     */
    askMatchObj = tAge
    convKeys = ['george']
;

+ QueryTopic 'where' 'he was born; were you'
    "<q>Where were you born?</q> you ask.\b
    <q>London,</q> he replies flatly. "
    convKeys = ['george']
;

+ SayTopic 'he looks very tall; you look'
    "<q>You look very tall,</q> you remark.\b
    <q>I'm the height I am,</q> he replies with a little shrug. "
    tellMatchObj = tHeight
    convKeys = ['george']
;

+ TellTopic @frontDoor
    "<q>What I need to open that door is the brass key,</q> you say.
    <.inform brass-key><.known brassKey> "
    name = 'the front door'
;

+ YesTopic
    "<q>Yes, sure, I wouldn't mind,</q> you reply.\b
    <q>Well, I do,</q> he grunts. "
    convKeys = ['age-node']
    isActive = nodeActive
    timesToSuggest = nil
;

+ NoTopic
    "<q>No, I suppose not,</q> you concede.\b
    <q>Well, there you are then!</q> he declares triumphantly. "
    convKeys = ['age-node']
    isActive = nodeActive
    timeToSuggest = nil
;

+ NodeInitiateTopic
    "<q>I thought I asked you a question,</q> George reminds you. "
    convKeys = ['age-node']
;
    
+ YesTopic
    "<q>Yes!</q> you declare. "
    name = 'say yes'
;

+ AskTellTalkTopic @george
    
    keyTopics = ['george']
;

+ CommandTopic @Jump
    "<q>Jump!</q> you cry.\b
    <q>Very well then,</q> he agrees. "
    allowAction = true
;

+ CommandTopic @Take
    "<q>George, be a good fellow and pick up that red ball will you?</q> you
    request.\b
    <q>Very well,</q> he agrees.<.p>"
    
    allowAction = true
    matchDobj = redBall
    isActive = !redBall.isIn(george)
;

+ KissTopic
    "George shies away from you. "
;

+ HitTopic
    "<q>What did you do that for?</q> George cries. "
;

+ DefaultTellTopic
    "<q>How interesting,</q> he remarks dryly. "
;

+ DefaultGiveShowTopic
    topicResponse()
    {
        gAction.giveReport = 'George takes one look at {1} and shakes his
        head. ';
    }
;

+ DefaultCommandTopic
    "<q>George, would you <<actionPhrase>> please?</q> you ask.\b
    <q>No, I don't think I will,</q> he replies. "
;

+ DefaultAnyTopic    
    "<q>I am not programmed to respond in that area,</q> he confesses. "
;

+ DefaultTalkTopic
    "<q>I'd rather not talk about that,</q> he tells you. "
;

+ DefaultAgendaTopic
    "<q>Let's talk about something else,</q> he suggests. <.topics>"
;

+ fireAgenda: ConvAgendaItem
    invokeItem()
    {
        isDone = true;
        "<<if invokedByActor>><q>What I want to know,</q> says George, 
        <q><<else>><q>Never mind that,</q> George interrupts you, <q>what I want 
        to know<<end>> is what you're going to do about this fire.</q> ";
    }
;

+ ByeTopic
    "<q>Goodbye,</q> you say.\b
    <q>Cheerio,</q> he replies. <q>Not that either of us is going anywhere.</q> "
;


+ georgeSulking: ActorState
    specialDesc = "George is pointedly looking away from you. "
    activateState(actor, oldState)
    {
        "George goes into a big sulk. ";
        new Fuse(self, &endSulk, 5);
    }
    
    endSulk()
    {
        "George decides to stop sulking and turns back to you. ";
        getActor.setState(nil);
    }
;

++ DefaultAnyTopic
    "George refuses to take any notice of you. "
;

tMistress: Topic 'his mistress; love life'
;

tHowOld: Topic 'old he is; are you'
;

tAge: Topic 'his age'
;

tHeight: Topic 'his height'
;

tFire: Topic 'fire'
;

//CustomMessages
//    messages = [
//        Msg(cannot read, 'Don\'t be daft, there\'s obviously nothing to read
//            there. ')
//    ]
//    
//;
//    
   
myThoughts: ThoughtManager
;

+ Thought @george
    "To be honest, you're not really sure what he's doing here. "
;

+ Thought @tFire
    "It's a wretched nuiscance. Your nephew's probably to blame for it
    somehow, but the important thing right now is just to escape from it. "
;



 topHintMenu: TopHintMenu 'Hints';

+ Goal 'How do I get out of the house?'
    [
        'Well, that\'s the problem, isn\'t it? ',
        'There are two ways out -- you have to find the appropriate key. ',
        'You left the key to the front door in your bedroom. '
    ]
    openWhen = true
;
        
        