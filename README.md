# Voxel Terrain Editor (Godot 4)

This repository documents the development of a **voxel terrain editor** built in **Godot 4**, using **Marching Cubes** for smooth surface extraction.

<p align="center">
  <a href="figures/development_snapshots/Screenshot from 2025-12-18 18-55-07.png">
	<img src="figures/development_snapshots/Screenshot from 2025-12-18 18-55-07.png" width="800">
  </a>
</p>


## Overview

The project explores:

* interactive Marching Cubes terrain
* surface-based sculpting tools
* material painting using vertex colors

## Development Log

### 1. First Marching Cubes Output

Initial implementation of Marching Cubes using the standard Bourke tables.
The focus at this stage was correctness and understanding the algorithm.

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

Implemented undo/redo using the wonderful [https://gameprogrammingpatterns.com/command.html](command pattern) alongside a simple menu.

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
| Cycle material      | `Tab`                     |
| Move                | WASD + Space + Shift      |
| Undo/redo           | Control + z/y             |
| Menu                | Escape                    |


## Planned Work

* [ ] Performance optimizations
* [ ] Tool & material UI
* [ ] Texture-based materials
* [ ] Additional sculpting tools

## License

[MIT](LICENSE)
