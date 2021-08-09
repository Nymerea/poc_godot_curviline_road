extends Button

var button_name="road destroy"
var mouse_icon:Texture=load("res://interactive_control_points/text_mouse_destroyroad.png")
var sms
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	sms=get_owner().SMS.DESTROY_BUTTON_SIG
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
