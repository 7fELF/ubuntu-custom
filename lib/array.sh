#!/usr/bin/env bash

function array_join { local IFS="$1"; shift; echo "$*"; }
