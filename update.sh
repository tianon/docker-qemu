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
done
