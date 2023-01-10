#charset "us-ascii"
#include "advlite.h"


/*
 *   ***************************************************************************
 *   messages.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve, but is
 *   based substantially on the Mercury Library (c) 2012 Michael J. Roberts
 */

/* ------------------------------------------------------------------------ */
/*
 *   Global narration parameters.  This object's properties control the way
 *   parameter-based messages are generated.  The message generator
 *   consults the narration parameters each time it generates a message, so
 *   you can change the settings on the fly, and subsequent output will
 *   automatically adapt to the latest settings.  
 */
Narrator: object
    /*
     *   The verb tense of the narration.  This is one of the VerbTense
     *   objects (Present, Past, Perfect, Past Perfect, Future, Future
     *   Perfect).  This controls the way {verb} substitution parameters
     *   are generated, which in turn affects most library messages.  The
     *   default is Present, which is the conventional tense for most IF.
     *   
     *   Examples of the English tenses:
     *   
     *.    Present: Bob opens the box.
     *.    Past: Bob opened the box.
     *.    Perfect: Bob has opened the box.
     *.    Past Perfect: Bob had opened the box.
     *.    Future: Bob will open the box.
     *.    Future Perfect: Bob will have opened the box.
     *   
     *   (Language modules are free to add their own tenses if the target
     *   language has others that would be of interest to IF authors.
     *   They're also free to ignore any of the "standard" tenses we
     *   define.  At a minimum, though, some form of present tense should
     *   always be provided, since most IF is narrated in the present.  If
     *   you need to differentiate among different present tenses, you
     *   might prefer to define your own IDs instead of using the generic
     *   Present, but you should still support *some* present tense that's
     *   suitable for narration.  Some type of past tense usable in
     *   narration is also nice to have.  The others are probably of
     *   marginal value; in English, at least, other tenses are rare in any
     *   kind of narrative fiction, and are mostly limited to experimental
     *   or novelty use.)  
     */
    tense = (gameMain.usePastTense ? Past : Present)
;

/*
 *   Root class for verb tenses
 */
class VerbTense: object
    /*
     *   Tense name.  This is just an identifier for internal and degugging
     *   purposes, so we don't bother farming it out to the language module
     *   for translation. 
     */
    name = nil
;

Present: VerbTense
    name = 'present'
;
Past: VerbTense
    name = 'past'
;
Perfect: VerbTense
    name = 'perfect'
;
PastPerfect: VerbTense
    name = 'past perfect'
;
Future: VerbTense
    name = 'future'
;
FuturePerfect: VerbTense
    name = 'future perfect'
;


/* ------------------------------------------------------------------------ */
/*
 *   Show a message.
 *
 *   This looks for a customized version of the message text, as defined in
 *   CustomMessages objects.  If we don't find one, we use the provided default
 *   message text.
 *
 *   Substitution parameters take the form {x y z} - curly braces with one or
 *   more space-delimited tokens.  The first token is the parameter name, and
 *   any additional tokens are arguments.  The parameter names and their
 *   arguments are up to the language module to define.
 *
 *   In addition to the parameters, the string itself can have two sections,
 *   separated by a vertical bar, '|'.  The first section (before the bar) is
 *   the "terse" string, which is for a straightforward acknowledgment of a
 *   simple, ordinary action: "Taken", "Dropped", etc. The terse string is used
 *   only if the Command argument's actor is the player character, AND the
 *   command doesn't have any disambiguated objects.  If these conditions aren't
 *   met, the second half of the string, the "verbose" version, is used.
 *
 *   Once we have the message text, we perform parameter substitutions.
 *   Parameters can be provided as strings, which are substituted in literally;
 *   or as objects, whose names are inserted according to the grammar in the
 *   template text.
 */

message(id, txt, [args])    
    {
        
        txt = buildMessage(id, txt, args...);
        
        
        /* 
         *   use the oSay function to output the text to avoid an infinite
         *   recursive call through say.
         */        
        oSay(txt);       
    }

/* 
 *   Build a message to be shown by message()
 *
 *   We put this in a separate function to make it easy to obtain the text of a
 *   message for subsequent use without first displaying it.
 */
buildMessage(id, txt, [args])
{
    
    /* look for a customized version of the message */
    local cm = nil;
    foreach (local c in CustomMessages.all)
    {
        /* 
         *   if this customizer is active and defines the message, and it
         *   has a higher priority than any previous customizer we've
         *   already found, remember it as the best candidate so far 
         */
        if (c.active && c.msgTab[id] != nil
            && (cm == nil || c.priority > cm.priority))
            cm = c;
    }

    /* show debugging information, if desired */
    IfDebug(messages, debugMessage(id, txt, cm, args));

    /* if we found an override, use it instead of the provided text */
    if (cm != nil)
        txt = cm.msgTab[id];
    
    /* if txt is a function pointer, retrieve the value it returns */
    if(dataType(txt) == TypeFuncPtr)
        txt = txt();

    /* set up a sentence context for the expansion */
    local ctx = new MessageCtx(args);

    /* 
     *   Carry out any language-specific adjustments to the text prior to any
     *   further processing
     */
    txt = langAdjust(txt);
    
    /* 
     *   First look for a tense-swithing message substitution of the form
     *   {present-string|past-string} and choose whichever is appropriate to the
     *   tense of the game.
     */   
    local bar, openBrace = 0, closeBrace = 0, newTxt = txt;
    for(;;)
    {
        /* Find the next opening brace */
        openBrace = txt.find('{', closeBrace + 1);
        
        /* If there isn't one, we're done, so leave the loop. */
        if(openBrace == nil)
            break;
        
        /* Find the next vertical bar that follows the opening brace */
        bar = txt.find('|', openBrace);
        
        /* If there isn't one, we're done, so leave the loop. */
        if(bar == nil)
            break;
        
        /* Find the next closing brace that follows the opening brace */
        closeBrace = txt.find('}', openBrace);
        
        /* If there isn't one, we're done, so leave the loop. */
        if(closeBrace == nil)
            break;
        
        /* 
         *   If the bar doesn't come before the closing brace, then it's not
         *   between the two braces, so we don't want to process it in this
         *   circuit of the loop. Instead we need to see if there's another
         *   opening brace on the next iteration.
         */
        if(bar > closeBrace)
            continue;
        
        /* 
         *   Extract the string that starts with the opening brace we found and
         *   ends with the closing brace we found.
         */
        local pString = txt.substr(openBrace, closeBrace - openBrace + 1);
        
        /*   
         *   If the game is in the past tense, extract the second part of this
         *   above string (that following the bar up to but not including the
         *   closing brace). Otherwise extract the first part (that following
         *   but not including the opening brace up to but not including the
         *   bar)
         */
        local subString = (gameMain.usePastTense || Narrator.tense == Past) ?
            txt.substr(bar + 1, closeBrace - bar - 1) : txt.substr(openBrace +
                1, bar - openBrace - 1);
        
        /* 
         *   In the copy of our original text string, replace the string in
         *   braces with the substring we just extracted from it.
         */
        newTxt = newTxt.findReplace(pString, subString, ReplaceOnce);
        
    }
    
    /* Copy our adjusted string back to our original string */
    txt = newTxt;
    
    /* check for separate PC and NPC messages */
    bar = txt.find('|');
    if (bar != nil)
    {
        /* there's a bar - check to see if the terse format can be used */
        if (ctx.cmd != nil && ctx.cmd.terseOK())
            txt = txt.left(bar - 1);
        else
            txt = txt.substr(bar + 1);
    }

    /* get the message object */
    local mo = MessageParams.langObj;

    /* apply substitutions */
    for (local i = 1 ; i <= txt.length() ; )
    {
        /* find the end of the current sentence */
        local eos = txt.find(R'<.|!|?><space>', i) ?? txt.length() + 1;  

        /* 
         *   Build a list of the parameters in the sentence, and preprocess
         *   each one.  We need to preprocess the entire sentence before we
         *   can expand any of it, because some parameters can depend upon
         *   other parameters later in the sentence.  For example, some
         *   languages generally place the subject after the verb; to
         *   generate the verb with proper agreement, we need to know the
         *   subject when we expand the verb, which means we need to have
         *   scanned the entire sentence before we expand the verb.
         */
        ctx.startSentence();
        local plst = new Vector(10);
        for (local j = i ; ; )
        {
            /* find the next parameter */
            local lb = txt.find('{', j);
            if (lb == nil || lb >= eos)
                break;

            /* find the end of the parameter */
            local rb = txt.find('}', lb + 1);
            if (rb == nil)
                break;

            /* pull out the parameter string */
            local param = txt.substr(lb + 1, rb - lb - 1);

            /* turn it into a space-delimited token list */
            param = param.trim().split(' ');
            
            /* 
             *   do the preliminary expansion, but discard the result -
             *   this gives the expander a chance to update any effect on
             *   the sentence context 
             */
            mo.expand(ctx, param);

            /* add it to the list */
            plst.append([lb, rb, param]);

            /* move past this item */
            j = rb + 1;
        }

        /* restart the sentence */
        ctx.endPreScan();

        /* do the actual expansion */
        local delta = 0;
        for (local j = 1 ; j <= plst.length() ; ++j)
        {
            /* pull out this item */
            local cur = plst[j];
            local lb = cur[1], rb = cur[2], param = cur[3];
            local paramLen = rb - lb + 1;

            /* get the expansion */
            local sub = mo.expand(ctx, param);

            /* 
             *   if it starts with a "backspace" character ('\010', which
             *   is a ^H character, the standard ASCII backspace), delete
             *   any spaces immediate preceding the substitution parameter 
             */
            if (sub.startsWith('\010'))
            {
                /* count spaces immediately preceding the parameter */
                local m = lb + delta - 1, spCnt = 0;
                while (m >= 1 && txt.toUnicode(m) == 32)
                    --m, ++spCnt;

                /* if we found any spaces, splice them out */
                if (spCnt != 0)
                {
                    /* splice out the spaces */
                    txt = txt.splice(m + 1, spCnt, '');

                    /* adjust our delta for the deletion */
                    delta -= spCnt;
                }

                /* remove the backspace from the replacement text */
                sub = sub.substr(2);
            }

            /* splice the replacement text into the string */
//            txt = txt.splice(lb + delta, paramLen, sub);
            txt = txt.substr(1, lb + delta -1) + sub + txt.substr(lb + delta 
                + paramLen );

            /* adjust our delta to the next item for the splice */
            delta += sub.length() - paramLen;
        }

        /* move to the end of the sentence */
        i = eos + delta + 1;
    }


    return txt;
}

/*
 *   Message debugging.  This shows the message before processing: the ID,
 *   the default source text with the {...} parameters, the overriding
 *   custom source text, and the arguments.  
 */
#ifdef __DEBUG
debugMessage(id, txt, cm, args)
{
    if(id is in (nil,'','command results prefix', 'command prompt', 'command
        results suffix') 
       || outputManager.curOutputStream != mainOutputStream)       
        return;
    
    local idchk = [id, libGlobal.totalTurns];
    
    if(DebugCtl.messageIDs[idchk] != nil)
        return;
    else
        DebugCtl.messageIDs[idchk] = true; 
    
    oSay('\nmessage(id=<<id>>, default text=\'<<txt>>\' ');
    if (cm != nil)
        oSay('custom text=\'<<cm.msgTab[id]>>\'');

    if (args.length() != 0)
    {
        oSay(', args={ ');
        for (local i = 1 ; i <= args.length() ; ++i)
        {
            local a = args[i];
            if (i > 1)
                oSay(', ');
            if (dataType(a) == TypeSString)
                oSay(''''<<args[i]>>'''');
            else
                oSay('object(name=<<a.name>>)');
        }
        oSay(' }');
    }
    oSay(')\n');
}
#endif


/* ------------------------------------------------------------------------ */
/*
 *   Noun parameter roles for MessageCtx.noteObj() 
 */

/* the noun is the subject of the sentence */
enum vSubject;

/* the noun is an object of the verb */
enum vObject;

/* 
 *   the role is ambiguous (it's not marked clearly in the case or
 *   position, for example) 
 */
enum vAmbig;

/* the noun is a possessive, not the subject or the object */
enum vPossessive;
/* ------------------------------------------------------------------------ */
/*
 *   Message expansion sentence context.  This keeps track of the parts of
 *   the sentence we've seen so far in the substitution parameters.
 *   
 *   The sentence context is important for expanding certain items.  For
 *   verbs, it tells us which object is the subject, so that we can
 *   generate the agreeing conjugation of the verb (in number and
 *   grammatical person).  For direct and indirect objects, it lets us
 *   generate a reflexive when the same object appears in a second role
 *   ("You can't put the box in itself").
 */
class MessageCtx: object
    construct(args)
    {
        /* remember the message arguments */
        self.args = args;

        /* if there's a Command among the arguments, note it */
        cmd = gCommand;

        /* if there's no command, use the placeholder */
        if (cmd == nil)
            cmd = messageDummyCommand;
    }

    /* start a new sentence */
    startSentence()
    {
        /* forget any subject/object information */
        subj = nil;
        vobj = nil;
        gotVerb = nil;
        reflexiveAnte.clear();

        /* note that we're on the initial scan */
        prescan = true;

        /* we're starting a new scan, so reset the previous parameter */
        lastParam = nil;
    }

    /* 
     *   End the pre-expansion scan.  The expander makes two passes over
     *   each sentence.  The first scan doesn't actually do any
     *   substitutions, but merely invokes each parameter to give it a
     *   chance to exert its side effects on the sentence context.  The
     *   second scan actually applies the substitutions.  At the end of the
     *   first pass, the expander calls this to let us finalize the initial
     *   scan and prepare for the second scan.  
     */
    endPreScan()
    {
        /* 
         *   Forget the reflexive antecedent.  Reflexives are generally
         *   anaphoric (i.e., they refer back to earlier clauses in the
         *   same sentence), so we generally don't care about anything we
         *   found later in the same sentence. 
         */
        reflexiveAnte.clear();

        /* we're no longer on the initial scan */
        prescan = nil;

        /* we're starting a new scan, so reset the previous parameter */
        lastParam = nil;
    }

    /*
     *   Note a parameter value.  Some parameters refer back to the
     *   immediately preceding parameter, so it's useful to have the most
     *   recent value stashed away.  Returns the parameter value as given.
     */
    noteParam(val)
    {
        /* remember the value */
        return lastParam = val;
    }

    /*
     *   Convert a parameter value to a string representation suitable for
     *   message substitution. 
     */
    paramToString(val)
    {
        switch (dataType(val))
        {
        case TypeSString:
            return val;
            
        case TypeInt:
            return toString(val);

        case TypeObject:
            if (val.ofKind(Mentionable) || val.ofKind(Pronoun))
                return val.name;
            else if (val.ofKind(List) || val.ofKind(Vector))
                return val.mapAll({ x: paramToString(x) }).join(', ');
            else if (val.ofKind(BigNumber))
                return toString(val);
            else
                return '(object)';

        case true:
            return 'true';

        case nil:
            return '';

        default:
            return '(?)';
        }
    }

    /*
     *   Convert a parameter value to a numeric representation.  If the
     *   value is an integer or BigNumber, we return it as is; if a list or
     *   vector, we return the number of elements; if nil, 0; if a string,
     *   the parsed numeric value of the string; otherwise we simply return
     *   1.  
     */
    paramToNum(val)
    {
        switch (dataType(val))
        {
        case TypeSString:
            return toInteger(val);

        case TypeInt:
            return val;

        case TypeObject:
            if (val.ofKind(BigNumber))
                return val;
            if (val.ofKind(List) || val.ofKind(Vector))
                return val.length();
            return 1;

        case TypeList:
            return val.length();

        case nil:
            return 0;

        default:
            return 1;
        }
    }

    /*
     *   Note an object being used as a parameter in the given sentence
     *   role.  The role is one of the noun role enums defined above:
     *   vSubject, vObject, or vAmbig.  If the object is a subject, we'll
     *   save it as the sentence subject, so that we can generate an
     *   agreeing verb.  Regardless of role, we'll also save it as a
     *   reflexive antecedent, so that we can generate a reflexive pronoun
     *   if we see the same object again in another role in the same
     *   sentence.  
     */
    noteObj(obj, role)
    {
        /* remember the object as the last parameter value */
        noteParam(obj);

        /* 
         *   If the role is ambiguous, guess at the role based on the
         *   general sentence order. 
         */
        if (role == vAmbig && MessageParams.langObj.sentenceOrder != nil)
        {
            /* get the sentence order flags */
            local so = MessageParams.langObj.sentenceOrder;

            /* figure whether the subject/object is before/after the verb */
            local ssv = (so.find(R'S.*V') != nil ? -1 : 1);
            local osv = (so.find(R'O.*V') != nil ? -1 : 1);

            /* figure whether the subject or object comes first */
            local fo = (so.find(R'S.*O') != nil ? vSubject : vObject);

            /* figure which side of the verb we're on (-1 before, 1 after) */
            local sv = (gotVerb ? 1 : -1);

            /*
             *   If we're on the right side of the verb for both subject
             *   and object: if we have an object, this is the subject; if
             *   we have a subject, this is the object; if we have neither
             *   this is the first role in sentence order.
             *   
             *   Otherwise, if we're on the subject side of the verb, and
             *   we don't have a subject, this is the subject.
             *   
             *   Otherwise, if we're on the object side of the verb, and we
             *   don't have an object, this is an object.  
             */
            if (ssv == sv && osv == sv)
                role = (subj != nil ? vObject :
                        vobj != nil ? vSubject : fo);
            else if (ssv == sv && subj == nil)
                role = vSubject;
            else if (osv == sv && vobj == nil)
                role = vObject;
        }

        /* if it's the subject, remember it as such */
        if (role == vSubject)
            subj = obj;
        else if (role == vObject)
            vobj = obj;

        /* 
         *   Only record the reflexive antecent for the subject, so that the
         *   reflexive pronoun is used when an actor or object tries to act on
         *   itself.
         */
        if(role != vSubject)
            return;
        
        /* 
         *   If there's nothing in the reflexive antecedent list that uses
         *   the same pronoun, add this to the list.  Otherwise, replace
         *   the object that used the same antecedent. 
         */
//        local p = obj.pronoun();
//        local idx = reflexiveAnte.indexWhich({ o: o.pronoun() == p });
        
        /* 
         *   The foregoing rule seems to generate false positives (that is, it
         *   can result in reflexive pronouns where they're not appropriate), so
         *   we'll try the different strategy of looking for anything in the
         *   reflexive ante list. The reason for this is that if a new
         *   subject is introduced into the sentence, it doesn't have to be the
         *   same gender as the previous subject to become the most likely
         *   antecedent for a reflexive.
         */
        local idx = reflexiveAnte.indexWhich({ o: o.ofKind(Thing) });
        
        if (idx == nil)
        {
            /* 
             *   There's no object with this pronoun yet - add it.  We want
             *   to keep earlier antecedents with different pronouns
             *   because we can still refer back to earlier objects
             *   reflexively as long as it's clear which one we're talking
             *   about.  The distinct pronouns provide that clarity. 
             */
            reflexiveAnte.append(obj);
        }
        else
        {
            /* 
             *   We already have an object with this pronoun, so replace it
             *   with the new one.  Reflexives generally bind to the prior
             *   noun phrase that matches the pronoun *and* is closest in
             *   terms of word order.  Once another noun phrase intervenes
             *   in word order, we can only refer back to an earlier one by
             *   reflexive pronoun if the earlier noun is distinguishable
             *   from the later one by its use of a distinct pronoun from
             *   the later one.  For example, we can say "Bob asked Sue
             *   about himself", because "himself" could only refer to Bob,
             *   but most people would take "Bob asked Sam about himself"
             *   to mean that Bob is asking about Sam.  
             */
            reflexiveAnte[idx] = obj;
        }
    }

    /*
     *   Note a verb parameter. 
     */
    noteVerb()
    {
        /* note that we got a verb */
        gotVerb = true;
    }

    /* 
     *   Was the last parameter value plural?  If the value is numeric, 1
     *   is singular and anything else is plural.  If it's a list, a
     *   one-element list is singular and anything else is plural.  If it's
     *   a Mentionable, the 'plural' property determines it. 
     */
    lastParamPlural()
    {
        switch (dataType(lastParam))
        {
        case TypeInt:
            return lastParam != 1;

        case TypeObject:
            if (lastParam.ofKind(Mentionable) || lastParam.ofKind(Pronoun))
                return lastParam.plural;
            else if (lastParam.ofKind(List) || lastParam.ofKind(Vector))
                return lastParam.length() != 1;
            else if (lastParam.ofKind(BigNumber))
                return lastParam != 1;
            else
                return nil;

        case TypeList:
            return lastParam.length() != 1;

        default:
            return nil;
        }
    }

    /*
     *   Is the actor involved in the Command the PC?  If there's a Command
     *   with an actor, we check to see if it's the PC.  If there's no
     *   Command or no actor, we assume that the PC is the relevant actor
     *   (since there's nothing else specified anywhere) and return true.  
     */
    actorIsPC()
    {
        return cmd == nil || cmd.actor == nil
            || cmd.actor == gPlayerChar;
    }

    /* the last parameter value */
    lastParam = nil

    /* are we on the initial pre-expansion scan? */
    prescan = nil

    /* the subject of the sentence (as a Mentionable object) */
    subj = nil

    /* the last object of the verb we saw */
    vobj = nil

    /* have we seen a verb parameter in this sentence yet? */
    gotVerb = nil
    
    /* the message argument list */
    args = nil

    /* the Command object among the arguments, if any */
    cmd = nil

    /* 
     *   The reflexive antecedents.  Each time we see an object in a
     *   non-subject role, and the object has different pronoun usage from
     *   any previous entry, we'll add it to this list.  If we see the same
     *   object subsequently in another non-subject role, we'll know that
     *   we should generate a reflexive pronoun for the object rather than
     *   the name or a regular pronoun:
     *   
     *   You can't put the tongs in the box with the tongs -> with
     *   themselves
     */
    reflexiveAnte = perInstance(new Vector(5))
;

/*
 *   Dummy command placeholder for messages generated without a command.
 */
messageDummyCommand: object
    /* use the player character as the actor */
    actor = (gPlayerChar)
    
;

/*
 *    Use the message builder to format a message without supplying a key
 *    to look up at alternative message. We can use this with library
 *    messages that employ object properties (e.g. cannotTakeMsg) or user
 *    code.
 *
 *    dmsg() displays the resultant message.
 */
dmsg(txt, [args])
{
    message('', txt, args...);
}


/* bmsg returns the text of a message formatted by the message formatter. */
bmsg(txt, [args])
{
    return buildMessage('', txt, args...);
}

/* ------------------------------------------------------------------------ */
/*
 *   Message customizer object.  Language extensions and games can use this
 *   class to define their own custom messages that override the default
 *   English messages used throughout the library.
 *   
 *   Each CustomMessages object can define a list of messages to be
 *   customized.  This lets you centrally locate all of your custom
 *   messages by putting them all in a single object, if you wish.
 *   Alternatively, you can create separate objects, if you prefer to keep
 *   them with some other body of code they apply to.  In either case, the
 *   library gathers them all up during preinit.  
 */
class CustomMessages: object
    /*
     *   The priority determines the precedence of a message defined in
     *   this object, if the same message is defined in more than one
     *   CustomMessages object.  The message with the highest priority is
     *   the one that's actually displayed.
     *   
     *   The library defines one standard priority level: 100 is the
     *   priority for language module overrides.  Each language module
     *   provides a translated set of the standard library messages, via a
     *   CustomMessages object with priority 100.  (The default English
     *   messages defined in-line throughout the library via DMsg() macros
     *   effectively have a priority of negative infinity, since any custom
     *   message of any priority overrides a default.)
     *   
     *   Games will generally want to override all library messages,
     *   including translations, so we set the default here to 200.  
     */
    priority = 200

    /*
     *   Is this customizer active?  If you want to change the messages at
     *   different points in the course of the game, you can use this to
     *   turn sets of messages on and off.  For example, if your game
     *   includes narrator changes at certain points, you can create
     *   separate sets of messages per narrator.  By default, we make all
     *   customizations active, but you can override this to turn selected
     *   messages on and off as needed.  Note that the library consults
     *   this every time it looks up a message, so you can change the value
     *   dynamically, or use a method whose return value changes
     *   dynamically.  
     */
    active = true

    /*
     *   The message list.  This can contain any number of messages; the
     *   order isn't important.  Each message is defined with a Msg()
     *   macro:
     *   
     *.     Msg(id key, 'Message text'),  ...
     *   
     *   The "id key" is the message ID that the library uses in the DMsg()
     *   message that you're customizing.  (DON'T use quotes around the ID
     *   key.)  The message text is a single-quoted string giving the
     *   message text.  This can contain curly-brace replacement
     *   parameters.  
     */
    messages = []

    /*
     *   Construction.  Build the lookup table of our messages for fast
     *   access at run-time. 
     */
    construct()
    {
        /* add me to the master list of message customizers */
        CustomMessages.all += self;

        /* create the lookup table */
        msgTab = new LookupTable(64, 128);

        /* populate it with our key->string mappings */
        for (local i = 1, local len = messages.length() ; i <= len ; i += 2)
            msgTab[messages[i]] = messages[i+1];
    }

    /* message lookup table - this maps ID keys to message text strings */
    msgTab = nil

    /* 
     *   class property: the master list of CustomMessages objects defined
     *   throughout the game 
     */
    all = []
;

/* ------------------------------------------------------------------------ */
/*
 *   Message Parameter Handler.  This object defines and handles parameter
 *   expansion for '{...}' strings in displayed messages.
 *   
 *   The language module must provide one instance of this class.  The name
 *   of the instance doesn't matter - we'll find it at preinit time.  The
 *   object must provide the 'params' property giving the language-specific
 *   list of substitution parameter names and handler functions.  
 */
class MessageParams: object
    /*
     *   Expand a parameter string.  'ctx' is a MessageCtx object with the
     *   current sentence context.  This contains the message expansion
     *   arguments (ctx.args), the Command object from the arguments
     *   (ctx.cmd), and information on the grammar elements of the
     *   sentence.  'params' is the list of space-delimited tokens within
     *   the curly-brace parameter string.  Returns the string to
     *   substitute for the parameter in the message output.  
     */
    expand(ctx, params)
    {
        /* look up the parameter name */
        local pname = params[1].trim();
        local t = paramTab[pname.toLower()];

        /* 
         *   If we found an entry, let the entry handle it.  If there's no
         *   matching entry, it's basically an error: return the original
         *   parameter source text, with the braces restored, so that it'll
         *   be obvious in the output.
         */
        local txt = nil;
        if (t != nil)
        {
            /* 
             *   If we have not previously identified a subject for this
             *   context, use the dummy_ object, which provides a dummy third
             *   person singular noun as a default subject for the verb.
             */
            if(ctx.subj == nil)
                ctx.subj = dummy_;
            
            /* we found the parameter - get the translation */
            txt = t[2](ctx, params);
            
            /* 
             *   if this isn't a pre-scan, and the parameter name starts
             *   with a capital, mimic that pattern in the result 
             */
            if (txt != nil && !ctx.prescan && rexMatch(R'<upper>', pname) != nil)
                txt = txt.firstChar().toUpper() + txt.delFirst();
        }

        /* 
         *   if we failed to find an expansion, and this isn't just a
         *   pre-scan, return the source text as an error indication 
         */
        if (txt == nil && !ctx.prescan)
            txt = '{' + params.join(' ') + '}';

        /* return the result */
        return txt;
    }

    /* 
     *   Parameter mapping list.  This is a list of lists: [name, func],
     *   where 'name' is the parameter name (as a string), and 'func' is
     *   the expansion handler function.
     *   
     *   The parameter name must be all lower case.  During expansion, we
     *   convert the first space-delimited token within the {curly brace}
     *   parameter string to lower case, then look for an entry in the list
     *   with the matching parameter name.  If we find an entry, we call
     *   its handler function.
     *   
     *   The handler function is a pointer to a function that takes two
     *   arguments: func(params, ctx), where 'params' is the list of tokens
     *   within the {curly braces} of the substitution string, as a list of
     *   strings, where each string is a space-delimited token in the
     *   original {curly brace} string; and 'ctx' is the MessageCtx object
     *   for the expansion.  The function returns a string giving the
     *   expansion of the parameter.
     *   
     *   The parameter list must be provided by the language module, since
     *   each language's list of parameters and expansions will vary.  
     */
    params = [ ]

    /*
     *   Some parameters expand to properties of objects involved in the
     *   command.  cmdInfo() makes it easier to define the expansion
     *   functions for such parameters.  We search the parameters for a
     *   Command object, and if we find it, we retrieve a particular source
     *   object and evaluate a particular property on the source object to
     *   get the result string.
     *   
     *   For example, {the dobj} could be handled via cmdInfo('ctx, dobj',
     *   &theName, vSubject): we find the current 'dobj' object in the
     *   Command, then evaluate the &theName property on that object.
     *   
     *   'ctx' is the MessageCtx object with the current sentence context.
     *   
     *   'src' is the source object in the Command.  This can be given as a
     *   property pointer (&actor, say), in which case we simply evaluate
     *   that property of the Command object (cmd.(src)) to get the source
     *   object.  Or, it can be a string giving a NounRole name (dobj,
     *   iobj, acc), in which case we'll retrieve the current object for
     *   the noun role from the Command.  Or, it can be a string with a
     *   number, in which case we'll use the number as an index into the
     *   argument list.
     *   
     *   'objProp' is the property of the source object to evaluate to get
     *   the expansion string.
     *   
     *   'role' is vSubject if this is a noun phrase with subject usage (in
     *   most languages, this is a noun phrase in the nominative case; in
     *   English this is called subjective case).  It's vObject for any
     *   other noun phrase role (direct object, prepositional object, etc).
     *   If the role isn't clear from the context (the case marking of the
     *   parameter, or the position), use vAmbig to mark it as ambiguous.  
     */
    cmdInfo(ctx, src, objProp, role)
    {
        try
        {
            /* we don't have a source object yet */
            local srcObj = nil;
            
            /* if the source is a role name, get the corresponding property */
            if (dataType(src) == TypeSString)
            {
                /* check for a number */
                if (rexMatch(R'<digit>+', src) != nil)
                {
                    /* it's an argument index */
                    src = ctx.args[toInteger(src)];
                }
                else
                {
                    /* Find the source object corresponding to the string */
                    src = findStrParam(src, role);
                
                /* 
                 *   If we didn't find an object, return nil to the caller to
                 *   indicate an error
                 */     
                
                    if(src == nil)
                        return nil;
                
                }
                    
            }

            /* retrieve the source object from the command */
            if (dataType(src) == TypeProp)
                srcObj = ctx.cmd.(src);
            else if (dataType(src) == TypeObject 
                     && (src.ofKind(Mentionable) || src.ofKind(Pronoun)
                         || src.ofKind(LiteralObject) ||
                         src.ofKind(ResolvedTopic)))
                srcObj = src;

            /* check for reflexivity */
            if (srcObj != nil && role == vObject && !ctx.prescan)
            {
                local r = cmdInfoReflexive(ctx, srcObj, objProp);
                if (r != nil)
                    return r;
            }

            /* note the object's role in the sentence context */
            if (srcObj != nil)
                ctx.noteObj(srcObj, role);

            /* 
             *   if we're in pre-scan mode, skip the actual expansion;
             *   otherwise evaluate the target property on the source
             *   object to get the expansion text 
             */
            return ctx.prescan ? nil : srcObj.(objProp);
        }
        catch (Exception e)
        {
            /* 
             *   if anything went wrong, return nil to indicate we failed
             *   to find an expansion
             */
            return nil;
        }
    }
    
    findStrParam(src, role)
    {
        local targetObj;
        
        if (gAction != nil)
        {
            /* get the target object by name through the action */
            targetObj = gAction.getMessageParam(src);
        }
        else
        {
            /* there's no action, so we don't have a value yet */
            targetObj = nil;
        }
        
        if (targetObj == nil)
        {
            /* look up the name */
            targetObj = libGlobal.nameTable_[src];
            
            /* 
             *   if we found it, and the result is a function pointer or an
             *   anonymous function, invoke the function to get the result
             */
            if (dataTypeXlat(targetObj) == TypeFuncPtr)
            {
                /* evaluate the function */
                targetObj = (targetObj)();
            }
        }
        
        /* 
         *   If we still haven't found a targetObj, try getting it from the
         *   role's object property.
         */
        
        if (targetObj == nil && role != nil)
        {
            /* it's a role name - look up the role */
            local role = NounRole.all.valWhich({ r: r.name == src });
            
            /* get the role's object property */
            if(role != nil)
               targetObj = role.objProp;
        }
        
        /* 
         *   If we still haven't found a targetObj, there's probably an error in
         *   the way the object parameter was specified, but rather than
         *   allowing this to cause a run-time error down the track, substitute
         *   a dummy object and note the offending src parameter on an
         *   appropiate property so that the text presented should make it clear
         *   where the problem lies.
         */
        
        if(targetObj == nil)
        {
            targetObj = dummy_;
            dummy_.noteName('[' + src + ']');
        }
            
        
        return targetObj;
    }

    /* 
     *   Parameter lookup table.  This maps a parameter name to its handler
     *   function.  
     */
    paramTab = nil

    /* the language module's instance of the class */
    langObj = nil

    /* construction - build the lookup table */
    construct()
    {
        /* remember the instance */
        MessageParams.langObj = self;

        /* create the parameter table */
        paramTab = new LookupTable(64, 128);
        foreach (local p in params)
            paramTab[p[1]] = p;
    }
;

/* Dummy object to use as a fallback when a parameter can't be identified */

dummy_: Thing
    noteName(src) { }
;

pluralDummy_: Thing
    noteName(src) { }
;


/*----------------------------------------------------------------------------*/

