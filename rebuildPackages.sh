#!/bin/bash
#1305 2377 3124
#
# Dufflebunk at dufflebunk dot homeip dot neet
# May 26, 2002
#
# Yeah, I'm tossing this under the latest GPL (v2)

ACTIVITY_FILE=/var/log/sorcery/activity
PACKAGES_FILE=/dev/stdout
OUT_FILE=/dev/stderr
TEMP_FILE=/tmp/rebuildPackages.$$.activity
#PACKAGES_FILE=/var/state/sorcery/packages


if [ -f $PACKAGES_FILE ] ; then echo "$PACKAGES_FILE exists. I will overwrite."; fi

#The successful activity in reverse chrono
SUCC_ACTIVITY=`sed -n '/.*dispel.*success.*/p
/.*cast.*success.*/p' $ACTIVITY_FILE | tac`
echo "SUCC_ACTIVITY: $SUCC_ACTIVITY" >> $OUT_FILE

ALL_PACKAGES=`echo "$SUCC_ACTIVITY" | awk '{print $3;}' | sort | uniq`

echo "All packages ever installed:" >> $OUT_FILE
echo $ALL_PACKAGES >> $OUT_FILE
echo "Parsing activity and recreating packages." >> $OUT_FILE

for PACKAGE in $ALL_PACKAGES; do
	# We want the last action with the package first
	ACTIVITY=`echo "$SUCC_ACTIVITY" | grep "[[:space:]]$PACKAGE[[:space:]]"`
	LAST_ACTIVITY=`echo $ACTIVITY | head -n 1 | awk '{print $2;}'`
#echo "$PACKAGE ($LAST_ACTIVITY): $ACTIVITY"
	if [ "$LAST_ACTIVITY" == "cast" ] ; then
		echo $ACTIVITY | head -n 1 | awk '{gsub(":.*","", $1); printf("%s:%s:installed:%s\n", $1, $3, $4);}' >> $TEMP_FILE
	else
		echo "$PACKAGE was last $LAST_ACTIVITY, not added to packages." >> $OUT_FILE
	fi
done

echo "Done." >> $OUT_FILE
echo "Sorting entries chronologicaly" >> $OUT_FILE

sort -n $TEMP_FILE | awk -F ':' '{printf("%s:%s:%s:%s\n", $2, $1, $3, $4);}' > $PACKAGES_FILE
