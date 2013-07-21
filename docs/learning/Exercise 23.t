#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*   
 *   EXERCISE 23 - AN EVENTFUL WALK
 *
 *   This game is a demonstration of the various EventList classes in TADS.
 *
 *   It also demonstrates Scenes, Menus, Hints and Scoring (which, after all,
 *   have to be demonstrated in conjunction with something.
 *
 *   There are several methods of scoring in TADS 3. Here we'll demonstrate only
 *   the that which uses Achievement objects to keep track of the score, calling
 *   their awardPointsOnce method. This allows the game to calculate the maximum
 *   score automatically for us.
 */




versionInfo: GameID
    IFID = '4de6c2e8-342b-471b-aeb8-c6960e0c801b'
    name = 'Exercise 23 - An Eventful Walk'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A demonstration of adv3Lite Scenes, EventList classes, menus, hints
        and scoring. '
    htmlDesc = 'A demonstration of adv3Lite Scenes, EventList classes, menus,
        hints and scoring. '
    
    
    /* This method will be run in response to an ABOUT command. */
    showAbout()
    {
        /* Display our help menu (defined below). */
        helpMenu.display();
        "Done. ";
    }
    
    /* This method is run in response to a CREDITS command. */
    showCredit()
    {
        "<i><<name>></i> <<htmlByline>>.\b
        adv3Lite library by Eric Eve.\b
        TADS 3 Language and Library by Michael J. Roberts.\b
         ";
    }
;

gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    
    showIntro()
    {
        /* 
         *   Show the introductory text. On an HTML interpreter (like 
         *   HTML-TADS for Windows) the aHref() definition towards the end 
         *   will result in the player seeing a clickable link labelled 
         *   ABOUT which s/he can click on to execute the ABOUT command.
         */        
        "It was to be a pleasant afternoon's walk, then back to the car and a
        short drive back home in time for tea.\b
        Except that now you're having a hard time <i>finding</i> you way back
        to to your car.\b
        (First-time players might like to type <<aHref('ABOUT','ABOUT', 'Show
            the about menu')>>)\b ";
    }
    
    /*  
     *   The setAboutBox() is method to set up an About Box that will be 
     *   displayed in response to selecting Help -> About from the HTML-TADS 
     *   Interpreter. The text to be displayed must appear between <ABOUTBOX>
     *   and </ABOUTBOX> tags. The following is a plain vanilla definition 
     *   that would do for any game, since it picks up all its information 
     *   from versionInfo.
     */    
    setAboutBox()
    {
        "<ABOUTBOX><CENTER>
        <<versionInfo.name>>\b
        <<versionInfo.byline>>\b
        Version <<versionInfo.version>>
        </CENTER></ABOUTBOX>";
    }
;


/* The starting location; this can be called anything you like */

startroom: Room, ShuffledEventList 'Deep in the Forest'    
    "You are at a junction of three paths in the depths of the forest: one leads
    west, one leads northeast, and one leads southeast. "
    
    northeast = byStream
    southeast = clearing
    
    /*  
     *   STOP EVENT LIST      DEAD END CONNECTOR
     *
     *   A StopEventList displays (or executes) each of its elements in turn
     *   till it reaches the last one, which it will then just repeat. If we
     *   make a TravelConnetor also an EventList and don't define a
     *   destinationfor it , then the items in the eventList will be used each
     *   time the PC attempts to traverses the connector without actually going
     *   anywhere.
     *
     *   We could also have defined destination = startroom to simulate the
     *   player character wandering down the path and returning to his starting
     *   point.
     */    
    west: TravelConnector, StopEventList {
    [
        /*  
         *   We are not restricted to putting just strings in an EventList. 
         *   Various other things, including function pointers can go there 
         *   too. Calling new function {} returns a pointer to the new 
         *   function so defined, so we can use this syntax to define a 
         *   function containing any code we like to execute as an item in 
         *   the list.
         */
        new function {
            "You walk a long way down the path until you find your way blocked
            by a fallen tree. Finding no way round it, you are forced to turn
            round and come back, but not before you retrieve a small branch
            that had broken off the tree. ";
            branch.moveInto(me);
            
            /* 
             *   Award some points (well, only one point as it turns out) for
             *   finding the branch.
             */
            achievement.awardPointsOnce();
        },
        
        'When you walk back down the back, the tree is still there, and you
        find nothing more of use, so you\'re forced to return again. ',
        
        'Yes -- that fallen tree is still blocking the path. '
    ]
        
        
        /*  
         *   This is a custom property, which we could have called anything 
         *   we liked. Calling it achievement, however, usefully reflects its
         *   purpose. We could have created a set of separate Achievement 
         *   objects to keep score, but it's often quite convenient to make 
         *   them nested anonymous objects associated with the object that 
         *   awards the points, as here. 
         *
         *   The two items in the template are the number of points to award 
         *   and the description of the achievement that led to the awarding 
         *   of the points.
         */
        achievement: Achievement { +1 "finding the branch" }
        
        
    }
    
    
    /*  
     *   SHUFFLED EVENT LIST
     *
     *   A ShuffledEventList (which this Room also is) is typically used to
     *   display a random series of messages. Each message is displayed once
     *   before any is used again, and no message will be seen twice in
     *   succession.
     *
     *   Making a Room also a ShuffledEventList and defining its eventLis
     *   property provides a randomly ordered list of atmospheric messages; this
     *   is one typical use of a ShuffledEventList.
     */
    eventList = 
    [
        'Somewhere off in the forest you hear the cry of a crow. ',
        'A pair of rabbits hop across your path and vanish into the trees. ',
        'A fox dashes across your path. ',
        'You hear the flap of wings as a flock of birds takes flight. ',
        'There\'s a momentary rustle in the undergrowth off among the trees. '
    ]
    /* 
     *   These messages would quickly become tiresome if one was displayed on
     *   every turn, so we start by showing them only 80% of the time, and then
     *   drop the frequency to 40% after every message has been displayed once.
     */
    eventPercent = 80
    eventReduceTo = 40
    eventReduceAfter = static eventList.length()
    
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


++ Wearable 'walking clothes; durable old;; them'
    "More durable than smart, they're just some old clothes you go walking in. "
    dobjFor(Doff)
    {
        check()
        {
            /* We don't actually want to allow the removing of these clothes. */
            "This is no time for stripping off. ";
        }
    }
    wornBy = me
;

+ Decoration 'trees;; tree forest; them it'
    "There are trees all around you. "
    
;

/*  
 *   Several locations will mention paths running off in various directions. 
 *   To avoid repetitive typing, we define a custom Path class (immediately 
 *   following this object) so we can define Paths just by setting a couple 
 *   of properties.
 */
+ Path
    /*  
     *   dir1 and dir2 are custom properties defined on the custom Path 
     *   class, for which see immediately below.
     */
    dir1 = 'northeast, southeast'
    dir2 = 'west'
;

/*  
 *   Path is a custom class we define to represent the various paths 
 *   mentioned in four of the locations in the game. It's basically a kind 
 *   of Decoration.
 */
class Path: Decoration 'path;;;it them'
    /* 
     *   Provide a generic description which will be automatically 
     *   customised from the dir1 and dir2 properties.
     */
    "Paths head from here to <<dir1>> and <<dir2>>. "
    
    /*   
     *   Define a custom notImportantMsg (used for all actions except EXAMINE
     *   and the two we define below), which will automatically be 
     *   customised with the text from the dir1 and dir2 properties.
     */
    notImportantMsg = ('The only thing you can usefully do with the paths is to
        walk down one of them, by going either ' + dir1 + ' or ' + dir2 + '. ')
    
    
    /*   
     *   One might reasonably try to FOLLOW a path, so we provide custom 
     *   handling for this.
     */
    dobjFor(Follow)
    {
        verify() {}
        action()
        {
            /* 
             *   Turn FOLLOW PATH into a question asking which way the PC 
             *   should go.
             */
            "Which way to do you want to go: <<dir1>> or <<dir2>>? ";
        }
    }
       
    
    /*   
     *   To customize individual Path objects we just need to override the 
     *   custom (non library) dir1 and dir2 properties. Both properties 
     *   should be set to single-quoted strings: dir2 should describe the 
     *   final direction to be shown in any list, and dir1 should list all 
     *   the other directions. So if a location has paths running east, west 
     *   and south, you would set dir1 to 'east, west' and dir2 to 'south'. 
     *   If there paths running in only two directions, e.g. southeast and 
     *   southwest, just put one direction in each property, e.g. dir1 = 
     *   'southeast' and dir2 = 'southwest'.
     */
    dir1 = nil
    dir2 = nil
;

/*  
 *   TAKE PATH is equivalent to FOLLOW PATH, but only if the phrasing TAKE PATH
 *   is used; PICK UP PATH or GET PATH wouldn't mean the same thing.
 */
Doer 'take Path'
    execAction(c)
    {
        doInstead(Follow, gDobj);
    }
    strict = true
;

/*  
 *   The PC picks up this branch on going west from the starting location 
 *   for the first time. It's purpose is to act as a torch to explore inside 
 *   the dark cave, so we make it of kind Candle so it can be lit and will 
 *   continue to burn.
 */

branch: Thing 'small branch;; twigs foliage'
    "The branch about three feet long, ending in a mass of twigs and foliage. "
    
    /* It starts unlit */
    isLit = nil
        
    /* We can burn (i.e. set light to) it */
    isBurnable = true
    
    
    /* 
     *   If we just issue the command BURN BRANCH, then we'll have the game
     *   either ask the player what s/he wants to burn it with, or, if there's
     *   one best choice of indirect object in scope, have the parser select it
     *   automatically (so that BURN BRANCH in the presence of the fire will be
     *   treated as BURN BRANCH WITH FIRE)
     */
    dobjFor(Burn)
    {
        action() { askForIobj(BurnWith); }
    }
    
    /* Make LIGHT BRANCH behave the same as BURN BRANCH */
    dobjFor(Light) asDobjFor(Burn)
    
    dobjFor(BurnWith)
    {
        verify()
        {
            if(isLit)
                illogicalNow('The branch is already alight. ');
            
        }
        
        action()
        {
            makeLit(true);
        }
    }
    
    
    
    makeLit(stat)
    {
        inherited(stat);
        /* When it's lit, award some points for lighting it. */
        if(stat)
            achievement.awardPointsOnce();
    }
    
    achievement: Achievement { +1 "setting light to the branch" }
;


//------------------------------------------------------------------------------

byStream: Room, RandomEventList 'By the River' 'the riverbank'
    "A wide river, swolled by recent heavy rain, blocks the way north. Heavy
    undergrowth growing along the bank would make it difficult to follow the
    course of the river to either east or west, but there are paths leading off
    to both southeast and southwest. "
    southwest = startroom
    southeast = byCave
    
    /*  
     *   EVENT LIST              TRAVEL CONNECTOR TO NOWHERE
     *
     *   An EventList executes every item in its list in turn, until it reaches
     *   the end, when it will do nothing. Since the last item in this EventList
     *   kills the Player Character (and so ends the game) we don't need
     *   anything to happen beyond the end of the list, so an EventList is just
     *   fine here.
     *
     *   Since this travel connector has no destination, all that will happen
     *   when we try to traverse it is that it will execute its noteTraversal
     *   method, which will in turn call travelDesc, which will in turn execute
     *   doScript, thus displaying each item in the event list in turn.
     */
    
    north: TravelConnector, EventList {
    [
        'You can\'t go that way; the river is in the way. ',
        
        'The river is still in the way, and it looks far too dangerous to swim
        across. ',
        
        /*  
         *   As before we can execute any code we like within an EventList 
         *   item by wrapping it in the new function syntax.
         */        
        new function {
            "Oh, very well, if you insist.\b
            You wade into the river. It's deep. You can't swim all that well.
            You drown.\b";
            
            /*  
             *   Kill the PC on the third attempt, but allow the player to 
             *   UNDO, so it's not too cruel. Also give the player the 
             *   option to see the full score (listing all the achievements 
             *   achieved to date).
             */
            finishGameMsg(ftDeath, [finishOptionUndo, finishOptionFullScore]);
        }
    ]
        
        /* 
         *   Since this connector isn't meant to lead anywhere, we don't want it
         *   listed as an exit.
         */
        isConnectorListed = nil
    }
    
    
    
    east = "Heavy undergrowth prevents you from walking directly along the bank
        of the river. " 
    
    /*  Use the same message for both east and west. */
    west asExit(east)
    
    /*  
     *   RANDOM EVENT LIST
     *
     *   A RandomEventList simply displays one of its items at random. The
     *   difference between this and a ShuffledEventList is that a
     *   RandomEventList may show the same item twice (or more) in a row. In a
     *   situation where this is acceptable, you can use it as an alternative to
     *   a ShuffledEventList, as here.
     */
    eventList =     
    [
        'There\'s a brief disturbance in the river as something breaks
        above the surface and then vanishes beneath it again. ',
        
        'Somewhere, you hear the croaking of a frog. ',
        'A flock of birds flies overhead. ',
        'Something splashes in the marshy undergrowth. ',
        'A gust of wind ripples across the surface of the river. '
    ]
    
    eventPercent = 50
;


/*  
 *   SYNC EVENT LIST
 *
 *   A SyncEventList is an EventList that's kept in sync with another 
 *   EventList (pointed to in its masterObject property).
 *
 *   This game is mean enough to drown the PC on the third attempt to cross 
 *   the river whether it's by typing NORTH or SWIM RIVER, although we'll 
 *   display different messages for the two commands. Using a SyncEventList 
 *   here esnures we keep count of the total number of attempts to cross the 
 *   river, by whichever means. 
 */
+ Fixture, SyncEventList 'river; broad wide swollen; water'
    "Swollen by recent floods, the river rushes rapidly by. "
    
    /*  
     *   We can fill things (well, the bucket) from the river, and pour 
     *   things (well, water) into it.
     */
    iobjFor(FillWith) { verify() {} }
    iobjFor(PourInto) { verify() {} }
    
    
    /*   
     *   In principle, the river is something that could be swum. Note that 
     *   Swim is not an action defined in the standard library; we define it 
     *   below.
     */
    dobjFor(Swim)
    {
        verify() {}
        action() { doScript(); }       
    }
    
    eventList = 
    [
        'The river has been swollen by recent rainfall, the current looks
        exceptionally strong, and you aren\'t such a great swimmer. So after
        dipping a toe in the water, you think better of it. ',
        
        'You are almost desperate enough to try it, but not quite. The water is
        cold, and the current looks strong. You\'re not sure you\'d make it to
        the other side. ',

        new function {
        "Throwing all caution to the winds, you plunge into the river and strike
        out for the opposite bank, but the river is even deeper and the current
        even stronger than you thought. Less than halfway across you find
        yourself swept away. Unable to keep your head above water, you
        drown.\b";
        
        finishGameMsg(ftDeath, [finishOptionUndo, finishOptionFullScore]);
    }        
    ]
    
    /* The EventList object we're keeping in sync with. */
    masterObject = byStream.north
;

/* Path is a custom class defined above. */
+ Path
    dir1 = 'southeast'
    dir2 = 'southwest'
;

+ Decoration 'some undergrowth; heavy thick marshy; bank' 
    "Thick undergrowth, made marshy by the swollen river, blocks the bank to
    both east and west. "     
;


//------------------------------------------------------------------------------

byCave: Room 'Outside a Cave' 'the cave entrance'
    "Paths from both northwest and southwest come to an end here just outside
    the mouth of a cave to the east. "
    northwest = byStream     
    southwest = clearing
    east = cave
    in asExit(east)
    
    /*  
     *   Award some points if the player character enters this room carrying 
     *   the bucket, which will happen if the PC takes the bucket out of the 
     *   cave. Since awardPointsOnce() only awards points once, it doesn't 
     *   matter how many times the PC subsequently enters the room carrying 
     *   the bucket; no more points will be awarded.
     */
    travelerEntering(traveler, origin)
    {
        if(bucket.isIn(traveler))
           achievement.awardPointsOnce();
    }
    achievement: Achievement { +2 "getting the bucket out of the cave" }
;

+ Enterable -> cave 'cave entrance; of[prep]; mouth'
    "The cave entrance <<cave.blocked ? 'has been blocked by a recent fall of
        rocks' : 'is not all that large, but looks large enough to enter'>>. "
;

/*  
 *   HIDDEN ROCKFALL
 *
 *   This rockfall should only be present once the cave entrance has collapsed,
 *   so we make it start out hidden so it can be made present once it's needed.
 */
+ rockfall: Immovable 'rockfall; rock of[prep]; rocks fall pile' 
    "The fall of rocks has completely blocked the entrance to the cave. "

    specialDesc = "A pile of rocks blocks the entrance to the cave. "
    
    cannotTakeMsg = 'You\'ll never shift that lot by hand. '
    
    isHidden = true
;

/*   Path is a custom class defined above. */
+ Path
    dir1 = 'northwest'
    dir2 = 'southwest'
;


//------------------------------------------------------------------------------

cave: Room 'Cave' 
    "It looks like this cave goes back quite a long way, but the only way out
    is to the west. "
    
    /* The cave is dark */
    isLit = nil
    
    /*  
     *   darkName and darkDesc will be used instead of the ordinary 
     *   room name and description when the room is dark. The use of the 
     *   <.reveal> tag in the dark description enables the hints system to 
     *   track when the PC has visited this room in the dark.
     */
    darkName = 'Cave (in the dark)'
        
    darkDesc = "It's too dark to see anything in here, except that the way
        back out is to the west. <.reveal dark-cave>"
    
    /*   
     *   EVENT LIST        TRAVEL MESSAGE
     *
     *   We can mix an EventList with a TravelMessage to provide a sequence 
     *   of different responses each time the PC goes this way. Since the PC 
     *   cannot in any case traverse this travel connector after the third 
     *   traversal blocks the entrance to the cave, a simple EventList will 
     *   do.
     */    
    west: TravelConnector, EventList {
    [
        /* 
         *   An EventList item can simply be nil, in which case it does 
         *   nothing.
         */
        nil,
        
        /*  The second time through we'll display a warning message. */
        'As you walk out of the cave, you hear a diquieting rumble, and you
        feel fine dust and pebbles fall around you just before you emerge into
        the light. ',
        
        /*  
         *   The third time through we'll cause a rockfall that blocks the 
         *   way back into the cave. We could do this with new function 
         *   again, but this time we'll illustrate an alternative. Another 
         *   kind of thing that can occur in an EventList is a method 
         *   pointer; when the EventList reaches &rockFall it will execute 
         *   self.rockFall().
         */
        &rockFall
    ]
        /*   This travel connector takes us outside the cave. */
        destination = byCave
        
        /*   A custom method invoked by the last item in the EventList above. */
        rockFall()
        {
            /* 
             *   Start by blocking the cave. Note that we have defined the 
             *   custom blocked property on the cave object, not the 
             *   TravelMessage, so we use lexicalParent to get the right 
             *   object's property (forgetting to do this can be a very 
             *   common source of bugs).
             */
            lexicalParent.blocked = true;
            "As you walk out of the cave the rocks around the exit begin to
            tremble. You manage to dash out just in time to avoid the rockfall
            that blocks the cave. ";
            
            /*   Make present the rocks blocking the cave from the outside. */
            rockfall.discover();
            
            /*   
             *   If the PC has left the bucket in the cave, the game is now 
             *   unwinnable, so we may as well end it straight away.
             */
            if(bucket.isIn(cave) && !bucket.isIn(me))
                finishGameMsg('THE GAME IS NOW UNWINNABLE', 
                              [finishOptionUndo, finishOptionFullScore]);
        }
        
        
    }
    
    out asExit(west)
    
    /*  A custom property we use to block the cave after the rockfall. */
    blocked = !rockfall.isHidden
    
    /*  
     *   Once the cave is blocked we can't get back into it. Since the cave 
     *   is the only TravelerConnector to itself, we can block it by using 
     *   its canTravelerPass method.
     */
    canTravelerPass(traveler) { return !blocked; }
    explainTravelBarrier(traveler) 
    {
        "You can't go back into the cave; a rockfall has covered the entrance.
        ";
    }
    
    /*  
     *   Once the cave is blocked, we obviously can't get back in, so we 
     *   shouldn't list the way back in as a possible exit.
     */
    isConnectorApparent = (!blocked)
;    


+ bucket: Container 'bucket; ordinary'
    "It's just a perfectly ordinary bucket<< water.isIn(self) ? ', full of
        water' : ''>>."
    
    /*  
     *   FillWith is a custom action defined below. The bucket is the only 
     *   object in the game that can be filled with anything, so we need to 
     *   define special action handling for it.
     */
    dobjFor(FillWith)
    {
        /*  
         *   In order to fill the bucket the actor must be holding the 
         *   bucket and the bucket must first be empty.
         */
        preCond = [objHeld]
        verify() 
        {
            /*  We can't fill a bucket that's already full. */
            if(water.isIn(self))
                illogicalNow('The bucket is already full. ');
        }
        action()
        {
            "You fill the bucket from {the iobj}. ";
            
            /*  
             *   The water object is defined below. Moving it into the bucket
             *   effectively fills the bucket with water.
             */
            water.moveInto(self);
            
            /*   Award some points for filling the bucket. */
            achievement.awardPointsOnce();
        }
    }
    initSpecialDesc = "A bucket has been left on the ground near the rear of the
        cave. "
    bulkCapacity = 4
    
    
    /* When the bucket's full of water we'll say so when the bucket's listed. */
    listName = (water.isIn(self) ? inherited + ' (full of water)' : inherited)
    
    achievement: Achievement { +2 "filling the bucket with water" }
;


//------------------------------------------------------------------------------

clearing: Room 'Clearing'
    "<<first time>>You recognize this clearing; you've pretty sure you've been
    this way before. <<only>>Unless you're much mistaken the way back to the car
    park lies straight to the south<< smoke.isIn(self) ?  '-- if you can get to
        it with all the smoke now billowing from the bonfire' : ''>>. Other
    paths lead off to northeast and northwest. "
    
    
    northwest = startroom
    northeast = byCave
    
    south: TravelConnector
    {
        
        noteTraversal(traveler)
        {
            "Now that the smoke from the fire has abated, you are able to reach
            the southern exit from the clearing with ease. After that, you find
            it's only a short walk back to your car.\b";
            
            /*  
             *   Once the PC traverses this connector award the final points 
             *   end the game in victory.
             */
            achievement.awardPointsOnce();
            finishGameMsg(ftVictory, [finishOptionUndo, finishOptionFullScore]);
        }
        
        achievement: Achievement { +2 "finding your way back to your car" }
    }
    
;


/*   
 *   FIRE - we use a Fixture and add some customizations to make it work like a
 *   bonfire.
 *
 */
+ bonfire: Fixture 'bonfire; large; fire flames'    
    "The bonfire is <<if isLit>>blazing and emitting clouds of smoke<<else>>
    merely smouldering<<end>>. "
    
    feelDesc = "<<if isLit>>The bonfire is far to hot to touch. <<else>>It still
        feels quite warm. <<end>>"
    
    /*  Special handling for pouring water onto the fire. */
    
    iobjFor(PourOnto)
    {
        verify()
        {
            /*  If the fire isn't lit, there's no point trying to put it out. */
            if(!isLit)
                illogicalNow('You\'ve already put the fire out. ');
        }
        check() {}
        action()
        {
            /*  
             *   Pouring water into the fire makes it go out, and removes the
             *   smoke.
             */
            "Your pour {the dobj} onto the fire, and the fire goes out. ";
            smoke.moveInto(nil);
            
            /*   Award some points for extinguishing the fire. */
            achievement.awardPointsOnce();
            
            /* 
             *   Now that we've put the fire out, we shouldn't be able to refer
             *   to any flames.
             */
            removeVocabWord('flames');
        }
    }
    
    /*   
     *   The player might try DOUSE FIRE or EXTINGUISH FIRE, so we provide 
     *   handling for that.
     */
    dobjFor(Extinguish)
    {
        /*  
         *   We save ourselves some typing by re-using the same verify() 
         *   method as for PourOnto, since exactly the same conditions apply.
         */
        verify() { verifyIobjPourOnto(); }
        check()
        {
            /*  We can only extinguish the fire if the water is to hand. */
            if(!gActor.canReach(water))
               "You have nothing to hand to do that with. ";
        }
        
        /* 
         *   If we've got this fire, there is water to hand, and the fire 
         *   hasn't been put out yet, so we can now translate DOUSE FIRE 
         *   into POUR WATER ONTO FIRE.
         */
        action() { replaceAction(PourOnto, water, self); }
        
    }
    
    iobjFor(BurnWith) { preCond = [touchObj] }
    
    canBurnWithMe = true
    
    /*   The bonfire is lit when it is smoking. */
    isLit = (smoke.isIn(self))
   
    cannotTakeMsg = (isLit ? 'The fire is far too hot too much, let
        alone move around. ' : 'It\'s both too warm and too large to move. ')
    
    cannotPutOnMsg = (isLit ? 'You don\'t want to add any more fuel to
        the flames! ' : 'Better not risk it; it might catch light again. ')
    
    achievement: Achievement { +2 "putting out the fire" }
;

++ smoke: Decoration 'some smoke; billowing; clouds heat smoke' 
    "The smoke is billowing from the fire, nearly filling the southern side of
    the clearing. "
    aName = 'smoke' 
    
    smellDesc = "It smells quite acrid. "
    
    /* We want to be able to smell the smoke as well as examine it. */
    decorationActions = [Examine, SmellSomething]
    
    notImportantMsg = 'You can\'t do that to smoke. '
;

+++ smokeSmell: Odor, ExternalEventList 'smell; acrid of[prep]; (smoke)' 
    eventList =
    [
        'The smell of smoke from the fire seems overwhelming. ',
        'The acrid smell of smoke makes you cough. ',
        'The smoke stings your eyes. ',
        'The smell of smoke is quite unpleasant. '
    ]
    
    /*  
     *   An ExternalScriptList provides no mechanism of its own for changing 
     *   its state. Here we set its curScriptState to track the Odor's 
     *   displayCount (which is advanced every time the Odor is mentioned). 
     *   We have to make sure that curScriptState is never a number that's 
     *   larger than the length of the event list.
     */
    curScriptState = (displayCount > eventList.length ?
                                      eventList.length : displayCount)
    
    displayCount = 1

;

/*  Here we define a very basic NPC. */
+ man: Actor 'tall man; gaunt;;him'     
    "He's very tall and rather gaunt looking, as if he'd just spent the last
    fifty years in a monastery devoted to fasting. "
    
    globalParamName = 'man'
;

/* This is the ActorState the man starts out in */
++ ActorState   
    isInitState = true
    specialDesc = "{The subj man} is walking briskly by. "
    
    /* 
     *   Any attempt to converse with the man while he's in this state will be
     *   met with this noResponse.
     */
    noResponse = "He's too deep in his own thoughts to take any notice of yours.
        "
    stateDesc = "He looks lost in his thoughts. "
    
    /* 
     *   The message to display when the man enters the location of the player
     *   character.
     */
    sayArriving(fromLoc)
    {
        "<<one of>>A<<or>>The<<stopping>> tall man appears down the path. ";
    }
;

/*  
 *   CYCLIC EVENT LIST
 *
 *   A CyclicEventList is an EventList that goes round in a continuous cycle;
 *   after the last item in the list has been used, it loops back to the 
 *   first.
 *
 *   Here we combine a CyclicEventList with an AgendaItem to send our 
 *   NPC walking in a continuous circle round the map.
 */
++ walkingAgenda: AgendaItem, CyclicEventList
    [
        /* 
         *   The {: } syntax is just a short form of the new function syntax we
         *   can use when the function contains a single statement. The first
         *   item in the list is equivalent to:
         *
         *   new function { man.travelVia(startRoom); }
         *
         *   Note that when we use the short form {: } syntax we must not end
         *   the single statement in the function with a semicolon.
         *
         *   Note the use of the report method (a method of AgendaItem) in the
         *   third item in the list to make sure the message is only displayed
         *   when the player character can see the man.
         */        
        {: man.travelVia(startroom) },
        {: man.travelVia(byStream) },
        {: report('{The subj man} pauses to scoop a handful of water from the
            river, before continuing on his way. ')} ,
        {: man.travelVia(byCave) },
        {: man.travelVia(clearing) }
    ]    
    
    initiallyActive = true
    invokeItem() { doScript(); }
;

/* 
 *   An alternative actor state the tall man goes into if the Player Character
 *   triggers a rock fall in the cave.
 */

++ manStandingState: ActorState
    specialDesc = "The tall man is standing just outside the cave, staring at
        the pile of rocks with a mixture of dismay and disapproval. "

    stateDesc = "He doesn't look at all pleased right now. "
;

+++ DefaultAnyTopic, CyclicEventList
    [
        '<q>That was <i>my</i> cave,</q> he complains. <q>That\'s where I go to
        meditate. What am I meant to do now?</q> ',
        
        '<q>I\'ll never be able to move all those rocks,</q> he sighs. ',
        
        '<q>It\'s too much, it really is,</q> he mutters, shaking his head. '
    ]
;

/*  The custom Path class is defined above. */
+ Path
    dir1 = 'northeast, northwest'
    dir2 = 'south'
;

fireLitUnlitState: State
    appliesTo(obj) { return obj == bonfire; }
    stateProp = &isLit
    adjectives = [[nil, ['unlit', 'warm', 'smouldering']], 
        [true, ['lit', 'hot', 'blazing']]]
    
;


/* 
 *   SCENES
 *
 *   This is admittedly a somewhat artificial example since everything this
 *   Scene does could be done in other ways, but it nevertheless illustrates the
 *   principle.
 */
bonfireLitScene: Scene
    /* This Scene is active from the start of the game */
    startsWhen = true
    
    eachTurn()
    {
        if(gPlayerChar.isIn(clearing))
        {
            smokeSmell.doScript();
            smokeSmell.displayCount++;            
        }
        else
            smokeSmell.displayCount = 1;
    }
    
    endsWhen = !bonfire.isLit
;


/* 
 *   A second example of a Scene. Again, this could be done another way, but a
 *   Scene provides quite a convenient means of making things happen in response
 *   to some condition becoming true.
 */
manComplainingScene: Scene
    startsWhen = !rockfall.isHidden
    
    whenStarting()
    {
        man.removeFromAgenda(walkingAgenda);
        man.setState(manStandingState);
        man.moveInto(byCave);
        "Just at that moment, the tall man appears down the path. ";
    }
;


/* 
 *   What this Doer does could just as easily have been done using the
 *   canTravelerPass() and explainTravelBarrier() methods on the TravelConnector
 *   south from the clearing, but this illustrates another approach tied in with
 *   a Scene.
 */
Doer 'go south'
    execAction(c)
    {
        "You can't reach the southern exit for the smoke and the heat of the
        fire.<.reveal smoke-block> ";
    }
    
    where = [clearing]
    during = [bonfireLitScene]
;




//==============================================================================
/*  The WATER object */

water: Immovable 'water' 
    
    aName = 'water'
    cannotTakeMsg = 'The water runs through your fingers. '
    
    /* Custom handling for pouring water onto something. */    
    dobjFor(PourOnto)
    {
        /*  
         *   To be able to pour water onto something we must be holding its 
         *   container.
         */
        preCond() { return [new ObjectPreCondition(location, objHeld)]; }
        verify() {}
        action()
        {
            moveInto(nil);
        }
    }
    
    /* 
     *   Treat PUT WATER ON SOMETHING as equivalent to POUR WATER ONTO 
     *   SOMETHING.
     */
    dobjFor(PutOn) 
    {
        preCond() { return [new ObjectPreCondition(location, objHeld)]; }
        verify() {}
        action()
        {
            doInstead(PourOnto, self, gIobj);
        }
    }
       
    
    
    /*  Custom handling for pouring water into something. */
    dobjFor(PourInto)
    {
        preCond() { return [new ObjectPreCondition(location, objHeld)]; }
        verify() {}
        action()
        {
            "You pour the water into {the iobj. ";
            moveInto(nil);
        }
    }
       
    
    
    bulk = 4
;


//==============================================================================
/* CUSTOM ACTIONS AND GRAMMAR */
          
DefineTIAction(FillWith)    
;

VerbRule(FillWith)
    'fill' singleDobj ('with' | 'from') singleIobj
    : VerbProduction
    action = FillWith
    verbPhrase = 'fill (what) (from what)'
    missingQ = 'what do you want to fill; what do you want to fill it with'
;

/*  
 *   Provide this form to handle FILL SOMETHING. If the player types FILL BUCKET
 *   the parser will  prompt for an indirect object: "What do you want to fill
 *   it from?"
 */

VerbRule(FillWithWhat)
    [badness 500] 'fill' singleDobj     
    : VerbProduction
    action = FillWith
    verbPhrase = 'fill (what) (from what)'
    missingQ = 'what do you want to fill; what do you want to fill it with'
    missingRole = IndirectObject
    dobjReply = singleNoun
    iobjReply = withSingleNoun
;

DefineTAction(Swim)
;    

VerbRule(Swim)
    'swim' ('across' | 'in' | ) singleDobj
    : VerbProduction
    action = Swim
    verbPhrase = 'swim/swimming (what) '
    missinqQ = 'what do you want to swim'
;

/*  Put appropriate action handling on Thing for our new actions. */
modify Thing
    dobjFor(FillWith)
    {
        preCond  = [touchObj]
        verify() { illogical('You can\'t fill {the dobj} with anything. ');
        }
    }
    iobjFor(FillWith)
    {
        preCond = [touchObj]
        verify() { illogical('You can\'t fill anything with {that iobj. '); }
                
    }
    
    dobjFor(Swim)
    {
        preCond = [touchObj]
        verify()
        {
            illogical('{That dobj}{\'s} not something {i} {can} swim. ');
        }
    }
    
    /*  
     *   Also make it logical to pour onto anything, but rule it out in 
     *   check(), so the player can't waste the water in the bucket by 
     *   pouring it onto anything other than the fire.
     */
    iobjFor(PourOnto)
    {
        preCond = [touchObj]
        verify() {}
        check()
        {
            "There's not much point pouring {the dobj} onto {that iobj}. ";
        }
    }
    
;


//==============================================================================
/* 
 *   MENUS
 *
 *   We'll demonstrate menus in general by setting up a short menu of options
 *   that can be displayed in response to an ABOUT command. This will 
 *   include the instructions on playing IF in general defined in instruct.t
 *
 *
 *   We first modify the InstructionsAction (defined in the standard library 
 *   file instruct.t). Here we're modifying standard properties provided for 
 *   the purpose of allowing game authors to tweak the otherwise standard 
 *   instructions.
 */

modify Instructions
    /* 
     *   Our game is a bit on the cruel side, so change the cruelty lever to 
     *   2 so that this is reflected in the instructions.
     */
    crueltyLevel = 2
    
    /*  
     *   The instructions can say that they contain all the verbs a player 
     *   needs to complete the game.
     */
    allRequiredVerbsDisclosed = true
    
    /*   
     *   To make the above claim true we need to add an example of the FILL
     *   WITH grammar to the list of standard verbs.
     */
    customVerbs = ['FILL BUCKET WITH SAND']
;

/*  Make HELP equivalent to ABOUT. */
modify VerbRule(About)
    'about' | 'help'
    :
;

/*  
 *   MENU ITEM
 *
 *   We can use MenuItem to define a top-level menu or a sub-menu. Here we're
 *   defining the top menu that's displayed in response to an ABOUT command 
 *   (see versionInfo.showAbout() defined near the start of this file.
 */     
helpMenu: MenuItem 'Help Menu'
    /* 
     *   In addition to the two items defined below, we want this menu to 
     *   contain the instructions menu from instruct.t and out hint menu, 
     *   which we're about to define below.
     *
     *   Note that instruct.t doesn't automatically provide the instructions 
     *   as a menu. To make it do so, we must make sure that 
     *   INSTRUCTIONS_MENU is defined before instruct.t is compiled into the 
     *   build. We can do this in Workbench using the Build -> Settings menu 
     *   and adding INSTRUCTIONS_MENU via the Compiler -> Defines tab.
     *
     *   If you're not using Workbench you'll need to add -D 
     *   INSTRUCTIONS_MENU when compiling from the command line.
     *
     *   You might also need to force a recompile of instruct.t, either by 
     *   doing a Compile All, or by opening instruct.t and, say, adding and 
     *   deleting a space so that the compiler thinks it has changed.
     *
     */
    
    contents = [topInstructionsMenu, topHintMenu]    
;

/*  
 *   MENU LONG TOPIC ITEM
 *
 *   We use MenuLongTopicItem to display some text when the item is selected 
 *   from a menu.
 */
+ MenuLongTopicItem 'About This Game'
    menuContents = "<<versionInfo.name>> is a demonstration of EventLists,
        menus, hints and scoring in TADS 3.\b
        As games go, it's neither long nor taxing. After rushing through to a
        winning ending first time round, you might want to go back and explore
        it at a more leisurely pace, to see how the various EventLists are
        working and try out all the hints. "
    
;

+ MenuLongTopicItem 'Credits'
    /* 
     *   When the Credits item is selected from the menu, just show the 
     *   credits information already defined on the versionInfo object.
     */
    menuContents = (versionInfo.showCredit)
;


//------------------------------------------------------------------------------
/*  
 *   HINTS
 *
 *   This demonstration is probably a bit over the top in providing 
 *   comprehensive hints for such simple puzzles, but the idea is to show the
 *   principles of the Hints system.
 *
 *   We begin by defining the root menu of our Hints System. This could 
 *   contain submenus if we wanted, but an adaptive hint system rarely has 
 *   enough hints active at once for this to be worthwhile.
 *
 *   This is the menu that will be displayed in response to a HINTS command.
 */


topHintMenu: TopHintMenu 'Hints'
;

/*  
 *   GOAL
 *
 *   Goals constitute the contents of the Hints system. They represent tasks 
 *   that the player is trying to perform and might want guidance on. Only 
 *   those Goals that are currently open (relevant for active tasks) are 
 *   displayed.
 *
 *   We start with a very general goal that the player might have right at 
 *   the start of the game.
 */


+ Goal 'What am I meant to be doing?'
    /* 
     *   The following hints will be displayed one at a time until the player
     *   reaches a list. As each hint is displayed, the previous ones remain
     *   visible.
     */
    [
        'Try exploring. ',
        'You\'re trying to find a way back to your car. ',
        'Make sure you\'ve explored the whole area. '
    ]
    
    /*  
     *   This goal is open at the start of the game. We use the OpenWhenTrue 
     *   condition to open it and simply define the condition as true.
     */
    openWhenTrue = true
    
    /*   
     *   We close this Goal once the player has visited the four main 
     *   locations on the map and encountered something that looks enough 
     *   like a recognizable difficulty to suggest a more specific goal to 
     *   pursue.
     */
    closeWhenTrue = byCave.seen && byStream.seen && clearing.seen &&
    (gRevealed('smoke-block') || gRevealed('dark-cave') )
;


+ caveGoal: Goal 'How do I bring light to the cave?'
    [
        'Have you seen anything round here that gives off light? ',
        'Maybe it\'s also giving off heat. ',
        'Like a fire. ',
        'Perhaps if you could set light to something portable you could
        bring it to the cave. ',
        'Wood burns. ',
        
        /* 
         *   Mostly we can just use single-quoted strings to display hints. 
         *   Occasionally, when we want displaying the hint to have some side
         *   effect, such as opening another goal, it's convenient to use a 
         *   hint object instead.
         */
        branchHint
    ]
    
    /* 
     *   The cave is not considered 'seen' until it has been seen in lit 
     *   conditions. The dark description of the cave reveals the dark-cave 
     *   tag so we can use it here to test whether it has been revealed; if 
     *   it is, it's time to open this goal.
     */
    openWhenRevealed = 'dark-cave'
    
    /*  
     *   Once the cave has been seen properly (with the aid of a light) this 
     *   goal has been achieved, its hints are no longer needed, so we close 
     *   it.
     */
    closeWhenSeen = cave
;

/*   
 *   HINT
 *
 *   There's no necessity to nest Hint objects inside Goals, but it can be 
 *   convenient to do so, since this allows us to define the Hint object 
 *   close to the Goal that refers to it without messing up the object 
 *   hierarchy of the menu; otherwise all the Hint objects would have to be 
 *   defined after the last Goal. 
 *
 *   This Hint displays "So you could try using a branch." and open the 
 *   branchGoal Goal.
 */
++ branchHint: Hint 'So you could try using a branch. '
    [branchGoal]
;

+ branchGoal: Goal 'Where can I find a branch?'
    [
        'How thoroughly have you explored? ',
        'What lies to the west? ',
        'More specifically, what lies to the west of your starting location? '        
    ]
    /*  
     *   We don't provide an openWhenXXXX, since this Goal is opened by the 
     *   display of the branchHint Hint. It's closed once the branch has 
     *   been moved, since at that point the player has found the branch and 
     *   doesn't need any more hints on how to do so. 
     */
    closeWhenTrue = branch.moved
;


+ Goal 'How do I get south from the bonfire clearing? '
    [
        'What\'s stopping you? ',        
        fireHint
    ]
    /* Once again use a reveal tag to open the Goal. */
    openWhenRevealed = 'smoke-block'
    
    /* 
     *   We can close the Goal once the fire's been put out; since putting 
     *   out the fire causes the achievement of the bonfire.achievement, we 
     *   can use that as the test here. Equally usable alternatives would 
     *   have included:
     *
     *   closeWhenTrue = !bonfire.isLit
     *
     *   OR
     *
     *   closeWhenTrue = smoke.isIn(nil)
     *
     */
    closeWhenAchieved = bonfire.achievement
;

++ fireHint: Hint 'Perhaps it would be a good idea to put the fire out. '
    [fireGoal]
;

+ fireGoal: Goal 'How can I put the fire out?'
    [
        'How would you usually put a fire out? ',
        'What can you put on a fire to douse it? ',
        waterHint
    ]
    closeWhenAchieved = bonfire.achievement
;

++ waterHint: Hint 'Perhaps you should fetch some water. '
    [waterGoal]
;
    
    
+ waterGoal: Goal 'How can I bring water from the river to the fire? '
    [ 
        'What would you normally carry water in? ',
        bucketHint   
    ]
    closeWhenTrue = water.moved
;

++ bucketHint: Hint 'Perhaps you could find a bucket somewhere. '
    [bucketGoal]
;

+ bucketGoal: Goal 'Where can I find a bucket? '
    [        
        'How thoroughly have you explored? ',
        'What lies to the east? ',
        caveHint
    ]
    closeWhenSeen = bucket
;

    /* 
     *   Note that though this Hint opens caveGoal, that Goal can also be 
     *   opened by the PC entering the cave when it's dark.
     */
++ caveHint: Hint 'Try looking in the cave. '
    [caveGoal]
;

/*  
 *   Once the bonfire has been put out, there's nothing left to do except 
 *   leave the clearing by the south exit. For the sake of completeness we 
 *   include a Goal even for that.
 */

+ Goal 'What should I do now?'
    [
        'What have you been trying to do all along? ',
        'You\'re meant to be trying to find your way back to your car. ',
        'Do you remember where you parked it? ',
        'You\'re pretty sure it was to the south of the bonfire clearing. '        
    ]
    openWhenAchieved = bonfire.achievement
    
    /* 
     *   We don't need a CloseWhenXXXX condition, since this Goal should 
     *   remain open until the end of the game.
     */
;
