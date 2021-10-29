#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh "$BUILD_TAG?unspecified image to test}"
  cp_fixture test.rec .
}

teardown() {
  docker rm --force "$BATS_TEST_NAME" >/dev/null 2>&1 || true
}

@test "should change user ID to 1000 by default" {
  run docker run --name "$BATS_TEST_NAME" -v "$PWD:/tmp" -w /tmp "$BUILD_TAG" --rec-dir /tmp test.rec
  assert_file_owner_group "$PWD/build/rec/test.sh" '1000' -
}

@test "should change user ID to specified ID" {
  run docker run -e PUID=2000 --name "$BATS_TEST_NAME" -v "$PWD:/tmp" -w /tmp "$BUILD_TAG" --rec-dir /tmp test.rec
  assert_file_owner_group "$PWD/build/rec/test.sh" '2000' -
}

@test "should change group ID to 1000 by default" {
  run docker run --name "$BATS_TEST_NAME" -v "$PWD:/tmp" -w /tmp "$BUILD_TAG" --rec-dir /tmp test.rec
  assert_file_owner_group "$PWD/build/rec/test.sh" - '1000'
}

@test "should change group ID to specified ID" {
  run docker run -e PGID=2000 --name "$BATS_TEST_NAME" -v "$PWD:/tmp" -w /tmp "$BUILD_TAG" --rec-dir /tmp test.rec
  assert_file_owner_group "$PWD/build/rec/test.sh" - '2000'
}
