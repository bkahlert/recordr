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

@test "should preserve LC_ALL in recorded commands" {
  mkdir rec && echo 'echo "> $LC_ALL <"' >rec/test.rec
  image -e "LC_ALL=C" "$BUILD_TAG" rec/test.rec
  assert_line --partial "> C <"
}

@test "should leave LC_ALL unset in recorded commands by default" {
  mkdir rec && echo 'echo "> ${LC_ALL-unset} <"' >rec/test.rec
  image "$BUILD_TAG" rec/test.rec
  assert_line --partial "> unset <"
}
