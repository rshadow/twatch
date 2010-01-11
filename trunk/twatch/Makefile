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

VERSION = 0.0.2-1
SVN = https://twatch.svn.sourceforge.net/svnroot/twatch/trunk

# Make new release from svn (deb package and files for mainteiner)
all:
	@echo "*** Full build ***"
	make clean
	make get && make doc && make orig && make build

# Get source from svn (prepare to make deb package)
get:
	@echo "*** Get last from svn ***"
	cd release/ && svn export $(SVN)/twatch/ twatch-$(VERSION)

# Creatre doc in cource directory (prepare to make deb package)
doc:
	@echo "*** Create man pages ***"
	cd release/ && pod2man twatch-$(VERSION)/twatch > twatch-$(VERSION)/man/twatch.man

# Create orig archive
orig:
	@echo "*** Create sorce archive ***"
	cd release/ && tar -czvf twatch_$(VERSION).orig.tar.gz twatch-$(VERSION) \
		--exclude twatch-$(VERSION)/debian 

# Create local deb package
build:
	@echo "*** Create deb package ***"
	cd release/ && chmod -R a+x twatch-$(VERSION)/debian/rules
	cd release/ && cd twatch-$(VERSION) && dpkg-buildpackage

# Clear all files in release/ directory
clean:
	@echo "*** Clean all ***"
	@echo "Pause 5 sec. You can stop it by press Ctrl+C..."
	sleep 5
	cd release/ && rm -fr ./*twatch*

# Install use Debian package system
install:
	@echo "*** Install packages ***"
	cd release/ && dpkg --install ./*twatch*.deb

# Uninstall use Debian package system
uninstall:
	@echo "*** Uninstall packages ***"
	cd release/ && dpkg --purge twatch libtwatch-perl

# Test source code by scripts in t/ directory	
tests:
	set -e; find t/ -name '*.t'|while read test; do perl $$test; done

# Send new release to mainteiner via email dimka@uvw.ru
mail:
	mutt -s "New TWatch version $(VERSION)" \
		-a release/twatch_$(VERSION).diff.gz \
		-a release/twatch_$(VERSION).dsc \
		-a release/twatch_$(VERSION).orig.tar.gz \
		rshadow@rambler.ru

.PHONY: all get doc orig build clean install uninstall tests mail