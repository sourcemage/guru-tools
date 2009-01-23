#---------------------------------------------------------------------
##
## Lists all spells created by author(s)
## @param author (any part of the HISTORY title header; case insensitive)
## @param author (optional)
## @param ...
##
#---------------------------------------------------------------------
. /etc/sorcery/config 

function show_creator()  {
  local spell spells

  spells=$(
    for spell in $(codex_get_all_spells); do
      if [[ -e $spell/HISTORY ]]; then
        tac $spell/HISTORY | grep -m1 -E "^(199|20)" | grep -iq "$1" &&
        echo ${spell##*/}
      fi
    done
  )
  message "$spells" | column
  local count=$(wc -l <<< "$spells")
  message "Total: $count"
}

for i in "$@"; do
  message "Spells created by $i:"
  show_creator "$i"
  message
done
