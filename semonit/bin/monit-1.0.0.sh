#!/bin/bash

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

testdomain() {
    if [ $(grep -c "$1" $TMPFILE) -eq 0 ]; then
      echo "$1:${2^}" >> $TMPFILE
    else
      sed -i "s/^\($1.*\)$/\1, ${2^}/" $TMPFILE
    fi
}

matchdomain() {
  # standard domain parser
  if [ $3 -eq 1 ]; then
    for domain in `cat $SRCHFILE-$2.html | egrep -o "$1" | cut -d'/' -f3 | sort -u | sed 's/^www\.//'`; do
      testdomain $domain $2
    done

  # bing ads domain parser
  elif [ $3 -eq 2 ]; then
    for domain in `cat $SRCHFILE-$2.html | egrep -o "$1" | sed 's/http[s]*%3a%2f%2f//' | sed 's/%.*//' | cut -d'=' -f2 | sort -u | sed 's/^www\.//'`; do
      testdomain $domain $2
    done

  # yahoo domain parser
  elif [ $3 -eq 3 ]; then
    for domain in `cat $SRCHFILE-$2.html | egrep -o "$1" | sed 's/.*RU=//' | sed 's/^http[s]*%3a%2f%2f//' | sed 's/%.*//' | sort -u | sed 's/^www\.//'`; do
      testdomain $domain $2
    done
    
  fi
}

retrieve() {
	wget $quiet --tries=$TRIES --connect-timeout=$TIMEOUT --header="User-Agent: Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)" $1 -O $SRCHFILE-$2.html
}

google() {
	retrieve "https://www.google.com.br/search?q=$1&num=$2" "google"

  matchdomain '<h3 class="r"><a href=([^ ]+)' "google" 1
  matchdomain 'adurl=([^ ]+)' "google" 1
}

bing() {
  retrieve "https://www.bing.com/search?q=$1&count=$2" "bing"

  matchdomain '<li class="b_algo"><h2><a href=([^ ]+)' "bing" 1
  matchdomain ';u=([^ ]+)' "bing" 2
}

yahoo() {
  retrieve "https://br.search.yahoo.com/search?n=$2&p=$1" "yahoo"

  matchdomain '<li><div class="res"><div><h3><a id="link-[0-9]*" class="yschttl spt" href=([^ ]+)' "yahoo" 3
}

logresults() {
  while read line; do 
    domain=`echo $line | cut -d":" -f1`
    seng=`echo $line | cut -d":" -f2`
    logger -d -n $HOST -p $PORT -p $PRIO -t "$PROGTAG" -u /dev/null "Search term $1 : found domain $domain on search engine(s) $seng"
  done < $TMPFILE
}

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
