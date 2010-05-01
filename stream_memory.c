#include "glknew.h"

static void memory_set_position(strid_t str, glsi32 pos, glui32 seekmode) {
  if (seekmode == seekmode_Start) {
    str->u.mem.pos = pos;
  } else if (seekmode == seekmode_Current) {
    str->u.mem.pos += pos;
  } else if (seekmode == seekmode_End) {
    str->u.mem.pos = str->u.mem.buflen - pos;
  }

  if (str->u.mem.pos > str->u.mem.buflen || str->u.mem.pos < 0) {
    printf("Memory stream seeked to illegal position %u, but has length %d\n", str->u.mem.pos, str->u.mem.buflen);
    exit(~0);
  }
}

static glsi32 memory_get_char_uni(strid_t str) {
  if (str->u.mem.pos > str->u.mem.buflen) {
    return -1;
  }

  if (str->u.mem.width == 1) {
    char *buf = str->u.mem.buf;

    return buf[str->u.mem.pos++];
  } else if (str->u.mem.width == 4) {
    glui32 *buf = str->u.mem.buf;

    return buf[str->u.mem.pos++];
  } else {
    printf("Strange width %d on memory stream", str->u.mem.width);
    exit(4);
  }
}

static void memory_put_char_uni(strid_t str, glui32 ch) {
  if (str->u.mem.pos > str->u.mem.buflen) {
    printf("put_char_uni in memory stream out of range: trying to write character %d in a %d character stream", str->u.mem.pos, str->u.mem.buflen);
    /* exit(5); */
    return;
  }
  if (str->u.mem.pos < 0) {
    printf("put_char_uni in memory stream out of range: %d\n", str->u.mem.pos);
    exit(6);
  }

  if (str->u.mem.width == 1) {
    char *buf = str->u.mem.buf;

    buf[str->u.mem.pos++] = (ch & 0xFF);
  } else if (str->u.mem.width == 4) {
    glui32 *buf = str->u.mem.buf;
    
    buf[str->u.mem.pos++] = ch;
  } else {
    printf("Strange width %d on memory stream", str->u.mem.width);
    exit(4);
  }
}

struct glk_stream_struct_vtable stream_memory_vtable = {
  .set_position = memory_set_position,
  .get_char_uni = memory_get_char_uni,
  .put_char_uni = memory_put_char_uni,
};

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html section 5.6.2 */
strid_t glk_stream_open_memory_uni(glui32 *buf, glui32 buflen, glui32 fmode, glui32 rock) {
  return glk_stream_open_memory_base(buf, buflen, fmode, rock, 4);
}

strid_t glk_stream_open_memory(char *buf, glui32 buflen, glui32 fmode, glui32 rock) {
  return glk_stream_open_memory_base(buf, buflen, fmode, rock, 1);
}

strid_t glk_stream_open_memory_base(void *buf, glui32 buflen, glui32 fmode, glui32 rock, glui32 width) {
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
  stream->u.mem.width = width;
  stream->u.mem.pos = 0;
  
  /* FIXME: 1: There should be a better way.
     FIXME: 2: The spec suggests that we should save this up, and call
     it when we do have a dispatch_register. */
  if (dispatch_register) {
    stream->dispatch_rock = dispatch_register((void *)stream, gidisp_Class_Stream);
  }

  /* We (apparently) need to tell the user of the library that we now
     own the buffer, or it will free it behind our back. */
  /* FIXME: is the len parameter supposed to be the length in bytes,
     or in glui32s? */
  if (dispatch_adopt) {
    if (width == 4) {
      dispatch_adopt(buf, buflen, "&+#!Iu");
    } else if (width == 1) {
      dispatch_adopt(buf, buflen, "&+#!Cn");
    } else {
      printf("Width %d, not 1 or 4", width);
      exit(7);
    }
  }

  return stream;
}
