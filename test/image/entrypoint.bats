#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh "$BUILD_TAG?unspecified image to test}"
}

teardown() {
  image_cleanup
}

@test "should convert rec dir by default" {
  mkdir rec && cp_fixture test.rec rec
  image "$BUILD_TAG"
  assert_line '●◕ BATCH RECORD AND CONVERT'
  assert_line ' ℹ recordings directory: rec/'
}

@test "should display help if specified" {
  image "$BUILD_TAG" --help
  # TODO correct version
  assert_line '   ▔▔▔▔▔▔▔ RECORDR SNAPSHOT'
  assert_line '     --rec-dir              path to prefix specified rec files with (default: rec/)'
}

@test "should print output to STDOUT" {
  mkdir rec
  image --stdout-only "$BUILD_TAG"
  assert_output "\
●◕ BATCH RECORD AND CONVERT
 ℹ recordings directory: rec/
 ✔ BATCH COMPLETED"
}

@test "should print logs to STDERR" {
  mkdir rec
  image --stderr-only "$BUILD_TAG"
  assert_line --partial "updating timezone to UTC"
  assert_line --partial "terminal profile search directory"
}

@test "should use rich console if terminal is connected" {
  mkdir rec
  TERM=xterm image --tty "$BUILD_TAG"
  assert_line --partial ''
  refute_line " ⚙ updating timezone to UTC"
}

@test "should use plain console if no terminal is connected" {
  mkdir rec
  TERM=xterm image "$BUILD_TAG"
  refute_line --partial ''
  assert_line "   updating timezone to UTC"
  assert_line " ✔ updating timezone to UTC"
}
