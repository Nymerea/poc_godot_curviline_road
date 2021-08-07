tool
extends Node2D

const POINT_PICK_DISTANCE = 10.0
var point_picked = false
var selected_point = null
var select_index=0

export(int, 0, 100) var offset = 90
export(int, 0, 100) var steps = 100
export var road_scale = 4

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(event):
	if event is InputEventMouseMotion:
		
		if point_picked:
			if selected_point != null and select_index != null:
				$Line2D.remove_point(select_index)
				$Line2D.add_point(get_local_mouse_position()/road_scale, select_index)
				update()
		else:
			selected_point = null
			for p in $Line2D.points:
				var point = p*road_scale
				if event.position.distance_to(point) < POINT_PICK_DISTANCE:
					selected_point = point
	if event is InputEventMouseButton:
		if event.pressed:
			point_picked = true
			selected_point = null
			var i=0
			for p in $Line2D.points:
				var point = p*road_scale
				if event.position.distance_to(point) < POINT_PICK_DISTANCE:
					selected_point = point
					select_index=i
				i=i+1
			print("selected point")
			print(selected_point)
		else:
			point_picked = false
			selected_point = null
export var path :PoolVector2Array = PoolVector2Array()
func get_road_path() -> PoolVector2Array:
	var path :PoolVector2Array = PoolVector2Array()
	for p in $Line2D.points:
		var point = p*road_scale
		path.append(point)
	path.invert()
	return path
	
func _draw():
	draw_points()

	if selected_point != null:  # draw selected point
		draw_circle(selected_point, 10, Color(1, 1, 1, 0.3))
		pass

func draw_points():
	for point in $Line2D.points:
		draw_circle(point*road_scale, 7, Color(1.0, 0.5, 0.5))
