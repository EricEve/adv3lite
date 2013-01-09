#include "advlite.h"


sceneManager: object
    
    doScenes()
    {
        for(local scene = firstObj(Scene); scene != nil ; scene = nextObj(scene,
            Scene))
            
        {
            if(scene.startsWhen && !scene.isHappening 
               && (scene.recurring || scene.startedAt == nil))
                scene.start();
            
            if(scene.isHappening && (scene.howEnded = scene.endsWhen) != nil)
                scene.end();
            
            if(scene.isHappening)
                scene.eachTurn();
        }
        
    }
;


class Scene: object
    
    /* 
     *   an expression or method that evaluates to true when you want the scene
     *   to start
     */
    startsWhen = nil
    
    /*  
     *   an expression or method that evaluates to something other than nil when
     *   you want the scene to end
     */
    endsWhen = nil
    
    /* 
     *   Normally a scene will only occur once. Set isRecurring to true if you
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
    
    start()
    {
        isHappening = true;
        startedAt = libGlobal.totalTurns;
        whenStarting();
    }
    
    
    
    end()
    {        
        whenEnding();
        isHappening = nil;
        endedAt = libGlobal.totalTurns;       
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


InitObject
    execute()
    {
        /* Set up a daemon to start, stop and run scenes each turn.  */        
        local daem = new Daemon(sceneManager, &doScenes, 1);
        
        /* Run the scene manager late in the daemon sequence. */
        daem.eventOrder = 1000;
    }
;

