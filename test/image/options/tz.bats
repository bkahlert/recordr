#!/usr/bin/env bats

setup() {
  # TODO move build_tag to setup.sh
  load ../helpers/setup.sh "$BUILD_TAG?unspecified image to test}"
}

teardown() {
  image_cleanup
}

@test "should change timezone to UTC by default" {
  mkdir rec && echo 'date +"%Z"' >rec/test.rec
  image "$BUILD_TAG" test.rec
  assert_line --partial UTC
}

@test "should change timezone to specified timezone" {
  mkdir rec && echo 'date +"%Z"' >rec/test.rec
  image -e "TZ=CEST" "$BUILD_TAG" test.rec
  assert_line --partial CEST
}
