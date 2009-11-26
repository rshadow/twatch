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
	make get && make orig && make doc && make build

get:
	@echo "*** Get last from svn ***"
	svn export $(SVN)/twatch/ twatch-$(VERSION)
#	svn export $(SVN)/twatch-gtk twatch-gtk-$(VERSION)

orig:
	@echo "*** Create sorce archive ***"
	tar -czvf twatch_$(VERSION).orig.tar.gz twatch-$(VERSION) \
		--exclude debian/ 
#	tar -czvf twatch-gtk_$(VERSION).orig.tar.gz twatch-gtk-$(VERSION) \
#		--exclude debian/

doc:
	@echo "*** Create man pages ***"
	pod2man twatch-$(VERSION)/twatch > twatch-$(VERSION)/man/twatch.man

build:
	@echo "*** Create deb package ***"
	chmod -R a+x twatch-$(VERSION)/debian/rules
	cd twatch-$(VERSION) && fakeroot debian/rules binary

clean:
	@echo "*** Clean all ***"
	@echo "Pause 5 sec. You can stop it by press Ctrl+C..."
	sleep 5
	rm -fr ./*twatch*

install:
	@echo "*** Install packages ***"
	dpkg -i ./*twatch*.deb

.PHONY: all get orig doc build clean install