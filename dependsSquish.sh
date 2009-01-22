#!/bin/bash
#
# Dufflebunk, Started June 17, 2002
# Last modified June 17. Version 0.2
# dufflebunk at dufflebunk dot homeip (dot) netnet
# Yeah, I'll toss this under the latest GPL (v2)
#
# I used global vars, so sue me. I think this is as fast as it can go baring major changes.
# It will only return spells that are listed as an arg, even if there are intermediate depends not listed

. /etc/sorcery/config

#Must have spaces for the greps in depends and optional_depends
# SPELLS=all spells that have to be checked, CHECKED=spells tha have been checked
export SPELLS=" $* "
export CHECKED=" "

function usage ()
{
cat << EOF
Usage:
dependsSquish [spell] [spell] ...
EOF
}
function inputCheck ()
{
#	for i in $*; do
#		gaze where $i | grep -q "not found" && 	\
#			echo "$i doesn't exist." && 	\
#			return 1
#		echo "$* " | grep -q ".*$i .* $i.*" &&	\
#			echo "Why are you putting duplicates in?" &&
#			return 1
#	done
	return 0
}

# Called by spell/DEPENDS
# checks if a dependancy is listed in SPELLS, then recurses for all depends of this dependancy
function depends ()
{ #$1=dependancy, $2, $3
	[[ $CURR_BAD ]] && return 1 #This probably shouldn't happen... but I'm too lazy to check

	#if a dependancy of this spell is in SPELLS, then this tree cannot be cast yet
	# Mark tree as Bad for now, and return
	if echo "$SPELLS" | grep -q -m 1 " $1 " ; then 
		export CURR_BAD="B"	
		return 1
	fi
	
	#this dependancy is ok, so check depends if this depends (recurse)
	do_depends $1
	echo "$1 alread done or not in list." > /dev/stderr
	return ${#CURR_BAD}
}
#Same as depends
function optional_depends ()
{ #$1=dependancy, $2, $3
	depends $*
	return $?
}

# returns absolute path to the spell directory
function where ()
{
  gaze -q where -path $1
}

# if a DEPENDS file for a spell is not found
function no_depends ()
{
	echo "$1 has no dependancies or does not exist" > /dev/stderr
	return 0
}

# checks the dependancies of a spell for the existance of an entry in SPELLS
#  breaks out if an existing dependancy has been found
#  breaks out if this spell has already been checked and listed
function do_depends ()
{ #$1=spell to check
	[[ $CURR_BAD ]] && return 1
	echo "${CHECKED} ${CURR_CHECKED}" | grep -q -m 1 " $1 " && echo "Skipping $1" >&2 && return 0
	DEP=`where $1`
	echo "Looking at $DEP" > /dev/stderr

	#If there's a depends file then run it
	[ -x "$DEP/DEPENDS" ] && . $DEP/DEPENDS
	! [ -x "$DEP/DEPENDS" ] && no_depends $i

	#Leave a note that this tree has been checked
	export CURR_CHECKED="${CURR_CHECKED}${1} "

	return ${#CURR_BAD} #0 if no bad depends were found, 1 otherwise
}

function main ()
{
	echo "Starting WHILE loop" > /dev/stderr

	#Keep on looping while there are more spells to check in SPELLS
	num_left=`echo $SPELLS | awk '{ print NF } '`

	while [ $num_left -gt 0 ] ; do
	
		#Go through SPELLS 
		echo "Starting FOR loop" > /dev/stderr
		for i in $SPELLS; do
	
			#reset CURR_BAD since we don't know if the depends for this spell have been taken care of
			export CURR_BAD=""
			#reset CURR_CHECKED. It's used to keep track of what spells have been checked already for this spell ($i)
			export CURR_CHECKED=" "
			
			#if there are no bad depends, this spell is good. Remove it from SPELLS and add it to CHECKED
			if do_depends $i ; then
				echo "$i "
				export SPELLS="`echo "$SPELLS" | sed 's/\(.*\) '$i' \(.*\)/\1 \2/'`"
				export CHECKED="${CHECKED}${i} "
			fi
		done
		#echo
		echo "Done FOR loop" > /dev/stderr
	
		#if no spells were removed, something bad happened.
		if [[ num_left == `echo $SPELLS | awk '{ print NF } '` ]] ; then
			echo "Something is wrong... circular dependancy perhaps?"
			echo "Spells remaining: $SPELLS"
			break
		fi
		num_left=`echo $SPELLS | awk '{ print NF } '`
		echo "Looping WHILE loop" > /dev/stderr
		#read
	done
	echo "Done WHILE loop" > /dev/stderr
}

#Check for help request
[ "$1" == "--help" ] && usage && exit

( ! inputCheck $*) && exit

echo "Spells: $SPELLS" > /dev/stderr

main $*
