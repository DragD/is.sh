# is.sh

Fancy alternative for old good test command.

[![NPM Version][npm-image]][npm-url]
[![Build][travis-image]][travis-url]

## Example

```sh
declare var=123

$ is equal "$var" 123.0 && printf 'it just works!\n'
it just works

$ is not a substring "$var" 'foobar' && printf "and it is easy to read\n"
and it is easy to read
```

## Installation

In order to use is.sh you can install it with one of following 1-liners:

```sh
# Unix-like
$ sudo sh -c 'cd /usr/local/bin \
  && wget raw.githubusercontent.com/qzb/is.sh/latest/is.sh -O is \
  && chmod +x is'

# NPM
$ npm install -g is.sh
```

If you don't want to install is.sh system-wide you can just download it and
  source it from your script:

```sh
# retrieve and source
$ wget raw.githubusercontent.com/qzb/is.sh/latest/is.sh && . ./is.sh

```

## Usage

* `is` without arguments will print out version followed by usage
* `is --help` - displays usage
* `is --version` - displays version

### Conditions

checks if...

* `is equal "$valueA" "$valueB"` - 1st value is identical||equivalent to the 2nd
* `is matching "$regex" "$value"` - whole value matches the regular expression
* `is substring "$valueA" "$valueB"` - 1st value is a part of the 2nd
* `is empty "$value"` - value is empty
* `is number "$value"` - value is a number
* `is gt "$numberA" "$numberB"` - 1st number is greater than the 2nd
* `is lt "$numberA" "$numberB"` - 1st number is less than the 2nd
* `is ge "$numberA" "$numberB"` - 1st number is greater than or equal to the 2nd
* `is le "$numberA" "$numberB"` - 1st number is less than or equal to the 2nd
* `is file "$path"` - path is a file
* `is dir "$path"` - path is a directory
* `is link "$path"` - path is a symbolic link
* `is existent "$path"` - there is anything at this path
* `is readable "$path"` - path is readable
* `is writeable "$path"` - path is writeable
* `is executable "$path"` - path is executable
* `is available "$command"` - command is available
* `is older "$pathA" "$pathB"` - 1st path is older than the 2nd
* `is newer "$pathA" "$pathB"` - 1st path is newer than the 2nd
* `is true "$value"` - value is equal to `true` or `0`
* `is false "$value"` - value is not equal to `true` and not equal to `0`

### Negations

You can negate any condition by putting *not* in front of it.

```sh
$ is number '123' && printf 'number'
number
$ is not number 'abc' && printf 'not a number'
not a number
```

### Articles

You can add *a*, *an*, and *the* articles before condition name.

```sh
$ is a number 5; printf '%s\n' $?
0
$ is not a substring abc defghi; printf '%s\n' $?
1
```

## License

MIT

[npm-image]: https://img.shields.io/npm/v/is.sh.svg
[npm-url]: https://npmjs.org/package/is.sh
[travis-image]: https://img.shields.io/travis/qzb/is.sh/master.svg
[travis-url]: https://travis-ci.org/qzb/is.sh
