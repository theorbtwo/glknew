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

gidispatch_rock_t gidispatch_get_objrock(void *obj, glui32 objclass) {
  switch(objclass) {

  case gidisp_Class_Stream:
    {
      struct glk_stream_struct *stream = obj;
      return stream->dispatch_rock;
    }
    break;

  default:
    printf("gidspatch_get_objrock");
    exit(~0);

  }
}

void gidispatch_set_retained_registry(
                                      gidispatch_rock_t (*regi)(void *array, glui32 len, char *typecode), 
                                      void (*unregi)(void *array, glui32 len, char *typecode, 
                                                     gidispatch_rock_t objrock)) {
  dispatch_adopt = regi;
  dispatch_disown = unregi;
}

