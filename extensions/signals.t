#charset "us-ascii"
#include "advlite.h"

/*--------------------------------------------------------*/
/*
 *   SIGNAL EXTENSION Still at an experimental stage
 *
 *   To use this extension, include the relations extensions before it.
 */

/* 
 *   A Signal is a kind of Relation that can be used to send a signal from a
 *   sender to all the objects related to that sender via this Signal Relation.
 *
 *   For a signal to be sent from a sender to a receiver, a relationship first
 *   needs to be set up between them with a statement like:
 *
 *   relate(sender, signal, receiver);
 *
 *   Where signal is either the programmatic name or the string name of the
 *   signal we want sent.
 *
 *   To break the link subsequently we can use:
 *
 *   unrelate(sender, signal, receiver);
 */
Signal: Relation
    /* Signals can potentially relate many things to many other things. */
    relationType = manyToMany
    
    /* 
     *   Notify every object related to sender by us to handle us as a signal
     *   from sender.
     */
    emit(sender)
    {
        relatedTo(sender).forEach({ obj: obj.handle(sender, self) });
    }
;

/* Signals to handle common state changes on Thing */
litSignal: Signal 'lit';
unlitSignal: Signal 'unlit';
discoverSignal: Signal 'discover';
undiscoverSignal: Signal 'undiscover';
lockSignal: Signal 'lock';
unlockSignal: Signal 'unlock';
onSignal: Signal 'turned on';
offSignal: Signal 'turned off';
wornSignal: Signal 'worn';
doffSignal: Signal 'doffed';
moveSignal: Signal 'moved' destination = nil;
seenSignal: Signal 'seen' location = nil;
examinedSignal: Signal 'examined' actor = nil;
takeSignal: Signal 'take' actor = nil;
dropSignal: Signal 'drop' actor = nil;
openSignal: Signal 'open';
closeSignal: Signal 'close';


modify Thing
    /* Emit a signal */
    emit(signal)
    {
        /* Simply call the signal's emit method with ourselves as the sender. */
        signal.emit(self);
    }
    
    /* 
     *   Handle a signal from sender; game code will need to override particular
     *   instances
     */
    handle(sender, signal)
    {
    }
    
    /*  
     *   Make various common state changes and actions emit the appropriate
     *   signals.
     */
    makeLit(stat)
    {
        inherited(stat);
        emit(stat ? litSignal : unlitSignal);
    }
    
    discover(stat = true)
    {
        inherited(stat);
        emit(stat ? discoverSignal : undiscoverSignal);
    }
    
    makeLocked(stat)
    {
        inherited(stat);
        emit(stat ? lockSignal : unlockSignal);       
    }
    
    makeOn(stat)
    {
        inherited(stat);
        emit(stat ? onSignal: offSignal);
    }
    
    makeWorn(stat)
    {
        inherited(stat);
        emit(stat? wornSignal : doffSignal);
    }
    
    moveInto(newCont)
    {
        inherited(newCont);
        moveSignal.destination = newCont;
        emit(moveSignal);
    }
    
    noteSeen()
    {
        inherited();
        seenSignal.location = location;
        emit(seenSignal);
    }
    
    dobjFor(Examine)
    {
        action()
        {
            inherited();
            examinedSignal.actor = gActor;
            emit(examinedSignal);
        }
    }
    
    dobjFor(Take)
    {
        action()
        {
            inherited();
            takeSignal.actor = gActor;
            emit(takeSignal);
        }
    }
    
    dobjFor(Drop)
    {
        action()
        {
            inherited();
            dropSignal.actor = gActor;
            emit(dropSignal);
        }
    }
    
    makeOpen(stat)
    {
        inherited(stat);
        emit(stat ? openSignal : closeSignal);
    }
;
    
    
    