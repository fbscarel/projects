#!/usr/bin/env bash

function pkg_sysvinit_depends() {
  depends="baselayout glibc ncurses"
}

function pkg_sysvinit() {
  USE="minimal netifrc -device-mapper -newnet"
  packages="sys-apps/sysvinit sys-apps/openrc sys-process/psmisc net-misc/netifrc"
}
