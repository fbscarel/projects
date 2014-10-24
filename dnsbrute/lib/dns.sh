#!/usr/bin/env bash
# dns.sh, 2014/10/24 10:22:16 fbscarel $

## DNS utility functions for all scripts in this package 
#

## set query flags
#
setflags() {
  [ "$aaonly" = true ]  && aa="+aaonly"   || rec="+noaaonly"
  [ "$recurse" = true ] && rec="+recurse" || rec="+norecurse"
}


## print query flags to $1
#
printflags() {
  echo -n "# Query flags:" >> $1
  [ "$aaonly" = true ]  && echo -n " authoritative" >> $1 || echo -n " non-authoritative" >> $1
  [ "$recurse" = true ] && echo -n " recursive" >> $1 || echo -n " non-recursive" >> $1
  echo >> $1
}

## lookup domain $1 from server $2
#
getdomain() {
  setflags
  local retval="$( dig +noall +answer +short +time=$DIG_TIMEOUT $aa $rec $1 $qtype @$2 | grep -v '^;' )"

  if [ -z "$retval" ]; then
    echo ""
  else
    retval="$( echo $retval | sort -n | tr '\n' ' ' )"
    echo "$( nocname "$retval" )"
  fi
}


## get Start of Authority (SOA) information about domain $1 from server $2
#
getsoa() {
  setflags
  local retval="$( dig @$2 +noall +authority +answer +time=$DIG_TIMEOUT $aa $rec $1 $qtype | grep -v '^;' | grep "SOA" )"

  if [ -z "$retval" ]; then
    echo ""
  else
    retval="$( echo $retval | tr '[:space:]' ',' | sed 's/,,*/,/g' )"

    local primaryns="$( echo $retval | cut -d',' -f5 )"
    local hostmaster="$( echo $retval | cut -d',' -f6 )"
    local serial="$( echo $retval | cut -d',' -f7 )"

    local echoval="$( echo "$primaryns,$hostmaster,$serial" )"
    [ "$echoval" == ",," ] && echo "" || echo "$echoval"
  fi
}


## make A-type queries on trusted/suspicious DNS servers
##   $1: domain list file
##   $2: suspicious servers file
##   $3: output file
##   $4: trusted server
#
query_A() {
  # complement header information
  echo "# Query type: A" >> $3
  printflags $3
  echo "# Fields: Domain, Trusted DNS, Trusted reported IPs, Suspicious DNS, Suspicious reported IP" >> $3
  echo "#" >> $3

  while read domain; do
    if check_comment "$domain"; then continue; fi
    local trusted="$( getdomain $domain $4 )"

    # if we have no response from trusted, skip this domain
    [ -z "$trusted" ] && continue

    while read dns; do
      if check_comment "$dns"; then continue; fi
      local suspicious="$( getdomain $domain $dns )"

      # if we have no response, skip this server
      [ -z "$suspicious" ] && continue

      for ip in $suspicious; do
        # IP not found on trusted result set?
        if [[ $trusted != *$ip* ]]; then
          ia=( $(echo_range $ip) )

          # search IP range on whitelists
          flag=0
          for i in ${ia[@]}; do
            [ "$( egrep -ci $i $wdir/* | cut -d ':' -f 2 | sort -n | tail -n1 )" -ne 0 ] && flag=1
          done
              
          [ "$flag" -eq 0 ] && echo "$domain,$4,$trusted,$dns,$ip" >> $3
        fi
      done
    done < $2
  done < $1
}


## make SOA-type queries on trusted/suspicious DNS servers using global vars
##   $1: domain list file
##   $2: suspicious servers file
##   $3: output file
##   $4: trusted server
#
query_SOA() {
  # complement header information
  echo "# Query type: SOA" >> $3
  printflags $3
  echo "# Fields: Domain, Trusted DNS, Trusted primary DNS, Trusted hostmaster, Trusted serial, Suspicious DNS, Suspicious primary DNS, Suspicious hostmaster, Suspicious serial" >> $3
  echo "#" >> $3

  while read domain; do
    if check_comment "$domain"; then continue; fi

    local trusted="$( getsoa $domain $4 )"
    local tsegment="$( echo $trusted | cut -d',' -f 1,2 | tr '[:upper:]' '[:lower:]' )"

    # if we have no response from trusted, skip this domain
    [ -z "$trusted" ] && continue

    while read dns; do
      if check_comment "$dns"; then continue; fi
      local suspicious="$( getsoa $domain $dns )"
      local ssegment="$( echo $suspicious | cut -d',' -f 1,2 | tr '[:upper:]' '[:lower:]' )"

      # if we have no response, skip this server
      [ -z "$suspicious" ] && continue

      # only compare primary NS and hostmaster values, ignore different serial numbers
      if [[ "$tsegment" != "$ssegment" ]]; then
        echo "$domain,$4,$trusted,$dns,$suspicious" >> $3
      fi
    done < $2
  done < $1
}


## remove CNAME records from $1, keep only IP addresses
nocname() {
  local retval=""

  for record in $1; do
    if validip $record; then retval="$retval $record"; fi
  done

  echo "$retval" | sed "s/^ //"
}
