#!/bin/bash
# vmib.sh, 2014/11/11 10:06:21 fbscarel $

VMIB_HOME="$( readlink -f $0 | sed 's/\/[^\/]*$//' | sed 's/\/[^\/]*$//' )"
PROGNAME="$( basename $0 )"
VERSION="1.0.0"

## file paths
#
FILE_UTILS="$VMIB_HOME/lib/file.sh"
PACKAGE_UTILS="$VMIB_HOME/lib/package.sh"
VMIB_CONF="vmib.conf"

## assumed defaults, if unspecified
#
DEFAULT_BUILD_DIR="$VMIB_HOME/var/build"
DEFAULT_CONF_DIR="$VMIB_HOME/etc"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## parse configuration file for parameters
#
parse_conf() {
  [ -z "$build_dir" ]        && build_dir="$( getparam BUILD_DIR $vmib_conf )"
  [ -z "$device" ]           && device="$( getparam DEVICE $vmib_conf )"
  [ -z "$deploy_dir" ]       && deploy_dir="$( getparam DEPLOY_DIR $vmib_conf )"
  [ -z "$install_packages" ] && install_packages="$( getparam INSTALL_PACKAGES $vmib_conf )"

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
  echo "option), the file can be found in 'etc/vmib.conf'."
  echo
  echo "Available options:"
  echo "  -b          Use BUILD_DIR as mountpoint for the device specified with the"
  echo "              '-d' option. If unspecified, the 'var/build' directory will"
  echo "              be used by default. Can be set via configuration file."
  echo "  -c          Use CONFIG_DIR as the configuration directory to control"
  echo "              Portage and VMIB execution. Be careful: if you specify an"
  echo "              alternate configuration directory, the program will expect all"
  echo "              relevant configuration files (for VMIB, Portage and deployment)"
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
  echo "              'deploy/home/user/file'. If unspecified, the 'etc/deploy'"
  echo "              directory will be used by default. Can be set via configuration"
  echo "              file."
  echo "  -p          Install PACKAGES on the minimal system. This option should be"
  echo "              a comma-separated list of packages to install. Check the"
  echo "              'lib/package.sh' file to see the packages available for"
  echo "              installation. WARNING: if you opt to skip crucial packages"
  echo "              (for example, the kernel or an init system) your system could"
  echo "              become unbootable. Can be set via configuration file."
  echo "  -v          Toggle verbose mode."
  exit 1
}


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


. $PACKAGE_UTILS

# check for parameters
while getopts "b:c:d:f:p:hv" opt; do
    case "$opt" in
        h) usage ;;
        b) build_dir=${OPTARG} ;;
        c) conf_dir=${OPTARG} ;;
        d) device=${OPTARG} ;;
        f) deploy_dir=${OPTARG} ;;
        p) install_packages=${OPTARG} ;;
        v) verbose=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# if not using a custom configuration directory, set default
[ -z "$conf_dir" ] && conf_dir="$DEFAULT_CONF_DIR"
vmib_conf="$conf_dir/$VMIB_CONF"

# parse configuration file, do not override commandline options
[ -f "$vmib_conf" ] && parse_conf || echo "[!] Configuration file $vmib_conf not found, continuing..."
