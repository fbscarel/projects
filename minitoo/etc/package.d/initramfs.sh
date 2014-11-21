#!/usr/bin/env bash

function pkg_initramfs_depends() {
  depends="kernel"
}

function pkg_initramfs_hook() {
  local target="$build_dir/boot"

  # load optional modules added by package install files
  [ -f "$DRACUT_MODULES" ] && dracut_modules="$( paste -s -d' ' $DRACUT_MODULES )"

  check_verb "[*] Installing initramfs on directory $target ."
  dracut --kver $kver                         \
         --conf $conf_dir/dracut.conf         \
         --confdir $conf_dir/dracut.conf.d/   \
         --add "$dracut_modules"              \
         --force                              \
         --stdlog 4                           \
         --strip                              \
         --xz                                 \
         $target/initramfs

  if [ $? -ne 0 ]; then
    echo "[!] There was an error while generating an initramfs."
    echo "    Please review 'dracut' output above for a more detailed error report."
    return
  else
    check_verb "[*] Installation successful."
    check_verb "    Remember that no further changes are made to the kernel commandline"
    check_verb "    specified in your bootloader configuration. Make sure the"
    check_verb "    '/boot/initramfs' file is loaded during boot time."
  fi
}
