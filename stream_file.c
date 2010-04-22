#include "glknew.h"

struct glk_stream_struct_vtable stream_file_vtable = {
};

/* Not part of the glk API proper, but required by the glkunix API. */
/* Opens a given pathname, as a read-only stream. */
strid_t gli_stream_open_pathname(char *pathname, int textmode,
                                 glui32 rock) {
  struct glk_stream_struct *stream;
  int fd;
  
  printf("gli_stream_open_pathname: %s\n", pathname);
  fd = open(pathname, O_RDONLY);
  if (fd == -1) {
    printf("open of file %s failed: errno=%d\n", pathname, errno);
    return NULL;
  }

  stream = malloc(sizeof(struct glk_stream_struct));
  if (!stream) {
    return stream;
  }
  
  stream->rock = rock;
  stream->fmode = filemode_Read;
  stream->type = STREAM_TYPE_FILE;
  stream->vtable = &stream_file_vtable;
  stream->u.file.fd = fd;
  
  stream->dispatch_rock = dispatch_register((void *)stream, gidisp_Class_Stream);
  
  return stream;
}
