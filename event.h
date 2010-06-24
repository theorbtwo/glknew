#ifndef GLKNEW_EVENT_H
#define GLKNEW_EVENT_H

/* The sort of text event the program wants to recieve.  These are
   mutually exclusive, so we just need one thingy.  On the other hand,
   at least in theory, this is per-window state.
*/

#define TEXT_INPUT_NONE        0
#define TEXT_INPUT_CHAR_LATIN1 1
#define TEXT_INPUT_CHAR_UNI    2
#define TEXT_INPUT_LINE_LATIN1 3
#define TEXT_INPUT_LINE_UNI    4

struct line_event_request_latin1 {
  winid_t win;
  char *buf;
  char *prefill;
  glui32 maxlen;
};

struct line_event_request_uni {
  winid_t win;
  glui32 *buf;
  glui32 *prefill;
  glui32 maxlen;
};

#endif
