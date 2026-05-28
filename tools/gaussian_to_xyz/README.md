# Gaussian to XYZ

This program allows to extract from a Gaussian 12 output log a square
potential-energy surface information and store it in a XYZ file with
specifications specified [here](https://github.com/srampinogroup/PES-trotter/blob/main/files-specifications.md).

It can be used to generate AVATAR[^avatar] and
PES-trotter[^pes-trotter]
compatible surfaces.

[^avatar]: Martino M, Salvadori A, Lazzari F, et al. "Chemical promenades: Exploring potential-energy surfaces with immersive virtual reality". _J Comput Chem_. 2020;41:1310–1323. https://doi.org/10.1002/jcc.26172
[^pes-trotter]: Privat E, Rawat AMS, Ballotta B, Polimeno A, Rampino S, "PES-trotter: A Cross-Platform Open-Source Application for the Analysis of Molecular Processes on 3D Potential-Energy Landscapes", _Journal of Computational Chemistry_ 47, e70397 (2026). https://doi.org/10.1002/jcc.70397

## Files

* `gaussian_to_xyz.py`: main script. Usage:
```bash
./gaussian_to_xyz.py input.log output.xyz
```
* `test_gaussian_to_xyz.py`: tests for above script functions.
* `plot_pes.py`: utility script to plot a PES in XYZ format.

## Specifications

Files specifications can be found here:
https://github.com/srampinogroup/PES-trotter/blob/main/files-specifications.md
