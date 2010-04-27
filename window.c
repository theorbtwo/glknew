#include "glknew.h"

struct glk_window_struct *root_window = NULL;

/* http://www.eblong.com/zarf/glk/glk-spec-070_3.html#s.2 */
winid_t glk_window_open(winid_t split, glui32 method, glui32 size,
                        glui32 wintype, glui32 rock) {
  struct glk_window_struct *newwin;
  
  printf(">>>Opening new window, splitting exsiting window %p\n", split);
  printf(">>>win: method=");
  if ((method & winmethod_DirMask) == winmethod_Left) {
    printf("left");
  } else if ((method & winmethod_DirMask) == winmethod_Right) {
    printf("right");
  } else if ((method & winmethod_DirMask) == winmethod_Above) {
    printf("above");
  } else if ((method & winmethod_DirMask) == winmethod_Below) {
    printf("below");
  }

  if ((method & winmethod_DivisionMask) == winmethod_Fixed) {
    printf(", fixed");
  } else if ((method & winmethod_DivisionMask) == winmethod_Proportional) {
    printf(", proportional");
  }

  printf("\n");

  printf(">>>win: size %d\n", size);

  printf(">>>win: wintype=%d ", wintype);
  if (wintype == wintype_Pair) {
    printf("Pair\n");
  } else if (wintype == wintype_Blank) {
    printf("Blank\n");
  } else if (wintype == wintype_TextBuffer) {
    printf("TextBuffer\n");
  } else if (wintype == wintype_TextGrid) {
    printf("TextGrid\n");
  } else if (wintype == wintype_Graphics) {
    printf("Graphics\n");
  }

  if (!root_window) {
    if (split) {
      /* If we are opening the root window, split must be zero, method
         and size are ignored. (Spec.) */
      printf("Nonzero split when opening root window.");
      exit(~0);
    }
    printf(">>>win: is root\n");
    root_window = newwin;
  }

  newwin=malloc(sizeof(*newwin));
  newwin->wintype=wintype;
  newwin->rock=rock;
  if (dispatch_register) {
    newwin->dispatch_rock = dispatch_register(newwin, gidisp_Class_Window);
  } else {
    printf("Making window while dispatch_register unset\n");
  }

  printf(">>>win: at %p\n", newwin);

  newwin->stream = glk_stream_open_window(newwin, filemode_ReadWrite, 0);

  return newwin;
}

void glk_set_window(winid_t win) {
  if (!win) {
    printf("DEBUG: Ignoring attempt to set to null window, as recommended at http://groups.google.com/group/rec.arts.int-fiction/browse_thread/thread/b7671883f03914cc?pli=1\n");
    return;
  }
  
  glk_stream_set_current(glk_window_get_stream(win));
}

strid_t glk_window_get_stream(winid_t win) {
  return win->stream;
}

void glk_window_move_cursor(winid_t win, glui32 xpos, glui32 ypos) {
  printf(">>>window_move_cursor win=%p, xpos=%d, ypos=%d\n", win, xpos, ypos);
}
