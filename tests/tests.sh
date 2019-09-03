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

  declare -g path_file_abs="${PWD}/file_abs" path_dir_abs="${PWD}/dir_abs" \
    path_dir_rel='./dir_rel' \
    path_dir_symlink='dir_symlink' \
    path_file_forbidden='./file_forbidden' \
    path_file_inexistent='./file_inexistent' \
    path_file_new='./file_new' \
    path_file_old='./file_old' \
    path_file_rel='./file_rel' \
    path_file_symlink='file_symlink'

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
    array_falsey=(1 false 'FALSE' 'F' 'No' 'n' 'OFF') \
    array_truthy=(0 true 'True' 't' 'YES' 'Y' 'on')

  # shellcheck disable=SC1010,SC1083
  # We disable these because we are intentionally not quoting these so as to
  #   potentially display your editors language syntax highlighting.
  #   Ideally, these should be highlighted like any other string literal.

  # these are syntactically valid forms
  declare -a array_keywords_brackets=(
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
    [[ # then bash will throw an EOF error
       # this subsequent closing double bracket actually gets parsed as the
       #    balanced pair and the subsequent one is lone
       #    but because a lone closing double bracket is a valid keyword, we
       #    can put it in this array
       # ]]
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
  )
  # shellcheck disable=SC1010,SC1083
  declare -ag array_keywords=(
    if then elif else fi
    for in do done
    while until
    case esac
    function
    select
    time
    !
    "${array_keywords_brackets[@]}"
  )

  # similar to the keyword [[ (as seen above), test's bracket alias has similar
  #   issues these are syntactically valid forms
  # shellcheck disable=SC1010,SC1083
  declare -a array_builtin_test_bracket=(
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
  )
  declare -ag array_builtins_bash=(
    alias unalias
    bind
    builtin
    caller
    command type
    declare local typeset
    echo printf
    enable
    help
    let
    logout
    mapfile read readarray
    source # `.` facade
    ulimit
    # Job Control Builtins
    bg fg jobs kill wait disown suspend
    # Directory Stack Builtins
    dirs popd pushd
    # History Builtins
    fc history
    # Programmable Completion Builtins
    compgen complete compopt
    # Special builtins
    shopt
  ) \
  array_builtins_sh=(
    true # `:` facade
    false # `! true` facade
    cd
    getopts
    hash
    pwd
    test
    times
    umask
    "${array_builtin_test_bracket[@]}"
    # Special POSIX builtins
    :
    .
    break
    continue
    eval
    exec
    exit
    export
    readonly
    return
    set
    shift
    trap
    unset
  ) \
  array_not_builtins=(
    [] '[]' ]
    grep sed awk touch
    "$ref_alias" "$ref_function" "$ref_keyword"
  )

  #  # These cause a EOF error due to improper parsing of command subsitution
  #   within comments
  declare -ag parser_error_for_keyword_double_bracket=(
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
  parser_error_for_builtin_test_bracket=(
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

  declare -g var_declared var_unset=''
  command unset ${BASH_VERSION+-v} var_unset

  declare -g val_string='string' val_str='str' val_rtS='rtS' val_string_empty=''

  # remember, -g just bring the variables scope to the top
  #   `declare -p` will not show `-g`
  declare -gi var_gi=0
  declare -ga var_ga=([0]='-ga')
  declare -gA var_gA=([0]='-gA')
  declare -gx var_gx='-x'

  # -{i,a,A}gx, -{i,a,A}xg, -gx{i,a,A}, -x{i,a,A}g, -xg{i,a,A},
  #   will all evaluate to -g{i,a,A}x
  #   likewise with -g{i,a,A}, -{i,a,A}g and then exporting
  declare -gix var_gix=1
  declare -gax var_gax=([0]='-gax')
  declare -gAx var_gAx=([0]='-gAx')

  command alias myAlias=''
  declare -g ref_alias='myAlias' \
    ref_builtin='printf' \
    ref_keyword='if' \
    ref_function='assert_true' \
    ref_var_gi='var_gi'

  # note: bash's goes up to but excludes uint64 (2**64); it will evaluate to 0
  declare -g val_uint16=$((2**16)) val_uint32=$((2**32)) val_sint64=$((2**63-1))
  declare -g val_nsint64=$((val_sint64+1)) # wraps to negative
  val_sint64="+$val_sint64"
  declare -g val_udec16dot0="$val_uint16.0"
    val_udec16dot16="$val_uint16.$val_uint16"

  declare -g val_rgb='0011ff' \
    val_curreny_usd="'\$$val_uint16'" \
    val_e_notation="${val_uint16}e${val_uint16}" \
    val_nsdec16="-$val_udec16dot0" \
    val_sdec16="+$val_udec16dot0" \
    val_udec16comma0="$val_uint16,0"

  declare -ga array_decimal=(
    "$val_nsdec16"
    "$val_sdec16"
    "$val_udec16dot0"
    "$val_udec16dot16"
  ) \
  array_int=(
    "$ref_var_gi" var_gi var_gix
    "$val_nsint64"
    "$val_sint64"
    "$val_uint16"
  ) \
  array_not_int=(
    "+$val_nsint64"
    "$val_curreny_usd"
    "$val_e_notation"
    "$val_rgb"
    "$val_string_empty"
    "$val_string"
    "$val_udec16comma0"
    var_gax
    var_gAx
  )
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

  # is cmd|command
  assert_true  'cmd' 'which'
  assert_false 'command' 'witch'

  # is empty
  assert_true  'empty' "$val_string_empty" '""'
  assert_false 'empty' $val_string

  # is older
  assert_true  'older' "$path_file_old $path_file_new"
  assert_false 'older' "$path_file_new $path_file_old"

  # is newer
  assert_false 'newer' "$path_file_old $path_file_new"
  assert_true  'newer' "$path_file_new $path_file_old"

  # is gt
  assert_true  'gt' "$val_uint32 $val_udec16dot0" "$val_uint32 $val_uint16"
  assert_false 'gt' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_uint16 $val_udec16dot0" "$val_udec16dot0 $val_uint32" \
                    "$val_string $val_string"

  # is lt
  assert_true  'lt' "$val_udec16dot0 $val_uint32" "$val_uint16 $val_uint32"
  assert_false 'lt' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_uint16 $val_udec16dot0" "$val_uint32 $val_udec16dot0" \
                    "$val_string $val_string"

  # is ge
  assert_true  'ge' "$val_uint32 $val_udec16dot0" "$val_uint16 $val_udec16dot0"
  assert_false 'ge' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_udec16dot0 $val_uint32" "$val_string $val_string"

  # is le
  assert_true  'le' "$val_udec16dot0 $val_uint32" "$val_uint16 $val_udec16dot0"
  assert_false 'le' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_uint32 $val_udec16dot0" "$val_string $val_string"

  # is eq|equal
  assert_true  'equal' "$val_string $val_string" "$val_uint16 $val_udec16dot0"
  assert_false 'eq' "$val_uint16 $val_string" "$val_string $val_uint16" \
                    "$val_udec16dot0 $val_uint32" "$val_uint32 $val_udec16dot0"

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
  assert_true 'bool' "${array_truthy[@]}" "${array_falsey[@]}"
  _assert_raises 2 'boolean' $val_string $val_nsint64 $val_uint16

  # # is truthy
  assert_true 'truthy' "${array_truthy[@]}"
  assert_false 'truthy' "${array_falsey[@]}"

  # # is falsey
  assert_true 'falsey' "${array_falsey[@]}"
  assert_false 'falsey' "${array_truthy[@]}"

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

  # is number
  assert_true  'number' "${array_int[@]}" "${array_decimal[@]}"
  assert_false 'num' "${array_not_int[@]}"

  # is int
  assert_true  'integer' "${array_int[@]}"
  assert_false 'integer' "${array_not_int[@]}" "${array_decimal[@]}"

  # is array
  assert_true  'array' var_ga var_gax
  assert_false 'array' var_gx var_gA var_gAx

  # is hash
  assert_true  'hash' var_gA var_gAx
  assert_false 'dictionary' var_gx var_ga var_gaX

  # is export
  assert_true  'export' var_gx var_gax var_gix var_gAx
  assert_false 'exported' var_gA var_ga var_gi

  # is alias
  assert_true  'alias' $ref_alias
  assert_false 'alias' $ref_builtin $ref_function $ref_keyword "\$CMD"

  # is builtin
  assert_true  'builtin' "${array_builtins_sh[@]}" "${array_builtins_bash[@]}"
  assert_false 'builtin' "${array_not_builtins[@]}"

  # is keyword
  assert_true  'keyword' $ref_keyword
  assert_false 'keyword' $ref_alias $ref_builtin $ref_function CMD

  # is function
  assert_true  'fn' $ref_function
  assert_false 'function' $ref_alias $ref_builtin $ref_keyword CMD

  # is set|var|variable
  assert_true  'set' val_string_empty
  assert_false 'var' var_undeclared var_declared var_unset

  # is in
  assert_true  'in' "$needle array_withNeedle"
  assert_false 'in' "$needle array_empty" "$needle array_withoutNeedle" \
    "$needle array_withNeedleasSubstring"
    assert_false 'in' 'a apple' # this may change
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
assert_end "${CMD}"
