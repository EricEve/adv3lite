#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*
 *   EXERCISE 13 - CONTAINERS
 *
 *   A small 'game' implementing a kitchen as an illustration of adv3Lite
 *   containers.
 */

versionInfo: GameID
    IFID = '13cb0798-2be6-4082-87e1-aa077cb36bb7'
    name = 'Exercise 13'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A sample game to illustrate the use of Containers in adv3Lite and
        provide a possible solution to Exercises 12 and 13 in Learning TADS 3
        with AdvLite. '
    htmlDesc = 'A sample game to illustrate the use of Containers in adv3Lite
        and provide a possible solution to Exercises 12 and 13 in <i>Learning
        TADS 3 with AdvLite</i>. '
;

/*
 *   The "gameMain" object lets us set the initial player character and
 *   control the game's startup procedure.  Every game must define this
 *   object.  For convenience, we inherit from the library's GameMainDef
 *   class, which defines suitable defaults for most of this object's
 *   required methods and properties.  
 */
gameMain: GameMainDef
    /* the initial player character is 'me' */
    initialPlayerChar = me
    showIntro()
    {
        "Now your kitchen's been refurbished, you want to take a look
        around.<.p> ";
    }
;


/* 
 *   ROOM
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
kitchen: Room 'Kitchen'
    "Much of the space is taken up with a wooden table in the middle of the
    kitchen. There's a cabinet on one wall, a cooker next to another, with a
    peg placed conveniently by. A long work surface runs under the cabinet,
    with a kitchen roll mounted on the wall just above it. The opposite wall is
    adorned with a cheerful poster. The way out is to the north, but you're not
    interested in the rest of the house just now. "
    
    north() { "There's no need to go wandering round the rest of
        the house; it's the kitchen you want to investigate right now. "; }    
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
    
    /* 
     *   Give the player character a modest bulkCapacity so we can try out the
     *   BagOfHolding.
     */
    bulkCapacity = 20                                                           
;


//------------------------------------------------------------------------------

/*  
 *   DISTANT
 *
 *   We'll start with a simple Distant object. In practice the PC could 
 *   probably reach the light bulb by standing on the kitchen table, but 
 *   that's a complication beyond what we want to illustrate in this demo.
 */

+ bulb: Distant 'naked light bulb'
    "A naked light bulb hangs from the ceiling. "        
;

+ Distant 'ceiling'
    desc = bulb.desc
;

/*  
 *   DECORATION
 *
 *   By making this a RoomPartItem we ensure its specialDesc is only shown 
 *   if the east wall is examined.
 */

+ Decoration 'poster; large cheerful sunny landscape poster' 
    "You put it there because it's cheerful. It depicts a sunny landscape. "    
;

//------------------------------------------------------------------------------
/*
 *   A SIMPLE SURFACE
 *
 *
 *   About the simplest kind of container object is a simple surface. We'll 
 *   make this one a Fixture too, since it obviously can't be moved.
 */

+ workTop: Surface, Fixture 'work surface; long; top counter' 
    cannotTakeMsg = 'The builder seems to have done his job with the work
        surface, at any rate; it\'s so firmly fixed in place that you can\'t
        budge it by as a much as a nanometer. '
;

/*  
 *   RESTRICTED CONTAINER
 *
 *   We'll first define a Container - a pencil sharpener - into which only
 *   pencils can be put, and then only one at a time. We'll use its notifyInsert
 *   method to enforce these conditions.
 *
 *   This definition of the pencilSharpener is fairly minimal, but below we
 *   shall define a custom Pencil class which will make the sharpener work in a
 *   fairly basic fashion.
 */
 
++ pencilSharpener: Container 'small pencil sharpener; red plastic' 
    "Apart from the blade, it's made of red plastic. "
    
    notifyInsert(obj)
    {
        if(!obj.ofKind(Pencil))
        {
            "Only pencils can go in the sharpener. ";
            exit;
        }
        
        if(contents.length > 0)
        {
            "The sharpener can only hold one pencil at a time. ";
            exit;
        }
    }
        
    bulkCapacity = 1
    bulk = 2   
;

/*   
 *   HIDDEN UNDER
 *
 *   We can hide things under other things by listing the concealed items in the
 *   hiddenUnder property. example: a book under which a note has been
 *   concealed. Note that the note will stay behind when the book is taken.
 */

++ redBook: Thing 'big red book; cookery'
    "It's a cookery book. "
    readDesc = "You flick through some of the pages, but none of the recipes
        take your fancy right now. "    
    
    hiddenUnder = [note]
    
    bulk = 3
;

/*  
 *   RESTRICTED SURFACE
 *
 *   An example of a Surface we can only put one thing on; here a peg on which
 *   we can hang (here just PUT) an apron, but nothing else.
 */


+ peg: Surface, Fixture 'peg;; hook'
    notifyInsert(obj)
    {
        if(obj != apron)
        {
            "{I} {can\'t} hang {the dobj} on the peg. ";
            exit;
        }
    }
;

/*   WEARABLE */

++ apron: Wearable 'striped apron; blue (and) red striped'
    "It's striped blue and red. "
    bulk = 4
;

 /*  
 *   REAR CONTAINER
 *
 *   RearContainers are used less often. The point to remember is that when 
 *   they're moved their contents doesn't move with them, so the bag and the 
 *   sack will remain put.
 *
 *   Normally we'd be able to open a large brown box, but to keep this 
 *   RearContainer simple we'll just display a message showing why we don't 
 *   want to open it just yet.
 */


+ brownBox: Heavy, RearContainer 'large brown box; square'
    "It's about two foot square. "
    initSpecialDesc = "A large brown box sits in the corner. "
    cannotOpenMsg = 'It\'s full of your china and cutlery, but you don\'t want
        to start unpacking them yet. '
    lookInDesc = "<<cannotOpenMsg>>"
    
    cannotPutOnMsg = 'You don\'t want to put anything on the box in case you
        damage the china inside. '
    bulk = 8
    
    /* 
     *   This isn't really an openable container, but it looks like one so 
     *   the player might try to put something in it. To cater for this we 
     *   add stub iobjFor(PutIn) handling that makes it logical to put 
     *   something in the brown box, but will fail on the attempt to open 
     *   the brown box that will be triggered by the objOpen precondition.
     */
    iobjFor(PutIn)
    {
        preCond = [objOpen]
        verify() {}
    }
    
    /* 
     *   In practice it would probably be simpler to list the items hidden
     *   behind the box in its hiddenBehind property, but here we're
     *   illustrating the use of a RearContainer, so we need to manually make it
     *   discover anything hidden behind it when we look behind it.
     */
    dobjFor(LookBehind)
    {
        action()
        {
            foreach(local cur in contents)
                cur.discover();
            inherited;
        }
    }
;

/*  
 *   STRETCHY CONTAINER
 *
 *   We make the sack start out hidden by setting its isHidden property to true;
 *   calling discover() makes it unhidden. We make the bulk of the box depend on
 *   the bulk of the items it contains by defining its bulk to be a minimum
 *   value (3) - the bulk of the sack when empty - plus the total bulk of the
 *   items it contains.
 */


++ sack: Container 'old brown sack'
    bulk = (3 + getBulkWithin)
    isHidden = true    
;

/*   
 *   BAG OF HOLDING
 *
 *   To try out the BagOfHolding, take it early on, then take as many other
 *   objects as you can. BagOfHolding is a mix-in class so we need to list it
 *   before any Thing-derived classes in the bag's class list.
 */

++ bag: BagOfHolding, Container 'old beige bag' 
    
    /* 
     *   Making the bulk smaller than the bulk capacity may seem 
     *   unrealistically Tardis-like, but if we don't do that the 
     *   BagOfHolding can't do its job, since the whole purpose of it is to 
     *   carry more bulk than the PC can hold in his/her hands.
     */
    bulk = 4
    bulkCapacity = 100
    
    isHidden = true
;

/* 
 *   MULTIPLE-TYPE CONTAINER
 *
 *   A cooker is something you can typically put things on top of and 
 *   inside, so it's a good candidate for illustrating Multiple Containment. 
 *   While we're at it, we'll give it a rear as well with something 
 *   hidden behind.
 */


+ oven: Fixture 'cooker;;oven stove' 
    "It's not quite hard against the wall. "
    
    /* 
     *   The remapOn property defines the sub-object we actually put things on
     *   when we notionally put them on the oven.
     */
    remapOn: SubComponent {}    
    
    /* 
     *   The remapIn property defines the sub-object we actually put things in
     *   when we notionally put them in the oven.
     */
    remapIn: SubComponent { isOpenable = true bulkCapacity = 10}
    
    /* 
     *   The remapBehind property defines the sub-object we actually put things
     *   behind when we notionally put them behind the oven.
     */
    remapBehind: SubComponent { bulkCapacity = 1 }   
    
    /* 
     *   The leaflet will be moved to the remapBehind SubComponent when we look
     *   behind the oven.
     */
    hiddenBehind = [leaflet]
;

/*  
 *   CONTAINER DOOR
 *
 *   A ContainerDoor is normally only used on a Multiple Container, as here.
 */

++ ContainerDoor '(oven) door; (stove) (cooker)'
;

++ cake: Food 'chocolate cake; large round delicious brown' 
    "It's large, round and brown. "
    /* 
     *   Note the special syntax for locating something initially in a 
     *   remapIn object of a multiply-containing object. 
     */
    subLocation = &remapIn
    
    dobjFor(Eat)
    {
        action()
        {
            "You take one bite and it's delicious, so you take a whole slice;
            then another, and another and another and another until the whole
            cake is gone and your waistline threatens to bulge beyond acceptable
            limits. ";
            inherited;
        }
    }
    
    tasteDesc = "It tastes deliciously chocolately. "
    bulk = 3
;

++ saucepan: Container 'saucepan; stainless steel (sauce); pan' 
    "It's made of stainless steel. "
    
    subLocation = &remapOn
    bulkCapacity = 3
    bulk = 4
    allowPourIntoMe = true
;

/*  
 *   MULTIPLEX CONTAINER WITH LID
 *
 *   Rather more complicated than a simple saucepan is a pot which is open or
 *   closed by removing or replacing its lid. In order to allow the lid to 
 *   be put ON it while other things can be put IN it, we need to make it a 
 *   Mutliplex Container.
 */

++ pot: Thing 'large orange casserole pot; orange' 
    "It's a large orange pot with a black handle. "
    remapOn: SubComponent 
    {
        notifyInsert(obj)
        {
            if(obj != potLid)
            {
                "The only thing you can put on the pot is its lid. ";
                exit;
            }
        }
    }
    
    remapIn: SubComponent    
    {
        isOpenable = true
        isOpen = (!potLid.isIn(lexicalParent.remapOn))
        bulkCapacity = 5
        
        
        dobjFor(Open) 
        {
            verify()
            {
                if(isOpen)
                    illogicalNow('It\'s already open, ');
            }
            
            action()
            {                
                doInstead(Take, potLid);                
            }
        }
        
        dobjFor(LookIn) { preCond = [objOpen] }
    }
    
    bulk = 6     
    allowPourIntoMe = true
    subLocation = &remapOn
;


/* THE LID */

+++ potLid: Thing 'lid' 
    bulk = 3
    subLocation = &remapOn
    dobjFor(Take)
    {
        action()
        {
            if(isIn(pot.remapOn))
                "You take the lid off the pot. ";
            inherited;
        }
    }
;

/*  
 *   COMPONENT
 *
 *   Since the pot is already a ComplexContainer, its easy to add a Component
 *   like a handle. You couldn't do this directly on an OpenableContainer.
 */

+++ Component 'black handle' 
;


/*
 *   A MULTIPLEX CONTAINER YOU CAN STAND ON
 *
 *   A table could just be a straightforward Surface, but since it's 
 *   reasonable to put things under a table as well as on top of it, we can 
 *   also make it a Multiplex Container to allow this. A further complication 
 *   is that people might be able to sit, stand, or lie on a large kitchen 
 *   table: this example shows one way of allowing that
 *
 *   Note that we also make the table inherit from Heavy, since it's too 
 *   heavy to pick up or move around.
 */

+ table: Heavy 'table; wooden large'
    "It's a large wooden table. "
    remapOn: SubComponent, Platform { }
    remapUnder: SubComponent {}
;

/* 
 *   OPENABLE CONTAINER
 *
 *   The red box is a straightforward OpenableContainer 
 */

++ redBox: OpenableContainer 'big red box'
    subLocation = &remapUnder
    bulk = 10
    bulkCapacity = 10
;

/*  We'll see how this can opener is used below. */

+++ canOpener: Thing 'can opener; tin'
    iobjFor(OpenWith)
    {
        verify() {}
    }
;

/*  
 *   Some pencils for the sharpener; we'll define the Pencil class below.
 *
 *   Note that objects can inherit vocab from their superclass. The '+' in the
 *   vocab of these Pencils is a placeholder for the 'pencil' that they all
 *   inherit from the Pencil class.
 */

+++ Pencil 'red +';
+++ Pencil 'blue +';
+++ Pencil 'green +';
+++ Pencil 'black +';
+++ Pencil 'yellow +';



/* 
 *   LOCKABLE CONTAINER
 *
 *   The cabinet is also a straightforward LockableContainer, but it's also 
 *   fixed in place. Note that we don't need a key to unlock a 
 *   LockableContainer (which makes the class almost pointless in practice.
 */
 

+ cabinet: LockableContainer, Fixture 'cabinet;; cupboard'
    cannotTakeMsg = 'The cabinet is firmly fastened to the wall. '
    
    /* If we want a LockableContainer to start out locked, we have to say so. */
    isLocked = true
;

/*  TRANSPARENT OPENABLE CONTAINER */

++ glassJar: OpenableContainer 'glass jar' 
    /*  
     *   By declaring isTransparent = true, we make it possible to see what's
     *   inside even when it's closed.
     */

    isTransparent = true
    
    /* 
     *   The following property prevents our putting anything but fairly small 
     *   objects into the jar, even though it has quite a large bulkCapacity.
     */    
    maxSingleBulk = 3
    bulkCapacity = 10
    allowPourIntoMe = true
;

/*  
 *   CLASS DEFINITION
 *
 *   Note that since we can define the SugarCube class here without upsetting
 *   the object containment hierarchy. Since every sugar cube will have the same
 *   name, the sugar cubes will automatically be treated as equivalent.
 */

class SugarCube: Food 'sugar cube'    
    tasteDesc = "It tastes just as sweet as you'd expect. "
;

/*  
 *   These ten SugarCubes will be in the glassJar, not the SugarCube class! Note
 *   that when we first examine the glass jar the sugar cubes will be listed as
 *   'ten sugar cubes' not 'a sugar cube, a sugar cube, ... and a sugar cube'.
 *   Adv3Lite automatically groups items like this if their names are identical.
 */
 

+++ SugarCube;
+++ SugarCube;
+++ SugarCube;
+++ SugarCube;
+++ SugarCube;
+++ SugarCube;
+++ SugarCube;
+++ SugarCube;
+++ SugarCube;
+++ SugarCube;

/*  
 *   A CUSTOMISED CONTAINER
 *
 *   The soup can is a more complicated example of a container; it starts off
 *   closed and can only be opened in a special way, using the can opener. 
 *   This requires some custom coding.
 */

++ soupCan: Container 'can of soup;;tin'
    isOpen = nil    
    
    dobjFor(OpenWith)
    {
        preCond = [objHeld]
        verify() 
        {
            if(isOpen)
                illogicalNow('The can is already open. ');
        }
        check()
        {
            if(gIobj != canOpener)
                "{I} {can\'t} open the can with {the iobj}. ";
        }
        action()
        {            
            makeOpen(true);
            "{I} open{s/ed} the can with {the iobj}. ";
            
            /* 
             *   If opening us is not being performed as an implicit action,
             *   list the contents that are revealed as a result of our being
             *   opened.
             */
            if(!gAction.isImplicit)
            {              
                unmention(contents);
                listSubcontentsOf(self, openingContentsLister);
            }  
                       
        }
    }
    cannotOpenMsg = 'You\'ll need something to open it with. '
    bulk = 3
    bulkCapacity = 2
    allowPourIntoMe = true
;

/*  
 *   A SIMPLE LIQUID
 *
 *   The soup in the can is also an odd kind of object, since it can't 
 *   simply be picked up, although it should be possible to transfer it from 
 *   one container to another. 
 */


+++ soup: Food 'some tomato soup; red orange thick'
    "It looks quite thick, and its colour is somewhere between red and orange. "
   
    dobjFor(Take)
    {
        verify() { illogical('It\'s liquid; you can\'t pick it up. '); }
    }
    
    dobjFor(PutIn)
    {
        preCond = [touchObj]
        check()
        {
            /* 
             *   allowPourIntoMe is a library property we define as true on
             *   those few containers above we're prepared to allow the soup to
             *   be poured into.
             */
            if(!gIobj.allowPourIntoMe)
                "It would make too much of a mess to pour the soup in there. ";
        }
    }
        
    dobjFor(PutOn)
    {
        preCond = [touchObj]
        check()
        {
            "You don\'t want to make a mess. ";
        }
    }
    dobjFor(PutUnder) asDobjFor(PutOn)
    dobjFor(PutBehind) asDobjFor(PutOn)
    dobjFor(PourOnto) asDobjFor(PutOn)
    
    isPourable = true
    
    dobjFor(PourInto) 
    {
        action() { doInstead(PutIn, self, gIobj); }
    }    
    
    bulk = 2
    dobjFor(Drink) asDobjFor(Eat)
    dobjFor(Eat)
    {
        preCond = [touchObj]
        action()
        {
            "It tastes okay, but it would have been better hot. ";
            inherited;
        }
    }
    tasteDesc = "It tastes of tomato. "
;


/*   
 *   DISPENSER AND DISPENSABLES
 *
 *   A Dispenser is a container for a special type of item. By default its
 *   contents can be taken but not returned. A roll of kitchen towels provides a
 *   good example of this; you can take a towel from the roll, but you can't but
 *   it back.
 *
 *   The adv3Lite library doesn't define Dispenser and Dispensable classes; here
 *   we instead implement the equivalent by making the roll a Container you
 *   can't put things in and which doesn't list its contents.
 *
 *
 *   We'll make the roll an Immovable; it's not obvious that you couldn't tale
 *   the whole roll, but in this case we won't allow it.
 */
 

+ roll: Immovable, Container 'kitchen roll; (towel); holder'
    "It's a<<contents.length == 0 ? 'n empty roll' : ' roll of paper towels'>>,
    mounted on the wall. "
    
    cannotTakeMsg = 'You can\'t detach the roll from its holder; the builder
        must have fitted it wrong. '
    
    canPutInMe = nil
    
    contentsListed = nil
;

  /* 
   *   Once again we can define the class between the container and its 
   *   contents -- we don't have to define it here, but doing so does no harm.
   */

class PaperTowel: Thing 'paper towel; plain paper white square (kitchen)'     
    "It's a plain, white, square paper towel. "    
    bulk = 1
;

++ PaperTowel;
++ PaperTowel;
++ PaperTowel;
++ PaperTowel;
++ PaperTowel;
++ PaperTowel;
++ PaperTowel;
++ PaperTowel;
++ PaperTowel;
++ PaperTowel;


/* 
 *   A Fixture to represent the wall the clock starts out hanging on, and can be
 *   returned to.
 */
+ wall: Fixture, Surface 'wall; (north) (n)'
    notifyInsert(obj)
    {
        if(obj != clock)
        {
            "You can't put that on the wall. ";
            exit;
        }
    }
;

/*  
 *   RESTRICTED REAR CONTAINER
 *
 *   This clock has a label attached to the rear. The label will move with the
 *   clock. We define a notifyInsert method to ensure that the label is the only
 *   thing that can go behind the clock.
 */

++ clock: RearContainer 'clock; round white' 
   "It's white and round, and shows the current time as <<showTime()>>. "
        
    /* 
     *   When we move the clock we want the label that's behind it to move with
     *   it.
     */
    dropItemsBehind = nil
    
    dobjFor(LookBehind)
    {
        preCond = [objHeld]
    }

    notifyInsert(obj)
    {
        if(obj != blueLabel)
        {
            "Only the label can be put on the back of the clock. ";
            exit;
        }
    }
    

    initSpecialDesc = "A clock hangs on the north wall. "
    useInitSpecialDesc = (isIn(wall))

    objInPrep = 'on the back of'
    
    bulk = 3
    
    /* 
     *   There's no need to worry too much about the showTime() method below;
     *   what it does it read the system time and then report it as the 
     *   time shown on the clock.
     */
    
    showTime()
    {
        local minute = getTime()[7];
        local hour = getTime()[6];
        
        /* 
         *   If the minute is more than 30, then we want to report the time 
         *   as so many minutes to the hour, otherwise we'll report it as so 
         *   many minutes past the hour.
         */
        local prep = minute > 30 ? 'to' : 'past';
        
        /*   
         *   If the minute it more than 30, subtract it from 60 to get the 
         *   number of minutes to the next hour.
         */
        minute = minute > 30 ? 60 - minute : minute;
        
        /*   
         *   If we're reporting so many minutes to the hour, we need to add 
         *   one to the hour ( 10:35 is 25 minutes to 11). 
         */
        hour = prep == 'to' ? hour + 1 : hour;
        
        /*   
         *   If the hour is more than 12, deduct 12 so it's on a 12 hour 
         *   rather than 24 hour clock.
         */
        hour = hour > 12 ? hour - 12 : hour;
        
        /*   Finally spell the time out in words, not numbers. */
        
        if(minute == 0)
            "<<spellNumber(hour)>> o'clock";
        else
            "<<spellNumber(minute)>> minute<<minute > 1 ? 's' :''>> <<prep>>
            <<spellNumber(hour)>>";
    }
;

/*  
 *   The label starts hidden, since we obviously can't see it while the 
 *   clock is hanging on the wall.
 */

+++ blueLabel: Thing 'blue label' 
    "It says <q>Made in adv3Lite</q>. "   
    isHidden = clock.useInitSpecialDesc
;


   
/* 
 *   Make PUT SOMETHING ON CLOCK or ATTACH SOMETHING TO CLOCK behave like PUT
 *   SOMETHING BEHIND CLOCK by defining a DOER
 */
Doer 'put Thing on clock; attach Thing to clock'
    execAction(c)
    {
        doInstead(PutBehind, gDobj, clock);
    }
;



//------------------------------------------------------------------------------

/* The note that's hidden under the cookery book. */

note: Thing 'piece of yellow paper;; note'
    "Someone's scribbled a note on it. "
    readDesc = "It reads: <q>I just realized there was a slight error in my
        original estimate for fitting this kitchen. Nothing to worry about --
        just add another couple of noughts to the figure I quoted.\b
        Buck Grubber (builder)</q>"
    
    bulk = 1
;

/* The leaflet that's hidden behind the oven */
leaflet: Thing 'leaflet; (cooker) instruction'
    "It looks like the instruction leaflet for the cooker. <<first time>> It
    must have fallen down behind.<<only>> "
    
    readDesc = "You can't make head nor tail of the instructions. It looks like
        they've been translated from Chinese with the aid of a
        Portugese-Swahili phrasebook by someone whose first language was
        Sanskrit. "
    dobjFor(Read) { preCond = [objVisible, objHeld] }
    bulk = 1
;



/*
 *   Another example of a DOER: If the player tries to turn the sharpener when
 *   there's a pencil in it, turn the pencil instead.
 *
 *   The property matched in the template, the single-quoted string, is the cmd
 *   property. This defines the command this Doer will respond to when its when
 *   condition is true. We construct this string using the name of the command
 *   as it would be typed by the player ('turn') followed by the *programmatic*
 *   name of the item (or class) the command applies to ('pencilSharpener').
 */
Doer 'turn pencilSharpener'
    execAction(c)
    {
        doInstead(Turn, pencilSharpener.contents[1]);
    }
    when = pencilSharpener.contents.length > 0
;

//==============================================================================
/* The PENCIL class */

class Pencil: Thing 'pencil'
    "It's <<if isSharpened>> quite sharp<<else>> rather blunt<<end>>. "
    dobjFor(Turn)
    {
        verify() 
        {
            /* 
             *   It's most useful to turn a pencil when it's in the 
             *   sharpener, so we'll boost the logical rank of such a pencil.
             */
            
            if(isIn(pencilSharpener))
                logicalRank(120);
        }
        action()
        {
            if(isIn(pencilSharpener))
            {
                "You turn the <<theName>> a few times, sharpening it nicely. ";
                isSharpened = true;
            }
            else
                "You twiddle <<theName>> around, but it doesn't do much. ";
        }
    }
    
    
    isSharpened = nil
    
    /* 
     *   Assigning a ListOrder to the Pencil class will ensure that Pencils 
     *   are listed together in a sensible way in room descriptions, 
     *   inventory listings and the like.
     */
    
    listOrder = 11  
;

/* 
 *   STATE object for the Pencil class so that pencils can be described as
 *   'sharp' or 'blunt'
 */

sharpenedState: State
    /* 
     *   This State will relate to any object that defines the isSharpened
     *   property (i.e. all Pencils), and the isSharpened property will
     *   determine which additional adjectives apply.
     */
    stateProp = &isSharpened
    
    /*   
     *   The additional adjective 'blunt' will apply to Pencils whose
     *   isSharpened property is nil, while the adjectives 'sharp' and
     *   'sharpened' will apply to Pencils whose isSharpened property is true.
     */
    adjectives = [[nil, ['blunt']], [true, ['sharp', 'sharpened']]]
;


//==============================================================================
/*  
 *   CUSTOM ACTIONS AND GRAMMAR
 *
 *   Define the custom OpenWith action plus default action handlers for it. 
 */


DefineTIAction(OpenWith)
;

VerbRule(OpenWith)
    'open' multiDobj 'with' singleIobj
    : VerbProduction
    action = OpenWith
    verbPhrase = 'open/opening (what) (with what)'
    missingQ = 'what do you want to open;what do you want to open it with'
;

modify Thing
    dobjFor(OpenWith)
    {
        preCond = [touchObj]
        
        /* For a multiplex container, remap OpenWith to the remapIn object */             
        remap = remapIn
        
        verify()
        {
            if(isOpenable)
                illogical('{I} {don\'t need} {the iobj} to open {that dobj}. ');
            else
                illogical(&cannotOpenMsg);
        }
    }
    
    iobjFor(OpenWith)
    {
        preCond = [objHeld]
        verify()
        {
            illogical(cannotOpenWithMsg);
        }
    }
    cannotOpenWithMsg = '{I} {can\'t} open anything with {that iobj}. '
    
    /* 
     *   By default the library doesn't allow anything to be the indirect object
     *   of a PourOnto command -- the library simply responds with "You can't
     *   pour anything onto that" -- but it's obviously possible to pour stuff
     *   onto anything (even if we're going to stop the soup being poured for
     *   other reasons) so we'll override the library default.
     */    
    allowPourOntoMe = true
        
;


/* 
 *   With both the clock and the apron a player might try HANG CLOCK ON WALL 
 *   or HANG APRON ON PEG, so it would be good to allow this grammar. The 
 *   best way to do this is to make HANG ON a synonym for PUT ON. There are 
 *   two ways to do this: modify the existing VerbRule or create a new one. 
 *   Here we'll demonstrate the second method.
 */


VerbRule(HangOn)
    'hang' multiDobj 'on' singleIobj
    : VerbProduction
    action = PutOn // this makes it a synonym for PUT ON
    verbPhrase = 'hang/hanging (what) (on what)'
    missingQ = 'what do you want to hang;what do you want to hang it on'
;
