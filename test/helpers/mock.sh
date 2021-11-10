#!/usr/bin/env bash

# Prints a `asciinema` function that run the specified actions
# and finally creates a cast with the contents of fixture `test.cast`.
asciinema_mock() {
  local fixture="test.cast" actions
  printf -v actions '%s\n' "$@"
  fixture=$(fixture "$fixture") || exit $?
  echo 'asciinema() {
  printenv > '"$BATS_TEST_TMPDIR"'/asciinema.env
  echo "$@" > '"$BATS_TEST_TMPDIR"'/asciinema.args
  local last_index=$#
  local cast_file=${!last_index}
  '"$actions"'
  cat <<"FIXTURE_CONTENT" >"$cast_file"
'"$(cat "$fixture")"'
FIXTURE_CONTENT
}
  export -f asciinema
'
}

# Prints a `svg-term` function that creates a cast with the contents of the specified fixture (default: `test.svg.0`).
# If there is no such fixture the argument is added to the mock as is.
svg-term_mock() {
  local fixture="test.svg.0" actions
  printf -v actions '%s\n' "$@"
  fixture=$(fixture "$fixture") || exit $?
  echo 'svg-term() {
  printenv > '"$BATS_TEST_TMPDIR"'/svg-term.env
  echo "$@" > '"$BATS_TEST_TMPDIR"'/svg-term.args
  local svg_file
  while (($#)); do
    case $1 in
      --out)
        shift
        svg_file=$1
        ;;
      *)
        shift
    esac
  done
  '"$actions"'
  cat <<"FIXTURE_CONTENT" >"$svg_file"
'"$(cat "$fixture")"'
FIXTURE_CONTENT
}
  export -f svg-term
'
}

# Prints the path of an executable `recordr` that has mocked dependencies `asciinema` and `svg-term`.
# Arguments can be passed to the corresponding mock factories by prefixing each argument to be passed
# with `--[mock name]:`, e.g. `--asciinema:--foo=bar` whereas `--foo=bar` would be passed to `asciinema_mock`.
mocked_recordr() {
  local -a asciinema_args=() svg_term_args=()
  while (($#)); do
    case $1 in
      --asciinema:*)
        asciinema_args+=("${1#--asciinema:}")
        ;;
      --svg-term:*)
        svg_term_args+=("${1#--svg-term:}")
        ;;
      *)
        fail "unknown option $1"
        ;;
    esac
    shift
  done
  make_interpretable '#!/usr/bin/env bash' <(asciinema_mock "${asciinema_args[@]}") <(svg-term_mock "${svg_term_args[@]}") - <<<"$BATS_CWD/recordr"' "$@"'
}
