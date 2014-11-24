#!/usr/bin/env bash
# package.sh, 2014/11/11 13:40:52 fbscarel $

## functions dealing with package checks and installation
#

## check if space-separated package/dependency list $1 contains only valid
## packages
## $2 may contain, optionally, the function where an error was found
#
function pkg_check() {
  local function=""

  for function in $1; do
    if ! check_function "pkg_${function}" &&
       ! check_function "pkg_${function}_depends" &&
       ! check_function "pkg_${function}_hook"; then
      echo -n "[!] Unknown package $function"
      if [ -n "$2" ]; then
        echo " on file $conf_dir/etc/package.d/${2}.sh ."
      else
        echo "."
        echo "[!] Please double-check your package list and try again."
      fi
      exit 1
    fi
  done
}


## install each of the packages contained in list $3 on target $1, using
## configuration parameters from directory $2
#
function pkg_install() {
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
      if [ -n "$packages" ]; then
        check_verb "[*] Installing package $function ..."
        
        local instok=0
        local amask=0
        local emerge_opts="-bkq --quiet-build --binpkg-respect-use=y"
        local emerge_config="--config-root=$config_root"
        local emerge_target="--root=$1"

        while [ $instok -eq 0 ]; do

          USE="$USE" emerge $emerge_opts $emerge_config $emerge_target $packages
          if [ "$?" -eq 0 ]; then
            instok=1

          else
            
            # try --autounmask-write, in case we have package masking issues
            if [ $amask -eq 0 ]; then
              emerge_opts="$emerge_opts --autounmask-write"
              amask=1
            
            # --autounmask-write returns 1, so we have to re-loop removing autounmask
            elif [ $amask -eq 1 ]; then
              emerge_opts="${emerge_opts% --autounmask-write}"
              amask=2
            
            # autounmask didn't work, error out
            else
              echo "[!] Error installing package $function ."
              echo "[!] Check emerge output above for the detailed error report."
              echo
              if check_yes "[*] Continue program execution? (y/n) "; then
                exit 1
              elif check_yes "[*] Run hooks for package $function, despite installation errors? (y/n) "; then
                return
              else
                break
              fi
            fi
          fi
        done
      fi
    fi

    # check if there's a hook function to run
    if check_function "pkg_${function}_hook"; then
      check_verb "[*] Running hooks for package $function ..."
      pkg_${function}_hook
    fi
  done
}


## receive the unordered list of packages $1, resolve dependencies between all
## packages, and output an ordered list of packages for installation
##
## the 'tsort' command is used to implement topological sorting on the
## package list while checking dependencies, a well-known method for sorting
## directed acyclic graphs (DAGs)
#
function pkg_tsort() {
  local function=""
  local deplist=""
  local dep=""

  for function in $1; do

    # if there's a depend function, inspect it
    if check_function "pkg_${function}_depends"; then
      depends=""
      pkg_${function}_depends
      
      # change $depends context from global to local
      deplist="$depends"

      # avoid bogus (empty/whitespace-only) dependencies
      if [ -z "$deplist" ] || [[ "$deplist" =~ ^[[:space:]]+$ ]]; then
        echo "PKG_NODEP $function" >> $pkgfile

      else
        # check if the dependency list only contains valid packages
        pkg_check "$deplist" "$function"

        # recursively resolve dependency list and write graph edges to file
        for dep in $deplist; do
          if ! grep "$dep" $pkgfile &> /dev/null ; then pkg_tsort "$dep"; fi
          echo "$dep $function" >> $pkgfile
        done
      fi

    # otherwise, inform this package has no dependencies
    else
      echo "PKG_NODEP $function" >> $pkgfile
    fi
  done
}


## relay package list $1 to pkg_tsort() for recursive dependency resolution
## and topological sorting; writes sorted list to global variable
## $package_install, space-separated
#
function pkg_order() {
  pkgfile="$TMP_DIR/.pkg_order"
  local tmpfile="$TMP_DIR/.tmp_order"

  # ensure our pkg list file is empty, and exists
  rm -f $pkgfile ; touch $pkgfile

  # recursively resolve dependencies on package list
  pkg_tsort "$1"

  # sort and write ordered package list, checking for loop errors
  if tsort $pkgfile > $tmpfile ; then
    package_install="$( cat $tmpfile | sed '/^PKG_NODEP/d' | paste -s -d' ')"
  else
    echo "[!] There was an error while resolving package dependencies."
    echo "[!] Please review 'tsort' output above and check your package '_depends' functions."
    exit 1
  fi
}
