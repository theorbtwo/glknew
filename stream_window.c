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
  struct glk_stream_struct *stream;

  stream = malloc(sizeof(struct glk_stream_struct));
  if (!stream) {
    return stream;
  }

  if (!win) {
    *(int*)NULL = 42;
  }

  stream->vtable = &stream_window_vtable;
  stream->rock  = rock;
  stream->fmode = fmode;
  stream->type  = STREAM_TYPE_WINDOW;
  stream->current_style = styles[win->wintype][style_Normal];
  stream->u.win.win = win;
  stream->readcount = 0;
  stream->writecount = 0;
  stream->next = NULL;
  
  /* FIXME: 1: There should be a better way.
     FIXME: 2: The spec suggests that we should save this up, and call
     it when we do have a dispatch_register. */
  stream->did_dispatch_register = 0;
  if (dispatch_register) {
    stream->dispatch_rock = dispatch_register((void *)stream, gidisp_Class_Stream);
    stream->did_dispatch_register = 1;
  }

  if (!first_stream) {
    first_stream = stream;
  } else {
    strid_t prev_stream = first_stream;
    while (prev_stream->next != NULL)
      prev_stream = prev_stream->next;
    prev_stream->next = stream;
  }
  stream->next = NULL;

  printf("DEBUG: Created stream for window %p at %p\n", win, stream);
  printf("DEBUG: Stream window: %p\n", stream->u.win.win);

  return stream;
}
