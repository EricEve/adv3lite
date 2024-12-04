#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*
 *   SENSE & SENSIBILITY
 *
 *   A demonstration of Senses, SenseRegions, MultiLocs and the like.
 */

versionInfo: GameID
    IFID = '0c5628bc-e220-496d-ac6d-10dcadcb7015'
    name = 'Exercise 21 - Sense and Sensbility'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A demonstration of Senses, Multilocs and the like in adv3Lite.'
    htmlDesc = 'A demonstration of Senses, Multilocs and the like in adv3Lite.'
;

gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    showIntro()
    {
        "It looks a fine day now, but there have been several days of
        exceptionally heavy rain. The water is now pouring off the hills,
        swelling the river, and several severe flood warnings are in place.
        Your job is to make sure there's no one left in this part of town.\b";
    }
;

/*  
 *   CUSTOM SOUND EVENT CLASS
 *
 *   We define a custom SoundEvent class to allow certain objects to respond to
 *   'sound events' that are triggered in their hearing. An alternative would
 *   have been to use the SoundEvent class defined in the sensory.t extension,
 *   but here we show how to build one from scratch.
 */
class SoundEvent: object
    /* 
     *   Triggering a sound event causes the notifySoundEvent() method to be
     *   called on every object that can hear its source (provided in the obj
     *   parameter). Most objects don't define (our custom) notifySoundEvent()
     *   method, so this will mostly do nothing, but a couple of objects below
     *   do.     
     */
    triggerEvent(obj) 
    {
        /* Get a list of everything in obj's Room */
        local lst = obj.getOutermostRoom.allContents;
        
        /* Add all the items in rooms with an audio connection to obj's room */
        foreach(local rm in obj.getOutermostRoom.audibleRooms)
            lst = lst.appendUnique(rm.allContents);
        
        /* 
         *   Reduce the list to the subset of objects that can actually hear obj
         */
        lst = lst.subset({o: Q.canHear(o, obj)});
        
        /*   
         *   Call the notifySoundEvent event method on every item in our reduced
         *   list.
         */
        foreach(local cur in lst)
            cur.notifySoundEvent(self, obj);    
        
    }
;
/* 
 *   REGIONS
 *
 *   We define a couple of regions; an outdoorRegion to represent every room
 *   that's outdoors, and a squareRegion that's a SenseRegion containing every
 *   room in the square.
 */

outdoorRegion: Region
;

/*  
 *   SENSE REGION
 *
 *   A SenseRegion is a region with sensory connections between its rooms. The
 *   squareRegion is also in the outdoorRegion (all the rooms in the square are
 *   oudoors).
 */
squareRegion: SenseRegion
    regions = [outdoorRegion]
;

/*  
 *   We'll define a custom SquareRoom class to save ourselves a bit of 
 *   typing on each of the rooms representing the four corners of the square.
 */

class SquareRoom: Room
    /* 
     *   corner is a custom property. It will be used to hold a string saying
     *   which corner of the square this is: northeast, northwest, 
     *   southeast, or southwest.
     */
    corner = ''
    
    /*   
     *   We next use the custom corner property to construct the destName (a 
     *   standard library property) of this square).
     */
    vocab = ('the ' + corner + ' corner of the square')
      
    
    regions = [squareRegion]
;





//------------------------------------------------------------------------------
/*  
 *   We now create a square comprising four corners. These will be joined by 
 *   a SenseRegion (see below) so that the player character can see 
 *   from any part of the square into any other part.
 */

squareNW: SquareRoom 'Main Square (NW)'
    "This square is said to date from the fourteenth century, and from the state
    of the surrounding buildings you can well believe it. The square continues
    to south and east, with a large ornamental fountain at the centre of the
    square blocking the way diagonally across the square to the southeast.
    A long building runs along the north side of the square; its entrance is
    off to the east, though a small window overlooks this corner of the square.
    To the west lies the way into the park. "
    
    corner = 'northwest'
    south = squareSW
    east = squareNE
    west = parkS
    
    /*  
     *   Below we shall be defining a SenseConnector representing a window 
     *   between this room and a chamber in the building to the north. This 
     *   means that when the PC is in squareNW objects inside the chamber 
     *   will also be listed. To make it clear where they are and how the PC 
     *   can see them we want them to be listed specially, preceded by 
     *   "Through the window, you see...". We do this be overriding 
     *   remoteRoomContentsLister().
     */
    
    remoteContentsLister() 
    { 
        if(gPlayerChar.isIn(chamber))
            
            /*  
             *   CUSTOM ROOM LISTER
             *
             *   A lister that can be customized very simply by supplying two
             *   strings: a prefix string that comes before the list of 
             *   objects listed in the other location (here 'Through the 
             *   window you see') and a suffix string that comes after it 
             *   (here just a full-stop/period).
             */
            return new CustomRoomLister('Through the window, {i} {see}'); 
        else
            return inherited;
    } 
    
    regions = [squareRegion, windowRegion]
;

/* 
 *   The player character object. This doesn't have to be called me, but me is a
 *   convenient name. If you change it to something else, rememember to change
 *   gameMain.initialPlayerChar accordingly.
 */

+ me: Player'you'  
    "You're a young police officer. "    
;


+ Fixture 'building; old crumbling'
    "It's very old, and looks a bit crumbling, but it's been there quite a few
    centuries now and will probably be around for several centuries to come. 
    Immediately to the north a window looks out from the building over the
    square. "
;

//------------------------------------------------------------------------------

squareNE: SquareRoom 'Main Square (NE)'
    "From this corner of the square a door leading into the building to the
    north. The square continues to south and west, with the fountain at its
    centre lying to the southwest. "
    corner = 'northeast'
    south = squareSE
    west = squareNW
    
    north = doorOutside
;

+ Enterable 'building; grand'
    "The building runs along the entire north side of the square, and looks
    rather grand, in a slightly faded sort of way. The door into the building
    is just to the north. "
    
    connector = doorOutside
;

++ doorOutside: Door ->doorInside 'door;;entrance'
;

//------------------------------------------------------------------------------

squareSW: SquareRoom 'Main Square (SW)'
    "The main street out of the square runs off to the south from here. The
    square continues to north and east, with the fountain at its centre
    blocking the way northeast. "
        
    corner = 'southwest'
    north = squareNE
    east = squareSE
    south { "You can't leave until you make sure you've got everyone safely away
        from the area. "; 
    }
;

/*  
 *   TRAVEL PUSHABLE
 *
 *   A Travel Pushable is an object that can be pushed from one location to
 *   another but not picked up and carried. We make an ordinary object into a
 *   Travel Pushable by defining its canPushTravel property to be true.
 */
+ barrelOrgan: Heavy 'barrel organ; gaudy red'
    "It's painted a gaudy red and has a handle that can be turned to crank out
    a tune. "
    
    /* 
     *   A Heavy is would nor normally be listed in a room description, but
     *   since this one is moveable we'd like it to be, so we override isListed
     *   to make it so.
     */
    isListed = true
    
    
    canPushTravel = true    

    /* 
     *   By overriding this method we can customize the message used to announce
     *   the barrel organ's arrival in its new location.
     */
    describeMovePushable (connector, dest)
    {
        "The barrel organ slows to a halt. ";
    }
    
;

++ handle: Component 'handle' 
    dobjFor(Turn)
    {
        verify() { }
        action()
        {
            "You turn the handle of the barrel organ a few times; it cranks out
            a wheezy version of some Verdi aria. ";
            
            /* When the music plays, trigger the associated SoundEvent. */
            organEvent.triggerEvent(self);
        }
    }
;

/* This DOER turns PLAY ORGAN into TURN HANDLE */
Doer 'play barrelOrgan'
    execAction(c)
    {
        doInstead(Turn, handle);
    }
;

/* 
 *   The SoundEvent that's triggered by playing the organ. SoundEvent is a
 *   custom class we defined above.
 */
organEvent: SoundEvent;

//------------------------------------------------------------------------------
squareSE: SquareRoom 'Main Square (SE)'
    "A long wooden bench stands in the southeast corner of the square, for the
    benefit of those who want to rest their legs. The square continues to north
    and west, but direct access to the northwest corner from here is blocked by
    the fountain at the centre of the square. "
    corner = 'southeast'
    north = squareNE
    west = squareSW    
;

+ bench: Platform, Heavy 'bench;long weathered wooden'
    "It looks well weathered, and you vaguely recall it was placed there in
    memory of some local worthy at the beginning of the last century. "
    bulkCapacity = 30
      
;

/*   
 *   ACTOR 
 *
 */
++ oldLady: Actor 'old lady; wizzened; woman someone person; her'     
    "She looks rather wizzened. You wonder if she's as old as the bench she's
    sitting on. "
    
    
    /*  
     *   The notifySoundEvent method is where we put the code defining the old
     *   lady's response to a SoundEvent.
     */
    notifySoundEvent(event, source) 
    { 
        /*  
         *   We'll make the old lady's response differ according to whether 
         *   the source of hand is close by or in a different corner of the 
         *   square.
         */
        if(source.isIn(getOutermostRoom))
            /* 
             *   There are a number of different soundEvents in the game, 
             *   and we'd like them to provoke different responses. We could 
             *   do this with a series of if statements or a switch 
             *   statement here, but it's neater and more in common with 
             *   TADS 3 programming style to farm actor responses out to 
             *   TopicEntry objects as possible, and we can do that by 
             *   calling initiateTopic here and defining the different 
             *   responses on a series of InitiateTopics.
             */
            initiateTopic(event);
           
        else
        {
          "<.p>The woman starts, wakes up momentarily, looking confused, then
          settles down to snooze again. ";
        }
    }
    uselessToAttackMsg = 'You\'ll be dismissed from the force and lose your
        pension if you start attacking old ladies. '
    
    /* 
     *   Override the normal handling of greeting an Actot to have this old lady ignore the player
     *   character.
     */
    sayHello = "The old lady remains profoundly asleep. "
;

/*   
 *   ACTOR STATE
 *
 *   We could almost use a HermitActorState here, except that we want the 
 *   InitiateTopics to work.
 */

+++ ActorState
    /*  The old lady starts out in this ActorState. */
    isInitState = true
    
    /*  This will be appended to her description. */
    stateDesc = "She looks profoundly asleep. "
    
    /*  
     *   This is how she will be listed in a room description when the player
     *   character is in the same room as her.
     */
    specialDesc = "An old lady is snoozing on the bench.<.reveal lady> "
    
    /*   
     *   This is how she will be listed in a room description when the PC is 
     *   in a different part of the square.
     */
    remoteSpecialDesc(actor) 
    { 
        /*  
         *   When the PC first sees the old lady from a distance, it's not 
         *   clear who or what she is, so we just describe her as 'someone'. 
         *   Once the PC has seen the old lady close too, it'll be apparent 
         *   even from a distance that she's still the same old lady, so 
         *   we'll switch to calling her that.
         */        
        "<<gRevealed('lady') ? 'The old lady' : 'Someone'>> is sitting on the
        bench in the southeast corner of the square. "; 
    }
    
;

/*   
 *   INITIATE TOPIC
 *
 *   An InitiateTopic is executed in response to calling initateTopic() on 
 *   the actor. In this game we're doing that in response to SoundEvents.
 */
++++ InitiateTopic @whistleEvent
    "<.p>The old woman opens her eyes and covers her ears. Giving you a furious
    stare she snaps, <q>Do stop that <i>terrible</i> noise, officer! Can\'t
    you see I\'m trying to sleep?</q> Without waiting for a reply, she dozes
    off again. "
;

++++ InitiateTopic @yellEvent
    "<.p>The old lady wakes with a start and glares at you fiercely. <q>There's
    no need to shout!</q> she tells you, <q>It's quite unnecessary! When I was a
    girl, young people used to treat their elders with respect!</q>\b
    Her rebuke delivered, she dozes off agains traight away. "
;    


/*  
 *   Playing the trumpet in the presence of the old lady finally succeeds in 
 *   getting her attention, and so wins the game.
 */
++++ InitiateTopic @trumpetEvent
    topicResponse()
    {
        "<.p>The old woman wakes up with a start and springs smartly to
        attention. Now that you have her attention you explain about the
        imminent flooding, and the two of you leave the square together.<.p>";
        finishGameMsg(ftVictory, [finishOptionUndo]);
    }
;

/*  
 *   CATCH-ALL INITIATE TOPIC 
 *
 *   We use this Catch-all InitiateTopic to deal with any SoundEvent for which 
 *   we haven't defined an InitiateTopic above.
 */

++++ InitiateTopic +80 @SoundEvent
    "<.p>The old woman wakes up and throws you a baleful glance. <q>Can't you
    let an old woman sleep?</q> she complains. Without waiting for a reply, she
    leans back, closes her eyes, and dozes straight off again. "
;

/*   
 *   DEFAULT ANY TOPIC
 *
 *   We use this DefaultAnyTopic to provide a response to any conversational 
 *   command addressed to the old lady.
 */
++++ DefaultAnyTopic
    "She ignores you, preferring to snooze on. "
;

/*  
 *   MULTILOC
 *
 *   The fountain stands at the centre of the square, and is thus equally 
 *   accessible from all four corners. We can represent this by making the 
 *   fountain a MultiLoc (which must be mixed-in with one or more 
 *   Thing-derived classes in order to represent a physical object) and 
 *   locating it in all four corners of the square.
 */
fountain: MultiLoc, Container, Fixture 'fountain; stone; figure pool' 
    "Whatever the stone figure originally was at the centre of the fountain, it
    has long since been worn unrecognizable by the water constantly pouring from
    it into the pool. "   
    locationList = [squareRegion]
    
    listenDesc = "A gentle tinkling sound comes from the fountain. "
;

/*  
 *   Note that while this coin is in the fountain it can be taken from any 
 *   corner of the square.
 */
+ coin: Thing 'copper coin; old ; penny' 
    "It's just an old penny. "
    
    sightSize = small
;

/*  
 *   SIMPLE NOISE
 *
 *   The sound of the fountain doesn't need to be described different under 
 *   different circumstances, so we can use a SimpleNoise to represent it.
 */
+ Noise 'tinkling; gentle; sound' 
    "It's the gentle sound of running water. "
;

+ Decoration 'water; running' 
    "It's pretty transparent, and undoubtedly wet. "
    notImportantMsg = 'You\'re happy to leave the water alone. '
;


/*  
 *   MULTILOC, DISTANT
 *
 *   We can also use a MultiLoc to represent a distant object that can be 
 *   seen (and looks much the same) from a number of different locations. 
 *   One obvious example would be the sun, which should be visible from 
 *   every outdoor location.
 */
MultiLoc, Distant 'sun; bright shining'
    "The sun is shining bright today -- far too bright to look at directly. "
    
    /*  
     *   Rather than listing each OutdoorRoom, we can simply specify that 
     *   the sun should appear in every OutdoorRoom.
     */
    locationList = [outdoorRegion]
;

//------------------------------------------------------------------------------

hall: Room 'Hall'
    "This hall is almost empty; whoever lives here has obviously taken the
    precaution of packing everything away and putting it in safe storage in
    anticipation of the flood. A door leads out to the south, and a second exit
    leads west. "
    south = doorInside
    west = chamber
    out asExit(south)
;

+ doorInside: Door ->doorOutside 'door' 
;

+ ladder: Platform 'ladder; long wooden sturdy'
    "It's quite long, and looks reasonably sturdy. "
    initSpecialDesc = "A long wooden ladder leans against the wall. "
    dobjFor(Climb) asDobjFor(Board)
    dobjFor(ClimpUp) asDobjFor(Board)
    dobjFor(ClimbDown) asDobjFor(GetOff)
    bulk = 8
    
    /*  
     *   You can't lie down on a ladder, and you wouldn't normally think of 
     *   sitting on one.
     */
    canLieOnMe = nil
    sitOnScore = 70
;

//------------------------------------------------------------------------------

/* 
 *   ANOTHER SENSE REGION
 *
 *   We define another SenseRegion to represent the SensoryConnection between
 *   the rooms on either side of the window.
 */

windowRegion: SenseRegion
    
    
;

/*  
 *   WINDOW
 *
 *   Both squareNW and chamber mention a window - the same window, in fact, 
 *   seen from different sides. 
 *
 *   One can often open and close windows, so we should make it openable 
 *   too.
 */


window: MultiLoc, Fixture 'window; small'
    "It's <<if isOpen>>open, but it's too small to climb through<<else>>
    closed<<end>>. "
    
    isOpenable = true
    
    locationList = [windowRegion]
    
    
    /*  
     *   One obviously ought to be able to Look Through a window, but we 
     *   need to define handling for this specially.
     */         
    dobjFor(LookThrough)
    {
        action()
        {
            /* 
             *   First print some introductory text depending on the 
             *   location of the actor who's doing the looking.
             */
            "You look <<gActor.isIn(chamber) ? 'out' : 'in'>> through the
            window and see <<gActor.isIn(chamber) ? 'the square' : 'a
                chamber'>>";
            
            /*   
             *   Then list the objects that can be seen through the window 
             *   from the point of view of the actor. Here we do this by 
             *   constructing a list of listable objects.
             */
            
            local other = gActor.isIn(chamber) ? squareNW : chamber;
            
            local lst = other.contents.subset({o: o.isListed});
            if(lst.length > 0)
                ", in which you can see <<makeListStr(lst)>>";
            
            ".\b";
        }
    }
    
        
    cannotGoThroughMsg = 'The window is not big enough for you to fit through. '
    cannotEnterMsg = (cannotGoThroughMsg)
;



//------------------------------------------------------------------------------

chamber: Room 'Chamber'
    "This chamber is almost as bare as the hall, and presumably for much the
    same reasons; just about everything has been safely packed away elsewhere in
    case of flooding. From the shape and size of the room and the style of the
    wallpaper you'd guess that in normal times it might be a sitting-room. A
    window overlooks the square to the north, but the only way out is to the
    east. "
    east = hall
    out asExit(east)
    
    regions = [windowRegion]
    
    inRoomName(pov)
    {
        if(pov.isIn(squareNW))
            return 'through the window';
        else
            return inherited(pov);
    }
    
    /* 
     *   We have put the chamber and the northwest corner of the square in a
     *   common SenseRegion, since they're connected by a window, but we only
     *   want sound to pass through the window when the window is open. To
     *   enforce this we can use the canHearOutTo() method of the hall, so that
     *   it returns true only when the window is open. By default this will mean
     *   that canHearInFrom(loc) on the hall will follow the same condition.
     *   Note that these methods can only be used to impose additional
     *   restrictions on sense passing - they can't be used to provide sensory
     *   connections that aren't already provided by a SenseRegion.
     */
    canHearOutTo(loc)
    {
        return window.isOpen;
    }
    
    /* Logically it makes sense that a closed window would block smells too. */
    canSmellOutTo(loc) { return window.isOpen; }
;

+ Decoration 'wallpaper; green striped'
    "It's striped, in alternativing shades of green. "
;

+ OpenableContainer 'large wooden box; packing; case'
    "It might be a packing case of some sort. "
    /*  
     *   By specifying that the box is made of 'paper' we allow sounds and 
     *   smells (but not sight or touch) to pass through it even when it's 
     *   closed. This means that we can hear the radio (when it's on) even 
     *   when it's shut in the box.
     */
    
    bulkCapacity = 4
;

/*  
 *   SWITCH
 *
 *   A Switch is something that can be switched on and off. Here we use it to
 *   implement a radio that makes a noise only when it's turned on.
 */
++ radio: Switch 'radio' 
    isOn = true
    makeOn(stat)
    {
        inherited(stat);
        if(stat)
        {
            "Turning on the radio makes a sudden burst of loud music pour forth.
            ";
            /* 
             *   When the radio is turned on, trigger a SoundEvent to 
             *   represent the sudden incidence of a loud noise that wasn't 
             *   there before.
             */
            musicEvent.triggerEvent(radio);
        }
        else
            "The radio falls silent. ";
    }
    
    listenDesc = "<<if isOn>><<if Q.canSee(gPlayerChar, self)>>The radio is
        playing loud music. <<else>>There's some loud music playing. <<end>>
        <<else>>The radio is quite silent. <<end>>"
   
    soundSize = large
    
    /* 
     *   Don't mention our listenDesc in response to a LISTEN command unless
     *   we're on
     */
    isProminentNoise = isOn
    

;

/*  
 *   NOISE
 *
 *   We can create a Noise object to represent the sound the radio makes when
 *   it's turned on. Note the distinction between this Noise (which represents
 *   the ongoing Sensory Emanation that occurs for as long as the radio is on)
 *   and the musicEvent SensoryEvent which represents the event of the radio
 *   being turned on (a continuously playing radio might fade into the
 *   background of our consciousness; a radio suddenly turned on is likely to
 *   burst in on our consciousness; the Noise represents the former and the
 *   SoundEvent the latter.
 *
 *   Note that it would probably have been easier to do this by using the
 *   definition of Noise provided in the sensory.t extension (which does quite a
 *   bit of the work for us), but here we're sticking to features provided in
 *   the main library.
 */
+++ Noise '() music; loud operatic; sound noise wagner'
    "<<if Q.canSee(gPlayerChar, self)>> <<descWithSource>> <<else>>
    <<descWithoutSource>> <<end>>"
    
    /*  The noise is only audible when the radio is turned on. */
    isEmanating = (radio.isOn)
    
    isHidden = !isEmanating
    
    /*  The response to LISTEN TO MUSIC when we can see the radio. */
    descWithSource = "The radio is playing something loud and operatic -- Wagner
        perhaps. "
    
    /*  The response to LISTEN TO MUSIC when we can't see the radio. */
    descWithoutSource = "The music sounds loud and operatic -- Wagner
        perhaps. "
    
   
;

+ whistle: Instrument 'whistle; silver'
    "It's silver in colour, a bit like a policeman's whistle. "
    
    /*  
     *   The following two properties are custom properties we define on our 
     *   custom Instrument class, for which see below. Since there are two 
     *   musical instruments in the game -- this whistle and a trumpet -- we 
     *   can save ourselves some work by defining a new class to implement 
     *   their common behaviour and then just customizing individual 
     *   Instruments with these two properties. 
     *
     *   When the whistle is blown, whistleEvent will be triggered, and the 
     *   message "You bloe a shrill blast on the whistle" displayed.
     */
    soundEvent = whistleEvent
    playDesc = 'You blow a shrill blast on the whistle. '
;

/*  The two SoundEvents referred to above. */

musicEvent: SoundEvent;
whistleEvent: SoundEvent;

//------------------------------------------------------------------------------
/*  
 *   REGION
 *
 *   We're about to implement a park comprising two locations, so we'll 
 *   start by joining them together with a DistanceConnector, so that we can 
 *   see from one end of the park into the other. 
 */

parkRegion: SenseRegion
    regions = [outdoorRegion]
;


parkS: Room 'Park (South)'
     "The park occupies a large area, peppered with trees, shrubs and bushes.
     An abandonded bonfire is smouldering down by the swollen river. The park
     continues to the north, and the way back to the square lies eastwards. "
    east = squareNW
    north = parkN
    
    /*  
     *   The phrase to use to describe the location of objects left here when
     *   viewed from the other end of the park.
     */
    inRoomName(pov) { return 'in the south end of the Park'; }
    
    regions = [parkRegion]
;

+ Fixture 'bonfire; smouldering bonfire; fire'
    "It's still smouldering nicely, giving off lots of smoke. But it won't be
    for much longer if the river bursts its banks. "
    feelDesc = "It feels hot. "
;

/*  
 *   A DECORATION USED TO REPRESENT SMOKE
 *
 *   Smoke is only marginally tangible, but for our purposes it can be quite 
 *   adequately represented by a Decoration. 
 */
++ Decoration 'smoke; billowing thick'
    "Thick smoke is billowing up from the smouldering fire. "
    
    /* We don't want the parser referring to 'a smoke' or even 'some smoke' */
    aName = (name)
    
    /*  The smoke should be clearly visible from a distance. */
    sightSize = large
    smellSize = large
    
    decorationActions = [Examine, SmellSomething]
    
    smellDesc = "The acrid smell of smoke wafts from the bonfire down by the 
        river. "
    
    notImportantMsg = '{I} {can\'t} do that to smoke. '
;

/*  
 *   ODOR
 *
 *   We use the same description for the smell of the as for the smoke itself.
 *   The Odor object is used to represent the smell as opposed to the object
 *   emitting the smell, but in the case of smoke that's arguably a distinction
 *   scarcely worth making. Still, we'll use an Odor object here to provide
 *   another example of its use.
 */
+++ Odor 'smell; acrid'
    desc = location.smellDesc
    
    
    /* The smell should be quite apparent at a distance. */
    smellSize = large
    
;

//------------------------------------------------------------------------------


parkN: Room 'Park (North)' 'north end of the park'
    "The park occupies a large area, peppered with trees, shrubs and bushes,
    bounded by the swollen river to the west. The park continues to the south. "
    
    south = parkS
    
    /*  
     *   The phrase to use to describe the location of objects left here when
     *   viewed from the other end of the park.
     */
    inRoomName(pov) { return 'in the north end of the Park'; }
    
    regions = [parkRegion]
;

+ Fixture 'elm tree; tall' 
    "The elm tree is really quite tall. Its lowest branch is a bit too high for you to reach
    unaided. "
    sightSize = large
;


/*  
 *   PUTTING SOMETHING OUT OF REACH
 *
 *   We don't want the player character to be able to reach the trumpet without
 *   the ladder, so we can put it out of reach using the checkReach() method of
 *   the branch, which also restricts access to the contents of the branch.
 */
+ Fixture, Surface 'branch; lowest' 
    "It's about half way up the tree. " 
    
    
    /*  
     *   The PC can only reach this branch if s/he's standing on the 
     *   ladder.
     */
    checkReach(obj)
    {
        /* 
         *   Note that the checkReach method only needs to display some text to
         *   prevent reaching the object, so we use the method to explain why
         *   the branch can't be reached if the actor isn't on the ladder.
         */
        if(!obj.isIn(ladder))
            "The branch is too high up to reach. ";
    }
    
    /* 
     *   We won't allow anything other than the trumpet to be put on the 
     *   branch.
     */
    notifyInsert(obj)
    {
        if(obj != trumpet)
        {
            gMessageParams(obj);
            "{I} {can\'t} put {the obj} on the branch. ";
            exit;
        }        
    }
;

/*  
 *   The trumpet is the second instrument in the game. Once again we'll use 
 *   our custom Instrument class (defined below).
 */
++ trumpet: Instrument 'trumpet; brass; object instrument' 
    "<<if moved>>Despite its sojourn up an elm tree, it looks in perfectly good
    working order. <<else>> It's a strange place for a trumpet, perhaps someone
    left it there for a prank, or perhaps someone felt a strange urge to play
    their trumpet halfway up an elm tree.<<end>> "
    
  
    /*  
     *   The initial (until moved) description of the trumpet in a room 
     *   description when it's viewed from a remote location (the other end 
     *   of the park).
     */
    remoteInitSpecialDesc (actor)
    {
        "The sun glints off a brass object somewhere up a tree in the north end
        of the park. ";
    }
    initSpecialDesc = "For some reason, there's a trumpet hanging from a branch
        half-way up the elm tree. "
    
    /*  The sound event that's triggered when the trumpet is played. */
    soundEvent = trumpetEvent
    
    /*  The text that's displayed when the trumpet is played. */
    playDesc = 'You blast out a stirring rendition of the National Anthem. '
;

+ basket: OpenableContainer 'small wicker basket'
    "It looks like the sort of basket that might be used by a fisherman. "
    

    bulkCapacity = 2
    initSpecialDesc = "A small wicker basket lies abandoned by the river. "
    
    /*  
     *   Another way of specifying how the basket should be listed in a room 
     *   description when viewed from afar.
     */
    remoteInitSpecialDesc(pov)
    { 
        "Through the trees and shrubs you can just make out        
        a basket sitting by the river in the far end of the park. ";
    }
    
    /*  
     *   We wan't to be able to smell the fish even when the basket is closed,
     *   on the basis that the smell of rotting fish would probably manage to
     *   seep through the weave of the basket. We can do that by setting its
     *   canSmellIn property to true. There's also a canSmellOut property, but
     *   we don't need it here since the player character will never be inside
     *   the basket.
     */
    canSmellIn = true
;


/* Something smelly in the basket */
++ fish: Thing 'rotting fish;; herring'
    "It's hard to tell what it was -- a herring perhaps (possibly a red one). "
    cannotEatMsg = 'It looks far too far gone to be edible. '
    tasteDesc = "<<cannotEatMsg>>"
    
    smellDesc = "<<if gPlayerChar.canSee(self)>>A terrible rotting smell comes
        from the fish. <<else>>There's a terrible smell of something rotting.
        <<end>> " 
;

/*  
 *   ODOR
 *
 *   We use an Odor object to represent the smell of the fish. This object can
 *   describe the smell of the fish in a number of ways, as illustrated below.
 *
 *   Once again, we could have saved ourselves a little bit of work here by
 *   using the Odor class defined in the sensory.t extension, which already
 *   implements the descWithSource/descWithoutSource distinction in its
 *   definition of the desc property.
 */

+++ Odor 'terrible rotting smell; ; stink stench'
    "<<if gPlayerChar.canSee(fish)>><<descWithSource>> <<else>>
    <<descWithoutSource>> <<end>> "
    
    
    /* The response to SMELL STENCH when we can see the fish */
    descWithSource = "It's the now quite unmistakeable smell of rotting fish. "
    
    /* The response to SMELL STENCH when we can't see the fish */
    descWithoutSource = "It's a truly horrible smell; something rotting -- a
        fish perhaps. "
    
    
    /* As horrible as the smell is, we probably can't smell it at a distance */
    smellSize = small
    
    
;

/*  The SoundEvent associaated with playing the trumpet. */

trumpetEvent: SoundEvent
;

//------------------------------------------------------------------------------
/*  
 *   MULTILOC
 *
 *   A MultiFaceted object is one that runs through several locations, such 
 *   as this river that runs along the west side of the park. Whereas the 
 *   MultiLoc statue in the square was one physical object in one location 
 *   accessible from all four corners of the square (because it lay on their 
 *   joint boundaries at the centre of the square, in the case of the river 
 *   we have two segments of the same object (the river) that are 
 *   nevertheless physically distinct.
 */

MultiLoc, Fixture 'river; fast flowing; bank water'   
    "The river running along the west side of the park is flowing much faster
    than usual, and looks exceptionally high; it could burst its banks at any
    moment. "
    locationList = [parkRegion]  
;

/*  
 *   MULTILOC DECORATION 
 */

MultiLoc, Decoration 'trees, shrubs and bushes;;; them'
    "A variety of trees, shrubs and bushes have been tastefully distributed
    around the park, and carefully tended over the years. You only hope that
    they won't be damaged by the flood waters if and when the river bursts
    its banks. "
    
    locationList = [parkRegion]
    
    /*  
     *   The response we get from the trees if a SoundEvent is triggered in
     *   their vicinity.
     */
    notifySoundEvent(event, source) 
    {
        "The sudden noise makes a flock of birds take flight and flutter
        away from the trees. ";
    }
    
;

//==============================================================================

/*  
 *   We've defined a couple of Musical Instruments, now we need to define a 
 *   custom Play action so they can be played or blown.
 */
DefineTAction(Play)
;

VerbRule(Play)
    ('play' | 'blow') singleDobj
    : VerbProduction
    action = Play
    verbRule = 'play/playing (what)'
    missingQ = 'what do you want to play'
;


/*  We need to ensure that there's handling for the PlayAction on Thing. */
modify Thing
    dobjFor(Play)
    {
        preCond = [touchObj]
        verify() { illogical('I} can\'t play {that dobj}. '); }
    }
;


/*  
 *   Finally, we define our custom Instrument class, so that it knows how to 
 *   handle a Play command.
 */
class Instrument: Thing
    dobjFor(Play)
    {
        /* We need to hold a wind instrument in order to play it. */
        preCond = [objHeld]
        verify() {}
        action()
        {
            /* Display the custom playDesc property. */
            say(playDesc);
            
            /* trigger the SoundEvent associated with this instrument. */
            if(soundEvent)
                soundEvent.triggerEvent(self);
        }
    }
    
    /*  The SoundEvent associated with this instrument. */
    soundEvent = nil
    
    /*  The description of this instrument being played. */
    playDesc = nil     
;

/*  
 *   Yelling also makes a noise, so we'll associate a SoundEvent with that too.
 */

modify Yell
    execAction(cmd)
    {
        inherited(cmd);
        yellEvent.triggerEvent(gActor);
    }
;

yellEvent: SoundEvent;

