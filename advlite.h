#charset "us-ascii"

/* 
 *   Copyright (c) 2000, 2006 Michael J. Roberts.  All Rights Reserved. 
 *   
 *   TADS 3 Library - main header
 *   
 *   This file provides definitions of macros, properties, and other
 *   identifiers used throughout the library and in game source.
 *   
 *   Each source code file in the library and in a game should generally
 *   #include this header near the top of the source file.  
 */

#ifndef ADV3LITE_H
#define ADV3LITE_H

/* ------------------------------------------------------------------------ */
/*
 *   Include the system headers that we depend upon.  We include these here
 *   so that each game source file will pick up the same set of system
 *   headers in the same order, which is important for intrinsic function
 *   set definitions.  
 */
#include <tads.h>
#include <tok.h>
#include <t3.h>
#include <vector.h>
#include <strbuf.h>
#include <file.h>
#include <dict.h>
#include <bignum.h>
#include <gramprod.h>
#include <strcomp.h>


/* ------------------------------------------------------------------------ */
/*
 *   Turn on sourceTextGroup property generation in the compiler.  (This lets
 *   us determine which module defined an object, and the order of the module
 *   in the overall project build.  We use this for determining the
 *   precedence of certain items based on their definition order in the
 *   source code.)  
 */
#pragma sourceTextGroup(on)
/* ------------------------------------------------------------------------ */

/* ------------------------------------------------------------------------ */
/*
 *   The '+' property sets an object's location to the lexically preceding
 *   object. 
 */
+ property location;


/*
 *   The VerbRule macro starts the definition of a verb grammar rule.  The
 *   tag is just an identifying name for the rule, so that you can refer to
 *   it with 'replace' or 'modify'.  
 */
#define VerbRule(tag)  grammar predicate(tag):

/*
 *   Verb rule noun phrase macros.  These are convenience macros for
 *   specifying the most common noun phrase slots in the grammar templates
 *   for verb rules.  
 */
#define singleDobj     singleNoun->dobjMatch
#define singleIobj     singleNoun->iobjMatch
#define singleAcc      singleNoun->accMatch
#define singleAobj     singleNoun->accMatch
#define multiDobj      nounList->dobjMatch
#define multiIobj      nounList->iobjMatch
#define accList        nounList->accMatch
#define aobjList       nounList->accMatch
#define multiAcc       nounList->accMatch
#define multiAobj      nounList->accMatch
#define numberDobj     numberPhrase->dobjMatch
#define topicDobj      topicPhrase->dobjMatch
#define topicIobj      topicPhrase->iobjMatch
#define topicAcc       topicPhrase->accMatch
#define topicAobj      topicPhrase->accMatch
#define literalDobj    literalPhrase->dobjMatch
#define literalIobj    literalPhrase->iobjMatch
#define literalAcc     literalPhrase->accMatch
#define literalAobj    literalPhrase->accMatch
#define singleDir      directionName->dirMatch
#define numericDobj    numberPhrase -> dobjMatch
#define numericIobj    numberPhrase -> iobjMatch
#define numericAcc     numberPhrase -> accMatch
#define numericAobj    numberPhrase -> accMatch

/* Also add a couple of synonyms familiar froma adv3 */
#define dobjList      nounList->dobjMatch
#define iobjList      nounList->iobjMatch

/* ------------------------------------------------------------------------ */
/*
 *   Establish the default dictionary for the game's player command parser
 *   vocabulary.
 */
dictionary cmdDict;

/*
 *   The standard parts of speech for the dictionary.
 */
dictionary property noun, nounApostS;


/* ------------------------------------------------------------------------ */
/*
 *   Flags for matching noun phrases during parsing.  These are bit flags, so
 *   they can be combined with '|' (bitwise OR).
 *   
 *   Note that the arithmetic values also matter: the values are in order of
 *   priority for noun phrase matches.  That is, a higher arithmetic value is
 *   a better match.  The best match is one with no truncation and no
 *   approximation, so that will have the highest arithmetic value when you
 *   combine those two bit flags.  The next best is character approximation
 *   but no truncation - truncation is more important than approximation, so
 *   it has a higher arithmetic value.  
 */

/* matched a preposition (the phrase contains at least one preposition) */
#define MatchPrep      0x0001

/* 
 *   matched a weak token (which we'll treat as equivalent to matchimg a
 *   preposition).
 */
#define MatchWeak      0x0001

/* matched an adjective (the phrase contains at least one adjective) */
#define MatchAdj       0x0002

/* matched a noun (the phrase contains at least one noun word) */
#define MatchNoun      0x0004

/* matched a plural (the phrase contains at least one plural word) */
#define MatchPlural    0x0008

/* matched a phrase */
#define MatchPhrase    0x0010 

/* mask to select only the part-of-speech flags */
#define MatchPartMask  0x0FFF


/* 
 *   all words were matched WITHOUT character approximations (such as
 *   matching 'a' to 'a-umlaut') 
 */
#define MatchNoApprox  0x1000

/* all words were matched WITHOUT truncation */
#define MatchNoTrunc   0x2000

/* mask to select only the match-strength flags */
#define MatchStrengthMask  0xF000

/* ------------------------------------------------------------------------ */
/*
 *   Flags for object selection during parsing.  These flags reflect how well
 *   an object matched a noun phrase during the resolution process.  
 */

/* 
 *   The noun phrase required disambiguation, because more than one object
 *   was in scope that matched the noun phrase.  We were able to figure out
 *   which one(s) the player meant from context, without having to ask the
 *   player for help.
 *   
 *   For example, there are two doors in the room, one open and one closed.
 *   The player types OPEN DOOR.  It's fairly obvious that they must be
 *   talking about the closed door.  So, we choose that object and set the
 *   Disambig flag.
 *   
 *   (Note that this flag specifically does NOT mean that we had to ask the
 *   user for help with the dreaded "Which do you mean..." question.  It's
 *   kind of the opposite: it means that we had a noun phrase that was
 *   initially ambiguous, but that we managed to disambiguate it on our own.
 *   When we get the user involved, there's ambiguity *before* we ask the
 *   question, but the user's response removes the ambiguity by telling us
 *   exactly which alternative they intended.  This flag indicates that we
 *   made an educated guess about what the user must have intended, without
 *   asking.  The flag lets the parser tell the player about the guess, which
 *   is desirable because the guess is sometimes wrong.  
 */
#define SelDisambig         0x0001

/*
 *   This object was chosen arbitrarily from a larger set, because the noun
 *   phrase construction says we should do so.  This flag is set when the
 *   noun phrase is something TAKE A BOOK or TAKE ANY OF THE BOOKS.  
 */
#define SelArbitrary        0x0002

/*
 *   The noun phrase that we matched was a manifestly plural construction,
 *   such as TAKE ALL or TAKE THE BOOKS.  
 */
#define SelPlural           0x0004

/*
 *   We selected an object as a default.  This is set when the player leaves
 *   out a noun phrase, but we can guess what was probably meant based on
 *   context: e.g., ASK ABOUT THE HOUSE is probably directed to Bob if Bob is
 *   the only person nearby.  
 */
#define SelDefault          0x0008

/*
 *   This object was set internally by the program; it did not come from
 *   parsing any player input.  This generally means that the whole command
 *   was constructed by the program, to handle an event or other internal
 *   processing, rather than by parsing player input.  
 */
#define SelProg             0x1000

/* ------------------------------------------------------------------------ */
/*
 *   readMainCommandTokens() phase identifiers.  We define a separate code
 *   for each kind of call to readMainCommandTokens() so that we can do any
 *   special token processing that depends on the type of command we're
 *   reading.
 *   
 *   The library doesn't use the phase information itself for anything.
 *   These phase codes are purely for the author's use in writing
 *   pre-parsing functions and for differentiating prompts for the different
 *   types of input, as needed.
 *   
 *   Games that read additional response types of their own are free to add
 *   their own enums to identify the additional phases.  Since the library
 *   doesn't need the phase information for anything internally, it won't
 *   confuse the library at all to add new game-specific phase codes.  
 */

/* reading a normal command line */
enum rmcCommand;

/* reading an unknown word response, to check for an "oops" command */
enum rmcOops;

/* reading a response to a prompt for a missing object phrase */
enum rmcAskObject;

/* reading a response to a prompt for a missing literal phrase */
enum rmcAskLiteral;

/* reading a response to an interactive disambiguation prompt */
enum rmcDisambig;


/* ------------------------------------------------------------------------ */
/* 
 *   A couple of utility macros we use internally for turning macro values
 *   into strings.  STRINGIZE(x) expands any macros in its argument and then
 *   turns the result into a single-quoted string, which can then be used in
 *   regular program text or in directives that evaluate constant
 *   expressions, such as #if.  (STRINGIZE is the real macro; _STRINGIZE is
 *   needed to force expansion of any macros in the argument, which is
 *   required because of the weird ANSI C expansion-order rules, and which
 *   works because of same.)  
 */
#define _STRINGIZE(x) #@x
#define STRINGIZE(x)  _STRINGIZE(x)




/* ------------------------------------------------------------------------ */
/*
 *   Parser global variables giving information on the command currently
 *   being performed.  These are valid through doAction processing.  These
 *   should never be changed except by the parser.
 */

/* the actor performing the current command */
#define gActor (libGlobal.curActor)

/*
 *   For convenience, define some macros that return the current direct and
 *   indirect objects from the current action.  The library only uses direct
 *   and indirect objects, so games that define additional command objects
 *   will have to add their own similar macros for those.  
 */
#define gDobj (gAction.curDobj)
#define gIobj (gAction.curIobj)
#define gLiteral (gAction.literal)
#define gNumber (gAction.num)


/* the Action object of the command being executed */
#define gAction (libGlobal.curAction)
#define gCommand (libGlobal.curCommand)

#define gTentativeDobj (gCommand.dobjs.mapAll({x: x.obj}).toList)
#define gTentativeIobj (gCommand.iobjs.mapAll({x: x.obj}).toList)

/* 
 *   the probable Action objects of the command being executed for use in verify routines when
 *   resolution of both objects may not be complete. If the gDobj or gIobj is non-nil, use that,
 *   otherwise use the first object in the tentative resolution list if the list has any items,
 *   otherwisse evaluate to failVerifyObj.
 */
#define gVerifyDobj (gDobj ?? (gTentativeDobj.length > 0 ? gTentativeDobj[1] : failVerifyObj))
#define gVerifyIobj (gIobj ?? (gTentativeIobj.length > 0 ? gTentativeIobj[1] : failVerifyObj))

/* 
 *   An alternative way of dealing with the potential object not yet resolved problem, by testing
 *   whether any of the objects in lst are in the Tentative Object List.
 */
#define gTentativeDobjIn(lst)  (gTentativeDobj.overlapsWith(lst))
#define gTentativeIobjIn(lst)  (gTentativeIobj.overlapsWith(lst))

/* The previous action and command */
#define gLastAction (libGlobal.lastAction)
#define gLastCommand (libGlobal.lastCommand)

/*
 *   Determine if the current global action is the specified action.  Only
 *   the action prefix is needed - so use "Take" rather than "TakeAction"
 *   here.
 *   
 *   This tests to see if the current global action is an instance of the
 *   given action class - we test that it's an instance rather than the
 *   action class itself because the parser creates an instance of the
 *   action when it matches the action's syntax.  
 */
#define gActionIs(action) \
    (gAction != nil && gAction.ofKind(action))

/* is the current global action ANY of the specified actions? */
#define gActionIn(action...) \
    (gAction != nil \
     && (action#foreach/gAction.ofKind(action)/||/))

/* is the current action a Travel action going dirn */
#define gTravelActionIs(dirn) \
  (gAction != nil && gAction.ofKind(Travel) && gAction.direction == dirn ## Dir)

/* the list of objects involved in the action just completed */
#define gActionList (nilToList(gCommand.action.actionList))

/* a displaying string version of the above */
#define gActionListStr makeListStr(gCommand.action.reportList, &theName)

/* 
 *   an object that is singular or plural according to whether gActionList
 *   represents a single object of a plurality of objects, and which picks
 *   up the correct gender if there is only a single object.
 */

#define gActionListObj (object: Thing \
             { \
                 plural = (gAction.reportList.length > 1 || \
                           gAction.reportList[1].plural); \
                 isIt = (gAction.reportList.length == 1 ? \
                    gAction.reportList[1].isIt : nil);\
                 isHim = (gAction.reportList.length == 1 ? \
                    gAction.reportList[1].isHim : nil);\
                 isHer = (gAction.reportList.length == 1 ? \
                    gAction.reportList[1].isHer : nil);\
                 name = gActionListStr; \
                 qualified = true; \
             } )


/* ------------------------------------------------------------------------ */
/*
 *   Miscellaneous macros
 */

/* get the current player character Actor object */
#define gPlayerChar (libGlobal.playerChar)

/* get the player character's location */
#define gLocation (getPlayerChar().location)

/* get the current turn count */
#define gTurns (libGlobal.totalTurns)

/* 
 *   get the player character's current room (which may or may not be the same
 *   as his/her location)
 */
#define gRoom (getPlayerChar().getOutermostRoom)

/* Get the current actor's curren room (which may not be the same as its location) */
#define gActorRoom (gActor.getOutermostRoom)

#define objFor(which, action) propertyset '*' ## #@which ## #@action

#define dobjFor(action) objFor(Dobj, action)
#define iobjFor(action) objFor(Iobj, action)
#define gTopic (gAction.curTopic)
#define gTopicText (gTopic.getTopicText)
#define gTopicMatch (gTopic.getBestMatch)

#define reportAfter(msg) gCommand.afterReports += msg
#define reportPostImplicit(msg) gCommand.postImplicitReports += msg

/* 
 *   Defined for the sake of adv3 users moving to adv3Lite, who may be more used to using
 *   mainReport() in a similar context.
 */
#define mainReport(msg, args...) actionReport(msg, ##args)

#define sLoc(which) subLocation = &remap##which

#define UsePronoun 1



/*
 *   Treat an object definition as equivalent to another object definition.
 *   These can be used immediately after a dobjFor() or iobjFor() to treat
 *   the first action as though it were the second.  So, if the player types
 *   "search box", and we want to treat the direct object the same as for
 *   "look in box", we could make this definition for the box:
 *   
 *   dobjFor(Search) asDobjFor(LookIn)
 *   
 *   Note that no semicolon is needed after this definition, and that this
 *   definition is completely in lieu of a regular property set for the
 *   object action.
 *   
 *   In general, a mapping should NOT change the role of an object:
 *   dobjFor(X) should not usually be mapped using asIobjFor(Y), and
 *   iobjFor(X) shouldn't be mapped using asDobjFor(Y).  The problem with
 *   changing the role is that the handler routines often assume that the
 *   object is actually in the role for which the handler was written; a
 *   verify handler might refer to '{dobj}' in generating a message, for
 *   example, so reversing the roles would give the wrong object in the role.
 *   
 *   Role reversals should always be avoided, but can be used if necessary
 *   under conditions where all of the code involved in the TARGET of the
 *   mapping can be carefully controlled to ensure that it doesn't make
 *   assumptions about object roles, but only references 'self'.  Reversing
 *   roles in a mapping should never be attempted in general-purpose library
 *   code, because code based on the library could override the target of the
 *   role-reversing mapping, and the override could fail to observe the
 *   restrictions on object role references.
 *   
 *   Note that role reversals can almost always be handled with other
 *   mechanisms that handle reversals cleanly.  Always consider Doer.doInstead()
 *   first when confronted with a situation that seems to call for a
 *   role-reversing asObjFor() mapping, as doInstead() specifically allows for
 *   object role changes.  
 */
#define asObjFor(obj, Action) \
    { \
        preCond { return preCond##obj##Action; } \
        verify() { verify##obj##Action; } \
        remap() { return remap##obj##Action; } \
        check() { check##obj##Action; } \
        action() { action##obj##Action; } \
        report() { report##obj##Action; } \
    }

#define asDobjFor(action) asObjFor(Dobj, action)
#define asIobjFor(action) asObjFor(Iobj, action)

/* 
 *   Define mappings of everything except the action.  This can be used in
 *   cases where we want to pick up the verification, preconditions, and
 *   check routines from another handler, but not the action.  This is often
 *   useful for two-object verbs where the action processing is entirely
 *   provided by one or the other object, so applying it to both would be
 *   redundant.  
 */
#define asObjWithoutActionFor(obj, Action) \
    { \
        preCond { return preCond##obj##Action; } \
        verify() { verify##obj##Action; } \
        remap() { return remap##obj##Action(); } \
        check() { check##obj##Action; } \
        action() {  } \
    }

#define asDobjWithoutActionFor(action) asObjWithoutActionFor(Dobj, action)
#define asIobjWithoutActionFor(action) asObjWithoutActionFor(Iobj, action)

#define asObjWithoutVerifyFor(obj, Action) \
    { \
        preCond { return preCond##obj##Action; } \
        remap() { return remap##obj##Action(); } \
        check() { check##obj##Action; } \
        action() { action##obj##Action(); } \
        report() { report##obj##Action(); } \
    }

#define asDobjWithoutVerifyFor(action) asObjWithoutVerifyFor(Dobj, action)
#define asIobjWithoutVerifyFor(action) asObjWithoutVerifyFor(Iobj, action)

#define askForDobj(action)  askMissingObject(action, DirectObject)
#define askForIobj(action)  askMissingObject(action, IndirectObject)
#define askForAobj(action)  askMissingObject(action, AccessoryObject)
#define askForAcc(action)   askMissingObject(action, AccessoryObject) 

#define askForDobjX(action)  askMissingObject(action, DirectObject, nil)
#define askForIobjX(action)  askMissingObject(action, IndirectObject, nil)
#define askForAobjX(action)  askMissingObject(action, AccessoryObject, nil)
#define askForAccX(action)   askMissingObject(action, AccessoryObject, nil) 

/*  Convenience macros for synthesizing travel in a given compass direction */

#define goInstead(dirn) doInstead(Go, dirn##Dir)
#define goNested(dirn) doNested(Go, dirn##Dir)




#define asExit(dir) : UnlistedProxyConnector { direction = dir##Dir }
#define asExitListed(dir) : UnlistedProxyConnector { direction = dir##Dir  isConnectorListed = true}
#define ulExit(dest) : UnlistedTravelConnector { destination = dest }
#define ulMsgExit(dest, msg) : UnlistedTravelConnector { \
    destination = dest \
    travelDesc = msg   }
#define tcMsg(dest, msg) : TravelConnector { \
    destination = dest \
    travelDesc = msg   }    

/* ------------------------------------------------------------------------ */
/*
 *   Define an action with the given base class.  This adds the *Action
 *   suffix to the given root name, and defines a class with the given base
 *   class.  We also define the baseActionClass property to refer to myself;
 *   this is the canonical class representing the action for all subclasses.
 *   This information is useful because a language module might define
 *   several grammar rule subclasses for the given class; this lets us
 *   relate any instances of those various subclasses back to this same
 *   canonical class for the action if necessary.  
 */

/* 
 *   Define an action OBJECT with the given name inheriting from the given base
 *   class, for use with the Mercury parser.
 */

#define DefineAction(name, baseClass...) \
    name: ##baseClass \
    baseActionClass = name

/*
 *   Define a "system" action.  System actions are meta-game commands, such
 *   as SAVE and QUIT, that generally operate the user interface and are not
 *   part of the game world.  
 */
#define DefineSystemAction(name) \
    DefineAction(name, SystemAction)

/*
 *   Define a concrete IAction, given the root name for the action.  We'll
 *   automatically generate a class with name XxxAction. 
 */
#define DefineIAction(name) \
    DefineAction(name, IAction)

/*
 *   Define a concrete TAction, given the root name for the action.  We'll
 *   automatically generate a class with name XxxAction, a verProp with name
 *   verXxx, a checkProp with name checkXxx, and an actionProp with name
 *   actionDobjXxx.  
 */
#define DefineTAction(name) \
    DefineTActionSub(name, TAction)

/*
 *   Define a concrete TAction with a specific base class.  
 */
#define DefineTActionSub(name, cls) \
    DefineAction(name, cls) \
    verDobjProp = &verifyDobj##name \
    remapDobjProp = &remapDobj##name \
    preCondDobjProp = &preCondDobj##name \
    checkDobjProp = &checkDobj##name \
    actionDobjProp  = &actionDobj##name \
    reportDobjProp = &reportDobj##name \

#define DefineLiteralTAction(name)\
    DefineTActionSub(name, LiteralTAction)

#define DefineLiteralAction(name)\
    DefineAction(name, LiteralAction)

#define DefineTopicTAction(name)\
    DefineTActionSub(name, TopicTAction)

#define DefineTopicAction(name)\
    DefineAction(name, TopicAction)

#define DefineNumericTAction(name)\
    DefineTActionSub(name, NumericTAction)

#define DefineNumericAction(name) \
    DefineAction(name, NumericAction)


/*
 *   Define a concrete TIAction, given the root name for the action.  We'll
 *   automatically generate a class with name XxxAction, a verDobjProp with
 *   name verDobjXxx, a verIobjProp with name verIobjxxx, a checkDobjProp
 *   with name checkDobjXxx, a checkIobjProp with name checkIobjXxx, an
 *   actionDobjProp with name actionDobjXxx, and an actionIobjProp with name
 *   actionIobjXxx.  
 */
#define DefineTIAction(name) \
    DefineTIActionSub(name, TIAction)

/*
 *   Define a concrete TIAction with a specific base class.  
 */
#define DefineTIActionSub(name, cls) \
    DefineAction(name, cls) \
    verDobjProp = &verifyDobj##name \
    verIobjProp = &verifyIobj##name \
    remapDobjProp = &remapDobj##name \
    remapIobjProp = &remapIobj##name \
    preCondDobjProp = &preCondDobj##name \
    preCondIobjProp = &preCondIobj##name \
    checkDobjProp = &checkDobj##name \
    checkIobjProp = &checkIobj##name \
    actionDobjProp  = &actionDobj##name \
    actionIobjProp = &actionIobj##name \
    reportDobjProp = &reportDobj##name \
    reportIobjProp = &reportIobj##name \

/* Shortcut macros for defining VerbRules and Actions together in a single statement. */
#define DefineTVerb(name, gram, inf, partc) \
    VerbRule(name)\
    gram\
    : VerbProduction\
    action = name\
    verbPhrase = inf + '/' + partc + 'what '\
    missingQ = 'what do you want to ' + inf\
    ;\
    DefineTAction(name)

#define DefineIVerb(name, gram, inf, partc)\
    VerbRule(name)\
    gram\
    :VerbProduction \
    action = name\
    verbPhrase = inf + '/' + partc\
    ;\
    DefineIAction(name)

#define DefineTIVerb(name, gram, inf, partc, prep) \
    VerbRule(name)\
    gram\
    : VerbProduction\
    action = name\
    verbPhrase = inf + '/' + partc + ' what ' + '('+ #@prep + ' what)'\
    missingQ = 'what do you want to ' + inf +';what do you want to ' + inf + ' it ' + #@prep\
    iobjReply = prep##SingleNoun \
    ;\
    DefineTIAction(name)
    
#define DefineTVerbS(name, gram, inf, partc) \
    VerbRule(name)\
    gram\
    : VerbProduction\
    action = name\
    verbPhrase = inf + '/' + partc + 'what '\
    missingQ = 'what do you want to ' + inf\
    dobjReply = singleNoun\
    ;\
    DefineTAction(name)

#define DefineTIVerbS(name, gram, inf, partc, prep) \
    VerbRule(name)\
    gram\
    : VerbProduction\
    action = name\
    verbPhrase = inf + '/' + partc + ' what ' + '('+ #@prep + ' what)'\
    missingQ = 'what do you want to ' + inf +';what do you want to ' + inf + ' it ' + #@prep\
    iobjReply = prep##SingleNoun \
    dobjReply = singleNoun\
    ;\
    DefineTIAction(name)

/* Macros to abbreviate the definitions of SpecialTRavelActions. */
    
#define DefSTA(action, prop) action : SpecialTravelAction travelProp = prop
#define DefSTAVR(name, voc) VerbRule(name) voc :VerbProduction action = name 
#define DefSpecialTravel(action, prop, voc) \
    DefSTAVR(action, voc);\
    DefSTA(action, prop)

/*
 *   Modify a concrete TIAction to work with multimethods. This creates the base version of the
 *   three multimethods needed then sets the relevant methods of the TIAction to call the relevant
 *   multimethod.
 */   
#define MMTIAction(name) \
    verify ## name (Object dobj, Object iobj, Thing verobj) {} \
    check ## name (Object dobj, Object iobj) {} \
    action ## name (Object dobj, Object iobj) {} \
    modify name \
    mmVerify(dobj, iobj, verobj) { verify ## name (dobj, iobj, verobj); } \
    mmCheck(dobj, iobj) { check ## name (dobj, iobj); } \
    mmAction(dobj, iobj) { action ## name (dobj, iobj); }

#define tvo Thing verobj

/*
 *   The following macros relating to the TIAAction class are only relevant when
 *   the TIAAction extension is used. The macros are nevertheless included here
 *   for convenience when using the TIAAction extension.
 *
 *   Define a concrete TIAAction, given the root name for the action.  We'll
 *   automatically generate a class with name XxxAction, a verDobjProp with name
 *   verDobjXxx, a verIobjProp with name verIobjxxx, a checkDobjProp with name
 *   checkDobjXxx, a checkIobjProp with name checkIobjXxx, an actionDobjProp
 *   with name actionDobjXxx, and an actionIobjProp with name actionIobjXxx.
 */
#define DefineTIAAction(name) \
    DefineTIAActionSub(name, TIAAction)

/*
 *   Define a concrete TIAction with a specific base class.  
 */
#define DefineTIAActionSub(name, cls) \
    DefineAction(name, cls) \
    verDobjProp = &verifyDobj##name \
    verIobjProp = &verifyIobj##name \
    verAobjProp = &verifyAobj##name \
    remapDobjProp = &remapDobj##name \
    remapIobjProp = &remapIobj##name \
    remapAobjProp = &remapAobj##name \
    preCondDobjProp = &preCondDobj##name \
    preCondIobjProp = &preCondIobj##name \
    preCondAobjProp = &preCondAobj##name \
    checkDobjProp = &checkDobj##name \
    checkIobjProp = &checkIobj##name \
    checkAobjProp = &checkAobj##name \
    actionDobjProp  = &actionDobj##name \
    actionIobjProp = &actionIobj##name \
    actionAobjProp = &actionAobj##name \
    reportDobjProp = &reportDobj##name \
    reportIobjProp = &reportIobj##name \
    reportAobjProp = &reportAobj##name \


#define aobjFor(action) objFor(Aobj, action)
#define asAobjFor(action) asObjFor(Aobj, action)
#define accFor(action) objFor(Aobj, action)
#define asAccFor(action) asObjFor(Aobj, action)
#define gAobj gAction.curAobj
#define gAcc gAction.curAobj


/* 
 *   Macros for use in verify routines, returning various kinds of verify
 *   results
 */

#define gVerifyList gAction.verifyList

#define logical gAction.addVerifyResult (new VerifyResult(100, '', true, verobj))
    
#define illogical(msg) \
    gAction.addVerifyResult(new VerifyResult(30, msg, nil, verobj))

#define illogicalNow(msg) \
    gAction.addVerifyResult(new VerifyResult(40, msg, nil, verobj))


/* 
 *   IllogicalAlready doesn't do anything mush different from IllogicalNow in
 *   adv3Lite, but is supplied so that game authors familiar with adv3 can use
 *   it without getting a compilation error. It may also be slightly useful for
 *   documentary purposes to clarify why a verify routine in game code is ruling
 *   out an action. We now give it a slightly higher logical rank than illogicalNow().
 */
#define illogicalAlready(msg) \
    gAction.addVerifyResult(new VerifyResult(45, msg, nil, verobj))

#define illogicalSelf(msg) \
    gAction.addVerifyResult(new VerifyResult(20, msg, nil, verobj))

#define logicalRank(score) \
    gAction.addVerifyResult(new VerifyResult(score, '', true, verobj))

#define inaccessible(msg) \
    gAction.addVerifyResult(new VerifyResult(10, msg, nil, verobj))

#define implausible(msg) \
    gAction.addVerifyResult(new VerifyResult(35, msg, nil, verobj))

#define nonObvious \
    gAction.addVerifyResult(new VerifyResult(30, '', true, verobj, nil))

#define dangerous \
    gAction.addVerifyResult(new VerifyResult(90, '', true, verobj, nil))


/* ------------------------------------------------------------------------ */
/*
 *   Command interruption signal macros.  
 */

/* a concise macro to throw an ExitSignal */
#define exit throw new ExitSignal()

/* a concise macro to throw an ExitActionSignal */
#define exitAction throw new ExitActionSignal()

/* a concise macro to throw an AbortImplicitSignal */
#define abortImplicit throw new AbortImplicitSignal()

/* a concise macro to throw an Abort signal */
#define abort throw new AbortActionSignal()

/* a concise macro to throw a Skip signal */
#define skip throw new SkipSignal() 

/* ------------------------------------------------------------------------ */
/*
 *   aHref() flags 
 */
#define AHREF_Plain  0x0001    /* plain text hyperlink (no underline/color) */



/* ------------------------------------------------------------------------ */
/*
 *   An achievement defines its descriptive text.  It can also optionally
 *   define the number of points it awards.  
 */
Achievement template +points? "desc";



/* ------------------------------------------------------------------------ */
/*
 *   Templates for style tags 
 */
StyleTag template 'tagName' 'openText'? 'closeText'?;

/* ------------------------------------------------------------------------ */
/*
 *   Object definition templates 
 */

Thing template 'vocab' @location? "desc"?;
Topic template 'vocab' @familiar?;

Room template 'roomTitle' 'vocab' "desc"?;
Room template 'roomTitle' "desc"?;

Region template [rooms];

Door template  'vocab' @location? "desc"? ->otherSide;
Door template  ->otherSide 'vocab' @location? "desc"?;

TravelConnector template 'vocab'? @location? "desc"? ->destination;
TravelConnector template ->destination "travelDesc";

Enterable template inherited ->connector;
Enterable template ->connector inherited;

Unthing template 'vocab' @location? 'notHereMsg'?;
Unthing template @unObject @location? 'notHereMsg'?;

SensoryEmanation template inherited [eventList]?;

ActorState template @location? "specialDesc" 'stateDesc' | "stateDesc" ? ;
ActorState template @location;

TopicGroup template @location? +scoreBoost? 'convKeys' | [convKeys] ? ;


TopicEntry template
   ->location? 
   +matchScore?
   @matchObj | [matchObj] | 'matchPattern'
   "topicResponse" | [eventList] ?;

/* a ShuffledEventList version of the above */
TopicEntry template
    ->location?
   +matchScore?
   @matchObj | [matchObj] | 'matchPattern'
   [firstEvents] [eventList];

/* we can also include *both* the match object/list *and* pattern */
TopicEntry template
    ->location?
   +matchScore?
   @matchObj | [matchObj]
   'matchPattern'
   "topicResponse" | [eventList] ?;

/* a ShuffledEventList version of the above */
TopicEntry template
   ->location? 
   +matchScore?
   @matchObj | [matchObj]
   'matchPattern'
   [firstEvents] [eventList]; 

/* Version of ActorTopicEntry template for use with Facts and kTag */
ActorTopicEntry template ->location? +matchScore? "topicResponse" | [eventList];

QueryTopic template
   ->location? 
   +matchScore? 'matchPattern'
    "topicResponse" | [eventList] ?;

QueryTopic template
    ->location?
    +matchScore? 'matchPattern'
    [firstEvents] [eventList];    

QueryTopic template
    ->location?
   +matchScore? 'qtype'
   @matchObj | [matchObj] | 'matchPattern'
   "topicResponse" | [eventList] ?;

/* a ShuffledEventList version of the above */
QueryTopic template
    ->location?
   +matchScore? 'qtype'
   @matchObj | [matchObj] | 'matchPattern'
   [firstEvents] [eventList];

/* we can also include *both* the match object/list *and* pattern */
QueryTopic template
    ->location?
   +matchScore? 'qtype'
   @matchObj | [matchObj]
   'matchPattern'
   "topicResponse" | [eventList] ?;

/* a ShuffledEventList version of the above */
QueryTopic template
    ->location?
   +matchScore? 'qtype'
   @matchObj | [matchObj]
   'matchPattern'
   [firstEvents] [eventList];

SayTopic template
    ->location?
    +matchScore?
    'tTag' 'extraVocab'
    "topicResponse" | [eventList] ?;

CommandTopic template ->location? +matchScore? 
    
    @matchObj | [matchObj]
    @matchDobj @matchIobj? "topicResponse" | [eventList]? ;

CommandTopic template ->location? +matchScore?     
    @matchObj | [matchObj] [matchDobj] @matchIobj "topicResponse" | [eventList]? ;

DefaultTopic template ->location? "topicResponse" | [eventList];
DefaultConsultTopic template ->location? "topicResponse" | [eventList];
DefaultThought template ->location? "topicResponse" | [eventList];

/* miscellanous topics just specify the response text or list */
MiscTopic template ->location? "topicResponse" | [eventList];
MiscTopic template ->location? [firstEvents] [eventList];
NodeContinuationTopic template ->location? "topicResponse" | [eventList];
NodeContinuationTopic template ->location? [firstEvents] [eventList];

/* AltTopics just specify the response text or list */
AltTopic template ->location? "topicResponse" | [eventList];
AltTopic template ->location? [firstEvents] [eventList];


AgendaItem template @location;

/* The ProxyActor template just specifies the location (i.e. the base Actor) */
ProxyActor template @location;

/* ProxyRoom templates - the only compulsory element is the destination. */
ProxyRoom template 'vocab'? "desc"? ->destination;
ProxyRoom template 'vocab'? ->destination "desc"?; 

Doer template 'cmd';
RemapCmd template 'cmd' @where? 'remappedCmd'?;

/* Templates for use with test sequences */
Test template 'testName' [testList] @location? [testHolding]?;
Test template 'testName' [testList] [testHolding]? @location?;

/* Define some convenient abbreviations for ConvNode related objects */
#define NEC NodeEndCheck
#define NCT NodeContinuationTopic
#define DCT DefaultConvstayTopic


/* Define convenient named constants for use with ConvAgendaItem */
#define InitiateConversationReason 1
#define ConversationLullReason 2
#define DefaultTopicReason 3



/* ------------------------------------------------------------------------ */
/*
 *   Command interruption signal macros.  
 */

/*
 *   Terminate execution of the command line.  This aborts the current
 *   command, including any remaining object iterations for the current
 *   action, and discards anything else on the command line.  
 */
#define exitCommandLine  throw new ExitCommandLineSignal()
/*----------------------------------------------------------------------------*/
/*
 *   enums for different types of lock:
 */    
   
enum notLockable, lockableWithoutKey, lockableWithKey, indirectLockable;

enum masculine, feminine, neuter;

/* ------------------------------------------------------------------------ */
/*
 *   The current library messages object.  This is the source object for
 *   messages that don't logically relate to the actor carrying out the
 *   comamand.  It's mostly used for meta-command replies, and for text
 *   fragments that are used to construct descriptions.
 *   
 *   This message object isn't generally used for parser messages or action
 *   replies - most of those come from the objects given by the current
 *   actor's getParserMessageObj() or getActionMessageObj(), respectively.
 *   
 *   By default, this is set to libMessages.  The library never changes this
 *   itself, but a game can change this if it wants to switch to a new set of
 *   messages during a game.  (If you don't need to change messages during a
 *   game, but simply want to customize some of the default messages, you
 *   don't need to set this variable - you can simply use 'modify
 *   libMessages' instead.  This variable is designed for cases where you
 *   want to *dynamically* change the standard messages during the game.)  
 */
#define gLibMessages (libGlobal.libMessageObj)

/* 
 *   the exit lister object - if the exits module isn't included in the
 *   game, this will be nil 
 */
#define gExitLister (libGlobal.exitListerObj)

/*
 *   the hint manager object - if the hints module isn't included in the
 *   game, this will be nil 
 */
#define gHintManager (libGlobal.hintManagerObj)


/*
 *   the extra hint manager object - if the hints module isn't included in the
 *   game, this will be nil 
 */
#define gExtraHintManager (libGlobal.extraHintManagerObj)


/* ------------------------------------------------------------------------ */
/*
 *   Convenience macros for controlling the narrative tense.
 */

/*
 *   Set the current narrative tense.  Use val = true for past and
 *   val = nil for present.
 */
#define setPastTense(val) (gameMain.usePastTense = (val))

/*
 *   Shorthand macro for selecting one of two values depending on the
 *   current narrative tense.
 */
#define tSel(presVal, pastVal) \
    (gameMain.usePastTense ? (pastVal) : (presVal))

/*
 *   Temporarily override the current narrative tense and invoke a callback
 *   function.
 */
#define withPresent(callback) (withTense(nil, (callback)))
#define withPast(callback)    (withTense(true, (callback)))


/* ------------------------------------------------------------------------ */
/*
 *   Object role identifiers.  These are used to identify the role of a noun
 *   phrase in a command.
 *   
 *  
 */


/*
 *   A special role for the "other" object of a two-object command.  This
 *   can be used in certain contexts (such as remapTo) where a particular
 *   object role is implied by the context, and where the action involved
 *   has exactly two objects; OtherObject in such contexts means
 *   DirectObject when the implied role is IndirectObject, and vice versa. 
 */
enum OtherObject;


/* ------------------------------------------------------------------------ */
/* 
 *   A couple of utility macros we use internally for turning macro values
 *   into strings.  STRINGIZE(x) expands any macros in its argument and then
 *   turns the result into a single-quoted string, which can then be used in
 *   regular program text or in directives that evaluate constant
 *   expressions, such as #if.  (STRINGIZE is the real macro; _STRINGIZE is
 *   needed to force expansion of any macros in the argument, which is
 *   required because of the weird ANSI C expansion-order rules, and which
 *   works because of same.)  
 */
#define _STRINGIZE(x) #@x
#define STRINGIZE(x)  _STRINGIZE(x)


/* ------------------------------------------------------------------------ */
/*
 *   Msg() - define a custom message to override a library message.  'id' is
 *   the message ID, which is the same ID used for the DMsg() message that
 *   you wish to override.  Do NOT use quotes around the ID - just enter it
 *   as though it were a variable name.  'txt' is the message text, as a
 *   single-quoted string.  
 *   
 *   This is used in CustomMessages objects to define message overrides.  See
 *   CustomMessages for full details.  
 */
#define Msg(id, txt)  #@id, txt

/* Template for CustomMessages objects */
CustomMessages template [messages] +priority?;



/* ------------------------------------------------------------------------ */
/*
 *   DMsg() - default English library message cover macro.
 *   
 *   Whenever the library displays a message, it uses the DMsg() macro.  The
 *   arguments are a message ID, and the default English message text to
 *   display.  The message ID is a string that identifies the message; this
 *   is used to look for overriding customizations of the message.  Refer to
 *   the CustomMessages class for information on customizing the standard
 *   library messages.
 *   
 *   In our approach, the library defines the default English text of the
 *   messages in-line, directly in the code.  On the surface, this is
 *   contrary to standard practices in most modern programming projects,
 *   which strive to make translations easier by separating the message text
 *   from the program code, gathering all of the text into a central message
 *   file that can be replaced for each language.  Despite appearances, we're
 *   accomplishing the same thing - but in our system, we have the advantage
 *   that we *also* define the default English message text in-line as part
 *   of the code it applies to.  This makes it easier to read the code by
 *   keeping a message and its full context in one place; this way you don't
 *   have to shuttle between the code and message file.
 *   
 *   Here's how we accomplish the message separation required for
 *   translations, and also for games that wish to customize the library
 *   defaults.  The DMsg() macro requires both the default English message
 *   text *and* an ID key for the message.  The message display function
 *   receives both.  The display function proceeds to look up the ID key in a
 *   translation table; if it finds an entry, it uses the version of the
 *   message in the translation table instead of the English default passed
 *   in via DMsg().  A language module can provide a message table that
 *   defines the language translations, and a game can provide a table that
 *   further customizes the library messages to fit its narrative style.
 *   
 *   There's one additional element.  Translators and game authors need to be
 *   able to see all of the messages in one place, so they can create their
 *   tables.  We would seem to lack that central list of English messages.
 *   Fortunately, by using a standard macro for each message, we can extract
 *   a comprehensive English message list automatically via a special tool.
 *   We use this as part of the library release process to create the English
 *   message file for reference.
 *   
 *   Note that the macro expansion includes the default English text only in
 *   English builds.  It omits the text in non-English builds.  This is to
 *   save space - we assume that the English messages will all be overridden
 *   anyway by each translated library version, so there's no point in
 *   including their text in the final compiled program.  
 */
#if STRINGIZE(LANGUAGE) == 'english'
#define DMsg(id, txt, args...)  message(#@id, txt, ##args)
#define BMsg(id, txt, args...)  buildMessage(#@id, txt, ##args)
#else
#define DMsg(id, txt, args...)  message(#@id, nil, ##args)
#define BMsg(id, txt, args...)  buildMessage(#@id, nil, ##args)
#endif

/* ------------------------------------------------------------------------ */
/*
 *   Debugging.  When we compile in development mode, we'll include a number
 *   of functions and methods that display information for debugging
 *   purposes.  We omit these in release builds to keep the compiled file
 *   size smaller, and to avoid making it too easy for end users to
 *   snoop around in the program internals.
 */
#ifdef __DEBUG
# define IfDebug(key, code) \
    if (DebugCtl.enabled[#@key]) { code; } else { }
#else
# define IfDebug(key, code)
#endif

#define gOutStream (outputManager.curOutputStream)

#ifdef __DEBUG
#include <dynfunc.h>
#endif

/*
 *   Some message processors add their own special parameters to messages,
 *   because they want to use expansion parameters (in the "{the dobj/him}"
 *   format) outside of the set of objects directly involved in the command.
 *   
 *   The Action method setMessageParam() lets you define such a parameter,
 *   but for convenience, we define this macro for setting one or more
 *   parameters whose names exactly match their local variable names.  In
 *   other words, if you call this macro like this:
 *   
 *   gMessageParams(obj, cont)
 *   
 *   then you'll get one parameter with the text name 'obj' whose expansion
 *   will be the value of the local variable obj, and another with text name
 *   'cont' whose expansion is the value of the local variable cont.  
 */
#define gMessageParams(var...) \
    (gAction.setMessageParams(var#foreach/#@var, var/,/))

/* ------------------------------------------------------------------------ */
/*
 *   Definitions for the menu system
 */

/* 
 *   The indices for the key values used to navigate menus, which are held
 *   in the keyList array of MenuItems.  
 */
#define M_QUIT      1
#define M_PREV      2
#define M_UP        3
#define M_DOWN      4
#define M_SEL       5

/* some templates for defining menu items */
MenuItem template 'title' 'heading'?;
MenuTopicItem template 'title' 'heading'? [menuContents];
MenuLongTopicItem template 'title' 'heading'? 'menuContents' | "menuContents";

/* templates for hint system objects */
Goal template ->closeWhenAchieved? 'title' 'heading'? [menuContents];
Hint template 'hintText' [referencedGoals]?;

/* 
 *   A Template to facilitate the definition of ExtraHints. We can define it 
 *   here and not in a header file since ExtraHints are only defined in this 
 *   source file. */

ExtraHint template +hintDelay? "hintText" | [eventList];

Tip template "desc" | 'desc';
    
/* templates for EventLists */

EventList template [eventList];
ShuffledEventList template [firstEvents] [eventList];

/* template for Scenery Class */
Scenery template @location? [scenList];

/* template and macros for Facts module */
Fact template 'name' [topics]? 'desc' [initiallyKnownBy]?;

#define gFact(tag) (factManager.getFact(tag))
#define gFactDesc(tag) (factManager.getFactDesc(tag))

/* Convenient synonyms for two ActorTopicEntry properties used in conjunction with Facts. */
#define rTag aTag
#define iTag tTag


/* ------------------------------------------------------------------------ */
/*  
 *   Property synonyms
 */

/* 
 *   The library uses isEdible rather than isEatable, since edible is the more
 *   natural word to use, but strict consistency might have dictated isEatable,
 *   so we make it an effective synonym in case some game authors use it.
 */
#define isEatable isEdible

/* Further macros for various isXable properties game author may spell wrong. */
#define isCutable isCuttable
#define isTouchable isFeelable
#define isDropable isDroppable
#define isLookUnderable canLookUnderMe
#define isLooBehindable canLookBehindMe

#define isLookThroughable canLookThroughMe
#define isLookThrughable canLookThroughMe
#define isGoThroughable canGoThroughMe
#define isGoThruable canGoThroughMe
#define isGoAlongable canGoAlongMe

#define isSwitchOnable isSwitchable
#define canSwitchMeOn isSwitchable
#define canSwichOnMe isSwitchable
#define isSwitchOffable isSwitchable
#define canSwitchMeOff isSwitchable
#define canSwichOffMe isSwitchable
#define isFlipable isFlippable
#define isClimbUpable canClimbUpMe
#define isClimbDownable canClimbDownMe
#define isStandOnable canStandOnMe
#define isSitOnable canSitOnMe
#define isLieOnable canLieOnMe
#define isDigable isDiggable
#define isTurnToable canTurnToMe
#define isSetToable canSetToMe
#define isPluggable isPlugable
#define isUnpluggable isUnplugable
#define isJumpOffable canJumpOffMe
#define isJumpOverable camJumpOverMe
#define isSetable isSettable
#define isTypeOnable canTypeOnMe
#define isEnterOnable canEnterOnMe
#define isWriteOnAble canWriteOnMe
#define isPushTravelable canPushTravel



/*  
 *   Conversely, authors alive to the Latin root of edible might try the
 *   latinate isPotable instead of isDrinkable.
 */
#define isPotable isDrinkable

/* ------------------------------------------------------------------------ */
/*
 *   String templates for room descriptions etc.
 */

string template <<mention name * >> mentionObj;
string template <<mention a * >> mentionA;
string template <<mention an * >> mentionA;
string template <<mention the * >> mentionThe;
string template << list of * is >> listStrIs;
string template << list of * >> makeListInStr;
string template << the list of * >> makeTheListStr;
string template << is list of * >> isListStr;
string template << exclude * >> makeMentioned;

/* ------------------------------------------------------------------------*/
/*
 *   Some useful macros for command text.
 */

/* Get the first word the player entered for the current command. */
#define gVerbWord (gCommand == nil || gCommand.verbProd == nil ? '' \
    : getTokVal(gCommand.verbProd.tokenList[1]))

/* Get the command tokens for the current command. */
#define gCommandToks (gCommand == nil || gCommand.verbProd == nil ? [] \
    : gCommand.verbProd.tokenList.mapAll({t: getTokVal(t)}))

/* Test for the presence of tok among the command tokens entered by the player. */
#define gToksInclude(tok) gCommandToks.indexOf(tok)

/* Get the command phrase for the current command. */
#define gVerbPhrase (gCommand.getCommandPhrase())

/* ------------------------------------------------------------------------ */
/*
 *   Size classes.  An object is large, medium, or small with respect to
 *   each sense; the size is used to determine how well the object can be
 *   sensed at a distance or when obscured.
 *   
 *   What "size" means depends on the sense.  For sight, the size
 *   indicates the visual size of the object.  For hearing, the size
 *   indicates the loudness of the object.  
 */

/* 
 *   Large - the object is large enough that its details can be sensed
 *   from a distance or through an obscuring medium.
 */
enum large;

/* 
 *   Medium - the object can be sensed at a distance or when obscured, but
 *   not in any detail.  Most objects fall into this category.  Note that
 *   things that are parts of large objects should normally be medium.  
 */
enum medium;

/*
 *   Small - the object cannot be sensed at a distance at all.  This is
 *   appropriate for detailed parts of medium-class objects.  
 */
enum small;

/*  Enums for Goals in the Hint system */
enum OpenGoal, ClosedGoal, UndiscoveredGoal;

/* Enums for Footnotes */
enum FootnotesFull, FootnotesMedium, FootnotesOff;

/* Template for Footnotes */
Footnote template "desc";

/* Template for ClockEvent */
ClockEvent template [eventTime];

/* String Templates for Objective Time module */
string template <<take * seconds>> takeTime;
string template <<take * second>> takeTime;
string template <<take * sec>> takeTime;
string template <<take * secs>> takeTime;

string template <<add * seconds>> addTime;
string template <<add * second>> addTime;
string template <<add * sec>> addTime;
string template <<add * secs>> addTime;


/* ------------------------------------------------------------------------- */
/*
 *   Communication Link Types
 *
 *   AudioLink means audio communication only is available VideoLink means both
 *   audio and visual links are available.
 */
#define AudioLink 1
#define VideoLink 2


/* ------------------------------------------------------------------------ */
/*
 *   Conversation manager macros
 */

/* has a topic key been revealed through <.reveal>? */
#define gRevealed(key)  (libGlobal.getRevealed(key)) 

/* reveal a topic key, as though through <.reveal> */
#define gReveal(key, args...) (libGlobal.setRevealed(key, ## args))

/* remove a topic key, as though through <.unreveal> */
#define gUnreveal(key) (libGlobal.setUnrevealed(key))

/* mark a Topic/Thing as known/seen by the player character */
#define gSetKnown(obj) (gPlayerChar.setKnowsAbout(obj))
#define gSetSeen(obj) (gPlayerChar.setHasSeen(obj))

/* does the player character know about obj? */
#define gKnown(obj) (gPlayerChar.knowsAbout(obj))
#define pcKnows(obj) (gPlayerChar.knowsAbout(obj))

/* has a topic key been revealed to an NPC through <.inform>? */
#define gInformed(key) (getActor.informedAbout(key))

/* is the topic key or object known to the NPC we're in conversaation with? */
#define npcKnows(obj) (getActor.knowsAbout(obj))

/* the last topic mentioned in the course of the current conversation */
#define gLastTopic (libGlobal.lastTopicMentioned)

/* the last fact mentioned in the course of the current conversation */
#define gLastFact (libGlobal.lastFactMentioned)

/* Associated knowledge enums */

enum likely, dubious, unlikely, untrue;

/* Macros to deal with knowledge enums and their associated objects */

#define BV(x) (defined(beliefManager) ? beliefManager.bvTab[x] : x)

#define RNF(name_, desc, args...) revealNewFact(name_, desc, ## args)
#define INF(name_, desc, args...) informNewFact(name_, desc, ## args)


/* ------------------------------------------------------------------------- */
/*
 *   Define some synonyms for potentially confusing property names
 */

#define checkTouchMsg checkFeelMsg
#define feelResponseMsg touchResponseMsg

#define cannotTouchMsg cannotFeelMsg

#define checkHitMsg checkAttackMsg
#define hitResponseMsg attackResponseMsg

/*--------------------------------------------------------------------------- */
/* 
 *   Define some macros to give abbreviated synonyms to inputManager method
 */

#define more inputManager.pauseForMore()
#define input(x...) inputManager.getInputLine(x)
#define waitKey(x...) inputManager.getKey(x)

/*----------------------------------------------------------------------------*/
/*
 *   Definitions for the rules.t extension
 */

#define stop return stopValue;

/* 
 *   Null value to return from Rules that don't stop a RuleBook from continuing
 *   to consider rules.
 */
enum null;

/* 
 *   Convenient abbreviations for rules that want to allow their RuleBook to
 *   continue processing more rules.
 */
#define rnull return null
#define nextrule return (rulebook.contValue)
#define nostop return (rulebook.contValue)

Rule template @location? &action | [action]?;
Rule template @location? "follow";

/*----------------------------------------------------------------------------*/
/*
 *   Definitions for the relations.t extension
 */

enum oneToOne, oneToMany, manyToOne, manyToMany;
Relation template 'name' 'reverseName'? @relationType? +reciprocal?;

enum normalRelation, reverseRelation;

/*----------------------------------------------------------------------------*/
/*
 *   Definitions for the Signals Extension
 */

#define DefSignal(sig, nam) sig##Signal: Signal \
    name = #@nam\
    handleProp = &handle_##sig
/*----------------------------------------------------------------------------*/
/*
 *   Definitions for the SymConn Extension
 */

SymConnector template ->destination;
SymConnector template @room1 @room2;

SymPassage template ->destination 'vocab' "desc"?;
SymPassage template 'vocab' ->destination "desc"?;
SymPassage template 'vocab' @room1 @room2 "desc"?;
SymPassage template 'vocab' [rooms] "desc"?;
 
string template <<* by room>> byRoomFunc;

/* Equivalent template for DSCon objects in main linrary. */
DSCon template 'vocab' @room1 @room2 "desc"?;

DSTravelConnector template @room1 @room2;
DSTravelConnector template ->room1 ->room2;


/*----------------------------------------------------------------------------*/
/*
 *   Definitions for the eventListItem Extension
 */
EventListItem template @myListObj? ~isReady? +minInterval? *maxFireCt? "invokeItem"? ;

/*-----------------------------------------------------------------------------*/
/*
 *   Definitions for Moods and Stances
 */

/* Define a new Stance */
#define DefStance(name_, score_) \
    name_ ## Stance: Stance \
    name = #@name_ \
    score = score_

/* Define a new Mood */
#define DefMood(name_) \
    name_ ## Mood: Mood \
    name = #@name_ 

/* Is the actor whose agenda item, topic entry or whatever we're looking from in this stance? */
#define gStance (getActor().stance)
#define gStanceIs(st_) (getActor().stance == st_ ## Stance)

/* What stance is this actor in? */
#define aStance(actor) (actor.stance)

/* Is actor in this stance ? */
#define aStanceIs(actor, st_) (actor.stance == st_ ## Stance)

/* Is actor in one of these stances? */
#define gStanceIn(st_...) \
    (gStance is in (st_#foreach: st_##Stance:, :))

#define aStanceIn(actor, st_...) \
    (actor.stance is in (st_#foreach: st_##Stance:, ))

/* What mood is getActor in? */
#define gMood (getActor().mood)

/* Is getActor in one of these moods? */
#define gMoodIs(mood_) (getActor().mood == mood_ ## Mood)


/* What mood is actor in? */
#define aMood(actor) (actor.mood)

/* Is actor in this mood? */
#define aMoodIs(actor, mood_) (actor.mood == mood_ ## Mood)

/* Is getActor in one of these moods? */
#define gMoodIn(mood_...) \
    (gMood is in (mood_#foreach: mood_ ## Mood:, :))

/* Is actor in one of these moods? */
#define aMoodIn(actor, mood_...) \
    (actor.mood is in (mood_#foreach: mood_##Mood:, :))

/* Set stances towards the player character */
#define gSetStance(st_) (getActor.setStanceToward(gPlayerChar, st_ ## Stance))
#define aSetStance(actor, st_) (actor.setStanceToward(gPlayerChar, st_ ## Stance))

/* Set moods */
#define gSetMood(mood_) (getActor.setMood(mood_ ## Mood))
#define aSetMood(actor, mood_) (actor.setMood(mood_ ## Mood))

#define Sta(a, b, c) [a, b ## Stance, c]

/* Templates for SpecialVerbs */
SpecialVerb template 'specVerb' 'stdVerb' @matchObjs | [matchObjs];
SpecialVerb template 'specVerb' @matchObjs | [matchObjs] 'stdVerb' ;

 /*----------------------------------------------------------------------------*/
/*
 *   Include the header for the Date intrinsic class. For some reason the
 *   compiler seems to prefer this to be at the end of this header file.
 */
#include <date.h>

#endif