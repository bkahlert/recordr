#!/usr/bin/env bash

# Prints a `asciinema` function that creates a cast with the contents of the specified fixture.
asciinema_mock() {
  echo 'asciinema() {
  printenv > '"$BATS_TEST_TMPDIR"'/asciinema.env
  echo "$@" > '"$BATS_TEST_TMPDIR"'/asciinema.args
  local last_index=$#
  local cast_file=${!last_index}
  cat <<"CAST_FILE" >"$cast_file"
'"$(cat "$(fixture "${1?path missing}")")"'
CAST_FILE
}
  export -f asciinema
'
}

# Prints a `svg-term` function that creates a cast with the contents of the specified fixture.
svg-term_mock() {
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
  cat <<"SVG_FILE" >"$svg_file"
'"$(cat "$(fixture "${1?path missing}")")"'
SVG_FILE
}
  export -f svg-term
'
}

# Prints the path of an executable `recordr` that has mocked dependencies `asciinema` and `svg-term`.
mocked_recordr() {
  make_interpretable '#!/usr/bin/env bash' <(asciinema_mock test.cast) <(svg-term_mock test.svg.0) - <<<"$BATS_CWD/recordr"' "$@"'
}
