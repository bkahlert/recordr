#!/usr/bin/env bash

# Prints a `asciinema` function that creates a cast with the contents of the specified fixture.
asciinema_mock() {
  echo 'asciinema() {
  printenv > '"$BATS_TEST_TMPDIR"'/asciinema.env
  echo "$@" > '"$BATS_TEST_TMPDIR"'/asciinema.args
  local cast_file=${!#}
  cat <<CAST_FILE >$cast_file
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
  cat <<SVG_FILE >$svg_file
'"$(cat "$(fixture "${1?path missing}")")"'
SVG_FILE
}
  export -f svg-term
'
}

# Creates shell script that runs the specified rec file.
# Additional arguments will be written to the shell script, that is,
# they must be valid shell script code in order to not break the script.
recording() {
  local -a parts=()
  parts+=('#!/usr/bin/env bash')
  parts+=('
rec() {
  [[ ! "${1-}" =~ -[0-9]+ ]] || shift
  ("$@" 2>&1) || true
}
')
  for part in "${@:2}"; do
    parts+=("$part")
  done
  parts+=("$(cat "$BATS_CWD/rec/${1?rec file missing}")")
  mkfile "${parts[@]}"
}

# Invokes `recordr` with the specified arguments but mocked dependencies `asciinema` and `svg-term`.
mocked_recordr() {
  local -a parts=(
    "#!/usr/bin/env bash"
    "$(asciinema_mock test.cast)"
    "$(svg-term_mock test.svg.0)"
    "$BATS_CWD/recordr \"\$@\""
  )
  "$(mkfile +x "${parts[@]}")" "$@"
}
