# Gaussian to XYZ

This program allows to extract from a Gaussian 12 output log the
potential-energy surface information and store it in a XYZ file with
specifications specified below.

It can be used to generate AVATAR[^avatar] and
[PES-trotter](https://github.com/srampinogroup/PES-trotter)[^pes-trotter]
compatible surfaces.

[^avatar]: Martino M, Salvadori A, Lazzari F, et al. Chemical promenades: Exploring potential-energy surfaces with immersive virtual reality. J Comput Chem. 2020;41:1310–1323. https://doi.org/10.1002/jcc.26172
[^pes-trotter]: ***TODO

## Files

* `gaussian_to_xyz.py`: main script. Usage:
```bash
./gaussian_to_xyz.py input.log output.xyz
```
* `test_gaussian_to_xyz.py`: tests for above script functions.
* `plot_pes.py`: utility script to plot a PES in XYZ format.


## Specifications

Potential energy surfaces are defined with the [XYZ
format](https://en.wikipedia.org/wiki/XYZ_file_format), more
precisely an "animated" XYZ where each frame is a point on a grid
defined by the comment line. Note that each space represents any
number of blank (space or tab) characters, and each new line exactly
one line break.

```html
<number-of-atoms N>
G: <grid width> x <grid height> i: <point index.i> j: <point index.j> E: <point energy>
<atom0 element.symbol> <atom0 position.x> <atom0 position.y> <atom0 position.z>
<atom1 element.symbol> <atom1 position.x> <atom1 position.y> <atom1 position.z>
[...]
<atomN-1 element.symbol> <atomN-1 position.x> <atomN-1 position.y> <atomN-1 position.z>
```
This block is repeated ``<grid width> x <grid height>`` times with
``i`` and ``j`` setting the point position on the grid.
