#!/bin/bash
#set -x
#---------
## By Paul Mahon, Feb 1, 2004
## Licence is GPL v2 or higher
## <p>
## Pass the spells you want to check as arguments
## No arguments and it'll check all spells installed.
## <>
## glibc and xfree86 are exceptions. This does not do a 
## recursive check.
## <p>
## Note: If more than one spell provides a library, only the
## first is mentioned. The rest are ignored.
##
#----------

. /etc/sorcery/config

#---------
## Checks the needed libraries for an ELF binary or library
## Check for spell providing needed lib, and that the providing 
## spell is listed as a dependancy.
## 
## @param File to check (including path)
##
#---------
function CheckELF()
{
	local libDeps=$(ldd $1|sed -n '/0x/s/^.*[[:blank:]]\([^[:blank:]]*\)[[:blank:]](0x.*$/\1/p')
	local notFound=$(ldd $1 | awk '/not found/{print "\""$1"\"";}' )
	local ret=0

	for lib in $libDeps ; do
    # glibc links are special. so lets readlink for those.
    if [[ -L $lib ]] && gaze from $(readlink -f $lib) |grep -iq glibc ; then
      lib=$(readlink -f $lib)
    fi
    # files that have lib/../ are not in install logs
    if echo $lib |grep -iq ".." ; then
      lib=$(readlink -f $lib)
    fi
    # this sed will fail if version have "-" in it...
		provider=$(gaze from $lib | sed -n '1,1s/^\([^:]*\)-\([^-:]*\)\?:.*$/\1/p')
		if ! [[ $provider ]] ; then
			echo -e "$1 needs $lib. \n\tNot provided by anyone!"
			ret=1
			continue
		fi
		if 	[[ $provider != glibc ]] && 	
			[[ $provider != xfree86 ]] &&	
			[[ $provider != $SPELL ]] &&
			! grep -Eq "^$SPELL:$provider:on:" $DEPENDS_STATUS
		then
			echo -e "$1 needs $lib. 
\tProvided by $PROBLEM_COLOR$provider$DEFAULT_COLOR, but not in DEPENDS."
			let ret+=1
			continue
		fi
		
	done
	return $ret	
}

if [ $# -eq 0 ] ; then
	SPELLS=$(codex_get_all_spells | get_basenames)
else
	SPELLS="$*"
fi

NUM_BAD=0

for SPELL in $SPELLS ; do
	echo "Looking at $SPELL"
	spell_ok $SPELL || { echo "Not installed, skipping..." && continue; } 
	while read FILE ; do
		if [ -x $FILE ] && file $FILE | grep -q ELF ; then
			CheckELF $FILE
			let NUM_BAD+=$?
		fi
	done < <(gaze install $SPELL)
done
echo "Number bad: $NUM_BAD"
[ $NUM_BAD -eq 0 ] && exit 0
exit 1

