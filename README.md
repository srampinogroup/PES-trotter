# PES-trotter

<p align="center">
<img width="1135" height="423" alt="PES-trotter title image" src="https://github.com/user-attachments/assets/a1d88a4a-94e3-4f13-b6d0-714e3b5da181" />
</p>

![GitHub License](https://img.shields.io/github/license/srampinogroup/PES-trotter)

PES-trotter is a mutli-plateform software designed to allow the
exploration of Potential Energy Surfaces (PES). It aims at
facilitating the exploration of the different features of a PES by
allowing 3D navigation, energy profiling, Minimum Energy Path (MEP)
computation and trajectory playback.

A full description of the software is in the open-access article:

Privat E, Rawat AMS, Ballotta B, Polimeno A, Rampino S,
"PES-trotter: A cross-platform open-source application for the analysis of molecular processes on 3D potential-energy landscapes",
*Journal of Computational Chemistry* 47, e70397 (2026),
DOI: https://doi.org/10.1002/jcc.70397

## Online version is live

This is the official repository for the open-source PES-trotter app.
You can test the project via web at this page:

* https://srampinogroup.github.io/PES-trotter

or run from source with the
[Godot editor](https://godotengine.org/download)
v4.6.2-stable or newer.

The user guide is available below. Feel free to open an issue if you
found a bug.

# User guide

[![license: CC BY 4.0](https://img.shields.io/badge/license-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

## Table of contents

- [Quick start](#quick-start)
- [User guide](#user-guide)
   * [Main menu](#main-menu)
      + [Loading the PES](#loading-the-pes)
      + [PES settings tab](#pes-settings-tab)
         - [Surface and atom coordinates](#surface-and-atom-coordinates)
         - [World map](#world-map)
         - [Tiling](#tiling)
         - [Import/export](#importexport)
      + [App settings](#app-settings)
         - [Controls settings](#controls-settings)
         - [Accessibility](#accessibility)
         - [Trajectory playback](#trajectory-playback)
         - [Profile chart](#profile-chart)
         - [Miscellaneous](#miscellaneous)
   * [Exploration](#exploration)
      + [Navigation](#navigation)
      + [Drawing a trajectory](#drawing-a-trajectory)
      + [Computing minimum energy path](#computing-minimum-energy-path)
      + [Playback of the trajectory](#playback-of-the-trajectory)
- [Keyboard and mouse controls](#keyboard-and-mouse-controls)
- [Alternate controls for touch devices](#alternate-controls-for-touch-devices)


# Quick start

Here is how to quickly overview the features of the software.

0. If it is the first time you launch the app, read the disclaimer,
eventually adapt the font size, and go to **File Loading** tab.
1. Load one of the demonstration files available with the drop-down
menu on the right of the first button. See the article for more
details on the available demos.
2. Press **Load demo** to load the PES.

> [!NOTE]
> Loading a demo file will erase previously entered settings
> and replace them by the presets shipped with the demo PES.
> This will not alter non PES-specific settings.

3. After a few seconds of loading, press **Run**. This will also take
a few seconds for bigger PES.
4. Explore and navigate with `WASD` to explore the PES "by foot",
showing in the corner the configuration of the molecule at the point
you are standing.  On touch screen devices you have virtual joystick,
on the left to move and on the right to look around.  All actions are
accessible through the action menu at the bottom of the screen. For
mouse users, you need to press `Enter` or `F12` to toggle mouse capture.
Exhaustive control map for PC is
[at the end of this guide](#keyboard-and-mouse-controls).
5. Use `F` with keyboard, or **Fly mode** in the action menu
at the bottom to have the configuration of the molecule shown at the
point you aim at, like a laser pointer.
6. In the action menu you can use **Draw profile** to draw on the PES
   an energy profile.
7. You can either watch or ride the trajectory you just draw with the
action **Trajectory playback**. Press again to exit this mode.
   * If you are in walk mode, you will ride the trajectory and see
     the configuration updated from your position on the PES.
   * If you are in fly mode, you will see a pointer arrow indicating
     the current PES coordinates corresponding to the displayed
     configuration.
8. The current profile can be saved with `K` or the corresponding
   action **Save profile**, and similarly loaded with `L` or **Load
   profile** action.
9. You can display points of interest, that is critical points
(maxima, minima and saddle points). For that:
   1. Toggle anchors visibility in the menu with **Show critical
   points**.
   2. You can press the newly displayed anchors to teleport to them
   and see the specific configuration at this point.
10. There is an A* estimate of a minimum energy path (MEP)
available. With this feature, you can compute the minimum energy path
a complex would take during e.g. a reaction.
    1. First, enable the user interface to select the start and final
    points of the MEP with the action **Compute MEP**.
    2. Click/tap on the surface where you want the MEP to start from.
    3. Click/tap on the surface where you want the path to end.
    4. You have now the MEP in green. You can toggle its visibility
    with the **Show minimum energy path (MEP)** option.
    5. Convert the MEP to an energy profile with the action **MEP to
    profile**. You can now use the trajectory features on this path.
11. Alternatively, you can compute the steepest-descent path with
    the **Compute SD** action.

# User guide

We use the term "native" when the project is launched from Godot,
being on desktop or mobile (android only).  We will refer to the
"web" version when the project is accessed by browser, being from
desktop or mobile.  We say "desktop" for mouse and keyboard controls,
and "touch device" for phones and tablets independant of whereas the
app is being accessed by browser or natively.  Everything should be
equivalent for native PC, native mobile, web PC and web mobile.

> [!WARNING]
> Right now the web exported app does not work correctly
> on Safari because of mouse capture issues. Please use another
> browser on macOS.

## Main menu

You arrive first on the disclaimer page. You can then go to the main
menu by selecting the **File loading** tab on top.  This is the tab
where you load the PES. The screenshot below shows both native and
web UI elements, but you should only see half of those when you run
the project depending on if you use the native or web version.

<p align="center">
<img width="718" height="264" alt="main-menu" src="https://github.com/user-attachments/assets/283438fd-2faf-4f38-a104-97672f616330" />
</p>

1. The tab bar allowing you to access different menus.
2. Demo PES selector. Here you can find demo PESs shipped with the
application. Once you have selected a PES, you can use (4) to load
it.
3. Load the selected demo PES. Fast-forward: you can then press Run
(6) right after the load is finished and go the
[Exploration](#exploration) section.
4. Open a PES file from your computer/phone. On the web version this
   is an upload button.
5. Non interactive progress bar and log console.
6. Run the loaded PES. You will not be able to press the button if no
PES is loaded so if you can click it is safe to do so.

### Loading the PES

Depending on the plateform you can either load from disk, load from
URL, or upload as explained above. In any case, we'll use the demo
for now on.  With (2) select a demo and click (3) to load it. After a
few seconds, the Run (6) button should be enabled.  If you want you
dive straight into navigation, skip the next section.

Format specifications are detailed in the dedicated document [here](files-specifications.md).

### PES settings tab

The PES settings tab can be accessed from the top tab bar (1). They
are organized in sections.

<p align="center">
<img width="968" height="1056" alt="settings-full" src="https://github.com/user-attachments/assets/06483a17-c859-47d4-b833-b3b407673826" />
</p>

#### Surface and atom coordinates

This section allows you to name the parameters of the PES. By default
they are called `x` and `y` for the two coordinates of the file.  You
can also specify the range of these parameters so the correct value
is displayed when exploring. This is also used by the tiling feature
if you use it.
You can also clamp the PES in the height dimension, for example to
cut very high peaks or deep wells from the rendering. To do that, put
a maximum and/or a minimum value for the energy.
Finally you can specify the units used in the PES XYZ file. They are
normally angstroms. It only affects the rendering of the molecule.

#### World map

This section contains the in-world scaling factors of the PES so you
can change the world size. ISO lines can be displayed and their
spacing specified.

The A* weight function setting is a bit more complicated: it gives
you the possibility of choosing how Godot will convert energies to
the path finding A* algorithm's weights. This defines the "traversal
hardness" of the terrain as a function of the energy.  You should
write it as a function of `E`, that is the energy minus the minimum
energy so that the minimum is at `E = 0`.

Next you have the minimap, on which you can click to select the
landing position when running the exploration.  On it will also be
displayed the extrema and saddle points that you can hide or show
with the check button next to the **Recompute** button. You can set
the threshold to eliminate false positive or duplicated detected
points, e.g. on flat surfaces.

#### Tiling

These settings allow you to inform PES-trotter that the provided PES
is actually tiled. It does not tile it for you. To do that, see the
[dedicated script](tools/xyz_tile_pes.py).

#### Import/export

FInally, you can load or save these settings from and to a `.ini`
file. Demos are shipped with their own `.ini`, and PES-trotter will
load any `.ini` file sharing the same path and name as the loaded
`.pes`.

### App settings

#### Controls settings

Here you have miscellaneous settings regarding controls. On touch
devices, do not deactivate joysticks unless you have external
controls plugged-in or you will be unable to navigate.

#### Accessibility

You can swap and rotate the hue of the whole app to help with
protanopia or deuteranopia, as well as scale the whole UI.

#### Trajectory playback

This allows you to set the time it takes to play a trajectory or a
ride on the energy profile (see profiling below).  You can also allow
for the playback to loop back to initial position once it reaches the
end or bounce back.

#### Profile chart

This sets the number of points used during energy profile drawing and
trajectory resampling.

#### Miscellaneous

Allows selective UI tweaks for sound and color bars display.
The **show bonds** option reduce the size of the atomic balls and
display a varying-in-size cylinder to represent bonds. It should not
be used for big molecules, as the visiblity and performance will be
greatly affected.

## Exploration

Once you press the **Run**/**Resume** button, after a little scene
loading time, you will land on the PES. Every keyboard actions I'll
mention will also be actionable from the Actions menu at the bottom
of the screen.

### Navigation

The initial control scheme will be in walk mode. That is you can move
like in a FPS video game with `WASD`, sprint with `Shift` and jump
with `Space`. You can toggle fly mode with `F`, and control vertical
movements with `Space` and `Ctrl`. On phone, you can use the left
joystick to move and the right one to look.  You can then fly up by
looking up and going forwards, or by looking down and going
backwards.

### Drawing a trajectory

For drawing a trajectory by hand we recommend activating fly mode
(`F`) to take a view from the top. Toggle the profiling mode and draw
onto the PES. Toggle the profiling mode again to leave drawing mode.

### Computing minimum energy paths

Again we recommend taking some distance in fly mode. Toggle the
minimum energy path (MEP) (`O`). Click to set the starting point,
click again on the end point.
You can now create a trajectory from the MEP by selecting the
corresponding action in the menu.
The same steps can be used with the steepest-descent method.

### Playback of the trajectory

Any profile can be played, either in "ride mode", that is you will
automatically walk alongside the trajectory if in walk mode, or in
"spectator mode", if you are in fly mode. A red arrow will be
displayed following the trajectory. This mode can be activated with
`T`.

If the trajectory is loaded from a file however, the configuration
will follow the one in the file and will not be the minimum
configuration pre-computed with the PES. This will be made obvious by
the display of the file name under the molecule and a change of the
color of the support.


# Keyboard and mouse controls

Keys are given by position on US qwerty keyboard, but is is keyboard
agnostic.  That means that `WASD` on an azerty keyboard will actually
be `ZQSD`.  `LMB`, `MMB`, `RMB`, `MBn` are respectively left, right,
middle and n-th mouse button.  `Wheel` is mouse wheel or touchpad
scroll.

key              | mode         | description
-----------------|--------------|------------
`W`              |              | move forwards
`S`              |              | move backwards
`A`              |              | strafe left
`D`              |              | strafe right
`Mouse move`     |              | look around
`↑`              |              | look up
`↓`              |              | look down
`←`              |              | look left
`→`              |              | look right
`Space`          |              | jump
`Shift`          |              | speed up all movements
`Enter`/`F12`    |              | toggle mouse capture (prefer `Enter` on web on laptop)
`F`              |              | toggle fly mode
`Space`          | fly          | fly up
`Ctrl`           | fly          | fly down
`A`              |              | rotate molecule anti-clockwise
`E`              |              | rotate molecule clockwise
`+`              |              | on all axes, scale map up (PC only)
`-`              |              | on all axes, scale map down (PC only)
`LMB`            | on molecule  | drag to rotate molecule
`Wheel`          |              | zoom of the molecule
`P`              |              | toggle profiling and mouse capture
`LMB`            | profiling    | drag to draw profile
`RMB`            | profiling    | erase profile
`K`              |              | save profile to file
`L`              |              | load profile from file
`O`              |              | toggle minimum energy path mode and mouse capture
`T`              |              | toggle trajectory playback
`U`              |              | slow down trajectory playback
`I`              |              | speed up trajectory playback
`LMB`            | minimum path | select first point, then select second point
`ESC`            |              | open menu, resume from menu
`Ctrl+F`         |              | force instant quit (safe)

# Alternate controls for touch devices

Touch devices are straightforward since you have twin-sticks like
controls with the virtual joysticks. The only difference is that in walk mode
you have to double tap your screen to jump, and in fly mode aim for the
sky/ground and go forward to fly up/down respectively. Every other action
have a UI touch equivalent in the **actions** menu.

# Cite this software

You can use the following bibtex to cite PES-trotter:
```bibtex
@article{https://doi.org/10.1002/jcc.70397,
author = {Privat, Erwan and Rawat, Ajay Mohan Singh and Ballotta, Bernardo and Polimeno, Antonino and Rampino, Sergio},
title = {PES-trotter: A Cross-Platform Open-Source Application for the Analysis of Molecular Processes on 3D Potential-Energy Landscapes},
journal = {Journal of Computational Chemistry},
volume = {47},
number = {14},
pages = {e70397},
keywords = {chemical education, conformational analysis, minimum energy path, potential energy surface, reaction dynamics},
doi = {https://doi.org/10.1002/jcc.70397},
url = {https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.70397},
eprint = {https://onlinelibrary.wiley.com/doi/pdf/10.1002/jcc.70397},
note = {e70397 5824200},
year = {2026}
}
```
