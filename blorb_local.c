/* This implements the pieces that are blorb-specific, but aren't in
   blorb.c */

#include "glknew.h"
#include "blorb.h"

giblorb_map_t *map;

giblorb_err_t giblorb_set_resource_map(strid_t file) {
  giblorb_err_t err;
  
  err = giblorb_create_map(file, &map);

  return err;
}

giblorb_map_t *giblorb_get_resource_map(void) {
  return map;
}
