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
  [ "$allyes" == true ] && return 0

  local opt=""
  while true; do
    echo -n "$1"
    read opt

    opt="$( echo "$opt" | tr '[:upper:]' '[:lower:]' )"
    if [ "$opt" == "y" ]; then
      return 1;
    elif [ "$opt" == "n" ]; then
      echo "[*] Terminating due to user input."
      exit 1
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
