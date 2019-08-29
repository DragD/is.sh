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

  : 1> 'forbidden_file'
  chmod 000 'forbidden_file'

  : 1> 'old_file'
  command read -rst 1 -n 999
  : 1> 'new_file'

  : 1> 'file'
  chmod 777 'file'
  mkdir 'dir'
  ln -s 'file' 'symlink_file'
  ln -s 'dir' 'symlink_dir'

  command alias myAlias=''

  declare var_declared
  declare var_initialized='' var_unset=''
  command unset ${BASH_VERSION+-v} var_unset

  declare bell=$'\a' backspace=$'\b'
  declare needle=':'
  declare -a array_empty=()
  declare -a array_withNeedle=(':')
  declare -a array_withoutNeedle=('a' '' 0 true)
  declare -a array_withNeedleasSubstring=(
    " ${needle}"
    "\\$needle"
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
  )
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
  assert_true  'file' './file' './symlink_file'
  assert_false 'file' './dir' './symlink_dir' './nothing'

  # is dir|directory
  assert_true  'dir' './dir' './symlink_dir'
  assert_false 'directory' './file' './symlink_file' './nothing'

  # is link|symlink
  assert_false 'link' './file' './dir' './nothing'
  assert_true  'symlink' './symlink_file' './symlink_dir'

  # is existent|exist|exists|existing
  assert_true  'existent' './file' './symlink_file' './dir' './symlink_dir'
  assert_true  'exist' './file'
  assert_true  'exists' './file'
  assert_false 'existing' './nothing'

  # is writable
  assert_true  'writeable' './file'
  assert_false 'writeable' './forbidden_file'

  # is readable
  assert_true  'readable' './file'
  assert_false 'readable' './forbidden_file'

  # is executable
  assert_true  'executable' './file'
  assert_false 'executable' './forbidden_file'

  # is available|installed
  assert_true  'available' 'which'
  assert_false 'installed' 'witch'

  # is empty
  assert_true  'empty' '' '""'
  assert_false 'empty' 'abc'

  # is number
  assert_true  'number' '123' '123.456' '-123' '+123'
  assert_false 'number' 'abc' '123ff' '123,456' '12e3' '+-123'

  # is older
  assert_true  'older' './old_file ./new_file'
  assert_false 'older' './new_file ./old_file'

  # is newer
  assert_false 'newer' './old_file ./new_file'
  assert_true  'newer' './new_file ./old_file'

  # is gt
  assert_true  'gt' '333 222.0'
  assert_false 'gt' '222 222.0' '111 222.0' 'abc 222' '222 abc' 'abc abc'

  # is lt
  assert_true  'lt' '111 222.0'
  assert_false 'lt' '222 222.0' '333 222.0' 'abc 222' '222 abc' 'abc abc'

  # is ge
  assert_true  'ge' '333 222.0' '222 222.0'
  assert_false 'ge' '111 222.0' 'abc 222' '222 abc' 'abc abc'

  # is le
  assert_true  'le' '111 222.0' '222 222.0'
  assert_false 'le' '333 222.0' 'abc 222' '222 abc' 'abc abc'

  # is eq|equal
  assert_true  'eq' 'abc abc' '222 222.0'
  assert_false 'equal' '333 222.0' '111 222.0' 'abc 222' '222 abc'

  # is match|matching
  assert_true  'match' '"[a-c]+" "abc"'
  assert_false 'matching' '"[a-c]+" "Abc"' '"[a-c]+" "abd"'

  # is substr|substring
  assert_true  'substr' 'cde abcdef'
  assert_false 'substring' 'cdf abcdef'

  # is true
  assert_true  'true' 'true' '0'
  assert_false 'true' 'abc' '1' '-12'

  # is false
  assert_true  'false' 'abc' '1' '-12'
  assert_false 'false' 'true' '0'

  # negation
  assert_true  'not number' 'abc'
  assert_true  'not equal' 'abc def'
  assert_false 'not number' '123'
  assert_false 'not equal' 'abc abc'

  # articles
  assert_true  'a number' '123'
  assert_true  'an number' '123'
  assert_true  'the number' '123'
  assert_true  'not a number' 'abc'
  assert_true  'not an number' 'abc'
  assert_true  'not the number' 'abc'

  # --version
  assert_true '--version'

  # help
  assert_true '--help'

  # no args
  assert_true ''

  # unknown condition
  assert_false 'spam' 'foo bar'

  # is alias
  assert_true  'alias' 'myAlias'
  assert_false 'alias' 'CMD'

  # is builtin
  assert_true  'builtin' 'printf' 'true'
  assert_false 'builtin' 'grep'

  # is keyword
  assert_true  'keyword' 'if' 'while'
  assert_false 'keyword' 'CMD'

  # is fn|function
  assert_true  'fn' '_assert_raises'
  assert_false 'function' 'CMD'

  # is set|var|variable
  assert_true  'set' 'var_initialized'
  assert_false 'var' 'var_declared' 'var_undeclared' 'var_unset'

  # is in
  assert_true  'in' "$needle array_withNeedle"
  assert_false 'in' "$needle array_empty" "$needle array_withoutNeedle" \
    "$needle array_withNeedleasSubstring"
    assert_false 'in' 'a apple' # this may change
} && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# end of tests
# shellcheck disable=SC2119
assert_end
