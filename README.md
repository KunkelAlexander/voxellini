# Voxellini

This repository documents the development of *Voxellini*, a **voxel terrain editor** built in **Godot 4**, using **Marching Cubes** for smooth surface extraction. Try it out here: https://kunkelalexander.github.io/voxellini/ (Chrome is recommended for the best experience).

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-20 16-42-59.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-20 16-42-59.png" width="800">
  </a>
</p>


## Overview

The project explores:

* interactive Marching Cubes terrain
* surface-based sculpting tools
* material painting using vertex colors

## Development Log

### 1. First Marching Cubes Output

Initial implementation of Marching Cubes. The focus was on understanding the algorithm which clearly was not the case here.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-18 10-41-31.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-18 10-41-31.png" width="800">
  </a>
</p>

This validated:

* cube corner ordering
* edge interpolation
* table indexing


### 2. Correct Marching Cubes Surface

After fixing corner ordering and lookup tables, the algorithm produced a stable surface.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-18 14-29-33.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-18 14-29-33.png" width="800">
  </a>
</p>


### 3. Surface-Based Sculpting

Interaction was added by raycasting from the camera and sculpting directly on the surface.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-18 15-49-45.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-18 15-49-45.png" width="800">
  </a>
</p>

Features:

* surface-aligned brush
* adjustable radius
* continuous push / pull editing

### 4. Material Painting

Material painting was implemented using **material IDs stored on grid points**, converted to **vertex colors during Marching Cubes**.

Matplotlib's Inferno color palette is used for visualization.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-18 18-55-07.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-18 18-55-07.png" width="800">
  </a>
</p>

### 5. Undo/Redo + Menu

Implement undo/redo using the wonderful command pattern (see https://gameprogrammingpatterns.com/command.html) alongside a simple menu.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-19 15-34-48.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-19 15-34-48.png" width="800">
  </a>
</p>

<p align="center">
  <img src="figures/development_snapshots/Screencast from 2025年十二月19日 15時35分07秒.gif" width="800">
</p>

### 6. Implement better lighting by better approximating normals

Compute vertex normals in marching cubes. The below figure shows before (left) and after (right).

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-19 15-57-59.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-19 15-57-59.png" width="800">
  </a>
</p>

### 6. Implement chunking for larger worlds

Add chunks on demand - loading and unloading are not dynamic yet.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-19 19-47-35.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-19 19-47-35.png" width="800">
  </a>
</p>


### 7. Save and load filepickers

Also support saving and loading chunked data.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-19 21-34-05.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-19 21-34-05.png" width="800">
  </a>
</p>

### 8. A colourwheel

User can pick from a nice colour palette to colour voxels. Every colour is assigned an id.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-19 22-35-51.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-19 22-35-51.png" width="800">
  </a>
</p>

### 9. Fix chunk boundary bug

Update all boundary chunks when adding voxels at chunk boundaries. This avoids open meshes such as in the following screenshot. The basic features work more or less.


<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-20 15-14-59.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-20 15-14-59.png" width="800">
  </a>
</p>

### 10. Performance optimisation
The global density/material lookup is currently very slow.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-20 16-33-55.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-20 16-33-55.png" width="800">
  </a>
</p>

I made a simple change that drastically improved performance: The chunks do not need to query the world for boundary conditions anymore, but I set the boundary conditions directly when modifying density/material values. In addition, I implemented a chunk update scheduling system that limits the number of meshes regenerated in a given step.
As a next step, moving from dictionaries to arrays would probably help with performance. But I wonder whether just writing a compute shader might not force me to rethink some design decisions right away and would solve make the marching cubes algorithm much more performant.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-20 21-02-03.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-20 21-02-03.png" width="800">
  </a>
</p>



### 10. Different meshers
Add the option the render a cubic mesh at runtime as well as a box explaining the game's controls.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-24 11-29-47.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-24 11-29-47.png" width="800">
  </a>
</p>


## Current Features

* Marching Cubes terrain with linear interpolation
* Surface-based sculpting
* Material painting with vertex colors
* Shared sculpt / paint brush system
* Real-time brush preview
* Undo/Redo
* Save/Load
* Menu
* Chunking

## Controls (current)

| Action              | Input                     |
| ------------------- | ------------------------- |
| Sculpt mode         | `1`                       |
| Paint mode          | `2`                       |
| Sculpt in           | Mouse Button              |
| Sculpt out          | Mouse Button              |
| Paint material      | Mouse Button (paint mode) |
| Change brush radius | Mouse Wheel               |
| Open palette        | `Tab`                     |
| Move                | WASD + Space + Shift      |
| Undo/redo           | Control + z/y             |
| Menu                | Escape                    |


## Planned Work

* [ ] Performance optimizations
* [ ] Texture-based materials
* [ ] Additional sculpting tools

## License

[MIT](LICENSE)
