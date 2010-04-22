#include "glknew.h"

static void set_position(strid_t str, glsi32 pos, glui32 seekmode) {
  if (seekmode == seekmode_Start) {
    str->u.mem.pos = pos;
  } else if (seekmode == seekmode_Current) {
    str->u.mem.pos += pos;
  } else if (seekmode == seekmode_End) {
    str->u.mem.pos = str->u.mem.buflen - pos;
  }

  if (str->u.mem.pos > str->u.mem.buflen || str->u.mem.pos < 0) {
    printf("Memory stream seeked to illegal position %d, but has length %d\n", str->u.mem.pos, str->u.mem.buflen);
    exit(~0);
  }
}

static glsi32 get_char_uni(strid_t str) {
  /* FIXME: do I need wide and narrow memory streams?
   * git is creating a memory stream of a mmapped .gblorb file, and
   * expecting it to work, which implies that that stream is
   * byte-sized.
   */
  if (str->u.mem.pos > str->u.mem.buflen) {
    return -1;
  }

  return str->u.mem.buf[str->u.mem.pos++];
}

struct glk_stream_struct_vtable stream_memory_vtable = {
  .set_position = set_position,
  .get_char_uni = get_char_uni
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
