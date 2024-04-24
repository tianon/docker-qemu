#!/usr/bin/env bash
set -Eeuo pipefail

declare -A aliases=(
	[9.0]='9 latest'
	[8.2]='8'
	[7.2]='7'
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

# sort version numbers with highest first
IFS=$'\n'; versions=( $(echo "${versions[*]}" | sort -rV) ); unset IFS

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		files="$(
			git show HEAD:./Dockerfile HEAD:./Dockerfile.native | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						if ($i ~ /^--from=/) {
							next
						}
						print $i
					}
				}
			'
		)"
		fileCommit Dockerfile Dockerfile.native $files
	)
}

getArches() {
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -g -A parentRepoToArches=( $(
		find -name 'Dockerfile*' -exec awk '
				toupper($1) == "FROM" && $2 !~ /^(scratch|.*\/.*)(:|$)/ {
					print "'"$officialImagesUrl"'" $2
				}
			' '{}' + \
			| sort -u \
			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
	) )"
}
getArches

cat <<-EOH
# this file is generated via https://github.com/tianon/docker-qemu/blob/$(fileCommit "$self")/$self

Maintainers: Tianon Gravi <admwiggin@gmail.com> (@tianon)
GitRepo: https://github.com/tianon/docker-qemu.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version; do
	fullVersion="$(jq -r --arg version "$version" '.[$version].version' versions.json)"

	rcVersion="${version%-rc}"

	versionAliases=()
	while [ "$fullVersion" != "$rcVersion" -a "${fullVersion%[.]*}" != "$fullVersion" ]; do
		versionAliases+=( $fullVersion )
		fullVersion="${fullVersion%[.]*}"
	done
	versionAliases+=(
		$version
		${aliases[$version]:-}
	)

	commit="$(dirCommit "$version")"

	for variant in '' native; do
		variantAliases=( "${versionAliases[@]}" )
		if [ -n "$variant" ]; then
			variantAliases=( "${variantAliases[@]/%/-$variant}" )
			variantAliases=( "${variantAliases[@]//latest-/}" )
		fi

		variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$version/Dockerfile${variant:+.$variant}")"

		suite="${variantParent#*:}" # "buster-slim", "buster"
		suite="${suite%-slim}" # "buster"
		suiteAliases=( "${variantAliases[@]/%/-$suite}" )
		suiteAliases=( "${suiteAliases[@]//latest-/}" )
		variantAliases+=( "${suiteAliases[@]}" )

		case "$variant" in
			'') variantArches='amd64' ;; # only make the "fat" variant on amd64
			*) variantArches="${parentRepoToArches[$variantParent]}" ;;
		esac

		# skip i386 (missing many packages, like libxen-dev; not something I actually care to target)
		variantArches="$(sed -e 's/ i386 / /g' <<<" $variantArches ")"

		# architectures I don't think make sense to or I don't care to support
		variantArches="$(sed -e 's/ arm32v5 / /g' <<<" $variantArches ")"
		variantArches="$(sed -e 's/ mips64le / /g' <<<" $variantArches ")"
		variantArches="$(sed -e 's/ ppc64le / /g' <<<" $variantArches ")"
		variantArches="$(sed -e 's/ s390x / /g' <<<" $variantArches ")"

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: $(join ', ' $variantArches)
			GitCommit: $commit
			Directory: $version
		EOE
		if [ -n "$variant" ]; then
			echo "File: Dockerfile.$variant"
		fi
	done
done
