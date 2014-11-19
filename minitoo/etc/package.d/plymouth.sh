#!/usr/bin/env bash

function pkg_plymouth_depends() {
  depends="udev xorg gtk"
}

function pkg_plymouth() {
  USE="gtk libkms pango -gdm"
  packages="sys-boot/plymouth"
}
