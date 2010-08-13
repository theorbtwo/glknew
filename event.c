#include "glknew.h"

/* The spec allows each window to have exactly one text input request
   pending at once -- we can have two windows, each of which has one.
   Worry about that when it happens. */
struct glk_window_struct *input_window = NULL;
int text_input_type_wanted = TEXT_INPUT_NONE;
struct line_event_request_latin1 line_event_request_info_latin1;
struct line_event_request_uni    line_event_request_info_uni;

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

void glk_request_char_event_uni(winid_t win) {
  input_window = win;
  text_input_type_wanted = TEXT_INPUT_CHAR_UNI;
}

void glk_cancel_char_event(winid_t win) {
  input_window = NULL;
  text_input_type_wanted = TEXT_INPUT_NONE;
}

void glk_cancel_line_event(winid_t win, event_t *event) {
  input_window = NULL;
  text_input_type_wanted = TEXT_INPUT_NONE;

  /* We are apparently supposed to fill in the event structure based
     on what the user has already entered.  Ignore this (for now?),
     and simply tell the caller that the user has not yet entered
     anything.
  */

  if (event) {
    event->type = evtype_LineInput;
    event->win = win;
    event->val1 = 0;
    event->val2 = 0;
  }

  if (line_event_request_info_latin1.buf)
    line_event_request_info_latin1.buf[0] = '\0';

  if (line_event_request_info_uni.buf)
    line_event_request_info_uni.buf[0] = '\0';
}

void glk_request_line_event(winid_t win, char *buf, glui32 maxlen, glui32 initlen) {
  char *prefill;

  /* This is the maximum len that select() is prepared to handle. */
  if (maxlen > (1024 - 17)) {
    printf("DEBUG: Game passed maxlen (%d) above what we are prepared for.\n", maxlen);
    maxlen = 1024-17;
  }

  prefill = malloc(initlen+1);
  if (!prefill) {
    printf("glk_request_line_event malloc prefill failed, %d bytes\n", initlen+1);
    exit(12);
  }
  strncpy(prefill, buf, initlen);
  prefill[initlen] = '\0';

  input_window = win;
  text_input_type_wanted = TEXT_INPUT_LINE_LATIN1;

  line_event_request_info_latin1.win = win;
  line_event_request_info_latin1.buf = buf;
  line_event_request_info_latin1.prefill = prefill;
  line_event_request_info_latin1.maxlen = maxlen;
}

void glk_request_line_event_uni(winid_t win, glui32 *buf,
                                glui32 maxlen, glui32 initlen) {
  glui32 *prefill;

  prefill = malloc(4*(initlen+1));
  if (!prefill) {
    printf("glk_request_line_event_uni malloc prefill failed, %d bytes\n", 4*(initlen+1));
    exit(33);
  }
  memcpy(prefill, buf, initlen*4);
  prefill[initlen] = 0;
  
  input_window = win;
  text_input_type_wanted = TEXT_INPUT_LINE_UNI;

  line_event_request_info_uni.win = win;
  line_event_request_info_uni.buf = buf;
  line_event_request_info_uni.prefill = prefill;
  line_event_request_info_uni.maxlen = maxlen;
}


void glk_request_mouse_event(winid_t win) {
  /* Ignore this for now. */
}

void glk_request_timer_events(glui32 miliseconds) {
  /* Ignore this for now.  Thinking about implementation anyway: store
     time of next timer event in a global, if select happens after
     then, throw the timer event and update the time at which the next
     timer even happens.  However, this contrivenes the end of
     http://www.eblong.com/zarf/glk/glk-spec-070_4.html#s.4, which
     says that keyboard events should win over timer events. */
}


#define evtype_charinput_special(name) \
  else if (strcmp(ret, "evtype_CharInput keycode_" #name "\n") == 0) {  \
    event->val1 = keycode_ ## name;                                     \
    return;                                                             \
  }

void glk_select(event_t *event) {
  char line[1024];
  char *ret;

  /* glk_selects input pointer should never be null */
  if(!event) {
    printf(">>> glk_select, dying on NULL event pointer");
    exit(10);
  }
  
  printf("???select, window=%p, want %s\n", input_window, text_input_names[text_input_type_wanted]);
  
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
    evtype_charinput_special(Left    )
    evtype_charinput_special(Right   )
    evtype_charinput_special(Up      )
    evtype_charinput_special(Down    )
    evtype_charinput_special(Return  )
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
    if (!line_event_request_info_latin1.buf) {
      printf("Got [latin1] LineInput while the buffer is unset\n");
      exit(34);
    }
    /* http://www.eblong.com/zarf/glk/glk-spec-070_4.html#s.2 second
       para from the end. */
    strncpy(line_event_request_info_latin1.buf, ret+17, line_event_request_info_latin1.maxlen);
    line_event_request_info_latin1.buf[line_event_request_info_latin1.maxlen] = '\0';
    /* Strip off the last character, which will be the trailing
       newline */
    line_event_request_info_latin1.buf[strlen(line_event_request_info_latin1.buf)-1] = '\0';
    
    event->type = evtype_LineInput;
    event->win = line_event_request_info_latin1.win;
    event->val1 = strlen(line_event_request_info_latin1.buf);
    event->val2 = 0;

    glk_put_string_stream(line_event_request_info_latin1.win->stream, ret+17);

    printf("DEBUG: event got '%s' of len %d\n", line_event_request_info_latin1.buf, event->val1);
  } else if (strncmp(ret, "evtype_LineInputUni ", 20) == 0) {
    glui32 len;
    size_t fread_ret;

    printf("DEBUG: Got LineInputUni, top line '%s'\n", ret);

    if (!sscanf(ret, "evtype_LineInputUni %d", &len)) {
      printf("Got evtype_LineInputUni, but couldn't find (or parse) length: %s\n", ret);
      exit(36);
    }
    printf("DEBUG: Got LineInputUni, len=%d\n", len);

    if (!line_event_request_info_uni.buf) {
      printf("Got [uni] LineInput while the buffer is unset\n");
      exit(35);
    }

    printf("DEBUG: Got LineInputUni, reading content...\n");
    fread_ret = fread(line_event_request_info_uni.buf, 4, len, stdin); 
    if (fread_ret != len) {
      printf("Fread of data in evtype_LineInputUni failed, got %d, errno=%d\n", fread_ret, errno);
      exit(36);
    }
    printf("DEBUG: Got LineInputUni, read content\n");
    line_event_request_info_uni.buf[len] = 0;
    
    /* http://www.eblong.com/zarf/glk/glk-spec-070_4.html#s.2 second
       para from the end. */
    event->type = evtype_LineInput;
    event->win = line_event_request_info_uni.win;
    event->val1 = len;
    event->val2 = 0;

    /*    glk_put_string_stream(line_event_request_info_latin1.win->stream, ret+17); */
    glk_put_buffer_stream_uni(line_event_request_info_uni.win->stream, line_event_request_info_uni.buf, len);
    glk_put_string_stream(line_event_request_info_uni.win->stream, "\n");

  } else {
    printf("Couldn't parse select response: '%s'\n", ret);
    exit(9);
  }
}

void glk_tick(void) {
  /* NOP */
}
