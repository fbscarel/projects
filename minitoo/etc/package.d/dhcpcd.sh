#!/usr/bin/env bash

function pkg_dhcpcd_depends() {
  depends="sysvinit"
}

function pkg_dhcpcd() {
  packages="net-misc/dhcpcd"
}
