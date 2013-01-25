#
#   appweb-solaris-debug.mk -- Makefile to build Embedthis Appweb for solaris
#

PRODUCT         ?= appweb
VERSION         ?= 4.3.0
BUILD_NUMBER    ?= 0
PROFILE         ?= debug
ARCH            ?= $(shell uname -m | sed 's/i.86/x86/;s/x86_64/x64/;s/arm.*/arm/;s/mips.*/mips/')
OS              ?= solaris
CC              ?= /usr/bin/gcc
LD              ?= /usr/bin/ld
CONFIG          ?= $(OS)-$(ARCH)-$(PROFILE)

CFLAGS          += -fPIC  -w
DFLAGS          += -D_REENTRANT -DPIC 
IFLAGS          += -I$(CONFIG)/inc
LDFLAGS         += '-g'
LIBPATHS        += -L$(CONFIG)/bin
LIBS            += -llxnet -lrt -lsocket -lpthread -lm -ldl

CFLAGS-debug    := -g
CFLAGS-release  := -O2
DFLAGS-debug    := -DBIT_DEBUG
DFLAGS-release  := 
LDFLAGS-debug   := -g
LDFLAGS-release := 
CFLAGS          += $(CFLAGS-$(PROFILE))
DFLAGS          += $(DFLAGS-$(PROFILE))
LDFLAGS         += $(LDFLAGS-$(PROFILE))

all compile: prep \
        $(CONFIG)/bin/libmpr.so \
        $(CONFIG)/bin/libmprssl.so \
        $(CONFIG)/bin/appman \
        $(CONFIG)/bin/libest.so \
        $(CONFIG)/bin/ca.crt \
        $(CONFIG)/bin/libpcre.so \
        $(CONFIG)/bin/libhttp.so \
        $(CONFIG)/bin/http \
        $(CONFIG)/bin/http-ca.crt \
        $(CONFIG)/bin/libappweb.so \
        $(CONFIG)/bin/esp.conf \
        src/server/esp.conf \
        $(CONFIG)/bin/esp-www \
        $(CONFIG)/bin/esp-appweb.conf \
        $(CONFIG)/bin/libejs.so \
        $(CONFIG)/bin/ejs \
        $(CONFIG)/bin/ejsc \
        $(CONFIG)/bin/ejs.mod \
        $(CONFIG)/bin/libmod_ssl.so \
        $(CONFIG)/bin/authpass \
        $(CONFIG)/bin/setConfig \
        src/server/slink.c \
        $(CONFIG)/bin/libapp.so \
        $(CONFIG)/bin/appweb \
        src/server/cache \
        $(CONFIG)/bin/testAppweb \
        test/cgi-bin/testScript \
        test/web/caching/cache.cgi \
        test/web/auth/basic/basic.cgi \
        test/cgi-bin/cgiProgram \
        test/web/js

.PHONY: prep

prep:
	@if [ "$(CONFIG)" = "" ] ; then echo WARNING: CONFIG not set ; exit 255 ; fi
	@[ ! -x $(CONFIG)/inc ] && mkdir -p $(CONFIG)/inc $(CONFIG)/obj $(CONFIG)/lib $(CONFIG)/bin ; true
	@[ ! -f $(CONFIG)/inc/bit.h ] && cp projects/appweb-$(OS)-$(PROFILE)-bit.h $(CONFIG)/inc/bit.h ; true
	@[ ! -f $(CONFIG)/inc/bitos.h ] && cp src/bitos.h $(CONFIG)/inc/bitos.h ; true
	@if ! diff $(CONFIG)/inc/bit.h projects/appweb-$(OS)-$(PROFILE)-bit.h >/dev/null ; then\
		echo cp projects/appweb-$(OS)-$(PROFILE)-bit.h $(CONFIG)/inc/bit.h  ; \
		cp projects/appweb-$(OS)-$(PROFILE)-bit.h $(CONFIG)/inc/bit.h  ; \
	fi; true
	@echo $(DFLAGS) $(CFLAGS) >projects/.flags

clean:
	rm -rf $(CONFIG)/bin/libmpr.so
	rm -rf $(CONFIG)/bin/libmprssl.so
	rm -rf $(CONFIG)/bin/appman
	rm -rf $(CONFIG)/bin/libest.so
	rm -rf $(CONFIG)/bin/ca.crt
	rm -rf $(CONFIG)/bin/libpcre.so
	rm -rf $(CONFIG)/bin/libhttp.so
	rm -rf $(CONFIG)/bin/http
	rm -rf $(CONFIG)/bin/http-ca.crt
	rm -rf $(CONFIG)/bin/libappweb.so
	rm -rf $(CONFIG)/bin/esp.conf
	rm -rf src/server/esp.conf
	rm -rf $(CONFIG)/bin/esp-www
	rm -rf $(CONFIG)/bin/esp-appweb.conf
	rm -rf $(CONFIG)/bin/libejs.so
	rm -rf $(CONFIG)/bin/ejs
	rm -rf $(CONFIG)/bin/ejsc
	rm -rf $(CONFIG)/bin/ejs.mod
	rm -rf $(CONFIG)/bin/libmod_ssl.so
	rm -rf $(CONFIG)/bin/authpass
	rm -rf $(CONFIG)/bin/setConfig
	rm -rf $(CONFIG)/bin/libapp.so
	rm -rf $(CONFIG)/bin/appweb
	rm -rf $(CONFIG)/bin/testAppweb
	rm -rf test/cgi-bin/testScript
	rm -rf test/web/caching/cache.cgi
	rm -rf test/web/auth/basic/basic.cgi
	rm -rf test/cgi-bin/cgiProgram
	rm -rf test/web/js
	rm -rf $(CONFIG)/obj/mprLib.o
	rm -rf $(CONFIG)/obj/mprSsl.o
	rm -rf $(CONFIG)/obj/manager.o
	rm -rf $(CONFIG)/obj/makerom.o
	rm -rf $(CONFIG)/obj/estLib.o
	rm -rf $(CONFIG)/obj/pcre.o
	rm -rf $(CONFIG)/obj/httpLib.o
	rm -rf $(CONFIG)/obj/http.o
	rm -rf $(CONFIG)/obj/sqlite3.o
	rm -rf $(CONFIG)/obj/sqlite.o
	rm -rf $(CONFIG)/obj/config.o
	rm -rf $(CONFIG)/obj/convenience.o
	rm -rf $(CONFIG)/obj/dirHandler.o
	rm -rf $(CONFIG)/obj/fileHandler.o
	rm -rf $(CONFIG)/obj/log.o
	rm -rf $(CONFIG)/obj/server.o
	rm -rf $(CONFIG)/obj/edi.o
	rm -rf $(CONFIG)/obj/espAbbrev.o
	rm -rf $(CONFIG)/obj/espFramework.o
	rm -rf $(CONFIG)/obj/espHandler.o
	rm -rf $(CONFIG)/obj/espHtml.o
	rm -rf $(CONFIG)/obj/espTemplate.o
	rm -rf $(CONFIG)/obj/mdb.o
	rm -rf $(CONFIG)/obj/sdb.o
	rm -rf $(CONFIG)/obj/esp.o
	rm -rf $(CONFIG)/obj/ejsLib.o
	rm -rf $(CONFIG)/obj/ejs.o
	rm -rf $(CONFIG)/obj/ejsc.o
	rm -rf $(CONFIG)/obj/cgiHandler.o
	rm -rf $(CONFIG)/obj/ejsHandler.o
	rm -rf $(CONFIG)/obj/phpHandler.o
	rm -rf $(CONFIG)/obj/proxyHandler.o
	rm -rf $(CONFIG)/obj/sslModule.o
	rm -rf $(CONFIG)/obj/authpass.o
	rm -rf $(CONFIG)/obj/cgiProgram.o
	rm -rf $(CONFIG)/obj/setConfig.o
	rm -rf $(CONFIG)/obj/slink.o
	rm -rf $(CONFIG)/obj/web.o
	rm -rf $(CONFIG)/obj/appweb.o
	rm -rf $(CONFIG)/obj/appwebMonitor.o
	rm -rf $(CONFIG)/obj/testAppweb.o
	rm -rf $(CONFIG)/obj/testHttp.o
	rm -rf $(CONFIG)/obj/removeFiles.o

clobber: clean
	rm -fr ./$(CONFIG)

$(CONFIG)/inc/bitos.h:  \
        $(CONFIG)/inc/bit.h
	rm -fr $(CONFIG)/inc/bitos.h
	cp -r src/bitos.h $(CONFIG)/inc/bitos.h

$(CONFIG)/inc/mpr.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/bitos.h
	rm -fr $(CONFIG)/inc/mpr.h
	cp -r src/deps/mpr/mpr.h $(CONFIG)/inc/mpr.h

$(CONFIG)/obj/mprLib.o: \
        src/deps/mpr/mprLib.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/mpr.h
	$(CC) -c -o $(CONFIG)/obj/mprLib.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/mpr/mprLib.c

$(CONFIG)/bin/libmpr.so:  \
        $(CONFIG)/inc/mpr.h \
        $(CONFIG)/obj/mprLib.o
	$(CC) -shared -o $(CONFIG)/bin/libmpr.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/mprLib.o $(LIBS)

$(CONFIG)/inc/est.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/bitos.h
	rm -fr $(CONFIG)/inc/est.h
	cp -r src/deps/est/est.h $(CONFIG)/inc/est.h

$(CONFIG)/obj/estLib.o: \
        src/deps/est/estLib.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/est.h
	$(CC) -c -o $(CONFIG)/obj/estLib.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/est/estLib.c

$(CONFIG)/bin/libest.so:  \
        $(CONFIG)/inc/est.h \
        $(CONFIG)/obj/estLib.o
	$(CC) -shared -o $(CONFIG)/bin/libest.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/estLib.o $(LIBS)

$(CONFIG)/obj/mprSsl.o: \
        src/deps/mpr/mprSsl.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/mpr.h \
        $(CONFIG)/inc/est.h
	$(CC) -c -o $(CONFIG)/obj/mprSsl.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/mpr/mprSsl.c

$(CONFIG)/bin/libmprssl.so:  \
        $(CONFIG)/bin/libmpr.so \
        $(CONFIG)/bin/libest.so \
        $(CONFIG)/obj/mprSsl.o
	$(CC) -shared -o $(CONFIG)/bin/libmprssl.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/mprSsl.o -lest -lmpr $(LIBS)

$(CONFIG)/obj/manager.o: \
        src/deps/mpr/manager.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/mpr.h
	$(CC) -c -o $(CONFIG)/obj/manager.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/mpr/manager.c

$(CONFIG)/bin/appman:  \
        $(CONFIG)/bin/libmpr.so \
        $(CONFIG)/obj/manager.o
	$(CC) -o $(CONFIG)/bin/appman $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/manager.o -lmpr $(LIBS) -lmpr -llxnet -lrt -lsocket -lpthread -lm -ldl $(LDFLAGS)

$(CONFIG)/bin/ca.crt: 
	rm -fr $(CONFIG)/bin/ca.crt
	cp -r src/deps/est/ca.crt $(CONFIG)/bin/ca.crt

$(CONFIG)/inc/pcre.h:  \
        $(CONFIG)/inc/bit.h
	rm -fr $(CONFIG)/inc/pcre.h
	cp -r src/deps/pcre/pcre.h $(CONFIG)/inc/pcre.h

$(CONFIG)/obj/pcre.o: \
        src/deps/pcre/pcre.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/pcre.h
	$(CC) -c -o $(CONFIG)/obj/pcre.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/pcre/pcre.c

$(CONFIG)/bin/libpcre.so:  \
        $(CONFIG)/inc/pcre.h \
        $(CONFIG)/obj/pcre.o
	$(CC) -shared -o $(CONFIG)/bin/libpcre.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/pcre.o $(LIBS)

$(CONFIG)/inc/http.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/mpr.h
	rm -fr $(CONFIG)/inc/http.h
	cp -r src/deps/http/http.h $(CONFIG)/inc/http.h

$(CONFIG)/obj/httpLib.o: \
        src/deps/http/httpLib.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/http.h \
        $(CONFIG)/inc/pcre.h
	$(CC) -c -o $(CONFIG)/obj/httpLib.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/http/httpLib.c

$(CONFIG)/bin/libhttp.so:  \
        $(CONFIG)/bin/libmpr.so \
        $(CONFIG)/bin/libpcre.so \
        $(CONFIG)/inc/http.h \
        $(CONFIG)/obj/httpLib.o
	$(CC) -shared -o $(CONFIG)/bin/libhttp.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/httpLib.o -lpcre -lmpr $(LIBS)

$(CONFIG)/obj/http.o: \
        src/deps/http/http.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/http.h
	$(CC) -c -o $(CONFIG)/obj/http.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/http/http.c

$(CONFIG)/bin/http:  \
        $(CONFIG)/bin/libhttp.so \
        $(CONFIG)/obj/http.o
	$(CC) -o $(CONFIG)/bin/http $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/http.o -lhttp $(LIBS) -lpcre -lmpr -lhttp -llxnet -lrt -lsocket -lpthread -lm -ldl -lpcre -lmpr $(LDFLAGS)

$(CONFIG)/bin/http-ca.crt: 
	rm -fr $(CONFIG)/bin/http-ca.crt
	cp -r src/deps/http/http-ca.crt $(CONFIG)/bin/http-ca.crt

$(CONFIG)/inc/customize.h:  \
        $(CONFIG)/inc/bit.h
	rm -fr $(CONFIG)/inc/customize.h
	cp -r src/customize.h $(CONFIG)/inc/customize.h

$(CONFIG)/inc/appweb.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/mpr.h \
        $(CONFIG)/inc/http.h \
        $(CONFIG)/inc/customize.h
	rm -fr $(CONFIG)/inc/appweb.h
	cp -r src/appweb.h $(CONFIG)/inc/appweb.h

$(CONFIG)/obj/config.o: \
        src/config.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h \
        $(CONFIG)/inc/pcre.h
	$(CC) -c -o $(CONFIG)/obj/config.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/config.c

$(CONFIG)/obj/convenience.o: \
        src/convenience.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	$(CC) -c -o $(CONFIG)/obj/convenience.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/convenience.c

$(CONFIG)/obj/dirHandler.o: \
        src/dirHandler.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	$(CC) -c -o $(CONFIG)/obj/dirHandler.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/dirHandler.c

$(CONFIG)/obj/fileHandler.o: \
        src/fileHandler.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	$(CC) -c -o $(CONFIG)/obj/fileHandler.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/fileHandler.c

$(CONFIG)/obj/log.o: \
        src/log.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	$(CC) -c -o $(CONFIG)/obj/log.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/log.c

$(CONFIG)/obj/server.o: \
        src/server.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	$(CC) -c -o $(CONFIG)/obj/server.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/server.c

$(CONFIG)/bin/libappweb.so:  \
        $(CONFIG)/bin/libhttp.so \
        $(CONFIG)/inc/appweb.h \
        $(CONFIG)/inc/bitos.h \
        $(CONFIG)/inc/customize.h \
        $(CONFIG)/obj/config.o \
        $(CONFIG)/obj/convenience.o \
        $(CONFIG)/obj/dirHandler.o \
        $(CONFIG)/obj/fileHandler.o \
        $(CONFIG)/obj/log.o \
        $(CONFIG)/obj/server.o
	$(CC) -shared -o $(CONFIG)/bin/libappweb.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/config.o $(CONFIG)/obj/convenience.o $(CONFIG)/obj/dirHandler.o $(CONFIG)/obj/fileHandler.o $(CONFIG)/obj/log.o $(CONFIG)/obj/server.o -lhttp $(LIBS) -lpcre -lmpr

$(CONFIG)/bin/esp.conf: 
	rm -fr $(CONFIG)/bin/esp.conf
	cp -r src/esp/esp.conf $(CONFIG)/bin/esp.conf

src/server/esp.conf: 
	rm -fr src/server/esp.conf
	cp -r src/esp/esp.conf src/server/esp.conf

$(CONFIG)/bin/esp-www: 
	rm -fr $(CONFIG)/bin/esp-www
	cp -r src/esp/www $(CONFIG)/bin/esp-www

$(CONFIG)/bin/esp-appweb.conf: 
	rm -fr $(CONFIG)/bin/esp-appweb.conf
	cp -r src/esp/esp-appweb.conf $(CONFIG)/bin/esp-appweb.conf

$(CONFIG)/inc/ejs.slots.h:  \
        $(CONFIG)/inc/bit.h
	rm -fr $(CONFIG)/inc/ejs.slots.h
	cp -r src/deps/ejs/ejs.slots.h $(CONFIG)/inc/ejs.slots.h

$(CONFIG)/inc/ejs.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/bitos.h \
        $(CONFIG)/inc/mpr.h \
        $(CONFIG)/inc/http.h \
        $(CONFIG)/inc/ejs.slots.h
	rm -fr $(CONFIG)/inc/ejs.h
	cp -r src/deps/ejs/ejs.h $(CONFIG)/inc/ejs.h

$(CONFIG)/inc/ejsByteGoto.h: 
	rm -fr $(CONFIG)/inc/ejsByteGoto.h
	cp -r src/deps/ejs/ejsByteGoto.h $(CONFIG)/inc/ejsByteGoto.h

$(CONFIG)/inc/sqlite3.h:  \
        $(CONFIG)/inc/bit.h
	rm -fr $(CONFIG)/inc/sqlite3.h
	cp -r src/deps/sqlite/sqlite3.h $(CONFIG)/inc/sqlite3.h

$(CONFIG)/obj/ejsLib.o: \
        src/deps/ejs/ejsLib.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/ejs.h \
        $(CONFIG)/inc/mpr.h \
        $(CONFIG)/inc/pcre.h \
        $(CONFIG)/inc/sqlite3.h
	$(CC) -c -o $(CONFIG)/obj/ejsLib.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/ejs/ejsLib.c

$(CONFIG)/bin/libejs.so:  \
        $(CONFIG)/bin/libhttp.so \
        $(CONFIG)/bin/libpcre.so \
        $(CONFIG)/bin/libmpr.so \
        $(CONFIG)/inc/ejs.h \
        $(CONFIG)/inc/ejs.slots.h \
        $(CONFIG)/inc/ejsByteGoto.h \
        $(CONFIG)/obj/ejsLib.o
	$(CC) -shared -o $(CONFIG)/bin/libejs.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/ejsLib.o -lmpr -lpcre -lhttp $(LIBS) -lpcre -lmpr

$(CONFIG)/obj/ejs.o: \
        src/deps/ejs/ejs.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/ejs.h
	$(CC) -c -o $(CONFIG)/obj/ejs.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/ejs/ejs.c

$(CONFIG)/bin/ejs:  \
        $(CONFIG)/bin/libejs.so \
        $(CONFIG)/obj/ejs.o
	$(CC) -o $(CONFIG)/bin/ejs $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/ejs.o -lejs $(LIBS) -lmpr -lpcre -lhttp -lejs -llxnet -lrt -lsocket -lpthread -lm -ldl -lmpr -lpcre -lhttp $(LDFLAGS)

$(CONFIG)/obj/ejsc.o: \
        src/deps/ejs/ejsc.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/ejs.h
	$(CC) -c -o $(CONFIG)/obj/ejsc.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/deps/ejs/ejsc.c

$(CONFIG)/bin/ejsc:  \
        $(CONFIG)/bin/libejs.so \
        $(CONFIG)/obj/ejsc.o
	$(CC) -o $(CONFIG)/bin/ejsc $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/ejsc.o -lejs $(LIBS) -lmpr -lpcre -lhttp -lejs -llxnet -lrt -lsocket -lpthread -lm -ldl -lmpr -lpcre -lhttp $(LDFLAGS)

$(CONFIG)/bin/ejs.mod:  \
        $(CONFIG)/bin/ejsc
	cd src/deps/ejs >/dev/null ;\
		../../../$(CONFIG)/bin/ejsc --out ../../../$(CONFIG)/bin/ejs.mod --optimize 9 --bind --require null ejs.es ;\
		cd - >/dev/null 

$(CONFIG)/obj/sslModule.o: \
        src/modules/sslModule.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	$(CC) -c -o $(CONFIG)/obj/sslModule.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/modules/sslModule.c

$(CONFIG)/bin/libmod_ssl.so:  \
        $(CONFIG)/bin/libappweb.so \
        $(CONFIG)/obj/sslModule.o
	$(CC) -shared -o $(CONFIG)/bin/libmod_ssl.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/sslModule.o -lappweb $(LIBS) -lhttp -lpcre -lmpr

$(CONFIG)/obj/authpass.o: \
        src/utils/authpass.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	$(CC) -c -o $(CONFIG)/obj/authpass.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/utils/authpass.c

$(CONFIG)/bin/authpass:  \
        $(CONFIG)/bin/libappweb.so \
        $(CONFIG)/obj/authpass.o
	$(CC) -o $(CONFIG)/bin/authpass $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/authpass.o -lappweb $(LIBS) -lhttp -lpcre -lmpr -lappweb -llxnet -lrt -lsocket -lpthread -lm -ldl -lhttp -lpcre -lmpr $(LDFLAGS)

$(CONFIG)/obj/setConfig.o: \
        src/utils/setConfig.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/mpr.h
	$(CC) -c -o $(CONFIG)/obj/setConfig.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/utils/setConfig.c

$(CONFIG)/bin/setConfig:  \
        $(CONFIG)/bin/libmpr.so \
        $(CONFIG)/obj/setConfig.o
	$(CC) -o $(CONFIG)/bin/setConfig $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/setConfig.o -lmpr $(LIBS) -lmpr -llxnet -lrt -lsocket -lpthread -lm -ldl $(LDFLAGS)

src/server/slink.c: 
	cd src/server >/dev/null ;\
		[ ! -f slink.c ] && cp slink.empty slink.c ; true ;\
		cd - >/dev/null 

$(CONFIG)/inc/edi.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h
	rm -fr $(CONFIG)/inc/edi.h
	cp -r src/esp/edi.h $(CONFIG)/inc/edi.h

$(CONFIG)/inc/esp.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h \
        $(CONFIG)/inc/edi.h
	rm -fr $(CONFIG)/inc/esp.h
	cp -r src/esp/esp.h $(CONFIG)/inc/esp.h

$(CONFIG)/obj/slink.o: \
        src/server/slink.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/esp.h
	$(CC) -c -o $(CONFIG)/obj/slink.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/server/slink.c

$(CONFIG)/inc/esp-app.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/esp.h
	rm -fr $(CONFIG)/inc/esp-app.h
	cp -r src/esp/esp-app.h $(CONFIG)/inc/esp-app.h

$(CONFIG)/obj/web.o: \
        src/server/cache/web.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/esp.h \
        $(CONFIG)/inc/esp-app.h
	$(CC) -c -o $(CONFIG)/obj/web.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/server/cache/web.c

$(CONFIG)/bin/libapp.so:  \
        src/server/slink.c \
        $(CONFIG)/obj/slink.o \
        $(CONFIG)/obj/web.o
	$(CC) -shared -o $(CONFIG)/bin/libapp.so $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/slink.o $(CONFIG)/obj/web.o $(LIBS)

$(CONFIG)/obj/appweb.o: \
        src/server/appweb.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/appweb.h \
        $(CONFIG)/inc/esp.h
	$(CC) -c -o $(CONFIG)/obj/appweb.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc src/server/appweb.c

$(CONFIG)/bin/appweb:  \
        $(CONFIG)/bin/libappweb.so \
        $(CONFIG)/bin/libmod_ssl.so \
        $(CONFIG)/bin/libapp.so \
        $(CONFIG)/obj/appweb.o
	$(CC) -o $(CONFIG)/bin/appweb $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/appweb.o -lapp -lmod_ssl -lappweb $(LIBS) -lhttp -lpcre -lmpr -lapp -lmod_ssl -lappweb -llxnet -lrt -lsocket -lpthread -lm -ldl -lhttp -lpcre -lmpr $(LDFLAGS)

src/server/cache: 
	cd src/server >/dev/null ;\
		mkdir -p cache ;\
		cd - >/dev/null 

$(CONFIG)/inc/testAppweb.h:  \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/mpr.h \
        $(CONFIG)/inc/http.h
	rm -fr $(CONFIG)/inc/testAppweb.h
	cp -r test/testAppweb.h $(CONFIG)/inc/testAppweb.h

$(CONFIG)/obj/testAppweb.o: \
        test/testAppweb.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/testAppweb.h
	$(CC) -c -o $(CONFIG)/obj/testAppweb.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc test/testAppweb.c

$(CONFIG)/obj/testHttp.o: \
        test/testHttp.c \
        $(CONFIG)/inc/bit.h \
        $(CONFIG)/inc/testAppweb.h
	$(CC) -c -o $(CONFIG)/obj/testHttp.o -fPIC $(LDFLAGS) $(DFLAGS) -I$(CONFIG)/inc test/testHttp.c

$(CONFIG)/bin/testAppweb:  \
        $(CONFIG)/bin/libappweb.so \
        $(CONFIG)/inc/testAppweb.h \
        $(CONFIG)/obj/testAppweb.o \
        $(CONFIG)/obj/testHttp.o
	$(CC) -o $(CONFIG)/bin/testAppweb $(LDFLAGS) $(LIBPATHS) $(CONFIG)/obj/testAppweb.o $(CONFIG)/obj/testHttp.o -lappweb $(LIBS) -lhttp -lpcre -lmpr -lappweb -llxnet -lrt -lsocket -lpthread -lm -ldl -lhttp -lpcre -lmpr $(LDFLAGS)

test/cgi-bin/testScript: 
	cd test >/dev/null ;\
		echo '#!../$(CONFIG)/bin/cgiProgram' >cgi-bin/testScript ; chmod +x cgi-bin/testScript ;\
		cd - >/dev/null 

test/web/caching/cache.cgi: 
	cd test >/dev/null ;\
		echo "#!`type -p ejs`" >web/caching/cache.cgi ;\
	echo 'print("HTTP/1.0 200 OK\nContent-Type: text/plain\n\n" + Date() + "\n")' >>web/caching/cache.cgi ;\
	chmod +x web/caching/cache.cgi ;\
		cd - >/dev/null 

test/web/auth/basic/basic.cgi: 
	cd test >/dev/null ;\
		echo "#!`type -p ejs`" >web/auth/basic/basic.cgi ;\
	echo 'print("HTTP/1.0 200 OK\nContent-Type: text/plain\n\n" + serialize(App.env, {pretty: true}) + "\n")' >>web/auth/basic/basic.cgi ;\
	chmod +x web/auth/basic/basic.cgi ;\
		cd - >/dev/null 

test/cgi-bin/cgiProgram: 
	cd test >/dev/null ;\
		cp ../$(CONFIG)/bin/cgiProgram cgi-bin/cgiProgram ;\
	cp ../$(CONFIG)/bin/cgiProgram cgi-bin/nph-cgiProgram ;\
	cp ../$(CONFIG)/bin/cgiProgram 'cgi-bin/cgi Program' ;\
	cp ../$(CONFIG)/bin/cgiProgram web/cgiProgram.cgi ;\
	chmod +x cgi-bin/* web/cgiProgram.cgi ;\
		cd - >/dev/null 

test/web/js: 
	cd test >/dev/null ;\
		cp -r ../src/esp/www/files/static/js 'web/js' ;\
		cd - >/dev/null 

version: 
	@echo 4.3.0-0 

genslink: 
	cd src/server >/dev/null ;\
		esp --static --genlink slink.c --flat compile ;\
		cd - >/dev/null 

run:  \
        compile
	cd src/server >/dev/null ;\
		sudo $(CONFIG)/bin/appweb -v ;\
		cd - >/dev/null 

test-run:  \
        compile
	cd test >/dev/null ;\
		$(CONFIG)/bin/appweb -v ;\
		cd - >/dev/null 

install: 
	cd . >/dev/null ;\
		sudo make root-install ;\
		cd - >/dev/null 

install-prep:  \
        compile
	cd . >/dev/null ;\
		$(eval $(shell $(BIN)/ejs bits/getbitvals projects/$(NAME)-$(OS)-$(PROFILE)-bit.h  ;\
	PRODUCT VERSION CFG_PREFIX PRD_PREFIX WEB_PREFIX LOG_PREFIX BIN_PREFIX SPL_PREFIX BIN_PREFIX  ;\
	>.prefixes; chmod 666 .prefixes)) ;\
	$(eval include .prefixes) ;\
		cd - >/dev/null 

root-install:  \
        compile \
        install-prep
	cd . >/dev/null ;\
		@$(BIN)/appman stop disable uninstall >/dev/null 2>&1 ; true ;\
	rm -f $(BIT_PRD_PREFIX)/latest $(LBIN)/appweb $(LBIN)/appman $(LBIN)/esp ;\
	install -d -m 755 $(BIT_CFG_PREFIX) $(BIT_BIN_PREFIX) ;\
	install -m 644 src/server/appweb.conf src/server/esp.conf src/server/mime.types $(BIT_CFG_PREFIX) ;\
	install -m 755 $(filter-out $(BIN)/esp-www,$(wildcard $(BIN)/*)) $(BIT_BIN_PREFIX) ;\
	install -m 644 -o root -g wheel ./package/macosx/com.embedthis.appweb.plist /Library/LaunchDaemons ;\
	$(OS)-$(ARCH)-$(PROFILE)/bin/setConfig --home $(BIT_CFG_PREFIX) --documents $(BIT_WEB_PREFIX)  ;\
	--logs $(BIT_LOG_PREFIX) --cache $(BIT_SPL_PREFIX)/cache  ;\
	--modules $(BIT_BIN_PREFIX)  $(BIT_CFG_PREFIX)/appweb.conf ;\
	ln -s $(BIT_VERSION) $(BIT_PRD_PREFIX)/latest ;\
	ln -s $(BIT_BIN_PREFIX)/appweb $(LBIN)/appweb ;\
	ln -s $(BIT_BIN_PREFIX)/appman $(LBIN)/appman ;\
	[ -f $(BIT_BIN_PREFIX)/esp ] && ln -s $(BIT_BIN_PREFIX)/esp $(LBIN)/esp ;\
	$(BIN)/appman install enable start ;\
	exit 0 ;\
		cd - >/dev/null 

uninstall: 
	cd . >/dev/null ;\
		sudo make root-uninstall ;\
		cd - >/dev/null 

root-uninstall:  \
        compile \
        install-prep
	cd . >/dev/null ;\
		$(BIN)/appman stop disable uninstall ;\
	rm -fr $(BIT_CFG_PREFIX) $(BIT_PRD_PREFIX) ;\
		cd - >/dev/null 

