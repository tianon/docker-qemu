#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

# https://download.qemu.org/?C=M;O=D
urls="$(
	wget -qO- 'https://www.qemu.org/download/' \
		| grep -oE 'https://download[.]qemu[.]org/qemu-([^"]+)[.]tar[.]xz' \
		| sort -ruV
)"

for version in "${versions[@]}"; do
	rcGrepV='-v'
	rcVersion="${version%-rc}"
	if [ "$rcVersion" != "$version" ]; then
		rcGrepV=
	fi

	url="$(
		grep -E "qemu-$rcVersion([.-])" <<<"$urls" \
			| grep $rcGrepV -E -- '-rc' \
			| head -1
	)"
	fullVersion="${url##*/qemu-}"
	fullVersion="${fullVersion%%.tar.*}"

	echo "$version: $fullVersion"

	sed -r \
		-e 's/%%QEMU_VERSION%%/'"$fullVersion"'/g' \
		-e 's!%%QEMU_URL%%!'"$url"'!g' \
		Dockerfile.template > "$version/Dockerfile"
	cp -a start-qemu *.patch "$version/"

	case "$rcVersion" in
		# https://github.com/qemu/qemu/commit/b10d49d7619e4957b4b971f816661b57e5061d71
		3.0 | 3.1 | 4.0)
			sed -ri \
				-e 's/libssh-dev/libssh2-1-dev/g' \
				-e 's/--enable-libssh/--enable-libssh2/g' \
				"$version/Dockerfile"
			;;
	esac
done
