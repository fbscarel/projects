#!/usr/bin/env bash

function pkg_glibc() {
  USE="-cracklib -gd -static-libs"
  packages="sys-libs/zlib sys-libs/timezone-data sys-libs/db sys-libs/glibc sys-libs/pam sys-auth/pambase"
}

function pkg_glibc_hook() {
  if [ "$( uname -m )" == "x86_64" ]; then
    local libstdc="$( find /usr/lib/gcc -name libstdc++.so | grep -v "/32" )"
    local libgccs="$( find /usr/lib/gcc -name libgcc_s.so | grep -v "/32" )"
  else
    local libstdc="$( find /usr/lib/gcc -name libstdc++.so )"
    local libgccs="$( find /usr/lib/gcc -name libgcc_s.so )"
  fi

  # copy libstdc++ and libgcc_s, normally included with the 'gcc' package
  cp -a $libstdc* $build_dir/lib/
  cp -a $libgccs* $build_dir/lib/

  # append default locale directories to globalvar $LOCALE_DIRS
  echo "/usr/share/locale"       >> $LOCALE_DIRS
  echo "/usr/share/i18n/locales" >> $LOCALE_DIRS

  # append default documentation directories to globalvar $LOCALE_DIRS
  echo "/usr/share/doc"        >> $DOC_DIRS
  echo "/usr/share/info"       >> $DOC_DIRS
  echo "/usr/share/man"        >> $DOC_DIRS
  echo "/usr/local/share/doc"  >> $DOC_DIRS
  echo "/usr/local/share/info" >> $DOC_DIRS
  echo "/usr/local/share/man"  >> $DOC_DIRS
}
