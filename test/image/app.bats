#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh "${BUILD_TAG:?unspecified image to test}"
  load ../helpers/svg.sh
}

teardown() {
  image_cleanup
}

@test "should print help" {
  mkdir rec
  image --stdout-only -i "$BUILD_TAG" --help
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

@test "should record all rec files in rec directory and convert them to svg in docs directory" {
  mkdir -p rec/bar && cp_fixture .itermcolors . && cp_fixture test.rec rec/foo.rec && cp_fixture test.rec rec/bar/baz.rec
  image -i -e NODE_OPTIONS="--max-old-space-size=16384" "$BUILD_TAG"

  assert_equal_svg_fixture "test.svg" "docs/foo.svg"
  assert_equal_svg_fixture "test.svg" "docs/bar/baz.svg"
  assert_line " ℹ terminal profile search directory: rec/"
  assert_line "●◕ BATCH RECORD AND CONVERT"
  assert_line " ℹ recordings directory: rec/"
  assert_line " ● RECORDING rec/foo.rec"
  assert_line " ● RECORDING rec/bar/baz.rec"
  assert_line " ◕ CONVERTING build/rec/bar/baz.cast"
  assert_line " ◕ CONVERTING build/rec/foo.cast"
  assert_line " ✔ COMPLETED build/rec/foo.svg"
  assert_line " ✔ COMPLETED build/rec/bar/baz.svg"
  assert_line " ✔ BATCH COMPLETED"
}
