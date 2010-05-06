#ifndef GLKNEW_FILE_H
#define GLKNEW_FILE_H

struct glk_fileref_struct {
  glui32 usage;
  char *name;
  glui32 rock;
  gidispatch_rock_t dispatch_rock;
};

#endif
