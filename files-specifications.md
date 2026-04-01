# Potential energy surface

Potential energy surfaces (PES) are defined with the [XYZ format](https://en.wikipedia.org/wiki/XYZ_file_format),
more precisely an "animated" XYZ where each frame is a point on a grid defined by the comment line.
Note that each space represents any number of blank (space or tab) characters, and each new line exactly one line break.

## Specifications

```html
<number-of-atoms N>
G: <grid width> x <grid height> i: <point index.i> j: <point index.j> E: <point energy>
<atom0 element.symbol> <atom0 position.x> <atom0 position.y> <atom0 position.z>
<atom1 element.symbol> <atom1 position.x> <atom1 position.y> <atom1 position.z>
[...]
<atomN-1 element.symbol> <atomN-1 position.x> <atomN-1 position.y> <atomN-1 position.z>
```
This block is repeated ``<grid width> x <grid height>`` times with ``i`` and ``j`` setting the point position on the grid.

For samples, see the [demo pes directory](tests-src/mesh-reader/demo_pes).

# Trajectories on PES

Trajectories also uses the animated XYZ file format. Here, each frame of the animation is a point on the PES.
The whole configuration is exported as well for the file to be useful in other chemical software.
This is however not needed for loading the trajectory.

## Specifications

The trajectory is saved according the the following specifications:
```html
<number-of-atoms N>
total: <number-of-points M> i: <point index> x: <PES-grid x> y: <PES-grid y> E: <point energy>
<atom0 element.symbol> <atom0 position.x> <atom0 position.y> <atom0 position.z>
<atom1 element.symbol> <atom1 position.x> <atom1 position.y> <atom1 position.z>
[...]
<atomN-1 element.symbol> <atomN-1 position.x> <atomN-1 position.y> <atomN-1 position.z>
```
This block is repeated ``M`` times with ``<point index>`` incremented each time.

When loading a trajectory, the configuration is read and the application will show that the configuration is taken
from the loaded file, but not the energy which is taken from the PES. So when generating the file or exporting from
another software, you can set the energy to zero.
