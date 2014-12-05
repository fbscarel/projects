#!/usr/bin/env bash

function pkg_baselayout() {
  packages="sys-apps/baselayout"
}

function pkg_baselayout_hook () {
  # ensure all needed dirs are created
  mkdir -p $build_dir/bin   \
           $build_dir/boot  \
           $build_dir/dev   \
           $build_dir/home  \
           $build_dir/mnt   \
           $build_dir/opt   \
           $build_dir/proc  \
           $build_dir/root  \
           $build_dir/sbin  \
           $build_dir/sys

  # make mtab symlink
  ln -s /proc/mounts $build_dir/etc/mtab
}
