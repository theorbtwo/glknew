#include "glknew.h"

struct glk_stream_struct_vtable stream_window_vtable = {
};

strid_t glk_stream_open_window(struct glk_window_struct *win, glui32 fmode, glui32 rock) {
  struct glk_stream_struct *stream;

  stream = malloc(sizeof(struct glk_stream_struct));
  if (!stream) {
    return stream;
  }

  stream->rock  = rock;
  stream->fmode = fmode;
  stream->type  = STREAM_TYPE_WINDOW;
  stream->vtable = &stream_window_vtable;
  
  /* FIXME: 1: There should be a better way.
     FIXME: 2: The spec suggests that we should save this up, and call
     it when we do have a dispatch_register. */
  if (dispatch_register) {
    stream->dispatch_rock = dispatch_register((void *)stream, gidisp_Class_Stream);
  }

  return stream;
}
