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

VERSION = $(shell grep -P "^[$$]VERSION" twatch | sed "s~[^[:digit:].]~~g")
SVN = http://svn.twatch.rshadow.ru/trunk/

# Make new release from local path (deb package and files for mainteiner)
.PHONY: all
all:
	@echo "*** Full build from local ***"
	@make clean
	@make get && make doc && make orig && make build

# Get source from local path (prepare to make deb package)
.PHONY: get
get:
	@echo "*** Get last from local ***"
	@test -d build || mkdir build
	@cd build/ && svn export ../ twatch-$(VERSION)

# Make new release from svn (deb package and files for mainteiner)
.PHONY: all_svn
all_svn:
	@echo "*** Full build form SVN ***"
	@make clean
	@make get_svn && make doc && make orig && make build
	
# Get source from svn (prepare to make deb package)
.PHONY: get_svn
get_svn:
	@echo "*** Get last from SVN ***"
	@test -d build || mkdir build
	@cd build/ && svn export $(SVN)/twatch/ twatch-$(VERSION)

# Creatre doc in cource directory (prepare to make deb package)
.PHONY: doc
doc:
	@echo "*** Create man pages ***"
	@cd build/ && pod2man twatch-$(VERSION)/twatch > twatch-$(VERSION)/man/twatch.man

# Create orig archive
.PHONY: orig
orig:
	@echo "*** Create sorce archive ***"
	@cd build/ && tar -czvf twatch_$(VERSION).orig.tar.gz twatch-$(VERSION) \
		--exclude twatch-$(VERSION)/debian 

# Create local deb package
.PHONY: build
build:
	@echo "*** Create deb package ***"
	@cd build/ && chmod -R a+x twatch-$(VERSION)/debian/rules
	@cd build/ && cd twatch-$(VERSION) && dpkg-buildpackage

# Clear all files in build/ directory
.PHONY: clean
clean:
	@echo "*** Clean all ***"
	@echo "Pause 5 sec. You can stop it by press Ctrl+C..."
	@sleep 5
	@cd build/ && rm -fr ./*twatch*

# Install use Debian package system
.PHONY: install
install:
	@echo "*** Install packages ***"
	@cd build/ && dpkg --install ./*twatch*.deb

# Uninstall use Debian package system
.PHONY: uninstall
uninstall:
	@echo "*** Uninstall packages ***"
	@cd build/ && dpkg --purge twatch libtwatch-perl

# Test source code by scripts in t/ directory
.PHONY: tests	
tests:
	@set -e; find t/ -name '*.t'|while read test; do perl $$test; done

# Send new release to mainteiner via email
.PHONY: mail
mail:
	@echo "New files attached" | \
	@mutt -x -s "New TWatch version $(VERSION)" \
		-a build/twatch_$(VERSION).dsc \
		   build/twatch_$(VERSION).tar.gz \
		   build/twatch_$(VERSION).orig.tar.gz \
		-- dimka@uvw.ru

# Get source from svn. After usage delete this file because in created twatch
# directory has one and newest.
.PHONY: src
src:
	@echo "*** Get source from svn ***"	
	@svn checkout $(SVN)/twatch/ ./twatch
