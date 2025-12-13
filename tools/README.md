# PES-trotter tools

These python scripts are used to manipulate XYZ potential energy surfaces (PESs). Make sure the files are executable and that you have python3 installed (we used python 3.13.9).

## xyz_generate_test_pes

This allows to generate a dummy PES with size x by y and energies incrementing for each grid point.
For a 2x3 grid:
```bash
./xyz_generate_test_pes.py 2 3 >test.pes
```

## xyz_downsample_pes

This divides the number of grid points in each dimension by the provided parameter by taking one point and skipping n - 1. Default n is 2.
Usage:
```bash
./xyz_downsample_pes.py [<n>] <in.pes >out.pes
```

## xyz_tile_pes

<img width="1302" height="579" alt="image" src="https://github.com/user-attachments/assets/b455ae42-4121-4bee-b232-4899405334dd" />

This allows tiling of a periodic PES. Flip is not yet supported for symmetric half-PESs.
Example use of 3x2 tiling:
```bash
./xyz_tile_pes.py -x3 -y2 <example.pes >tiled.pes
```

If we denote the whole PES with `#`, the file tiled.pes would be equivalent to
```
###
###
```
