#include "glknew.h"
#include <arpa/inet.h>
#include <stdlib.h>

void glk_window_fill_rect(winid_t win, glui32 color, glsi32 left, glsi32 top, glui32 width, glui32 height) {
  printf(">>>glk_window_fill_rect win=%p, color=0x%x, left=%d, top=%d, width=%d, height=%d\n",
         win, color, left, top, width, height);
}

glui32 glk_image_get_info(glui32 image, glui32 *width, glui32 *height) {
  giblorb_err_t err;
  giblorb_result_t res;

  err = giblorb_load_resource(giblorb_get_resource_map(), giblorb_method_Memory, &res, giblorb_ID_Pict, image);

  if (err) {
    printf("DEBUG: Couldn't get pict id %d from blorb, err = %d\n", image, err);
    return FALSE;
  }

  if (res.chunktype == 0x504e4720) {
    /* FIXME: Is that constant portable?  Would 'PNG ' be more portable? */
    /* Quietly assumes that the PNG is valid. */
    /* 0       string          \x89PNG         PNG image data,
       >4      belong          !0x0d0a1a0a     CORRUPTED,
       >4      belong          0x0d0a1a0a
       >>16    belong          x               %ld x
       >>20    belong          x               %ld,
    */
    *width  = ntohl(*(glui32*)((char*)res.data.ptr+16));
    *height = ntohl(*(glui32*)((char*)res.data.ptr+20));

    printf("DEBUG: found image size of %d x %d\n", *width, *height);

    return TRUE;
  } else {
    printf("Don't know how to handle chunktype=0x%x in image_get_info\n", res.chunktype);
    exit(30);
  }
}

glui32 glk_image_draw_scaled(winid_t win, glui32 image, glsi32 val1, glsi32 val2, glui32 width, glui32 height) {
  /* FIXME: Let the system tell us what dir to use? */
  char filename[] = "/tmp/glknew-image-XXXXXX";
  int fd = mkstemp(filename);
  int ret;
  giblorb_err_t err;
  giblorb_result_t res;

  err = giblorb_load_resource(giblorb_get_resource_map(), giblorb_method_Memory, &res, giblorb_ID_Pict, image);

  if (err) {
    printf("DEBUG: Couldn't get pict id %d from blorb, err = %d\n", image, err);
    return FALSE;
  }

  ret = write(fd, res.data.ptr, res.length);
  if (ret != res.length) {
    printf("Failed to write to temp file (%s) for glk_image_draw_scaled, wrote %d bytes of %d, errno=%d\n",
           filename, ret, res.length, errno);
    exit(31);
  }

  if (win->wintype == wintype_Graphics) {
    printf(">>>image_draw_scaled win=%p, filename=%s, x=%d, y=%d, width=%d, height=%d\n",
           win, filename, val1, val2, width, height);

    return TRUE;
  } else {
    printf("DEBUG: Attempt to image_draw_scaled to something other then a Graphics window\n");
    return FALSE;
  }
}
