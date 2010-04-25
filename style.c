#include "glknew.h"

struct stylehint styles[wintype_Graphics][style_NUMSTYLES][stylehint_NUMHINTS];

const char *style_name(glui32 styl) {
#define switch_entry(const, var, this) case const ## _ ## this : return #this; break
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
#undef switch_entry
#undef style_entry
}

void glk_stylehint_set(glui32 wintype, glui32 styl, glui32 hint,
                       glsi32 val) {
  styles[wintype][styl][hint].is_set = 1;
  styles[wintype][styl][hint].val = val;

  {
    const char *wintype_name;
    const char *styl_name;
    const char *hint_name;

    /* must be used with trailing ; */
#define switch_entry(const, var, this) case const ## _ ## this : var = #this; break

#define wintype_entry(this) switch_entry(wintype, wintype_name, this)
    switch (wintype) {
      wintype_entry(Pair);
      wintype_entry(Blank);
      wintype_entry(TextBuffer);
      wintype_entry(TextGrid);
      wintype_entry(Graphics);
    default:
      wintype_name = "WTF";
      break;
    }
    
    styl_name = style_name(styl);
    
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
      hint_name="WTF";
      break;
    }

    printf(">>stylehint_set for wintype=%d (%s), styl=%d (%s), hint=%d (%s) to val=%d\n",
           wintype, wintype_name, styl, styl_name, hint, hint_name, val
           );
  }
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
    printf("Attempt to call glk_set_style_stream on a non-window stream (type=%d)\n", str->type);
    exit(3);
  }

  printf(">>>glk_set_style_stream Window=%p to style=%d (%s)\n", str->u.win.win, styl, style_name(styl));

  str->current_style = styles[str->u.win.win->wintype][styl];
}
