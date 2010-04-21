#include <stdio.h>
#include <stdlib.h>

#include "glk.h"
#include "blorb.h"
#include "dispatch.h"
#include "stream.h"

/* Every time the glk library creates an object, we should call this,
 * passing a gidisp_Class_Foo constant from dispatch.h in the second
 * thing, and the object just created in the first.  Then we should
 * stash away the gidispatch_rock_t in the object.
 */
gidispatch_rock_t (*dispatch_register)(void *obj, glui32 objclass);
/* Called when (just before?) we free an object. */
void (*dispatch_unregister)(void *obj, glui32 objclass, gidispatch_rock_t objrock);

/* These two are for pointers that get passed to us, which we then
 * own, and, contrarywise, when we give up ownership of them.
 */
gidispatch_rock_t (*dispatch_adopt)(void *array, glui32 len, char *typecode);
void (*dispatch_disown)(void *array, glui32 len, char *typecode, gidispatch_rock_t objrock);

