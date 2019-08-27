#!/usr/bin/env bash
###
 # @author Józef Sokołowski
 # @copyright 2015-2019 Józef Sokołowski
 # @license MIT
 # @see https://github.com/qzb/is.sh
##

is() {
    if [ "$1" == '--help' ]; then
        cat << EOF
Conditions:
  is equal VALUE_A VALUE_B
  is matching REGEXP VALUE
  is substring VALUE_A VALUE_B
  is empty VALUE
  is number VALUE
  is gt NUMBER_A NUMBER_B
  is lt NUMBER_A NUMBER_B
  is ge NUMBER_A NUMBER_B
  is le NUMBER_A NUMBER_B
  is file PATH
  is dir PATH
  is link PATH
  is existing PATH
  is readable PATH
  is writeable PATH
  is executable PATH
  is available COMMAND
  is older PATH_A PATH_B
  is newer PATH_A PATH_B
  is true VALUE
  is false VALUE

Negation:
  is not equal VALUE_A VALUE_B

Optional article:
  is not a number VALUE
  is an existing PATH
  is the file PATH
EOF
        exit
    fi

    if [ "$1" == '--version' ]; then
        echo "is.sh 1.1.0"
        exit
    fi

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
            echo "$1" | grep -E '^[0-9]+(\.[0-9]+)?$'; return $?;;
        older)
            [ "$1" -ot "$2" ]; return $?;;
        newer)
            [ "$1" -nt "$2" ]; return $?;;
        gt)
            is not a number "$1"      && return 1;
            is not a number "$2"      && return 1;
            awk "BEGIN {exit $1 > $2 ? 0 : 1}"; return $?;;
        lt)
            is not a number "$1"      && return 1;
            is not a number "$2"      && return 1;
            awk "BEGIN {exit $1 < $2 ? 0 : 1}"; return $?;;
        ge)
            is not a number "$1"      && return 1;
            is not a number "$2"      && return 1;
            awk "BEGIN {exit $1 >= $2 ? 0 : 1}"; return $?;;
        le)
            is not a number "$1"      && return 1;
            is not a number "$2"      && return 1;
            awk "BEGIN {exit $1 <= $2 ? 0 : 1}"; return $?;;
        eq|equal)
            [ "$1" = "$2" ]     && return 0;
            is not a number "$1"      && return 1;
            is not a number "$2"      && return 1;
            awk "BEGIN {exit $1 == $2 ? 0 : 1}"; return $?;;
        match|matching)
            echo "$2" | grep -xE "$1"; return $?;;
        substr|substring)
            echo "$2" | grep -F "$1"; return $?;;
        true)
            [ "$1" == true ] || [ "$1" == 0 ]; return $?;;
        false)
            [ "$1" != true ] && [ "$1" != 0 ]; return $?;;
    esac > /dev/null

    return 1
}

if is not equal "${BASH_SOURCE[0]}" "$0"; then
    export -f is
else
    is "${@}"
    exit $?
fi
