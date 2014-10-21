#!/usr/bin/env bash
# util.sh, 2014/09/24 08:22:07 fbscarel $

## utility functions for all scripts in this directory
#

## echo out class B/C ranges for ip
#
function echo_range() {
  # get class-B/C range
  local bip="$( echo $1 | sed 's/[^.]*.[^.]*$/0.0/' )"
  local cip="$( echo $1 | sed 's/[^.]*$/0/' )"

  # check if ranges not already in file
  echo "$bip $cip $1"
}


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


## test IP address for validity
## http://www.linuxjournal.com/content/validating-ip-address-bash-script
#
validip() {
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
  fi
  return $stat
}


## remove CNAME records from $1, keep only IP addresses
nocname() {
  local retval=""

  for record in $1; do
    if validip $record; then retval="$retval $record"; fi
  done

  echo "$retval" | sed "s/^ //"
}


## check if line $1 is led by a comment sign, or is a blank line
#
check_comment() {
  [[ "$1" =~ ^#.*$ ]] && return 0
  [[ "$1" =~ ^[:space:]*$ ]] && return 0
  return 1
}
