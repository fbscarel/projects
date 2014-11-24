#!/bin/bash
# minitoo.sh, 2014/11/11 10:06:21 fbscarel $

MINITOO_HOME="$( readlink -f $0 | sed 's/\/[^\/]*$//' | sed 's/\/[^\/]*$//' )"
PROGNAME="$( basename $0 )"
VERSION="1.0.0"

## file paths
#
LIB_DIR="$MINITOO_HOME/lib"
VAR_DIR="$MINITOO_HOME/var"
TMP_DIR="$MINITOO_HOME/var/tmp"
MINITOO_CONF="minitoo.conf"
PACKAGE_DIR="package.d"

## cross-module temporary files
#
DOC_DIRS="$TMP_DIR/.doc_dirs"
LOCALE_DIRS="$TMP_DIR/.locale_dirs"
DRACUT_MODULES="$TMP_DIR/.dracut_modules"
PACKAGE_KEYWORDS="$TMP_DIR/.pkg_keywords"

## assumed defaults, if unspecified
#
DEFAULT_CONF_DIR="$MINITOO_HOME/etc"
DEFAULT_BUILD_DIR="$MINITOO_HOME/var/build"
DEFAULT_DEPLOY_DIR="$MINITOO_HOME/var/deploy"
DEFAULT_PACKAGE_INSTALL="@base"

## default package keywords
#
KEYWORD_BASE="@base = baselayout busybox extlinux glibc kernel shadow sysvinit udev"


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# trap CTRL-C to avoid subprocesses getting out of control
trap sigint SIGINT

# load libraries
for lib in $( ls $LIB_DIR/* ); do . $lib; done

# check for parameters
while getopts "b:c:d:D:f:k:l:p:hsvy" opt; do
    case "$opt" in
        h) usage ;;
        b) build_dir=${OPTARG} ;;
        c) conf_dir=${OPTARG} ;;
        d) device=${OPTARG} ;;
        D) daemon_opts=${OPTARG} ;;
        f) deploy_dir=${OPTARG} ;;
        k) kernel_opts=${OPTARG} ;;
        l) locales=${OPTARG} ;;
        p) package_install=${OPTARG} ;;
        s) optsize=true ;;
        v) verbose=true ;;
        y) allyes=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# check for trailing parameters
        if [ -n "$1" ]; then
  echo "[!] Unrecognized trailing parameters on commandline."
  echo "[!] Check if you didn't forget to enclose parameters with double-quotes."
  exit 1
fi

# if not using a custom configuration directory, set default
[ -z "$conf_dir" ] && conf_dir="$DEFAULT_CONF_DIR" || check_dir $conf_dir
minitoo_conf="$conf_dir/$MINITOO_CONF"
package_dir="$conf_dir/$PACKAGE_DIR"

# load package files
for pkg in $( ls $package_dir/*.sh ); do . $pkg; done

# parse configuration file, do not override commandline options
[ -f "$minitoo_conf" ] && conf_parse || echo "[!] Configuration file $minitoo_conf not found, continuing..."

# if still unset, give default values to non-mandatory parameters
[ -z "$build_dir" ]       && build_dir="$DEFAULT_BUILD_DIR"
[ -z "$deploy_dir" ]      && deploy_dir="$DEFAULT_DEPLOY_DIR"
[ -z "$package_install" ] && package_install="$DEFAULT_PACKAGE_INSTALL"

# parse package keywords, expand '$package_install' variable
package_install="$( keyword_parse )"

# check if supplied directories exist
check_dir $build_dir
check_dir $deploy_dir

# if set, check whether supplied block device exists
[ -n "$device" ] && check_blockdev $device

# check if packages set for installation are registered in the program
pkg_check "$package_install"

# parse kernel options and check for validity
if [ -n "$kernel_opts" ]; then
  kopts_parse
  [ -n "$kver" ]    && check_dir /usr/src/linux-$kver
  [ -n "$kconfig" ] && check_file $kconfig
fi

# check locale list for validity
[ -n "$locales" ] && locale_parse "$locales"

# remove tempfiles prior to package installation
rm -f $DOC_DIRS $LOCALE_DIRS $DRACUT_MODULES 2> /dev/null

echo "[*] minitoo-$VERSION: Starting operation. Invoke with '-h' for detailed help."

# if $device is set, prompt user, format and mount target device
if [ -n "$device" ]; then
  if check_yes "[*] We're now going to format device $device . Go ahead? (y/n) "; then exit_generic; fi
  disk_prep $device $build_dir
else
  if check_yes "[*] No device set. Installation will be done directly to $build_dir . Continue? (y/n) "; then exit_generic; fi
fi

# recursively resolve dependencies between packages, return ordered list
check_verb "[*] Processing package list..."
pkg_order "$package_install"

# go through ordered package list, install each one
check_verb "[*] Installing packages and dependencies on $build_dir ..."
pkg_install $build_dir $conf_dir "$package_install"

check_verb "[*] Syncing content between $deploy_dir and $build_dir ..."
rsync -a $deploy_dir/ $build_dir/

check_verb "[*] Performing post-installation configuration..."
post_install

if [ -n "$daemon_opts" ]; then
  check_verb "[*] Configuring daemon startup options..."
  daemon_config
fi

if [ -n "$locales" ]; then
  check_verb "[*] Removing unwanted locales..."
  locale_remove "$locales"
fi

if [ "$optsize" == true ]; then
  check_verb "[*] Performing size optimizations..."
  size_opts
fi

check_verb "[*] Finished. No error reported."
