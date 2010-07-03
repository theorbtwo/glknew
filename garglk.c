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
  printf(">>>garglk_set_program_name: \"%s\"\n", name);
}

/* reference implementation: garglk's cgmisc.c, line 58.  Defaults to
   "". */
void garglk_set_program_info(const char *name) {
  printf(">>>garglk_set_program_name: \"%s\"\n", name);
}

/* reference implementation: garglk's cgmisc.c, line 58.  Defaults to
   "".  Seems to be used for window title. */
void garglk_set_story_name(const char *name) {
  printf(">>>garglk_set_story_name: \"%s\"\n", name);
}

/* 
 garglk's garglk's cgstream.c, line 1603.  
 just forwards to gli_set_reversevideo on the current stream.
 garglk's cgstream.c, line 924.
 
 Seems to set reverse video for *the window as a whole*, not just the
 current style?
*/
void garglk_set_reversevideo(glui32 reverse) {
  if (current_stream->type != STREAM_TYPE_WINDOW) {
    printf("garglk_set_reversevideo when current stream isn't a window\n");
    exit(24);
  }
  
  printf(">>>garglk_set_reversevideo win=%p, reverse=%d\n", current_stream->u.win.win, reverse);
}


/* 
 * garglk's cgstream.c, line 1598.
 * forwards to gli_set_zcolors on current stream.
 * garglk's cgstream.c, line 882.
 * 
 * Setting fg or bg to zero is a NOP -- zero means "current".
 * Setting fg or bg to one moves back to the normal color for that style.
 */
void garglk_set_zcolors(glui32 fg, glui32 bg) {
  printf("FIXME: garglk_set_zcolors: fg=%d, bg=%d\n", fg, bg);
}
