#!/usr/bin/env bash
# disk.sh, 2014/11/12 09:38:07 fbscarel $

## disk and mountpoint-related utility functions
#

## format and partition disk $1, mount on directory $2
#
function disk_prep() {
  # check if $1 is mounted
  local partitions="$( mount | grep "^$1" | cut -d' ' -f1 | sort )"
  for part in $partitions; do
    if [ -n "$part" ]; then
      if check_yes "[*] Partition $part from device $1 seems to be mounted. Unmount? (y/n) "; then
        echo "[!] Can't continue, device is mounted. Terminating."
        exit 1
      fi
      if ! umount $part; then
        echo "[!] Couldn't unmount partition $part . Check umount(8) output above. Terminating."
        exit 1
      fi
    fi
  done

  check_verb "[*] Formatting and preparing disk $1 ..."

  # script fdisk to:
  #   1) create new partition table
  #   2) create one partition spanning the whole disk
  #   3) set partition as bootable
  #   4) write changes
  echo -e "o\nn\np\n1\n\n\na\nw\n" | fdisk $1 1> /dev/null

  # create ext2 filesystem, for compatibility purposes
  mkfs.ext2 -Fq ${1}1 1> /dev/null

  # mount filesystem on $2
  mount -t ext2 ${1}1 $2
}
