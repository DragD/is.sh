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
      'false VALUE'

    printf '\nNegation:\n'
    printf "  ${name} %s\n" \
      'not equal VALUE_A VALUE_B'

    printf '\nOptional article:\n'
    printf "  ${name} %s\n" \
      'not a number VALUE' \
      'an existing PATH' \
      'the file PATH'

    unset ${BASH_VERSION:+-f}
    exit 0
  }

  is::show.version() {
    printf '%s %s\n' "${name}" "${version}"

    unset ${BASH_VERSION:+-f}
    exit 0
  }

  [ "$1" = '--help' ] && is::show.help
  [ "$1" = '--version' ] && is::show.version

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
      [ -f "$1" ]; return $?;;
    dir|directory)
      [ -d "$1" ]; return $?;;
    link|symlink)
      [ -L "$1" ]; return $?;;
    existent|existing|exist|exists)
      [ -e "$1" ]; return $?;;
    readable)
      [ -r "$1" ]; return $?;;
    writeable)
      [ -w "$1" ]; return $?;;
    executable)
      [ -x "$1" ]; return $?;;
    available|installed)
      which "$1"; return $?;;
    empty)
      [ -z "$1" ]; return $?;;
    number)
      printf '%s' "$1" | grep -E '^[0-9]+(\.[0-9]+)?$'; return $?;;
    older)
      [ "$1" -ot "$2" ]; return $?;;
    newer)
      [ "$1" -nt "$2" ]; return $?;;
    gt)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 > $2 ? 0 : 1}"; return $?;;
    lt)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 < $2 ? 0 : 1}"; return $?;;
    ge)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 >= $2 ? 0 : 1}"; return $?;;
    le)
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 <= $2 ? 0 : 1}"; return $?;;
    eq|equal)
      [ "$1" = "$2" ] && return 0;
      is not a number "$1" && return 1;
      is not a number "$2" && return 1;
      awk "BEGIN {exit $1 == $2 ? 0 : 1}"; return $?;;
    match|matching)
      printf '%s' "$2" | grep -xE "$1"; return $?;;
    substr|substring)
      printf '%s' "$2" | grep -F "$1"; return $?;;
    true)
      [ "$1" == true ] || [ "$1" == 0 ]; return $?;;
    false)
      [ "$1" != true ] && [ "$1" != 0 ]; return $?;;
  esac > /dev/null

  return 1
}

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f is
else
  is "${@}"
  exit $?
fi
