#!/usr/bin/env bash

function pkg_xmisc_depends() {
  depends="xorg"
}

function pkg_xmisc() {
  packages="x11-apps/setxkbmap x11-apps/xrandr x11-misc/xsel"
}
