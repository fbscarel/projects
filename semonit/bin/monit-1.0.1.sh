#!/bin/bash
# monit-1.0.1.sh, 2014/08/18 17:41:16 fbscarel $

SAVEIFS=$IFS
IFS="$(printf '\n\t')"

## search options
#
TIMEOUT=5
TRIES=3

## file options
#
BASEDIR="/opt/semonit"
CURTIME=`date +%Y%m%d%H%M`
SRCHDIR="$BASEDIR/searches"
SRCHFILE="$SRCHDIR/$1-$CURTIME"
TMPFILE="$BASEDIR/tmpdomains.txt"

## logging options
#
PROGTAG="SEMonit"
PRIO="daemon.warn"
LPRIO="daemon.info"
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
    if [ $(grep -c "$1|$2" $TMPFILE) -eq 0 ]; then
      echo "$1|$2|${3^}" >> $TMPFILE
    else
      sed -i "s/^\($1|$2.*\)$/\1, ${3^}/" $TMPFILE
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
    testdomain $domain $(skipslashes $url) $2
  done 
}


## download search results
#
retrieve() {
	wget $quiet --tries=$TRIES --connect-timeout=$TIMEOUT --header="User-Agent: Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)" $1 -O $SRCHFILE-$2.html
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


## produce and send results to SIEM/email/etc.
#
logresults() {
  while read line; do 
    domain=`echo $line | cut -d"|" -f1`
    url=`echo $line | cut -d"|" -f2`
    seng=`echo $line | cut -d"|" -f3`
    logger -d -n $HOST -p $PORT -p $PRIO -t "$PROGTAG" -u /dev/null "Search term $1 : found domain $domain : URL $url : search engine(s) $seng"
  done < $TMPFILE
}


## perform housekeeping
#
cleanup() {
  find $SRCHDIR -mtime +60 -exec rm {} \;

  for file in `ls $SRCHDIR | grep -v "$CURTIME\|.bz2"`; do
    bzip2 -z9 $SRCHDIR/$file
  done

  if [ -z $quiet ]; then
    cat $TMPFILE
  fi

  rm -f $TMPFILE
}


## main() - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#

touch $TMPFILE

# use $3="v" for verbose mode
if [ ! -z $3 ] && [ "$3" == "v" ] ; then
  quiet=""
else 
  quiet="--quiet"
fi

google  $1 $2
bing    $1 $2
yahoo   $1 $2

logresults $1

cleanup

IFS=$SAVEIFS
