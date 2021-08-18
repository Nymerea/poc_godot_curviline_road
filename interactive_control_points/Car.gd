extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var belong_to:Array=[] 
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


var time=0
var t
func _process(delta):
	if belong_to.empty():
		return
	time=time+delta
	t=abs(cos(time))
	var road=belong_to[1]
	var fragment_index=belong_to[2]
	var couple_points=road.get_road_fragment(fragment_index)
	var p1=couple_points[0]
	var p2=couple_points[1]
	if p1==p2:
		print("same coord")
		pass
	else:
		var dir=(p2-p1).normalized()
		var pos=p1*(1-t) +p2*t
		$Sprite.global_position=pos
		global_position=pos
		orientate($Sprite,dir)
		pass
	pass
	
var DIRECTION0=Vector2(0,1)
func orientate(roadobj:Sprite,grad:Vector2):
	var direction:Vector2
	var signe:float
	var angle:float
	if grad.length()==0:
		direction=Vector2(1,0)
	else:
		direction=grad.normalized()
	angle=acos(min(1,max(-1,DIRECTION0.dot(direction))))
	signe=DIRECTION0.cross(direction)
	if signe<0:
		signe=-1
	else:
		signe=1
	roadobj.rotation_degrees=signe*(angle/(2*PI))*360
	pass

func set_car(var car):
	print("initialize var")
	self.belong_to = car
