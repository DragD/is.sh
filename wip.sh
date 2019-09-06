#!/usr/bin/env bash

is::wip() { :
}

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f is::wip
else
  is::wip "${@}"
  exit $?
fi
