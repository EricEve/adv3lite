#charset "us-ascii"
#include <dict.h>
#include <strcomp.h>
#include <tok.h>
#include "advlite.h"


/* ------------------------------------------------------------------------ */
/*
 *   Additional token types for US English.
 */

/* special "apostrophe-s" token */
enum token tokApostropheS;

/* special abbreviation-period token */
enum token tokAbbrPeriod;

/* special "#nnn" numeric token */
enum token tokPoundInt;

/* ------------------------------------------------------------------------ */
/*
 *   Is the given token a word?  This receives a token element in the same
 *   format returned by Tokenizer.tokenize().  Returns true if the token
 *   represents a word that could be looked up in the dictionary, nil if
 *   it's something else (such as punctuation, a number, or a quoted
 *   literal).
 *   
 *   [Required] 
 */
isWordToken(tok)
{
    /* in English, the word tokens are of type tokWord and tokAbbrPeriod */
    return getTokType(tok) is in (tokWord, tokAbbrPeriod);
}

/* ------------------------------------------------------------------------ */
/*
 *   Concatenate two tokens.  This takes two token elements in the same
 *   format returned by Tokenizer.tokenize(), and returns a combined
 *   element in the same format.  The result should be as though the
 *   original pair of tokens had been concatenated in the input string.  
 */
concatTokens(a, b)
{
    /* 
     *   Return the concatenated token values and original text.  Use the
     *   second token's type as the combined type.  In most cases, the two
     *   types will be the same, since it usually only makes sense to
     *   combine tokens of like kind.  
     */
    return [getTokVal(a) + getTokVal(b),
            getTokType(b),
            getTokOrig(a) + getTokOrig(b)];
}

/* ------------------------------------------------------------------------ */
/*
 *   Command tokenizer for US English.  Other language modules should
 *   provide their own tokenizers to allow for differences in punctuation
 *   and other lexical elements.
 *   
 *   [Required] 
 */
cmdTokenizer: Tokenizer
    /*
     *   The list of tokenizing rules.  This isn't actually required to be
     *   defined by the language module, since you *could* just use the
     *   default rules inherited from the base Tokenizer class, but it's
     *   likely that each language will have some quirks that require
     *   custom rules.  
     */
    rules_ = static
    [
        /* skip whitespace */
        ['whitespace', new RexPattern('<Space>+'), nil, &tokCvtSkip, nil],

        /* certain punctuation marks */
        ['punctuation', new RexPattern('<' + punctChars + '>'),
         tokPunct, nil, nil],

        /*
         *   We have a special rule for spelled-out numbers from 21 to 99:
         *   when we see a 'tens' word followed by a hyphen followed by a
         *   digits word, we'll pull out the tens word, the hyphen, and
         *   the digits word as separate tokens.
         */
        ['spelled number',
         new RexPattern('<NoCase>(twenty|thirty|forty|fifty|sixty|'
                        + 'seventy|eighty|ninety)-'
                        + '(one|two|three|four|five|six|seven|eight|nine)'
                        + '(?!<AlphaNum>)'),
         tokWord, &tokCvtSpelledNumber, nil],

        /* integer numbers */
        ['integer', new RexPattern('[0-9]+' + endAssert),
         tokInt, nil, nil],
        
//        ['real', new RexPattern('[0-9]+<period>[0-9]+' + endAssert), tokReal,
//            nil, nil],

        /* numbers with a '#' preceding */
        ['integer with #', new RexPattern('#[0-9]+' + endAssert),
         tokPoundInt, nil, nil],

        /*
         *   Initials.  We'll look for strings of three or two initials,
         *   set off by periods but without spaces.  We'll look for
         *   three-letter initials first ("G.H.W. Billfold"), then
         *   two-letter initials ("X.Y. Zed"), so that we find the longest
         *   sequence that's actually in the dictionary.  Note that we
         *   don't have a separate rule for individual initials, since
         *   we'll pick that up with the regular abbreviated word rule
         *   below.
         *
         *   Some games could conceivably extend this to allow strings of
         *   initials of four letters or longer, but in practice people
         *   tend to elide the periods in longer sets of initials, so that
         *   the initials become an acronym, and thus would fit the
         *   ordinary word token rule.
         */
        ['three initials',
         new RexPattern('<alpha><period><alpha><period><alpha><period>'),
         tokWord, &tokCvtAbbr, &acceptAbbrTok],

        ['two initials',
         new RexPattern('<alpha><period><alpha><period>'),
         tokWord, &tokCvtAbbr, &acceptAbbrTok],

        /*
         *   Abbbreviated word - this is a word that ends in a period, such
         *   as "Mr.".  This rule comes before the ordinary word rule
         *   because we will only consider the period to be part of the
         *   word (and not a separate token), but only if the entire string
         *   including the period is in the dictionary.  
         */
        ['abbreviation',
         new RexPattern('<AlphaNum|' + wordPunct + '>+<period>'),
         tokWord, &tokCvtAbbr, &acceptAbbrTok],

        /*
         *   A word ending in an apostrophe-s.  We parse this as two
         *   separate tokens: one for the word and one for the
         *   apostrophe-s.
         */
        ['apostrophe-s word',
         new RexPattern('<AlphaNum|' + wordPunct + '>+<' + squote + '>[sS]%>'),
         tokWord, &tokCvtApostropheS, nil],

        /*
         *   Words - note that we convert everything to lower-case.  A word
         *   must start with an alphabetic character, a hyphen, or an
         *   ampersand; after the initial character, a word can contain
         *   alphabetics, digits, hyphens, ampersands, and apostrophes.
         */
        ['word',
         new RexPattern('<AlphaNum|' + wordPunct + '|' + squote + '>+'),
         tokWord, nil, nil],

        /* strings with ASCII "straight" quotes */
        ['string ascii-quote',
         new RexPattern('<min>([`\'"])(.*)%1' + endAssert),
         tokString, nil, nil],

        /* some people like to use single quotes like `this' */
        ['string back-quote',
         new RexPattern('<min>`(.*)\'' + endAssert), tokString, nil, nil],

        /* strings with Latin-1 curly quotes (single and double) */
        ['string curly single-quote',
         new RexPattern('<min>\u2018(.*)\u2019'), tokString, nil, nil],
        ['string curly double-quote',
         new RexPattern('<min>\u201C(.*)\u201D'), tokString, nil, nil],

        /*
         *   unterminated string - if we didn't just match a terminated
         *   string, but we have what looks like the start of a string,
         *   match to the end of the line
         */
        ['string unterminated',
         new RexPattern('([`\'"\u2018\u201C](.*)'), tokString, nil, nil],

        /* 
         *   Accept any other group of characters, barring spaces and
         *   punctuation that we handle specially, as though they were
         *   words.  This is a catch-all for anything that the other rules
         *   don't handle, and will just make a basic word out of any group
         *   of characters delimited by one of our normal delimiters.  
         */
        ['any characters', new RexPattern('<^space|' + punctChars + '>+'),
         tokWord, nil, nil]
    ]

    /* token-separating punctuation marks, as an <alpha|x|y> pattern */
    punctChars = '.|,|;|:|?|!'

    /* end-of-token assertion */
    endAssert = static ('(?=$|<space|' + punctChars + '>)')

    /* 
     *   List of characters consisting a single quote mark.  This includes
     *   regular ASCII straight quotes as well as the unicode curly quotes.
     *   This is for pasting into a <alpha|x|y> pattern.  
     */
    squote = 'squote|\u8216|\u8217'

    /* 
     *   list of acceptable punctuation marks within words; this is for
     *   pasting into an <alpha|x|y> pattern 
     */
    wordPunct = static
        '~|@|#|$|%|^|*|(|)|{|}|[|]|vbar|_|=|+|/|\\|langle|rangle|-|&'

    /*
     *   Handle an apostrophe-s word.  We'll return this as two separate
     *   tokens: one for the word preceding the apostrophe-s, and one for
     *   the apostrophe-s itself.
     */
    tokCvtApostropheS(txt, typ, toks)
    {
        local w;
        local s;

        /*
         *   pull out the part up to but not including the apostrophe, and
         *   pull out the apostrophe-s part
         */
        w = txt.left(-2);
        s = txt.right(2);

        /* add the part before the apostrophe as the main token type */
        toks.append([w, typ, w]);

        /* add the apostrophe-s as a separate special token */
        toks.append([s, tokApostropheS, s]);
    }

    /*
     *   Handle a spelled-out hyphenated number from 21 to 99.  We'll
     *   return this as three separate tokens: a word for the tens name, a
     *   word for the hyphen, and a word for the units name.
     */
    tokCvtSpelledNumber(txt, typ, toks)
    {
        /* parse the number into its three parts with a regular expression */
        rexMatch(patAlphaDashAlpha, txt);

        /* add the part before the hyphen */
        toks.append([rexGroup(1)[3], typ, rexGroup(1)[3]]);

        /* add the hyphen */
        toks.append(['-', typ, '-']);

        /* add the part after the hyphen */
        toks.append([rexGroup(2)[3], typ, rexGroup(2)[3]]);
    }
    patAlphaDashAlpha = static new RexPattern('(<alpha>+)-(<alpha>+)')

    /*
     *   Check to see if we want to accept an abbreviated token - this is
     *   a token that ends in a period, which we use for abbreviated words
     *   like "Mr." or "Ave."  We'll accept the token only if it appears
     *   as given - including the period - in the dictionary.  Note that
     *   we ignore truncated matches, since the only way we'll accept a
     *   period in a word token is as the last character; there is thus no
     *   way that a token ending in a period could be a truncation of any
     *   longer valid token.
     */
    acceptAbbrTok(txt)
    {
        /* look up the word, filtering out truncated results */
        return cmdDict.isWordDefined(
            txt, {result: (result & StrCompTrunc) == 0});
    }

    /*
     *   Process an abbreviated token.
     *
     *   When we find an abbreviation, we'll enter it with the abbreviated
     *   word minus the trailing period, plus the period as a separate
     *   token.  We'll mark the period as an "abbreviation period" so that
     *   grammar rules will be able to consider treating it as an
     *   abbreviation -- but since it's also a regular period, grammar
     *   rules that treat periods as regular punctuation will also be able
     *   to try to match the result.  This will ensure that we try it both
     *   ways - as abbreviation and as a word with punctuation - and pick
     *   the one that gives us the best result.
     */
    tokCvtAbbr(txt, typ, toks)
    {
        local w;

        /* add the part before the period as the ordinary token */
        w = txt.left(-1);
        toks.append([w, typ, w]);

        /* add the token for the "abbreviation period" */
        toks.append(['.', tokAbbrPeriod, '.']);
    }

    /*
     *   Given a list of token strings, rebuild the original input string.
     *   We can't recover the exact input string, because the tokenization
     *   process throws away whitespace information, but we can at least
     *   come up with something that will display cleanly and produce the
     *   same results when run through the tokenizer.
     *   
     *   [Required] 
     */
    buildOrigText(toks)
    {
        local str;

        /* start with an empty string */
        str = '';

        /* concatenate each token in the list */
        for (local i = 1, local len = toks.length() ; i <= len ; ++i)
        {
            /* add the current token to the string */
            str += getTokOrig(toks[i]);

            /*
             *   if this looks like a hyphenated number that we picked
             *   apart into two tokens, put it back together without
             *   spaces
             */
            if (i + 2 <= len
                && rexMatch(patSpelledTens, getTokVal(toks[i])) != nil
                && getTokVal(toks[i+1]) == '-'
                && rexMatch(patSpelledUnits, getTokVal(toks[i+2])) != nil)
            {
                /*
                 *   it's a hyphenated number, all right - put the three
                 *   tokens back together without any intervening spaces,
                 *   so ['twenty', '-', 'one'] turns into 'twenty-one'
                 */
                str += getTokOrig(toks[i+1]) + getTokOrig(toks[i+2]);

                /* skip ahead by the two extra tokens we're adding */
                i += 2;
            }
            else if (i + 1 <= len
                     && getTokType(toks[i]) == tokWord
                     && getTokType(toks[i+1]) == tokApostropheS)
            {
                /*
                 *   it's a word followed by an apostrophe-s token - these
                 *   are appended together without any intervening spaces
                 */
                str += getTokOrig(toks[i+1]);

                /* skip the extra token we added */
                ++i;
            }

            /*
             *   if another token follows, and the next token isn't a
             *   punctuation mark, add a space before the next token
             */
            if (i < len && rexMatch(patPunct, getTokVal(toks[i+1])) == nil)
                str += ' ';
        }

        /* return the result string */
        return str;
    }

    /* some pre-compiled regular expressions */
    patSpelledTens = static new RexPattern(
        '<nocase>twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety')
    patSpelledUnits = static new RexPattern(
        '<nocase>one|two|three|four|five|six|seven|eight|nine')
    patPunct = static new RexPattern('[.,;:?!]')
;


