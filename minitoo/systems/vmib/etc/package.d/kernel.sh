#!/usr/bin/env bash

## Hook function to build and install kernel on $build_dir/boot .
## Kernel version and configuration file are available on global variables
## $kver and $kconfig, parsed from commandline.
#
function pkg_kernel_hook() {
  local archpath="arch/x86/boot"
  local build_boot="$build_dir/boot"

  # set defaults if not specified
  if [ -z "$kver" ]; then
   kpath="/usr/src/linux"
   kver="$( readlink -f $kpath | sed 's:.*/linux-\([^/]*\)$:\1:' )"
  else
   kpath="/usr/src/linux-$kver"
  fi

  [ -z "$kconfig" ] && local kconfig="$kpath/.config"

  # if no image found, build first
  if [ ! -f "$kpath/$archpath/bzImage" ]; then

    # no custom kconfig, no default config AND no image found -- no way
    while [ ! -f "$kconfig" ]; do
      echo "[!] No kernel image and kernel configuration found."
      if check_yes "[*] Launch 'make menuconfig' to create a .config file for this kernel? (y/n) "; then
        echo "[!] No .config available. Skipping kernel installation."
        return
      else
        ( cd $kpath ; make menuconfig )
      fi
    done

    check_verb "[*] No kernel image found, we'll build one."
    check_verb "[*] If using a .config for an older kernel version, 'make' may ask questions"
    check_verb "    regarding newly-introduced options. You can either answer them one by one,"
    check_verb "    or generate a .config for the new kernel version and re-run the script."

    # backup old config, if existing
    [ -f "$kpath/.config" ] && cp $kpath/.config $kpath/.config.old
    [ "$kconfig" != "$kpath/.config" ] && cp $kconfig $kpath/.config

    check_verb "[*] Compiling kernel $kver with configuration $kconfig ."
    ( cd $kpath ; make ; make INSTALL_MOD_PATH=$build_dir modules_install )
  fi

  # remove old(er) kimages, rename current to .old
  rm -f $build_boot/{map,config,vmlinuz}.old
  [ -f "$build_boot/map" ]     && mv $build_boot/map     $build_boot/map.old
  [ -f "$build_boot/config" ]  && mv $build_boot/config  $build_boot/config.old
  [ -f "$build_boot/vmlinuz" ] && mv $build_boot/vmlinuz $build_boot/vmlinuz.old

  # install kernel image, map and config to target /boot directory
  check_verb "[*] Installing kernel $kver to $build_boot ."
  mkdir -p $build_boot
  ( cd $kpath ; INSTALLKERNEL="installkernel" sh $kpath/$archpath/install.sh $kver $archpath/bzImage System.map "$build_boot" )
  
  # rename kernel objects to standardize bootloader config
  mv $build_boot/System.map-* $build_boot/map
  mv $build_boot/config-*     $build_boot/config
  mv $build_boot/vmlinuz-*    $build_boot/vmlinuz
}
