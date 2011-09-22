#!/bin/bash
# Version 0.4
# Paul Mahon, April 24, 2002.
# dufflebunk (at) dufflebunk (dot) homeip (dot) nnet
# Yeah, I'm tossing this under the latest GPL (v2)
#
# change to avoid race condition in temp file and 
#  -follow to find suggested by Sergey A. Lipnevich
#
# --mono inspired by some guy on IRC who was grep'ping
# added a 10s connection-timeout to curl
# --suggestion because I had the code and couldn't think 
#  of anywhere else to put it.
#
# Multithreaded: 1 thread/URL when check each spell
#
# TODO:
#  Perhaps check the syntax of spell files?
#  

. /etc/sorcery/config
. ${SUBROUTINES}
SUGGESTIONS=""
GRIMOIRE="/var/lib/sorcery/codex/devel"

CONN_TIMEOUT=30
TIMEOUT=30	#seconds. gnome.org is shitty and takes at least 20s.
TRIES=4		#4 tries of TIMEOUT each

function usage()
{
cat << EOF
Usage: checkGrimoire.sh [--mono] [--suggestions] [ --grimoire <path> ] [section] [section] [section] ...
No arguments will cause the whole grimoire to be checked.
Otherwise all spells in the given sections will be checked.
--mono removes the colours. Usefull when using grep and stuff.
--suggestion uses an FTP search to try to find alternates if all links are broken.
--grimoire <path> Set path to the grimoire you want the sections to be in.
EOF
}

function do_args()
{
	let numShift=0;
	while true; do
    	case $1 in
			-h|--help)  usage ; exit  ;;
			-m|--mono)
				DEFAULT_COLOR=""
				SPELL_COLOR=""
				PROBLEM_COLOR=""
				MESSAGE_COLOR=""
				let numShift++
           			shift 1
	            ;;
			-s|--suggestions)  [[ `lynx --help` ]] && SUGGESTIONS="y" ; let numShift++ ; shift 1 ;;
			-g|--grimoire) GRIMOIRE="$2"; let numShift+=2; shift 2 ;;
			*)  return $numShift  ;;
		esac
	done
}

function check_thread ()
{ # $1=URL $2=file
		
	for (( i=0 ; $i < $TRIES  ; i++ )) ; do
		# disable all output, only get first 100b, timeout of 10s
		curl -f -s -r 0-100 -m $TIMEOUT --connect-timeout $CONN_TIMEOUT $1 -o $2 2>&1
		if [ -s $2 ] ; then
			echo "good" > $2.d
			return
		fi
	done

	echo -e "\t${DEFAULT_COLOR}$j is ${PROBLEM_COLOR}Broken";
	touch $2.d
	return 1;

}

FILE=/tmp/`basename $0`.$$

do_args $*
shift $?

if [ $# -eq 0 ] ; then
	SPELLS=`find ${GRIMOIRE} -follow -mindepth 2 -maxdepth 2 -type d  -printf "%f\n"`
else
	SPELLS=""
	# must get spells only in section directory
	pushd ${GRIMOIRE}
	SPELLS=`find $* -follow  -mindepth 1 -maxdepth 1 -type d -printf "%f\n"`
	popd
fi

rm $FILE.* 2>/dev/null
for i in $SPELLS; do
	# make sure there was no mistake and the directory is indeed a spell (kde3)
	SECTION=`find_section $i`
	if ! [ -x $GRIMOIRE/$SECTION/$i/DETAILS ] ; then continue; fi
	echo -e "${DEFAULT_COLOR}Spell ${SPELL_COLOR}${i}${DEFAULT_COLOR} ($(gaze where "$i")):"
	# set the SOURCE_URL stuff
	SPELL=$i
	run_details $i
	
	let NUM_GOOD=0
	# check each source's url
	# First start one thread per URL in spell
	let COUNT=0
	for j in ${SOURCE_URL[*]}; do
		check_thread $j $FILE.$COUNT &
		let COUNT++
	done
	# Second, wait for notification that each thread is done
	for j in ${SOURCE_URL[*]}; do
		let COUNT-- 					# deincrement first because the COUNT is 1 high
		until [ -f $FILE.$COUNT.d ] ; do sleep 1; done
		[ -s $FILE.$COUNT.d ] && let NUM_GOOD++
	done
	rm $FILE.* 2>/dev/null
		# must unset the var or it persists into next spell
	unset SOURCE_URL
	
	# Third, output results for the spell
	if [ $NUM_GOOD -eq 0 ] ; then 
		echo -e "\t${PROBLEM_COLOR}0 links are good for $i in $(gaze where $i)!";
		if [ $SUGGESTIONS ]; then
	        	echo -e "${MESSAGE_COLOR}Suggested replacements (alltheweb.com):${DEFAULT_COLOR}"
				echo "---"
				FTP=`lynx -dump "http://www.alltheweb.com/search?cat=ftp&ftype=6&q=${SOURCE}" | \
					grep "${SOURCE}$" | awk '{print \$NF;}'`
				if [[ $FTP ]] ; then
	        		FTP=${FTP:="None found :("}
			        echo "$FTP"
			        echo -n "--- "
			        echo "$FTP" | wc | awk '{printf("%s", $1);}'
		        	echo " alternates found ---"
				else
					echo "None found :("
					echo "---"

				fi
	        fi
	elif [ $NUM_GOOD -eq 1 ] ; then echo -e "\t${MESSAGE_COLOR}1 link is good."
	elif [ $NUM_GOOD -gt 1 ] ; then echo -e "\t${MESSAGE_COLOR}${NUM_GOOD} links are good."
	fi
done
# to avoid colourful prompts:
echo -ne "${DEFAULT_COLOR}"
[ -f $FILE ] && rm $FILE

