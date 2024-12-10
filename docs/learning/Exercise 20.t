#charset "us-ascii"

#include <tads.h>
#include "advlite.h"


/*   
 *   LIGHTHOUSE is a adv3Lite demo designed to illustrate implementing NPCs in 
 *   adv3Lite. It's loosely inspired by the Bop character used as an example in
 *   Mike Roberts's "Creating Dynamic Actors" article in the Technical 
 *   Manual.
 *
 *   There's a couple of endings you can reach, but you can't really win. As 
 *   with all these demos the point isn't playing the game but learning from 
 *   the sourc code (although as ever it's worth trying to play it to see 
 *   what the code does).
 */



versionInfo: GameID
    IFID = '058e959b-0b9d-41e7-be20-cf89edbfe97c'
    name = 'Exercise 20 - Lighthouse'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc.ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc.ox.ac.uk>'
    desc = 'A short game to demonstrate programming NPCs in adv3Lite'
    htmlDesc = 'A short game to demonstrate programming NPCs in adv3Lite'
;

gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    showIntro()
    {
        "You've only just moved into town, so you thought you'd pay the local
        store a visit to pick up some basic essentials. But you may be about to
        get more than you bargained for.\b";
    }
    
    showGoodbye()
    {
        if(me.hasSeen(horrorChamber))
            "<.p>Sorry, that's all folks! ";
        else
            "<.p>Perhaps you should try a bit harder next time! ";
    }
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
 */
shop: Room 'General Store'
    "The shop has much the sort of stuff you'd expect in a general store in a
    sleepy sea-side town like this. The only way out is to the north. "
    north = street
    out asExit(north)
    
    /* 
     *   followDesc is a custom property we are defining for use with an 
     *   accompanying NPC (see below). It's used to customize what's 
     *   displayed when the sally NPC accompanies the PC via a particular 
     *   connector.
     */
    followDesc = 'back into the shop'
;

/* 
 *   The player character object. This doesn't have to be called me, but me is a
 *   convenient name. If you change it to something else, rememember to change
 *   gameMain.initialPlayerChar accordingly.
 */

+ me: Player 'you'       
;

/*   
 *   Since this is a demo of NPCs, we'll keep the implementation of the map 
 *   and the physical objects in it as basic as possible, more or less to 
 *   the bare minimum needed to illustrate the various features of NPC 
 *   programming. For the same reason we'll only provide minimal commenting 
 *   for the map-building section of the code.
 *
 *   We don't need multiple rooms to illustrate conversation, but we do need 
 *   multiple rooms to illustrate an NPC who accompanies the PC on his 
 *   travels, so we'll still need several rooms in this map.
 */


+ Decoration 'clothes rack' 
    "It's a rack with lots of clothes on. "
;

+ cans: Decoration 'cans; carefully stacked of[prep]; stack can; them' 
    "The cans are all carefully stacked. "    
;

street: Room 'Main Street'
    "This looks the main street running through the town. At this point it runs
    past the general store immediately to the south. The town centre lies to the
    west, while to the east the street runs on out of town. "
    
    south = shop
    in asExit(south)
    
    west: TravelConnector {         
        destination = street
        travelDesc = "You wander round the town centre for a while, but find
            nothing that holds your attention, so you eventually find your feet
            bringing you back where you started. " 
    }
    
    east: TravelConnector {
        destination = road
        
        /* 
         *   followDesc is a custom property we're defining to customize the
         *   description of one actor following another through a
         *   TravelConnector. See below for how it's used in this demo game.
         */
        followDesc = 'along the street all the way out of town, and then on
            down the road'
    }
;

road: Room 'Road'
    "The road seems unusually quiet, with very little traffic; right now
    there's none in sight at all. It runs fairly straight here, almost dead
    straight back into the town to the west, although you can see it start to
    bend some way off to the east. An open field lies to the south. "
    
    west = street
    east: TravelConnector { 
        destination = road
        travelDesc = "You walk a short way down the road, then turn
        round and come back. "
    }
    
    south: TravelConnector {
        destination = hillTop
        followDesc = 'away from the road, across a field and up a shallow hill'
    }
;

+ Enterable 'open field' 
    "It slopes gently up to the east. "
    destination = road.south
;

hillTop: Room 'Hilltop'
    "From the top of the hill you can clearly see the sea glinting a short way
    to the south. It looks possible to descend the hill to the southeast, the
    southwest, or the north. "
    
    southeast: TravelConnector {
        destination = cliff
        followDesc = 'down the far side of the hill, and carry on a short way
        towards the coast'
    }
    southwest: TravelConnector {
        destination = hillTop
        travelDesc = "You walk a short way down to the southwest, but soon come
            to a sheer cliff overlooking the sea. Since you can go no further in
            that direction you turn round and come back. "
    }
    north = road
    followDesc = 'back up the hill'
;

MultiLoc, Distant 'sea; wet watery calm'
    "It looks as wet and watery as the sea always does, though it also looks
    reasonably calm. "
    locationList = [cliff, cliffPath, hillTop]
    aName = 'the sea'
;

cliff: Room 'Lonely Cliff'
    "The path down the hillside to the northwest comes to an end on this bleak
    stretch of cliff, overlooking the sea several dozen yards below. An old
    lighthouse, perched strategically near the cliff-edge, stands immediately
    to the east. To the west a narrow path snakes precariously along the
    cliff-top. "
    northwest = hillTop
    
    east = lhDoor
    in asExit(east)
    west = narrowPath
;

+ lighthouse: Enterable 'lighthouse; damaged old'
    "The lighthouse is still standing, but it looks as if the upper part has
    sustained some damage. "
    connector = lhDoor
;

/* 
 *   Using -> in the template is an alternative way of specifying the otherSide
 *   of a Door.
 */
++ lhDoor: Door ->lhDoorInside 'door' 
    followDesc = 'through the door into the lighthouse'
;

+ narrowPath: PathPassage 'narrow path' 
    "It snakes precariously along the cliff-top to the west. "
    destination = cliffPath
    followDesc = 'down the narrow path'
;

cliffPath: Room 'Cliff Path'
    "The path from the northwest comes to a dead end overlooking the sea. "
    northwest = cliff    
;

lobby: Room 'Lighthouse Lobby'
    "This would seem to be the entrance lobby for the lighthouse. A spiral
    staircase winds up to the north, and the way out is to the west, while a
    second exit leads east. "
    west = lhDoorInside
    out asExit(west)
    north = lhStair
    up asExit(north)
    east = store
    
    followDesc = 'back into the lobby'
;

+ lhDoorInside: Door ->lhDoor 'door' 
    followDesc = 'back out through the door'
;

+ lhStair: StairwayUp 'flight of stairs; spiral; staircase; it them' 
    followDesc = 'up the stairs'
    destination = midStair
; 


store: Room 'Storeroom' 
    "This looks as if it was once a storeroom for the lighthouse, but it's been
    stripped almost bare now. The exit back to the lobby is to the west, but
    there's another exit to the south. "
    west = lobby
    south = office
    out asExit(west)
    followDesc = 'into the storeroom'
;

office: Room 'Office'
    "The battered old wooden desk standing in the corner suggests that this was
    once an office of some sort, but there's little else here now. The only way
    out is to the north. "
    north = store
    out asExit(north)
    followDesc = 'into the office'
;

+ Surface, Heavy 'desk; battered old wooden'
    "It has certainly seen better days. "
;

midStair: Room 'On the Staircase'
    "About halfway up the lighthouse the spiral staircase passes an oak door
    to the east. "
    down = midStairDown
    up = midStairUp
    east = oakDoor
;

+ midStairDown: StairwayDown 'descending staircase; down spiral; stairs; it
    them'    
    destination = lobby 
    
    followDesc = 'back down the staircase'
;

+ midStairUp: StairwayUp 'ascending staircase; up spiral;
    stairs; it them' 
    
    destination = location
    
    travelDesc =  "You only get a short way further up the staircase before
        discovering that the way has been blocked by falling masonry, so you are
        forced to turn round and come back. "   
;

+ oakDoor: Door ->horrorDoor 'oak door'
    followDesc = 'through the door'
;

horrorChamber: Room 'Chamber of Horrors'
    /* 
     *   Normally it would be a bad idea to include a description of the PC's
     *   first reaction to a location in the desc property (we should 
     *   normally use roomFirstDesc for this), but since this room 
     *   description will only ever be displayed once, when the PC first 
     *   enters this room, it doesn't matter here.
     */
    "The sight that meets your eyes as you walk into this chamber astonishes,
    disgusts and terrifies you all at once. You are literally struck dumb with
    horror. You didn't know what to expect, but never in your wildest nightmares
    did you ever imagine anything like <i>this</i>..."
    east = horrorDoor
    out asExit(east)
;

+ horrorDoor: Door ->oakDoor 'door' 
;


//==============================================================================
/*   
 *   CLASS DEFINITION
 *
 *   Later in the game we'll be creating Can objects dynamically, so we need 
 *   to define a Can class.
 */

class Can: Thing 'can; round aluminium tin; tin'
    "It's round and made of tin -- or maybe aluminium. "
            
    /* 
     *   We want to keep track of the total number of Cans we've created, so 
     *   we do this in the construct() method. Note that we keep this count 
     *   on the Can class, not on individual Can objects.
     */
    construct()
    {
        inherited();
        Can.cansCreated ++;
    }
    cansCreated = 0
;


//==============================================================================
/*  
 *   THE MAIN NPC CODE STARTS HERE
 *
 *   There'll be two NPCs in this game. Bob, the shopkeeper, will be used to 
 *   demonstrate the standard method of implementing conversations in adv3Lite. 
 *   Sally, the other, will be used to illustrate an NPC who accompanies 
 *   the PC on his travel, as well as other features such as AgendaItems and 
 *   Conversation Nodes. 
 *
 *
 *   We'll start by modifying the standard library Actor class to provide 
 *   some tweaks we should find useful.
 */


modify Actor
    /* 
     *   We often don't know the name of NPCs when we first encounter them, 
     *   so that to begin with they have generic descriptions like 'a tall 
     *   man' or 'a blonde woman'. But once the PC knows an NPC's proper 
     *   name, that's the name that should be used. makeProper() is a custom 
     *   method we define to handle giving an NPC a proper name once we know 
     *   what it is.
     */
    
    makeProper()
    {
        /* 
         *   Calling addVocab in this way simultaneously changes the name of the
         *   Actor to properName, makes it proper (if every word in properName
         *   starts with a capital letter) and adds properName to this actor's
         *   vocabWords.
         */
        addVocab(properName);
        
        /*   
         *   Return the properName to the caller, so it can be used in 
         *   constructions like "<q>Hi, I'm <<properName>>,</q> the man 
         *   introduces himself.
         */
        return properName;
    }
    
    /* 
     *   properName is a custom property we define to contain the NPC's 
     *   proper name -- what he or she will be known by once the PC knows 
     *   his or her name.
     */
    properName = nil

    /*  
     *   The first time an actor's mentioned we expect him or her to be 
     *   described with the indefinite object ("A tall man is standing 
     *   here"); thereafter we'd expect to see the definite article ("The 
     *   tall man is standing here"). We therefore override theName (and add 
     *   a custom previouslyMentioned property) to produce this effect; the 
     *   first time theName is called it will return aName; thereafter it 
     *   will return the inherited version of theName.
     */
    
    timesMentioned = 0
    theName = (timesMentioned++ ? inherited : aName)
    
    /*  
     *   There aren't many portable objects in this game (unless the player 
     *   start collecting cans from Bob), but the standard library response 
     *   for throwing things at things is quite inappropriate when the 
     *   target is a person, (e.g. "The can hits Bob without any obvious 
     *   effect and falls to the floor") that we should in any case override 
     *   it.
     */
    
    iobjFor(ThrowAt)
    {
        check()
        {
            "You're not a child throwing a tantrum; you know better than to
            start throwing things at people. ";
        }
    }
    
;


//==============================================================================
/*  
 *   CODE FOR THE BOB NPC 
 *
 *   There's usually a lot of code and objects associated with an NPC, so 
 *   where an NPC is at all complex it's best to keep the NPC code separate 
 *   from the rest of the room and game code.
 *
 *   PERSON
 *
 *   There's not much to define on the Person object itself, since most of 
 *   Bob's behaviour will be implemented in his ActorStates and Topic 
 *   Entries. 
 */

bob: Actor 'tall man;;people[pl]; him'  @shop
    "He's a man with a gaunt face and a slight stoop; you'd estimate he was
    nearer sixty than fifty. "
       
    /* Remember, this is a custom property. We just defined it above/ */
    properName = 'Bob'
      
    /* 
     *   It's useful to define a globalParamName on an NPC, so we can refer 
     *   to him or her in paramater substitution string (such as '{the 
     *   bob/he}'). This is particular useful when the name of the NPC might 
     *   change in the course of play (e.g. from 'the tall man' to 'Bob' if 
     *   and when we learn Bob's name), but we don't know in advance when 
     *   this will happen. 
     */
    globalParamName = 'bob'
    
    /*   Customize the responses for ATTACK/HIT/KICK/KILL BOB and KISS BOB */    
    shouldNotAttackMsg = 'There seems to be no call for violence. '
    shouldNotKissMsg = 'Neither of you would enjoy that very much. '
    
;

/*  
 *   UNTHING
 *
 *   It's debatable whether the player who already knows that the tall man is
 *   called Bob should be able to refer to him as 'Bob' before the player 
 *   character has officially learned his name. In this example we're 
 *   assuming not, but you may well prefer to do things differently in your 
 *   own games, (in which case just include 'bob' or whatever in the NPC's 
 *   vocabWords property when you first define him or her.
 *
 *   But the problem then is what to do when the player does try to refer to 
 *   Bob before the PC has learned his name. If we haven't defined 'bob' in 
 *   bob's vocabWords the game will respond with "The word “bob” is not 
 *   necessary in this story. ", but that's simply untrue!
 *
 *   One way to get round this is with this little trick using an Unthing, 
 *   which we attach to Bob so it's always in scope when Bob is in scope. 
 *   Then if the player tries to refer to Bob before Bob has been named, 
 *   s/he'll get the response "You don't know anyone called Bob yet", which 
 *   is at least better than the default. Once Bob has named, the Unthing 
 *   will simply be ignored (since the parser always prefers any other 
 *   object to an Unthing if one is available).
 */


+ Unthing 'bob' 
    'You don\'t know anyone called Bob yet. '
;

/*  
 *   INITIAL ACTOR STATE
 *
 *   bobStacking is the ActorState Bob is in when he's not 
 *   actually engaged in conversation, but can be. When the PC talks to Bob, 
 *   we'll switch Bob to the bobTalking.
 *
 *
 */

+ bobStacking: ActorState
    /* This is the state Bob starts out in. */
    isInitState = true
    
    /* 
     *   commonDesc is not a library property; it's a custom property we're 
     *   defining to avoid the need to duplicate text in the specialDesc and 
     *   stateDesc properties.
     */
    commonDesc = 'busily stacking cans at the rear of the shop'
    
    /*   
     *   How Bob will be mentioned in a room description when he's in this 
     *   state.
     */
    specialDesc = "{The subj bob} {is} <<commonDesc>>. "
    
    /*   
     *   The stateDesc will be added to the end of the description provided 
     *   by bob.desc when Bob is in this ActiveState and the player examines 
     *   Bob.
     */
    stateDesc = "He's <<commonDesc>>. "    
;


/*
 *   HELLO TOPIC
 *
 *   A HelloTopic is used to handle Bob's response to BOB, HI, or TALK TO BOB,
 *   when Bob is in this ActorState. Since we're not also defining an
 *   ImpHelloTopic it will also be used when the PC addresses any conversational
 *   command to Bob (e.g. ASK MAN ABOUT THE WEATHER) while he's in the
 *   ActorState, in which case the conversational exchange defined in the
 *   HelloTopic will occur before the specific topic asked about is handled (and
 *   Bob will then switch into the bobTalkingState, as defined on this
 *   HelloTopic).
 *
 *   Note that HelloTopics are normally located in the ActorState the actor's in
 *   just prior to the start of the conversation.
 *
 *   By combining HelloTopic with  StopEventList we can vary the response Bob
 *   gives each time he is addressed.
 */

++ HelloTopic, StopEventList
    [
        '<q>Hello there!</q> you say.\b
        <q>Good morning, sir,</q> he replies, turning to you. ',
        
        '<q>Excuse me,</q> you say.\b
        <q>Yes?</q> he replies, turning to face you. ',
        
        '<q>Hello again,</q> you greet him.\b
        <q>Good morning once more, sir,</q> he answers, as he turns to face
        you. '
    ]
    
    /* 
     *   When this HelloTopic is invoked at the start of a conversation we'll
     *   switch Bob to the bobTalking state.
     */
    changeToState = bobTalking
;

/*   
 *   ACTOR STATE WHILE BOB IS IN CONVERSATION
 *
 *   To implement a conversation with Bob, we also define the the ActorState
 *   he's in when conversing with the player character
 */

+ bobTalking: ActorState
    /* 
     *   The specialDesc defines how Bob will be described in a room 
     *   description when he's in this ActorState. Note the use of {The subj
     *   bob} which will expand to either 'Bob' or 'The tall man', 
     *   depending on whether or not the PC has yet learned Bob's name.
     */
    specialDesc = "{The subj bob} {is} standing facing you, with one hand on his
        hip and the other holding a can. "
    
;

/*
 *   BYE TOPIC
 *
 *   We use a ByeTopic to end a conversation just as we use a HelloTopic to
 *   begin with. Since we're also defining an ImpByeTopic, this ByeTopic will
 *   only be triggered in the player explicitly bids Bob goodbye (e.g. with a
 *   BYE command). Note that ByeTopics are normally located in the state the
 *   actor is in while talking.
 */    
++ ByeTopic
    "<q>Well, cheerio then!</q> you say.\b
    <q>Good day, sir,</q> {the subj bob} replies, before returning to his stack
    of cans. "
    
    /* 
     *   Change Bob back to the bobStacking state when this ByeTopic is invoked.
     */
    changeToState = bobStacking
;

/*   
 *   IMP BYE TOPIC
 *
 *   An ImpByeTopic is just like a ByeTopic, except that it is triggered 
 *   when a conversation is terminated other than with an explicit GOODBYE. 
 *   This may happen if the Player Character simply walks away in the middle 
 *   of the conversation, or if s/he fails to address Bob for so many turns 
 *   (defined in the InConversationState's attentionSpan property) and Bob 
 *   gets bored waiting for the PC to speak. If we want to distinguish 
 *   between these two implicit Bye cases we can use LeaveByeTopic and 
 *   BoredByeTopic, but here we'll just use an ImpByeTopic to cover both 
 *   cases. 
 */

++ ImpByeTopic
    "{The subj bob} turns away and resumes stacking cans. "
    
    /* 
     *   Change Bob back to the bobStacking state when this ByeTopic is invoked.
     */
    changeToState = bobStacking
;

/*   
 *   ASK TOPIC, WITH SUGGESTION
 *
 *   An AskTopic is used to respond to a question such as ASK BOB ABOUT WHATEVER
 *   (which can be abbreviated to A WHATEVER one a conversation is underway).
 *   The AskTopic defined below will match the question ASK BOB ABOUT LIGHTHOUSE
 *   (because 'lighthouse' is defined in the vocabWords of the lighthouse
 *   object). But note that the PC must first know about the lighthouse before
 *   this topic becomes available.
 *
 *   By giving this AskTopic a name we include it in the topic inventory - the
 *   list of suggested topics for conversation displayed in response to a TOPICS
 *   command or to TALK ABOUT BOB. Note that the topic will only be suggested
 *   when the TopicEntry becomes available, i.e. when the PC knows about the
 *   lighthouse.
 */
++ AskTopic @lighthouse
    "<q>So what happened at the lighthouse?</q> you wanted to know.\b
    <q>Well,</q> he begins, <q>it was like this -- all those years ago...</q> he
    breaks off, as if wrestling with himself, then suddenly snaps, <q>Just don't
    go there, that's all!</q> "
    
    /* The name we use to describe this topic in a list of suggested topics. */
    name = 'the lighthouse'
;

/*
 *   TELL TOPIC, SUGGESTED
 *
 *   TellTopic is the converse of AskTopic. It defines the response to a 
 *   command like TELL BOB ABOUT WHATEVER (in this case TELL BOB ABOUT 
 *   MYSELF or T MYSELF). We give it a name so that it 
 *   appears in a list of suggested topics (note we don't have to do this; 
 *   it's up to the game author whether a particular TopicEntry should be 
 *   suggested or not). 
 *
 *   By combining the TellTopic with ShuffledEventList we can vary the 
 *   response. This is often a good idea for creating more life-like NPCs.
 */
++ TellTopic, ShuffledEventList @me
    /* 
     *   When we define two lists for a ShuffledEventList, the items in the 
     *   first list are first shown in order.
     */
    [
        '<q>I\'m new around here,</q> you say.\b 
        <q>That probably explains why we haven\'t met before,</q> he remarks. '
    ]
    
    /*  
     *   After the items in the first list have been shown, the items in the 
     *   second list are displayed in shuffled-random order. We don't need to
     *   define both lists; if we only define one, it will be used as a 
     *   shuffled list.
     */    
    [
        '{The subj bob} listens politely while you tell him a chunk of you
        life-history. ',
        
        '{The subj bob} does his best to pretend he finds you as fascinating a
        topic of conversation as you appear to. ',
        
        '<q>How interesting!</q> he mutters. '
    ]
    
    /* The name for the list of suggested topics */
    name = 'yourself'
;


/*  
 *   Another ASK TOPIC
 *
 *   This time we mix it in with a StopEventList, which will display each 
 *   item in turn and then keep displaying the last one.
 *
 *   The @bob means the bob object, of course, but while we're talking to bob
 *   this can be referred to as 'himself', so this topic will match ASK BOB 
 *   ABOUT HIMSELF.
 */
++ AskTopic, StopEventList @bob
    [
        /* 
         *   We can't include a double-quoted string in an EventList, but we 
         *   can include a function pointer, which is what wrapping a 
         *   double-quoted string in the {: } short-form anonymous function 
         *   notation actually does. This enables us to invoke 
         *   bob.makeProper() using the <<>> syntax; bob.makeProper() 
         *   returns 'Bob', so this is what it displays, but it also carries 
         *   out the corresponding changes on the bob object.
         *
         *   An alternative would have been to write:
         *
         *   '<q>By the way, I don\'t think I caught your name,</q> you 
         *   say.\b <q>I\'m '+ bob.makeProper() + ',</q> he tells you. '
         */        
        {: "<q>By the way, I don't think I caught your name,</q> you say.\b
            <q>I'm <<bob.makeProper()>>,</q> he tells you. " },
        
        '<q>Have you worked here long?</q> you ask.\b
        <q>Only the last forty years,</q> he replies. ',
        
        'You can\'t think of anything to ask him about himself right now. '
    ]    
    name = 'himself'
    
    /* 
     *   Once the player has seen the first two responses, the response to 
     *   ASK BOB ABOUT HIMSELF ceases to be interesting, so there's no point 
     *   in suggesting it any longer. So we'll only suggest it twice (note 
     *   that the default value of timesToSuggest is 1).
     */
    timesToSuggest = 2
    
    /*
     *   Normally ASK BOB ABOUT WHATEVER would trigger the greeting protocols
     *   (the HelloTopic) when Bob is in his ConversationReadyState. But the
     *   final response suggests that no conversational exchange actually 
     *   takes place, so it would be inappropriate to display a greeting 
     *   only to have a message say that you can't think of anything to ask. 
     *   We can avoid this by marking this TopicEntry as non-conversational 
     *   once the final response is reached. Since we've already defined 
     *   timesToSuggest = 2 this is equivalent to marking it as 
     *   non-conversational once curiosity has been satisfied.
     */    
    isConversational = (!curiositySatisfied)    
;

/*  
 *   ASK TELL SHOW TOPIC
 *
 *   An AskTellShowTopic responds to ASK ABOUT, TELL ABOUT and SHOW 
 *   commands, so that this one will respond to ASK BOB ABOUT BLONDE, TELL 
 *   BOB ABOUT BLONDE, or SHOW BLONDE TO BOB.
 */
++ AskTellShowTopic, StopEventList @sally
    [
        {: "<q>Who's that blonde woman over there?</q> you ask.\b
            <q>That's <<sally.makeProper()>>, sir,</q> he replies. "
        },
        
        '<q>Is {the subj sally} a regular customer here?</q> you enquire.\b
        <q>Oh yes, sir, one of my best,</q> he tells you. ',
        
        'You\'ve asked enough about {the sally} for now; you don\'t want to
        give {the bob} the impression that you\'re fixated on her! '
    ]
    
    /* 
     *   We want this topic to be suggested as 'ask Bob about the blonde 
     *   woman' before we learn Sally's name and 'ask Bob about Sally' 
     *   thereafter.
     */
    name = (sally.theName)
    
    /*   
     *   The first question presupposes that Sally is present to be asked 
     *   about, so we make this TopicEntry active only when Sally is in the 
     *   shop.
     */    
    isActive = (sally.isIn(shop))
    timesToSuggest = 2
    isConversational = (!curiositySatisfied)
;


++ AskTopic, StopEventList @tTown
    [
        /* 
         *   Until the player sees this response, the player character 
         *   hasn't even heard of the troubles. The tag <.reveal troubles> 
         *   notes the fact that the topic of troubles has now been 
         *   mentioned. Note that 'troubles' is an arbitrary string here; we 
         *   could have used <.reveal xp1-q34r>, except it wouldn't have 
         *   been so meaningul. Had we for example wanted to distinguish Bob 
         *   mentioning the troubles from Sally mentioning the troubles, we 
         *   could use <.reveal bob-troubles> and <.reveal sally-troubles>.
         */        
        '<q>What\'s this town like?</q> you ask.\b
            <q>Oh great. Just great,</q> he replies. Lowering his voice he adds,
            <q>now that the troubles are over.</q><.reveal troubles> ',
                
        'He provides you with a whole lot of information about places to eat,
        shop, visit, and avoid throughout the turn. You don\'t take a tenth of
        it in. '
    ]
    name = 'the town'
;


/*  
 *   ASK TELL TOPIC
 *
 *   Since this is an AskTellTopic it will be used as a response to both ASK 
 *   BOB ABOUT TROUBLES and TELL BOB ABOUT TROUBLES.
 */
++ AskTellTopic, StopEventList @tTroubles
    [
        /*  
         *   The first response to ASK ABOUT TROUBLES mentions the 
         *   lighthouse, so once the player has seen this response, the PC 
         *   knows about the lighthouse. We can mark this by using 
         *   <.known lighthouse>. 
         */        
        '<q>You said something about some troubles,</q> you remark, <q>what
            were they all about?</q>\b
        <q>Well,</q> he begins, <q>it all began up at the lighthouse...</q>
            he breaks off, shaking his head, <q>No, you really don\'t want to
        know, you really don\'t -- believe me!</q> <.known lighthouse> ',
        
        
        '{The subj bob} steadfastly refuses to tell you anything more about the
        troubles. '
    ]
    
    /* 
     *   Here we test whether the tag 'troubles' has been revealed in order 
     *   to decide whether this TopicEntry is active.
     *
     *   tTroubles is a Topic, not a Thing (see below), so it starts out 
     *   known by default. As an alternative to using <.reveal troubles> and 
     *   testing for gRevealed('troubles') here we could have overridden 
     *   isKnown to nil on tTroubles and then used gSetKnown(tTroubles) to 
     *   make it known once Bob mentioned the troubles. 
     */
    isActive = gRevealed('troubles')
    name = 'the troubles'
;


/*   
 *   TALK TOPIC
 *
 *   A TalkTopic responds to TALK ABOUT SO-AND-SO. In this case, TALK ABOUT THE
 *   WEATHER.
 *
 *   Note that tWeather is another Topic (defined below) not a Thing. Using a
 *   lower case initial t to distinguish Topics from Things in this way is just
 *   a convention I employ, not a requirement; but it's useful to adopt some
 *   such convetion.
 */
++ TalkTopic @tWeather
    "<q>Nice weather we're having,</q> you remark.\b
    <q>Not bad for the time of year, sir,</q> he agrees. "    
    name = 'the weather'
;

/*   
 *   ASK FOR TOPIC
 *
 *   We use an AskForTopic to handle commands like ASK BOB FOR SOMETHING. 
 *   Since Bob is desribed as stacking cans we'll allow the PC to ask for a 
 *   can; but since it's irrelevant to the plot, we shan't suggest it. 
 */
++ AskForTopic @cans
    topicResponse()
    {
        "<q>Can I have one of those cans please?</q> you ask.\b
        <q>Sure,</q> he replies. He turns round, picks up a can, and then
        turns back and hands it to you. <q>Here you are,</q> he announces. ";
        
        /*  Create a new Can object and then move it to the PC's inventory. */
        local obj = new Can;
        obj.moveInto(me);
    }
;

/*   
 *   ALTERNATIVE RESPONSE
 *
 *   We use another AskForTopic to provide an alternative response to a
 *   conversational command when a particular condition (defined in the isActive
 *   property) holds. By giving it a higher matchScore (the + property in the
 *   template) we make sure it's used in preference to the previous AskForTopic
 *   when its isActive property becomes true.
 *.
 *
 *   Here we use the second AskForTopic to put a limit on the number of cans the
 *   PC can ask for, since we don't want the game to generate an infinite number
 *   of dynamically-created cans. Ten cans should be more than enough, so we'll
 *   stop when 10 cans have been created.
 *
 *   The other (and possibly neater way) of providing an alternative response is
 *   to use an AltTopic, which will be illustrated below.
 */
++ AskForTopic +110 @cans
    "You've had more than enough cans for now. "
    isConversational = nil
    isActive = Can.cansCreated >= 10
;


/*   
 *   ASK TELL GIVE SHOW TOPIC
 *
 *   An AskTellGiveShowTopic provides the same response to ASK BOB ABOUT X, 
 *   TELL BOB ABOUT X, SHOW X TO BOB and GIVE X TO BOB. Here we'll use it for
 *   asking about, telling about, showing or giving cans.
 *
 *   There's one complication, though; the PC can only give Bob a can if the 
 *   PC is holding a can, and since the Can objects given to the player are 
 *   created dynamically, we don't have an object name for any such can. We 
 *   can instead test for an object belonging to the Can class.
 *
 *   If it were allowed, we'd simply express the matchObj for this 
 *   TopicEntry as a list:
 */
++ AskTellGiveShowTopic [cans, Can]
    "<q>What's in those cans?</q> you ask.\b
    <q>Baked beans,</q> he replies briskly, <q>not just any baked beans, though
    -- the beans in those cans are environmentally-friendly anti-carcogenic
    organic high-fibre baked beans -- the very best!</q> "   
    
;

/*  
 *   DEFAULT ASK TOPIC
 *
 *   The chances are the player will try to ASK Bob about topics for which we
 *   haven't replied a response. We can use a DefaultAskTopic to deal with 
 *   these commands. To avoid making the NPC look like a talking robot, it's 
 *   best to vary such responses, so we also make the DefaultAskTopic a 
 *   ShuffledEventList.
 */

++ DefaultAskTopic, ShuffledEventList
    [
        '{The subj bob} gives a puzzled frown, as if he didn\'t understand your
        question. ',
        
        '<q>Yes, well,</q> he begins, and then gabbles such a rapid reply that
        you don\'t catch a word of it. ',
        
        '<q>The way I see it...</q> he begins; but then the rest of his reply
        is lost in a fit of coughing. '
    ]
;

/*   
 *   DEFAULT TELL TOPIC 
 *
 *   We use DefaultTellTopic to cater for topics we haven't provided a 
 *   specific TELL ABOUT response to.
 */
++ DefaultTellTopic
    "{The subj bob} listens politely as you rattle on. "
;

/*  
 *   We can use a CommandTopic to provide a response to particular 
 *   commands such as BOB, JUMP (as here).
 *
 *   CommandTopic doesn't make it particularly easy to match command 
 *   involving particular objects, such as BOB, TAKE THE RED BALL or BOB, 
 *   PUT THE RED BALL IN THE GREEN BOX; to match such commands you'd need to 
 *   override the matchTopic() method of the CommandTopic. Alternatively you 
 *   could just download and use the TCommand extension.
 */

++ CommandTopic @Jump
    "<q>Jump!</q> you cry!\b
    {The subj bob} is so startled that he jumps. "
;

/*  
 *   DEFAULT COMMAND TOPIC
 *
 *   We use a DefaultCommandTopic to handle all orders given to the Bob for
 *   which we haven't provided a customised response. We can use the
 *   actionPhrase property to represent the command the player just issued.
 */
++ DefaultCommandTopic
    "<q>\^<<actionPhrase>>!</q> you command.\b    
    <q>Not wishing to be rude, sir, but I don't reckon you have any call to be
    bossing me around,</q> he complains. "
;
     
++ DefaultAskForTopic
    "<q>I'm afraid I don't think I can help you there, sir,</q> he replies. "
;


//==============================================================================
/*  
 *   CODE FOR THE SALLY NPC
 *
 *   Sally is a more complex NPC than Bob, in that she'll lead the PC to the
 *   lighthouse and then follow him around. We also use her to illustrate
 *   ConvNodes and AgendaItems.
 *
 *   To begin with a summary: Sally starts out in the shop looking for clothes,
 *   but can't be talked to while she's in that state. As soon as she hears Bob
 *   mention the troubles she goes outside the shop to wait for the PC. When the
 *   PC emerges from the shop she offers to take him to the lighthouse. If he
 *   refuses, the game ends then and there. If he accepts she leads him to the
 *   lighthouse. Once they arrive at the lighthouse she will follow the PC
 *   (there's no particular reason for this swap of leading character other than
 *   to demonstrate the two different ways in which an NPC can be made to
 *   accompany the PC). Once they start to explore the lighthouse together they
 *   come face to face with the origin of the troubles.
 *
 */

sally: Actor 'blonde woman; petite pretty; people[pl]; her' @shop
    "She's a petite blonde, with a pretty round face. "
    
    properName = 'Sally'
    
    globalParamName = 'sally'
    
    shouldNotAttackMsg = 'You are not the sort of man that goes round attacking
        defenceless women. '
    
    shouldNotKissMsg = ('You\'d better not; ' + (gRevealed('married') ?
                             'you\'ve already told her you\'re married. ' : 'you
                                 don\'t know her well enough. '))
;

/*  
 *   We add an Unthing to Sally as we did for Bob, to handle attempts to 
 *   refer to Sally before the PC has learned her name.
 */
+ Unthing 'sally' 
    'You don\'t know anyone called Sally yet. '
;


/*  
 *   NO RERSPONSE STATE
 *
 *   A No Response State is an ActorState in which an NPC will not respond to
 *   any conversational commands. It can be used to represent an NPC who is
 *   preoccupied, stand-offish, unconscious, or even dead. Here we start Sally
 *   off in a No Response State since we don't want the PC to talk to her until
 *   they meet outside the shop. While he's in the shop the PC should
 *   concentrate on talking to Bob. We make an ordinary actor state behave as a
 *   No Response State simply by defining its noResponse property to display the
 *   reason the actor is refusing to respond.
 *
 *   If we mix in an EventList class with an ActorState, the EventList's
 *   doScript() method will be called every tutn the NPC is in the state, so
 *   that we can display a list of messages indicating that that NPC is actually
 *   doing something. Here we make the ActorState also a ShuffledEventList
 *   so that Sally looks a bit livelier than a tailor's dummy while she's
 *   shopping for clothes.
 */

+ sallyShopping: ActorState, ShuffledEventList
    /* This is the state Sally starts out in. */
    isInitState = true
    
    /* 
     *   This is how Sally will be listed in a room description when she's in
     *   this ActorState.
     */
    specialDesc = "{The subj sally} is standing by the clothes rack, carefully
        inspecting everything that's on offer. "
    
    /* 
     *   This will be appended to the description of Sally when she's in this
     *   ActorState.
     */
    stateDesc = "She's standing by the clothes rack, inspecting what\'s on
        offer. "
    
    
    
    /*   
     *   The list of random messages to display while the actor is in this 
     *   state.
     */
    eventList = [
        '{The subj sally} takes a coat from the rack, holds it against her body,
        then shakes her head and returns it to the rack. ',
        
        '{The subj sally} continues rifling through the rack. ',
        
        '{The subj sally} picks up a hat and tries it on. She pulls it down over
        her face, frowns, and then puts it back. ',
        
        {: "{The subj sally} takes a <<rand('skirt', 'blouse', 'dress',
                                           'jumper')>> off the rack and mutters
            something disapproving about the wrong shade of <<rand('blue',
                'green', 'yellow', 'orange', 'pink', 'mauve')>>. "
        },
        
        '{The subj sally} struggles to remove a pair of trousers from the rack,
        then decides that they\'re too long, so struggles to put them back
        again. '
    ]
    
    /* 
     *   It would be intrusive to see these messages every turn, so we'll 
     *   start off displaying them on average on two turns out of three.
     */
    eventPercent = 67
    /*   
     *   Once the player has seen all these messages once, it's probably 
     *   best to make them less frequent before they start to seem obviously 
     *   repetitive and tiresome, so we'll reduce the frequency to one turn 
     *   in three once after displaying five messages.
     */
    eventReduceTo = 33
    eventReduceAfter = 5
    
    /*   
     *   When Sally leaves the shop the default message would be "Sally/The 
     *   blonde woman leaves to the north." We replace that here with 
     *   something more appopriate to the context.
     */
    sayDeparting(conn)
    {
        "Then she turns away again and hurries out of the shop. ";
    }
    
    /*  
     *   If a noResponse method is defined, as here, it will be used as the
     *   response to all conversational commands directed at Sally while she's
     *   in this state.
     */
    noResponse =  "You know better than to interrupt a woman when she's hunting
        for bargains on the clothes rack. "
;


/*  
 *   ACTOR STATE
 *
 *   This ActorStatre is used while Sally is waiting outside the shop.
 */
+ sallyStreetState: ActorState
    specialDesc = "{The subj sally} is standing just outside the shop. "
;


/*  
 *   We put Sally into this state when she's leading (i.e. when she wants the
 *   player character to follow her.
 */
+ sallyLeadingState: ActorState
    specialDesc = "{The subj sally} is right beside you. "
    stateDesc = "She's right beside you. "
    
    activateState(actor, oldState)
    {
        /* 
         *   Most of the work of acting as an actor the PC can follow is
         *   actually done by a FollowAgendaItem, so here we add a suitable
         *   FollowAgendaItem to Sally's agendaList when she enters this state.
         */
        actor.addToAgenda(sallyLeadingAgenda);
    }
;

/* 
 *   FOLLOW AGENDA ITEM
 *
 *   A FollowAgendaItem is used when we want the player character to be able to
 *   follow another actor, in this case Sally.
 */
     
+ sallyLeadingAgenda: FollowAgendaItem
    /* 
     *   The list of TravelConnectors we want Sally to lead the player character
     *   through. When we get to the end of the list, the FollowAgendaItem is
     *   done with.
     */
    connectorList = [street.east, road.south, hillTop.southeast]
    
    /*   
     *   The noteArrival method is called after Sally has been followed to the
     *   final destination along her route. Here we use it to change Sally to a
     *   different ActorState, which would be a fairly common use of this
     *   method.
     */
    noteArrival() 
    {
        getActor.setState(sallyArriving);
    }
    
    /*  
     *   The arrivingDesc is shown each turn just after the player character has
     *   followed the actor. The default is to say "Sally is waiting for you to
     *   follow her to the [whichever direction]. Here we use the default except
     *   right at the end, when we've arrived at the cliff, when we display a
     *   custom message.
     */
    arrivingDesc() 
    { 
        if(me.isIn(cliff))
            "{The subj sally} comes to a stop outside the old lighthouse
            and turns to face you. ";
        else
            inherited; 
    }
    
    /* 
     *   The sayDeparting(conn) message is used to describe the player character
     *   following the actor each time they move. Here we customize it to make
     *   use of the custom followDesc property defined on another of
     *   TravelConnectors above.
     */
    sayDeparting(conn)
    {
        "You follow Sally <<conn.followDesc>>. ";
    }
;

/*   
 *   ACTOR STATE
 *
 *   Sally will leave this ActorState almost as soon as she enters it. It's 
 *   purpose is to smooth the transition from Sally leading the PC to Sally 
 *   following the PC.
 */

+ sallyArriving: ActorState
    activateState(actor, oldState)    
    {      
        
        sally.actorSay('<q>Well, here we are then,</q> she tells you, <q>This is
            where it all started. Shall we go inside?</q> 
            <.convnode lighthouse>');      
    }    
    
    specialDesc = "{The subj sally} is standing just by the lighthouse door. "
    
    /* As soon at the PlayerCharacter moves Sally will start following him. */
    beforeTravel(traveler, connector)
    {
        getActor.setState(sallyFollowingState);
    }
    
    
;

/*  
 *   ACCOMPANYING STATE
 *
 *   To make an actor follow the PC around we actually need to call the
 *   startFollowing method on the actor. But we often want the actor to be in
 *   particular ActorState while following, so here we define an ActorState for
 *   the purpose which calls Sally's startFollowing() method when it's
 *   activated. Once she enters this state, Sally will remain in it for the rest
 *   of the game.
 */

+ sallyFollowingState: ActorState
    specialDesc = "{The subj sally} is at your side. "
    
    /* 
     *   The arrivingTurn() method is called each time the NPC arrives in a 
     *   at a location while following the PC. Here we use it to make Sally 
     *   say or do something via an InitiateTopic keyed on the location just 
     *   arrived at; calling sally.initiateTopic(obj) will cause the 
     *   corresponding InitiateTopic @obj to be triggered.
     */
    arrivingTurn()
    {
        sally.initiateTopic(sally.location);
    }
    
    
    /* 
     *   Tell Sally to start following the player character around when she
     *   enters this ActorState.
     */
    activateState(actor, oldState)
    {
        actor.startFollowing();
    }
   
    
    beforeTravel(traveler, connector)
    {
        if(connector == road.west)
        {
            "<q>I'll wait here for you,</q> {the subj sally} announces. ";
            sally.stopFollowing;
        }
    }
    
    afterTravel(traveler, connector)
    {
        if(traveler == me && connector == road)
            sally.startFollowing();
    }
    
    sayFollowing(oldLoc, conn)
    {
        /* In case conn is nil fall back to an empty travel description. */
        local travelMsg = conn ? ' ' + conn.followDesc : '';
        
        "{The subj sally} follows you<<travelMsg>>. ";
    }
;

/*  
 *   INITIATE TOPIC
 *
 *   An InitiateTopic is triggered by an explicit call to 
 *   actor.initiateTopic. It's use to make an NPC react to specific things 
 *   in the game. These InitiateTopics are all triggered from the 
 *   arrivingTurn() method of sallyFollowing to make Sally respond to 
 *   arriving in various locations. Note that we're also locating all these 
 *   InitiateTopics in the sallyFollowingState (the definition of the 
 *   SallyAccompanyingInTravelState forms no part of the object containment 
 *   hierarchy).
 */
++ InitiateTopic @lobby
    topicResponse()
    {
        "<q>Well, this is it,</q> {the subj sally} announces, <q>Let\'s take a
        look around.</q> ";
        
        /*  
         *   This is the way to add a DelayedAgendaItem (for which see 
         *   below) to Sally's agenda list.
         *
         */
        sally.addToAgenda(sallyImpatientAgenda.setDelay(4));
        /* 
         *   We only want this InitiateTopic to fire on the first time Sally 
         *   enters the lobby. Setting isActive to nil here disables this 
         *   InitiateTopic for subsequent occasions.
         */
        isActive = nil;
    }
;

++ InitiateTopic @midStair
    "<q>That's it,</q> {the subj sally} announces, pointing to the oak door,
    <q>the answer to all your questions lies through there. Enter if you
    dare!</q> "
;

++ InitiateTopic @horrorChamber
    topicResponse()
    {
        "She lets out a piercing scream; but you're only dimly aware of
        her presence; as your stomach threatens to empty its contents, the room
        seems to start spinning around you, and then everything goes blank.\b";
        
        /*  
         *   We'll end the game at this point (it's only a demo, after all!).
         *   Note how we can use finishGameMsg to display a custom finishing
         *   message.
         */
        finishGameMsg('YOU HAVE FAINTED', [finishOptionUndo]);
    }
;

++ InitiateTopic @road
    "<q>I'm not going back into town until I've shown you what's in the
    lighthouse,</q> {the subj sally} warns you. "
;

++ InitiateTopic, StopEventList @store
    [
        '<q>They took everything out after the troubles,</q> {the subj sally}
        remarks, <q>there\'s nothing interesting in this part of the lighthouse
        now.</q> ',
        
        '<q>Like I said, there\'s nothing interesting left in this part of the
        lighthouse now,</q> {the subj sally} remarks, <q>let\'s look somewhere
        else.</q> '
    ]
;


++ InitiateTopic, StopEventList @office
    [
        '<q>There doesn\'t seem to be much here, does there?</q>
        {the subj sally} declares. ',
        
        '{The subj sally} glances around the room without much interest. '
    ]
;

++ InitiateTopic @cliffPath
    "<q>Well, there was a <i>lot</i> of point in coming here, wasn\'t there!</q>
    {the subj sally} declares. "
;


/*   
 *   TOPIC GROUP
 *
 *   We'll define a few conversational responses for Sally; these could all 
 *   go directly in the sally object, but we can also use a TopicGroup for 
 *   the purpose (and since there are so many other kinds of thing going 
 *   directly in the actor, using a TopicGroup can seem neater).
 */

+ TopicGroup
    /* 
     *   The TopicEntries in this TopicGroup will only be reachable when this
     *   isActive condition is true. As a matter of fact it will true 
     *   practically all the time the PC is in a position to talk to Sally in
     *   any case, so we're just illustrating the principle here. 
     *   In a real game you might want to use a more restrictive condition.
     */
    isActive = (sally.curState is in(sallyLeadingState, sallyFollowingState,
                                     sallyArriving))
;

++ AskTopic,  StopEventList @sally
    [
        '<q>Are you married, Sally?</q> you ask.\b
        <q>I was,</q> she tells you, <q>but then the troubles came. But how
        about you? Do you have a family?</q><.convnode family> ',
        
        '<q>How did the troubles...?</q> you begin.\b
        <q>End my marriage?</q> she asks, <q>Well, it\'s a long story. Maybe
        I\'ll tell you about it some other time.</q> ',
        
        '<q>Is there a man in your life now?</q> you ask.\b
        <q>I can but keep hoping,</q> she smiles coyly. ',
        
        '<q>Tell me more about yourself, Sally,</q> you say.\b
        <q>Some other time,</q> she replies. '
    ]
    name = 'herself'
    timesToSuggest = 3
;

/*
 *   ALTTOPIC
 *
 *   An AltTopic can be used to provide an alternative response to a
 *   conversational command. It responds to the same command as the TopicEntry
 *   it's located in (in this case ASK SALLY ABOUT HERSELF) but is used in
 *   preference to its parent TopicEntry when its own isActive property is true;
 *   in this case when the player character doesn't know Sally's name.
 */

+++ AltTopic
    "<q>I'm sorry, I don't think we've been introduced,</q> you say, <q>You
    are...?</q>\b
    <q>I'm <<sally.makeProper()>>,</q> she tells you, <q>I've lived round here
    most of my life.</q>"
  
    isActive = !sally.proper
;

   /* 
    *   ASK TELL TOPIC
    *
    *   Note that as an alternative to using the @obj template syntax to 
    *   make a TopicEntry match the single object obj, we can provide a list 
    *   of objects that a TopicEntry can match. Here we make asking/telling 
    *   Sally about the lighthouse equivalent to asking/telling her about 
    *   the troubles (or about the oakDoor once the PC has seen it)
    */
++ AskTellTopic [lighthouse, tTroubles, oakDoor]
    "<q>So what were the troubles, and what are we going to find at the
    lighthouse?</q> you ask.\b
    <q>You'll see when we get there,</q> she assures you. "
    name = 'the lighthouse'
;

/*   
 *   ALT TOPIC
 *
 *   We also provide a whole series of AltTopics to tailor the response to 
 *   ASK/TELL SALLY ABOUT LIGHTHOUSE/TROUBLES according to the current 
 *   situation.
 */
+++ AltTopic
    "<q>So, what did happen in the lighthouse?</q> you ask, <q>is that where the
    troubles started?</q>\b
    <q>The answers are all in the lighthouse,</q> she tells you, <q>if you want
    to find out what happened, you'll have to go inside.</q> "
    
    isActive = me.hasSeen(lighthouse)
;

+++ AltTopic
    "<q>So, what did happen here?</q> you want to know, <q>And what were the
    troubles?</q>\b
    <q>Keep looking,</q> she tells you, <q>you'll see soon enough!</q> "
    name = 'the troubles'
    isActive = me.location is in (lobby, store, office)
;

+++ AltTopic
    "<q>What's on the other side of that door?</q> you ask, <q>is that where
    the troubles started?</q>\b
    <q>If you go through it you'll see,</q> she tells you. "    
    name = 'the troubles'
    isActive = me.isIn(midStair)
;

++ TellTopic, StopEventList @me
    [
        '<q>I\'m new to this area,</q> you tell her.\n
        <q>So I gathered,</q> she remarks. ',
        
        'You carry on telling her about yourself, but you sense she isn\'t
        really listening. '
    ]
;


++ DefaultCommandTopic
    "<q>My husband used to try telling me what to do all the time, too;</q> she
    remarks, <q>frankly, it's not something I find attractive in a man.</q> "
;

/*   
 *   DEFAULT GIVE SHOW TOPIC
 *
 *   We can use a DefaultGiveShowTopic to provide a response to attempt to 
 *   Give or Show anything to Sally (for which we haven't provided any more 
 *   specific handling).
 */

++ DefaultGiveShowTopic
    "<q>Yes, {he subj dobj}{\'s} {a subj dobj},</q> she observes, <q>very
    interesting, I\'m sure!</q> "
;

/*   
 *   DEFAULT ANY TOPIC
 *
 *   A DefaultAnyTopic will match anything for which we haven't provided a 
 *   more specific response. Here, for example, it would match ASK SALLY 
 *   ABOUT HER MOTHER, or TELL SALLY ABOUT CHINESE COOKERY. A 
 *   DefaultAnyTopic is used as a last resort: any other kind of 
 *   DefaultXXXXTopic (e.g. DefaultAskTopic, DefaultTellTopic, 
 *   DefaultGiveShowTopic) will be used in preference to it (so our 
 *   DefaultGiveShowTopic will still work, but the DefaultAnyTopic would 
 *   have handled GIVE & SHOW if we hadn't defined a DefaultGiveShowTopic.
 *
 *   Here we use a DefaultAnyTopic in place of defining separate a 
 *   DefaultAskTopic and DefaultTellTopic (given that most other kinds have 
 *   already been covered). We could have done almost the same job in this 
 *   particular context with a DefaultAskTellTopic.
 */

++ DefaultAnyTopic
    "<q>We can talk later; let's just get to the lighthouse,</q> she replies. "
;

/*   
 *   ALT TOPIC
 *
 *   We can use AltTopics with DefaultTopics as well as other kinds of 
 *   TopicEntry. Normally one would use a ShuffledEventList to vary the 
 *   response to a DefaultTopic, but here we'll use a whole series of 
 *   AltTopics to vary the response according to the situation.
 */
+++ AltTopic
    "<q>Let\'s talk about that some other time,</q> she suggests, <q>I think we
    should go back to the lighthouse before it gets dark.</q> "
    isActive = me.hasSeen(lighthouse) && !me.canSee(lighthouse)
;

+++ AltTopic
    "<q>All this talk!</q> she complains, <q>anyone would think you were afraid
    to go in there!</q> She nods towards the lighthouse. "
    isActive = me.isIn(cliff)
;

+++ AltTopic, ShuffledEventList
    [
        '<q>This doesn\'t seem the right place to talk about that,</q> she
        replies, <q>I thought you were anxious to find out about the
        troubles!</q> ',
        
        '<q>Later,</q> she urges you, <q>in any case, you\'ll see everything
        differently once you\'ve seen the source of the troubles.</q> ',
        
        '<q>We can discuss that some other time,</q> she tells you, <q>right
        now, let\'s concentrate on what we came for!</q> '
    ]
    isActive = me.location is in (lobby, store, office, midStair)
;

//------------------------------------------------------------------------------
/*   
 *   CONVERSATION NODES
 *
 *   A Conversation Node, or ConvNode (as the class is actually called) 
 *   represents a particular point in a conversation at which a particular 
 *   set of responses becomes appropriate. For example, if an NPC asks a 
 *   question, it may be pertinent to reply YES or NO immediately after, 
 *   whereas interjecting YES or NO into the conversation at some later or 
 *   earlier point of the conversation would either be meaningless, or else 
 *   would have some quite different meaning. 
 *
 *
 *   There are basically two types of Conversation Node that one might 
 *   typically be implemented in adv3Lite, which one might for convenience 
 *   called 'open' and 'closed' (though this is nowhere defined in the 
 *   library's nomenclature). An 'open' node is one at which a particular 
 *   set of responses becomes appropriate (such as YES or NO or some more 
 *   detailed reply), but the player doesn't have to use one of them; the 
 *   player can take the opportunity to use one of these responses or ignore 
 *   it (though once ignored, the opportunity is lost, as it would be in a 
 *   real conversation).
 *
 *   A 'closed' node, on the other hand, is where the NPC demands an answer 
 *   and won't let the conversation move on until s/he receives one. This is 
 *   the more laborious kind of Conversation Node to implement, but it's the 
 *   one we'll illustrate first, as it demonstrates more of the features of 
 *   ConvNodes, and once we've implemented a 'closed' node the 'open' ones 
 *   will seem easy!
 *
 *   The ConvNode below is used for Sally to offer to show the PC to the 
 *   lighthouse; she'll demand that he says yes or no.
 */

+ ConvNode 'troubles'   
;


/*   
 *   NODE CONTINUATION TOPIC
 *
 *   A NodeContinuationTopic can be used to let the actor remind the player
 *   character she's waiting for an answer to her question while she's at this
 *   ConvNode. Here we mix it in with ShuffledEventList to vary the 'nag'
 *   messages displayed.
 */
++ NodeContinuationTopic, ShuffledEventList
    
    [
        '<q>The lighthouse,</q> {the sally/she} reminds you, <q>I offered
        to take you to see it. Would you like me to?</q> ',
        
        '<q>I\'m still waiting to hear if you\'d me to show you the
        lighthouse,</q> {the sally/she} reminds you. ',
        
        '<q>I\'ve been kind enough to offer to show you the lighthouse, so
        I think I deserve an answer,</q> {the sally/she} remarks, <q>So --
        are you coming?</q> '
    ]
    /*  
     *   Sally would seem needlessly importunate if she nagged the PC for a
     *   response on every turn he didn't say something, so we'll use one of
     *   these messages on average only every other turn.
     */
    eventPercent = 50
; 

/* 
 *   NODE END CHECK
 *
 *   A NodeEndCheck object can be used to prevent the player character from
 *   ending the conversation while the actor is at this ConvNode.
 */
++ NodeEndCheck
    /*  
     *   Since Sally is insisting on an answer, we need to block the various 
     *   ways in which the player could simply end the conversation. Walking 
     *   away from her might be one way; saying goodbye would be another. We 
     *   use canEndConversation() to block both.
     */
    canEndConversation(actor, reason)
    {
        if(reason == endConvLeave)
            "<q>Don't walk away when I'm talking with you!</q> {the subj sally}
            protests, <q>I asked you a question: do you want me to show you the
            lighthouse or don't you?</q> ";
        if(reason == endConvBye)
            "<q>Don't you <q>goodbye</q> me when I ask you a question!</q> {the
            subj sally} storms, <q>Now, are you coming with me to the lighthouse
            or aren't you?</q> ";
        
        /*  
         *   blockEndConv is a special value which not only doesn't allow the
         *   conversation to be ended while we're in this ConvNode but also 
         *   tells the caller that we've displayed a message explaining why, 
         *   so that we don't also need to display one of the messages from 
         *   npcContinueList/
         */
        return blockEndConv;
    }   
;


/*  
 *   YES TOPIC
 *
 *   A YesTopic handles the response when the player types YES. Normally a 
 *   YesTopic will only be useful in a ConvNode (to handle a reply to a 
 *   question the NPC has just asked. Making it a SuggestedYesTopic also 
 *   means that 'say yes' will be one of the suggestions offered to the 
 *   player/
 */
++ YesTopic
    topicResponse()
    {
        /*  
         *   If the player replies YES, we want to leave this ConvNode. This
         *   will happen in any case unless we include a <.convstay> or
         *   <.convstayt> tag in the response, which we don't want to do here.
         */
        "<q>Yes, all right, take me to the lighthouse,</q> you say.\b
        <q>Follow me,</q> she replies, starting towards the east.";
        
        /*   
         *   If the player says YES, Sally will lead him to the lighthouse, 
         *   so we need to put her in the first of her GuidedTourStates.
         */
        sally.setState(sallyLeadingState);
    }
;

/*   
 *   NO TOPIC
 *
 *   A NoTopic is just like a YesTopic, except that it handles a response to 
 *   NO.
 */
++ NoTopic
    topicResponse()
    {
        "<q>No, I'm a bit busy right now,</q> you say.\b
        <q>Very well, suit yourself,</q> she shrugs, <q>It's your loss, not
        mine,</q>\b
        So saying, she turns away; and with her goes your only chance of
        learning about the lighthouse and the troubles.\b";
        
        /* 
         *   If the PC refuses to follow Sally, then the plot (such as it 
         *   is) has been derailed, so we may as well end the game. We do so 
         *   with a suitable custom message.
         */        
        finishGameMsg('YOU ARE FEEBLY FAINT-HEARTED', [finishOptionUndo]);
        
    }
;

/*  
 *   QUERY TOPIC
 *
 *   A QueryTopic is a special kind of TopicEntry that can be used to allow the
 *   player to ask things that normally wouldn't be possible in the standard
 *   ASK/TELL system. The QueryTopic we define immediately below will be
 *   suggested to the player as "as why she's offering", but the player could
 *   also trigger it with WHY ARE YOU OFFERING.
 *
 *   The first single-quoted string in the template is the qType, in this case
 *   'why', which enables the parser to match the QueryTopic to ASK WHY... or
 *   just WHY... The second string is the vocab property of the Topic object the
 *   library will create for us to act as this QueryTopic's matchObj.
 *
 *   Note that in this case we do use <.convstay> tag so the the conversation
 *   will remain at this ConvNode even after this TopicEntry has been triggered.
 */
++ QueryTopic, StopEventList 'why' 'she\'s offering; (she) (is) (you) (are)'   
    [
        '<q>Why are you offering to show me?</q> you ask.\b
        <q>Because you\'re new here; you need to understand what happened,</q>
        she replies. <q>So, are you coming? Yes or no?</q> <.convstay>',
        
        '<q>I still don\'t understand why you\'re so keen to show me the
        lighthouse,</q> you say.\b
        <q>Like I said, you need to understand what happened there. So, do you
        want me to show you?</q> <.convstay>'
        
    ]
;
    
/* 
 *   If the PC doesn't yet know who Sally is (he could have found out from 
 *   Bob), we'll let him ask her.
 */
++ AskTopic @sally
    "<q>Who are you?</q> you ask.\b
    <q>I'm <<sally.makeProper()>>,</q> she replies briskly, <q>and I've been
    around here long enough to know a thing or two. So, do you want me to take
    you to the lighthouse?</q> <.convstay>"
    isActive = (!sally.proper)
    name = 'herself'
;

/*   
 *   DEFAULT ANY TOPIC
 *
 *   This DefaultAnyTopic ensures that this ConvNode remains 'closed', since it
 *   will be triggered in response to any conversational command except for the
 *   four explicitly handled above. Without one or more DefaultTopics to trap
 *   other conversational commands, they would be handled by the next
 *   TopicDatabase (ActorState or Actor) in the hierarchy, and we'd slip
 *   straight out of the ConvNode. Note that to make this DefaultTopic 'close'
 *   the node we have to add a <.convstay> tag to the response so that we stay
 *   at this ConvNode each time this DefaultAnyTopic is triggered.
 *
 *   In a real game we'd probably want to make the DefaultAnyTopic a
 *   ShuffledEventList to vary the responses.
 */ 
++ DefaultAnyTopic
    "<q>Never mind that,</q> she says, <q>I asked you if you wanted me to show
    you the lighthouse. Do you?</q> <.convstay>"
;


    
//------------------------------------------------------------------------------
/*   
 *   AN 'OPEN' CONVERSATION NODE
 *
 *   This is the conversation node that's triggered when Sally and the PC arrive
 *   outside the lighthouse. She asks the PC whether they should go inside, but
 *   that's an invitation to action rather than a demand for a verbal response,
 *   so though we should cater for a verbal response, we shouldn't demand one.
 *   So we can use the much simpler 'open' ConvNode coding structure here. This
 *   is marked by the absence of any catchall DefaultTopics.
 */
+ ConvNode 'lighthouse'     
;

++ YesTopic
    "<q>Yes; that's what came for, isn't it?</q> you reply.\b
    <q>Quite,</q> she agrees, <q>So lead on!</q> "    
;

++ NoTopic
    "<q>No, I don't like the look of it,</q> you reply.\b
    <q>Don't be a ninny!</q> she protests, <q>It's quite safe! So -- lead
    on!</q>"
;

++ AskTopic @lighthouse
    "<q>What will we find in there?</q> you ask.\b
    <q>Why don't we go in and see?</q> she replies, <q>Shall we?</q> <.convstay>
    "
    name = 'the lighthouse'
;

/* 
 *   There's no DefaultTopic at the end of this ConvNode structure. If the 
 *   player responds with anything other than YES, NO or ASK ABOUT 
 *   LIGHTHOUSE, we'll simply fall straight out of the ConvNode, since we'll 
 *   have left the point of the conversation at which any of these responses 
 *   made sense.
 */


//------------------------------------------------------------------------------
/*   
 *   A THREADED CONVERSATION NODE CHAIN
 *
 *   We can also use ConvNodes to created a threaded conversational chain. 
 *   This could be done with 'closed' nodes, but quickly becomes very 
 *   laborious (perhaps for the player as well as the author!). Here we just 
 *   illustrate a chain of very simple 'open' nodes. Note that the 
 *   conversation will only continue on to the next node in the chain if the 
 *   player gives the 'correct' answer on every turn (though we could have 
 *   programmed a branching chain had we wanted to). In this case this is a 
 *   reasonable model of how such a conversation might proceed.
 */

+ ConvNode 'family'   
;

++ YesTopic
    "<q>Yes, I've just moved here with my wife and kids,</q> you say.\b
    <q>Well, I hope you like it here!</q> she replies.<.reveal married> "
;

++ NoTopic
    /* 
     *   The tag <.convnode drink> at the end of this reply will take the 
     *   Conversation to the next ConvNode (called 'drink').
     */
    "<q>No, I'm a bachelor,</q> you reply.\b
    <q>Really?</q> she replies, <q>I'd've thought a guy like you -- well, maybe
    we could have a drink some time, and you can tell me all about it.</q>
    <.convnode drink> "
;

+ ConvNode 'drink'
;

/*  
 *   Likewise the <.convnode date> tag will take the conversation to the next
 *   ConvNode (called 'date')
 */
++ YesTopic
    "<q>Yes, I'd like that,</q> you say.\b
    <q>Good!</q> she smiles, <q>How about tonight? I know a great little place
    we could go, so, if you're free...</q> <.convnode date>"
;

++ NoTopic
    "<q>No, I'd better not. My girlfriend probably wouldn't understand,</q> you
    tell her.\b
    <q>Oh, very well then,</q> she replies. "
;

+ ConvNode 'date'
;

++ YesTopic
    "<q>Yes, I'm free tonight,</q> you say, <q>let's meet up for a drink
    then!</q>\b
    <q>It's a date!</q> she declares with a broad grin. "
;

/* 
 *   The <.convnodet other> tag takes the conversation to the ConvNode 'other'
 *   immediately below, but this time, since we're not just looking for a simple
 *   yes or no answer, we need to inform the player what responses are now
 *   possible. By using <.convnodet other> rather than <.convnode other> we're
 *   asking for a topic inventory (list of suggested topics) to be displayed on
 *   entering the new ConvNode.
 */
++ NoTopic
    "<q>No, I'm busy tonight,</q> you reply, <q>just moved it, so many things to
    attend to...</q>\b
    <q>Some other time then, maybe,</q> she suggests. <.convnodet other>"    
;

+ ConvNode 'other'
;

/* 
 *   SAY TOPIC
 *
 *   A SayTopic is another kind of SpecialTopic that can be used to allow the
 *   player to SAY anything. It works much like a QueryTopic except that we
 *   don't define a qType for it.
 */
++ SayTopic 'suggest tomorrow' 
    "<q>How about tomorrow?</q> you suggest.\b
    <q>That would be great -- it's a date!</q> she beams. "
    
    /* 
     *   We want this SayTopic to be suggested as "suggest tomorrow" not "say
     *   suggect tomorrow", so we set includeSayInName to nil to remove "say"
     *   from this SayTopic's name
     */
    includeSayInName = nil
;

++ SayTopic 'answer vaguely; (be) vague' 
    "<q>Yes, some other time,</q> you agree. "
    includeSayInName = nil
;



//==============================================================================
/*  
 *   AGENDA ITEMS
 *
 *   AgendaItems provide a mechanism to allow NPCs to pursue goal-directed 
 *   behaviour or responded to particular events. Each NPC has an agendaList 
 *   (which may, of course, be empty at any one time), and on each turn when 
 *   the NPC is not otherwise engaged his/her/its agendaList is searched for 
 *   an AgendaItem that's ready to be used. If one is found, it's 
 *   invokeItem() method is called. 
 *
 *   We want Sally to walk out of the shop and wait for the PC as soon as she
 *   hears Bob mention the lighthouse. An AgendaItem is ideal for this.
 */

+ AgendaItem
    /* 
     *   AgendaItems normally have to be added to an NPC's AgendaList 
     *   explicitly, but by setting this property to true we can have an 
     *   AgendaItem automatically added to the agendaList at the start of 
     *   the game, which is what we want here.
     */
    initiallyActive = true
    
    /*   
     *   An AgendaItem can fire once its isReady property is true. The PC 
     *   learns about the lighthouse when Bob first mentions it, so checking 
     *   for when the PC knows about the lighthouse should make this 
     *   AgendaItem fire at the right time.
     */
    isReady = (me.knowsAbout(lighthouse))
    
    /*   The code to execute once this AgendaItem is triggered. */
    invokeItem
    {
        /*  
         *   Note that text displayed in the invokeItem() of an AgendaItem 
         *   will only be displayed if the PC can see the NPC in question. 
         *   Normally this is what we want, since it allows us to describe 
         *   what an NPC is doing without worrying if the PC is there to see 
         *   it or not (if the PC isn't, the text won't be displayed), but 
         *   occasionally this can catch us out, not least if the 
         *   invokeItem() method moves the NPC in or out of the PC's scope 
         *   in the course of execution.
         *
         *   Here, though, it's straightforward, since the PC will always be 
         *   present to see Sally's reaction to the mention of the lighthouse.
         */
        "{The subj sally} pauses from her clothes-hunting and throws you an
        anxious glance. ";
        
        /*  Make Sally leave the shop. */
        sally.travelVia(street);
        
        /*  Change Sally's ActorState to sallyStreetState */
        sally.setState(sallyStreetState);
        
        /*  Add a new AgendaItem to Sally's agendaList. */
        sally.addToAgenda(sallyStreetAgenda);
        
        /*  
         *   We're done with this AgendaItem, so it can be removed from 
         *   Sally's agendaList; we show this by setting isDone = true. If 
         *   we didn't this AgendaItem would keep on firing while its 
         *   isReady property evaluated to true. 
         *
         *   In come cases we might want an AgendaItem to be triggered over 
         *   several terms, in which case we wouldn't set isDone = true 
         *   until we were done with it; but this AgendaItem is a one-off, 
         *   so we set isDone = true first time through.
         */
        isDone = true;
    }
;

/*   
 *   CONV AGENDA ITEM
 *
 *   A ConvAgendaItem is used to allow the NPC to try to say something on 
 *   his or her own initiative. By default it becomes ready when (a) the NPC 
 *   is in a position to talk to the PC and (b) the PC hasn't conversed with 
 *   the NPC on that turn. When those two conditions are met the NPC can 
 *   inject her conversational gambit into the conversation. 
 *
 *   We want Sally to offer to lead the PC to the lighthouse as soon as he 
 *   emerges from the shop. A ConvAgenaItem will do this job for us, since 
 *   the Sally can't talk to the PC when he's inside the shop and she's 
 *   outside, but will be able to as soon as he comes out of the shop. 
 */

+ sallyStreetAgenda: ConvAgendaItem
    invokeItem()
    {           
        /* 
         *   Here we have Sally ask a question and then wait for a reply. The
         *   possible responses are defined in the 'troubles' ConvNode to which
         *   the conversation is moved by the <.convnodet troubles> tag. Note
         *   that there are restrictions on where such tags can be used, but
         *   they can be used in ConvAgendaItems as well as TopicEntries.
         */
        "{The subj sally} walks up to you and says, <q>Excuse me,
        but I couldn't help hearing you asking about the troubles. Would you
        like me to show you the lighthouse?</q> <.convnodet troubles>";       
     
        /* This is a once-off AgendaItem, so note we're done with it. */
        isDone = true;
    }
;

/*
 *   DELAYED AGENDA ITEM
 *
 *   A DelayedAgendaItem is one that fires a predetermined number of turns 
 *   after its added to its actor's agendaList.
 *
 *   If the PC wanders around for too long after entering the lighthouse 
 *   without going to the room Sally wants him to visit, she'll become 
 *   impatient enough to give him a verbal nudge. Since this is a 
 *   conversational activity, it's appropriate to make this a ConvAgendaItem 
 *   as well. Note that we can just mix the two classes together to combine 
 *   their behaviour.
 */


+ sallyImpatientAgenda: DelayedAgendaItem, ConvAgendaItem
    invokeItem()
    {
        if(me.hasSeen(oakDoor))
            "<.p><q>If you want answers you <i>have</i> to go through that oak
            door,</q> {the subj sally} tells you. ";
        else
            "<.p><q>You won't find anything down here,</q> {the subj sally} tells
            you, <q>we'll have to try upstairs.</q> ";
        
        isDone = true;
    }
;






//==============================================================================
/*   
 *   TOPIC
 *
 *   A Topic is used to represent a possible Topic of Conversation that's not
 *   otherwise represented as a physical object in the game world, either 
 *   because it's an abstraction (like 'weather' or 'troubles') or because 
 *   there's no physical object by that name corresponding to it in the game 
 *   (like the town).
 *
 *   Here we define just three Topics. A real game would probably define many
 *   more. Note that starting the name of a Topic object with a lower-case 
 *   t is not a requirement, it's simply a convention adopted here/
 *
 *   Note also that the only property we need to define on a Topic object is 
 *   its vocabWords (the single-quoted string in the Topic template). 
 */

tWeather: Topic 'weather';
tTown: Topic 'this town;;place';
tTroubles: Topic 'troubles;;;them';

