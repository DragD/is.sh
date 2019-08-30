#!/usr/bin/env bash

declare CMD='is' DIR FILE
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
FILE="${1:-"$DIR/is.sh"}"

# shellcheck source=../is.sh
. "$FILE"
! command -v "$CMD" > /dev/null && printf '%s not found.\n' "$CMD" && exit 1

# : 1> file === touch file without calling an external tool
# read -rst # -n 999 === sleep # without calling an external tool
# Prepare working directory
# shellcheck disable=SC2034
printf 'Warming tests\n' && {
  command cd "$(mktemp -d)" || exit 1

  declare var_declared \
    path_file_inexistent='./file_inexistent' \
    path_file_old='./file_old' \
    path_file_new='./file_new' \
    path_file_forbidden='./file_forbidden' \
    path_file_abs="${PWD}/file_abs" \
    path_file_rel='./file_rel' \
    path_file_symlink='file_symlink' \
    path_dir_abs="${PWD}/dir_abs" \
    path_dir_rel='./dir_rel' \
    path_dir_symlink='dir_symlink'

  declare var_unset=''
  command unset ${BASH_VERSION+-v} var_unset

  declare string='string' substr='str' not_substr="rts" string_empty=''

  : 1> 'file_forbidden'
  chmod 000 'file_forbidden'

  : 1> $path_file_old
  command read -rst 1 -n 999
  : 1> $path_file_new

  : 1> $path_file_abs
  : 1> $path_file_rel
  chmod 777 $path_file_rel
  mkdir $path_dir_rel $path_dir_abs
  ln -s $path_file_rel $path_file_symlink
  ln -s $path_dir_rel $path_dir_symlink

  command alias myAlias=''

  declare bell=$'\a' backspace=$'\b'
  declare needle=':'
  declare -a array_empty=() \
    array_withNeedle=(':') \
    array_withoutNeedle=('a' '' 0 true) \
    array_withNeedleasSubstring=(
      " ${needle}"
      "\\${needle}"
      "${backspace}${needle}"
      "${bell}${backspace}${needle}"
      "${bell}${needle}"
      "${needle} "
      "${needle}\a"
      "${needle}${backspace}"
      "${needle}${bell}"
      "${needle}${bell}${backspace}"
      "${needle}a"
      "${needle}a${needle}"
      "a${needle}"
      ''
    ) \
    falsey=(1 false 'FALSE' 'F' 'No' 'n' 'OFF') \
    truthy=(0 true 'True' 't' 'YES' 'Y' 'on')

  # note: `$uint64` evaluates to zero
  declare uint16=$((2**16)) \
    uint32=$((2**32)) \
    uint64=$((2**64)) \
    sint64=$((2**63-1))
  declare nsint64=$((sint64+1))
  sint64="+$sint64"

  declare udec16="$uint16.0" \
    sdec16="+$udec16" \
    nsdec16="-$udec16" \
    rgb='0011ff' \
    udec16_comma="$uint16,0" \
    e_notation="${uint16}e${uint16}" \
    curreny_usd="\$${uint16}"
} && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# Helpers
_assert_raises() {
  local args expected=$1 condition=$2 && shift 2
  for args in "${@}"; do assert_raises "$CMD $condition $args" "$expected"; done
}

assert_true() { _assert_raises 0 "${1}" "${@:2}"; }
assert_false() { _assert_raises 1 "${1}" "${@:2}"; }

# shellcheck source=./assert.sh
. "$DIR/tests/assert.sh"

# Tests
printf 'Running tests\n' && {
  # is file
  assert_true  'file' "$path_file_abs" $path_file_rel $path_file_symlink
  assert_false 'file' $path_dir_rel $path_dir_symlink $path_file_inexistent

  # is dir|directory
  assert_true  'directory' "$path_dir_abs" $path_dir_rel $path_dir_symlink
  assert_false 'dir' $path_file_rel $path_file_symlink $path_file_inexistent

  # is link|symlink
  assert_false 'link' $path_file_rel $path_dir_rel $path_file_inexistent
  assert_true  'symlink' $path_file_symlink $path_dir_symlink

  # is existent|exist|exists|existing
  assert_true  'existent' $path_file_rel $path_file_symlink
  assert_true  'exist' $path_dir_rel
  assert_true  'exists' $path_dir_symlink
  assert_false 'existing' $path_file_inexistent

  # is writable
  assert_true  'writeable' $path_file_rel
  assert_false 'writeable' $path_file_forbidden

  # is readable
  assert_true  'readable' $path_file_rel
  assert_false 'readable' $path_file_forbidden

  # is executable
  assert_true  'executable' $path_file_rel
  assert_false 'executable' $path_file_forbidden

  # is available|installed
  assert_true  'available' 'which'
  assert_false 'installed' 'witch'

  # is empty
  assert_true  'empty' "$string_empty" '""'
  assert_false 'empty' $string

  # is number
  assert_true  'number' $uint16 "$uint16.$uint16" $sint64 $nsint64 $curreny_usd
  assert_false 'number' $string $rgb $udec16_comma $e_notation "+$nsint64"

  # is older
  assert_true  'older' "$path_file_old $path_file_new"
  assert_false 'older' "$path_file_new $path_file_old"

  # is newer
  assert_false 'newer' "$path_file_old $path_file_new"
  assert_true  'newer' "$path_file_new $path_file_old"

  # is gt
  assert_true  'gt' "$uint32 $udec16" "$uint32 $uint16"
  assert_false 'gt' "$uint16 $string" "$string $uint16" "$uint16 $udec16" \
                    "$udec16 $uint32" "$string $string"

  # is lt
  assert_true  'lt' "$udec16 $uint32" "$uint16 $uint32"
  assert_false 'lt' "$uint16 $string" "$string $uint16" "$uint16 $udec16" \
                    "$uint32 $udec16" "$string $string"

  # is ge
  assert_true  'ge' "$uint32 $udec16" "$uint16 $udec16"
  assert_false 'ge' "$uint16 $string" "$string $uint16" \
                    "$udec16 $uint32" "$string $string"

  # is le
  assert_true  'le' "$udec16 $uint32" "$uint16 $udec16"
  assert_false 'le' "$uint16 $string" "$string $uint16" \
                    "$uint32 $udec16" "$string $string"

  # is eq|equal
  assert_true  'eq' "$string $string" "$uint16 $udec16"
  assert_false 'equal' "$uint16 $string" "$string $uint16" "$udec16 $uint32" \
                    "$uint32 $udec16"

  # is match|matching
  assert_true  'match' "'[$string]+' '$string'" "'[$string]+' $substr"
  assert_false 'matching' "[$string]+ ${string^}" "[$string]+ '$not_substr'"

  # is substr|substring
  assert_true  'substr' "$substr $string"
  assert_false 'substring' "$not_substr $string"

  # is true
  assert_true  'true' 0 true
  assert_false 'true' 1 false $string $nsint64

  # is false
  assert_true  'false' 1 false $string $nsint64
  assert_false 'false' 0 true

  # is bool|boolean
  assert_true 'bool' "${truthy[@]}" "${falsey[@]}"
  _assert_raises 2 'boolean' $string $nsint64 $uint16

  # # is truthy
  assert_true 'truthy' "${truthy[@]}"
  assert_false 'truthy' "${falsey[@]}"

  # # is falsey
  assert_true 'falsey' "${falsey[@]}"
  assert_false 'falsey' "${truthy[@]}"

  # negation
  assert_true  'not number' $string
  assert_true  'not equal' "$string $substr"
  assert_false 'not number' $uint16
  assert_false 'not equal' "$string $string"

  # articles
  assert_true  'a number' $uint16
  assert_true  'an number' $uint16
  assert_true  'the number' $uint16
  assert_true  'not a number' $string
  assert_true  'not an number' $string
  assert_true  'not the number' $string

  # version
  assert_true '--version'

  # help
  assert_true '--help'

  # no args
  assert_true $string_empty

  # unspported condition
  assert_false 'spam' 'foo bar'

  # is alias
  assert_true  'alias' myAlias
  assert_false 'alias' "\$CMD"

  # is builtin
  assert_true  'builtin' printf true
  assert_false 'builtin' grep

  # is keyword
  assert_true  'keyword' if while
  assert_false 'keyword' 'CMD'

  # is fn|function
  assert_true  'fn' '_assert_raises'
  assert_false 'function' 'CMD'

  # is set|var|variable
  assert_true  'set' 'string_empty'
  assert_false 'var' 'var_declared' 'var_undeclared' 'var_unset'

  # is in
  assert_true  'in' "$needle array_withNeedle"
  assert_false 'in' "$needle array_empty" "$needle array_withoutNeedle" \
    "$needle array_withNeedleasSubstring"
    assert_false 'in' 'a apple' # this may change

  # is cmd|command
  assert_true  'cmd' 'which'
  assert_false 'command' 'witch'
} && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# end of tests
# shellcheck disable=SC2119
assert_end
