#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*   
 *   EXERCISE 11.T
 *
 *   Demonstration of Room and Connector classes. A real game would be much 
 *   more fully implemented. Here we've kept the number of 
 *   non-Room-or-Connector objects to the minimum needed to demonstrate the 
 *   use of the various kinds of room and connector.
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
    IFID = 'a69ade80-dd65-470b-a2a1-037f03fed454'
    name = 'Exercise 11'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A possible solution to Exercise 11 in Learning TADS 3 with Adv3Lite,
        illustrating how to lay out a map and use various kinds of
        TravelConnectors.'
    htmlDesc = 'A possible solution to Exercise 11 in <i>Learning TADS 3 with
        Adv3Lite</i>, illustrating how to lay out a map and use various kinds of
        TravelConnectors.'
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
    /* the initial player character is 'me' */
    initialPlayerChar = me
    
    /* Display some introductory text at the start of the game */
    showIntro()
    {
        "You've just bought a new property, so you thought you'd take a quick
        look round the house and grounds.<.p>";
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
hall: Room 'Hall'
    "The hall is empty, but a passage runs south, and there's an archway to the
    east as well as the front door to the north. A flight of stairs leads down.
    "
    /* 
     *   Only the east property points directly to another room; the other 
     *   three directional properties point to various other kinds of 
     *   TravelConnector: a Passage, a StairwayDown, and a Door.
     */
    south = hallPassage
    down = hallStairs
    north = frontDoorInside
    east = lounge
    
    /* A simple illustration of the travelerEntering() method */
    
    travelerEntering(traveler, origin)
    {
        if(traveler == bicycle)
            "It occurs to you that you'd better not ride your bike into the hall
            too often, or you'll leave tyre marks on the floor. ";
    }
;

/*
 *   THING  - PLAYER CHARACTER
 *
 *   Define the player character.  The name of this object is not important, but it MUST match the
 *   name we use to initialize gameMain.initialPlayerChar above.
 *
 *   Note that the initial player character should be of the Player class, and the only object of
 *   that class in the game. If the player character changes during the course of play, the
 *   subsequent player characters should be of the Actor class.
 */ 

+ me: Player 'you'   
    "You look splendidly equipped to explore the area. "      
;

/*
 *   STAIRWAY DOWN
 *
 *   A StairwayDown is something you can climb down, so a flight of stairs is an
 *   obvious example. We can't a bicycle or push a trolley down a staircase,
 *   though, so we'll attach a couple of travel barriers to the stairway to
 *   prevent this. For the definition of these traval barrier objects see below.
 *   For the moment note how defining them as objects allows them to be used on
 *   many different TravelConnectors.
 *
 *   Where the three TravelConnectors we go on to define here (hallStairs,
 *   hallPassage and frontDoorInside) lead is defined on their destination
 *   property. Note that for the flight of stairs we define the last (pronoun)
 *   section of the vocab property as both 'it' and 'them' since while 'flight
 *   of stairs' is grammatically singular ('it') the player may think of the
 *   stairs as plural and refer to them as 'them'.
 */

+ hallStairs: StairwayDown 'flight of stairs;;;it them'
    travelBarriers = [bikeBarrier, trolleyBarrier]
    destination = cellar
;



/*  
 *   PASSAGE
 *
 *   This is simply a passage the Player Character can ENTER or GO THROUGH. The
 *   Player Character will automatically go through this passage if s/he leaves
 *   the hall to the south.
 *
 *   The name of this passage as it will appear in the messages displayed by the
 *   parser is simply 'passage', but since it's described as a 'narrow passage;
 *   in its description we add the adjective 'narrow' to its vocab property
 *   after its name.
 *
 *   The destination of this Passage is the room it leads to.
 */

+ hallPassage: Passage 'passage; narrow'
    "The narrow passage leads off to the south. "
    
    destination = kitchen
;

/*  
 *   DOOR 
 *
 *   This is a very basic door, without any kind of lock. The player 
 *   character can GO THROUGH IT explicitly, or will be taken through it if 
 *   s/he leaves the hall to the north. If the door is closed it will be 
 *   opened with an implicit action. 
 *
 */

+ frontDoorInside: Door 'front door'
    otherSide = frontDoorOutside
;

/* 
 *   ENTERABLE
 *
 *   An Enterable is something we can enter. Defining destination = lounge
 *   defines where we go if we enter the arch (in this case, the lounge). Adding
 *   dobjFor(GoThrough) asDobjFor(Enter) makes GO THROUGH ARCH behave like ENTER
 *   ARCH and also takes us to the lounge. 
 */

+ hallArch: Enterable 'arch; carved painted white wood; archway' 
    "It's a carved wood arch, painted white. "
    
    destination = lounge
    
    dobjFor(GoThrough) asDobjFor(Enter)
;

//------------------------------------------------------------------------------
/* Another ROOM */

kitchen: Room 'Kitchen'
    "The kitchen has been stripped of everything, pending its total
    refurbishment. A passage leads off to the north, and there's a laundry chute
    in the west wall<<secretPanel.isOpen ? ', and a large square opening in the
        east one' : '' >>. "
    north = kitchenPassage
    west = laundryChute
    east = secretPanel
;

/* 
 *   TRAVEL PUSHABLE
 *
 *   We need to supply a TravelPushable in order to demonstrate the use of
 *   TravelBarriur with this kind of Thing. In adv3Lite to make a travel
 *   pushable (i.e. something that can be pushed from place to place) we just
 *   use a Thing (or descendent of Thing) and set its canPushTravel property to
 *   true.
 *
 *   We also make the trolley a Surface so we can put things on it.
 */

+ trolley: Heavy, Surface 'trolley' 
    /* 
     *   Without a specialDesc the trolley wouldn't show up in a room
     *   description, since we've made it a Heavy, which descends from Fixture.
     */
    specialDesc = "There's a trolley here. "
    
    
    /* A trolley is something we can push from place to place */
    canPushTravel = true   
;

/* 
 *   FLASHLIGHT
 *
 *   We need to supply some kind of light source, otherwise it will be 
 *   impossible to explore the DarkRoom example (the cellar)
 */

++ torch: Flashlight 'flashlight;red plastic; torch light'     
    "It's made of red plastic. "
;

/* 
 *   PASSAGE (again)
 *
 *   This is the other end of the passage that leads from the hall. 
 */

+ kitchenPassage: Passage 'passage' 
    destination = hall 
;

/* 
 *   PASSAGE, WITH MESSAGE DISPLAYED ON TRAVELING THROUGH IT
 *
 *   Since travelling via a laundry chute is a little unusual, we should 
 *   probably describe the travel here. One way of doing this is by 
 *   defining the travelDesc property.
 *
 *   A more complete implementation of the laundry chute might allow the 
 *   player to put things in it which then fall down into the cellar, but we 
 *   don't need that complication for this demo game, so it's left as an 
 *   exercise for the interested reader. 
 */

+ laundryChute: Passage 'laundry chute'
    "Although it's intended for laundry, it's large enough for a person to fit
    into as well. "
    
    specialDesc = "A laundry chute is set in the west wall. "
    
    /* 
     *   We can't ride the bike or push the trolley through the laundry chute.
     *   To enforce this we can use a couple ot travel barriers.
     */
    travelBarriers = [bikeBarrier, trolleyBarrier]
    
    travelDesc = "You find yourself tumbling rapidly down the laundry chute
        until you are unceremoniously ejected from its lower end, landing with a
        bone-shaking bump. "
    
    destination = cellar
;

/*   
 *   HIDDEN DOOR
 *
 *   A Hidden Door is one that doesn't reveal its presence at all (it can't be
 *   sensed) unless it's open. To make a Hidden Door we simply define an
 *   ordinary Door and then define its isHidden property to be true when the
 *   Door isn't open.
 *
 *   The other side of this door will be a bookcase in the study, so we define
 *   the otherSide property to be the bookcase.
 */

+ secretPanel: Door  'opening; large square'
    isHidden = !isOpen
    otherSide = bookcase
;


//------------------------------------------------------------------------------

/* 
 *   DARK ROOM
 *
 *   To make a Dark Room we just use an ordinary Room and define its isLit
 *   property to be nil.
 */

cellar: Room 'Cellar'    
    "The cellar is bare, since the last owners moved all their rubbish out and
    you haven't moved your own rubbish in yet. A flight of stairs leads up, and
    the end of the laundry chute protrudes from the west wall. "
    
    isLit = nil
    
    /* 
     *   By default a Dark Room displays "In the dark" and "It's pitch black" 
     *   as its name and description respectively, but we can change that on 
     *   individual dark rooms by overriding the following two properties.
     */
    darkName = 'Cellar (in the dark) '
    darkDesc = "It's too dark to see anything in here, but you can just make
        out some stairs leading up. "
    up = cellarStairs
    west = cellarChute
;

/*  
 *   STAIRWAY UP       
 */

+ cellarStairs: StairwayUp 'flight of stairs;;;it them'

    /* The stairs lead back up to the hall */
    destination = hall
    /* 
     *   By giving the stairs visibleInDark property of truewe make them dimly
     *   visible even when the cellar is dark. This will allow the player to
     *   climb the stairs even if s/he arrives in the cellar via the laundry
     *   chute without a light source (which would otherwise leave the player
     *   character totally stuck). Note that this only the stairs visible in the
     *   dark; they will not illuminate anything else/
     */
    visibleInDark = true
;

 /* 
  *   EXIT ONLY PASSAGE
  *
  *   This is where we emerge from if we enter the laundry chute in the kitchen.
  *   We make this end a Passage since it looks like something we might be able
  *   to travel back up, but in fact we can't climb back up the chute, so we
  *   block the attempt to do so.
  */
+ cellarChute: Passage 'laundry chute; of[prep]; end'
 
    /* 
     *   Since we don't give this Passage a destination the player character
     *   won't be able to traverse it, but the travelDesc will still be
     *   displayed, so we can use the travelDesc to explain why the PC can't go
     *   back up the chute. Since CLIMB CHUTE is another possible phrasing,
     *   we'll use the cannotClimbMsg to explain the failure of both types of
     *   attempt.
     */
    travelDesc = "<<cannotClimbMsg>>"
    
    cannotClimbMsg = 'There\'s no way you can climb back up the chute.'
    
    /* 
     *   This specialDesc will be displayed in the room description (when the
     *   room is lit).
     */
    specialDesc = "The end of the laundry chute protrudes from the west wall. "
;


//------------------------------------------------------------------------------

/*  Another ROOM */

lounge: Room 'Lounge' 
    "This will be a comfortable enough room once it is furnished, no doubt. At
    the moment, though, there's nothing here except an exit to the west and a
    door leading south. "
    
    /* 
     *   TRAVEL CONNECTOR WITH MESSAGE
     *
     *   A TravelConnector can display a message (travelDesc) when the player
     *   characters traverses it, and can be defined directly on a direction
     *   property of a Room as an anonymous nested object.
     */
    
    west: TravelConnector 
    { 
        destination = hall 
        
        /* 
         *   travelMethod() is a custom function we define below; it displays
         *   either 'walk' or 'cycle' depending on whether or not the player
         *   character is on the bicycle.
         */    
        travelDesc = "You <<travelMethod()>> back out into the hall. "     
    }
       
    
    south = oakDoor  
;


/*  An ordinary DOOR */

+ oakDoor: Door 'oak door'
    
    otherSide = studyDoor
    /* 
     *   A Door is a subclass of TravelConnector, so we can attach travel 
     *   barriers to it directly.
     */
    travelBarriers = [bikeBarrier, trolleyBarrier]
;

//------------------------------------------------------------------------------

/*  Yet Another ROOM */

study: Room 'Study'
    "This long, rectangular room is currently unfurnished, but you've earmarked
    it for your study. There's an oak door to the north, and an empty bookcase
    <<bookcase.isOpen ? 'has swung open from' : 'rests against'>> the west
    wall. "
    north = studyDoor    
    out asExit(north)
    west =  bookcase
;

/*  The other side of the oak door in the lounge */

+ studyDoor: Door 'oak door'   
    otherSide = oakDoor
;
    
  /* 
   *   SECRET DOOR
   *
   *   A SecretDoor is something that doesn't look like a door at all unless 
   *   it's open. Here we'll use a bookcase as a secret door. When closed, 
   *   it'll just look like a bookcase; when open, the player can go through 
   *   it to the kitchen.  
   *
   *   Since it's described as a bookcase people might try to put things on 
   *   it or in it, so we'll make it a Surface to allow this. Note that 
   *   making a Container wouldn't have worked, since the isOpen property of 
   *   Container would conflict with the isOpen property of SecretDoor.
   */

+ bookcase: Surface, SecretDoor 
    'bookcase; large square wooden empty (book); case shelf shelves' 
    "It's a large, square, wooden bookcase, currently empty. <<isOpen ? 'It has
        swung open, revealing a secret exit behind' : ''>> "
    
    /* The bookcase is the other side of the secret panel from the kitchen */
    otherSide = secretPanel
    
    
    /* 
     *   The name and vocabulary used for this object when it's open and also
     *   functions as an openind through to the kitchen.
     */
    vocabWhenOpen = 'opening; secret large square wooden (book); 
        exit bookcase case shelf shelves' 
    
    /* 
     *   Since this is a secret door, it won't respond to OPEN and CLOSE 
     *   commands, so we need to provide some other means of opening and 
     *   closing it. This could be with a concealed lever or secret button, 
     *   but since we want to keep the use of other objects to a minimum 
     *   here, we'll just let the player PULL the bookcase open and PUSH it 
     *   closed.    
     */
    
    dobjFor(Pull)
    {
        verify()
        {
            if(isOpen)
                illogicalNow('It\'s already fully open. ');
        }
        action()
        {
            makeOpen(true);
            "The bookcase swings open, revealing an opening behind. ";
        }
    }
    
    dobjFor(Push)
    {
        verify()
        {
            if(!isOpen)
                inherited;
        }
        action()
        {
            makeOpen(nil);
            "You push the bookcase shut again. ";
        }
    }
    
    /* 
     *   We'll also make MOVE BOOKCASE act like PUSH BOOKCASE if it's open 
     *   and PULL BOOKCASE if it's closed.
     */
    
    dobjFor(Move)
    {
        verify() {  }
        action()
        {
            if(isOpen)
                replaceAction(Push, self);
            else
                replaceAction(Pull, self);
        }
    }
    
   
;

/* 
 *   WEARABLE
 *
 *   These shoes will be useful for the 
 *   example of a two-way Connector below, where they are used in connection 
 *   with a canTravelerPass() method. Although they don't strictly belong in 
 *   a game demonstrating rooms and connectors, it's almost impossible to 
 *   demonstrate every type of connector without at least a few other 
 *   objects. 
 */

+ shoes: Wearable 'pair of brown shoes; floatation; footware; it them'
    "They're brown in colour, and marked <q>water-repellant floatation
    footware</q>. "
    
    initSpecialDesc =  "A pair of shoes lie on the floor. "    
       
;

//------------------------------------------------------------------------------

/* 
 *   OUTDOOR ROOM
 *
 *   The drive is the first Outdoor Room defined in this game. In the adv3Lite
 *   main library there's no special OutdoorRoom class, so we just use a Room.
 *   If you were using the roomparts.t extension, however, you would use the
 *   OutdoorRoom class here.
 */

drive: Room, ShuffledEventList 'Front Drive'
    "The drive opens out into a busy road to the north. A path leads off to the
    east, while to the east stand some dense woods. The south side of the drive
    is occupied by a large house, while a tall oak tree grows right in the
    middle of the drive. "
    south = frontDoorOutside
    in asExit(south)
    up = oakTree
    
    /* 
     *   METHODS AS PSEUDO-CONNECTORS
     *
     *   We can define direction properties as methods, which will then be
     *   executed when travel is attempted in the corresponding direction. The
     *   directions will still show up in the exit-lister. This is most useful
     *   in the kind of case shown below, where we want to give the impression
     *   that there's more in a particular direction even though we haven't
     *   implemented it, so we just display a message saying why travel isn't
     *   possible.
     */
    
    north  { "You don't want to wander out into the road right
        now; at this time of day the traffic is so busy that it's just not safe
        for << me.isIn(bicycle) ? 'cyclists' : 'pedestrians'>>. "; }
    
    /* 
     *   For the connection to the wood we simulate travelling a litte way into
     *   the woods and coming back again.
     */
    west: TravelConnector 
    { 
        /* 
         *   Our destination is our starting point, i.e. the drive, which we can
         *   refer to here as lexicalParent, i.e. the object we're defined on.
         */
        destination = lexicalParent
        
        travelDesc = "You <<travelMethod()>> into the woods, but the paths
            become so confusing that for a while you are lost. Eventually you
            find your way back onto a familiar path and manage to return to your
            starting point. " 
    }
    
    east = drivePath
    
    /* 
     *   ATMOSPHERE LIST
     *
     *   We can have a Room display a series of atmospheric messages; to do this
     *   we include an EventList class (such as ShuffledEventList) in its class
     *   list and then define its  eventList property to contain a list of
     *   messages.
     */       
    eventList =     
    [
        'A lorry rumbles past on the road. ',
        'The sound of a loud siren wails from the road. ',
        'A pair of rabbits scuttle off into the woods. ',
        'A flock of pigeons flies overhead. ',
        'The sun comes out from behind a cloud. ',
        'A gust of wind rustles the oak tree. '
    ]
    
    /* 
     *   We probably don't want to see one of these messages every turn, so
     *   we'll set them to display only once every two turns on average.
     */        
    eventPercent = 50
   
;

/*  
 *   ENTERABLE 
 *
 *   We use an Enterable to represent the outside of the house. Thus can be 
 *   entered via the front door, so we point the house's connector property 
 *   to the frontDoorOutside object.
 */

+ house: Enterable 'large house'
    "It's a large house with a front door that\'s <<frontDoorOutside.isOpen ?
      'invitingly open' : 'firmly closed'>>. "
    
    connector = frontDoorOutside
;

++ frontDoorOutside: Door 'front door' 
    otherSide = frontDoorInside
;


/* 
 *   A less conventional STAIRWAY UP
 *
 *   A StairwayUp can be used for things other than stairs; anything 
 *   climbable is a candidate for a StairwayUp, including a tree.
 *
 *   But note that we can hardly ride a bicycle up a tree, or push a trolley 
 *   up one, so we attach the appropriate travel barriers to prevent this.
 */     


+ oakTree: StairwayUp 'large oak tree'
    destination = topOfTree
    
    travelBarriers = [bikeBarrier, trolleyBarrier]
    
    /* We'll also stop the player climbing the tree while carrying the bike. */
    canTravelerPass(traveler) { return !bicycle.isIn(traveler); }
    explainTravelBarrier(traveler)
    {
        "You can hardly climb the tree carrying the bicycle. ";
    }
;

/* PATH PASSAGE */

+ drivePath: PathPassage 'path' 
    "The path leads off to the east. "
    
    destination = lawn
;

/* 
 *   VEHICLE
 *
 *   We need a vehicle to demonstrate how a TravelBarriers can prevent them passimng, so we'll
 *   provide this bicycle. To make it a vehicle we make it a Platform so we can get on it and then
 *   define its isVehicle property to be true.
 */

+ bicycle: Platform 'bicycle; old; bike cycle'
    "It's old, but it looks functional enough. "
    initSpecialDesc = "An old bicycle leans against the front of the house. "
    
    /* 
     *   You can sit on a bicycle but you can't lie on it. Adv3Lite doesn't track postures (unless
     *   you imclude the postures.t extensiob) but you can rule out LIE ON BICYCLE (which is
     *   otherwise effectivey the same as GET ON BICYCLE).
     */
    canLieOnMe = nil
    
    isVehicle = true
    /* 
     *   The bike is perfectly usable without the following action handling, but
     *   RIDE BIKE and RIDE BIKE <direction> (e.g. RIDE BIKE NORTH) are such
     *   obvious commands to try that it seems worth implementing them.
     *
     *   We start by implementing RIDE BIKE. If the player character is not
     *   already on the bike we make this equivalent to SIT ON BIKE, otherwise
     *   we ask the player which direction the bike should be ridden in.
     *
     *   RIDE and RIDE DIR are not actions defined in the library; we define
     *   them below.
     */
    
    dobjFor(Ride)
    {
        verify() { }
        action()
        {
            if(!gActor.isIn(self))
                replaceAction(SitOn, self);
            else
                "Which way do you want to ride the bike? ";
        }
    }
    
    /*
     *   The other obvious form of command is RIDE BIKE <dir> (e.g. RIDE BIKE
     *   NORTH). We implement that next. 
     */
    
    dobjFor(RideDir)
    {
        
        verify() 
        { 
            if(!gPlayerChar.isIn(self))
                illogicalNow('You\'ll have to get on the bike before you can
                    ride it anywhere. ');
        }
                
        /* 
         *   This exercise isn't about defining actions, so don't worry about
         *   this too much now, but this is how we synthesise a command to go in
         *   the direction the player wants to ride. 
         */
        action()
        {
            doInstead(Go, gCommand.verbProd.dirMatch.dir);          
        }      
        
    }
;

/* 
 *   ENTERABLE
 *
 *   We want ENTER WOODS to behave the same way as WEST. We do that by 
 *   pointing the associated connector to the location's west property.
 */

+ Enterable 'dense woods;; wood trees; them it'
    connector = location.west
;


//------------------------------------------------------------------------------
/*  
 *   A FLOORLESS ROOM
 *
 *   The top of the tree has no floor.
 */

topOfTree: Room 'Top of Tree' 'the top of the tree'
    "The top of the tree doesn't afford much of a view, since the leaves and
    branches get in the way. "
    
    down = trunk
    
    /* There's no floor or ground here. */
    floorObj = nil
    
    /* 
     *   Anything dropped here will fall to the drive below rather than remain
     *   suspended in mid-air.
     */
    dropLocation = drive
    
    /* 
     *   If we like we can display a message describing the fact that something
     *   dropped here falls to the ground.
     */
    roomAfterAction()
    {
        if(gActionIs(Drop))
            "{The subj dobj} {falls} to the ground below. ";
    }
;

/*  An unconventional STAIRWAY DOWN to match the StairwayUp at the bottom */

+ trunk: StairwayDown 'trunk; tree'
    destination = drive
;

//------------------------------------------------------------------------------
/*   Another OUTDOOR ROOM */

lawn: Room 'Lawn'
    "This large lawn is enclosed to east and south by a bend in a river, though
    you could board the boat that's moored up just to the east. A path leads
    west back to the main drive. "
    west = gardenPath    
    east = mainDeck
    south = riverConnector
    
    /* 
     *   A FAKE EXIT
     *
     *   We can define a string directly to a direction property to display a message explaining why
     *   travel is not permitted in that direction. If we use a double-quoted string the exit is
     *   still shown in the exit lister. If we don't want it to be listed there, we could use a
     *   single-quoted string instead.
     */
    
    north = "Even if you could force your way through the thick shrubbery, which
        you can't, on the far side of it runs the main road, which you'd rather
        avoid right now. "
    
    /* One more naturally moves 'onto' a lawn than 'into' it. */
    objIntoPrep = 'onto'
;

/*  PATH PASSAGE */

+ gardenPath: PathPassage 'path'
    destination = drive
    travelDesc = "You <<travelMethod()>> back down the path. "
;

/* 
 *   ENTERABLE
 *
 *   We'll provide a boat here in order to give examples of Shipboard rooms. */


+ boat: Enterable 'large boat'
    "It's about fifteen feet long. "
   specialDesc = "A large boat is moored up on the river at the bottom of the
       garden, just to the east. "
    
    destination = mainDeck
    
    dobjFor(Board) asDobjFor(Enter)
    getFacets = [boat2] // see below
;

//------------------------------------------------------------------------------

 /* 
  *   A MULTILOC DECORATION
  *
  *   The river is not strictly essential in this demonstration game, but 
  *   since it's mentioned rather prominently, it would seem needlessly 
  *   sloppy not to implement it, albeit in minimal form.
  */


MultiLoc, Decoration 'swollen river' 
    "Swollen by recent heavy rain, the river runs broad and fast. "
    locationList = [lawn, meadow]
;

 /* 
  *   A TWO-WAY CONNECTOR
  *
  *   To make a TravelConnector that can be traversed in both directions, we
  *   define its destination property to be the meadow if the actor is in the
  *   lawn and vice versa.
  */


riverConnector: TravelConnector
    
    destination = gActor.isIn(lawn) ? meadow : lawn
       
    /*
     *   Note that if the PC is riding the bicycle, the traveler will be the 
     *   bicycle, not the PC, and the bicycle can never wear the shoes; thus 
     *   this canTravelerPass() method will only allow the PC to pass on foot
     *   wearing the shoes. It will also prevent the trolley from being 
     *   pushed across the river, since the trolley can never wear the 
     *   shoes either (nor can the PushTravel object created to handle 
     *   moving the trolley).
     */
    canTravelerPass(traveler) { return shoes.wornBy == traveler; }
    explainTravelBarrier(traveler)
    {
        
        /* 
         *   The tricky case is where we're trying to push the trolley across the river. So we need
         *   to test for which object is tryjng to cross the river.
         */       
        
        switch(traveler)
        {
        case me:
            "You aren't equipped for walking on water. "; break;
        case bicycle:
            "You can hardly cycle across the river. "; break;
        default:
            if(traveler == trolley)
               "You can't push the trolley across the river. "; 
            else
                "You can't cross the river. "; 
            break;
        }
    }
    
    /* 
     *   We can use noteTraversal() to describe what happens when an actor
     *   crosses the river. Note that this message will display for *any* actor
     *   crossing the river, not just the player character. In this game the
     *   player character is the only actor, so that's okay; the effect is
     *   exactly the same as if we'd  defined a travelDesc. In a game which had
     *   mobile actors in addition to the player character, using travelDesc
     *   might be a better choice.
     */
    
    noteTraversal(traveler)
    {
        "Aided by the special shoes, you are able to walk across the river. ";
    }
;





//------------------------------------------------------------------------------
/*  Another OUTDOOR ROOM */

meadow: Room 'Meadow' 
    "This vast meadow stretches as far as you can see in every direction except
    north, where it is bounded by the river. "
    
    /* 
     *   Here we override the standard "You can't go that way" message and 
     *   provide our own version instead.
     */
    
    cannotGoThatWayMsg = 'It\'s your own property you want to explore, and this
        meadow clearly isn\'t part of it. '
    north = riverConnector
;

//------------------------------------------------------------------------------

 /*  
  *   ABOARD SHIP
  *
  *   We add a few locations aboard a boat to demonstrate 
      the various shipboard directions. These are automatically valid in any
      room that defines any of them
  */

mainDeck: Room 'Main Deck'
    "The main deck is tidy to the point of bareness. The main cabin lies aft,
    and you can leave the boat to starboard. "
    
    /* 
     *   Since we're now aboard a boat we can now use the shipboard 
     *   directions port, starboard, fore and aft, so we'll use these to 
     *   define the direction properties on all these boat-location. Since 
     *   the boat is moored up and will never move in this game, the compass 
     *   directions will map unambiguously onto the shipboard directions, 
     *   and since the player might use these too, we'll implement them via 
     *   asExit macros. Note that it's the shipboard directions that will 
     *   show up in the exit lister, since these are the ones we define 
     *   directly.
     */
    
    starboard = lawn
    
    /* Make WEST and OUT behave the same as STARBOARD */
    west asExit(starboard)
    out asExit(starboard)
    
    aft = mainCabin
    south asExit(aft)
    in asExit(aft)
    
    /* We use a single-qouoted string here so FORE won't be listed as a possible exit. */
    fore = 'You don\'t want to walk off the bow! ' 
    north asExit(fore)
    
    describePushTravelInto()
    {
        "You push the trolley onto the main deck of the boat. ";
    }
;

/* 
 *   EXITABLE
 *
 *   Providing this object here allows us to handle commands like 
 *   LEAVE THE BOAT or GET OUT OF THE BOAT.
 */

+ boat2: Fixture 'boat' 
    "It's about fifteen feet long from stem to stern. <<location.desc()>>"
    dobjFor(GetOff) asDobjFor(GetOutOf)
    
    /* Make GET OUT OF BOAT equivalent to GO STARBOARD */
    dobjFor(GetOutOf)
    {
        verify() {}
        action() { goInstead(starboard); }
    }
    
    /* 
     *   We make boat and boat2 facets of each other so that if, for 
     *   example, the player were to type ENTER BOAT followed by LEAVE IT, 
     *   the parser would know what IT refers to (since the parser now 
     *   recognizes boat and boat2 as facets of the same object.
     */
    getFacets = [boat]
;

/*  
 *   SHIPBOARD ROOMS
 *
 *   Both the main cabin and the sleeping cabin are Rooms aboard the boat. The
 *   library will recognize them as shipboard rooms (that is, rooms in which the
 *   shipboard directions port, starboard, fore and aft are valid) because we
 *   define at least one of these as an exit on each of these rooms.
 */

mainCabin: Room 'Main Cabin'
    "The main cabin is bare, since the boat is being refitted. The way back out
    to the deck is fore, while the sleeping cabin lies to port. "
    fore = mainDeck
    north asExit(fore)
    out asExit(fore)
    port = sleepingCabin
    east asExit(port)
;

sleepingCabin: Room 'Sleeping Cabin'
    "There would normally be a bunk here, but it's been removed while the boat
    is being refitted. The way out back to the main cabin is to starboard. "
    starboard = mainCabin
    west asExit(starboard)
    out asExit(starboard)
;

//==============================================================================
/* 
 *   TRAVEL BARRIERS
 *
 *   We define two TravelBarriers for use on a number of 
 *   TravelConnectors.
 */


bikeBarrier: TravelBarrier
    canTravelerPass(traveler, connector)
    {
        return traveler != bicycle;
    }
    
    explainTravelBarrier(traveler, connector)
    {
        "You can't ride the bike that way. ";
    }    
;

trolleyBarrier: TravelBarrier
    canTravelerPass(traveler, connector)
    {
        return traveler != trolley;
    }
    
    
    /* 
     *   This illustrates one way in which we can customise the message 
     *   explaining why the trolley can't be pushed through certain 
     *   connectors. We wouldn't want to do this for a whole lot of 
     *   different travel barriers and connectors, so in a more complicated 
     *   game we'd probably devise a more generalized scheme.
     */
    
    explainTravelBarrier(traveler, connector)
    {
        "You can't push the trolley <<connector.traversalMsg()>>.";             
    }
    
;

/* 
  *   Defining a FUNCTION
  *
  *   Since we've used travel messages on several TravelConnectors that can 
  *   be traversed either on foot or on the bicycle, it's helpful to have a 
  *   utility function that gives us a verb appropriate to the means of 
  *   locomotion.
  */

travelMethod()
{
    return me.isIn(bicycle) ? 'cycle' : 'walk';
}


//==============================================================================

/*  
 *   NEW ACTIONS
 *
 *   Add a couple of new actions for riding the bike, since RIDE BIKE or RIDE
 *   BIKE EAST etc. would be such natural actions to try
 */


DefineTAction(Ride)
;

VerbRule(Ride)
    ('ride' | 'mount') singleDobj
    :  VerbProduction
    action = Ride
    verbPhrase = 'ride/riding (what)'
    missinqQ = 'what do to you want to ride'
;

DefineTAction(RideDir)
;

VerbRule(RideDir)
    'ride' singleDobj ('to' ('the'|) |) singleDir
    : VerbProduction
    action = RideDir
    verbPhrase = 'ride/riding (what) (where)'
    missinqQ = 'what do to you want to ride'
;

modify Thing
    dobjFor(Ride)
    {
        preCond = [touchObj]
        verify() { illogical(cannotRideMsg); }
    }
    dobjFor(RideDir)
    {
        preCond = [touchObj]
        verify() { illogical(cannotRideMsg); }
    }
    
    cannotRideMsg = '{The subj dobj} {is} not something you can ride. '
;
