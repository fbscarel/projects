#!/usr/bin/env bash
# file.sh, 2014/10/29 10:30:37 fbscarel $

## file-related utility functions for all scripts in this package
#

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
