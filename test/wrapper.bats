#!/usr/bin/env bats

setup() {
  load helpers/mock.sh
  load helpers/svg.sh

  cp "$BATS_CWD/logr.sh" "$BATS_TEST_TMPDIR"
  mkdir -p "${BATS_TEST_TMPDIR%/}/rec/bar"

  export RECORDRW_ARGS
  RECORDRW_ARGS=$(cat <<RECORDRW_ARGS
-v "$BATS_CWD/recordr":/usr/local/bin/recordr \
-v "$BATS_CWD/logr.sh":/usr/local/bin/logr.sh
RECORDRW_ARGS
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
