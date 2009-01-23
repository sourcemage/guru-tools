#!/bin/bash
#
# searches for spells that have not been updated in $1 years
# (based on history entries)

ref_date=$(date -d "${1:-1} year ago" +%F)
codex=${2:-/var/lib/sorcery/codex}

for spell in $(find $codex -name HISTORY)
do
  [[ -s $spell ]] || continue # empty file
  spell_date=$(sed -n '/^20/{ s, .*$,,p;q}' $spell)
  if [[ $ref_date > $spell_date ]]
  then
    echo "$(basename $(dirname $spell)) was last updated before $ref_date ($spell_date)"
  fi
done
