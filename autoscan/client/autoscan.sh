#!/usr/bin/env bash
# autoscan.sh, 2014/09/08 14:40:16 fbscarel $


# globalvars - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## files and dirs
#
ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`
CONFIG="$ABS_PATH/autoscan.conf"
GENBAT="$ABS_PATH/pscp/genbat.sh"
GENEXE="$ABS_PATH/sfx/genexe.sh"
SIGNEXE="$ABS_PATH/sign/signexe.sh"
FCA_CONF="$ABS_PATH/fcaj/exec/fca.conf"
EXE_PATH="$ABS_PATH/exe"

## binary dependencies
#
NC=(nc)
EXPECT=(expect)
PYTHON=(python)
SSHKEYGEN=(ssh-keygen)
Z7=(7z 7za 7zr p7zip)
BINDIR="$ABS_PATH/bin"

## network parameters
#
TIMEOUT=3

## misc
#
VERSION="1.0.0"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## check if supplied user exists
#
check_user() {
  [ $( getent passwd | egrep -c "^$1:" ) -eq 0 ] && echo 0 || echo 1
}


## check if supplied binary files exist, bail if they don't
#
check_binaryexist() {
  # tricky pass-by-name to get array as parameter, check
  # http://stackoverflow.com/questions/16461656/bash-how-to-pass-array-as-an-argument-to-a-function
  local n=$1[@]
  local a=("${!n}")
  for file in "${a[@]}"; do
    fpath=$( which $file 2> /dev/null )
    [ ! -z "$fpath" ] && { echo $fpath; return 0; }
  done

  echo "[!] $file binary not found in \$PATH, terminating." > /dev/stdin
  return 1
}


## check if files inside 'bin/' are binary-compatible with current OS
#
check_binarycompat() {
  for file in $BINDIR/*; do
    if [ "$( file -L $file | grep -v -e "$( uname )" -e "Windows" | wc -l )" -ne 0 ]; then
      echo "[!] Binary file $file not compatible with current OS, terminating."
      exit 1
    fi
  done
}


## check if user $1 has write permissions on directory $2
## reference: http://stackoverflow.com/questions/14103806/bash-test-if-a-directory-is-writable-by-a-given-uid
#
write_perms() {
  # customize 'stat' string according to OS; if unknown, bypass permission checking
  case "$myos" in
    "FreeBSD") str="-Lf%Su %Sg %Sp" ;;
    "Linux")   str="-Lc%U %G %A" ;;
    "NetBSD")  str="-Lf%Su %Sg %Sp" ;;
    "OpenBSD") str="-Lf%Su %Sg %Sp" ;;
    *) return 0 ;;
  esac

  dirVals=( $( stat "$str" $2 ) )

  if ( [ "$dirVals" == "$1" ] && [ "${dirVals[2]:2:1}" == "w" ] ) ||
     ( [ "${dirVals[2]:8:1}" == "w" ] ) ||
     ( [ "${dirVals[2]:5:1}" == "w" ] && (
      gMember=($(groups $1)) &&
      [[ "${gMember[*]:2}" =~ ^(.* |)${dirVals[1]}( .*|)$ ]]
    ) )
  then
    return 0
  else
    echo "[!] User $1 doesn't seem to have write permission on target $2, terminating."
    exit 1
  fi
}


## check if supplied file exists, bail if it doesn't
#
check_file() {
  if [ ! -f "$1" ]; then
    echo "[!] File $1 not found, terminating."
    exit 1
  fi
}


## check if supplied directory exists, bail if it doesn't
#
check_dir() {
  if [ ! -d "$1" ]; then
    echo "[!] Directory $1 not found, terminating."
    exit 1
  fi
}


## test IP address for validity
## http://www.linuxjournal.com/content/validating-ip-address-bash-script
#
validip() {
  local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
  fi
  return $stat
}


## get configuration value $1 from $CONFIG, variable delimiter
#
getparam() {
  local delim="$( egrep "^$1" $CONFIG | sed "s/^$1//" )"
  echo "$( egrep "^$1" $CONFIG | sed "s/.*${delim:0:1} *\(.*\)/\1/" )"
}


## parse configuration file for parameters
#
parse_conf() {
  [ -z $host ]    && host="$( getparam SSH_SERVER )"
  [ -z $port ]    && port="$( getparam PORT )"
  [ -z $user ]    && user="$( getparam USERNAME )"
  [ -z $chost ]   && chost="$( getparam CLIENT_HOSTNAME )"
  [ -z $target ]  && target="$( getparam TARGET )"
  [ -z $cksum ]   && cksum="$( getparam CHECKSUM )"
  [ -z $pkicert ] && pkicert="$( getparam PKI_CERT )"
  [ -z $pkikey ]  && pkikey="$( getparam PKI_KEY )"
  [ -z $pkipass ] && pkipass="$( getparam PKI_PASS )"

  return 0
}


## show configuration parameters, if verbose
#
printconf() {
  echo    "[*] $( basename $0 ), version $VERSION"
  echo -e "    Using the following configuration parameters:\n"
  echo    "        SSH server IP: $host"
  echo    "        SSH server port: $port"
  echo    "        User login as: $user"
  echo    "        Client hostname: $chost"
  echo    "        Target directory: $target"
  echo    "        Checksum algorithm: $cksum"
  [ ! -z $pkicert ] && echo    "        Signing certificate: $pkicert"
  [ ! -z $pkikey  ] && echo    "        Signing private key: $pkikey"
  [ ! -z $pkipass ] && echo -e "\n    Private key password omitted for security reasons."
  echo
}


## show program usage and exit
#
usage() {
  echo "Usage: $( basename $0 ) -s SSH_SERVER -u USER [-c CLIENT_HOSTNAME] [-p PORT]" 1>&2
  echo "                        [-t TARGET] [-z CHECKSUM] [-i CERT] [-k KEY] [-l PASSWORD] [-v]"
  echo "Generate an executable file (.exe) to be run on clients for automated scanning, report"
  echo "generation and uploading. Run this script at SSH_SERVER, logged in as either root or USER,"
  echo "since we need write permissions to ~USER/.ssh . Supports code signing and checksum."
  echo
  echo "Available options:"
  echo "  -c          Specify CLIENT_HOSTNAME for client-specific SSH keys. Can be omitted, in which"
  echo "              case the generic 'host' string will be used."
  echo "  -i          Use the supplied X.509 CERT certificate to sign the executable. Signing is done"
  echo "              using osslsigncode (http://sourceforge.net/projects/osslsigncode/). Mandatory if"
  echo "              KEY was specified."
  echo "  -k          Use the supplied KEY private key to sign the executable. Mandatory if CERT was"
  echo "              specified."
  echo "  -l          Use PASSWORD as the passphrase to decrypt KEY."
  echo "  -p          SSH server listening port. Defaults to 22 if omitted."
  echo "  -s          SSH server public IP, to which clients will connect back to. Mandatory."
  echo "  -t          Specify TARGET folder on server to which files will be copied from clients. If"
  echo "              omitted, defaults to USER_HOME directory. Will not be created if non-existing."
  echo "  -u          Specify the USER clients will use to authenticate to your SSH server. Mandatory."
  echo "  -v          Toggle verbose output."
  echo "  -z          Specify CHECKSUM as the digest algorithm to be used for executable checksum."
  echo "              Available choices are: md5, sha1, sha224, sha256 sha384 or sha512. Defaults to"
  echo "              sha512 if omitted."
  exit 1
}


## write configuration file for FCA file naming
#
fca_writeconf() {
  echo "USER = $user"   >  $FCA_CONF
  echo "CHOST = $chost" >> $FCA_CONF
}


# main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# check for parameters
while getopts ":hvc:i:k:l:p:s:t:u:z:" opt; do
    case "$opt" in
        c) chost=${OPTARG} ;;
        h) usage ;;
        i) pkicert=${OPTARG} ;;
        k) pkikey=${OPTARG} ;;
        l) pkipass=${OPTARG} ;;
        p) port=${OPTARG} ;;
        s) host=${OPTARG} ;;  
        t) target=${OPTARG} ;;
        u) user=${OPTARG} ;;  
        v) verbose=true ;;
        z) cksum=${OPTARG} ;;
        *) usage ;;  
    esac
done
shift $((OPTIND-1))

# parse configuration file, do not override commandline options
[ -f "$CONFIG" ] && parse_conf || echo "[!] Configuration file $CONFIG not found, continuing..."

# check mandatory options
[ -z "$host" ] && { echo "[!] Option '-s' is mandatory!"; usage; }

if [ -z "$user" ]; then
  echo "[!] Option '-u' is mandatory!"
  usage
elif [ "$( check_user $user )" -eq 0 ]; then
  echo "  [!] User $user does not exist!"
  usage
fi

[ -z "$port" ]    && port=22
[ -z "$chost" ]   && chost="host"
[ -z "$target" ]  && target=~$user
[ -z "$verbose" ] && verbose=false
[ -z "$cksum" ]   && cksum="sha512"

# check if we have necessary privs
myid=`id -u`
if [ "$myid" -ne 0 ] && [ "$myid" -ne "$( id -u $user )" ]; then
  echo "[!] This script must be run as either root or the user passed to the '-u'"
  echo "    option, terminating."
  exit 1
fi

# get current OS
myos="$( uname )"

# check if supplied IP address is valid
if ! validip $host; then
  echo "[!] IP $host is invalid, terminating."
  exit 1
fi

# check if auxiliary scripts are where we expect them to be
check_file $GENBAT
check_file $GENEXE
check_file $SIGNEXE

# check if 'extra/' dependencies are binary-compatible
check_binarycompat

# check for binary dependencies
binstat=$( check_binaryexist NC )         ; [ "$?" -ne 0 ] && exit 1
binstat=$( check_binaryexist EXPECT )     ; [ "$?" -ne 0 ] && exit 1
binstat=$( check_binaryexist PYTHON )     ; [ "$?" -ne 0 ] && exit 1
binstat=$( check_binaryexist SSHKEYGEN )  ; [ "$?" -ne 0 ] && exit 1

# check if 7-zip binary file dependencies are met, set zpath
zpath=$( check_binaryexist Z7 ) ; [ "$?" -ne 0 ] && exit 1

# check if server:port is on listening state
connect=$( nc -w $TIMEOUT -zn "$host" "$port" &> /dev/null )
if [ "$?" -ne 0 ]; then
  echo "[!] Server $host doesn't seem to be listening on port $port, terminating."
  exit 1
fi

# check if checksum binary path is available, set cksumpath
case "$cksum" in
  "md5")    ckwhich=( md5sum md5 ) ;;
  "sha1")   ckwhich=( sha1sum sha1 ) ;;
  "sha224") ckwhich=( sha224sum sha224 ) ;;
  "sha256") ckwhich=( sha256sum sha256 ) ;;
  "sha384") ckwhich=( sha384sum sha384 ) ;;
  "sha512") ckwhich=( sha512sum sha512 ) ;;
  *) echo "[!] Digest algorithm $cksum is not supported!"; usage ;;
esac
cksumpath=$( check_binaryexist ckwhich ); [ "$?" -ne 0 ] && exit 1

# expand '~', check if TARGET exists
while echo $target | grep -c '~' &> /dev/null; do target=$( eval echo $target ); done
check_dir $target

# check if USER has write permissions on TARGET
write_perms $user $target

# if a cert was specified we must have a key, and vice-versa
if [ ! -z "$pkicert" -a -z "$pkikey" ] || [ ! -z "$pkikey" -a -z "$pkicert" ]; then
  echo "  [!] You must supply both CERT and KEY to produced signed executables!"
  usage
fi

# check if certificate and privkey actually exist, if they were set
[ ! -z $pkicert ] && check_file $pkicert
[ ! -z $pkikey ]  && check_file $pkikey

# if using privkey, check if password is correct
if [ ! -z $pkikey ]; then
  if ! openssl pkey -in "$pkikey" -passin pass:"$pkipass" &> /dev/null ; then
    echo "[!] Password $pkipass can't decrypt private key $pkikey, terminating."
    exit 1
  fi
fi

# everything fine, show current configuration if verbose
if [ "$verbose" = true ]; then
  printconf
fi

# call genbat.sh for SSH/DOS batch configuration
VERBOSE=$verbose $GENBAT -c $chost -p $port -s $host -t $target -u $user

# create configuration file for FCA operation
fca_writeconf

# create SFX directory (if needed) and executable
mkdir -p $EXE_PATH
cli_exe="$EXE_PATH/$chost""_$user""_autoscan.exe"
VERBOSE=$verbose ZPATH="$zpath" CKSUMPATH="$cksumpath" $GENEXE $chost $user $cli_exe $cksum

# optionally sign executable
if [ ! -z $pkicert ]; then
  VERBOSE=$verbose CKSUMPATH="$cksumpath" $SIGNEXE $cli_exe $cksum $pkicert $pkikey $pkipass
fi
