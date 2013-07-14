#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

modify Odor
    desc
    {
        if(Q.canSee(gActor, location))
            descWithSource;
        else
            descWithoutSource;
    }
    
    descWithSource = nil
    descWithoutSource = nil
    
    isEmanating = true
    isHidden = !isEmanating
    
    emanate() { }
    
;

modify Noise
    desc
    {
        if(Q.canSee(gActor, location))
            descWithSource;
        else
            descWithoutSource;
    }
    
    descWithSource = nil
    descWithoutSource = nil   
    
    isEmanating = true
    isHidden = !isEmanating
    
    emanate() { }
;

emanationControl: InitObject
    execute()
    {
        new Daemon(self, &emanate, 1);
    }
    
    emanate()
    {
        local lst = buildEmanationList;
        for(local e in lst)
            e.emanate();      
    }
    
    buildEmanationList   
    {
        local pc = gPlayerChar;
        
        local lst = pc.getOutermostRoom.allContents.subset(
            {o: canSense(pc, o)});
        
        if(defined(SenseRegion))
        {
            local remoteLst = [];
            foreach(local rm in valToList(pc.getOutermostRoom.audibleRooms))
                remoteLst += rm.allContents.subset(
                    {o: o.isEmanating && o.ofKind(Noise) && Q.canHear(pc, o)});
            
            foreach(local rm in valToList(pc.getOutermostRoom.smellableRooms))
                remoteLst += rm.allContents.subset(
                    {o: o.isEmanating && o.ofKind(Odor) && Q.canSmell(pc, o)});
            
            lst = lst.appendUnique(remoteLst);    
        }
        
        return lst;    
    }
        
       
    canSense(pc, o)
    {
        return o.isEmanating && ((o.ofKind(Noise) && Q.canHear(pc, o))
                                  || (o.ofKind(Odor) && Q.canSmell(pc, o)));
    }
        
    
;


class SensoryEvent: object
    triggerEvent(obj)
    {
        local notifyList = obj.getOutermostRoom.allContents.subset({
            o: Q.(senseProp)(o, obj) });
        
        notifyList = notifyList.appendUnique(remoteList(obj));
        
        for(local cur in notifyList)
            cur.(notifyProp)(self, obj);
    }
    
    notifyProp = nil
    senseProp = nil
    remoteProp = nil
    
    remoteList(obj)
    {
        local lst = [];
        for(local rm in valToList(obj.getOutermostRoom.(remoteProp)))
            lst = lst.appendUnique(rm.allContents.({
            o: Q.(senseProp)(o, obj) }));
        
        return lst;
    }
;

class SoundEvent: SensoryEvent    
    notifyProp = &notifySoundEvent
    senseProp = &canHear
    remoteProp = &audibleRooms
    
;

class SmellEvent: SensoryEvent    
    notifyProp = &notifySmellEvent
    senseProp = &canSmell
    remoteProp = &smellableRooms
;

class SightEvent: SensoryEvent    
    notifyProp = &notifySightEvent
    senseProp = &canSee
    remoteProp = &visibleRooms
;

modify Thing
    notifySoundEvent(event, source) { notifyEvent(event, source); }
    notifySmellEvent(event, source) { notifyEvent(event, source); }
    notifySightEvent(event, source) { notifyEvent(event, source); }
    notifyEvent(event, source) {  }   
    
  
;