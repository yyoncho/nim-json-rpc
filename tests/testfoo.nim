import unittest
import json, ../json_rpc/router

suite "description for this stuff":
  echo "suite setup: run once before the tests"

  setup:
    echo "run before each test"

  teardown:
    echo "run after each test"

  test "slightly less obvious stuff":
    # print a nasty message and move on, skipping
    # the remainder of this block
    check(1 == 1)

  test "out of bounds error is thrown on bad access":
    let v = @[1, 2, 3]  # you can do initialization here
    expect(IndexDefect):
      discard v[4]

  echo "suite teardown: run once after the tests"
