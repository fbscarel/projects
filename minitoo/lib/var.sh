#!/usr/bin/env bash
# var.sh, 2014/11/12 14:40:52 fbscarel $

## utility functions to manipulate variables, functions and variable content
#

## check if we're running on verbose mode, print $1 if true
#
function check_verb() {
  [ "$verbose" == true ] && echo "$1"
}


## check if user answers 'yes' to question $1
#
function check_yes() {
  [ "$allyes" == true ] && return 1

  local opt=""
  while true; do
    echo -n "$1"
    read opt

    opt="$( echo "$opt" | tr '[:upper:]' '[:lower:]' )"
    if [ "$opt" == "y" ]; then
      return 1
    elif [ "$opt" == "n" ]; then
      return 0
    else
      echo "[!] Invalid option, please answer 'y' or 'n'."
    fi
  done
}


## check if string $1 is a function
#
function check_function() {
  [ "$( type -t "$1" )" == "function" ] && return 0 || return 1
}


## terminate program with generic message
#
function exit_generic() {
  echo "[!] Terminating due to user input."
  exit 1
}


## show options $1, $2, $3... to user, output selection
## question to ask is on last parameter
#
function check_opts() {
  nopts=$( expr $# - 1 )

  for (( i=1 ; i<=$nopts ; i++ )); do
    echo "     [$i] $1"
    shift
  done

  while true; do
    echo -n "$1"
    read opt

    if [[ ! $opt =~ ^-?[0-9]+$ ]] || [ $opt -lt 1 ] || [ $opt -gt $nopts ]; then
      echo "[!] Invalid option, pleasy type an integer between 1 and $nopts."
    else
      return $opt
    fi
  done
}


## treat SIGINT interrupts
#
function sigint() {
  echo "[!] Detected SIGINT from user. Terminating abruptly."
  exit 1
}


## parse kernel options passed via commandline
#
function kopts_parse() {
  local IFS=" "

  set -- $kernel_opts
  kver="$1"
  kconfig="$2"
}
