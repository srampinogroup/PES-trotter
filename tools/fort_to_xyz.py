#!/usr/bin/env python3
"""
Convert two TSV-like output from Fortran trajectory to PES-trotter
XYZ format to standard out. The first file should be the path on the
PES, with lines in the form
pes-x pes-y energy
The second one the configuration, with lines in the form
rBC rAC rAB
Only handle triatomic systems.
The last argument can be used to specify which atom will be at the
origin. 0 for A, 1 for B, 2 for C. Default 0.
Example usage:
  ./traj_tsv_to_xyz.py fort.80000.tsv fort.10000.tsv Li H H
  ./traj_tsv_to_xyz.py fort.80000.tsv fort.10000.tsv Li H H 1
"""
import sys
from collections import deque
from math import sqrt
from typing import TextIO


N_DIM = 3
ANGSTROM = 0.529177249


def usage() -> None:
  """
  Print usage to standard error.
  """
  print("""
Usage:
  ./traj_tsv_to_xyz.py path.tsv interdist.tsv A B C [origin] >trajectory.xyz
  """, file=sys.stderr)


def parse_tsv(tsv: TextIO) -> list[list[float]]:
  """
  Basic space separated numeric value parser. Perform no check.
  """
  traj = []

  for line in tsv:
    segments = line.split()
    traj += [list(map(float, segments))]

  return traj


def interdist_to_xyz(interdist: list[float]) -> list[list[float]]:
  """
  Compute the positions in space of the A, B and C atoms from the
  interatomic distances using the cosine law. Take the atom A as
  origin, and the second as reference frame for the X axis. The y
  coordinate is always zero because of conservation of angular
  momentum.
  Example:
  interdist_to_xyz([5, 4, 3]) == [[0, 0, 0], [4, 0, 0], [0, 0, 3]]
  """
  rbc = interdist[0]
  rac = interdist[1]
  rab = interdist[2]

  va = [0.0] * N_DIM
  vb = [0.0] * N_DIM
  vc = [0.0] * N_DIM

  cosa = rab**2 + rac**2 - rbc**2
  cosa /= 2 * rac * rab
  sina = sqrt(1 - cosa**2)

  vb[0] = rab
  vc[0] = rac * cosa
  vc[1] = rac * sina

  return [va, vb, vc]
  # return [va, vc, vb]


def to_center_of_mass(
    vatoms: list[list[float]],
    masses: list[float] = None,
  ) -> list[list[float]]:
  """
  Compute the center of mass and translates the vectors accordingly.
  """
  n_atoms = len(vatoms)
  if not masses:
    masses = [1.0] * n_atoms

  vcom = [0.0] * N_DIM

  for i, m in enumerate(masses):
    for j in range(N_DIM):
      vcom[j] += m * vatoms[i][j]

  mtot = sum(masses)
  vcom = list(v / mtot for v in vcom)

  for i in range(n_atoms):
    for j in range(N_DIM):
      vatoms[i][j] -= vcom[j]

  return vatoms


def generate_xyz(
    pes_path: list[list[float]],
    configurations: list[list[float]],
    atoms: list[str],
    origin: list[str],
    out: TextIO
  ) -> None:
  """
  Combine pes_path and configurations as an XYZ trajectory file to
  `out`.
  """
  tot = len(pes_path)
  n_atoms_line = f"{len(atoms)}\n"

  for i, pos in enumerate(pes_path):
    out.write(n_atoms_line)
    out.write(f"total: {tot} i: {i} "
            + f"x: {pos[0]} y: {pos[1]} E: {pos[2]}\n")

    conf = configurations[i]
    # conf = map(lambda r: r * ANGSTROM, conf)
    conf = deque(conf)
    conf.rotate(-origin)
    vabc = interdist_to_xyz(conf)
    vabc = deque(vabc)
    vabc.rotate(origin)
    vabc = to_center_of_mass(vabc)

    for i_atom, atom in enumerate(atoms):
      v = vabc[i_atom]
      out.write(f"{atom} {v[0]} {v[1]} {v[2]} \n")


def main() -> None:
  """
  Setup IO and start conversion.
  """
  narg = len(sys.argv)
  if narg != 6 and narg != 7:
    usage()
    sys.exit(1)

  with open(sys.argv[1], "r", encoding="utf-8") as f:
    pes_path = parse_tsv(f)

  with open(sys.argv[2], "r", encoding="utf-8") as f:
    configurations = parse_tsv(f)

  assert len(pes_path) == len(configurations), \
    "the two files have different number of lines"

  atoms = sys.argv[3:6]
  origin = int(sys.argv[6]) if narg == 7 else 0
  generate_xyz(pes_path, configurations, atoms, origin, sys.stdout)


if __name__ == "__main__":
  main()
