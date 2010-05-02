#include "glknew.h"

/* The spec allows each window to have exactly one text input request
   pending at once -- we can have two windows, each of which has one.
   Worry about that when it happens. */
struct glk_window_struct *input_window = NULL;
int text_input_type_wanted = TEXT_INPUT_NONE;
struct line_event_request line_event_request_info;

/* KEEP THIS UPDATED WITH THE #defines IN THE .h FILE! */
const char* text_input_names[] = {
  "none",
  "char_latin1",
  "char_uni",
  "line_latin1",
  "line_uni"
};

void glk_request_char_event(winid_t win) {
  input_window = win;
  text_input_type_wanted = TEXT_INPUT_CHAR_LATIN1;
}

void glk_request_line_event(winid_t win, char *buf, glui32 maxlen, glui32 initlen) {
  char *prefill;

  /* This is the maximum len that select() is prepared to handle. */
  if (maxlen > (1024 - 11)) {
    printf("DEBUG: Game passed maxlen (%d) above what we are prepared for.\n", maxlen);
  }

  prefill = malloc(initlen+1);
  if (!prefill) {
    printf("glk_request_line_even malloc prefill failed, %d bytes\n", initlen+1);
    exit(12);
  }
  strncpy(prefill, buf, initlen);
  prefill[initlen] = '\0';

  input_window = win;
  text_input_type_wanted = TEXT_INPUT_LINE_LATIN1;

  line_event_request_info.win = win;
  line_event_request_info.buf = buf;
  line_event_request_info.prefill = prefill;
  line_event_request_info.maxlen = maxlen;
  line_event_request_info.want_unicode = 0;
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
  
  printf("???select, want %s\n", text_input_names[text_input_type_wanted]);
  
  /* FIXME: Do something useful when the game wanted a line and
     allowed for it to be > 1024 chars. */
  /* The spec states
  (http://www.eblong.com/zarf/glk/glk-spec-070_2.html#s.3) that you
  cannot input newlines, so we should be safe here. */
  ret = fgets(line, 1024, stdin);

  if (!ret) {
    printf("Failed fgets in glk_select!");
    exit(10);
  }

  /* http://www.eblong.com/zarf/glk/glk-spec-070_2.html#s.4 */
  if (strncmp(ret, "evtype_CharInput ", 17) == 0) {
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
  } else if (strncmp(ret, "evtype_LineInput ", 17) == 0) {
    /* http://www.eblong.com/zarf/glk/glk-spec-070_4.html#s.2 second
       para from the end. */
    strncpy(line_event_request_info.buf, ret+17, line_event_request_info.maxlen);
    line_event_request_info.buf[line_event_request_info.maxlen] = '\0';
    /* Strip off the last character, which will be the trailing
       newline */
    line_event_request_info.buf[strlen(line_event_request_info.buf)-1] = '\0';
    
    if (line_event_request_info.want_unicode) {
      printf("Line event request when unicode wanted.\n");
      exit(13);
    }

    event->type = evtype_LineInput;
    event->win = line_event_request_info.win;
    event->val1 = strlen(line_event_request_info.buf);
    event->val2 = 0;

    printf("DEBUG: event got '%s' of len %d\n", line_event_request_info.buf, event->val1);
  } else {
    printf("Couldn't parse select response: '%s'\n", ret);
    exit(9);
  }
}
