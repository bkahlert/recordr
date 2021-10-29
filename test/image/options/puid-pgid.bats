#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load ../helpers/setup.sh "$BUILD_TAG?unspecified image to test}"
  declare -r -g pattern='> %d <\n'
  declare -r -g puid='$(id -u)'
  declare -r -g pgid='$(id -g)'
}

teardown() {
  image_cleanup
}

@test "should change user ID to 1000 by default" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$puid" >rec/test.rec
  IMAGE_PUID='' image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp test.rec
  assert_line --partial "> 1000 <"
}

@test "should change group ID to 1000 by default" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$pgid" >rec/test.rec
  IMAGE_PGID='' image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp test.rec
  assert_line --partial "> 1000 <"
}

@test "should change user ID to specified ID" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$puid" >rec/test.rec
  IMAGE_PUID="echo 2000" image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp test.rec
  assert_line --partial "> 2000 <"
}

@test "should change group ID to specified ID" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$pgid" >rec/test.rec
  IMAGE_PGID="echo 2000" image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp test.rec
  assert_line --partial "> 2000 <"
}

# TODO fix test
# TODO fix fixtures tests
# TODO refactor bats files (PUID, PGID, etc)
# TODO delete mkfile
# TODO rename cp_fixture
