#!/usr/bin/env bash
# signexe.sh, 2014/09/08 14:40:16 fbscarel $


# globalvars - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## files and dirs
#
ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`
OSSLSIGNCODE="$ABS_PATH/../bin/osslsigncode"

## misc
#
SIGNED_SUFFIX="_SIGNED"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

checkverb() {
  [ "$VERBOSE" = true ] && echo $1
}


# main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## $1 = $cli_exe, $2 = $cksum, $3 = $pkicert, $4 = $pkikey, $5 = $pkipass
#

signedexe=$( echo $1 | sed "s/.exe$/$SIGNED_SUFFIX.exe/" )
checkverb "[*] Signing executable [ $1 ] with certificate [ $3 ] and private key [ $4 ]."

[ ! -z $5 ] && pkipass=$( echo "-pass $5" )
$OSSLSIGNCODE sign -certs $3 -key $4 $pkipass -in $1 -out $signedexe &> /dev/null

cksumfile="$( echo $signedexe | sed "s/.exe$/.$2/" )"
$CKSUMPATH $signedexe > $cksumfile

checkverb "[*] Created signed executable [ $signedexe ]."
checkverb "[*] $2 checksum written to [ $cksumfile ]."

oldfile="$( echo $1 | sed "s/exe$//" )"
rm -f $oldfile* &> /dev/null
checkverb "[*] Removed unsigned source executable [ $1 ], and its checksum."
