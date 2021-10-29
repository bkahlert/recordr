#!/usr/bin/env bash
export RECORDING=1
printf '[8;25;132t'
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
  local result=0 col esc_hpa_col tmp
  tmp=$(mktemp)

  {
    "$@" || result=$? || true
  } | tee "$tmp"

  # add eventually missing new line
  [ "$(tail -c 1 "$tmp" | tr -Cd "\n" | tr "\n" 'n')" ] || {
    printf "%s%s%s\n" "$(tput 'sm''so')" "␊" "$(tput sgr0)"
  }
  rm -- "$tmp"

  # highlight non-0 exit code
  [ "$result" -eq 0 ] || {
    col=$((132 -"${#result}" -3))
    esc_hpa_col=$(tput hpa "$col" || tput ch "$col")
    printf "%s%s%s ↩ %s\n" "$(tput cuu 1)${esc_hpa_col-}" "$(tput bold)$(tput 'set''af' 1)" "$result" "$(tput sgr0)"
  }
  echo
}
# END OF INSTRUMENTATION
#!/usr/bin/env bash

set -euo pipefail

# bashsupport disable=BP5008
baz() {
  # shellcheck disable=SC2059
  [ $# -eq 0 ] || printf "$@"
  exit 42
}

rec printf '%s\n' 'foo'
rec printf '%s' 'bar'
rec baz $'\n'
rec baz ''
rec baz

# RESTART IN 5 SECONDS(S)
tput civis
printf '5%s' "$(tput hpa 0)"
sleep .5; tput cnorm; sleep .5; tput civis;
printf '4%s' "$(tput hpa 0)"
sleep .5; tput cnorm; sleep .5; tput civis;
printf '3%s' "$(tput hpa 0)"
sleep .5; tput cnorm; sleep .5; tput civis;
printf '2%s' "$(tput hpa 0)"
sleep .5; tput cnorm; sleep .5; tput civis;
printf '1%s' "$(tput hpa 0)"
sleep .5; tput cnorm; sleep .5; tput civis;
