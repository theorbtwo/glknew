#include "glknew.h"

struct glk_stream_struct_vtable stream_memory_vtable = {
  /* &glk_stream_memory_set_position, */
  /* &glk_stream_memory_get_position  */
};

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html section 5.6.2 */
strid_t glk_stream_open_memory(char *buf, glui32 buflen, glui32 fmode, glui32 rock) {
  struct glk_stream_struct *stream;

  stream = malloc(sizeof(struct glk_stream_struct));
  if (!stream) {
    return stream;
  }

  stream->rock  = rock;
  stream->fmode = fmode;
  stream->type  = STREAM_TYPE_MEMORY;
  stream->vtable = &stream_memory_vtable;
  stream->u.mem.buf = buf;
  stream->u.mem.buflen = buflen;
  
  /* FIXME: 1: There should be a better way.
     FIXME: 2: The spec suggests that we should save this up, and call
     it when we do have a dispatch_register. */
  if (dispatch_register) {
    stream->dispatch_rock = dispatch_register((void *)stream, gidisp_Class_Stream);
  }

  return stream;
}
