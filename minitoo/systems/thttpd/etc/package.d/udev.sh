#!/usr/bin/env bash

function pkg_udev_depends() {
  depends="glibc ncurses shadow"
}

function pkg_udev() {
  USE="minimal kmod -firmware-loader -gudev -suid -cramfs -cytune -fdformat -tty-helpers"
  packages="sys-apps/util-linux sys-fs/udev"
}

function pkg_udev_post() {
  local extlinux_conf="$build_dir/boot/extlinux/extlinux.conf"

  if [ -f "$extlinux_conf" ]; then
    sed -i "s/\( *APPEND.*\)/\1 net.ifnames=0/" $extlinux_conf
  fi
}
