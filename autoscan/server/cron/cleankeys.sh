#!/bin/bash
# cleankeys.sh, 2014/09/08 14:40:16 fbscarel $


# globalvars - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## files and dirs
#
ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`
KEYSDB="$ABS_PATH/../keys.db"
TMPFILE="$ABS_PATH/.tmpfile"
AUTH_KEYS=".ssh/authorized_keys"


# main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# check for parameters
if [ "$#" -ne 1 ]; then
  echo "Usage: $( basename $0 ) DAYS" 1>&2
  echo "Cleanup client public keys stored on server older than \$DAYS days."
  echo "Assumes the 'keys.db' file resides in parent directory (..) . Uses the"
  echo "'bc' arbitrary precision calculator."
  exit 1
fi

# check for 'bc' availability
if [ ! "$( which bc )" ]; then
  echo "[!] 'bc' doesn't seem to be available on \$PATH, terminating."
  exit 1
fi

# get current time, calculate max pubkey age from parameter
curdate="$( date "+%s" )"
maxage="$( echo "$curdate - ($1 * 86400)" | bc )"

while read line; do
  tstamp="$( echo "$line" | cut -d' ' -f1 )"

  # compare pubkey timestamp to maxage, prune if older
  if [ "$maxage" -gt "$tstamp" ]; then
    key="$( echo "$line" | sed 's/^[^ ]* //' )"
    user="$( echo "$key" | egrep -o " [A-Za-z]*@" | sed 's/^ \(.*\)@/\1/' )"
    user_keys="$( eval echo ~$user)/$AUTH_KEYS"
    grep -v "$key" $user_keys > $TMPFILE ; mv $TMPFILE $user_keys
    grep -v "$key" $KEYSDB > $TMPFILE ; mv $TMPFILE $KEYSDB
  fi
done < <(egrep "^[0-9]" $KEYSDB)

rm -f $TMPFILE &> /dev/null
