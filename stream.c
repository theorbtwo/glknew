#include "glknew.h"


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

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html section 5.2.
 * The prototype in the spec disagrees with the prototype in the
 * provided .h file.  The .h version makes sense, so we use it here.
 */
glui32 glk_get_buffer_stream(strid_t str, char *buf, glui32 len) {
  printf("glk_get_buffer_stream\n");
  exit(~0);
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html section 5.4 */
void glk_stream_set_position(strid_t str, glsi32 pos, glui32 seekmode) {
  (*str->vtable->set_position)(str, pos, seekmode);
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.4 */
glui32 glk_stream_get_position(strid_t str) {
  return ((*str->vtable->get_position)(str));
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
