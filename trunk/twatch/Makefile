############################################################################
#
# Makefile for TWatch. 
# Get progect from svn, create source code archive, generate documentation
# and build deb package.
#
# Simple create directory "twatch"
# copy this file in it
# and execute: make all
#
############################################################################

VERSION = 0.0.2
SVN = https://twatch.svn.sourceforge.net/svnroot/twatch/trunk


all:
	@echo "*** Full build ***"
	make clean
	make get && make doc && make orig && make build

get:
	@echo "*** Get last from svn ***"
	cd release/ && svn export $(SVN)/twatch/ twatch-$(VERSION)

doc:
	@echo "*** Create man pages ***"
	cd release/ && pod2man twatch-$(VERSION)/twatch > twatch-$(VERSION)/man/twatch.man

orig:
	@echo "*** Create sorce archive ***"
	cd release/ && tar -czvf twatch_$(VERSION).orig.tar.gz twatch-$(VERSION) \
		--exclude twatch-$(VERSION)/debian 

build:
	@echo "*** Create deb package ***"
	cd release/ && chmod -R a+x twatch-$(VERSION)/debian/rules
	cd release/ && cd twatch-$(VERSION) && dpkg-buildpackage

clean:
	@echo "*** Clean all ***"
	@echo "Pause 5 sec. You can stop it by press Ctrl+C..."
	sleep 5
	cd release/ && rm -fr ./*twatch*

install:
	@echo "*** Install packages ***"
	cd release/ && dpkg --install ./*twatch*.deb

uninstall:
	@echo "*** Uninstall packages ***"
	cd release/ && dpkg --purge twatch libtwatch-perl
	
tests:
	set -e; find t/ -name '*.t'|while read test; do perl $$test; done

.PHONY: all get doc orig build clean install uninstall tests