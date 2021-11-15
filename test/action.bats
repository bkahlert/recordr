#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert
  load_lib file

  load helpers/mock.sh
  load helpers/svg.sh

  cp -R action.yml "$BATS_TEST_TMPDIR"
  cp -R logr.sh "$BATS_TEST_TMPDIR"
  cp -R recordr "$BATS_TEST_TMPDIR"
  cp -R recordrw "$BATS_TEST_TMPDIR"
  cp -R .git "$BATS_TEST_TMPDIR"
  cd "$BATS_TEST_TMPDIR" || exit
  mkdir -p rec
  copy_fixture test.rec rec/hello-world.rec
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
  opts+=("${ACTW_IMAGE:-efrecon/act:${ACTW_IMAGE_TAG:-v0.2.24}}")

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
        uses: actions/checkout@v2
      - name: ● REC
        id: recordr
        uses: ./
        with:
          files: rec/hello-world.rec
WORKFLOW

  run act -j test
  assert_output --partial '[test workflow/test]   ⚙  ::set-output:: status=0
[test workflow/test]   ⚙  ::set-output:: files=docs/hello-world.svg
[test workflow/test]   ⚙  ::set-output:: file-list=docs/hello-world.svg
[test workflow/test]   ⚙  ::set-output:: markdown=<details>
<summary>docs/hello-world.svg</summary>
<h3>Preview</h3>'
  assert_output --partial '[![description of the contents of hello-world](../raw/'
  assert_output --partial '/docs/hello-world.svg "Title of Hello World")'
  assert_output --partial '*Title of Hello World*](../raw/'
  assert_output --partial '/docs/hello-world.svg)'
  assert_output --partial '<h3>Markdown</h3>

```markdown
[![description of the contents of hello-world](docs/hello-world.svg "Title of Hello World")
*Title of Hello World*](../../raw/master/docs/hello-world.svg)
```

</details>
[test workflow/test]   ✅  Success - ● REC'
}
