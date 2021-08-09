extends Node2D

class_name Curve4game

const DIFERENTIAL_POSITION=0.00001
var dp=DIFERENTIAL_POSITION

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_cathesian_position(pos:float)->Vector2:
	#Virtual
	push_error ( "Virtual method, have to be instanciated" )
	return Vector2(0,0)

func get_gradient(pos:float)->Vector2:
	return (get_cathesian_position(pos+dp)-get_cathesian_position(pos))/dp

func get_dir_vec(pos:float)->Vector2:
	var grad=get_gradient(pos)
	var ret:Vector2
	if grad.length()==0:
		ret=Vector2(1,0)
	else:
		ret=grad.normalized()
	return ret

#func get_rigth_vec(pos:float)->Vector2
#	return Vector2()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
