extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var world_size:Vector2
export var world_color:Color
export var ousideworld_color:Color
export var ousideworld_relativ_border:float #potentielement inutile peut se calculer si on clamp la position du world dans les coordonnées de la zone de jeux
export var world_homotetie_min:float=0.1
export var world_homotetie_max:float=5
export var road_width:float
export var road_color:Color
export var centredroadline_relativ_width:float
export var centredroadline_length:float #-1 infinite
export var centredroadline_void_length:float 
export var centredroadline_color:Color

export var roadway_relativ_exentration:float #beetween -0.5 and 0.5 (negative for left driving positive for right driving)
export var exentrateroadline_relativ_width:float
export var exentrateroadline_length:float #-1 infinite
export var exentrateroadline_void_length:float
export var exentrateroadline_color:Color

const RKEY_GLOBAL_ROAD:String="global_road"
const RKEY_CENTERED_WHITE_LINES:String="centered_white_lines"
const RKEY_RIGHT_WHITE_LINES:String="right_white_lines"
const RKEY_LEFT_WHITE_LINES:String="left_white_lines"
const RKEY_CURVE:String="curve"
const RKEY_R_CURVE:String="right_curve"
const RKEY_L_CURVE:String="left_curve"

var world_homotetie:float=1
var roadlist=[]#road: dictionar with keys
#"global_road" -> lines that describe the main road
#"white lines" -> list of lines that describe the lines on the road
#"curve" -> the curve function name that describe the road trajectory
#"right_curve" -> the curve function name that describe the road trajectory for the right driver
#"left_curve" -> the curve function name that describe the road trajectory for the left driver
var screensize:Vector2
# Called when the node enters the scene tree for the first time.


func test_create_line():
	print("test function called")
	var test_line=Line2D.new()
	add_child(test_line)
	#print(test_line.visible)
	test_line.add_point(Vector2(0,0))
	test_line.add_point(Vector2(100,100))

func create_game_space():
	var game_space:Polygon2D=Polygon2D.new()
	var outergame_space:Polygon2D=Polygon2D.new()
	add_child(outergame_space)
	add_child(game_space)
	#game_space.polygon.insert(0,Vector2(0,0))
	game_space.polygon=[
		Vector2(-world_size.x/2,-world_size.y/2),
		Vector2(world_size.x/2,-world_size.y/2),
		Vector2(world_size.x/2,world_size.y/2),
		Vector2(-world_size.x/2,world_size.y/2),
		]
	game_space.color=world_color
	outergame_space.polygon=[
		Vector2(-world_size.x/2*ousideworld_relativ_border,-world_size.y/2*ousideworld_relativ_border),
		Vector2(world_size.x/2*ousideworld_relativ_border,-world_size.y/2*ousideworld_relativ_border),
		Vector2(world_size.x/2*ousideworld_relativ_border,world_size.y/2*ousideworld_relativ_border),
		Vector2(-world_size.x/2*ousideworld_relativ_border,world_size.y/2*ousideworld_relativ_border),
		]
	outergame_space.color=ousideworld_color
	#game_space.polygon.append(Vector2(0,0))
	#game_space.polygon.append(Vector2(100,0))
	#game_space.polygon.append(Vector2(100,100))
	#game_space.polygon[0]=Vector2(0,0)
	#game_space.polygon[1]=Vector2(100,0)
	#game_space.polygon[2]=Vector2(100,100)
	#print(game_space.polygon)
	#print($Polygon2D.polygon)
	pass

func convert_to_a_screen_position(p:Vector2):
	#screen space is expressed with [-1,1]x[-1,1]
	#(0,0) is the center
	#(-1,-1) is the left down corner
	#(-1,1) is the left up corner
	#return value is in the world2 position
	return 

func set_screencenter_position(pos:Vector2):
	#((screensize/2)-position)/scale.x=pos
	#(screensize/2) - position=pos*scale
	position=-(pos*scale - (screensize/2))
	pass

func screencenter_position():
	return ((screensize/2)-position)/scale.x

func reposition_screen():
	#if screen looks outside the game reposition the screen on the game
	scale=Vector2(world_homotetie,world_homotetie)
	#position point haut gauche
	#print(position)
	
	#position.x=clamp(position.x*scale.x,-world_size.x,world_size.x)
	var scpos=screencenter_position()
	#set_screencenter_position(Vector2(150,150))
	set_screencenter_position(Vector2(clamp(scpos.x,-world_size.x/2,world_size.x/2),clamp(scpos.y,-world_size.y/2,world_size.y/2)))
	pass

func gamma_circle(p:float)->Vector2:
	return Vector2(cos(2*PI*p),sin(2*PI*p))*100
	#return Vector2(cos(4*PI*p),sin(4*PI*p))*p*200
	#return Vector2(cos(8*PI*p),10*p)*100-Vector2(0,250)
func frange(begin:float,end:float,discr:int):
	var dx:float=(end-begin)/discr
	var res=[]
	for i in range(discr):
		res+=[dx*i+begin]
	return res

func displace_local_curve(displacement_frontXright_vector:Vector2,curve_fun,dp:float,position:float):
	var gamma=funcref(self,curve_fun)
	var pos0:Vector2=gamma.call_func(position)
	var pos1:Vector2=gamma.call_func(position+dp)
	var gradient:Vector2=pos1-pos0
	var dir_vec:Vector2
	var right_vec:Vector2
	if gradient.length()==0:
		dir_vec=Vector2(1,0)
	else:
		dir_vec=gradient.normalized()
	right_vec=dir_vec.rotated(-PI/2)
	return gamma.call_func(position)\
	+dir_vec*displacement_frontXright_vector.x\
	+right_vec*displacement_frontXright_vector.y
	#print(dir_vec)
	#print(right_vec)

func right_displacement(curve,p,dp):
	return displace_local_curve(Vector2(0,road_width*roadway_relativ_exentration),
		curve,dp,p)
func left_displacement(curve,p,dp):
	return displace_local_curve(Vector2(0,-road_width*roadway_relativ_exentration),
		curve,dp,p)

func roadline_iswhite(total_distance,line_length,noline_length):
	var ret
	if line_length<0:
		ret=true
	elif line_length==0:
		ret=false
	else:
		ret= total_distance-(line_length+noline_length)*int(total_distance/(line_length+noline_length))<=line_length
	#print(total_distance/(line_length+noline_length))
	#print(line_length+noline_length)
	#print(int(total_distance/(line_length+noline_length)))
	#print(total_distance-total_distance*int(total_distance/(line_length+noline_length)))
	return ret

func centeredroadline_iswhite(total_distance):
	return roadline_iswhite(total_distance,centredroadline_length,centredroadline_void_length)

func excentredroadline_iswhite(total_distance):
	return roadline_iswhite(total_distance,exentrateroadline_length,exentrateroadline_void_length)

func calculate_dist(curve,p,dp):
	return (funcref(self,curve).call_func(p)-funcref(self,curve).call_func(p+dp)).length()



func create_roads_from_curve(curve_func_name,dl:float,dp:float):
	#dl minimal line lenght to create a curve fragment
	#dp variation applied on the curve function to make a step
	#multiple dx application will make a dl and a road fragment of dl length will be create
	var fcurve=funcref(self,curve_func_name)
	var thisroad={}
	thisroad[RKEY_GLOBAL_ROAD]=Line2D.new()
	add_child(thisroad[RKEY_GLOBAL_ROAD])
	thisroad[RKEY_CENTERED_WHITE_LINES]=[]
	thisroad[RKEY_RIGHT_WHITE_LINES]=[]
	thisroad[RKEY_LEFT_WHITE_LINES]=[]
	thisroad[RKEY_CURVE]=curve_func_name
	
	var centeredline_drawing=false
	var exentredline_drawing=false
	var total_distance=0
	var localdist
	var local_pos=0
	var distance_beetween_lastpos_and_localpos=0
	var last_curve_position=0
	#var last_carth_position:Vector2
	var local_carth_position:Vector2
	
	local_carth_position=fcurve.call_func(local_pos)
	thisroad[RKEY_GLOBAL_ROAD].width=road_width
	thisroad[RKEY_GLOBAL_ROAD].add_point(local_carth_position)
	thisroad[RKEY_GLOBAL_ROAD].default_color=road_color
	if centeredroadline_iswhite(total_distance):
		centeredline_drawing=true
		thisroad[RKEY_CENTERED_WHITE_LINES]+=[Line2D.new()]
		add_child(thisroad[RKEY_CENTERED_WHITE_LINES][-1])
		thisroad[RKEY_CENTERED_WHITE_LINES][-1].width=road_width*centredroadline_relativ_width
		thisroad[RKEY_CENTERED_WHITE_LINES][-1].add_point(local_carth_position)
		thisroad[RKEY_CENTERED_WHITE_LINES][-1].default_color=centredroadline_color
	if excentredroadline_iswhite(total_distance):
		exentredline_drawing=true
		thisroad[RKEY_RIGHT_WHITE_LINES]+=[Line2D.new()]
		add_child(thisroad[RKEY_RIGHT_WHITE_LINES][-1])
		thisroad[RKEY_RIGHT_WHITE_LINES][-1].width=road_width*exentrateroadline_relativ_width
		thisroad[RKEY_RIGHT_WHITE_LINES][-1].add_point(right_displacement(curve_func_name,local_pos,dp))
		thisroad[RKEY_RIGHT_WHITE_LINES][-1].default_color=exentrateroadline_color
		
		thisroad[RKEY_LEFT_WHITE_LINES]+=[Line2D.new()]
		add_child(thisroad[RKEY_LEFT_WHITE_LINES][-1])
		thisroad[RKEY_LEFT_WHITE_LINES][-1].width=road_width*exentrateroadline_relativ_width
		thisroad[RKEY_LEFT_WHITE_LINES][-1].add_point(left_displacement(curve_func_name,local_pos,dp))
		thisroad[RKEY_LEFT_WHITE_LINES][-1].default_color=exentrateroadline_color
	while local_pos<1:
		#last_carth_position=local_carth_position
		localdist=calculate_dist(curve_func_name,local_pos,dp)
		distance_beetween_lastpos_and_localpos+=localdist
		total_distance+=localdist
		local_pos+=dp
		if distance_beetween_lastpos_and_localpos>=dl:
			distance_beetween_lastpos_and_localpos=0
			local_carth_position=fcurve.call_func(local_pos)
			thisroad[RKEY_GLOBAL_ROAD].add_point(local_carth_position)
			if centeredroadline_iswhite(total_distance):
				if centeredline_drawing==false:
					#print(total_distance)
					centeredline_drawing=true
					thisroad[RKEY_CENTERED_WHITE_LINES]+=[Line2D.new()]
					add_child(thisroad[RKEY_CENTERED_WHITE_LINES][-1])
					thisroad[RKEY_CENTERED_WHITE_LINES][-1].width=road_width*centredroadline_relativ_width
					thisroad[RKEY_CENTERED_WHITE_LINES][-1].default_color=centredroadline_color
				thisroad[RKEY_CENTERED_WHITE_LINES][-1].add_point(local_carth_position)
			else:
				centeredline_drawing=false
			
			if excentredroadline_iswhite(total_distance):
				if exentredline_drawing==false:
					exentredline_drawing=true
					thisroad[RKEY_RIGHT_WHITE_LINES]+=[Line2D.new()]
					add_child(thisroad[RKEY_RIGHT_WHITE_LINES][-1])
					thisroad[RKEY_RIGHT_WHITE_LINES][-1].width=road_width*exentrateroadline_relativ_width
					thisroad[RKEY_RIGHT_WHITE_LINES][-1].default_color=exentrateroadline_color
					
					thisroad[RKEY_LEFT_WHITE_LINES]+=[Line2D.new()]
					add_child(thisroad[RKEY_LEFT_WHITE_LINES][-1])
					thisroad[RKEY_LEFT_WHITE_LINES][-1].width=road_width*exentrateroadline_relativ_width
					thisroad[RKEY_LEFT_WHITE_LINES][-1].default_color=exentrateroadline_color
				
				thisroad[RKEY_RIGHT_WHITE_LINES][-1].add_point(right_displacement(curve_func_name,local_pos,dp))
				thisroad[RKEY_LEFT_WHITE_LINES][-1].add_point(left_displacement(curve_func_name,local_pos,dp))
			else:
				exentredline_drawing=false
	
	local_pos=1
	local_carth_position=fcurve.call_func(local_pos)
	thisroad[RKEY_GLOBAL_ROAD].add_point(local_carth_position)
	if centeredroadline_iswhite(total_distance):
		if centeredline_drawing==false:
			centeredline_drawing=true
			thisroad[RKEY_CENTERED_WHITE_LINES]+=[Line2D.new()]
			add_child(thisroad[RKEY_CENTERED_WHITE_LINES][-1])
			thisroad[RKEY_CENTERED_WHITE_LINES][-1].width=road_width*centredroadline_relativ_width
			thisroad[RKEY_CENTERED_WHITE_LINES][-1].default_color=centredroadline_color
		thisroad[RKEY_CENTERED_WHITE_LINES][-1].add_point(local_carth_position)
	else:
		centeredline_drawing=false
	if excentredroadline_iswhite(total_distance):
		if exentredline_drawing==false:
			exentredline_drawing=true
			thisroad[RKEY_RIGHT_WHITE_LINES]+=[Line2D.new()]
			add_child(thisroad[RKEY_RIGHT_WHITE_LINES][-1])
			thisroad[RKEY_RIGHT_WHITE_LINES][-1].width=road_width*exentrateroadline_relativ_width
			thisroad[RKEY_RIGHT_WHITE_LINES][-1].default_color=exentrateroadline_color
				
			thisroad[RKEY_LEFT_WHITE_LINES]+=[Line2D.new()]
			add_child(thisroad[RKEY_LEFT_WHITE_LINES][-1])
			thisroad[RKEY_LEFT_WHITE_LINES][-1].width=road_width*exentrateroadline_relativ_width
			thisroad[RKEY_LEFT_WHITE_LINES][-1].default_color=exentrateroadline_color
				
		thisroad[RKEY_RIGHT_WHITE_LINES][-1].add_point(right_displacement(curve_func_name,local_pos,dp))
		thisroad[RKEY_LEFT_WHITE_LINES][-1].add_point(left_displacement(curve_func_name,local_pos,dp))
	else:
		exentredline_drawing=false
	pass

func _resize():
	print("resize")
	var ancient_size=screensize
	screensize=get_viewport().size
	translate(-ancient_size/2)
	translate(screensize/2)
	#translate(Vector2(1,1))

func _ready():
	assert(ousideworld_relativ_border>=1)
	screensize=(Vector2(0,0))
	get_tree().get_root().connect("size_changed", self, "_resize")
	_resize()
	#translate(Vector2((screensize/2).x,(screensize/2).y))
	position=Vector2((screensize/2).x,(screensize/2).y)
	#scale=Vector2(2,2)
	#test_create_line()
	create_game_space()
	#test_create_line()
	#print(displace_local_curve(Vector2(1,0),"gamma_circle",0.0000001,0))
	#print(gamma_circle(0))
	create_roads_from_curve("gamma_circle",0.5,0.001)
	pass # Replace with function body.

func _process(delta):
	#print(delta)
	if Input.is_action_pressed("ui_right"):
		translate(Vector2(-10,0))
	if Input.is_action_pressed("ui_left"):
		translate(Vector2(10,0))
	if Input.is_action_pressed("ui_up"):
		translate(Vector2(0,10))
	if Input.is_action_pressed("ui_down"):
		translate(Vector2(0,-10))
	if Input.is_action_pressed("ui_page_down"):
		world_homotetie=min(world_homotetie_max,max(world_homotetie_min,world_homotetie*1.1))
	if Input.is_action_pressed("ui_page_up"):
		world_homotetie=min(world_homotetie_max,max(world_homotetie_min,world_homotetie/1.1))
	reposition_screen()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
