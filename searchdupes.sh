#!/bin/bash

# depth-first traversal of the grimoire's spells.
#
# supply args: <path-grimoire> [<optional-section>]
# if no section, does entire grimoire.

grimoire=$1
cd $grimoire # grimoire
sec=$2

[ -z "$sec" ] && sec=. # blank, then do whole grimoire
if [ ! -d "./$sec" ]; then
  sec="*/$sec"
fi

[ ! -f /tmp/depends ] &&
echo -n "Making dependency index of $grimoire in /tmp/depends ... " > /dev/stderr &&
  find . -name DEPENDS |
    while read DEPENDS; do
      cat "$DEPENDS" |
        grep -v optional |
        grep 'depends' |
        sed -e 's/.*depends[ 	]*//g' -e 's/[ 	&].*//g' |
          while read DEPEND; do
            echo "$DEPENDS:$DEPEND";
          done
    done > /tmp/depends && echo done

function dep() {
  grep /$1/ /tmp/depends | cut -d: -f2| tr -d '"'"'" |
    while read LINE; do
      touch /tmp/mark.file.$$
      if ! grep -q ^$LINE /tmp/mark.file.$$ ; then
        echo "$2$LINE" > /dev/stderr &&
        echo $LINE $1 >> /tmp/mark.file.$$ &&
        dep $LINE "$2  "
      else
        [ -n "$LINE" ] &&
        echo "$2dupe: $LINE of $1 first seen in $(
          grep ^$LINE /tmp/mark.file.$$ | cut -d' ' -f2 | head -n 1
        )" > /dev/stderr;
      fi
    done
    [ -z "$2" ] && rm /tmp/mark.file.$$ 2> /dev/null
}

echo "Searching $sec in $grimoire..." > /dev/stderr

find $sec -name DETAILS | sed -e 's!^.*/\(.*\)/DETAILS!\1!' |
  while read SP; do
    echo "== $SP =="
    dep $SP 2>&1 | grep '  dupe: .*'"$SP"'$\|^dupe'
  done
