#!/usr/bin/env bash
# getrange.sh, 2014/09/24 08:20:43 fbscarel $

DNSBRUTE_HOME=`readlink -f $0 | sed 's/\/[^\/]*$//' | sed 's/\/[^\/]*$//'`

## file paths
#
FILE_UTILS="$DNSBRUTE_HOME/lib/file.sh"
IP_UTILS="$DNSBRUTE_HOME/lib/ip.sh"
TMPFILE="$DNSBRUTE_HOME/var/.gr_tmpfile"
TMP_IPS="$DNSBRUTE_HOME/var/.gr_ips"
TMP_RANGES="$DNSBRUTE_HOME/var/.gr_ranges"
TMP_WHOIS="$DNSBRUTE_HOME/var/.gr_whois"
WHITELIST_DIR="$DNSBRUTE_HOME/var/whitelists"

## network defaults
#
IPDB_ORG="https://ipdb.at/org"
DEFAULT_PAGECOUNT=1

## binary dependencies
#
WGETPROG=(wget)
WHOISPROG=(whois)


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## check if IP range $1 belongs to organization $2, according to whois
#
check_range() {
  if [ "$( whois $1 | grep -ci "$2" )" -ne 0 ]; then
    echo $1 >> $TMP_RANGES
    return 0
  else
    echo $1 >> $TMP_WHOIS
    return 1
  fi
}


## show program usage and exit
#
usage() {
  echo "Usage: $( basename $0 ) -i IPDB_STRING -o ORGANIZATION_STRING [-p PAGECOUNT]" 1>&2
  echo "Produce a whitelist for IP ranges identified as belonging to ORGANIZATION_STRING,"
  echo "via queries to the https://ipdb.at service. This whitelist can then be used by 'dnsbrute'"
  echo "to avoid false positive results on queries."
  echo
  echo "This program uses the 'whois' executable to resolve queries for IP ranges. Make sure"
  echo "your firewall allows outgoing connections to port 43/TCP, otherwise you'll get bogus"
  echo "results. The binary 'wget' is also a dependency."
  echo
  echo "Available options:"
  echo "  -h          Show this help screen and exit."
  echo "  -i          String to be passed as query parameter to the https://ipdb.at service. This"
  echo "              string differs from organization to organization, and must be discovered"
  echo "              using trial-and-error. Mandatory."
  echo "  -o          String to be used to parse whois queries and determine if the IP range"
  echo "              being analyzed belongs to the organization. This is usually a lowercase"
  echo "              string identifying the organization, such as 'google' or 'microsoft', for"
  echo "              example. Mandatory."
  echo "  -p          Number of pages to be retrieved and analyzed using the https://ipdb.at service."
  echo "              The exact number of IPs analyzed is roughly PAGECOUNT * 50. If unspecified,"
  echo "              only a single page will be fetched."
  exit 1
}


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


. $FILE_UTILS
. $IP_UTILS

# check for parameters
while getopts "i:o:p:h" opt; do
    case "$opt" in
        h) usage ;;
        i) ipdbstr=${OPTARG} ;;
        o) orgstr=${OPTARG} ;;
        p) pagecount=${OPTARG} ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# check mandatory options
[ -z "$ipdbstr" ] && { echo "[!] Option '-i' is mandatory!"; usage; }
[ -z "$orgstr" ]  && { echo "[!] Option '-o' is mandatory!"; usage; }

# if unset, specify default pagecount
[ -z $pagecount ] && pagecount=$DEFAULT_PAGECOUNT

# check binary dependencies
stat=$( check_binaryexist WGETPROG ) ; [ "$?" -ne 0 ] && exit 1
stat=$( check_binaryexist WHOISPROG ) ; [ "$?" -ne 0 ] && exit 1

# delete/touch tempfiles from previous execution
rm -f $TMP_IPS $TMP_RANGES $TMP_WHOIS
touch $TMP_IPS $TMP_RANGES $TMP_WHOIS

# set output file
outfile="$WHITELIST_DIR/$orgstr"

# fetch ip list
echo "[*] Fetching results from https://ipdb.at :"
i=1
while [ $i -le $pagecount ]; do
  echo -n "$i... "
  wget $IPDB_ORG/$ipdbstr?page=$i --quiet --no-check-certificate -O $TMPFILE
  grep '<td ><a href="/ip/' $TMPFILE | cut -d'>' -f3 | sed 's/<.*//' >> $TMP_IPS
  let i++
done
sort -n $TMP_IPS | uniq > $TMPFILE ; mv $TMPFILE $TMP_IPS

echo "ok!"
echo

while read ip ; do
  echo -n "[*] For IP $ip, "
  # get ip ranges
  ia=( $(echo_range $ip) )

  for i in ${ia[@]}; do
    # check if IP range has already been included
    if [ "$( egrep -c "^$i$" $TMP_RANGES )" -ne 0 ]; then
      echo "skipping range $i"
      break
    elif [ "$( egrep -c "^$i$" $TMP_WHOIS )" -ne 0 ]; then
      continue
    fi

    # check if ranges belong to organization $orgstr
    if $( check_range $i $orgstr ); then
      echo "registering range $i"
      break
    fi
  done
done < $TMP_IPS
sort -n $TMP_RANGES | uniq > $TMPFILE ; mv $TMPFILE $TMP_RANGES

mv $TMP_RANGES $outfile &> /dev/null

echo
echo "[*] Whitelist written to file $outfile"
