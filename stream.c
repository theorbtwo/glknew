#include "glknew.h"

strid_t current_stream = NULL;

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
void glk_put_char_uni(glui32 ch) {
  glk_put_char_stream_uni(current_stream, ch);
}

void glk_put_char(unsigned char ch) {
  glui32 ch_uni = ch;
  glk_put_char_uni(ch_uni);
}

void glk_put_char_stream(strid_t str, unsigned char ch) {
  glui32 ch_uni = ch;
  glk_put_char_stream_uni(current_stream, ch);
}
