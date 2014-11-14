#!/usr/bin/env bash

function pkg_udev_depends() {
  depends="glibc ncurses shadow"
}

function pkg_udev() {
  USE="minimal kmod -firmware-loader -gudev -suid -cramfs -cytune -fdformat -tty-helpers"
  packages="sys-apps/util-linux sys-fs/udev"
}
