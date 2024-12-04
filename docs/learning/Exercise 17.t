#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*   
 *   EXERCISE 17 - LIGHT SOURCES
 *
 *   This is a demonstration of how to use and adapt the standard library light
 *   source classes. It's not at all an exciting game, and playing it straight
 *   through will not be particularly informative. You'll get more out of it by
 *   experimenting with the different kind of light sources provided.
 */

versionInfo: GameID
    IFID = 'c0cc995b-54ce-4f2a-9bdc-ff7a40100ffa'
    name = 'Exercise 17 - Light Sources'
    byline = 'by Eric Eve'
    htmlByline = 'by <a href="mailto:eric.eve@hmc,ox.ac.uk">Eric Eve</a>'
    version = '1'
    authorEmail = 'Eric Eve <eric.eve@hmc,ox.ac.uk>'
    desc = 'A brief game to illustrate various kinds of light sources.'
    htmlDesc = 'A brief game to illustrate various kinds of light sources.'
;

gameMain: GameMainDef
    /* Define the initial player character; this is compulsory */
    initialPlayerChar = me
    
    showIntro()
    {
        "You have travelled a long way to get here, but finally you arrived at
        the caves in which the legendary magic crystal is said to be concealed.
        Determined to overcome all dangers and difficulties you are ready to
        embark on your quest to recover the Crystal That Glows In The Dark!\b";
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
 *   The name "startRoom" isn't special - you can change this any other
 *   name you'd prefer.  The player character's starting location is simply
 *   the location where the "me" actor is initially located.  
 */
startRoom: Room 'Outside Cave'
    "The cave you came to visit stands just to the north. To the south lies the
    way back to civilization. "
    north = smallCave
    south: TravelConnector
    {
        /* 
         *   Don't allow travel this way until the PC has seen the crystal 
         *   and is carrying it.
         */
        
        canTravelerPass(traveler)
        {
            return me.hasSeen(crystal) && crystal.isIn(me);
        }
        explainTravelBarrier(traveler)
        {
            "You came all the way here to collect the crystal and you're not
            leaving without it! ";
        }
        
        /*  
         *   When travel is allowed, simply end the game with a message 
         *   saying that the player has won.
         */
        
        noteTraversal(traveler)
        {
            "The crystal recovered, you go triumphantly on your way. ";
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
;

/*
 *   READABLE
 *
 *   To make an object readable in adv3Lite we just need to define its 
 *   readDesc property.
 */
++ Thing 'note; handwriten' 
    "It's a handwritten note from the friend who tipped you off about the
    magic crystal. "
    readDesc = "It says, <q>You should find the crystal in the deepest
        cave.</q> "
;

++ matchbox: OpenableContainer 'matchbox; (match} plain yellow ; box'
    "It's a plain yellow box, labeled <q>Lite Quality Matches</q>. "
;

/* The Matchstick class is defined below. */
+++ Matchstick;
+++ Matchstick;
+++ Matchstick;
+++ Matchstick;
+++ Matchstick;


/*  ENTERABLE */

+ Enterable 'cave entrance; narrow'
    "The cave entrance just to the north is narrow, but wide enough for you to
    enter. "
    
    destination = smallCave
;

//------------------------------------------------------------------------------
/*  
 *   DARKROOM: Note the DarkRoom class is not defined in the adv3Lite library;
 *   we define our own custom DarkRoom class below.
 */

smallCave: DarkRoom 'Small Cave'
    "It's fortunate you didn't bring a cat, because there'd hardly be room to
    swing it in here. The exit lies to the south, and you could also squeeze
    through the narrow gap to the northwest. "
    south = startRoom
    out asExit(south)
    northwest = gap
;


/*  
 *   CANDLE
 *
 *   A Candle is an object that can be lit and will stay alight for a certain
 *   length of time before going out. We can base it on the FueledLightSource
 *   class we go on define below.
 */

+ candle: FueledLightSource 'red candle' 
    /* 
     *   A candle is effectively its own fuel, so we make its length reflect the
     *   amount of 'fuel' remaining.
     */
    "The candle is about <<spellNumber(fuelLevel)>> inch<<fuelLevel > 1 ? 'es' :
      ''>> long; it's currently <<isLit ? 'lit' : 'unlit'>>. "
    
    initSpecialDesc = "A red candle lies on the ground. "
      
    /* 
     *   These warning messages will be displayed when the candle comes close to
     *   being fully burned down; they warn the player that s/he needs to find
     *   another light source quickly.
     */
    warningMessage()
    {
        switch(fuelLevel)
        {
            case 2: "The candle is burning very low. "; break;
            case 1: "What's left of the candle gutters, about to go out. ";
            break;
        }
    }
    
    sayBurnedOut()
    {
        "The candle goes out, leaving only a burnt-out stub. ";
        
        /* 
         *   We use the replaceVocab() method here both to give the candle a new
         *   name and to change the vocab words that can be used to refer to it.
         *   This effectively changes it from candle to stub.
         */
        replaceVocab('candle stub; red burnt-out burned-out burnt');
        
        /*  
         *   A the same time and for the same reason we change its description;
         *   we can't change the desc property using a statement like desc =
         *   "whatever", but we can change it using setMethod as shown below.
         */
        setMethod(&desc, 'It\'s just a burnt-out stub. ');
    }
    
    sayNoFuel = "There's not enough left of the candle stub to light. "
;

/*  
 *   PASSAGE
 *
 *   Since we mentioned a narrow gap in the room description we should 
 *   probably implement it.
 */

+ gap: Passage 'narrow gap' 
    "It's lucky you went on a diet before you came here; you should just about
    be able to get through it. "
    
    destination = largeCave
;


//------------------------------------------------------------------------------

largeCave: DarkRoom 'Large Cave'
    "This cave is so large you could almost get lost in it; even so it's clear
    enough that the only viable exits are to southeast, northeast and west. "
    southeast = smallCave
    northeast = roundCave
    west = deadEnd
;


/*  
 *   FUELED LIGHT SOURCE
 *
 *   A FueledLightSource is a light source that consumes fuel as it burns. The
 *   Library provides quite a bit of the implementation for this class, but we
 *   need to do more work to make it function in a particular object (unless we
 *   use the Candle subclass). Here we'll use a FueledLightSource to implement
 *   an oil lamp.
 */

+ oilLamp: FueledLightSource 'oil lamp; fine old brass'
    "It's a fine old brass oil lamp. "
        
        
    /*  
     *   We'll start the lamp very low on oil, so we'll need to allow it to 
     *   be refueled. We'll assume it can be refuelled by pouring oil into 
     *   it, so we add an action handler for the PourInto action with the 
     *   lamp as the indirect object.
     */
        
    iobjFor(PourInto)
    {
        verify() 
        {
            if(fuelLevel == maxFuelLevel)
                illogicalNow('The oil lamp is already full. ');
            if(isLit)
                illogicalNow('You can\'t pour anything into the lamp while
                    it\'s lit. ');
        }
        check()
        {
            if(gDobj != oilCan)
                "That won't do much good! ";
        }
        action()
        {
            "You pour enough oil into the lamp to fill it. ";
            fuelLevel = maxFuelLevel;
        }
    }
    
    /* Start the lamp off nearly out of fuel. */
    
    fuelLevel = 4
    
    /* 
     *   This is a custom property we are defining for our own use, not a 
     *   library property.
     */
    maxFuelLevel = 50
    
    /*  
     *   Our custom FueledLightSource class included a warningMessage method
     *   which we can override to display messages when the lamp is about to go
     *   out.
     */
   
   
    warningMessage()
    {
        switch(fuelLevel)
        {
            case 3: "<.p>The lamp starts to dim. "; break;
            case 2: "<.p>The lamp flickers, as if it's about to go out. "; break;
            case 1: "<.p>The lamp flame gutters; it really is about to go out."; 
            break;
        }
    }
    
    /* Customize the message for the lamp running out of fuel. */    
    sayBurnedOut()
    {
        "The oil lamp flickers and goes out. ";
    }
;

//------------------------------------------------------------------------------

deadEnd: DarkRoom 'Dead End'
    "The passage from the Large Cave rapidly peters out to this dead end. The
    way back is to the east. "
    east = largeCave
    out asExit(east)
;

+ oilCan: Thing 'can of oil;; oilcan oil'
    initSpecialDesc = "A can of oil rests on the floor. "
    
    dobjFor(PourInto)
    {
        preCond = [objHeld]        
    }
    
    /* We use the fluidName property to name the fluid contained by or poured from the can.*/
    fluidName = 'oil'
    isPourable = true
;

//------------------------------------------------------------------------------

roundCave: DarkRoom 'Round Cave'   
    "The cave is roughly round, and looks like it once had exits in all
    directions, but rockfalls have blocked all but two of them, those to east
    and southwest. "
    east = squareCave
    southwest = largeCave
;

/*  
 *   FLASHLIGHT 
 *
 *   A Flashlight is a LightSource that can be turned on and off. 
 */

+ Flashlight 'flashlight; old black plastic; torch' 
    "It's an old black plastic torch. "
    initSpecialDesc = "A flashlight lies abandoned in at the centre of the cave.
        "
;

/*  
 *   DECORATION 
 *
 *   Since we mentioned rockfalls in the room description we'll give them a 
 *   minimal implementation - as a Decoration.
 */

+ Decoration 'rockfalls; rock; falls exits; them' 
    "Rockfalls block all the exits except those to the east and southwest. "    
;

//------------------------------------------------------------------------------

squareCave: DarkRoom 'Square Cave'
    "This cave is so perfectly square that you suspect it must be artificial.
    The only way out is to the west. "
    west = roundCave
    out asExit(west)
;

/*  
 *   OPENABLE CONTAINER 
 *
 *   Rather than leaving the crystal in plain view we'll put it in a box.
 */

+ OpenableContainer 'iron box; rusty old'
    "It's started to rust. << moved ? '' : 'It looks like it may have been here
        quite a while'>>. "
    initSpecialDesc = "An iron box nestles against a wall. "  
    
;

/*  
 *   LIGHT SOURCE
 *
 *   A plain LightSource is a Thing that gives off constant light. To make 
 *   this one more interesting we'll make it light up only when it would 
 *   otherwise be dark.
 */


++ crystal: Thing 'magic crystal; blue' 
    "It is <<isLit ? 'glowing with a steady light' : 'a dull blue colour'>>. "
    
    /* 
     *   After each turn when the crystal is in scope, check whether it 
     *   would be light if the crystal were not lit. If it would and the 
     *   crystal was previously unlit, report that the crystal has ceased to 
     *   glow. If it would be dark without the crystal and the crystal was 
     *   previously unlit, make it lit and report the fact.
     */
    afterAction()
    {
        /* Keep track of whether the crystal was lit when we started. */
        local wasLit = isLit;
        
        /* 
         *   Make it unlit so we can test what the light would be like 
         *   without it.
         */
        isLit = nil;
        
        /*   Then test the light level. */
        if(getOutermostRoom.isIlluminated)            
        {
            if(wasLit)
            {
               "The crystal grows dim and stops glowing. ";
               return;
            }
        }
        else if(!wasLit)
        {
            "The crystal starts glowing. ";
            isLit = true;
            return;
        }
        
        /* 
         *   Restore the crystal to its starting lit/unlit state if we didn't
         *   report any change.
         */
        isLit = wasLit;
    }
;

/*  
 *   STATES
 *
 *   The library defines lightSourceStateOn and lightSourceStateOff as the 
 *   States for a LightSource. Here we provide customized versions to 
 *   cater for the extra vocabulary (glowing, dim, dull) associated with the 
 *   two states/
 */

crystalLitUnlitState: State
    stateProp = &isLit
    adjectives = [[nil, ['dim', 'dull', 'unlit']], [true, ['glowing', 'lit']]]
    appliesTo(obj) { return obj == crystal; }
;


/* 
 *   DARKROOM
 *
 *   The adv3Lite library doesn't define a DarkRoom class, but there's nothing
 *   to stop us defining our own, which may be convenient in a game with quite a
 *   few unlit rooms.
 */
class DarkRoom: Room
    isLit = nil
    regions = [caveRegion]
;

/* 
 *   REGION
 *
 *   Since all the DarkRooms in this game will be in the caves, we'll take the
 *   opportunity to demonstrate the use of a Region and illustrate the use of
 *   regionBeforeAction and regionAfterAction.
 */
caveRegion: Region
    regionBeforeAction()
    {
        if(gActionIs(Jump))
        {
            "The ceiling is too low here for jumping; you might bang your head!
            ";
            exit;
        }
    }
    
    regionAfterAction
    {
        if(gActionIs(Yell))
        {
            "Your voice echoes round the cave. ";
        }
    }
    
;


/*  
 *   FUELED LIGHT SOURCE
 *
 *   The adv3Lite library doesn't define a FueledLightSource class (to represent a light source with
 *   a limited life) as standard, but again, there's nothing to stop us defining our own, as here.
 *   Alternatively, we coulld use the FueledLightSource class provided by the Fuerled extension that
 *   comes with adv3Lite (but is not incldued in your game unless you explicitly add it).
 */

class FueledLightSource: Thing
    /* 
     *   The current fuelLevel of our light source, representing the number of
     *   turns until it burns out.
     *
     *   Note that while we're defining our own FueledLightSource class here we
     *   could instead use the one that comes in the Fueled Light Source
     *   extension.
     */
    fuelLevel = 10
        
    daemonID = nil
    
    /*   A method that runs every turn while we're lit. */
    burnDaemon()
    {        
        /* Display a message warning that we're about to burn out. */
        warningMessage();
        
        /* 
         *   Reduce the fuel level by one. If we're out of fuel, make us unlit
         *   and display a message saying we've gone out.
         */
        if(fuelLevel-- < 1)
        {            
            makeLit(nil);
            sayBurnedOut;
        }
    }
    
    /*  
     *   A warning message to display when we're running low on fuel. By default
     *   we do nothing here but specific instances can override this to display
     *   a warning message depending on the fuelLevel when the fuelLevel is
     *   running low.
     */
    warningMessage() {}
    
    /*   
     *   Override the standard library makeLit() method to carry out some
     *   additional handling based on fuelLevel.
     */
    makeLit(stat)
    {
        if(stat)
        {
            /* 
             *   If something wants to light us and we have no fuel, display a
             *   message saying we can't be lit instead.
             */
            if(fuelLevel < 1)
            {
                sayNoFuel();
                exit;
            }
            /*  Otherwise, if we're being lit, start our burn daemon */
            else if(daemonID == nil)
                daemonID = new SenseDaemon(self, &burnDaemon, 1);                
        }
        /* Otherwise, if we're being put out, stop our burn daemon */
        else if(daemonID != nil)
        {
            daemonID.removeEvent();
            daemonID = nil;
        }
            
        /*  Finally, carry out the inherited handling. */
        inherited(stat);           
    }
    
    /*  
     *   Display a message saying we won't light (because our fuel is exhausted)
     */
    sayNoFuel = "\^<<theName>> won't light. "
    
    /*  Display a message to say we're going out when we're out of fuel. */
    sayBurnedOut = "\^<<theName>> goes out. "
    
    /*  We're definitely something that can be lit. */
    isLightable = true
    
    /*  
     *   But we may need an external light (of the naked flame sort) to light us
     *   with. If this flag is nil, we can be lit without the use of another
     *   light (flame) source.
     */
    needsExternalLight = true
    
    dobjFor(Light)
    {
        action()
        {
            /* 
             *   If we need an external light source to light us with, then ask
             *   which one to use (if there's only one possible candidate, the
             *   library will automatically pick it).
             */
            if(needsExternalLight)
                askForIobj(BurnWith);
            else
                /* 
                 *   othewise carry out the inherited handling (and make us
                 *   lit).
                 */
                inherited;
        }
    }
        
    /* Treat BURN ITEM as equivalent to LIGHT ITEM */
    dobjFor(Burn) asDobjFor(Light)
    
    /* Handling for lighting me with an external light source */
    dobjFor(BurnWith)
    {
        verify()
        {
            /* If I'm already lit there's no point trying to light me */
            if(isLit)
                illogicalNow('{The subj dobj} {is} already lit. ');           
        }
        
        action()
        {
            makeLit(true);
            "{I} {light} {the dobj} with {the iobj}. ";
        }
    }
    
    /*  
     *   All our FueledLightSources can be used to light other
     *   FueledLightSources with provided the FueledLightSource we want to light
     *   with is already lit itself.
     */
    iobjFor(BurnWith)
    {
        verify()
        {
            if(!isLit)
                illogicalNow('{The subj dobj} {can\'t} be used to light anything
                    else with when it\'s not lit itself. ');
        }
    }
;

/* A Matchstick is a FueledLightSource with a short life */
class Matchstick: FueledLightSource 'match;;matchstick'
    "It's just an ordinary matchstick<<if isLit>>, currently glowing with a dim
    flame<<end>>. "
    
    /* A Matchstick won't stay alight very long */
    fuelLevel = 3
    
    sayBurnedOut()
    {
        "The match flickers and dies, <<if !getOutermostRoom.isIlluminated>>
        plunging you into darkness, <<end>>so you toss the burned-out match
        away. ";
        
        /* 
         *   We assume there's not enough left of the burnt-out match to be
         *   worth keeping, so we just move it off-stage.
         */
        moveInto(nil);
    }
    
    /* 
     *   We don't need an external light source to light a match with (though we
     *   do need the matchbox to strike it against -- see below).
     */
    needsExternalLight = nil
        
    
    dobjFor(Light)
    {
        /* 
         *   In order to light a match I must be holding both the match and the
         *   matchbox to strike it against.
         */
        preCond = [objHeld, new ObjectPreCondition(matchbox, objHeld)]
        
        action()
        {
            inherited();
            "You strike a match, and it flickers into life with a feeble glow.
            ";
        }
    }
;

/* 
 *   DOER
 *
 *   STRIKE MATCH means the same as LIGHT MATCH, so this Doer converts the first
 *   action into the second. By making the Doer 'strict', we prevent it
 *   operating on synonyms of STRIKE such as HIT MATCH or ATTACK MATCH; this
 *   Doer only takes effect if the Attack action is triggered through the
 *   command STRIKE.
 */     
     
Doer 'strike Matchstick'
    execAction(c)
    {
        doInstead(Light, gDobj);
    }
    
    strict = true
;


//==============================================================================
/*   
 *   SUPPLYING THE AMUSING OPTION
 */
     

modify finishOptionAmusing
    doOption()
    {
        
        "Try jumping and shouting in the caves.\b";
       
        if(!oilCan.seen)
            "Try going west from the large cave and see what you find.\b";
        else if(oilLamp.fuelLevel < 5)
            "Try refilling the oil lamp.\b";
        
        "Once you've recovered the crystal, try extinguishing all the other
        light sources while you're still in the caves.\b
        
        Then try lighting one of your other light-sources again.\b";   
        
        
        
        /* 
         *   this option has now had its full effect, so tell the caller
         *   to go back and ask for a new option 
         */

        return true;
    }
;



//==============================================================================
/*   
 *   MODIFYING A VERBRULE
 *
 *   At one point the game describes a gap the PC could squeeze through, so 
 *   it would be good to make SQUEEZE THROUGH a synonym for GO THROUGH. We 
 *   can do this either with a new VerbRule or by modifying an existing one. 
 *   Here we'll illustrate the second method.
 */

modify VerbRule(GoThrough)
    ('walk' | 'go' | 'squeeze') ('through' | 'thru')
        singleDobj
    :
;

/*  
 *   The player might type FILL LAMP WITH OIL instead of POUR OIL INTO LAMP; 
 *   defining the following VerbRule makes the two synoynmous. Note how we 
 *   fill the iobj and dobj roles in this new VerbRule: FILL X WITH Y is the 
 *   same as POUR Y INTO X, so in the FILL version the normal roles of 
 *   direct and indirect object are reversed from that of the normal way of 
 *   phrasing the PourIntoAction.
 */

VerbRule(FillWith)
    'fill' singleIobj 'with' singleDobj
    : VerbProduction
    action = PourInto
    verbPhrase = 'fill/filling (with what) (what)'
    missingQ = 'what do you want to fill; what do you want to fill it with'
;

/*  
 *   The player might also type just FILL LAMP; this VerbRule handles that by
 *   treating it as an incomplete PourIntoAction and prompting for what 
 *   should be used to fill it.
 */

VerbRule(FillWithWhat)
    [badness 500] 'fill' singleIobj
    : VerbProduction
    action = PourInto
    /* 
     *   This verbPhrase looks back to front; this is a consequence of 
     *   reversing the normal dobj and iobj roles. If the player types FILL 
     *   LAMP, this VerbRule takes Lamp to be the Indirect object of a 
     *   PourInto command (effectively POUR SOMETHING INTO LAMP) and then 
     *   prompts for (or in this game, chooses a default) direct object. The 
     *   parser will then construct the default object announcement on the 
     *   assumption that the dobj comes before the iobj placeholder in the 
     *   verbPhrase string, but we want the iobj announcement to say 'filling
     *   with the oil lamp' not 'filling the oil lamp'.
     */
    verbPhrase = 'fill/filling (with what) (what)'
    missingQ = 'what do you want to fill it with; what do you want to fill'
    askDobjResponseProd = withSingleNoun
    missingRole = DirectObject
    
;

