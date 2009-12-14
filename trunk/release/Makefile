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

VERSION = 0.0.1
SVN = https://twatch.svn.sourceforge.net/svnroot/twatch/trunk


all:
	@echo "*** Full build ***"
	make clean
	make get && make doc && make orig && make build

get:
	@echo "*** Get last from svn ***"
	svn export $(SVN)/twatch/ twatch-$(VERSION)

doc:
	@echo "*** Create man pages ***"
	pod2man twatch-$(VERSION)/twatch > twatch-$(VERSION)/man/twatch.man

orig:
	@echo "*** Create sorce archive ***"
	tar -czvf twatch_$(VERSION).orig.tar.gz twatch-$(VERSION) \
		--exclude twatch-$(VERSION)/debian 

build:
	@echo "*** Create deb package ***"
	chmod -R a+x twatch-$(VERSION)/debian/rules
	cd twatch-$(VERSION) && dpkg-buildpackage

clean:
	@echo "*** Clean all ***"
	@echo "Pause 5 sec. You can stop it by press Ctrl+C..."
	sleep 5
	rm -fr ./*twatch*

install:
	@echo "*** Install packages ***"
	dpkg --install ./*twatch*.deb

uninstall:
	@echo "*** Uninstall packages ***"
	dpkg --purge twatch libtwatch-perl

.PHONY: all get doc orig build clean install uninstall