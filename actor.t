#charset "us-ascii"
#include "advlite.h"

class Actor: AgendaManager, ActorTopicDatabase, Thing
    
    curState = nil
    
    stateDesc = (curState != nil ? curState.stateDesc : '')
    specialDesc = (curState != nil ? curState.specialDesc : actorSpecialDesc)
    actorSpecialDesc = nil
    
    specialDescBeforeContents = nil
    
    remoteSpecialDesc(pov) 
    { 
        curState == nil ? actorRemoteSpecialDesc(pov) :
        curState.remoteSpecialDesc(pov);
    }
    
    actorRemoteSpecialDesc(pov) { actorSpecialDesc; }
    
    
    setState(stat)
    {
        if(curState != stat)
        {
            if(curState != nil)
               curState.deactivateState(self, stat);
            
            if(stat != nil)
               stat.activateState(self, curState);
            
            curState = stat;
        }
    }
    
   
    
    isFixed = true    
    
    cannotTakeMsg = BMsg(cannot take actor, '{The subj dobj} {won\'t} let {me}
        pick {him dobj} up. ')
    
    contType = Carrier
    
    /* 
     *   We don't normally list the contents of an Actor when Looking or
     *   Examining.
     */
    contentsListed = nil
    
    
    noResponseMsg = BMsg(no response, '{The subj cobj} {does} not respond. ')
    
    kissResponseMsg = BMsg(kiss, '{The subj dobj} {does}n\'t like that. ')
    
    handleCommand(action)
    {
        /* 
         *   if the Command is GiveTo and the iobj is the player char, treat it
         *   as Ask for with the player char as the effective actor
         */
        
        if(action.ofKind(GiveTo) && gCommand.iobj == gPlayerChar)
        {
            gCommand.actor = gPlayerChar;
            handleTopic(&askForTopics, gCommand.dobj);
        }
        /* 
         *   if the command is TellAbout then convert the command from X,tell me
         *   about Y to ASK X ABOUT Y
         */
        else if(action.ofKind(TellAbout) && gCommand.dobj == gPlayerChar)
        {
            /* 
             *   if the command appears to ask the actor to tell the pc about
             *   the pc, the player probably intended to tell the actor to tell
             *   the pc about the actor (the reference of 'yourself' would be
             *   the actor, not the pc).
             */
            if(gCommand.iobj.topicList[1] == gPlayerChar)
                gCommand.iobj.topicList[1] = self;
            
            /* 
             *   since we've translated this into an ASK ABOUT command, the
             *   effective actor is now the player char.
             */
            gCommand.actor = gPlayerChar;
            
            handleTopic(&askTopics, gCommand.iobj.topicList);
        }
        
        /* exclude SystemActions as a matter of course */
        else if(action.ofKind(SystemAction))
        {
            DMsg(cant command system action, 'Only the player can carry out
                that kind of command. ');
        }
        /* treat Actor, hello as saying hello to the actor */
        else if(action.ofKind(Hello))
        {
            gCommand.actor = gPlayerChar;
            sayHello();
        }
        /* treat Actor, Bye as saying goodbye to the actor */
        else if(action.ofKind(Goodbye))
        {
            gCommand.actor = gPlayerChar;
            sayGoodbye();
        }    
        /* treat Actor, question as directing a question to the actor */
        else if(action.ofKind(Query))
        {
            gCommand.actor = gPlayerChar;
            gAction.qType = gCommand.verbProd.qtype;
            handleTopic(&queryTopics, gCommand.dobj.topicList);
        }
        /* treat Actor, (say) something as SAY SOMETHING TO ACTOR */
        else if(action.ofKind(SayAction))
        {
            gCommand.actor = gPlayerChar;            
            handleTopic(&sayTopics, gCommand.dobj.topicList);
        }
        
        /* Otherwise try letting a CommandTopic handle it */
        else
        {
            action.curDobj = gCommand.dobj;
            action.curIobj = gCommand.iobj;
            handleTopic(&commandTopics, action, &refuseCommandMsg);
        }
    }
    
    refuseCommandMsg = BMsg(refuse command, '{I} {have} better things to do. ')
    
    getBestMatch(myList, requestedList)
    {
        /* 
         *   If we have a current activeKeys list restrict the choice of topic
         *   entries to those whose convkeys overlap with it, at least at a
         *   first attempt. If that doesn't produce a match, try the normal
         *   handling.
         */
        
        if(activeKeys.length > 0)
        {
            local kList = myList.subset({x:
                                   valToList(x.convKeys).overlapsWith(activeKeys)});
            
            local match = inherited(kList, requestedList);
            if(match != nil)
                return match;
        }
      
        return inherited(myList, requestedList);
    }
    
    /* 
     *   Find the best response to the topic produced by the player's command.
     *   prop is the xxxTopics list property we'll use to search for a matching
     *   TopicEntry. We first search the current ActorState for a match and
     *   then, only if we fail to find one, we search TopicEntries directly
     *   located in the actor.
     */
    
    findBestResponse(prop, topic)
    {
        local bestMatch;
        if(curState != nil)
        {
            bestMatch = curState.getBestMatch(curState.(prop), topic);
            if(bestMatch != nil)
                return bestMatch;
        }
        
        return getBestMatch(self.(prop), topic);
    }
    
    handleTopic(prop, topic, defaultProp = &noResponseMsg)
    {
        
        
        local response = findBestResponse(prop, topic);
        
        /* 
         *   If the player tried a (possibly implicit) say command and we didn't
         *   find a match, try to see if we match a non-default AskTopic or
         *   TellTopic instead
         */
        
        if((response == nil || (response.ofKind(DefaultTopic) &&
           !response.ofKind(DefaultSayTopic))) && prop == &sayTopics)
        {
            response = findBestResponse(&askTopics, topic);
            if(response == nil || response.ofKind(DefaultTopic))
            {
                response = findBestResponse(&tellTopics, topic);                
            }
           
        }
        
        if(response != nil)
        {    
            if(gPlayerChar.currentInterlocutor != self &&
               response.isConversational)
            {            
                gPlayerChar.currentInterlocutor = self;
                if(response.impliesGreeting)
                {
                    if(handleTopic(&miscTopics, [impHelloTopicObj]))
                      "<.p>";
                }
            }
            response.handleTopic();     
            
            if(response.isConversational)
                noteConversed(); 
        }
        else
        {
            /* 
             *   If we were speculatively trying an initiateTopic that doesn't
             *   actually find anything, don't count this as a conversational
             *   turn from the point of view of updating pending and active
             *   keys. The same applies if we were speculatively trying to find
             *   an ImpHelloTopic.
             */
            if(prop == &initiateTopics || topic == [impHelloTopicObj])
                return nil;
            else
                say(self.(defaultProp));    
           
        }
        
                 
        
       
        
//        
//        /* If the active keys are about to change, schedule a topic inventory */
//        if(pendingKeys != activeKeys && pendingKeys.length > 0)
//            conversationManager.pendingTopicInventory = true;
//        
        /* 
         *   Reset the pending keys to nil unless we've been requested to retain
         *   them
         */
        if(!keepPendingKeys)
            pendingKeys = [];
        
        activeKeys = pendingKeys;
        
        keepPendingKeys = nil;
        
                
        return response != nil;
    }
    
    /* Convenience method to note that conversation has occurred on this turn */
    
    noteConversed()
    {
        gPlayerChar.currentInterlocutor = self;
        lastConvTime = libGlobal.totalTurns;
    }
    
    lastConvTime = -1
    
    conversedThisTurn = (lastConvTime == libGlobal.totalTurns)

    conversedLastTurn = (lastConvTime == libGlobal.totalTurns - 1)
    
    
    /* 
     *   If this list is not empty then the choice of topic entries to match
     *   will be restricted to those whose convKeys property includes at least
     *   one key in this list.
     */
    activeKeys = []
    
    /* 
     *   a list of the keys to be copied into the activeKeys property for use in
     *   the next conversational turn. These are normally added by game code via
     *   <.convnode> tags in conversational output.
     */
    pendingKeys = []
    
    /* 
     *   If keepPendingKeys is set to true (normally by a <.convstay> tag) then
     *   retain the pending conversation keys (and hence the active ones) for
     *   the next conversational turn.
     */
    
    keepPendingKeys = nil
    
    /* 
     *   Add a convkey value to our pending keys list (for use as an active key
     *   on the next conversational turn.
     */
    
    addPendingKey(val)
    {
        pendingKeys += val;
    }
    
    beforeAction()
    {
        actorBeforeAction();
        if(curState != nil)
            curState.beforeAction();
    }
    
    /* 
     *   Give this actor a chance to respond just before an action prior to any
     *   response from its current actor state.
     */
    
    actorBeforeAction()
    {
    }
    
    afterAction()
    {
        actorAfterAction();
        if(curState != nil)
            curState.afterAction();
           
    }
    
    actorAfterAction() { }
    
     /* 
      *   before and after travel connections. By default we defer to out actor
      *   state, if we have one, but we also give the actor object a chance to
      *   respond.
      */
    
    beforeTravel(traveler, connector) 
    {
        if(curState != nil)
            curState.beforeTravel(traveler, connector);
        
        actorBeforeTravel(traveler, connector);
        
        /* 
         *   If the player char is talking to me and I'm not following him, end
         *   the conversation.
         */
        
        if(gPlayerChar.currentInterlocutor == self && traveler == gPlayerChar
           && fDaemon == nil)
            endConversation(endConvLeave);
        
        if(traveler == gPlayerChar)
            pcConnector = connector;
    }
    
    /* The Travel Connector just traversed by the player character */
    
    pcConnector = nil
    
    
    actorBeforeTravel(traveler, connector) { }
       
    afterTravel(traveler, connector) 
    {
        if(curState != nil)
            curState.afterTravel(traveler, connector);
        
        actorAfterTravel(traveler, connector);
    }  
        
        
    actorAfterTravel(traveler, connector) {}
    
    endConversation(reason)
    {
        if(canEndConversation(reason))
            sayGoodbye(reason);
        
        /* 
         *   if the player char is about to depart and the actor won't let the
         *   conversation end, block the travel
         */
        else if(reason == endConvLeave)
            exit;
    }
    
    /* 
     *   Is the actor willing for this conversation to be ended? We first check
     *   the current actor state (if any) and then the actor object. If either
     *   raises an object it should display a message saying what the objection
     *   is (and then return nil). By default we simply return true, allowing
     *   the conversation to end.
     */
    
    canEndConversation(reason)
    {
        
        /* 
         *   first check whether there's a Conversation Node that wants to
         *   object to the conversation ending. We do that by first seeing if
         *   there's an active NodeEndCheck object...
         */
        local nodeCheck = findBestResponse(&initiateTopics, [nodeEndCheckObj]);
        
        /* 
         *... and if there is, seeing whether its canEndConversation() method
         *   objects.
         */
        
        if(nodeCheck != nil && !nodeCheck.canEndConversation(reason))
            return nil;
        
        /* 
         *   Then check with the current ActorState (if there is one) and our
         *   own actorCanEndConversation() method.
         */
        if(curState == nil || curState.canEndConversation(reason))
            return actorCanEndConversation(reason);
        
        
        /* 
         *   if we've reached this point it's because our current ActorState has
         *   objected to ending the conversation, so return nil to disallow it.
         */
        return nil;
    }
    
    actorCanEndConversation(reason) { return true; }
    
    
    /* 
     *   Mechanism to allow this actor to follow the player char. We do this
     *   rather simplistically by checking whether the player char is still in
     *   our location and moving us to the player char's location if s/he is not
     *   on the assumption that if the player char can get there in one turn, so
     *   can we. On arriving in the player char's new location we announce that
     *   we've just followed the player char and then run the arrivingTurn
     *   method on our current actor state (if we have one).
     */
    
    followDaemon()
    {
        local oldLoc = getOutermostRoom;
        if(getOutermostRoom != gPlayerChar.getOutermostRoom)
        {
            if(pcConnector != nil)
                pcConnector.travelVia(self);
            else
                gPlayerChar.getOutermostRoom.travelVia(self);
            
            sayFollowing(oldLoc);
            arrivingTurn();            
        }        
        
        /* 
         *   Set pcConnector to nil in any event so that a spurious value isn't
         *   left for a later turn.
         */
        pcConnector = nil;
    }
    
    /* 
     *   Instruct this actor to start following the player char round the world
     *   map
     */
    
    startFollowing()
    {
        fDaemon = new Daemon(self, &followDaemon, 1);
    }
    
    /* 
     *   Instruct this actor to stop following the player char round the world
     *   map.
     */
    
    stopFollowing()
    {
        if(fDaemon != nil)
            fDaemon.removeEvent();
        
        pcConnector = nil;
    }
    
    /* 
     *   Store the id of the daemon being used to make us follow the player
     *   char. We can check whether this actor is currently following or not by
     *   testing whether or not this is nil.
     */
    
    fDaemon = nil
    
    sayFollowing(oldLoc)
    {
        if(curState == nil)
            sayActorFollowing(oldLoc);
        else
            curState.sayFollowing(oldLoc);
    }
    
    
    sayActorFollowing(oldLoc)
    {
        local follower = self;
        gMessageParams(follower);
        DMsg(follow, '<.p>{The follower} {follows} behind {me}. ');
    }

    arrivingTurn()
    {
        if(curState != nil)
            curState.arrivingTurn();
        else
            actorArrivingTurn();
    }
    
    actorArrivingTurn() { }
        
       
    takeTurn()
    {
        /* 
         *   if we have active keys we may be in a notional conv node. If we
         *   haven't conversed this turn we may want to nudge the player's
         *   memory, which we do by trying an initiate topic
         */
        
        /* 
         *   But first, if we're the current interlocutor, check that we can
         *   still talk to the player character. If not, make us no longer the
         *   current interlocutor so we don't respond to conversational commands
         *   when we're no longer there.
         */
        
        if(gPlayerChar.currentInterlocutor == self && 
           !canTalkTo(gPlayerChar))
        {
            gPlayerChar.currentInterlocutor = nil;
            activeKeys = [];
            pendingKeys = [];
            return;
        }
        
        if(!conversedThisTurn && activeKeys.length > 0 &&
           initiateTopic(nodeObj))
                        return;
        
        
        if(!conversedThisTurn && !executeAgenda)
        {
            if(curState != nil && curState.ofKind(Script) 
               && Q.canSee(gPlayerChar, self))
                curState.doScript();
        }
        
        if(!conversedThisTurn && gActor.currentInterlocutor == self)
        {
            boredomCount++;
            
        }
        else
            boredomCount = 0;
           
    }
    
    
    
    /* 
     *   our special "boredom" agenda item - this makes us initiate an end
     *   to an active conversation when the PC has ignored us for a given
     *   number of consecutive turns 
     */
    boredomAgendaItem = perInstance(new BoredomAgendaItem(self))

    
    /* 
     *   If this is non-nil then a TOPICS command will use it to restrict the
     *   topics suggested to those with this key in their convKeys property.
     *   This could be used, for example, to provide a top-level 'menu' of
     *   topics when the full list would otherwise be overwhelming.
     */
    suggestionKey = nil

    showSuggestions(explicit = true, tag = nil)
    {
        local lst = listableTopics;
        
        if(curState != nil)
            lst += curState.listableTopics;
        
        
        /* 
         *   If the tag parameter is supplied, use it to provide a sublist of
         *   only those topics with a convKeys property matching the tag. A tag
         *   of 'all' is treated as a special value to allow a <.suggest all>
         *   tag to list all available special topics.
         */
        if(tag not in (nil, 'all'))
            lst = lst.intersect(valToList(convKeyTab[tag]));
        
        suggestedTopicLister.show(lst, explicit);            
        
    }
    
        
     /* A Lookup Table holding conversation keys. */
    
    convKeyTab = nil
    
    /* 
     *   set the curiosityAroused flag to true for all topic entries with this
     *   convKey
     */
    arouse(key)
    {
        if(convKeyTab != nil)
            foreach(local cur in valToList(convKeyTab[key]))
        {
            cur.curiosityAroused = true;
        }
    }
    
    /* 
     *   set the activated flag to true for all topic entries with this
     *   convKey
     */    
    makeActivated(key)    
    {
        if(convKeyTab != nil)
            foreach(local cur in valToList(convKeyTab[key]))
        {
            cur.activated = true;
        }
    }
    
    
    
    
    getActor { return self; }
    
    boredomCount = 0
    
    attentionSpan = nil
    
    /* Our look up table for things we've been informed about */
    
    informedNameTab = static new LookupTable(32, 32)
    
    /* Note that we've been informed of something */
    
    setInformed(tag)
    {
        informedNameTab[tag] = true;
    }
    
    informedAbout(tag) { return informedNameTab[tag] != nil; }
    
    /* Say hello to the actor (initiated by the player character) */
    sayHello()
    {
        
        if(gPlayerChar.currentInterlocutor != self)
        {
            gPlayerChar.currentInterlocutor = self;
            handleTopic(&miscTopics, [helloTopicObj], &noResponseMsg);
        }
        "<.p>";
        showSuggestions(nil, suggestionKey);
    }
    
    /* Have the actor greet the player character */
    actorSayHello()
    {
        if(gPlayerChar.currentInterlocutor != self)
        {
            noteConversed();
            return handleTopic(&miscTopics, [actorHelloTopicObj], &nilResponse);
        }       
        
        return nil;
    }
    
    /* Say goodbye to this actor (farewell from the player character) */
    sayGoodbye(reason = endConvBye)
    {
        if(gPlayerChar.currentInterlocutor != self && reason == endConvBye)
        {
            DMsg(not interlocutor, '{I}{\'m} not talking to {1}. ', theName);
        }
        else
        {
            handleTopic(&miscTopics, [reason], 
                        reason == endConvBye ? &noResponseMsg : &nilResponse);
            gPlayerChar.currentInterlocutor = nil;
        }
    }
    
    /* Do nothing if we can't fine a suitable Hello or Bye Topic/ */
    
    nilResponse() { }
    
    allStates = []
    
    /* 
     *   Is this actor ready to invoke a ConvAgendaItem? We're ready if we
     *   haven't conversed this term and we can speak to the other actor and
     *   we're not at a conversation node. This method is used by the isReady
     *   property of ConvAgendaItem.
     */
    
    convAgendaReady(other)
    {
        return !conversedThisTurn && canTalkTo(other) && activeKeys.length == 0;
    }
    
    
    /* Convenience methods for adding agenda items */
    
    /* 
     *   Add an agenda item to both myself and any DefaultAgendaTopic directly
     *   within me.
     */
    
    addToBothAgendas([lst])
    {
        addToAgenda(lst...);
        if(defaultAgendaTopic != nil)
            defaultAgendaTopic.addToAgenda(lst...);
    }
    
    /* 
     *   Add an agenda item both to myself and to any DefaultAgendaTopics either
     *   directly in me or in any of my Actor States
     */
    
    addToAllAgendas([lst])
    {
        addToBothAgendas(lst...);
        foreach(local state in allStates)
        {
            if(state.defaultAgendaTopic != nil)
                state.defaultAgendaTopic.addToAgenda(lst...);
        }      
    }
    
    /* 
     *   Add an agenda item to myself and to any DefaultAgendaTopios directly in
     *   me or in my current ActorState.
     */
    
    addToCurAgendas([lst])
    {
        addToBothAgendas(lst...);
        if(curState != nil && curState.defaultAgendaTopic != nil)
            curState.defaultAgendaTopic.addToAgenda(lst...);
    }
    
    removeFromBothAgendas([lst])
    {
        removeFromAgenda(lst...);
        if(defaultAgendaTopic != nil)
            defaultAgendaTopic.removeFromAgenda(lst...);
    }
    
    removeFromAllAgendas([lst])
    {
        removeFromBothAgendas(lst...);
        foreach(local state in allStates)
        {
            if(state.defaultAgendaTopic != nil)
                state.defaultAgendaTopic.removeFromAgenda(lst...);
        }      
    }
    
    removeFromCurAgendas([lst])
    {
        removeFromBothAgendas(lst...);
        if(curState != nil && curState.defaultAgendaTopic != nil)
            curState.defaultAgendaTopic.removeFromAgenda(lst...);
    }
    
    /* a list of agenda items to be added to our agenda at some later point. */
    
    pendingAgendaList = []
    
    /* Add an item to our pending agenda list */
    
    addToPendingAgenda([lst])
    {
        foreach(local item in lst)
            pendingAgendaList += item;
    }
    
    activatePendingAgenda()
    {
        foreach(local cur in pendingAgendaList)
            addToAllAgendas(cur);
        
        pendingAgendaList = [];
    }
    
    removeFromPendingAgenda([lst])
    {
        foreach(local item in lst)
            pendingAgendaList -= item;
    }
    
    
  
    /* 
     *   Try our current actor state first, if we have one, and only if it fails
     *   to find a response try handling the initiateTopic on the actor.
     */
    
    initiateTopic(top)
    {
        if(curState != nil && curState.initiateTopic(top))
            return true;
        
        return inherited(top);
    }
    
   
    notifyRemove(obj)
    {
        if(gActor != self && !allowOtherActorToTake(obj))
        {            
            say(cannotTakeFromActorMsg(obj));
            exit;
        }
    
    }
    
    cannotTakeFromActorMsg(obj)
    {
        local this = self;
        gMessageParams(obj, this);
        return BMsg(cannot take from actor, '{The subj this} {won\'t} let {me}
            have {the obj} while {he obj}{\'s} in {her this} possession. ');
    }
    
    allowOtherActorToTake(obj) { return nil; }
    
    /* An actor generally owns its contents */
    ownsContents = true
    
    /* 
     *   This definition is needed for the TopicGroup implementation, and should
     *   not normally be overridden in user game code.
     */
    active = true
    
    /*
     *   ***********************************************************************
     *   ACTION HANDLING
     *****************************************************************/
         
    dobjFor(TalkTo)
    {
        verify() {}
        
        action()
        {
            sayHello();
        }
    }
    
    dobjFor(AskAbout)
    {
        verify() {}
        action()
        {
            handleTopic(&askTopics, gIobj.topicList);
        }
    }
    
    dobjFor(AskFor)
    {
        verify() {}
        action()
        {
            handleTopic(&askForTopics, gIobj.topicList);
        }
    }
    
    dobjFor(TellAbout)
    {
        verify() {}
        action()
        {
            handleTopic(&tellTopics, gIobj.topicList);
        }
    }
    
    dobjFor(TalkAbout)
    {
        verify() {}
        action()
        {
            handleTopic(&talkTopics, gIobj.topicList);
        }
    }
    
       
    
    dobjFor(SayTo)
    {
        verify() {}
        action()
        {
            handleTopic(&sayTopics, gIobj.topicList);
        }
    }
    
    dobjFor(QueryAbout)
    {
        verify() {}
        action()
        {
            handleTopic(&queryTopics, gIobj.topicList);
        }
    }
    
    /* 
     *   By default we'll respond to KISS ACTOR with the shouldNotKissMsg; to
     *   enable responses to KISS via KissTopics (or some other custom handling
     *   in the action stage) set allowKiss to true.
     */
       
    allowKiss = nil
    
    /* The message to display if allowKiss is nil */
    shouldNotKissMsg = BMsg(should not kiss, 'That hardly {dummy} {seems}
        appropriate. ')
    
    dobjFor(Kiss)
    {
        verify() {}
            
        check()
        {
            if(!allowKiss)
                say(shouldNotKissMsg);
        }
        
        action()
        {
            handleTopic(&miscTopics, [kissTopicObj], &kissResponseMsg);
        }
    
    }
    
     /* 
     *   By default we'll respond to ATTACK ACTOR with the shouldNotAttackMsg; to
     *   enable responses to ATTACK via HitTopics (or some other custom handling
     *   in the action stage) set allowAttack to true.
     */
       
    allowAttack = nil
    
    /* The message to display if allowKiss is nil */
    shouldNotAttackMsg = BMsg(should not attack, 'That hardly {dummy} {seems}
        appropriate. ')
    
   
    isAttackable = true
    
    dobjFor(Attack)
    {       
        
        check()  
        {
            if(!allowAttack)
                say(shouldNotAttackMsg);
        }
        
        action()
        {
            handleTopic(&miscTopics, [hitTopicObj], &shouldNotAttackMsg);
        }
    
    }
    
    iobjFor(GiveTo)
    {
        verify() {}
        action()
        {
            handleTopic(&giveTopics, [gDobj]);
        }
    }
    
    iobjFor(ShowTo)
    {
        verify() {}
        action()
        {
            handleTopic(&showTopics, [gDobj]);
        }
    }
    
    
    /* 
     *   Unlike inaminate objects, actors can be the logical target of a ThrowTo
     *   action
     */
    
    canThrowToMe = true
    
    /* 
     *   We'll assume that actors can catch anything thrown at them by default,
     *   but game code may wish to override this assumption.
     */
    canCatchThrown(obj) { return true; }
    
    iobjFor(ThrowTo)
    {
        action()
        {
            if(canCatchThrown(gDobj))
            {
                gDobj.moveInto(self);
                DMsg(catch okay, '{The subj iobj} {catches} {the dobj}. ');
            }
            else
            {
                gDobj.moveInto(location);
                DMsg(drop catch, '{The subj iobj} {fails} to catch {the dobj},
                    so that {he dobj} {lands} on the ground instead. ');
            }
        }       
    }
;

class ActorState: ActorTopicDatabase
    stateDesc = nil
    specialDesc = nil
    isInitState = nil
    remoteSpecialDesc(pov) { specialDesc; }
    
    initializeActorState()
    {
        if(isInitState && location != nil)
            location.curState = self;
        
        getActor = location.getActor;
        
        addToActor();
               
    }
    
    afterAction() {}
    beforeAction() {}
    
    sayFollowing(oldLoc)
    {
        local follower = location;
        gMessageParams(follower);
        DMsg(follow, '{The follower} {follows} behind {me}. ');
    }
    
    getActor = nil
    
    attentionSpan = nil
    
    /* 
     *   the arrivingTurn method is executed when an actor in this state has
     *   just followed the player char to a new location.
     */
    
    arrivingTurn() { }
    
    addToActor()
    {
        if(getActor.allStates == nil)
            getActor.allStates = [];
        
        getActor.allStates += self;
    }
    
      /*
     *   Activate the state - this is called when we're about to become
     *   the active state for an actor.  We do nothing by default.
     */
    activateState(actor, oldState) { }

    /* 
     *   Deactivate the state - this is called when we're the active state
     *   for an actor, and the actor is about to switch to a new state.
     *   We do nothing by default.  
     */
    deactivateState(actor, newState) { }
    
    /* before and after travel notifications. By default we do nothing */
    
    beforeTravel(traveler, connector) {}
    afterTravel(traveler, connector) {}
    
    canEndConversation(reason) { return true; }
    
    active = (location.active)
   
;

class ActorTopicDatabase: TopicDatabase
       
    askTopics = []
    tellTopics = []
    sayTopics = []
    queryTopics = []
    giveTopics = []
    showTopics = []
    askForTopics = []
    talkTopics = []
    initiateTopics = []
    miscTopics = []
    commandTopics = []
    
    
    listableTopics()
    {
        local lst = miscTopics + askTopics + tellTopics + sayTopics +
            queryTopics + giveTopics + askForTopics + talkTopics;
        
        local actor = getActor;
        
        lst = lst.getUnique();
        
        lst = lst.subset({x: x.name!= nil && x.active && !x.curiositySatisfied 
                        && x.curiosityAroused && x.isReachable});
        
        if(actor.activeKeys.length > 0)
            lst = lst.subset({x: actor.activeKeys.overlapsWith(x.convKeys)});
        
        return lst;
    }
    
    defaultAgendaTopic = static 
                       askTopics.valWhich({x: x.ofKind(DefaultAgendaTopic)})
    
    initiateTopic(top)
    {
       return handleTopic(&initiateTopics, [top], &nilResponse);
    }
;


/* 
 *   A TopicGroup is an object that can be used to group ActorTopicEntries that
 *   share common features such as convKeys or isActive conditions. A TopicGroup
 *   can be used anywhere an ActorTopicEntry can be used, and any
 *   ActorTopicEntries should behave just as they would if they were in the
 *   TopicGroup's container, apart from the modifications imposed by the
 *   TopicGroup.
 */

class TopicGroup: object
    
    addTopic(obj)
    {
        location.addTopic(obj);
        
        /* 
         *   For each TopicEntry located in this TopicGroup, add any convKeys
         *   defined on the TopicGroup to those defined on the individual
         *   TopicEntries
         */
        
        obj.convKeys =
            valToList(obj.convKeys).appendUnique(valToList(convKeys));
        
        
        /* 
         *   If the TopicEntry's scoreBoost property is an integer, add our
         *   scoreBoost to it (obviously we can't do this if it's defined as a
         *   method, for example
         */
        if(obj.propType(&scoreBoost) == TypeInt)
            obj.scoreBoost += scoreBoost;
        
    }
    
    isActive = true
    
    active = (isActive && location.active)
    
    convKeys = nil
        
    scoreBoost = 0
    
    nodeActive()
    {
        return valToList(convKeys).overlapsWith(getActor.activeKeys);
    }
    
    getActor = (location.getActor)
    
    
;

/* 
 *   A ConvNode is a TopicGroup specialized for use as a ConversationNode; it's
 *   active when its nodeActive property is true.
 */

class ConvNode: TopicGroup
    isActive = nodeActive
;


class ActorTopicEntry: TopicEntry
    /* 
     *   To make this a suggested topic, just give it a name under which it will
     *   be suggested (of the kind that could follow 'You could ask about ' or
     *   'You could tell him about ' or 'You could show him ' etc.). Note that
     *   for QueryTopics and SayTopics that are specified with a matchObj the
     *   library constructs this name automatically.
     */
         
    name = nil
    
    /* 
     *   Set autoName to true to have this topic entry generate a name from its
     *   first matchObj's theName
     */
    
    autoName = nil
    
    isConversational = true
    
    impliesGreeting = true
    
    /* 
     *   A string or list of strings defining one or more groups to which this
     *   topic entry belongs
     */
    convKeys = nil
    
    /* 
     *   Test whether any of this Topic Entry's convKeys match those in the
     *   Actor's activeKeys list (whether or not the latter has any entries).
     *   This can be used in the isActive property to make this topic entry
     *   *only* available when its convKeys are active.
     */
    
    nodeActive()
    {
        return valToList(convKeys).overlapsWith(getActor.activeKeys);
    }
    
    addToConvKeyTable()   
    {
        local actor = getActor;
        
        if(actor.convKeyTab == nil)
            actor.convKeyTab = new LookupTable;
        
        foreach(local k in valToList(convKeys))
        {
            local val = actor.convKeyTab[k];
            actor.convKeyTab[k] = valToList(val) + self;
        }
    }
    
    initializeTopicEntry()
    {
        inherited;
        
        addToConvKeyTable();
        
        if(autoName && matchObj != nil && name is in (nil, ''))
            buildName();
    }
    
    buildName() { name = valToList(matchObj)[1].theName; }
    
    getActor = (location.getActor)
    
    /* 
     *   The number of times to suggest this topic entry, if we do suggest it.
     *   By default this is either once (if we're not also an EventList) or the
     *   number of items in our eventList (if we are an EventList). If you want
     *   this topic entry to go on being suggested ad infinitum, set
     *   timesToSuggest to nil.
     */
    
    timesToSuggest = static (ofKind(EventList) ? eventList.length : 1)
    
    /* 
     *   Assuming this topic entry is ever suggested, it will continue to be
     *   suggested until curiositySatisfied becomes true. By default this occurs
     *   when the topic has been invoked timesToSuggest times.
     */
    curiositySatisfied = ( timesToSuggest != nil && timesInvoked >=
                          timesToSuggest)
    
    /* The number of times this topic entry has been invoked. */
    timesInvoked = 0
    
    
    /* 
     *   We won't suggest this topic entry (if we ever suggest it at all) until
     *   its curiosityAroused property by true. By default it normally is from
     *   the start, but this can be overridden in individual cases if desired.
     */
    curiosityAroused = true
    
    /* 
     *   The suggestAs property can be overridden to change the list this topic
     *   entry will be suggested as if you don't want it placed in the list the
     *   library chooses by default. The allowed values are one of AskTopic,
     *   TellTopic, GiveTopic, ShowTopic, or TalkTopic. Normally, though, the
     *   library default will work perfectly well and you don't need to specify
     *   this property. If you do it must be specified as a kind that this topic
     *   entry can actually match, e.g. TellTopic for an AskTellTopic or
     *   ShowTopic for a GiveShowTopic.
     */
    
    suggestAs = nil
    
    
    handleTopic()
    {
        timesInvoked++ ;
        
        if(valToList(keyTopics).length > 0)
        {
            showKeyTopics();
            
            /* 
             *   Throw an abort signal so that showing a list of topics doesn't
             *   count as a player turn.
             */
            abort;
        }
        else
            topicResponse();
    }
        
    
    showKeyTopics()
    {
        local actor = getActor();

        local lst = [];
        
        
        foreach(local ky in valToList(keyTopics))
            lst += actor.convKeyTab[ky];
        
        lst = lst.subset({t: t.active && !t.curiositySatisfied &&
                         t.curiosityAroused && t.isReachable });
            
        lst = nilToList(lst).getUnique();    
        
        suggestedTopicLister.show(lst);       
            
    }
    
    keyTopics = nil
    
    
    /* 
     *   A flag that can be set with an <.activate> tag and tested with
     *   isActive. Unless it is explicitly tested by isActive is has no effect.
     */
    activated = nil
    
    
    /* 
     *   This TopicEntry is active if its own isActive property is true and if
     *   its location is active. This allows the isActive conditions of
     *   individual TopicEntries to be combined with that of any TopicGroups
     *   they're in. This property should not normally be overridden in game
     *   code.
     */
    active = (isActive && location.active)
    
    
    isReachable()
    {
        local actor = getActor;
        
        /* 
         *   if the actor has a current ActorState and we're in a different
         *   ActorState then we're reachable only if we're in the current
         *   ActorState
         */
        
        if(actor.curState != nil && location.ofKind(ActorState) 
           && location != actor.curState)
            return nil;
        
                    
        /* 
         *   if we don't have a matchObj assume we're reachable (this will need
         *   refining.
         */
        
        if(matchObj == nil)
        {
            /* 
             *   if the actor doesn't have a current actor state or we're in the
             *   current actor state, assume we're reachable
             */
            
            if(actor.curState == nil || location == actor.curState)            
               return true;
            
            /* 
             *   otherwise, we're reachable if the current actor state doesn't
             *   have a DefaulTopic that might block us.
             */
            
            foreach(local prop in includeInList)
            {
                if(actor.curState.(prop).indexWhich({ t: t.ofKind(DefaultTopic)
                    }) != nil)
                    return nil;
            }
            
            return true;
            
        }
        
        /* 
         *   We're not reachable if the player char doesn't know about our
         *   matchObj
         */
        
        if(valToList(matchObj).indexWhich({ x: x.isClass() 
                                          || gPlayerChar.knowsAbout(x)}) == nil) 
        
            return nil;
        
        /* 
         *   Otherwise we're reachable if we're the best match for our matchObj
         *   according to our suggestion type
         */
        
        /* 
         *   If the author has indicated a suggestAs property, use it to
         *   determine which list property we should test for, otherwise use the
         *   first one in our own list, which should correspond to the topic
         *   suggestion lister's default behaviour. By this means we simulate
         *   the command the sugggestion lister will suggest; e.g. if it would
         *   suggest ASK ABOUT FOO we test whether this topic entry is reachable
         *   via an ASL ABOUT command, so we want to test whether its the best
         *   response for its matchObj from the askTopic list.
         */
        
        local prop = (suggestAs != nil ? suggestAs.includeInList[1] :
                      includeInList[1]);
        
        if(prop == &queryTopics)
            gAction.qType = qtype.split('|')[1];
        
        if(actor.findBestResponse(prop, matchObj) == self)
            return true;
        
        
        return nil;           
            
    }
;

class CommandTopicHelper: LCommandTopicHelper
    handleTopic()
    {
        inherited;
        
        if(allowAction)
            myAction.exec(gCommand);
    }
    
    /* 
     *   Set this to true to allow the action to proceed as commanded by the
     *   player.
     */
    allowAction = nil
        
    
    myAction = (gCommand.action)
;

class CommandTopic: CommandTopicHelper, ActorTopicEntry    
    matchTopic(top)
    {
               
        myAction = top;
        
        /* 
         *   If we've specified that this CommandTopic must match specific
         *   objects and the action we've been passed doesn't match them, return
         *   nil.
         */
        if(matchDobj != nil && (top.curDobj == nil ||
           valToList(matchDobj).indexWhich ({x: top.curDobj.ofKind(x)}) == nil))
            return nil;
        
        if(matchIobj != nil && (top.curIobj == nil ||
           valToList(matchIobj).indexWhich ({x: top.curIobj.ofKind(x)}) == nil))
            return nil;
     
        /* return the inherited handling */
        return inherited(top);
        
        
    }
    
    
    /* 
     *   The direct and indirect objects I must match (individually or as one of
     *   a list) if this CommandTopic is to be matched.
     */
    matchDobj = nil
    matchIobj = nil
    
    /* the action I've just matched. */
    myAction = nil
    
    
    
    includeInList = [&commandTopics]
    
    
;

class MiscTopic: ActorTopicEntry
 
    
    matchTopic(obj)
    {
        /* 
         *   if it's one of our matching topics, return our match score,
         *   otherwise return a nil score to indicate failure 
         */
        return (valToList(matchObj).indexOf(obj) != nil) ? matchScore +
            scoreBoost: nil;
    }
;

class KissTopic: MiscTopic
    includeInList = [&miscTopics]
    matchObj = kissTopicObj
    isConversational = nil
    impliesGreeting = nil
;

kissTopicObj: object;

class HitTopic: MiscTopic
    includeInList = [&miscTopics]
    matchObj = hitTopicObj
    isConversational = nil
    impliesGreeting = nil
;

hitTopicObj: object;

class YesTopic: MiscTopic
    includeInList = [&miscTopics]
    matchObj = yesTopicObj
    name = BMsg(say yes, 'say yes')
;

class NoTopic: MiscTopic
    includeInList = [&miscTopics]
    matchObj = noTopicObj
    name = BMsg(say no, 'say no')
;

class YesNoTopic: MiscTopic
    includeInList = [&miscTopics]
    matchObj = [yesTopicObj, noTopicObj]
    name = BMsg(say yes or no, 'say yes or no')
;

class GreetingTopic: MiscTopic
    includeInList = [&miscTopics]
    impliesGreeting = nil
    
    /* 
     *   It may be that we want to change to a different actor state when we
     *   begin or end a conversation. If so the changeToState property can be
     *   used to specify which state to change to.
     */
    changeToState = nil
    
    handleTopic()
    {
        local result = inherited();
        if(changeToState != nil)
            getActor.setState(changeToState);
        
        
        return result;
    }
;

class HelloTopic: GreetingTopic    
    matchObj = [helloTopicObj, impHelloTopicObj]    
    handleTopic()
    {
        getActor.activatePendingAgenda();
        return inherited;
    }
;

class ImpHelloTopic: HelloTopic
    matchObj = [impHelloTopicObj]
    matchScore = 150
;

/*
 *   Actor Hello topic - this handles greetings when an NPC initiates the
 *   conversation. 
 */
class ActorHelloTopic: HelloTopic    
    matchObj = [actorHelloTopicObj]
    matchScore = 200


    /* 
     *   if we use this as a greeting upon entering a ConvNode, we'll want
     *   to stay in the node afterward
     */
    noteInvocation(fromActor)
    {
        inherited(fromActor);
        "<.convstay>";
    }
;

/*
 *   A goodbye topic - this handles both explicit GOODBYE commands and
 *   implied goodbyes.  Implied goodbyes happen when a conversation ends
 *   without an explicit GOODBYE command, such as when the player character
 *   walks away from the NPC, or the NPC gets bored and wanders off, or the
 *   NPC terminates the conversation of its own volition.  
 */
class ByeTopic: GreetingTopic    
    matchObj = [endConvBye,
                 endConvLeave, endConvBoredom, endConvActor]

    
;

/* 
 *   An implied goodbye topic.  This handles ONLY automatic (implied)
 *   conversation endings, which happen when we walk away from an actor
 *   we're talking to, or the other actor ends the conversation after being
 *   ignored for too long, or the other actor ends the conversation of its
 *   own volition via npc.endConversation().
 *   
 *   We use a higher-than-default matchScore so that any time we have both
 *   a ByeTopic and an ImpByeTopic that are both active, we'll choose the
 *   more specific ImpByeTopic.  
 */
class ImpByeTopic: GreetingTopic    
    matchObj = [endConvLeave, endConvBoredom, endConvActor]
    matchScore = 200
;

/*
 *   A "bored" goodbye topic.  This handles ONLY goodbyes that happen when
 *   the actor we're talking terminates the conversation out of boredom
 *   (i.e., after a period of inactivity in the conversation).
 *   
 *   Note that this is a subset of ImpByeTopic - ImpByeTopic handles
 *   "bored" and "leaving" goodbyes, while this one handles only the
 *   "bored" goodbyes.  You can use this kind of topic if you want to
 *   differentiate the responses to "bored" and "leaving" conversation
 *   endings.  
 */
class BoredByeTopic: GreetingTopic    
    matchObj = [endConvBoredom]
    matchScore = 300
;

/*
 *   A "leaving" goodbye topic.  This handles ONLY goodbyes that happen
 *   when the PC walks away from the actor they're talking to.
 *   
 *   Note that this is a subset of ImpByeTopic - ImpByeTopic handles
 *   "bored" and "leaving" goodbyes, while this one handles only the
 *   "leaving" goodbyes.  You can use this kind of topic if you want to
 *   differentiate the responses to "bored" and "leaving" conversation
 *   endings.  
 */
class LeaveByeTopic: GreetingTopic    
    matchObj = [endConvLeave]
    matchScore = 300
;

/*
 *   An "actor" goodbye topic.  This handles ONLY goodbyes that happen when
 *   the NPC terminates the conversation of its own volition via
 *   npc.endConversation(). 
 */
class ActorByeTopic: GreetingTopic    
    matchObj = [endConvActor]
    matchScore = 300
;

/* a topic for both HELLO and GOODBYE */
class HelloGoodbyeTopic: GreetingTopic    
    matchObj = [helloTopicObj, impHelloTopicObj,
                 endConvBye, endConvBoredom, endConvLeave,
                 endConvActor]
    
;

/* 
 *   Topic singletons representing HELLO and GOODBYE topics.  These are
 *   used as the parameter to matchTopic() when we're looking for the
 *   response to the corresponding verbs. 
 */
helloTopicObj: object;
endConvBye: object;

/* 
 *   a topic singleton for implied greetings (the kind of greeting that
 *   happens when we jump right into a conversation with a command like
 *   ASK ABOUT or TELL ABOUT, rather than explicitly saying HELLO first) 
 */
impHelloTopicObj: object;

/*
 *   a topic singleton for an NPC-initiated hello (this is the kind of
 *   greeting that happens when the NPC is the one who initiates the
 *   conversation, via actor.initiateConversation()) 
 */
actorHelloTopicObj: object;


/* 
 *   topic singletons for the two kinds of automatic goodbyes (the kind of
 *   conversation ending that happens when we simply walk away from an
 *   actor we're in conversation with, or when we ignore the other actor
 *   for enough turns that the actor gets bored and ends the conversation
 *   of its own volition) 
 */
endConvBoredom: object;
endConvLeave: object;

/*
 *   a topic singleton for an NPC-initiated goodbye (this is the kind of
 *   goodbye that happens when the NPC is the one who breaks off the
 *   conversation, via npc.endConversation()) 
 */
endConvActor: object;


class DefaultTopic: ActorTopicEntry
//    matchTopic(top)
//    {
//        
//        return matchScore + scoreBoost;
//    } 
    
    matchObj = [Thing, Topic, yesTopicObj, noTopicObj]
    matchScore = 1
;

class DefaultAnyTopic: DefaultTopic
//    matchTop(top)
//    {
//        /* We don't want a DefaultAnyTopic to respond to HIT or KISS */
//        if(top is in (hitTopicObj, kissTopicObj))
//            return nil;
//        
//        return inherited(top);
//    }
    
    includeInList = [&sayTopics, &queryTopics, &askTopics, &tellTopics,
        &giveTopics, &showTopics, &askForTopics, &talkTopics, &miscTopics]
;

/* 
 *   A DefaultAgendaTopic can be used to give the actor the opportunity to seize
 *   the conversational initiative when the player enters a conversational
 *   command for which there's no explicit match. Instead of giving a bland
 *   default response the actor can instead respond with an item from its own
 *   agenda, e.g. "Never mind that, what I really want to know is...".
 *
 *   Items can be added to the agenda of a DefaultAgendaTopic by calling its
 *   addToAgenda method. To obtain a reference to a DefaultAgendaTopic use the
 *   defaultAgendaTopic property of the Actor or ActorState in which it is
 *   located (note, therefore, that there should only be at most one of these
 *   per Actor or Actor State).
 *
 *   Note that you should define the topicResponse or eventList property of a
 *   DefaultAgendaTopic in case none of the agenda items in its agenda list turn
 *   out to be executable.
 */


class DefaultAgendaTopic: AgendaManager, DefaultAnyTopic
    
    handleTopic()
    {
        /* 
         *   Try to execute our next agenda item. If this fails fall back on our
         *   inherited handling.
         */
        
        if(!executeAgenda())
            inherited();
    }
    
    /* 
     *   This kind of Default Topic is active only when it has any agenda items
     *   to process.
     */
    isActive = (agendaList != nil && agendaList.length > 0)
    
    /* 
     *   When this DefaultTopic is active we want it to take priority over over
     *   DefaultTopics.
     */
    matchScore = 10
;

class DefaultConversationTopic: DefaultTopic
    includeInList = [&sayTopics, &queryTopics, &askTopics, &tellTopics,
        &askForTopics, &talkTopics]
    matchScore = 2
;

class DefaultAskTellTopic: DefaultTopic
    includeInList = [&askTopics, &tellTopics]
    matchScore = 4    
;

class DefaultGiveShowTopic: DefaultTopic
    includeInList = [&giveTopics, &showTopics]
    matchScore = 4
;

class DefaultAskTopic: DefaultTopic
    includeInList = [&askTopics]
    matchScore = 5
;

class DefaultTellTopic: DefaultTopic
    includeInList = [&tellTopics]
    matchScore = 5
;

class DefaultTalkTopic: DefaultTopic
    includeInList = [&talkTopics]
    matchScore = 5
;

class DefaultGiveTopic: DefaultTopic
    includeInList = [&giveTopics]
    matchScore = 5
;

class DefaultShowTopic: DefaultTopic
    includeInList = [&showTopics]
    matchScore = 5
;

class DefaultAskForTopic: DefaultTopic
    includeInList = [&askForTopics]
    matchScore = 5
;

class DefaultSayTopic: DefaultTopic
    includeInList = [&sayTopics]
    matchScore = 5
;

class DefaultQueryTopic: DefaultTopic
    includeInList = [&queryTopics]
    matchScore = 5
;

class DefaultSayQueryTopic: DefaultTopic
    includeInList = [&sayTopics, &queryTopics]
    matchScore = 4
;

class DefaultCommandTopic: CommandTopicHelper, DefaultTopic
    includeInList = [&commandTopics]
    matchScore = 5
    matchObj = [Action]
;

class AskTopic: ActorTopicEntry
    includeInList = [&askTopics]
;

class TellTopic: ActorTopicEntry
    includeInList = [&tellTopics]
;

class AskTellTopic: ActorTopicEntry
    includeInList = [&askTopics, &tellTopics]
;

class AskForTopic: ActorTopicEntry
    includeInList = [&askForTopics]
;

class AskAboutForTopic: ActorTopicEntry
    includeInList = [&askForTopics, &askTopics]
;

class GiveTopic: ActorTopicEntry
    includeInList = [&giveTopics]
;

class ShowTopic: ActorTopicEntry
    includeInList = [&showTopics]
;

class GiveShowTopic: ActorTopicEntry
    includeInList = [&giveTopics, &showTopics]
;

class SpecialTopic: ActorTopicEntry
    initializeTopicEntry()
    {
        inherited;
        
        
        /* 
         *   if the matchPattern contains a semi-colon assume it's not a regex
         *   match pattern but the vocab for a new Topic object.
         */
        
        
        if(matchPattern != nil && (matchPattern.find(';') != nil ||                             
                                   matchPattern.find(rex) == nil))            
        {
            /* create a new Topic object using the matchPattern as its vocab */
            matchObj = new Topic(matchPattern);
            
            /* then set the matchPattern to nil, since we shan't be using it. */
            matchPattern = nil;
            
            /* add the new matchObj to the universal scope list */
            World.universalScope += matchObj;
        }
        
        if(autoName)
           buildName();
        
        if(askMatchObj != nil && askMatchObj == tellMatchObj)
        {
            new SlaveTopic(askMatchObj, self, [&askTopics, &tellTopics]);            
        }
        else if(askMatchObj != nil)
            new SlaveTopic(askMatchObj, self, [&askTopics]);
        
        if(tellMatchObj != nil && tellMatchObj != askMatchObj)
            new SlaveTopic(tellMatchObj, self, [&tellTopics]);
    }
    
    rex = static new RexPattern('<langle|rangle|star|dollar|vbar|percent|carat>')
    
    askMatchObj = nil
    tellMatchObj = nil
    
    /* 
     *   For a SpeciallTopic make constructing a name property automatically the
     *   default.
     */
    autoName = true;
    
;

class SlaveTopic: ActorTopicEntry
    construct(matchObj_, masterObj_, includeInList_)
    {
        matchObj = matchObj_;
        masterObj = masterObj_;
        includeInList = includeInList_;
        location = masterObj.location;
        initializeTopicEntry();
    }
    
    initializeTopicEntry()
    {
        if(!initialized)
        {
            inherited();
            initialized = true;
        }
    }
    
    handleTopic() { masterObj.handleTopic(); }
    
    masterObj = nil
    initialized = nil
;

class QueryTopic: SpecialTopic
    matchTopic(top)
    {
        local qtList = qtype.split('|');
        
        if(qtList.indexOf(gAction.qType) == nil)
            return nil;
        
        return inherited(top);
    }
    
    /* 
     *   The list of query types we match, e.g. 'where'. To match multiple types
     *   list them divided by a vertical bar, e.g. 'if|whether'
     */
    qtype = nil    
    
    
    initializeTopicEntry()
    {
        /* 
         *   If qtype isn't specified but matchPattern is, take the first word
         *   of the matchPattern to be the qtype.
         */
        if(qtype == nil && matchPattern != nil)
        {
            local idx = matchPattern.find(' ');
            if(idx)
            {
                qtype = matchPattern.substr(1, idx - 1);
                matchPattern = matchPattern.substr(idx + 1).trim();
            }
            
        }
     
        inherited;    
    }
    
    buildName()
    {
        if(name == nil && matchObj != nil)
        {
            local qList = qtype.split('|');
            name = qList[1] + ' ' + valToList(matchObj)[1].name; 
        }
    }
    
   
    includeInList = [&queryTopics]
            
           
;

class SayTopic: SpecialTopic
    buildName()
    {
        if(name == nil && matchObj != nil)
            name = valToList(matchObj)[1].name; 
    }
    
    initializeTopicEntry()
    {
        inherited;
        buildName();
    }
    includeInList = [&sayTopics]
    
    /* 
     *   When a SayTopic is suggested we normally precede its name by 'say',
     *   e.g. 'say you are happy'. In some cases an author might want to use a
     *   SayTopic to match input that's better without the initial 'say', e.g.
     *   'tell a lie', in which case set includeSayInName to nil to suppress the
     *   initial 'say' in topic inventory listings.
     */
    
    includeSayInName = true
;

class TalkTopic: ActorTopicEntry
    includeInList = [&talkTopics]
;
    

class TellTalkTopic: TalkTopic
    includeInList = [&tellTopics, &talkTopics]
;
 
class AskTellTalkTopic: TalkTopic
    includeInList = [&askTopics, &tellTopics, &talkTopics]
;

class AskTalkTopic: TalkTopic
    includeInList = [&askTopics, &talkTopics]
;


/* An initiateTopic is used for conversational topics initiated by the actor */

class InitiateTopic: ActorTopicEntry
    includeInList = [&initiateTopics]
;

/* 
 *   A special kind of InitiateTopic that can be used to prompt the player/pc
 *   when particular convKeys have been activated.
 */

class NodeContinuationTopic: InitiateTopic
    matchObj = nodeObj
    
    /* 
     *   We're only active when one or more of our keys is active (having been
     *   activated through an <.convnode> tag).
     */
    isActive = nodeActive
    
    
    /* 
     *   Particular instances must override this property to stipulate which
     *   keys we're active for.
     */
    convKeys = nil
    
    handleTopic()
    {
        /* 
         *   We don't want a NodeContinuationTopic to reset the active keys, so
         *   we send a convstay tag to retain them.
         */
        "<.p><.convstay>";
        inherited();
    }
;

/* 
 *   A NodeEndCheck may optionally be assigned to a Conversation Node (as
 *   defined on the convKeys property) to decide whether a conversation is
 *   allowed to end while it's at this node. There's no need to define one of
 *   these objects for a conversation node if you're happy for the conversation
 *   to be ended during it under all circumstances.
 */

class NodeEndCheck: InitiateTopic
    matchObj = nodeEndCheckObj
    
    /* 
     *   We're only active when one or more of our keys is active (having been
     *   activated through an <.convnode> tag).
     */
    isActive = nodeActive
    
    
    /* 
     *   Particular instances must override this property to stipulate which
     *   keys we're active for.
     */
    convKeys = nil
    
    /*   
     *   Decide whether the conversation can be ended for reason while the
     *   conversation is at this node. By default we simply return true but
     *   instances should override to return nil when the conversation should
     *   not be permitted to end. When the method returns nil it should also
     *   display a message saying why the conversation may not be ended.
     */
    
    canEndConversation(reason)
    {
        return true;
    }
    
    /* 
     *   Do nothing here; this class only exists for the sake of its
     *   canEndConversation() method.
     */
    
    handleTopic() { }
    
    /* 
     *   Convenience method that notes that conversation has occurred on this
     *   turn and returns nil. This is to allow us to use:
     *.
     *   return blockEndConv;
     *
     *   in the canEndConversation method to suppress the output of any
     *   NodeContinuationTopic on this turn.
     */
    
    blockEndConv()
    {
        getActor.noteConversed();
        return nil;
    }
    
;

nodeObj: object;
nodeEndCheckObj: object;
yesTopicObj: object familiar = true;
noTopicObj: object familiar = true;

actorPreinit:PreinitObject
    execute()
    {       
        forEachInstance(ActorState, {a: a.initializeActorState() } );
        
        forEachInstance(ActorTopicEntry, {a: a.initializeTopicEntry() });
        
        local actorDaemon = new Daemon(self, &eachTurn, 1);
        actorDaemon.eventOrder = 300;
    }
    
    execBeforeMe = [World, libObjectInitializer, pronounPreinit]

    eachTurn()
    {
        forEachInstance(Actor, {a: a.takeTurn() });
    }
    
;




/* ------------------------------------------------------------------------ */
/*
 *   Conversation manager output filter.  We look for special tags in the
 *   output stream:
 *   
 *   <.reveal key> - add 'key' to the knowledge token lookup table.  The
 *   'key' is an arbitrary string, which we can look up in the table to
 *   determine if the key has even been revealed.  This can be used to make
 *   a response conditional on another response having been displayed,
 *   because the key will only be added to the table when the text
 *   containing the <.reveal key> sequence is displayed.
 *   
 *   <.activate name> - add 'name' to the current list of convKeys (this 
 *   actually adds it to the actor's pendingKeys for use on the next turn)'.  
 *   
 *   <.convstay> - retain the same list of active keys for the next 
 *   conversational response
 *   
 *   <.topics> - schedule a topic inventory for the end of the turn (just
 *   before the next command prompt) 
 */
conversationManager: OutputFilter, PreinitObject
    /*
     *   Custom extended tags.  Games and library extensions can add their
     *   own tag processing as needed, by using 'modify' to extend this
     *   object.  There are two things you have to do to add your own tags:
     *   
     *   First, add a 'customTags' property that defines a regular
     *   expression for your added tags.  This will be incorporated into
     *   the main pattern we use to look for tags.  Simply specify a
     *   string that lists your tags separated by "|" characters, like
     *   this:
     *   
     *   customTags = 'foo|bar'
     *   
     *   Second, define a doCustomTag() method to process the tags.  The
     *   filter routine will call your doCustomTag() method whenever it
     *   finds one of your custom tags in the output stream.  
     */
    customTags = nil
    doCustomTag(tag, arg) { /* do nothing by default */ }

    respondingActor = (gPlayerChar.currentInterlocutor)
    
    /* filter text written to the output stream */
    filterText(ostr, txt)
    {
        local start;
        
        /* scan for our special tags */
        for (start = 1 ; ; )
        {
            local match;
            local arg;
//            local actor;
//            local sp;
            local tag;
            local nxtOfs;
            local obj;
            
            /* scan for the next tag */
            match = rexSearch(tagPat, txt, start);

            /* if we didn't find it, we're done */
            if (match == nil)
                break;

            /* note the next offset */
            nxtOfs = match[1] + match[2];

            /* get the argument (the third group from the match) */
            arg = rexGroup(3);
            if (arg != nil)
                arg = arg[3];

            /* pick out the tag */
            tag = rexGroup(1)[3].toLower();

            /* check which tag we have */
            switch (tag)
            {
                /* 
                 *   We distiguish between information that is revealed *to* the
                 *   player char (by using a <.reveal> tag) and information
                 *   imparted by the player char to other characters (using the
                 *   <.inform> tag). Game authors do not have to observe this
                 *   distinction if they only want to use <.reveal> as in the
                 *   adv3 library, but it may be a useful distinction for some
                 *   games.
                 *
                 *   Note that there is one global table of revealed tags (on
                 *   libGlobal) use for revealed items, but that each actor
                 *   (apart from the player char) maintains its own table of
                 *   items imparted through inform tags.
                 *
                 *   Note also that a <.reveal> or <.inform> tag causes the tag
                 *   to be added to the informNameTag table of every actor who
                 *   can hear the conversation, not just the current
                 *   interlocutor.
                 *
                 *   If <.inform> tags are used as well as <.reveal> tags it's
                 *   therefore a good idea to regard the tags as a global
                 *   namespace -- i.e. one tag value should be used consistently
                 *   to represent one piece of information.
                 *
                 *   Finally, note that the gRevealed() macro only adds the tag
                 *   to the libGlobal table - it doesn't result in any other
                 *   actors being informed. It can therefore be used (among
                 *   other things) to reveal information that remains private to
                 *   the player char.
                 */
             
                
            case 'reveal':
                /* reveal the key by adding it to our database */
                setRevealed(arg);
                break;
                
            case 'inform':    
                /* reveal the key by adding it to the actor's database */
                setInformed(arg);
                break;

//            
            case 'convnode':
            case 'convnodet':    
                /* 
                 *   if there's a current responding actor, add the key to its
                 *   list of pending keys (for use on the next conversational
                 *   turn).
                 */
                
                if(respondingActor != nil)
                {
                    /* 
                     *   If we are processing several convnode tags on the same
                     *   turn, we want them all to take effect; otherwise we
                     *   want the new convnode to replace any that was
                     *   previously in effect.
                     */
                    if(convnodeSetTurn == libGlobal.totalTurns)
                        respondingActor.addPendingKey(arg);
                    else
                        respondingActor.pendingKeys = [arg];
                }
                
                /* Note that we have set a new convnode on this turn */
                convnodeSetTurn = libGlobal.totalTurns;
                
                /* 
                 *   We deliberatelty don't put a BREAK; statement here since we
                 *   need to fall through the convstay behaviour to ensure that
                 *   our keys aren't obliterated as soon as they're set.
                 */
                
            case 'convstay':
            case 'convstayt':    
                /* 
                 *   leave the responding actor in the old conversation
                 *   node - we don't need to change the ConvNode, but we do
                 *   need to note that we've explicitly set it 
                 */
                if (respondingActor != nil)
                    respondingActor.keepPendingKeys = true;
               
                /* 
                 *   if the tag was 'convnode' we didn't ask for a topic
                 *   inventory, so we need to avoid falling through. If the tag
                 *   was 'convnodet' or 'convstayt' we want a topic inventory
                 *   too, so we fall through to the 'topics' tag.
                 */
                
                if(tag not in ('convnodet', 'convstayt'))
                   break;

            case 'topics':
                /* schedule a topic inventory listing */
                if (respondingActor != nil)
                    scheduleTopicInventory(respondingActor.suggestionKey);
                break;
            case 'arouse':
                /* 
                 *   make the curiosityAroused property true for Topic Entries
                 *   with the appropriate key.
                 */
                if (respondingActor != nil)
                    respondingActor.arouse(arg);
                
                break;
            case 'suggest':
                 /* translate the string 'nil' to an actual nil */
                if(arg == 'nil')
                    arg = nil;
                
                if (respondingActor != nil)
                    scheduleTopicInventory(arg);
                break;
            case 'sugkey':
                /* translate the string 'nil' to an actual nil */
                if(arg == 'nil')
                    arg = nil;
                /* set the suggestionKey on the responding actor to arg */
                if (respondingActor != nil)
                    respondingActor.suggestionKey = arg;
                break;    
            case 'activate':
                /* 
                 *   Set the activated property to true for all Topic Entries
                 *   with the appropriate key.
                 */
                if (respondingActor != nil)
                    respondingActor.makeActivated(arg);
                break;
                
            case 'agenda':
                /* add an agenda item to all relevant objects */
                obj = objNameTab[arg];
                
                if(obj == nil || !obj.ofKind(AgendaItem) || 
                   obj.getActor != respondingActor)
                {
                    showAgendaError(tag, arg);
                }
                else
                    respondingActor.addToAllAgendas(obj);
                break;
                
            case 'remove':
                /* remove an agenda item from all relevant objects */
                
                obj = objNameTab[arg];
                
                if(obj == nil || !obj.ofKind(AgendaItem) || 
                   obj.getActor != respondingActor)
                {
                    showAgendaError(tag, arg);
                }
                else
                    respondingActor.removeFromAllAgendas(obj);
                break;
            case 'state':
                /* change ActorState */
                
                obj = objNameTab[arg];
                if(arg == 'nil')
                    obj = nil;                
                else if(obj == nil || !obj.ofKind(ActorState) || 
                   obj.getActor != respondingActor)
                {
                    showStateError(tag, arg);
                }
                else
                    respondingActor.setState(obj);
                break;
            
            case 'known':
                /* mark as item as known. */
                
                obj = objNameTab[arg];
                             
                if(obj == nil || !obj.ofKind(Mentionable))
                {
                    showKnownError(tag, arg);
                }
                else
                   gPlayerChar.setKnowsAbout(obj);
                break;
                
            default:
                /* check for an extended tag */
                doCustomTag(tag, arg);
                break;
            }

            /* continue the search after this match */
            start = nxtOfs;
        }

        /* 
         *   remove the tags from the text by replacing every occurrence
         *   with an empty string, and return the result 
         */
        return rexReplace(tagPat, txt, '', ReplaceAll);
    }

    
    /* The turn on which we last processed a convnode tag */
    convnodeSetTurn = 0
    
    /* regular expression pattern for our tags */
    tagPat = static new RexPattern(
        '<nocase><langle><dot>'
        + '(reveal|agenda|remove|state|known|activate|inform|convstay|topics'
        + (customTags != nil ? '|' + customTags : '')
        + '|arouse|suggest|sugkey|convnode|convnodet|convstayt)'
        + '(<space>+(<^rangle>+))?'
        + '<rangle>')

    /*
     *   Schedule a topic inventory request.  Game code can call this at
     *   any time to request that the player character's topic inventory
     *   be shown automatically just before the next command prompt.  In
     *   most cases, game code won't call this directly, but will request
     *   the same effect using the <.topics> tag in topic response text.  
     */
    scheduleTopicInventory(key = nil)
    {
        /* note that we have a request for a prompt-time topic inventory */
        pendingTopicInventory = true;      
        
        /* note the key to be used for this request. */
        pendingTopicInventoryKey = key;
    }

    /*
     *   Mark a tag as revealed.  This adds an entry for the tag to the
     *   revealedNameTab table.  We simply set the table entry to 'true'; the
     *   presence of the tag in the table constitutes the indication that the
     *   tag has been revealed.
     *
     *   (Games and library extensions can use 'modify' to override this and
     *   store more information in the table entry.  For example, you could
     *   store the time when the information was first revealed, or the location
     *   where it was learned.  If you do override this, just be sure to set the
     *   revealedNameTab entry for the tag to a non-nil and non-zero value, so
     *   that any code testing the presence of the table entry will see that the
     *   slot is indeed set.)
     *
     *   The actual method and the revealedNameTab are on libGlobal rather than
     *   here in order to make them available to games that don't include
     *   actor.t.
     */
    setRevealed(tag)
    {
        libGlobal.setRevealed(tag);
        
        /* 
         *   if something has just been revealed to us, it has also just been
         *   revealed to every other actor in the vicinity who could overhear
         *   the conversation (including the actor who has just spoken, if there
         *   is one; if there isn't then the revealed tag is presumably being
         *   used for a non-conversational purpose, so we don't try to inform
         *   any other actors).
         */
        
        
        if(respondingActor != nil)
        {
            forEachInstance(Actor, new function(a) {
                if(a != gPlayerChar && Q.canHear(a, respondingActor))
                    a.setInformed(tag);
            } );
        }
    }

    /* 
     *   Notify every actor who's in a position to hear that we've just imparted
     *   some information.
     */
    setInformed(tag)
    {
        forEachInstance(Actor, new function(a) {
            if(a != gPlayerChar && Q.canHear(a, gPlayerChar))
                a.setInformed(tag);
        } );
    }
    
    
    showAgendaError(tag, arg)
    {
#ifdef __DEBUG
        "WARNING!!! ";
        if(obj == nil)
            showObjNotExistError(tag, arg, 'Agenda Item');
        else if(!obj.ofKind(AgendaItem))
            showWrongKindofObjectError(tag, arg, 'an Agenda Item');
        else if(obj.getActor != respondingActor)
            showObjDoesNotBelongToActorError(tag, arg, 'Agenda Item');
        
        
#endif
        
    }
    
    showStateError(tag, arg)
    {
        #ifdef __DEBUG
        "WARNING!!! ";
        if(obj == nil)
            showObjNotExistError(tag, arg, 'Actor State');
        else if(!obj.ofKind(ActorState))
            showWrongKindofObjectError(tag, arg, 'an ActorState');
        else if(obj.getActor != respondingActor)
            showObjDoesNotBelongToActorError(tag, arg, 'Actor State');
        
        #endif
    }

    showKnownError(tag, arg)
    {
         #ifdef __DEBUG
        "WARNING!!! ";
        if(obj == nil)
            showObjNotExistError(tag, arg, 'Mentionable');
        else if(!obj.ofKind(Mentionable))
            showWrongKindofObjectError(tag, arg, 'a Mentionable');
        
#endif
    }
    
 #ifdef __DEBUG   
    showObjNotExistError(tag, arg, typ)
    {
        "<<typ>> <<arg>> for (actor = <<respondingActor.name>> was not added to
        conversationManager.objNameTab or does not exist. Check that you have
        spelled the <<typ>> <<arg>> name correctly or try adding a dummy
        (unused) topic entry that uses &lt;.<<tag>> <<arg>>&gt;. ";
    }
    
    showWrongKindofObjectError(tag, arg, typ)
    {
        "<tag> is not <<typ>> so can't be used in a <<tag>> tag (see
        TopicEntries for <<respondingActor.theName>> ";
    }
    
    showObjDoesNotBelongToActorError(tag, arg, typ)
    {
        "<<typ>> <<tag>> does not belong to
            <<respondingActor.theName>>, so can't be used in a <<tag>> tag. ";
    }
 #endif   
    
    /* a vector of actors, indexed by their convMgrID values */
    idToActor = static new Vector(32)

    /* preinitialize */
    execute()
    {
//        /* add every ConvNode object to our master table */
//        forEachInstance(ConvNode,
//                        { obj: obj.getActor().convNodeTab[obj.name] = obj });
        
        
        /*  Add ourselves to the list of output filters. */
        
        mainOutputStream.addOutputFilter(self);
        /* 
         *   set up the prompt daemon that makes automatic topic inventory
         *   suggestions when appropriate 
         */
        new PromptDaemon(self, &topicInventoryDaemon);
    }

    /*
     *   Prompt daemon: show topic inventory when appropriate.  When a
     *   response explicitly asks us to show a topic inventory using the
     *   <.topics> tag, or when other game code asks us to show topic
     *   inventory by calling scheduleTopicInventory(), we'll show the
     *   inventory just before the command input prompt.  
     */
    topicInventoryDaemon()
    {
        /* if we have a topic inventory scheduled, show it now */
        if (pendingTopicInventory)
        {
            /* 
             *   Show the player character's topic inventory.  This is not
             *   an explicit inventory request, since the player didn't ask
             *   for it.  
             */
            
            if(gPlayerChar.currentInterlocutor != nil)
                gPlayerChar.currentInterlocutor.showSuggestions(nil,
                    pendingTopicInventoryKey); 

            /* we no longer have a pending inventory request */
            pendingTopicInventory = nil;
            pendingTopicInventoryKey = nil;
        }
    }

    /* flag: we have a pending prompt-time topic inventory request */
    pendingTopicInventory = nil
    
    /* The key to use for the pending prompt-time inventory request */
    pendingTopicInventoryKey = nil
    
    objNameTab = static new LookupTable
;

/* 
 *   Base class for items (Actors and DefaultAgendaTopics) that can handle
 *   AgendaItems
 */

class AgendaManager: object
    agendaList = nil
    
    /* 
     *   add an agenda item. We try to make this as author-proof as possible so
     *   that the method will accept addToAgenda(item), addToAgenda(item1,
     *   item2, ...) or addToAgenda([item1, item2,..])
     */
     
    addToAgenda([lst])
    {
        /* if we don't have an agenda list yet, create one */
        if (agendaList == nil)
            agendaList = new Vector(10);
        
        /* add the item or items */
        foreach(local val in lst)
        {    
            foreach(local cur in valToList(val))
            {
                agendaList += cur;
                
                /* reset the agenda item */
                cur.resetItem();
            }
        }
        
        /* 
         *   keep the list in ascending order of agendaOrder values - this will
         *   ensure that we'll always choose the earliest item that's ready to
         *   run
         */
        agendaList.sort(SortAsc, {a, b: a.agendaOrder - b.agendaOrder});

       
    }

    /* remove one or more agenda items */
    removeFromAgenda([lst])
    {
        /* if we have an agenda list, remove the item */
        if (agendaList != nil)
        {
            foreach(local val in lst)
            {
                foreach(local item in valToList(val))
                {
                    agendaList.removeElement(item);
                }
            }
        }
    }

    /*
     *   Execute the next item in our agenda, if there are any items in the
     *   agenda that are ready to execute.  We'll return true if we found
     *   an item to execute, nil if not.  
     */
    executeAgenda()
    {
        local item;
        local actor = getActor;

        /* if we don't have an agenda, there are obviously no items */
        if (agendaList == nil)
            return nil;
        
        /* remove any items that are marked as done */
        while ((item = agendaList.lastValWhich({x: x.isDone})) != nil)
        {    
            actor.removeFromAllAgendas(item);
            actor.removeFromPendingAgenda(item);
        }

        /* 
         *   Scan for an item that's ready to execute.  Since we keep the
         *   list sorted in ascending order of agendaOrder values, we can
         *   just pick the earliest item in the list that's ready to run,
         *   since that will be the ready-to-run item with the lowest
         *   agendaOrder number. 
         */
        item = agendaList.valWhich({x: x.isReady});

        /* if we found an item, execute it */
        if (item != nil)
        {
            try
            {
                /* execute the item */
                item.invokeItemBase(self);
                
                /* 
                 *   if the item is done, remove it from all relevant agenda
                 *   lists
                 */
                if(item.isDone)
                    getActor.removeFromAllAgendas(item);
            }
            catch (RuntimeError err)
            {
                /* 
                 *   If an error occurs while executing the item, mark the
                 *   item as done.  This will ensure that we won't get
                 *   stuck in a loop trying to execute the same item over
                 *   and over, which will probably just run into the same
                 *   error on each attempt.  
                 */
                item.isDone = true;

                /* re-throw the exception */
                throw err;
            }

            /* tell the caller we found an item to execute */
            return true;
        }
        else
        {
            /* tell the caller we found no agenda item */
            return nil;
        }
    }
    
    
;



/* ------------------------------------------------------------------------ */
/*
 *   An "agenda item."  Each actor can have its own "agenda," which is a
 *   list of these items.  Each item represents an action that the actor
 *   wants to perform - this is usually a goal the actor wants to achieve,
 *   or a conversational topic the actor wants to pursue.
 *   
 *   On any given turn, an actor can carry out only one agenda item.
 *   
 *   Agenda items are a convenient way of controlling complex behavior.
 *   Each agenda item defines its own condition for when the actor can
 *   pursue the item, and each item defines what the actor does when
 *   pursuing the item.  Agenda items can improve the code structure for an
 *   NPC's behavior, since they nicely isolate a single background action
 *   and group it with the conditions that trigger it.  But the main
 *   benefit of agenda items is the one-per-turn pacing - by executing at
 *   most one agenda item per turn, we ensure that the NPC will carry out
 *   its self-initiated actions at a measured pace, rather than as a jumble
 *   of random actions on a single turn.
 *   
 *   Note that NPC-initiated conversation messages override agendas.  If an
 *   actor has an active ConvNode, AND the ConvNode displays a
 *   "continuation message" on a given turn, then the actor will not pursue
 *   its agenda on that turn.  In this way, ConvNode continuation messages
 *   act rather like high-priority agenda items.  
 */
class AgendaItem: object
    /* 
     *   My actor - agenda items should be nested within the actor using
     *   '+' so that we can find our actor.  Note that this doesn't add the
     *   item to the actor's agenda - that has to be done explicitly with
     *   actor.addToAgenda().  
     */
    getActor() { return location; }

    /*
     *   Is this item active at the start of the game?  Override this to
     *   true to make the item initially active; we'll add it to the
     *   actor's agenda during the game's initialization.  
     */
    initiallyActive = nil

    /* 
     *   Is this item ready to execute?  The actor will only execute an
     *   agenda item when this condition is met.  By default, we're ready
     *   to execute.  Items can override this to provide a declarative
     *   condition of readiness if desired.  
     */
    isReady = true

    /*
     *   Is this item done?  On each turn, we'll remove any items marked as
     *   done from the actor's agenda list.  We remove items marked as done
     *   before executing any items, so done-ness overrides readiness; in
     *   other words, if an item is both 'done' and 'ready', it'll simply
     *   be removed from the list and will not be executed.
     *   
     *   By default, we simply return nil.  Items can override this to
     *   provide a declarative condition of done-ness, or they can simply
     *   set the property to true when they finish their work.  For
     *   example, an item that only needs to execute once can simply set
     *   isDone to true in its invokeItem() method; an item that's to be
     *   repeated until some success condition obtains can override isDone
     *   to return the success condition.  
     */
    isDone = nil

    /*
     *   The ordering of the item relative to other agenda items.  When we
     *   choose an agenda item to execute, we always choose the lowest
     *   numbered item that's ready to run.  You can leave this with the
     *   default value if you don't care about the order.  
     */
    agendaOrder = 100

    /*
     *   The caller is passed as a parameter so we can tell whether we're being
     *   called from an Actor or from a DefaultAgendaTopic, which may affect
     *   what we want to do -- for example the wording of what the actor says at
     *   this point.
     */
    invokeItemBase(caller)
    {
        calledBy = caller;
        invokeItem();
    }
    
    /* 
     *   invokeItem can test the invokedByActor property to decide whether what
     *   the actor says should be a conversational gambit started on the actor's
     *   own initiative or as a (default) response to something the pc has just
     *   tried to say.
     */
    
    invokedByActor = (calledBy == getActor)
    
    calledBy = nil
    /*
     *   Execute this item.  This is invoked during the actor's turn when the
     *   item is the first item that's ready to execute in the actor's agenda
     *   list.  We do nothing by default.
     *
    
     */
    invokeItem() { }

    /*
     *   Reset the item.  This is invoked whenever the item is added to an
     *   actor's agenda.  By default, we'll set isDone to nil as long as
     *   isDone isn't a method; this makes it easier to reuse agenda
     *   items, since we don't have to worry about clearing out the isDone
     *   flag when reusing an item. 
     */
    resetItem()
    {
        /* if isDone isn't a method, reset it to nil */
        if (propType(&isDone) != TypeCode)
            isDone = nil;
    }
    
    /* An optional tag, specified as a single-quoted string. */
    
    name = nil
;


/*
 *   A "conversational" agenda item.  This type of item is ready to execute
 *   only when the actor hasn't engaged in conversation during the same
 *   turn.  This type of item is ideal for situations where we want the
 *   actor to pursue a conversational topic, because we won't initiate the
 *   action until we get a turn where the player didn't directly talk to
 *   us.  
 */
class ConvAgendaItem: AgendaItem
    isReady = (getActor().convAgendaReady(otherActor) && inherited())

    /* 
     *   The actor we're planning to address - by default, this is the PC.
     *   If the conversational overture will be directed to another NPC,
     *   you can specify that other actor here. 
     */
    otherActor = (gPlayerChar)
    
    invokeItemBase(caller)
    {
        /* 
         *   Note that our actor is in conversation with the otherActor
         *   (normally gPlayerChar) and attempt an actor greeting, if one has
         *   been defined. It's useful to do this here since a ConvAgendaItem
         *   might very well initiate a conversation.
         */
        
        local actor = getActor();
        
        if(otherActor == gPlayerChar)                    
        {
            if(gPlayerChar.currentInterlocutor != actor)
                reasonInvoked = 1;
            else if(caller == actor)
                reasonInvoked = 2;
            else
                reasonInvoked = 3;
            
            greetingDisplayed = actor.actorSayHello();                    
        }
        else
            otherActor.currentInterlocutor = actor;
        
        /* Then call the base handling */
        inherited(caller);     
        
        /* 
         *   It's possible that our invokeItem() method just tried to set up a
         *   convnode, but since the actor won't have gone through it's
         *   handleTopic method, it won't have moved any pendingKeys into the
         *   activeKeys, so we need to do that now. At the same time we need to
         *   tell the actor not to keep the pending keys beyond the next
         *   conversational turn.
         */
        
        actor.activeKeys = actor.pendingKeys;        
        actor.keepPendingKeys = nil;
    }
    
    /* 
     *   Flag; did invoking this item result in the display of a greeting (from
     *   an ActorHelloTopic)?
     */
    
    greetingDisplayed = nil
    
    /* 
     *   Why was this ConvAgenda Item invoked?
     *.    1 = Actor initiating new conversation
     *.    2 = Actor using lull in conversation
     *.    3 = Actor responding DefaultAgendaTopic
     */
            
    reasonInvoked = 0
    
;

/*
 *   A delayed agenda item.  This type of item becomes ready to execute
 *   when the game clock reaches a given turn counter.  
 */
class DelayedAgendaItem: AgendaItem
    /* we're ready if the game clock time has reached our ready time */
    isReady = (libGlobal.totalTurns >= readyTime && inherited())

    /* the turn counter on the game clock when we become ready */
    readyTime = 0

    /*
     *   Set our ready time based on a delay from the current time.  We'll
     *   become ready after the given number of turns elapses.  For
     *   convenience, we return 'self', so a delayed agenda item can be
     *   initialized and added to an actor's agenda in one simple
     *   operation, like so:
     *   
     *   actor.addToAgenda(item.setDelay(1)); 
     */
    setDelay(turns)
    {
        /* 
         *   initialize our ready time as the given number of turns in the
         *   future from the current game clock time 
         */
        readyTime = libGlobal.totalTurns + turns;

        /* return 'self' for the caller's convenience */
        return self;
    }
;


/*
 *   A special kind of agenda item for monitoring "boredom" during a
 *   conversation.  We check to see if our actor is in a conversation, and
 *   the PC has been ignoring the conversation for too long; if so, our
 *   actor initiates the end of the conversation, since the PC apparently
 *   isn't paying any attention to us. 
 */
class BoredomAgendaItem: AgendaItem
    /* we construct these dynamically during actor initialization */
    construct(actor)
    {
        /* remember our actor as our location */
        location = actor;
    }

    /* 
     *   we're ready to run if our actor is in an InConversationState and
     *   its boredom count has reached the limit for the state 
     */
    isReady()
    {
        local actor = getActor();
        local state = actor.curState;
        if(state == nil)
            state = actor;

        return (inherited()
                && gPlayerChar.currentInterlocutor == actor
                && state.attentionSpan != nil
                && actor.boredomCount >= state.attentionSpan);
    }

    /* on invocation, end the conversation */
    invokeItem()
    {
        local actor = getActor();
        local state = actor.curState;
        if(state == nil)
            state = actor;

        /* tell the actor to end the conversation */
        actor.endConversation(endConvBoredom);
       
    }

    /* 
     *   by default, handle boredom before other agenda items - we do this
     *   because an ongoing conversation will be the first thing on the
     *   NPC's mind 
     */
    agendaOrder = 50
;

/* 
 *   An AgendaItem initializer.  For each agenda item that's initially
 *   active, we'll add the item to its actor's agenda.  
 */
PreinitObject
    execute()
    {
        forEachInstance(AgendaItem, function(item) {
            /* 
             *   If this item is initially active, add the item to its
             *   actor's agenda. 
             */
            if (item.initiallyActive)
                item.getActor().addToAgenda(item);
             
                        
        });
    }
;

/* 
 *   Create and store a table of string representation of object names that
 *   might be needed in conversation tags.
 */

objTablePreinit: PreinitObject
    execute()
    {
        t3GetGlobalSymbols().forEachAssoc( new function(key, value)
        {
            if(dataType(value) == TypeObject && (value.ofKind(Mentionable) ||
                                                 value.ofKind(AgendaItem) ||
                                                 value.ofKind(ActorState)))
                
                conversationManager.objNameTab[key] = value;
            
        } );        
    }
    
    executeBeforeMe = [pronounPreinit, thingPreinit]   
;



 /* 
  *   The problem with the smart quotes <q> </q> is that if one is missing, 
  *   or a spurious one is added, the error is perpetrated throughout the 
  *   rest of the game (or until a compensating error is located). The 
  *   purpose of quoteFilter is (a) to report such errors (to make them 
  *   easier to fix) and (b) to prevent them being propagated beyond a 
  *   single turn. In the main this works by having quoteFilter take over 
  *   responsibility for turning the <q> and </q> tags into the appropriate 
  *   HTML entities rather than leaving it to the HTML rendering engine in 
  *   the interpreter. The quoteFilter OutputFilter keeps its own track of 
  *   whether a double quote or a single quote is rquired next, and resets 
  *   this count at the start of each turn.
  */


quoteFilter: OutputFilter, InitObject
    filterText(ostr, txt) 
    { 
        local quoteRes, quoteStr;
        do
        {
            quoteRes = rexSearch(quotePat, txt);
            if(quoteRes)
            {   
                quoteStr = quoteRes[3];
                if(quoteStr.toLower() == '<q>')
                {
                    txt = txt.findReplace(quoteStr, quoteCount % 2 == 0 
                                          ? '&ldquo;' : '&lsquo;', ReplaceOnce);
                   quoteCount ++;                
                }
                else
                {
                    
                    txt = txt.findReplace(quoteStr, quoteCount % 2 == 1 
                                          ? '&rdquo;' : '&rsquo;', ReplaceOnce);
                    quoteCount --;                   
                    
                }
            }      
                
                
        } while(quoteRes);

        return txt; 
    }
    
    quoteCount = 0 
    
    quotePat = static new RexPattern('<NoCase><langle>(q|/q)<rangle>')
    
    
    
    execute()
    {
        mainOutputStream.addOutputFilter(self);
        
        if(showWarnings)
            new PromptDaemon(self, &quoteCheck);
       
    }
    
    /* 
     *   Should I show a warning when I find unmatched smart quotes over the 
     *   course of a turn? Displaying such a warning would probably look 
     *   intrusive in a released version, but might well be useful in a 
     *   version sent out to beta-testers (so it shouldn't be tied to a 
     *   version compiled for debugging). The showWarnings flag thus allows 
     *   the warning messages to be turned on and off as desired.
     */
    
    showWarnings = true
    
    /* 
     *   The PromptDaemon set up in our execute() method at Initialization 
     *   runs this method at the end of each turn. It checks to see if the 
     *   number of opening smart quotes over the course of the turn just 
     *   completed is the same as the number of closing smart quotes, and 
     *   optionally prints a warning message if it is not.
     */
    
    
    quoteCheck()
    {
        if(quoteFilter.quoteCount != 0 && showWarnings)
            "<FONT COLOR=RED><b>WARNING!!</b></FONT> Unmatched quotes on
            this turn; quoteCount = <<quoteCount>>. ";      
        
        /* 
         *   In any case we want to zeroize the quoteCount at the start of 
         *   each turn so that the first smart quote we encounter on the 
         *   turn will display correctly no matter what went before.
         */
        quoteCount = 0;
    }
    
;


/* 
 *   A special lister to display a topic inventory list from a list of topics
 *   provided in the lst parameter.
 */

suggestedTopicLister: object
    show(lst, explicit = true)
    {
        /* 
         *   first exclude all items that don't have a name property, since
         *   there won't be anything to show.
         */
        
        lst = lst.subset({x: x.name != nil && x.name.length > 0});
        
        /* 
         *   if the list is empty there's nothing for us to say, so say so and
         *   finish
         */
        
        if(lst.length == 0)
        {
            if(explicit)
                DMsg(nothing in mind, '{I} {have} nothing in mind to discuss
                    {now}. ');
                
            return;
        }
        
        
        /* next we need to divide the list according to category */   
        
//        /* first, initialize all our lists. */
//        
//       
//        doneList = new Vector;
        
        
        /* 
         *   Go through the list assigning each topic entry to the user
         *   specified type, where the user has specified it.
         */
        
        foreach(local cur in typeInfo)
        {
            self.(cur[1]) = lst.subset({t: t.suggestAs == cur[3]});
            lst -= self.(cur[1]);
        }
        
        /* 
         *   then go through every remaining item in our main list, assigning it
         *   to a sublist on the basis of which type of topic entry it is, which
         *   we'll determine on the basis of its includeInList.
         */
        
        foreach(local cur in typeInfo)
        {
            self.(cur[1]) += lst.subset({t: includes(t, cur[2])});
            lst -= self.(cur[1]);
        }
        
//       
        
        /* Introduce the list */
        if(!explicit)
            "<.p>(";
        
        DMsg(suggestion list intro, '{I} could ');
        
        local listStarted = nil;
        local interlocutor = gPlayerChar.currentInterlocutor;
        gMessageParams(interlocutor);
        
        if(sayList.length > 0)
        {
            showList(sayList);
            listStarted = true;
        }
        
        if(queryList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(ask query, 'ask {him interlocutor} ');
            showList(queryList);
            listStarted = true;                
        }
        
        if(askList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(ask about, 'ask {him interlocutor} about ');
            showList(askList);
            listStarted = true;
        }
        
        if(tellList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(tell about, 'tell {him interlocutor} about ');
            showList(tellList);
            listStarted = true;
        }
        
        if(talkList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(talk about, 'talk about ');
            showList(talkList);
            listStarted = true;
        }
        
        if(giveList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(give, 'give {him interlocutor} ');
            showList(giveList);
            listStarted = true;
        }
        
        if(showToList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(show, 'show {him interlocutor} ');
            showList(showToList);
            listStarted = true;
        }
        
        if(askForList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(ask for, 'ask {him interlocutor} for ');
            showList(askForList);
            listStarted = true; 
        }
        
        if(yesList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            
            showList(yesList);
            listStarted = true;
        }
        
        if(noList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            
            showList(noList);
            listStarted = true;
        }
        
        if(commandList.length > 0)
        {
            if(listStarted)
                say(orListSep);
            DMsg(ask for, 'tell {him interlocutor} to ');
            showList(askForList);
            listStarted = true; 
        }
        
        /* finish the list. */
        if(explicit)
            ".\n";
        else
            ")\n";
        
    }
    
    showList(lst)
    {
        for(local cur in lst, local i = 1 ;; ++i)
        {
            if(cur.includeSayInName)
                say(sayPrefix);
            say(cur.name);
            if(i == lst.length - 1)
                DMsg(or, ' or ');
            if(i < lst.length - 1)
                ", ";
            
        }
    }
    
    typeInfo = [
        [&sayList, &sayTopics, SayTopic],
        [&queryList, &queryTopics, QueryTopic],
        [&askForList, &askForTopics, AskForTopic],
        [&askList, &askTopics, AskTopic],
        [&tellList, &tellTopics, TellTopic],
        [&talkList, &talkTopics, TalkTopic],
        [&giveList, &giveTopics, GiveTopic],
        [&showToList, &showTopics, ShowTopic],
        [&yesList, &miscTopics, YesTopic],
        [&nolist, &miscTopics, NoTopic],
        [&commandList, &commandTopics, CommandTopic]
        
    ]
    
    sayList = []
    queryList = []
    askList = []
    tellList = []
    talkList = []
    giveList = []
    showToList = []
    yesList = []
    noList = []
    askForList = []
    commandList = []
    
    doneList = nil
    
    /* 
     *   Test whether the topicEntry t includes prop in its includeInList and
     *   hasn't already been included in a previous list.
     */
    
    includes(t, prop)
    {
        return t.includeInList.indexOf(prop) != nil;
    }
    
    sayPrefix = BMsg(say prefix, 'say ')
    orListSep = BMsg(or list separator, '; or ')

;
