#!/bin/sh
# ASH version of the BASH3 Boilerplate: ini_val
# @see: https://github.com/kvz/bash3boilerplate/blob/master/src/ini_val.sh
#
# This file:
#  - Can read and write .ini files using pure ash
#
# Limitations:
#
#  - All keys inside a section of the .ini file must be unique
#  - Optional comment parameter for the creation of new entries
#
# Usage as a function:
#  source ini_val.sh
#  ini_val data.ini connection.host 127.0.0.1 "Host name or IP address"
#
# Usage as a command:
#  ini_val.sh data.ini connection.host 127.0.0.1 "Host name or IP address"
#
# Based on a template by BASH3 Boilerplate v2.4.1
# http://bash3boilerplate.sh/#authors
#
# The MIT License (MIT)
# Copyright (c) 2013 Kevin van Zonneveld and contributors
# You are not obligated to bundle the LICENSE file with your b3bp projects as long
# as you leave these references intact in the header comments of your source files.

ini_val() {
    local file="${1:-}"
    local sectionkey="${2:-}"
    local val="${3:-}"
    local comment="${4:-}"
    local delim="="
    local comment_delim=";"
    local section=""
    local key=""
    local current=""
    # add default section
    local section_default="default"

    # Split on . for section. However, section is optional
    #read section key <<<$(IFS="."; echo ${sectionkey})
    IFS="." read section key <<EOF
$sectionkey
EOF
  if [ -z "${key}" ]; then
    key="${section}"
    section="${section_default}"
  fi

  # touch file if not exists
  if [ ! -f "$file" ]; then
     touch "$file"
  fi


  # get current value (if exists)
  current=$(sed -En "/^\[/{h;d;};G;s/^${key}([[:blank:]]*)${delim}(.*)\n\[${section}\]$/\2/p" "${file}"|awk '{$1=$1};1')
  # get current comment (if exists)
  current_comment=$(sed -En "/^\[${section}\]/,/^\[.*\]/ s|^(${comment_delim}\[${key}\])(.*)|\2|p" "${file}"|awk '{$1=$1};1')


  if ! grep -q "\[${section}\]" "${file}"; then
    # create section if not exists (empty line to seperate new section for better readability)
    echo  >> "${file}"
    echo "[${section}]" >> "${file}"
  fi

  #local current=$(awk -F "${delim}" "/^${key}${delim}/ {for (i=2; i<NF; i++) printf \$i \" \"; print \$NF}" "${file}")
  if [ -z "${val}" ]; then
    # get a value
    echo "${current}"
  else
    # set a value
    if [ -z "${section}" ]; then
      # if no section is given, propagate the default section
      section=${section_default}
    fi

    if [ -z "${comment}" ]; then
      # if no comment given, keep old comment
      comment="${current_comment}"
    fi

    # maintenance area
    # a) remove comment if new given / respect section
    sed -i.bak "/^\[${section}\]/,/^\[.*\]/ s|^\(${comment_delim}\[${key}\] \).*$||" "${file}"
    # b) remove old key / respect section
    sed -i.bak "/^\[${section}\]/,/^\[.*\]/ s|^\(${key}[[:space:]]*=\).*$||" "${file}"
    # c) remove all empty lines in ini file
    sed -i.bak '/^[[:space:]]*$/d' "${file}"
    # d) insert line break before every section for better readability (except first occurence)
    #sed -i.bak $'s/^\\[/\\\n\\[/g' "${file}"
    sed -i.bak 's/^\[/\n\[/g' "${file}"
    sed -i.bak -n '/./,$p' "${file}"

      # add to section
    if [ -z "${comment}" ]; then
      # add new key/value _without_ comment
      RET="/\\[${section}\\]/a\\
${key}${delim}${val}"
    else
      # add new key/value _with_ preceeding comment
      RET="/\\[${section}\\]/a\\
${comment_delim}[${key}] ${comment}\\
${key}${delim}${val}"
    fi
    sed -i.bak -e "${RET}" "${file}"
    # this .bak dance is done for BSD/GNU portability: http://stackoverflow.com/a/22084103/151666
    rm -f "${file}.bak"
  fi
}

# check sourced or called
case ${0##*/} in
  sh|-sh|dash|-dash)
    # file has been sourced
    ;;
  *)
    # file has been called
    ini_val "${@}"
    exit ${?}
    ;;
esac
