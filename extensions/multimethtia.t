#charset "us-ascii"

#include <tads.h>
#include "advlite.h"

/*
 *   Multimethtia.t
 *
 *   Version 1.0
 *
 *   This extension simply calls the mmTia() macro on all the TIActions defined in the library to
 *   enable them for multi-method handling.
 */

MMTIAction(DigWith);
MMTIAction(CleanWith);
MMTIAction(MoveTo);
MMTIAction(MoveAwayFrom);
MMTIAction(MoveWith);
MMTIAction(PutOn);
MMTIAction(PutIn);
MMTIAction(PutUnder);
MMTIAction(PutBehind);
MMTIAction(UnlockWith);
MMTIAction(LockWith);
MMTIAction(AttachTo);
MMTIAction(DetachFrom);
MMTIAction(FastenTo);
MMTIAction(TurnWith);

