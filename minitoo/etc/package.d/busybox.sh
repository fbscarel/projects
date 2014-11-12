#!/usr/bin/env bash

function do_busybox() {
  USE="-make-symlinks -mdev -sep-usr"
  packages="sys-apps/busybox"
}
