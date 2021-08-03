extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const DIRECTION0:Vector2=Vector2(1,0)
var screensize:Vector2
var screencenter:Vector2
var radius:float=100
var roadlist=[]

func gamma_circle(p:float)->Vector2:
	return Vector2(cos(2*PI*p),sin(2*PI*p))*radius+screencenter
	#return Vector2(cos(2*PI*p),sin(2*PI*p))*p*radius+screencenter
	#return Vector2(cos(4*PI*p),5*p)*100+screencenter-Vector2(0,250)
func frange(begin:float,end:float,discr:int):
	var dx:float=(end-begin)/discr
	var res=[]
	for i in range(discr):
		res+=[dx*i+begin]
	return res

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

func create_road(discretisation:int):
	var local_pos:Vector2
	for p in frange(0,1,discretisation):
		local_pos=gamma_circle(p)
		var newRoad = Sprite.new()
		newRoad.texture=load("res://road_fragment.png")
		newRoad.global_position = local_pos
		add_child(newRoad)
		orientate(newRoad,gamma_circle(p+0.0001)-gamma_circle(p))
		roadlist+=[newRoad]


	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	screensize=get_viewport().size
	screencenter=screensize/2
	#$Road.position=screencenter
	#roadlist[0].global_position=screencenter
	#print($Road)
	#print(roadlist)
	#roadlist[0].visible=true
	#add_child(roadlist[0])
	#print(DIRECTION0.cross(Vector2(0,-1)))
	create_road(50)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
