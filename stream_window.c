#include "glknew.h"

static void put_char_uni(struct glk_stream_struct *str, glui32 ch) {
  printf(">>>put_char_uni for window %p, character U+%x", str->u.win.win, ch);
  if (ch > ' ' && ch < '~') {
    printf(", '%c'\n", ch);
  } else {
    printf("\n");
  }
  
  if (str->u.win.win->echo_stream) {
    glk_put_char_stream_uni(str->u.win.win->echo_stream, ch);
  }
}

struct glk_stream_struct_vtable stream_window_vtable = {
  .put_char_uni = put_char_uni
};

strid_t glk_stream_open_window(struct glk_window_struct *win, glui32 fmode, glui32 rock) {
  struct glk_stream_struct *stream = glk_stream_open_base(rock, fmode, STREAM_TYPE_WINDOW, &stream_window_vtable);

  if (!win) {
    *(int*)NULL = 42;
  }

  stream->current_style = styles[win->wintype][style_Normal];
  stream->u.win.win = win;

  printf("DEBUG: Created stream for window %p at %p\n", win, stream);
  printf("DEBUG: Stream window: %p\n", stream->u.win.win);

  return stream;
}
