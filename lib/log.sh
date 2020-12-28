#!/usr/bin/env bash

if [ -t 1 ]
then
	COLOR_ERROR='\033[0;31m'
	COLOR_SUCCESS='\033[0;32m'
	COLOR_WARN='\033[0;33m'
	COLOR_INFO='\033[0;94m'
	COLOR_DEFAULT='\033[0m'
else
	COLOR_ERROR='ERROR: '
	COLOR_SUCCESS='SUCCESS: '
	COLOR_WARN='WARNING: '
	COLOR_INFO=''
	COLOR_DEFAULT=''
fi


function fatal() {
	error "${1}"
	exit 1
}

function warn() {
	echo -e "${COLOR_WARN}${1}${COLOR_DEFAULT}"
}

function success() {
	echo -e "${COLOR_SUCCESS}${1}${COLOR_DEFAULT}"
}

function error() {
	echo -e "${COLOR_ERROR}${1}${COLOR_DEFAULT}"
}

function info() {
	echo -e "${COLOR_INFO}${1}${COLOR_DEFAULT}"
}

# Like info but replaces the current line
function info_replace() {
	if [ -t 1 ]
	then
		echo -ne '\033[2K\r'
		echo -ne "${COLOR_INFO}${1}${COLOR_DEFAULT}"
	else
		info "${1}"
	fi
}
