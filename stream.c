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
  return ((*str->vtable->put_char_uni)(str, ch));
}

glsi32 glk_get_char_stream_uni(strid_t str) {
  if (str->vtable->get_char_uni) {
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

glui32 glk_get_buffer_stream(strid_t str, char *buf, glui32 len) {
  int i;

  /* FIXME: stop at eof */
  for (i=0; i<len; i++) {
    glui32 c = glk_get_char_stream(str);
    if (c == -1) {
      return i-1;
    }
    buf[i] = c;
  }

  return i;
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.3 */
void glk_stream_close(strid_t str, stream_result_t *result) {
  /* We don't currently track these. */
  if (result) {
    result->readcount = 0;
    result->writecount = 0;
  }

  /* We should probably do some sort of cleanup here, and disown the
     buffer, in the case of a memory stream. */
}
