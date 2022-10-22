#charset "us-ascii"
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
     *   Note that many specific listers replaced the 'paraCnt' parameter with a
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
    
    /* 
     *   Flag, so we want to list contents of contents when using this lister;
     *   by default we do.
     */
    listRecursively = true
;


/*
 *   lookLister displays a list of miscellaneous objects in a room description.
 */
lookLister: ItemLister
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed && !obj.isHidden; }
;

/* 
 *   lookContentsLister is used to display a list of the contents of objects in
 *   a room description.
 */
lookContentsLister: ItemLister
    /* is the object listed in a LOOK AROUND description? */
    listed(obj) { return obj.lookListed && !obj.isHidden; }
    
    contentsListedProp = &contentsListedInLook
;

/*
 *   inventoryLister displays an inventory listing in WIDE format.
 */
inventoryLister: ItemLister
    /* is the object listed in an inventory list? */
    listed(obj) { return obj.inventoryListed && !obj.isHidden; }
;

/* wornLister displays a list of items being worn. */
wornLister: ItemLister
     /* is the object listed in an inventory list? */
    listed(obj) { return obj.inventoryListed && !obj.isHidden; }
;

/*
 *   inventoryTallLister for displaying an inventory list in TALL format.
 */
inventoryTallLister: ItemLister
    /* is the object listed in an inventory list? */
    listed(obj) { return obj.inventoryListed && !obj.isHidden; }
    
     showList(lst, parent, paraBrk = true)
    {
        /* list the inventory using the inventory tall format. */
        showContentsTall(lst, parent, paraBrk);
        
        
        /* Ensure the indentation level is reset to zero once we've finished listing */
        indentLevel = 1;   
        
    }
    
    
    /* 
     *   List the player's inventory in tall format, i.e., as a columnar list with each item on a
     *   new line. This method may call itself recursively to list subcontents (such as the visible
     *   contents of any containers in the player character's inventory).
     */
    showContentsTall(lst, parent, paraBrk = true) 
    {
        foreach(local cur in lst)
        {
            /* Carry out the indenting for sublisting contents */
            for(local i in 1..indentLevel)            
                "\t";
            
            /* Display the appropriate name for the listed item */
            say(listName(cur));
            
            /* Move to a new line */
            "\n";
            
            /* Note that every item in our list has been mentioned and seen */
            cur.mentioned = true;
            cur.noteSeen();  
            
            /* 
             *   If we want to list recursively and we haven't yet reached out maximum indentation
             *   (i.e., nesting) level, then build a list of subcontents and then display it.
             */
            if(listRecursively && indentLevel < maxIndentLevel)
            {
                /* 
                 *   Get a list of the current item's listable contents. If we can't see in this is
                 *   an empty list.
                 */
                local subList = (cur.contType == In && !cur.canSeeIn) 
                    ? [] : cur.contents.subset({o: listed(o) });
                
                /*   If we have an open or transparent subcontainer, add its contents. */ 
                if(cur.remapIn && cur.remapIn.canSeeIn)
                    subList += cur.remapIn.contents.subset({o: listed(o) });
                
                /*   If we have a subsurface, add its contents. */ 
                if(cur.remapOn)
                    subList += cur.remapOn.contents.subset({o: listed(o) });
                
                
                /* 
                 *   If this list isn't empty, then display this list of subcontents as a column of
                 *   items indented under their containing item.
                 */
                if(subList.length > 0)
                {
                    /* increment the indentation level. */
                    indentLevel++;
                    
                    /* sort the list of subcontents in ascending order of their listOrder property */
                    subList = subList.sort(true, {x, y: y.listOrder - x.listOrder});
                    
                    /* call this method recursively to list the subcontents. */
                    showContentsTall(subList, cur, paraBrk);
                    
                    /* decrement the indentation level once we've finished listing. */
                    indentLevel-- ;
                    
                }
            }
        }
        
    }    
    
    
    /* 
     *   A version of the listName method that doesn't list an items contents in parenthesis after
     *   its name, which would be inappropriate to the tall inventory format.
     */
    listName(o)
    {
        /* 
         *   When we're doing a tall inventory listing we don't want to list sucontents after the
         *   name of each item, so we store the current value of showSubListing, then set
         *   showSublisting to nil before carrying out the inherited handling, and then finally
         *   restore the original value of ShowSubListing.
         */
        
        local ssl = showSubListing;
        
        showSubListing = nil;
        
        local lnam = inherited(o);
        
        showSubListing = ssl;
        
        return lnam;          
        
    }
    
    /* The current indentation level for listing subcontents recursively */
    indentLevel = 1
    
    /* The maximum level of indentation we want to allow for listed nested subcontents. */
    maxIndentLevel = 5
    
    /* 
     *   The property on a Thing-derived container to test whether its contents
     *   should be listed when listing with this lister
     */
    contentsListedProp = &contentsListed
    
    /* 
     *   Flag, so we want to list contents of contents when using this lister;
     *   by default we do.
     */
    listRecursively = true
    
    showListPrefix(lst, pl, paraCnt)  { DMsg(list tall prefix, '\n{I} {am} carrying:\n '); }
    
    showListSuffix(lst, pl, paraCnt)  { }
    
    showListEmpty(paraCnt)  { DMsg(list tall empty, '\n{I} {am} empty-handed. '); }
    
;





/*
 *   descContentsLister displays a list of miscellaneous contents of an object
 *   being examined.  
 */
descContentsLister: ItemLister
    /* is the object listed in an EXAMINE description of its container? */
    listed(obj) { return obj.examineListed && !obj.isHidden; }

    contentsListedProp = &contentsListedInExamine
;

/* 
 *   openingContentsLister displays the contents of an openable container when
 *   it is first opened.
 */
openingContentsLister: ItemLister
    /* is the object listed in an EXAMINE description of its container? */
    listed(obj) { return obj.examineListed && !obj.isHidden; }
    
    /* 
     *   We don't want recursive listing with the openingContentsLister, since
     *   this can produce odd results.
     */
    listRecursively = nil
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
    listed(obj) { return obj.searchListed && !obj.isHidden; }

    contentsListedProp = &contentsListedInSearch

;

/* A lister used to list the items attached to a SimpleAttachable */
simpleAttachmentLister: ItemLister
    /* an object is listed if it's attached */
    listed(obj) { return obj.attachedTo != nil && !obj.isHidden; }
    
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
    listed(obj) { return obj.lookListed && !obj.isHidden; }
    
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