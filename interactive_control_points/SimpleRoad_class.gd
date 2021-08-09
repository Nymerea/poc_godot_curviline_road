extends Line2D

var node_a:Line2D=null #RoadNode
var node_b:Line2D=null #RoadNode
var control_points:Array=[]
var points2:PoolVector2Array

# Declare member variables here. Examples:
# var a = 2
# var b = "text"



#func get_control_point()

func maj_control_point_index():
	for i in range(control_points.size()):
		control_points[i].index=i
	pass

func remove_control_point_index(index:int):
	var cp=control_points[index]
	control_points.remove(index)
	match node_a:
		null:points2.remove(index)
		_:points2.remove(index+1)
	points=points2
	cp.queue_free()
	pass

func remove_control_point_cp(cp):
	remove_control_point_index(cp.index)
	pass

func add_control_point(point_index:int,position:Vector2):
	#point_index, index in control_points array that the added point will have
	var cp=$Control_point.duplicate()
	self.add_child(cp)
	cp.position=position
	control_points.insert(point_index,cp)
	match node_a:
		null:points2.insert(point_index,cp.position)
		_:points2.insert(point_index+1,cp.position)
	points=points2
	pass

func add_control_point_on_fragment(fragment_index:int,position:Vector2):
	assert(fragment_index<get_number_of_road_fragment() and fragment_index>=0)
	match node_a:
		null:add_control_point(fragment_index+1,position)
		_:add_control_point(fragment_index,position)
	

func move_control_point_cp(cp,position:Vector2):
	move_control_point_index(cp.index,position)

func move_control_point_index(point_index:int,position:Vector2):
	control_points[point_index].position=position
	match node_a:
		null:points2.set(point_index,position)
		_:points2.set(point_index+1,position)
	points=points2
	pass



func _link_node_a():
	node_a.add_road(self,true)

func _link_node_b():
	node_b.add_road(self,false)


func move_node_a(position:Vector2):
	assert(node_a!=null)
	node_a.position=position
	points2.set(0,position)
	points=points2
	pass

func move_node_b(position:Vector2):
	assert(node_b!=null)
	node_b.position=position
	points2.set(points2.size()-1,position)
	points=points2

func set_node_a(node):
	if node==null:
		disconnect_node_a()
	else:
		match node_a:
			node:
				pass #push_warning???
			null:
				node_a=node
				points2.insert(0,node.position)
				_link_node_a()
			_:
				disconnect_node_a()
				node_a=node
				points2.set(0,node.position)
				_link_node_a()
		points=points2

func set_node_b(node):
	if node==null:
		disconnect_node_b()
	else:
		match node_b:
			node:
				pass #push_warning???
			null:
				node_b=node
				points2.insert(points2.size(),node.position)
				_link_node_b()
			_:
				disconnect_node_b()
				node_b=node
				points2.set(points2.size()-1,node.position)
				_link_node_b()
		points=points2

func disconnect_node_a():
	match node_a:
		null:pass
		_:node_a.disconnect_road(self)
	pass

func disconnect_node_b():
	match node_b:
		null:pass
		_:node_b.disconnect_road(self)
	pass


func get_number_of_road_fragment():
	return max(0,points2.size()-1)

func get_road_fragment(road_frag_index:int):
	assert(road_frag_index>=0 and road_frag_index<get_number_of_road_fragment())
	return [points2[road_frag_index],points2[road_frag_index+1]]

func set_control_points_visibility(is_visible:bool):
	for cp in control_points:
		cp.visible=is_visible
	pass

func set_node_visibility(is_visible:bool):
	node_a.visible=is_visible
	node_b.visible=is_visible
	pass




func remove_road():
	print(self.to_string()+" is under deleting")
	disconnect_node_a()
	disconnect_node_b()
	for cp in control_points:
		cp.queue_free()
	self.queue_free()
	
func cut_with_node_and_self_destroy(node,road_fragment_index):
	#/!\ self destroy
	print("cut_with_node_and_self_destroy need to be tested with control points on the road")
	var road1=duplicate()
	var road2=duplicate()
	get_parent().add_child(road1)
	get_parent().add_child(road2)
	assert(road_fragment_index<get_number_of_road_fragment() and road_fragment_index>=0)
	road1.set_node_a(node_a)
	road1.set_node_b(node)
	road2.set_node_a(node)
	road2.set_node_b(node_b)
	match node_a:
		null:
			for i in range(0,road_fragment_index+1):
				road1.add_control_point(i,control_points[i].position)
			for i in range(road_fragment_index+1,control_points.size()):
				road2.add_control_point(i-(road_fragment_index+1),control_points[i].position)
		_:
			for i in range(0,road_fragment_index):
				road1.add_control_point(i,control_points[i].position)
			for i in range(road_fragment_index,control_points.size()):
				road2.add_control_point(i-(road_fragment_index+1),control_points[i].position)
	self.remove_road()
	return [road1,road2]

# Called when the node enters the scene tree for the first time.
func _test():
	add_control_point(0,Vector2(100,100))
	#translate(Vector2(50,50))
	add_control_point(1,Vector2(300,300))
	#translate(Vector2(50,50))
	add_control_point(2,Vector2(100,300))
	#translate(Vector2(50,50))
	move_control_point_index(1,Vector2(0,100))
	#translate(Vector2(50,50))
	#create_node_a(Vector2(50,50))
	#translate(Vector2(400,300))
	#self.position=Vector2(400,300)

func _ready():
	position=Vector2(0,0)
	points2=PoolVector2Array()
	points=points2
	#_test()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
