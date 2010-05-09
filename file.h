#ifndef GLKNEW_FILE_H
#define GLKNEW_FILE_H

struct glk_fileref_struct {
  glui32 usage;
  char *name;
  glui32 rock;
  gidispatch_rock_t dispatch_rock;
};

/* Keep these synced to the function definitions in file.c */
#define USAGE_NAME_LEN strlen("InputRecord, BinaryMode")+1
extern void usage_to_name(glui32 usage, char *name);

#define FILEMODE_NAME_LEN strlen("WriteAppend")+1
extern void filemode_to_name(glui32 filemode, char *name);


#endif
