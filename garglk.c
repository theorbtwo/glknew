/* This file implements API extensions used by the gargoyle family of
   interpreters.
 
   So far as I know these are undocumented.  The header file
   /mnt/shared/projects/games/flash-if/garglk-read-only/garglk/glk.h
   specifies them with very little comment.
*/

#include "glknew.h"

char* garglk_fileref_get_name(frefid_t fref) {
  return fref->name;
}

/* reference implementation: garglk's cgmisc.c, line 51.  Defaults to
   "Unknown", seems to be used for setting the window title. */
void garglk_set_program_name(const char *name) {
  printf("garglk_set_program_name: \"%s\"\n", name);
}

/* reference implementation: garglk's cgmisc.c, line 58.  Defaults to
   "". */
void garglk_set_program_info(const char *name) {
  printf("garglk_set_program_name: \"%s\"\n", name);
}

/* reference implementation: garglk's cgmisc.c, line 58.  Defaults to
   "".  Seems to be used for window title. */
void garglk_set_story_name(const char *name) {
  printf("garglk_set_program_name: \"%s\"\n", name);
}

