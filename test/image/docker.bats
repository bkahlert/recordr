#!/usr/bin/env bats
# bashsupport disable=BP5007

@test "should provide Docker client" {
  mkdir rec && echo "docker --version" >rec/test.rec
  image "$BUILD_TAG" rec/test.rec
  assert_line --partial 'Docker version'
  assert_line --partial 'build'
}

@test "should pass-through socket" {
  mkdir rec && echo "docker run --rm hello-world" >rec/test.rec
  image -v /var/run/docker.sock:/var/run/docker.sock "$BUILD_TAG" rec/test.rec
  assert_line --partial 'Hello from Docker!'
}

@test "should access Docker socket without changing recording user or primary group" {
  local socket_gid recording_gid=2000
  socket_gid=$(docker run --rm --entrypoint stat \
    -v /var/run/docker.sock:/var/run/docker.sock "$BUILD_TAG" \
    -c '%g' /var/run/docker.sock)
  [ "$socket_gid" != "$recording_gid" ] || recording_gid=2001

  mkdir rec
  cat >rec/test.rec <<'RECORDING'
printf 'recording uid=%s gid=%s\n' "$(id -u)" "$(id -g)"
docker info --format 'docker server={{.ServerVersion}}'
RECORDING

  IMAGE_PUID="echo 2000" IMAGE_PGID="echo $recording_gid" \
    image -v /var/run/docker.sock:/var/run/docker.sock "$BUILD_TAG" \
    --build-dir /tmp/rec --out-dir /tmp/docs rec/test.rec

  assert_line --partial "recording uid=2000 gid=$recording_gid"
  assert_line --partial 'docker server='
  refute_output --partial 'permission denied'
}
