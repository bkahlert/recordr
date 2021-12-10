#!/usr/bin/env bash
#
# Logr — logger written for the Bourne Again SHell — Bash, with a certain focus on aesthetics
# https://github.com/bkahlert/logr
#
# MIT License
#
# Copyright (c) 2021 Dr. Björn Kahlert
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

(return 2>/dev/null) || set -- "$@" "-!-"

# bashsupport disable=BP2001
# Prints the escape sequences of the requested capabilities to STDERR.
# Arguments:
#   init - initializes ANSI output if
#          - terminal is connected on STDERR,
#          - TERM is not dumb,
#          - NO_COLOR has no value, and
#          - [APP]_NO_COLOR (e.g. `FOO_NO_COLOR`) has no value
#   v - same behavior as `printf -v`
#   * - capabilities
esc() {
  local _esc_var _esc_val='' usage="[--init] [-v VAR] [CAPABILITIES...]"
  while (($#)); do
    case $1 in
      --init)
        shift
        local no_color=${NO_COLOR-} app=${0##*/} && app_no_color="${app^^}_NO_COLOR"
        [ ! -v "$app_no_color" ] || [ "${!app_no_color:-false}" = false ] || no_color=1
        # shellcheck disable=SC2015,SC2034
        [ ! -t 2 ] || [ "${TERM-}" = dumb ] || [ "${no_color-}" ] || {
          tty_connected=true                               # if set, signifies a connected terminal
          esc_alt=$(tput smcup || tput ti)                 # start alt display
          esc_alt_end=$(tput rmcup || tput te)             # end alt display
          esc_scroll_up=$(tput indn 1 || tput SF 1)        # entire display is moved up, new line(s) at bottom
          esc_hpa0=$(tput hpa 0 || tput ch 0)              # set horizontal abs pos 0
          esc_hpa1=$(tput hpa 1 || tput ch 1)              # set horizontal abs pos 1
          esc_hpa_margin=$(tput hpa ${#MARGIN})            # set horizontal abs end of margin
          esc_cuu1=$(tput cuu 1 || tput cuu1 || tput up)   # move up one line; stop at edge of screen
          esc_cud1=$(tput cud 1 || tput cud1 || tput 'do') # move down one line; stop at edge of screen
          esc_cuf1=$(tput cuf 1 || tput cuf1 || tput nd)   # move right one pos; stop at edge of screen
          esc_cub1=$(tput cub 1 || tput cub1 || tput le)   # move left one pos; stop at edge of screen
          esc_cursor_hide=$(tput civis || tput vi)         # hide cursor
          esc_cursor_show=$(tput cnorm || tput ve)         # show cursor
          esc_save=$(tput sc)                              # save cursor
          esc_load=$(tput rc)                              # load cursor
          esc_dim=$(tput dim || tput mh)                   # start dim
          esc_bold=$(tput bold || tput md)                 # start bold
          esc_stout=$(tput smso || tput so)                # start stand-out
          esc_stout_end=$(tput rmso || tput se)            # end stand-out
          esc_underline=$(tput smul || tput us)            # start underline
          esc_underline_end=$(tput rmul || tput ue)        # end underline
          esc_reset=$(tput sgr0 || tput me)                # reset cursor
          esc_blink=$(tput blink || tput mb)               # start blinking
          esc_italic=$(tput sitm || tput ZH)               # start italic
          esc_italic_end=$(tput ritm || tput ZR)           # end italic
          esc_colors=$(tput colors || tput Co)             # number of colors

          local -A colors=(['black']=0 ['red']=1 ['green']=2 ['yellow']=3 ['blue']=4 ['magenta']=5 ['cyan']=6 ['white']=7)
          local index name bright_name bg_name bg_bright_name
          # shellcheck disable=SC2059
          for color in "${!colors[@]}"; do
            [ "$color" = black ] || [ "$color" = white ] || [[ $TERM != *-m ]] || continue
            index=${colors["$color"]}
            name=esc_$color bright_name=esc_bright_$color bg_name=esc_bg_$color bg_bright_name=esc_bg_bright_$color
            printf -v "$name" "$(tput setaf "$index" || tput AF "$index")"
            printf -v "$bg_name" "$(tput setab "$index" || tput AB "$index")"
            if [ "$esc_colors" -gt 8 ]; then
              printf -v "$bright_name" "$(tput setaf "$((index + 8))" || tput AF "$((index + 8))")"
              printf -v "$bg_bright_name" "$(tput setab "$((index + 8))" || tput AB "$((index + 8))")"
            else
              printf -v "$bright_name" "$esc_bold${!name}"
              printf -v "$bg_bright_name" "$esc_bold${!bg_name}"
            fi
          done

          esc_default=$(tput op)
          esc_eed=$(tput ed || tput cd)  # erase to end of display
          esc_eel=$(tput el || tput ce)  # erase to end of line
          esc_ebl=$(tput el1 || tput cb) # erase to beginning of line
          esc_ewl=${esc_eel-}${esc_ebl-} # erase whole line
        } 3>&2 2>/dev/null || true
        ;;
      -v)
        [ "${2-}" ] || logr error "value of var missing" --usage "$usage" --stacktrace -- "$@"
        _esc_var=$2 && shift 2
        ;;
      *)
        local _esc_cap="esc_$1" && shift
        [ ! -v "$_esc_cap" ] || _esc_val+=${!_esc_cap}
        ;;
    esac
  done

  if [ "${_esc_var-}" ]; then
    printf -v "$_esc_var" '%s' "$_esc_val"
  else
    printf '%s' "$_esc_val" >&2
  fi
}

# Invokes a utility function.
# Arguments:
#   v - same behavior as `printf -v`
#   * - args passed to the utility function.
util() {
  local args=() _util_var usage="[-v VAR] UTIL [ARGS...]"
  while (($#)); do
    case $1 in
      -v)
        [ "${2-}" ] || logr error "value of var missing" --usage "$usage" --stacktrace -- "$@"
        _util_var=$2 && shift 2
        ;;
      *)
        args+=("$1") && shift
        ;;
    esac
  done
  set -- "${args[@]}"
  [ $# = 0 ] && logr error "command missing" --usage "$usage" --stacktrace -- "$@"

  # utilities
  local util_text
  # bashsupport disable=BP2001
  case $1 in
    remove_ansi)
      args=() cleansed=() usage="${usage%UTIL*}$1 FORMAT [ARGS...]"
      shift
      [ $# -gt 0 ] || logr error "format missing" --usage "$usage" --stacktrace -- "$@"
      for text in "${@}"; do
        cleansed+=("$(echo "$text" | sed "$ESC_PATTERN")")
      done
      # shellcheck disable=SC2059
      printf -v util_text "${cleansed[@]}"
      util_text=$(echo "$util_text" | sed -e "$ESC_PATTERN")
      ;;

    center)
      args=() usage="${usage%UTIL*}$1 [-w|--width WIDTH] TEXT"
      shift
      local util_center_width
      while (($#)); do
        case $1 in
          -w | --width)
            [ "${2-}" ] || logr error "value of width missing" --usage "$usage" --stacktrace -- "$@"
            util_center_width=$2 && shift 2
            ;;
          *)
            args+=("$1") && shift
            ;;
        esac
      done

      set -- "${args[@]}"
      [ $# -eq 1 ] || logr error "text missing" --usage "$usage" --stacktrace -- "$@"

      local -i available_width=${#MARGIN} text_width="${util_center_width:-${#1}}"
      local -i lpad=$(((available_width - text_width) / 2))
      [ "$lpad" -gt 0 ] || lpad=0
      local -i rpad=$((available_width - text_width - lpad))
      [ "$rpad" -gt 0 ] || rpad=0

      printf -v util_text "%*s%s%*s" "$lpad" '' "$1" "$rpad" ''
      ;;

    icon)
      args=() usage="${usage%UTIL*}$1 [-c|--center] ICON"
      shift
      local _icon_center
      while (($#)); do
        case $1 in
          -c | --center)
            _icon_center=true && shift
            ;;
          *)
            args+=("$1") && shift
            ;;
        esac
      done
      set -- "${args[@]}"
      [ $# -eq 1 ] || logr error "icon missing" --usage "$usage" --stacktrace -- "$@"
      local _icon_name=${1,,}
      _icon_name=${ICON_ALIASES[$_icon_name]-$_icon_name}
      local _icon=${ICONS[$_icon_name]-'?'}
      [ ! ${_icon_center-} ] || util -v _icon center --width 1 "$_icon"
      util_text=$_icon
      ;;

    inline)
      usage="${usage%UTIL*}$1 FORMAT [ARGS...]"
      shift

      [ $# -ge 1 ] || logr error "format missing" --usage "$usage" --stacktrace -- "$@"

      # shellcheck disable=SC2059
      local text && printf -v text "${@}"
      text=${text#$LF}
      text=${text%$LF}
      text=${text//$LF*$LF/; ...; }
      text=${text//$LF/; }

      util_text="$text"
      ;;

    # fits the given pattern in the current row by truncating the middle with ... if necessary
    fit)
      shift
      local truncation=' ... ' slack=5
      # shellcheck disable=SC2059
      local _fit_text && printf -v _fit_text "$@"
      local _fit_columns=$((${COLUMNS:-80} - ${#MARGIN} - "$slack"))
      [ "$_fit_columns" -gt 20 ] || _fit_columns=20
      if [ "$_fit_columns" -lt "${#_fit_text}" ]; then
        local _fit_half=$(((_fit_columns - ${#truncation} - 1) / 2))
        local _fit_left=${_fit_text:0:_fit_half} _fit_right=${_fit_text:$((${#_fit_text} - _fit_half)):_fit_half}
        printf -v util_text "%s%s%s" "${_fit_left%% }" "$truncation" "${_fit_right## }"
      else
        util_text=$_fit_text
      fi
      ;;

    # concatenates the specified texts with the specified icon
    fit_concat)
      usage="${usage%UTIL*}$1 ICON TEXT1 TEXT2"
      shift
      [ $# -eq 3 ] || logr error --usage "$usage" --stacktrace -- "$@"

      local _fit_concat_icon
      util -v _fit_concat_icon icon --center "$1"
      shift

      local _fit_concat_text
      if [ "$1" ] && [ "$2" ]; then
        _fit_concat_text="$1$_fit_concat_icon$2"
      else
        _fit_concat_text="$1$2"
      fi

      _fit_concat_text=${_fit_concat_text//$_fit_concat_icon/$''}
      util fit -v _fit_concat_text "$_fit_concat_text"
      _fit_concat_text=${_fit_concat_text//$''/$_fit_concat_icon}

      util_text=$_fit_concat_text
      ;;

    # prints the optional icon and text
    print | reprint)
      args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] [FORMAT [ARGS...]]"
      if [ "$1" = reprint ]; then
        shift
        if [ "${1-}" = --skip-icon ]; then
          shift
          esc cuu1 hpa_margin eel
        else
          esc cuu1 ewl
        fi
      else
        shift
      fi
      local print_icon=${esc_hpa_margin-$MARGIN} icon_last=false
      while (($#)); do
        case $1 in
          -i | --icon)
            [ "${2-}" ] || usage
            icon_last=true
            util -v print_icon icon --center "$2"
            shift 2
            ;;
          *)
            icon_last=false
            args+=("$1")
            shift
            ;;
        esac
      done
      set -- "${args[@]}"

      # shellcheck disable=SC2059
      local text='' && [ $# -eq 0 ] || printf -v text "$@"
      text=${text//$LF/$LF$MARGIN}
      [ ! "${icon_last:-false}" = false ] || util_text=$print_icon$text
      [ "${icon_last:-false}" = false ] || util_text=$text$print_icon
      ;;

    prefix)
      args=() usage="${usage%UTIL*}$1 [--config CONFIG] [FORMAT [ARGS...]]"
      local prefix_colors=(black cyan blue green yellow magenta red) config
      shift
      while (($#)); do
        case $1 in
          --config)
            [ "${2-}" ] || logr error "value for config missing" --usage "$usage" --stacktrace -- "$@"
            config=$2 && shift 2
            ;;
          *)
            args+=("$1") && shift
            ;;
        esac
      done
      set -- "${args[@]}"

      local prefix='' name color bg_color props char state
      while IFS=' ' read -r -d: -a props || props=''; do
        [ "${#prefix_colors[@]}" -gt 0 ] || break
        name=${prefix_colors[0]} char=$BANR_CHAR state=1 && prefix_colors=("${prefix_colors[@]:1}")
        for prop in "${props[@]}"; do
          [ "${prop-}" ] || continue
          case $prop in
            c=* | char=*)
              char=${prop#*=}
              continue
              ;;
            s=* | state=*)
              state=${prop#*=}
              continue
              ;;
          esac
          logr error "unknown prop '$prop'; expected colon (:) separated list of space ( ) separated key=value pairs"
        done

        [ "${char-}" ] || continue

        color="esc_bright_$name"
        bg_color=''
        if [ "${state-}" ]; then
          [ ! "${state:0:1}" = 0 ] || color="esc_$name"
          [ ! "${state:1:1}" = 0 ] || bg_color="esc_bg_$name"
          [ ! "${state:1:1}" = 1 ] || bg_color="esc_bg_bright_$name"
        fi

        [ ! -v "${color-}" ] || prefix+=${!color}
        [ ! -v "${bg_color-}" ] || prefix+=${!bg_color}
        prefix+=$char${esc_reset-}
        prefix+=${esc_reset-}
      done <<<"${config-} :"

      # shellcheck disable=SC2034,SC2059
      local parts=("$prefix") && [ $# -eq 0 ] || printf -v parts[1] "$@"
      printf -v util_text %s "${parts[*]}"
      ;;

    # colored banner words
    words)
      shift
      local prefix_colors=("${esc_cyan-}" "${esc_dim-}${esc_cyan-}" "${esc_magenta-}")
      case ${1-} in
        --bright)
          prefix_colors=("${esc_bright_cyan-}" "${esc_cyan-}" "${esc_bright_magenta-}") && shift
          ;;
        --dimmed)
          prefix_colors=("${esc_cyan-}" "${esc_dim-}${esc_cyan-}" "${esc_magenta-}") && shift
          ;;
      esac
      # shellcheck disable=SC2059
      local _words_text && [ $# -eq 0 ] || printf -v _words_text "$@"
      # shellcheck disable=SC2015
      local -a _words=() && [ ! "${_words_text-}" ] || IFS=' ' read -r -a _words <<<"$_words_text"
      local -a _colored=()
      local i
      for i in "${!_words[@]}"; do
        # color all but first words bright magenta
        if [ "$i" -gt 0 ]; then
          _colored+=("${prefix_colors[2]}${_words[$i]^^}${esc_reset-}")
          continue
        fi

        # split first word camelCase; first word -> bright cyan; rest -> cyan
        # shellcheck disable=SC2001
        local -a _words0 && read -r -a _words0 <<<"$(echo "${_words[$i]}" | sed -E -e 's,([A-Z]), \1,g' -e 's,([a-z])([0-9]+),\1 \2,g')"
        if [ ${#_words0[@]} -gt 0 ]; then
          _colored+=("${prefix_colors[0]}${_words0[0]^^}${esc_reset-}")
          if [ ${#_words0[@]} -gt 1 ]; then
            local _word=${_words0[*]:1}
            _word=${_word// /}
            _colored+=("${prefix_colors[1]}${_word^^}${esc_reset-}")
          fi
        fi
      done
      printf -v util_text %s "${_colored[*]}"
      ;;

    *)
      logr error "unknown command" --usage "$usage" --stacktrace -- "$@"
      ;;
  esac

  if [ "${_util_var-}" ]; then
    printf -v "$_util_var" '%s' "$util_text"
  else
    printf '%s\n' "$util_text"
  fi
}

# Invokes a spinner function.
# Arguments:
#   * - args passed to the spinner function.
spinner() {
  [ "${tty_connected-}" ] || return "$EX_OK"
  local usage="start | stop"
  [ $# -gt 0 ] || logr error "command missing" --usage "$usage" --stacktrace -- "$@"
  case $1 in
    start)
      shift
      [ $# = 0 ] || logr error "unexpected argument" --usage "$usage" --stacktrace -- "$@"
      spinner stop
      spinner _spin &
      ;;
    stop)
      shift
      [ $# = 0 ] || logr error "unexpected argument" --usage "$usage" --stacktrace -- "$@"
      if jobs -pr 'spinner _spin' >/dev/null 2>/dev/null; then
        jobs -pr 'spinner _spin' | xargs -r kill
      fi
      ;;
    _spin)
      shift
      [ $# = 0 ] || logr error "unexpected argument" --usage "$usage" --stacktrace -- "$@"
      local -a frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
      local _i
      for _i in "${!frames[@]}"; do
        util -v "frames[$_i]" center "${frames[$_i]}"
      done
      while true; do
        for _i in "${!frames[@]}"; do
          printf '%s' "${esc_save-}" "${esc_hpa0-}" "${esc_cuu1-}" "${esc_bright_yellow-}" "${frames[$_i]}" "${esc_reset-}" "${esc_load-}" >&2
          sleep 0.10
        done
      done
      ;;
    *)
      logr error "unknown command" --usage "$usage" --stacktrace -- "$@"
      ;;
  esac
}

# Prints a colorful banner.
# Globals:
#   BANR_CHAR - the default char to use
# Arguments:
#   --indent - Either the number of whitespaces or the string itself to prepend the banner with (default: 1)
#   --static - If specified, not animation will take place; optionally can be set to a pattern that controls the design.
#              Format: colon (:) separated list of space separated key-value pairs, e.g. `char=A : char=B state=1` specifies
#                      the first banner char as an `A`, the second as a `B` with bright colors and the remaining chars as default.
#   --bright - Whether bright colors should be applied (default: set)
#   --dimmed - Whether dimmed colors should be applied.
#   --opacity - The opacity of the banner. Valid values are `high`, `medium`, or `low`.
#   --skip-intro - If specified, the animation will not play the intro.
#   --skip-outro - If specified, the animation will not play the outro.
#   + - Positional arguments are interpreted as the actual text.
banr() {
  local -a args=()
  local indent=3 config type=bright
  local intro=true intro_char=$'\u00A0' intro_modifier='' intro_state='10'
  local outro=true outro_char=$BANR_CHAR outro_modifier='' outro_state='1'
  while (($#)); do
    case $1 in
      --indent=*)
        indent=${1#*=} && shift
        ;;
      --static=*)
        config=${1#*=} && shift
        ;;
      --static)
        config=" " && shift
        ;;
      --bright)
        type=bright && shift
        intro_state="1${intro_state:1:1}"
        outro_state="1${outro_state:1:1}"
        ;;
      --dimmed)
        type=dimmed && shift
        intro_state="0${intro_state:1:1}"
        outro_state="0${outro_state:1:1}"
        ;;
      --opacity=high)
        outro_char=█ && intro_modifier=${esc_default-}${esc_dim-} && shift
        ;;
      --opacity=medium)
        outro_char=▒ && intro_modifier=${esc_default-}${esc_dim-} && shift
        ;;
      --opacity=low | --opacity=*)
        outro_char=░ && intro_modifier=${esc_default-}${esc_dim-} && shift
        ;;
      --skip-intro)
        intro=false
        shift
        ;;
      --skip-outro)
        outro=false
        shift
        ;;
      --)
        shift
        args+=("$@")
        break
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  set -- "${args[@]}"
  printf '\n'

  [ "$indent" -eq "$indent" ] 2>/dev/null && printf -v indent '%*.s' "$indent" ''

  local raw_prefix && tty_connected='' util -v raw_prefix prefix && raw_prefix=${raw_prefix//[^$BANR_CHAR]/}

  # shellcheck disable=SC2015
  local text && [ "$#" -eq 0 ] || util -v text words ${type+"--${type-}"} '%s' ${@+"${*}"}
  if [ "${config:=}" ] || [ ! "${tty_connected-}" ]; then
    [ "${config// /}" ] || [ ! "${outro_char-}" ] || config="${raw_prefix//?/"c=$outro_char s=$outro_state:" }"
    local _banner && util -v _banner prefix ${config+--config "$config"} ${text+"$text"}
    printf '%s%s\n\n' "$indent" "$_banner"
    return
  fi

  # shellcheck disable=SC2206
  local intro_frames=(${raw_prefix//?/"$intro_char" }) outro_frames=(${raw_prefix//?/"$outro_char" })

  [ "${intro:-false}" = false ] || intro_frames+=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ █ █ █ ▉ ▊ ▋ ▌ ▍ ▎ ▏ "${intro_char[@]}")
  [ "${outro:-false}" = false ] || outro_frames=(▏ ▎ ▍ ▌ ▋ ▊ ▉ "${outro_frames[@]}")

  intro_frames=("${intro_frames[@]/#/c=$intro_modifier}")
  outro_frames=("${outro_frames[@]/#/c=$outro_modifier}")

  local i frames=("${intro_frames[@]/%/ s=$intro_state}" "${outro_frames[@]/%/ s=$outro_state}")
  for ((i = 0; i < ${#frames[@]}; i++)); do
    local props=("${frames[@]:i:${#raw_prefix}}")
    [ "${#props[@]}" -eq 7 ] || break
    local _banr_words=''
    [ ! "$i" = 0 ] || util -v _banr_words words ${type+"--${type-}"} ' %s' "$@"
    printf '%s' "$indent"
    util prefix --config "${props[*]/%/ :}" "$_banr_words"
    esc cuu1
    sleep 0.0125
  done
  sleep 1.2
  printf '\n\n'
}

# Banner configuration suited for titles and headlines.
# Arguments: see `banr`
# bashsupport disable=BP5005
HEADR() {
  banr --bright --opacity=high "$@"
}

# Banner configuration suited for headlines and sub headlines.
# Arguments: see `banr`
headr() {
  banr --bright --skip-intro "$@"
}

# Logs according to the given type.
# Arguments:
#   1 - command
#   * - command arguments
# Returns:
#   0 - success
#   1 - error
#   * - signal
logr() {
  local inv=("$@") args=() code=${LOGR_ALIAS_CODE:-$?} usage="[-i | --inline] COMMAND [ARGS...]" inline
  while (($#)); do
    case $1 in
      -i | --inline)
        inline=true && shift
        ;;
      --)
        args+=("$@") && break
        ;;
      *)
        args+=("$1") && shift
        ;;
    esac
  done
  set -- "${args[@]}"
  case ${1:-'_help'} in
    _help)
      printf '\n   %s\n\n   Usage: logr %s%s' "$(banr --static "logr" "$LOGR_VERSION")" "$usage" '

   Commands:
     created     Log a created item
     added       Log an added item
     item        Log an item
     list        Log a list of items
     link        Log a link
     file        Log a file link

     success     Log a success message
     info        Log an information
     warning     Log a warning
     error       Log an error
     failure     Log an error and terminate

'
      exit "$EX_OK"
      ;;
    _init)
      shift
      [ -e "$TMPDIR" ] || mkdir -p "$TMPDIR" || die "'$TMPDIR' could not be created"

      # Registers signal_handler to run when the shell receives one of the specified signals.
      handle() {
        [ ! "${_Dbg_DEBUGGER_LEVEL-}" ] || return 0
        local args=('$?' '"${BASH_COMMAND:-?}"' '"${FUNCNAME[0]:-main}(${BASH_SOURCE[0]:-?}:${LINENO:-?})"')
        for signal in "$@"; do
          trap 'signal_handler '"$signal ${args[*]}" "$signal" || die "Failed to set trap for $signal"
        done
      }
      # Unified signal handler run when shell receives signals earlier registered using handle.
      signal_handler() {
        local signal="$1" status="$2" command="$3" location="$4"
        logr cleanup
        case $signal in
          EXIT)
            return 0
            ;;
          ERR)
            [ "${status:-1}" -ne 0 ] || return 0
            status="${esc_red-}${status:-?} ${ICONS['exit']}${esc_reset-}"
            logr fatal --name "${0##*/}" "%s %s\n     %s %s" "$status" "$command" 'at' "$location"
            ;;
        esac

        trap - EXIT HUP INT QUIT PIPE TERM
        kill -TERM $$
      }
      handle HUP INT QUIT PIPE TERM
      [ "${TESTING-}" ] || handle ERR
      esc cursor_hide
      ;;

    cleanup)
      shift
      esc cursor_show
      ;;

    created | added | item | info)
      local usage="${usage%COMMAND*}$1 FORMAT [ARGS...]"
      local _rs
      util -v _rs print --icon "$1" "${@:2}"
      [ ! "${inline-}" ] || _rs="${_rs# }"
      echo "$_rs"
      ;;

      # TODO
      #    EX_*)
      #      local
      #       Parses this script for a line documenting the parameter and returns the comment.
      #      describe() { sed -En "/declare -r -g $1=.*#/p" "${BASH_SOURCE[0]}" | sed -E 's/[^#]*#[[:space:]]*(.*)$/\1/g'; }
      #
      #      local err_message=$(describe $1)
      #      logr error --code "$1" "$2 is missing a value -- $err_message" --usage "$usage" -- "${@}"
      #      ;;

    success | warning | error | failure)
      local command=$1 call_offset=0
      local usage="${usage%COMMAND*}$1 [-c|--code CODE] [-n|--name NAME] [-u|--usage USAGE] [FORMAT [ARGS...]] [--] [INVOCATION...]" && shift
      [ "$command" = success ] || [ "$command" = warning ] || [ "$code" -ne 0 ] || code=1 # default code for errors
      [ ! "${LOGR_ALIAS-}" ] || call_offset=1
      local name=${FUNCNAME[$((1 + call_offset))]:-?} format=() usage_opt stacktrace=() print_call idx
      [ ! "${name-}" = main ] || name=${BASH_SOURCE[$((${#BASH_SOURCE[@]} - 1))]##*/}
      while (($#)); do
        case $1 in
          -c | --code)
            [ "${2-}" ] || logr error "value of code missing" --usage "$usage" -- "${inv[@]}"
            code=$2 && shift 2
            ;;
          -n | --name)
            [ "${2-}" ] || logr error "value of name missing" --usage "$usage" -- "${inv[@]}"
            name=$2 && shift 2
            ;;
          -u | --usage)
            [ "${2-}" ] || logr error "value of usage missing" --usage "$usage" -- "${inv[@]}"
            usage_opt=$2 && shift 2
            ;;
          -x | --stacktrace)
            shift
            for idx in "${!BASH_LINENO[@]}"; do
              [ "$call_offset" -eq 0 ] || {
                call_offset=$((call_offset - 1))
                continue
              }
              [ "${BASH_LINENO[idx]}" = 0 ] || stacktrace+=("${FUNCNAME[idx + 1]:-?}(${BASH_SOURCE[idx + 1]:-?}:${BASH_LINENO[idx]:-?})")
            done
            ;;
          --)
            print_call=true && shift
            break
            ;;
          *)
            format+=("$1") && shift
            ;;
        esac
      done

      if [ "$code" -le "$EX_GENERAL" ] && [ "${usage_opt-}" ]; then
        code="$EX_USAGE"
      fi

      local invocation=$name
      if [ "${print_call-}" ]; then
        if [ $# -eq 0 ]; then
          invocation+=" ${esc_italic-}[no arguments]${esc_italic_end-}"
        else
          printf -v invocation " ${esc_underline-}%q${esc_underline_end-}" "$@"
          invocation="$name$invocation"
        fi
      fi

      local formatted
      # shellcheck disable=SC2059
      [ "${#format[@]}" -eq 0 ] || printf -v formatted -- "${format[@]}"
      case $command in
        success)
          printf -v formatted '%s %s %s%s%s\n' "${esc_green-}" "${ICONS["$command"]}" "$invocation" \
            "${formatted+: "${esc_bold-}${formatted}${esc_stout_end-}"}" "${esc_reset-}"
          ;;
        warning)
          printf -v formatted '%s %s %s%s%s\n' "${esc_yellow-}" "${ICONS["$command"]}" "$invocation" \
            "${formatted+: "${esc_bold-}${formatted}${esc_stout_end-}"}" "${esc_reset-}"
          ;;
        failure)
          printf -v formatted '%s %s %s failed%s%s\n' "${esc_red-}" "${ICONS["$command"]}" "$invocation" \
            "${formatted+: "${esc_bold-}${formatted}${esc_stout_end-}"}" "${esc_reset-}"
          ;;
        *)
          printf -v formatted '%s %s %s%s%s\n' "${esc_red-}" "${ICONS["$command"]}" "$invocation" \
            "${formatted+: "${esc_bold-}${formatted}${esc_stout_end-}"}" "${esc_reset-}"
          ;;
      esac

      [ ${#stacktrace[@]} -eq 0 ] || formatted+="$(printf '     at %s\n' "${stacktrace[@]}")$LF"
      [ ! "${usage_opt-}" ] || formatted+="   Usage: $name ${usage_opt//$LF/$LF   }$LF"

      printf '%s' "$formatted" >&2

      if [ "$command" = success ] || [ "$command" = warning ]; then
        return "${code:-0}"
      else
        exit "${code:-1}"
      fi
      ;;
    list)
      local items=() item usage="${usage%COMMAND*}$1 [-i | --inline] [ITEMS...]" && shift
      for item in "$@"; do items+=("$(logr item "$item")"); done
      if [ "${inline-}" ]; then
        item=${items[*]}
        echo "${item:1}"
      else
        item=${items[*]/#/$'\n'}
        echo "${item:1}"
      fi
      ;;
    link)
      usage="${usage%COMMAND*}$1 URL [TEXT]"
      shift
      [ $# -ge "1" ] || logr error "url missing" --usage "$usage" -- "$@"
      local url="$1" text=${2-} _link_link
      # shellcheck disable=SC1003
      if [ "${tty_connected-}" ]; then
        local params='' # colon separated list of key-value pairs
        local start="${ESC_OSC}8;${params};%s${ESC_ST}" end="${ESC_OSC}8;;${ESC_ST}"
        util -v _link_link print --icon link "${start}%s${end}" "$url" "${text:-$url}"
      else
        if [ "${text-}" ]; then
          util -v _link_link print --icon link '[%s](%s)' "$url" "$text"
        else
          util -v _link_link print --icon link '%s' "$url"
        fi
      fi
      [ ! "${inline-}" ] || _link_link="${_link_link# }"
      echo "$_link_link"
      ;;
    file)
      usage="${usage%COMMAND*}$1 [-l|--line LINE [-c|--column COLUMN]] PATH [TEXT]"
      shift
      local args=() line column
      while (($#)); do
        case $1 in
          -l | --line)
            [ "${2-}" ] || logr error "value of line missing" --usage "$usage" -- "$@"
            line=$2 && shift 2
            ;;
          -c | --column)
            [ "${2-}" ] || logr error "value of column missing" --usage "$usage" -- "$@"
            column=$2 && shift 2
            ;;
          *)
            args+=("$1") && shift
            ;;
        esac
      done
      set -- "${args[@]}"
      [ $# -ge 1 ] || logr error "path missing" --usage "$usage" -- "$@"
      local path=$1
      local text=${2-}
      [[ $path =~ ^/ ]] || path="$PWD/$path"
      if [ "${line-}" ]; then
        # line suffix at needed by IntelliJ
        if [[ ${__CFBundleIdentifier-} == "com.jetbrains"* ]]; then
          path+=":$line"
        else
          # line suffix as specified by iTerm 2
          path+="#$line"
        fi
        [ ! "${column-}" ] || path+=":$column"
      fi
      local url="file://$path"
      if [ "${tty_connected-}" ]; then
        logr ${inline+"--inline"} link "$url" "${text:-$url}"
      else
        logr ${inline+"--inline"} link "$url" ${text+"$text"}
      fi
      ;;
    task)
      usage="${usage%COMMAND*}$1 [FORMAT [ARGS...]] [-- COMMAND [ARGS...]]"
      shift
      local format=()
      while (($#)); do
        case $1 in
          --)
            shift && break
            ;;
          *)
            format+=("$1") && shift
            ;;
        esac
      done
      local -a cmdline=("$@")

      local logr_task
      if [ "${#format[@]}" -eq 0 ]; then
        [ "${#cmdline[@]}" -gt 0 ] || logr error "format or command missing" --usage "$usage" -- "$@"
        util inline -v logr_task "${cmdline[*]}"
      else
        # shellcheck disable=SC2059
        util inline -v logr_task "${format[@]}"
      fi

      if [ "${#cmdline[@]}" -eq 0 ]; then
        local _rs
        util -v _rs print --icon task "$logr_task"
        [ ! "${inline-}" ] || _rs="${_rs# }"
        echo "$_rs"
        return "$EX_OK"
      fi

      local logr_tasks && util -v logr_tasks fit_concat nested "$logr_parent_tasks" "$logr_task"

      local task_file && task_file=${TMPDIR%/}/logr.$$.task
      local log_file && log_file=${TMPDIR%/}/logr.$$.log

      local task_exit_status=0
      if [ ! "$logr_parent_tasks" ]; then
        [ ! -f "$task_file" ] || rm -- "$task_file"
        [ ! -f "$log_file" ] || rm -- "$log_file"
        util print "$logr_tasks"
        spinner start
        # run command line; redirect stdout+stderr to log_file; provide FD3 and FD4 as means to still print
        (logr_parent_tasks=$logr_tasks "${cmdline[@]}" 3>&1 1>"$log_file" 4>&2 2>"$log_file") || task_exit_status=$?
      else
        util reprint --skip-icon "$logr_tasks" 1>&3 2>&4
        # run command line; redirects from parent task already apply
        (logr_parent_tasks=$logr_tasks "${cmdline[@]}") || task_exit_status=$?
      fi

      if [ ! "$task_exit_status" -eq 0 ] && [ ! -f "$task_file" ]; then
        printf %s "$logr_tasks" >"$task_file"
      fi

      # pass exit code up to initial task
      if [ "$logr_parent_tasks" ]; then
        [ "$task_exit_status" -eq 0 ] || exit "$task_exit_status"
      else
        # --- only initial task here
        spinner stop

        if [ ! "$task_exit_status" -eq 0 ]; then
          # error
          {
            util reprint --icon error "$(cat "$task_file")"
            [ ! -e "$task_file" ] || rm -- "$task_file"
            sed \
              -e "$ESC_PATTERN" \
              -e 's/^/'"$MARGIN${esc_red-}"'/;' \
              -e 's/$/'"${esc_reset-}"'/;' \
              "$log_file"
            [ ! -e "$log_file" ] || rm -- "$log_file"
            logr cleanup
            exit $task_exit_status
          } >&2
        else
          # success
          # erase what has been printed on same line by printing task_line again
          [ ! -e "$task_file" ] || rm -- "$task_file"
          [ ! -e "$log_file" ] || rm -- "$log_file"
          util reprint --icon success "$logr_tasks"
        fi
      fi
      ;;
    *)
      local alias=$1
      local original="${ICON_ALIASES[$1]-}"
      [ "${original}" ] || logr error "unknown command" --usage "$usage" -- "$@"

      shift
      LOGR_ALIAS=$alias LOGR_ALIAS_CODE=$code logr ${inline+"--inline"} "$original" "$@" || return "$?"
      ;;
  esac
}

# Prompts for user input of the specified type.
# Arguments:
#   1 - type
#   * - type arguments
# Returns:
#   0 - success
#   1 - error
#   10 - no
#   * - signal
prompt4() {
  local usage="TYPE [ARGS...]"
  case ${1:-'_help'} in
    _help | -h | --help)
      printf '\n   %s\n\n   Usage: prompt4 %s%s' "$(banr --static "prompt4" "$LOGR_VERSION")" "$usage" '

   Type:
     Y/n    "Do you want to continue?"
'
      exit "$EX_OK"
      ;;
    Y/n)
      shift
      local -a args=()
      local _arg _yn_question="Do you want to continue?"
      for _arg in "$@"; do
        if [ "${_arg-}" = - ]; then
          args+=("$_yn_question")
        else
          args+=("${_arg-}")
        fi
      done
      set -- "${args[@]}"

      if [ $# -gt 0 ]; then
        # shellcheck disable=SC2059
        printf -v _yn_question "$@"
      fi

      local formatted_question
      util -v formatted_question print '%s%s %s %s' "${esc_bold-}" "${_yn_question%%$LF}" "[Y/n]" "${esc_stout_end-}"
      [ ! "${tty_connected-}" ] || {
        printf '\n%s' "$esc_cuu1"
      }

      prompt4 _read_answer "$formatted_question" || true

      local _prompt4_format="${esc_cursor_hide-}${esc_dim-}%s${esc_reset-}${esc_hpa0-}"

      if [ "${REPLY-}" = no ]; then
        util print "$_prompt4_format" no --icon error
        exit "$EX_NEG_USR_RESP"
      fi

      util print "$_prompt4_format" yes --icon success
      printf '\n'
      sleep .4
      ;;
    _read_answer)
      shift
      trap 'REPLY=no; trap - INT TERM; return '"$EX_GENERAL" INT TERM
      read -n 1 -r -s -p "${1?prompt missing}"
      if [ "$REPLY" = $'\E' ] || [ "$REPLY" = 'n' ]; then
        REPLY=no
      fi
      ;;
    *)
      logr error "unknown type" --usage "$usage" -- "$@"
      ;;
  esac
}

# Kommons' tracer [1] inspired helper function that supports print debugging [2]
# by printing details about the passed arguments.
# Arguments:
#   * - arguments to print debugging information for
# References:
#   1 - https://github.com/bkahlert/kommons/blob/35e2ac1c4246decdf7e7a1160bfdd5c9e28fd066/src/commonMain/kotlin/com/bkahlert/kommons/debug/Insights.kt#L149
#   2 - https://en.wikipedia.org/wiki/Debugging#Print_debugging
tracr() {
  local arg_columns=40 && [ ! "${COLUMNS-}" ] || arg_columns=$((COLUMNS / 2))
  local out_args='' out_args_len=0 out_argc=0 out_location='?'

  # shellcheck disable=SC2059
  [ $# -eq 0 ] || {
    printf -v out_args '%q ' "$@"
    printf -v out_args_len '%q ' "$@" && out_args_len="${#out_args_len}"
  }

  # shellcheck disable=SC2059
  printf -v out_argc '%q' "$#"
  local out_argc_pad=' ' && [ $# -le 9 ] || out_argc_pad=''

  [ ! "${BASH_SOURCE[1]-}" ] || out_location=$(logr file ${BASH_LINENO[0]+--line "${BASH_LINENO[0]}"} "${BASH_SOURCE[1]}")
  local missing=$((arg_columns - out_args_len - 4))
  [ "$missing" -gt 0 ] || missing=1
  printf '%s%s%s %s%*s %s%s\n' "${esc_bright_cyan-}" "$out_argc_pad" "$out_argc" "$out_args" "$missing" '' "$out_location" "${esc_reset-}" >&2
}

# Initializes environment
# shellcheck disable=SC2034
# bashsupport disable=BP2001
main() {
  [ ! "${LOGR_VERSION-}" ] || return 0

  set -o nounset
  set -o pipefail
  set -o errtrace

  declare -r -g EX_OK=0
  declare -r -g EX_GENERAL=1
  declare -r -g EX_NEG_USR_RESP=10
  # see https://man.openbsd.org/sysexits.3
  declare -r -g EX_USAGE=64       # command line usage error
  declare -r -g EX_DATAERR=65     # data format error
  declare -r -g EX_NOINPUT=66     # cannot open input
  # bashsupport disable=SpellCheckingInspection
  declare -r -g EX_NOUSER=67      # addressee unknown
  # bashsupport disable=SpellCheckingInspection
  declare -r -g EX_NOHOST=68      # host name unknown
  declare -r -g EX_UNAVAILABLE=69 # service unavailable
  declare -r -g EX_SOFTWARE=70    # internal software error
  # bashsupport disable=SpellCheckingInspection
  declare -r -g EX_OSERR=71       # system error (e.g., can't fork)
  # bashsupport disable=SpellCheckingInspection
  declare -r -g EX_OSFILE=72      # critical OS file missing
  declare -r -g EX_CANTCREAT=73   # can't create (user) output file
  # bashsupport disable=SpellCheckingInspection
  declare -r -g EX_IOERR=74       # input/output error
  declare -r -g EX_TEMPFAIL=75    # temp failure; user is invited to retry
  declare -r -g EX_PROTOCOL=76    # remote error in protocol
  # bashsupport disable=SpellCheckingInspection
  declare -r -g EX_NOPERM=77      # permission denied
  declare -r -g EX_CONFIG=78      # configuration error

  declare -r -g TMPDIR=${TMPDIR:-/tmp}
  declare -r -g LOGR_VERSION=0.6.2
  declare -r -g BANR_CHAR=▔
  declare -r -g MARGIN='   '
  declare -r -g LF=$'\n'
  declare -r -g ESC=$'\x1B'
  declare -r -g ESC_CSI="$ESC"'[' # control sequence intro
  declare -r -g ESC_OSC="$ESC"']' # operating system command
  declare -r -g ESC_ST="\e\\\\"   # string terminator
  declare -r -a -g ESC_PATTERNS=(
    's|'"$ESC_OSC"'[[:digit:]]*\;[^'"$ESC"']*'"$ESC"'\\||g;' # OSC escape sequences
    's|'"$ESC"'[@-Z\\-_]||g;'                                # Fe escape sequences
    's|'"$ESC"'[ -/][@-~]||g;'                               # 2-byte sequences
    's|'"$ESC_CSI"'[0-?]*[ -/]*[@-~]||g;'                    # CSI escape sequences
  )
  printf -v ESC_PATTERN '%s' "${ESC_PATTERNS[@]}"

  esc --init

  local r=${esc_reset-}
  # bashsupport disable=BP5006
  declare -A -g ICONS=(
    ['created']="${esc_yellow-}✱$r"
    ['added']="${esc_green-}✚$r"
    ['item']="${esc_bright_black-}▪$r"
    ['link']="${esc_blue-}↗$r"
    ['file']="${esc_blue-}↗$r"
    ['task']="${esc_yellow-}⚙$r"
    ['nested']="${esc_yellow-}❱$r"
    ['exit']="${esc_bold-}${esc_red-}↩$r"
    ['success']="${esc_green-}✔$r"
    ['info']="${esc_white-}ℹ$r"
    ['warning']="${esc_bold-}${esc_yellow-}!$r"
    ['error']="${esc_red-}✘$r"
    ['failure']="${esc_bold-}${esc_red-}ϟ$r"
  )

  declare -g logr_parent_tasks=''

  # bashsupport disable=BP5006
  declare -A -g -x ICON_ALIASES=(
    ['creation']="created"
    ['create']="created"
    ['new']="created"
    ['addition']="added"
    ['add']="added"
    ['hyperlink']="link"
    ['job']="task"
    ['work']="task"
    ['nesting']="nested"
    ['nest']="nested"
    ['successful']="success"
    ['succeed']="success"
    ['succeeded']="success"
    ['inform']="info"
    ['informed']="info"
    ['warn']="warning"
    ['warned']="warning"
    ['err']="error"
    ['erroneous']="error"
    ['failed']="failure"
    ['fail']="failure"
    ['fatal']="failure"
  )

  # Checks if the given shell option is available and activates it. Fails otherwise.
  # Arguments:
  #   1 - shell option name
  require_shopt() {
    [[ $# -eq 1 ]] || logr error --usage "option" --stacktrace -- "$@"
    [[ ":${BASHOPTS}:" != *":$1:"* ]] || return 0
    shopt -s "$1" || logr error "unsupported shell option" --stacktrace -- "$@"
  }
  require_shopt globstar            # ** matches all files and any number of dirs and sub dirs
  require_shopt checkwinsize        # updates COLUMNS and LINES
  stty -echoctl 2>/dev/null || true # don't echo control characters in hat notation (e.g. `^C`)

  logr _init

  [ ! "${RECORDING-}" ] || return "$EX_OK"
  [[ " $* " == *" -!- "* ]] || return "$EX_OK"
  [[ " $* " != *" -h "* ]] || logr _help
  [[ " $* " != *" --help "* ]] || logr _help

  logr error "execution detected" --usage "must be sourced at the top of your script in order to be used.

$(
    logr info "%s\n%s\n" "If logr is on your ${esc_bold-}\$PATH${esc_reset-} add:" \
      "${esc_yellow-}"'source logr.sh'"${esc_reset-}"
    logr info "%s\n%s\n" "To source logr from the ${esc_bold-}same directory as your script${esc_reset-} add:" \
      "${esc_yellow-}"'source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/logr.sh"'"${esc_reset-}"
    logr info "%s\n%s\n" "To source logr ${esc_bold-}relative to your script${esc_reset-} add:" \
      "${esc_yellow-}"'source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/RELATIVE_PATH/logr.sh"'"${esc_reset-}"
    logr info "%s\n%s\n" "And for the more adventurous:" \
      "${esc_yellow-}"'source <(curl -LfsS https://git.io/logr.sh)'"${esc_reset-}"
  )"
}

main "$@"
