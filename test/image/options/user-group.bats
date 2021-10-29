#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load ../helpers/setup.sh "$BUILD_TAG?unspecified image to test}"
}

teardown() {
  image_cleanup
}

@test "should persist APP_USER and APP_GROUP in entrypoint.sh" {
  mkdir rec
  image "$BUILD_TAG"
  run docker cp "${BATS_TEST_NAME}:/usr/local/sbin/entrypoint.sh" -
  assert_line '  local -r app_user=recordr app_group=recordr'
}
