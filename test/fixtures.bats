#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load helpers/mock.sh
}

@test "should have working demo.rec" {
  run bash "$(recording "demo.rec")"

  assert_success
  assert_line " 💡 This is a [31m● rec(B[m file."
  assert_line "The moment it hits 0 the animation plays again."
}

@test "should have working recordr.rec" {
  run bash "$(recording "recordr.rec" "$(asciinema_mock test.cast)" "$(svg-term_mock test.svg.0)")"

  assert_success
  assert_output "\
 ℹ terminal profile search directory: rec/
 ✔ terminal profile: rec/.iterm"''"colors
 ● RECORDING rec/logr.rec
 ◕ CONVERTING build/rec/logr.cast
 ✔ COMPLETED build/rec/logr.svg"
}

@test "should have working logr.rec" {
  run bash "$(recording "logr.rec")"

  assert_line '   ▔▔▔▔▔▔▔ LOGR DEMO'
  assert_line ' ℹ Lorem ipsum dolor sit amet.'
  assert_line ' ✔ 2 seconds of work'
  assert_line ' ! Extracting link from sources and placing it in the top right corner. ↗︎'
  assert_line ' … Cleaning up'
}

@test "should have working chafa.rec" {
  run bash "$(recording "chafa.rec")"

  assert_success
  assert_output "$(cat "$(fixture nyan-cat.ansi)")"
}
