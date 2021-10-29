#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh "$BUILD_TAG?unspecified image to test}"
}

teardown() {
  docker rm --force "$BATS_TEST_NAME" >/dev/null 2>&1 || true
}

@test "should convert rec dir by default" {
  local container && container=$(docker run -d --name "$BATS_TEST_NAME" "$BUILD_TAG")
  assert_within 10s -- assert_container_log "$container" --partial 'recordr failed: rec-dir `rec/` does not exist'
}

@test "should display help if specified" {
  run docker run --name "$BATS_TEST_NAME" "$BUILD_TAG" --help
  # TODO correct version
  assert_line '   ▔▔▔▔▔▔▔ RECORDR SNAPSHOT'
  assert_line '     --rec-dir              path to prefix specified rec files with (default: rec/)'
}

@test "should print output to STDOUT" {
  local output && output=$(docker run --name "$BATS_TEST_NAME" -w /tmp "$BUILD_TAG" --rec-dir /tmp 2>/dev/null)
  assert_output "\
●◕ BATCH RECORD AND CONVERT
 ℹ recordings directory: /tmp
 ✔ BATCH COMPLETED"
}

@test "should print logs to STDERR" {
  local output && output=$(docker run --name "$BATS_TEST_NAME" -w /tmp "$BUILD_TAG" --rec-dir /tmp 2>&1 1>/dev/null)
  assert_output --partial "updating timezone to UTC"
  assert_output --partial "terminal profile search directory"
}

@test "should use rich console if terminal is connected" {
  TERM=xterm run docker run --tty --name "$BATS_TEST_NAME" -w /tmp "$BUILD_TAG" --rec-dir /tmp
  assert_line --partial ''
  refute_line " ⚙ updating timezone to UTC"
}

@test "should use plain console if no terminal is connected" {
  run docker run --name "$BATS_TEST_NAME" -w /tmp "$BUILD_TAG" --rec-dir /tmp
  refute_line --partial ''
  assert_line "   updating timezone to UTC"
  assert_line " ✔ updating timezone to UTC"
}
