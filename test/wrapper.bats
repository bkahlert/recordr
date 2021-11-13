#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert
  load_lib file

  load helpers/mock.sh
  load helpers/svg.sh

  cd "$BATS_TEST_TMPDIR" || exit
  cp "$BATS_CWD/logr.sh" .
  mkdir -p rec/bar

  export DOCKER_ARGS
  DOCKER_ARGS=$(cat <<DOCKER_ARGS
-v "$BATS_CWD/recordr":/usr/local/bin/recordr \
-v "$BATS_CWD/logr.sh":/usr/local/bin/logr.sh
DOCKER_ARGS
)
}

@test "should do the same as wrapped" {
  assert_alias "bash -c '\"$BATS_CWD/recordrw\"'" "bash -c '\"$BATS_CWD/recordr\"'"
}

@test "should do same on redirected STDOUT" {
  assert_alias "bash -c 'echo \"\$($BATS_CWD/recordrw)\"'" "bash -c 'echo \"\$($BATS_CWD/recordr)\"'"
}

@test "should do same on redirected STDERR" {
  assert_alias "bash -c '\"$BATS_CWD/recordrw\" 2>/dev/null'" "bash -c '\"$BATS_CWD/recordr\" 2>/dev/null'"
}

@test "should print same help as wrapped" {
  assert_alias "bash -c '\"$BATS_CWD/recordrw\" --help'" "bash -c '\"$BATS_CWD/recordr\" --help'"
}

@test "should print same help on redirected STDOUT" {
  assert_alias "bash -c 'echo \"\$($BATS_CWD/recordrw)\" --help'" "bash -c 'echo \"\$($BATS_CWD/recordr)\" --help'"
}

@test "should print same help on redirected STDERR" {
  assert_alias "bash -c '\"$BATS_CWD/recordrw\" --help 2>/dev/null'" "bash -c '\"$BATS_CWD/recordr\" --help 2>/dev/null'"
}
