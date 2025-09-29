# PES-trotter


<p align="center">
 <img width="1135" height="423" alt="image" src="https://github.com/user-attachments/assets/32355cce-61df-4fb0-9f72-f0729553ba37" />
</p>

----------------

![GitHub License](https://img.shields.io/github/license/srampinogroup/PES-trotter)


## Beta version is now live

This is the official repository for the beta version of the
open-source PES-demo app. The full source code will be available
soon. In the meantime, you can test the project via web at this page:

* https://srampinogroup.github.io/PES-trotter

The user guide is available below. Feel free to open an issue if you
found a bug.

# User guide

[![License: CC BY
4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

> [!NOTE]
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

Here is how to quickly overview the features of the software.

0. If it is the first time you launch the app, read the disclaimer
and go to **File Loading** tab.
1. Load one of the demo files available with the drop-down menu on
the right of the first button.
   * The glycine one will quickly load but is really small and uses
     internal degrees of freedom as coordinates.
   * If unsure, use the `rrx_c2hp` or `lih2p_rrp_coords` PESs who
     demonstrates reactive scattering with three atoms.
   * The `test_*` ones are for debugging purpose and do not represent
     any meaningful physical process.
2. Press **Load demo** to load the PES.

> [!WARNING]
> For now, loading a demo file will erase previously entered settings
> and replace them by the settings shipped with the demo PES.

3. After a few seconds of loading, press **Run**. This will also take
a few seconds for bigger PES.
4. Explore and navigate with `WASD` to explore the PES "by foot",
showing in the corner the configuration of the molecule at the point
you are standing.  On touch screen devices you have virtual joystick,
on the left to move and on the right to look around.  All actions are
accessible through the action menu at the bottom of the screen. For
mouse users, you need to press `F12` to toggle mouse capture.
Exhaustive control map for PC is [at the end of this
guide](#keyboard-and-mouse-controls).
6. Use `F11` with keyboard, or **Toggle fly mode** in the action menu
at the bottom to have the configuration of the molecule shown at the
point you aim at, like a laser pointer.
7. In the action menu you can use **Activate drawing profile** to
draw on the PES an energy profile.
8. You can either watch or ride the trajectory you just draw with the
action **Toggle trajectory ride**. Press again to exit this mode.
   * If you are in walk mode, you will ride the trajectory and see
     the configuration updated from your position on the PES.
   * If you are in fly mode, you will see a pointer arrow indicating
     the current PES coordinates corresponding to the displayed
     configuration.
9. The current profile can be saved with `K` or the corresponding
   action **Save profile**, and similarly loaded with `L` or **Load
   profile** action.
9. You can display points of interest, that is critical points
(maxima, minima and saddle points). For that:
   1. Go to the main menu with `ESC` or from the action menu.
   2. In the **Settings** tab, press **Compute critical points** under
   the minimap.
   3. Press **Resume** to go back to the PES map.
   4. You can press the newly displayed "anchors" to teleport to them
   and see the specific configuration at this point.
   5. In the action menu there is a visibility toggle for these
   points, it is called **Show/hide anchors**.
10. Finally there is a rough estimate of a minimum energy path (MEP)
available. That, you can compute the minimum energy path a complex
would take during e.g. a reaction.
    1. First, enable the user interface to select the start and final
    points of the MEP with the action **Compute MEP**.
    2. Click/tap on the surface where you want the MEP to start from.
    3. Click/tap on the surface where you want the path to end.
    4. You have now the MEP in green. You can toggle its visibility
    with the **Show/hide minimum energy path (MEP)** option.
    5. Optionnally, you can create an energy profile from this MEP
    with the action **MEP to profile**. That way, you can use point 7.
    on the MEP.
11. Enjoy!
   

# User guide

I will use the term "native" when the project is launched from Godot,
being on desktop or mobile (android only).  I will refer to the "web"
version when the project is accessed by browser, being from desktop
or mobile browser.  I will say "desktop" for mouse and keyboard
controls, and "touch device" for phones and tablets independant of
whereas the app is being accessed by browser or natively.  Everything
should be equivalent for native PC, native mobile, web PC and web
mobile, but bugs might prove me wrong.

> [!WARNING]
> Right now the web exported app does not work correctly
> on Safari because of mouse capture issues. Please use another
> browser.


## Main menu

You arrive first on the disclaimer page. You can then go to the main
menu by selecting the **File loading** tab on top.  This is the tab
where you load the PES. The screenshot below shows both native and
web UI elements, but you should only see half of those when you run
the project depending on if you use the native or web version.

<img width="807" height="540" alt="image"
src="https://github.com/user-attachments/assets/c82dd044-5994-487e-bc55-e460f319f90c"
/>

Here are the interacting elements:

1. The main tab of the main menu.
2. The settings tab (described below).
3. Demo PES selector. Here you can find demo PESs shipped with the
application. Once you have selected a PES, you can use (4) to load
it.
4. Load the selected demo PES. Fast-forward: you can then press Run
(9) right after the load is finished and go the
[Exploration](#exploration) section.
5. Open a PES file from your computer/phone. Only works in native
version.
6. Load from a URL. Work on any platform.
7. Load from clipboard (as if you did `Ctrl+V`/`Cmd+V`). This is not
a stable feature, ff the file is too big it might crash the app.
8. Upload from your device (web only).
9. Run the loaded PES. You will not be able to press the button if no
PES is loaded so if you can click it is safe to do so.

Not interactive elements include:

* a. Progress bar. Not working on web at the moment.
* b. Console.

### Loading the PES

Depending on the plateform you can either load from disk, load from
URL, or upload as explained above. In any case, we'll use the demo
for now one.  With (3) select the `rrx_c2hp.pes` demo and click (4)
    to load the demo. After a few seconds (the progress bar is not
    working on web right now), the Run (9) button should be enabled.
    If you want you dive straight into navigation, skip the next
    section.

### Settings tab

The settings tab can be accessed from the top tab bar (2).

TODO screenshot

#### Surface coordinates

This section allows you to name the parameters of the PES. By default
they are called `x` and `y` for the two coordinates of the file.  You
can also specify the range of these parameters so the correct value
is displayed when exploring.

#### World map

This section contains the in-world scaling factors of the PES so you
can change the world size.  You can also clip the PES by setting
custom minimum and maximum energies to be considered when rendering.

The A* weight function setting is a bit more complicated: it gives
you the possibility of choosing how Godot will convert energies to
the path finding A* algorithm's weights. This defines the "traversal
hardness" of the terrain as a function of the energy.  You should
write it as a function of `E`, that is the energy minus the minimum
energy so that the minimum is at `E = 0`.

Next you have a sort of minimap, on which you can click to select the
landing position when running the exploration.  On it will also be
displayed the extrema and saddle points if you compute them with the
button below.  Note that you can play with the threshold to eliminate
false positive detected points on flat surface.  You have to press
the button to have the points displayed in exploration mode.

#### Trajectory playback

This allows you to set the time it takes to play a trajectory or a
ride on the energy profile (see profiling below).  You can also allow
for the playback to loop back to initial position once it reaches the
    end.

#### Controls settings

Here you have miscellaneous settings regarding controls. On touch
devices, do not deactivate joysticks or you will be unable to
navigate.

## Exploration

Once you press the Run/Resume button, after a little scene loading
time, you will land on the PES. Every keyboard actions I'll mention
will also be actionable from the Actions menu at the bottom of the
screen.

### Navigation

The initial control scheme will be in walk mode. That is you can move
like in a FPS video game with `WASD`, sprint with `Shift` and jump
with `Space`. You can toggle fly mode with `F11`, and control
vertical movements with `Space` and `Ctrl`. On phone, you can use the
left joystick to move and the right one to look.  You can then fly up
by looking up and going forwards, or by looking down and going
backwards.

### Drawing a trajectory

For drawing a trajectory by hand I recommand activating fly mode
(`F11`) to take a view from the top. Toggle the profiling mode
and draw onto the PES. Toggle the profiling mode again to leave
drawing mode.

> [!NOTE]
> Work in progress

### Computing minimum energy path

Again I recommend taking some distance in fly mode. Toggle the
minimum energy path (MEP) with `F9`. Click to set the starting point,
click again on the end point.  Press `F9` again to leave the mode.
You can now create a trajectory from the MEP by selecting the
corresponding action in the menu.

Work in progress

# Keyboard and mouse controls

Keys are given by position on US qwerty keyboard, but is is keyboard
agnostic.  That means that `WASD` on an azerty keyboard will actually
be `ZQSD`.  `LMB`, `MMB`, `RMB`, `MBn` are respectively left, right,
middle and n-th mouse button.  `Wheel` is mouse wheel or touchpad
scroll.

key         | mode         | description
------------|--------------|------------
`W`         |              | move forwards
`S`         |              | move backwards
`A`         |              | straff left
`D`         |              | straff right
`Space`     |              | jump
`Shift`     |              | accelerate all movements
`F12`       |              | toggle mouse capture (buggy on web)
`F11`       |              | toggle fly mode
`Space`     | fly          | fly up
`Ctrl`      | fly          | fly down
`A`         |              | rotate molecule anti-clockwise
`E`         |              | rotate molecule clockwise
`+`         |              | on all axes, scale map up (PC only)
`-`         |              | on all axes, scale map down (PC only)
`LMB`       | on molecule  | drag to rotate molecule
`RMB`       |              | drag to rotate molecule (still working?)
`Alt+LMB`   |              | drag to rotate molecule (still working?)
`Wheel`     |              | zoom of the molecule
`F10`       |              | toggle profiling and mouse capture
`LMB`       | profiling    | drag to draw profile
`RMB`       | profiling    | erase profile
`K`         |              | save profile to file
`L`         |              | load profile from file
`ESC`       |              | open menu, resume from menu
`F9`        |              | toggle minimum energy path mode and mouse capture
`LMB`       | minimum path | select first point, then select second point

# Alternate controls for touch devices

Touch devices are straightforward since you have twin-sticks like
controls with the virtual joysticks. The only difference is that in walk mode
you have to double tap your screen to jump, and in fly mode aim for the
sky/ground and go forward to fly up/down respectively. Every other action
should have an UI touch equivalent in the **actions** menu.
