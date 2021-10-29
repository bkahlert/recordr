#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh "${BUILD_TAG:?unspecified image to test}"
  load ../helpers/svg.sh
}

teardown() {
  docker rm --force "$BATS_TEST_NAME" >/dev/null 2>&1 || true
  if [ -e data ] && ! rm -rf data; then
    echo "Failed to delete data. Try the following command to resolve this issue:"
    echo "docker run --rm -v '$PWD:/work' ubuntu bash -c 'chmod -R +w /work/data; rm -rf /work/data'"
    exit 1
  fi
  if [ -e disk.img ] && ! rm -f disk.img; then
    echo "Failed to delete data. Try the following command to resolve this issue:"
    echo "docker run --rm -v '$PWD:/work' ubuntu bash -c 'chmod -R +w /work/disk.img; rm -rf /work/disk.img'"
    exit 1
  fi
}

@test "should print help" {
  run --separate-stderr docker run -i --name "$BATS_TEST_NAME" "$BUILD_TAG" --help
  assert_container_status "$BATS_TEST_NAME" 'exited'
  assert_success
  assert_output --partial '
   ▔▔▔▔▔▔▔ RECORDR SNAPSHOT

   Usage: recordr [OPTIONS] [FILE...]

   Options:
     --'
  assert_line '     --rec-dir              path to prefix specified rec files with (default: rec/)'
  assert_output --partial '
   Files:
     Specify any number of files relative to the `rec-dir`.
     If no files are specified, all files located in the `rec-dir` are processed.'
}

@test "should record all rec files in rec directory and convert them to svg in docs directory" {
  mkdir rec
  mkdir rec/foo
  cp_fixture .itermcolors .
  cp_fixture test.rec rec
  cp rec/test.rec rec/foo/bar.rec

  run docker run -i --name "$BATS_TEST_NAME" \
    -e TZ="$(date +"%Z")" \
    -e PUID="$(id -u)" \
    -e PGID="$(id -g)" \
    -e NODE_OPTIONS="--max-old-space-size=16384" \
    -e TERM="$TERM" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w "$PWD" \
    "$BUILD_TAG"

  assert_container_status "$BATS_TEST_NAME" 'exited'
  assert_success
  assert_equal_svg_fixture "test.svg" "docs/test.svg"
  assert_equal_svg_fixture "test.svg" "docs/foo/bar.svg"
  assert_line " ℹ terminal profile search directory: rec/"
  assert_line "●◕ BATCH RECORD AND CONVERT"
  assert_line " ℹ recordings directory: rec/"
  assert_line " ● RECORDING rec/test.rec"
  assert_line " ● RECORDING rec/foo/bar.rec"
  assert_line " ◕ CONVERTING build/rec/foo/bar.cast"
  assert_line " ◕ CONVERTING build/rec/test.cast"
  assert_line " ✔ COMPLETED build/rec/test.svg"
  assert_line " ✔ COMPLETED build/rec/foo/bar.svg"
  assert_line " ✔ BATCH COMPLETED"
}
