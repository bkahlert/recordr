#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert
  load_lib file

  load helpers/mock.sh
  load helpers/svg.sh

  cd "$BATS_TEST_TMPDIR" || exit
  cp "${BATS_CWD}/logr.sh" .
  mkdir -p rec/bar
  copy_fixture test.rec rec/foo.rec
  copy_fixture test.rec rec/bar/baz.rec
}

@test "should record all rec files in rec directory and convert them to svg in docs directory by default" {
  run bash "$(mocked_recordr)"
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_line "●◕ BATCH PROCESSING"
  assert_line " ℹ recordings directory: rec"
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ● RECORDING: rec/bar/baz.rec"
  assert_line " ◔ CONVERTING: build/rec/bar/baz.cast"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◑ PATCHING: build/rec/bar/baz.svg.0"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◕ LINKING: build/rec/bar/baz.svg.1"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ● ANNOTATING: build/rec/bar/baz.svg.2"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● COMPLETED: docs/foo.svg"
  assert_line " ● COMPLETED: docs/bar/baz.svg"
  assert_line " ✔ BATCH PROCESSING: COMPLETED"
}

@test "should output completed files separately on redirected STDOUT" {
  run bash -c "echo \"\$('$(mocked_recordr)')\""
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_output --regexp 'docs/.*.svg'$'\n''docs/.*.svg'
}

@test "should output completed files separately on redirected STDERR" {
  run bash -c "'$(mocked_recordr)' 2>/dev/null"
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_output --regexp 'docs/.*.svg'$'\n''docs/.*.svg'
}

@test "should record all rec files in specified recordings directory" {
  run bash "$(mocked_recordr)" rec/
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_line "●◕ BATCH PROCESSING"
  assert_line " ℹ recordings directory: rec"
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ● RECORDING: rec/bar/baz.rec"
  assert_line " ◔ CONVERTING: build/rec/bar/baz.cast"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◑ PATCHING: build/rec/bar/baz.svg.0"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◕ LINKING: build/rec/bar/baz.svg.1"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ● ANNOTATING: build/rec/bar/baz.svg.2"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● COMPLETED: docs/foo.svg"
  assert_line " ● COMPLETED: docs/bar/baz.svg"
  assert_line " ✔ BATCH PROCESSING: COMPLETED"
}

@test "should record all specified rec files relative to recordings directory contained in first file" {
  run bash "$(mocked_recordr)" rec/foo.rec bar/baz.rec
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_line "●◕ BATCH PROCESSING"
  assert_line " ℹ recordings directory: rec"
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ● RECORDING: rec/bar/baz.rec"
  assert_line " ◔ CONVERTING: build/rec/bar/baz.cast"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◑ PATCHING: build/rec/bar/baz.svg.0"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◕ LINKING: build/rec/bar/baz.svg.1"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ● ANNOTATING: build/rec/bar/baz.svg.2"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● COMPLETED: docs/foo.svg"
  assert_line " ● COMPLETED: docs/bar/baz.svg"
  assert_line " ✔ BATCH PROCESSING: COMPLETED"
}

@test "should record all specified rec files relative to specified recordings directory" {
  run bash "$(mocked_recordr)" rec foo.rec bar/baz.rec
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_equal_svg_fixture test.svg docs/bar/baz.svg
  assert_line "●◕ BATCH PROCESSING"
  assert_line " ℹ recordings directory: rec"
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ● RECORDING: rec/bar/baz.rec"
  assert_line " ◔ CONVERTING: build/rec/bar/baz.cast"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◑ PATCHING: build/rec/bar/baz.svg.0"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◕ LINKING: build/rec/bar/baz.svg.1"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ● ANNOTATING: build/rec/bar/baz.svg.2"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● COMPLETED: docs/foo.svg"
  assert_line " ● COMPLETED: docs/bar/baz.svg"
  assert_line " ✔ BATCH PROCESSING: COMPLETED"
}

@test "should record single specified rec file relative to its self-contained recordings directory" {
  run bash "$(mocked_recordr)" rec/foo.rec
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● COMPLETED: docs/foo.svg"
}

@test "should skip invalid files" {
  run bash "$(mocked_recordr --asciinema:"sleep 1")" rec/foo.rec rec/bar/baz.rec
  assert_failure
  assert_equal_svg_fixture test.svg docs/foo.svg
  assert_line "●◕ BATCH PROCESSING"
  assert_line " ℹ recordings directory: rec"
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ✘ NOT FOUND: rec/rec/bar/baz.rec"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● COMPLETED: docs/foo.svg"
  assert_line " ! BATCH PROCESSING: COMPLETED WITH ERRORS"
}

@test "should log asciinema errors" {
  run bash "$(mocked_recordr --asciinema:"exit 42")" rec/foo.rec
  assert_failure
  assert_line " ✘ RECORDING: asciinema did exit 42 while recording build/rec/foo.sh"
}

@test "should log svg-term errors" {
  run bash "$(mocked_recordr --svg-term:"exit 42")" rec/foo.rec
  assert_failure
  assert_line " ✘ CONVERTING: svg-term did exit 42 while recording build/rec/foo.cast"
}

@test "should record rec using interpreter" {
  {
    printf '#!%s\n' "$(mocked_recordr)"
    head -n -1 rec/foo.rec
  } >foo.patched.rec
  chmod +x foo.patched.rec
  run bash -c "./foo.patched.rec"
  assert_success
  assert_equal_svg_fixture test.svg docs/foo.patched.svg
  assert_line " ● RECORDING: foo.patched.rec"
  assert_line " ◔ CONVERTING: build/rec/foo.patched.cast"
  assert_line " ◑ PATCHING: build/rec/foo.patched.svg.0"
  assert_line " ◕ LINKING: build/rec/foo.patched.svg.1"
  assert_line " ● ANNOTATING: build/rec/foo.patched.svg.2"
  assert_line " ● COMPLETED: docs/foo.patched.svg"
}

@test "should use specified build-dir" {
  run bash "$(mocked_recordr)" --build-dir build rec/foo.rec
  assert_success
  assert_dir_exist build
  assert_file_exist build/foo.sh
  assert_file_exist build/foo.cast
  assert_file_exist build/foo.svg
}

@test "should use specified out-dir" {
  run bash "$(mocked_recordr)" --out-dir out rec/foo.rec
  assert_success
  assert_equal_svg_fixture test.svg out/foo.svg
}

@test "should use term xterm-256color by default" {
  run bash "$(mocked_recordr)" rec/foo.rec
  assert_file_contains asciinema.env 'TERM=xterm-256color'
}
@test "should use specified term" {
  run bash "$(mocked_recordr)" --term xterm rec/foo.rec
  assert_file_contains asciinema.env 'TERM=xterm'
}
@test "should fail on invalid term" {
  run bash "$(mocked_recordr)" --term invalid rec/foo.rec
  assert_failure
  assert_line --partial 'unknown terminal `invalid`'
}

@test "should use indicator RECORDING by default" {
  run bash "$(mocked_recordr)" --build-dir . rec/foo.rec
  assert_file_contains foo.sh 'export RECORDING=1'
}
@test "should use specified indicator" {
  run bash "$(mocked_recordr)" --build-dir . --indicator SPECIFIED rec/foo.rec
  assert_file_contains foo.sh 'export SPECIFIED=1'
}

@test "should use 132 columns and 25 rows by default" {
  run bash "$(mocked_recordr)" --build-dir . rec/foo.rec
  # shellcheck disable=SC2034
  output=$(cat foo.sh)
  assert_output --partial "printf '[8;25;132t'"
}
@test "should use specified columns and rows" {
  run bash "$(mocked_recordr)" --build-dir . --columns 133 --rows 26 rec/foo.rec
  # shellcheck disable=SC2034
  output=$(cat foo.sh)
  assert_output --partial "printf '[8;26;133t'"
}

@test "should use restart-delay 5 default" {
  TESTING='' run bash "$(mocked_recordr)" --build-dir . rec/foo.rec
  # shellcheck disable=SC2034
  output=$(cat foo.sh)
  assert_output --partial "trap 'count_down 5' EXIT"
}
@test "should use specified restart-delay" {
  TESTING='' run bash "$(mocked_recordr)" --build-dir . --restart-delay 2 rec/foo.rec
  # shellcheck disable=SC2034
  output=$(cat foo.sh)
  assert_output --partial "trap 'count_down 2' EXIT"
}

@test "should find term-profile by default" {
  copy_fixture .itermcolors rec
  run bash "$(mocked_recordr)" --build-dir . rec/foo.rec
  assert_file_contains svg-term.args " --profile $PWD/rec/.iterm""colors"
}
@test "should log term-profile search dir" {
  copy_fixture .itermcolors rec
  run bash "$(mocked_recordr)" --build-dir . rec/foo.rec
  assert_line " ℹ terminal profile search directory: rec"
}
@test "should use any term-profile if multiple are found" {
  copy_fixture .itermcolors rec/foo.itermcolors
  copy_fixture .itermcolors rec/bar/baz.itermcolors
  run bash "$(mocked_recordr)" --build-dir . rec/foo.rec
  assert_file_contains svg-term.args " --profile $PWD/.*.iterm""colors"
}
@test "should use specified term-profile" {
  copy_fixture .itermcolors rec/foo.itermcolors
  copy_fixture .itermcolors rec/bar.itermcolors
  copy_fixture .itermcolors rec/baz.itermcolors
  run bash "$(mocked_recordr)" --build-dir . --term-profile rec/bar.itermcolors rec/foo.rec
  assert_file_contains svg-term.args " --profile $PWD/rec/bar.iterm""colors"
}
@test "should auto-detect term" {
  copy_fixture .itermcolors rec/bar.itermcolors
  run bash "$(mocked_recordr)" --build-dir . --term-profile rec/bar.itermcolors rec/foo.rec
  assert_file_contains svg-term.args " --term iterm2"
}
@test "should use no term-profile if none was found" {
  run bash "$(mocked_recordr)" --build-dir . rec/foo.rec
  assert_file_not_contains svg-term.args " --term"
  assert_file_not_contains svg-term.args " --profile"
}

@test "should record in parallel by default" {
  run bash "$(mocked_recordr --asciinema:"sleep 1")" --build-dir . rec/foo.rec bar/baz.rec
  output=${output//test2/test}
  assert_output --regexp " ● RECORDING: rec\/(foo|bar\/baz).rec
 ● RECORDING: rec\/(foo|bar\/baz).rec"
}
@test "should record using specified number of processes" {
  cp rec/foo.rec rec/test2.rec
  run bash "$(mocked_recordr)" --build-dir . --parallel 1 rec foo.rec test2.rec
  assert_output --partial " ● RECORDING: rec/foo.rec
 ◔ CONVERTING: foo.cast"
}

@test "should keep build by default" {
  run bash "$(mocked_recordr)" --build-dir build rec/foo.rec
  assert_success
  assert_file_exist build/foo.sh
  assert_file_exist build/foo.cast
  assert_file_exist build/foo.svg.0
  assert_file_exist build/foo.svg.1
  assert_file_exist build/foo.svg.2
  assert_file_exist build/foo.svg.3
  assert_file_exist build/foo.svg
}
@test "should delete build if specified" {
  run bash "$(mocked_recordr)" --build-dir build --delete-build rec/foo.rec
  assert_success
  assert_file_not_exist build/foo.sh
  assert_file_not_exist build/foo.cast
  assert_file_not_exist build/foo.svg.0
  assert_file_not_exist build/foo.svg.1
  assert_file_not_exist build/foo.svg.2
  assert_file_not_exist build/foo.svg.3
  assert_file_not_exist build/foo.svg
}

@test "should create intermediary svg files" {
  run bash "$(mocked_recordr)" --build-dir build rec/foo.rec
  assert_success
  assert_dir_exist build
  assert_file_exist build/foo.svg.0
  assert_file_exist build/foo.svg.1
  assert_file_exist build/foo.svg.2
}
