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
test::warm() {
  command cd "$(mktemp -d)" || exit 1

  declare -g var_declared \
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

  declare -g var_unset=''
  command unset ${BASH_VERSION+-v} var_unset

  declare -g val_string='string' val_str='str' val_rtS='rtS' val_string_empty=''

  : 1> 'file_forbidden'
  chmod 000 'file_forbidden'

  : 1> $path_file_old
  command read -rst 1 -n 999
  : 1> $path_file_new

  : 1> "$path_file_abs"
  : 1> $path_file_rel
  chmod 777 $path_file_rel
  mkdir $path_dir_rel "$path_dir_abs"
  ln -s $path_file_rel $path_file_symlink
  ln -s $path_dir_rel $path_dir_symlink

  command alias myAlias=''

  declare -g bell=$'\a' backspace=$'\b' needle=':'
  declare -ag array_empty=() \
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

  # note: bash's goes up to but excludes uint64 (2**64); it will evaluate to 0
  declare -g val_uint16=$((2**16)) \
    val_uint32=$((2**32)) \
    val_sint64=$((2**63-1))
  declare -g val_nsint64=$((val_sint64+1))
  val_sint64="+$val_sint64"

  declare -g val_udec16="$val_uint16.0" \
    val_sdec16="+$val_udec16" \
    val_nsdec16="-$val_udec16" \
    val_rgb='0011ff' \
    val_udec16_comma="$val_uint16,0" \
    val_e_notation="${val_uint16}e${val_uint16}" \
    val_curreny_usd="\$${val_uint16}"
}

# Helpers
_assert_raises() {
  local args expected="${1-}" condition="${2-}" && shift 2
  for args in "${@}"; do assert_raises "$CMD $condition $args" "$expected"; done
}

assert_true() { _assert_raises 0 "${1}" "${@:2}"; }
assert_false() { _assert_raises 1 "${1}" "${@:2}"; }

# Tests
test::run() {
  # no args
  assert_true $val_string_empty

  # help
  assert_true '--help'

  # version
  assert_true '--version'

  # unspported condition
  assert_false 'spam' 'foo bar'

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
  assert_true  'empty' "$val_string_empty" '""'
  assert_false 'empty' $val_string

  # is number
  assert_true  'number' $val_uint16 "$val_uint16.$val_uint16" $val_sint64 $val_nsint64 $val_curreny_usd
  assert_false 'number' $val_string $val_rgb $val_udec16_comma $val_e_notation "+$val_nsint64"

  # is older
  assert_true  'older' "$path_file_old $path_file_new"
  assert_false 'older' "$path_file_new $path_file_old"

  # is newer
  assert_false 'newer' "$path_file_old $path_file_new"
  assert_true  'newer' "$path_file_new $path_file_old"

  # is gt
  assert_true  'gt' "$val_uint32 $val_udec16" "$val_uint32 $val_uint16"
  assert_false 'gt' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_uint16 $val_udec16" "$val_udec16 $val_uint32" \
                    "$val_string $val_string"

  # is lt
  assert_true  'lt' "$val_udec16 $val_uint32" "$val_uint16 $val_uint32"
  assert_false 'lt' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_uint16 $val_udec16" "$val_uint32 $val_udec16" \
                    "$val_string $val_string"

  # is ge
  assert_true  'ge' "$val_uint32 $val_udec16" "$val_uint16 $val_udec16"
  assert_false 'ge' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_udec16 $val_uint32" "$val_string $val_string"

  # is le
  assert_true  'le' "$val_udec16 $val_uint32" "$val_uint16 $val_udec16"
  assert_false 'le' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_uint32 $val_udec16" "$val_string $val_string"

  # is eq|equal
  assert_true  'eq' "$val_string $val_string" "$val_uint16 $val_udec16"
  assert_false 'equal' "$val_uint16 $val_string" "$val_string $val_uint16" \
                       "$val_udec16 $val_uint32" "$val_uint32 $val_udec16"

  # is match|matching
  assert_true  'match' "'[$val_string]+' '$val_string'" \
                       "'[$val_string]+' $val_str"
  assert_false 'matching' "[$val_string]+ ${val_string^}" \
                          "[$val_string]+ '$val_rtS'"

  # is val_str|substring
  assert_true  'substr' "$val_str $val_string"
  assert_false 'substring' "$val_rtS $val_string"

  # is true
  assert_true  'true' 0 true
  assert_false 'true' 1 false $val_string $val_nsint64

  # is false
  assert_true  'false' 1 false $val_string $val_nsint64
  assert_false 'false' 0 true

  # is bool|boolean
  assert_true 'bool' "${truthy[@]}" "${falsey[@]}"
  _assert_raises 2 'boolean' $val_string $val_nsint64 $val_uint16

  # # is truthy
  assert_true 'truthy' "${truthy[@]}"
  assert_false 'truthy' "${falsey[@]}"

  # # is falsey
  assert_true 'falsey' "${falsey[@]}"
  assert_false 'falsey' "${truthy[@]}"

  # negation
  assert_true  'not number' $val_string
  assert_true  'not equal' "$val_string $val_str"
  assert_false 'not number' $val_uint16
  assert_false 'not equal' "$val_string $val_string"

  # articles
  assert_true  'a number' $val_uint16
  assert_true  'an number' $val_uint16
  assert_true  'the number' $val_uint16
  assert_true  'not a number' $val_string
  assert_true  'not an number' $val_string
  assert_true  'not the number' $val_string

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
  assert_true  'set' 'val_string_empty'
  assert_false 'var' 'var_declared' 'var_undeclared' 'var_unset'

  # is in
  assert_true  'in' "$needle array_withNeedle"
  assert_false 'in' "$needle array_empty" "$needle array_withoutNeedle" \
    "$needle array_withNeedleasSubstring"
    assert_false 'in' 'a apple' # this may change

  # is cmd|command
  assert_true  'cmd' 'which'
  assert_false 'command' 'witch'
}

printf 'Warming Tests\n' \
  && test::warm \
  && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# shellcheck source=./assert.sh
. "$DIR/tests/assert.sh"

printf 'Running Tests\n' \
  && test::run \
  && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# end of tests
# shellcheck disable=SC2119
assert_end
