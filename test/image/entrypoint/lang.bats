#!/usr/bin/env bats

@test "should change LANG to C.UTF-8 by default" {
  mkdir rec && echo 'echo "> $LANG <"' >rec/test.rec
  image "$BUILD_TAG" rec/test.rec
  assert_line --partial "> C.UTF-8 <"
}

@test "should change LANG to specified lang" {
  mkdir rec && echo 'echo "> $LANG <"' >rec/test.rec
  image -e "LANG=C" "$BUILD_TAG" rec/test.rec
  assert_line --partial "> C <"
}
