#!/bin/bash
# monit-1.0.3.sh, 2014/08/19 13:47:14 fbscarel $

SAVEIFS=$IFS
IFS="$(printf '\n\t')"

## search options
#
DEFAULT_RCOUNT=10
TIMEOUT=5
TRIES=3
USER_AGENT="User-Agent: Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"

## base directory: careful when invoking from external dirs,
##                 use absolute path if possible
#
BASEDIR="/opt/semonit"
#BASEDIR="./"

## file options
#
CURTIME=`date +%Y%m%d%H%M`
SRCHDIR="$BASEDIR/searches"
TMPFILE="$BASEDIR/tmpdomains.txt"
WHITELIST="$BASEDIR/whitelist.txt"

## logging options
#
PROGTAG="SEMonit"
PRIO="daemon.warn"
HOST="192.168.0.1"
PORT="514"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## skip slashes in strings for 'sed' substitution
#
skipslashes() {
  echo $1 | sed 's/\//\\\//g'
}


## strip domain from urls
#
stripdomain() {
  if [[ $1 =~ http[s]*:// ]]; then
    retval=`echo $1 | cut -d'/' -f3 | sed 's/^www\.//'`
  else
    retval=`echo $1 | sed 's/^www\.//'`
  fi

  echo $retval
}


## test if domain was already included in $TMPFILE
#
testdomain() {
    if [ $(egrep -c "^$1|$2" $TMPFILE) -eq 0 ]; then
      echo "$1|$2|${3^}" >> $TMPFILE
    else
      sed -i "s/^\($1|$(skipslashes $2)|.*\)$/\1, ${3^}/" $TMPFILE
    fi
}


## parse & match domain from various search engines
#
matchdomain() {
  for href in `cat $SRCHFILE-$2.html | egrep -o "$1"`; do
    case $3 in
      # google/bing standard parser
      1) url=`echo $href | cut -d'"' -f4` ;;

      # google/bing ads parser
      2) url=`echo $href | cut -d'=' -f2 | sed 's/"$//'`
         url=`perl -MURI::Escape -e 'print uri_unescape($ARGV[0]);' "$url"` ;;

      # yahoo standard parser
      3) url=`echo $href | sed 's/.*RU=//' | cut -d'/' -f1`
         url=`perl -MURI::Escape -e 'print uri_unescape($ARGV[0]);' "$url"` ;;
    esac

    domain=$(stripdomain $url)
    testdomain $domain $url $2
  done 
}


## download search results
#
retrieve() {
	wget $quiet --tries=$TRIES --connect-timeout=$TIMEOUT --header="$USER_AGENT" $1 -O $SRCHFILE-$2.html
}


## google SE meta-function
#
google() {
	retrieve "https://www.google.com.br/search?q=$1&num=$2" "google"

  matchdomain '<h3 class="r"><a href=([^ ]+)' "google" 1
  matchdomain 'adurl=([^ ]+)' "google" 2
}


## bing SE meta-function
#
bing() {
  retrieve "https://www.bing.com/search?q=$1&count=$2" "bing"

  matchdomain '<li class="b_algo"><h2><a href=([^ ]+)' "bing" 1
  matchdomain ';u=([^ ]+)' "bing" 2
}


## yahoo SE meta-function
#
yahoo() {
  retrieve "https://br.search.yahoo.com/search?n=$2&p=$1" "yahoo"

  matchdomain '<li><div class="res"><div><h3><a id="link-[0-9]*" class="yschttl spt" href=([^ ]+)' "yahoo" 3
}


## produce and send results to SIEM/stdout/email/etc.
#
logresults() {
  while read line; do 
    domain=`echo $line | cut -d"|" -f1`
    url=`echo $line | cut -d"|" -f2`
    seng=`echo $line | cut -d"|" -f3`

    ## uncomment this line to use syslog reporting; remember to set $HOST and $PORT above
    #
    logger -d -n $HOST -p $PORT -p $PRIO -t "$PROGTAG" -u /dev/null "Search term $1 : found domain $domain : URL $url : search engine(s) $seng"

    ## uncomment for simple echo reporting
    #
    #echo "Search term $1 : found domain $domain : URL $url : search engine(s) $seng"

    ## whitelist matching; remember to set $WHITELIST above
    #
    #if [ $(egrep -c "^$domain$" $WHITELIST) -eq 0 ]; then
    #  echo "Search term $1 : domain $domain not found on whitelist $WHITELIST"
    #fi
  done < $TMPFILE
}


## perform housekeeping
#
cleanup() {
  find $SRCHDIR -mtime +60 -exec rm {} \;

  for file in `ls $SRCHDIR | grep -v "$CURTIME\|.bz2"`; do
    bzip2 -z9 $SRCHDIR/$file
  done

  # if verbose, print $TMPFILE for debugging
  if [ -z $quiet ]; then
    cat $TMPFILE
  fi

  rm -f $TMPFILE
}


## show program usage and exit
#
usage() {
  echo "Usage: $0 -t SEARCH_TERM [-r RESULT_COUNT] [-v]"
  echo "Search on Google/Bing/Yahoo! for 'SEARCH_TERM', returning 'RESULT_COUNT' results."
  echo "Check internal function 'logresults()' for actions taken on result set."
  echo
  echo "Available options:"
  echo "  -h          Show this help screen."
  echo "  -r          Request RESULT_COUNT from search engine. Use 10/15/20/30/40/100 for"
  echo "              Yahoo! compatibility."
  echo "  -t          Use SEARCH_TERM as query parameter."
  echo "  -v          Toggle verbose output."
  exit 1
}


## main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#

# check commandline parameters
while getopts ":hr:t:v" opt; do
  case "$opt" in
    h) usage ;;
    r) rcount=${OPTARG} ;;
    t) srchterm=${OPTARG} ;;
    v) verbose=true ;;
  esac
done
shift $((OPTIND-1))

# 'srchterm' is mandatory
if [ -z "$srchterm" ]; then
  echo "  [!] Option '-t' is mandatory!"
  usage
fi
SRCHFILE="$SRCHDIR/$srchterm-$CURTIME"

# if unset, default 'rcount' to $DEFAULT_RCOUNT
if [ -z "$rcount" ]; then
  echo "  [*] Using default RESULT_COUNT = $DEFAULT_RCOUNT."
  rcount=$DEFAULT_RCOUNT
fi

# test for verbose flag
[ ! -z $verbose ] && quiet="" || quiet="--quiet"

# check for $TMPFILE
[ -f $TMPFILE ] && rm -f $TMPFILE
touch $TMPFILE

google  $srchterm $rcount
bing    $srchterm $rcount
yahoo   $srchterm $rcount

logresults $srchterm

cleanup

IFS=$SAVEIFS
