#!/usr/bin/env bash

function do_xorg() {
  USE="xorg libkms -kdrive -loongson2f -deprecated -tls-heartbeat -infinality -utils -dmx -glamor -tslib -unwind -xnest -xvfb -egl -gallium -gbm -llvm -xa -static-libs"
  packages="x11-base/xorg-server x11-base/xorg-drivers"
}
