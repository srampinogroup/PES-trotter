#!/usr/bin/env python3
"""
Parse a log file to extract geometry data and create an XYZ potential
energy surface.
Full specifications at
https://github.com/srampinogroup/PES-trotter/blob/main/files-specifications.md

Usage:
  ./log2avatar.py input.log output.xyz
"""
import sys
import os
import math
from dataclasses import dataclass, field
import periodictable


ENCODING = "us-ascii"
eV = 1/27.211396641308 # Hartree


@dataclass
class Atom:
  """
  Represent an atom with its atomic symbol and position in
  space ready for the XYZ file format.
  """
  atomic_symbol: str
  x: float = 0.0 # angström
  y: float = 0.0
  z: float = 0.0

  def __str__(self) -> str:
    """XYZ string representation."""
    return f"{self.atomic_symbol} {self.x} {self.y} {self.z}"


@dataclass
class Geometry:
  """
  Store a full geometry on a grid point ready for the XYZ file
  format.
  """
  grid_width: int = 1
  grid_height: int = 1
  grid_i: int = 0
  grid_j: int = 0
  energy: float = 0 # unit agnostic but prefer eV
  atoms: list[Atom] = field(default_factory=list)

  def __str__(self) -> str:
    """XYZ string representation."""
    xyz_str = f"{len(self.atoms)}\n"
    xyz_str += f"G: {self.grid_width} x {self.grid_height} "
    xyz_str += f"i: {self.grid_i} j: {self.grid_j} "
    xyz_str += f"E: {self.energy}\n"
    xyz_str += "\n".join(map(str, self.atoms))
    return xyz_str


def parse_atom_list(buffer: list[str]) -> list[Atom]:
  """
  Read geometry from a table. Expected columns are:
  center number, atomic number, atomic type, x, y, z
  """
  atoms: list[Atom] = []

  for atom_line in buffer:
    elems = atom_line.split()
    # center_number = int(elems[0])
    atomic_number = int(elems[1])
    # atomic_type = int(elems[2])
    x = float(elems[3])
    y = float(elems[4])
    z = float(elems[5])
    atomic_symbol = periodictable.elements[atomic_number].symbol
    atoms += [Atom(atomic_symbol, x, y, z)]

  return atoms


def parse_geometries(path: str) -> list[Geometry]:
  """
  Parse log file and returns geometries found at the last step of
  each optimization procedure.
  """
  geometries: list[Geometry] = []

  with open(path, "r", encoding=ENCODING) as f:
    # Exit is in first nested for loop
    while True:
      last_step_line: str
      last_energy_line: str
      found: bool = False

      for line in f:
        if "Step number" in line:
          last_step_line = line
        elif "SCF Done" in line:
          last_energy_line = line

        if "Stationary point" in line or \
            "Optimization stopped" in line:
          found = True
          break
      else:
        return geometries

      assert found, "reached end without finding optimized setup"

      found = False
      for line in f:
        if "Standard orientation" in line:
          found = True
          break

      assert found, "reached end without finding geometry"

      for _i in range(4):
        next(f)

      atoms_buffer = []
      found = False
      for line in f:
        if line[1] == "-":
          found = True
          break

        atoms_buffer += [line]

      assert found, "reached end but geometry not finished"

      grid_n, grid_i, grid_j = parse_grid(last_step_line)
      energy = parse_energy(last_energy_line)
      atoms = parse_atom_list(atoms_buffer)
      geo = Geometry(grid_n, grid_n, grid_i, grid_j, energy, atoms)
      geometries += [geo]


def parse_grid(step_line: str) -> tuple[int, int, int]:
  """
  Guess the grid size and grid indices from the line
  Step number n out of (...) <gn> out of <gtot>.
  Only support square grids.
  """
  step_info = step_line.split()

  gn = int(step_info[-4]) - 1
  gtot = int(step_info[-1])
  sqgtot = math.sqrt(gtot)
  assert sqgtot.is_integer(), "grid is not square"
  n = int(sqgtot)
  row = gn % n
  col = gn // n

  row = boustrophedonize(n, row, col)

  return n, row, col


def boustrophedonize(num_cols: int, row: int, col: int) -> int:
  """
  Return row index only. For num_cols = 4, this function returns
  j=0 ...
   0  3  0  3   i=0
   1  2  1  2    .
   2  1  2  1    .
   3  0  3  0    .
  """
  return row if col % 2 == 0 else num_cols - row - 1


def parse_energy(energy_line: str) -> float:
  """Parse energy from line starting by "SCF Done"."""
  e = float(energy_line.split()[4])
  return e / eV


def shift_energy(geometries: list[Geometry]) -> None:
  """Shift all energies such that the minimum is 0."""
  min_e = math.inf
  for g in geometries:
    min_e = min(min_e, g.energy)

  for g in geometries:
    g.energy -= min_e


def main(argv) -> None:
  """Main. Parse input file and write output."""
  if len(argv) != 3:
    usage()
    return

  print(f"Parsing {argv[1]}...")
  geometries = parse_geometries(argv[1])
  shift_energy(geometries)

  print(f"Saving to {argv[2]}...")
  with open(argv[2], "w", encoding=ENCODING) as out:
    out.write("\n".join(map(str, geometries)))

  print("Done.")


def usage() -> None:
  """Print usage."""
  fn = os.path.basename(__file__)
  print(f"Usage: ./{fn} input.log output.xyz", file=sys.stderr)


if __name__ == "__main__":
  main(sys.argv)
