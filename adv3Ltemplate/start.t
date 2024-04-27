#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

versionInfo: GameID
    IFID = '' // obtain IFID from http://www.tads.org/ifidgen/ifidgen
    name = 'My Game'
    byline = 'by A.N. Author'
    htmlByline = 'by <a href="mailto:an.author@somemail.com">
                  A.N. Author</a>'
    version = '1'
    authorEmail = 'A.N. Author <an.author@somemail.com>'
    desc = 'Your blurb here.'
    htmlDesc = 'Your blurb here.'    
    
;

gameMain: GameMainDef
    /* Define the initial player character; this is optional here */
    initialPlayerChar = me
;


/* The starting location; this can be called anything you like */

startroom: Room 'The Starting Location'
    "Add your description here. "
;

/* 
 *   The player character object. This doesn't have to be called me, but me is a
 *   convenient name. For a first or third person game define person = 1 or 
 *   person = 3 on this object.
 */

+ me: Player 'you'  
       
;