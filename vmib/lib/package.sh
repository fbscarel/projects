#!/usr/bin/env bash
# package.sh, 2014/11/11 13:40:52 fbscarel $

## functions dealing with package checks and installation
#

## check if space-separated package list $1 contains only valid packages
#
function check_packages() {
  local function=""

  for function in $1; do
    local retval="$( type -t do_$function )"

    if [ "$retval" != "function" ]; then
      echo "[!] Unknown package $function, terminating."
      echo "[!] Please double-check your package list and try again."
      exit 1
    fi
  done
}


function do_baselayout() {
  packages="sys-apps/baselayout"
}


function do_busybox() {
  USE="-make-symlinks -mdev -sep-usr"
  packages="sys-apps/busybox"
}


function do_extlinux() {
  return;
}


function do_fluxbox() {
  USE="minimal -alsa -bidi -cvs -git -deprecated"
  packages="x11-wm/fluxbox x11-libs/libXtst"
}


function do_glibc() {
  USE="netifrc -gd -static-libs"
  packages="sys-libs/zlib sys-libs/timezone-data sys-libs/db sys-libs/cracklib sys-libs/glibc sys-libs/pam sys-auth/pambase"
}


function do_gtk() {
  USE="glib minimal introspection -alsa -systemtap -utils -doctool -gtk3 -wininst -internal-glib -graphite -gallium -gles2 -legacy-drivers -openvg -valgrind -xlib-xcb -cloudprint -colord -packagekit -apng -opengl -egl -gallium -gbm -llvm -xa -static-libs"
  packages="=x11-libs/gtk+-2.24.24"
}


function do_kernel() {
  return;
}


function do_pam() {
  USE="-audit"
  packages="sys-apps/shadow virtual/pam"
}


function do_plymouth() {
  USE="gtk libkms pango -gdm"
  packages="sys-boot/plymouth"
}


function do_sysvinit() {
  USE="netifrc minimal -ada -device-mapper -newnet -trace"
  packages="sys-apps/sysvinit sys-apps/openrc"
}


function do_udev() {
  USE="minimal kmod -usb -firmware-loader -gudev -suid -cramfs -cytune -fdformat -tty-helpers"
  packages="sys-apps/util-linux sys-fs/udev"
}


function do_vboxguest() {
  packages="app-emulation/virtualbox-guest-additions"
}


function do_xmisc() {
  packages="x11-apps/setxkbmap x11-apps/xrandr x11-misc/xsel"
}


function do_xorg() {
  USE="xorg libkms -kdrive -loongson2f -deprecated -tls-heartbeat -infinality -utils -dmx -glamor -tslib -unwind -xnest -xvfb -egl -gallium -gbm -llvm -xa -static-libs"
  packages="x11-base/xorg-server x11-base/xorg-drivers"
}
