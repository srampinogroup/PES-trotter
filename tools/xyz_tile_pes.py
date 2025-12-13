#!/usr/bin/env python3
"""
Repeat the whole PES on specified axes. Parses the whole PES in
memory.
Usage:
  Simple copy:
  ./xyz_tile_pes.py -x1 -y1 <in.pes >out.pes

  Tile on X such that # becomes
  ###
  ./xyz_tile_pes.py -x3 -y1 <in.pes >out.pes

  Tile on Y such that # becomes
  #
  #
  ./xyz_tile_pes.py -x1 -y2 <in.pes >out.pes

  Tile on X and Y such that # becomes
  ####
  ####
  ####
  ./xyz_tile_pes.py -x4 -y3 <in.pes >out.pes

  Tile on X and Y such that R becomes
  RR
  ʁʁ
  RR
  ./xyz_tile_pes.py -x2 -y3 --flip-y <in.pes >out.pes

  Tile on X and Y such that R becomes
  RЯR
  ʁꓤʁ
  RЯR
  ./xyz_tile_pes.py -x2 -y3 --flip-xy <in.pes >out.pes
"""
import sys
import copy
from argparse import ArgumentParser, Namespace
from typing import TextIO
from xyz_dataclasses import PESData
from xyz_dataclasses import DIM_X, DIM_Y


def tile_on_dimension(pes: PESData, dim: int, times: int,
                      flip: bool) -> PESData:
  """
  Tile the inputed PES on the one dimension specified. Every other
  concatenation is flipped if `flip` is True.
  """
  assert dim in [DIM_X, DIM_Y]
  tiled = copy.deepcopy(pes)
  for i in range(times - 1):
    tiled.append(pes, dim, flip and i % 2 == 0)
  return tiled


def tile_pes(pes: PESData,
             tile_x: int, tile_y: int,
             flip_x: bool, flip_y: bool) -> PESData:
  """
  Tile the PES on both dimension according to the number of tiles
  provided.
  """
  # Keep Y before X because of how the internal representation of the
  # PES is stored.
  pes = tile_on_dimension(pes, DIM_Y, tile_y, flip_y)
  pes = tile_on_dimension(pes, DIM_X, tile_x, flip_x)
  return pes


def process_pes(f_in: TextIO, f_out: TextIO, args: Namespace) \
      -> None:
  """
  Handle IO and call tile_pes.
  """
  tile_x = args.x
  tile_y = args.y
  flip_x = args.flip_x or args.flip_xy
  flip_y = args.flip_y or args.flip_xy
  pes = PESData.from_string(f_in.read())
  tiled_pes = tile_pes(pes, tile_x, tile_y, flip_x, flip_y)
  f_out.write(str(tiled_pes))


def main() -> None:
  """
  Entry point. Parse arguments.
  """
  parser = ArgumentParser(description="Repeat the whole PES on "
                                      "specified axes.")
  parser.add_argument("-x", type=int, required=True,
                      help="number of tiles on the X axis")
  parser.add_argument("-y", type=int, required=True,
                      help="number of tiles on the Y axis")
  parser.add_argument("--flip-x",
                      help="flip every other X copies",
                      action="store_true")
  parser.add_argument("--flip-y",
                      help="flip every other Y copies",
                      action="store_true")
  parser.add_argument("--flip-xy",
                      help="flip every other X and Y copies",
                      action="store_true")

  args = parser.parse_args()
  process_pes(sys.stdin, sys.stdout, args)


if __name__ == "__main__":
  main()
