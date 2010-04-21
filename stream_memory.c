#include "glknew.h"

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
  stream->u.mem.buf = buf;
  stream->u.mem.buflen = buflen;

  stream->dispatch_rock = dispatch_register((void *)stream, gidisp_Class_Stream);

  return stream;
}
