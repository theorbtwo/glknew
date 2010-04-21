#include "glknew.h"

/* This implements the functions that the dispatch library requires
   from the glk library in order for it to work.

   http://www.eblong.com/zarf/glk/glk-spec-070_11.html#s.1.5
*/

void gidispatch_set_object_registry(
    gidispatch_rock_t (*regi)(void *obj, glui32 objclass), 
    void (*unregi)(void *obj, glui32 objclass, gidispatch_rock_t objrock)) {

  dispatch_register = regi;
  dispatch_unregister = unregi;
}

/*
extern gidispatch_rock_t gidispatch_get_objrock(void *obj, glui32 objclass);
extern void gidispatch_set_retained_registry(
    gidispatch_rock_t (*regi)(void *array, glui32 len, char *typecode), 
    void (*unregi)(void *array, glui32 len, char *typecode, 
        gidispatch_rock_t objrock));
*/
