#!/bin/bash



MAKE_NAME="/tmp/grimoireCircCheck.Makefile"
ALL_SPELLS=""

function depends()
{ echo -n "$1 ">>$MAKE_NAME; }
function optional_depends()
{ echo -n "$1 ">>$MAKE_NAME; }
function requires()
{ return 0 ;    }
function grep()
{ return 0 ;    }
function spell_installed()
{ return 0 ;    }
function message()
{ return 0 ;    }

rm $MAKE_NAME

for GRIM in $* ; do  #Each grimoire listed
	pushd $GRIM
	for SPELL_DIR in `find -type d -maxdepth 2` ; do
		echo  "Looking at $GRIM/$SPELL_DIR  "
		SPELL=$(basename $SPELL_DIR)
		echo -n "$SPELL: " >> $MAKE_NAME
		[ -f $SPELL_DIR/DEPENDS ] && source $SPELL_DIR/DEPENDS >/dev/null
		ALL_SPELLS="$ALL_SPELLS $SPELL"
		echo >> $MAKE_NAME
	done
	popd
done

echo "all: $ALL_SPELLS" >>$MAKE_NAME

make -k -n -r -f $MAKE_NAME all
