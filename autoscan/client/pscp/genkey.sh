#!/usr/bin/env bash
# genkey.sh, 2014/09/08 14:40:16 fbscarel $


# globalvars - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## files and dirs
#
ABS_PATH=$( readlink -f $0 | sed 's/\/[^\/]*$//' )
CLI_DIR=$( readlink -f $ABS_PATH/cli )
PUTTYGEN="$ABS_PATH/../bin/puttygen"
AUTH_KEYS="$( eval echo ~$2 )/.ssh/authorized_keys"
SERVER_KEYS="$ABS_PATH/../../server/keys.db"


# main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## $1 = $chost, $2 = $user
#

# generate client keys on $CLI_DIR using puttygen
cli_key="$CLI_DIR/$2_$1_rsa"

if [ ! -f $cli_key ]; then 
/usr/bin/env expect << EOF
log_user 0
spawn $PUTTYGEN -t rsa -o $cli_key
expect "Enter passphrase to save key:"
send "\r"
expect "Re-enter passphrase to verify:"
send "\r"
expect eof
EOF
fi

# test if .ssh dir exists, create if it doesn't
mkdir -p "$( echo "$AUTH_KEYS" | sed 's/\/[^\/]*$//' )"
[ ! -f "$AUTH_KEYS" ] && touch "$AUTH_KEYS"

# append client public key to user@server authorized_keys, remove duplicates
ckey="$( $PUTTYGEN -L "$cli_key" | sed "s/[^ ]*$/$2@$1/" )"
echo "$ckey" > /tmp/key
echo "$ckey" >> $AUTH_KEYS
sort -u -o $AUTH_KEYS $AUTH_KEYS

# append client key to server key database, prefix timestamp
if [ ! "$( grep "$ckey" $SERVER_KEYS )" ]; then
  echo "$( date "+%s" ) $ckey" >> $SERVER_KEYS
fi

# return $cli_key filename
echo "$cli_key"
