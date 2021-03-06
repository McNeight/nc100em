# makefile for nc100em

# You need an ANSI C compiler. gcc is probably best.
#
CC=gcc

# set this if compiling xnc100em; it should point to where X is
# installed. If you don't know where it is, try `/usr/X11', that's a
# common culprit. This is where it is on my Linux box, and probably on
# most other XFree86-using systems:
#
XROOT=/usr/X11R6

# There are various compile-time options. Generally you won't want to
# change the `CFLAGS' line below, but they're described below in case
# you do.
#
# -DSCALE=n sets how many times to scale up the window, 1=normal.
#  In xnc100em, this isn't changeable after compiling, and doesn't
#  work on 1-bit displays. In gnc100em, it can be changed at run-time
#  and should work on any display (for this version, SCALE only sets
#  the default initial scale, which can be overridden with `-S').
#
# -DUSE_MMAP_FOR_CARD enables use of mmap() to access `nc100.card',
#  the PCMCIA memory card image. The main effect of this is that
#  the emulator starts/stops rather more quickly, and only
#  bits of the card which are accessed are read/written. It also
#  makes zcntools *much* faster, and means you can use zcntools while
#  an emulator is running (if you're careful) because of ZCN's
#  stateless `disk' I/O, despite what it says in the man page. :-) So
#  you probably shouldn't remove it unless you have problems compiling.
#
# -DMITSHM is for the Xlib version, and tells it to use shared memory
#  if the X server is local (running on the same machine) and supports
#  it. Don't remove it unless you have problems compiling.
#
# As I say, the default settings below should generally be ok.
#
CFLAGS=-DMITSHM -DUSE_MMAP_FOR_CARD -DSCALE=1 -O -Wall \
	-I$(XROOT)/include

# dest for make install
#
PREFIX=/usr/local
BINDIR=$(PREFIX)/bin
MANDIR=$(PREFIX)/man/man1
XBINDIR=$(BINDIR)
# if you want the X versions to be installed in the usual X executables
# directory, uncomment this:
#XBINDIR=$(XROOT)/bin

# you shouldn't need to edit the rest
#-----------------------------------------------------------------

# this looks wrong, but *ops.c are actually #include'd by z80.c
DNC100EM_OBJS=sdlmain.o common.o libdir.o z80.o debug.o fdc.o
GNC100EM_OBJS=gtkmain.o common.o libdir.o z80.o debug.o fdc.o
SNC100EM_OBJS=smain.o common.o libdir.o z80.o debug.o fdc.o
TNC100EM_OBJS=txtmain.o common.o libdir.o z80.o debug.o fdc.o
XNC100EM_OBJS=xmain.o common.o libdir.o z80.o debug.o fdc.o

# All targets build the tty version, as that should work on all
# machines any of the other versions work on. Ditto for zcntools.

all: x vga tty zcntools

# svga allowed in case they can't read the README :^)
svga: vga
vga: snc100em tty zcntools

x: gtk xlib tty zcntools

xlib: xnc100em tty zcntools

gtk: gnc100em tty zcntools

sdl: dnc100em tty zcntools

# text allowed as that was the old name for this target
text: tty
tty: tnc100em zcntools


snc100em: $(SNC100EM_OBJS)
	$(CC) -o snc100em $(SNC100EM_OBJS) -lvgagl -lvga

tnc100em: $(TNC100EM_OBJS)
	$(CC) -o tnc100em $(TNC100EM_OBJS)

xnc100em: $(XNC100EM_OBJS)
	$(CC) -o xnc100em $(XNC100EM_OBJS) -L$(XROOT)/lib -lXext -lX11

gnc100em: $(GNC100EM_OBJS)
	$(CC) -o gnc100em $(GNC100EM_OBJS) `gtk-config --libs`

dnc100em: $(DNC100EM_OBJS)
#	$(CC) -o dnc100em $(DNC100EM_OBJS)  `sdl-config --libs`
#	$(CC) -framework SDL -framework AppKit -framework Cocoa -o dnc100em $(DNC100EM_OBJS)
#  Compile a distrubution version (using Framework SDL on OS X) like this:
	g++ -c -o SDMain.o  SDLMain.m
	gcc -framework SDL -framework AppKit -framework Cocoa -o dnc100em sdlmain.o common.o libdir.o z80.o debug.o fdc.o SDMain.o

# special stuff needed for gtkmain.o
gtkmain.o: gtkmain.c nc100.xpm
	$(CC) $(CFLAGS) `gtk-config --cflags` -c gtkmain.c -o gtkmain.o

zcntools: zcntools.o libdir.o
	$(CC) -o zcntools zcntools.o libdir.o

pdrom.h: pdrom.bin mkpdromhdr
	./mkpdromhdr <pdrom.bin >pdrom.h

# this is omitted from the `all' target as most people won't have
# zmac, and `pdrom.bin' will be effectively portable anyway... :-)
pdrom.bin: pdrom.z
	zmac pdrom.z

installdirs:
	/bin/sh ./mkinstalldirs $(BINDIR) $(XBINDIR) $(MANDIR)

install: installdirs
	if [ -f gnc100em ]; then \
	install -m 755 -s gnc100em $(XBINDIR); fi
	if [ -f snc100em ]; then \
	install -o root -m 4755 -s snc100em $(BINDIR); fi
	if [ -f tnc100em ]; then \
	install -m 755 -s tnc100em $(BINDIR); fi
	if [ -f xnc100em ]; then \
	install -m 755 -s xnc100em $(XBINDIR); fi
	install -m 755 -s zcntools $(BINDIR)
	install -m 755 makememcard.sh $(BINDIR)/makememcard
	install -m 644 nc100em.1 makememcard.1 zcntools.1 $(MANDIR)
	ln -sf $(MANDIR)/nc100em.1 $(MANDIR)/gnc100em.1
	ln -sf $(MANDIR)/nc100em.1 $(MANDIR)/snc100em.1
	ln -sf $(MANDIR)/nc100em.1 $(MANDIR)/tnc100em.1
	ln -sf $(MANDIR)/nc100em.1 $(MANDIR)/xnc100em.1
	for i in cat df format get info ls put ren rm zero; do \
	  ln -sf $(BINDIR)/zcntools $(BINDIR)/zcn$$i; \
	  ln -sf $(MANDIR)/zcntools.1 $(MANDIR)/zcn$$i.1; \
	done

# we also blast any `nc100em' executable, in case they had a previous version.
uninstall:
	$(RM) $(BINDIR)/{,s,t}nc100em $(XBINDIR)/[gx]nc100em
	$(RM) $(BINDIR)/makememcard
	$(RM) $(BINDIR)/zcntools
	$(RM) $(MANDIR)/{,g,s,t,x}nc100em.1* $(MANDIR)/zcntools.1*
	for i in cat df format get info ls put ren rm zero; do \
	  $(RM) $(BINDIR)/zcn$$i $(MANDIR)/zcn$$i.1*; \
	done

clean:
	$(RM) *.o *~ *.lst [dgstx]nc100em zcntools
	$(RM) mkpdromhdr pdrom.h


common.o: common.c pdrom.h z80.h libdir.h
txtmain.o: smain.c
	$(CC) $(CFLAGS) -DTEXT_VER -c smain.c -o txtmain.o


VERS=1.2

tgz: ../nc100em-$(VERS).tar.gz
  
../nc100em-$(VERS).tar.gz: clean
	$(RM) ../nc100em-$(VERS)
	@cd ..;ln -s nc100em nc100em-$(VERS)
	cd ..;tar zchvf nc100em-$(VERS).tar.gz nc100em-$(VERS)
	@cd ..;$(RM) nc100em-$(VERS)
