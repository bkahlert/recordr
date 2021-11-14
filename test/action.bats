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
  chmod -R +rw "$BATS_TEST_TMPDIR"
}

act() {
  docker run \
    --name "act--$(head /dev/urandom | LC_ALL=C.UTF-8 tr -dc A-Za-z0-9 2>/dev/null | head -c 3)" \
    --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":"$PWD" \
    -w "$PWD" \
    efrecon/act:v0.2.24 \
    -b \
    -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest \
    "$@"
}

@test "Xshould run action" {
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

  export DOCKER_ARGS
  DOCKER_ARGS=$(
    cat <<DOCKER_ARGS
-v "$PWD/recordr":/usr/local/bin/recordr \
-v "$PWD/logr.sh":/usr/local/bin/logr.sh
DOCKER_ARGS
  )

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
