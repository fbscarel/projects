#!/usr/bin/env bash
# log.sh, 2014/10/22 15:17:52 fbscarel $

## logging functions for all scripts in this package 
#

## print pretty-printed output to file with parameters:
##   $1: log file
##   $2: output file
#
function output_file() {
  local tmpfile="$DNSBRUTE_HOME/var/.tmpfile"  
  local stripcomm_file="$DNSBRUTE_HOME/var/.stripcomm_file"  
  local domain=""
  local dflag=true

  # strip comments from logfile
  sort $1 | egrep -v "^#" > $stripcomm_file
  echo "Domain,Suspicious DNS,Suspicious reported IP,Trusted DNS,Trusted reported IPs" > $tmpfile

  # parse logfile, grouping by domain
  while read line; do
    local curdomain="$( echo $line | cut -d',' -f 1 )"

    if [ "$curdomain" != "$domain" ]; then
      domain="$curdomain"
      dflag=true
    fi

    if [ "$dflag" = true ]; then
      dflag=false
      echo -n "$domain," >> $tmpfile
      echo -n "$( echo $line | cut -d',' -f 2,3 )," >> $tmpfile
      echo "$( echo $line | cut -d',' -f 4,5 )" >> $tmpfile
    else
      echo " ,$( echo $line | cut -d',' -f 2,3 ), , " >> $tmpfile
    fi
  done < $stripcomm_file

  # make pretty-printing arrangements
  column -s ',' -t $tmpfile > $stripcomm_file
  mv $stripcomm_file $tmpfile

  local lline="$( awk '{print length, $0}' $tmpfile | sort -nr | head -1 | cut -d' ' -f1 )"
  local sep="$( printf %${lline}s | tr ' ' '-' )"

  cat $tmpfile | sed "s/^[a-z]/$sep\\`echo -e '\n\r'`&/" > $2
  rm -f $tmpfile $stripcomm_file
}


## send email output with parameters:
##   $1: log file
##   $2: recipient list
#
function output_mail() {
  local mailfile="$DNSBRUTE_HOME/var/.mailfile"
  local date="$( date +"%d/%m/%Y %H:%M:%S" )"

  # call output_file to do the hard work for us
  output_file $1 $mailfile
  cat $mailfile | mail -s "$PROGNAME report for $date" "$2"

  rm -f $mailfile
}


## send syslog output with parameters:
##   $1: log file
##   $2: syslog server
##   $3: syslog port
##   $4: syslog priority
#
function output_syslog() {
  local stripcomm_file="$DNSBRUTE_HOME/var/.stripcomm_file"

  # strip comments from logfile
  sort $1 | egrep -v "^#" > $stripcomm_file

  # if running on Linux/FreeBSD, set remote options
  case "$( uname )" in
    "Linux")   local remote="-n $2 -P $3 -d" ;;
    "FreeBSD") local remote="-h $2 -P $3" ;;
    *)         local remote="" ;;
  esac

  while read line; do
    local loginfo=( $(echo $line | sed 's/,/ /g') )
    local msg="Suspicious DNS ${loginfo[1]} reported IP ${loginfo[2]} for domain ${loginfo[0]} , contrasting with Trusted DNS ${loginfo[3]} reported IP ${loginfo[4]}"
    logger $remote -p $4 -t "$PROGNAME" "$msg" 
  done < $stripcomm_file

  rm -f $stripcomm_file
}
