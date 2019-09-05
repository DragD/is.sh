#!/usr/bin/env bash
###
 # @author Józef Sokołowski
 # @copyright 2015-2019 Józef Sokołowski
 # @license MIT
 # @see https://github.com/qzb/is.sh
##

is() {
  local name="${FUNCNAME[0]}" version='1.1.2'

  # shellcheck disable=SC2016
  is::show.help() {
    command printf 'Note:\n'
    command printf ' - %s\n   %s\n' \
      'The provided condition is case-insensitive.' \
        'i.e the following conditions are equivalent: `is dir` === `is DIR`' \
      'Conditions evaluate by value with the exception of those that' \
        'accept `COMMAND` or `NAME`; they will evaluate by reference.' \
      'Conditions may have multiple patterns they will match.' \
        'Those will be listed inline and comma separated.'

    command printf 'Conditions:\n'
    command printf "  ${name} %s\n" \
      'equal VALUE_A VALUE_B, eq VALUE_A VALUE_B' \
      'matching REGEXP VALUE, match REGEXP VALUE' \
      'substring VALUE_A VALUE_B, substr VALUE_A VALUE_B' \
      'empty VALUE' \
      'number VALUE, num VALUE' \
      'gt NUMBER_A NUMBER_B' \
      'lt NUMBER_A NUMBER_B' \
      'ge NUMBER_A NUMBER_B' \
      'le NUMBER_A NUMBER_B' \
      'file PATH' \
      'dir PATH, directory PATH' \
      'link PATH, symlink PATH' \
      'existent PATH, existing PATH, exist PATH, exists PATH' \
      'readable PATH' \
      'writeable PATH' \
      'executable PATH' \
      'available COMMAND, installed COMMAND' \
      'cmd COMMAND, command COMMAND' \
      'older PATH_A PATH_B' \
      'newer PATH_A PATH_B' \
      'true VALUE' \
      'false VALUE' \
      'bool VALUE, boolean VALUE' \
      'truthy VALUE' \
      'falsey VALUE' \
      'set NAME, var NAME, variable NAME' \
      'alias NAME' \
      'builtin NAME' \
      'function NAME, fn NAME' \
      'keyword NAME' \
      'array NAME' \
      'exported NAME, export NAME' \
      'int NAME, int VALUE, integer NAME, integer VALUE' \
      'hash NAME, dictionary NAME' \
      'in $VALUE NAME'

    command printf '\nNegation:\n'
    command printf "  ${name} %s\n" \
      'not equal VALUE_A VALUE_B'

    command printf '\nOptional article:\n'
    command printf "  ${name} %s\n" \
      'not a number VALUE' \
      'an existing PATH' \
      'the file PATH'

    command unset ${BASH_VERSION:+-f}
  }

  is::show.version() {
    command printf '%s %s\n' "${name}" "${version}"

    command unset ${BASH_VERSION:+-f}
  }

  is::tolower() {
    if [ "$IS_NOT_OLD_BASH" -eq 0 ]; then
      printf '%s' "${1,,}"
    else
      printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
    fi

    return 0
  }

  [ "$#" -eq 0 ] && is::show.version && is::show.help && return 0
  [ "$1" = '--help' ] && is::show.help && return 0
  [ "$1" = '--version' ] && is::show.version && return 0

  # Since we currently support bash v3.2.57, we can't use `"${1,,}"`
  local condition=$1 && shift 1
  condition=$(is::tolower "$condition")

  if [ "$condition" = 'not' ]; then
    ! is "${@}"
    return $?
  fi

  while [ "$condition" == 'a' ] || [ "$condition" == 'an' ] \
    || [ "$condition" == 'the' ]; do :
    condition=$(is::tolower "$1") && shift 1
  done

  # Note: case statements takes an expression & therefore doesn't need quotes
  #       it is being kept for consistency
  case "$condition" in
    file)
      [ -f "$1" ];;
    dir|directory)
      [ -d "$1" ];;
    link|symlink)
      [ -L "$1" ];;
    existent|existing|exist|exists)
      [ -e "$1" ];;
    readable)
      [ -r "$1" ];;
    writeable)
      [ -w "$1" ];;
    executable)
      [ -x "$1" ];;
    available|installed)
      which "$1";;
    cmd|command)
      command -v "$1" -- 2> /dev/null;;
    empty)
      [ -z "$1" ];;
    num|number)
      # for compatibility w/ versions < 3.2, regex must be stored in variable
      local regex='^[-+]?([0-9]+\.?|[0-9]*\.[0-9]+)$'
      [[ $1 = *[0-9]* && $1 =~ $regex ]] || is 'int' "$1";;
    older)
      [ "$1" -ot "$2" ];;
    newer)
      [ "$1" -nt "$2" ];;
    gt)
      is '_compare' "${@}" '>';;
    lt)
      is '_compare' "${@}" '<';;
    ge)
      is '_compare' "${@}" '>=';;
    le)
      is '_compare' "${@}" '<=';;
    eq|equal)
      [ "$1" = "$2" ] || is '_compare' "${@}" '==';;
    _compare)
      is number "$1" && is number "$2" \
        && command awk "BEGIN {exit $1 $3 $2 ? 0 : 1}";;
    match|matching)
      command printf '%s' "$2" | command grep -xE "$1";;
    substr|substring)
      case $2 in
        *$1*) true;; *) false;; esac;;
    true)
      [ "$1" == true ] || [ "$1" == 0 ];;
    false)
      [ "$1" != true ] && [ "$1" != 0 ];;
    bool|boolean)
      is 'truthy' "$1" || is 'falsey' "$1" || return 2;;
    truthy)
      case $(is::tolower "$1") in
        0|t|y|true|yes|on) true;; *) false;; esac;;
    falsey)
      case $(is::tolower "$1") in
        1|f|n|false|no|off) true;; *) false;; esac;;
    set|var|variable)
      # cross-sh-compatible sans `pdksh v5.2.14` treats expanded empty as unset
      # @see http://mywiki.wooledge.org/BashFAQ/083
      local x; eval x="\"\${$1+set}\""; [ "$x" = 'set' ];;
    array|builtin|keyword|hash|export)
      is '_type' "$condition" "$1" || false;;
    alias)
      is '_type' "$condition" "$1" || [ "${BASH_ALIASES[$1]+"set"}" = 'set' ];;
    fn|function)
      is '_type' 'function' "$1" || false;;
    int|integer)
      is '_type' 'integer' "$1" || [ "$1" -eq "$1" ] 2> /dev/null || false;;
    _type)
      local var reg='^declare -n [^=]+=\"([^\"]+)\"$'
      var=$(declare -p "$2" 2> /dev/null)

      while [[ $var =~ $reg ]]; do
        var=$(declare -p "${BASH_REMATCH[1]}" 2> /dev/null)
      done

      var="${var#declare -}"
      local prefix="${KSH_VERSION:+"$2 is a "}" attributes="${var%% *}"
      local expectedType="${prefix}$1" actualType="$prefix"

      case $attributes in
        *x*) [ "$expectedType" = 'export' ] && return 0;;
      esac

      case "$attributes" in
        a*) actualType+='array';;
        A*) actualType+='hash';;
        i*) actualType+='integer';;
        x*) actualType+='export';; # this shouldn't get hit anymore
         *) actualType=$(LANG=C \type ${BASH_VERSION:+-t} "$2" 2> /dev/null);;
      esac

      [ "$expectedType" = "$actualType" ] || return 2;;
    in)
      # currently does not handle being passed in a string instead of an array
      # use a subshell so as to preserve $IFS
      ( local localarray IFS=$'\a\b\a'
      eval "localarray=( \"\${$2[@]}\" )"
      is 'substring' "$IFS$1$IFS" "$IFS${localarray[*]}$IFS" );;
    *) false ;;
  esac 1> /dev/null

  return $?
}

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f is
else
  is "${@}"
  exit $?
fi
