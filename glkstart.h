/* 
 * Not offically part of the glk spec.
 * See
 * http://www.os4depot.net/index.php?function=showfile&file=development/library/misc/libcheapglk.lha
 * for a description of this interface.
 *
 * Also, cheapglk's glkstart.h
 */
#include "glk.h"

/* glkunix_arguments will be defined by the application; glk is
   expected to parse these command-line arguments
*/

#define glkunix_arg_End (0)
#define glkunix_arg_ValueFollows (1)
#define glkunix_arg_NoValue (2)
#define glkunix_arg_ValueCanFollow (3)
#define glkunix_arg_NumberValue (4)

typedef struct glkunix_argumentlist_struct {
  char *name;
  int argtype;
  char *desc;
} glkunix_argumentlist_t;

extern glkunix_argumentlist_t glkunix_arguments[];

/* This library contains main, which will init the library, and then
   call glkunix_startup_code, then glk_main. */

typedef struct glkunix_startup_struct {
    int argc;
    char **argv;
} glkunix_startup_t;

extern int glkunix_startup_code(glkunix_startup_t *data);

