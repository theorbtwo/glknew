#include "glknew.h"

/* A bunch of functions that simply dispatch depending on the stream
   type they refer to (or, rather, depending on the vtable of the
   stream).
*/

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.4 */
void glk_stream_set_position(strid_t str, glsi32 pos, glui32 seekmode) {
  if (str->vtable->set_position) {
    (*str->vtable->set_position)(str, pos, seekmode);
  } else {
    printf("Attempt to set_position, but vtable entry not defined for type=%d", str->type);
    exit(~0);
  }
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.4 */
glui32 glk_stream_get_position(strid_t str) {
  return ((*str->vtable->get_position)(str));
}


void glk_put_char_stream_uni(strid_t str, glui32 ch) {
  str->writecount++;
  return ((*str->vtable->put_char_uni)(str, ch));
}

glsi32 glk_get_char_stream_uni(strid_t str) {
  if (str->vtable->get_char_uni) {
    str->readcount++;
    return ((*str->vtable->get_char_uni)(str));
  } else {
    printf("Attempt to get_char_uni, but vtable entry not defined for type=%d", str->type);
    exit(~0);
  }
}

/* There's a concept of the "current stream" in glk.  I don't like it,
   it's an unneccessary global.  The ills of implementing somebody
   else's API. */
/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html */
strid_t current_stream = NULL;

void glk_stream_set_current(strid_t str) {
  current_stream = str;
}

strid_t glk_stream_get_current(void) {
  return current_stream;
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.1 */
/* There are lots of versions of putting data to a stream:
 * glk_put_(char|string|buffer)(|_stream)(|_uni).
 * We define:
 * !stream -> stream
 * !uni -> uni
 * (buffer|string) -> char
 * ...in order of preference.  Maybe.
 */
void glk_put_char_stream(strid_t str, unsigned char ch) {
  glui32 ch_uni = ch;
  glk_put_char_stream_uni(current_stream, ch_uni);
}

void glk_put_string_stream(strid_t str, char *s) {
  for (; *s; s++) {
    glk_put_char_stream(str, (unsigned char)*s);
  }
}

void glk_put_buffer_stream(strid_t str, char *buf, glui32 len) {
  for (int i = 0; i < len; i++) {
    glk_put_char_stream(str, buf[i]);
  }
}

void glk_put_char_uni(glui32 ch) {
  glk_put_char_stream_uni(current_stream, ch);
}

void glk_put_char(unsigned char ch) {
  glk_put_char_stream(current_stream, ch);
}

void glk_put_string(char *s) {
  glk_put_string_stream(current_stream, s);
}

void glk_put_buffer(char *buf, glui32 len) {
  for (int i=0; i<len; i++) {
    glk_put_char(buf[i]);
  }
}


/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.2 */
/* There are several ways to read from a stream:
 * glk_get_(char|buffer|line)_stream(|_uni).
 */
glsi32 glk_get_char_stream(strid_t str) {
  glsi32 uni_char = glk_get_char_stream_uni(str);

  /* EOF */
  if (uni_char == -1) 
    return -1;

  if (uni_char > 0xFF) {
    return '?';
  }

  return uni_char;
}

glui32 glk_get_line_stream(strid_t str, char *buf, glui32 len) {
  glui32 offset;
  
  /* FIXME: Halt on error reading properly. */
  for (offset = 0; offset < len; offset++) {
    buf[offset] = glk_get_char_stream(str);
    if (buf[offset] == '\n') {
      break;
    }
  }
  buf[offset+1] = '\0';

  return offset;
}


glui32 glk_get_buffer_stream(strid_t str, char *buf, glui32 len) {
  glui32 i;

  for (i=0; i<len; i++) {
    glsi32 c = glk_get_char_stream(str);
    if (c == -1) {
      printf("glk_get_buffer_stream terminating from -1, %d of %d\n", i, len);
      return i-1;
    }
    if (c > 0xFF) {
      printf("'?' while narrowing in glk_get_buffer_stream!\n");
      exit(21);
      buf[i] = '?';
    } else {
      buf[i] = (char)c;
      /* printf("glk_get_buffer_stream [%d]: 0x%x\n", i, buf[i]); */
    }
  }

  printf("DEBUG: glk_get_buffer_stream terminating from running out the clock, %d of %d\n", i, len);
  return i;
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.3 */
void glk_stream_close(strid_t str, stream_result_t *result) {
  printf("DEBUG: glk_stream_close stream=%p\n", str);

  /* We don't currently track these. */
  if (result) {
    result->readcount = str->readcount;
    result->writecount = str->writecount;
  }

  /* FIXME: This probably belongs in stream_memory.c */
  if (str->type == STREAM_TYPE_MEMORY && dispatch_disown) {
    printf("DEBUG: (close_stream) width %d, buflen=%d\n", str->u.mem.width, str->u.mem.buflen);
    if (str->u.mem.width == 4) {
      dispatch_disown(str->u.mem.buf, str->u.mem.buflen, "&+#!Iu", str->u.mem.buffer_adoption_rock);
    } else if (str->u.mem.width == 1) {
      dispatch_disown(str->u.mem.buf, str->u.mem.buflen, "&+#!Cn", str->u.mem.buffer_adoption_rock);
    } else {
      printf("(close_stream) Width %d, not 1 or 4", str->u.mem.width);
      exit(22);
    }
  }

  /* We should probably do some sort of cleanup here, and disown the
     buffer, in the case of a memory stream. */
  if (dispatch_unregister) {
    dispatch_unregister((void *)str, gidisp_Class_Stream, str->dispatch_rock);
  }

  /*  free(str); */
}
