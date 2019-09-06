#!/usr/bin/env bash

is() { [ "$(LANG=C type -t "$2" 2>/dev/null)" = "${1,,}" ]; }

_assert_raises() {
  local args expected="${1-}" condition="${2-}" && shift 2
  for args in "${@}"; do assert_raises "is $condition $args" "$expected"; done
}

assert_true() { _assert_raises 0 "${1}" "${@:2}"; }
assert_false() { _assert_raises 1 "${1}" "${@:2}"; }

# shellcheck disable=SC1010,SC1083
test::warm() {
  declare -ag array_keywords_valid=(
    '[[' ']]' # these are parsed individually
    [[ ]] # this is parsed as a single string
    [[

    ]]
    [[
    ]]
    [[
      # current bug:
    ]]
    [[ # command subsitution gets evaluates in these comments

    ]]
    [[

    ]]  # so if there is an unbalanced backtick or
    [[
       # ]] then bash will throw an EOF error
    ]]
    [[ # ]]
    ]]
    [[
      #
    ]]
    # i.e the following two lines are equivalent
    [[ { "hello" } ]]
    '[[ { "hello" } ]]'
    [[
        # any content, sans comment, between [[ && ]] will be parsed
        # as a single string, even in this array
    ]]
    [[
      # $()
    ]]
    [[
      # ``
    ]]
    [[
      # $(``)
    ]]
    [[
      # $
    ]]
    [[
      # \`
    ]]
    [[
      # (
    ]]
    [[
      # \`\`
    ]]
  ) \
  array_keywords_invalid=(
    [[]]
  ) \
  array_builtins_sh_valid=(
    test
    '[' # these are parsed individually
    [ ] # this is parsed as a single string
    [

    ]
    [
    ]
    [
      # this is valid
    ]
    [ # this is valid

    ]
    [ # this is valid
       # this is valid
    ]
    [
      #
    ]
    # i.e the following two lines are equivalent
    [ { "hello" } ]
    '[ { "hello" } ]'
    [
        # any content, sans comment, between [ && ] will be parsed
        # as a single string, even in this array
    ]
    [
      # $()
    ]
    [
      # ``
    ]
    [
      # $(``)
    ]
    [
      # $
    ]
    [
      # \`
    ]
    [
      # (
    ]
    [
      # \`\`
    ]
  ) \
  array_builtins_sh_invalid=(
    []
    '[]'
    ]
  )
  declare -ag array_keywords_error=(
    # [[
    #   # $([[)
    #   # $(]])
    #   # `
    #   # \``
    #   # `\`
    #   # $(
    #   # ]] this text will be considered outside of the brackets
    #   # [[ this text will be considered outside of the brackets previous
    #   #   brackets since the line above closes it
    # ]]
  ) \
  array_builtins_sh_error=(
    # [
    #   # $([)
    #   # $(])
    #   # `
    #   # \``
    #   # `\`
    #   # $(
    #   # this commented out right square bracket gets parsed as a normal one
    #   #   it can be located anywhere in between the top & bottom-most brackets
    #   # [
    #   # ]
    # ]
  )
  declare -ag array_keywords=(
  ) \
  array_builtins_sh=(
  )
}

test::run() {
  assert_true 'keyword' "${array_keywords_valid[@]}"
  assert_true 'builtin' "${array_builtins_sh_valid[@]}"

  assert_false 'keyword' "${array_keywords_invalid[@]}"
  assert_false 'builtin' "${array_builtins_sh_invalid[@]}"

  assert_true 'keyword' "${array_keywords[@]}"
  assert_true 'builtin' "${array_builtins_sh[@]}"
}

printf 'Warming Tests\n' \
  && test::warm \
  && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# shellcheck source=./assert.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/tests/assert.sh"

printf 'Running Tests\n' \
  && test::run \
  && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# shellcheck disable=SC2119
assert_end
