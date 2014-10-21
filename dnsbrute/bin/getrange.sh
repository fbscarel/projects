#!/usr/bin/env bash
# getrange.sh, 2014/09/24 08:20:43 fbscarel $

ABS_PATH=`readlink -f $0 | sed 's/\/[^\/]*$//'`
UTIL="$ABS_PATH/util.sh"
TMPFILE="$ABS_PATH/.tmpfile"
IPS="$ABS_PATH/reported_ips"
RANGES="$ABS_PATH/confirmed_ranges"
WHOIS_DONE="$ABS_PATH/.whois_done"

IPDB_ORG="https://ipdb.at/org"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


## check if IP range $1 belongs to organization $2, according to whois
#
check_range() {
  if [ "$( whois n $1 | grep -ci "$2" )" -ne 0 ]; then
    echo $1 >> $RANGES
    return 0
  else
    echo $1 >> $WHOIS_DONE
    return 1
  fi
}


# - - -  main()  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


if [ $# -ne 3 ]; then
  echo "  Usage: $(basename $0) IPDB_STRING ORGANIZATION PAGECOUNT"
  exit 1
fi

# delete/touch tempfiles from previous execution
[ ! -f $IPS ]    && { rm -f $IPS ; touch $IPS; }
[ ! -f $RANGES ] && { rm -f $RANGES ; touch $RANGES; }
[ ! -f $WHOIS_DONE ] && { rm -f $WHOIS_DONE ; touch $WHOIS_DONE; }
. $UTIL

# fetch ip list
i=1
while [ $i -le $3 ]; do
  wget $IPDB_ORG/$1?page=$i -O $TMPFILE
  grep '<td ><a href="/ip/' $TMPFILE | cut -d'>' -f3 | sed 's/<.*//' >> $IPS
  let i++
done
sort -n $IPS | uniq > $TMPFILE ; mv $TMPFILE $IPS

while read ip ; do
  echo -n "For IP $ip, "
  # get ip ranges
  ia=( $(echo_range $ip) )

  for i in ${ia[@]}; do
    # check if IP range has already been included
    if [ "$( egrep -c "^$i$" $RANGES )" -ne 0 ]; then
      echo "skipping range $i , already on file..."
      break
    elif [ "$( egrep -c "^$i$" $WHOIS_DONE )" -ne 0 ]; then
      continue
    fi

    # check if ranges belong to organization $2
    if $( check_range $i $2 ); then
      echo "added range $i to file."
      break
    fi
  done
done < $IPS
sort -n $RANGES | uniq > $TMPFILE ; mv $TMPFILE $RANGES

mv $RANGES $ABS_PATH/whitelist/"$2"_ranges &> /dev/null
rm -f $IPS &> /dev/null
rm -f $WHOIS_DONE &> /dev/null
