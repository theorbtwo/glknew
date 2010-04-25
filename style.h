#ifndef GLKNEW_STYLE_H
#define GLKNEW_STYLE_H

struct stylehint {
  glsi32 val;
  glsi32 is_set;
};

typedef struct stylehint style[stylehint_NUMHINTS];

/* Each window type has it's own set of styles. */
extern style styles[wintype_Graphics][style_NUMSTYLES];

#endif
