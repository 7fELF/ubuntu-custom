#!/usr/bin/env bash

[ -n "$DEBUG" ] && set -x
LIB_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

function import {
	local file="$LIB_ROOT/$1.sh"
	[ ! -f "$file" ] && echo "invalid import $1" && exit 1
	# shellcheck source=/dev/null
	source "$file"
}
