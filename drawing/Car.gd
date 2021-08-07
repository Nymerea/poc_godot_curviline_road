extends Navigation2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var destination : Vector2 = Vector2.ZERO
export var speed: int = 10
export var velocity : Vector2 = Vector2(1,1)
export var path :PoolVector2Array = PoolVector2Array()

	
# Called when the node enters the scene tree for the first time.
func _ready():
	var nav : NavigationPolygon = NavigationPolygon.new()
	var polygon = NavigationPolygon.new()
	var outline = PoolVector2Array([Vector2(0, 0), Vector2(0, 50), Vector2(50, 50), Vector2(50, 0)])
	polygon.add_outline(outline)
	polygon.make_polygons_from_outlines()
	navpoly_add(polygon,Transform2D.IDENTITY)
	
	pass # Replace with function body.

func _process(delta):
	# Calculate the movement distance for this frame
	var distance_to_walk = speed * delta
	
	# Move the player along the path until he has run out of movement or the path ends.
	while distance_to_walk > 0 and path.size() > 0:
		var distance_to_next_point = position.distance_to(path[0])
		if distance_to_walk <= distance_to_next_point:
			# The player does not have enough movement left to get to the next point.
			position += position.direction_to(path[0]) * distance_to_walk
		else:
			# The player get to the next point
			position = path[0]
			path.remove(0)
		# Update the distance to walk
		distance_to_walk -= distance_to_next_point
