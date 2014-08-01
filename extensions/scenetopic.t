#charset "us-ascii"
#include "advlite.h"

/* SceneTopic Extension, based on work by D.Smith */

/* Modifications to Scene for the SCENETOPIC EXTENSION */
modify Scene
    /* Modified for SceneTopic Extension */
    end()
    { 
        /* Carry out the inherited handling */
        inherited();
        
        /* Notify any actor that we can talk to that this scene had ended */
        notifyActors(&sceneEndTopics);
    }
    
    /*  Modified for SceneTopic Extension */
    start()    
    {
        /* Carry out the inherited handling */     
        inherited();
        
         /* Notify any actor that we can talk to that this scene had started */
        notifyActors(&sceneStartTopics);
    }
    
    notifyActors(prop)
    {
        /* Set up a new vector */
        local vec = new Vector;
        
        /* 
         *   Loop through every actor in the game, adding every actor that
         *   gPlayerChar can talk to to our vector.
         */
        forEachInstance(Actor, function(a) {
            if(gPlayerChar.canTalkTo(a))
                vec.append(a);            
        });
        
        /* Remove the player char from the list of actors to notify */
        vec -= gPlayerChar;
        
        /* Sort the list in ascending order of notificationOrder */
        vec.sort(SortAsc, {a, b: a.notificationOrder - b.notificationOrder} );
        
        /* Notify each actor in the resultant list. */
        foreach(local cur in vec)
        {           
            /* 
             *   If we only want one actor to respond, stop here if the current
             *   actor's handleTopic method returns true to show that a
             *   SceneTopic was matched.
             */
            if(cur.handleTopic(prop, [self], nil) && notifySingleActor)
                break;
        }
    }
    
    /* 
     *   Flag (for use with SceneTopic extension): do we want to trigger a
     *   SceneTopic response from every actor the player char can talk to, or
     *   only the first one we find? By default we assume we want a response
     *   from only one actor. Note that the Actor notificationOrder property can
     *   be defined so that we can select which Actor this will be (the one with
     *   the lowest notificationOrder).
     */
    notifySingleActor = true
;


/* Modifications to ActorTopicDatabase for SceneTopic extension */
modify ActorTopicDatabase
    sceneStartTopics = []
    sceneEndTopics = []
;

/* 
 *   The SceneTopic class (defined in the scenetopic extension) is the base
 *   class
 */
class SceneTopic: ActorTopicEntry
    handleTopic()
    {
        beforeResponse();
        inherited;
        afterResponse();
    }
    
    /* By default, we just dislpay a spacing paragraph break */
    beforeResponse()
    {
        "<.p>";       
    }
    
    /* By default we do nothing here, but game code can override. */
    afterResponse()
    {        
    }
    
;

/* 
 *   A SceneEndTopic is a topic entry that is triggered when any of the scenes
 *   in its matchObj property ends.
 */
class SceneEndTopic: SceneTopic
    includeInList = [&sceneEndTopics]
;


/* 
 *   A SceneStartTopic is a topic entry that is triggered when any of the scenes
 *   in its matchObj property starts.
 */
class SceneStartTopic: SceneTopic
    includeInList = [&sceneStartTopics]
;