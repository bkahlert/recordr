#!/usr/bin/env bats
# bashsupport disable=BP5007

setup() {
  # TODO correct version
  load helpers/setup.sh "${BUILD_TAG:?unspecified image to test}"
  load ../helpers/svg.sh
}

teardown() {
  image_cleanup
}

@test "should print help if specified" {
  mkdir rec
  image --stdout-only -i "$BUILD_TAG" --help
  assert_success
  assert_output --partial '
   ▔▔▔▔▔▔▔ RECORDR SNAPSHOT

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

@test "should convert rec dir by default" {
  mkdir rec && copy_fixture test.rec rec && copy_fixture test.rec rec/test2.rec
  image "$BUILD_TAG"
  assert_line '●◕ BATCH PROCESSING'
  assert_line ' ℹ recordings directory: rec'
}

@test "should record all rec files in rec directory and convert them to svg in docs directory" {
  mkdir -p rec/bar && copy_fixture .itermcolors . && copy_fixture test.rec rec/foo.rec && copy_fixture test.rec rec/bar/baz.rec
  image -i -e NODE_OPTIONS="--max-old-space-size=16384" "$BUILD_TAG"

  assert_equal_svg_fixture "test.svg" "docs/foo.svg"
  assert_equal_svg_fixture "test.svg" "docs/bar/baz.svg"
  assert_line " ℹ terminal profile search directory: rec"
  assert_line "●◕ BATCH PROCESSING"
  assert_line " ℹ recordings directory: rec"
  assert_line " ● RECORDING: rec/bar/baz.rec"
  assert_line " ● RECORDING: rec/foo.rec"
  assert_line " ◔ CONVERTING: build/rec/foo.cast"
  assert_line " ◔ CONVERTING: build/rec/bar/baz.cast"
  assert_line " ◑ PATCHING: build/rec/foo.svg.0"
  assert_line " ◑ PATCHING: build/rec/bar/baz.svg.0"
  assert_line " ◕ LINKING: build/rec/foo.svg.1"
  assert_line " ◕ LINKING: build/rec/bar/baz.svg.1"
  assert_line " ● ANNOTATING: build/rec/foo.svg.2"
  assert_line " ● ANNOTATING: build/rec/bar/baz.svg.2"
  assert_line " ● COMPLETED: build/rec/foo.svg"
  assert_line " ● COMPLETED: build/rec/bar/baz.svg"
  assert_line " ✔ BATCH PROCESSING: COMPLETED"
}
