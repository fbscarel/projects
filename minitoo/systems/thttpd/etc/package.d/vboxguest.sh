#!/usr/bin/env bash

function pkg_vboxguest_depends() {
  depends="udev xorg"
}

function pkg_vboxguest() {
  packages="app-emulation/virtualbox-guest-additions"
}
