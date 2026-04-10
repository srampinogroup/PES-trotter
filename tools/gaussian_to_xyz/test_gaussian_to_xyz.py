#!/usr/bin/env python3
"""Test module gaussian_to_xyz."""

from gaussian_to_xyz import (
  Atom,
  Geometry,
  parse_atom_list,
  parse_grid,
  parse_energy,
  boustrophedonize,
  eV,
)

def test_classes() -> None:
  """Test classes serialization."""
  valid = r"""3
G: 1 x 1 i: 0 j: 0 E: 666
8 0 0 0
1 0.95 0.22 0
1 -0.95 0.22 0"""
  print("Should print:\n" + valid)
  print("-----------------------")
  o = Atom(8, 0, 0, 0)
  h1 = Atom(1, 0.95, 0.22, 0)
  h2 = Atom(1, -0.95, 0.22, 0)
  g = Geometry(1, 1, 0, 0, 666, [o, h1, h2])
  print(g)
  assert str(g) == valid, "Test failed."
  print("OK")


def test_parse_atom_list() -> None:
  """Test parse_atom_list"""

  test_data = """\
      1          6           0       -1.850814    0.227150   -0.310821
      2          1           0       -2.164554    0.287732   -1.367447
      3          1           0        0.600567   -0.686268   -0.004711
      4          6           0       -0.562692    1.077443   -0.152821
      5          8           0       -0.647581    2.326084   -0.269095
      6          7           0        0.547569    0.356733   -0.040607
      7          6           0        1.912587    0.865404    0.005998
      8          1           0        2.095983    1.481356    0.895211
      9          1           0        2.162517    1.461996   -0.879954
     10          6           0       -2.937815    0.866259    0.564193
     11          1           0       -2.909278    1.941685    0.371333
     12          1           0       -3.935658    0.466760    0.350420
     13          1           0       -2.690959    0.679507    1.614252
     14          8           0       -1.666294   -1.125567    0.204523
     15          6           0       -2.694796   -2.050434   -0.225279
     16          1           0       -2.394235   -3.031727    0.153367
     17          1           0       -3.689636   -1.798977    0.176781
     18          1           0       -2.773618   -2.098336   -1.325118
     19          6           0        2.843656   -0.436742    0.057146
     20          8           0        2.180435   -1.538256    0.055721
     21          8           0        4.084082   -0.224178    0.092552"""

  atoms = parse_atom_list(test_data.split("\n"))

  print("Geometry should match following table:")
  print("""
 Center     Atomic      Atomic             Coordinates (Angstroms)
 Number     Number       Type             X           Y           Z
 ---------------------------------------------------------------------""")
  print(test_data)

  print("\nGeometry:")
  for atom in atoms:
    print(atom)

  print("parse_atom_list OK")


def test_parse_grid() -> None:
  """Test parse_grid"""
  test_str = "Step number  11 out of a maximum of  101 on scan point   552 out of   625"
  n, i, j = parse_grid(test_str)
  assert n == 25, f"bad grid size: {n} != 25"
  assert i == 1, f"bad i grid index: {i} != 1"
  assert j == 22, f"bad j grid index: {j} != 22"
  print("parse_grid OK")


def test_parse_energy() -> None:
  """Test parse_energy"""
  test_line = "SCF Done:  E(RB3LYP) =  -587.116115299     A.U. after  12 cycles"
  energy = parse_energy(test_line)
  assert energy == -587.116115299 / eV, \
      f"wrong energy parsed: {energy} != -587.116115299"
  print("parse_energy OK")


def test_boustrophedonize() -> None:
  """Test boustrophedonize"""
  ib = boustrophedonize(10, 3, 3)
  assert ib == 10 - 3 - 1, f"incorrect index: {ib} != 6"
  print("boustrophedonize OK")


if __name__ == "__main__":
  test_classes()
  test_parse_atom_list()
  test_parse_grid()
  test_parse_energy()
  test_boustrophedonize()
