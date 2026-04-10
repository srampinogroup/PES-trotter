#!/usr/bin/env python3
"""Plot PES from both dat file and generated xyz."""

import pandas as pd
import matplotlib.pyplot as plt


def read_pes_from_dat(path: str) -> pd.DataFrame:
  df = pd.read_csv(path, sep=r"\s+")
  # df[XYZ] = df[XYZ].astype(float)
  return df


def read_pes_from_xyz(path: str) -> pd.DataFrame:
  buffer: list[str] = []

  with open(path, "r", encoding="us-ascii") as f:
    for line in f:
      if line[0] == "G":
        buffer += [line.split()]

  gs_norm = 360 / float(buffer[0][1])

  df = pd.DataFrame()

  for i, row in enumerate(buffer):
    df.at[i, "X"] = float(row[5]) * gs_norm
    df.at[i, "Y"] = float(row[7]) * gs_norm
    df.at[i, "Z"] = float(row[9])

  return df


def main() -> None:
  df_dat = read_pes_from_dat("Glycine_param_BB/de.tsv")
  df_xyz = read_pes_from_xyz("glycine.xyz")

  for ti, df in [("DAT file", df_dat), ("XYZ file", df_xyz)]:
    fig, ax = plt.subplots(subplot_kw={"projection": "3d"})
    ax.plot_trisurf(df["X"], df["Y"], df["Z"], cmap="viridis")
    ax.azim = 150
    plt.xlabel("SC1")
    plt.ylabel("SC2")
    plt.clabel("E")
    plt.title(ti)
    plt.tight_layout()

  plt.show()


if __name__ == "__main__":
  main()
