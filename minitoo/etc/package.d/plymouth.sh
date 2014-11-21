#!/usr/bin/env bash

function pkg_plymouth_depends() {
  plymouth_bin=( plymouth plymouth-set-default-theme )

  # check if plymouth is installed in the host system
  if check_binaryexist $plymouth_bin; then
    echo "[!] Plymouth doesn't seem to be installed in the host system."
    echo "    Can't generate a plymouth-enabled initramfs."

  else
    depends="initramfs udev"

    # enable the 'plymouth' module in dracut
    echo "plymouth" >> $DRACUT_MODULES

    # edit the '$plymouth_theme' variable below to optionally set plymouth theme
    # to be used by 'dracut' during initramfs generation
    local plymouth_theme=""

    if [ ! -z "$plymouth_theme" ]; then
      local plymouth_path="/usr/share/plymouth/themes/"

      if [ ! -d "$plymouth_path/$plymouth_theme" ]; then
        echo "[!] Invalid theme specified on plymouth package configuration."
        echo "    Using default theme instead."
        return
      else
        plymouth-set-default-theme $plymouth_theme
      fi
    fi
  fi
}
