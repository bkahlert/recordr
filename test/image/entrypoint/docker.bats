#!/usr/bin/env bats
# shellcheck disable=SC2218

@test "should reuse the Docker socket group" {
  socket_image 0
}

@test "should create a missing Docker socket group" {
  socket_image 65532
}

@test "should preserve primary group matching the Docker socket" {
  socket_image 2001
}

socket_image() {
  local -r socket_gid="$1"
  IMAGE_PUID="echo 2000" IMAGE_PGID="echo 2001" image \
    --env "SOCKET_GID=$socket_gid" --entrypoint bash "$BUILD_TAG" -ec '
      ssh-agent -a /var/run/docker.sock >/dev/null
      chown "0:$SOCKET_GID" /var/run/docker.sock
      chmod 0660 /var/run/docker.sock
      cat >/usr/local/bin/entrypoint_user.sh <<"CHECK"
#!/usr/bin/env bash
printf "recording uid=%s gid=%s\n" "$(id -u)" "$(id -g)"
stat -c "socket=%u:%g %a" /var/run/docker.sock
[ -r /var/run/docker.sock ] && [ -w /var/run/docker.sock ]
CHECK
      exec /usr/local/sbin/entrypoint.sh
    '

  assert_line 'recording uid=2000 gid=2001'
  assert_line "socket=0:$socket_gid 660"
}
