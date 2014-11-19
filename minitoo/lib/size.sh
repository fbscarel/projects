#!/usr/bin/env bash
# size.sh, 2014/11/19 11:22:13 fbscarel $

## size optimization functions
#

## 
#
function size_opts() {
  local compress_dirs="opt usr"
  local mountopts="ro,suid,dev,exec,auto,nouser,async,relatime"

  # remove uneeded documentation
  doc_remove

  # compress dirs using SquashFS, making them read-only after mounting
  # add to minimal system '/etc/fstab'
  for dir in $compress_dirs; do
    if [ ! -d "$build_dir/$dir" ]; then continue; fi
    mksquashfs $build_dir/$dir $build_dir/${dir}.sqsh -comp xz
    rm -rf $build_dir/$dir 2> /dev/null
    echo "/${dir}.sqsh /$dir squashfs $mountopts 0 0" >> $build_dir/etc/fstab
  done
}
