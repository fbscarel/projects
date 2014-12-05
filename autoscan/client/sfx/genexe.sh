#!/usr/bin/env bash
# genexe.sh, 2014/09/08 14:40:16 fbscarel $


# globalvars - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## files and dirs
#
ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`
TMP_ZFILE="$ABS_PATH/tmpfile.7z"
SCP_CLI_DIR="$ABS_PATH/../pscp/cli"
FCA_EXE_DIR="$ABS_PATH/../fcaj/exec"

F_7ZS="$ABS_PATH/../bin/7zS.sfx"
F_CONFIG="$ABS_PATH/config.txt"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

checkverb() {
  [ "$VERBOSE" = true ] && echo $1
}


# main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## $1 = $chost, $2 = $user, $3 = $cli_exe, $4 = $cksum
#

# ZPATH should containg 7zip path; create 7z file to be appended to executable
$ZPATH -l a $TMP_ZFILE $SCP_CLI_DIR $FCA_EXE_DIR &> /dev/null

# produce executable using 7zip '7zS' module as PE header and 'config.txt'
cat $F_7ZS $F_CONFIG $TMP_ZFILE > $3
rm -f $TMP_ZFILE &> /dev/null

cksumfile="$( echo $3 | sed "s/.exe$/.$4/" )"
$CKSUMPATH $3 > $cksumfile 

checkverb "[*] Bundle packed, client executable written to [ $3 ]."
checkverb "[*] $4 checksum written to [ $cksumfile ]."
