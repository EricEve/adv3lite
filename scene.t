#include "advlite.h"


/*
 *   ****************************************************************************
 *    scene.t 
 *    This module forms an optional part of the adv3Lite library 
 *    (c) 2012-13 Eric Eve
 */

/* 
 *   The sceneManager object is used to control the scene-switching and
 *   execution mechanism.
 */
sceneManager: InitObject
    execute()
    {
        /* Set up a daemon to start, stop and run scenes each turn.  */        
//        local daem = new Daemon(self, &doScenes, 1);
        
        /* Run the scene manager late in the daemon sequence. */
//        daem.eventOrder = 1000;
        
         /* 
         *   Set up a new Schedulable in the game to run our doScene method each
         *   turn
         */
        local sceneSchedule = object {           
            eventOrder = 200;
            executeEvent() { sceneManager.doScenes(); }
        };
            
        eventManager.schedulableList += sceneSchedule;
        
        /* 
         *   Run the doScenes() method for the first time to set up any scenes
         *   that should be active at the start of play.
         */
        doScenes();
    }
    
    /* The doScenes() method is run each turn to drive the Scenes mechanism */
    doScenes()
    {
        /* Go through each Scene defined in the game in turn. */
        for(local scene = firstObj(Scene); scene != nil ; scene = nextObj(scene,
            Scene))
            
        {
            /* 
             *   If the scene's startsWhen condition is true and the scene is
             *   not already happening, then provided it's a recurring scene or
             *   it's never been started before, start the scene.
             */
            if(scene.startsWhen && !scene.isHappening 
               && (scene.recurring || scene.startedAt == nil))
                scene.start();
            
            /*  
             *   If the scene is happening and its endsWhen property is non-nil,
             *   then record the value of its endsWhen property in its howEnded
             *   property and end the scene.
             */
            if(scene.isHappening && (scene.howEnded = scene.endsWhen) != nil)
                scene.end();
            
            /* If the scene is happening, call its eachTurn() method */
            if(scene.isHappening)
                scene.eachTurn();
        }        
    }  
    
    execBeforeMe = [adv3LibInit]
;


/* 
 *   A Scene is an object that represents a slice of time that starts and ends
 *   according to specified conditions, and which can define what happens when
 *   it starts and ends and also what happens each turn when it is happening.
 */
class Scene: object
    
    /* 
     *   An expression or method that evaluates to true when you want the scene
     *   to start
     */
    startsWhen = nil
    
    /*  
     *   an expression or method that evaluates to something other than nil when
     *   you want the scene to end
     */
    endsWhen = nil
    
    /* 
     *   Normally a scene will only occur once. Set recurring to true if you
     *   want the scene to start again every time its startsWhen condition is
     *   true.
     */
    recurring = nil
    
    /* 
     *   Is this scene currently taking place? (Game code should treat this as
     *   read-only)
     */
    isHappening = nil
    
    /* The turn this scene started at */
    startedAt = nil
    
    /* The turn this scene ended at */
    endedAt = nil
    
    /* 
     *   The method executed when this Scene starts. Game code should normally
     *   override whenStarting() rather than this method.
     */
    start()
    {
        /* Note that this Scene is now happening */
        isHappening = true;
        
        /* Note the turn on which this Scene started */
        startedAt = libGlobal.totalTurns;
        
        /* 
         *   Execute our whenStarting() method to carry out the particular
         *   effects of this scene starting.
         */
        whenStarting();
    }
    
    /* 
     *   The method executed when this Scene ends. Game code should normally
     *   override whenStarting() rather than this method.
     */    
    end()
    {  
        /* 
         *   Execute our whenEnding method to carry out any particular effects
         *   of this scene coming to an end.
         */
        whenEnding();
        
        /* Note that this scene is no longer happening. */
        isHappening = nil;
        
        /* Note the turn on which this scene ended. */
        endedAt = libGlobal.totalTurns;       
        
        /* 
         *   Increment the counter of the number of times this scene has
         *   happened.
         */
        timesHappened++ ;        
    }
    
    /* Routine to execute when this scene starts */
    whenStarting() {}
    
    /* Routine to execute when this scene ends */
    whenEnding() {}
    
    /* Routine to execute every turn this scene is in progress. */
    eachTurn() {}
    
    /* Flag to show whether this scene has ever happened. */
    hasHappened = (endedAt != nil)
    
    /* The numbter of times this scene has happened. */
    timesHappened = 0
    
    /*  A user defined flag showing how the scene ended */
    howEnded = nil    
;

