#!/usr/bin/env bash
###
 # @author Józef Sokołowski
 # @copyright 2015-2019 Józef Sokołowski
 # @license MIT
 # @see https://github.com/qzb/is.sh
##

is() {
  local name="${FUNCNAME[0]}" version='1.1.0'

  is::show.help() {
    printf 'Conditions:\n'
    printf "  ${name} %s\n" \
      'equal VALUE_A VALUE_B' \
      'matching REGEXP VALUE' \
      'substring VALUE_A VALUE_B' \
      'empty VALUE' \
      'number VALUE' \
      'gt NUMBER_A NUMBER_B' \
      'lt NUMBER_A NUMBER_B' \
      'ge NUMBER_A NUMBER_B' \
      'le NUMBER_A NUMBER_B' \
      'file PATH' \
      'dir PATH' \
      'link PATH' \
      'existing PATH' \
      'readable PATH' \
      'writeable PATH' \
      'executable PATH' \
      'available COMMAND' \
      'older PATH_A PATH_B' \
      'newer PATH_A PATH_B' \
      'true VALUE' \
      'false VALUE' \
      'set NAME, var NAME, variable NAME' \
      'false VALUE' \
      'alias NAME' \
      'builtin NAME' \
      'function NAME, fn NAME' \
      'keyword NAME'

    printf '\nNegation:\n'
    printf "  ${name} %s\n" \
      'not equal VALUE_A VALUE_B'

    printf '\nOptional article:\n'
    printf "  ${name} %s\n" \
      'not a number VALUE' \
      'an existing PATH' \
      'the file PATH'

    unset ${BASH_VERSION:+-f}
  }

  is::show.version() {
    printf '%s %s\n' "${name}" "${version}"

    unset ${BASH_VERSION:+-f}
  }

  [ "$#" -eq 0 ] && is::show.version && is::show.help && return 0
  [ "$1" = '--help' ] && is::show.help && return 0
  [ "$1" = '--version' ] && is::show.version && return 0

  local condition="$1" && shift 1

  if [ "$condition" = 'not' ]; then
    ! is "${@}"
    return $?
  fi

  if [ "$condition" == 'a' ] || [ "$condition" == 'an' ] \
    || [ "$condition" == 'the' ]; then
      is "${@}"
      return $?
  fi

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
    empty)
      [ -z "$1" ];;
    number)
      printf '%s' "$1" | grep -E '^[0-9]+(\.[0-9]+)?$';;
    older)
      [ "$1" -ot "$2" ];;
    newer)
      [ "$1" -nt "$2" ];;
    gt)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 > $2 ? 0 : 1}";;
    lt)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 < $2 ? 0 : 1}";;
    ge)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 >= $2 ? 0 : 1}";;
    le)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 <= $2 ? 0 : 1}";;
    eq|equal)
      [ "$1" = "$2" ] && return 0;
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 == $2 ? 0 : 1}";;
    match|matching)
      printf '%s' "$2" | grep -xE "$1";;
    substr|substring)
      case $2 in
        *$1*) true;; *) false;; esac;;
    true)
      [ "$1" == true ] || [ "$1" == 0 ];;
    false)
      [ "$1" != true ] && [ "$1" != 0 ];;
    set|var|variable)
      # cross-sh-compatible sans `pdksh v5.2.14` treats expanded empty as unset
      # @see http://mywiki.wooledge.org/BashFAQ/083
      local x; eval x="\"\${$1+set}\""; [ "$x" = 'set' ];;
    alias)
      is '_type' 'alias' "$1" || [ "${BASH_ALIASES[$1]+"set"}" = 'set' ];;
    builtin)
      is '_type' 'builtin' "$1";;
    fn|function)
      is '_type' 'function' "$1";;
    keyword)
      is '_type' 'keyword' "$1";;
    _type)
      LANG=C \type ${BASH_VERSION:+-t} "$2" 2> /dev/null \
        | \grep "${KSH_VERSION:+"$2 is a "}$1" 1> /dev/null;;
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
