# Notify makefile for distribution

VERSION = 0.3.0

bindir = /usr/local/sbin
sysconfdir = /etc
docdir = /usr/share/doc/notify
mandir = /usr/share/man
libdir = /var/lib/notify
perllibdir = /usr/local/lib/site_perl

MAN_SECTION = 8

DOCS = LICENSE
SAMPLES = sample-notify.conf notify.debian-init
BIN = Makefile notify notifyctl
MAN = notify.8 notifyctl.8
LIB = Notify/

DIST_DIR = notify-${VERSION}
DEB_DIST_DIR = notify-${VERSION}-debian
TARBALL = notify_${VERSION}.orig.tar.gz
DEB_TARBALL = notify_${VERSION}.debian.tar.gz

FILES = ${DOCS} ${SAMPLES} ${BIN} ${MAN}

all: ${FILES}

doc:
	pod2man --center "Notification Throttling Daemon" --section ${MAN_SECTION} notify >notify.${MAN_SECTION}
	pod2man --center "Notification Throttling Daemon Control" --section ${MAN_SECTION} notifyctl >notifyctl.${MAN_SECTION}

test:
	perl -MTest::Harness -e'runtests(@ARGV)' t/*.t

clean:
	rm -rf notify_*.tar.gz

dist: ${TARBALL} ${DEB_TARBALL}

${TARBALL}:
	mkdir -p ${DIST_DIR}
	cp -r t/ ${DIST_DIR}/t/
	cp ${FILES} ${DIST_DIR}
	cp -r ${LIB} ${DIST_DIR}/${LIB}
	tar czvf ${TARBALL} ${DIST_DIR}
	rm -rf ${DIST_DIR}

${DEB_TARBALL}:
	mkdir -p ${DEB_DIST_DIR}
	cp debian/* ${DEB_DIST_DIR}
	cp notify.debian-init ${DEB_DIST_DIR}/init
	tar czvf ${DEB_TARBALL} ${DEB_DIST_DIR}
	rm -rf ${DEB_DIST_DIR}

install:
	install -D notify ${DESTDIR}${bindir}/notify
	install -D notifyctl ${DESTDIR}${bindir}/notifyctl
	install -D Notify/Client.pm ${DESTDIR}${perllibdir}/Notify/Client.pm
	install -D Notify/Client/Console.pm ${DESTDIR}${perllibdir}/Notify/Client/Console.pm
	install -D Notify/Config.pm ${DESTDIR}${perllibdir}/Notify/Config.pm
	install -D Notify/Logger.pm ${DESTDIR}${perllibdir}/Notify/Logger.pm
	install -D Notify/Message.pm ${DESTDIR}${perllibdir}/Notify/Message.pm
	install -D Notify/Notification.pm ${DESTDIR}${perllibdir}/Notify/Notification.pm
	install -D Notify/Provider.pm ${DESTDIR}${perllibdir}/Notify/Provider.pm
	install -D Notify/ProviderFactory.pm ${DESTDIR}${perllibdir}/Notify/ProviderFactory.pm
	install -D Notify/Queue.pm ${DESTDIR}${perllibdir}/Notify/Queue.pm
	install -D Notify/Recipient.pm ${DESTDIR}${perllibdir}/Notify/Recipient.pm
	install -D Notify/RecipientFactory.pm ${DESTDIR}${perllibdir}/Notify/RecipientFactory.pm
	install -D Notify/SMS/ProviderEsendex.pm ${DESTDIR}${perllibdir}/Notify/SMS/ProviderEsendex.pm
	install -D Notify/SMS/Recipient.pm ${DESTDIR}${perllibdir}/Notify/SMS/Recipient.pm
	install -D Notify/Email/Recipient.pm ${DESTDIR}${perllibdir}/Notify/Email/Recipient.pm
	install -D Notify/Email/ProviderEmail.pm ${DESTDIR}${perllibdir}/Notify/Email/ProviderEmail.pm
	install -D Notify/Sender.pm ${DESTDIR}${perllibdir}/Notify/Sender.pm
	install -D Notify/Suspend.pm ${DESTDIR}${perllibdir}/Notify/Suspend.pm
	install -D Notify/Server.pm ${DESTDIR}${perllibdir}/Notify/Server.pm
	install -g root -m 0644 notify.8 ${DESTDIR}${mandir}/man8/
	install -g root -m 0644 notifyctl.8 ${DESTDIR}${mandir}/man8/
	install -g root -m 755 -d ${DESTDIR}${libdir}
	install -D notify ${DESTDIR}${bindir}/notify
	[ -f ${DESTDIR}${sysconfdir}/notify/notify.conf ] || \
		install -g root -m 0644 -D sample-notify.conf ${DESTDIR}${sysconfdir}/notify/notify.conf
