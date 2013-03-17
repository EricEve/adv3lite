#include "advlite.h"


/*
 *   ***************************************************************************
 *   lister.t
 *
 *   This module forms part of the adv3Lite library (c) 2012-13 Eric Eve, and is
 *   substantially borrowed from the Mercury library (c) 2012 Michael J.
 *   Roberts.
 */


/*
 *   Lister is the class that displays lists of objects.  This is used in
 *   room descriptions, inventory lists, and EXAMINE descriptions of
 *   objects (to show the examined object's contents).
 *   
 *   Showing a listing is basically a function call.  The reason we make a
 *   whole class out of it is that we provide a number of options, and a
 *   class is a convenient way to specify options.  The options are simply
 *   defined as properties of a lister object, so to create a certain kind
 *   of list, you just set up a Lister instance with the desired options.
 *   We provide pre-defined Lister objects for the common library listing
 *   types, but games can create their own custom list types by creating
 *   their own Lister objects for different sets of options.  
 */
class Lister: object
    /*
     *   Show a list of objects.  'lst' is the list of objects to show;
     *   'paraCnt' is the number of paragraph-style descriptions that we've
     *   already shown as part of this description.
     *
     *   Note that many specifio listers replaced the 'paraCnt' parameter with a
     *   more useful 'parent' parameter, containing the identity of the object
     *   whose contents are being listed.
     */
    show(lst, paraCnt, paraBrk = true)
    {
        /* get the subset that passes our 'listed' test */
        lst = lst.subset({ o: listed(o) });
        
        /* if we have any items, show them */
        if (lst.length() > 0)
        {
            /* sort into listing order */
            lst = lst.sort(SortAsc, { a, b: listOrder(a) - listOrder(b) });
            
            /* 
             *   The list is plural if it has multiple items, or a single item
             *   that has plural usage.
             */
            local pl = (lst.length() > 1 || lst[1].plural);
            
            /* Show the list prefix */
            showListPrefix(lst, pl, paraCnt);
            
            /* show the items */
            showList(lst, pl, paraCnt);
            
            /* Show the list suffix. */
            showListSuffix(lst, pl, paraCnt);
            
            /* add a paragraph break at the end, if it's requested */
            if(paraBrk)
                "<.p>";
        }
        else
            showListEmpty(paraCnt);
    }
    
    showListPrefix(lst, pl, paraCnt)  { }
    
    showListSuffix(lst, pl, paraCnt)  { }
    
    showListEmpty(paraCnt)  { }
    
    /*
     *   Show the contents of an object.  This displays the paragraph-style
     *   descriptions for any direct contents of the object that have them,
     *   followed by a simple list of the items that don't have paragraph
     *   descriptions.
     */
    listInside(parent, pov, vis, done)
    {
        /* 
         *   Get the list of direct contents of 'c' that are visible and haven't
         *   yet been displayed.  Skip showing the object that contains the
         *   actor, since we'll instead show its inside description on the next
         *   iteration of the main room display loop.
         */
        local lst;
        if (vis != nil)
        {
            /* we have a visible list, so subset it to get our list */
            lst = vis.subset({ o: o.isDirectChild(parent, nil) });
        }
        else
        {
            /* there's no visible list; simply use all contents */
            lst = parent.contents;
        }
        
        /* keep only the objects that aren't marked as done */
        lst = lst.subset({ o: !done[o] });
        
        /* if we have a POV, exclude the POV and its containers */
        if (pov != nil)
            lst = lst.subset({ o: o != pov && !pov.isChild(o, nil) });
        
        /* we haven't showed any paragraph descriptions yet */
        local cnt = 0;
        
        /* show paragraph-style descriptions for objects that have them */
        foreach (local o in lst)
        {
            /* try showing a paragraph description; count it if so */
            if (childPara(o, pov, vis, done))
                ++cnt;
        }
        
        /* 
         *   Now show miscellaneous items that didn't have paragraph
         *   descriptions.  Anything that was listed in a paragraph description
         *   will be marked in the 'done' table.
         */
        lst = lst.subset({ o: !done[o] });
        show(lst, cnt);
        
        /* mark these items as done */
        lst.forEach({ o: done[o] = true });
    }
    
    /*
     *   Show an object's paragraph-style description as part of a LOOK AROUND
     *   room description.
     */
    childPara(obj, pov, vis, done)
    {
        /* if the object hasn't already been described, check lookDesc */
        if (!done[obj] && desc(obj, pov))
        {
            /* we generated a message - add a paragraph break */
            "<p>";
            
            /* mark the object as described */
            done[obj] = true;
            
            /* recursively process this object's contents */
            listInside(obj, pov, vis, done);
            
            /* we showed a paragraph description */
            return true;
        }
        else
        {
            /* we didn't show a paragraph description */
            return nil;
        }
    }
    
    /*
     *   Should 'obj' be listed in this list?  Returns true if so, nil if not.
     *   By default, we list any object whose 'listed' property is true.
     */
    listed(obj) { return obj.listed; }
    
    /*
     *   Get an item's sorting order.  This returns an integer that gives the
     *   relative position in the list; we order the list in ascending order of
     *   this value.  By default, we return the 'listOrder' property of the
     *   object.
     */
    listOrder(obj) { return obj.listOrder; }
    
    /*
     *   For listInside(), show the paragraph-style description of a child
     *   object.
     */
    desc(obj, pov) { return obj.lookDesc(pov); }
    
    /* 
     *   Return a string containing what this lister would display, minus the
     *   terminating paragraph break.
     */
    buildList(lst)
    {
        local str = gOutStream.captureOutput({: show(lst, 0, nil) });
        
        return str;
    }
    
;

/* 
 *   An Item Lister is a lister used for listing physical items. Notice that
 *   most of the specifics of the listers defined below are language-specific,
 *   and so are defined in the language-specific part of the library (e.g. in
 *   english.t).
 */
class ItemLister: Lister
    
    /*
     *   Show a list of objects.  'lst' is the list of objects to show; 'parent'
     *   parameter is the object whose contents are being listed, 'paraBrk'
     *   defines whether or not we want a paragraph break after the list.
     */
    show(lst, parent, paraBrk = true)
    {
        /* Carry out the inherited handling */
        inherited(lst, parent, paraBrk);
        
        /* Note that every item in our list has been mentioned and seen */
        foreach(local cur in lst)
        {
            cur.mentioned = true;
            cur.noteSeen();
        }
        
    }
    
    /* 
     *   The property on a Thing-derived container to test whether its contents
     *   should be listed when listing with this lister
     */
    contentsListedProp = &contentsListed
;


/*
 *   lookLister displays a list of miscellaneous objects in a room description.
 */
lookLister: ItemLister
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed; }
;

/* 
 *   lookContentsLister is used to display a list of the contents of objects in
 *   a room description.
 */
lookContentsLister: ItemLister
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed; }
    
    contentsListedProp = &contentsListedInLook
;

/*
 *   inventoryLister displays an inventory listing.
 */
inventoryLister: ItemLister
    /* is the object listed in an inventory list? */
    listed(obj) { return obj.inventoryListed; }
;

/* wornLister displays a list of items being worn. */
wornLister: ItemLister
     /* is the object listed in an inventory list? */
    listed(obj) { return obj.inventoryListed; }
;

/*
 *   descContentsLister displays a list of miscellaneous contents of an object
 *   being examined.  
 */
descContentsLister: ItemLister
    /* is the object listed in an EXAMINE description of its container? */
    listed(obj) { return obj.examineListed; }

    /* show the paragraph-style description of a child object */
    desc(obj, pov) { return obj.childDesc(pov); }
    
    contentsListedProp = &contentsListedInExamine
;

/* 
 *   openingContentsLister displays the contents of an openable container when
 *   it is first opened.
 */
openingContentsLister: ItemLister
    /* is the object listed in an EXAMINE description of its container? */
    listed(obj) { return obj.examineListed; }

    /* show the paragraph-style description of a child object */
    desc(obj, pov) { return obj.childDesc(pov); }   
;

/* 
 *   lookInLister is used to list the contents of an object in response to LOOK
 *   IN/UNDER/BEHIND
 */
lookInLister: ItemLister
    /* 
     *   is the object listed in a SEARCH/LOOK IN/UNDER/BEHIND description of
     *   its container?
     */
    listed(obj) { return obj.searchListed; }

    /* show the paragraph-style description of a child object */
    desc(obj, pov) { return obj.childDesc(pov); }   

    contentsListedProp = &contentsListedInSearch

;

/* A lister used to list the items attached to a SimpleAttachable */
simpleAttachmentLister: ItemLister
    /* an object is listed if it's attached */
    listed(obj) { return obj.attachedTo != nil; }
    
;

/*  A lister used to list the items plugged into a PlugAttachable */
plugAttachableLister: simpleAttachmentLister
;

/* 
 *   A lister that can be readily customized to tailor the text before and after
 *   a list of miscellaneous items in a room description.
 */
class CustomRoomLister: ItemLister
    
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed; }
    
    /* 
     *   In the simple form of the constructor, we just supply a string that
     *   will form the prefix string for the lister. In the more sophisticated
     *   form we can supply an additsion argument that's an anonymous method or
     *   function that's used to show the list prefix or suffix, or else just
     *   the suffix string.
     */
    construct(prefix, prefixMethod:?, suffix:?, suffixMethod:?)
    {
        prefix_ = prefix;
        
        if(prefixMethod != nil)
            setMethod(&showListPrefix, prefixMethod);
        
        if(suffix != nil)
            suffix_ = suffix;
        
        if(suffixMethod != nil)
            setMethod(&showListSuffix, suffixMethod);
    }
    
    prefix_ = nil
    suffix_ = '. '
    
    showListPrefix(lst, pl, irName)  
    { 
        "<.p><<prefix_>> ";
    }
    
    showListSuffix(lst, pl, irName)  
    { 
        "<<suffix_>>";
    }
    
    showSubListing = (gameMain.useParentheticalListing)
;