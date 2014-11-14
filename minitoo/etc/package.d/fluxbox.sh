#!/usr/bin/env bash

function pkg_fluxbox_depends() {
  depends="xorg"
}

function pkg_fluxbox() {
  USE="minimal -alsa -bidi -cvs -git -deprecated"
  packages="x11-wm/fluxbox x11-libs/libXtst"
}
