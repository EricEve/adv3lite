#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*
 *   sensory.t
 *
 *   The SENSORY extension is intended for use with the adv3Lite library. It
 *   adds slightly more sophisticated handling for smells and sounds, as well as
 *   a new SensoryEvent class which can be useful for making actors and other
 *   objects respond to sensory events.
 *
 *   VERSION 1
 *.  20-Jul-13
 *
 *   Usage: include this extension after the adv3Lite library but before your
 *   own game-specific files. Make sure that events.t is also included in your
 *   build.
 */


sensoryID: ModuleID
    name = 'Sensory'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '1'    
;

property remoteSmellDesc;
property remoteListenDesc;
property tooFarAwayToHearMsg;
property tooFarAwayToSmellMsg;


/* 
 *   The SensoryEmanation class is the base class for sensory emanations such as
 *   smells and noises.
 */
class SensoryEmanation: Decoration
    
    /* 
     *   By default we vary our description according to whether the player
     *   character can see the object whose sound or smell we represent. If you
     *   don't these this variation, you can just override desc directly.
     */
    desc
    {
        if(Q.canSee(gPlayerChar, location))
            descWithSource;
        else
            descWithoutSource;
    }
    
    /* Our description when the player character can see our source */
    descWithSource = nil
    
    /* Our description when the player character can't see our source */
    descWithoutSource = nil
    
    /*  
     *   Are we actually emanating? We may not be if something stops us, e.g.
     *   breaking a ticking clock
     */
    isEmanating = true
    
    /*  If we're not emanating we can't be sensed at all, so we're hidden */
    isHidden = !isEmanating
    
    /* 
     *   The emanate method is called on each turn that the player character can
     *   sense us, and can be used to display a message announcing our presence,
     *   such as "There's an awful stink here" or "A loud ticking noise comes
     *   from somewhere. "
     */
    emanate() 
    { 
        /* If our schedule is nil (see below) we don't do anything at all */
        if(schedule == nil)
            return;
        
        /* Get the interval before we're due to show another message */
        local interval = schedule[scheduleState];
        
        /* 
         *   If this is nil, we don't want to show another message, so simply
         *   end the routine here.
         */
        if(interval == nil)
            return;
        
        /*  
         *   If incrementing our emanation state by one makes it greater than
         *   the its value when we last showed a message plus the interval to
         *   the next one, show our emanation desc
         */ 
        if(++emanationState >= lastEmanationTime + interval)
        {
            /* Display our emanation description */
            emanationDesc();
            
            /* 
             *   If we haven't reached the end of the emanation schedule yet,
             *   increase our scheduleState by one.
             */
            if(nilToList(schedule).length > scheduleState)
                scheduleState++;
        
            /*  Note when we last displayed a message. */
            lastEmanationTime = emanationState;
        }
    }
    
    /* 
     *   The message to display to announce our presence. This is overridden on
     *   our subclasses.
     */
    emanationDesc() { }
    
    /*  
     *   A counter to keep track of when we're next due to display an emanation
     *   message
     */
    emanationState = 0
    
    /*  A counter to keep track of where we are in our emanation schedule. */
    scheduleState = 1
    
    /*  The last time we emanated, relevant to when we started emanating */
    lastEmanationTime = 0
    
    /*  
     *   Our emanation schedule. If this is just nil we won't show any emanation
     *   meessages at all. Otherwise this should be a list of numbers. The first
     *   number is the first interval between emanations, the second number the
     *   second interval and so on. When we get to the end of the list we keep
     *   using the last number in the list as the interval. If the last entry in
     *   the list is nil we stop showing emanation messages. This can be used to
     *   reduce the frequency of messages to model the player character becoming
     *   less aware of us.
     */
    schedule = [1]

    /*  Reset all out counters to their initial states */
    reset()
    {
        emanationState = 0;
        scheduleState = 1;
        if(ofKind(Script))
            curScriptState = 1;
        lastEmanationTime = 0;
    }
       
    /* 
     *   The message to display when the player tries to do something with us
     *   other than sense us.
     */
    notImportantMsg = BMsg(cannot do to sensory, '{I} {can\'t} do that to {a
        cobj}. ')
;

/* An Odor is a SensoryEmanation representing a Smell */
replace class Odor: SensoryEmanation
    /*  An Odor responds to EXAMINE SOMETHING or SMELL SOMETHING */
    decorationActions = [Examine, SmellSomething]   
    
    /*   Treat Smelling an Odor as equivalent to Examining it. */
    dobjFor(SmellSomething) asDobjFor(Examine)   
    
    /*   
     *   In order to be able to 'examine' an Odor you must be able to smell it
     */
    dobjFor(Examine) { preCond = [objSmellable] }    
    
    /*   
     *   The message to be displayed to show that there's a smell here. The
     *   default implementation should be serviceable in many cases, but game
     *   code can easily override this method if something different is
     *   required.
     */
    emanationDesc()
    { 
        /* 
         *   If we're mixed in with an EventList class, display the next item
         *   from our eventList.
         */
        if(ofKind(Script))
            doScript();
        /*  
         *   Otherwise use our location's smellDesc or remoteSmellDesc, as
         *   appropriate
         */
        else
        {
            if(!location.isIn(gPlayerChar.getOutermostRoom) 
               && location.propDefined(&remoteSmellDesc))
                location.remoteSmellDesc(gPlayerChar);
            else
                location.smellDesc;
        }
    }
    
    /* 
     *   Only carry out the inherited handling if the player hasn't issued a
     *   SMELL command on this turn, otherwise there's the risk of duplicate
     *   messages.
     */
    emanate()
    {
        if(!gActionIn(Smell, SmellSomething))
            inherited;
    }
    
    sightSize = smellSize
        
    tooFarAwayToSeeDetailMsg = tooFarAwayToSmellMsg
;

replace class Noise: SensoryEmanation
     /*  A Noise responds to EXAMINE SOMETHING or LISTEN TO SOMETHING */
    decorationActions = [Examine, ListenTo]    
    
    /*   Treat Listening to a Noise as equivalent to Examining it. */
    dobjFor(ListenTo) asDobjFor(Examine)    
    
    /*   
     *   In order to be able to 'examine' a Noise you must be able to hear it
     */
    dobjFor(Examine) { preCond = [objAudible] }
    
    /*   
     *   The message to be displayed to show that there's a noise here. The
     *   default implementation should be serviceable in many cases, but game
     *   code can easily override this method if something different is
     *   required.
     */
    emanationDesc()
    { 
        /* 
         *   If we're mixed in with an EventList class, display the next item
         *   from our eventList.
         */
        if(ofKind(Script))
            doScript();
        /*  
         *   Otherwise use our location's listenDesc, or remoteListenDesc, as
         *   appropriate
         */
        else
        {
            if(!location.isIn(gPlayerChar.getOutermostRoom) 
               && location.propDefined(&remoteListenDesc))
                location.remoteListenDesc(gPlayerChar);
            else
                location.listenDesc;
        }
    }
    
    /* 
     *   Only carry out the inherited handling if the player hasn't issued a
     *   LISTEN command on this turn, otherwise there's the risk of duplicate
     *   messages.
     */
    emanate()
    {
        if(!gActionIn(Listen, ListenTo))
            inherited;
    }
    
    sightSize = soundSize
        
    tooFarAwayToSeeDetailMsg = tooFarAwayToHearMsg
;

/* The object which drives emanation messages for Odors and Noises */
emanationControl: InitObject
    /* Set up our Daemon at the start of play. */
    execute()
    {
        new Daemon(self, &emanate, 1);
    }
    
    /* 
     *   Each turn, execute the emanate() method for every item in our list of
     *   emanations.
     */
    emanate()
    {
        /* Get a list of items potentially due to emanate */
        local lst = buildEmanationList;
        
        /* Make every item in our list execute its emanate method */
        for(local e in lst)
            e.emanate();      
    }
    
    
    /*  
     *   Construct a list of SensoryEmanations that can currently be sensed by
     *   the player character.
     */
    buildEmanationList   
    {
        local pc = gPlayerChar;
        
        /* 
         *   First get a list of all the SensoryEmanations in the player
         *   character's current room that can be sensed by the player character
         */
        local lst = pc.getOutermostRoom.allContents.subset(
            {o: canSense(pc, o)});
        
        /*  
         *   If the SenseRegion class is defined then add all the
         *   SensoryEmanations that can be sensed in remote locations
         */
        if(defined(SenseRegion))
        {
            /* Set up an empty list of remote SensoryEmanations */
            local remoteLst = [];
            
            /* 
             *   For each room that's audible from the player character's
             *   current location, all all the currently emanating Noises that
             *   the player character can hear.
             */
            foreach(local rm in valToList(pc.getOutermostRoom.audibleRooms))
                remoteLst += rm.allContents.subset(
                    {o: o.isEmanating && o.ofKind(Noise) && Q.canHear(pc, o)});
            
            /* 
             *   For each room that's audible from the player character's
             *   current location, all all the currently emanating Odors that
             *   the player character can smell.
             */
            foreach(local rm in valToList(pc.getOutermostRoom.smellableRooms))
                remoteLst += rm.allContents.subset(
                    {o: o.isEmanating && o.ofKind(Odor) && Q.canSmell(pc, o)});
            
            /* 
             *   Add the remote list to the local list, ensuring that each item
             *   appears only once.
             */
            lst = lst.appendUnique(remoteLst);    
        }
        
        /* Return the resulting list. */
        return lst;    
    }
        
    /* 
     *   The pc can sense o if o is currently emanating and its a Noise the pc
     *   can currently hear or an Odor the pc can currently smell.
     */   
    canSense(pc, o)
    {
        return o.isEmanating && ((o.ofKind(Noise) && Q.canHear(pc, o))
                                  || (o.ofKind(Odor) && Q.canSmell(pc, o)));
    }   
;

/* 
 *   A SensoryEvent is a brief event in time, such as a sudden noise, to which
 *   other actors or objects in the vicinity may react.
 */
class SensoryEvent: object
    /* 
     *   We call the trigger event method of a SensoryEvent to simulate the
     *   occurrence of that event. The obj parameter is the object associated
     *   with the event, for example the source of a sudden explosion.
     */    
    triggerEvent(obj)
    {
        /* 
         *   Construct a list containing all the items in the player character's
         *   current room that the pc can sense via the relevant sense
         */
        local notifyList = obj.getOutermostRoom.allContents.subset({
            o: Q.(senseProp)(o, obj) });
                
        /* 
         *   Add any items from remote locations that meet the same conditions,
         *   making the list unique so we don't get any duplicates.
         */
        notifyList = notifyList.appendUnique(remoteList(obj));
        
        /*  
         *   Notify every item in our notification list that this event has just
         *   occurred.
         */
        for(local cur in notifyList)
            cur.(notifyProp)(self, obj);
    }
    
    /* 
     *   A property pointer to the property on each notified object that needs
     *   to be executed when it's notified of this SensoryEvent (e.g.
     *   &notifySoundEvent).
     */
    notifyProp = nil
    
    /*   
     *   The property pointer relating to the Q method that needs to be called
     *   to determined whethet this SensoryEvent can be sensed (e.g. &canHear).
     */
    senseProp = nil
    
    /*   
     *   The property pointer to the property of Room defining which list of
     *   rooms also needs to be checked for remote items that might sense this
     *   event (e.g. &audibleRooms).
     */
    remoteProp = nil
    
    /*  Construct a list of notifiable objects in remote locations */
    remoteList(obj)
    {
        /* Start with an empty list */
        local lst = [];
        
        /* 
         *   If the SenseRegion class isn't present, there's no point trying to
         *   look for objects in remote rooms.
         */
        if(defined(SenseRegion))
        {
           /* 
            *   Got through each room in the appropriate list of remote rooms
            *   that can be sensed from us through the appropriate sense to
            *   build a list of all their contents which can be senses via the
            *   appropriate sense.
            */
            for(local rm in valToList(obj.getOutermostRoom.(remoteProp)))
                lst = lst.appendUnique(rm.allContents.({
                    o: Q.(senseProp)(o, obj) }));
        }
        
        /* Return the resulting list */
        return lst;
    }
;

/* 
 *   A SoundEvent represents any sudden noise to which other objects or people
 *   might react.
 */
class SoundEvent: SensoryEvent    
    notifyProp = &notifySoundEvent
    senseProp = &canHear
    remoteProp = &audibleRooms
    
;

/* 
 *   A SoundEvent represents any sudden smell to which other objects or people
 *   might react.
 */
class SmellEvent: SensoryEvent    
    notifyProp = &notifySmellEvent
    senseProp = &canSmell
    remoteProp = &smellableRooms
;


/* 
 *   A SightEvent represents any visible event to which other objects or people
 *   might react.
 */
class SightEvent: SensoryEvent    
    notifyProp = &notifySightEvent
    senseProp = &canSee
    remoteProp = &visibleRooms
;

/*  Modifications to Thing to work with the sensory extension */
modify Thing
    /* 
     *   The methods that define our reactions to SoundEvents, SmellEvents and
     *   SightEvents respectively. By default all three methods defer to a
     *   common handler.
     */    
    notifySoundEvent(event, source) { notifyEvent(event, source); }
    notifySmellEvent(event, source) { notifyEvent(event, source); }
    notifySightEvent(event, source) { notifyEvent(event, source); }
        
    /* 
     *   Our common handler for SensoryEvents; it may often be more convenient
     *   to use this than to write separate handlers for each kind of
     *   SensoryEvent, since in any case the event parameter (containing the
     *   SensoryEvent that's just been triggered) tells us what kind of
     *   SensoryEvent it is. The source parameter is the object associated with
     *   the event.
     */
    notifyEvent(event, source) {  }   
    
    /*   
     *   By default we split our smellDesc into smellDescWithoutSource (when the
     *   player character can't see us) and smellDescWithSource (when the pc
     *   can). If we don't need this distinction we can override this method
     *   directly.
     */
    smellDesc()
    {
      if(Q.canSee(gActor, self))
            smellDescWithSource;
        else
            smellDescWithoutSource;   
    }
  
    /* The response to SMELLing this object when the actor can see us. */
    smellDescWithSource = nil

    /* The response to SMELLing this object when the actor can't see us. */
    smellDescWithoutSource = nil
    
    /*   
     *   By default we split our listenDesc into listenDescWithoutSource (when
     *   the player character can't hear us) and listenDescWithSource (when the
     *   pc can). If we don't need this distinction we can override this method
     *   directly.
     */
    listenDesc()
    {
      if(Q.canSee(gActor, self) )
            listenDescWithSource;
        else
            listenDescWithoutSource;   
    }
  
    /* The response to LISTENing TO this object when the actor can see us. */
    listenDescWithSource = nil
    
    /* The response to LISTENing TO this object when the actor can't see us. */
    listenDescWithoutSource = nil    
    
    
    dobjFor(ListenTo)
    {
        action()
        {
            /* 
             *   If I have an associated Noise object which isn't emanating,
             *   then assume I have fallen silent.
             */
            
            if(soundObj != nil && !soundObj.isEmanating)
                say(hearNothingMsg);          
            else
                inherited;
        }
    }
    
    dobjFor(SmellSomething)
    {
        action()
        {
            /* 
             *   If I have an associated Odor object which isn't emanating,
             *   then assume I no longer smell.
             */            
            if(smellObj != nil && !smellObj.isEmanating)
                say(smellNothingMsg);          
            else
                inherited;
        }
    }
    
    /* 
     *   We don't have a prominent smell if we have an associated Odor object
     *   that isn't emanating.
     */
    isProminentSmell
    {
        if(smellObj && !smellObj.isEmanating)
            return nil;
        return true;
    }
    
    /* 
     *   We don't have a prominent noise if we have an associated Noise object
     *   that isn't emanating.
     */
    isProminentNoise
    {
        if(soundObj && !soundObj.isEmanating)
            return nil;
        
        return true;
    }
    
    /* Our associated Odor object, if we have one */
    smellObj = (contents.indexWhich({o: o.ofKind(Odor)}))
    
    /* Our associated Noise object, if we have one. */            
    soundObj = (contents.indexWhich({o: o.ofKind(Noise)}))
;

modify Room
    /* 
     *   Reset every SensoryEmanation in this room to its initial state when the
     *   player character leaves this room.
     */
    notifyDeparture(traveler, dest)
    {
        inherited(traveler, dest);
        
        if(traveler == gPlayerChar)
        {
            local lst = allContents.subset({o: o.ofKind(SensoryEmanation)});
            
            /* 
             *   If the SenseRegion class is included, then we need to deal with
             *   SensoryEmanations in remote rooms.
             */
            if(defined(SenseRegion))
            {
                try
                {
                    scopeProbe_.moveInto(dest);
                    
                    /* First add all the Noises in the remote rooms we can hear */
                    for(local rm in getOutermostRoom.audibleRooms)
                        lst.appendUnique(rm.allContents.subset({o:
                            o.ofKind(Noise)}));
                    
                    /* Then add all the Odors in the remote rooms we can smell */
                    for(local rm in getOutermostRoom.smellableRooms)
                        lst.appendUnique(rm.allContents.subset({o:
                            o.ofKind(Odor)}));
                    
                    /* 
                     *   Finally remove all the Odors that can't be smelled from
                     *   the destination and all the Noises than can't be heard
                     *   from the destination.
                     */
                    lst = lst.subset({o: (o.ofKind(Noise) &&
                                          !Q.canHear(scopeProbe_, o)) 
                                     || (o.ofKind(Odor) 
                                         && !Q.canSmell(scopeProbe_, o))});
                }
                finally
                {
                    scopeProbe_.moveInto(nil);
                }
            }
            
            /* Reset every SensoryEmanation in our list */
            lst.forEach({o: o.reset() });
        }
    }
;
                                       