#!/usr/bin/env bats

setup() {
  load helpers/mock.sh
}

# Creates shell script that runs the specified rec file.
# Additional arguments will be written to the shell script, that is,
# they must be valid shell script code in order to not break the script.
recording() {
  file="$(mktemp "$BATS_TEST_TMPDIR/XXXXXX")"
  {
    echo '#!/usr/bin/env bash'
    echo '
    rec() {
      if [ "$#" -eq 0 ]; then
        set -- -1 eval "$(cat -)"
      fi
      [[ ! "${1-}" =~ -[0-9]+ ]] || shift
      "$@"
    }
    '
    for part in "${@:2}"; do
      echo "$part"
    done
    cat "$BATS_CWD/rec/${1?rec file missing}"
  } >"$file"

  echo "$file"
}

@test "should have working hello-world.rec" {
  TERM=xterm run bash "$(recording "hello-world.rec")"
  assert_success
  assert_line "Hello World!"
}

@test "should have working recording-hello-world.rec" {
  run bash -c "cd '$BATS_CWD' && bash '$(recording "recording-hello-world.rec" "$(asciinema_mock test.cast)" "$(svg-term_mock test.svg.0)")'"

  assert_output --partial " ● COMPLETED: docs/hello-world.svg"
}

@test "should have working demo.rec" {
  TERM=xterm run bash "$(recording "demo.rec")"

  assert_success
  assert_line " 💡 This is a [31m● rec(B[m file."
  assert_line "The moment it hits 0 the animation plays again."
}

@test "should have working recording-demo.rec" {
  run bash -c "cd '$BATS_CWD' && bash '$(recording "recording-demo.rec" "$(asciinema_mock test.cast)" "$(svg-term_mock test.svg.0)")'"

  assert_output --partial ' ℹ terminal profile search directory: rec'
  assert_output --partial ' ✔ find_term_profile: terminal profile: rec/.itermcolors'
  assert_output --partial ' ● RECORDING: rec/demo.rec'
  assert_output --partial ' ● COMPLETED: docs/demo.svg'
}

@test "should have working logr.rec" {
  run bash "$(recording "logr.rec")"

  assert_line '   ▔▔▔▔▔▔▔ LOGR DEMO'
  assert_line ' ℹ Lorem ipsum dolor sit amet.'
  assert_line ' ✔ 2 seconds of work'
  assert_line --partial 'Extracting link from sources and placing it in the top right corner. ↗︎'
  assert_line --partial ' … Cleaning up'
}

@test "should have working chafa.rec" {
  cd "$BATS_CWD/rec"

  TERM=xterm run bash "$(recording "chafa.rec")"

  assert_success
  while read -r line; do
    assert_output --partial "$line"
  done < <(
    cat <<'NYAN-CAT'
i>::::::~iiiiii|::::::.______________,
_,zzzzzzT______3zzzzz~jMMMMMMMM0MMMMMMf
00MMM00MM0000000MMM0M'JMMMMMMMM"w_~4MMf._y
MMMMMMMMMMMMMMMMP'_^MlJMMMMMMMM #Mm____mM0
&&~~~~~~'&&&&&&Z'\\\_:JMMM0MMM !M0f~M@*0f~m
my_______mmmmmm_____}:JMWMMMMM !Mm-4#^w}-wM
^^MMMMMMP^^^^^^^M0MMP'JMM0MMMMm,~0_______~
uTyyyyyy3uuuuuw_'gy~we "~~~~~~~~'     :
  .......     `~_..,.   ..       .   .
                 ^ .
NYAN-CAT
  )
}
