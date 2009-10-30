
VERSION = 0.0.1
SVN = http://svn.rshadow.ru/twatch/trunk


all:
	make clean
	make get && make orig && make doc && make build

get:
	@echo "Получение всех проектов twatch из svn"
	svn export $(SVN)/twatch/ twatch-$(VERSION)
	svn export $(SVN)/twatch-gtk twatch-gtk-$(VERSION)

orig:
	tar -czvf twatch_$(VERSION).orig.tar.gz twatch-$(VERSION) \
		--exclude debian/ 
	tar -czvf twatch-gtk_$(VERSION).orig.tar.gz twatch-gtk-$(VERSION) \
		--exclude debian/

doc:
	pod2man twatch-$(VERSION)/twatch > twatch-$(VERSION)/man/twatch.man

build:
	cd twatch-$(VERSION) && fakeroot debian/rules binary

clean:
	@echo "Удаление всех проектов twatch"
	@echo "Пауза 5 секунд для принятия решения..."
	sleep 5
	rm -fr ./twatch*

.PHONY: all get tar clean