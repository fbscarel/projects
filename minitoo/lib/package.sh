#!/usr/bin/env bash
# package.sh, 2014/11/11 13:40:52 fbscarel $

## functions dealing with package checks and installation
#

## check if space-separated package list $1 contains only valid packages
#
function check_packages() {
  local function=""

  for function in $1; do
    local retval="$( type -t do_$function )"

    if [ "$retval" != "function" ]; then
      echo "[!] Unknown package $function, terminating."
      echo "[!] Please double-check your package list and try again."
      exit 1
    fi
  done
}
