#!/usr/bin/env bash
# usage.sh, 2014/11/24 09:19:36 fbscarel $

## show program usage
## placed on separate file for readability
#
function usage() {
  echo "Usage: $( basename $0 ) [-b BUILD_DIR] [-c CONFIG_DIR] [-d DEVICE]" 1>&2
  echo "                  [-D DAEMONS] [-f DEPLOYFILES_DIR] [-k KERNEL_OPTS]"
  echo "                  [-l LOCALES] [-p PACKAGES] [-s] [-v] [-y]"
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
  echo "  -D          Add and/or delete DAEMONS to the installed minimal system boot."
  echo "              This set of commands is run on a chroot, calling 'rc-update' to"
  echo "              perform the desired changes."
  echo
  echo "              The parameter to this option is a string on a fixed format, as"
  echo "              shown in the example below:"
  echo
  echo "                -D \"a:dbus@boot net.enp0s8 xdm,d:netmount swap swapfiles\""
  echo
  echo "              The character 'a' followed by a colon indicates the daemons that"
  echo "              should be (A)dded to system boot. If no runlevel is indicated, the"
  echo "              daemon will be added to the 'default' runlevel. Otherwise, set"
  echo "              the desired runlevel with using a '@' character, as shown with the"
  echo "              'dbus' daemon above."
  echo
  echo "              The character 'd' followed by a colon indicated the daemons that"
  echo "              should be (D)eleted from system boot. There's no need to specify a"
  echo "              runlevel in this case, Minitoo will auto-detect."
  echo
  echo "              (A)dd targets will be processed BEFORE (D)elete targets. If the"
  echo "              same daemon is present in both lists, it will ultimately be kept"
  echo "              in a deleted state."
  echo
  echo "              You should separate the 'a' (Add) and 'd' (Delete) daemon lists"
  echo "              with a comma (','), as shown in the example above. Daemon names"
  echo "              inside each list are separated by spaces. If no option is set,"
  echo "              default daemon startup options will not be changed. This option can"
  echo "              be set via configuration file."
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
  echo "  -l          Keep only the specified LOCALES installed on the minimal system."
  echo "              All locales EXCEPT the ones on this list will be REMOVED from the"
  echo "              target system."
  echo "              Locales should be specified as a space-separated list, surrounded"
  echo "              by double-quotes. Valid locales follow the format:"
  echo
  echo "                language_TERRITORY"
  echo
  echo "              For example:"
  echo
  echo "                de_BE"
  echo "                en_US"
  echo "                es_ES"
  echo "                pt_BR"
  echo
  echo "              Consult the file 'etc/locales' for a list of valid locales,"
  echo "              largely based on the official '/usr/share/i18n/SUPPORTED' file."
  echo
  echo "              The 'en_US' locale will always be kept for compatibility"
  echo "              purposes. If unspecified, all locales will be kept in the"
  echo "              minimal system. Can be set via configuration file."
  echo
  echo "  -p          Install PACKAGES on the minimal system. This option should be"
  echo "              a space-separated list of packages or package keywords to"
  echo "              install, surrounded by double-quotes. Package keywords can be"
  echo "              defined in the 'etc/minitoo.conf' configuration file, using the"
  echo "              'PACKAGE_KEYWORDS' parameter. The full list of packages"
  echo "              available for installation can be found in the 'etc/package.d'"
  echo "              directory. If unspecified, the following keyword will be"
  echo "              installed by default:"
  echo
  echo "                @base"
  echo
  echo "              This keyword defines the installation of the following"
  echo "              packages:"
  echo
  echo "                baselayout busybox extlinux glibc kernel shadow sysvinit udev"
  echo
  echo "              Additional packages could be selected via commandline using the"
  echo "              following example:"
  echo
  echo "                -p \"@base xorg xmisc fluxbox\""
  echo
  echo "              Conversely, you can install a subset of the base packages with:"
  echo
  echo "                -p \"busybox glibc kernel sysvinit\""
  echo
  echo "              WARNING: if you opt to skip crucial packages (for example, the"
  echo "              kernel or an init system) your system could become unbootable."
  echo "              This parameter can be set via configuration file."
  echo
  echo "  -s          Optimize for size. This option will trigger the removal of all"
  echo "              documentation directories (/usr/share/{doc,gtk-doc,info,man}),"
  echo "              Python objects (*.pyc and *.pyo files), use squashfs to"
  echo "              compress non-critical directories (such as /opt or /usr, for"
  echo "              example), among other optimizations."
  echo
  echo "  -v          Toggle verbose mode."
  echo
  echo "  -y          Answer 'yes' to all questions. Important changes, such as disk"
  echo "              formatting and file overwrites, WILL BE COMMITTED without"
  echo "              confirmation. Only use this option if you're absolutely sure"
  echo "              your parameters are correct."
  exit 1
}
