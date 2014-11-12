#!/bin/bash
# minitoo.sh, 2014/11/11 10:06:21 fbscarel $

MINITOO_HOME="$( readlink -f $0 | sed 's/\/[^\/]*$//' | sed 's/\/[^\/]*$//' )"
PROGNAME="$( basename $0 )"
VERSION="1.0.0"

## file paths
#
DISK_UTILS="$MINITOO_HOME/lib/disk.sh"
FILE_UTILS="$MINITOO_HOME/lib/file.sh"
PACKAGE_UTILS="$MINITOO_HOME/lib/package.sh"
MINITOO_CONF="minitoo.conf"
PACKAGE_DIR="package.d"

## assumed defaults, if unspecified
#
DEFAULT_CONF_DIR="$MINITOO_HOME/etc"
DEFAULT_BUILD_DIR="$MINITOO_HOME/var/build"
DEFAULT_DEPLOY_DIR="$MINITOO_HOME/var/deploy"
DEFAULT_INSTALL_PACKAGES="baselayout busybox extlinux glibc kernel pam sysvinit udev"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## parse configuration file for parameters
#
function parse_conf() {
  [ -z "$build_dir" ]        && build_dir="$( getparam BUILD_DIR $minitoo_conf )"
  [ -z "$device" ]           && device="$( getparam DEVICE $minitoo_conf )"
  [ -z "$deploy_dir" ]       && deploy_dir="$( getparam DEPLOY_DIR $minitoo_conf )"
  [ -z "$install_packages" ] && install_packages="$( getparam INSTALL_PACKAGES $minitoo_conf )"

  return 0
}


## show program usage and exit
#
function usage() {
  echo "Usage: $( basename $0 ) -d DEVICE [-b BUILD_DIR] [-c CONFIG_DIR]" 1>&2
  echo "                    [-f DEPLOYFILES_DIR] [-p PACKAGES] [-v]"
  echo "Build a minimal system on BUILD_DIR using Gentoo's Portage system. You can"
  echo "customize the system via various configuration flags, explained below."
  echo
  echo "Some program parameters can be set via configuration file, as explained below."
  echo "Unless you re-locate the default configuration directory (using the '-c'"
  echo "option), the file can be found in 'etc/minitoo.conf'."
  echo
  echo "Available options:"
  echo "  -b          Use BUILD_DIR as mountpoint for the device specified with the"
  echo "              '-d' option. If unspecified, the 'var/build' directory will"
  echo "              be used by default. Can be set via configuration file."
  echo "  -c          Use CONFIG_DIR as the configuration directory to control"
  echo "              Portage and MINITOO execution. Be careful: if you specify an"
  echo "              alternate configuration directory, the program will expect all"
  echo "              relevant configuration files (for MINITOO, Portage and deployment)"
  echo "              to be found on the new directory. If unspecified, the 'etc/'"
  echo "              directory will be used by default."
  echo "  -d          Use DEVICE as target for the minimal system. This parameter"
  echo "              must be a valid hard disk on the '/dev' directory. WARNING: the"
  echo "              hard disk (for example, '/dev/sdb') will be COMPLETELY wiped,"
  echo "              and we'll create a single partition spanning the whole disk."
  echo "              The MBR code will also be OVERWRITTEN, so be careful."
  echo "              This parameter is mandatory, unless specified via configuration"
  echo "              file."
  echo "  -f          Use DEPLOYFILES_DIR as template, copying its files to the"
  echo "              minimal system, verbatim. This option can be used to customize"
  echo "              your system post-installation. Keep in mind this directory must"
  echo "              emulate the root ('/') filesystem structure; that is, if you"
  echo "              want to copy a file to the '/home/user' directory, this file"
  echo "              must exist inside the deploy directory as"
  echo "              'deploy/home/user/file'. If unspecified, the 'var/deploy'"
  echo "              directory will be used by default. Can be set via configuration"
  echo "              file."
  echo "  -p          Install PACKAGES on the minimal system. This option should be"
  echo "              a comma-separated list of packages to install. Check the"
  echo "              'lib/package.sh' file to see the packages available for"
  echo "              installation. WARNING: if you opt to skip crucial packages"
  echo "              (for example, the kernel or an init system) your system could"
  echo "              become unbootable. Can be set via configuration file."
  echo "  -v          Toggle verbose mode."
  echo "  -y          Answer 'yes' to all questions. Important changes, such as disk"
  echo "              formatting and file overwrites, WILL BE COMMITTED without"
  echo "              confirmation. Only use this option if you're absolutely sure"
  echo "              your parameters are correct."
  exit 1
}


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


. $DISK_UTILS
. $FILE_UTILS
. $PACKAGE_UTILS

# check for parameters
while getopts "b:c:d:f:p:hvy" opt; do
    case "$opt" in
        h) usage ;;
        b) build_dir=${OPTARG} ;;
        c) conf_dir=${OPTARG} ;;
        d) device=${OPTARG} ;;
        f) deploy_dir=${OPTARG} ;;
        p) install_packages=${OPTARG} ;;
        v) verbose=true ;;
        y) allyes=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# if not using a custom configuration directory, set default
[ -z "$conf_dir" ] && conf_dir="$DEFAULT_CONF_DIR" || check_dir $conf_dir
minitoo_conf="$conf_dir/$MINITOO_CONF"
package_dir="$conf_dir/$PACKAGE_DIR"

# load package files
for file in $( ls $package_dir/*.sh ); do
  . $file
done

# parse configuration file, do not override commandline options
[ -f "$minitoo_conf" ] && parse_conf || echo "[!] Configuration file $minitoo_conf not found, continuing..."

# check mandatory options
[ -z "$device" ] && { echo "[!] Option '-d' is mandatory!"; usage; }

# if still unset, give default values to non-mandatory parameters
[ -z "$build_dir" ]        && build_dir="$DEFAULT_BUILD_DIR"
[ -z "$deploy_dir" ]       && deploy_dir="$DEFAULT_DEPLOY_DIR"
[ -z "$install_packages" ] && install_packages="$DEFAULT_INSTALL_PACKAGES"

# check if supplied directories exist
check_dir $build_dir
check_dir $deploy_dir

# check if supplied block devices exist
check_blockdev $device

# check if packages set for installation are registered in the program
check_packages "$install_packages"

check_verb "[*] minitoo-$VERSION: Starting operation."

# prompt user, format and mount target device
check_yes "[*] We're now going to format device $device . Go ahead? (y/n) "
disk_prep $device $build_dir
