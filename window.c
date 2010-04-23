#include "glknew.h"

struct glk_window_struct *root_window;

/* http://www.eblong.com/zarf/glk/glk-spec-070_3.html#s.2 */
winid_t glk_window_open(winid_t split, glui32 method, glui32 size,
                        glui32 wintype, glui32 rock) {
  struct glk_window_struct *newwin;
  
  printf(">>>Opening new window, splitting exsiting window %p\n", split);
  printf(">>>method");
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
    printf(", fixed\n");
  } else if ((method & winmethod_DivisionMask) == winmethod_Proportional) {
    printf(", proportional\n");
  }

  printf(">>>size %d\n", size);

  printf(">>>wintype=%d ", wintype);
  if (wintype == wintype_Pair) {
    printf("pair\n");
  } else if (wintype == wintype_Blank) {
    printf("blank\n");
  } else if (wintype == wintype_TextBuffer) {
    printf("textbuffer\n");
  } else if (wintype == wintype_TextGrid) {
    printf("textgrid\n");
  } else if (wintype == wintype_Graphics) {
    printf("graphics\n");
  }

  if (!root_window) {
    if (split) {
      /* If we are opening the root window, split must be zero, method
         and size are ignored. (Spec.) */
      printf("Nonzero split when opening root window.");
      exit(~0);
    }
    printf(">>>is root\n");
    root_window = newwin;
  }

  newwin=malloc(sizeof(*newwin));
  newwin->wintype=wintype;
  newwin->rock=rock;
  if (dispatch_register) {
    newwin->dispatch_rock = dispatch_register(newwin, gidisp_Class_Window);
  }

  printf(">>>at %p\n", newwin);

  return newwin;
}
