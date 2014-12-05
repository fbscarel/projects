#!/usr/bin/env bash
# postinst.sh, 2014/11/20 09:51:32 fbscarel $

## various post installation functions
#

## detect if /bin/sh is present; symlink to bash/busybox if negative
## optionally set user default shells
#
function post_shell() {
  [ -f "$build_dir/bin/bash" ]    && local bashok=1    || local bashok=0
  [ -f "$build_dir/bin/busybox" ] && local busyboxok=1 || local busyboxok=0

  if [ "$bashok" -eq 1 ] && [ "$busyboxok" -eq 1 ]; then
    echo "[*] Found both /bin/bash and /bin/busybox on ${build_dir}."
    if check_yes "[*] Set default shell automatically? (y/n) "; then
      echo "[*] If you have not installed coreutils, findutils, grep and other system"
      echo "    utilities you HAVE TO select busybox here, or you'll run into problems."
      check_opts "/bin/bash" "/bin/busybox" "[*] Please choose a default shell: "
      [ $? -eq 1 ] && shell="/bin/bash" || shell="/bin/busybox"
    else
      shell="/bin/busybox"
    fi
  elif [ "$bashok" -eq 1 ]; then
    shell="/bin/bash"
  elif [ "$busyboxok" -eq 1 ]; then
    shell="/bin/busybox"
  else
    echo "[!] No standard shell found on $build_dir/bin."
    echo "[!] Continuing without configuration."
    return
  fi

  check_verb "[*] Symlinking /bin/sh to ${shell}..."
  rm -f $build_dir/bin/sh 2> /dev/null
  ln -s $shell $build_dir/bin/sh

  if ! check_yes "[*] Set default user shell to $shell? (y/n) "; then
    local passwd_file="$build_dir/etc/passwd"
    local useradd_file="$build_dir/etc/default/useradd"

    [ "$shell" == "/bin/busybox" ] && shell="/bin/sh"
    [ -f $passwd_file ]  && sed -i "s:/bin/bash:$shell:" $passwd_file
    [ -f $useradd_file ] && sed -i "s:/bin/bash:$shell:" $useradd_file
  fi
}


## ask user and set root password for minimal system
## if '-y' is active, randomize and set password automatically
#
function post_rootpw() {
  if [ -f "$build_dir/etc/passwd" ]; then
    if check_yes "[*] Randomize and set root password automatically? (y/n) "; then
      chroot $build_dir passwd root
    else
      local randpw="$( head /dev/urandom | tr -cd '[:alnum:]' | fold -w8 | head -n1 )"
      echo "root:$randpw" | chroot $build_dir chpasswd
      echo "[*] Set root password as '$randpw' . WRITE DOWN THIS INFORMATION FOR LATER USE."
    fi
  fi
}


##
#
function post_user() {
  return
}


## perform post installation configuration
#
function post_install() {
  # set user shell
  post_shell

  # set root password
  post_rootpw

  # optionally create users
  #post_user
}
