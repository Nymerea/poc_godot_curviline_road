extends Line2D

var linked_road:Array=[]


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func disconnect_road(road):
	if road in linked_road:
		linked_road.erase(road)


func add_road(road,node_a:bool):
	if not road in linked_road:
		linked_road.push_back(road)
		match node_a:
			true:road.set_node_a(self)
			false:road.set_node_b(self)

func remove_all_road():
	print(linked_road)
	for road in linked_road.duplicate():
		road.disconnect_node_a()
		road.disconnect_node_b()
		road.remove_road()

func remove_node():
	remove_all_road()
	self.queue_free()
	pass	


func get_position():
	return position

func set_position(pos:Vector2):
	position=pos

# Called when the node enters the scene tree for the first time.
func _ready():
	position=Vector2(0,0)
	points=[Vector2(0,0),Vector2(0.001,0)]
	linked_road=[]
	#visible=true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
