#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*
 *   sensory.t
 *
 *   The SENSORY EXTENSION is intended for use with the adv3Lite library. It
 *   adds slightly more sophisticated handling for smells and sounds, as well as
 *   a new SensoryEvent class which can be useful for making actors and other
 *   objects respond to sensory events.
 *
 *   VERSION 2
 *.  19-Jul-14
 *
 *   Usage: include this extension after the adv3Lite library but before your
 *   own game-specific files. Make sure that events.t is also included in your
 *   build.
 */


sensoryID: ModuleID
    name = 'Sensory'
    byline = 'by Eric Eve'
    htmlByline = 'by Eric Eve'
    version = '2'    
;

property remoteSmellDesc;
property remoteListenDesc;
property tooFarAwayToHearMsg;
property tooFarAwayToSmellMsg;


/* 
 *   The SensoryEmanation class is the base class for sensory emanations such as
 *   smells and noises. [MODIFIED FOR SENSORY EXTENSION]
 */
modify SensoryEmanation
    
    /* 
     *   By default we vary our description according to whether the player
     *   character can see the object whose sound or smell we represent. If you
     *   don't these this variation, you can just override desc directly.
     *   [MODIFIED FOR SENSORY EXTENSION]
     */
    desc
    {
        if(Q.canSee(gPlayerChar, location))
            descWithSource;
        else
            descWithoutSource;
    }
    
    /* 
     *  Our description when the player character can see our source 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    descWithSource = nil
    
    /* 
     *  Our description when the player character can't see our source 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    descWithoutSource = nil
    
    /*  
     *   Are we actually emanating? We may not be if something stops us, e.g.
     *   breaking a ticking clock [DEFINED IN SENSORY EXTENSION]
     */
    isEmanating = true
    
    /*  
     *  If we're not emanating we can't be sensed at all, so we're hidden 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    isHidden = !isEmanating
    
    /* 
     *   The emanate method is called on each turn that the player character can
     *   sense us, and can be used to display a message announcing our presence,
     *   such as "There's an awful stink here" or "A loud ticking noise comes
     *   from somewhere. " [DEFINED IN SENSORY EXTENSION]
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
            
            /*  Note that the player character must now know about us. */
            setKnown();
        }
    }
    
    /* 
     *   The message to display to announce our presence. This is overridden on
     *   our subclasses.[DEFINED IN SENSORY EXTENSION]
     */
    emanationDesc() { }
    
    /*  
     *   A counter to keep track of when we're next due to display an emanation
     *   message [DEFINED IN SENSORY EXTENSION]
     */
    emanationState = 0
    
    /*  
     *  A counter to keep track of where we are in our emanation schedule. 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    scheduleState = 1
    
    /*  
     *  The last time we emanated, relevant to when we started emanating 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    lastEmanationTime = 0
    
    /*  
     *   Our emanation schedule. If this is just nil we won't show any emanation
     *   meessages at all. Otherwise this should be a list of numbers. The first
     *   number is the first interval between emanations, the second number the
     *   second interval and so on. When we get to the end of the list we keep
     *   using the last number in the list as the interval. If the last entry in
     *   the list is nil we stop showing emanation messages. This can be used to
     *   reduce the frequency of messages to model the player character becoming
     *   less aware of us. [DEFINED IN SENSORY EXTENSION]
     */
    schedule = [1]

    /*  Reset all out counters to their initial states [DEFINED IN SENSORY EXTENSION] */
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
     *   other than sense us. [DEFINED IN SENSORY EXTENSION]
     */
    notImportantMsg = BMsg(cannot do to sensory, '{I} {can\'t} do that to {a
        cobj}. ')
;

/* An Odor is a SensoryEmanation representing a Smell [MODIFIED FOR SENSORY EXTENSION]*/
modify Odor
        
    /*   
     *   The message to be displayed to show that there's a smell here. The
     *   default implementation should be serviceable in many cases, but game
     *   code can easily override this method if something different is
     *   required.[DEFINED IN SENSORY EXTENSION]
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
     *   messages. [DEFINED IN SENSORY EXTENSION]
     */
    emanate()
    {
        if(!gActionIn(Smell, SmellSomething))
            inherited;
    }    
;

/*  
 *   A SimpleOdor is an object representing a free-standing smell directly
 *   present in a location rather than attached to any specific object. It can
 *   be used to display atmospheric smells either according to its schedule or
 *   in response to a SMELL command.
 */
SimpleOdor: Odor
    /*  
     *   Unless this is overridden, our desc property simply executes our
     *   script.
     */
    desc() { doScript(); }
    
    /* The smellDesc of a SimpleOdor is simply its desc. */
    smellDesc = desc
      
    /* 
     *   A SimpleOdor is a prominent smell by default, since we want it to show
     *   up in response to a SMELL command.
     */
    isProminentSmell = true
    
    emanationDesc()
    { 
        
        if(!isIn(gRoom) && propDefined(&remoteSmellDesc))
            remoteSmellDesc(gPlayerChar);
        else
            smellDesc;        
    }
    
;

/* [MODIFIED FOR SENSORY EXTENSION] */
modify Noise   
    
    /*   
     *   The message to be displayed to show that there's a noise here. The
     *   default implementation should be serviceable in many cases, but game
     *   code can easily override this method if something different is
     *   required. [DEFINED IN SENSORY EXTENSION]
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
     *   messages. [DEFINED IN SENSORY EXTENSION]
     */
    emanate()
    {
        if(!gActionIn(Listen, ListenTo))
            inherited;
    }  
;

/*  
 *   A SimpleNoise is an object representing a free-standing sound directly
 *   present in a location rather than attached to any specific object. It can
 *   be used to display atmospheric sounds either according to its schedule or
 *   in response to a LISTEN command.
 */
SimpleNoise: Noise
    /*  
     *   Unless this is overridden, our desc property simply executes our
     *   script.
     */
    desc() { doScript(); }
    
    /* The listenDesc of a SimpleNoise is simply its desc. */
    listenDesc = desc
     
    /* 
     *   A SimpleNoise is a prominent noise by default, since we want it to show
     *   up in response to a LISTEN command.
     */
    isProminentNoise = true
 
    /*   
     *   The message to be displayed to show that there's a noise here. The
     *   default implementation should be serviceable in many cases, but game
     *   code can easily override this method if something different is
     *   required. [DEFINED IN SENSORY EXTENSION]
     */
    emanationDesc()
    { 
        
        if(!isIn(gRoom) && propDefined(&remoteListenDesc))
            remoteListenDesc(gPlayerChar);
        else
            listenDesc;        
    }
;


/* 
 *  The object which drives emanation messages for Odors and Noises 
 *  [DEFINED IN SENSORY EXTENSION]
 */
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
 *   other actors or objects in the vicinity may react. [DEFINED IN SENSORY EXTENSION]
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
        
        /*  
         *   Presumablty obj has just made its presence known to the player
         *   character, even if it wasn't before.
         */
        obj.setKnown();
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
 *   might react. [DEFINED IN SENSORY EXTENSION]
 */
class SoundEvent: SensoryEvent    
    notifyProp = &notifySoundEvent
    senseProp = &canHear
    remoteProp = &audibleRooms
    
;

/* 
 *   A SoundEvent represents any sudden smell to which other objects or people
 *   might react. [DEFINED IN SENSORY EXTENSION]
 */
class SmellEvent: SensoryEvent    
    notifyProp = &notifySmellEvent
    senseProp = &canSmell
    remoteProp = &smellableRooms
;


/* 
 *   A SightEvent represents any visible event to which other objects or people
 *   might react. [DEFINED IN SENSORY EXTENSION]
 */
class SightEvent: SensoryEvent    
    notifyProp = &notifySightEvent
    senseProp = &canSee
    remoteProp = &visibleRooms
;

/*  Modifications to Thing to work with the SENSORY EXTENSION */
modify Thing
    /* 
     *   The methods that define our reactions to SoundEvents, SmellEvents and
     *   SightEvents respectively. By default all three methods defer to a
     *   common handler. [DEFINED IN SENSORY EXTENSION]
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
     *   the event. [DEFINED IN SENSORY EXTENSION]
     */
    notifyEvent(event, source) {  }   
    
    /*   
     *   By default we split our smellDesc into smellDescWithoutSource (when the
     *   player character can't see us) and smellDescWithSource (when the pc
     *   can). If we don't need this distinction we can override this method
     *   directly. [MODIFIED FOR SENSORY EXTENSION]
     */
    smellDesc()
    {
      if(Q.canSee(gActor, self))
            smellDescWithSource;
        else
            smellDescWithoutSource;   
    }
  
    /* 
     *  The response to SMELLing this object when the actor can see us. 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    smellDescWithSource = nil

    /* 
     *  The response to SMELLing this object when the actor can't see us. 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    smellDescWithoutSource = nil
    
    /*   
     *   By default we split our listenDesc into listenDescWithoutSource (when
     *   the player character can't hear us) and listenDescWithSource (when the
     *   pc can). If we don't need this distinction we can override this method
     *   directly. [MODIFIED FOR SENSORY EXTENSION]
     */
    listenDesc()
    {
      if(Q.canSee(gActor, self) )
            listenDescWithSource;
        else
            listenDescWithoutSource;   
    }
  
    /* 
     *  The response to LISTENing TO this object when the actor can see us. 
     *  [DEFINED IN SENSORY EXTENSION]
     */
    listenDescWithSource = nil
    
    /* 
     *   The response to LISTENing TO this object when the actor can't see us. 
     *   [DEFINED IN SENSORY EXTENSION]
     */
    listenDescWithoutSource = nil    
    
    /* [MODIFIED FOR SENSORY EXTENSION] */
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
    
    /* [MODIFIED FOR SENSORY EXTENSION] */
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
     *   that isn't emanating. [MODIFIED FOR SENSORY EXTENSION]
     */
    isProminentSmell
    {
        if(smellObj && !smellObj.isEmanating)
            return nil;
        return true;
    }
    
    /* 
     *   We don't have a prominent noise if we have an associated Noise object
     *   that isn't emanating. [MODIFIED FOR SENSORY EXTENSION]
     */
    isProminentNoise
    {
        if(soundObj && !soundObj.isEmanating)
            return nil;
        
        return true;
    }
    
    /* Our associated Odor object, if we have one */
    smellObj = (contents.valWhich({o: o.ofKind(Odor)}))
    
    /* Our associated Noise object, if we have one. */            
    soundObj = (contents.valWhich({o: o.ofKind(Noise)}))
;

/* MODIFICATIONS FOR SENSORY EXTENSION */
modify Room
    /* 
     *   Reset every SensoryEmanation in this room to its initial state when the
     *   player character leaves this room. [MODIFIED FOR SENSORY EXTENSION]
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
                local sp = defined(scopeProbe_) ? scopeProbe_ : object: Thing {};
                try
                {                    
                    sp.moveInto(dest);
                    
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
                                          !Q.canHear(sp, o)) 
                                     || (o.ofKind(Odor) 
                                         && !Q.canSmell(sp, o))});
                }
                finally
                {
                    
                    sp.moveInto(nil);
                }
            }
                
            /* Reset every SensoryEmanation in our list */
            lst.forEach({o: o.reset() });
        }
    }
;
                                       