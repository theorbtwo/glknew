CC = gcc
OPTIONS = -std=c99 -Wall -g3 -O0
CFLAGS = $(OPTIONS) $(INCLUDEDIRS)
GLKLIB = libglknew.a

OBJS = dispatch.o dispatch_local.o \
	blorb.o blorb_local.o \
	stream.o stream_memory.o stream_file.o stream_window.o \
	start.o char.o gestalt.o style.o \
	window.o 
HEADERS = glk.h glknew.h glkstart.h blorb.h dispatch.h

all: $(GLKLIB) Make.glknew

$(GLKLIB): $(OBJS) Makefile
	ar r $(GLKLIB) $(OBJS)
	ranlib $(GLKLIB)

Make.glknew: Makefile
	echo LINKLIBS = $(LIBDIRS) $(LIBS) > Make.glknew
	echo GLKLIB = -lglknew             >> Make.glknew

$(OBJS): $(HEADERS)

clean:
	rm -f *.o $(GLKLIB) Make.glknew