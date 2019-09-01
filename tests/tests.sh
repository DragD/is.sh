#!/usr/bin/env bash

declare DIR CMD
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
CMD="${1:-"$DIR/is.sh"}"

if [ -n "$FILE" ] && ! which "$FILE" > /dev/null; then
    printf '%s not found.\n' "$FILE"
    exit 1
fi

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

#
# Helpers
#

assert_true() {
    assert_raises "$1" 0
}

assert_false() {
    assert_raises "$1" 1
}

# shellcheck source=./assert.sh
. "$DIR/tests/assert.sh"

# Tests
is="$CMD"
printf 'Running tests\n' && {
# is file
assert_true  "$is file ./file"
assert_true  "$is file ./symlink_file"
assert_false "$is file ./dir"
assert_false "$is file ./symlink_dir"
assert_false "$is file ./nothing"

# is directory
assert_false "$is directory ./file"
assert_false "$is directory ./symlink_file"
assert_true  "$is directory ./dir"
assert_true  "$is directory ./symlink_dir"
assert_false "$is directory ./nothing"

# is link
assert_false "$is link ./file"
assert_true  "$is link ./symlink_file"
assert_false "$is link ./dir"
assert_true  "$is link ./symlink_dir"
assert_false "$is link ./nothing"

# is existent
assert_true  "$is existent ./file"
assert_true  "$is existent ./symlink_file"
assert_true  "$is existent ./dir"
assert_true  "$is existent ./symlink_dir"
assert_false "$is existent ./nothing"

# is writable
assert_true  "$is writeable ./file"
assert_false "$is writeable ./forbidden_file"

# is readable
assert_true  "$is readable ./file"
assert_false "$is readable ./forbidden_file"

# is executable
assert_true  "$is executable ./file"
assert_false "$is executable ./forbidden_file"

# is available
assert_true  "$is available which"
assert_false "$is available witch"

# is empty
assert_true  "$is empty"
assert_true  "$is empty ''"
assert_false "$is empty abc"

# is number
assert_true  "$is number 123"
assert_true  "$is number 123.456"
assert_false "$is number abc"
assert_false "$is number 123ff"
assert_false "$is number 123,456"
assert_false "$is number 12e3"

# is older
assert_true  "$is older ./old_file ./new_file"
assert_false "$is older ./new_file ./old_file"

# is newer
assert_false "$is newer ./old_file ./new_file"
assert_true  "$is newer ./new_file ./old_file"

# is gt
assert_false "$is gt 111 222.0"
assert_false "$is gt 222 222.0"
assert_true  "$is gt 333 222.0"
assert_false "$is gt abc 222"
assert_false "$is gt 222 abc"
assert_false "$is gt abc abc"

# is lt
assert_true  "$is lt 111 222.0"
assert_false "$is lt 222 222.0"
assert_false "$is lt 333 222.0"
assert_false "$is lt abc 222"
assert_false "$is lt 222 abc"
assert_false "$is lt abc abc"

# is ge
assert_false "$is ge 111 222.0"
assert_true  "$is ge 222 222.0"
assert_true  "$is ge 333 222.0"
assert_false "$is ge abc 222"
assert_false "$is ge 222 abc"
assert_false "$is ge abc abc"

# is le
assert_true  "$is le 111 222.0"
assert_true  "$is le 222 222.0"
assert_false "$is le 333 222.0"
assert_false "$is le abc 222"
assert_false "$is le 222 abc"
assert_false "$is le abc abc"

# is equal
assert_false "$is equal 111 222.0"
assert_true  "$is equal 222 222.0"
assert_false "$is equal 333 222.0"
assert_false "$is equal abc 222"
assert_false "$is equal 222 abc"
assert_true  "$is equal abc abc"

# is matching
assert_true  "$is matching '[a-c]+' 'abc'"
assert_false "$is matching '[a-c]+' 'Abc'"
assert_false "$is matching '[a-c]+' 'abd"

# is substring
assert_true  "$is substring cde abcdef"
assert_false "$is substring cdf abcdef"

# is true
assert_false "$is true abc"
assert_true  "$is true true"
assert_true  "$is true 0"
assert_false "$is true 1"
assert_false "$is true -12"

# is false
assert_true  "$is false abc"
assert_false "$is false true"
assert_false "$is false 0"
assert_true  "$is false 1"
assert_true  "$is false -12"

# negation
assert_true  "$is not number abc"
assert_false "$is not number 123"
assert_true  "$is not equal abc def"
assert_false "$is not equal abc abc"

# articles
assert_true  "$is a number 123"
assert_true  "$is an number 123"
assert_true  "$is the number 123"
assert_true  "$is not a number abc"
assert_true  "$is not an number abc"
assert_true  "$is not the number abc"

# test aliases
assert_true  "$is dir ./dir"
assert_true  "$is symlink ./symlink_file"
assert_true  "$is existing ./file"
assert_true  "$is exist ./file"
assert_true  "$is exists ./file"
assert_true  "$is eq 222 222.0"
assert_true  "$is match '^[a-c]+$' 'abc'"
assert_true  "$is substr cde abcdef"
assert_true  "$is installed which"

# --version
assert_true "$is --version"

# help
assert_true "$is --help"

# unknown condition
assert_false "$is spam foo bar"
} && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# end of tests
# shellcheck disable=SC2119
assert_end
