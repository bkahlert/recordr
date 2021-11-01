#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert
}

recordr() {
  "$BATS_CWD/recordr" "$@"
}

@test "should print help on --help" {
  run recordr --help
  assert_success
  assert_output --partial '
   ▔▔▔▔▔▔▔ RECORDR SNAPSHOT

   Usage: recordr [OPTIONS] [FILE...]

   Options:
     --'
  assert_line '     --rec-dir              path to prefix specified rec files with (default: rec/)'
  assert_output --partial '
   Files:
     Specify any number of files relative to the `rec-dir`.
     If no files are specified, all files located in the `rec-dir` are processed.'
}

@test "should print help on -h" {
  assert_equal "$(recordr --help)" "$(recordr -h)"
}

@test "should print usage on missing option value" {
  run recordr --rec-dir
  assert_failure 64
  assert_line ' ✘ recordr --rec-dir: --rec-dir is missing a value'
  assert_line '   Usage: recordr [OPTIONS] [FILE...]'
}

@test "should print error on invalid option value" {
  run recordr --rec-dir invalid
  assert_failure 64
  assert_line ' ✘ recordr: rec-dir `invalid` does not exist'
}

@test "should print usage on unknown option" {
  run recordr --unknown
  assert_failure 64
  assert_line ' ✘ recordr --unknown: unknown option --unknown'
  assert_line '   Usage: recordr [OPTIONS] [FILE...]'
}
