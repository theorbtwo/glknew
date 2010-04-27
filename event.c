#include "glknew.h"

/* The sort of text event the program wants to recieve.  These are
   mutually exclusive, so we just need one thingy.  On the other hand,
   at least in theory, this is per-window state.
*/

#define TEXT_INPUT_NONE        0
#define TEXT_INPUT_CHAR_LATIN1 1
#define TEXT_INPUT_CHAR_UNI    2
#define TEXT_INPUT_LINE_LATIN1 3
#define TEXT_INPUT_LINE_UNI    4

const char* text_input_names[] = {
  "none",
  "char_latin1",
  "char_uni",
  "line_latin1",
  "line_uni"
};


struct glk_window_struct *input_window = NULL;

glui32 text_input_type_wanted = TEXT_INPUT_NONE;

void glk_request_char_event(winid_t win) {
  input_window = win;
  text_input_type_wanted = TEXT_INPUT_CHAR_LATIN1;
}


#define evtype_charinput_special(name) \
  else if (sscanf(ret, "evtype_CharInput keycode_" #name)) { \
    event->val1 = keycode_ ## name;                          \
    return;                                                  \
  }

void glk_select(event_t *event) {
  char line[1024];
  char *ret;

  /* glk_selects input pointer should never be null */
  if(!event) {
    printf(">>> glk_select, dying on NULL event pointer");
    exit(10);
  }
  
  printf(">>> select, want %s\n", text_input_names[text_input_type_wanted]);
  
  ret = fgets(line, 1024, stdin);

  if (!ret) {
    printf("Failed fgets in glk_select!");
    exit(10);
  }

  /* http://www.eblong.com/zarf/glk/glk-spec-070_2.html#s.4 */
  if (strncmp(ret, "evtype_CharInput ", 11) == 0) {
    event->type = evtype_CharInput;
    /* val2 is unused for char inputs. */
    event->val2 = 0xDEADBEEF;
    /* We need to set a window, else glk_select loops.. */
    event->win = input_window;

    if (sscanf(ret, "evtype_CharInput %d", &event->val1)) {
      printf("DEBUG: Got evtype_CharInput: %d\n", event->val1);
      return;
    }
    evtype_charinput_special(Left)
    evtype_charinput_special(Right)
    evtype_charinput_special(Up)
    evtype_charinput_special(Down)
    evtype_charinput_special(Return)
    evtype_charinput_special(Delete  )
    evtype_charinput_special(Escape  )
    evtype_charinput_special(Tab     )
    evtype_charinput_special(PageUp  )
    evtype_charinput_special(PageDown)
    evtype_charinput_special(Home    )
    evtype_charinput_special(End     )
    evtype_charinput_special(Func1   )
    evtype_charinput_special(Func2   )
    evtype_charinput_special(Func3   )
    evtype_charinput_special(Func4   )
    evtype_charinput_special(Func5   )
    evtype_charinput_special(Func6   )
    evtype_charinput_special(Func7   )
    evtype_charinput_special(Func8   )
    evtype_charinput_special(Func9   )
    evtype_charinput_special(Func10  )
    evtype_charinput_special(Func11  )
    evtype_charinput_special(Func12  ) 
    else {
      printf("Couldn't process evtype_CharInput select response: '%s'\n", ret);
      exit(8);
    }
  } else {
    printf("Couldn't parse select response: '%s'\n", ret);
    exit(9);
  }
}
