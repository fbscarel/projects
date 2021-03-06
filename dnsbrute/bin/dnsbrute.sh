#!/usr/bin/env bash
# dnsbrute.sh, 2014/11/10 11:22:42 fbscarel $

DNSBRUTE_HOME="$( readlink -f $0 | sed 's/\/[^\/]*$//' | sed 's/\/[^\/]*$//' )"
PROGNAME="$( basename $0 )"
VERSION="1.2.0"

## file paths
#
LOGPARSE="$DNSBRUTE_HOME/bin/logparse.sh"
CONFIG="$DNSBRUTE_HOME/etc/dnsbrute.conf"
DNS_UTILS="$DNSBRUTE_HOME/lib/dns.sh"
FILE_UTILS="$DNSBRUTE_HOME/lib/file.sh"
IP_UTILS="$DNSBRUTE_HOME/lib/ip.sh"
DNS_TMPFILE="$DNSBRUTE_HOME/var/.dns_tmpfile"

## network parameters
#
DIG_TIMEOUT=1

## assumed defaults, if unspecified
#
DEFAULT_QTYPE="A"
DEFAULT_RDIR="$DNSBRUTE_HOME/var/results"
DEFAULT_WDIR="$DNSBRUTE_HOME/var/whitelists"
DEFAULT_TSERVER="8.8.8.8"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## parse configuration file for parameters
#
parse_conf() {
  [ -z "$tserver" ]  && tserver="$( getparam TRUSTED_SERVER $CONFIG )"
  [ -z "$sservers" ] && sservers="$( getparam SUSPICIOUS_SERVERS $CONFIG )"
  [ -z "$wdir" ]     && wdir="$( getparam WHITELIST_DIR $CONFIG )"

  return 0
}


## if running verbose, print configuration parameters being used
#
print_conf() {
  check_verb "[*] Using configuration options:"
  check_verb "      Domain file:                   $DNSBRUTE_HOME/$domains"
  check_verb "      Suspicious servers file:       $DNSBRUTE_HOME/$sservers"
  check_verb "      Output file:                   $outfile"
  check_verb "      Whitelist directory:           $wdir"
  check_verb "      Trusted server:                $tserver"
  check_verb "      Using query type:              $qtype"

  [ "$aaonly" = true ]  && local aastr="authoritative" || local aastr="non-authoritative"
  [ "$recurse" = true ] && local rcstr="recursive"     || local rcstr="non-recursive"
  local qopt="      Using query options:           $aastr $rcstr"
  check_verb "$qopt"

  [ ! -z "$logline" ] && check_verb "      Using 'logparse' commandline:  $logline"
  check_verb " "
}


## show program usage and exit
#
usage() {
  echo "Usage: $( basename $0 ) -d DOMAIN_FILE [-o OUTFILE] [-r] [-s SUSPSERVER_FILE]" 1>&2
  echo "                    [-t TRUSTED_SERVER] [-w WHITELIST_DIR]"
  echo "Lookup various suspicious DNS servers for an arbitrary number of domains,"
  echo "comparing results against a trusted server. Report discrepancies for further"
  echo "action on a number of formats, including CSV, syslog and email."
  echo
  echo "Some program parameters can be set via configuration file, as explained below,"
  echo "which can be found in 'etc/dnsbrute.conf'."
  echo
  echo "Available options:"
  echo "  -a          Only check authoritative answers from suspicious servers."
  echo "              Non-authoritative answers, even if incorrect or malicious, will"
  echo "              be IGNORED. If unset, queries will also check non-authoritative"
  echo "              results by default."
  echo "  -d          List of domains to be looked up and compared. Mandatory."
  echo "  -h          Show this help screen and exit."
  echo "  -l          Invoke 'logparse.sh' after execution to process results. The"
  echo "              parameter passed to this option will be passed over verbatim."
  echo "              You MUST enclose this parameter using double-quotes, otherwise"
  echo "              it will be interpreted as being passed directly to $PROGNAME ."
  echo "              It is not necessary, however, to specify the logfile to be"
  echo "              processed, as it's implicit. Check the 'logparse.sh' online help"
  echo "              option ('-h') for usage information."
  echo "  -o          Specify alternative outfile to log output into. If unspecified,"
  echo "              'var/results/dnsbrute.sh.\$TIMESTAMP.out' will be used."
  echo "              \$TIMESTAMP format is Unix epoch."
  echo "  -q          Query type to be performed. If unspecified, the default is an A"
  echo "              (address) query. Available types: A, MX, NS, SOA."
  echo "  -r          Toggle RD (recursion desired) bit in DNS queries. If unset,"
  echo "              queries will be non-recursive by default."
  echo "  -s          Specify file containing a list of suspicious servers to be looked"
  echo "              up against. This file should contain one IP address per line. The"
  echo "              file 'etc/sample_sservers.db' contains examples of accepted"
  echo "              formats. Mandatory. Can be set via configuration file."
  echo "  -t          Specify trusted server to be looked up against. The responses"
  echo "              given by this server will be used for comparison with the '-s'"
  echo "              list of suspicious servers for validity. If unspecified, the"
  echo "              Google DNS Server (8.8.8.8) will be used. Can be set via"
  echo "              configuration file."
  echo "  -v          Toggle verbose mode."
  echo "  -w          Specify directory where whitelists will be searched. Whitelists"
  echo "              can be generated using the 'bin/getrange.sh' helper script. If"
  echo "              unspecified, 'var/whitelists' will be used by default. Can be"
  echo "              set via configuration file."
  exit 1
}


## print informative header to $outfile
#
print_header() {
  echo "# Generated by $PROGNAME on `date`" >> $outfile
  echo "#">> $outfile
}


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


. $DNS_UTILS
. $FILE_UTILS
. $IP_UTILS

# ensure tmpfiles are clean
if [ -f $DNS_TMPFILE ]; then
  rm -f $DNS_TMPFILE
fi

# check for parameters
while getopts "d:l:o:q:s:t:w:harv" opt; do
    case "$opt" in
        h) usage ;;
        a) aaonly=true ;;
        d) domains=${OPTARG} ;;
        l) logline=${OPTARG} ;;
        o) outfile=${OPTARG} ;;
        q) qtype=${OPTARG} ;;
        r) recurse=true ;;
        s) sservers=${OPTARG} ;;
        t) tserver=${OPTARG} ;;
        v) verbose=true ;;
        w) wdir=${OPTARG} ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# parse configuration file, do not override commandline options
[ -f "$CONFIG" ] && parse_conf || echo "[!] Configuration file $CONFIG not found, continuing..."

# check mandatory options
[ -z "$domains" ]   && { echo "[!] Option '-d' is mandatory!"; usage; }
[ -z "$sservers" ]  && { echo "[!] Option '-s' is mandatory!"; usage; }

# if still unset, give default values to non-mandatory parameters
[ -z "$qtype" ]     && qtype="$DEFAULT_QTYPE"
[ -z "$outfile" ]   && outfile="$DEFAULT_RDIR/$PROGNAME.`date +%s`.out"
[ -z "$tserver" ]   && tserver="$DEFAULT_TSERVER"
[ -z "$wdir" ]      && wdir="$DEFAULT_WDIR"

# check if file paths passed to the program actually exist
check_file $domains
check_file $sservers
check_dir  $wdir

# check if trusted server's IP address is valid
if ! validip $tserver; then
  echo "[!] IP $tserver is invalid, terminating."
  exit 1
fi

# check if query type is valid
qtype="$( echo $qtype | tr '[:lower:]' '[:upper:]' )"
if [ "$qtype" != "A" ]  && [ "$qtype" != "MX" ] &&
   [ "$qtype" != "NS" ] && [ "$qtype" != "SOA" ]; then
  echo "[!] Invalid query type specified, terminating."
  exit 1
fi

check_verb "[*] dnsbrute-$VERSION: Starting operation."
print_conf
print_header

# remove offline servers from query set
check_nsonline $sservers $DNS_TMPFILE

# make DNS queries according to $qtype
nsquery $domains $DNS_TMPFILE $outfile $tserver

# process outfile using log parser, if requested
[ -n "$logline" ] && $LOGPARSE -l $outfile $logline
