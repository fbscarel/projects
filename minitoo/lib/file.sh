#!/usr/bin/env bash
# file.sh, 2014/10/29 10:30:37 fbscarel $

## file-related utility functions for all scripts in this package
#

## parse configuration file for parameters
#
function conf_parse() {
  [ -z "$build_dir" ]       && build_dir="$( getparam BUILD_DIR $minitoo_conf )"
  [ -z "$daemon_opts" ]     && daemon_opts="$( getparam DAEMON_OPTS $minitoo_conf )"
  [ -z "$deploy_dir" ]      && deploy_dir="$( getparam DEPLOY_DIR $minitoo_conf )"
  [ -z "$device" ]          && device="$( getparam DEVICE $minitoo_conf )"
  [ -z "$package_install" ] && package_install="$( getparam PACKAGE_INSTALL $minitoo_conf )"
  [ -z "$locales" ]         && locales="$( getparam LOCALES $minitoo_conf )"

  return 0
}


## process and dereference package keywords to globalvar '$package_install'
#
function keyword_parse() {
  local expkw=""
  local pkg_tmpfile="$TMP_DIR/.pkg_tmpfile"

  echo "$KEYWORD_BASE" > $PACKAGE_KEYWORDS
  getparam PACKAGE_KEYWORDS $minitoo_conf >> $PACKAGE_KEYWORDS

  # remove duplicate keywords, keep only first declaration
  awk '!_[$1]++' FS=' ' $PACKAGE_KEYWORDS > $pkg_tmpfile
  mv $pkg_tmpfile $PACKAGE_KEYWORDS

  # expand keywords in $package_install
  for pkg in $package_install; do
    if [[ $pkg =~ @.* ]]; then
      expkw="$expkw $( getparam $pkg $PACKAGE_KEYWORDS )"
    else
      expkw="$expkw $pkg"
    fi
  done

  # remove duplicate packages, sort list alphabetically
  echo "$expkw" | sed 's/ /\n/g' | sort | uniq | paste -s -d' '
}


## get configuration value $1 from file $2, with variable delimiter support
#
function getparam() {
  egrep "^$1" $2 | sed "s/^$1 *. *['\"]\?\([^'\"]*\).*/\1/"
}


## check if supplied file exists, bail if it doesn't
#
function check_file() {
  if [ ! -f "$1" ]; then
    echo "[!] File $1 not found, terminating."
    exit 1
  fi  
}


## check if supplied directory exists, bail if it doesn't
#
function check_dir() {
  if [ ! -d "$1" ]; then
    echo "[!] Directory $1 not found, terminating."
    exit 1
  fi
}


## check if block device exists, bail if it doesn't
#
function check_blockdev() {
  if [ ! -b "$1" ]; then
    if [ ! -e "$1" ]; then
      echo "[!] Block device $1 not found, terminating."
    else
      echo "[!] File $1 is not a block device, terminating."
    fi
    exit 1
  fi
}


## check if supplied binary files exist, return as appropriate
#
function check_binaryexist() {
  # tricky pass-by-name to get array as parameter, check
  # http://stackoverflow.com/questions/16461656/bash-how-to-pass-array-as-an-argument-to-a-function
  local n=$1[@]
  local a=("${!n}")
  for file in "${a[@]}"; do
    local fpath=$( which $file 2> /dev/null )
    [ ! -z "$fpath" ] && return 0
  done

  return 1
}


## check if line $1 is led by a comment sign, or is a blank line
#
function check_comment() {
  [[ "$1" =~ ^#.*$ ]] && return 0
  [[ "$1" =~ ^[:space:]*$ ]] && return 0
  return 1
}
