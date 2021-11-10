#!/usr/bin/env bash
#
# Common test setup

set -uo pipefail

declare -r -g EX_USAGE=64       # command line usage error
declare -r -g EX_CANTCREAT=73   # can't create (user) output file

# Prints the specified error message and exits with an optional exit code (default: 1).
# Arguments:
#   -n          - number of stacktrace elements to skip (default: 0)
#   -c | --code - exit code (default: 1)
#   --          - indicates that all following arguments are non-options
#   FORMAT      - `printf` format (default: unknown error)
#   ARG...      - optional `printf` arguments
die() {
  local skip=0 code=$?
  if [ "${1-}" ] && [ "${1#-}" -eq "${1#-}" ] &>/dev/null; then
    skip=${1#-} && shift
  fi
  [ "$code" -ne 0 ] || code=1
  while (($#)); do
    case $1 in
    -c=* | --code=*)
      code=${1#*=} && shift
      ;;
    -c | --code)
      [ "${2-}" ] || die -1 --code "$EX_USAGE" "${FUNCNAME[0]} $1 is missing a value"
      code=$2 && shift 2
      ;;
    --)
      shift && break      ;;
    *)
      break
    esac
  done

  # shellcheck disable=SC2059
  local message && printf -v message -- "${@-unknown error}"
  message=${message%$'\n'}
  message=${message//$'\n'/$'\n'   }

  printf ' %s %s\n     at %s(%s:%s)\n' \
    "$([ ! -t 2 ] || tput setaf 1)✘$([ ! -t 2 ] || tput sgr0)" "${message#   }" \
    "${FUNCNAME[$((1+skip))]:-main}" "${BASH_SOURCE[$skip]:-?}" "${BASH_LINENO[$skip]:-?}" >&2
  exit "$code"
}

#(die) # " ✘ error in line 35"
#(touch &>/dev/null || die) # " ✘ error in line 36"
#(die -c=42) # " ✘ error in line 37"
#(die --code=42) # " ✘ error in line 38"
#(die -c 42) # " ✘ error in line 37"
#(die --code 42) # " ✘ error in line 38"
#(die -c) # " ✘ die -c is missing a value"
#(die --code) # " ✘ die --code is missing a value"
#(die foo) # " ✘ foo"
#(die '%s %s' foo bar) # " ✘ foo bar"
#(die '%s\n%s' foo bar) # " ✘ foo\n   bar"
#(die '%s\n%s\n' foo bar) # " ✘ foo\n   bar"
#(TERM=xterm die 2>&1 | cat -) # no ESC
#(TERM=xterm die > >(socat - pty | cat -)) # ESC

# Exits with a error message if this function is called outside of
# the execution of a test.
require_test() {
  [ "${BATS_TEST_TMPDIR-}" ] || die "running test required"
  [ -e "${BATS_TEST_TMPDIR-}" ] || die "'$BATS_TEST_TMPDIR' does not exist"
  [ -d "${BATS_TEST_TMPDIR-}" ] || die "'$BATS_TEST_TMPDIR' is no directory"
  [ -w "${BATS_TEST_TMPDIR-}" ] || die "'$BATS_TEST_TMPDIR' is no writable directory"
}

# Enables the specified options. Prefix an option with + to disable.
# Prefixing options with `-` is optional.
#set_opt() {
#  local opt set_op shopt_op
#  while(($#)); do
#    opt=$1 set_op=- shopt_op=s && shift
#    [ ! "${opt:0:1}" = "-" ] || opt=${opt:1}
#    [ ! "${opt:0:1}" = "+" ] || opt=${opt:1} set_op=+ shopt_op=u
#    set "${set_op}o" "$opt" 2>/dev/null || shopt "-q${shopt_op}" "$opt" 2>/dev/null || exit 99
#  done
#}


declare -A -g shell_options=()
while read -a arr -r; do
  # shellcheck disable=SC2209
  shell_options["${arr[2]}"]=set
done < <(set +o)
while read -a arr -r; do
  shell_options["${arr[0]}"]=opt
done < <(shopt)

# TODO check $SHELLOPTS and $BASHOPTS instead
# Returns if the specified shell option is enabled.
# Arguments:
#   1 - complete shell option name
shell_option_enabled() {
  case ${shell_options[$1]} in
    set)
      while read -a arr -r; do
        [ "${arr[2]}" = "$1" ] || continue
        [ "${arr[1]}" = "-o" ]
        return
      done < <(set +o)
      ;;
    opt)
      shopt -q "$1"
      ;;
    *)
      fail "Unknown shell option '$1'"
      ;;
  esac
}

# TODO use shopt -so $1 || shopt -sO $1 || fail "'$1' is neither a shell nor a Bash option"
# Enables the specified shell option.
# Arguments:
#   1 - complete shell option name
enable_shell_option() {
  case ${shell_options[$1]} in
    set)
      set -o "$1"
      ;;
    opt)
      shopt -s "$1"
      ;;
    *)
      fail "Unknown shell option '$1'"
      ;;
  esac
}

# Enables the specified shell option.
# Arguments:
#   1 - complete shell option name
disable_shell_option() {
  case ${shell_options[$1]} in
    set)
      set +o "$1"
      ;;
    opt)
      shopt -u "$1"
      ;;
    *)
      fail "Unknown shell option '$1'"
      ;;
  esac
}

# Runs the specified command line with a defined a shell option state.
#   1 - +|- complete option name; - enables and + disables the option
#   * - command line
with_shell_option() {
  local name=${1?shell option name missing} result=0
  shift
  case $name in
    -*)
      if shell_option_enabled "${name:1}"; then
        "$@" || result=$?
      else
        enable_shell_option "${name:1}"
        "$@" || result=$?
        disable_shell_option "${name:1}"
      fi
      ;;
    +*)
      if shell_option_enabled "${name:1}"; then
        disable_shell_option "${name:1}"
        "$@" || result=$?
        enable_shell_option "${name:1}"
      else
        "$@" || result=$?
      fi
      ;;
    *)
      fail "Shell option '$1' must be either prefixed with - or +"
      ;;
  esac
  return "$result"
}

# Provides access to the specified internal Bats function
# by re-declaring with with a `batsw` prefix (instead of `bats`).
#
# Arguments:
#   1 - name of the re-declared function (default: calling function name)
# shellcheck disable=SC2120
batsw_redeclare() {
  local batsw_name=${1:-${FUNCNAME[1]}} declaration
  local bats_name=${batsw_name/#batsw_/bats_}
  local raw_name=${bats_name/#bats_/batsw__}
  declaration=$(
    source /opt/bats/lib/bats-core/test_functions.bash
    declare -f "$bats_name"
  )
  eval "${declaration/#"$bats_name"/"$raw_name"}"
  eval "$batsw_name() { with_shell_option '+no""unset' $raw_name \"\${@}\" || true; }"
}

# Provides access to `bats_separate_lines`.
batsw_separate_lines() {
  [ "${batsw_separate_lines-}" ] || batsw_redeclare
  batsw_separate_lines "$@"
}

# Delegates to echo just as if called directory
# **unless** a Bats test is being executed
# (determined by an open file descriptor 3).
#
# In case of a test, this function prints
# TAP compliant with a preceding `#` and
# Bats compliant to file descriptor 3.
#
# Globals:
#   none
# Arguments:
#   * - echo arguments
# Outputs:
#   FD3 - echo message
trace() {
  if [ $# -eq 0 ] && [ "${output-}" ]; then
    set -- "${output:-}"
  fi
  local argc="$#" _trace_args=""
  printf -v _trace_args " %q" "$@"
  if { true >&3; } 2<>/dev/null; then
    echo '# ' "$argc$_trace_args" >&3
  else
    echo "$argc$_trace_args"
  fi
}

# Downloads a Bats library
#
# Globals:
#   BATS_SUITE_TMPDIR
# Arguments:
#   1 - short name of the library, e.g. assert
# Returns:
#   0 - download successful
#   1 - otherwise
# Outputs:
#   STDOUT - directory containing the downloaded and extracted Bats library
#   STDERR - details, on failure
download_lib() {
  local short_name="${1?}"

  local url="https://github.com/bats-core/bats-${short_name}/tarball/master"
  local target="${BATS_SUITE_TMPDIR:?}/_libs/${short_name}"

  if [ ! -d "$target" ] || [ ! -f "$target/load.bash" ]; then
    rm -rf "${target:?}"
    mkdir -p "$target"
    (
      cd "$target" || exit
      curl -LfsS "$url" \
        | tar --extract --gunzip --strip-components=1
    )
  fi

  if [ ! -d "$target" ] || [ ! -f "$target/load.bash" ]; then
    echo "Failed to download $short_name from $url" >&2
    return 1
  fi
  echo "$target"
  return 0
}

# Loads a Bats library from /opt.
#
# Globals:
#   none
# Arguments:
#   1 - Short name of the library, e.g. assert
load_lib() {
  local short_name=${1:?}

  local file="/opt/bats-${short_name}/load.bash"
  if [ ! -f "$file" ]; then
    trace "No local copy of library ${short_name} found at ${file}. Downloading..."
    local download && download="$(download_lib "${short_name}")"
    if [ -f "${download}/load.bash" ]; then
      file="${download}/load.bash"
    fi
  fi
  if [ ! -f "$file" ]; then
    printf 'bats: %s does not exist\n' "$file" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$file"
  patch_lib "$short_name"
}

# Applies patches to libs.
# Arguments:
#   1 - Short name of the library, e.g. assert
patch_lib() {
  local short_name=${1:?}

  case $short_name in
    assert)
      local bats_assert_line
      bats_assert_line=$(declare -f assert_line) || true
      if [ "${bats_assert_line-}" ]; then
        eval "bats_${bats_assert_line}"
        # bashsupport disable=BP5008
        assert_line() {
          local shell_option=nullglob
          if shopt -q "$shell_option"; then
            printf '%s\n' "❗ Bats' assert_line seems broken if shell option $shell_option is enabled." >&2
            printf '%s\n' "❗ Workaround: enable $shell_option only locally or use assert_output." >&2
            exit 1
          fi
          bats_assert_line "$@"
        }
      fi
      ;;
    file)
      local bats_fn bats_decl
      for bats_fn in $(set | grep -e "^assert_file_*"); do
        [[ $bats_fn == assert_file_* ]] || continue
        bats_decl=$(declare -f "$bats_fn") || true
        if [ "${bats_decl-}" ]; then
          eval "bats_$bats_decl"
          eval "$bats_fn() {
          BATSLIB_FILE_PATH_REM=\${BATSLIB_FILE_PATH_REM:-} \
          BATSLIB_FILE_PATH_ADD=\${BATSLIB_FILE_PATH_ADD:-} \
          bats_$bats_fn \"\$@\"
        }"
        fi
      done
      ;;
  esac
}

# Tests if at least one log line matches the provided arguments.
# Arguments:
#   1 - Docker container ID
#   * - assert_line arguments
assert_container_log() {
  local container=${1:?container missing} && shift
  run docker logs "$container"
  assert_line "$@"
}

# Tests the current status of a Docker container.
# Globals:
#   none
# Arguments:
#   1 - Docker container ID
#   2 - expected value
# Returns:
#   0 - statuses equal
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_container_status() {
  local actual_status && actual_status=$(docker container inspect --format "{{.State.Status}}" "$1")
  local expected_status=$2
  assert_equal "${actual_status}" "${expected_status}"
}

# Tests the owner of a file.
# The original implementation suffers from its reliance on sudo.
# see https://github.com/bats-core/bats-file#assert_file_permission
#
# Accepts either user and group name or user ID and group ID.
#
# Globals:
#   none
# Arguments:
#   1 - file
#   2 - expected user; use - to not check the owning user
#   3 - expected group; use - to not check the owning group
# Returns:
#   0 - file owner equal
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_file_owner_group() {
  local file="$1"
  local user="$2"
  local group="$3"

  local flag='-l'
  [[ ! ${user%-} =~ ^[0-9]*$ ]] || [[ ! ${group%-} =~ ^[0-9]*$ ]] || flag='-n'
  [ ! "${user-}" = - ] || user='.*'
  [ ! "${group-}" = - ] || group='.*'

  run ls "$flag" "$file" # total 10444 -rw-r--r-- 1 tester tester 10692675 Sep 25 17:29 core.gz

  local s='\s+'
  local regexp='.*\d+'                             # hard links
  regexp="${regexp}${s}${user}"                    # file owner
  regexp="${regexp}${s}${group}"                   # file group
  regexp="${regexp}${s}"'\d+'                      # file size
  regexp="${regexp}${s}"'\w+'"${s}"'\d+\s+\d+:\d+' # date and time
  regexp="${regexp}${s}${file}"                    # file name
  assert_output --regexp "${regexp}"
}

# Fail and display path of the file (or directory) if it does contain a string.
# This function is the missing logical complement of `assert_file_contains'.
#
# Globals:
#   BATSLIB_FILE_PATH_REM
#   BATSLIB_FILE_PATH_ADD
# Arguments:
#   $1 - path
#   $2 - regex
# Returns:
#   0 - file not contains regex
#   1 - otherwise
# Outputs:
#   STDERR - details, on failure
assert_file_not_contains() {
  local -r file="$1"
  local -r regex="$2"
  if ! grep -v -q "$regex" "$file"; then
    local -r rem="$BATSLIB_FILE_PATH_REM"
    local -r add="$BATSLIB_FILE_PATH_ADD"
    batslib_print_kv_single 4 'path' "${file/$rem/$add}" \
      | batslib_decorate 'file contains regex' \
      | fail
  fi
}

# Calls the specified command once a seconds for at most the
# specified number of time and returns 0 if the command succeeds within time.
assert_within() {
  local -i time=${1%s} && shift
  [ ! "${1-}" = "--" ] || shift
  local -a cmdline=("$@")

  local -i timeout=$((SECONDS + time))
  while true; do
    run "${cmdline[@]}"
    [ ! "${status-}" -eq 0 ] || {
      assert_success
      return 0
    }
    [ "$SECONDS" -le "$timeout" ] || {
      assert_success
      break
    }
    sleep 1
  done
  echo " $(tput setaf 1)✘$(tput sgr0) '${cmdline[*]}' did not succeed within ${time}s"
  exit 1
}

# Prints the IP of the specified container.
#   1 - Docker container ID
container_ip() {
  docker inspect "${1:?container missing}" | jq --join-output '.[].NetworkSettings.Networks.bridge.IPAddress'
}

# Finds the absolute path for the given fixture.
# The search starts with the current test's fixture directory (e.g. test/foo/fixture)
# and if no fixture is found, continues with the parent directory (e.g. test/fixture)
# until the parent of the test directory (e.g. fixture) is reached.
#
# Arguments:
#   1 - name of the fixture
#   2 - the directory in which to look for (default: $BATS_TEST_DIRNAME)
# Outputs:
#   STDOUT - absolute path of the given fixture
#   STDERR - details on failure
fixture() {
  local dir="${2:-${BATS_TEST_DIRNAME:?}}"
  if [ ! "${dir#${BATS_CWD:?}}" ]; then
    echo "Cannot find fixture $1" >&2
    exit 1
  fi

  if [ -e "$dir/fixtures/$1" ]; then
    echo "$dir/fixtures/$1"
    return 0
  fi

  fixture "$1" "${dir%/*}"
}

# Copies the source of the specified fixture to the specified target.
# Arguments:
#   1 - name of the fixture
#   2 - target
# Outputs:
#   STDERR - details on failure
# See also:
#   cp(1) `fixture`
copy_fixture() {
  [ $# -ge 2 ] || fail "${FUNCNAME[0]} needs at least two arguments: fixture and target"
  local -a args=()
  while (($#)); do
    if [ $# -eq 2 ]; then
      args+=("$(fixture "${1:?}")")
    else
      args+=("${1:?}")
    fi
    shift
  done
  cp "${args[@]}"
}

# Creates a file with `executable` permissions in this test's temporary
# directory containing the contents of the specified files
# (`-` means standard input), or standard input if none are given,
# and prints it path.
# Arguments:
#   [FILE...] - files of which the contents to add to the temporary executable
# Output:
#   STDOUT - path of the created executable
make_executable() {
  require_test
  local executable
  executable="$(mktemp "$BATS_TEST_TMPDIR/executable_XXXXXX")" || die --code "$EX_CANTCREAT" "failed to create temporary file"
  touch "$executable" || die "failed to touch $executable"
  chmod +x "$executable" || die "failed to change permissions of $executable"
  cat "$@" >"$executable" || die "failed to copy $*"
  echo "$executable"
}

# Creates a file with `executable` permissions in this test's temporary
# directory containing a shebang (`#!`) with the specified interpreter,
# the contents of the remaining files arguments
# (`-` means standard input), or standard input if none are given,
# and prints it path.
# Arguments:
#   1         - interpreter (e.g. `/usr/bin/env bash`)
#   [FILE...] - files of which the contents to add to the temporary interpretable
# Output:
#   STDOUT - path of the created executable
make_interpretable() {
  make_executable <(echo "$1") "${@:2}"
}

# Expect-based counterpart to Bats' run function.
# The piped script must not include a shebang as it will be added automatically.
# Globals:
#   Same as run, i.e. `output`, `lines` and `status`
# Arguments:
#   * - run arguments
# Inputs:
#   STDIN - content of the expect script
expect() { # [!|=N] [--keep-empty-lines] [--output merged|separate|stderr|stdout] [--] <command to run...>
  run "$@" "$(make_interpretable '#!/usr/bin/expect' -)"
}

run_tty() {
  local script command
  printf -v command " %s" "$@"
  opts='-no''echo'
  script=$(
    mkfile +x '#!/usr/bin/expect' - <<EXPECT
set timeout -1
spawn $opts$command
expect "$ "
EXPECT
  )
  run "$script"
}


# Tests if this test run was invoked via BashSupport Pro.
# Globals:
#   BASH_SOURCE
#   BATS_SHELL
# Returns:
#   0 - successful
#   1 - not successful
test_bashsupport_pro() {
  local i
  for i in "${!BASH_SOURCE[@]}"; do
    [[ ${BASH_SOURCE[i]} =~ IntelliJ|intellij && ${BASH_SOURCE[i]} =~ "bashsupport-pro" ]] || continue
    return 0
  done
  return 1
}

# Tests if the currently running Bats has the required minimal version.
# Returns:
#   0 - successful
#   1 - not successful
test_min_bats_version() {
  local version
  version=$(bats --version) 2>/dev/null
  version=${version#Bats }
  (
    IFS='.' read -r -a parts <<<"$version"
    [ "${parts[0]-0}" -lt 2 ] || return 0 # if >= 2.x.x 👍
    [ "${parts[0]-0}" -eq 1 ] || return 1 # if <= 0.x.x 👎
    [ "${parts[1]-0}" -ge 4 ] || return 1 # if >= 1.4.x 👍
    # else < 1.4.x 👎
  )
}

# Sanity checks
main() {

  local version
  ! version=$(test_min_bats_version) || return 0

  if test_bashsupport_pro; then
    # shellcheck disable=SC2016
    printf '%s' '
❗ You are running these tests with a version of BashSupport Pro that uses an outdated Bats.

You can workaround this problem by using the Bats wrapper `batsw` instead:
1. Open the outdated bats binary in a text editor.
   It should be printed at the very top of the test output.
2. Paste the following lines right after the first line.

current_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
formatter="${current_dir%/bats-core/*}/bats-core/libexec/bats-core/bats-format-bashpro"
if [ ! -f "$formatter" ]; then echo "Could not find BashSupport Pro formatter at $formatter" >&2; exit 1; fi

project_dir=$PWD
while true; do
  if [ ! "${project_dir}" ]; then echo "Could not find BashSupport Pro formatter at $formatter" >&2; exit 1; fi
  if [ ! -f "${project_dir}/batsw" ]; then project_dir="${project_dir%/*}"; continue; fi
  break
done
[ -x "${project_dir}/batsw" ] || chmod +x "${project_dir}/batsw"
cd "${project_dir}" && ./batsw --quiet --inject "libexec/bats-core/bats-format-junit=$(cat "$formatter")" "${@//bashpro/junit}"
exit

3. Run the tests again
' >&2
  else
    # shellcheck disable=SC2016
    printf '%s' '
❗ You are running these tests with an outdated version of Bats ('"$version"').

Please update or use the Bats wrapper `batsw`.
' >&2
  fi

  exit

}

main "$@"
