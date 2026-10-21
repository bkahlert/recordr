#!/usr/bin/env bats

setup() {
  load helpers/mock.sh
  load helpers/svg.sh

  cp -R action.yml "$BATS_TEST_TMPDIR"
  cp -R logr.sh "$BATS_TEST_TMPDIR"
  cp -R recordr "$BATS_TEST_TMPDIR"
  cp -R recordrw "$BATS_TEST_TMPDIR"
  cp -R .git "$BATS_TEST_TMPDIR"
  mkdir -p "${BATS_TEST_TMPDIR%/}/rec"
  copy_fixture test.rec "${BATS_TEST_TMPDIR%/}/rec/hello-world.rec"
}

teardown() {
  unlock
}

actw() {
  local wrapper_name=${FUNCNAME[0]}
  local -a args=() wrapper_args=()
  while (($#)); do
    case $1 in
      --${wrapper_name?}:*)
        wrapper_args+=("${1#--${wrapper_name?}:}")
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done
  set -- "${args[@]}"

  local -a opts=()
  opts+=("-e" "TESTING=${TESTING-}")
  opts+=("-e" "RECORDING=${RECORDING-}")
  opts+=("-e" "TERM=${TERM-}")

  # Adds the given arguments to the opts array
  opts() { eval 'opts+=("$@")'; }
  [ ! -t 0 ] || opts+=("--interactive")
  [ ! -t 1 ] || [ ! -t 2 ] || [ "${TERM-}" = dumb ] || opts+=("--tty")
  [ ! -v ACTW_ARGS ] || eval opts "$ACTW_ARGS"
  opts+=("${wrapper_args[@]}")
  opts+=("--rm")
  opts+=("--name" "$wrapper_name--$(head /dev/urandom | LC_ALL=C.UTF-8 tr -dc A-Za-z0-9 2>/dev/null | head -c 3)")
  opts+=("${ACTW_IMAGE:-efrecon/act:${ACTW_IMAGE_TAG:-v0.2.89}}")

  docker run \
    -e DEBUG="${DEBUG-}" \
    -e TZ="$(date +"%Z")" \
    -e PUID="$(id -u)" \
    -e PGID="$(id -g)" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":"$PWD" \
    -w "$PWD" \
    "${opts[@]+"${opts[@]}"}" \
    "$@"
}

# Note: --env arguments are not passed to the act wrapper but to act itself which
#       provides the corresponding environment variables inside the workflow
act() {
  export RECORDRW_ARGS
  RECORDRW_ARGS=$(
    cat <<RECORDRW_ARGS
-e PUID="$(id -u)" \
-e PGID="$(id -g)" \
-v "$PWD/recordr":/usr/local/bin/recordr \
-v "$PWD/logr.sh":/usr/local/bin/logr.sh
RECORDRW_ARGS
  )

  actw \
    --bind \
    --env TESTING="${TESTING-}" \
    --env RECORDING="${RECORDING-}" \
    --env TERM="${TERM-}" \
    --env RECORDRW_IMAGE_TAG=edge \
    --env RECORDRW_ARGS="${RECORDRW_ARGS-}" \
    --platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest \
    "$@"
}

@test "should run action" {
  local workflows="$BATS_TEST_TMPDIR/.github/workflows"
  mkdir -p "$workflows"
  cat <<WORKFLOW >"$workflows/act-test.yml"
name: test workflow
on: [push,workflow_dispatch]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7.0.1
      - name: ● REC
        id: recordr
        uses: ./
        with:
          files: rec/hello-world.rec
      - name: Verify outputs
        env:
          STATUS: \${{ steps.recordr.outputs.status }}
          FILES: \${{ steps.recordr.outputs.files }}
          FILE_LIST: \${{ steps.recordr.outputs.file-list }}
          MARKDOWN: \${{ steps.recordr.outputs.markdown }}
        run: |
          set -e
          test "\$STATUS" = 0
          test "\$FILES" = docs/hello-world.svg
          test "\$FILE_LIST" = docs/hello-world.svg
          [[ "\$MARKDOWN" == *'<summary>docs/hello-world.svg</summary>'* ]]
          [[ "\$MARKDOWN" == *'../../raw/master/docs/hello-world.svg)'* ]]
          printf '%s\n' 'Action outputs verified'
WORKFLOW

  run act -j test
  assert_success
  assert_output --partial 'Action outputs verified'
}
