#!/usr/bin/env bash

function pkg_extlinux_hook() {
  local target="$build_dir/boot/extlinux"
  local syslinux_dir="/usr/share/syslinux"

  if [ -z "$device" ]; then
    echo "[!] No DEVICE specified, cannot install extlinux."
    return
  fi

  if check_yes "[*] Install extlinux to $device ? All partition data will be erased. (y/n) "; then
    echo "[!] Skipping extlinux installation due to user input."
    return
  else
    check_verb "[*] Installing extlinux bootloader to device $device ."
    mkdir -p $target
    extlinux --install $target &> /dev/null
    cp $syslinux_dir/*menu* $target 1> /dev/null
    cat $syslinux_dir/mbr.bin > $device

    check_verb "[*] Installation successful. The default deploy directory 'var/deploy' contains"
    check_verb "    a sample 'boot/extlinux/extlinux.conf' file that is fit for most use cases."
    check_verb "    If you did not change the default deploy directory, a copy of this file"
    check_verb "    should be found on the '/boot/extlinux' directory of your newly-created"
    check_verb "    system."
    check_verb "    If your system needs special tweaking, you should edit this file to"
    check_verb "    accomodate your configuration."
  fi
}
