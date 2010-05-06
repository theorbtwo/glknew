#include "glknew.h"

frefid_t glk_fileref_create_by_name(glui32 usage, char *name, glui32 rock) {
  struct glk_fileref_struct *fileref;
  char *name_copy;

  fileref = malloc(sizeof(*fileref));
  /* According to the prototype in dispatch.c, name does not become an
     owned pointer, so we should probably copy it. */
  name_copy = malloc(strlen(name) + 1);
  strcpy(name_copy, name);
  fileref->name = name_copy;
  fileref->rock = rock;
  
  if (dispatch_register) {
    fileref->dispatch_rock = dispatch_register(fileref, gidisp_Class_Fileref);
  }

  return fileref;
}

void glk_fileref_destroy(frefid_t fileref) {
  if (dispatch_unregister) {
    dispatch_unregister(fileref, gidisp_Class_Fileref, fileref->dispatch_rock);
  }
  free(fileref->name);
  free(fileref);
}
