#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert
}

recordr() {
  "$BATS_CWD/recordr" "$@"
}

@test "should print help on --help" {
  run recordr --help
  assert_success
  assert_output --partial '
   ▔▔▔▔▔▔▔ RECORDR 0.1.0

   Usage: recordr [OPTIONS] [DIR[/ ]FILE [FILE...]]

   Options:
     --'
  assert_line '     --out-dir              path to copy the created SVG files to (default: docs/)'
  assert_output --partial "
   Files:
     There are basically two ways to specify which ● rec files to convert:
     - Convert a single file: ./recordr rec/foo.rec
       same as: ./rec/foo.rec (interpreter form)
       same as: ./recordr --build-dir build/rec --out-dir docs rec/foo.rec (explicit directories)

       Before:
       ▤ work             ⬅︎ you are here
       └─▤ rec
         ├─● foo.rec
         └─▤ bar
           └─● baz.rec

       After:
       ▤ work             ⬅︎ you are here
       ├─▤ rec
       │ ├─● foo.rec
       │ └─▤ bar
       │   └─● baz.rec
       ├─▤ build
       │ └─▤ rec
       │   ├─▢ foo.sh
       │   ├─▢ foo.svg.0
       │   ├─▢ foo.svg.⋮
       │   └─▢ foo.svg.n
       └─▤ docs
         └─● foo.svg      ⬅︎ to SVG converted ● rec file

     - Convert a file tree: ./recordr rec
       same as: ./recordr (default directory: rec)
       same as: ./recordr --build-dir build/rec --out-dir docs rec (explicit default directories)
       same as: ./recordr rec foo.rec bar/baz.rec (explicit files)

       Before:
       ▤ work             ⬅︎ you are here
       └─▤ rec
         ├─● foo.rec
         └─▤ bar
           └─● baz.rec

       After:
       ▤ work             ⬅︎ you are here
       ├─▤ rec
       │ ├─● foo.rec
       │ └─▤ bar
       │   └─● baz.rec
       ├─▤ build
       │ └─▤ rec
       │   ├─▢ foo.sh
       │   ├─▢ foo.svg.0
       │   ├─▢ foo.svg.⋮
       │   ├─▢ foo.svg.n
       │   └─▤ bar
       │     ├─▢ baz.sh
       │     ├─▢ baz.svg.0
       │     ├─▢ baz.svg.⋮
       │     └─▢ baz.svg.n
       └─▤ docs
         ├─● foo.svg      ⬅︎ to SVG converted ● rec file
         └─▤ bar
           └─● baz.svg    ⬅︎ to SVG converted ● rec file"
}

@test "should print help on -h" {
  assert_equal "$(recordr --help)" "$(recordr -h)"
}

@test "should print usage on missing option value" {
  run recordr --parallel
  assert_failure 64
  assert_line ' ✘ recordr --parallel: --parallel is missing a value'
  assert_line '   Usage: recordr [OPTIONS] [DIR[/ ]FILE [FILE...]]'
}

@test "should print error on invalid option value" {
  run recordr --parallel invalid
  assert_failure 65
  assert_line --partial "invalid --parallel value 'invalid'"
}

@test "should print usage on unknown option" {
  run recordr --unknown
  assert_failure 64
  assert_line ' ✘ recordr --unknown: unknown option --unknown'
  assert_line '   Usage: recordr [OPTIONS] [DIR[/ ]FILE [FILE...]]'
}
