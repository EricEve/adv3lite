#charset "us-ascii"
#include "advlite.h"


/*
 *   ****************************************************************************
 *    actor.t 
 *
 *    This module forms part of the adv3Lite library 
 *    (c) 2012-13 Eric Eve
 */

/* Declare the eventList property in case the eventList module isn't included */
property eventList;

/*    
 *   An Actor is an object representing a living being (or something that
 *   behaves like a living being, such as an intelligent robot), with which the
 *   player character can potentially converse, and which can move around and
 *   pursue his/her/its own agenda. This class is intended for the
 *   implementation of NPCs (non-player characters).
 */
class Actor: AgendaManager, ActorTopicDatabase, Thing
    
    /* 
     *   Our current ActorState. This should normally be treated as a read-only
     *   property; to change the current ActorState of an actor call the
     *   setState() method.
     */
    curState = nil
    
    /*   
     *   Set our current ActorState to a new state (stat) or to no state at all
     *   (if the stat parameter is supplied as nil).
     */
    setState(stat)
    {
        /* 
         *   Only do anything if the new state (stat) is different from our
         *   current state.
         */
        if(curState != stat)
        {
            /* 
             *   If the current state is non-nil, call its deactivateState()
             *   method to notify it that we're leaving it.
             */
            if(curState != nil)
               curState.deactivateState(self, stat);
            
            /*  
             *   If the new state is non-nil, call its activateState() method to
             *   notify it that we're entering it.
             */
            if(stat != nil)
               stat.activateState(self, curState);
            
            /*  Set out current state to the new state. */
            curState = stat;
        }
    }
    
    
    /* 
     *   Our state-specific description, which is appended to our desc to give
     *   our full description. By default we simply take this from our current
     *   ActorState.
     */
    stateDesc = (curState != nil ? curState.stateDesc : '')
    
    /*   
     *   Our specialDesc (used to describe us in room listing). By default we
     *   use our ActorState's specialDesc if we have a current ActorState or
     *   else our actorSpecialDesc if our current ActorState is nil. But if
     *   there's a current FollowAgendaItem we let it handle the specialDesc
     *   instead.
     */
    specialDesc()
    {
        /* If we have a current followAgendaItem, use its specialDesc */
        if(followAgendaItem != nil)
            followAgendaItem.showSpecialDesc();
        
        /* 
         *   Otherwise use our current ActorState's specialDesc if we have one
         *   or our our actorSpecialDesc if not.
         */
        else
            curState != nil ? curState.specialDesc : actorSpecialDesc;
    }
    
    
    /*   
     *   The specialDesc to use if we don't have a current ActorState By default
     *   we just display a message saying the actor is here or that the actor is
     *   in a nested room.
     */
    actorSpecialDesc()
    {	    
        /* 
         *   If this actor is the player character then we don't want to display
         *   anything by default here.
         */
        if(isPlayerChar)
            return;
        
        if(location == getOutermostRoom)
            DMsg(actor here, '\^<<theNameIs>> {here}. ');
        else
            DMsg(actor in location, '\^<<theNameIs>> <<location.objInName>>. ');        		
    }
    
    /*   
     *   We normally list any actors after the miscellaneous contents of a room
     */
    specialDescBeforeContents = nil
    
    /*   
     *   The specialDesc of this actor when it is viewed from a remote location.
     *   If we have a current ActorState we use its remoteSpecialDesc, otherwise
     *   we use the actorRemoteSpecialDesc on the actor. Either way the pov
     *   parameter is the point of view object from which this actor is being
     *   viewed (normally the player char).
     *
     *   Note that this method is generally only relevant if the senseRegion
     *   module is used.
     */
    remoteSpecialDesc(pov) 
    { 
        curState == nil ? actorRemoteSpecialDesc(pov) :
        curState.remoteSpecialDesc(pov);
    }
        
    /* 
     *   The remoteSpecialDesc to use if we don't have a current ActorState
     *   (i.e. if curState is nil). By default we just use our actorSpecialDesc.
     */
    actorRemoteSpecialDesc(pov) { actorSpecialDesc; }
       
    /*   
     *   By default actors can't be picked up and carried around by other actors
     *   (though game authors can override this if they need to create a
     *   portable actor).
     */
    isFixed = true    
    
    /*   The message to display when someone tries to take this actor. */
    cannotTakeMsg = BMsg(cannot take actor, '{The subj dobj} {won\'t} let {me}
        {dummy} pick {him dobj} up. ')
    
    /*   The (portable) contents of an actor are regarded as being carried. */
    contType = Carrier
    
    /* 
     *   We don't normally list the contents of an Actor when Looking or
     *   Examining.
     */
    contentsListed = nil
    
    /*   
     *   The default response of the actor to a conversational command that is
     *   not handled anywhere else.
     */
    noResponseMsg = BMsg(no response, '{The subj cobj} {doesnot respond[ed]}. ')
    
    
    /* Handle a command (e.g. BOB, JUMP) directed at this actor. */
    handleCommand(action)
    {
        /* 
         *   If the Command is GiveTo and the iobj is the player char, treat it
         *   as AskFor with the player char as the effective actor
         */        
        if(action.ofKind(GiveTo) && gCommand.iobj == gPlayerChar)
        {
            /* Change the current actor to the player char */
            gCommand.actor = gPlayerChar;
            
            /* 
             *   Handle the command as if the player had issued an AskFor
             *   command
             */
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
            
            /* Handle the command as AskFor */ 
            handleTopic(&askTopics, gCommand.iobj.topicList);
        }
        
        /* exclude SystemActions as a matter of course */
        else if(action.ofKind(SystemAction))
        {
            DMsg(cannot command system action, 'Only the player can carry out
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
            /* Make the player character the current actor */
            gCommand.actor = gPlayerChar;
            
            /* Note the query type on the current action */
            gAction.qType = gCommand.verbProd.qtype;
            
            /* Carry out the QueryTopic handling. */
            handleTopic(&queryTopics, gCommand.dobj.topicList);
        }
        
        /* treat Actor, (say) something as SAY SOMETHING TO ACTOR */
        else if(action.ofKind(SayAction))
        {
            /* Make the player character the current actor */
            gCommand.actor = gPlayerChar;            
            
            /* Carry out the SayTopic handling */
            handleTopic(&sayTopics, gCommand.dobj.topicList);
        }
        
        /* Otherwise try letting a CommandTopic handle it */
        else
        {
            /* 
             *   Note the direct and indirect objects of the command on the
             *   action.
             */
            action.curDobj = gCommand.dobj;
            action.curIobj = gCommand.iobj;
            
            /* Carry out the CommandTopic handling with the action commanded. */
            handleTopic(&commandTopics, action, &refuseCommandMsg);
        }
    }
    
    /*  
     *   The default message to use in response to a command directed to this
     *   actor that is not handled in any other way.
     */
    refuseCommandMsg = BMsg(refuse command, '{I} {have} better things to do. ')
        
    
    /* 
     *   Find the best response to the topic produced by the player's command.
     *   prop is the xxxTopics list property we'll use to search for a matching
     *   TopicEntry. We first search the current ActorState for a match and
     *   then, only if we fail to find one, we search TopicEntries directly
     *   located in the actor. First priority, however, is given to TopicEntries
     *   whose convKeys match this actor's currentKeys (they match if the two
     *   lists have at least one element in common).
     */    
    getBestMatch(prop, requestedList)    
    {
        /* 
         *   In the implementation of the conversation system we expect the prop
         *   parameter to be passed as a property pointer, but in the inherited
         *   handling it's a list. To avoid accidents, first check what we've
         *   got before converting the prop to a list.
         *
         */
        local myList;
        
        /* 
         *   If prop has been supplied as a property pointer, get the list
         *   defined on that property
         */
        if(dataType(prop) == TypeProp)
            myList = self.(prop);
        
        /*  
         *   Otherwise, if prop is simply a value, convert it directly to a list
         */
        else
            myList = valToList(prop);
        
        
        /* 
         *   If we have a current activeKeys list restrict the choice of topic
         *   entries to those whose convkeys overlap with it, at least at a
         *   first attempt. If that doesn't produce a match, try the normal
         *   handling.
         */             
        if(activeKeys.length > 0)
        {
            /* 
             *   Obtain a list of those items in myList (the list of topic
             *   entries we started with) that have convKeys that overlap with
             *   our activeKeys.
             */
            local kList = myList.subset({x:
                                   valToList(x.convKeys).overlapsWith(activeKeys)});
            
            /* 
             *   See if we can find a match by carrying out the inherited
             *   handling (from ActorTopicDatabase) with this sublist (for which
             *   the convKeys and activeKeys overlap)
             */
            local match = inherited(kList, requestedList);
            
            /*   If we find a match, simply return it and end there. */
            if(match != nil)
                return match;
        }
      
        /* 
         *   Otherwise carry out the inherited handling (from
         *   ActorTopicDatabase) with the complete list and return the result.
         */
        return inherited(myList, requestedList);
    }
    
    /*  
     *   Find the best response to use for a conversational command directed to
     *   this actor. prop would normally be a property pointer for the property
     *   containing the appropriate list or lists of Topic Entries to test, and
     *   topic is the Topic object we're trying to match.
     */
    findBestResponse(prop, topic)
    {
        local bestMatch;
        
        /* If we have a current ActorState, first try to get its best match */
        if(curState != nil)
        {
            /* Get the best matching TopicEntry from our current actor state. */
            bestMatch = curState.getBestMatch(prop, topic);
            
            /* If we found a result, return it and end there. */
            if(bestMatch != nil)
                return bestMatch;
        }
        
        /* 
         *   If we don't have a current ActorState, or we can't find a match on
         *   our current ActorState, find the best match from the TopicEntries
         *   located directly within the actor.
         */
        return getBestMatch(prop, topic);
    }
    
    /* 
     *   Handle a conversational command where prop is a pointer to the property
     *   containing the appropriate list of TopicEntries to search (e.g.
     *   &askTopics), topic is the Topic to match, and defaultProp is pointer to
     *   the property to invoke if we can't find a match.
     */
    handleTopic(prop, topic, defaultProp = &noResponseMsg)
    {
        /* 
         *   Reset the keysManaged flag to nil so that we can end this method by
         *   carrying out the necessary keys management unless this is handled
         *   indirectly through the call to response.handleTopic() below, which
         *   may set this flag to true.
         */
        keysManaged = nil;
	
        /* 
         *   Note the best response we can find; i.e. the TopicEntry from the
         *   prop list that best matches topic.
         */
        local response = findBestResponse(prop, topic);
        
        /* 
         *   If we find a response, carry out an implied greeting if we need
         *   one, and then display the response.
         */
        if(response != nil)
        {    
            /* 
             *   Check whether we need to carry out an implied greeting. We need
             *   to do so if we're not already the player character's current
             *   interlocutor and the response we've found is a conversational
             *   one (i.e. one in which a conversational exchange actually takes
             *   place as opposed to one explaining why it can't or shouldn't).
             */
            if(gPlayerChar.currentInterlocutor != self &&
               response.isConversational)
            {            
                /* Make the player character the current interlocutor. */
                gPlayerChar.currentInterlocutor = self;
                
                /* 
                 *   Only try an implicit greeting if the response we've found
                 *   implies one (this prevents an implicit greeting from
                 *   forever trying to trigger itself, for example).
                 */
                if(response.impliesGreeting)
                {
                    /* 
                     *   Carry out an implicit greeting. If this does anything
                     *   add a paragraph break to separate it from the
                     *   conversational exchange that follows.
                     */
                    if(handleTopic(&miscTopics, [impHelloTopicObj]))
                      "<.p>";
                }
            }
            
            /* 
             *   Let the response (the TopicEntry we've identified as the best
             *   match to the topic requested) handle the topic.
             */
            response.handleTopic();     
            
            /* 
             *   If the response is a converational one, note that conversation
             *   has taken place on this turn.
             */
            if(response.isConversational)
                noteConversed(); 
        }
        
        /* Otherwise, if we haven't found a matching response... */
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
            
            /* Otherwise, use our defaultProp to display a default message */
            else
                say(self.(defaultProp));    
           
        }
        
        /* 
         *   Carry out the key management if it hasn't already been carried out
         *   on this turn. It may already have been by a tag handled by the
         *   conversationManager object processed via the call to
         *   response.handleTopic() above.
         */
        if(!keysManaged)
            manageKeys();
        
         /* 
          *   Return true or nil depending on whether we found a matching
          *   response to display
          */        
        return response != nil;
    }
    
    /* 
     *   Move pending keys to active keys and clear pending keys if need be. We
     *   call this out as a separate method to allow it to be directly called
     *   from elsewhere.
     */
    manageKeys()
    {
        /* 
         *   Reset the pending keys to nil unless we've been requested to retain
         *   them. (The pendingKeys are the set of convKeys that a previous
         *   conversational turn may have told us to match).
         */
        if(!keepPendingKeys)
            pendingKeys = [];
        
        /* Set our activeKeys to our pendingKeys */
        activeKeys = pendingKeys;
        
        /*  Reset the flag that tells us to keep our pending keys */
        keepPendingKeys = nil;  
        
        /* Note that we have now managed our keys. */ 
        keysManaged = true;		
    }
    
    /* 
     *   Flag; has the active/pending key management already been carried out on
     *   this turn?
     */
    keysManaged = nil
	
    /* Convenience method to note that conversation has occurred on this turn */    
    noteConversed()
    {
        /* Note that we're the player character's current interlocutor */
        gPlayerChar.currentInterlocutor = self;
        
        /* Note that we last conversed on this turn */
        lastConvTime = libGlobal.totalTurns;
        
        /* Note that this actor is a possible antecedent for a pronoun */
        notePronounAntecedent(self);
        
        /* Add our boredomAgendaItem to our agenda if it isn't already there */
        if(valToList(agendaList).indexOf(boredomAgendaItem) == nil)
            addToAgenda(boredomAgendaItem);
    }
    
    /* 
     *   This method can be called on the actor when we want to display the text
     *   of one or both sides of a conversational exchange with the actor
     *   without going through the TopicEntry mechanism to do so.
     */ 
    actorSay(str)
    {
        /* 
         *   Reset the keysManaged flag to nil so that we can end this method by
         *   carrying out the necessary keys management unless this is handled
         *   indirectly through the call to say(str) below, which may set this
         *   flag to true.
         */
        keysManaged = nil;
        
        /* Not that we have conversed with the actor this turn */		
        noteConversed();
        
        /* Display the text of the conversational exchange. */
        say(str);
        
        /* Carry out the keys management if it hasn't already been carried out. */
        if(!keysManaged)
            manageKeys();
    }
    
	
    /* 
     *   The last turn on which this actor conversed with the player character.
     *   We start out with a value of -1 to mean that we haven't conversed at
     *   all.
     */
    lastConvTime = -1
    
    /*  
     *   Has this actor conversed with the player character on the current turn?
     *   He/she/it has done so if our last conversation time is the same as the
     *   game's turn count.
     */
    conversedThisTurn = (lastConvTime == libGlobal.totalTurns)

    /*  
     *   Did this actor converse with the player character on the previous turn?
     *   He/she/it did so if our last conversation time is one less than the
     *   game's current turn count.
     */
    conversedLastTurn = (lastConvTime == libGlobal.totalTurns - 1)
    
    
    /* 
     *   If this list is not empty then the choice of topic entries to match
     *   will be restricted to those whose convKeys property includes at least
     *   one of the key values in this list.
     */
    activeKeys = []
    
    /* 
     *   a list of the keys to be copied into the activeKeys property for use in
     *   the next conversational turn. These are normally added by game code via
     *   <.convnode> tags and the like in conversational output.
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
     *   on the next conversational turn.     */
    
    addPendingKey(val)
    {
        pendingKeys += val;
    }
    
    
    /*  Notification that an action is about to be carried out in our presence */
    beforeAction()
    {
        /* First execute our own actorBeforeAction() method */
        actorBeforeAction();
        
        /* 
         *   Then execute our current ActorState's beforeAction() method, if we
         *   have a current ActorState.
         */
        if(curState != nil)
            curState.beforeAction();
    }
    
    /* 
     *   Give this actor a chance to respond just before an action prior to any
     *   response from its current actor state. By default we do nothing, but
     *   game code can easily override this without any risk of breaking the
     *   state-dependent beforeAction mechanism.
     */    
    actorBeforeAction()  { }
    
    /*  Notification that an action has just been carried out in our presence */
    afterAction()
    {
        /* First execute our own actorAfterAction() method */
        actorAfterAction();
        
        /* 
         *   Then execute the afterAction() method on our current ActorState, if
         *   we have one.
         */
        if(curState != nil)
            curState.afterAction();
           
    }
    
    /* 
     *   Give this actor a chance to respond just after an action prior to any
     *   response from its current actor state. By default we do nothing, but
     *   game code can easily override this without any risk of breaking the
     *   state-dependent afterAction mechanism.
     */ 
    actorAfterAction() { }
    
     /* 
      *   Notification that something else is about to travel. By default we
      *   defer to out actor state, if we have one, but we also give the actor
      *   object a chance to respond.
      */
    
    beforeTravel(traveler, connector) 
    {
        /* 
         *   If we have a current FollowAgendaItem, start by executing its
         *   beforeTravel() method.
         */
        
        if(followAgendaItem != nil && followAgendaItem.isReady)
            followAgendaItem.beforeTravel(traveler, connector);
        
        
        /* 
         *   Execute the beforeTravel() method on our current ActorState, if we
         *   have one.
         */
        if(curState != nil)
            curState.beforeTravel(traveler, connector);
        
        /*  Then execute our own actorBeforeTravel() method. */
        actorBeforeTravel(traveler, connector);
        
        /*  
         *   If the actor is waiting for the traveler to follow the actor via
         *   connector, then set the follow fuse instead of executing the
         *   actor's travel command.
         */        
        if(followAgendaItem != nil 
           && traveler == gPlayerChar 
           && followAgendaItem.isReady
           && followAgendaItem.nextConnector == connector)
        {

            setFollowMeFuse();
            exit;
        }
        
        
        /* 
         *   If the player char is talking to this actor and this actor is not
         *   following the player character, end the conversation.
         */
        
        if(gPlayerChar.currentInterlocutor == self && traveler == gPlayerChar
           && fDaemon == nil)
            endConversation(endConvLeave);
        
        /*  
         *   If the traveler that's about to travel is the player character,
         *   note the connector the player character is about to use.
         */
        if(traveler == gPlayerChar)
            pcConnector = connector;       
        
        
        
    }
    
    /* The Travel Connector just traversed by the player character */    
    pcConnector = nil
    
    /* 
     *   If the player character has seen this actor travel then lastTravelInfo
     *   contains a two-element list comprising the room the actor was seen
     *   travelling from and the connector by which the actor was seen
     *   travelling.
     *
     *   Note that if you move an actor by authorial fiat using moveInto() (say)
     *   when the player character can see the actor, you might want to update
     *   lastTravelInfo manually to ensure that any subsequent FOLLOW command
     *   still works properly, e.g.:
     *.
     *.   "Bob storms out through the front door, slamming it behind him. ";
     *.   bob.moveInto(nil);
     *.   bob.lastTravelInfo = [hall, frontDoor];
     *.
     *   (If instead of or before bob.moveInto(nil) you had written
     *   frontDoor.travelVia(bob), this wouldn't be necessary, since it would be
     *   handled for you by frontDoor.travelVia()).
     */
    lastTravelInfo = nil
    
    /* 
     *   Give this actor a chance to react just before another actor travels in
     *   addition to any reaction from its current actor state. By default we do
     *   nothing, but game code can easily override this without any risk of
     *   breaking the state-dependent beforeTravel mechanism.
     */ 
    actorBeforeTravel(traveler, connector) { }
       
    /* 
     *   Notification that travel has just taken place in our presence (usually
     *   because an actor has just arrived in our location)
     */    
    afterTravel(traveler, connector) 
    {
        /* If we have a current ActorState, execute its afterTravel() method */
        if(curState != nil)
            curState.afterTravel(traveler, connector);
        
        /* Execute our own actorAfterTravel() method */
        actorAfterTravel(traveler, connector);
    }  
        
        
    /* 
     *   Give this actor a chance to react just after another actor travels in
     *   addition to any reaction from its current actor state. By default we do
     *   nothing, but game code can easily override this without any risk of
     *   breaking the state-dependent afterTravel mechanism.
     */ 
    actorAfterTravel(traveler, connector) {}
    
    
    /*   
     *   Terminate a conversation that's currently going on between this actor
     *   and the player character. The reason parameter is the reason for ending
     *   the conversation and can be one of endConvBye (the player character has
     *   just said goodbye), endConvTravel (the player character is leaving the
     *   location), endConvBoredom (this actor has become bored with waiting for
     *   the player character to say anything) or endConvActor (this actor
     *   wishes to terminate the conversation for some other reason of its own).
     */
    endConversation(reason)
    {
        /* 
         *   If we're permitted to end the conversation for the reason
         *   specified, display a farewell message appopriate to the reason
         */
        if(canEndConversation(reason))
            sayGoodbye(reason);
        
        /* 
         *   otherwise if the player char is about to depart and the actor won't
         *   let the conversation end, block the travel
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
         *   First check whether there's a Conversation Node that wants to
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
         *   If we've reached this point it's because our current ActorState has
         *   objected to ending the conversation, so return nil to disallow it.
         */
        return nil;
    }
    
    /* 
     *   A state-independent check on whether this actor will allow the current
     *   conversation to end on account of reason. By default we simply return
     *   true to allow the conversation to end, but game code can override this
     *   to return nil to disallow the ending of the conversation (presumably
     *   under specific conditions).
     */
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
        /* First note which room we're currently in */
        local oldLoc = getOutermostRoom;
        
        /* 
         *   If we're not in the player character's current room, try to follow
         *   the player character
         */
        if(getOutermostRoom != gPlayerChar.getOutermostRoom)
        {
            /* 
             *   If we know which TravelConnector the player character left by,
             *   try to traverse it.
             */
            if(pcConnector != nil)                
                pcConnector.travelVia(self);
            
            /* 
             *   Otherwise, simply travel to the player character's current room
             */
            else
                gPlayerChar.getOutermostRoom.travelVia(self);
            
            /*  
             *   Display our message to say we're following the player character
             */
            sayFollowing(oldLoc);
            
            /* 
             *   Carry out any additional handling we want to do on arriving in
             *   our new location.
             */
            arrivingTurn();            
        }        
        
        /* 
         *   Reset pcConnector to nil in any event so that a spurious value
         *   isn't left for a later turn.
         */
        pcConnector = nil;
    }
    
    /* 
     *   Game code can call this method to instruct this actor to start
     *   following the player char round the map
     */    
    startFollowing()
    {
        /* 
         *   Create a new Daemon to carry out the following and make a note of
         *   it
         */
        fDaemon = new Daemon(self, &followDaemon, 1);
    }
    
    /* 
     *   Game code can call this method to instruct this actor to stop following
     *   the player char round the map.
     */    
    stopFollowing()
    {
        /* 
         *   If there's a currently active following Daemon, remove it from the
         *   game's list of events to be executed each turn.
         */
        if(fDaemon != nil)
            fDaemon.removeEvent();
        
        /*   Note that we no longer have an active following Daemon */
        fDaemon = nil;
        
        /*   
         *   Reset pcConnector to nil so that we don't leave an old spurious
         *   value for a later turn.
         */
        pcConnector = nil;
    }
    
    /* 
     *   Store the id of the daemon being used to make us follow the player
     *   char. We can check whether this actor is currently following or not by
     *   testing whether or not this is nil.
     */    
    fDaemon = nil
    
    /*   
     *   Display a message to say that we've just followed the player character
     *   to a new location from oldLoc.
     */
    sayFollowing(oldLoc)
    {
        /* 
         *   If we don't have a current ActorState, use our own
         *   sayActorFollowing() method to say we've just followed the player
         *   character.
         */
        if(curState == nil)
            sayActorFollowing(oldLoc);
        
        /*  Othewise call the sayFollowing() method on our current ActorState */
        else
            curState.sayFollowing(oldLoc);
    }
    
    /*  
     *   Display a message to say that we've just followed the player character
     *   to a new location from oldLoc. The library provides a default message
     *   but this can be overridded as desired.
     */
    sayActorFollowing(oldLoc)
    {
        /* Create a local variable to use as a message substitution parameter */
        local follower = self;
        gMessageParams(follower);
        
        /* Display our default following message */
        DMsg(follow, '<.p>{The follower} follow{s/ed} behind {me}. ');
    }
    
    
    /* 
     *   In addition to providing a mechanism to allow an actor to follow the
     *   player character around (above) we provide a few methods to enable the
     *   player character to follow an actor (below). We do this by having the
     *   the FOLLOW command set a fuse which, when it is triggered later on the
     *   same turn, attempts to make the player character follow the target
     *   actor either if the target actor has just moved away from the player
     *   character's current location later on the same turn as the FOLLOW
     *   command was issued or if the player character is in the location from
     *   which he last saw the target actor depart, in which case the player
     *   character attempts to traverse the TravelConnector through which s/he
     *   saw the actor depart.
     */
    
    /*   
     *   Set the fuse to enable travel later on the same turn if this actor
     *   travels in the meantime. This method is called when a FOLLOW command is
     *   issed with this actor as its direct object.
     */
    setFollowMeFuse()
    {
        /* reset the travel info */
        lastTravelInfo = nil;
        
        /* set up a new fuse */ 
        followFuseID = new Fuse(self, &followFuse, 0);
        
        /* give it a low priority so any events that move the actor fire first */
        followFuseID.eventOrder = 100000;
        
        /* 
         *   Suppress the next paragraph break (otherwise we get an unnecessary
         *   blank line after a FOLLOW command)
         */
        "<.p0>";
    }
    
    /* 
     *   A note of our current following fuse, if we have one; this is used by
     *   FollowAgendaItem to check whether the player character is ready to
     *   follow us.
     */
    followFuseID = nil
    
    /*   
     *   This method is executed right at the end of a turn on which the player
     *   has issued a command to follow this actor, and carries out the travel
     *   to follow this actor if the actor has traveled.
     */
    followFuse()
    {
        /* 
         *   If we have information relating to this actor's last travel
         *   movements, then follow this actor.
         */
        if(lastTravelInfo)
        {
                        
            /* Display a message saying that we're following this actor. */
            sayActorFollowingMe(lastTravelInfo[2]);
            
            /* 
             *   Make the following actor travel via the TravelConnector last
             *   traversed by this actor.
             */
            lastTravelInfo[2].travelVia(gActor);
        }
        
        /* Otherwise display a message saying that the actor hasn't moved */
        else
            say(actorStaysPutMsg);
        
        /* Reset the following fuse ID to nil */
        followFuseID = nil;
        
        /* 
         *   If we have a current FollowAgendaItem and it's finished with, note
         *   that we no longer have a current FollowAgendaItem.
         */
        if(followAgendaItem != nil && followAgendaItem.isDone)
            followAgendaItem = nil;
    }

    /* The message to display when another actor follows this one. */
    sayActorFollowingMe(conn)
    {       
        /* 
         *   If we have a current followAgendaItem, let it handle it in the
         *   first instance.
         */
        if(followAgendaItem != nil)
            followAgendaItem.sayDeparting(conn);
        
        /* Otherwise, let the connector handle it. */
        else                
            conn.sayActorFollowing(gActor, self);
    }
    
    followActorMsg = BMsg(follow actor, '{I} follow{s/ed} {1}. ', theName)
    
    /* 
     *   The message to display when this actor doesn't go anywhere when the
     *   player character tries to follow this actor.
     */
    actorStaysPutMsg = BMsg(actor stays put, '{I} wait{s/ed} in vain for {1} to
        go anywhere. ', theName)
    
    
    /* Our currently executing FollowAgendaItem, if we have one. */
    followAgendaItem = nil
    
    /* 
     *   Display a message describing this actor's departure via conn. This
     *   looks a bit circuitous in that this method calls the corresponding
     *   method on the current ActorState, which by default calls our own
     *   sayActorDeparting() method, which in turn calls sayDeparting on the
     *   connector; the idea is to allow customization at any point with the
     *   connector's sayDeparting() method simply providing a fallback to a
     *   colourless default. Note, however, that game code shouldn't normally
     *   override the actor's sayDeparting() method, but should instead
     *   intervene either on the ActorState or on the actor's
     *   sayActorDeparting() method.
     */
    sayDeparting(conn)
    {
        /* If we have a current ActorState, call its sayDeparting() method */
        if(curState != nil)
            curState.sayDeparting(conn);
        
        /* Otherwise, call our own sayActorDeparting() method */
        else
            sayActorDeparting(conn);
    }
    
    /*  
     *   Method to display a message saying that this actor is departing via
     *   conn (a TravelConnector object, which may be a Room as well as a Door
     *   or other kind of connector). Note that the default behaviour of
     *   ActorState.sayDeparting is simply to call this method.
     */
    sayActorDeparting(conn)
    {
        /* 
         *   By default we let the connector describe the departure in a manner
         *   appropriate to the kind of connector it is.
         */
        conn.sayDeparting(self);
    }
    
    /* 
     *   This method is executed when this actor has just followed the player
     *   character to a new location.
     */
    arrivingTurn()
    {
        /* If we have a current ActorState, execute its arrivingTurn() method */
        if(curState != nil)
            curState.arrivingTurn();
        
        /* Otherwise execute our own actorArrivingTurn() method. */
        else
            actorArrivingTurn();
    }
    
    /* 
     *   This method is executed when this actor has just followed the player
     *   character to a new location and there is no current ActorState. By
     *   default we do nothing.
     */
    actorArrivingTurn() { }
        
    /* 
     *   The message to display when the player char sees this actor arriving
     *   after traveling from loc.
     */
    sayArriving(fromLoc)
    {
       /* If we have a current ActorState, call its sayArriving() method */
        if(curState != nil)
            curState.sayArriving(fromLoc);
        
        /* Otherwise, call our own sayActorArriving() method */
        else
            sayActorArriving(fromLoc);   
    }
    
    /* 
     *   Default message to display when the player character sees this actor
     *   arriving. We use a very plain-vanilla message here, since in practice
     *   game code will generally want to override this.
     */
    sayActorArriving(fromLoc)
    {
        local traveler = self;
        gMessageParams(traveler);
        
        DMsg(actor arriving, '{The subj traveler} arrive{s/d} in the area. ');
    }
    
    
    /* 
     *   Make this actor travel via the connector conn and report its departure.
     *   If announceArrival is true (the default) we also announce the actor's
     *   arrival (if it's visible to the player char).
     *
     *   To suppress the default arrival announcement altogether, supply the
     *   second optional parameter as nil. In some cases it may be easier to do
     *   this and supply your own custom arrival message after calling
     *   travelVia() than to juggle with the various sayArriving() methods.
     */     
    travelVia(conn, announceArrival = true)
    {
        local wasSeenLeaving = nil;
        local oldLoc = location;
        
        /* 
         *   If the player character can see this actor, display a message
         *   indicating this player's departure.
         */
        if(Q.canSee(gPlayerChar, self))
        {
            sayDeparting(conn);
            
            /* Note that we were seen leaving. */
            wasSeenLeaving = true;
        }
        
        /* Move this actor via conn. */
        conn.travelVia(self);
        
        if(announceArrival && !wasSeenLeaving && Q.canSee(gPlayerChar, self))
            sayArriving(oldLoc);
    }
       
    /*  
     *   The takeTurn() method is called on every Actor every turn to carry out
     *   a number of housekeeping functions relating to the conversation and
     *   agenda item systems.
     */
    takeTurn()
    {      
        
        /* 
         *   First, if we're the current interlocutor, check that we can
         *   still talk to the player character. If not, make us no longer the
         *   current interlocutor so we don't respond to conversational commands
         *   when we're no longer there.
         */        
        if(gPlayerChar.currentInterlocutor == self && 
           !canTalkTo(gPlayerChar))
        {
            /* Reset the player character's current interlocutor to nil */
            gPlayerChar.currentInterlocutor = nil;
            
            /* 
             *   Reset our active and pending conversation keys so we don't
             *   behave as if we were still in an active conversation node.
             */
            activeKeys = [];
            pendingKeys = [];
            
            /* Terminate the method there; we've done enough for this turn. */
            return;
        }
        
        /*  
         *   Next, if we haven't already conversed this turn, and we have active
         *   conversation keys (meaning that we might be in a Conversation
         *   Node), try executing the NodeContinuationTopic associated with our
         *   current node (this can be used to nudge the player's memory that
         *   we're expecting an answer to a question we've just asked). If we
         *   find one and execute it, end there.
         */
        if(!conversedThisTurn && activeKeys.length > 0 &&
           initiateTopic(nodeObj))
                        return;
        
        
        /* 
         *   Next, if we haven't conversed this turn, try executing our highest
         *   priority AgendaItem, if we have one.
         */
        if(!conversedThisTurn && !executeAgenda)
        {
            /* 
             *   If we haven't conversed this turn and we didn't find an
             *   AgendaItem to execute, then, if we have a current ActorState
             *   that's been mixed in with a Script class (typically some kind
             *   of EventList), execute our current ActorState's curScript
             *   method, provided the player character can see us. This allows
             *   an ActorState to display a series of 'fidget messages' or the
             *   like for an actor who hasn't otherwise done anything this turn.
             */
            if(curState != nil && curState.ofKind(Script) 
               && Q.canSee(gPlayerChar, self))
                curState.doScript();
        }
        
        /* 
         *   If we haven't conversed this term and we're meant to be in
         *   conversation with the player character, increment our boredomCount
         *   by one; this may eventually lead to this actor terminating the
         *   conversation of its own accord.
         */
        if(!conversedThisTurn && gActor.currentInterlocutor == self)        
            boredomCount++;
            
        /*  Otherwise reset the boredomCount to zero */
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

    /* 
     *   Show a list of topics the player character might want to discuss with
     *   this actor. The explicit flag is true if the player has explicitly
     *   requested the topic list via a TOPICS command. The tag parameter can be
     *   a single convKey tag or a list of convKey tags; if tag is nil or 'all'
     *   then we don't restrict the suggestions by tag, otherwise we restrict
     *   the suggestions to those that match the tag (or one of the tags in the
     *   list of tags).
     */
    showSuggestions(explicit = true, tag = (pendingKeys == [] ? suggestionKey
                                            : pendingKeys))
    {
        /* 
         *   Start by creating a list of listable topics (i.e. those topics that
         *   could be reached by a conversational command issued by the player
         *   on the next turn)
         */
        local lst = listableTopics;
        
        /* 
         *   If we have a current ActorState, add its listableTopics to our
         *   list.
         */
        if(curState != nil)
            lst += curState.listableTopics;
        
        /* 
         *   If the tag parameter has been passed as a list, then for each tag
         *   in the list find all the matching TopicEntries, then find the
         *   intersect of all the listable TopicEntries with those that match
         *   all the tags.
         */
        if(dataType(tag) == TypeList)
        {
            /* Create a new empty Vector */
            local vec = new Vector(10);
            
            /* 
             *   Go through each tag in our list, looking it up in our
             *   convKeyTab table and adding all the corresponding TopicEntries
             *   (that match the tag) to our Vector.
             */
            foreach(local t in tag)
            {
                vec.appendUnique(valToList(convKeyTab[t]));
            }
            
            /* 
             *   Restrict our list of TopicEntries to those that are also found
             *   in the Vector of TopicEntries that match one of our tags.
             */
            lst = lst.intersect(vec.toList());    
        }
        
        /* 
         *   Otherwise, if the tag parameter is supplied, use it to provide a
         *   sublist of only those topics with a convKeys property matching the
         *   tag. A tag of 'all' is treated as a special value to allow a
         *   <.suggest all> tag to list all available special topics.
         */
        else if(tag not in (nil, 'all'))
            lst = lst.intersect(valToList(convKeyTab[tag]));
        
        /* 
         *   Use the suggestedTopicLister to show a list of Suggested Topics
         *   from the resulting list (lst).
         */
        suggestedTopicLister.show(lst, explicit);            
        
    }
    
        
     /* 
      *   A Lookup Table holding conversation keys. Entries in this list take
      *   the form tag -> list of TopicEntries that match this tag (e.g. the key
      *   is a convKey tag, expressed as a single-quoted string, and the value
      *   is a list containing TopicEntries whose convKeys property contains
      *   that tag).
      */      
    convKeyTab = nil
    
    /* 
     *   Set the curiosityAroused flag to true for all topic entries with this
     *   convKey. This allows topics to be suggested when and only when the
     *   player character has some reason to be curious about them, even though
     *   they were actually available before.
     */
    arouse(key)
    {
        /* 
         *   First check that we actually have any entries in our convKeyTab
         *   before we attempt to use them.
         */
        if(convKeyTab != nil)
            /* 
             *   If we do then go through every TopicEntry that has key amongst
             *   its convKeys (which we can obtain by looking up the list of suh
             *   TopicEntries in our convKeysTab) and set its curiosityAroused
             *   property to true.
             */
            foreach(local cur in valToList(convKeyTab[key]))
        {
            cur.curiosityAroused = true;
        }
    }
    
    /* 
     *   Set the activated flag to true for all topic entries with this convKey.
     *  
     */    
    makeActivated(key)    
    {
        /* 
         *   First check that we actually have any entries in our convKeyTab
         *   before we attempt to use them.
         */
        if(convKeyTab != nil)
        {
            /* 
             *   If we do then go through every TopicEntry that has key amongst
             *   its convKeys (which we can obtain by looking up the list of suh
             *   TopicEntries in our convKeysTab) and set its activated property
             *   to true.
             */
            foreach(local cur in valToList(convKeyTab[key]))
                cur.activate();
        }
    }
    
    
    /* 
     *   Set the activated flag to nil for all topic entries with this convKey.
     *  
     */    
    makeDeactivated(key)    
    {
        /* 
         *   First check that we actually have any entries in our convKeyTab
         *   before we attempt to use them.
         */
        if(convKeyTab != nil)
        {
            /* 
             *   If we do then go through every TopicEntry that has key amongst
             *   its convKeys (which we can obtain by looking up the list of suh
             *   TopicEntries in our convKeysTab) and set its activated property
             *   to nil.
             */
            foreach(local cur in valToList(convKeyTab[key]))
                cur.deactivate();
        }
    }
    
    /* 
     *   We supply a getActor method that returns self so that objects such as
     *   TopicEntries that may be located either directly or indirectly in us
     *   can get at their associated actor by simply calling getActor on their
     *   immediate location; at some point such a chain of calls to
     *   location.getActor will end here.
     */    
    getActor { return self; }
    
    /*   
     *   The count of how many turns have passed during which no conversation
     *   has actually taken place when we're the player charater's current
     *   interlocutor. This can be used to terminate the conversation through
     *   'boredom' if the boredomCount exceeds our attention span.
     */
    boredomCount = 0
    
    
    /*  
     *   The maximum value that our boredomCount can reach before we terminate a
     *   conversation through 'boredom', because we've given up waiting for the
     *   player character to say anything. A value of nil (the default) meanns
     *   that we never terminate a conversation for this reason.
     */
    attentionSpan = nil
    
    /* Our look up table for things we've been informed about */    
    informedNameTab = nil
    
    
    /* 
     *   Note that we've been informed of something, by adding it to our
     *   informedNameTab. Tag is an arbitrary single-quoted string value used to
     *   represent the information in question.
     */    
    setInformed(tag)
    {
        if(informedNameTab == nil)
            informedNameTab = new LookupTable(32, 32);
        
        informedNameTab[tag] = true;
    }
    
    /* 
     *   Determine whether this actor has been informed about tag. We return
     *   true if there is a corresponding non-nil entry in our informedNameTab
     */
    informedAbout(tag) 
    {        
        return informedNameTab == nil ? nil : informedNameTab[tag] != nil;     
    }
    
    /*  
     *   Should other actors who can notionally hear the PC talking to us
     *   overhear when information is imparted to us? I.e. should their
     *   setInform() methods be called too? If we have a curState we use its
     *   setting, otherwise we use the value of actorInformOverheard.
     */
    informOverheard = (curState == nil ? actorInformOverheard :
    curState.informOverheard)
    
    /*  
     *   Should other actors who can notionally hear the PC talking to us
     *   overhear when information is imparted to us when our current ActorState
     *   is nil? By default they should.
     */
    actorInformOverheard =  true


    /* 
     *   Say hello to the actor (when the greetin is initiated by the player
     *   character)
     */
    sayHello()
    {
        /* 
         *   Only carry out the  full greeting if we're not already the player
         *   character's current interlocutor.
         */
        if(gPlayerChar.currentInterlocutor != self)
        {
            /* 
             *   Note that we are now the player character's current
             *   interlocutor
             */
            gPlayerChar.currentInterlocutor = self;
            
            /*  Look for an appropriate HelloTopic to handle the greeting. */
            handleTopic(&miscTopics, [helloTopicObj], &noResponseMsg);
        }
        
        /* Add a paragraph break */
        "<.p>";
        
        /* Display a list of not-explicitly-asked-for topic suggestions */
        showSuggestions(nil, suggestionKey);
    }
    
    /* Have the actor greet the player character on the actor's initiative */
    actorSayHello()    
    {
        /* 
         *   First check that we're not already the player character's current
         *   interlocutor before issuing a greeting.
         */
        if(gPlayerChar.currentInterlocutor != self)
        {
            /* 
             *   Note that we have conversed with the player character on this
             *   turn.
             */
            noteConversed();
            
            /*  
             *   Find an appropriate ActorHelloTopic to handle the greeting; if
             *   we don't find one, use our nilResponse (i.e., don't display
             *   anything)
             */
            return handleTopic(&miscTopics, [actorHelloTopicObj], &nilResponse);
        }       
        
        /* Return nil to signal we didn't actually do anything */
        return nil;
    }
    
    /* 
     *   Say goodbye to this actor (farewell from the player character). The
     *   optional reason parameter is the reason we're saying goodbye, which
     *   defaults to endConvBye (i.e. the player character saying goodbye)
     */
    sayGoodbye(reason = endConvBye)
    {
        /* 
         *   If we've not the player character's current interlocutor and the
         *   player character tries to say goodbye to us, display a message
         *   saying that the player character isn't talking to us.
         */
        if(gPlayerChar.currentInterlocutor != self && reason == endConvBye)
        {
            DMsg(not interlocutor, '{I}{\'m} not talking to {1}. ', theName);
        }        
        else
        {
            /* 
             *   Otherwise find the appropriate kind of ByeTopic to handle the
             *   farewell, which will vary according to the reason for the
             *   farewell.
             */
            handleTopic(&miscTopics, [reason], 
                        reason == endConvBye ? &noResponseMsg : &nilResponse);
            
            /* 
             *   Then note that we are no longer in conversation with the player
             *   character.
             */
            gPlayerChar.currentInterlocutor = nil;
        }
    }
    
    /* Do nothing if we can't fine a suitable Hello or Bye Topic/ */    
    nilResponse() { }
    
    /* 
     *   A list of all the ActorStates associated with this Actor; this is
     *   populated by the preinitialization of the individual ActorStates.
     */
    allStates = []
    
    /* 
     *   Is this actor ready to invoke a ConvAgendaItem? We're ready if we
     *   haven't conversed this term and we can speak to the other actor and
     *   we're not at a conversation node. This method is used by the isReady
     *   property of ConvAgendaItem (to save it having to make three separate
     *   calls to getActor).
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
    
    /*  
     *   Remove an agenda Item both from this actor and from any associated
     *   DefaultAgendaTopics directly within this actor.
     */
    removeFromBothAgendas([lst])
    {
        removeFromAgenda(lst...);
        if(defaultAgendaTopic != nil)
            defaultAgendaTopic.removeFromAgenda(lst...);
    }
    
    /*  
     *   Remove an agenda Item both from this actor and from any associated
     *   DefaultAgendaTopics directly within this actor or in any of its
     *   ActorStates.
     */
    removeFromAllAgendas([lst])
    {
        removeFromBothAgendas(lst...);
        foreach(local state in allStates)
        {
            if(state.defaultAgendaTopic != nil)
                state.defaultAgendaTopic.removeFromAgenda(lst...);
        }      
    }
    
    /* 
     *   Remove an agenda item from myself and from any DefaultAgendaTopios
     *   directly in me or in my current ActorState.
     */
    removeFromCurAgendas([lst])
    {
        removeFromBothAgendas(lst...);
        if(curState != nil && curState.defaultAgendaTopic != nil)
            curState.defaultAgendaTopic.removeFromAgenda(lst...);
    }
    
    /* 
     *   A list of agenda items to be added to our agenda at some later point.
     *   The main purpose is to allow game code to set up a list of AgendaItems
     *   (typically ConvAgendaItems) that become part of the actor's current
     *   agenda when conversation is initiated via a HelloTopic.
     */    
    pendingAgendaList = []
    
    /* Add an item to our pending agenda list */    
    addToPendingAgenda([lst])
    {
        foreach(local item in lst)
            pendingAgendaList += item;
    }
    
    /* 
     *   Make our pending agenda items acting by moving them all from our
     *   pendingAgendaList to all our actual agenda lists (on the actor and on
     *   all our DefaultAgendaItems).
     */
    activatePendingAgenda()
    {
        foreach(local cur in pendingAgendaList)
            addToAllAgendas(cur);
        
        pendingAgendaList = [];
    }
    
    /*  Remove one or more agenda items from our pending agenda */
    removeFromPendingAgenda([lst])
    {
        foreach(local item in lst)
            pendingAgendaList -= item;
    }
      
    
    /*  
     *   Respond to an InitiateTopic triggered on this actor with top as the
     *   matching object
     */
    initiateTopic(top)
    {        
        /* 
         *   Try our current actor state first, if we have one, and only if it
         *   fails to find a response try handling the initiateTopic on the
         *   actor.
         */
        if(curState != nil && curState.initiateTopic(top))
            return true;
        
        return inherited(top);
    }
    
    /* 
     *   The notifyRemove() method is triggered when actionMoveInto() tries to
     *   move an object that's located within this actor. By default we don't
     *   allow it since it typically represents an attempt by the player
     *   character to take something from this actor's inventory.
     */
    notifyRemove(obj)
    {
        /* 
         *   If we're not the actor initiating the moving of obj and we don't
         *   allow this object to be removed from us, prevent the move.
         */
        if(gActor != self && !allowOtherActorToTake(obj))
        {            
            /* Display a message saying that removing obj is disallowed. */
            say(cannotTakeFromActorMsg(obj));
            
            /* Halt the action. */
            exit;
        }    
    }
    
    /* 
     *   Return a message saying that the actor cannot take obj from our
     *   inventory.
     */
    cannotTakeFromActorMsg(obj)
    {
        /* 
         *   Set up a convenient pair of message substitution parameters to use
         *   in the mesage.
         */
        local this = self;
        gMessageParams(obj, this);
        
        /* Return the text of the message. */
        return BMsg(cannot take from actor, '{The subj this} {won\'t} let {me}
            have {the obj} while {he obj}{\'s} in {her this} possession. ');
    }
    
    /* 
     *   Is another actor allowed to take obj from our inventory? By default we
     *   return nil to disallow it for all objects.
     */
    allowOtherActorToTake(obj) { return nil; }
    
    /* An actor generally owns its contents */
    ownsContents = true
    
    /* 
     *   This definition is needed for the TopicGroup implementation, and should
     *   not normally be overridden in user game code. It allows TopicEntries
     *   and TopicGroups to determine their own active status by reference to
     *   that of their immediate location.
     */
    active = true
    
    /*
     *   ***********************************************************************
     *   ACTION HANDLING
     *****************************************************************/
         
    /* In general we can talk to actors */
    canTalkToMe = true
    
    dobjFor(TalkTo)
    {  
        action()
        {
            sayHello();
        }
    }
    
    dobjFor(AskAbout)
    {     
        action()
        {
            handleTopic(&askTopics, gIobj.topicList);
        }
    }
    
    dobjFor(AskFor)
    {     
        action()
        {
            handleTopic(&askForTopics, gIobj.topicList);
        }
    }
    
    dobjFor(TellAbout)
    {
        action()
        {
            handleTopic(&tellTopics, gIobj.topicList);
        }
    }
    
    dobjFor(TalkAbout)
    {        
        action()
        {
            handleTopic(&talkTopics, gIobj.topicList);
        }
    }
    
       
    
    dobjFor(SayTo)
    {        
        action()
        {
            handleTopic(&sayTopics, gIobj.topicList);
        }
    }
    
    dobjFor(QueryAbout)
    {        
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
    shouldNotKissMsg = BMsg(should not kiss, 'That hardly {dummy} seem{s/ed}
        appropriate. ')
    
    /*   
     *   The default response of the actor to an attempt to kiss him/her/it
     *   where this is not handled anywhere else, but allowKiss is true.
     */
    kissResponseMsg = BMsg(kiss response, '{The subj dobj} {doesn\'t like[d]}
        that. ')
    
    dobjFor(Kiss)
    {
        verify() 
        {
            if(!allowKiss)
                implausible(shouldNotKissMsg);
        }
                
        
        action()
        {
            handleTopic(&miscTopics, [kissTopicObj], &kissResponseMsg);
        }
    
    }
    
    /* 
     *   By default it's normally possible to attack an actor, even if we don't
     *   want to allow it. Game code might want to override this to nil for
     *   actors it's obviously futile to try attacking, such as ghosts, gods and
     *   giants.
     */
    isAttackable = true
    
     /* 
      *   By default we'll respond to ATTACK ACTOR with the shouldNotAttackMsg;
      *   to enable responses to ATTACK via HitTopics (or some other custom
      *   handling in the action stage) set allowAttack to true.
      *
      *   Leave allowAttack at nil for actors the player character will never
      *   want to attack (because their friendly or harmless, for instance) and
      *   for which the refusal to attack message will never vary. Override
      *   allowAttack to true for actor the player character may want to attack
      *   under some circumstances, or where the response to ATTACKing this
      *   actor might vary.
      */       
    allowAttack = nil
    
    /* The message to display if allowAttack is nil */
    shouldNotAttackMsg = BMsg(should not attack, 'That hardly {dummy} seem{s/ed}
        appropriate. ')
    
    
    
    dobjFor(Attack)
    {       
        
        verify()  
        {
            if(!allowAttack)
                implausible(shouldNotAttackMsg);
        }
        
        action()
        {
            handleTopic(&miscTopics, [hitTopicObj], &shouldNotAttackMsg);
        }
    
    }
    
    dobjFor(AttackWith) asDobjFor(Attack)
    
    iobjFor(GiveTo)
    {        
        action()
        {
            handleTopic(&giveTopics, [gDobj]);
        }
    }
    
    iobjFor(ShowTo)
    {        
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
            /* 
             *   First check whether the throw is possible by checking with the
             *   Query object. This will normally only be relevant if the target
             *   actor is in a location remote from that of the thrower. If the
             *   Q object rules out the throw, move the direct object to the
             *   thrower's room and display a message saying the object fell
             *   short.
             */
            if(!Q.canThrowTo(gActor, self))
            {
                gDobj.moveInto(gActor.getOutermostRoom);
                say(throwFallsShortMsg);
                
            }            
            
            /* 
             *   Otherwise if this Actor can catch Dobj when it's thrown, move
             *   the direct object into this Actor and display an appropriate
             *   message.
             */
            else if(canCatchThrown(gDobj))
            {
                gDobj.moveInto(self);
                sayActorCatches(gDobj);
            }
            
            /* 
             *   Otherwise move the direct object into this actor's location and
             *   display a message saying that the actor dropped the catch.
             */
            else
            {
                gDobj.moveInto(location);
                sayActorDropsCatch(gDobj);   
            }
        }       
    }
    
    /* Display a message saying that this actor catches obj */
    sayActorCatches(obj)
    {
        gMessageParams(obj);
        DMsg(catch okay, '{The subj iobj} {catches} {the obj}. ');
    }
    
    /* Display a message saying that this actor failst to catch obj */
    sayActorDropsCatch(obj)
    {
        gMessageParams(obj);
        DMsg(drop catch, '{The subj iobj} fail{s/ed} to catch {the obj},
            so that {he obj} land{s/ed} on the ground instead. ');
    }
    
    dobjFor(Follow)
    {
        preCond = []
        
        verify()
        {
            /* 
             *   If the player character can see the actor s/he wants to follow,
             *   and they're in the same qocation then following the target is
             *   logical.
             */
            if(Q.canSee(gActor, self) && isIn(gActor.getOutermostRoom))
                logical;
            
            /*   But we can't follow an actor we can see in a remote location */
            else if(Q.canSee(gActor, self))
                illogicalNow(cantFollowFromHereMsg);
            
            /*  And we can't follow the actor if we don't know where it went */
            else if(lastTravelInfo == nil)
                illogicalNow(dontKnowWhereGoneMsg);
            
            /*  
             *   And we can't follow the actor if we're not in the location we
             *   last saw it depart from.
             */
            else if(!gActor.isIn(lastTravelInfo[1]))
                illogicalNow(cantStartFromHereMsg);
        }
        
        action()
        {
            /* 
             *   If we can see the actor we want to follow, then set the
             *   following Fuse (to fire at the end of this turn so we can
             *   follow the actor if it moves on this turn)
             */
            if(Q.canSee(gActor, self))
            {
                setFollowMeFuse();
            }
            
            /* 
             *   Otherwise use our stored travel information to try to follow
             *   this actor.
             */
            else if(lastTravelInfo)
            {
                /* Display a message to say we're following this actor */
                sayHeadAfterActor(lastTravelInfo[2]);
                
                /* 
                 *   Then travel via the connector this actor was seen to leave
                 *   by.
                 */
                lastTravelInfo[2].travelVia(gActor);
                
                /* 
                 *   reset the lastTravelInfo now that it's been used and is no
                 *   longer relevant.
                 */
                lastTravelInfo = nil;
            }
        }
        
    }
   
    sayHeadAfterActor(conn)
    {
        DMsg(say head after actor, '{I} head{s/ed} off {1} after {2}. ',
             conn.traversalMsg, theName);
    }
    
    waitToSeeMsg = BMsg(wait to see, '{I} wait{s/ed} to see where {he dobj}
        {goes}. ')
     

    dontKnowWhereGoneMsg = BMsg(dont know where gone, '{I} {don\'t know} where
        {the subj dobj} {has} gone. ')
    cantStartFromHereMsg = BMsg(cannot start from here, '{I}{\'m} not where {i}
        last saw {the dobj}. ')
    cantFollowFromHereMsg = BMsg(cannot follow from here, '{I} {can\'t} follow
        {him dobj} from {here}. ')
;

/*  
 *   An ActorState represents a state (possibly one of many) an actor can be in
 *   or get into. This can control how the actor is described and the actor's
 *   response to certain conversational commands and other actions.
 *
 *   ActorStates should always be located directly in the Actor to which they
 *   belong.
 */

class ActorState: ActorTopicDatabase
    
    /* 
     *   The stateDesc from the actor's current ActorState is appended to the
     *   desc defined on the actor when the actor is described via an EXAMINE
     *   command.
     */
    stateDesc = nil
    
    /*   
     *   The specialDesc from the actor's current ActorState is used as the
     *   specialDesc for that actor in a room listing.
     */
    specialDesc = nil
    
    /*   
     *   If our associated actor is viewed from a remote location, use the
     *   ActorState's remoteSpecialDesc to describe the actor in a room listing.
     *   By default we just use the specialDesc.
     */    
    remoteSpecialDesc(pov) { specialDesc; }
    
    
    /*   
     *   Set isInitState to true if you want this ActorState to be the one the
     *   associated Actor starts out in.
     */
    isInitState = nil
    
    
    /*   Initialize this ActorState (this is actually called at preinit). */
    initializeActorState()
    {
        /* 
         *   If we're our Actor's initial state and we have a location (our
         *   associated actor) set out location's (i.e. our actor's) current
         *   state to this ActorState
         */
        if(isInitState && location != nil)
            location.curState = self;
        
        /*   
         *   Initialize our getActor property from the getActor property of our
         *   location, which should simply return our associated actor. This
         *   should normally never change at run-time.
         */
        getActor = location.getActor;
        
        /*   Add this ActorState to our actor's list of ActorStates */
        addToActor();
               
    }
    
    /*   Add this ActorState to our actor's list of ActorStates */
    addToActor()
    {
        /* 
         *   First convert our actor's allStates property to an empty list if
         *   it's still nil
         */
        if(getActor.allStates == nil)
            getActor.allStates = [];
        
        /*   Then add ourself to our actor's list of all its ActorStates */
        getActor.allStates += self;
    }
    
    /*  
     *   The afterAction() method is called on an actor's current ActorState
     *   when the actor is in scope for the action that's just taken place. This
     *   allows game code to define state-specific reactions.
     */
    afterAction() {}
    
    
    /*  
     *   The beforeAction() method is called on an actor's current ActorState
     *   when the actor is in scope for the action that's just about to take
     *   place. This allows game code to define state-specific reactions.
     */
    beforeAction() {}
    
    /*  
     *   Display a message saying that we're following the player character from
     *   oldLoc when our actor is in this ActorState (and the actor is following
     *   the player character)
     */
    sayFollowing(oldLoc)
    {
        /* Create a convenient message substitution parameter */
        local follower = getActor;
        gMessageParams(follower);
        
        /* Display the message */
        DMsg(state follow, '{The follower} follow{s/ed} behind {me}. ');
    }
    
    /*  
     *   Display a message saying that our associated actor is departing via
     *   conn. By default we simply use our actor's sayActorDeparting(conn)
     *   method.
     */
    sayDeparting(conn) { getActor.sayActorDeparting(conn); }
    
    /* 
     *   The message to display when the player char sees this actor arriving
     *   after traveling from loc. By default we simply use our actor's
     *   sayActorArriving(fromLoc) method.
     */
    sayArriving(fromLoc) { getActor.sayActorArriving(fromLoc); }
    
    
    /*   
     *   Our associated actor. This is set to our location at preinit by our
     *   initializeActorState method.
     */
    getActor = nil
    
    
    /*   
     *   Our actor's attention span while our actor is in this ActorState. This
     *   is the number of turns the actor will wait for the player character to
     *   say something when a our actor is the player character's current
     *   conversation partner, before our actor gives up on the conversation and
     *   terminates it through 'boredom'. A value of nil (the default) means our
     *   actor is infinitely patient and will never terminate a conversation for
     *   this reason.
     */
    attentionSpan = nil
    
    /* 
     *   the arrivingTurn method is executed when an actor in this state has
     *   just followed the player char to a new location.
     */    
    arrivingTurn() { }
    
    
    
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
    
    
    /* 
     *   The beforeTravel notification triggered when the Actor is in this
     *   ActorState and traveler is just about to travel via connector. By
     *   default we do nothing.
     */
    beforeTravel(traveler, connector) {}
        
    /* 
     *   The afterTravel notification triggered when the Actor is in this
     *   ActorState and traveler has just traveled via connector. By default we
     *   do nothing.
     */
    afterTravel(traveler, connector) {}
    
    
    /*   
     *   Determine whether our actor will allow a current conversation to be
     *   terminated for reason when in this ActorState. Return true to allow the
     *   conversation to be terminated and nil otherwise. By default we simply
     *   return true. If we return nil we should also display a message
     *   explaining why we're not allowing the conversation to end.
     */
    canEndConversation(reason) { return true; }
    
    /*   
     *   The active property is used by any TopicGroups and TopicEntries located
     *   directly within us to determine whether they in turn are active.
     *   Normally there is no reason for game code to override this on an
     *   ActorState; the property is simply provided so that TopicGroups and
     *   TopicEntries can call location.active regardless of whether they're
     *   located in TopicGroups, ActorStates or Actors.
     */    
    active = (location.active)
   
    /* 
     *   The getBestMatch() method is already defined on TopicDatabase, from
     *   which ActorState inherits via ActorTopicDatabase. ActorState overrides
     *   it to allow certain modifications particular to ActorState, such as the
     *   possibility that the prop parameter might be passed as either a list or
     *   a property pointer to a list property, and the need to take into
     *   account the actor's activeKeys list.
     */    
    getBestMatch(prop, requestedList)
    {
        
        local myList;
        
        /* 
         *   In the implementation of the conversation system, prop should be
         *   passed as a property pointer, but in the base TopicDatabase class
         *   the corresponding parameter is a list, so check what we have before
         *   we deal with it.
         *
         *   If prop has been passed as a property pointer, get our list from
         *   the corresponding property.
         */        
        if(dataType(prop) == TypeProp)        
            myList = self.(prop);
        
        /*  Otherwise get our list directely from the prop parameter. */
        else
            myList = valToList(prop);
        
        /* 
         *   If we have a current activeKeys list restrict the choice of topic
         *   entries to those whose convkeys overlap with it, at least at a
         *   first attempt. If that doesn't produce a match, try the normal
         *   handling. We need to do this first to ensure that we prioritize
         *   TopicEntries whose convKeys match our actor's activeKeys (which is
         *   the whole point of our actor having activeKeys).
         */
        
        if(getActor.activeKeys.length > 0)
        {
            /* 
             *   Obtain a list that is that subset of our original list where
             *   the convKeys of the TopicEntries in the list overlaps with our
             *   actor's active keys (i.e. at this stage we only want to
             *   consider TopicEntries selected by our actor's active keys)
             */
            local kList = myList.subset({x:
                                   valToList(x.convKeys).overlapsWith(getActor.activeKeys)});
            
            /*   
             *   Now find the best match that results from using the inherited
             *   handling with our restricted list
             */
            local match = inherited(kList, requestedList);
            
            /*   If we found a suitable match, return it. */
            if(match != nil)
                return match;
            
            /* 
             *   If we didn't find a match in the current state that overlaps
             *   with activeKeys, try finding one in the actor. (Not doing this
             *   would break the Conversation Nodes mechanism, quite apart from
             *   anything else). Note we can only do this is prop has been
             *   passed as a property pointer, as the method expects.
             */            
            if(dataType(prop) == TypeProp)
            {
                /* 
                 *   If prop was passed as a property pointer, obtain the list
                 *   from the corresponding property on our actor (if it wasn't
                 *   there's no need to do anything since we're already stored
                 *   it as a list)
                 */
                myList = getActor.(prop);
                
                /*   
                 *   Obtain that subset of our list that contains TopicEntries
                 *   whose convKeys overlap with our actor's activeKeys
                 .*/
                kList = myList.subset({x:
                                      valToList(x.convKeys).overlapsWith(getActor.activeKeys)});
                
                /*  
                 *   Try to find a best match using the inherited handling with
                 *   our new sub-list.
                 */
                match = inherited(kList, requestedList);
                
                /*  If we found a suitable match, return it. */
                if(match != nil)
                    return match;
                
                /* 
                 *   Restore the list to this ActorState's list of relevant
                 *   TopicEntries
                 */
                myList = self.(prop);
            }
        }
      
        /* 
         *   If we haven't found a match corresponding to our actor's
         *   activeKeys, or if our actor doesn't have any activeKeys, simply
         *   return the result of the inherited handling.
         */
        return inherited(myList, requestedList);
    }
    
    /*  
     *   Should other actors who can notionally hear the PC talking to us
     *   overhear when information is imparted to us and we're in this
     *   ActorState? I.e. should their setInform() methods be called too? By
     *   default they should.
     */
    informOverheard = true
;

/*  
 *   A TopicDatabase is an object that can contain TopicEntries and return the
 *   best match on request. ActorTopicDatabase is a specialization of
 *   TopicDatabase for use with the conversation system, and is used as a mix-in
 *   class in the list of classes from which Actor and ActorState inherit.
 */
class ActorTopicDatabase: TopicDatabase
       
    /* 
     *   The various lists of TopicEntries located within this TopicDatabase.
     *   For exampel the askTopics list would contain a list of all our
     *   AskTopics. Note that the same TopicEntry can appear in more than one
     *   list; for example an AskTellTopic would appear in both the askTopics
     *   list and the tellTopics list, and a DefaultAnyTopic would appear in all
     *   the lists apart from initiateTopics.
     */
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
    
    /* 
     *   Return a list of our listable topics, that is the topic entries located
     *   within us that should be included in a topic inventory listing because
     *   they are (a) currently reachable and (b) currently marked for listing.
     *   The resulting list forms part of the list passed to the
     *   suggestedTopicLister.
     */
    listableTopics()
    {
        /* 
         *   Start by creating a list of all the TopicEntries we contain
         *   (excluding InitiateTopics, which are never suggested because
         *   they're never a response to a conversational command).
         */
        local lst = miscTopics + askTopics + tellTopics + sayTopics +
            queryTopics + giveTopics + askForTopics + talkTopics;
        
        /*  Note our actor. */
        local actor = getActor;
        
        /*  Remove any duplicates from our list */
        lst = lst.getUnique();
        
        /*  
         *   Form that subset of our list that contains TopicEntries that are
         *   actually listable. These are TopicEntries that meet all of the
         *   following conditions:
         
         *. 1) They define a name property (used to list them)
         *. 2) They are currently active
         *. 3) Their curiosity is not yet satisfied
         *. 4) Their curiosity has been aroused
         *. 5) They are reachable (i.e. they could potentially be triggered
         *   by a player command on the current turn).
         *
         *   Note that we deliberately leave the reachability test to last as it
         *   is the most computationally demanding.
         */
        lst = lst.subset({x: x.name!= nil && x.active && !x.curiositySatisfied 
                        && x.curiosityAroused && x.isReachable});
        
        /*  
         *   If our actor has any activeKeys, further narrow down our list to
         *   those TopicEntries whose convKeys match (i.e. overlap with) our
         *   actor's activeKeys.
         */
        if(actor.activeKeys.length > 0)
            lst = lst.subset({x: actor.activeKeys.overlapsWith(x.convKeys)});
        
        /* Return the resulting list. */
        return lst;
    }
    
    /* 
     *   Obtain the identify of any DefaultAgendaTopic contained in this
     *   database
     */
    defaultAgendaTopic = static 
                       askTopics.valWhich({x: x.ofKind(DefaultAgendaTopic)})
    
    /*  Handle an InitiateTopic */
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
    
    /* 
     *   Add a topic entry to our database; since a TopicGroup isn't a
     *   TopicDatabase we simply ask our location to add it to its database. We
     *   also modify the convKeys and scoreBoost properties of any items
     *   contained in us according to our own convKeys and scoreBoost
     *   properties.
     */
    addTopic(obj)
    {
        /* Add the topic entry to our enclosing topic database */
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
    
    /*  
     *   A TopicGroup's isActive property can be used to make all the
     *   TopicEntries enclosed within in inactive by being set to nil; if it is
     *   true then the enclosed TopicEntries are active if their own isActive
     *   property is true.
     */
    isActive = true
    
    /* 
     *   This TopicGroup is active if both its own isActive property is true and
     *   its location is active (this allows us to locate TopicGroups within
     *   other TopicGroups, for instance)
     */
    active = (isActive && location.active)
    
    /*  
     *   A list of convKeys that should be added to the convKeys of each of our
     *   TopicEntries.
     */
    convKeys = nil
    
    /*   
     *   A scoreBoost that should be added to the scoreBoost of each of our
     *   TopicEntries.
     */
    scoreBoost = 0
    
    /*   
     *   If we're being used as a conversation node, our node is active when our
     *   own convKeys matches (i.e. overlaps with) that of our actor's
     *   activeKeys.
     */
    nodeActive()
    {
        return valToList(convKeys).overlapsWith(getActor.activeKeys);
    }
    
    /* Our associated actor is our location's associated actor. */
    getActor = (location.getActor)    
;

/* 
 *   A ConvNode is a TopicGroup specialized for use as a ConversationNode; it's
 *   active when its nodeActive property is true.
 */

class ConvNode: TopicGroup
    isActive = nodeActive
;

/* 
 *   An ActorTopicEntry is a specialization of TopicEntry for use with the
 *   conversation system. ActorTopicEntries represent potential responses to
 *   conversational commands like ASK BOB ABOUT LIGHTHOUSE or TELL GEORGE ABOUT
 *   FIRE.
 *
 *   Since ActorTopicEntry inherits from ReplaceRedirector as well as
 *   TopicEntry, its topicResponse() methods can make use of doInstead() and
 *   doNested().
 */
class ActorTopicEntry: ReplaceRedirector, TopicEntry
    
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
     *   first matchObj's theName     */
    
    autoName = nil
    
    /*   
     *   An ActorTopicEntry is conversational (the default) if it results in an
     *   actual conversational exchange. Change this to nil for
     *   ActorTopicEntries that merely report why a conversational exchange did
     *   not take place (e.g. "Bob ignores you" or "You think better of talking
     *   to George about that.")
     */
    isConversational = true
    
    /*  
     *   Normally a conversational command implies a greeting (that is, it
     *   should trigger a greeting if a conversation is not already in process).
     *   This needs to be overridden to nil on ActorTopicEntries that explicitly
     *   handle greetings (HelloTopic and its subclasses) to avoid an infinite
     *   loop.
     */
    impliesGreeting = isConversational
    
    /* 
     *   A string or list of strings defining one or more groups to which this
     *   topic entry belongs. Under certain circumstances an ActorTopicEntry may
     *   be prioritized if its convKeys overlaps with the associated actor's
     *   activeKeys.
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
    
    /* Add this ActorTopicEntry to its associated actor's table of convKeys */
    addToConvKeyTable()   
    {
        /* Note our associated actor. */
        local actor = getActor;
        
        /* If our actor doesn't yet have a convKeyTab, create one */
        if(actor.convKeyTab == nil)
            actor.convKeyTab = new LookupTable;
        
        /*  
         *   Go through every key in our convKeys list and add this
         *   ActorTopicEntry to the list of ActorTopicEntries that correspond to
         *   it in our actor's convKeyList.
         */
        foreach(local k in valToList(convKeys))
        {
            /* Obtain the existing value corresponding to this key */
            local val = actor.convKeyTab[k];
            
            /* 
             *   Make sure the value is a list, and then add this
             *   ActorTopicEntry to it before storing it in the table.
             */
            actor.convKeyTab[k] = valToList(val) + self;
        }
    }
    
    /* Initialize this ActorTopicEntry (this is actually called at preinit) */
    initializeTopicEntry()
    {
        /* Carry out the inherited handling (on TopicEntry) */
        inherited;
        
        /* 
         *   Add this ActorTopicEntry and its associated convKeys to our actor's
         *   convKeyTable
         */
        addToConvKeyTable();
        
        /*  
         *   If our autoname property is true, construct our name (for use in
         *   suggesting this TopicEntry) provided we have something to construct
         *   it from.
         */
        if(autoName && matchObj != nil && name is in (nil, ''))
            buildName();
    }
    
    /* 
     *   Construct the name of this ActorTopicEntry by using the theName
     *   property of our first matchObj.     
     */
    buildName() { name = valToList(matchObj)[1].theName; }
    
    /* Our associated actor is our location's associated actor. */
    getActor = (location.getActor)
    
    /* 
     *   The number of times to suggest this topic entry, if we do suggest it.
     *   By default this is either once (if we're not also an EventList) or the
     *   number of items in our eventList (if we are an EventList). If you want
     *   this topic entry to go on being suggested ad infinitum, set
     *   timesToSuggest to nil.
     */    
    timesToSuggest = static (ofKind(Script) ? eventList.length : 1)
    
    /* 
     *   Assuming this topic entry is ever suggested, it will continue to be
     *   suggested until curiositySatisfied becomes true. By default this occurs
     *   when the topic has been invoked timesToSuggest times. If, however, we
     *   have any keyTopics we'll take our curiosity to be satisfied when our
     *   keyTopics have all been satisfied.
     */
    curiositySatisfied()
    {
        if(keyTopics == nil)
            return( timesToSuggest != nil && timesInvoked >= timesToSuggest);
        else
            return getKeyTopics.length == 0;
    }
    
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
    
    /*   
     *   Handle this topic (if we're the ActorTopicEntry selected to respond to
     *   a conversational command.
     */
    handleTopic()
    {
        /* Increment our timesInvoked counter */            
        timesInvoked++ ;
        
        /* 
         *   If we have a list of keyTopics defined, then we display them as a
         *   list of topic suggestions instead of showing our topicResponse.
         *   This allows one topicEntry to be used as a means of suggesting
         *   other, more specific, topics.
         */
        if(valToList(keyTopics).length > 0)
        {
            /* Show a list of our keyTopics */
            showKeyTopics();
            
            /* 
             *   Throw an abort signal so that showing a list of topics doesn't
             *   count as a player turn.
             */
            abort;
        }
        
        /* Otherwise execute our topicResponse  */
        else
            topicResponse();
    }
        
    /* 
     *   The keyTopios can contain a convKey or a list of convKeys, in which
     *   case when this TopicEntry is triggered instead of responding directly
     *   it will list topic suggestions that correspond to the convKeys defined
     *   here. For example, a TopicEntry that responded to ASK BOB ABOUT
     *   TROUBLES could define a keyTopics property of 'troubles' that triggered
     *   more specific suggestions such as "You could ask when the troubles
     *   started, or what the troubles were, or how the troubles ended",
     *   assuming that these QueryTopics had a convKeys property of 'troubles'
     *
     *   If you want this TopicEntry to display its topicResponse in the normal
     *   way, leave keyTopics as nil.
     */
    keyTopics = nil
    
    /* Show our suggested keyTopics, if keyTopics is defined. */
    showKeyTopics()
    {
        /* 
         *   First construct a list of TopicEntries that match the keys in our
         *   keyTopics.
         */
        local lst = getKeyTopics();
        
        /*   
         *   If the list contains any entries, display the list of suggestions
         *   using the suggestedTopicLister
         */
        if(lst.length > 0)                    
           suggestedTopicLister.show(lst);       
        
        /* 
         *   Otherwise display a message explaining that we've nothing to
         *   discuss on this topic.
         */
        else
            DMsg(nothing to discuss on that topic, '{I} {have} nothing to
                discuss on that topic just {then}. '); 
    }
    
    /* Obtain a list of the TopicEntries that match our keyTopics property. */
    getKeyTopics()
    {
        /* Make a note of our associated actor. */
        local actor = getActor();

        /* Initialize an empty list */
        local lst = [];
        
        /* 
         *   For each key value in our keyTopics list, look up the associated
         *   TopicEntries in our actor's convKeyTab and add them to our list. If
         *   however a key value looks like a <. > tag, output the tag (this
         *   could be use to activate or arouse a group of topics just prior to
         *   suggesting them).
         */
        foreach(local ky in valToList(keyTopics))
        {
            /* 
             *   If this value looks like a control tag, output it straight
             *   away.
             */
            if(ky.startsWith('<.'))
                say(ky.trim);
            
            /* Otherwise add it to our list. */
            else                
                lst += actor.convKeyTab[ky];
        }
        
        /*   
         *   Reduce our list to a subset that only contains those TopicEntries
         *   that (1) are active, (2) don't yet have their curiosity satisfied,
         *   (3) have their curiosity aroused and (4) are reachable (i.e. they
         *   would actually be triggered if the player were to follow the
         *   suggestion).
         */
        lst = lst.subset({t: t.active && !t.curiositySatisfied &&
                         t.curiosityAroused && t.isReachable });
            
        /* Remove any duplicate entries from the list. */
        lst = nilToList(lst).getUnique();
        
        /* Return the list. */
        return lst;
    }
       
    
    /* 
     *   A flag that can be set with an <.activate> tag. It must be true for
     *   this TopicEntry to be active, regardless of the value of isActive. It
     *   starts out true by default, but it can be set to nil on TopicEntries
     *   that you want to start out as inactive subsequently activate via an
     *   activate tag.
     */
    activated = true
    
    
    /* 
     *   Activate this TopicEntry. This would normally be called in game code
     *   via an <.activate> tag. 
     */
    activate() { activated = true; }
    
    /*  
     *   Deactivate this topic. This could typically be used from within the
     *   topicResponse of an ActorTopicEntry you only want to use once (or in
     *   the last entry in a StopEventList of an ActorTopicEntry). It can also
     *   be called via a <.deactivate key> tag in combination with the convKeys.
     */
    deactivate() { activated = nil; }
    
    /* 
     *   This TopicEntry is active if its own isActive property is true and its
     *   activated property is true and if its location is active. This allows
     *   the isActive conditions of individual TopicEntries to be combined with
     *   that of any TopicGroups they're in. This property should not normally
     *   be overridden in game code.
     */
    active = (isActive && activated && location.active)
    
    
    /* 
     *   Determine whether this TopicEntry is currently reachable, i.e. whether
     *   it could be reached if the player asked/told etc. about its matchObj on
     *   the next turn.
     */
    isReachable()
    {
        /* Note our associated actor */
        local actor = getActor;
        
        /* 
         *   If the actor has a current ActorState and we're in a different
         *   ActorState then we're reachable only if we're in the current
         *   ActorState
         */        
        if(actor.curState != nil && location.ofKind(ActorState) 
           && location != actor.curState)
            return nil;
        
                    
        /* 
         *   If we don't have a matchObj assume we're reachable unless certain
         *   conditions apply (e.g. we're blocked by a DefaultTopic).
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
             *   Otherwise, we're reachable if the current actor state doesn't
             *   have a DefaulTopic that might block us, or if our convKeys
             *   overlap with that of the actor's activeKeys
             */
            
            /*   First check if we're reachable by virtue of our convKeys */
            if(valToList(convKeys).overlapsWith(getActor.activeKeys))
                return true;
            
            
            /*   
             *   Then check for a DefaultTopic in the Actor's current ActorState
             */
            foreach(local prop in includeInList)
            {
                if(actor.curState.(prop).indexWhich({ t: t.ofKind(DefaultTopic)
                    }) != nil)
                    return nil;
            }
            
            /* 
             *   There's nothing obvious that makes this TopicEntry unreachable,
             *   so return true to say we are reachable.
             */
            return true;
            
        }
        
        /* 
         *   We're not reachable if the player char doesn't know about our
         *   matchObj         */
        
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
         *   via an ASK ABOUT command, so we want to test whether its the best
         *   response for its matchObj from the askTopic list.
         */
        
        /*   
         *   Find the topic entry list property of our TopicDatabase that would
         *   be searched to find us if the player followed the suggestion to try
         *   us (e.g. if we would be listed as "You could ask about foo" prop
         *   should come out as &askTopics).
         */
        local prop = (suggestAs != nil ? suggestAs.includeInList[1] :
                      includeInList[1]);
        
        /*   
         *   If we'd be sought as a QueryTopic, determine what qType we'd match;
         *   if we can match more than one qType, select our first one for this
         *   exercise.
         */             
        if(prop == &queryTopics)
            gAction.qType = qtype.split('|')[1];
        
        /* 
         *   Try seeing what the best response would be if we asked our actor to
         *   find the best matching TopicEntry for our matchObj in its prop list
         *   (e.g. its askTopics list if prop is &askTopics). If the result is
         *   this TopicEntry, then this TopicEntry is reachable, so return true.
         */
        if(actor.findBestResponse(prop, matchObj) == self)
            return true;
        
        /*   
         *   Otherwise it's not reachable, so return nil. (This might happen if
         *   another matching topic has a higher matchScore, for example).
         */
        return nil;           
            
    }
;


/* 
 *   CommandTopicHelper is a mix-in class for use with CommandTopic and
 *   DefaultCommantTopic to provide some common handling for both. Its base
 *   class LCommandTopicHelper (which provides a method for reconstructing the
 *   text of a command issued to an actor) must be defined in the
 *   language-specific part of the library.
 */
class CommandTopicHelper: LCommandTopicHelper
    handleTopic()
    {
        /* Carry out the inherited handling */
        inherited;
        
        /* 
         *   If this CommandTopic allows the action our actor has been ordered
         *   to carry out to proceed, then execute it
         */
        if(allowAction)
            myAction.exec(gCommand);
    }
    
    /* 
     *   Set this to true to allow the action to proceed as commanded by the
     *   player.
     */
    allowAction = nil
        
    /*   
     *   The action our actor has been ordered to carry out, which will be the
     *   action on the current Command object.
     */
    myAction = (gCommand.action)
;

/*  
 *   A CommandTopic is a TopicEntry that handles a command directed at this
 *   actor (e.g. BOB, JUMP).
 */
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
    
    
    /* 
     *   CommandTopics are included in the commandTopics list of their
     *   ActorTopicDatabase
     */
    includeInList = [&commandTopics]
    
    
;

/* 
 *   A MiscTopic is an ActorTopicEntry that responds not to a conversational
 *   command specifying a separate topic (such as ASK BOB ABOUT FRUIT) but just
 *   to as simple command like YES, NO, HELLO or GOODBYE
 */
class MiscTopic: ActorTopicEntry
    /* 
     *   A MiscTopic isn't matched to a topic in the normal sense, but we
     *   instead pass the routine an obj parameter to determine what particular
     *   kind of MiscTopic (e.g. YesTopic or ByeTopic) we want to match.
     */    
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

/*  
 *   A KissTopic can be used to provide a response to KISS ACTOR, provided that
 *   we have overridden allowKiss to true on the actor object. This allows the
 *   response to Kiss to vary according to ActorState or other conditions in a a
 *   way that can readily be expressed in a declarative programming style
 */
class KissTopic: MiscTopic
    /* 
     *   KissTopics should be included in the miscTopics list of their
     *   TopicDatabase (Actor or ActorState)
     */
    includeInList = [&miscTopics]
    
    /*   A KissTopic matches the kissTopicObj */
    matchObj = kissTopicObj
    
    /*   
     *   A KissTopic is not regarded as conversational, since KISS ACTOR is not
     *   normally treated as a conversational exchange.
     */
    isConversational = nil
    
    /*   Kissing someone should not trigger a greeting */
    impliesGreeting = nil
;

/*  The kissTopicObject is simply an object used for KissTopic to match. */
kissTopicObj: object;


/*  
 *   A HitTopic can be used to respond to HIT ACTOR (or ATTACK ACTOR, etc.),
 *   provided the actor's allowAtack property has been overridden to true
 */
class HitTopic: MiscTopic
    /* 
     *   HitTopics should be included in the miscTopics list of their
     *   TopicDatabase (Actor or ActorState)
     */
    includeInList = [&miscTopics]
    
    /* HitTopics match the hitTopicObj */
    matchObj = hitTopicObj
    
    /* 
     *   Hitting someone is not normally regarded as form of conversational
     *   exchange.
     */
    isConversational = nil
    
    /*  Hitting someone does not trigger a greeting */
    impliesGreeting = nil
;

/* The hitTopicObj exists solely as something for HitTopics to match. */
hitTopicObj: object;

/* A YesTopic is a TopicEntry that responds to YES or SAY YES */
class YesTopic: MiscTopic
    /* YesTopics are included in the miscTopics list of their TopicDatabase */
    includeInList = [&miscTopics]
    
    /* YesTopics match the yesTopicObj */
    matchObj = yesTopicObj
    
    /* 
     *   We give YesTopic a name so that it can be suggested in response to a
     *   request to display a list of suggested topics.
     */
    name = BMsg(say yes, 'say yes')
;

/* A NoTopic is a TopicEntry that responds to NO or SAY NO */
class NoTopic: MiscTopic
    /* NoTopics are included in the miscTopics list of their TopicDatabase */    
    includeInList = [&miscTopics]
    
    /* NoTopics match the noTopicObj */
    matchObj = noTopicObj
    
    /* 
     *   We give NoTopic a name so that it can be suggested in response to a
     *   request to display a list of suggested topics.
     */
    name = BMsg(say no, 'say no')
;

/* A YesNoTopic is a TopicEntry that responds to either YES or NO */
class YesNoTopic: MiscTopic
        /* 
         *   YesNoTopics are included in the miscTopics list of their
         *   TopicDatabase
         */
    includeInList = [&miscTopics]
    
    /* YesNoTopics match the yesTopicObj or the noTopicObj*/
    matchObj = [yesTopicObj, noTopicObj]
    
    /* 
     *   We give YesNoTopic a name so that it can be suggested in response to a
     *   request to display a list of suggested topics.
     */
    name = BMsg(say yes or no, 'say yes or no')
;

/*  
 *   A GreetingTopic is a kind of TopicEntry used in greeting protocols (saying
 *   Hello or Goodbye). Game code will not use this class directly but will
 *   instead use one or more of its subclasses
 */
class GreetingTopic: MiscTopic
    includeInList = [&miscTopics]
    impliesGreeting = nil
    
    /* 
     *   It may be that we want to change to a different actor state when we
     *   begin or end a conversation. If so the changeToState property can be
     *   used to specify which state to change to.
     */
    changeToState = nil
    
    /*   
     *   Handling a GreetingTopic includes the requested state change, if
     *   changeToState is defined
     */
    handleTopic()
    {
        /* 
         *   Carry out the inherited handling and store the result (true or nil
         *   for success or failure)
         */
        local result = inherited();
        
        /*  
         *   If changeToState is not nil, change our actor's current ActorState
         *   accordingly
         */
        if(changeToState != nil)
            getActor.setState(changeToState);        
        
        /* Return the result of the inherited handling. */
        return result;
    }
;

/* 
 *   A HelloTopic is a TopicEntry that handles an explicit greeting (the player
 *   character explicitly saying Hello to this actor). It also handles implicit
 *   greetings (triggered when the player enters a conversational command when a
 *   conversation with this actor is not already going on), unless we have also
 *   defined an ImpHelloTopic, which will then take preference.
 */
class HelloTopic: GreetingTopic    
    /* A HelloTopic matches either helloTopicObj or impHelloTopicObj */
    matchObj = [helloTopicObj, impHelloTopicObj]    
    
    handleTopic()    
    {
        /* 
         *   Activate our actor's pending agenda items at the start of this new
         *   conversation.
         */
        getActor.activatePendingAgenda();
        
        /* Carry out the inherited handling and return the result. */
        return inherited;
    }
;

/* 
 *   An ImpHelloTopic is one that handles an implied greeting; i.e. it is used
 *   to start a conversation when some other conversational command is used
 *   before the conversation is underway.
 */
class ImpHelloTopic: HelloTopic
    /* An ImpHelloTopic matches the impHelloTopicObj only. */
    matchObj = [impHelloTopicObj]
    
    /* 
     *   We give ImpHelloTopic a higher than usual matchScore so that it's used
     *   in preference to a HelloTopic when both are present to match the
     *   impHelloTopicObj.
     */
    matchScore = 150
;

/*
 *   Actor Hello topic - this handles greetings when an NPC initiates the
 *   conversation. 
 */
class ActorHelloTopic: HelloTopic    
    /* An ActorHelloTopic matches the actorHelloTopicObj only. */
    matchObj = [actorHelloTopicObj]
    
    matchScore = 200


    /* 
     *   If we use this as a greeting upon entering a ConvNode, we'll want
     *   to stay in the node afterward
     */
    noteInvocation(fromActor)
    {
        /* Carry out the inherited handling. */
        inherited(fromActor);
        
        /* Issue a constay tag */-
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
    /* 
     *   This most general kind of ByeTopic matches every kind of
     *   conversation-ending object
     */
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
    /* 
     *   The ImpByeTopic matches endConvLeave, endConvBoredom, or endConvActor
     *   (but not endConvBye).
     */
    matchObj = [endConvLeave, endConvBoredom, endConvActor]
    
    /* 
     *   Give ImpByeTopic a high matchScore so that it takes precedence over
     *   ByeTopic when both are present.
     */
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
    /* A BoredByeTopic matches endConvBoredom only */
    matchObj = [endConvBoredom]
    
    /* 
     *   Give BoredByeTopic an even higher matchScore so that it takes
     *   precedence over ImpByeTopic when both are present.
     */
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
    /* A LeaveByeTopic matches endConvLeave only */
    matchObj = [endConvLeave]
    
    /* 
     *   Give LeaveByeTopic an even higher matchScore so that it takes
     *   precedence over ImpByeTopic when both are present.
     */
    matchScore = 300
;

/*
 *   An "actor" goodbye topic.  This handles ONLY goodbyes that happen when
 *   the NPC terminates the conversation of its own volition via
 *   npc.endConversation(). 
 */
class ActorByeTopic: GreetingTopic   
    /* An ActorByeTopic matches endConvActor only */
    matchObj = [endConvActor]
    
    /* 
     *   Give BoredByeTopic an even higher matchScore so that it takes
     *   precedence over ImpByeTopic when both are present.
     */
    matchScore = 300
;

/* a topic for both HELLO and GOODBYE */
class HelloGoodbyeTopic: GreetingTopic    
    /* A HelloGoodbyeTopic matches every kind of hello and endConv object */
    matchObj = [helloTopicObj, impHelloTopicObj,
                 endConvBye, endConvBoredom, endConvLeave,
                 endConvActor]
    
    /* 
     *   We give HelloGoodByeTopic a slightly lower than normal matchScore to
     *   ensure that all the other, more specific, types of HelloTopic and
     *   ByeTopics take precedence over it.
     */
    matchScore = 90
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


/* 
 *   A DefaultTopic is a kind of TopicEntry for use as a fallback when the
 *   player attempts to discuss a topic that game code doesn't explicitly cater
 *   for.
 */
class DefaultTopic: ActorTopicEntry       
    /* A DefaultTopic matches any Thing or Topic or yes or no */
    matchObj = [Thing, Topic, yesTopicObj, noTopicObj]
    
    /* 
     *   A DefaultTopic has a very low matchScore to allow anything more
     *   specific to take precedence.
     */
    matchScore = 1    
;

/* 
 *   A DefaultAnyTopic is a DefaultTopic that can match any kind of
 *   conversational command.
 */
class DefaultAnyTopic: DefaultTopic
    /* 
     *   DefaultAnyTopics are included in all the lists of their TopicDatabase
     *   that contain lists of conversational responses.
     */
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

/* 
 *   A DefaultConversationTopic is a DefaultTopic that matches any strictly
 *   conversational command; it matches everything a DefaultAnyTopic matches
 *   apart from GIVE and SHOW (which don't necessarily imply verbal exchanges)
 */
class DefaultConversationTopic: DefaultTopic
    includeInList = [&sayTopics, &queryTopics, &askTopics, &tellTopics,
        &askForTopics, &talkTopics]
    matchScore = 2
;

/* Default Topic to match ASK ABOUT and TELL ABOUT */
class DefaultAskTellTopic: DefaultTopic
    includeInList = [&askTopics, &tellTopics]
    matchScore = 4    
;

/* Default Topic to match GIVE and SHOW */
class DefaultGiveShowTopic: DefaultTopic
    includeInList = [&giveTopics, &showTopics]
    matchScore = 4
;

/* Default Topic to match ASK ABOUT */
class DefaultAskTopic: DefaultTopic
    includeInList = [&askTopics]
    matchScore = 5
;

/* Default Topic to match TELL (SOMEONE) ABOUT */
class DefaultTellTopic: DefaultTopic
    includeInList = [&tellTopics]
    matchScore = 5
;

/* Default Topic to match TALK ABOUT */
class DefaultTalkTopic: DefaultTopic
    includeInList = [&talkTopics]
    matchScore = 5
;

/* Default Topic to match GIVE (something to someone) */
class DefaultGiveTopic: DefaultTopic 
    includeInList = [&giveTopics]
    matchScore = 5
;

/* Default Topic to match SHOW (something to someone) */
class DefaultShowTopic: DefaultTopic
    includeInList = [&showTopics]
    matchScore = 5
;

/* Default Topic to match ASK (someone) FOR (something) */
class DefaultAskForTopic: DefaultTopic
    includeInList = [&askForTopics]
    matchScore = 5
;

/* Default Topic to match SAY (something) */
class DefaultSayTopic: DefaultTopic
    includeInList = [&sayTopics]
    matchScore = 5
;

/* Default Topic to match ASK (WHO/WHAT/WHY/WHERE/WHEN/HOW/IF) */
class DefaultQueryTopic: DefaultTopic
    includeInList = [&queryTopics]
    matchScore = 5
;

/* Default Topic to match SAY (something) or ASK (WHO/WHAT/WHY etc.) */
class DefaultSayQueryTopic: DefaultTopic
    includeInList = [&sayTopics, &queryTopics]
    matchScore = 4
;

/* DefaultTopic to match SAY (something) OR TELL (someone) ABOUT (something) */
class DefaultSayTellTopic: DefaultTopic
    includeInList = [&sayTopics, &tellTopics]
    matchScore = 4
;

/* 
 *   DefaultTopic to match TELL (someone) ABOUT (something) OR TALK ABOUT
 *   (something)
 */
class DefaultTellTalkTopic: DefaultTopic
    includeInList = [&tellTopics, &talkTopics]
    matchScore = 4
;

/* 
 *   DefaultTopic to match SAY (something) OR TELL (someone) ABOUT (something)
 *   OR TALK ABOUT (something)
 */
class DefaultSayTellTalkTopic: DefaultTopic
    includeInList = [&sayTopics, &tellTopics, &talkTopics]
    matchScore = 3
;

/* Default Topic to match ASK ABOUT/HOW/WHAT/WHY/WHEN/WHO/IF/WHERE etc */
class DefaultAskQueryTopic: DefaultTopic
    includeInList = [&queryTopics, &askTopics]
    matchScore = 4
;

/* 
 *   DefaultTopic to match orders directed to this actor by the player
 *   (character)
 */
class DefaultCommandTopic: CommandTopicHelper, DefaultTopic
    includeInList = [&commandTopics]
    matchScore = 5
    matchObj = [Action]
;

/* A TopicEntry that matches ASK ABOUT */
class AskTopic: ActorTopicEntry
    includeInList = [&askTopics]
;

/* A TopicEntry that matches TELL ABOUT */
class TellTopic: ActorTopicEntry
    includeInList = [&tellTopics]
;

/* A TopicEntry that matches ASK ABOUT or TELL ABOUT*/
class AskTellTopic: ActorTopicEntry
    includeInList = [&askTopics, &tellTopics]
;

/* A TopicEntry that matches ASK FOR */
class AskForTopic: ActorTopicEntry
    includeInList = [&askForTopics]
;

/* A TopicEntry that matches ASK ABOUT or ASK FOR*/
class AskAboutForTopic: ActorTopicEntry
    includeInList = [&askForTopics, &askTopics]
;

/* A TopicEntry that matches GIVE TO */
class GiveTopic: ActorTopicEntry
    includeInList = [&giveTopics]
;

/* A TopicEntry that matches SHOW TO */
class ShowTopic: ActorTopicEntry
    includeInList = [&showTopics]
;

/* A TopicEntry that matches GIVE TO or SHOW TO */
class GiveShowTopic: ActorTopicEntry
    includeInList = [&giveTopics, &showTopics]
;

class TellTalkShowTopic: ActorTopicEntry
    includeInList = [&tellTopics, &talkTopics, &showTopics]   
;

/* 
 *   SpecialTopic is the base class for two kinds of TopicEntry that extend the
 *   conversation system beyong basic ask/tell: SayTopic and QueryTopic. The
 *   SpecialTopic class defines the common handling but is not used directly in
 *   game code, which will use either SayTopic or QueryTopic
 */
class SpecialTopic: ActorTopicEntry
    
    /* 
     *   Carry out the initialization (actually preinitialization) of a
     *   SpecialToipc
     */
    initializeTopicEntry()
    {
        /* First carry out the inherited handling */
        inherited;
        
        
        /* 
         *   if the matchPattern contains a semi-colon assume it's not a regex
         *   match pattern but the vocab for a new Topic object.
         */        
        
        if(matchPattern != nil && (matchPattern.find(';') != nil ||                             
                                   matchPattern.find(rex) == nil))            
        {
            /* 
             *   first see if there's already a Topic that has our matchPattern
             *   as its vocab.
             */            
            matchObj = findMatchingTopic(matchPattern);
            
            /* if we found a matching topic, we're done. */
            if(matchObj != nil)
            {
                /* set the matchPattern to nil, since we shan't be using it. */
                matchPattern = nil;               
            }
            else
            {
                
                /* create a new Topic object using the matchPattern as its vocab */
                matchObj = new Topic(matchPattern);
                
                /* then set the matchPattern to nil, since we shan't be using it. */
                matchPattern = nil;
                
                /* add the new matchObj to the universal scope list */
                World.universalScope += matchObj;
            }
        }
        
        /* 
         *   Although the inherited handling might have built our name property
         *   already, it won't have done if we created our matchObj from our
         *   matchPattern property, so if need be we try building it again here.
         */
        if(autoName)
           buildName();
        
        /* 
         *   It may be we want this SpecialTopic also to respond to a
         *   conventional ASK ABOUT X or TELL ABOUT X. We can do this by
         *   defining the askMatchObj and tellMatchObj properties.
         *
         *   First check if our askMatchObj is non-nil and equal to our
         *   tellMatchObj. If so then we want this SpecialTopic also to behave
         *   like an AskTellTopic that matches askMatchObj. To that end we
         *   create a SlaveTopic to represent the AskTellTopic
         */
        if(askMatchObj != nil && askMatchObj == tellMatchObj)
        {
            new SlaveTopic(askMatchObj, self, [&askTopics, &tellTopics]);            
        }
        
        /* 
         *   Otherwise, if we have an askMatchObj, create a SlaveTopic to
         *   represent us as an AskTopic so that we also match ASK ABOUT
         *   askMatchObj.
         */
        else if(askMatchObj != nil)
            new SlaveTopic(askMatchObj, self, [&askTopics]);
        
        /*   
         *   If we have a tellMatchObj that's different from our askMatchObj
         *   (and non-nil), create a new SlaveTopic to represent a TellTopic
         *   that we also match.
         */
        if(tellMatchObj != nil && tellMatchObj != askMatchObj)
            new SlaveTopic(tellMatchObj, self, [&tellTopics]);
    }
    
    /* 
     *   A Regular expression pattern to look for the kinds of characters we'd
     *   expect to find in our matchPattern property if it actually represents a
     *   regular expression for this TopicEntry to match. We use this to help
     *   determine whether the matchPattern property contains a regex to match
     *   our the vocab of a Topic object to create on the fly.
     */    
    rex = static new RexPattern('<langle|rangle|star|dollar|vbar|percent|carat>')
    
    /* 
     *   If we want this SpecialTopic also to match an ASK ABOUT command, define
     *   the askMatchObj to hold the topic or list of topics that said ASK ABOUT
     *   command should match here.
     */
    askMatchObj = nil
    
    /* 
     *   If we want this SpecialTopic also to match an TELL ABOUT command,
     *   define the askMatchObj to hold the topic or list of topics that said
     *   TELL ABOUT command should match here.
     */
    tellMatchObj = nil
    
    /* 
     *   For a SpeciallTopic make constructing a name property automatically the
     *   default.
     */
    autoName = true;
    
;

/*  
 *   A SlaveTopic is a special kind of TopicEntry created by a SpecialTopic to
 *   function as an AskTopic, TellTopic or AskTellTopic that produces the same
 *   response at the SpecialTopic. Game code would not normally define
 *   SlaveTopics directly
 */
class SlaveTopic: ActorTopicEntry
    
    /* Construct a SlaveTopic */
    construct(matchObj_, masterObj_, includeInList_)
    {
        /* Note the Topic/Object (or objects) this TopicEntry should match. */           
        matchObj = matchObj_;
        
        /* 
         *   Note our masterObj, which will be the SpecialTopic that called our
         *   c constructor.
         */
        masterObj = masterObj_;
        
        /*  Note which list or lists of TopicEntries we should be included in */
        includeInList = includeInList_;
        
        /*  Our location is the same as our masterObj's location. */
        location = masterObj.location;
        
        /* Carry out our initialization as a TopicEntry. */
        initializeTopicEntry();
    }
    
    initializeTopicEntry()
    {
        /* 
         *   Only carry out our initialization if we haven't been initialized
         *   already.
         */
        if(!initialized)
        {
            /* Carry out the inherited handling. */
            inherited();
            
            /* Note that we've now been initialized. */
            initialized = true;
        }
    }
    
    /* 
     *   To handle this topic we simply call the handleTopic method on our
     *   masterObj (i.e. the SpecialTopic that created us)
     */
    handleTopic() { masterObj.handleTopic(); }
    
    /* Our masterObj is the SpecialTopic that created us */
    masterObj = nil
    
    /* Flag: has this SlaveTopic already been initialized. */
    initialized = nil
;

/* 
 *   A QueryTopic is a kind of SpecialTopic that extends the range of questions
 *   that the player (character) can ask an NPC from ASK ABOUT so-and-so to ASK
 *   WHO/WHAT/WHY/WHERE/WHETHER/IF/HOW so-and-so. The type of question to be
 *   matched (who/what/why/when etc.) needs to be defined on a QueryTopic's
 *   qType property (so that it can be matched by the QueryTopic's grammar). The
 *   remainder of the question is the Topic a particular QueryTopic matches.
 */
class QueryTopic: SpecialTopic
    
    /* 
     *   Check whether this QueryTopic matches the question asked. For it to do
     *   so it must match not only the topic but the qType (query type)
     */
    matchTopic(top)
    {
        /* 
         *   A QueryTopic can match more than one query type, so first we split
         *   our qType property into a potential list.
         */
        local qtList = qtype.split('|');
        
        /* 
         *   If the action's qType isn't in our list of qTypes, then we don't
         *   match the question asked, so return nil to indicate a failure to
         *   match.
         */
        if(qtList.indexOf(gAction.qType) == nil)
            return nil;
                
        /* 
         *   Otherwise carry out the inherited handling to see whether we match
         *   the topic (i.e., the rest of the question following the qType word)
         */
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
            /* 
             *   Find the first space in our matchPattern string. This should
             *   mark the end of the first word.
             */
            local idx = matchPattern.find(' ');
            
            /* Only do anything if we find a space */
            if(idx)
            {
                /* 
                 *   Take the qType to be the first word, i.e. the beginning of
                 *   the string up to but not including the first space
                 */
                qtype = matchPattern.substr(1, idx - 1);
                
                /*   
                 *   Take the true matchPattern -- or rather the Topic vocab --
                 *   to be the rest of the matchPattern string following the
                 *   first space.
                 */
                matchPattern = matchPattern.substr(idx + 1).trim();
            }
            
        }
     
        /* Carry out the inherited handling. */
        inherited;    
    }
    
    /* 
     *   When we build the name of a QueryTopic (for use in a list of topic
     *   suggestions) we need to include the query type (qType).
     */
    buildName()
    {
        /* 
         *   Don't attempt to construct the name if we already have one or we
         *   don't have a matchObj.
         */
        if(name == nil && matchObj != nil)
        {
            /* 
             *   Split our qType property into a list of query types, since it
             *   could be specified as several possible types separated by
             *   vertical bars
             */
            local qList = qtype.split('|');
            
            /*   
             *   Prepend the first word from the query type list to the name of
             *   our matchObj to create our name
             */
            name = qList[1] + ' ' + valToList(matchObj)[1].name; 
        }
    }
    
    /* A QueryTopic belongs in the queryTopics list of its TopicDatabase */
    includeInList = [&queryTopics]          
;


/* 
 *   A SayTopic is a kind of SpecialTopic that allows the player (character) to
 *   say virtually anything (within reason) to an NPC; a SayTopic may be
 *   triggered by a command that explicitly begins with SAY, but it may also be
 *   triggered by any combination of words that matches its matchObj and doesn't
 *   correspond to any other recognizable command. This allows the player to
 *   respond, for example, with either SAY YOU DON'T KNOW or just I DON'T KNOW,
 *   to trigger an appropriately defined SayTopic.
 */
class SayTopic: SpecialTopic
   
    /* 
     *   When we construct the name of a SayTopic we use the name property of
     *   its matchObj rather that theName property, since it won't normally make
     *   sense to include the definite article at the beginning of suggestions
     *   of things that can be said.
     */
    buildName()
    {
        /* 
         *   We don't try to construct a name if we have one already or if we
         *   don't have a matchObhj.
         */
        if(name == nil && matchObj != nil)
            /* 
             *   The matchObj property could in principle be specified as a
             *   list, in which case use the first (and possibly omly) item in
             *   the list to construct our name.
             */
            name = valToList(matchObj)[1].name; 
    }

    /* SayTopics belong in the sayTopics list of their TopicDatabase */    
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

/* A TalkTopic is a TopicEntry that responds to TALK ABOUT so-and-so. */
class TalkTopic: ActorTopicEntry
    includeInList = [&talkTopics]
;
    
/* 
 *   A TellTalkTopic is a TopicEntry that responds to TELL ABOUT or TALK ABOUT
 *   so-and-so.
 */
class TellTalkTopic: TalkTopic
    includeInList = [&tellTopics, &talkTopics]
;
 
/* 
 *   An AskTellTalkTopic is a TopicEntry that responds to ASK ABOUT or TELL
 *   ABOUT or TALK ABOUT so-and-so.
 */
class AskTellTalkTopic: TalkTopic
    includeInList = [&askTopics, &tellTopics, &talkTopics]
;

/* 
 *   An AskTalkTopic is a TopicEntry that responds to ASK ABOUT or TALK ABOUT
 *   so-and-so.
 */
class AskTalkTopic: TalkTopic
    includeInList = [&askTopics, &talkTopics]
;


/* 
 *   An initiateTopic is used for conversational topics initiated by the actor
 *   through a call to initiateTopic() on the actor or ActorState
 */
class InitiateTopic: ActorTopicEntry
    includeInList = [&initiateTopics]
;

/* 
 *   A NodeContinuationTopic is aspecial kind of InitiateTopic that can be used
 *   to prompt the player/pc when particular convKeys have been activated. It is
 *   generally used when a Conversation Node is active to remind the player that
 *   the player character's conversation partner is waiting for an answer.
 */

class NodeContinuationTopic: InitiateTopic
    matchObj = nodeObj
    
    /* 
     *   We're only active when one or more of our keys is active (having been
     *   activated through an <.convnode> tag).
     */
    active = (nodeActive && inherited)
    
    /* 
     *   Particular instances must override this property to stipulate which
     *   keys we're active for. (This isn't needed if the NodeContinuationTopic
     *   is located in a ConvNode, since the ConvNode will then take care of
     *   this for us).
     */
    convKeys = nil
    
    handleTopic()
    {
        /* 
         *   We don't want a NodeContinuationTopic to reset the active keys, so
         *   we send a convstay tag to retain them.
         */
        "<.p><.convstay>";
        
        /* Carry out the inherited handling. */
        inherited();
    }
;

/* 
 *   A NodeEndCheck may optionally be assigned to a Conversation Node (as
 *   defined on the convKeys property, or through being located in a ConvNode
 *   object) to decide whether a conversation is allowed to end while it's at
 *   this node. There's no need to define one of these objects for a
 *   conversation node if you're happy for the conversation to be ended during
 *   it under all circumstances.
 */

class NodeEndCheck: InitiateTopic
    matchObj = nodeEndCheckObj
    
    /* 
     *   We're only active when one or more of our keys is active (having been
     *   activated through an <.convnode> tag).
     */
    active = (nodeActive && inherited)
    
    
    /* 
     *   Particular instances must override this property to stipulate which
     *   keys we're active for, unless this NodeEndCheck is located within a
     *   ConvNode object which will take care of this for us. Note that instead
     *   of locating a NodeEndCheck in a particular ConvNode, you can specify
     *   the convKeys for a number of ConvNodes here, and this NodeEndCheck will
     *   then apply to them all.
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
     *   NodeContinuationTopic on this turn.     */
    
    blockEndConv()
    {
        /* Note that the actor has conversed on this turn */
        getActor.noteConversed();
        
        /* 
         *   Return nil to signal that we're not allowing the conversation to
         *   end.
         */
        return nil;
    }
    
;

/* Singleton object to allow initiateTopic to trigger a NodeContinuationTopic */
nodeObj: object;

/* Singleton object to allow initiateTopic to trigger a NodeEndCheck */
nodeEndCheckObj: object;

/* 
 *   Singleton object used to trigger a YesTopic; we must make it familiar so
 *   that YesTopics can be listed as suggested topics.
 */
yesTopicObj: object familiar = true;

/* Singleton object used to trigger a NoTopic */
noTopicObj: object familiar = true;


/* 
 *   Preinitialize all the Actors in the game and the objects associated with
 *   them.
 */
actorPreinit:PreinitObject
    execute()
    {       
        /* Initialize every ActorState defined in the game */
        forEachInstance(ActorState, {a: a.initializeActorState() } );
        
        /* Initialize every ActorTopicEntry definined in the game */
        forEachInstance(ActorTopicEntry, {a: a.initializeTopicEntry() });
        
        /* 
         *   Set up a new Daemon in the game to run our eachTurn method each
         *   turn
         */
        local actorDaemon = new Daemon(self, &eachTurn, 1);
        
        /*   Give the actorDaemon a relatively late running order */
        actorDaemon.eventOrder = 300;
    }
    
    /* 
     *   Make use that various other preinitializations presupposed by our own
     *   have been carried out before ours
     */
    execBeforeMe = [World, libObjectInitializer, pronounPreinit]

    /* 
     *   Our eachTurn method is called every turn by the Daemon set up in out
     *   preinitialization
     */
    eachTurn()
    {
        /* Call the takeTurn() method on every Actor in the game */
        forEachInstance(Actor, {a: a.takeTurn() });
    }
    
;




/* ------------------------------------------------------------------------ */
/*
 *   Conversation manager output filter.  We look for special tags in the output
 *   stream:
 *
 *   <.reveal key> - add 'key' to the knowledge token lookup table.  The 'key'
 *   is an arbitrary string, which we can look up in the table to determine if
 *   the key has even been revealed.  This can be used to make a response
 *   conditional on another response having been displayed, because the key will
 *   only be added to the table when the text containing the <.reveal key>
 *   sequence is displayed.
 *
 *   <.inform key> - add 'key' to our actor's knowledge token lookup take. The
 *   'key' is an arbitrary string, which we can look up in the table to
 *   determine if the actor has ever been informed about this key.  This can be
 *   used to make a response conditional on another response having been
 *   displayed, because the key will only be added to the information table when
 *   the text containing the <.inform key> sequence is displayed.
 *
 *   <.convnode name> - add 'name' to the current list of convKeys (this
 *   actually adds it to the actor's pendingKeys for use on the next turn); this
 *   is normally used to trigger a Conversation Node that's defined to match the
 *   same name.
 *
 *   <.convodet name> does the same as <.convnode name> and additionally
 *   schedules a topic inventory (a listing of suggested topics); this can be
 *   used to ensure that the player knows what conversational options are
 *   available in the node we're about to enter, where this isn't obvious from
 *   the context.
 *
 *   <.convstay> - retain the same list of active keys for the next
 *   conversational response (and thus has the effect of making the conversation
 *   remain in the same conversation node).
 *
 *   <.convstayt> - does the same as <.convstay> but additionally schedules a
 *   topic inventory.
 *
 *   <.topics> - schedule a topic inventory for the end of the turn (just before
 *   the next command prompt)
 *
 *   <.arouse key> Set the curiosityAroused property to true for all
 *   TopicEntries whose convKeys include key
 *
 *   <.suggest key> Schedule a topic inventory for all topic entries whose
 *   convKeys include key.
 *
 *   <.sugkey key> Set our actor's suggestionKey to key (this potentially
 *   restricts the list of topics that will be suggested)
 *
 *   <.activate key> Set the activated property to true for every topic entry
 *   whose convKeys list includes key.
 *
 *   <.agenda item> Add item to the agenda list of our Actor and any associated
 *   DefaultAgendaTopics.
 *
 *   <.remove item> Remove item from the agenda list of our Actor and any
 *   associated DefaultAgendaTopics.
 *
 *   <.state newstate> Change our actor's current ActorState to newstate.
 *
 *   <.known obj> Mark obj (a Thing or Topic) as now being known (i.e. familiar)
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

    /* 
     *   The actor we're dealing with is the player character's current
     *   interlocutor
     */
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
                 *   Leave the responding actor in the old conversation
                 *   node - we don't need to change the ConvNode, but we do
                 *   need to note that we've explicitly set it 
                 */
                if (respondingActor != nil)
                    respondingActor.keepPendingKeys = true;
               
                /* 
                 *   If the tag was 'convnode' we didn't ask for a topic
                 *   inventory, so we need to avoid falling through. If the tag
                 *   was 'convnodet' or 'convstayt' we want a topic inventory
                 *   too, so we fall through to the 'topics' tag.
                 */                
                if(tag is in ('convnodet', 'convstayt') 
                   && respondingActor != nil)                    
                    scheduleTopicInventory(respondingActor.pendingKeys);
                    
                 break;

            case 'topics':
                /* schedule a topic inventory listing */
                if (respondingActor != nil)
                    scheduleTopicInventory(respondingActor.pendingKeys == [] ? 
                                           respondingActor.suggestionKey
                                           : respondingActor.pendingKeys);
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
                
                /* 
                 *   If we have a responding actor, schedule a topic inventory
                 *   for topic entries that match arg
                 */
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
                
            case 'deactivate':
                /* 
                 *   Set the activated property to true for all Topic Entries
                 *   with the appropriate key.
                 */
                if (respondingActor != nil)
                    respondingActor.makeDeactivated(arg);
                break;
                
            case 'agenda':
                /* add an agenda item to all relevant objects */
                
                /* 
                 *   Obtain the object corresponding to arg (a string value)
                 *   from our object name table
                 */
                obj = objNameTab[arg];
                
                /* 
                 *   If the object we're trying to add to an agenda list isn't
                 *   an AgendaItem belonging to our respondingActor, display an
                 *   error message.
                 */
                if(obj == nil || !obj.ofKind(AgendaItem) || 
                   obj.getActor != respondingActor)
                {
                    showAgendaError(tag, arg);
                }
                else
                    /* 
                     *   Otherwise add the AgendaItem obj to our
                     *   respondingActor's agendaList and that of any associated
                     *   DefaultAgendaTopics
                     */
                    respondingActor.addToAllAgendas(obj);
                break;
                
            case 'remove':
                /* remove an agenda item from all relevant objects */
                
                /* 
                 *   Obtain the object corresponding to arg (a string value)
                 *   from our object name table
                 */
                obj = objNameTab[arg];
                
                /* 
                 *   If the object we're trying to add to an agenda list isn't
                 *   an AgendaItem belonging to our respondingActor, display an
                 *   error message.
                 */
                if(obj == nil || !obj.ofKind(AgendaItem) || 
                   obj.getActor != respondingActor)
                {
                    showAgendaError(tag, arg);
                }
                else
                    /* 
                     *   Otherwise remove the AgendaItem obj from our
                     *   respondingActor's agendaList and that of any associated
                     *   DefaultAgendaTopics
                     */
                    respondingActor.removeFromAllAgendas(obj);
                break;
                
            case 'state':
                /* change ActorState */
                
                /* 
                 *   Obtain the object corresponding to arg (a string value)
                 *   from our object name table
                 */
                obj = objNameTab[arg];
                
                /* Convert a string 'nil' to an actual nil */
                if(arg == 'nil')
                    obj = nil;                
                
                /* 
                 *   Otherwise if the object we're trying to add to an agenda
                 *   list isn't an ActorState belonging to our respondingActor,
                 *   display an error message.
                 */
                else if(obj == nil || !obj.ofKind(ActorState) || 
                   obj.getActor != respondingActor)
                {
                    showStateError(tag, arg);
                }
                else
                    /* 
                     *   Otherwise set our respondingActor's ActorState to the
                     *   new state requested (obj).
                     */
                    respondingActor.setState(obj);
                break;
            
            case 'known':
                /* mark as item as known. */
                
                /* 
                 *   Obtain the object corresponding to arg (a string value)
                 *   from our object name table
                 */
                obj = objNameTab[arg];
                             
                /* 
                 *   If the obj doesn't exist, or it isn't a Mentionable,
                 *   display an error message
                 */
                if(obj == nil || !obj.ofKind(Mentionable))
                {
                    showKnownError(tag, arg);
                }
                else
                    /* 
                     *   Otherwise mark obj as known about by the player
                     *   character
                     */
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
        + '|arouse|suggest|sugkey|convnode|convnodet|convstayt|deactivate)'
        + '(<space>+(<^rangle>+))?'
        + '<rangle>')

	/* Provided we have a respondingActor, call its manageKeys method. */	
    manageKeys()
    {
	   if(respondingActor != nil)
	      respondingActor.manageKeys();
    }	
		
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
        /* Note that our tag has been revealed */
        libGlobal.setRevealed(tag);
        
        /* 
         *   If something has just been revealed to us, it has also just been
         *   revealed to every other actor in the vicinity who could overhear
         *   the conversation (including the actor who has just spoken, if there
         *   is one; if there isn't then the revealed tag is presumably being
         *   used for a non-conversational purpose, so we don't try to inform
         *   any other actors).
         *
         *   Note that we only do this if our respondingActor wants to allow it
         *   through its informOverheard property. If we want to model a private
         *   conversation that other people present don't pick up, we can
         *   override informOverheard on the the current ActorState or
         *   actorInformedOverhead on the Actor.
         */                
        if(respondingActor != nil && respondingActor.informOverheard )
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
        /*
         *   Note that we only do this if our respondingActor wants to allow it
         *   through its informOverheard property. If we want to model a private
         *   conversation that other people present don't pick up, we can
         *   override informOverheard on the the current ActorState or
         *   actorInformedOverhead on the Actor.
         */
        if(respondingActor.informOverheard)
        {
            forEachInstance(Actor, new function(a) {
                if(a != gPlayerChar && Q.canHear(a, gPlayerChar))
                    a.setInformed(tag);
            } );
        }
        
        /* 
         *   If this is a private conversation (informOverheard = nil), just set
         *   the informed tage on our respondingActor alone.
         */
        else
        {
            respondingActor.setInformed(tag);
        }
        
    }
    
    /* 
     *   Display an error message if the game code tries to add or remove agenda
     *   items from an agendaList using a <.agenda item> or <.remove item> tag,
     *   when item doesn't correspond to a valid AgendaItem, but only do so if
     *   the game has been compiled for debugging.
     */
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
    
    
    /* 
     *   Display an error message if the game code tries to change our actor's
     *   ActorState via a <.state newstate> tag, when tag doesn't correspond to
     *   a valid ActorState, but only do so if the game has been compiled for
     *   debugging.
     */
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

    /* 
     *   Display an error message if the game code tries mark an object as known
     *   about using a <.known obj> tag, when obj doesn't correspond to a valid
     *   Mentionable object, but only do so if the game has been compiled for
     *   debugging.
     */
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
    
    /* 
     *   Various supporting routines for displaying error messages that are only
     *   needed if the game has been compiled for debugging
     */
    
 #ifdef __DEBUG   
    /* The object referred to by tag doesn't exist */
    showObjNotExistError(tag, arg, typ)
    {
        "<<typ>> <<arg>> for (actor = <<respondingActor.name>> was not added to
        conversationManager.objNameTab or does not exist. Check that you have
        spelled the <<typ>> <<arg>> name correctly. ";
    }
    
    /* The object referred to by tag is the wrong sort of object */
    showWrongKindofObjectError(tag, arg, typ)
    {
        "<tag> is not <<typ>> so can't be used in a <<tag>> tag (see
        TopicEntries for <<respondingActor.theName>> ";
    }
    
    /* The object referred to by tag doesn't belong to the actor in question */
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
        
        /*  Add ourselves to the list of output filters. */        
        mainOutputStream.addOutputFilter(self);
        
        /* 
         *   Set up the prompt daemon that makes automatic topic inventory
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
 *   AgendaItems */

class AgendaManager: object
    
    /* 
     *   Our agendaList is the list of AgendaItems we're ready to execute when
     *   they're isReady property is true.
     */
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
        
        /* add the item or items. */
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
         *   Keep the list in ascending order of agendaOrder values - this will
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
        /* Note what object we were called from */
        calledBy = caller;
        
        /* Then carry out our invokeItem() method */
        invokeItem();
    }
    
    /* 
     *   invokeItem can test the invokedByActor property to decide whether what
     *   the actor says should be a conversational gambit started on the actor's
     *   own initiative or as a (default) response to something the pc has just
     *   tried to say.     */
    
    invokedByActor = (calledBy == getActor)
    
    /* The object from whose agendaList this AgendaItem was invoked */
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
    
    /* 
     *   A convenience method that can be used from within our invokeItem to
     *   display some text only if the player character can see us (or, if the
     *   optional second parameter is supplied, sense us through some other
     *   sense, e.g. &canHear or &canSmell).
     */
    report(msg, prop=&canSee) { senseSay(msg, getActor, prop); }
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
    
    /* There's more work to do on a ConvAgendaItem when it's invoked */
    invokeItemBase(caller)
    {
        /* 
         *   Note that our actor is in conversation with the otherActor
         *   (normally gPlayerChar) and attempt an actor greeting, if one has
         *   been defined. It's useful to do this here since a ConvAgendaItem
         *   might very well initiate a conversation.
         */        
        local actor = getActor();
        
        /* Set a flag to show why this ConvAgendaItem has just been invoked */
        if(otherActor == gPlayerChar)                    
        {
            /* 
             *   If our actor is not already the player character's current
             *   interlocutor, then we've been invoked to start a new
             *   conversation
             */
            if(gPlayerChar.currentInterlocutor != actor)
                reasonInvoked = InitiateConversationReason;
            
            /*  
             *   Otherwise if we've been invoked from the actor object, note
             *   that we've been invoked from our actor's agendaList during a
             *   lull in the conversation.
             */
            else if(caller == actor)
                reasonInvoked = ConversationLullReason;
            
            /*  
             *   Otherwise note that we've been invoked from a
             *   DefaultAgendaTopic
             */
            else
                reasonInvoked = DefaultTopicReason;
            
            /* 
             *   Give the actor the chance to say hello, and note whether this
             *   resulted in any greeting being displayed. Note that
             *   Actor.actorSayHello() won't actually attempt to do anything if
             *   a conversation is already in progress.
             */
            greetingDisplayed = actor.actorSayHello();    
            
            /* 
             *   Note that our actor has conversed with the player character on
             *   this turn.
             */
            actor.noteConversed();
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
         *   conversational turn. But we don't need to do any of this if we've
         *   been invoked from a DefaultAgendaTopic, since in that case we're
         *   being invoked as part of a conversational turn, which will handle
         *   the pending and active keys in any case.
         */
        
        if(reasonInvoked != DefaultTopicReason)
        {
            actor.activeKeys = actor.pendingKeys;        
            actor.keepPendingKeys = nil;
        }
    }
    
    /* 
     *   Flag; did invoking this item result in the display of a greeting (from
     *   an ActorHelloTopic)?
     */    
    greetingDisplayed = nil
    
    /* 
     *   Why was this ConvAgenda Item invoked?
     *.    1 = InitiateConversationReason = Actor initiating new conversation
     *.    2 = ConversationLullReason = Actor using lull in conversation
     *.    3 = DefaultTopicReason = Actor responding to DefaultAgendaTopic
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
       
        /* 
         *   Mark us as done; we'll be reinstated the next time someone
         *   converses with our actor.
         */
        isDone = true;
    }

    /* 
     *   by default, handle boredom before other agenda items - we do this
     *   because an ongoing conversation will be the first thing on the
     *   NPC's mind 
     */
    agendaOrder = 50
;

/* 
 *   An AgendaItem that can be used to trigger actor travel when the actor is
 *   waiting for the player character to follow him/her/it.
 */
class FollowAgendaItem: AgendaItem    
    
    invokeItem()
    {
         /* Note our actor */
        local actor = getActor;
        
        /* If we've exhausted our list of connectors, then we're done. */
        if(nextConnNum >= connectorList.length)    
        {
            isDone = true;    
            actor.followAgendaItem = nil;
            return;
        }
        
        /* Get our next connector */
        local conn = nextConnector;       
        
        /* Let our actor know we're its currently active FollowAgendaItem */
        actor.followAgendaItem = self;
        
        /* 
         *   Travel via the next connector in our list if we're ready to move;
         *   we're ready to move when the player character has just issued a
         *   Follow command, which in turn sets the fuse to move the player
         *   character when we move.
         */
        if(getActor.followFuseID != nil) 
        {           
            /* Travel via the connector. */
            conn.travelVia(actor);
            
            /* Increment our next connector number. */
            nextConnNum++;
            
            /* Note that we've traveled on this turn */
            traveledThisTurn = libGlobal.totalTurns;
            
            /* 
             *   Mark this Agenda Item as done if we've exhausted our list of
             *   connectors
             */
            if(nextConnNum >= connectorList.length)
            {
                isDone = true;
             
                /* Note that we've arrived at our destination */
                noteArrival();               
            }
        }

    }
    
    /* Which turn did this FollowAgendaItem last cause our NPC to travel on? */
    traveledThisTurn = nil
    
    /* A pointer to the next connector to use */
    nextConnNum = 0
    
    
    /* 
     *   A list of TravelConnectors through which we want the player character
     *   to follow our associated actor.
     */
    connectorList = []
    
    /*  The next connector our NPC wants to lead the PC via */
    nextConnector = connectorList.element(nextConnNum + 1)
    
    
    /*   
     *   This method is invoked when our NPC arrives at his/her destination. By
     *   default we do nothing, but instances can override to provide code to
     *   handle the arrival, e.g. by changing the NPC's ActorState.
     */
    noteArrival() { }
    
    resetItem()
    {
        /* Carry out the inherited handling. */
        inherited;
        
        /* Let our actor know we're now its active FollowAgendaItem. */
        getActor.followAgendaItem = self;
        
        /* Reset our next connector pointer */
        nextConnNum = 0;
    }
    
    /* 
     *   The specialDesc to display when our actor is waiting for the PC to
     *   follow it. By default we just show a plain vanilla message to the
     *   effect, "The NPC is waiting for you to follow him/her north" or
     *   whatever, but game code may wish to override this to provide a more
     *   customized message.
     */
    specialDesc()
    {
        /* 
         *   Note our actor and the player character and create a couple of
         *   useful message parameter substitutions.
         */
        local myactor = getActor;
        local pc = gPlayerChar;       
        gMessageParams(myactor, pc);
        
        /*   
         *   Display our default message. We make use there is a nextDirection
         *   before we attempt to use it in our message, otherwise we simply use
         *   a bland "X is here."
         */
        local nd = nextDirection;
        
        if(nd != nil)
            DMsg(waiting for follow, '{The subj myactor} {is} waiting for {the
                pc} to follow {him myactor} {1}. ', nd.departureName);
        else
            DMsg(actor is here, '{The subj myactor} {is} {here}. '); 
    }
        
    nextDirection = getActor.getOutermostRoom.getDirection(nextConnector)
    
    /* 
     *   The specialDesc to use when our NPC has just traveled as a result of
     *   this TravelAgendaItem. By default we just show our specialDesc, but
     *   game code might want to customize this to something like "Bob crosses
     *   the room and waits for you to follow him through the green door."
     */
    arrivingDesc() { specialDesc; }
    
    /* 
     *   Show a specialDesc for this NPC when this TravelAgendaItem is active.
     *   If we've just moved this turn we display the arrivingDesc(), otherwise
     *   we show the specialDesc.
     */
    showSpecialDesc()
    {
        if(traveledThisTurn == libGlobal.totalTurns)
            arrivingDesc();
        else
            specialDesc();        
    }
    
    /* 
     *   Display a message to say that our actor is leaving via conn. This would
     *   normally describe the player character following our actor via conn.
     */
    sayDeparting(conn)
    {
        /* 
         *   By default we use the connector's standard sayActorFollowing()
         *   method.
         */
        conn.sayActorFollowing(gActor, getActor);
    }
    
    
    /* 
     *   Give this AgendaItem the opportunity to react to travel; in particular
     *   this might be used to allow the NPC to react to or even forbid travel
     *   in a direction other than the one s/he's trying to lead the PC.
     */
    beforeTravel(traveler, connector) { }
    
    /* Cancel this FollowAgendaItem before its normal termination. */
    cancel()
    {
        /* Note our actor */
        local actor = getActor;
        
        /* Note that we're done. */
        isDone = true;        
        
        /* Note that we're no longer our actor's current FollowAgendaItem */
        if(actor.followAgendaItem == self)
            actor.followAgendaItem = nil;
        
        /* Remove us from all agenda lists. */
        actor.removeFromAllAgendas(self);        
    }
    
    /*   
     *   Give this agendaItem a high priority to make sure it is used in
     *   response to a FOLLOW ccmmand in preference to any other AgendaItems
     *   that may be pending.
     */
    agendaOrder = 1
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
 *   A special lister to display a topic inventory list from a list of topics
 *   provided in the lst parameter.
 */
suggestedTopicLister: object

    /* Introduce the topic inventory listing */
    showListPrefix(lst, pl, explicit)  
    { 
        /* 
         *   Introduce the list. If it wasn't explicitly requested start by
         *   outputting a paragraph break and an opening parenthesis.
         */
        if(!explicit)
            "<.p>(";
        
        /* 
         *   Then introduce the list of suggestions with the appropriate form of
         *   'You could' (suitably adjusted for the person of the player
         *   character)
         */
        DMsg(suggestion list intro, '{I} could ');
    }
    
    /* End the list with a closing parenthesis or full stop as appropriate */
    showListSuffix(lst, pl, explicit)  
    { 
        /* 
         *   Finish the list. If it was explicitly requested we finish it with a
         *   full stop and a newline, otherwise we finish it with a closing
         *   parenthesis and a newline.
         */
        if(explicit)
            ".\n";
        else
            ")\n";
    }
    
    /* The message to display if there are no topics to suggest. */
    showListEmpty(explicit)  
    { 
        if(explicit)
            DMsg(nothing in mind, '{I} {have} nothing in mind to discuss
                with {1} just {then}. ',
                 gPlayerChar.currentInterlocutor.theObjName);
    }
    
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
            showListEmpty(explicit);                
            return;
        }
        
        
        /* 
         *   Next we need to divide the list according to category
         *
         *
         *
         *   First we go through the list of suggestion types assigning each
         *   topic entry to the user specified type where the user has specified
         *   that it should be suggested at a specific type of Topic Entry (as
         *   opposed to the library default).
         */
        
        foreach(local cur in typeInfo)
        {
            /* 
             *   For each item in our typeInfo list (for which see below),
             *   extract that subset of topic entries from our main list for
             *   which the suggestAs property matches the suggestAs property in
             *   cur (which is the third element of cur). Set the corresponding
             *   list on this lister object (for which we obtain a property
             *   pointer from the first element of cur) to be that subset.
             */
            self.(cur[1]) = lst.subset({t: t.suggestAs == cur[3]});
            
            /* 
             *   Then remove the subset we've just identified from the list of
             *   topic entries to be processed, since we've just accounted for
             *   them
             */
            lst -= self.(cur[1]);
        }
        
        /* 
         *   Then go through every remaining item in our main list, assigning it
         *   to a sublist on the basis of which type of topic entry it is, which
         *   we'll determine on the basis of the property pointers in its
         *   includeInList.
         */        
        foreach(local cur in typeInfo)
        {
            /* 
             *   For each entry in our typeInfo list, find that subset of our
             *   list of topic entries that corresponds to the typeInfo. A topic
             *   entry will correspond to the cur typeInfo if the second element
             *   of cur (a property pointer such as &askTopics) can be found in
             *   the includeInList of the topic entry, which we can test with
             *   our includes method (defined below). Add the subset thus
             *   created to the list contained in the property defined by the
             *   property pointer held in the first element of cur (e.g.
             *   &sayList), which will be a property of this lister object.
             */
            self.(cur[1]) += lst.subset({t: includes(t, cur[2])});
            
            /* 
             *   Remove the sublist we've just created from our overall list of
             *   topic entries, since it's now accounted for.
             */
            lst -= self.(cur[1]);
        }
      
        
        /* 
         *   Introduce the list. 
         */
		showListPrefix(lst, nil, explicit);
		        
        /* Note that we haven't listed any items yet */
        local listStarted = nil;
        
        /* 
         *   Note that the actor we're listing suggestions for is the player
         *   character's current interlocutor.
         */
        local interlocutor = gPlayerChar.currentInterlocutor;
        
        /* Create a message parameter substitution for the interlocutor */
        gMessageParams(interlocutor);
        
        
        /* 
         *   We then output our list of suggestions category by category
         *
         *   We start with suggested SayTopics, if there are any to display.
         */        
        if(sayList.length > 0)
        {
            /* List our suggested SayTopics */
            showList(sayList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        /* Next list our suggested QueryTopics, if we have any */
        if(queryList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Output an introduction to our list of QueryTopics */
            DMsg(ask query, 'ask {him interlocutor} ');
            
            /* Show the list of suggested QueryTopics */
            showList(queryList);
            
            /* Note that we have now started listing topics */
            listStarted = true;                
        }
        
        /* Next list our suggested AskTopics, if we have any */
        if(askList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Output an introduction to our list of AskTopics */
            DMsg(ask about, 'ask {him interlocutor} about ');
            
            /* Show the list of suggested AskTopics */
            showList(askList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        /* Next list our suggested TellTopics, if we have any */
        if(tellList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */            
            if(listStarted)
                say(orListSep);
            
            /* Output an introduction to our list of AskTopics */
            DMsg(tell about, 'tell {him interlocutor} about ');

            /* Show the list of suggested TellTopics */
            showList(tellList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        /* Next list our suggested TalkTopics, if we have any */
        if(talkList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Output an introduction to our list of TalkTopics */
            DMsg(talk about, 'talk about ');
            
            /* Show the list of suggested TalkTopics */
            showList(talkList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        /* Next list our suggested GiveTopics, if we have any */
        if(giveList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);

            /* Output an introduction to our list of GiveTopics */
            DMsg(give, 'give {him interlocutor} ');
            
            /* Show the list of suggested GiveTopics */
            showList(giveList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        /* Next list our suggested ShowTopics, if we have any */
        if(showToList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Output an introduction to our list of ShowTopics */
            DMsg(show, 'show {him interlocutor} ');
            
            /* Show the list of suggested ShowTopics */
            showList(showToList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        /* Next list our suggested AskForTopics, if we have any */
        if(askForList.length > 0)
        {
             /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Output an introduction to our list of AskForTopics */
            DMsg(ask for, 'ask {him interlocutor} for ');
            
            /* Show the list of suggested AskForTopics */
            showList(askForList);
            
            /* Note that we have now started listing topics */
            listStarted = true; 
        }
        
        if(yesList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Show our list of YesTopics (typically, just 'say yes') */
            showList(yesList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        if(noList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Show our list of NoTopics (typically, just 'say no') */
            showList(noList);
            
            /* Note that we have now started listing topics */
            listStarted = true;
        }
        
        if(commandList.length > 0)
        {
            /* 
             *   If we've already listed some suggestions, output a list
             *   separator before starting the next group.
             */
            if(listStarted)
                say(orListSep);
            
            /* Output an introduction to our list of CommandTopics */
            DMsg(tell to, 'tell {him interlocutor} to ');
            
            /* Show the list of suggested CommandTopics */
            showList(commandList);
            
            /* Note that we have now started listing topics */
            listStarted = true; 
        }
        
        /* 
         *   Finish the list by appending its suffix 
         */
        showListSuffix(lst, nil, explicit);
        
    }
    
    /* Show one of our sublists of particular kinds of suggest topics */
    showList(lst)
    {
        /* For each element in the list */
        for(local cur in lst, local i = 1 ;; ++i)
        {
            /* 
             *   If the current topic entry wants to include a sayPrefix,
             *   displat the sayPrefix. In practice this only applies to
             *   SayTopics which may or may not want to introduce the name of a
             *   suggestion with 'say'.
             */
            if(cur.includeSayInName)
                say(sayPrefix);
            
            /* Display the name of the current suggestion */
            say(cur.name);
            
            /* Output a comma or 'or', depending where we are in the list */
            if(i == lst.length - 1)
                DMsg(or, ' or ');
            if(i < lst.length - 1)
                ", ";
            
        }
    }
    
    /* 
     *   The typeInfo contains a list of lists that are used by the show method
     *   to build our various sublists. The first element of each list is a
     *   pointer to the list property to use on this lister object to hold the
     *   particular sublist. The second element of each list is a property
     *   pointer used to identify which sublist a TopicEntry belongs in,
     *   according to its own includeInList property. The third element is the
     *   type of topic entry a topic entry should be suggested as if it is
     *   explicitly requested in its suggestAs property.
     */
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
    
    /* Sublists of each kind of suggestion which can be listed in turn */
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
    
    
    /* 
     *   Test whether the topicEntry t includes prop in its includeInList.
     */    
    includes(t, prop)
    {
        return t.includeInList.indexOf(prop) != nil;
    }
    
    /* 
     *   The prefix to use when suggesting a SayTopic, if it explicitly wants
     *   the suggestion to start with 'say'.
     */
    sayPrefix = BMsg(say prefix, 'say ')
    
    /*  The conjunction to use at the end of a list of alternatives */
    orListSep = BMsg(or list separator, '; or ')

;

modify Follow
    /* For this action to work all known actors also need to be in scope */
    addExtraScopeItems(whichRole?)
    {
        scopeList = scopeList.appendUnique(Q.knownScopeList.subset({x:
            x.ofKind(Actor)}));
    }
;