#ifndef GLKNEW_STREAM_H
#define GLKNEW_STREAM_H

#include "glknew.h"

/* The glk spec only defines strid_t, but has prototypes of stream_t. */
typedef strid_t stream_t;

/* Types of stream */
#define STREAM_TYPE_MEMORY 1;
#define STREAM_TYPE_FILE   2;
#define STREAM_TYPE_WINDOW 3;

/* We name all our temporary types --
 * first, the private data for each stream type. */
struct glk_stream_struct_u_mem {
  char *buf;
  glui32 buflen;
  glsi32 pos;
};

struct glk_stream_struct_u_file {
  int fd;
};

struct glk_stream_struct_u_window {
  struct glk_window_struct *win;
};

/* The union of all private data for stream types. */
union glk_stream_struct_u {
  struct glk_stream_struct_u_mem mem;
  struct glk_stream_struct_u_file file;
  struct glk_stream_struct_u_window win;
};

/* We make a vtable for simple dispatching downward to stream-type
   defined functions. */
struct glk_stream_struct_vtable {
  void (*set_position)(strid_t str, glsi32 pos, glui32 seekmode);
  glui32 (*get_position)(strid_t str);
  void (*put_char_uni)(strid_t str, glui32 ch);
  glsi32 (*get_char_uni)(strid_t str);
};

/* Finally, an individual stream. */
struct glk_stream_struct {
  glui32 rock;
  gidispatch_rock_t dispatch_rock;
  glui32 fmode;
  glui32 type;

  struct glk_stream_struct_vtable *vtable;

  union glk_stream_struct_u u;
};

extern strid_t glk_stream_open_window(struct glk_window_struct *win, glui32 fmode, glui32 rock);


#endif
