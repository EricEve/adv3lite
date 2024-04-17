#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*
 *   ****************************************************************************
 *    facts.t 
 *
 *    This module forms part of the adv3Lite library 
 *    (c) 2024 Eric Eve
 */


/* 
 *   A Fact encapsulates an item of knowledge (or supposed knowledge) keyed on the fact tags in the
 *   appropriate object's informedNameTab. Note that for the purposes of thid module, a Fact is not
 *   something that is necessarily true, but simply somethhing that some actor or Consultable in the
 *   game has asserted to be true.
 */
class Fact: object
    /* Our name is the fact tag (used in gInformed() stateement or the like) that identifies us. */
    name = nil
    
    /* 
     *   Our descripition. This should a single-quoted string with no closing punctuation that could
     *   follow 'that'; for example 'Spain is a country in Europe' or 'it rained yesterday'
     */
    desc = nil
    
    /* 
     *   We can if we wish vary the way this fact is described according to the source that's
     *   supplying it and the topic matched by the TopicEntry that's called this method; by
     *   default we just return desc here. Note that any such variation shouldn't change the content
     *   of the description but only the way it's phrased; e.g. 'Madrid is the capital of Spain'
     *   rather than 'the capital of Spain is Madrid' depending on whether the topic is Madrid or
     *   Spain.
     */
    qualifiedDesc(source, topic)
    {
        return desc;
    }
   
    /* The list of topics (Topics and Things, i.e. game objects) that this fact relates to.*/         
    topics = []
    
    /* 
     *   The list of actors and other objects - typically Consultables - that start the game knowing
     *   about us.
     */
    initiallyKnownBy = []
    
    /* Obtain a list of everything that knows this fact */
    currentlyKnownBy()
    {
        /* Set up a new Vector */
        local vec = new Vector;
        
        /* Iterate through every Thing in the game. */
        for(local obj = firstObj(Thing); obj != nil; obj = nextObj(obj, Thing))
        {
            /* If obj knows about us, add obj to our vector. */
            if(obj.knowsAbout(self.name))
                vec.append(obj);
        }        
        
        /* Convert the Vector to a List and return the result. */
        return vec.toList();
    }
    
    /* Initialise this fact at preInit. */
    initializeFact()
    {
        /* Run through all the actors (or other sources) in out initiallyKnownBy list. */
        foreach(local actor in initiallyKnownBy)
        {
            /* Create an entry in the actor's informedNameTab and set its value to ourself. */
            actor.setInformed(name);
            actor.informedNameTab[name] = self;
        }
        
        /* If we have a pcComment defined, add it to our pcCommentTab */
        if(pcComment)
            setPcComment(gPlayerChar, pcComment);
    }
    
    /* 
     *   LookUpTable containing lists of which sources have imparted this Fact to which actor;
     *   actor defaults to gPlayerChar we use a LookUpTable here in case the player character
     *   changes during the courss of play.
     */     
    sourcesTab = nil
    
    /* 
     *   LookUpTable containing lists of whom actor has imparted this Fact; actor defaults to
     *   gPlayerChar we use a LookUpTable here in case the player character changes during the
     *   courss of play.
     */
    targetsTab = nil
    
    /* Add a source (of information) to our sourcesTab table. */
    addSource(source, actor = gPlayerChar)
    {
        /* If we haven't created a sourceTab LookupTable yet, do so now. */
        if(sourcesTab == nil)
            sourcesTab = new LookupTable(5,5);
        
        /* 
         *   Retrieve the value from the sourcesTab table corresponding to actor (which will
         *   normally be the current player character.
         */
        local item = valToList(sourcesTab[actor]);
        
        /* Add our new source to the list of sources in this value without duplicating it. */
        item = item.appendUnique([source]);
        
        /* Store the updated value back in sourcesTab. */
        sourcesTab[gPlayerChar] = item;
                               
    }
    
    /* Add a target to our targetTab table */
    addTarget(target, actor = gPlayerChar)
    {
        /* If we haven't created a targetsTab LookupTable yet, do so now. */
        if(targetsTab == nil)
            targetsTab = new LookupTable(5,5);
        
        /* 
         *   Retrieve the value from the sourcesTab table corresponding to actor (which will
         *   normally be the current player character.
         */
        local item = valToList(targetsTab[actor]);
        
        /* Add our new source to the list of sources in this value without duplicating it. */
        item = item.appendUnique([target]);
        
        /* Store the updated value back in targetsTab. */
        targetsTab[gPlayerChar] = item;
    }
    
    /* 
     *   Get a list of the sources who have imparted this Fact to actor; actor dafaults to the
     *   player character and must normally have been the player character at some point for this to
     *   return anything but an empty list.
     */
    getSources(actor = gPlayerChar)
    {
        return sourcesTab ? valToList(sourcesTab[actor]) : []; 
    }
    
    /* 
     *   Get a list of the targets actor has imparted this Fact to; actor dafaults to the player
     *   character and must normally have been the player character at some point for this to return
     *   anything but an empty list.
     */
    getTargets(actor = gPlayerChar)
    {
        return valToList(targetsTab[actor]); 
    }
    
    /* 
     *   If our caller wants to list sources of information (listSources = true), then return a
     *   string containing a suitably formatted list of sources; otherwise return nil. This can then
     *   be used by TopicEntries (typically Thoughts) that want to list the sources of information
     *   along with the content of that information.
     */
    sourceIntro(listSources)
    {
        /* Start by creating an emptry string. */
        local srcList = '';
        
        /* 
         *   Only add to it if our caller actually wants to show a list of sources (thia allows the
         *   caller to insert a call to sourceIntro() passing the value or a user defined property
         *   to determine whether anything is listed or not).
         */
        if(listSources)
        {
            /* 
             *   obtain a list of the sources that have imparted this Fact to the current player
             *   character.
             */
            local objList = getSources();
            
            /*  
             *   Remove the player character from this list (we don't want to report that the player
             *   character informed themself.
             */
            objList -= gPlayerChar;
            
            /* 
             *   We only need to do any more if there's anything left in our list of source objects.
             */
            if(objList.length > 0)
            {
                /* 
                 *   Store a list of the names of the sources of the information from our list of
                 *   Facts.
                 */
                srcList = objList.mapAll({x:x.theName});
                
                /* 
                 *   Append a message explaining that these people/things were the sources of
                 *   information and append it to a formatted list of the source names.
                 */
                srcList = andList(srcList) + BMsg(told me that, ' told {me} that ');
            }            
        }
        
        /* Return the string that results. */
        return srcList;
    }
    
    /* 
     *   A single-quoted string containing the initial player character's initial comment or thought
     *   on this Fact; this can be left at nil if the PC doesn't have one. This will be appended to
     *   the description of this Fact when listed by a Thought, so should be a sentence fragment
     *   starting with a lower case letter (or some form of parenthetic punctuation) and without a
     *   full stop at the end.
     */
    pcComment = nil
    
    /*  
     *   A table containing platey characters' comments on this Fact. We use a LookpTable here in
     *   case the player character changes, so we can retrieve the comment relevant to the current
     *   player character
     .*/
    pcCommentTab = nil
    
    /* 
     *   Get the current player character's comment on this Fact; source is the source from which
     *   the PC learned the Fact and topic is the topic the Player Character is thinking about. By
     *   default this method returns different results for different player characters, but game
     *   code will need to override this method to return different comments for different sources
     *   and/or topics.
     */         
    getPcComment(source, topic)
    {
        /* 
         *   If our pcCommentTab hasn't been created yet, we don't have any player character
         *   comments, so just return nil
         .*/
        if(pcCommentTab == nil)
            return nil;
        
        /* Otherwise return the comment relating to the current player character. */
        return pcCommentTab[gPlayerChar];
    }
    
    /* 
     *   Set actor's comment on this fact; normally actor will be the current player character; txt
     *   is a single-quoted string containing the comment, which will usually be appended to the
     *   description of the fact.
     */
    setPcComment(actor, txt)    
    {
        /* If we don't yet have a LookUpTable for pcComments, create one. */
        if(pcCommentTab == nil)
            pcCommentTab = new LookupTable(5, 5);
            
        /* Set the actor's comment to txt. */ 
        pcCommentTab[actor] = txt;
    }
    
        
    /* 
     *   Our priority (what is our relevant importance). Facts with a higher priority will be listed
     *   earlier in any list of facts. We set a defaul priority of 100.
     */
    priority = 100
    
    /*   
     *   Alternatively we can use our list order to determine the order in which facts will be
     *   listed. By default we use give everything a list order of 1.
     */
    listOrder = 1
    
    /*   
     *   Deduct our listOrder from our priority to get the adjustedPriority that will actualy be
     *   used to sort facts in the desired order. This allows game authors to use either property
     *   (or possibly a combination of both) to determine the listing order.
     */
    adjustedPriority = (priority - listOrder)
;

/* 
 *   The factManager object initializes Facts at preInit and provides a number of service methods
 *   for dealing with Facts.
 */
factManager: PreinitObject
    
    /* 
     *   A LookUpTable of all the Facts defined in the game, to allow a Fact to be accessed via its
     *   name property.
     */
    factTab = nil
    
    /* Add a fact to our factTab */
    addFact(fact)
    {
        /* If our LookupTable hasn't been created yet, create it now. */
        if(factTab == nil)
            factTab = new LookupTable(30, 30);
        
        /* Add the new Fact to our factTab. */
        factTab[fact.name] = fact;
    }
    
    /* Retrieve a Fact from our factTab via its name (passed as the tag parameter. */    
    getFact(tag) { return factTab != nil ? factTab[tag] : nil; }
    
    /* Retrieve the base description of a Fact via its name (passed as the tag parameter. */ 
    getFactDesc(tag)
    {
        /* Get the corresponding Fact. */
        local fact = getFact(tag);
        
        /* If we've found one, return its base desc property, otherwise return nil. */
        return fact == nil ? nil : fact.desc();
    }
           
    /* 
     *   Retrieve the qualified description of a Fact: actor is the actor or Consultable that is the
     *   source of the information, tag is the fact's name (name property, not programmatic name)
     *   and topic is the topic that has just been matched by a TopicEntry.
     */
    getQualifiedFactDesc(actor, tag, topic?)
    {
        /* Retrieve the Fact corresponding to tag. */
        local fact = getFact(tag);
        
        /* If we've found a fact, return its qualified description, otherwise return nil */
        return fact == nil ? nil : fact.qualifiedDesc(actor, topic);
    } 
    
    /* 
     *   Get the player character's comment on the fact whose name is tag when it is retrieved in
     *   relation to topic (typically by a THINK ABOUT topic commannd).
     */
    getPcComment(tag, topic)
    {
        /* Find the fact relating to tag */
        local fact = getFact(tag);
        
        /* If there isn't one, issue a warning message if debugging, and return nil in any case. */
        if(fact == nil)
        {
#ifdef __DEBUG            
            "WARNING! No such fact as <<tag>> to retrieve PC comment from. ";
#endif
            return nil;
        }
        /* 
         *   Otherwise retrieve the player character's comment from the relevant fact and return the
         *   result.
         */
        else
            return fact.getPcComment(gPlayerChar, topic);
    }
    
    /* 
     *   Set the current player character's comment on the Fact identified by tag; txt is a
     *   single-quote string containing the comment.
     */
    setPcComment(tag, txt)
    {
        /* First retrieve the fact. */
        local fact = getFact(tag);
        
        /* 
         *   If we don't find one, return nil, after issuing a warning message if the game has been
         *   compiled for debugging.
         */
        if(fact == nil)
        {
#ifdef __DEBUG               
            "WARNING! No such fact as <<tag>> to set PC Comment for.";
#endif        
            ;
        }
        /* Otherwise set the current player character's comment to txt. */
        else
            fact.setPcComment(gPlayerChar, txt);
    }
    
    
    /* Setup method to call at preInit. */
    execute()
    {
        /* Iterate through the full list of Facts in the game. */
        for(local fact = firstObj(Fact); fact!= nil; fact = nextObj(fact, Fact))
        {
            /* Initialize the current fact. */
            fact.initializeFact();
            
            /* Then add it to our database of Facts. */
            addFact(fact);
        }                
    }
    
    
;

/* 
 *   Mix-in class for use with IopicEntries (typically Thoughts or ConsultTopics, though game
 *   authors are free to experiment with mixing it in with ActorTopicEntries, probably most usefully
 *   AskTopics or DefaultAskTopics), to provide additional functionality relating to Facts, in
 *   particular to generate a suitably formatted list of facts relating to the topic the TopicEntry
 *   has just matched, thereby automating the response to commands like THINK ABOUT X or LOOK UP X
 *   IN BOOK.
 */
class FactHelper: object
    /* 
     *   Get a sorted list of the facts known to our actor that are associated with the topic
     *   matched by our TopicEntry.
     */
    getFacts()
    {
        /* 
         *   Get our responding actor (the current interlocutor the player character is currently in
         *   conversation with, or the Consultable we're looking something up in, or the player
         *   character if we're thinking).
         */
        local actor = getActor();
        
        /* Note the topic (Topic or Thing) matched by our TopicEntry. */
        local top = topicMatched;
        
        /* A list of the Fact names we match in response to being queried. */
        tagList = [];
        
        /* 
         *   If our actor's informedNameTab hasn't been created, return an empty list, since there's
         *   nothing to look up.
         */
        if(actor.informedNameTab == nil)
            return [];
        
        /* Set up a new Vector to build our collection of Facts. */
        local vec = new Vector();
        
        /* Set up a local variable to store a current Fact object.*/
        local factObj;
        
        /* Get a list of keys (= Fact names) from our actor's informedNameTab */
        local keyList = actor.informedNameTab.keysToList();
        
        /* Iterate through our list of keys. */
        foreach(local fkey in keyList)
        {
            /* Retrieve the Fact object corresponding to the current key. */
            factObj = factManager.getFact(fkey);
            
            /* 
             *   If we found a Fact object and the topic matched by our TopicEntry is in the list of
             *   the Fact object's list of associated topics, add the current key to our tagList and
             *   append the Fact object to our vector.
             */
            if(factObj && factObj.topics.find(top))
            {
                tagList += fkey;
                vec.append(factObj);
            }
        }
        
        /* Sort the vector. convert it to a list, and then return the result. */
        return vec.sort(true, {a, b: a.adjustedPriority - b.adjustedPriority}).toList();        
        
    }
    
    /* 
     *   A list of the tags (Fact tag names) we're currently interested in. Note that this is
     *   populated by a call to getFacts().
     */
    tagList = nil
       
    /* 
     *   The prefix to be used to a list of facts. We specify nothing here since subclasses will
     *   override as approprite.
     */
    prefix = ''
    
    /*   
     *   The suffix to appear at the end of our list or item; normally this will be a full stop
     *   followed by a space.
     */
    suffix = '. '
    
    /*   
     *   The message to display if we don't find any matching facts. Subclasses will override as
     *   appropriate.
     */
    noFactsMsg = ''     
    
    /* 
     *   The parenthetical message to append to a listed fact if the player character has been
     *   informed of something they already knew.
     */
    knewFactAlreadyMsg = BMsg(knew fact already, ' (but {i} knew that already)')
    
    /* 
     *   Return a message stating that a fact was already known if the player character started out
     *   knowing it from the beginning of the game or an empty string otherwise. This makes it safe
     *   to call this method without knowing whether it's applicable, since this method will
     *   determine the applicabilitly.
     */     
    alreadyKnewMsg(fact)
    {
        /* 
         *   We only want to append a message saying the player character already knew this message
         *   if the player character is among the list of sources in its initiallyKnownBy list and
         *   there is at least one other source that is not the player character (so that when
         *   reported the fact will be prefixed by 'so-and-so told you that').
         */
        if(fact.initiallyKnownBy.find(gPlayerChar) 
                        && fact.getSources.indexWhich({x: x!= gPlayerChar}))
            return knewFactAlreadyMsg;
        
        /* Otherwise simply return an empty string. */
        return '';
    }
    
    /* 
     *   The word or phrase used to introduce the description of a fact or list of facts. In English
     *   this is simply 'that'.
     */
    factIntro = BMsg(fact intro, 'that')
    
    /* 
     *   The topicResponse to be provided by the TopicEntry we're mixed-in with. This performs the
     *   main purpose of the FactHelper mix-in class by providing an automated suitably-formatted
     *   list of the facts (and possibly their sources) associated with the topic matched by our
     *   TopicEntry. This can be used to automate the response to THINK ABOUT X or LOOK UP X IN
     *   WHATEVER, provided Facts have been used elsewhere to provide previous responses.
     */         
    topicResponse()
    {
        /* 
         *   Start by obtaining the list of facts associated with the topic our TopicEntry has just
         *   matched.
         */
        local factList = getFacts();        
               
        /* 
         *   tagList will have just been populated by the call to getFacts. It contains the list of
         *   name tags corresponding to those facts, If the list is empty we have no facts to
         *   display so we just display an appopriate message to that effect.
         */        
        if(tagList.length == 0)
            "<<noFactsMsg>>";
        else
        {
            /* 
             *   If we have only one fact to report or we don't want line breaks between facts, use
             *   the continuous single sentence form of listing.
             */
            if(tagList.length == 1 || addLineBreaks == nil)
            {
                /* 
                 *   Create a list of strings each of which starts with our factIntro (typically
                 *   'that') then (if requested) the list of sources who imparted this purported
                 *   fact to the Player Character, then the qualfied description of the fact.
                 */
                local factListStr = factList.mapAll({x: factIntro + ' ' + x.sourceIntro(listSources) + 
                                      x.qualifiedDesc(getActor, topicMatched)});
                
                /* Combine this list of strings into a suitably formalled single string. */
                local resp = andList(factListStr);
                
                /* 
                 *   If we're using the sentence format because we've only one fact to list, append
                 *   an explanation that we already knew this fact if other people have also
                 *   imparted it to us.
                 */
                if(tagList.length == 1)
                    resp += alreadyKnewMsg(factManager.getFact(tagList[1]));
                
                /* 
                 *   Display a single sentence listing all the facts the PC knows (or has been
                 *   informed about) in connection with the topic our TopicEntry matched.
                 */
                "<<prefix>> <<resp>><<suffix>>" ;
            }
            else
            {      
                /* 
                 *   If we're listing several facts line by line, start with a general introduction
                 *   to our list (of the form 'You recall that ').
                 */
                "<<prefix>> <<factIntro>>: ";
                
                /* 
                 *   Then iterate through our sorted list of facts to list each one on a separate
                 *   line.
                 */
                foreach(local fact in factList)
                {
                    /* 
                     *   Start on a new line, then list the sources of the information (if
                     *   listSources if true) then describe the fact, and then append the notice
                     *   that the Player Character already knew this fact if the Player Character is
                     *   listed in the fact's initiallyKnownBy list.
                     */
                    "\n\^<<fact.sourceIntro(listSources)>>  <<fact.qualifiedDesc(getActor,
                        topicMatched)>><<alreadyKnewMsg(fact)>>";                   
                    
                    /* Conclude each line with a dfull stop. */
                    ".";
                }
            }
            
            /* 
             *   Next loop through our list of tags to reveal them (so the game author doesn't also
             *   need to insert a <.reveal tag>) and, if requested, update the sources of
             *   information for each fact.
             */
            foreach(local tag in tagList)
            {
                /* 
                 *   If libGlobal.informOnReveal is true (the default) then reveal the tag (which
                 *   also adds it to the player characters informedNameTab).
                 */
                if(libGlobal.informOnReveal)
                    gReveal(tag);
                /* 
                 *   Otherwise we want to separate revealing from informing the player character, so
                 *   we only do the latter.
                 */
                else
                    gPlayerChar.setInformed(tag);
                
                /* If we want to update the sources of this fact, then do so. */
                if(updateSources)
                {
                    /* Obtain the fact object corresponding to tag. */
                    local factObj = factManager.getFact(tag);
                    
                    /* 
                     *   Add getActor() (the current source of information) to the list of sources
                     *   for this fact.
                     */
                    factObj.addSource(getActor);
                }
                
            }
        }
        
        
    }
    
    /* 
     *   Since we're typically going to be used to make a catch-all TopicEntry, we'll normally want
     *   to match any Thing or Topic in the game.
     */
    matchObj = [Thing, Topic]
    
    /* 
     *   Do we want our topicResponse() method to update the list of sources on the Facts it lists?
     *   We probably if we're mixed in with a ConsultTopic (to note the corresponding Consultable as
     *   the source of information) but not if we're mixed in with a Thought (since the Player
     *   Character must already effecitvely be a potential source of the information they're
     *   recalling).
     */
    updateSources = true
    
    /* 
     *   Do we want to list the sources of the facts our topicResponse is reporting? We might well
     *   want to do so on a ConsultTopic but probably not on a Thought, so we default to nil here.
     */
    listSources = nil
       
    /* 
     *   Do we want to insert line breaks between each item in a list of fact descriptions (so that
     *   we get a vertical list of facts or list them all in a continous sentence (addLineBreas =
     *   nil, the default).
     */
    addLineBreaks = nil    
;



/* 
 *   A FactConsultTopic can be used to generate an automated response to a potentially wide range of
 *   queries directed to the associated Consultable, provided that the Consultable in question has
 *   been listed in the various relevant facts' initiallyKnownBy list (or subquently added to its
 *   informedNameTab if the Consultable is updatable). A DefaultFactConsultTopic can also act like a
 *   regular DefaultConsultTopic when its Consultable has no facts corresponding to the topic that's
 *   just been looked up.
 */
 
class FactConsultTopic:  FactHelper, ConsultTopic
    /* 
     *   We give a FactConsultTopic a matchScore of 50 since it's not a mere DefaultConsultTopic
     *   that always gives a generic response to the effect that the Consultable has no useful
     *   information on every topic the DefaultTopic attempts to handle, but on the other hand we
     *   want it to defer to any regular ConsultTopic that gives a more tailored response to a
     *   particular topic or topics.
     */
    matchScore = 50    
    
    prefix = BMsg(consult prefix, '{The subj dobj} inform{s/ed} {me}')
    noFactsMsg = BMsg(no consult, '{The subj dobj} {has} nothing useful to say on that subject. ')
;

/* 
 *   A FactThought can be used to generate an automated response to a potentially wide range of
 *   requests to THINK ABOUT SO-AND-SO, provided that the Player Character has been listed in the
 *   various relevant facts' initiallyKnownBy list (or subquently added to its informedNameTab if the
 *   Consultable is updatable). A FactThought can also act like a DefaultThought when the player
 *   character knows no Facts corresponding to the topic that's being thought about. It will also
 *   defer to any specific Thoughts with a matchScore higher than 50.
 */
class FactThought: FactHelper, Thought
    /* 
     *   We give a FactThought a matchScore of 50 since it's not a mere DefaultThought
     *   that always gives a generic response to the effect that the player character has no
     *   information on whatever topic the player attempts to think about, but on the other hand we
     *   want it to defer to any regular Thoughts that gives a more tailored response to a
     *   particular topic or topics.
     */
    matchScore = 50    
    
    prefix = BMsg(thoughts prefix, '{I} recall{s/ed}')
    
    noFactsMsg = BMsg(no thoughts, 'Nothing relevant {dummy} {comes} to mind. ')
    
    /* 
     *   Enable a Tnought to show the player character's comment on a fact that's being listed as
     *   being thought about.
     */        
    alreadyKnewMsg(fact)
    {
        /* 
         *   Retrieve the player characte's comment on fact in relation to the topic matched by this
         *   Thought.
         */
        local txt = fact.getPcComment(getActor, topicMatched);
         
        /* 
         *   If we find a comment, prepend a space to sepaarate it from the description of the fact
         *   and then return the result. We then skip adding any 'but you already knew that' message
         *   since it would seem redundant - or overkill - to show both comments.
         */
        if(txt)
            return ' ' + txt;
        
        /* 
         *   Otherwise return the inherited result (normally a message saying the PC already knew
         *   the fact, should that be the case).
         */
        return inherited(fact);
    }
    
        
    /* 
     *   It makes senss to list sources on a Thought, since for the most part we'll be listing what
     *   the player character has been told, not what the PC necessarily believes to be the case (as
     *   it otherwise would appear without attribution of the facts) and it's conceivable that
     *   different sources may have given conflicting information to the Player Character, so it
     *   becomes important for our response to say something like "John told us that Bill killed
     *   Janet and Mavis told us that Bill died of natural causes."
     */
    listSources = true
    
    /*   
     *   The listing with attributions will likely look better and be easier to follow if it
     *   includes like breaks between facts.
     */
    addLineBreaks = true
    
    /* 
     *   There's no point updating Facts with the sources of the Player Character's own thought; the
     *   response to THINK ABOUT X should report on what the Player Charater already knows without
     *   changing the game state.
     */
    updateSources = nil
;

    
    
/* Modifications to Topic Entry to work with Facts */
modify TopicEntry
    /* 
     *   We can use revealFact(tag) to both reveal the tag (add it to the list of fact tags that
     *   have been revealed and stored in the player character's informedNameTab - what the PC has been
     *   informed about) and display the description of the corresponding Fact. We need to use this
     *   method if we want the game to keep track of who has imparted particular facts to the Player
     *   Character. Game authors will most likely use this method in the topicResponse of AskTopics
     *   or QueryTopics.
     */
    revealFact(tag)
    {
        /* If for any reason we're called with a nil tag, simply return nil and end there. */
        if(tag == nil) return nil;   
        
        /*
         *   If the informOnReveal option is true, then we want to both update the revealed list on
         *   libGlobal and the informedNameTab on the Player Character (and the call to gReveal will do
         *   both).
         */
        if(libGlobal.informOnReveal)        
            gReveal(tag); 
        /* Otherwise we just update the player character's informedNameTab. */
        else
            gPlayerChar.setInformed(tag);
        
        /* Get the fact associated with tag. */
        local fact = factManager.getFact(tag);
        
        /* 
         *   Add getActor (our current interlocutor or possibly consultable) to our fact's list of
         *   sources.
         */
        fact.addSource(getActor);
        
        /*  
         *   return our fact's description, which can be embedded in our topicResponse or an element
         *   of our eventList.         */
         
        return fact.qualifiedDesc(getActor, topicMatched);
    }
    
    /* 
     *   We can use informFact to update our current interlocutor's InformedTab list (removing th
     *   need to use a separate <.inform> tag to do so), to update the fact's target list (i.e. the
     *   list of people who have been informed of the fact by the current player character), and to
     *   return a description of the fact that can be embedded in the topicResponse of a TellTopic,
     *   or SayTopic. The actor parameter, if specified, should be the actor being informed, which
     *   will usually be the current interlocutor in a conversational context.
     */
    informFact(tag, actor = getActor())
    {
        /* If for any reason we're called with a nil tag, simply return nil and end there. */
        if(tag == nil) return nil;        
        
        /* 
         *   Update our current interloctutor's (or actor's if a different actor is specified)
         *   informedNameTab with our fact tag name.
         */
        actor.setInformed(tag);
        
        /* Get the fact corresponding to the tag. */
        local fact = factManager.getFact(tag);
        
        /* 
         *   Add actor to the fact's list of targets (the people to whom this fact has been
         *   imparted). Note that the library does nothing with this list; it's available for game
         *   code to use as desired.
         */
        fact.addTarget(actor);
        
        /* 
         *   Return a description of the Fact that can be used in this TopicEntry's showResponse()
         *   method or eventList property.
         */
        return factManager.getQualifiedFactDesc(gActor, tag, topicMatched);
    }
    
    /* 
     *   Simply display the descrption of the Fact corresponding to tag without changing the game
     *   state. This might conceivably be of use, for example, in a Thought.
     */
    factText(tag, actor = getActor)
    {
        return factManager.getQualifiedFactDesc(actor, tag, topicMatched);
    }    
    
;

/* Modifications to ActorTopicEntry to work with Facts. */
modify ActorTopicEntry
    /* The knowledge tag associated with this ActorTopicEntry. If it's nil, we ignore it. */
    aTag = nil
    
    /* If we define a aTag we're only active if our associated actor knows about our aTag. */
    active = inherited && (aTag == nil && tTag == nil) ? true : 
                           (aTag ? getActor.informedAbout(aTag) :
                           gActor.informedAbout(tTag))                          
        
    /* Carry out additional initialization to set our matchObj from our aTag */
    initializeTopicEntry()
    {
        /* First carry out the inherited handling. */
        inherited();
        
        /* 
         *   If we have a non-nil aTag or tTag and the user hasn't already set matchObj, set
         *   matchObj from the Fact defined by aTag if it's non-nil or else tTag.
         */
        if((aTag || tTag) && matchObj == nil)
        {
            /* Obtain the Fact corresponding to whichever tag is non-nil */
            local fact = gFact(aTag ?? tTag);
            
            /* If we found one, set our matchObj to our fact's topic list. */
            if(fact)
                matchObj = fact.topics;
        }
    }
    
    /* 
     *   Short-name method for retrieving the description of the fact associated with aTag and
     *   updating what the player character knows and the fact's list of sources.
     */
    revTag()
    {
        return revealFact(aTag);
    }
    
    /* 
     *   Short-nae method of retrieving the description of the fact associated with aTag or tTag
     *   without carrying out any further side-effects.
     */
    fText() { return factText(aTag ?? tTag); }
    
    tTag = nil
    
    infTag() { return informFact(tTag); } 
    
;

modify InitiateTopic
    /* Modification to allow InitiateTopic to match a Fact name. */
    matchTopic(top)
    {
        /* Store a reference to our caller in our agendaItem property. */
        agendaItem = libGlobal.agendaItem;
        
        /* If we have a matchPattern, first test whether it's a fact name. */
        if(matchPattern != nil && matchPattern == top)
        {
            /* Attempt to find the fact with name top. */
            local fact = gFact(top);
            
            /* I've we've found a fact, proceed accordinglay. */
            if(fact)
            {
                /* Note the fact we have matched. */
//                topicMatched = fact;
                
                /* 
                 *   If our topicResponse is going to reveal information about thio fact, set out
                 *   rTag (= aTag) to the fact name just matched.
                 */
                if(revealing)
                    rTag = top;
                
                /* 
                 *   Note that we don't set tTag otherwise, since if the actor isn't imparting new
                 *   information but instead asking a queastion, we must assume that no factual
                 *   information has yet been conveyed in either direction.
                 */
                
                
                /* Return the sum of our matchScore and scoreBooster */
                return matchScore + scoreBooster();
            }
        }
        
        /* Otherwise return our inherited score. */
        return inherited(top);
    }
    
    /* Flag: is the actor revealing information abouut the flag matched? */
    revealing = true   
;

/* 
 *   Modications to AltTopic to work with the modifications to ActorTopicEntry with the FACTS
 *   module.
 */
modify AltTopic
    /* Take our tTag from our location's tTag */
    tTag = location.tTag
    
    /* Take our rTag from our location's aTag */
    aTag = location.aTag
    
    /* Take our matchoObj from our location's matchObj */
    matchObj = location.matchObj
    
    /* Take our revealing flag from our location's revealing */
    revealing = location.revealing
;

/* 
 *   modify actorPreinit so that factMananger's happens first. This ensures that factManager's
 *   factTab has been populated and is availabe to actor-related object preinitialization.
 */
modify actorPreinit
    execBeforeMe = inherited + factManager;   
;

modify thingPreinit
   execBeforeMe = inherited + factManager;   
; 
    
/* 
 *   Modifications to the Consultable class to allow it to include fact tag strings in its
 *   topicEntryList. This consists of a list of items each of which is itself a list; item{1],
 *   passed at the topkey parameter, is the Thing or Topic to be matched; item[2], passed at the txt
 *   parameter, is either the text to be displayed or a fact name string for a fact whose
 *   descriptiopn we want displayed.
 */
modify Consultable
     setTopicResponse(top, topkey, txt)
    {
        /* First attempt to get the fact corresponding to the txt stroing */
        local fact = gFact(txt);
        
        /* 
         *   If we find one, replace txt with the desc of gFact(txt) plus a tag to reveal the fact
         *   to the player character. Otherwise we'll skip this and simply set up our new
         *   ConsultTopic to display txt.
         */
        if(fact)
        {            
            /* Store txt in a new local variable .*/
            local tag = txt;
            
            /* 
             *   Construct the <.reveal tag> or <.knoew tag> to reveal the fact to the player
             *   character, dependinng on whether libGobal.informOnReveal is true or false.
             */
            local rTag = '. <.' + (libGlobal.informOnReveal ? 'reveal ' : 'known ') + tag + '>';
            
            /* 
             *   Set txt to the qualified desription of our fact, adjusted according to the source
             *   of information (this Consultable) and the topic being looked up (topkey).
             */
            txt = fact.qualifiedDesc(self, topkey);    
            
            /* 
             *   Prepend the instructio to make the first letter of txt upper case and append our
             *   reveal tag.
             */
            txt ='\^' + txt + rTag;
            
            /* Add this Consultable as a source of informatio about our fact. */
            fact.addSource(self);
        }
        
        /* Carry out the inherited handling. */
        inherited(top, topkey, txt);  
    }
;

#ifdef __DEBUG
/* Debgugging command to list all the Facts defined in the game. */
VerbRule(ListFacts)
    'list' 'facts'
    :VerbProduction
    action = ListFacts
    verbPhrase = 'list/listing facts'
;

DefineSystemAction(ListFacts)
    execAction(cmd)
    {
        /* First check whether any facts have been added to the facts table. */
        if(factManager.factTab == nil)
        {
            DMsg(no facts defined, 'No Facts have been defined in this game. ');
            return;
        }
        
        /* Get a list of fact names */
        local keyList = factManager.factTab.keysToList();
        
        /* Sort the list of facts in alphabetical order of their names. */
        keyList = keyList.sort(nil, {a,b: a.compareTo(b)});
        
        /* Then list each fact name along with its corresponding description. */
        foreach(local item in keyList)
        {
            "<b><<item>></b>: <<factManager.getFactDesc(item)>>\n";
        }
    }
;

VerbRule(FactInfo)
    'fact' 'info' literalDobj
    : VerbProduction
    action = FactInfo
    verbPhrase = 'show/showing fact info'
    missingQ = 'which fact do you want info for'
;

DefineSystemAction(FactInfo)
    execAction(cmd)
    {
        literal = cmd.dobj.name.toLower;
        
        local fact = factManager.getFact(literal);
        
        if(fact == nil)
        {
            DMsg(no such fact, '''No fact with the name '<<literal>>' is defined in the game. ''');
            return;
        }
        
        "Name = <<fact.name>>\n";
        "Desc = <<fact.desc>>\n";
        "Topics = <<showContents(fact.topics)>>\n";
        "Initially Known By = <<showContents(fact.initiallyKnownBy)>>\n";
        "Currenly Known By = <<showContents(fact.currentlyKnownBy())>>\n";
        
    }
    
    showContents(lst)
    {
        local i = 0;
        "[";
        foreach(local obj in lst)
        {
            "<<obj.name>>";
            if(++i < lst.length)
                ", ";
        }
        
        "]"; 
    }
;

#endif