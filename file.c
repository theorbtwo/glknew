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

glui32 glk_fileref_does_file_exist(frefid_t fref) {
  int ret;
  struct stat info;

  ret = stat(fref->name, &info);

  if (ret == -1 && errno == ENOENT) {
    return 0;
  } else if (ret == -1) {
    printf("DEBUG: (unexpected) error on stat for glk_fileref_does_file_exist on %s: errno=%d\n",
           fref->name, errno);
    return 0;
  } else {
    return 1;
  }
}

void usage_to_name(glui32 usage, char *name) {
  name[0] = '\0';
  
  if ((usage & fileusage_TypeMask) == fileusage_Data) {
    strcat(name, "Data");
  } else if ((usage & fileusage_TypeMask) == fileusage_SavedGame) {
    strcat(name, "SavedGame");
  } else if ((usage & fileusage_TypeMask) == fileusage_Transcript) {
    strcat(name, "Transcript");
  } else if ((usage & fileusage_TypeMask) == fileusage_InputRecord) {
    strcat(name, "InputRecord");
  }

  if ((usage & fileusage_TextMode) == fileusage_TextMode) {
    strcat(name, "TextMode");
  } else if ((usage & fileusage_TextMode) == fileusage_TextMode) {
    strcat(name, "BinaryMode");
  }
}

void filemode_to_name(glui32 filemode, char *name) {
  name[0] = '\0';

  if (filemode == filemode_Write) {
    strcat(name, "Write");
  } else if (filemode == filemode_Read) {
    strcat (name, "Read");
  } else if (filemode == filemode_ReadWrite) {
    strcat (name, "ReadWrite");
  } else if (filemode == filemode_WriteAppend) {
    strcat (name, "WriteAppend");
  } else {
    strcat (name, "???");
  }
}

frefid_t glk_fileref_create_by_prompt(glui32 usage, glui32 filemode, glui32 rock) {
  char name[1024];
  char *ret;
  char usage_name[USAGE_NAME_LEN];
  char filemode_name[FILEMODE_NAME_LEN];

  usage_to_name(usage, usage_name);
  filemode_to_name(filemode, filemode_name);

  printf("???glk_fileref_create_by_prompt usage=%d (%s), filemode=%d (%s)\n", usage, usage_name, filemode, filemode_name);

  ret = fgets(name, 1024, stdin);
  if (!ret) {
    printf("Failed fgets in glk_fileref_create_by_prompt!\n");
    exit(18);
  }

  /* Remove trailing newline. */
  name[strlen(name)-1] = '\0';
  return glk_fileref_create_by_name(usage, name, rock);
}

void glk_fileref_delete_file(frefid_t fref) {
  if(unlink(fref->name)) {
    printf("Could not unlink file %s: %d", fref->name, errno);
    exit(28);
  }
}

frefid_t glk_fileref_create_temp(glui32 usage, glui32 rock) {
  char *name = tempnam(NULL, "glknew");

  return glk_fileref_create_by_name(usage, name, rock);
}
