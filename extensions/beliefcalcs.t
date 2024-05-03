#charset "us-ascii"
#include "advlite.h"

/* 
 *   BELIEF CALCULATIONS EXTENSION by Eric Eve
 *
 *   Version 1.0 23rd April 2024
 *
 *   The (curernlty experimental) beliefcalcs.t extension implements various calculations involving
 *   the degree of belief enums likely, dubious, unlikely and untrue, together with true.
 *
 *   To do this it defines a set of corresponding wrapper objects bTrue, bLikely, bDubious,
 *   bUnlikely, and bUntrue, which asssign a probability score to each of these possible values.
 *
 *   To perform calculations with the belief values, it's necessary to wrap them in the
 *   corresponding wrapper object (of the BelVal class). This can be done with the BV() macro; e.g.
 *   BV(dubious) evaluates to bDubious, and BV(x) evaiuaates to bLikely if x is likely.
 *
 *   This then allows us to use the following expressions:
 *
 *.     BV(a) | BV(b)   the belief enum for a or b
 *.     BV(a) + BV(b)   the probability (as a number out of 100) of a or b.
 *.     BV(a) & BV(b)   the belief enum for a and b
 *.     BV(a) + BV(b)   the probability (as a number out of 100) of a and b.
 *.     ~BV(a)          the negation/complement of a, e.g. ~BV(likely) = unlikely
 *.     BV(a) >> BV(b)  test whether a.score > b.score
 *.     BV(a) << BV(b)  test whether a.score < b.score
 *.     BV(a) >>> BV(b) test whether a.score >= b.score
 *
 *   One major limiation of this extension is that it does not repreaent how most people reason
 *   about probabilities in practice. A second, related, limitation is that the probabilities
 *   assigned to each enum (except for true and untrue, at 100 and 0 respectively) are somewhat
 *   arbitrary, e.g. should calling something 'likely' assign it a probability of 55% or 95%?
 *
 *   The extension does allow for further gradations if desired. For example one could define
 *   additional enums such as veryLikely and veryUnlikely and then define correspdonding objects of
 *   the BelVal class:
 *
 *.  bVeryLikely: BelVal status = veryLikely score = 90;
 *.  bVeryUnlikely: BelVal status = veryUnlikely score = 10;
 *
 *   Note that this extension does NOT require the facts.t module to be present (although it is
 *   [perfectly compatinle with it.
 */
 

/* 
 *   Object that carries out the preinitialization for the BelVal class. */
beliefManager: PreinitObject   
    
//    /* Function to convert arg from a belief type to an integer or vice versa */
//    convert(arg)
//    {
//        switch(dataType(arg))
//        {
//        case TypeObject:
//            if(arg.ofKind(BelVal))
//                return arg.score;
//            return nil;
//        case TypeEnum:
//        case TypeTrue:
//            return BV(arg).score;
//        case TypeInt:
//            return intToVal(arg);
//        default:
//            return nil;
//        }        
//    }
    
    
    
//    /* Function to compute the result of belielf type 1 AND belief type 2 */
//    and(belief1, belief2)
//    {
//        local b1 = convert(belief1);
//        local b2 = convert(belief2);
//        
//        if(b1==nil || b2 == nil)
//            return nil;
//        
//        return intToVal((b1 * b2) /100);
//    }
//    
//    /* Function to compute the result of belielf type 1 OR belief type 2 */
//    or(belief1, belief2)
//    {
//        local b1 = convert(belief1);
//        local b2 = convert(belief2);
//        
//        if(b1==nil || b2 == nil)
//            return nil;
//        
//        return intToVal(max(b1, b2));
//    }
    
//    /* 
//     *   Function to compare two belief types and return the numerical difference between them. A
//     *   poaitive result means belief 1 is believed that belief 2, a negative result that it is less
//     *   believed, and a result of 0 that the belief1 = belief 2
//     */
//    comp(belief1, belief2)
//    {
//        local b1 = convert(belief1);
//        local b2 = convert(belief2);
//        
//        if(b1==nil || b2 == nil)
//            return nil;
//        
//        return b1 - b2;
//    }
    
    /* Carry out our preinitialization */
    execute()
    {
        /* Set up a new working vector. */
        local vec = new Vector();
        
        /* 
         *   Obtain the list of value's from BelVal's valTab, which contains the initial boundary
         *   values for converting numerical probabilities to belief enums.
         */
        local vals = BelVal.valTab.valsToList();
        
        /* Obtain a list of keys from the same table */
        local keys = BelVal.valTab.keysToList();
        
        /* 
         *   Store the minumum key value. This should be the probability below which we regard
         *   something as untrue.
         */
        local minVal = keys.minVal(); 
        
        /* 
         *   Iterate through all BelVal objects in the game to constuct a vector containing all
         *   their scores.
         */
        for(local val = firstObj(BelVal); val != nil; val = nextObj(val, BelVal))
            vec.append(val);
        
        /* Sort the vector in descending order of score. */
        vec.sort(true, {x, y: x.score - y.score} );
        
        /* Iterate through the vector. */
        for(local i in 1..vec.length - 1)
        {            
            /* 
             *   Store the current item; this should have the higher score of the pair
             *   we're currently interested in.
             */
            local top = vec[i];
            
            /* 
             *   Store  the next item; this should have the lower score of the pair
             *   we're currently interested in.
             */
            local bottom = vec[i+1];
            
            /*   
             *   Calculate the mid-point of their two scores, which we'll use as the boundary
             *   between them.
             */
            local score = (top.score - bottom.score) / 2 + bottom.score;
                       
            /* 
             *   If we don't already have an entry for the top item of the pair and the bottom item
             *   is not the last in our list, store the mid-point score aa a key in our valTab table
             *   with the correspdonding enum as its key (to establish the minimum score for that
             *   value).             
             */
            if(vals.indexOf(top.status) == nil && i < vec.length - 1)
            {
                BelVal.valTab[score] = top.status;
            }
            /* 
             *   Otherwise, if we're at the penultime item, set the mimimum score for the final item
             *   (which should be untrue) to zero after setting the lower boundary for the next item
             *   up (by default unlikely) to what was previously the score for the final item. This
             *   might be a small number, so that we can regard a probability of less than, say 3%,
             *   as being effectively untrue.
             */
             
            else if(i == vec.length - 1)
            {
                BelVal.valTab[minVal] = top.status;
                BelVal.valTab[0] = bottom.status;
            }       
           
        }
        
        /* 
         *   Create a sorted list of the boundary values we've just stored in BekVal's valTab table
         *   and store them in BelVal's boundaries property, for BelVal to use to turn a probability
         *   into a belief enum.
         */
        BelVal.boundaries = BelVal.valTab.keysToList.sort();    
        
        /* 
         *   Iterate over all the BelVal objects in the game to add them into our bvTab table, which
         *   can be used to find the BelObject corresponding to any given belief enum.
         */
        for(local o = firstObj(BelVal); o != nil; o = nextObj(o, BelVal))
            bvTab[o.status] = o;
        
    }
    
    /* Our LookupTable for finding the BelVal object corresponding to any belief values. */     
    bvTab = [
        true -> bTrue
    ]    

;

/* 
 *   The BelVal class associates the belief enums with objects beginning with the letter b, e.g.
 *   bTrue is associated with true and bDubious with dubious.
 */

class BelVal: object
    status = nil    
    
    /* 
     *   Overridden operators to allow 'logical' calulations to be performed on belief enums; to use
     *   these operators we must either use the associated objects (e.g. bTrue for true) or wrap the
     *   enum in the BV macro, e.g. BV(true); the latter method will be needed when dealing with
     *   variables, e.g. BV(val) when val might be any of the enums
     */    
    operator &(x) { return intToVal(self * x); }
    operator |(x) { return intToVal(self + x); }
    
    operator -(x) { return self.score - x.score; }
    operator [] (x) {return bvTab[x]; }
    operator * (x) { return (self.score * x.score) / 100; }
    operator ~ () { return intToVal(100 - self.score); }
    operator + (x) { return 100 - ((100 - score) * (100 - x.score)) /100 ; }
    operator >> (x) { return self.score > x.score; }
    operator << (x) { return self.score < x.score; }
    operator >>> (x) { return self.score >= x.score; }
    
    /* Convert a number (a probability from 0 to 100) into a belief enum. */
    intToVal(num)
    {
        local idx = boundaries.lastValWhich({x: x <= num});    
        return valTab[idx];                                            
    }
    
    /* The Lookup Table that will be populated with the minimum scores for our belief enums. */
    valTab = [
        97 -> true,   
        3 -> untrue
    ]
    
    /* A list of the boundary scores between different belief enums. */
    boundaries = nil
   
    /* The score (probabiity as a number from 1 to 100) associated with this value. */
    score = 0

    
;


/* Define the five standard BelVal objects. */
bTrue: BelVal status = true score = 100;
bLikely: BelVal status = likely score = 75;
bDubious: BelVal status = dubious score = 50;
bUnlikely: BelVal status = unlikely score = 25;
bUntrue :BelVal status = untrue score = 0;

/* 
 *   Modify setRevealed() on libGlobal to accept a BelVal arg (by converting it to the equivalent
 *   enum)
 */
modify libGlobal
    setRevealed(tag, arg?)
    {        
        if(arg && objOfKind(arg, BelVal))
            arg = arg.status;
        
        inherited(tag, arg);
    }
;

/* 
 *   Modify setInformed() on Thing to accept a BelVal arg (by converting it to the equivalent
 *   enum)
 */
modify Thing
    setInformed(tag, val?)
    {
         if(val && objOfKind(val, BelVal))
            val= val.status;
        
        inherited(tag, val);
    }   
;
    