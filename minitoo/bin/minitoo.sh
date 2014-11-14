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
VAR_UTILS="$MINITOO_HOME/lib/var.sh"
VAR_DIR="$MINITOO_HOME/var"
MINITOO_CONF="minitoo.conf"
PACKAGE_DIR="package.d"

## assumed defaults, if unspecified
#
DEFAULT_CONF_DIR="$MINITOO_HOME/etc"
DEFAULT_BUILD_DIR="$MINITOO_HOME/var/build"
DEFAULT_DEPLOY_DIR="$MINITOO_HOME/var/deploy"
DEFAULT_INSTALL_PACKAGES="baselayout busybox extlinux glibc kernel shadow sysvinit udev"


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


## parse kernel options passed via commandline
#
function parse_kopts() {
  local IFS=" "

  set -- $kernel_opts
  kver="$1"
  kconfig="$2"
}


## show program usage and exit
#
function usage() {
  echo "Usage: $( basename $0 ) [-b BUILD_DIR] [-c CONFIG_DIR] [-d DEVICE]" 1>&2
  echo "                  [-f DEPLOYFILES_DIR] [-p PACKAGES] [-v]"
  echo "Build a minimal system on BUILD_DIR using Gentoo's Portage system. You can"
  echo "customize the system via various configuration flags."
  echo
  echo "Some program parameters can be set via configuration file, as explained below."
  echo "Unless you re-locate the default configuration directory (using the '-c'"
  echo "option), the file can be found in 'etc/minitoo.conf'."
  echo
  echo "Available options:"
  echo
  echo "  -b          Use BUILD_DIR as the target installation directory. If a DEVICE"
  echo "              has been set with the '-d' option, the program will attempt to"
  echo "              format and mount the disk under BUILD_DIR. If unspecified, the"
  echo "              'var/build' directory will be used by default. Can be set via"
  echo "              configuration file."
  echo
  echo "  -c          Use CONFIG_DIR as the configuration directory to control"
  echo "              Portage and Minitoo execution. Be careful: if you specify an"
  echo "              alternate configuration directory, the program will expect all"
  echo "              relevant configuration files (for Minitoo, Portage and deployment)"
  echo "              to be found on the new directory. If unspecified, the 'etc/'"
  echo "              directory will be used by default."
  echo
  echo "  -d          Use DEVICE as target for the minimal system. This parameter"
  echo "              must be a valid hard disk on the '/dev' directory. WARNING: the"
  echo "              hard disk (for example, '/dev/sdb') will be COMPLETELY wiped,"
  echo "              and we'll create a single partition spanning the whole disk."
  echo "              The MBR code will also be OVERWRITTEN, so be careful. Can be set"
  echo "              via configuration file."
  echo
  echo "  -f          Use DEPLOYFILES_DIR as template, copying its files to the"
  echo "              minimal system, verbatim. This option can be used to customize"
  echo "              your system post-installation. Keep in mind this directory must"
  echo "              emulate the root ('/') filesystem structure; that is, if you"
  echo "              want to copy a file to the '/home/user' directory, this file"
  echo "              must exist inside the deploy directory as"
  echo "              'deploy/home/user/file'. If unspecified, the 'var/deploy'"
  echo "              directory will be used by default. Can be set via configuration"
  echo "              file."
  echo
  echo "  -k          Specify kernel parameters for the 'kernel' package to use during"
  echo "              installation. Available kernel parameters are: version and"
  echo "              configuration file. This parameter should be in the format"
  echo "              \"VERSION CONFIG_FILE_PATH\", that is, a space-separated list,"
  echo "              surrounded by double-quotes, containing the desired infomation."
  echo "              For example:"
  echo
  echo "                -k \"3.15.10-hardened-r1 /home/user/kconfig\""
  echo
  echo "              The example above will use the kernel located in the"
  echo "              '/usr/src/linux-3.15.10-hardened-r1' directory, with the"
  echo "              options set in the configuration file found in"
  echo "              '/home/user/kconfig'."
  echo
  echo "              If a kernel version is provided, but the custom configuration"
  echo "              file field is omitted, Minitoo will use the file found in"
  echo "              '/usr/src/linux-\$VERSION/.config'"
  echo
  echo "              This parameter is optional. If you invoke the installation of"
  echo "              the 'kernel' package without using the '-k' option, Minitoo"
  echo "              will use the kernel pointed to by the '/usr/src/linux' symlink,"
  echo "              and the configuration located in '/usr/src/linux/.config'."
  echo
  echo "  -p          Install PACKAGES on the minimal system. This option should be"
  echo "              a space-separated list of packages to install, surrounded by"
  echo "              double-quotes. The full list of packages available for"
  echo "              installation can be found in the 'etc/package.d' directory. If"
  echo "              unspecified, the following packages will be installed by"
  echo "              default:"
  echo
  echo "                baselayout busybox extlinux glibc kernel shadow sysvinit udev"
  echo
  echo "              A subset of the packages above could be selected via"
  echo "              commandline using the following example:"
  echo
  echo "                -p \"baselayout busybox glibc kernel sysvinit\""
  echo
  echo "              WARNING: if you opt to skip crucial packages"
  echo "              (for example, the kernel or an init system) your system could"
  echo "              become unbootable. This parameter can be set via configuration"
  echo "              file."
  echo
  echo "  -v          Toggle verbose mode."
  echo
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
. $VAR_UTILS

# check for parameters
while getopts "b:c:d:f:k:p:hvy" opt; do
    case "$opt" in
        h) usage ;;
        b) build_dir=${OPTARG} ;;
        c) conf_dir=${OPTARG} ;;
        d) device=${OPTARG} ;;
        f) deploy_dir=${OPTARG} ;;
        k) kernel_opts=${OPTARG} ;;
        p) install_packages=${OPTARG} ;;
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
for file in $( ls $package_dir/*.sh ); do
  . $file
done

# parse configuration file, do not override commandline options
[ -f "$minitoo_conf" ] && parse_conf || echo "[!] Configuration file $minitoo_conf not found, continuing..."

# if still unset, give default values to non-mandatory parameters
[ -z "$build_dir" ]        && build_dir="$DEFAULT_BUILD_DIR"
[ -z "$deploy_dir" ]       && deploy_dir="$DEFAULT_DEPLOY_DIR"
[ -z "$install_packages" ] && install_packages="$DEFAULT_INSTALL_PACKAGES"

# check if supplied directories exist
check_dir $build_dir
check_dir $deploy_dir

# if set, check whether supplied block device exists
[ -n "$device" ] && check_blockdev $device

# check if packages set for installation are registered in the program
check_packages "$install_packages"

# parse kernel options and check for validity
if [ -n "$kernel_opts" ]; then
  parse_kopts
  [ -n "$kver" ]    && check_dir /usr/src/linux-$kver
  [ -n "$kconfig" ] && check_file $kconfig
fi

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
package_order "$install_packages"

# go through ordered package list, install each one
check_verb "[*] Installing packages and dependencies on $build_dir ."
package_install $build_dir $conf_dir "$install_packages"

# copy over '$deploy_dir' contents to '$build_dir'
check_verb "[*] Syncing content between $deploy_dir and $build_dir ."
rsync -a $deploy_dir/ $build_dir/

check_verb "[*] Finished. No error reported."
