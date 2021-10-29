#!/bin/bash

set -euo pipefail

# TODO remove?
export IMAGE_ID=${2:?}
if [ -f "$BATS_TEST_DIRNAME/../helpers/common.sh" ]; then
  load "$BATS_TEST_DIRNAME/../helpers/common.sh"
else
  load "$BATS_TEST_DIRNAME/../../helpers/common.sh"
fi

load_lib support
load_lib assert
load_lib file

assert [ "${IMAGE_ID-}" ]
cd "$BATS_TEST_TMPDIR" || exit 1

export IMAGE_PUID="id -u"
export IMAGE_PGID="id -g"

# Runs the specified Docker image with app specific defaults
# and the specified options.
# bashsupport disable=BP2001
# shellcheck disable=SC2034
image() {
  [ $# -gt 0 ] || fail 'IMAGE missing'
  output=$(
    case $1 in
    --stdout-only)
      shift
      exec 2>/dev/null
      ;;
    --stderr-only)
    shift
      exec 2>&1 1>/dev/null
      ;;
    *)
      exec 2>&1
      ;;
    esac

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
  assert_success
  assert_container_status "$BATS_TEST_NAME" exited
}

# Cleans up an eventually still running container.
image_cleanup() {
  docker rm --force "${BATS_TEST_NAME?must be only called from within a running test}" >/dev/null 2>&1 || true
}
