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
    gatTargets(actor = gPlayerChar)
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
        
        /* If we've found one, return is base desc property, otherwise return nil. */
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
        if(actor.informedNameTab== nil)
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
                 *   also adds it to the player characters informedTab).
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
     *   want to do so on a Thoght but probably not on a Consultable, so we default to nil here.
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
 *   A FactConsultTopic can be used to generate an automated response to a potentially wide
 *   range of queries directed to the associated Consultable, provided that the Consultable in
 *   question has been listed in the various relevant facts' initiallyKnownBy list (or subquently
 *   added to its informedTab if the Consultable is updatable). A DefaultFactConsultTopic can also
 *   act like a regular DefaultConsultTopic when its Consultable has no facts corresponding to the
 *   topic that's just been looked up.
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
 *   various relevant facts' initiallyKnownBy list (or subquently added to its informedTab if the
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
     *   have been revealed and stored in the player character's informedTab - what the PC has been
     *   informed about) and display the description of the corresponding Fact. We need to use this
     *   method if we want the game to keep track of who has imparted particular facts to the Player
     *   Character. Game authors will most likely use this method in the topicResponse of AskTopics
     *   or QueryTopics.
     */
    revealFact(tag)
    {
        /*
         *   If the informOnReveal option is true, then we want to both update the revealed list on
         *   libGlobal and the informedTab on the Player Character (and the call to gReveal will do
         *   both).
         */
        if(libGlobal.informOnReveal)        
            gReveal(tag); 
        /* Otherwise we just update the player character's informedTab. */
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
        /* 
         *   Update our current interloctutor's (or actor's if a different actor is specified)
         *   informedTab with our fact tag name.
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
        

#endif