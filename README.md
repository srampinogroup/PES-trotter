# PES-demo

![GitHub License](https://img.shields.io/github/license/srampinogroup/PES-demo)

<p align="center"><img width="700" alt="image" src="https://github.com/user-attachments/assets/3a64c898-122e-4315-874c-7933e05a3537" /></p>

## Beta version is now live

This is the official repository for the beta version of the open-source PES-demo app. The full source code will be available soon. In the meantime, you can test the project via web at this page:

* https://erwan-privat.fr/pes-demo/mesh-reader.html

The user guide is available below. Feel free to open an issue if you found a bug.

# User guide

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

> [!TIP]
> This guide is a work in progress and is frequently updated.

## Table of contents

- [Quick start](#quick-start)
- [User guide](#user-guide)
  * [Main menu](#main-menu)
    + [Loading the PES](#loading-the-pes)
    + [Settings tab](#settings-tab)
      - [Surface coordinates](#surface-coordinates)
      - [World map](#world-map)
      - [Trajectory playback](#trajectory-playback)
      - [Controls settings](#controls-settings)
  * [Exploration](#exploration)
    + [Navigation](#navigation)
    + [Drawing a trajectory](#drawing-a-trajectory)
    + [Computing minimum energy path](#computing-minimum-energy-path)
- [Keyboard and mouse controls](#keyboard-and-mouse-controls)

# Quick start

> [!NOTE]
> TODO this will be a quick start tutorial without the details of every features.

# User guide

> [!NOTE]
> TODO this will be a complete feature description.

I will use the term "native" when the project is launched from Godot, being on desktop or mobile (android only).
I will refer to the "web" version when the project is accessed by browser, being from desktop or mobile browser.
I will say "desktop" for mouse and keyboard controls, and "touch device" for phones and tablets independant of whereas the app is being accessed by browser or natively.
Everything should be equivalent for native PC, native mobile, web PC and web mobile, but bugs might prove me wrong.

> [!WARNING]
> Right now the app does not work correctly on web export on macOS because of mouse capture issues. You can still run the app from source within the Godot editor.

## Main menu

You arrive first on the disclaimer page. You can then go to the main menu by selecting the "File loading" tab on top.
This is the tab where you load the PES. The screenshot below shows both native and web UI elements, but you should only
see half of those when you run the project depending on if you use the native or web version.

<img width="807" height="540" alt="image" src="https://github.com/user-attachments/assets/c82dd044-5994-487e-bc55-e460f319f90c" />

Here are the interacting elements:

1. The main tab of the main menu.
2. The settings tab (described below).
3. Demo PES selector. Here you can find demo PESs shipped with the application. Once you have selected a PES, you can use (4) to load it.
4. Load the selected demo PES. Fast-forward: you can then press Run (9) right after the load is finished and go the [Exploration](#exploration) section.
5. Open a PES file from your computer/phone. Only works in native version.
6. Load from a URL. Work on any platform.
7. Load from clipboard (as if you did `Ctrl+V`/`Cmd+V`). This is not a stable feature, ff the file is too big it might crash the app.
8. Upload from your device (web only).
9. Run the loaded PES. You will not be able to press the button if no PES is loaded so if you can click it is safe to do so.

Not interactive elements include:

* a. Progress bar. Not working on web at the moment.
* b. Console.

### Loading the PES

Depending on the plateform you can either load from disk, load from URL, or upload as explained above. In any case, we'll use the demo for now one.
With (3) select the `rrx_c2hp.pes` demo and click (4) to load the demo. After a few seconds (the progress bar is not working on web right now),
the Run (9) button should be enabled. If you want you dive straight into navigation, skip the next section.

### Settings tab

The settings tab can be accessed from the top tab bar (2).

TODO screenshot

#### Surface coordinates

This section allows you to name the parameters of the PES. By default they are called `x` and `y` for the two coordinates of the file.
You can also specify the range of these parameters so the correct value is displayed when exploring.

#### World map

This section contains the in-world scaling factors of the PES so you can change the world size.
You can also clip the PES by setting custom minimum and maximum energies to be considered when rendering.

The A* weight function setting is a bit more complicated: it gives you the possibility of choosing how Godot will
convert energies to the path finding A* algorithm's weights. This defines the "traversal hardness" of the terrain as a function of the energy.
You should write it as a function of `E`, that is the energy minus the minimum energy so that the minimum is at `E = 0`.

Next you have a sort of minimap, on which you can click to select the landing position when running the exploration.
On it will also be displayed the extrema and saddle points if you compute them with the button below.
Note that you can play with the threshold to eliminate false positive detected points on flat surface.
You have to press the button to have the points displayed in exploration mode.

#### Trajectory playback

This allows you to set the time it takes to play a trajectory or a ride on the energy profile (see profiling below).
You can also allow for the playback to loop back to initial position once it reaches the end.

#### Controls settings

Here you have miscellaneous settings regarding controls. On touch devices, do not deactivate joysticks or you will be unable to navigate.

## Exploration

Once you press the Run/Resume button, after a little scene loading time, you will land on the PES. The initial control scheme will be
in walk mode. That is you can move like in a FPS video game with `WASD`, sprint with `Shift` and jump with `Space`. You can toggle
fly mode with `F11`, and control vertical movements with `Space` and `Ctrl`.

### Navigation

Work in progress

### Drawing a trajectory

Work in progress

### Computing minimum energy path

Work in progress

# Keyboard and mouse controls

Keys are given by position on US qwerty keyboard, but is is keyboard agnostic.
That means that `WASD` on an azerty keyboard will actually be `ZQSD`.
`LMB`, `MMB`, `RMB`, `MBn` are respectively left, right, middle and n-th mouse button.
`Wheel` is mouse wheel or touchpad scroll.

key       | mode         | description
----------|--------------|------------
`W`       |              | move forwards
`S`       |              | move backwards
`A`       |              | straff left
`D`       |              | straff right
`Space`   |              | jump
`Shift`   |              | accelerate all movements
`F12`     |              | toggle mouse capture (buggy on web)
`F11`     |              | toggle fly mode
`Space`   | fly          | fly up
`Ctrl`    | fly          | fly down
`A`       |              | rotate molecule anti-clockwise
`E`       |              | rotate molecule clockwise
`LMB`     | on molecule  | drag to rotate molecule
`RMB`     |              | drag to rotate molecule (still working?)
`Alt+LMB` |              | drag to rotate molecule (still working?)
`Wheel`   |              | zoom of the molecule
`F10`     |              | toggle profiling and mouse capture
`LMB`     | profiling    | drag to draw profile
`RMB`     | profiling    | erase profile
`K`       |              | save profile to file
`L`       |              | load profile from file
`ESC`     |              | open menu, resume from menu
`F9`      |              | toggle minimum energy path mode and mouse capture
`LMB`     | minimum path | select first point, then select second point
