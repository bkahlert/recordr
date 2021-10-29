#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh "$BUILD_TAG?unspecified image to test}"
}

teardown() {
  docker rm --force "$BATS_TEST_NAME" >/dev/null 2>&1 || true
}

@test "should change timezone to UTC by default" {
  mv "$(mkfile 'date +"%Z"')" test.rec
  local output && output="$(docker run --name "$BATS_TEST_NAME" -v "$PWD:/tmp" -w /tmp "$BUILD_TAG" --rec-dir /tmp test.rec)"
  assert_output --partial 'UTC'
}

@test "should change timezone to specified timezone" {
  mv "$(mkfile 'date +"%Z"')" test.rec
  local output && output="$(docker run -e "TZ=CEST" --name "$BATS_TEST_NAME" -v "$PWD:/tmp" -w /tmp "$BUILD_TAG" --rec-dir /tmp test.rec)"
  assert_output --partial 'CEST'
}
