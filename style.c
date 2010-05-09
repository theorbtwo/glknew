#include "glknew.h"

struct stylehint styles[wintype_Graphics][style_NUMSTYLES][stylehint_NUMHINTS];

#define switch_entry(const, var, this) case const ## _ ## this : return #this; break

const char *style_to_name(glui32 styl) {
#define style_entry(this) switch_entry(style, styl_name, this)
    switch(styl) {
      style_entry(Normal);
      style_entry(Emphasized);
      style_entry(Preformatted);
      style_entry(Header);
      style_entry(Subheader);
      style_entry(Alert);
      style_entry(Note);
      style_entry(BlockQuote);
      style_entry(Input);
      style_entry(User1);
      style_entry(User2);
    default: return "WTF"; break;
    }
#undef style_entry
}

const char *wintype_to_name(glui32 wintype) {
#define wintype_entry(this) switch_entry(wintype, wintype_name, this)
    switch (wintype) {
      wintype_entry(AllTypes);
      wintype_entry(Pair);
      wintype_entry(Blank);
      wintype_entry(TextBuffer);
      wintype_entry(TextGrid);
      wintype_entry(Graphics);
    default:
      return "WTF";
      break;
    }
}

const char *hint_to_name(glui32 hint) {
#define hint_entry(this) switch_entry(stylehint, hint_name, this)
    switch(hint) {
      hint_entry(Indentation);
      hint_entry(ParaIndentation);
      hint_entry(Justification);
      hint_entry(Size);
      hint_entry(Weight);
      hint_entry(Oblique);
      hint_entry(Proportional);
      hint_entry(TextColor);
      hint_entry(BackColor);
      hint_entry(ReverseColor);
    default:
      return "WTF";
      break;
    }
}

#undef switch_entry

void glk_stylehint_set(glui32 wintype, glui32 styl, glui32 hint,
                       glsi32 val) {
  styles[wintype][styl][hint].is_set = 1;
  styles[wintype][styl][hint].val = val;

  {
    const char *wintype_name = wintype_to_name(wintype);
    const char *styl_name = style_to_name(styl);
    const char *hint_name = hint_to_name(hint);

    printf(">>stylehint_set for wintype=%d (%s), styl=%d (%s), hint=%d (%s) to val=%d\n",
           wintype, wintype_name, styl, styl_name, hint, hint_name, val
           );
  }
}

extern void glk_stylehint_clear(glui32 wintype, glui32 styl, glui32 hint) {
  const char *wintype_name = wintype_to_name(wintype);
  const char *styl_name = style_to_name(styl);
  const char *hint_name = hint_to_name(hint);
  
  styles[wintype][styl][hint].is_set = 0;

  printf(">>stylehint_clear for wintype=%d (%s), styl=%d (%s), hint=%d (%s)\n",
         wintype, wintype_name, styl, styl_name, hint, hint_name
         );
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_5.html#s.5.2 -- returns
   1 iff the user can see the difference between the two given styles
   in the given window. */
glui32 glk_style_distinguish(winid_t win, glui32 styl1, glui32 styl2) {
  /* 6 is pretty arbitrary.  Really, we just want three chars,
     [01]\n\0. */
  char line[6];
  char *ret;

  printf("??? glk_style_distinguish win=%p, styl1=%d (%s), styl2=%d (%s)\n", 
         win, styl1, style_to_name(styl1), styl2, style_to_name(styl2));
  ret = fgets(line, 6, stdin);
  if (!ret) {
    printf("Failed fgets in glk_style_distinguish!");
    exit(15);
  }

  if (strncmp(ret, "1", 1) == 0) {
    return 1;
  } else {
    return 0;
  }
}

extern glui32 glk_style_measure(winid_t win, glui32 styl, glui32 hint,
                                glui32 *result) {
  printf("???glk_style_measure win=%p, styl=%d (%s), hint=%d (%s)\n",
         win, 
         styl, style_to_name(styl),
         hint, hint_to_name(hint)
         );
  *result = 0;
  return 0;
}


void glk_set_style(glui32 styl) {
  glk_set_style_stream(current_stream, styl);
}

void glk_set_style_stream(strid_t str, glui32 styl) {
  /* FIXME: What happens when the stream isn't a window stream?  Since
     each window type has it's own set of styles, we need to know the
     window type of this stream... but memory and file streams don't
     have a window style! */
  
  if (str->type != STREAM_TYPE_WINDOW) {
    printf("DEBUG: Attempt to call glk_set_style_stream on a non-window stream (stream type=%d, style=%d (%s))\n", str->type, styl, style_to_name(styl));
    
    /* Alabaster does this, on a memory stream.  The spec says "For a
       window stream, the text will appear in that style. For a memory
       stream, style changes have no effect. For a file stream, if the
       machine supports styled text files, the styles may be written to the
       file; more likely the style changes will have no effect. "
       
       It does not seem to account for the problem of which sort of
       style to apply to a non-window stream. */
    
    return;
  }

  printf(">>>glk_set_style_stream Window=%p to style=%d (%s)\n", str->u.win.win, styl, style_to_name(styl));

  str->current_style = styles[str->u.win.win->wintype][styl];
}
