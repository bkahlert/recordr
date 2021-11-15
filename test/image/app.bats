#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh
  load ../helpers/svg.sh
}

teardown() {
  image_cleanup
}

@test "should print help if specified" {
  mkdir rec
  image --stdout-only -i "$BUILD_TAG" --help
  assert_success
  assert_output --partial '
   ▔▔▔▔▔▔▔ RECORDR 0.1.0

   Usage: recordr [OPTIONS] [DIR[/ ]FILE [FILE...]]

   Options:
     --'
  assert_line '     --out-dir              path to copy the created SVG files to (default: docs/)'
  assert_output --partial "└─● baz.svg    ⬅︎ to SVG converted ● rec file"
}

@test "should convert rec dir by default" {
  mkdir rec && copy_fixture test.rec rec && copy_fixture test.rec rec/test2.rec
  image "$BUILD_TAG"
  assert_line '●◕ BATCH PROCESSING'
  assert_line ' ℹ recordings directory: rec'
}

@test "should record all rec files in rec directory and convert them to svg in docs directory" {
  mkdir -p rec/bar && copy_fixture .itermcolors . && copy_fixture test.rec rec/foo.rec && copy_fixture test.rec rec/bar/baz.rec
  image -i -e NODE_OPTIONS="--max-old-space-size=16384" "$BUILD_TAG"

  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_line " ℹ terminal profile search directory: rec"
  assert_line "●◕ BATCH PROCESSING"
  assert_line " ℹ recordings directory: rec"
  assert_line " ● RECORDING: rec/bar/baz.rec"
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◔ CONVERTING: build/rec/bar/baz.cast"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◑ PATCHING: build/rec/bar/baz.svg.0"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ◕ LINKING: build/rec/bar/baz.svg.1"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● ANNOTATING: build/rec/bar/baz.svg.2"
  assert_line " ● COMPLETED: docs/foo.svg"
  assert_line " ● COMPLETED: docs/bar/baz.svg"
  assert_line " ✔ BATCH PROCESSING: COMPLETED"
}

@test "should output only completed files on missing terminal" {
  mkdir -p rec/bar && copy_fixture test.rec rec/foo.rec && copy_fixture test.rec rec/bar/baz.rec
  image --stdout-only "$BUILD_TAG"
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_output --regexp 'docs/.*.svg'$'\n''docs/.*.svg'
}
