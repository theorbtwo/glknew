#include "glknew.h"

struct glk_window_struct *root_window = NULL;

/* http://www.eblong.com/zarf/glk/glk-spec-070_3.html#s.7 */
winid_t glk_window_get_root(void) {
  return root_window;
}

void glk_window_set_echo_stream(winid_t win, strid_t str) {
  win->echo_stream = str;
}

/* str should point to at least WIN_METHOD_NAME_SIZE
 bytes of space. */
#define WIN_METHOD_NAME_SIZE strlen("above, proportional")+1
void win_method_to_name(glui32 method, char *str) {
  str[0] = '\0';

  if ((method & winmethod_DirMask) == winmethod_Left) {
    strncat(str, "left", WIN_METHOD_NAME_SIZE);
  } else if ((method & winmethod_DirMask) == winmethod_Right) {
    strncat(str, "right", WIN_METHOD_NAME_SIZE);
  } else if ((method & winmethod_DirMask) == winmethod_Above) {
    strncat(str, "above", WIN_METHOD_NAME_SIZE);
  } else if ((method & winmethod_DirMask) == winmethod_Below) {
    strncat(str, "below", WIN_METHOD_NAME_SIZE);
  }

  if ((method & winmethod_DivisionMask) == winmethod_Fixed) {
    strncat(str, ", fixed", WIN_METHOD_NAME_SIZE);
  } else if ((method & winmethod_DivisionMask) == winmethod_Proportional) {
    strncat(str, ", proportional", WIN_METHOD_NAME_SIZE);
  }
}


/* http://www.eblong.com/zarf/glk/glk-spec-070_3.html#s.2 */
winid_t glk_window_open(winid_t split, glui32 method, glui32 size,
                        glui32 wintype, glui32 rock) {
  struct glk_window_struct *newwin;
  char win_method_name[WIN_METHOD_NAME_SIZE];
  
  printf(">>>Opening new window, splitting exsiting window %p\n", split);
  win_method_to_name(method, win_method_name);
  printf(">>>win: method=%s\n", win_method_name);

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

  newwin=malloc(sizeof(*newwin));
  newwin->wintype=wintype;
  newwin->rock=rock;
  newwin->echo_stream = NULL;
  newwin->next = NULL;
  
  /* The spec has a system of parents and partners.  When you split a
  window, you create a new window, the parent, split and newwin both
  become children of this new parent. */
  newwin->parent = split;
  if (dispatch_register) {
    newwin->dispatch_rock = dispatch_register(newwin, gidisp_Class_Window);
  } else {
    printf("Making window while dispatch_register unset\n");
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
  } else {
    /* If we are not the root window, then we need to be added to the
       linked list of windows. */
    winid_t lastwin = root_window;
    while (lastwin->next)
      lastwin = lastwin->next;
    lastwin->next = newwin;
  }

  printf(">>>win: at %p\n", newwin);

  newwin->stream = glk_stream_open_window(newwin, filemode_ReadWrite, 0);

  return newwin;
}

void glk_window_set_arrangement(winid_t win, glui32 method,
                                glui32 size, winid_t keywin) {
  char method_name[WIN_METHOD_NAME_SIZE];
  win_method_to_name(method, method_name);

  printf(">>>window_set_arrangement win=%p, method=%s, size=%d, keywin=%p\n",
         win, method_name, size, keywin);
} 

/* http://www.eblong.com/zarf/glk/glk-spec-070_3.html#s.2 */
void glk_window_close(winid_t win, stream_result_t *result) {
  struct glk_window_struct *walker;
  
  printf(">>>glk_window_close win=%p\n", win);

  glk_stream_close(win->stream, result);
  
  /* 
   * Because windows are a singly linked list, we need to start from
   * the beginning / root to find the prev.  (But if the window to
   * kill is the root window, then you don't need to, since there is
   * nothing currently previous to it... and we'd fall off the end if
   * we tried.
   * 
   * Fixme: We seem to be running through things here after they've
   * been closed already, which means that the entire point is being
   * missed somehow.     
   */
  if (win != root_window) {
    walker = root_window;
    while (1) {
      printf("glk_window_close walking: %p\n", walker);
      if (walker->next == win) {
        walker->next = win->next;
        break;
      }
      walker = walker->next;
    }
  }
  
  if (dispatch_unregister) {
    dispatch_unregister(win, gidisp_Class_Window, win->dispatch_rock);
  }

  free(win);
}


void glk_window_get_size(winid_t win, glui32 *widthptr, glui32 *heightptr) {
  char line[1024];
  char *ret;
  glui32 dummy;

  /* If we only care about one of the width / height, get both anyway,
     simplifies things -- passing NULL to sscanf will segfault. */
  widthptr  = widthptr  ? widthptr  : &dummy;
  heightptr = heightptr ? heightptr : &dummy;

  printf("???window_get_size win=%p\n", win);
  
  ret = fgets(line, 1024, stdin);
  
  if (!ret) {
    printf("Failed fgets in glk_window_get_size\n");
    exit(12);
  }

  if (sscanf(ret, "%d %d", widthptr, heightptr) == 2) {
    printf("DEBUG: answered, width=%d, height=%d\n", *widthptr, *heightptr);
    return;
  } else {
    printf("Couldn't scan response to window_get_size: '%s'\n", ret);
    exit(13);
  }
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

glui32 glk_window_get_type(winid_t win) {
  return win->wintype;
}

void glk_window_move_cursor(winid_t win, glui32 xpos, glui32 ypos) {
  printf(">>>window_move_cursor win=%p, xpos=%d, ypos=%d\n", win, xpos, ypos);
}

void glk_window_clear(winid_t win) {
  printf(">>>window_clear win=%p\n", win);
}

winid_t glk_window_get_parent(winid_t win) {
  return win->parent;
}

/* FIXME: The docs suggest this can be done with a macro for this,
 * stream, and fileref. OTOH, note that the type for windows is
 * winid_t, but the function name is glk_win*dow*_iterate. 
 */
winid_t glk_window_iterate(winid_t prevwin, glui32 *rockptr) {
  glui32 dummy;
  
  if (!rockptr) {
    rockptr = &dummy;
  }
  
  if (!root_window) {
    return NULL;
  }

  if (prevwin == NULL) {
    *rockptr = root_window->rock;
    return root_window;
  }

  if (prevwin->next == NULL) {
    /* Ignore rockptr? */
    return NULL;
  }

  *rockptr = prevwin->next->rock;
  return prevwin->next;
}
