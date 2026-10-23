#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  declare -r -g pattern='> %d <\n'
  declare -r -g puid='$(id -u)'
  declare -r -g pgid='$(id -g)'
}

@test "should persist APP_USER and APP_GROUP in entrypoint.sh" {
  mkdir rec
  image "$BUILD_TAG"
  run docker cp "${BATS_TEST_NAME}:/usr/local/sbin/entrypoint.sh" -
  assert_line '  local -r app_user=recordr app_group=recordr'
}

@test "should change user ID to 1000 by default" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$puid" >rec/test.rec
  IMAGE_PUID='' image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp rec/test.rec
  assert_line --partial "> 1000 <"
}

@test "should change group ID to 1000 by default" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$pgid" >rec/test.rec
  IMAGE_PGID='' image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp rec/test.rec
  assert_line --partial "> 1000 <"
}

@test "should change user ID to specified ID" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$puid" >rec/test.rec
  IMAGE_PUID="echo 2000" image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp rec/test.rec
  assert_line --partial "> 2000 <"
}

@test "should change group ID to specified ID" {
  mkdir rec && printf 'printf "%b" "%b"' "$pattern" "$pgid" >rec/test.rec
  IMAGE_PGID="echo 2000" image "$BUILD_TAG" --build-dir /tmp --out-dir /tmp rec/test.rec
  assert_line --partial "> 2000 <"
}

@test "should preserve configured primary GID with a distinct application group name" {
  IMAGE_PUID="echo 2000" IMAGE_PGID="echo 2001" image \
    --entrypoint bash "$BUILD_TAG" -ec '
      groupmod --new-name recording recordr
      sed -i "s/app_group=recordr/app_group=recording/" /usr/local/sbin/entrypoint.sh
      cat >/usr/local/bin/entrypoint_user.sh <<"CHECK"
#!/usr/bin/env bash
printf "recording uid=%s gid=%s\n" "$(id -u)" "$(id -g)"
CHECK
      exec /usr/local/sbin/entrypoint.sh
    '

  assert_line 'recording uid=2000 gid=2001'
}
