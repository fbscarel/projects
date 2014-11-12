#!/usr/bin/env bash
# package.sh, 2014/11/11 13:40:52 fbscarel $

## functions dealing with package checks and installation
#

## check if space-separated package list $1 contains only valid packages
#
function check_packages() {
  local function=""

  for function in $1; do
    if ! check_function "pkg_${function}" &&
       ! check_function "pkg_${function}_hook"; then
      echo "[!] Unknown package $function, terminating."
      echo "[!] Please double-check your package list and try again."
      exit 1
    fi
  done
}


## install each of the packages contained in list $3 on target $1, using
## configuration parameters from directory $2
#
function package_install() {
  local config_root="$( echo $2 | sed 's\[/]*etc[/]*$\\' )"
  [ -z "$config_root" ] && config_root="."

  local function=""
  for function in $3; do
    # clear global vars
    USE=""
    packages=""

    # check if this function has packages to install
    if check_function "pkg_${function}"; then
      pkg_${function}
      [ -n "$packages" ] && USE="$USE" emerge -bkq --quiet-build --config-root=$config_root --root=$1 "$packages"
    fi

    # check if there's a hook function to run
    if check_function "pkg_${function}_hook"; then
      pkg_${function}_hook
    fi
  done
}
