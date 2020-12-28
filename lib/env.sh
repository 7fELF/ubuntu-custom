#!/usr/bin/env bash

function set_default {
	local -n var="$1"
	local default="$2"

	if [ -z "$var" ]
	then
		info "$(printf "%-12s" "$1") \"$default\" (default) "
		var="$default"
	else
		info "$(printf "%-12s" "$1") \"$var\" (set from environemnt)"
	fi
}
