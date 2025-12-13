#!/usr/bin/env python3
"""
Define dataclasses to be used by other scripts.
"""
import copy
from dataclasses import dataclass, field
from typing import Self
from io import StringIO


DIM_X: int = 0
DIM_Y: int = 1


@dataclass
class GridInfo:
  """
  Represent a parsed comment line from a PES XYZ file.
  """
  size_x: int
  size_y: int
  i: int
  j: int
  energy: float


  @staticmethod
  def from_string(line: str) -> Self:
    """
    Parse grid infos from a comment line of a PES XYZ file.
    """
    splits = line.split()
    return GridInfo(
      int(splits[1]),
      int(splits[3]),
      int(splits[5]),
      int(splits[7]),
      float(splits[9])
    )


  def __str__(self) -> str:
    """
    Return the string representation as parsed.
    """
    return f"G: {self.size_x} x {self.size_y} i: {self.i} " \
         + f"j: {self.j} E: {self.energy}"


  def divided_by(self, n: int) -> Self:
    """
    Return a downsampled grid size and indices.
    """
    divided = copy.deepcopy(self)
    divided.size_x = (self.size_x - 1) // n + 1
    divided.size_y = (self.size_y - 1) // n + 1
    divided.i //= n
    divided.j //= n
    return divided


@dataclass
class AtomPosition:
  """
  Represent a line in the configuration of the PES, consisting of the
  atom element and its position in space.
  """
  atom: str
  x: float
  y: float
  z: float


  @staticmethod
  def from_string(line: str) -> Self:
    """
    Parse an AtomPosition from a XYZ configuration line.
    """
    splits = line.split()
    return AtomPosition(splits[0],
                        float(splits[1]),
                        float(splits[2]),
                        float(splits[3]))


  def __str__(self) -> str:
    """
    Serialize AtomPosition to XYZ configuration line.
    """
    return f"{self.atom} {self.x} {self.y} {self.z}"


@dataclass
class GridPoint:
  """
  Grid point on the PES with the energy and the configuration.
  """
  energy: float
  configuration: list[AtomPosition] = field(default_factory=list)


@dataclass
class PESData:
  """
  Full PES parsed from an XYZ file.
  """
  atoms_count: int
  size_x: int
  size_y: int
  grid_points: list[list[GridPoint]]


  @staticmethod
  def from_string(string: str) -> Self:
    """
    Parse a PES string to internal PESData representation.
    """
    lines = string.split("\n")
    atoms_count = int(lines[0])
    first_grid_info = GridInfo.from_string(lines[1])
    size_x = first_grid_info.size_x
    size_y = first_grid_info.size_y

    grid_points: list[list[GridPoint]] = []

    for _x in range(size_x):
      grid_points.append([None] * size_y)

    line_ix: int = 0
    for _i in range(size_x * size_y):
      line_ix += 1 # atom count
      grid_info = GridInfo.from_string(lines[line_ix])
      grid_point = GridPoint(grid_info.energy)
      line_ix += 1

      for _a in range(atoms_count):
        atom_position = AtomPosition.from_string(lines[line_ix])
        grid_point.configuration.append(atom_position)
        line_ix += 1

      grid_points[grid_info.i][grid_info.j] = grid_point

    return PESData(atoms_count, size_x, size_y, grid_points)


  def __str__(self) -> str:
    """
    Write internal PESData to string.
    """
    strio = StringIO()

    for i in range(self.size_x):
      for j in range(self.size_y):
        grid_point = self.grid_points[i][j]
        grid_info = GridInfo(self.size_x, self.size_y, i, j,
                             grid_point.energy)
        strio.write(str(self.atoms_count))
        strio.write("\n")
        strio.write(str(grid_info))
        strio.write("\n")

        for atom_position in grid_point.configuration:
          strio.write(str(atom_position))
          strio.write("\n")

    return strio.getvalue()


  def append(self, other: Self, dimension: int, flip: bool = False) \
      -> None:
    """
    Append to this PES the other one in the X or Y dimension. The
    other PES is flipped along `dimension` if `flip` is True.
    """
    assert dimension in [DIM_X, DIM_Y], "dimension should be 0 or 1"

    if dimension == DIM_X:
      assert self.size_y == other.size_y, "incompatible dimensions"

      for i in range(other.size_x):
        index = -i - 1 if flip else i
        self.grid_points.append(other.grid_points[index])

      self.size_x += other.size_x

    else: # if dimension == DIM_Y:
      assert self.size_x == other.size_x, "incompatible dimensions"

      for i in range(other.size_x):
        # to_add = other.grid_points[i][::-1 if flip else 1]
        to_add = other.grid_points[i]
        if flip:
          to_add = reversed(to_add)
        self.grid_points[i].extend(to_add)

      self.size_y += other.size_y

    assert len(self.grid_points) == self.size_x, "wrong x size"
    assert len(self.grid_points[0]) == self.size_y, "wrong y size"
