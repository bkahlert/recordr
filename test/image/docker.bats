#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  load helpers/setup.sh
}

teardown() {
  image_cleanup
}

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
