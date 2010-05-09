#include "glknew.h"

static glui32 get_position(strid_t str) {
  return lseek(str->u.file.fd, 0, SEEK_CUR);
}

static void set_position(strid_t str, glsi32 pos, glui32 seekmode) {
  int fd = str->u.file.fd;
  int whence;

  if (seekmode == seekmode_Start) {
    whence = SEEK_SET;
  } else if (seekmode == seekmode_Current) {
    whence = SEEK_CUR;
  } else if (seekmode == seekmode_End) {
    whence = SEEK_END;
  } else {
    printf("Can't happen: seekmode %d out of range\n", seekmode);
    exit(~0);
  }

  if (lseek(fd, pos, whence) == -1) {
    printf("Seek of fd %d to pos %d, whence=%d failed with errno=%d", fd, pos, whence, errno);
    exit(~0);
  }
}

static glsi32 get_char_uni(strid_t str) {
  unsigned char ch;
  ssize_t ret;
  
  ret = read(str->u.file.fd, &ch, 1);
  

  if (ret == 0) {
    printf("DEBUG: get_char_uni(file) read returned %d, errno=%d, ch=0x%x\n",
           ret, errno, ch);
    return -1;
  } else {
    return ch & 0xFF;
  }
}

static void file_put_char_uni(strid_t str, glui32 ch) {
  ssize_t ret;
  unsigned char real_ch;

  if (ch > 255) {
    printf("Over-wide character (U+%x) in put_char_uni for file stream\n", ch);
    exit(26);
  }
  real_ch = (unsigned char)ch;

  ret = write(str->u.file.fd, &real_ch, 1);
  if (ret != 1) {
    printf("Error writing to file, errno=%d\n", errno);
    exit(27);
  }
}

struct glk_stream_struct_vtable stream_file_vtable = {
  .set_position = &set_position,
  .get_position = &get_position,
  .get_char_uni = &get_char_uni,
  .put_char_uni = &file_put_char_uni,
};

/* This is probably woefully incomplete WRT unicode & textmode. */
strid_t glk_stream_open_file(frefid_t fileref, glui32 fmode,
                             glui32 rock) {
  struct glk_stream_struct *stream;
  int fd;
  int open_flags = 0;
  char filemode_name[FILEMODE_NAME_LEN];
  

  filemode_to_name(fmode, filemode_name);
  printf("DEBUG: glk_stream_open_file, fileref->name=%s fmode=%d (%s)\n", fileref->name, fmode, filemode_name);

  if (fmode == filemode_Write) {
    open_flags |= O_CREAT | O_WRONLY;
  } else {
    printf("FIXME: fmode to open_flags");
    exit(25);
  }
  
  /* rw for ugo.  If the user doesn't like this, by all means, they
     should set umask. */
  fd = open(fileref->name, open_flags, 0666);
  if (fd == -1) {
    printf("DEBUG: open of file %s failed: errno=%d\n", fileref->name, errno);
    return NULL;
  }

  stream = malloc(sizeof(struct glk_stream_struct));
  if (!stream) {
    return stream;
  }
  
  stream->rock = rock;
  stream->fmode = fmode;
  stream->type = STREAM_TYPE_FILE;
  stream->vtable = &stream_file_vtable;
  stream->u.file.fd = fd;
  stream->readcount = 0;
  stream->writecount = 0;
  
  if (dispatch_register) {
    stream->dispatch_rock = dispatch_register((void *)stream, gidisp_Class_Stream);
  }
  
  return stream;
}


/* Not part of the glk API proper, but required by the glkunix API. */
/* Opens a given pathname, as a read-only stream. */
strid_t gli_stream_open_pathname(char *pathname, int textmode,
                                 glui32 rock) {
  printf("FIXME: Reimplement gli_stream_open_pathname in terms of glk_stream_open_file\n");
  exit(24);
}

