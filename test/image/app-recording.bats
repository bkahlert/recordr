#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh "${BUILD_TAG:?unspecified image to test}"
  load ../helpers/svg.sh
}

teardown() {
  image_cleanup
}

@test "should record empty prompt" {
  assert_cast_contains <(
    record <<COMMANDS
:
COMMANDS
  ) <<SEQUENCES
\u001b[37m❱ \u001b[?12l\u001b[?25h
SEQUENCES
}

# To create tests:
# - add test commands to `author`
# - execute `author`
# - open build/rec/author/foo.cast
# - copy relevant lines
# - remove prefix and suffix (everything but the third argument)

@test "should count down before restart" {
  assert_cast_contains <(
    record <<COMMANDS
:
COMMANDS
  ) <<SEQUENCES
\r\n
\u001b[?25l
1\u001b[1G
\u001b[?12l\u001b[?25h
\u001b[?25l
SEQUENCES
}

@test "should simulate entering command" {
  assert_cast_contains <(
    record <<COMMANDS
rec echo foo
COMMANDS
  ) <<SEQUENCES
\u001b[37m❱ \u001b[?12l\u001b[?25h
echo foo
\u001b[?25l
\u001b[?12l\u001b[?25h
\u001b[90m\u001b[1G❱ echo foo\u001b(B\u001b[m\r\n
\u001b[?25l
SEQUENCES
}

@test "should print output" {
  assert_cast_contains <(
    record <<COMMANDS
rec echo output
COMMANDS
  ) <<SEQUENCES
output\r\n
\r\n
SEQUENCES
}

@test "should print error" {
  assert_cast_contains <(
    record <<COMMANDS
rec echo error >&2
COMMANDS
  ) <<SEQUENCES
error\r\n
\r\n
SEQUENCES
}

@test "should print all line feeds" {
  assert_cast_contains <(
    record <<COMMANDS
rec printf '%s\n\n' "output"
COMMANDS
  ) <<SEQUENCES
output\r\n\r\n
\r\n
SEQUENCES
}

@test "should highlight missing line feed" {
  assert_cast_contains <(
    record <<COMMANDS
rec printf %s output
COMMANDS
  ) <<SEQUENCES
output
\u001b[7m␊\u001b(B\u001b[m\r\n
\r\n
SEQUENCES
}

@test "should not highlight empty output" {
  assert_cast_contains <(
    record <<COMMANDS
rec :
COMMANDS
  ) <<SEQUENCES
\u001b[?25l
\r\n
SEQUENCES
}

@test "should highlight non-zero return status" {
  assert_cast_contains <(
    record <<COMMANDS
do_return() {
  return 42
}
rec do_return
COMMANDS
  ) <<SEQUENCES
\u001b[?25l
\u001b[1A\u001b[128G\u001b[1m\u001b[31m42 ↩ \u001b(B\u001b[m\r\n\r\n
\r\n
SEQUENCES
}

@test "should highlight output with non-zero return status" {
  assert_cast_contains <(
    record <<COMMANDS
call_and_return() {
  "$@"
  return 42
}
rec call_and_return echo output
COMMANDS
  ) <<SEQUENCES
\u001b[?25l
"output\r\n
\u001b[1A\u001b[128G\u001b[1m\u001b[31m42 ↩ \u001b(B\u001b[m\r\n\r\n
\r\n
SEQUENCES
}

@test "should highlight output with missing line feed and non-zero return status" {
  assert_cast_contains <(
    record <<COMMANDS
call_and_return() {
  "$@"
  return 42
}
rec call_and_return printf output
COMMANDS
  ) <<SEQUENCES
\u001b[?25l
output
\u001b[7m␊\u001b(B\u001b[m\r\n
\u001b[1A\u001b[128G\u001b[1m\u001b[31m42 ↩ \u001b(B\u001b[m\r\n
\r\n
SEQUENCES
}

@test "should not exit on non-zero return status" {
  assert_cast_contains <(
    record <<COMMANDS
call_and_return() {
  "$@"
  return 42
}
rec call_and_return echo output
rec echo continuing
COMMANDS
  ) <<SEQUENCES
continuing\r\n
SEQUENCES
}

@test "should highlight non-zero exit status" {
  assert_cast_contains <(
    record <<COMMANDS
call_and_exit() {
  "$@"
  exit 120
}
rec call_and_exit echo output
COMMANDS
  ) <<SEQUENCES
output\r\n
\u001b[1A\u001b[127G\u001b[1m\u001b[31m120 ↩ \u001b(B\u001b[m\r\n
\r\n
SEQUENCES
}

@test "should exit on non-zero exit status" {
  assert_cast_contains <(
    record <<COMMANDS
call_and_exit() {
  "$@"
  exit 120
}
rec call_and_exit echo output
rec echo continuing
COMMANDS
  ) <<SEQUENCES
output\r\n
\u001b[1A\u001b[127G\u001b[1m\u001b[31m120 ↩ \u001b(B\u001b[m\r\n
\r\n
\u001b[?25l
1\u001b[1G
SEQUENCES
}

@test "should hide specified amount of arguments" {
  assert_cast_contains <(
    record <<COMMANDS
hidden() {
  echo "doing hidden stuff"
  echo "$@"
}
rec -1 hidden echo output
COMMANDS
  ) <<SEQUENCES
doing hidden stuff\r\necho output\r\n
\r\n
SEQUENCES
}

@test "should count down even after kill" {
  assert_cast_contains <(
    record <<COMMANDS
trap 'echo "Exiting"; kill $$' EXIT
rec echo "last line"
COMMANDS
  ) <<SEQUENCES
last line\r\n
\r\n
Exiting\r\n
\u001b[?25l
1\u001b[1G
SEQUENCES
}

record() {
  local cast_file=test.cast
  mkdir -p rec
  {
    echo '#!/usr/bin/env bash'
    cat -
  } >rec/"${cast_file%.*}.rec"
  image "$BUILD_TAG" --build-dir .
  cat "$cast_file"
}

assert_cast_contains() {
  local -a lines=() line pattern
  while read -r line; do
    line=${line//\\/\\\\}
    line=${line//[/\\[}
    line=${line//(/\\(}
    printf -v line '\[[^,]+, "o", "%s"\]' "$line"
    lines+=("$line")
  done
  printf -v pattern '%s\n' "${lines[@]}"
  assert_file_contains "${1?cast file missing}" "$pattern"
}
