#!/usr/bin/env bash

function do_udev() {
  USE="minimal kmod -usb -firmware-loader -gudev -suid -cramfs -cytune -fdformat -tty-helpers"
  packages="sys-apps/util-linux sys-fs/udev"
}
