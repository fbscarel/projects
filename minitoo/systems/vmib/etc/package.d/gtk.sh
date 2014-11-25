#!/usr/bin/env bash

function pkg_gtk_depends() {
  depends="xorg"
}

function pkg_gtk() {
  USE="glib minimal introspection X -alsa -systemtap -utils -doctool -gtk3 -wininst -internal-glib -graphite -gallium -gles2 -legacy-drivers -openvg -valgrind -xlib-xcb -cloudprint -colord -packagekit -apng -opengl -egl -gallium -gbm -llvm -xa -static-libs"
  packages="=x11-libs/gtk+-2.24.24"
}

function pkg_gtk_hook() {
  # append GTK documentation directory to globalvar $DOC_DIRS
  echo "/usr/share/gtk-doc" >> $DOC_DIRS
}
