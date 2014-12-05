#!/usr/bin/env bash
# daemon.sh, 2014/11/24 09:44:17 fbscarel $

## daemon start/stop functions
#

## process daemon add/del list on globalval $daemon_opts, acting accordingly
#
function daemon_config() {
  # split daemon list in 'add' and 'del' sections
  local IFS=','
  set -- $daemon_opts

  # process each section
  for split in $1 $2; do
    case "$split" in
      a*) local daemon_add="$( echo $split | cut -d':' -f2 )" ;;
      d*) local daemon_del="$( echo $split | cut -d':' -f2 )" ;;
      *) echo "[!] Unsupported tag for daemon list '$split' ."
         echo "    Use either 'a' or 'd' for adding/deleting daemons from boot order."
         ;;
    esac
  done

  # discover system runlevels
  local runlevels="$TMP_DIR/.runlevels"
  chroot $build_dir rc-status -a | grep "Runlevel" | cut -d':' -f2 > $runlevels

  # add/delete specified daemons
  daemon_set "$daemon_add" "add" $runlevels
  daemon_set "$daemon_del" "del" $runlevels
}


## process daemon list $1, taking action $2 while consulting runlevel list $3
#
function daemon_set() {
  local action="$2"
  local runlevels="$3"
  local IFS=' '

  for daemon in $1; do
    local IFS='@'
    set -- $daemon

    # check if daemon exists
    if [ ! -f $build_dir/etc/init.d/$1 ]; then
      echo "[!] Daemon $1 not found on the '/etc/init.d' directory of minimal system."
      echo "    Please check your daemon list. We're skipping this one."

    else
      if [ "$action" == "add" ]; then
        if [ -z "$2" ]; then
          local rl="default"
        else
          local rl="$2"

          # check if this is a valid runlevel
          if ! grep "$rl" $runlevels &> /dev/null; then
            echo "[!] Invalid runlevel $rl specified on atom $1@$rl ."
            echo "    Can't act on daemon. We're skipping this one."
            continue
          fi
        fi

      # if running 'del', autodetect runlevel for this service
      else
        rl="$( find $build_dir/etc/runlevels/ -name $1 | awk -F/ '{print $(NF-1)}' )"
      fi

      # add/delete daemon from runlevel
      chroot $build_dir rc-update $action $1 $rl
    fi
  done
}
