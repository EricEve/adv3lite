#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*   
 *   BEDSITTERLAND
 *
 *   A demonstration of adv3Lite Nested Rooms (non-Room Things that can contain
 *   actors and/or the player character).
 *.
 *
 *   This is only minimally a game; there's nothing for the player to do but try
 *   out the various kinds of Nested Room. The 'game' is also fairly minimal in
 *   that very little has been implemented apart from what's necessary to show
 *   the various Nested Room classes.
 */


versionInfo: GameID
    IFID = '9ac9903f-75b8-436f-b1c5-263427d1ea00'
    name = 'Exercise 18 - Bedsitterland'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A demonstration of nested rooms in adv3Lite.'
    htmlDesc = 'A demonstration of nested rooms in adv3Lite.'
;

gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    showIntro()
    {
        "This bedsit was the best accommodation you could find at short notice;
        now it looks like you'll be stuck here for at least the next few months,
        so you may as well try out the furniture.\b";
    }
;

//==============================================================================
/* 
 *   A MODIFICATION TO PLATFORM
 *
 *   By default the library enforces no reachability conditions when the 
 *   actor is in an ordinary Platform, but this can seem a bit 
 *   unrealistic. For example the standard library behaviour would allow the 
 *   PC to open the wardrobe while lying on the bed, and this is surely 
 *   rather implausible.
 *
 *   The following modification to Platform changes that behaviour by 
 *   making an actor leave a Platform in order to perform an action that 
 *   requires touching an object that's not in the Platform.
 * 
 */
 
modify Platform
     /* 
     *   Check whether the actor can reach out of this object to touch obj, if
     *   obj is not in this object.
     */    
    allowReachOut(obj) { return nil; }          
;


/* 
 *   ROOM
 *
 *   Starting location - we'll use this as the player character's initial
 *   location.  The name of the starting location isn't important to the
 *   library, but note that it has to match up with the initial location for the
 *   player character, defined in the "me" object below.
 *
 *   Our definition defines three strings.  The first string, which must be in
 *   single quotes, is the "name" of the room; the name is displayed on the
 *   status line and each time the player enters the room.  The second (which is
 *   option) is in single quotes and defines the vocab property for the room.
 *   The third string, which must be in double quotes, is the "description" of
 *   the room, which is a full description of the room.  This is displayed when
 *   the player types "look around," when the player first enters the room, and
 *   any time the player enters the room when playing in VERBOSE mode.
 *
 *   The name "startRoom" isn't special - you can change this any other name
 *   you'd prefer.  The player character's starting location is simply the
 *   location where the "me" actor is initially located.
 */
startRoom: Room 'Your Bedsit' '() your bedsit;; room'
    "One thing that can be said for this room is that it is at least reasonably
    large. Whoever furnished it seems to have been in two minds about sleeping
    arrangements, since in addition to the conventional bed over in one corner,
    there's a bunk high up on one wall, over a short wooden bench. Fortunately
    the bench is not the only thing to sit on, since there's also a comfortable
    armchair and a long sofa. There's also a large desk, situated under a
    bookshelf that's fixed inconveniently high up the wall, and a built-in
    wardrobe large enough to walk into. "
    
    north = door
        
;

/* 
 *   The player character object. This doesn't have to be called me, but me is a
 *   convenient name. If you change it to something else, rememember to change
 *   gameMain.initialPlayerChar accordingly.
 */

+ me: Thing 'you'   
    "You can't bear to look at yourself right now; you've come down so
    far in the world to end up in this place! "
    isFixed = true       
    person = 2  // change to 1 for a first-person game
    contType = Carrier    
;


/*   
 *   DOOR
 *
 *   Even a bedsit must have a door, but we'll provide one that doesn't go 
 *   anywhere, giving a reason why the PC doesn't want to go out right now.
 */

+ door: Door 'door' 
    beforeTravel(traveler, connector)
    {
        if(connector == self)
        {
            say(cannotOpenMsg);
            
            exit;
        }
    }      
    
    isOpenable = nil
    cannotOpenMsg = '''You don't want to go out right now. You might run into 
        your landlady in the hall, and she'll only start demanding the rent! '''
    
    /* 
     *   This is the standard trick for a door that doesn't actually lead
     *   anywhere; it stops the library from warning us that we've forgotten to
     *   define the otherSide property on this Door.
     */
    otherSide = self
;



/*  
 *   CHAIR
 *
 *   A chair is something that you would normally sit on and possibly stand on.
 *
 *   Since adv3Lite doesn't track postures, it doesn't distinguish between
 *   objects you can stand on, sit on or lie on (platforms, chairs and beds),
 *   but simply uses the Platform class for all three. We'll make this Platform
 *   an Immovable, since it's not something the PC is meant to walk around with.
 */
 

+ armchair: Platform, Immovable 'armchair; arm neutral grey gray comfortable;
    chair furniture[pl] seating[pl]' 
    
    "It's a neutral gray in colour, but looks comfortable enough. "
    
    cannotTakeMsg = 'You could take the armchair, but it would be a bulky thing
        to walk around with, so you\'d rather not bother. '
    
    /* 
     *   This chair isn't big enough to lie on. Although adv3Lite doesn't
     *   actually track postures, it does allow commands like STAND ON, SIT ON
     *   and LIE ON. While in reality these mean the same as GET ON, the
     *   player's choice of command may indicate the particular item of
     *   furniture s/he has in mind, so it can be useful to control which
     *   commands are applicable to which objects.
     */
    canLieOnMe = nil
;


/*   
 *   CHAIR 
 *
 *   By default a Chair cannot be lain on, but a sofa might be long enough to
 *   allow someone to lie on, so here we'll override allowedPosture to allow
 *   this. We'll make the sofa a Heavy as well, since something that size 
 *   would presumably be too heavy to pick up.
 */

+ sofa: Platform, Heavy 'sofa; long; settee chairs[pl] furniture[pl]
    seating[pl]' 
    "It could easily sit three people; alternatively there's plenty of room for
    you to stretch yourself out on it. "
    
    standOnScore = 90
   
;

/*  
 *   BED
 *
 *   A bed is something that you would normally lie on, although by default 
 *   you can also sit or stand on a Bed. Since people are more likely to sit 
 *   on a bed than stand on one, sitting is also among the obviousPostures 
 *   but standing is not. 
 *
 *   LIE ON BED is equivalent to GET ON BED.
 */


+ bed: Platform, Heavy 'bed; single; furniture[pl]' 
    "It's just a standard size single bed, about three feet wide and six long.
    The space underneath it is taken up with a drawer in which you could store
    some of your things. "
    
    lookUnderMsg = 'The space under the bed is taken up by the drawer. '
    
    /* 
     *   Although we're not really modelling postures, we can adjust the
     *   suitability of different Platforms for different commands, so here we
     *   can make the bed particularly suitable for lying on, less suitable for
     *   for sitting on, and even less suitable for standing on, while note
     *   ruling out any of these. The default value of each of these three
     *   scores would be 100. Adjusting these scores can help the parser's
     *   choice of object in cases of ambiguity.
     */        
        
    lieOnScore = 110
    sitOnScore = 90
    standOnScore = 80
;

/*  
 *   OPENABLE CONTAINER
 *
 *   Since we described the bed as having a drawer underneath, we should 
 *   implement it.
 */

++ drawer: OpenableContainer, Fixture 'drawer; long'    
    "It would have made more sense to put a pair of drawers under the bed, but
    there's only one. "
;

+++ pillow: Thing 'spare pillow'
    bulk = 3
;

/*  
 *   BOOTH
 *
 *   A Booth is something an actor can enter. By default GET IN BOOTH is 
 *   treated as STAND ON (i.e. IN) BOOTH, but sitting or lying are regarded 
 *   as both allowed and obvious.
 */

+ wardrobe: Booth, Fixture 'wardrobe; built-in white painted large'     
    "It's painted white, and looks large enough to walk into. <<isOpen ? 'Inside
        the wardrobe is a metal hanging rail. ' : ''>>"      
    
    isOpenable = true
    isOpen = nil
    
    /* 
     *   Force an actor inside the wardrobe to leave the wardrobe in order to
     *   reach (i.e. touch) anything outside it.
     */
    allowReachOut(obj) { return nil; }   
    
;

/*  
 *   Just to make a wardrobe slightly less boring, we'll put a couple of 
 *   things inside it.
 */

++ Surface, Fixture 'metal rail; hanging; rod' 
    "The metal hanging rail runs the length of the wardrobe. "
    
    notifyInsert(obj)
    {
        if(obj != hanger)
        {
            "You can't put <<obj.theName>> on the rail. ";            
            exit;
        }           
    }    
    
;

+++ hanger: Thing 'wire coat-hanger; (coat); hanger coathanger'
    
;



/*  
 *   PLATFORM
 *
 *   A Platform is something one would normally stand on, although one could 
 *   equally well sit or lie on it. 
 *
 *   GET ON PLATFORM is treated as equivalent to STAND ON PLATFORM
 *
 *   To make it a bit more interesting, we'll make our first example of a 
 *   Platform a desk which things can be put under as well as on top of 
 *   (although one might normally think of a Desk as a Surface, it's usually 
 *   possible to sit or stand on a desk, and even to lie on it if it's big 
 *   enough). To allow this we need to make the desk itself a 
 *   Multiplex Container and attach the Platform to its remapOn.
 */


+ desk: Heavy 'desk;; furniture[pl]' 
    remapOn: SubComponent, Platform
    {       
        /* 
         *   We must be able to reach the bookshelf and anything on the
         *   bookshelf from the desk, or else we'll defeat the obiect of making
         *   the bookshelf only reachable from the desk.
         */   
        allowReachOut(obj)
        {
            return obj.isOrIsIn(bookshelf);
        }
        
        
    }
    remapUnder: SubComponent {  }   
;

++ ladder: Platform 'short ladder; wooden'
    
    /* 
     *   Put the ladder under the desk. Note the special syntax for placing 
     *   something within a subXXXXX of a ComplexContainer.
     */
    subLocation = &remapUnder
    
    /*  
     *   Normally you can sit, stand, or lie on a Platform, but in the case 
     *   of a ladder its only standing that makes much sense.
     */
    canSitOnMe = nil
    canLieOnMe = nil
        
    
    /*   
     *   It would be natural to try to climb, climb up or climb down a 
     *   ladder, so we redirect these actions appopriately.
     */
    dobjFor(Climb) asDobjFor(StandOn)
    dobjFor(ClimbUp) asDobjFor(StandOn)
    dobjFor(ClimbDown) asDobjFor(GetOff)
    
    /*   
     *   Add a custom property to keep track of the notional position of the 
     *   ladder.
     */    
    leaningAgainst = nil
    
    /*   
     *   We'll only allow the ladder to be used to reach the bunk when it's 
     *   leaning against the bunk, so we need to provide an action that 
     *   allows the player to put the ladder in the appropriate place. We'll 
     *   use MoveTo.
     */
    
    dobjFor(MoveTo)
    {
        action()
        {
            if(gIobj == bunk)
            {
                actionMoveInto(bunk.location);
                leaningAgainst = bunk;
                "You lean the ladder against the bunk. ";
            }
            else
                inherited;
        }
    }
    
    /*  
     *   Whenever the ladder is taken, it can no longer be leaning against 
     *   the bunk (or anything else), so we need to override the action 
     *   handling for Take accordingly.
     */
    
    dobjFor(Take)
    {
        action()
        {
            inherited;
            leaningAgainst = nil;
        }
    }
    
    /*  If the ladder is in position, make UP equivalent to STAND ON LADDER */
    
    beforeAction()
    {
        if(gActionIs(Up) && leaningAgainst != nil)
            replaceAction(StandOn, self);
    }
    
    /* 
     *   The purpose of the ladder is to enable the player character to 
     *   reach the bunk. We need to make sure we can touch the bunk (which 
     *   is outside us) when we're the staging location for the bunk. Here 
     *   we generalize the code to allow an actor inside us to touch 
     *   anything for which we are a staging location.
     */    
    
    allowReachOut(obj)
    {
        /* 
         *   Note that we can't be sure that the object we're trying to touch
         *   will have a stagingLocations property. By using the nilToList 
         *   function we avoid the run-time error that would otherwise occur 
         *   if we tried this test on a dest object for which 
         *   stagingLocations is nil.
         */
        return obj.stagingLocation == self;    
    }
    
;

/*  
 *   PUTTING SOMETHING OUT OF REACH
 *
 *   OutOfReach is a mix-in class which puts the object it's mixed in with, 
 *   together with that object's contents, out of reach (except under 
 *   conditions specified by the game author. It's not a NestedRoom class, 
 *   but it is convenient to demonstrate along with NestedRooms, not least 
 *   because an OutOfReach object will often be reached by standing on some 
 *   NestedRoom object, as here.
 *
 *   We'll use an OutOfReach to implement the bookshelf that's said to be 
 *   fixed high on the wall above the desk. The way to reach it will be by 
 *   standing on the desk.
 */


+ bookshelf: Surface, Fixture 
    'bookshelf; long wooden; shelf' 
    "It's a long wooden bookshelf, fixed far too high up on the wall for
    convenient access. "
    
    /* 
     *   Define the conditions under which this OutOfReach object can be 
     *   reached. obj is the object attempting the reaching -- typically an 
     *   actor. An actor can reach this shelf if s/he's standing on the 
     *   desk, so we need to test both that the obj is standing and that the 
     *   obj is on the desk, i.e. on the desk's subSurface.
     */
    checkReach(actor)
    {
        if(!actor.isIn(desk.remapOn))
            "You can't reach the shelf from there. ";
    }
        
;

/*  
 *   READABLE
 *
 *   To demonstrate OutOfReach fully we need to put something on the 
 *   bookshelf, and the obvious thing to put there is a book.
 */ 

++ book: Thing 'red book'
    "It's called <i>Life in Bedsitterland</i>. "
    readDesc = "You stop reading after a few pages. Of course the book relates
        someone else's experience of life in bedsitterland, but the prospect of
        the next few months turning out anything like that for you is just too
        depressing. "
        
    /*  
     *   One would normally hold a book in order to read it, and if we don't 
     *   enforce either objHeld or touchObj here, the player would be able to
     *   read the book without taking it off the shelf.
     */
    dobjFor(Read) { preCond = [objHeld] }
;


/*   
 *   CHAIR
 *
 *   So far all our examples of Nested Rooms have been NonPortable, but a 
 *   Nested Room can also be portable, as the following Chair object 
 *   demonstrates.
 */


+ Platform 'swivel chair; black swivel; furniture[pl] seating[pl]' 
    "It's black, and it swivels. "
    specialDesc = "A swivel chair has been placed right by the desk. "
    
    /*  
     *   Since it's described as a swivel chair we'd better allow the player 
     *   to turn it.
     */    
    dobjFor(Turn)
    {
        verify() {}
        action()
        {
            "You swivel the chair round a few times. How exciting! What fun! ";
        }
    }
    
    /* 
     *   A swivel chair might not be all that safe to stand on, so we'll 
     *   restrict the allowedPostures to sitting.
     */    
    canStandOnMe = nil
    canLieOnMe = nil
    
    cannotStandOnMsg = 'Since the swivel chair swivels so easily, it\'s not safe
        to stand on. '
;

/*  
 *   MAKING A NESTED ROOM TOO HIGH TOO REACH
 *
 *   We can created a NestedRoom that's regarded as being too high up to reach
 *   except via a special staging location (such as a ladder). The example here
 *   is a bunk high up on the east wall which can only be reached via the ladder
 *   once the ladder has been placed against the bunk.
 */

+ bunk: Platform, Fixture 'narrow bunk; hard; beds[pl]'     
    "It's quite narrow, and looks a bit hard, but at least it would allow you to
    have a visitor to stay. It's also quite high up the wall. "
    
    /* 
     *   Normally you could stand on a bed, but there's not enough headroom 
     *   above the bunk.
     */
    canStandOnMe = nil
    cannotStandOnMsg = 'There\'s not enough headroom to stand here. '
    
    /*  
     *   To reach a HighNestedRoom an actor has to be the appropriate staging
     *   location, so the stagingLocations property defines how the bunk 
     *   can be reached. Note that if we just defined stagingLocations = 
     *   [ladder], then GET ON BUNK would result in the player character 
     *   getting on the bunk via the ladder without further ado, and the 
     *   player would hardly notice that the bunk was tricky to get to. So 
     *   we define stagingLocations so that the ladder can only be used as a 
     *   staging location when it's in the right state (leaning against the 
     *   bunk).
     */
    stagingLocation = (ladder.leaningAgainst == self ? ladder : nil)
    
    checkReach(actor)
    {
        if(actor.location != stagingLocation)
            "The bunk is too high up to reach. ";
    }
    
    
    /*  
     *   In order to get the ladder into the right state the bunk must be a 
     *   possible target of a MoveTo command.
     */    
    iobjFor(MoveTo) 
    { 
        preCond = [objVisible]
        verify() {} 
    }
    
    

    
    lookUnderMsg = 'Beneath the bunk are a short wooden bench and a sleeping
        cat. '
;

+ Decoration 'north wall; (n)'
    "A narrow bunk has been fixed high up on the north wall, with a short wooden
    bench underneath. "
;


/* 
 *   CHAIR 
 *
 *   Since the bunk is high up on the wall, we may as well put something 
 *   underneath it.
 */

+ bench: Platform, Fixture 'bench; short wooden; chairs[pl] furniture [pl] 
    seating[pl]'     
    "Frankly, you're not sure what it's doing there; it looks neither
    comfortable nor decorative. Your best guess is that there was once a lower
    bunk that has long since been removed, and someone put the bench there to
    take up the space (and/or cover up a mark on the wall). "
    
    canSitOnMe = true
    canLieOnMe = true
    lieOnScore = 80
    
    cannotTakeMsg = 'It seems to be fixed firmly in place. '
    cannotStandOnMsg = 'There\'s not enough room to stand on the bench; you\'d
        bang your head on the bunk above. '
;


/*  
 *   CAT
 *
 *   Finally, the cat that's mentioned as sleeping under the bunk. Since it
 *   stays asleep during the course of the game its implentation can be fairly
 *   minimal.
 */

+ cat: Immovable 'cat; black tom sleeping; animal; him it'
    "It's a black cat, which currently looks profoundly asleep. "
    
    /*  
     *   Obviously it's possible to pick up a cat, so we'll customise the 
     *   cannotTakeMsg.
     */
    cannotTakeMsg = 'It would be kinder to let sleeping cats lie. '
    
    /*  
     *   By setting owner = me we ensure that the parser will recognize 'your
     *   cat' or 'my cat' as referring to the cat.
     */
    owner = me
    
    
    /*  
     *   We'll also have the cat referred to as 'your cat' rather than 'the 
     *   cat'
     */
    theName = 'your cat'
    
    /*   
     *   Throwing something at the cat would wake it up, which we don't want;
     *   also the default response for throwing things can look rather 
     *   ludicrous when the target is animate. So we'll override 
     *   iobjFor(ThrowAt) to disallow this, using the same failure message 
     *   as for take.
     */    
    iobjFor(ThrowAt)
    {
        check()
        {
            say(cannotTakeMsg);
        }
    }
    
    cannotAttackMsg = 'You\'d rather not; you\'re actually rather fond of your
        cat, and he\'s about the only friend you\'ve got round here. '
    
    specialDesc = "Your cat is asleep under the bunk. "
;


//==============================================================================
/* Modifying verb grammar */

/*   
 *   MOVE LADDER TO BUNK might not be the most obvious phrasing, so we'll add
 *   some alternative phrasings in a new VerbRule, but still assign them to 
 *   the MoveTo action.
 */


VerbRule(LeanAgainst)
    'lean' singleDobj ('on' | 'against') singleIobj |
    'put' singleDobj 'against' singleIobj
    : VerbProduction
    action = MoveTo
    verbPhrase = 'lean/leaning (what) (against what)'
    missingQ = 'what do you want to lean; what do you want to lean it against'
;

/*  
 *   Since we have an object called a swivel chair it seems likely that a 
 *   player might try to SWIVEL it, so we'll add 'swivel' to the standard 
 *   grammar for TurnAction.
 *
 *   Note the slightly unusual syntax for modifying a VerbRule, with the 
 *   colon after the grammar definition line. In this case the original 
 *   VerbRule(Turn) was copied and pasted from en_us.t and 'swivel' simply 
 *   added. 
 */         

modify VerbRule(Turn)
    ('turn' | 'twist' | 'rotate' | 'swivel') multiDobj
    :
;

/* 
 *   There's no particular reason why we modified VerbRule(Turn) and added a 
 *   new VerbRule(LeanAgainst), other than to illustrate both methods; but 
 *   the fact that just adding 'swivel' was a simpler change than the 
 *   additional grammar for MoveToAction helped determine that we did it 
 *   this way round.
 */


/*  
 *   There's a bed here, to the player might reasonably try to sleep. If the PC
 *   is not already on the bed when the command is issued, it makes sense to
 *   move him/her there with an implicit command first.
 */

modify Sleep
    execAction(cmd)
    {
        if(!me.isIn(bed))
        {
            tryImplicitAction(LieOn, bed);
            "<<buildImplicitActionAnnouncement(me.isIn(bed))>>";
        }
        "You drop off to sleep and dream of better times. You wake up again
        after an indeterminate period. ";
    }
;