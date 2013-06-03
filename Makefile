# mcdb

ifneq (,$(wildcard /bin/uname))
OSNAME:=$(shell /bin/uname -s)
else
OSNAME:=$(shell /usr/bin/uname -s)
endif

.PHONY: all
all: mcdbctl nss_mcdbctl t/testmcdbmake t/testmcdbrand t/testzero \
     libmcdb.so libmcdb.a libnss_mcdb.a libnss_mcdb_make.a libnss_mcdb.so.2

PREFIX?=/usr/local
ifneq (,$(PREFIX))
PREFIX_USR?=$(PREFIX)
else
PREFIX_USR?=/usr
endif

ifneq (,$(RPM_ARCH))
ifeq (x86_64,$(RPM_ARCH))
  ABI_BITS=64
  LIB_BITS=64
endif
else
ifneq (,$(wildcard /lib64))
  ABI_BITS=64
  LIB_BITS=64
endif
endif

# 'gmake ABI_BITS=64' for 64-bit build (recommended on all 64-bit platforms)
ifeq (64,$(ABI_BITS))
ifeq ($(OSNAME),Linux)
ABI_FLAGS?=-m64
endif
ifeq ($(OSNAME),Darwin)
ABI_FLAGS?=-m64
endif
ifeq ($(OSNAME),AIX)
AR+=-X64
ABI_FLAGS?=-maix64
endif
ifeq ($(OSNAME),HP-UX)
ABI_FLAGS?=-mlp64
endif
ifeq ($(OSNAME),SunOS)
ABI_FLAGS?=-m64
endif
endif

# cygwin needs -std=gnu99 or -D_GNU_SOURCE for mkstemp() and strerror_r()
# cygwin gcc does not support -fpic or -pthread
ifneq (,$(filter CYGWIN%,$(OSNAME)))
FPIC=
STDC99=-std=gnu99
PTHREAD_FLAGS=-D_THREAD_SAFE
endif

ifneq (,$(RPM_OPT_FLAGS))
  CFLAGS+=$(RPM_OPT_FLAGS)
  LDFLAGS+=$(RPM_OPT_FLAGS)
else
  CC=gcc -pipe
  ANSI?=-ansi
  WARNING_FLAGS?=-Wall -Winline -pedantic $(ANSI)
  CFLAGS+=$(WARNING_FLAGS) -O3 -g $(ABI_FLAGS)
  LDFLAGS+=$(ABI_FLAGS)
  ifneq (,$(filter %clang,$(CC)))
    ANSI=
  endif
endif
 
# To disable uint32 and nointr C99 inline functions:
#   -DNO_C99INLINE
# Another option to smaller binary is -Os instead of -O3, and remove -Winline

ifeq ($(OSNAME),Linux)
  ifneq (,$(strip $(filter-out /usr,$(PREFIX))))
    RPATH= -Wl,-rpath,$(PREFIX)/lib$(LIB_BITS)
  endif
  ifeq (,$(RPM_OPT_FLAGS))
    CFLAGS+=-D_FORTIFY_SOURCE=2 -fstack-protector
  endif
  # earlier versions of GNU ld might not support -Wl,--hash-style,gnu
  # (safe to remove -Wl,--hash-style,gnu for RedHat Enterprise 4)
  LDFLAGS+=-Wl,-O,1 -Wl,--hash-style,gnu -Wl,-z,relro,-z,now
  mcdbctl nss_mcdbctl t/testmcdbmake t/testmcdbrand t/testzero: \
    LDFLAGS+=-Wl,-z,noexecstack
endif
ifeq ($(OSNAME),Darwin)
  ifneq (,$(strip $(filter-out /usr,$(PREFIX))))
    RPATH= -Wl,-rpath,$(PREFIX)/lib$(LIB_BITS)
  endif
  ifeq (,$(RPM_OPT_FLAGS))
    CFLAGS+=-D_FORTIFY_SOURCE=2 -fstack-protector
  endif
endif
ifeq ($(OSNAME),AIX)
  ifneq (,$(strip $(filter-out /usr,$(PREFIX))))
    RPATH= -Wl,-b,libpath:$(PREFIX)/lib$(LIB_BITS)
  endif
  # -lpthreads (AIX) for pthread_mutex_{lock,unlock}() in mcdb.o and nss_mcdb.o
  libmcdb.so lib32/libmcdb.so libnss_mcdb.so.2 lib32/libnss_mcdb.so.2 \
  mcdbctl nss_mcdbctl t/testmcdbrand: \
    LDFLAGS+=-lpthreads
endif
ifeq ($(OSNAME),HP-UX)
  ifneq (,$(strip $(filter-out /usr,$(PREFIX))))
    RPATH= -Wl,+b,$(PREFIX)/lib$(LIB_BITS)
  endif
endif
ifeq ($(OSNAME),SunOS)
  ifneq (,$(strip $(filter-out /usr,$(PREFIX))))
    RPATH= -Wl,-R,$(PREFIX)/lib$(LIB_BITS)
  endif
  CFLAGS+=-D_POSIX_PTHREAD_SEMANTICS
  # -lsocket -lnsl for inet_pton() in nss_mcdb_netdb.o and nss_mcdb_netdb_make.o
  libnss_mcdb.so.2 lib32/libnss_mcdb.so.2 nss_mcdbctl: \
    LDFLAGS+=-lsocket -lnsl
  # -lrt for fdatasync() in mcdb_make.o, for sched_yield() in mcdb.o
  libmcdb.so lib32/libmcdb.so mcdbctl nss_mcdbctl t/testmcdbrand: \
    LDFLAGS+=-lrt
endif

# heavy handed dependencies
_DEPENDENCIES_ON_ALL_HEADERS_Makefile:= $(wildcard *.h) $(wildcard plasma/*.h) Makefile

# C99
STDC99?=-std=c99
CFLAGS+=$(STDC99)
# position independent code (for shared libraries)
FPIC?=-fpic
# link shared library
SHLIB?=-shared

# Thread-safety (e.g. for thread-specific errno)
# (vendor compilers might need additional compiler flags, e.g. Sun Studio -mt)
PTHREAD_FLAGS?=-pthread -D_THREAD_SAFE
CFLAGS+=$(PTHREAD_FLAGS)

# To use vendor compiler, set CC and the following macros, as appropriate:
#   Oracle Sun Studio
#     CC=cc
#     STDC99=-xc99=all
#     PTHREAD_FLAGS=-mt -D_THREAD_SAFE
#     FPIC=-xcode=pic13
#     SHLIB=-G
#     WARNING_FLAGS=-v
#   IBM Visual Age XL C/C++
#     CC=xlc
#     # use -qsuppress to silence msg: keyword '__attribute__' is non-portable
#     STDC99=-qlanglvl=stdc99 -qsuppress=1506-1108
#     PTHREAD_FLAGS=-qthreaded -D__VACPP_MULTI__ -D_THREAD_SAFE
#     FPIC=-qpic=small
#     SHLIB=-qmkshrobj
#     WARNING_FLAGS=
#     #(64-bit)
#     ABI_FLAGS=-q64
#     #(additionally, xlc needs -qtls to recognized __thread keyword)
#     nss_mcdb.o: CFLAGS+=-qtls=local-dynamic
#   HP aCC
#     CC=cc
#     STDC99=-AC99
#     PTHREAD_FLAGS=-mt -D_THREAD_SAFE
#     FPIC=+z
#     SHLIB=-b
#     #(noisy; quiet informational messages about adding padding to structs)
#     WARNING_FLAGS=+w +W4227,4255
#     #(64-bit)
#     ABI_FLAGS=+DD64
#     #(additionally, aCC does not appear to support C99 inline)
#     CFLAGS+=-DNO_C99INLINE

%.o: %.c $(_DEPENDENCIES_ON_ALL_HEADERS_Makefile)
	$(CC) -o $@ $(CFLAGS) -c $<

nss_mcdb.o:       CFLAGS+=-DNSS_MCDB_PATH='"$(PREFIX)/etc/mcdb/"'
lib32/nss_mcdb.o: CFLAGS+=-DNSS_MCDB_PATH='"$(PREFIX)/etc/mcdb/"'

PIC_OBJS:= mcdb.o mcdb_make.o mcdb_makefmt.o mcdb_makefn.o nointr.o uint32.o \
           nss_mcdb.o nss_mcdb_acct.o nss_mcdb_authn.o nss_mcdb_netdb.o \
           plasma/plasma_atomic.o plasma/plasma_spin.o
$(PIC_OBJS): CFLAGS+=$(FPIC)

# (nointr.o, uint32.o need not be included when fully inlined; adds 10K to .so)
ifeq ($(OSNAME),Linux)
libnss_mcdb.so.2: LDFLAGS+=-Wl,-soname,$(@F) -Wl,--version-script,nss_mcdb.map
endif
libnss_mcdb.so.2: mcdb.o uint32.o \
                  nss_mcdb.o nss_mcdb_acct.o nss_mcdb_authn.o nss_mcdb_netdb.o \
                  plasma/plasma_atomic.o plasma/plasma_spin.o
	$(CC) -o $@ $(SHLIB) $(FPIC) $(LDFLAGS) $^

ifeq ($(OSNAME),Linux)
libmcdb.so: LDFLAGS+=-Wl,-soname,$(@F)
endif
libmcdb.so: mcdb.o mcdb_make.o mcdb_makefmt.o mcdb_makefn.o nointr.o uint32.o \
            plasma/plasma_atomic.o plasma/plasma_spin.o
	$(CC) -o $@ $(SHLIB) $(FPIC) $(LDFLAGS) $^

libmcdb.a: mcdb.o mcdb_error.o mcdb_make.o mcdb_makefmt.o mcdb_makefn.o \
           nointr.o uint32.o plasma/plasma_atomic.o plasma/plasma_spin.o
	$(AR) -r $@ $^

libnss_mcdb.a: nss_mcdb.o nss_mcdb_acct.o nss_mcdb_authn.o nss_mcdb_netdb.o
	$(AR) -r $@ $^

libnss_mcdb_make.a: nss_mcdb_make.o nss_mcdb_acct_make.o nss_mcdb_authn_make.o \
                    nss_mcdb_netdb_make.o
	$(AR) -r $@ $^

mcdbctl: mcdbctl.o libmcdb.a
	$(CC) -o $@ $(LDFLAGS) $^

t/%.o: CFLAGS+=-I $(CURDIR)

t/testmcdbmake: t/testmcdbmake.o libmcdb.a
	$(CC) -o $@ $(LDFLAGS) $^

t/testmcdbrand: t/testmcdbrand.o libmcdb.a
	$(CC) -o $@ $(LDFLAGS) $^

t/testzero: t/testzero.o libmcdb.a
	$(CC) -o $@ $(LDFLAGS) $^

nss_mcdbctl: nss_mcdbctl.o libnss_mcdb_make.a libmcdb.a
	$(CC) -o $@ $(LDFLAGS) $^

$(PREFIX)/lib $(PREFIX)/bin $(PREFIX)/sbin:
	/bin/mkdir -p -m 0755 $@
ifneq (,$(LIB_BITS))
$(PREFIX)/lib$(LIB_BITS):
	/bin/mkdir -p -m 0755 $@
endif
ifneq ($(PREFIX_USR),$(PREFIX))
$(PREFIX_USR)/lib $(PREFIX_USR)/bin:
	/bin/mkdir -p -m 0755 $@
ifneq (,$(LIB_BITS))
$(PREFIX_USR)/lib$(LIB_BITS):
	/bin/mkdir -p -m 0755 $@
endif
$(PREFIX_USR)/lib$(LIB_BITS)/libnss_mcdb.so.2: \
  $(PREFIX)/lib$(LIB_BITS)/libnss_mcdb.so.2 $(PREFIX_USR)/lib$(LIB_BITS)
	[ -L $@ ] || /bin/ln -s ../../lib/$(<F) $@
endif

# (update library atomically (important to avoid crashing running programs))
# (could use /usr/bin/install if available)
$(PREFIX)/lib$(LIB_BITS)/libnss_mcdb.so.2: libnss_mcdb.so.2 \
                                           $(PREFIX)/lib$(LIB_BITS)
	/bin/cp -f $< $@.$$$$ \
	&& /bin/mv -f $@.$$$$ $@

$(PREFIX_USR)/lib$(LIB_BITS)/libmcdb.so: libmcdb.so \
                                         $(PREFIX_USR)/lib$(LIB_BITS)
	/bin/cp -f $< $@.$$$$ \
	&& /bin/mv -f $@.$$$$ $@

$(PREFIX_USR)/bin/mcdbctl: mcdbctl $(PREFIX_USR)/bin
	/bin/cp -f $< $@.$$$$ \
	&& /bin/mv -f $@.$$$$ $@

$(PREFIX)/sbin/nss_mcdbctl: nss_mcdbctl $(PREFIX)/sbin
	/bin/cp -f $< $@.$$$$ \
	&& /bin/mv -f $@.$$$$ $@

.PHONY: install-headers install install-doc install-plasma-headers
install-plasma-headers: plasma/plasma_atomic.h plasma/plasma_attr.h \
                        plasma/plasma_membar.h plasma/plasma_spin.h
	/bin/mkdir -p -m 0755 $(PREFIX_USR)/include/mcdb/plasma
	umask 333; \
	  /bin/cp -f --preserve=timestamps $^ $(PREFIX_USR)/include/mcdb/plasma/
install-headers: mcdb.h mcdb_error.h mcdb_make.h mcdb_makefmt.h mcdb_makefn.h \
                 nointr.h uint32.h | install-plasma-headers
	/bin/mkdir -p -m 0755 $(PREFIX_USR)/include/mcdb
	umask 333; \
	  /bin/cp -f --preserve=timestamps $^ $(PREFIX_USR)/include/mcdb/
install-doc: CHANGELOG COPYING FAQ INSTALL NOTES README
	/bin/mkdir -p -m 0755 $(PREFIX_USR)/share/doc/mcdb
	umask 333; \
	  /bin/cp -f --preserve=timestamps $^ $(PREFIX_USR)/share/doc/mcdb
install: $(PREFIX)/lib$(LIB_BITS)/libnss_mcdb.so.2 \
         $(PREFIX_USR)/lib$(LIB_BITS)/libnss_mcdb.so.2 \
         $(PREFIX_USR)/lib$(LIB_BITS)/libmcdb.so \
         $(PREFIX_USR)/bin/mcdbctl $(PREFIX)/sbin/nss_mcdbctl \
         install-headers
	/bin/mkdir -p -m 0755 $(PREFIX)/etc/mcdb


# also create 32-bit libraries for /lib on systems with /lib and /lib64
ifeq (,$(MCDB_SKIP32))
ifeq (,$(RPM_ARCH))
ifeq (64,$(LIB_BITS))
ifeq (,$(wildcard lib32))
  $(shell mkdir -p lib32/plasma)
endif
lib32/%.o: %.c $(_DEPENDENCIES_ON_ALL_HEADERS_Makefile)
	$(CC) -o $@ $(CFLAGS) -c $<

LIB32_PIC_OBJS:= $(addprefix lib32/,$(PIC_OBJS))
$(LIB32_PIC_OBJS): LIB_BITS=32
$(LIB32_PIC_OBJS): ABI_FLAGS=-m32
$(LIB32_PIC_OBJS): CFLAGS+= $(FPIC)

ifeq ($(OSNAME),Linux)
lib32/libnss_mcdb.so.2: \
  LDFLAGS+=-Wl,-soname,$(@F) -Wl,--version-script,nss_mcdb.map
endif
lib32/libnss_mcdb.so.2: ABI_FLAGS=-m32
lib32/libnss_mcdb.so.2: $(addprefix lib32/, \
  mcdb.o uint32.o nss_mcdb.o nss_mcdb_acct.o nss_mcdb_authn.o nss_mcdb_netdb.o \
  plasma/plasma_atomic.o plasma/plasma_spin.o)
	$(CC) -o $@ $(SHLIB) $(FPIC) $(LDFLAGS) $^

ifeq ($(OSNAME),Linux)
lib32/libmcdb.so: LDFLAGS+=-Wl,-soname,$(@F)
endif
lib32/libmcdb.so: ABI_FLAGS=-m32
lib32/libmcdb.so: $(addprefix lib32/, \
  mcdb.o mcdb_make.o mcdb_makefmt.o mcdb_makefn.o nointr.o uint32.o \
  plasma/plasma_atomic.o plasma/plasma_spin.o)
	$(CC) -o $@ $(SHLIB) $(FPIC) $(LDFLAGS) $^

ifneq ($(PREFIX_USR),$(PREFIX))
$(PREFIX_USR)/lib/libnss_mcdb.so.2: $(PREFIX)/lib/libnss_mcdb.so.2 \
                                    $(PREFIX_USR)/lib
	[ -L $@ ] || /bin/ln -s ../../lib/$(<F) $@
endif

$(PREFIX)/lib/libnss_mcdb.so.2: lib32/libnss_mcdb.so.2 $(PREFIX)/lib
	/bin/cp -f $< $@.$$$$ \
	&& /bin/mv -f $@.$$$$ $@

$(PREFIX_USR)/lib/libmcdb.so: lib32/libmcdb.so $(PREFIX_USR)/lib
	/bin/cp -f $< $@.$$$$ \
	&& /bin/mv -f $@.$$$$ $@

all: lib32/libnss_mcdb.so.2 lib32/libmcdb.so

install: $(PREFIX)/lib/libnss_mcdb.so.2 $(PREFIX_USR)/lib/libnss_mcdb.so.2 \
         $(PREFIX_USR)/lib/libmcdb.so
endif
endif
endif


# bootstrap for creating CPAN module MCDB_File dist package
.PHONY: MCDB_File-bootstrap MCDB_File-bootstrap-clean
MCDB_File-bootstrap: clean MCDB_File-bootstrap-clean
	cd .. && tar czf mcdb/contrib/MCDB_File/mcdb.tar.gz --exclude=mcdb.tar.gz --exclude=.git mcdb
MCDB_File-bootstrap-clean:
	[ ! -f contrib/MCDB_File/Makefile ] || \
          $(MAKE) -C contrib/MCDB_File distclean
	[ ! -d contrib/MCDB_File/mcdb ] || $(RM) -r contrib/MCDB_File/mcdb
	-$(RM) contrib/MCDB_File/mcdb.tar.gz


.PHONY: test test64
test64: TEST64=test64
test64: test ;
test: mcdbctl t/testzero
	$(RM) -r t/scratch
	mkdir -p t/scratch
	cd t/scratch && \
	  env - PATH="$(CURDIR):$(CURDIR)/t:$$PATH" \
	  $(CURDIR)/t/mcdbctl.t $(TEST64) 2>&1 | cat -v
	$(RM) -r t/scratch


usr_bin_id:=$(wildcard /usr/xpg4/bin/id)
ifeq (,$(usr_bin_id))
usr_bin_id:=/usr/bin/id
endif

.PHONY: clean clean-contrib realclean
clean:
	[ "$$($(usr_bin_id) -u)" != "0" ]
	$(RM) *.o t/*.o plasma/*.o
	$(RM) -r lib32
	$(RM) libmcdb.a libnss_mcdb.a libnss_mcdb_make.a
	$(RM) libmcdb.so libnss_mcdb.so.2
	$(RM) mcdbctl nss_mcdbctl t/testmcdbmake t/testmcdbrand t/testzero

clean-contrib:
	-$(MAKE) MCDB_File-bootstrap-clean
	$(MAKE) MCDB_File-bootstrap-clean
	$(MAKE) -C contrib/lua-mcdb clean
	[ ! -d contrib/python-mcdb/build ] || $(RM) -r contrib/python-mcdb/build
	[ ! -f contrib/ruby-mcdb/Makefile ] || \
          $(MAKE) -C contrib/ruby-mcdb distclean

realclean: clean-contrib clean
