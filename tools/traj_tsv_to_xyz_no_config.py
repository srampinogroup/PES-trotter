#!/usr/bin/env python3
"""
Convert a TSV-like output from Fortran trajectory to PES-trotter XYZ
format. Ignores configuration.
Usage:
  ./traj_tsv_to_xyz.py <fort.80000.tsv >trajectory.xyz
"""
import sys
from typing import TextIO


def parse_tsv(tsv: TextIO) -> list[list[float]]:
  """
  Basic space separated numeric value parser. Perform no check.
  """
  traj = []

  for line in tsv:
    segments = line.split()
    traj += [list(map(float, segments))]

  return traj


def generate_xyz(data: list[list[float]], out: TextIO) -> None:
  """
  Write data as an XYZ trajectory file to `out`.
  """
  tot = len(data)
  for i, pos in enumerate(data):
    out.write("0\n")
    out.write(f"total: {tot} i: {i} x: {pos[0]} y: {pos[1]} E: 0\n")


def main() -> None:
  """
  Setup IO and start conversion.
  """
  data = parse_tsv(sys.stdin)
  generate_xyz(data, sys.stdout)


if __name__ == "__main__":
  main()
