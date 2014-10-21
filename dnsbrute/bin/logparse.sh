#!/usr/bin/env bash
# logparse.sh, 2014/10/21 14:12:33 fbscarel $

DNSBRUTE_HOME="$( readlink -f $0 | sed 's/\/[^\/]*$//' | sed 's/\/[^\/]*$//' )"
PROGNAME="$( basename $0 )"

## file paths
#
CONFIG="$DNSBRUTE_HOME/etc/dnsbrute.conf"
FILE_UTILS="$DNSBRUTE_HOME/lib/file.sh"
LOG_UTILS="$DNSBRUTE_HOME/lib/log.sh"
IP_UTILS="$DNSBRUTE_HOME/lib/ip.sh"

## binary dependencies
#
NC=(nc)

## network parameters
#
TIMEOUT=3


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## parse configuration file for parameters
#
parse_conf() {
  [ -z "$mails" ]     && mails="$( getparam RECIPIENT_ADDRESSES $CONFIG )"
  [ -z "$logprio" ]   && logprio="$( getparam SYSLOG_PRIORITY $CONFIG )"
  [ -z "$logserver" ] && logserver="$( getparam SYSLOG_SERVER $CONFIG )"
  [ -z "$logport" ]   && logport="$( getparam SYSLOG_PORT $CONFIG )"

  return 0
}


## parse syslog information passed through commandline
parse_loginfo() {
  local IFS=":"

  set -- $loginfo
  if [ "${#@}" -ne 2 ]; then echo "[!] Invalid parameter format passed to '-s' option, terminating."; exit 1; fi
  logserver="$1"
  logport="$2"

  if ! validip $logserver; then echo "[!] Invalid IP address passed to '-s' option, terminating."; exit 1; fi
  if ! validport $logport; then echo "[!] Invalid port number passed to '-s' option, terminating."; exit 1; fi
}


## show program usage and exit
#
usage() {
  echo "Usage: $( basename $0 ) -l LOG_FILE [-m RECIPIENTS] [-p PRIORITY]" 1>&2
  echo "                    [-s SYSLOG_SERVER:PORT] [-v]"
  echo "Parse logfile produced by 'dnsbrute.sh', producing various configurable outputs."
  echo "Compatible with stdout, syslog and email."
  echo
  echo "Some program parameters can be set via configuration file, as explained below,"
  echo "which can be found in 'etc/dnsbrute.conf'."
  echo
  echo "Available options:"
  echo "  -h          Show this help screen and exit."
  echo "  -l          Logfile to be parsed. Mandatory."
  echo "  -m          Send results via mail to RECIPIENTS. Multiple recipients should be separated"
  echo "              using spaces, in which case you MUST enclose this parameter using single or"
  echo "              double-quotes. The local '/usr/bin/mail' binary will be used, check your"
  echo "              Sendmail/Postfix/Exim configuration. Can be set via configuration file."
  echo "  -p          Enter messages to syslog using the specified PRIORITY. This value must be"
  echo "              informed as a 'facility.level' pair, as per logger(1) manpage. By default,"
  echo "              the user.notice level will be used. If unspecified, will be set as 514/UDP."
  echo "              Can be set via configuration file."
  echo "  -s          Send results to syslog server SYSLOG_SERVER, connecting on UDP port PORT."
  echo "              The server:port pair has to be separated using a colon (':'). This option is"
  echo "              not supported on OpenBSD systems. If no parameter is given to this option,"
  echo "              SYSLOG_SERVER will be set as localhost and PORT will be set as 514/UDP. Can"
  echo "              be set via configuration file."
  echo "  -v          Log to standard output (stdout) using a pretty-printed format."
  exit 1
}


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


. $FILE_UTILS
. $LOG_UTILS
. $IP_UTILS

# check for parameters
while getopts ":l:m:p:s:hv" opt; do
    case "$opt" in
        h) usage ;;
        l) logfile=${OPTARG} ;;
        m) mail=true
           mails=${OPTARG} ;;
        p) logprio=${OPTARG} ;;
        s) syslog=true
           loginfo=${OPTARG} ;;
        v) stdout=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# parse configuration file, do not override commandline options
[ -f "$CONFIG" ] && parse_conf || echo "[!] Configuration file $CONFIG not found, continuing..."

# check mandatory options
[ -z "$logfile" ] && { echo "[!] Option '-l' is mandatory!"; usage; }

# if still unset, give default values to non-mandatory parameters
[ -z "$logprio" ] && logprio="user.notice"
if [ "$syslog" = true ]; then
  if [ -z "$loginfo" ]; then
    logserver="127.0.0.1"
    logport="514"
  else
    parse_loginfo
  fi
fi

# check if logfile path exists
check_file $logfile

# check if mail addresses passed to the program are valid
if [ ! -z "$mails" ]; then
  retmails=" $mails "
  for value in $mails; do
    if ! check_mail $value; then
      echo "[!] Email address $value is invalid, removed from recipient list."
      retmails="$(echo "$retmails" | sed "s/  *$value  */ /" )"
    fi
  done
  mails="$( echo $retmails | sed -e "s/^ *//;s/ *$//" )"
fi

# check if netcat is installed
ncstat=$( check_binaryexist NC ) ; [ "$?" -ne 0 ] && exit 1

# check if we can connect to logserver:logport
if [ "$syslog" = true ]; then
  connect=$( nc -w $TIMEOUT -znu "$logserver" "$logport" &> /dev/null )
  if [ "$?" -ne 0 ]; then
    echo "[!] Server $logserver doesn't seem to be listening on port $logport, terminating."
    exit 1
  fi
fi

# all good, check output options and act accordingly
if [ "$stdout" = true ]; then output_file   "$logfile" "/dev/stdout"; fi
if [ "$mail" = true ];   then output_mail   "$logfile" "$mails"; fi
if [ "$syslog" = true ]; then output_syslog "$logfile" "$logserver" "$logport" "$logprio"; fi
