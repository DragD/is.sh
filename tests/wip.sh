#!/usr/bin/env bash
# shellcheck disable=SC2034

declare CMD='is' CMD2='is::wip' DIR FILE FILE2
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
FILE="${1:-"$DIR/$CMD.sh"}" FILE2="${DIR}/wip.sh"

[ ! -x "$FILE" ] \
  && { chmod +x "$FILE" || printf 'Cannot not execute file.\n' && exit 1; }

# shellcheck source=../wip.sh
. "$FILE2"
! command -v "$CMD2" > /dev/null && printf '%s not found.\n' "$CMD2" && exit 1

# shellcheck source=../is.sh
. "$FILE"
! command -v "$CMD" > /dev/null && printf '%s not found.\n' "$CMD" && exit 1

_wip_raises() {
  local args expected="${1-}" condition="${2-}" && shift 2
  for args in "${@}"; do assert_raises "$CMD2 $condition $args" "$expected"; done
}

wip_true() { _wip_raises "$1" "${@:2}"; }
wip_false() { _wip_raises 1 "$1" "${@:2}"; }

_assert_raises() {
  local args expected="${1-}" condition="${2-}" && shift 2
  for args in "${@}"; do assert_raises "$CMD $condition $args" "$expected"; done
}

assert_true() { _assert_raises 0 "$1" "${@:2}"; }
assert_false() { _assert_raises 1 "$1" "${@:2}"; }

test::warm() { :
}

test::run() { :
}

test::run.wip() { :
}

printf 'Warming Tests\n' \
  && test::warm \
  && printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# shellcheck source=./assert.sh
. "$DIR/tests/assert.sh"

printf 'Running Tests\n' \
  && test::run \
&& printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# shellcheck disable=SC2119
assert_end "${CMD}"

printf 'Running WIP Tests\n' \
  && test::run.wip \
&& printf '\033[s\033[1F\033[%s@\033[%s@\033[32m\u2713\033[39m\033[u' '' ''

# shellcheck disable=SC2119
assert_end "${CMD2}"
