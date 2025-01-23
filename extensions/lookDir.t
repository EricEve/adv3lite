#charset "us-ascii"
#include <tads.h>
#include "advlite.h"

/*
 *   *********************************************************************************
 *
 *   This module provides the LookDir extension for the adv3Lite library (c) 2024 Eric Eve
 *
 *   Version 2.0  23-Jan-25
 *
 *   The LookDir extension provides better handling the LookDir action, which handles cdmmands of
 *   the form LOOK <DIR>, e.g., LOOK NORTH.
 *
 *   To use it, define xxxLook properties on each room where you want to provide a view in the xxx
 *   direction, for example:
 *
 *   northLook = "To the north you see a long row of pines marching into the middle distance. "
 *
 *   Where the appropriate xxxLook property hasn't been defined, this extension will attempt to
 *   generate a description of the direction being looked in based on what is defined on the
 *   corresponding direction property of the actor's location.
 */

modify LookDir    
       
    execAction(cmd)
    {   
        /* Get the direction the player typed in their LOOK <DIR> command. */
        direction = cmd.verbProd.dirMatch.dir; 
        
        /* If out handleLookIn() method handles looking in, return to stop here. */
        if(handleLookIn)
            return;        
        
        /* Note our actor's immediate container */
        local actorContainer = gActor.location;
        
        /* Note our actor's outermost visible parent. */
        local outerLoc = gActor.outermostVisibleParent;
        
        /* 
         *   loop outwards from the actor's immediate container to their outermost visible parent to
         *   find the object from which to attempt to look in the specified direction.
         */
        while(actorContainer != outerLoc)
        {
            if(actorContainer.isEnterable && actorContainer.contType == In)
                break;
            
            actorContainer = actorContainer.location;
        }
        
        
        actorContainer.lookDir(direction); 
    }
;

/* Modifications to Thing for the LookDir extension. */
modify Thing
    /* 
     *   If all else has failed, this metthos will attempt to display a suitablle message saying
     *   what the actor can see in the dir direction.  Game code can tweak this to a small extent,
     *   but if there are many instances where you want to describe the view in a particular
     *   direction you might find it easier to use the xxxLook properties, which are consulted
     *   first.
     */
    describeView(dir)    
    {
        /* We can only carry out this action is there's enough light to see by. */
        if(isIlluminated)
        {
            /* 
             *   If autoLookDir is nil, we don't want to attempt to generate an automatic
             *   description of what lies in the direction the player character is looking, so we
             *   just say that we can see nothing unexpected in that direction.
             */
            if(!autoLookDir)
            {
                sayNothingUnexpectedThatWay(); 
                return;
            }
             
            /* 
             *   The propery we need to work with is that correspdoning to the direction we're
             *   looking in.
             */
            local prop = dir.dirProp;
            
            /* Declare a local variable to hold any object that might be defined on prop. */
            local obj;
            
            /* Then handle matters according to what type of entity prop points to. */
            switch(propType(prop))
            {
                /* 
                 *   If prop is a single-quoted string, simply display it, since the player
                 *   character can't travel that way and the string will probably include a
                 *   description of why not that might well serve as a description of what lies that
                 *   way.
                 */
            case TypeSString:
                display(prop);
                break;
                
                /* If prop holds an object, start by noting what the object is. */
            case TypeObject:    
                obj = self.(prop);
                
                /* 
                 *   If obj is a proxy connector, replace it with the connector it's a proxy for.
                 */
                if(obj.ofKind(UnlistedProxyConnector))                
                    obj = obj.proxyForConnector(gActor.getOutermostRoom);
                
                /*  
                 *   If obj is a travel connector that's either hidden or not apparent, say that we
                 *   can't see anything that way (since the player shouldn't be able to see it at
                 *   this point).
                 */
                if(obj.ofKind(TravelConnector) && (!obj.isConnectorApparent || obj.isHidden))
                {
                    sayNothingUnexpectedThatWay(dir);    
                    break; 
                }
                /* 
                 *   Othewise if obj is a TravelConnector that defines a non-nil lookDirDesc,
                 *   display that lookDirDesc and stop there.
                 */
                else if(obj.ofKind(TravelConnector) && obj.propDefined(&lookDirDesc) 
                        && obj.propType(&lookDirDesc) != TypeNil)
                {
                    DMsg(intro look dirdesc, '\^{1} {i} {see} ', dir.departureName);
                    obj.display(&lookDirDesc);
                    ". ";
                    break;                         
                }
                 
                /* 
                 *   If obj is some king of physical travel connector such as a Door, Passage or
                 *   Stairway say that it lies in the direction we're looking in.
                 */
                if(obj.ofKind(Door) || obj.ofKind(Passage) || obj.ofKind(StairwayUp) ||
                   obj.ofKind(StairwayDown))            
                {
                     /* 
                      *   If obj is the door or other connector into an Enterable, the Enterable is
                      *   probably more noteworthy than the connector, so mention the Enterable
                      *   first and then the connector that leads into it.
                      *
                      *   To achieve this we first need to see if there's an Enterable in our room's
                      *   contents that uses obj as its connector.
                      */
                    
                    local ent = getOutermostRoom. allContents.valWhich({x: x.connector == obj 
                        && x.ofKind(Enterable)});
                    
                    /* If we find one, display a suiteable message relating to it. */
                    if(ent)
                        DMsg(enterable with door, '\^{1} {i} {see} {2} enterable via {3}. ', 
                             dir.departureName, ent.aName, obj.aName);
                    
                    /* Otherwise just say we see the obj in that direction. */
                    else                        
                        DMsg(passage that way, '\^{1} {i} {see} {2}. ', dir.departureName, obj.aName);
                    break;
                }
                
                /* 
                 *   If obj is a Room that's familiar or visited, say that if lies in the direction
                 *   we're looking in.
                 */
                if(obj.ofKind(Room) && (obj.familiar || obj.visited))
                {
                    DMsg(room that way, '\^{1} {dummy}{lies} {2}. ', dir.departureName, obj.theName);
                    break;
                }
                
                /* 
                 *   If obj is an AskConector, list the possible connectors it leads to, provided we
                 *   have any physical connectors to list.
                 */
                if(defined(AskConnector) && obj.ofKind(AskConnector))
                {
                    local optList = options.subset({x: x.ofKind(Thing)});
                    if(optList.length > 0)
                    {
                        
                        DMsg(ask connector options, '\^{1} {i} {see} {2}. ', dir.departureName, 
                             makeListStr(obj.options, &theName));
                        break;
                    }
                }
                 
                if(obj.ofKind(TravelConnector))
                {
                    sayCouldGoThatWay(dir);
                    break;
                }
                
                /* 
                 *   If we reach here we've exhausted all attempt to generate an automated
                 *   description, so just say we don't see anything unexpected that wey.
                 */
                sayNothingUnexpectedThatWay(dir); 
                break;
                
                /* 
                 *   is prop is a method or a double-quoted string, simply tell the player that
                 *   there oculd be an exit leading in the direction they're looking, since we can't
                 *   generate anything more detailed.
                 */
            case TypeDString:
            case TypeCode:
                sayCouldGoThatWay();
                break;
                
            default:
                /* 
                 *   If we reach here we've exhausted all attempt to generate an automated
                 *   description, so just say we don't see anything unexpected that wey.
                 */
                sayNothingUnexpectedThatWay(dir); 
            }
        }
        /* Otherwise say it's too dark to see. */
        else
            sayTooDarkToLookDir();       
        
    }
    
    sayCouldGoThatWay(dir)
    {
        DMsg(could go that way, 'It {dummy} look{s/ed} like {i} might be able to go that
            way. ');
    }
    
    /* Display a message saying we see nothing unexpected in the direction we're looking in. */
    sayNothingUnexpectedThatWay(dir)
    {
        DMsg(nothing unexpected that way, '{I} {see} nothing unexpected in that direction. ');
    }
    
    /* 
     *   Display a message saying it's too dark to see that way (for when we're trying to look in a
     *   particular direction in the dark.
     */
    sayTooDarkToLookDir() 
    {
        DMsg(too dark to look that way, 'It{dummy}{\'s} too dark to see anything that way. ' );        
    }
    
    /* 
     *   Flag - do we want the library to attempt to autogenerate a description of what lies in the
     *   direction we're looking in if we haven't provided one ourselves. By default we do, but if
     *   game authors don't like this feature they can switch it off by setting autoLookDir to nil.
     */
    autoLookDir = true
    
    
    /* 
         If no object matches the vocabulary of the direction the player wants to look in, we next
         call this method to handle it. 
         
         If the relevant xxxLook (e.g., northLook, westLook, portLook, upLook) is defined on this
         Thing, we use it to display what can be seen in the dir direction. Otherwise, if we're
         looking down and the 
     */
    lookDir(dir)
    {
        /* We can only carry out this action is there's enough light to see by. */
        if(isIlluminated)
        {
            /* Obtain the zzzLook property corresponding to the direction we want to look in. */
            local prop = dir.lookProp;
            
            /* Note that our starting location is this Thing. */
            local loc = self;
            
            /* 
             *   Note that our outermost location is our outermost visible parent, which will either
             *   be the room we're in or a Booth if we're in a closed opaque booth.
             */
            local outerLoc = gActor.outermostVisibleParent();
            
            /* Keep a note of whether we've succeeded in describing the view. */
            local viewDescribed = nil;
            
            /* 
             *   Work outwards from this object, which should be the actor's immmediate container,
             *   to its outermost visible parent to find an object that defines the appropriate
             *   xxxLook property and then use it to describe the view in that direction (if any is
             *   found). Otherwise, if we're looking down and we have a floor object, describe the
             *   floor object. Otherwise, if all else fails, call describeView() to autogenerate a
             *   description of what lies in the direction we're looking.
             */
            do
            {                      
                /* If our location defines this property and it's not nil, display it. */
                if(loc.propDefined(prop) && loc.propType(prop) != TypeNil)
                {
                    loc.display(prop);
                    viewDescribed = true;
                    break;
                }
                loc = loc.location;
            } while (loc != outerLoc && loc != nil);
            
            /* 
             *   Otherwise if we're looking down try describing our floor object, and if not call
             *   our describeView method to generate a description of the view in the dir direction
             *   based on what's defined on our room's corresponding direction property.
             */
            if(!viewDescribed)   
            {
                if(dir == downDir)
                    downLook();
                else
                    getOutermostRoom.describeView(dir);
            }
        }
        /* If we're in the dark, say there's not enough light to see by. */
        else
            sayTooDarkToLookDir();
            
        
        
    }
    
    /* By default, translate LOOK DOWN into examining our floor object if we have one. */
    downLook()
    {
        /* If we have a floor objecgt, examine it. */
        if(floorObj)
            doInstead(Examine, floorObj);
        /* Otherwise say there's nothing special to see. */
        else
            describeView(downDir);
    }
    
     
;
    

/* 
 *   Add a lookProp property to each Direction object and populate it with a pointer to the
 *   appropriate xxxLook property.
 */
modify northDir lookProp = &northLook;
modify eastDir lookProp = &eastLook;
modify southDir lookProp = &southLook;
modify westDir lookProp = &westLook;
modify northeastDir lookProp = &northeastLook;
modify southeastDir lookProp = &southeastLook;
modify southwestDir lookProp = &southwestLook;
modify northwestDir lookProp = &northwestLook;

modify starboardDir lookProp = &starboardLook;
modify portDir lookProp = &portLook;
modify foreDir lookProp = &foreLook;
modify aftDir lookProp = &aftLook;

modify upDir lookProp = &upLook;
modify downDir lookProp = &downLook;
modify inDir lookProp = &inLook;
modify outDir lookProp = &outLook;
