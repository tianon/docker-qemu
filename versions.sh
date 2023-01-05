#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
	json='{}'
else
	json="$(< versions.json)"
fi
versions=( "${versions[@]%/}" )

# TODO https://gitlab.com/qemu-project/qemu-web/-/blob/master/_data/releases.yml ?

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

	export version fullVersion url
	json="$(jq <<<"$json" '
		.[env.version] = {
			version: env.fullVersion,
			url: env.url,
		}
	')"
done

jq <<<"$json" -S . > versions.json
