#!/usr/bin/env bash
# dns.sh, 2014/10/24 12:44:28 fbscarel $

## DNS utility functions for all scripts in this package 
#


## print query flags to $1
#
printflags() {
  echo -n "# Query flags:" >> $1

  if [ "$aaonly" = true ]; then
    echo -n " authoritative" >> $1
    check_verb "[*] Running on authoritative mode. Non-authoritative responses by suspicious servers will be ignored."
  else
    echo -n " non-authoritative" >> $1
    check_verb "[*] Running on non-authoritative mode. All suspicious responses will be checked."
  fi

  if [ "$recurse" = true ]; then
    echo -n " recursive" >> $1
    check_verb "[*] Running on recursive mode. DNS queries will have RD (recursion desired) bit set."
  else
    echo -n " non-recursive" >> $1
    check_verb "[*] Running on non-recursive mode. DNS queries will not have RD (recursion desired) bit set."
  fi

  echo >> $1
}


## check if DNS response on file $1 is authoritative ( flags: aa )
#
check_aa() {
  retval="$( grep "^;; flags:" $1 | cut -d';' -f3 | grep 'aa' )"
  [ "$?" -eq 0 ] && return 1 || return 0
}


## lookup domain $1 from server $2
## $3 contains trusted DNS server
#
getdomain() {
  local qfile="$DNSBRUTE_HOME/var/.qfile"
  local qtmp="$DNSBRUTE_HOME/var/.qtmp"

  # cache query on tmpfile
  [ "$recurse" = true ] && local rec="+recurse" || local rec="+norecurse"
  dig @$2 +time=$DIG_TIMEOUT $rec $1 $qtype > $qfile

  # if authoritative-only flag is set, check if answer is authoritative
  # ONLY FOR suspicious queries
  if [ "$aaonly" = true ] && [ "$2" != "$3" ]; then
    if check_aa $qfile ; then echo "" ; return 1 ; fi
  fi

  # clear comments, empty lines, and space-separate entries
  grep -v '^;' $qfile | sed '/^$/d' | sed 's/\t\t*/ /g' > $qtmp
  mv $qtmp $qfile

  # select fields on output
  case "$qtype" in
    "A")   local fields="5" ;;
    "MX")  local fields="6" ;;
    "NS")  local fields="5" ;;
    "SOA") local fields="5,6,7"
           local grp=" SOA " ;;
  esac

  # echo query-specific output
  local retval="$( cat $qfile | grep "$grp" | cut -d ' ' -f $fields | sort -n | tr '\n' ' ' )"
  if [ -z "$retval" ]; then
    echo ""
  else
    [ "$qtype" == "A" ] && echo "$( nocname "$retval" )" || echo "$retval"
  fi
}


## make DNS queries to trusted/suspicious DNS servers
##   $1: domain list file
##   $2: suspicious servers file
##   $3: output file
##   $4: trusted server
#
nsquery() {
  # complement header information
  echo "# Query type: $qtype" >> $3
  printflags $3
  case "$qtype" in
    "A")   echo "# Fields: Domain, Trusted DNS, Trusted reported IPs, Suspicious DNS, Suspicious reported IP" >> $3 ;;
    "MX")  echo "# Fields: Domain, Trusted DNS, Trusted MX servers, Suspicious DNS, Suspicious MX server" >> $3 ;;
    "NS")  echo "# Fields: Domain, Trusted DNS, Trusted Nameservers, Suspicious DNS, Suspicious Nameserver" >> $3 ;;
    "SOA") echo "# Fields: Domain, Trusted DNS, Trusted primary DNS, Trusted hostmaster, Trusted serial, Suspicious DNS, Suspicious primary DNS, Suspicious hostmaster, Suspicious serial" >> $3 ;;
  esac
  echo "#" >> $3

  while read domain; do
    if check_comment "$domain"; then continue; fi

    # get trusted query info, skip if unavailable
    local trusted="$( getdomain $domain $4 $4 | tr '[:upper:]' '[:lower:]' )"
    [ -z "$trusted" ] && continue

    while read dns; do
      # get suspicious query info, skip if unavailable
      local suspicious="$( getdomain $domain $dns $4 | tr '[:upper:]' '[:lower:]' )"
      [ -z "$suspicious" ] && continue

      # SOA-type queries are done on the whole set, not on per-item basis
      if [ "$qtype" == "SOA" ]; then
        local tsegment="$( echo $trusted | cut -d' ' -f 1,2 )"
        local ssegment="$( echo $suspicious | cut -d' ' -f 1,2 )"
        [[ "$tsegment" != "$ssegment" ]] && echo "$domain,$4,$trusted,$dns,$suspicious" >> $3
        continue
      fi

      # A, MX and NS queries iterate on each value of the $suspicious result set
      for value in $suspicious; do
        case "$qtype" in
          "A")
            # IP not found on trusted result set?
            if [[ $trusted != *$value* ]]; then
              local ia=( $(echo_range $value) )

              # search IP range on whitelists
              local flag=0
              local i=""
              for i in ${ia[@]}; do
                [ "$( egrep -ci $i $wdir/* | cut -d ':' -f 2 | sort -n | tail -n1 )" -ne 0 ] && flag=1
              done
              
              [ "$flag" -eq 0 ] && echo "$domain,$4,$trusted,$dns,$value" >> $3
            fi
          ;;
          "MX")
            [[ $trusted != *$value* ]] && echo "$domain,$4,$trusted,$dns,$value" >> $3
          ;;
          "NS")
            [[ $trusted != *$value* ]] && echo "$domain,$4,$trusted,$dns,$value" >> $3
          ;;
        esac
      done
    done < $2
  done < $1
}


## check which DNS servers from file $1 are online, return new file $2 containing this set
#
check_nsonline() {
  while read dns; do
    if check_comment "$dns"; then continue; fi

    connect=$( dig @$dns +time=$DIG_TIMEOUT . A &> /dev/null )
    if [ "$?" -ne 0 ]; then
      echo "[!] Server $dns doesn't seem to be listening to DNS queries, removed from query set."
    else
      echo "$dns" >> $2
    fi
  done < $1
}


## remove CNAME records from $1, keep only IP addresses
#
nocname() {
  local retval=""

  for record in $1; do
    if validip $record; then retval="$retval $record"; fi
  done

  echo "$retval" | sed "s/^ //"
}
