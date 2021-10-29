#!/usr/bin/env bats

setup() {
  load ../helpers/common.sh
  load_lib support
  load_lib assert
  load_lib file

  load ../helpers/mock.sh
  load ../helpers/svg.sh

  cd "$BATS_TEST_TMPDIR" || exit
  mkdir rec
  cp_fixture test.rec rec
  cp "${BATS_CWD}/logr.sh" .
}

@test "should record all rec files in rec directory and convert them to svg in docs directory" {
  mkdir rec/foo
  cp rec/test.rec rec/foo/bar.rec
  run mocked_recordr
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

@test "should record specified rec files in rec directory and convert them to svg in docs directory" {
  mkdir rec/foo
  cp rec/test.rec rec/foo/bar.rec
  run mocked_recordr test.rec foo/bar.rec
  assert_success
  assert_equal_svg_fixture "test.svg" "docs/test.svg"
  assert_equal_svg_fixture "test.svg" "docs/foo/bar.svg"
  assert_line " ℹ terminal profile search directory: rec/"
  assert_line "●◕ BATCH RECORD AND CONVERT"
  assert_line " ℹ recordings directory: rec/"
  assert_line " ℹ files: test.rec foo/bar.rec"
  assert_line " ● RECORDING rec/test.rec"
  assert_line " ● RECORDING rec/foo/bar.rec"
  assert_line " ◕ CONVERTING build/rec/foo/bar.cast"
  assert_line " ◕ CONVERTING build/rec/test.cast"
  assert_line " ✔ COMPLETED build/rec/test.svg"
  assert_line " ✔ COMPLETED build/rec/foo/bar.svg"
  assert_line " ✔ BATCH COMPLETED"
}

@test "should record specified rec file and convert it to svg" {
  run mocked_recordr test.rec
  assert_success
  assert_equal_svg_fixture "test.svg" "docs/test.svg"
  assert_line " ℹ terminal profile search directory: rec/"
  assert_line " ● RECORDING rec/test.rec"
  assert_line " ◕ CONVERTING build/rec/test.cast"
  assert_line " ✔ COMPLETED build/rec/test.svg"
}

@test "should append .rec automatically" {
  run mocked_recordr test
  assert_success
  assert_equal_svg_fixture "test.svg" "docs/test.svg"
}

@test "should use specified rec-dir" {
  mv rec specified
  run mocked_recordr --rec-dir specified test.rec
  assert_success
  assert_equal_svg_fixture "test.svg" "docs/test.svg"
}

@test "should use specified build-dir" {
  run mocked_recordr --build-dir build test.rec
  assert_success
  assert_dir_exist build
  assert_file_exist build/test.sh
  assert_file_exist build/test.cast
  assert_file_exist build/test.svg
}

@test "should use specified out-dir" {
  run mocked_recordr --out-dir out test.rec
  assert_success
  assert_equal_svg_fixture "test.svg" "out/test.svg"
}

@test "should use term xterm-256color by default" {
  run mocked_recordr test.rec
  assert_file_contains asciinema.env 'TERM=xterm-256color'
}
@test "should use specified term" {
  run mocked_recordr --term xterm test.rec
  assert_file_contains asciinema.env 'TERM=xterm'
}
@test "should fail on invalid term" {
  run mocked_recordr --term invalid test.rec
  assert_failure
  assert_line --partial 'unknown terminal `invalid`'
}

@test "should use indicator RECORDING by default" {
  run mocked_recordr --build-dir . test.rec
  assert_file_contains test.sh 'export RECORDING=1'
}
@test "should use specified indicator" {
  run mocked_recordr --build-dir . --indicator SPECIFIED test.rec
  assert_file_contains test.sh 'export SPECIFIED=1'
}

@test "should use 132 columns and 25 rows by default" {
  run mocked_recordr --build-dir . test.rec
  # shellcheck disable=SC2034
  output=$(cat test.sh)
  assert_output --partial "printf '[8;25;132t'"
}
@test "should use specified columns and rows" {
  run mocked_recordr --build-dir . --columns 133 --rows 26 SPECIFIED test.rec
  # shellcheck disable=SC2034
  output=$(cat test.sh)
  assert_output --partial "printf '[8;26;133t'"
}

@test "should use restart-delay 5 default" {
  TESTING='' run mocked_recordr --build-dir . test.rec
  # shellcheck disable=SC2034
  output=$(cat test.sh)
  assert_output --partial "# RESTART IN 5 SECONDS(S)"
  assert_output --partial "tput civis"
  assert_output --partial "printf '5%s' \"\$(tput hpa 0)\""
  assert_output --partial "sleep .5; tput c""norm; sleep .5; tput civis;"
  assert_output --partial "printf '4%s' \"\$(tput hpa 0)\""
  assert_output --partial "sleep .5; tput c""norm; sleep .5; tput civis;"
  assert_output --partial "printf '3%s' \"\$(tput hpa 0)\""
  assert_output --partial "sleep .5; tput c""norm; sleep .5; tput civis;"
  assert_output --partial "printf '2%s' \"\$(tput hpa 0)\""
  assert_output --partial "sleep .5; tput c""norm; sleep .5; tput civis;"
  assert_output --partial "printf '1%s' \"\$(tput hpa 0)\""
  assert_output --partial "sleep .5; tput c""norm; sleep .5; tput civis;"
}
@test "should use specified restart-delay" {
  TESTING='' run mocked_recordr --build-dir . --restart-delay 2 test.rec
  # shellcheck disable=SC2034
  output=$(cat test.sh)
  assert_output --partial "# RESTART IN 2 SECONDS(S)"
  assert_output --partial "tput civis"
  assert_output --partial "printf '2%s' \"\$(tput hpa 0)\""
  assert_output --partial "sleep .5; tput c""norm; sleep .5; tput civis;"
  assert_output --partial "printf '1%s' \"\$(tput hpa 0)\""
  assert_output --partial "sleep .5; tput c""norm; sleep .5; tput civis;"
}

@test "should find term-profile by default" {
  cp_fixture .itermcolors rec
  run mocked_recordr --build-dir . test.rec
  assert_file_contains svg-term.args " --profile $PWD/rec/.iterm""colors"
}
@test "should use any term-profile if multiple are found" {
  mkdir rec/bar
  cp_fixture .itermcolors rec/foo.itermcolors
  cp_fixture .itermcolors rec/bar/baz.itermcolors
  run mocked_recordr --build-dir . test.rec
  assert_file_contains svg-term.args " --profile $PWD/rec/bar/baz.iterm""colors"
}
@test "should use specified term-profile" {
  cp_fixture .itermcolors rec/foo.itermcolors
  cp_fixture .itermcolors rec/bar.itermcolors
  cp_fixture .itermcolors rec/baz.itermcolors
  run mocked_recordr --build-dir . --term-profile rec/bar.itermcolors test.rec
  assert_file_contains svg-term.args " --profile $PWD/rec/bar.iterm""colors"
}
@test "should auto-detect term" {
  cp_fixture .itermcolors rec/bar.itermcolors
  run mocked_recordr --build-dir . --term-profile rec/bar.itermcolors test.rec
  assert_file_contains svg-term.args " --term iterm2"
}
@test "should use no term-profile if none was found" {
  run mocked_recordr --build-dir . test.rec
  assert_file_not_contains svg-term.args " --term"
  assert_file_not_contains svg-term.args " --profile"
}

@test "should record in parallel by default" {
  cp rec/test.rec rec/test2.rec
  run mocked_recordr --build-dir . test.rec test2.rec
  output=${output//test2/test}
  assert_output --partial " ● RECORDING rec/test.rec
 ● RECORDING rec/test.rec"
}
@test "should record using specified number of processes" {
  cp rec/test.rec rec/test2.rec
  run mocked_recordr --build-dir . --parallel 1 test.rec test2.rec
  assert_output --partial " ● RECORDING rec/test.rec
 ◕ CONVERTING test.cast"
}

@test "should keep build by default" {
  run mocked_recordr --build-dir build test.rec
  assert_success
  assert_file_exist build/test.sh
  assert_file_exist build/test.cast
  assert_file_exist build/test.svg
}
@test "should delete build if specified" {
  run mocked_recordr --build-dir build --delete-build test.rec
  assert_success
  assert_file_not_exist build/test.sh
  assert_file_not_exist build/test.cast
  assert_file_not_exist build/test.svg
}

@test "should create intermediary svg files" {
  run mocked_recordr --build-dir build test.rec
  assert_success
  assert_dir_exist build
  assert_file_exist build/test.svg.1
  assert_file_exist build/test.svg.2
  assert_file_exist build/test.svg.3
}
