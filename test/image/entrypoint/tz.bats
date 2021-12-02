#!/usr/bin/env bats

@test "should change timezone to UTC by default" {
  mkdir rec && echo 'date +"%Z"' >rec/test.rec
  image "$BUILD_TAG" rec/test.rec
  assert_line --partial UTC
}

@test "should change timezone to specified timezone" {
  mkdir rec && echo 'date +"%Z"' >rec/test.rec
  image -e "TZ=CEST" "$BUILD_TAG" rec/test.rec
  assert_line --partial CEST
}
