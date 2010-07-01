#!/bin/bash

## hashcheck.sh
# by Bor Kraljič <pyrobor[at]ver[dot]si>
#
# USAGE: hashcheck.sh spell(s)
#
# verifies the spell(s) source files 
#
#
. /etc/sorcery/config

# we don't need any input...
PROMPT_DELAY=0

# paste data even if we interupt withc ctrl-c :)
trap 'message "${PROBLEM_COLOR}control-c${DEFAULT_COLOR}"; end_hashcheck 1' INT

function show_usage() {
usage="${MESSAGE_COLOR}Usage: ${SPELL_COLOR}$(basename $0) ${FILE_COLOR}spell(s)
${MESSAGE_COLOR}\t-s|--section <section>\t to check whole section
\t-g|--grimoire <grimoire> to check whole grimoire
\t-v|--verbose\t\t show output from summon and verify_file
\t-d|--download\t\t force download of sources
\t-rf|--remove-failed\t remove sources that are unverified
\t-ra|--remove-all\t remove all sources after check
\t-h|--help\t\t show this help"
message "$usage"
}

# process the params
while [[ "$1" == -* ]] # 2) params
  do
  case "$1" in
     "-s"|"--section")  wanted_spells=$(codex_get_spells_in_section $(codex_find_section_by_name $2)|cut -f8 -d/);      shift 2;;
     "-g"|"--grimoire")  wanted_spells=$(codex_get_all_spells $(codex_find_grimoire $2)| cut -f8 -d/);          shift 2;;
     "-v"|"--verbose") verbose_mode="on" ; shift ;;
     "-d"|"--download") re_download="-d"; shift ;;
     "-rf"|"--remove-failed")   remove_sources="failed"; shift ;;
     "-ra"|"--remove-all")   remove_sources="all"; shift ;;
     "-h"|"--help"|*) show_usage; exit 2 ;;
  esac
done

if [[ $wanted_spells == "" ]]; then
  wanted_spells="$@"
fi



function end_hashcheck() {
  local exit_status=$1
  if [[ $failed_spells == "" ]] && [[ $dl_failed_spells == "" ]]; then
    message "${MESSAGE_COLOR}All spells passed the the hashcheck!${DEFAULT_COLOR}"
    set_term_title "success"
  else
    if [[ $failed_spells != "" ]]; then
      no_failed=$(echo $failed_spells|wc -w)
      message "${PROBLEM_COLOR}The following spells failed ($no_failed):"
      message "${SPELL_COLOR}$failed_spells${DEFAULT_COLOR}"
    fi
    
    if [[ $dl_failed_spells != "" ]]; then
      no_failed_dl=$(echo $dl_failed_spells|wc -w)
      message "${PROBLEM_COLOR}The following spells failed to download ($no_failed_dl):"
      message "${SPELL_COLOR}$dl_failed_spells${DEFAULT_COLOR}"
    fi
    set_term_title "Failed"
  fi
  exit $exit_status
}

function ver_message() {
  local msg=$1
  if [[ $verbose_mode == on ]]; then
    message "$msg"
  else
    message -n "$msg"
  fi
}

checked=1
total_spells=$(echo $wanted_spells| wc -w)

for spell in $wanted_spells; do
  set_term_title "checking $spell ($checked of $total_spells)"
  message -n "${SPELL_COLOR}$spell${MESSAGE_COLOR} : \t"
  
  if ! codex_does_spell_exist $spell; then
    true
  elif [[ $(sources $spell) == "" ]]; then
    message "${MESSAGE_COLOR}spell doesn't have sources...  SKIPING"
  else
    ver_message "Getting sources${MESSAGE_COLOR} ... "
    if [[ $verbose_mode == on ]]; then
      summon $re_download $spell
      summon_rc=$?
    else
      summon $re_download $spell > /dev/null 2>&1
      summon_rc=$?
    fi
    
    if [[ $summon_rc != 0 ]]; then
      message "\t${PROBLEM_COLOR}DOWNLOAD FAILED.${DEFAULT_COLOR}"
      dl_failed_spells="$dl_failed_spells $spell"
    else
      (
        ver_message  "\t${MESSAGE_COLOR}Checking ..."
        codex_set_current_spell_by_name $spell
        for suffix in '' $(get_source_nums); do
          if [[ $verbose_mode == on ]]; then
            verify_file "$suffix"
            verify_rc=$?
          else
            verify_file "$suffix" > /dev/null 2>&1
            verify_rc=$?
          fi
          
          if  [[ $verify_rc != 0 ]]; then
            exit 1
          fi
        done
      )
      subshell_rc=$?

      if [[ $subshell_rc != 0 ]]; then
        failed_spells="$failed_spells $spell"
        message "\t${PROBLEM_COLOR}FAILED.${DEFAULT_COLOR}"
        if [[ $remove_sources == "failed" ]] || [[ $remove_sources == "all" ]]; then
          for spell_source in $(sources $spell); do
            rm $SOURCE_CACHE/$spell_source
          done
        fi
      else
        message "\t${QUERY_COLOR}Done.${DEFAULT_COLOR}"
        if [[ $remove_sources == "all" ]]; then
          for spell_source in $(sources $spell); do
            rm $SOURCE_CACHE/$spell_source
          done
        fi
      fi
      
    fi
  fi
  checked=$(( $checked + 1 ))
done

end_hashcheck 0

echo "you shouldn't be here. ERRROR"
