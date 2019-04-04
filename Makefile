CC=cc -Wno-implicit-int
CFLAGS=-g
LDFLAGS=-g
AR=/usr/bin/ar
RANLIB=/usr/bin/ranlib
INSTALL_PROGRAM=/usr/bin/install -s -m 755
INSTALL_DIR=/Users/greg/Projects-Shared/GHMarkdownParser/discount/config.md
INSTALL_DATA=/usr/bin/install -m 444

BUILD=$(CC) -I. $(CFLAGS)
LINK=$(CC) -L. $(LDFLAGS)

.c.o:
	$(BUILD) -c -o $@ $<
	

BINDIR=/usr/local/bin
MANDIR=/usr/local/man
LIBDIR=/usr/local/lib
INCDIR=/usr/local/include
PKGDIR=$(LIBDIR)/pkgconfig

PGMS=markdown
SAMPLE_PGMS=mkd2html makepage
SAMPLE_PGMS+= theme
MKDLIB=libmarkdown
OBJS=mkdio.o markdown.o dumptree.o generate.o \
     resource.o docheader.o version.o toc.o css.o \
     xml.o Csio.o xmlpage.o basename.o emmatch.o \
     github_flavoured.o setup.o tags.o html5.o \
       flags.o
TESTFRAMEWORK=echo cols branch pandoc_headers

# modules that markdown, makepage, mkd2html, &tc use
COMMON=pgm_options.o gethopt.o notspecial.o

MAN3PAGES=mkd-callbacks.3 mkd-functions.3 markdown.3 mkd-line.3

all: $(PGMS) $(SAMPLE_PGMS) $(TESTFRAMEWORK)

install: $(PGMS) $(DESTDIR)$(BINDIR) $(DESTDIR)$(LIBDIR) $(DESTDIR)$(INCDIR) $(DESTDIR)$(PKGDIR)
	$(INSTALL_PROGRAM) $(PGMS) $(DESTDIR)$(BINDIR)
	./librarian.sh install libmarkdown VERSION $(DESTDIR)$(LIBDIR)
	$(INSTALL_DATA) mkdio.h $(DESTDIR)$(INCDIR)
	$(INSTALL_DATA) $(MKDLIB).pc $(DESTDIR)$(PKGDIR)

install.everything: install install.samples install.man

install.samples: $(SAMPLE_PGMS) install $(DESTDIR)$(BINDIR)
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man1
	for x in $(SAMPLE_PGMS); do \
	    $(INSTALL_PROGRAM) $$x $(DESTDIR)$(BINDIR)/$(SAMPLE_PFX)$$x; \
	    $(INSTALL_DATA) $$x.1 $(DESTDIR)$(MANDIR)/man1/$(SAMPLE_PFX)$$x.1; \
	done

install.man:
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man3
	$(INSTALL_DATA) $(MAN3PAGES) $(DESTDIR)$(MANDIR)/man3
	for x in mkd_line mkd_generateline; do \
	    ( echo '.\"' ; echo ".so man3/mkd-line.3" ) > $(DESTDIR)$(MANDIR)/man3/$$x.3;\
	done
	for x in mkd_in mkd_string; do \
	    ( echo '.\"' ; echo ".so man3/markdown.3" ) > $(DESTDIR)$(MANDIR)/man3/$$x.3;\
	done
	for x in mkd_compile mkd_css mkd_generatecss mkd_generatehtml mkd_cleanup mkd_doc_title mkd_doc_author mkd_doc_date; do \
	    ( echo '.\"' ; echo ".so man3/mkd-functions.3" ) > $(DESTDIR)$(MANDIR)/man3/$$x.3; \
	done
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man7
	$(INSTALL_DATA) markdown.7 mkd-extensions.7 $(DESTDIR)$(MANDIR)/man7
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man1
	$(INSTALL_DATA) markdown.1 $(DESTDIR)$(MANDIR)/man1

install.everything: install install.man

$(DESTDIR)$(BINDIR):
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)

$(DESTDIR)$(INCDIR):
	$(INSTALL_DIR) $(DESTDIR)$(INCDIR)

$(DESTDIR)$(LIBDIR):
	$(INSTALL_DIR) $(DESTDIR)$(LIBDIR)

$(DESTDIR)$(PKGDIR):
	$(INSTALL_DIR) $(DESTDIR)$(PKGDIR)

version.o: version.c VERSION branch
	$(BUILD) -DBRANCH=`./branch` -DVERSION=\"`cat VERSION`\" -c version.c

VERSION:
	@true

tags.o: tags.c cstring.h tags.h blocktags

blocktags: mktags
	./mktags > blocktags

mktags: mktags.o
	$(LINK) -o mktags mktags.o

# example programs
theme:  theme.o $(COMMON) $(MKDLIB) mkdio.h
	$(LINK) -o theme theme.o $(COMMON) -lmarkdown 


mkd2html:  mkd2html.o $(MKDLIB) mkdio.h gethopt.h $(COMMON)
	$(LINK) -o mkd2html mkd2html.o $(COMMON) -lmarkdown 

markdown: main.o $(COMMON) $(MKDLIB)
	$(LINK) -o markdown main.o $(COMMON) -lmarkdown 
	
makepage.o: makepage.c mkdio.h
	$(BUILD) -c makepage.c
makepage:  makepage.o $(COMMON) $(MKDLIB)
	$(LINK) -o makepage makepage.o $(COMMON) -lmarkdown 

pgm_options.o: pgm_options.c mkdio.h config.h
	$(BUILD) -c pgm_options.c

notspecial.o: notspecial.c
	$(BUILD) -c notspecial.c

gethopt.o: gethopt.c
	$(BUILD) -c gethopt.c

main.o: main.c mkdio.h config.h
	$(BUILD) -c main.c

$(MKDLIB): $(OBJS)
	./librarian.sh make $(MKDLIB) VERSION $(OBJS)

verify: echo tools/checkbits.sh
	@./echo -n "headers ... "; tools/checkbits.sh && echo "GOOD"

test:	$(PGMS) $(TESTFRAMEWORK) verify
	@for x in $${TESTS:-tests/*.t}; do \
	    HERE=`pwd` sh $$x || exit 1; \
	done

pandoc_headers.o: tools/pandoc_headers.c config.h
	$(BUILD) -c -o pandoc_headers.o tools/pandoc_headers.c
pandoc_headers: pandoc_headers.o
	$(LINK) -o pandoc_headers pandoc_headers.o $(COMMON) -lmarkdown 

branch.o: tools/branch.c config.h
	$(BUILD) -c -o branch.o tools/branch.c
branch: branch.o
	$(LINK) -o branch branch.o

cols.o:	tools/cols.c config.h
	$(BUILD) -c -o cols.o tools/cols.c
cols:   cols.o
	$(LINK) -o cols cols.o
	
echo.o:	tools/echo.c config.h
	$(BUILD) -c -o echo.o tools/echo.c
echo:   echo.o
	$(LINK) -o echo echo.o
	
clean:
	rm -f $(PGMS) $(TESTFRAMEWORK) $(SAMPLE_PGMS) *.o
	rm -f $(MKDLIB) `./librarian.sh files $(MKDLIB) VERSION`

distclean spotless: clean
	rm -fr *.dSYM Makefile version.c mkdio.h libmarkdown.pc config.cmd config.sub config.h config.mak config.sed config.md librarian.sh config.log ./mktags ./blocktags

Csio.o: Csio.c cstring.h amalloc.h config.h markdown.h
amalloc.o: amalloc.c
basename.o: basename.c config.h cstring.h amalloc.h markdown.h
css.o: css.c config.h cstring.h amalloc.h markdown.h
docheader.o: docheader.c config.h cstring.h amalloc.h markdown.h
dumptree.o: dumptree.c markdown.h cstring.h amalloc.h config.h
emmatch.o: emmatch.c config.h cstring.h amalloc.h markdown.h
generate.o: generate.c config.h cstring.h amalloc.h markdown.h
main.o: main.c config.h amalloc.h
pgm_options.o: pgm_options.c pgm_options.h config.h amalloc.h
makepage.o: makepage.c
markdown.o: markdown.c config.h cstring.h amalloc.h markdown.h
mkd2html.o: mkd2html.c config.h mkdio.h cstring.h amalloc.h
mkdio.o: mkdio.c config.h cstring.h amalloc.h markdown.h
resource.o: resource.c config.h cstring.h amalloc.h markdown.h
theme.o: theme.c config.h mkdio.h cstring.h amalloc.h
toc.o: toc.c config.h cstring.h amalloc.h markdown.h
version.o: version.c config.h
xml.o: xml.c config.h cstring.h amalloc.h markdown.h
xmlpage.o: xmlpage.c config.h cstring.h amalloc.h markdown.h
setup.o: setup.c config.h cstring.h amalloc.h markdown.h
github_flavoured.o: github_flavoured.c config.h cstring.h amalloc.h markdown.h
gethopt.o: gethopt.c gethopt.h
h1title.o: h1title.c markdown.h
notspecial.o: notspecial.c config.h
