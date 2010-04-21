#include "glknew.h"

/* http://www.eblong.com/zarf/glk/glk-spec-070_2.html#s.5 */
unsigned char glk_char_to_lower(unsigned char ch) {
  if ((ch >= 0x41 && ch <= 0x5A) ||
      (ch >= 0xC0 && ch <= 0xD8) ||
      (ch >= 0xD8 && ch <= 0xDE)) {
    return ch + 0x20;
  } else {
    return ch;
  }
}

/* http://www.eblong.com/zarf/glk/glk-spec-070_2.html#s.5 */
unsigned char glk_char_to_upper(unsigned char ch) {
  if ((ch >= 0x61 && ch <= 0x7A) ||
      (ch >= 0xE0 && ch <= 0xF8) ||
      (ch >= 0xF8 && ch <= 0xFE)) {
    return ch - 0x20;
  } else {
    return ch;
  }
}
