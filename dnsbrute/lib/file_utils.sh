#!/usr/bin/env bash
# file_utils.sh, 2014/10/21 15:01:12 fbscarel $

## file-related utility functions for all scripts in this package
#

## get configuration value $1 from file $2, with variable delimiter support
#
getparam() {
  local delim="$( egrep "^$1" $2 | sed "s/^$1//" )"
  echo "$( egrep "^$1" $2 | sed "s/.*${delim:0:1} *\(.*\)/\1/" )"
}


## check if supplied file exists, bail if it doesn't
#
check_file() {
  if [ ! -f "$1" ]; then
    echo "[!] File $1 not found, terminating."
    exit 1
  fi  
}


## check if supplied directory exists, bail if it doesn't
#
check_dir() {
  if [ ! -d "$1" ]; then
    echo "[!] Directory $1 not found, terminating."
    exit 1
  fi
}


## check if supplied mail address is valid
#
check_mail(){
  local IFS="@"

  set -- $1
  [ "${#@}" -ne 2 ] && return 1
  domain="$2"
  dig $domain | grep "ANSWER: 0" 1> /dev/null && return 1

  return 0
}


## check if line $1 is led by a comment sign, or is a blank line
#
check_comment() {
  [[ "$1" =~ ^#.*$ ]] && return 0
  [[ "$1" =~ ^[:space:]*$ ]] && return 0
  return 1
}
