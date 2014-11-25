#!/usr/bin/env bash

function pkg_opera_depends() {
  depends="glibc xorg gtk"
}

function pkg_opera_hook() {
  local opera_file_path=""

  if [ -z "$opera_file_path" ]; then
    echo "[!] No Opera package specified on install file $conf_dir/package.d/opera.sh ."
    echo "[!] Edit the 'opera_file_path' variable and inform the full path to the .tar.{bz2,gz,xz} file."
    return
  elif ! tar -tf "$opera_file_path"; then
    echo "[!] File $opera_file_path not in .tar.{bz2,gz,xz} format. Can't install Opera."
    return
  else
    local opera_dir="$( basename "$opera_file_path" | sed 's/\.tar\.[bgxz2]*$//' )"
    local opera_install_path="$build_dir/usr/local"

    tar -xf "$opera_file_path" -C "$TMP_DIR"
    $TMP_DIR/$opera_dir/install --quiet --prefix "$opera_install_path"

    # substitute strings to use $build_dir as '/'
    sed -i "s:$build_dir::" $opera_install_path/bin/opera

    # if there's a JRE installed, symlink it
    local jre_plugin="$( find $build_dir -name libnpjp2.so | sed "s:^$build_dir::" )"
    [ -n "$jre_plugin" ] && ln -s $jre_plugin $opera_install_path/lib/opera/plugins/libnpjp2.so

    check_verb "[*] Installed Opera package $opera_file_path to $opera_install_path ."
  fi

  # append Opera locale directory to globalvar $LOCALE_DIRS
  echo "/usr/local/share/opera/locale" >> $LOCALE_DIRS
}
