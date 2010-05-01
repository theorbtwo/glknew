#ifndef _GLKNEW_WINDOW_H
#define _GLKNEW_WINDOW_H

struct glk_window_struct {
  glui32 wintype;
  struct glk_stream_struct *stream;
  glui32 rock;
  gidispatch_rock_t dispatch_rock;
  struct glk_window_struct *parent;
};

#endif
