#!/usr/bin/env python3

import sys
from textwrap import dedent


def generate_pes(x_size: int, y_size: int):
  """
  Generate a x_size by y_size dummy PES.
  """
  index = 0

  for j in range(y_size):
    for i in range(x_size):
      print("1")
      print(f"G: {x_size} x {y_size} i: {i} j: {j} E: {index / 50}")
      print(f"H {i} {j} {index}")
      index += 1


def usage() -> str:
  """
  Prints usage to stderr.
  """
  print(dedent(f"""\
    Generates a dummy PES with provided sizes.
    Usage:
      {sys.argv[0]} <x_size> <y_size> >out.pes
    """),
    file=sys.stderr)


def main() -> None:
  """
  Parse arguments and call generate_pes.
  """
  n = len(sys.argv)
  if n != 3:
    usage()
    sys.exit(1)

  generate_pes(int(sys.argv[1]), int(sys.argv[2]))


if __name__ == "__main__":
  main()
