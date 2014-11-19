#!/usr/bin/env bash
# locale.sh, 2014/11/18 15:25:19 fbscarel $

## locale utility functions
#

## parse locale list $1, check for invalid parameters
#
function locale_parse() {
  local locale_file="$conf_dir/locales"

  for locale in $1; do
    if ! grep "$locale" $locale_file &> /dev/null; then
      echo "[!] Invalid locale $locale ."
      echo "[!] Please refer to the list of valid locales on $locale_file ."
      exit 1
    fi
  done
}


## remove unwanted locales, keeping only those in list $1
#
function locale_remove() {
  # append 'en_US' as a compatibility locale
  local keep_locales="$1|en_US"

  # convert list of locales into pipe-separated list
  # we also keep territory and language strings as a safeguard, besides
  # using hyphen '-' as an alternate separator
  #
  # for the 'en_US' locale, we'll then keep:
  #   en, us, en_us, en-us
  #
  # this goes for all locales in the list
  for loc in $keep_locales; do
    keep_locales="$keep_locales $( echo $loc | tr '_' ' ' ) $( echo $loc | tr '_' '-' )"
  done
  keep_locales="$( echo $keep_locales | xargs -n1 | sort | uniq | xargs | sed 's/  */|/g' | tr '[:upper:]' '[:lower:]' )"

  # for each locale directory to process, enable extended pattern matching,
  # case-insensitive matching and remove all but locales to be kept
  if [ -f "$LOCALE_DIRS" ]; then
    while read locdir; do
      bash -O extglob -O nocaseglob -c "rm -rf $build_dir/$locdir/!($keep_locales)"
    done < $LOCALE_DIRS
  fi
}
