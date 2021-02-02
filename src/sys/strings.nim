#
#            Abstractions for operating system services
#                   Copyright (c) 2021 Leorize
#
# Licensed under the terms of the MIT license which can be found in
# the file "license.txt" included with this distribution. Alternatively,
# the full text can be found at: https://spdx.org/licenses/MIT.html

## Special kinds of strings used for interacting with certain operating system
## APIs.
##
## While mutating APIs are provided, they are limited to simple operations
## only. For performance it is recommended to convert them to strings, perform
## the necessary mutations, then use the checked converters.

import std/strutils

type
  Without*[C: static set[char]] = distinct string
    ## A distinct string type without the characters in set `C`.

const
  InvalidChar = "$1 is not a valid character for this type of string."
    # Error message used for setting an invalid character.

  FoundInvalid = "Invalid character ($1) found at position $2"
    # Error message used when an invalid character is found during search.

template len*(w: Without): int =
  ## Obtain the length of the string `w`.
  w.string.len

template `==`*(a, b: Without): bool =
  ## Returns whether `a` and `b` are equal.
  a.string == b.string

template `==`*(a: Without, b: string): bool =
  ## Returns whether `a` and `b` are equal.
  a.string == b

template `==`*(a: string, b: Without): bool =
  ## Returns whether `a` and `b` are equal.
  a == b.string

template `[]`*(w: Without, i: Natural): char =
  ## Obtain the byte at position `i` of the string `w`.
  w.string[i]

template `[]`*(w: Without, i: BackwardsIndex): char =
  ## Obtain the byte at position `w.len - i` of the string `w`.
  w.string[i]

func `[]=`*[C](w: var Without[C], i: Natural, c: char)
              {.inline, raises: [ValueError].} =
  ## Set the byte at position `i` of the string `w` to `c`.
  ##
  ## Raises `ValueError` if `c` is in `C`.
  if c notin C:
    string(w)[i] = c
  else:
    raise newException(ValueError, InvalidChar % escape $c)

func toWithout*(s: sink string, C: static set[char]): Without[C]
               {.inline, raises: [ValueError].} =
  ## Checked conversion to `Without[C]`.
  ##
  ## Raises `ValueError` if any character in `C` was found in the string.
  let invalidPos = s.find C
  if invalidPos != -1:
    raise newException(
      ValueError,
      FoundInvalid % [escape $s[invalidPos], $invalidPos]
    )
  result = Without[C](s)

func filter*(s: string, C: static set[char]): Without[C] {.raises: [].} =
  ## Remove characters in set `C` from `s` and create a `Without[C]`.
  var i = 0
  result = Without[C](s)
  while i < result.len:
    if result[i] in C:
      result.string.delete(i, i)
    else:
      inc i

template add*[C](w: var Without[C], s: Without[C]) =
  ## Append the string `s` to `w`.
  w.string.add s.string

func add*[C](w: var Without[C], s: string) =
  ## Append the string `s` to `w`.
  ##
  ## Raises `ValueError` if any character in `C` if found in the string `s`.
  let origLen = w.len
  try:
    w.string.setLen origLen + s.len
    for idx, c in s:
      w[origLen + idx] = c
  except:
    # Clean up on failure
    w.string.setLen origLen
    raise

func add*[C](w: var Without[C], c: char) {.inline, raises: [ValueError].} =
  ## Append the character `c` to `w`.
  ##
  ## Raises `ValueError` if `c` is in `C`.
  if c notin C:
    w.string.add c
  else:
    raise newException(ValueError, InvalidChar % escape $c)

type
  Nulless* = Without[{'\0'}]
    ## A string without the character NUL, mainly used for file paths or
    ## command arguments.

func toNulless*(s: sink string): Nulless
               {.inline, raises: [ValueError].} =
  ## Checked conversion to `NullessString`.
  ##
  ## Raises `ValueError` if any NUL character was found in the string.
  s.toWithout({'\0'})
