#!/usr/bin/env bash

function pkg_feh_depends() {
  depends="xorg"
}

function pkg_feh() {
  USE="X gif jpeg png"
  packages="media-libs/libjpeg-turbo media-libs/libpng virtual/jpeg media-libs/giflib media-libs/giflib media-libs/imlib2 media-libs/giblib media-gfx/feh"
}
