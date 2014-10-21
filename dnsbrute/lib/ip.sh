#!/usr/bin/env bash
# ip.sh, 2014/10/21 15:00:13 fbscarel $

## IP/DNS utility functions for all scripts in this package 
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


## test port number for validity
#
validport() {
  if [[ ! $1 =~ ^[0-9]*$ ]]; then
    return 1
  elif [ "$1" -lt 1 ] || [ "$1" -gt 65535 ]; then
    return 1
  fi
  return 0
}


## remove CNAME records from $1, keep only IP addresses
nocname() {
  local retval=""

  for record in $1; do
    if validip $record; then retval="$retval $record"; fi
  done

  echo "$retval" | sed "s/^ //"
}
