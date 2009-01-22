#!/bin/bash

#this dumps a listing as follows:
#section:spell:version:md5sum

#one option is given: a full path to a grimoire
GPATH=$1
IFS="
"
cd $GPATH
for section in $(ls); do
  if [ -d $section ]; then
    cd $section
    for spell in $(ls); do
      if [ -d $spell ]; then
       	SCRIPT_DIRECTORY=$GPATH/$section/$spell
	if [ -x $SCRIPT_DIRECTORY/DETAILS ];then 

        	unset VERSION
        	source $SCRIPT_DIRECTORY/DETAILS 2>/dev/null >/dev/null #be quiet!

        	cd $SCRIPT_DIRECTORY
        	md5=$(find|sort|xargs md5sum 2>/dev/null | md5sum|cut -f1 -d' ')
        	cd ..
        	echo $section:$spell:$VERSION:$md5
        fi
      fi
    done
    cd ..
  fi
done
