#!/usr/bin/env bash

function pkg_busybox_depends() {
  depends="glibc"
}

function pkg_busybox() {
  USE="-make-symlinks -mdev -sep-usr"
  packages="sys-apps/busybox"
}
