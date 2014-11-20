#!/usr/bin/env bash
# size.sh, 2014/11/19 11:22:13 fbscarel $

## size optimization functions
#

## remove unwanted documentation directories
## check globalvar '$DOC_DIRS' for directory listing
#
function doc_remove() {
  if [ -f "$DOC_DIRS" ]; then
    while read docdir; do
      rm -rf $build_dir/$docdir
    done < $DOC_DIRS
  fi
}


## remove Python precompiled object files
#
function py_remove() {
  find $build_dir/usr -name *.pyc -exec rm -f {} \;
  find $build_dir/usr -name *.pyo -exec rm -f {} \;
}


## compress dirs using SquashFS, making them read-only after mounting
## add to minimal system '/etc/fstab'
#
function squash_dirs() {
  local compress_dirs="opt usr"
  local mountopts="ro,suid,dev,exec,auto,nouser,async,relatime"

  for dir in $compress_dirs; do
    if [ ! -d "$build_dir/$dir" ]; then
      continue
    else
      mksquashfs $build_dir/$dir $build_dir/${dir}.sqsh -comp xz
      rm -rf $build_dir/$dir 2> /dev/null
      echo "/${dir}.sqsh /$dir squashfs $mountopts 0 0" >> $build_dir/etc/fstab
    fi
  done
}


## perform various size optimization functions
#
function size_opts() {
  # remove uneeded documentation
  doc_remove

  # remove Python precompiled object files
  py_remove

  # compress dirs using SquashFS
  squash_dirs
}
