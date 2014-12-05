#!/usr/bin/env bash
# genbat.sh, 2014/09/08 14:40:16 fbscarel $


# globalvars - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## files and dirs
#
ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`
GENKEY="$ABS_PATH/genkey.sh"
KH2REG="$ABS_PATH/kh2reg.py"
CLI_DIR="$ABS_PATH/cli"
CLI_BATFILE="$CLI_DIR/pscp.bat"
SERVER_KEYS="$ABS_PATH/../../server/keys.db"

## registry variables
#
KEY="HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\SshHostKeys"
TYPE="REG_SZ"
PSCP="pscp-0.63.exe"
HACK_WAIT="ping -n 2 127.0.0.1 > nul"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

checkverb() {
  [ "$VERBOSE" = true ] && echo $1
}

# main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# assign parameters
while getopts ":hc:p:s:t:u:" opt; do
    case "$opt" in
        c) chost=${OPTARG} ;;
        p) port=${OPTARG} ;;
        s) host=${OPTARG} ;;  
        t) target=${OPTARG} ;;
        u) user=${OPTARG} ;;  
    esac
done

# grab SSH key from server and convert to PuTTY format
reg_add=`ssh-keyscan -t rsa -p $port $host 2> /dev/null | python $KH2REG | egrep '^"' | sed "s/@[0-9]*/@$port/"`
fields=($(echo $reg_add | sed 's/=/ /g'))

# generate client private key, add to user@server authorized_keys
cli_key=$( $GENKEY $chost $user )
checkverb "[*] Client private key generated, written to [ $cli_key ]."
checkverb "[*] Client public key appended to [ $( eval echo ~$user )/.ssh/authorized_keys ]."
checkverb "[*] Client public key registered to internal database [ $( readlink -f $SERVER_KEYS ) ]."

# output batch script
echo -e "@ECHO OFF\n" > $CLI_BATFILE
echo    "reg add $KEY /t $TYPE /v ${fields[0]} /d ${fields[1]}" >> $CLI_BATFILE
echo -e "$HACK_WAIT\n" >> $CLI_BATFILE

echo    "%~dp0"'\'"$PSCP -batch -l $user -P $port -i %~dp0"'\'"$( basename $cli_key ) %1 $host:$target" >> $CLI_BATFILE
echo -e "$HACK_WAIT\n" >> $CLI_BATFILE

echo -e "reg delete $( echo $KEY | sed "s/\\[A-Za-z]*\\[A-Za-z]*$//" ) /f" >> $CLI_BATFILE
unix2dos $CLI_BATFILE &> /dev/null

checkverb "[*] BAT script generated, written to [ $CLI_BATFILE ]."
