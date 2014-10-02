#	$Id: Makefile,v 1.5 2005/09/20 10:56:17 beah Exp $

BINDIR = /usr/local/sbin
MANDIR = /usr/local/man
#CFLAGS+= -DHAS_FGETLN -DHAS_STRLCPY
CFLAGS+= -Wall -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations
CFLAGS+= -Wshadow -Wpointer-arith -Wcast-qual -Wsign-compare

all:		femail

femail:		femail.o openbsd_compat.o
	$(CC) $(LDFLAGS) femail.o openbsd_compat.o $(LDLIBS) -o femail

femail.o:	femail.c
	$(CC) $(CFLAGS) -c femail.c

openbsd_compat.o:	openbsd_compat.c
	$(CC) $(CFLAGS) -c openbsd_compat.c

install:	all
	install -o root -g bin -m 0555 femail $(BINDIR)
	install -o root -g wheel -m 0755 -d $(MANDIR)/man8
	install -o root -g bin -m 0444 femail.8 $(MANDIR)/man8

clean:
	rm -f femail *.o
