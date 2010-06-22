#include "glknew.h"

schanid_t glk_schannel_create(glui32 rock) {
  printf("DEBUG: Attempt to create a sound channel\n");
  return NULL;
}

void glk_schannel_stop(schanid_t chan) {
  /* Stop any running audio on the channel. */
}


glui32 glk_schannel_play_ext(schanid_t chan, glui32 snd, glui32 repeats,
                             glui32 notify) {
  /* Start playing the given resource (snd) on the channel (chan),
  repeating it (repeats) times.  (~0 is forever, 0 is not at all.)
  */
  return 0;
}

void glk_schannel_set_volume(schanid_t chan, glui32 vol) {
  /* Set the volume of the channel.  0x10000 is both full and
     default. */
  return;
}

void glk_sound_load_hint(glui32 snd, glui32 flag) {
  /* Flag is true: Hey, library, I'm going to play this soon, you
     might want to load it.
     Flag is false: Eh, forget about it.  Throw it out.  It's garbage!
  */
}
