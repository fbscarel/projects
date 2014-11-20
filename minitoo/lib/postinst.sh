#!/usr/bin/env bash
# postinst.sh, 2014/11/20 09:51:32 fbscarel $

## various post installation functions
#

## detect if /bin/sh is present; symlink to bash/busybox if negative
## optionally set user default shells
#
function post_shell() {
  [ -f "$build_dir/bin/bash" ]    && local bashok=1
  [ -f "$build_dir/bin/busybox" ] && local busyboxok=1

  if [ $bashok -eq 1 ] && [ $busyboxok -eq 1 ]; then
    echo "[*] Found both /bin/bash and /bin/busybox on ${build_dir}."
    check_opts "/bin/bash" "/bin/busybox" "[*] Please choose a default shell: "
    [ $? -eq 1 ] && shell="/bin/bash" || shell="/bin/busybox"
  elif [ $bashok -eq 1 ]; then
    shell="/bin/bash"
  elif [ $busyboxok -eq 1 ]; then
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


##
#
function post_user() {
  return
}


##
#
function post_tty() {
  return
}


## perform post installation configuration
#
function post_install() {
  # set user shell
  post_shell

  # optionally create users
  #post_user

  # set up autologin and reduce tty count
  #post_tty
}
