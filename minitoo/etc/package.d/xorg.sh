#!/usr/bin/env bash

function pkg_xorg_depends() {
  depends="glibc udev"
}

function pkg_xorg() {
  USE="xorg libkms -kdrive -loongson2f -deprecated -tls-heartbeat -infinality -utils -dmx -glamor -tslib -unwind -xnest -xvfb -egl -gallium -gbm -llvm -xa -static-libs"
  packages="x11-base/xorg-server x11-base/xorg-drivers"
}
