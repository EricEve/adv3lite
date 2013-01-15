#include "advlite.h"

/* ------------------------------------------------------------------------ */
/*
 *   A Command describes the results of parsing one player predicate - that
 *   is, a single verb phrase, with all its parts.  This includes the
 *   action to be performed and the objects to perform it on.  It also
 *   includes information on the text of the player's input, and how it
 *   maps onto the grammar structures defined by the language module.
 *   
 *   The Command object is built in several steps, so its contents aren't
 *   complete until all of the steps are completed.  
 */
class Command: object
    /* 
     *   Create the command object.  There are several ways to create a
     *   command:
     *   
     *   new Command(parseTree) - create from a parsed command syntax tree.
     *   
     *   new Command(action, dobjProd...) - create from a given Action and
     *   a set of parsed syntax trees for the noun phrases.  The first noun
     *   phrase is the direct object, the second is the indirect object,
     *   and the third is the accessory.
     *   
     *   new Command(action, dobjs...) - create from a given Action and a
     *   set of objects or object lists for the noun slots.  The first
     *   argument after the Action, dobjs, can be a single Mentionable
     *   object to use as the resolved direct object, or a list or vector
     *   of Mentionables to use as the multiple direct objects.  The next
     *   argument is in the same format and is used for the indirect
     *   object.  The third is the accessory.
     *   
     *   new Command(actor, action, dobjs...) - create from a given actor
     *   (as a Mentionable object), an Action object, and the object list.
     *   
     *   new Command() - create a blank Command, for setting up externally
     *   or in a subclass.  
     */
    construct([args])
    {
        /* presume the command will be implicitly addressed to the PC */
        actor = gPlayerChar; //World.playerChar;

        /* check the various argument list formats */
        if (args.matchProto([Production]))
        {
            /* build the command from the parse tree */
            args[1].build(self, nil);

            /* save the parse tree */
            parseTree = args[1];
        }
        else if (args.matchProto([Action, '...'])
                 || args.matchProto([Mentionable, Action, '...']))
        {
            /* retrieve and skip the actor, if present */
            local i = 1;
            if (!args[i].ofKind(Action))
                actor = args[i++];

            /* retrieve the action */
            action = args[i++];

            /* the additional arguments are for the noun phrase slots */
            local roles = NounRole.all, rlen = roles.length();
            local alen = args.length();
            for (local r = 1 ; r <= rlen && i <= alen ; ++i, ++r)
            {
                /* get this noun phrase match tree or object list */
                local np = args[i];

                /*
                 *   Check the type of this argument: if it's a Production,
                 *   it's a parse tree to build into a NounPhrase list for
                 *   the slot.  If it's a list/vector, it's a list of
                 *   resolved objects for the slot. 
                 */
                if (np.ofKind(Production))
                {
                    /* parse tree - assign the role for this noun phrase */
                    np.nounPhraseRole = roles[r];

                    /* build it */
                    np.build(self, addNounListItem(roles[r], np));
                }
                else if (np.ofKind(List))
                {
                    /* it's an object list - save a copy */
                    self.(roles[r].objListProp) = np;
                }
                else if (np.ofKind(Vector))
                {
                    /* it's an object vector - save a list copy */
                    self.(roles[r].objListProp) = np.toList();
                }
                else if (np.ofKind(Mentionable))
                {
                    /* single object - make it into a single-element list */
                    self.(roles[r].objListProp) = [np];

                    /* also set it as the current object */
                    self.(roles[r].objProp) = np;

                    /* synthesize an NPMatch object for it */
                    local m = new NPMatch(nil, np, 0);
                    m.flags = SelProg;
                    self.(roles[r].objMatchProp) = m;
                   
                }
                else
                    throw new ArgumentMismatchError();
            }
        }
        else if (args.matchProto([]))
        {
            /* no arguments - they just want a basic empty command */
        }
        else
            throw new ArgumentMismatchError();

        /* set up the reflexive antecedent table (if we didn't already) */
        if (reflexiveAnte == nil)
            reflexiveAnte = new LookupTable(16, 32);
    }

    /* clone - create a new Command based on this Command */
    clone()
    {
        /* create a new object with my same property values */
        local cl = createClone();

        /* 
         *   make a copy of the antecedent table, so that changes made in
         *   the clone don't affect the original, and vice versa 
         */
        cl.reflexiveAnte = new LookupTable(16, 32);
        reflexiveAnte.forEachAssoc({ key, val: cl.reflexiveAnte[key] = val });

        /* likewise the object list vectors, if any */
        foreach (local role in npList)
        {
            local v = cl.(role.objListProp);
            if (v.ofKind(Vector))
                cl.(role.objListProp) = new Vector(v.length(), v);
        }

        /* return the clone */
        return cl;
    }

    /* clone a noun phrase that's part of this command */
    cloneNP(np)
    {
        /* create a clone of the noun phrase */
        local cl = np.clone();

        /* find and replace the original copy with the clone */
        foreach (local role in npList)
        {
            /* look for 'np' in this role's list of noun phrases */
            local idx;
            if ((idx = self.(role.npListProp).indexOf(np)) != nil)
            {
                /* found it - replace it with the clone, and we're done */
                self.(role.npListProp)[idx] = cl;
                break;
            }
        }

        /* return the clone */
        return cl;
    }

    /*
     *   Execute the action.  This carries out the entire command
     *   processing sequence for the action.  If the action involves a list
     *   of objects (as in TAKE ALL or DROP BOOK AND CANDLE), we iterate
     *   over the listed objects, executing the action on each object in
     *   turn.  
     */
    exec()
    {
        try
        {
            action.reset();
            gAction = action;
            lastAction = nil;
            gCommand = self;
            if(action.isRepeatable)
                libGlobal.lastCommand = self.createClone();
            
            if(action.includeInUndo && verbProd != nil)
            {
                local str = '';            
                foreach(local tok in nilToList(verbProd.tokenList))
                {
                    str += getTokVal(tok) + ' ';
                }
                libGlobal.lastCommandForUndo = str;
                savepoint();
            }
            
            /* 
             *   First, carry out the group action.  This gives the verb a
             *   chance to perform the action collectively on all of the objects
             *   at once.
             */
            
            
            //        action.reportList = [];
            //        action.afterReports = [];
            action.execGroup(self);
            
            
            /* 
             *   Get the list of predicate noun roles.  We only iterate over the
             *   noun roles that are verb arguments.
             */
            local predRoles = npList.subset({ r: r.isPredicate });
            
            /* 
             *   If we have any noun phrases, iterate over each combination of
             *   objects.  Otherwise, this is an intransitive verb, so just
             *   perform a single execution of the Action, with no objects.
             */
            if (predRoles.length() == 0)
            {
                /* it's intransitive - just execute once */
                execDoer([action]);
            }
            else
            {
                /* 
                 *   It's transitive, so execute iteratively over the objects.
                 *   First, generate the distinguished object names for each
                 *   list.
                 */
                foreach (local role in predRoles)
                {
                    /* get the NPMatch list for this role */
                    local matches = self.(role.objListProp);
                    
                    /* get the list of names for this role's list of objects */
                    local names = Distinguisher.getNames(
                        matches.mapAll({ m: m.obj }), nil);
                    
                    /* 
                     *   Assign each NPMatch object its name from the name list.
                     *   The name list is of the form [name, [objects]], so for
                     *   each object, we need to find the element n such that
                     *   n[2] (the object list) contains the object in question,
                     *   then retrieve the name string from n[1].
                     */
                    matches.forEach(
                        { m: m.name = names.valWhich(
                            { n: n[2].indexOf(m.obj) != nil })[1] });
                }
                
                /* 
                 *   execute for each combination of objects, starting with the
                 *   objects in the first role list
                 */
                execCombos(predRoles, 1, [action]);
            }
            
            /* Allow the action to summarize or report on what it has just done */
            
            action.reportAction();        
            
            /* 
             *   This is a kludgy fix to force a report of a redirected action,
             *   but a better solution is needed long-term
             */
            if(lastAction not in (nil, action))
            {
                action = lastAction;
                action.reportAction();
//                gAction = action;
            }
            
            /* List our own sequence of afterReports, if we have any. */
            afterReport();
            
            /* Carry out the after action handling for the current action */
            action.afterAction();
            
            /* 
             *   Carry out the turn sequence handling (daemons and turn count
             *   increment) for the current action.
             */
            action.turnSequence();
            
           
        }
        catch(AbortActionSignal aas)
        {
            /* 
             *   An AbortActionSignal skips the rest of the command including
             *   the post-action processing such as daemons and advancing the
             *   turn counter; the idea is that an abort command (macro)
             *   effectively cancels the entire command, or at least the rest of
             *   the command from the point it's issued.
             */
        }
    }
    
     /*   
     *   A list of strings containing reports to be displayed at the end of the
     *   command execution cycle for this command.
     */
    
    afterReports = []
    
    
    
    /* 
     *   Run through our list of afterReports displaying each in turn. We do
     *   this on the Command rather than on any of the Actions since actions may
     *   invoke other actions (implicit, remapped, nested or replaced), while
     *   the afterReports pertain to the command as a whole.
     */
    
    afterReport()
    {
        foreach(local cur in afterReports)
        {
            "<.p>";
            say(cur);
        }
    }
    
    /* 
     *   A list of reports of previous implicit actions performed in the course
     *   of executing this command which can be used if we need to collate a
     *   report of a stack of implicit actions.
     */
  
    
    implicitActionReports = []

    /*
     *   Execute the command for each combination of objects for noun role
     *   index 'n' and above.  'lst' is a list containing a partial object
     *   combination for roles at lower indices.  We iterate over each
     *   combination of the remaining objects.  
     */
    execCombos(predRoles, n, lst)
    {
        /* get this slot's role */
        local role = predRoles[n];

        /* iterate over the objects in the slot at this index */
        foreach (local obj in self.(role.objListProp))
        {
            /* set the current object and selection flags for this role */
            self.(role.objProp) = obj.obj;
            self.(role.objMatchProp) = obj;

            /* create a new list that includes the new object */
            local nlst = lst + obj.obj;

            /* 
             *   if there are more noun roles, recursively iterate over
             *   combinations of the remaining roles 
             */
            if (n < predRoles.length())
            {
                /* we have more roles - iterate over them recursively */
                execCombos(predRoles, n+1, nlst);
            }
            else
            {
                /* 
                 *   this is the last role - we have a complete combination
                 *   of current objects now, so execute the action with the
                 *   current set 
                 */
                execIter(nlst);
            }
        }
    }

    /*
     *   Execute one iteration of the command for a particular combination
     *   of objects.  'lst' is the object combination to execute: this is
     *   an [action, dobj, iobj, ...] list.  
     */
    execIter(lst)
    {
       
        try
        {         
            /* carry out the default action processing */
            execDoer(lst);
        }
        catch (ExitSignal ex)
        {
        }
            
    }

    /*
     *   Execute the command via the Doers that match the command's action
     *   and objects.  'lst' is the object combination to execute: [action,
     *   dobj, iobj, ...].  
     */
    execDoer(lst)
    {
        /* find the list of matching Doers */
        local dlst = DoerCmd.findDoers(lst);
      
        dlst[1].exec(self);
        
    }
    
  
    /*
     *   Invoke a callback for each object in the current command
     *   iteration.  This invokes the callback on the direct object,
     *   indirect object, accessory, and any other custom roles added by
     *   the game.  
     */
    forEachObj(func)
    {
        
        try
        {
            /* loop over the occupied roles */
            foreach (local role in npListSorted)
            {
                /* if this role is occupied, invoke the callback */
                local obj = self.(role.objProp);
                if (obj != nil)
                    func(role, obj);
            }
        }
        catch (BreakLoopSignal sig)
        {
            /* we've broken out of the loop, so 'sig' is now handled */
        }
    }
    

    /*
     *   Are terse messages OK for this command?  A terse message is a
     *   simple acknowledgment of a standard command, such as "Taken",
     *   "Dropped", "Done", etc.  The action is so ordinary that the result
     *   of a successful attempt should be obvious to the player; so the
     *   only reply needed is an acknowledgment, not an explanation.
     *   
     *   Terse replies only apply to simple actions, and only when the
     *   actor is the player character, AND there's no disambiguation
     *   involved.  If the actor isn't the PC, an acknowledgment isn't
     *   sufficient; we should instead describe the NPC carrying out the
     *   action, since it's something we observe, not something we do.  If
     *   any objects were disambiguated, we also want to describe the
     *   action fully, because the ambiguity calls for a description of
     *   precisely which objects were chosen.  Disambiguation guesses are
     *   sometimes wrong, so when they're involved, it's not safe to assume
     *   that the player and parser must both be thinking the same thing.
     *   Showing a full description of the action will make it obvious to
     *   the player when we guessed wrong, because the description won't
     *   accord with what they had in mind.  A terse acknowledgment would
     *   hide this difference, allowing the player to wrongly assume that
     *   the parser did what they thought it was going to do and
     *   potentially leading to confusion down the road.  
     */
    terseOK()
    {
        /* use full messages for NPC-directed commands */
        if (actor != gPlayerChar)
            return nil;

        /* 
         *   use full message for commands where ALL was used, since
         *   the player might not otherwise know what ALL referred to.
         */
        
        if(matchedAll || matchedMulti)
            return nil;
        
        /* check all noun roles for Disambig flags */
        foreach (local role in npList)
        {
            /* 
             *   if this is a predicate role, and there's an object in this
             *   slot with the Disambig flag, don't allow terse messages 
             */
            if (role.isPredicate
                && self.(role.objProp) != nil
                && (self.(role.objMatchProp).flags & SelDisambig) != 0)
                return nil;
        }

        /* 
         *   If we're reporting on fewer objects than the player requested then
         *   we'd better be specific about which ones we mean.
         */
        
        
        if(dobjs.length > action.reportList.length)
            return nil;
        
        /* we have no objection to terse messages */
        return true;
    }

    /* 
     *   Add a noun production, building it out as though it had been part
     *   of the original parse tree.  This can be used to add a noun phrase
     *   after the initial parsing, such as when the player supplies a
     *   missing object. 
     */
    addNounProd(role, prod)
    {
        /* create a noun list item for the production */
        local np = addNounListItem(role, prod);

        if(npListSorted.length != npList.length)
            npListSorted = npList;        
        
        
        /* build the tree */
        prod.nounPhraseRole = role;
        prod.build(self, np);

        /* let the verb production know about the change */
        verbProd.answerMissing(self, np);
    }

    /* add a noun phrase to the given role (a NounRole) */
    addNounListItem(role, prod)
    {
        /* create the new noun phrase object of the appropriate type */
        local np = prod.npClass.createInstance(nil, prod);

        /* remember the role in the noun phrase */
        np.role = role;

        /* add it to the given list */
        self.(role.npListProp) += np;

        /* 
         *   If this role isn't already in our list or roles, and it has a
         *   match property, add it.  Roles without match properties aren't
         *   predicate noun roles, so they don't go in our predicate object
         *   list.  
         */
        if (npList.indexOf(role) == nil)
        {
//            
            npList += role;
            
            /* 
             *   if the action is a TIAction then make sure the Direct and
             *   Indirect Objects are dealt with in the right order as specified
             *   by the action's resolveIobjFirst property. We do this on a copy
             *   of the list (npSorted) so we don't break anything that needs
             *   the original order (such as matching a Doer).
             */
            
            npListSorted = npList;
            
            if(action != nil && action.ofKind(TIAction))
            {
                local doIdx = npListSorted.indexOf(DirectObject);
                local ioIdx = npListSorted.indexOf(IndirectObject);
                if(doIdx != nil && ioIdx != nil)
                {
                    if((action.resolveIobjFirst && ioIdx > doIdx)
                        ||  (!action.resolveIobjFirst && doIdx > ioIdx))
                    {
                        npListSorted[ioIdx] = DirectObject;
                        npListSorted[doIdx] = IndirectObject;
                    }
                }
            }
        }

        /* return the new noun phrase */
        return np;
    }

    /* 
     *   Start processing a new disambiguation reply.  This adds a reply to
     *   a disambiguation question.  
     */
    startDisambigReply(parent, prod)
    {
        /* create the first NounPhrase for this reply */
        local np = new NounPhrase(parent, prod);

        /* add a new NounPhrase list to the reply list */
        disambig = disambig.append([np]);

        /* return the new noun phrase */
        return np;
    }

    /* 
     *   Add a disambiguation list item.  This adds a NounPhrase item to
     *   the current reply list.
     */
    addDisambigNP(prod)
    {
        /* get the current reply list */
        local idx = disambig.length(), lst = disambig[idx];

        /* create the new noun phrase */
        local np = new NounPhrase(lst[1].parent, prod);

        /* add it to the current disambiguation reply list */
        disambig[idx] = lst + np;

        /* return it */
        return np;
    }

    /*
     *   Fetch a disambiguation reply.  If we have more replies available,
     *   this returns the next reply's noun phrase list, otherwise nil.  
     */
    fetchDisambigReply()
    {
        return (disambigIdx <= disambig.length()
                ? disambig[disambigIdx++]
                : nil);
    }

    /* mark a noun phrase role as empty */
    emptyNounRole(role)
    {
        /* if this role isn't in our list yet, add it */
        if (npList.indexOf(role) == nil)
            npList += role;

        /* count the missing phrase */
        ++missingNouns;

        /* clear out the role list */
        self.(role.npListProp) = [];
    }

    /* resolve the noun phrases */
    resolveNouns()
    {
        /* we don't have an error for this resolution pass yet */
        cmdErr = nil;

        /* we haven't started pulling disambiguation replies yet */
        disambigIdx = 1;

        /* 
         *   Start by getting the basic vocabulary matches for each noun
         *   phrase.  Run through each noun phrase list.  
         */
        forEachNP({ np: np.matchVocab(self) });

        /* 
         *   Before we do the object selection, build the tentative lists
         *   of resolved objects.  This can be handy during disambiguation
         *   to help decide the resolution of one slot based on the
         *   possible values for other slots.  For example, for PUT COIN IN
         *   JAR, it might help us choose a coin to know that the iobj is
         *   JAR.  
         */
        buildObjLists();

        /* determine the actor */
        if (actorNPs != [])
        {
            /* 
             *   We have an explicit addressee.  If we have more than one
             *   object for the actor phrase, disambiguate to a single
             *   object.  Disambiguate in the context of TALK TO.  
             */
            local anp = actorNPs[1];
            if (anp.matches.length() > 1)
                anp.disambiguate(self, 1, TalkTo);
            if (anp.matches.length() == 0)
                throw new UnmatchedActorError(anp);

            /* pull out the match as the actor object */
            actor = anp.matches[1].obj;
        }

        /* 
         *   select the objects from the available matches according to the
         *   grammatical mode (definite, indefinite, plural) 
         */
        forEachNP({ np: np.selectObjects(self) });

        /* 
         *   Go back and re-resolve ALL lists.  For two-object commands,
         *   resolving ALL in one slot sometimes depends on resolving the
         *   object in the other slot first. 
         */
        forEachNP({ np: np.resolveAll(self) });

        /*
         *   Set up the second-person reflexive pronoun antecedent.  For a
         *   command addressed in the imperative form to an NPC (e.g., BOB,
         *   EXAMINE YOURSELF), YOU binds to the addressee.  For anything
         *   else (e.g., EXAMINE YOURSELF, or TELL BOB TO EXAMINE
         *   YOURSELF), YOU binds to the player character.  
         */
        if (reflexiveAnte != nil)
        {
            if (actorNPs != [] && actorPerson == 2)
            {
                /* imperative addressed to an actor: YOU is the actor */
                reflexiveAnte[You] = [actor];
            }
            else
            {
                /* for anything else, YOU is the PC */
                reflexiveAnte[You] = [gPlayerChar]; //[World.playerChar];
            }
        }

        /*
         *   Resolve reflexive pronouns (e.g., ASK BOB ABOUT HIMSELF).  We
         *   have to do this as a separate step because reflexives refer
         *   back to other noun phrases in the same command.  We can't do
         *   this until after we resolve everything else.  
         */
        forEachNP({ np: np.resolveReflexives(self) });

        /* check for empty roles */
        foreach (local role in npList)
        {
            if (self.(role.npListProp).length() == 0)
                throw new EmptyNounError(self, role);
        }

        /* 
         *   Clear out the old object lists, then build them anew.  The old
         *   object lists were tentative, before disambiguation; we want to
         *   replace them now with the final lists. 
         */
        buildObjLists();
    }

    /* carry out a callback for each noun phrase in each list */
    forEachNP(func)
    {       
        /* run through each noun phrase list in the command */
        foreach (local role in npListSorted)
        {
            /* run through each NounPhrase in this slot's list */
            foreach (local np in self.(role.npListProp))
            {
                /* invoke the callback on this item */
                func(np);
            }
        }
    }

    /* 
     *   Build the object lists.  This runs through each NounPhrase in the
     *   command to build its 'objs' list, then builds the corresponding
     *   master list in the Command object.  
     */
    buildObjLists()
    {
        /* run through each active noun phrase list */
        foreach (local role in npList)
        {
            /* set up a vector to hold this list's nouns */
            self.(role.objListProp) = new Vector(10);

            /* build the object list for each NounPhrase */
            foreach (local np in self.(role.npListProp))
            {
                /* build the list */
                np.buildObjList();

                /* append it to the master match list for this slot */
                self.(role.objListProp).appendAll(np.matches);
            }
        }
    }

    /*
     *   Save a potential antecedent for a reflexive pronoun coming up
     *   later in the command.  Each time we visit a noun phrase during the
     *   reflexive pronoun phase, we'll note its resolved objects here.
     *   Since we visit the noun phrases in their order of appearance in
     *   the command, we'll naturally always have the latest one mentioned
     *   when we come to a reflexive pronoun.  This gives us the correct
     *   resolution, which is the nearest preceding noun.  Note that the
     *   noun phrase shouldn't call this routine to note reflexive
     *   pronouns, since they don't bind to earlier reflexive pronouns -
     *   they only bind to regular noun phrases.  
     */
    saveReflexiveAnte(obj)
    {
        /* if we don't have a reflexive antecedent table, skip this */
        if (reflexiveAnte == nil)
            return;

        /* if the object isn't already a list, wrap it in a list */
        local lst = obj;
        if (!lst.ofKind(Collection))
            lst = [obj];

        /* 
         *   Run through the regular pronoun list, and save this object
         *   with the pronouns that apply to this object.  Note that a
         *   given object might match multiple pronouns, so we might save
         *   the object for several different pronouns.  
         */
        foreach (local p in Pronoun.all)
        {
            if (p.matchObj(obj))
                reflexiveAnte[p] = lst;
        }
    }

    /*
     *   Resolve a reflexive pronoun on behalf of one of the NounPhrases
     *   within this command.  
     */
    resolveReflexive(pronoun)
    {
        /* if there's no table, there's no antecedent */
        if (reflexiveAnte == nil)
            return [];

        /* get the meaning from the reflexive antecedent table */
        local ante = reflexiveAnte[pronoun];

        /* if there's no antecedent defined, return an empty list */
        if (ante == nil)
            ante = [];

        /* return the result */
        return ante;
    }

    /* table of reflexive pronoun antecedents */
    reflexiveAnte = nil

    /*
     *   Class method: Sort a list of Command matches, in priority order.
     *   The priority order is the order for processing predicate grammar
     *   matches: start at the highest priority, and work through the list
     *   until you find one where the noun phrases resolve to valid
     *   game-world objects; that's the one to execute.  
     */
    sortList(cmdLst)
    {
        /* pre-calculate the priorities, to save work during the sort */
        foreach (local cmd in cmdLst)
            cmd.fixPriority();

        /* sort in descending order of priority */
        return cmdLst.sort(SortDesc, {a, b: a.priority - b.priority});
    }

    /*
     *   Calculate the parsing priority.
     *   
     *   When the parser looks for grammar rule matches to the input, it
     *   considers *all* of the possible matches.  Natural language is full
     *   of syntactic ambiguity, so a given input string can often be
     *   parsed into several different, but equally valid, syntax trees.
     *   It's often impossible to tell which parsing is correct based on
     *   syntax alone - you often have to look at the overall meaning of
     *   the sentence.  For example, GIVE BOOK TO BOB could be interpreted
     *   as having a direct object (BOOK) and an indirect object (BOB), or
     *   it could be seen as having only a direct object (BOOK TO BOB,
     *   treating the TO as a prepositional phrase modifying BOOK rather
     *   than as a part of the verb phrase structure).  The initial parsing
     *   phase only looks at the syntax, so it has to consider all of the
     *   valid phrase structures, even though a human speaker would
     *   immediately dismiss many of them as nonsensical.  Once we find all
     *   of the syntax matches, the parser puts them into priority order,
     *   and then goes down the list looking for the first one that makes
     *   sense semantically (which is defined roughly as having noun
     *   phrases that refer to actual objects).
     *   
     *   The priority, then, represents our guess at the likelihood that
     *   the grammar structure matches the user's intentions, based on the
     *   syntax.  Our fundamental assumption is that the command is valid:
     *   that is, it's well-formed grammatically, AND it expresses
     *   something that's possible, or at least logical to try, within the
     *   game-world context.  Given this, our strategy is to find a grammar
     *   structure that gives us a command that we can actually carry out.
     *   
     *   The priority is a composite value, made up of weighted component
     *   values.  We combine the components into a single scalar value
     *   simply by adding up the parts multiplied by their weights.  (Or,
     *   looked at another way, we combine the values using a high-radix
     *   numbering system.)  The components are, from most significant to
     *   least significant:
     *   
     *   - Grammatically correct commands sort ahead of commands with
     *   structural errors.
     *   
     *   - The predicate priority, from the VerbProduction.  (This tells us
     *   how "complete" the predicate structure is: a predicate with
     *   missing information has a lower priority.  This is in keeping with
     *   our assumption that the user's input is well-formed - we'll try
     *   the most complete structures first before falling back on the
     *   possibility that the user left out some information.)
     *   
     *   - Filled noun slots ahead of missing noun slots.  A missing noun
     *   slot occurs when the player leaves one of the noun roles empty
     *   (PUT BOX, TAKE).  We can fill in this information with automatic
     *   defaults, so it's not necessarily a reason to reject the parsing,
     *   but if there's another interpretation that has fully occupied noun
     *   slots, try the occupied one first.
     *   
     *   - More noun phrase slots first.  For example, sort a command with
     *   a direct and indirect object (two slots) ahead of one with only a
     *   direct object.  More slots means that we found more "structure" in
     *   the command; we can sometimes interpret the same command with less
     *   structure by subsuming more words into a long noun phrase.
     *   
     *   - Longest noun phrases, in aggregate, first.  This is in terms of
     *   tokens matched from the user input.  (We want to consider longer
     *   noun phrases first because it's more likely that they'll match
     *   exact objects, so there's less chance of ambiguity, *and* it's
     *   more likely that if we're wrong about the structure, we'll simply
     *   fail to find a matching object and move on to other parse trees.
     *   Longer noun phrases are less likely to yield spurious matches
     *   simply because they have more words that have to match.)
     *   
     *   - Grammatical noun phrases take priority over misc word phrases (a
     *   misc word phrase is text in a noun phrase slot that doesn't match
     *   any of the defined patterns in the grammar rules).
     *   
     *   - Longest command first, in terms of tokens matched from the user
     *   input.  (The more user input we use the better, since that gives
     *   us more confidence that we're correctly interpreting what the user
     *   said.  When we leave extra tokens for later, we can't be sure that
     *   we'll be able to make any sense of what's left over, whereas
     *   tokens in the current match are known to fit a grammar rule.)  
     */
    calcPriority()
    {
        return (badMulti == nil ? 250000000 : 0)
            + predPriority*2500000
            + 500000*(4 - min(missingNouns, 4))
            + 100000*min(numNounSlots(), 4)
            + 10000*(9 - min(miscWordLists.length(), 9))
            + 100*min(npTokenLen(), 99)
            + min(tokenLen, 99);
    }

    /* 
     *   Set a fixed priority.  This makes the priority a fixed value
     *   rather than a calculated value.  We call this before sorting a
     *   list of commands, so that we don't have to recalculate the
     *   priority value repeatedly during the sort.  
     */
    fixPriority() { priority = self.calcPriority(); }

    /* note a noun phrase with a miscellaneous word list */
    noteMiscWords(np)
    {
        /* if we haven't already noted this one, add it to our list */
        if (miscWordLists.indexOf(np) == nil)
            miscWordLists += np;
    }

    /* the calculated priority */
    priority = 0

    /*
     *   List of noun phrases containing misc word phrases.  The misc word
     *   phrase grammar rules will notify us when they're visited in the
     *   build process, and we'll note them here.  
     */
    miscWordLists = []

    /*
     *   Do we have any missing or empty noun phrases in the match?  The
     *   verb and noun phrases will fill this in.  
     */
    missingNouns = 0

    /* 
     *   The number of tokens from the command line that we matched for the
     *   command.  The CommandProduction object sets this for us as it
     *   builds the command from the parse tree.  We use this to determine
     *   the priority order of the syntax matches, when there are multiple
     *   matches: other things being equal, we'll take the longest match.
     *   Longer matches are better because they come closer to using
     *   everything the user typed, which is our eventual goal.
     *   
     *   This reflects the number of tokens used in the first predicate
     *   phrase; it omits any additional predicates or conjunctions.  We
     *   only count the first predicate because we always go back and
     *   re-parse any additional text on the line from scratch after
     *   executing the first predicate, in case the execution changes the
     *   game state in such a way that the parsing changes.  
     */
    tokenLen = 0

    /* Calculate the sum of the token lengths of our noun phrases */
    npTokenLen()
    {
        /* sum the token counts of all of the noun phrases */
        local tot = 0;
        forEachNP({ np: tot += np.tokens.length() });

        /* return the sum */
        return tot;
    }

    /* Calculate the number of noun slots we have filled in */
    numNounSlots() { return npList.length(); }

    /* the predicate priority (see VerbProduction.priority) */
    predPriority = 0

    /*
     *   The parse tree (the root of the grammar match), if applicable.
     *   Commands built from user input have a parse tree; those built
     *   internally don't.  Note that the parse tree doesn't necessarily
     *   include *all* of the user input, since we could have asked
     *   questions (disambiguation, missing noun phrases) before the
     *   command was completed.  The question replies will be represented
     *   in noun phrases or other data added to the command after the
     *   initial parse.  
     */
    parseTree = nil

    /* the Action object giving the action to be performed */
    action = nil

    /* the Previous action performed by this command */
    lastAction = nil
    
    /* the VerbProduction object for the command */
    verbProd = nil

    /* the resolved actor; we determine this before disambiguation */
    actor = nil

    /* the actor(s) to whom the command is addressed, as a NounPhrase list */
    actorNPs = []

    /* the actor(s), as NPMatch objects */
    actors = []

    /*
     *   The grammatical person in which we're addressing the actor.  This
     *   is 2 for a second-person address, 3 for third-person orders.
     *   (It's hard to think of a case for first-person orders, but 
     *   
     *   The conventional IF syntax for giving orders is ACTOR, DO
     *   SOMETHING, which addresses ACTOR in the second person (as YOU).
     *   This means that second-person pronouns 
     */
    actorPerson = 2

    /* the direct object phrases, as a list of NounPhrase objects */
    dobjNPs = []

    /* the list of resolved direct objects, as NPMatch objects */
    dobjs = []

    /* the current direct object for the current action iteration */
    dobj = nil

    /* the NPMatch object for the current iteration's direct object */
    dobjInfo = nil

    /* the indirect object phrases, as a list of NounPhrase objects */
    iobjNPs = []

    /* the list of resolved indirect objects, as NPMatch objects */
    iobjs = []

    /* the indirect object for the current iteration */
    iobj = nil

    /* the NPMatch object for the current indirect object */
    iobjInfo = nil

    /* the accessory phrases, as a list of NounPhrase objects */
    accNPs = []

    /* the list of resolved accessory objects, as NPMatch objects */
    accs = []

    /* the accessory object for the current iteration */
    acc = nil

    /* the NPMatch object for the current accessory */
    accInfo = nil

    /*
     *   Disambiguation replies.  Each time the player answers a
     *   disambiguation question, we add the reply to this list.  We then
     *   go back and re-resolve the noun phrases, fetching replies from the
     *   list as we encounter the ambiguous objects again.
     *   
     *   Note that this is a list of list.  Each reply is a list of
     *   NounPhrase objects, and we might have a series of replies, so one
     *   list represents one reply.  
     */
    disambig = []

    /* the next available disambiguation reply */
    disambigIdx = 1

    /* 
     *   Is this command at the end of a sentence?  The grammar match sets
     *   this to true if the input syntax puts this predicate at the end of
     *   a sentence.  For example, in the English grammar, this is set if
     *   there's a period after this predicate.  This tells the parser that
     *   the next predicate in the same line is the start of a new
     *   sentence, so sentence-opening syntax is allowed.  
     */
    endOfSentence = nil

    /*
     *   The noun phrase roles (as NounRole objects), in the order they
     *   actually appear in the user input.  We build this list as the
     *   VerbProduction adds our noun phrases.  The phrase order is
     *   important when there are reflexive pronouns, because a reflexive
     *   pronoun generally refers back to the nearest preceding phrase of
     *   the same number and gender.  
     */
    npList = []
    
    /*  
     *   A copy of the npList sorted to ensure that the direct and indirect
     *   objects of a TIAction are verified in the order specified on that
     *   action.
     */
    
    npListSorted = []

    /* 
     *   Error flag: we have a noun list (grammatically) where a single
     *   noun is required.  When this occurs, this will be set to the role
     *   where the error was noted.  
     */
    badMulti = nil

    /*
     *   The token list for the next predicate.  The first predicate
     *   production fills this in during the build process with the token
     *   list for the next predicate on the same command line, based on the
     *   location of the conjunction or punctuation that ends the first
     *   predicate.  This is just what's left of the token list after the
     *   tokens used for our own predicate and after any conjunctions or
     *   punctuation marks that separate our predicate from the next one.  
     */
    nextTokens = []

    /* 
     *   The error we encountered building the command, if any.  This is
     *   usually a noun resolution error. 
     */
    cmdErr = nil
    
    /*   Does this command apply to objects matched to ALL? */
    
    
    matchedAll = nil
    
    /*   Does this command apply to objects matched to multiple objects? */
    matchedMulti = nil
;




/* ------------------------------------------------------------------------ */
/*
 *   A FuncCommand is a special version of Command that carries out its
 *   action via a custom callback function, rather than by executing a
 *   regular Action.  This can be used to create a simple one-off custom
 *   command without having to create a separate Action for it.  
 */
class FuncCommand: Command
    /*
     *   Create: provide the grammar match object, if any, and the callback
     *   function to execute to carry out the command. 
     */
    construct(prod, func)
    {
        /* call the appropriate inherited constructor */
        if (prod != nil)
            inherited(prod);
        else
            inherited();

        /* save the callback function */
        self.func = func;
    }

    /* the callback function for carrying out our command action */
    func = nil
;
