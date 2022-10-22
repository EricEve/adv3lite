#charset "us-ascii"
#include "advlite.h"

/* ------------------------------------------------------------------------ */
/*
 *   Spelling corrector.  This object implements automatic spelling
 *   correction on the player's input.  
 */
spellingCorrector: object
    /*
     *   Find the first word token that isn't in the dictionary.  Returns
     *   the token index, or nil if we don't find any unknown words. 
     */
    findUnknownWord(toks)
    {
        /* scan for a word that's not in the dictionary */
        for (local i = 1, local len = toks.length() ; i <= len ; ++i)
        {
            /* get this token */
            local tok = toks[i];

            /* if it's a word, and it's not defined, return its index */
            if (isWordToken(tok) && !isWordDefined(getTokVal(tok)))
                return i;
        }

        /* we didn't find any unknown words */
        return nil;
    }

    /*
     *   Attempt to correct a typographical error in a token list.
     *   
     *   'toks' is a token list to be corrected, and 'idx' is the index of
     *   the first unknown word.  'err' is ParseError that triggered the
     *   spelling check.  We use the error to filter the list of candidates
     *   for corrected spellings: for a general verb syntax error, for
     *   example, we'll look for words that are used in verb phrases, and
     *   for noun resolution we'll look for words associated with in-scope
     *   objects.
     *   
     *   If we fail to find a correction, the return value is nil.
     *   
     *   If we find a correction, the return value is a list of token
     *   lists.  It's a list rather than a single correction because we
     *   might be unable to break a tie; rather than picking one
     *   arbitrarily, we return all of the candidates.  This allows the
     *   caller to try the different possibilities.  The caller will
     *   generally have more information than we have here about the
     *   overall context, so it's in a better position to make a final
     *   judgment about how to break a tie.
     *   
     *   Note that we only correct a single error per call.  If the token
     *   list has additional unknown words, the caller can continue parsing
     *   and call here again to get candidate corrections for the next
     *   word, and so on until all unknown words are resolved.  We use this
     *   iterative approach because the first correction might change the
     *   parser's guess about where the error lies; by waiting, we get the
     *   benefit of the revised context information for correcting each
     *   additional word.  
     */
    correct(toks, idx, err)
    {
        /*
         *   Check for extra or missing spaces.  These are common typing
         *   errors, but our Levenshtein-distance corrector misses these
         *   because it only handles one word at a time.  So, we need to
         *   check for these separately.  
         */
        local spc = checkSpacing(toks, idx, err);

        /* get the token in question */
        local a = toks[idx], aw = getTokVal(a);

        /* 
         *   if the token is completely non-alphabetic, don't attempt
         *   correction - these are probably misplaced punctuation marks or
         *   completely spurious entries, so any attempted correction would
         *   almost certainly be wrong 
         */
        if (aw.find(R'<alpha>') == nil)
            return nil;

        /* get a list of candidates for the corrected word */
        local wlst = getCandidates(aw), wlen = wlst.length();

        /* build a list of candidate token lists */
        local clst = new Vector(wlen + 1);
        foreach (local w in wlst)
        {
            /* skip one-character candidates */
            if (w[1].length() < 2)
                continue;

            /*
             *   create the candidate token list: make a copy of the
             *   original token list, and substitute this candidate word
             *   for the unknown word 
             */
            local toks2 = toks;
            getTokVal(toks2[idx]) = w[1];
            getTokOrig(toks2[idx]) = matchCase(w[1], getTokOrig(toks2[idx]));
            
            /* add it to the list of candidates */
            clst.append(new CorrectionCandidate(toks2, w[2], w[3], idx, err));
        }
        
        /* if we found a possible spacing correction, add that as well */
        if (spc != nil)
            clst.append(spc);

        /* filter out candidates with rankings of zero */
        clst = clst.subset({ c: c.ranking != 0 });

        /* if the list is empty, we have no corrections to propose */
        if (clst.length() == 0)
            return nil;

        /*   
         *   sort by descending match quality: high rank first, then
         *   shorter edit distance first, then fewer replacements first
         */
        clst.sort(SortDesc,
                  { a, b: a.ranking != b.ranking ? a.ranking - b.ranking :
                          a.editDist != b.editDist ? b.editDist - a.editDist :
                          b.replCnt - a.replCnt });

        /* 
         *   return all of the candidates tied for best - just return the
         *   token lists 
         */
        return clst.mapAll({ x: x.tokenList });
    }

    /* 
     *   Find spacing corrections for the token at the given index.  This
     *   looks for extra inserted spaces, missing spaces, and spaces
     *   transposed with adjacent letters.  We return a list of proposed
     *   changes; each element is a list of three token values, giving the
     *   preceding, current and next token in the proposed change.  The
     *   preceding and/or next can be nil, in which case we're not
     *   proposing changes to those tokens.
     *   
     *   Note that all spacing changes have edit distance 1.  All of our
     *   corrections are single character insertions or deletions, or pair
     *   transpositions (which we count as one edit).  
     */
    checkSpacing(toks, idx, err)
    {
        /* note the total number of tokens */
        local len = toks.length();

        /* get this token, and its base text */
        local a = toks[idx], aw = getTokVal(a), alen = aw.length();

        /* if this isn't a word token, don't bother with spacing changes */
        if (!isWordToken(a))
            return nil;

        /* start with a copy of the input list */
        local ret = new Vector(len, toks);
        
        /*
         *   If the word isn't in the dictionary, look for a missing space.
         *   That is, try inserting a space at each character position to
         *   see if we can make two good words in place of this bad word.  
         */
        if (!isWordDefined(aw))
        {
            /* try each character position from 2 to last-minus-1 */
            for (local i = 2 ; i < alen ; ++i)
            {
                /* check to see if splitting here makes two good words */
                if (isWordDefined(aw.substr(1, i - 1))
                    && isWordDefined(aw.substr(i)))
                {
                    /* this works - keep the split tokens */
                    ret[idx] = [aw.substr(1, i- 1), getTokType(a),
                                getTokOrig(a).substr(1, i - 1)];
                    ret.insertAt(idx + 1,
                                 [aw.substr(i), getTokType(a),
                                  getTokOrig(a).substr(i)]);
                    
                    /* return the updated list */
                    return new CorrectionCandidate(
                        ret.toList(), 1, 0, idx, err);
                }
            }
        }
        
        /* if there's a previous word, try combinations with it */
        if (idx > 1 && correctPairSpacing(ret, idx - 1))
            return new CorrectionCandidate(ret.toList(), 1, 0, idx - 1, err);

        /* if there's a next word, try combinations with it */
        if (idx < len && correctPairSpacing(ret, idx))
            return new CorrectionCandidate(ret.toList(), 1, 0, idx, err);

        /* we didn't find any changes to make */
        return nil;
    }

    /*
     *   Try correcting spelling based on changes to the spacing between a
     *   pair of tokens.  We'll try deleting the intervening space
     *   entirely, and we'll try transposing the space with each adjacent
     *   letter.  'toks' is a vector that we'll modify in place; 'idx' is
     *   the index of the first word of the pair.  We return true if we
     *   make a correction, nil if not.  
     */
    correctPairSpacing(toks, idx)
    {
        /* get the two tokens */
        local a = toks[idx], aw = getTokVal(a), alen = aw.length();
        local b = toks[idx+1], bw = getTokVal(b), blen = bw.length();
        
        /* 
         *   If one or the other token isn't a word, or both the current
         *   word and the next word are already in the dictionary, don't
         *   bother with the combinations after all.  We only make edits
         *   when they're clearly improvements, meaning that we go from
         *   having an unrecognized word to having a recognized word.  If
         *   both words are already recognized, we can't improve anything.
         */
        if (!isWordToken(b) || !isWordToken(b)
            || (isWordDefined(aw) && isWordDefined(bw)))
            return nil;
            
        /* try deleting the space between this word and the next */
        if (isWordDefined(aw + bw))
        {
            /* a+b is a word - keep the combined token */
            toks[idx] = concatTokens(a, b);

            /* delete the second token, since we're combining the two */
            toks.removeElementAt(idx + 1);

            /* indicate that we made a change */
            return true;
        }

        /* 
         *   try transposing the space between the words with the final
         *   letter of the first word: that is, try removing the final
         *   letter of the first word and attaching it to the second word 
         */
        local a2 = aw.delLast();
        local b2 = aw.lastChar() + bw;
        if (alen > 1 && isWordDefined(a2) && isWordDefined(b2))
        {
            /* that worked - apply the change */
            toks[idx] = [a2, getTokType(a), getTokOrig(a).delLast()];
            toks[idx+1] = [b2, getTokType(b),
                           getTokOrig(a).lastChar() + getTokOrig(b)];

            /* indicate that we made a change */
            return true;
        }

        /* 
         *   try transposing the space after this word with the first
         *   letter of the next word 
         */
        local a3 = aw + bw.firstChar();
        local b3 = bw.delFirst();
        if (blen > 1 && isWordDefined(a3) && isWordDefined(b3))
        {
            /* that worked - apply the change */
            toks[idx] = [a3, getTokType(a),
                         getTokOrig(a) + getTokOrig(b).firstChar()];
            toks[idx+1] = [b3, getTokType(b), getTokOrig(b).delFirst()];

            /* indicate that we made a change */
            return true;
        }

        /* indicate that we didn't make any changes */
        return nil;
    }

    /* the dictionary object we use for looking up words */
    dict = cmdDict

    /*
     *   Is the given word defined?  We check the command dictionary for
     *   the word. 
     */
    isWordDefined(w) { return dict.isWordDefined(w); }

    /*
     *   Get a list of similar words, with their Levenshtein edit distances
     *   This returns a list of [word, distance] values.  
     */
    getCandidates(w)
    {
        /* 
         *   Figure the maximum Levenshtein distance to allow.  Use a
         *   roughly logarithmic scale: for short words (four letters or
         *   less), allow only one edit; for medium words (five to seven
         *   letters), allow two edits; for longer words, allow up to three
         *   edits. 
         */
        local wlen = w.length();
        local maxDist = (wlen <= 4 ? 1 : wlen <= 7 ? 2 : 3);

        /* ask the dictionary for the word list */
        return dict.correctSpelling(w, maxDist);
    }
;

/* ------------------------------------------------------------------------ */
/*
 *   Spelling correction candidate.  This tracks a modified token list with
 *   a corrected word, to keep track of which word was corrected and how
 *   well it ranks by our selection criteria.  
 */
class CorrectionCandidate: object
    construct(toks, dist, repl, idx, err)
    {
        /* save the basic data */
        tokenList = toks;
        editDist = dist;
        wordIdx = idx;
        replCnt = repl;

        /* assign the ranking via the error */
        ranking = err.rankCorrection(toks, idx, spellingCorrector.dict);
    }

    /* the corrected token list */
    tokenList = nil

    /* ranking */
    ranking = nil

    /* the edit distance between the original and corrected words */
    editDist = 0

    /* number of character replacements included in the edit distance */
    replCnt = 0

    /* the index of the corrected word */
    wordIdx = 1
;



/* ------------------------------------------------------------------------ */
/*
 *   Action Dictionary.  This is a lookup table that we generate during
 *   preinit from the vocabulary words associated with 'predicate' grammar
 *   rules.  We map each vocabulary word to the Action objects it's
 *   associated with.
 *   
 *   The standard dictionary contains all of these words as well, but it
 *   maps them all to the generic 'predicate' GrammarProd object.  That
 *   doesn't help us identify which words are associated with which
 *   actions.  That information is sometimes needed, such as during
 *   spelling correction.
 *   
 *   Note that the system library file gramprod.t must be included in the
 *   build, so that GrammarAltInfo is defined.  
 */
actionDictionary: PreinitObject
    /* initialize */
    execute()
    {
        /* get the table into a local for faster access */
        local atab = wordToAction = new LookupTable(128, 256);
        local xtab = xwords = new LookupTable(128, 256);
        
        /* run through each predicate rule */
        foreach (local gi in predicate.getGrammarInfo())
        {
            /* if the match object is a VerbProduction, process it */
            if (gi.gramMatchObj.ofKind(VerbProduction))
            {
                /* get the action */
                local action = gi.gramMatchObj.action;
                
                /* 
                 *   get the word list - this is the subset of gramTokens
                 *   items with type GramTokTypeLiteral, with just the word
                 *   strings (the gramTokInfo members) pulled out 
                 */
                local wlst = gi.gramTokens
                    .subset({t: t.gramTokenType == GramTokTypeLiteral })
                    .mapAll({t: t.gramTokenInfo });

                /* scan the token list */
                foreach (local w in wlst)
                {
                    /* add the action table entry */
                    if (atab[w] == nil)
                        atab[w] = [];
                    atab[w] += action;

                    /* add the associated word table entry */
                    if (xtab[w] == nil)
                        xtab[w] = [];
                    xtab[w] += wlst;
                }
            }
        }
    }

    /* 
     *   word-to-action table: this maps each vocabulary word to a list of
     *   the Action objects associated with the grammar rules in which it
     *   appears 
     */
    wordToAction = nil

    /* 
     *   Associated word table: this maps each vocabulary word to a list of
     *   all of the other words that appear in predicate grammar rules in
     *   which the given word appears.  For example, 'up' will have a list
     *   like [pick, go, look], since it's used in rules for 'pick up', 'go
     *   up', 'look up'.  
     */
    xwords = nil
;


/* ------------------------------------------------------------------------ */
/*
 *   SpellingHistory: this maintains the history of attempted spelling
 *   corrections for the current command.  We process each word separately,
 *   so each word has its own entry in the history.
 *   
 *   The point of maintaining a history is that it allows us to backtrack
 *   if we decide that an earlier guess at a corrected word isn't going to
 *   result in a working command after all.  If an earlier correction had
 *   other equally good options, we can go back and try the other options
 *   by unwinding the history.  
 */
class SpellingHistory: object
    construct(parser)
    {
        /* remember the parser */
        self.parser = parser;

        /* note the starting time */
        startTime = getTime(GetTimeTicks);
    }

    /* have we made any corrections? */
    hasCorrections() { return cstack.length() != 0; }

    /*
     *   Check for spelling errors in a token list, and attempt automatic
     *   spelling correction.  We'll scan the token list for a word that
     *   isn't in the dictionary.  If we find one, and spelling correction
     *   is enabled, we'll attempt to automatically correct the error.
     *   
     *   'toks' is the token list for the command line, and 'err' is the
     *   ParseError object indicating what error triggered the spelling
     *   check.
     *   
     *   Returns a new token list if we correct a spelling error, nil
     *   otherwise.  
     */
    checkSpelling(toks, err)
    {
        local t;

        /* if spelling correction is disabled, we can't correct anything */
        if (!parser.autoSpell)
            return nil;

        /* if we've exhausted the spelling correction time limit, give up */
        #ifndef __DEBUG
        if (getTime(GetTimeTicks) > startTime + parser.spellTimeLimit)
            return nil;
        #endif

        /* check for an obvious typo - i.e., a word not in the dictionary */
        local idx = spellingCorrector.findUnknownWord(toks);
        local unknown = (idx != nil);

        /*
         *   If we couldn't find any more *obvious* typos, we could have a
         *   more subtle error: a typo that misspells a word as another
         *   word that's coincidentally also in the dictionary: "no" for
         *   "on", "cattle" for "castle", etc.  So: pick a word that we
         *   haven't corrected yet on this pass, and try correcting it.
         *   
         *   Skip this step if we're already attempting a correction to a
         *   word that was in the dictionary.  This type of correction is
         *   much more speculative than for obvious typos (which is still
         *   somewhat speculative: a game dictionary is much smaller than
         *   the natural language's lexicon).  The odds of *multiple* typos
         *   that match dictionary words are geometrically smaller with
         *   each added typo.  The odds of a false positive are
         *   correspondingly higher.  To limit the damage we can do by wild
         *   guessing, then, we'll draw the line at one non-obvious typo
         *   correction per input.  
         */
        local limit = 1;
        if (idx == nil && cstack.countWhich({ c: !c.unknown }) < limit)
        {
            /*
             *   The odds of a typo matching a dictionary word decrease
             *   exponentially as word length increases (the number of
             *   possible letter combinations increases exponentially with
             *   word length, while the number of real words increases
             *   polynomially at best).  We're thus most likely to find a
             *   valid correction with the shortest words.  Get a list of
             *   word indexes sorted by increasing word length.  
             */
            local i, len = toks.length();
            local iv = new Vector(len);
            for (i = 1 ; i <= len ; ++i)
                iv[i] = i;

            iv.sort(SortAsc,
                    { a, b: getTokVal(toks[a]).length()
                    - getTokVal(toks[b]).length() });
            
            /* 
             *   scan for a word we haven't attempted to change yet; search
             *   in order of word length 
             */
            for (i = 1 ;
                 i <= len
                 && (!isWordToken(toks[iv[i]])
                     || corrections.indexOf(iv[i]) != nil) ;
                 ++i) ;

            /* if we found an as-yet uncorrected word, try correcting it */
            if (i <= len)
            {
                idx = iv[i];
                unknown = nil;
            }
        }

        /* if we found something to correct, try correcting it */
        if (idx != nil)
        {
            /* try correcting this word */
            local candidates = spellingCorrector.correct(toks, idx, err);

            /* if we found any candidates, try them out */
            if (candidates != nil)
            {
                /* add this to the list of corrections we've attempted */
                corrections += idx;

                /*
                 *   Log the correction in the history stack.  If we're
                 *   already working on a non-obvious typo, don't stack it;
                 *   just replace the top of stack with the new state.  
                 */
                if (cstack.isEmpty() || (t = cstack.getTop()).unknown)
                {
                    /* log the correction in the history */
                    cstack.push(new SpellingCorrection(
                        toks, candidates, corrections, unknown, err));
                }
                else
                {
                    /* replace the top of stack */
                    t.candidates = candidates;
                    t.curCand = 1;
                }

                /* log it for debugging */
                IfDebug(spelling,
                        "\nRespell: <<candidates[1].mapAll(
                            {x: getTokVal(x)}).join(' ')>>\n");
                
                /* return the first candidate token list */
                return candidates[1];
            }
        }

        /* 
         *   We've run out of words to correct, so try backtracking.  Look 
         *   at the stack and see if there are any items with more 
         *   candidates to try out.  If so, try out the next candidate.
         */
        if (cstack.indexWhich({c: c.curCand < c.candidates.length()}) != nil)
        {
            /* pop items until we reach one that hasn't been exhausted */
            while ((t = cstack.getTop()).curCand == t.candidates.length())
            {
                /* pop this stack item */
                local c = cstack.pop();

                /* restore the attempted correction list before this point */
                corrections = c.corrections;
            }

            /* log it for debugging */
            IfDebug(spelling, 
                    "\nRespell: <<t.candidates[t.curCand+1].mapAll(
                        {x: getTokVal(x)}).join(' ')>>\n");

            /* return the next candidate from this item */
            return t.candidates[++t.curCand];
        }

        /* no corrections are available */
        return nil;
    }

    /*
     *   Roll back spelling changes to the last one that actually improved
     *   matters.  'toks' is the latest token list, and 'err' is the
     *   parsing error that we encountered attempting to parse this token
     *   list.
     *   
     *   If 'err' is a curable error, we'll leave things as they are.  The
     *   curable error means that the token list is now well-formed, but is
     *   missing some information we need to actually execute it.  Since
     *   it's well-formed, our spelling corrections must have made some
     *   kind of sense, so we'll assume they were correct.
     *   
     *   If the error isn't curable, though, our spelling corrections
     *   didn't result in a working command.  The way we pick candidate
     *   words tends to give us lots of false matches, so the fact that we
     *   didn't end up with meaningful syntax overall suggests that our
     *   guess for an individual word was a spurious match.
     *   
     *   To determine what we keep and what we roll back, we look at
     *   whether a change improved the intelligibility of the command.
     *   There are basically three stages of intelligibility that we can
     *   distinguish: (1) completely unintelligible, (2) valid verb
     *   structure but unknown noun phrases, and (3) valid verb structure
     *   AND resolvable noun phrases.
     *   
     *   We want to keep any attempted spelling corrections that
     *   successfully advanced us from one stage to the next, because the
     *   improved intelligibility is pretty good evidence that our
     *   corrections were in fact correct.  We DON'T want to keep any
     *   corrections that didn't advance the process, because we can't tell
     *   if they actually helped.  We're intentionally conservative about
     *   spelling correction, because spurious corrections are worse in an
     *   IF context than in most applications.  In IF, a spurious
     *   correction could be a spoiler, by revealing the existence of a
     *   dictionary word too early in the game.  To reduce spurious
     *   corrections, we only accept corrections that actually make the
     *   command more parseable.
     */
    rollback(toks, err)
    {
        /* set up a dummy history item for the new error */
        local h = new SpellingCorrection(toks, toks, corrections, nil, err);

        /* if the error isn't curable, roll back unhelpful changes */
        if (!err.curable)
        {
            /* push the new error history item for easy scanning */
            cstack.push(h);
            local clen = cstack.length();

            /* assume we'll roll back to the first element */
            local hidx = 1;
            h = cstack[1];

            /* scan for the last stage upgrade in the list */
            for (local i = 2 ; i <= clen ; ++i)
            {
                /* if this is an upgrade, don't roll back past here */
                if (cstack[i].parseError.errStage > h.parseError.errStage)
                {
                    h = cstack[i];
                    hidx = i;
                }
            }

            /* discard the history items from the last one on */
            cstack.removeRange(hidx, clen);
        }

        /* return the history item we decided upon */
        return h;
    }

    /*
     *   Note spelling changes between the original token list and the
     *   given token list. 
     */
    noteSpelling(newToks)
    {
        /* if there's nothing in the stack, there are no changes to report */
        if (cstack.length() == 0)
            return;

        /* 
         *   Start by turning the token lists back into strings, then
         *   splitting them up into simple space-delimited tokens.  The
         *   full tokenizer can split tokens at delimiters other than
         *   spaces, but for our purposes we're only interested in the
         *   individual words tokens.  
         */
        local orig = cmdTokenizer.buildOrigText(cstack[1].oldToks).split(' ');
        newToks = cmdTokenizer.buildOrigText(newToks).split(' ');
        local newLen = newToks.length();

        /* if there are no tokens, there's nothing to display */
        if (newLen == 0)
            return;

        /* diff the word lists */
        local lcs = new LCS(orig, newToks);

        /* translate the new tokens to a vector for faster updates */
        newToks = new Vector(newLen, newToks);

        /* 
         *   Run through the new string, and highlight each word (via HTML)
         *   that's NOT in the common subsequence list.  Anything that's
         *   not in the common list is only in the new list, which means
         *   it's either an insertion or a replacement relative to the
         *   original string the user typed.  
         */
        for (local l = lcs.lcsB, local li = 1, local i = 1 ; i <= newLen ; ++i)
        {
            /* check to see if this word is in the common subsequence */
            if (li <= l.length() && l[li] == i)
            {
                /* it's in the common sublist - advance the common index */
                ++li;
            }
            else
            {
                /* it's not in the common sublist - highlight it */
                newToks[i] = '<b>' + newToks[i] + '</b>';
            }
        }
        
        /* reassemble the token list */
        local str = newToks[1];
        for (local i = 2 ; i <= newLen ; ++i)
            str += ' ' + newToks[i];

        /* for debugging, show the elapsed time for spelling correction */
        IfDebug(spelling, "\nElapsed spelling time: <<
              getTime(GetTimeTicks) - startTime>> ms\n");

        /* 
         *   While we're using the ^ for ' substitution trick to deal with
         *   certain apostrophe-S words, we need to change ^s back to 's in the
         *   spelling checker's output.
         */
        str = str.findReplace('^s', '\'s');
        
        
        /*
         *   Announce a correction made by the spelling corrector.  The
         *   corrected string includes HTML markups to highlight the word
         *   or words that the spelling corrector changed.  
         */
        DMsg(corrected spelling, '(<i>{1}</i>)<br>', str);
        
    }

    /* our parser object */
    parser = nil

    /* starting time (in GetTimeTicks time) */
    startTime = 0

    /* 
     *   The indices of the words we've corrected so far.  We keep track of
     *   the corrections we've made so that we don't try to further correct
     *   a word we've already corrected.  (We *do* try multiple candidates
     *   per slot, but we do that by backtracking.) 
     */
    corrections = []

    /* 
     *   The attempted correction stack.  Each time we correct a word,
     *   we'll add a SpellingCorrection item to the stack.  If we decide a
     *   correction didn't work after all (i.e., didn't yield a valid
     *   parsing), the stack lets us retract it and try a different
     *   correction candidate.  
     */
    cstack = perInstance(new Vector(10))
    
    /*
     *   Clear the history
     */
    clear()
    {
        corrections = [];
        
        cstack = new Vector(10);
    }

;

/* ------------------------------------------------------------------------ */
/*
 *   SpellingCorrection: Each time we attempt a spelling correction, we'll
 *   save information on the attempt in one of these objects.  
 */
class SpellingCorrection: object
    construct(oldToks, candidates, corrections, unknown, err)
    {
        self.oldToks = oldToks;
        self.candidates = candidates;
        self.corrections = corrections;
        self.unknown = unknown;
        self.parseError = err;
    }

    /* the token list before the spelling correction */
    oldToks = nil

    /* 
     *   is this a correction for an unknown word (as opposed to a word
     *   that's in the dictionary, but still could be a typo)? 
     */
    unknown = nil
    
    /* the indices of the corrections so far, before this one */
    corrections = nil

    /* the candidate list - this is a list of token lists */
    candidates = nil

    /* the current candidate index */
    curCand = 1

    /* the ParseError that triggered the spelling correction attempt */
    parseError = nil
;
    

