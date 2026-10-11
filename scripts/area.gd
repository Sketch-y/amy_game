extends Node2D
## Root of an area scene. Children (back to front): Background (Parallax2D,
## scrolls slower), Buildings, Decor, Floor, Actors.

@export var title := ""
## Walkable/camera width of the area in pixels. If you widen an area, extend
## the Background and Floor shapes to match.
@export var width := 960.0
