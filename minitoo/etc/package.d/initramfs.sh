#!/usr/bin/env bash

function pkg_initramfs_depends() {
  depends="kernel"
}

function pkg_initramfs_hook() {
  local target="$build_dir/boot"

  check_verb "[*] Installing initramfs on directory $target ."
  dracut --kver $kver                         \
         --conf $conf_dir/dracut.conf         \
         --confdir $conf_dir/dracut.conf.d/   \
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
    check_verb "[*] Installation successful. Keep in mind the 'initramfs' package does not"
    check_verb "    check if all necessary modules were installed in the generated initramfs."
    check_verb "    Review the 'etc/dracut.conf' and 'etc/dracut.conf.d' resources if you run"
    check_verb "    into any problems, and insert missing modules in your configuration files."
    check_verb "    Likewise, no further changes are made to the kernel commandline specified"
    check_verb "    in your bootloader configuration. Make sure the '/boot/initramfs' file is"
    check_verb "    loaded at boot time."
  fi
}
