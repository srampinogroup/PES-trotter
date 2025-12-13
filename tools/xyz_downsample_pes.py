#!/usr/bin/env python3
"""
Downsample a PES in XYZ format in integer division. Loses the last
rows if number of rows - 1 is not divisible by n, and loses the last
columns if the number of columns - 1 is not divisible by n.
Does not load the PES in memory.
Default n is 2.
Usage:
  ./xyz_downsample_pes.py [<n>] <in.pes >out.pes
"""

import sys
from textwrap import dedent
from xyz_dataclasses import GridInfo


def downsample(n: int) -> None:
  """
  Reads a well-formatted XYZ file from stdin and output one
  configuration every n configurations to stdout.
  """
  f = sys.stdin

  first_line: str = f.readline()
  second_line: str = f.readline()

  atoms_count: int = int(first_line)
  grid_info: GridInfo = GridInfo.from_string(second_line)

  # print first point
  print(first_line, end="")
  print(grid_info.divided_by(n))
  for _a in range(atoms_count):
    line: str = f.readline()
    print(line, end="")

  # and the rest
  for y in range(0, grid_info.size_y):
    for x in range(0, grid_info.size_x):
      if x == 0 and y == 0:
        continue # already done, this is first point

      atoms_line = f.readline()
      grid_line = f.readline()
      curr_grid_info: GridInfo = GridInfo.from_string(grid_line)
      i = curr_grid_info.i
      j = curr_grid_info.j
      should_print: bool = i % n == 0 and j % n == 0

      if should_print:
        print(atoms_line, end="")
        print(curr_grid_info.divided_by(n))

      for _atom in range(atoms_count):
        line: str = f.readline()
        if should_print:
          print(line, end="")


def usage() -> None:
  """
  Print usage to stderr.
  """
  print(dedent(f"""\
    Downsamples a PES file in XYZ format to 1/n size with n a positive
    integer.
    Reads from and write to standard in/out. Default n is 2.
    Usage:
      {sys.argv[0]} [<n>] <in.pes >out.pes
    """),
    file=sys.stderr)


def main() -> None:
  """
  Entry point. Check arguments.
  """
  argc = len(sys.argv)
  if argc > 2:
    usage()
    sys.exit(1)

  n: int = 2
  if argc == 2:
    n = int(sys.argv[1])
    if n < 1:
      usage()
      sys.exit(2)

  downsample(n)


def __test_divide() -> None:
  """
  Test the GridInfo.divided_by function for n = 2.
  """
  data = [
    "G: 5 x 5 i: 0 j: 0 E: 0.0\n",
    "G: 5 x 5 i: 1 j: 0 E: 0.0\n",
    "G: 5 x 5 i: 2 j: 0 E: 0.0\n",
    "G: 5 x 5 i: 0 j: 2 E: 0.0\n",
    "G: 5 x 5 i: 1 j: 3 E: 0.0\n",
    "G: 5 x 5 i: 2 j: 3 E: 0.0\n",
    "G: 5 x 5 i: 1 j: 4 E: 0.0\n",
    "G: 5 x 5 i: 2 j: 4 E: 0.0\n",
    "G: 5 x 5 i: 4 j: 4 E: 0.0\n",
  ]
  expected = [
    "G: 3 x 3 i: 0 j: 0 E: 0.0\n",
    "G: 3 x 3 i: 0 j: 0 E: 0.0\n",
    "G: 3 x 3 i: 1 j: 0 E: 0.0\n",
    "G: 3 x 3 i: 0 j: 1 E: 0.0\n",
    "G: 3 x 3 i: 0 j: 1 E: 0.0\n",
    "G: 3 x 3 i: 1 j: 1 E: 0.0\n",
    "G: 3 x 3 i: 0 j: 2 E: 0.0\n",
    "G: 3 x 3 i: 1 j: 2 E: 0.0\n",
    "G: 3 x 3 i: 2 j: 2 E: 0.0\n",
  ]
  n = 2

  count = 0
  for (d, e) in zip(data, expected):
    rs = str(GridInfo.from_string(d).divided_by(n))
    assert rs == e, f"test #{count}:\n'{rs}' != \n'{e}'"
    count += 1

  print("Tests ok")


if __name__ == "__main__":
  # __test_divide()
  main()
