#!/usr/bin/env bash

set -uo pipefail

if [ -f "$BATS_TEST_DIRNAME/../helpers/common.sh" ]; then
  load "$BATS_TEST_DIRNAME/../helpers/common.sh"
else
  load "$BATS_TEST_DIRNAME/../../helpers/common.sh"
fi

load_lib support
load_lib assert
load_lib file

cd "$BATS_TEST_TMPDIR" || exit 1

export IMAGE_PUID="id -u"
export IMAGE_PGID="id -g"

# Runs the specified Docker image with app specific defaults
# and the specified options.
# bashsupport disable=BP2001
# shellcheck disable=SC2034
image() {
  local args=() expected_status=0 filter
  while (($#)); do
    case $1 in
      --stdout-only)
        filter=1 && shift
        ;;
      --stderr-only)
        filter=2 && shift
        ;;
      --code=*)
        expected_status=${1#*=} && shift
        ;;
      *)
        args+=("$1") && shift
        ;;
    esac
  done
  set -- "${args[@]}"
  [ $# -gt 0 ] || fail 'IMAGE missing'
  output=$(
    exec 2>&1
    [ ! "${filter-}" = 1 ] || exec 2>/dev/null
    [ ! "${filter-}" = 2 ] || exec 1>/dev/null

    docker run --name "${BATS_TEST_NAME?must be only called from within a running test}" \
      ${IMAGE_PUID+-e PUID="$($IMAGE_PUID)"} \
      ${IMAGE_PGID+-e PGID="$($IMAGE_PGID)"} \
      -e TERM="$TERM" \
      -v "$PWD":"$PWD" \
      -w "$PWD" \
      "$@"
  ) || status=$?
  [ "${status-}" ] || status=0
  batsw_separate_lines lines output
  if [ "$expected_status" -eq 0 ]; then
    assert_success
  else
    assert_failure "$expected_status"
  fi
  assert_container_status "$BATS_TEST_NAME" exited
}

# Cleans up an eventually still running container.
image_cleanup() {
  docker rm --force "${BATS_TEST_NAME?must be only called from within a running test}" >/dev/null 2>&1 || true
}
