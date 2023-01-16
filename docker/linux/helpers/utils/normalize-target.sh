#!/usr/bin/env bash

. normalized-ids.sh

contains() {
	local target="$1"
	shift
	local arr="$@"
	[[ "$arr" =~ (^|[[:space:]])$target($|[[:space:]]) ]]
}

normalized() {
	local amd64_aliases="amd64 x86_64 x64"
	local arm64_aliases="arm64 aarch64 armv8-a armv8-m armv8-r"
	#local ia32_aliases="x86 ia32"
	#local arm_aliases="arm armv7 armv7l"

	local l_target=$TARGET
	if [ "${#1}" -le 5 -a "${#1}" -ge 3 ]; then
		l_target="$1"
	fi

	if contains $l_target "$amd64_aliases"; then
		echo "$amd64_normalized"
	elif contains $l_target "$arm64_aliases"; then
		echo "$arm64_normalized"
	#elif contains $l_target "$ia32_aliases"; then
	#	echo "$ia32_normalized"
	#elif contains $l_target "$arm_aliases"; then
	#	echo "$arm_normalized"
	else
		echo "Error: invalid target specified ( $l_target )" 1>&2
		exit 1
	fi
	echo "${lTargets[0]}"
}

has_kind() {
	local normalized_t="$(normalized)"
	contains $1 "$normalized_t"
}

has_only() {
	local normalized_t="$(normalized)"
	[ $1 = "$normalized_t" ]
}

if [ "$1" = "normalized" ]; then
	shift
	normalized "$@"
elif [ "$1" = "has_kind" ]; then
	shift
	has_kind "$@"
elif [ "$1" = "has_only" ]; then
	shift
	has_only "$@"
elif [ "$1" = "silent" ]; then
	shift
else
	cat <<EOF
	normalize-targets.sh [normalized|has_kind|has_only]
	USAGE:
		normalize-targets.sh normalized
			Parse the [TARGETS] environment variable and return
			a deduplicated list of just cpu archetecture names
			used and supported internally

		normalize-targets.sh has_kind [target]
			Return or fail if the normalized target list includes the
			specified target

		normalize-targets.sh has_only [target]
			Retrun or fail depending on whether there is only the
			specified target in the list
EOF
fi
