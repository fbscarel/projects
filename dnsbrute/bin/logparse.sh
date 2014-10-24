#!/usr/bin/env bash
# logparse.sh, 2014/10/24 12:44:21 fbscarel $

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
MAILPROG=(mail)
NC=(nc)

## network parameters
#
NC_TIMEOUT=3
SYSLOG_DEFPORT=514


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## parse configuration file for parameters
#
parse_conf() {
  [ -z "$mails" ]   && mails="$( getparam RECIPIENT_ADDRESSES $CONFIG )"
  [ -z "$logprio" ] && logprio="$( getparam SYSLOG_PRIORITY $CONFIG )"

  if [ -z "$loginfo" ]; then
    local lserv="$( getparam SYSLOG_SERVER $CONFIG )"
    if [ -n "$lserv" ]; then
      local lport="$( getparam SYSLOG_PORT $CONFIG )"
      [ -z "$lport" ] && lport=$SYSLOG_DEFPORT
      loginfo="$lserv:$lport"
    fi
  fi

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

  # if not running on Linux/FreeBSD, only localhost addresses are supported
  if [ "$( uname )" != "Linux" ] && [ "$( uname )" != "FreeBSD" ] && [ "$logserver" != "127.0.0.1" ]; then
    echo "[!] Non-localhost syslog servers are only supported on Linux and FreeBSD, terminating."
    exit 1
  fi
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
  echo "              the user.notice level will be used. Can be set via configuration file."
  echo "  -s          Send results to syslog server SYSLOG_SERVER, connecting on UDP port PORT."
  echo "              The server:port pair must be separated using a colon (':'). Remote syslog"
  echo "              messaging is supported only on Linux and FreeBSD; if running on other Unix"
  echo "              systems, use localhost (127.0.0.1) logging only. Can be set via"
  echo "              configuration file."
  echo "  -v          Log to standard output (stdout) using a pretty-printed format."
  exit 1
}


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


. $FILE_UTILS
. $LOG_UTILS
. $IP_UTILS

# check for parameters
while getopts "l:m:p:s:hv" opt; do
    case "$opt" in
        h) usage ;;
        l) logfile=${OPTARG} ;;
        m) mails=${OPTARG} ;;
        p) logprio=${OPTARG} ;;
        s) loginfo=${OPTARG} ;;
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

# check if logfile path exists
check_file $logfile

# check if mail addresses passed to the program are valid
if [ -n "$mails" ]; then
  stat=$( check_binaryexist MAILPROG ) ; [ "$?" -ne 0 ] && exit 1

  retmails=" $mails "
  for value in $mails; do
    if ! check_mail $value; then
      echo "[!] Email address $value is invalid, removed from recipient list."
      retmails="$(echo "$retmails" | sed "s/  *$value  */ /" )"
    fi
  done
  mails="$( echo $retmails | sed -e "s/^ *//;s/ *$//" )"
fi

# check if we can connect to logserver:logport
if [ -n "$loginfo" ]; then
  parse_loginfo

  stat=$( check_binaryexist NC ) ; [ "$?" -ne 0 ] && exit 1
  connect=$( nc -w $NC_TIMEOUT -znu "$logserver" "$logport" &> /dev/null )
  if [ "$?" -ne 0 ]; then
    echo "[!] Server $logserver doesn't seem to be listening on port $logport, terminating."
    exit 1
  fi
fi

# all good, check output options and act accordingly
if [ "$stdout" = true ]; then output_file   "$logfile" "/dev/stdout"; fi
if [ -n "$mails" ];      then output_mail   "$logfile" "$mails"; fi
if [ -n "$loginfo" ];    then output_syslog "$logfile" "$logserver" "$logport" "$logprio"; fi
