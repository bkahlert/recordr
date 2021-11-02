#!/usr/bin/env bash
export RECORDING=1
printf '[8;25;132t'
# Restarts in the specified number of seconds
count_down() {
  local seconds=${1:-5}
  tput civis
  [ "$seconds" -gt 0 ] || return 0
  for ((i = 0; i < "$seconds"; i++)); do
    printf '%s%s' $((seconds - i)) "$(tput hpa 0)"
    sleep .5; tput 'c''norm'; sleep .5; tput civis
  done
}

declare _status=0
# Simulates a user typing in the specified command and executes it.
rec() {
  local prompt="❱ "
  printf '%s%s' "$(tput 'set''af' 7)$prompt" "$(tput 'c''norm')"
  sleep 1
  local i j s min=10
  printf -v s '%q ' "$@"
  s=${s:0:$((${#s} -1))}
  [ ! "${TESTING-}" ] || min=99999
  # rec -n suppresses output of the first n arguments
  [[ ! "${1-}" =~ -[0-9]+ ]] || {
    s=${*:$((${1#-} +2))}
    shift
  }
  for ((i = 0, j = 0; i < ${#s}; i = i + j, j = "$min" + (RANDOM % 5))); do
    printf '%s' "${s:i:j}" && sleep .04
  done
  sleep .5; tput civis
  sleep .5; tput 'c''norm'
  printf "%s%s%s\n" "$(tput 'set''af' 8)$(tput hpa 0)$prompt" "$s" "$(tput sgr0)"
  tput civis
  local _status=0 tmp
  tmp=$(mktemp)

  "$@" > >(tee "$tmp")
  _status=$?

  # add eventually missing new line
  [ "$(du -k "$tmp" | cut -f1)" = 0 ] || [ "$(tail -c 1 "$tmp" | tr -Cd "\n" | tr "\n" 'n')" ] || {
    printf "%s%s%s\n" "$(tput 'sm''so')" "␊" "$(tput sgr0)"
  }
  rm -- "$tmp"

  # highlight non-0 exit code
  [ "$_status" -eq 0 ] || {
    col=$((132 -"${#_status}" -3))
    esc_hpa_col=$(tput hpa "$col" || tput ch "$col")
    printf "%s%s%s %s %s\n" "$(tput cuu 1)${esc_hpa_col-}" "$(tput bold)$(tput "set""af" 1)" ↩ "$_status" "$(tput sgr0)"
  }
  echo

}
trap 'count_down 5' EXIT
# END OF INSTRUMENTATION
(
#!/usr/bin/env recordr

set -uo pipefail

# bashsupport disable=BP5008
bar() {
  # shellcheck disable=SC2059
  [ $# -eq 0 ] || printf "$@"
  return 42
}

# bashsupport disable=BP5008
baz() {
  # shellcheck disable=SC2059
  [ $# -eq 0 ] || printf "$@"
  exit 120
}

rec printf '%s\n' 'foo'
rec printf '%s' 'foo'
rec bar $'\n'
rec bar ''
rec -1 baz
) || _status=$?

  # highlight non-0 exit code
  [ "$_status" -eq 0 ] || {
    col=$((132 -"${#_status}" -3))
    esc_hpa_col=$(tput hpa "$col" || tput ch "$col")
    printf "%s%s%s %s %s\n" "$(tput cuu 1)${esc_hpa_col-}" "$(tput bold)$(tput "set""af" 1)" ↩ "$_status" "$(tput sgr0)"
  }
  echo
