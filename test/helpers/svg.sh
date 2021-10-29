#!/usr/bin/env bash

# compares start and end of the expected fixture and the actual SVG
assert_equal_svg_fixture() {
  local expected actual part1_end='@keyframes' part2_start='class="container_end"'
  expected="$(cat "$(fixture "$1")")"
  expected_start=${expected%%${part1_end}*}
  expected_end=${expected##*${part2_start}}
  actual="$(cat "$2")"
  actual_start=${actual%%${part1_end}*}
  actual_end=${expected##*${part2_start}}

  assert_equal "$expected_start" "$actual_start"
  assert_equal "$expected_end" "$actual_end"
}
