#!/usr/bin/env bash
# doc.sh, 2014/11/19 11:10:52 fbscarel $

## documentation-related utility functions
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
