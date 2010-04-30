/* Sometimes, I wonder what the point is in not just having #include
   <make_it_fucking_work.h> */
#define _BSD_SOURCE 1 /* needed for setlinebuf() */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>

#include "glk.h"
#include "blorb.h"
#include "dispatch.h"
#include "stream.h"
#include "event.h"
#include "window.h"
#include "style.h"

/* The current stream; there's a bunch of shortcut functions in the
   API that use this explicitly.  Used to be local to stream.c, but
   style.c needs it too. */
extern strid_t current_stream;


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

/* From cheapglk/cheapglk.h, called in start.c */
extern strid_t gli_stream_open_pathname(char *pathname, int textmode,
                                        glui32 rock);

