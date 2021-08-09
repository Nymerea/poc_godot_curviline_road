extends Curve4game

class_name Curve4game_interpolated

export var color:Color
export var width:float
export(PoolVector2Array) var controls_points
enum INTERPOLATION_MODE{
  BEZIER,
  POLYNOMIAL_MAX_ORDER
}

export(INTERPOLATION_MODE) var interpolation


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	#print($Line2D.joint_mode)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
