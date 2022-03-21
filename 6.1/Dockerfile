#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:bullseye-slim

RUN set -eux; \
# add backports for (potentially) newer QEMU firmware packages
	suite="$(awk '$1 == "deb" { print $3; exit }' /etc/apt/sources.list)"; \
	echo "deb http://deb.debian.org/debian $suite-backports main" > /etc/apt/sources.list.d/backports.list; \
# and add APT pinning to ensure we don't accidentally get QEMU from Debian
	{ \
		echo 'Package: src:edk2'; \
		echo 'Pin: release a=*-backports'; \
		echo 'Pin-Priority: 600'; \
		echo; \
		echo 'Package: src:qemu'; \
		echo 'Pin: version *'; \
		echo 'Pin-Priority: -10'; \
	} > /etc/apt/preferences.d/qemu.pref; \
	apt-get update; \
# https://github.com/tianon/docker-qemu/issues/30
	apt-get install -y --no-install-recommends ca-certificates; \
	apt-get install -y --no-install-recommends \
		ovmf \
		ovmf-ia32 \
		qemu-efi-aarch64 \
		qemu-efi-arm \
	; \
	rm -rf /var/lib/apt/lists/*

COPY *.patch /qemu-patches/

# https://wiki.qemu.org/SecurityProcess
ENV QEMU_KEYS \
# Michael Roth
		CEACC9E15534EBABB82D3FA03353C9CEF108B584
# https://wiki.qemu.org/Planning/ReleaseProcess#Sign_the_resulting_tarball_with_GPG: (they get signed by whoever is making the release)

# https://www.qemu.org/download/#source
# https://download.qemu.org/?C=M;O=D
ENV QEMU_VERSION 6.1.1
ENV QEMU_URL https://download.qemu.org/qemu-6.1.1.tar.xz

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		gnupg dirmngr \
		wget \
		xz-utils \
		\
		patch \
		\
		bzip2 \
		gcc \
		gnutls-dev \
		libaio-dev \
		libbz2-dev \
		libc-dev \
		libcap-dev \
		libcap-ng-dev \
		libcurl4-gnutls-dev \
		libglib2.0-dev \
		libiscsi-dev \
		libjpeg-dev \
		libncursesw5-dev \
		libnfs-dev \
		libnuma-dev \
		libpixman-1-dev \
		libpng-dev \
		librbd-dev \
		libseccomp-dev \
		libssh-dev \
		libusb-1.0-0-dev \
		libusbredirparser-dev \
		libxen-dev \
		make \
		pkg-config \
		python3 \
		zlib1g-dev \
# https://wiki.qemu.org/ChangeLog/5.2#Build_Information
		ninja-build \
		python3-setuptools \
# https://www.qemu.org/2021/08/22/fuse-blkexport/
		libfuse3-dev \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	tarball="$(basename "$QEMU_URL")"; \
	wget -O "$tarball.sig" "$QEMU_URL.sig"; \
	wget -O "$tarball" "$QEMU_URL" --progress=dot:giga; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $QEMU_KEYS; do \
		gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	done; \
	gpg --batch --verify "$tarball.sig" "$tarball"; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	mkdir /usr/src/qemu; \
	tar -xf "$tarball" -C /usr/src/qemu --strip-components=1; \
	rm "$tarball" "$tarball.sig"; \
	\
	cd /usr/src/qemu; \
	\
	for p in /qemu-patches/*.patch; do \
		patch --strip 1 --input "$p"; \
	done; \
	rm -rf /qemu-patches; \
	\
	./configure --help; \
	./configure \
# let's add a link to our source code in the output of "--version" in case our users end up filing bugs against the QEMU project O:)
		--with-pkgversion='https://github.com/tianon/docker-qemu' \
		--target-list=' \
# system targets
# (https://sources.debian.org/src/qemu/buster/debian/rules/#L59-L63, slimmed)
			i386-softmmu x86_64-softmmu aarch64-softmmu arm-softmmu m68k-softmmu \
			mips64-softmmu mips64el-softmmu ppc64-softmmu riscv64-softmmu \
			sparc64-softmmu s390x-softmmu \
		' \
# let's point "firmware path" to Debian's value so we get access to "OVMF.fd" and friends more easily
		--firmwarepath=/usr/share/qemu:/usr/share/seabios:/usr/lib/ipxe/qemu \
# https://salsa.debian.org/qemu-team/qemu/-/blob/058ab4ec8623766b50055c8c56d0d5448d52fb0a/debian/rules#L38
		--disable-docs \
		--disable-gtk --disable-vte \
		--disable-sdl \
		--enable-attr \
		--enable-bzip2 \
		--enable-cap-ng \
		--enable-curl \
		--enable-curses \
		--enable-fdt \
		--enable-gnutls \
		--enable-kvm \
		--enable-libiscsi \
		--enable-libnfs \
		--enable-libssh \
		--enable-libusb \
		--enable-linux-aio \
		--enable-modules \
		--enable-numa \
		--enable-rbd \
		--enable-seccomp \
		--enable-tools \
		--enable-usb-redir \
		--enable-vhost-net \
		--enable-vhost-user \
		--enable-vhost-vsock \
		--enable-virtfs \
		--enable-vnc \
		--enable-vnc-jpeg \
		--enable-vnc-png \
		--enable-xen \
# rbd support is enabled, but "librbd1" is not included since it adds ~60MB and is version-sensitive (https://github.com/tianon/docker-qemu/pull/11#issuecomment-689816553)
#		--enable-vde \
# https://www.qemu.org/2021/08/22/fuse-blkexport/
		--enable-fuse \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	cd /; \
	rm -rf /usr/src/qemu; \
	\
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	find /usr/local \
		-type f \
		\( -executable -o -name '*.so' \) \
# rbd support is enabled, but "librbd1" is not included since it adds ~60MB and is version-sensitive (https://github.com/tianon/docker-qemu/pull/11#issuecomment-689816553)
		-not -name 'block-rbd.so' \
		-exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
# basic smoke test
	qemu-img --version

STOPSIGNAL SIGHUP

EXPOSE 22
EXPOSE 5900

COPY start-qemu /usr/local/bin/
CMD ["start-qemu"]
