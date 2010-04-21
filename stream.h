#ifndef GLKNEW_STREAM_H
#define GLKNEW_STREAM_H

#include "glknew.h"

glui32 stream_type_memory = 1;

struct glk_stream_struct_u_mem {
  char *buf;
  glui32 buflen;
};

union glk_stream_struct_u {
  struct glk_stream_struct_u_mem mem;
};

struct glk_stream_struct {
  glui32 rock;
  glui32 fmode;
  glui32 type;

  union glk_stream_struct_u u;
};

#endif
