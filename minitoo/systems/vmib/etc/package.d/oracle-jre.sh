#!/usr/bin/env bash

function pkg_oracle-jre_depends() {
  depends="glibc xorg"
}

function pkg_oracle-jre() {
  packages="x11-libs/libXtst"
}

function pkg_oracle-jre_hook() {
  local jre_file_path="/root/Downloads/jre-7u67-linux-x64.tar.gz"
  local opt_dir="$build_dir/opt"

  if [ -z "$jre_file_path" ]; then
    echo "[!] No JRE package specified on install file $conf_dir/package.d/oracle-jre.sh ."
    echo "[!] Edit the 'jre_file_path' variable and inform the full path to the .tar.{bz2,gz,xz} file."
    return
  elif ! tar -tzf "$jre_file_path"; then
    echo "[!] File $jre_file_path not in .tar.gz format. Can't install JRE."
    return
  else
    mkdir -p "$opt_dir"
    tar -zxf "$jre_file_path" -C "$opt_dir"
    check_verb "[*] Installed Oracle JRE $jre_file_path to $opt_dir ."
  fi

  # append Oracle JRE locale directory to globalvar $LOCALE_DIRS
  echo "/opt/jre1.7.0_67/lib/locale" >> $LOCALE_DIRS
}
