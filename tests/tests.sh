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
printf 'Warming tests\n' && {
  cd "$(mktemp -d)" || exit 1

  : 1> 'forbidden_file'
  chmod 000 'forbidden_file'

  : 1> 'old_file'
  read -rst 1 -n 999
  : 1> 'new_file'

  : 1> 'file'
  chmod 777 'file'
  mkdir 'dir'
  ln -s 'file' 'symlink_file'
  ln -s 'dir' 'symlink_dir'
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

  # is directory
  assert_true  'directory' './dir' './symlink_dir'
  assert_false 'directory' './file' './symlink_file' './nothing'

  # is link
  assert_false 'link' './file' './dir' './nothing'
  assert_true  'link' './symlink_file' './symlink_dir'

  # is existent
  assert_true  'existent' './file' './symlink_file' './dir' './symlink_dir'
  assert_false 'existent' './nothing'

  # is writable
  assert_true  'writeable' './file'
  assert_false 'writeable' './forbidden_file'

  # is readable
  assert_true  'readable' './file'
  assert_false 'readable' './forbidden_file'

  # is executable
  assert_true  'executable' './file'
  assert_false 'executable' './forbidden_file'

  # is available
  assert_true  'available' 'which'
  assert_false 'available' 'witch'

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

  # is equal
  assert_true  'equal' 'abc abc' '222 222.0'
  assert_false 'equal' '333 222.0' '111 222.0' 'abc 222' '222 abc'

  # is matching
  assert_true  'matching' '"[a-c]+" "abc"'
  assert_false 'matching' '"[a-c]+" "Abc"' '"[a-c]+" "abd"'

  # is substring
  assert_true  'substring' 'cde abcdef'
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

  # test aliases
  assert_true  'dir' './dir'
  assert_true  'symlink' './symlink_file'
  assert_true  'existing' './file'
  assert_true  'exist' './file'
  assert_true  'exists' './file'
  assert_true  'eq' '222 222.0'
  assert_true  'match' '"^[a-c]+$" "abc"'
  assert_true  'substr' 'cde abcdef'
  assert_true  'installed' 'which'

  # --version
  assert_true '--version'

  # help
  assert_true '--help'

  # unknown condition
  assert_false 'spam' 'foo bar'
} && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# end of tests
# shellcheck disable=SC2119
assert_end
