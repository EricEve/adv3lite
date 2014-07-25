#charset "us-ascii"
#include "advlite.h"

/*----------------------------------------------------------------------------*/
/*  
 *   SYSRULES (System Rules) EXTENSION By Eric Eve
 *
 *   This extension requires the Rules Extension
 *
 *   The Sysrules extension defines a number of rulebooks and rules that add
 *   more flexibility to certain aspects of the adv3Lite library.
 */

/*  
 *   RuleBook that can contain rules run at Preinit. By default this Rulebook
 *   starts out empty.
 */
preinitRules: RuleBook
    contValue = nil
;

/* PreinitObject to run PreinitRules. */
preinitRulesRunner: PreinitObject
    execute()
    {
        preinitRules.follow();
    }
    /* 
     *   Make sure we've initialized both the library and all the rules before
     *   we try to run our rules.
     */
    execBeforeMe = [adv3LibPreinit, rulePreinit]
;

/* A rule belonging to the preinitRules RuleBook. */
class PreinitRule: Rule
    location = preinitRules
;

/*  
 *   RuleBook that can contain rules run at Init. By default this Rulebook
 *   starts out empty. */

initRules: RuleBook
    contValue = nil
;

/* InitObject to run InitRules. */
initRulesRunner: InitObject
    execute()
    {
        initRules.follow();
    }
    execBeforeMe = [adv3LibInit]
;


/* A rule belonging to the initRules RuleBook. */
class InitRule: Rule
    location = initRules
;

/* A Rule beloning to the turnEndRules RuleBook. */
class TurnEndRule: Rule
    location = turnEndRules
;

/* 
 *   The turnEndRules execute the various things that need to happen at the end
 *   of each turn, including the current location's roomDaemon, any current
 *   Fuses and Daemons (via the eventManager), and advancing the turn counter.
 *   Additional rules can be added if game code wants something else to occur at
 *   the end of each turn.
 */
turnEndRules: RuleBook
    contValue = nil
;

+ turnEndSpacerRule: Rule
    follow()
    {
        "<.p>";
    }
    priority = 10000
;

+ roomDaemonRule: Rule
    follow()
    {
        /* Execute the player character's current location's roomDaemon. */
        gPlayerChar.getOutermostRoom.roomDaemon();  
    }
    priority = 9000
;
    
+  executeEventsRule: Rule
    follow()
    {
        /* 
         *   If the events.t module is included, execute all current Daemons and
         *   Fuses/
         */
        if(defined(eventManager) && eventManager.executeTurn())          
            ;
    }
    priority = 8000
;

+ advanceTurnCounterRule: Rule
    follow()
    {
        /* Advance the turn counter */
        libGlobal.totalTurns += gAction.turnsTaken;
    }
    priority = 50
;
        
/*  
 *   An AfterRule is a rule belonging to the afterRules Rulebook. Note than
 *   unlike after rules in I7 these are executed after the action is fully
 *   complete, i.e. *after* the report stage.
 */
class AfterRule: Rule
    location = afterRules
    
    /* The current action */
    currentAction = (rulebook.currentAction)
;

/*  Rulebook to carry out after action notifications. */
afterRules: RuleBook
    contValue = nil
    
    /* 
     *   The current action; this is set by the current action's afterAction()
     *   method.
     */
    currentAction = nil
;

checkIlluminationRule: AfterRule
    follow()
    {
        /* 
         *   If the actor is still in the same room s/he started out in, check
         *   whether the current illumination level has changed, and, if so,
         *   either show a room description or announce the onset of darkness,
         *   as appropriate.
         */
        local ac = currentAction;
        
        if(ac.oldRoom == gActor.getOutermostRoom)
        {
            if(ac.oldRoom.isIlluminated)
            {
                if(!ac.wasIlluminated)
                {   
                    "<.p>";
                    ac.oldRoom.lookAroundWithin();
                }
            }
            else if(ac.wasIlluminated)
            {
                DMsg(onset of darkness, '\n{I} {am} plunged into darkness. ');
            }
        }
        "<.p>";
        
    }
    priority = 10000
;
    
notifyScenesAfterRule: AfterRule
    follow()
    {
        /* Call the afterAction notifications on all currently active scenes. */
        if(defined(sceneManager))
           sceneManager.notifyAfter();        
    }
    priority = 9000
;

roomNotifyAfterRule: AfterRule
    follow()
    {
        /* 
         *   Call the afterAction notification on the current room and its
         *   regions.
         */
        gActor.getOutermostRoom.notifyAfter();
    }
    
    priority = 8000
;

scopeListNotifyAfterRule: AfterRule
    follow()
    {
        
        /* 
         *   Call the afterAction notification on every object in scope. Note
         *   that we have to recalculate the scope list here in case the action
         *   has changed it.
         */
        foreach(local cur in Q.scopeList(gActor))
        {
            cur.afterAction();
        }
        
    }
    
    priority = 7000    
;

/*  
 *   The BeforeRule class provides a convenient means of defining rules that
 *   belong to the beforeRules RuleBook. We derive it from ReplaceRedirector as
 *   well as Rule in case users want to use the doInstead() interface to
 *   redirect one action to another from a BeforeRule.
 */
class BeforeRule: Rule, ReplaceRedirector
    location = beforeRules
    
    /* The current action */
    currentAction = (rulebook.currentAction)
;

/*  
 *   The main function of the beforeRules is to carry out our before action
 *   notifications.
 */
beforeRules: RuleBook
    contValue = nil
    
    /* 
     *   The current action; this is set by the current action's beforeAction()
     *   method.
     */
    currentAction = nil
;

checkActionPreconditionsRule: BeforeRule
    follow()
    {
        /* 
         *   Check any Preconditions relating to the action as a whole (as
         *   opposed to any of its objects.
         */
        if(!currentAction.checkActionPreconditions())
            exit;
    }
    
    priority = 10000
;

actorActionRule: BeforeRule
    follow()
    {
        /*  
         *   Call the before action handling on the current actor (in its
         *   capacity as actor)
         */
        gActor.actorAction();
    }
    
    priority = 9000
;

sceneNotifyBeforeRule: BeforeRule
    follow()
    {
        /* 
         *   If the sceneManager is present then send a before action
         *   notification to every currently active Scene.
         */
        if(defined(sceneManager))
            sceneManager.notifyBefore();
    }
    
    priority = 8000
;

roomNotifyBeforeRule: BeforeRule
    follow()
    {
        /* 
         *   Call roomBeforeAction() on the current actor's location, and
         *   regionBeforeAction() on all the regions it's in.
         */        
        gActor.getOutermostRoom.notifyBefore();   
    }
    
    priority = 7000
;

scopeListNotifyBeforeRule: BeforeRule
    follow()
    {
        /* Call the beforeAction method of every action in scope. */
        foreach(local cur in currentAction.scopeList)
        {
            cur.beforeAction();
        }
    }
    
    priority = 6000
;


modify Action
    
    /* 
     *   Carry out the post-action processing. This first checks to see if
     *   there's been a change in illumination. If there has we either show a
     *   room description (if the actor's location is now lit) or announce the
     *   onset of darkness. We then call the after action notifications first on
     *   the actor's current room and then on every object in scope.
     *
     *   Note that afterAction() is called from the current Command object.
     */
    afterAction()
    {
        /* 
         *   If the current action is considered a failure, we don't carry out
         *   any after action handling, since in this case there's no action to
         *   react to.
         */
        if(actionFailed)
            return;
        
        /*  
         *   Register ourselves as the current action for our afterRules
         *   Rulebook
         */
        afterRules.currentAction = self;
        
        
        /*   
         *   Let the afterRules carry out the rest of the after action handling.
         */
        afterRules.follow();
        
    }
    
    beforeAction()
    {
        
        /* 
         *   If we don't already have a scope list for the current action, build
         *   it now.
         */
        if(nilToList(scopeList).length == 0)
            buildScopeList;
        
        /*   
         *   Register this action as the one the beforeRules RuleBook needs to
         *   deal with.
         */
        beforeRules.currentAction = self;
              
        /*  
         *   Get the beforeRules RuleBook to carry out the rest of the before
         *   action handling.
         */
        beforeRules.follow();
        
    }
    
    
    doAction() 
    { 
        actionRules.currentAction = self;
        
        actionRules.follow();
    }
    
    turnSequence()
    {
        /* Execute the rulebook that takes care of end-of-turn processing */
        turnEndRules.follow();                   
    }
;

class ActionRule: Action, ReplaceRedirector
    location = actionRules
;


actionRules: RuleBook
    currentAction = nil
;

standardActionRule: ActionRule
    follow()
    {
        local ca = currentAction;
        ca.curDobj.(ca.actionDobjProp);        
    }
    
    priority = 0
;



/*  
 *   The reportRules provide a convenient entry point to customize standard
 *   action reports under particular circumstances.
 */
reportRules: RuleBook
    /* 
     *   The current action; this is set by the current action's report()
     *   method.
     */
    currentAction = nil
    
    /* 
     *   This is the one RuleBook where we don't define contValue = nil, since
     *   normally we'll want the first matching rule to stop execution of the
     *   rulebook.
     */
    // contValue = null
;

/* A ReportRule is a rule belonging to the reportRules RuleBook. */
class ReportRule: Rule   
    location = reportRules
    
    /* The current action (the action that has just invoked our rulebook). */
    currentAction = (rulebook.currentAction)
;

reportImplicitActionsRule: ReportRule
    follow()
    {
        /* Output any pending implicit action reports */
        "<<currentAction.buildImplicitActionAnnouncement(true)>>";   
        
        nostop;
    }
    
    priority = 10000
;

/*  
 *   The standardReportRule reports the action in the standard way defined on
 *   the direct object's action-specified report method.
 */
standardReportRule: ReportRule
    follow()
    {
        local ca = currentAction;
        
        ca.curDobj.(ca.reportDobjProp); 
    }
    
    /* 
     *   Make this normally the last report rule to be considered, so that any
     *   custom rule will take precedence.
     */
    priority = 0
;


modify TAction
    /* 
     *   MODIFIED FOR SYSRULES EXTENSION   
     *
     *   reportAction() is called only after all the action routines have been
     *   run and the list of dobjs acted on is known. It only does anything if
     *   the action is not implicit. It can thus be used to summarize a list of
     *   identical actions carried out on every object in reportList or to print
     *   a report that is not wanted if the action is implicit. By default we
     *   call the dobj's reportDobjProp to handle the report.
     *
     *   Note that this method is usually called from the current Command object
     *   after its finished iterated over all the direct objects involved in the
     *   command.
     *
     *   This modified version uses the reportRules rulebook to make it easy to
     *   insert differently worded summary reports.
     */    
    reportAction()
    {
        /* 
         *   If we're not an implicit action and there's something in our report
         *   list to report on, execute the report stage of this action.
         */
        if(!isImplicit && reportList.length > 0)
        {
            /* Register this action with the reportRules RuleBook */
            reportRules.currentAction = self;
            
            /* Let the report rules handle it. */
            reportRules.follow();                      
        }

    }
;

/* ------------------------------------------------------------------------ */
/* 
 *   Modified version to work with the turnStartRules. This repeatedly prompts
 *   the player for a command and then processes the command until the game
 *   ends.
 */

replace mainCommandLoop()
{

    local txt;

    /* 
     *   Set the current actor to the player character at the start of the game
     *   (to ensure we have a current actor defined).
     */
    gActor = gPlayerChar;
    
    /* 
     *   Repeat this loop, which asks for a command and then parses it, until
     *   the game comes to an end.
     */
    do
    {
        turnStartRules.follow();
            
        
        /* 
         *   From here on use code from the original version of mainCommandLoop,
         *   since it's awkward to continue to follows rules inside the try...
         *   catch block, and in any case it would be inadvisable to tamper with
         *   what this section of code does.
         */
        try
        {
            /* Read a new command from the keyboard. */
            txt = inputManager.getInputLine();
            "<./inputline>\n";   
            
            /* Pass the command through all our StringPreParsers */
            txt = StringPreParser.runAll(txt, Parser.rmcType());
            
            /* 
             *   If the txt is now nil, a StringPreParser has fully dealt with
             *   the command, so go back and prompt for another one.
             */        
            if(txt == nil)
                continue;
            
            /* Parse and execute the command. */
            Parser.parse(txt);
        }
        catch(TerminateCommandException tce)
        {
            
        }      
        
    } while (true);    
    
}


turnStartRules: RuleBook
    contValue = nil
;

class TurnStartRule: Rule
    location = turnStartRules
;

updateStatusLineRule: TurnStartRule
    follow()
    {
         /* Update the status line. */
        statusLine.showStatusLine();
    }
    
    priority = 1000
;


scoreNotificationRule: TurnStartRule
    follow()
    {
        /* Display score notifications if the score module is included. */
        if(defined(scoreNotifier) && scoreNotifier.checkNotification())
            ;
    }
    
    priority = 9000
;

promptDaemonRule: TurnStartRule
    follow()
    {
        /* run any PromptDaemons if the events module is included */
        if(defined(eventManager) && eventManager.executePrompt())
            ;
    }
    priority = 8000
;

commandSpacingRule: TurnStartRule
    follow()
    {
        /* Output a paragraph break */
        "<.p>";
    }
    
    /* 
     *   We give this a low priority since this should normally come just before
     *   the command prompt.
     */
    priority = 20
;

startInputLineRule: TurnStartRule
    follow()
    {
        "<.inputline>";
    }
    priority = 10
;

displayCommandPromptRule: TurnStartRule
    follow()    
    {            
        DMsg(command prompt, '>');        
    }
    
    /* 
     *   This rule should normally be executed right at the end of its RuleBook,
     *   just before inputting a command.
     */
    priority = 0
;

