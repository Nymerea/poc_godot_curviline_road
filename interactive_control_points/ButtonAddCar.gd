extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var button_name="add car"
var mouse_icon:Texture=load("res://drawing/car_red.png")
var sms


# Called when the node enters the scene tree for the first time.
func _ready():
	sms=get_owner().SMS.ADD_CAR_BUTTON_SIG
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
