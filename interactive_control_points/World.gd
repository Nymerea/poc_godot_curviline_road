extends Node2D
#CP,cp <-> control point

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var dist_far_enougth_cp:float
export var dist_far_enougth_road:float
export var dist_far_enougth_node:float

enum EDIT_STATES{ROAD,DESTROY,NODE,CP,NONE,WAITING_ROAD_SECOND_NODE,MOVE_CP}
var current_state=EDIT_STATES.NONE
#var current_state=42

signal SIG_MOUSE_MOVE
signal SIG_MOUSE_RIGTH_CLICK
signal SIG_MOUSE_LEFT_CLICK

enum STATE_MACHINE_SIGNALS{ROAD_BUTTON_SIG,DESTROY_BUTTON_SIG,NODE_BUTTON_SIG,
CP_BUTTON_SIG,POINTER_MOVE,ACCEPT,DENY}
const SMS=STATE_MACHINE_SIGNALS
#yolo


# Called when the node enters the scene tree for the first time.

var roadlist:Array=[]
var nodelist:Array=[]

var savestate_last_road=null
var savestate_last_roadnode=null
var savestate_last_roadcp_index:int=-1
var savestate_last_roadcp_index_pos:Vector2


func add_child_transgressor(child):
	add_child(child)

func raise_fatal_error(text:String):
	push_error(text)
	get_tree().quit()


func _connect_buttons():
	connect_button($Button_road_create)
	connect_button($Button_road_destroy)
	connect_button($Button_add_node)
	connect_button($Button_modify_cp)
	
	assert(connect("SIG_MOUSE_MOVE",self,"_when_cursor_move")==0)
	assert(connect("SIG_MOUSE_RIGTH_CLICK",self,"_when_rigth_click")==0)
	assert(connect("SIG_MOUSE_LEFT_CLICK",self,"_when_left_click")==0)

func _ready():
	_connect_buttons()
	#var nodea=$RoadNode.duplicate()
	#var r=$SimpleRoad_class.duplicate()
	#add_child(nodea)
	#add_child(r)
	#print(nodea.get_path())
	#nodea.position=Vector2(100,100)
	#r.position=Vector2(0,0)
	#r.set_node_a(nodea)
	#r.add_control_point(0,Vector2(300,300))
	#r.move_node_a(Vector2(400,400))
	
	pass # Replace with function body.

func verbose_print(text:String,verbose:bool):
	if verbose:
		print(text)
	pass

func connect_button(button:Object):
	assert(button.connect("pressed",self,"_button_pressed",[button])==0)
	pass

func is_near_from_buttons(pos:Vector2):
	return [(pos-$Button_road_create.rect_position).length(),
			(pos-$Button_road_destroy.rect_position).length(),
			(pos-$Button_add_node.rect_position).length(),
			(pos-$Button_modify_cp.rect_position).length() 
			].min()<50

func make_the_road_follow_cursor(verbose:bool):
	var mouse_pos:Vector2=get_local_mouse_position()
	savestate_last_road.move_control_point_index(savestate_last_roadcp_index,mouse_pos)

func accept_cp_position(verbose:bool):
	assert(savestate_last_road!=null and savestate_last_roadcp_index!=-1)
	var mouse_pos=get_local_mouse_position()
	savestate_last_road.move_control_point_index(savestate_last_roadcp_index,mouse_pos)
	verbose_print("new cp position:"+String(mouse_pos),verbose)
	transition_from_MOVE_CP_to_CP(verbose)

func deny_cp_position(verbose:bool):
	assert(savestate_last_road!=null and savestate_last_roadcp_index!=-1)
	savestate_last_road.move_control_point_index(savestate_last_roadcp_index,savestate_last_roadcp_index_pos)
	verbose_print("revert to ancient cp position",verbose)
	transition_from_MOVE_CP_to_CP(verbose)

func far_enougth_nearest_road_projected_on_node()->bool:
	var mp=get_local_mouse_position()
	if road_fragment_count()==0:
		return true
	else:
		return nearest_node_distance(nearest_fragment_road_position(mp)[0])>dist_far_enougth_node


func nearest_node_distance(pos:Vector2)->float:
	var distances=[]
	#print(nodelist)
	if nodelist==[]:
		return INF
	else:
		for node in nodelist:
			distances+=[(pos-node.get_position()).length()]
		#print(distances)
		return distances.min()

func get_nearest_cp(pos):#->[road,cp_index]
	var assoc_road=null
	var assoc_index:int=-1
	var min_dist:float=INF
	var dist:float
	for road in roadlist:
		for cp_index in range(road.control_points.size()):
			dist=(road.control_points[cp_index].position-pos).length()
			if dist<min_dist:
				min_dist=dist
				assoc_road=road
				assoc_index=cp_index
	assert(assoc_road!=null and assoc_index!=-1)
	return [assoc_road,assoc_index]

func get_nearest_cp_pos(pos:Vector2)->Vector2:
	var nearest_cp:Vector2=Vector2(INF,INF)
	for road in roadlist:
		for cp in road.control_points:
			if (cp.position-pos).length()<(nearest_cp-pos).length():
				nearest_cp=cp.position
	return nearest_cp

func far_enougth_cp()->bool:
	var mp=get_local_mouse_position()
	return (get_nearest_cp_pos(mp)-mp).length()>dist_far_enougth_cp

func remove_nearest_control_point(verbose:bool):
	var mouse_pos:Vector2=get_local_mouse_position()
	var gncp=get_nearest_cp(mouse_pos)
	print(gncp[1])
	verbose_print("remove control point on road "+gncp[0].to_string()+" at position "+String(gncp[0].control_points[gncp[1]].position),verbose )
	gncp[0].remove_control_point_index(gncp[1])


func move_the_nearest_control_point(verbose):
	var mouse_pos:Vector2=get_local_mouse_position()
	var gncp=get_nearest_cp(mouse_pos)
	#savestate_last_road
	#savestate_last_roadcp_index:int=-1
	savestate_last_road=gncp[0]
	savestate_last_roadcp_index=gncp[1]
	savestate_last_roadcp_index_pos=savestate_last_road.control_points[savestate_last_roadcp_index].position
	change_to_state_MOVE_CP(verbose)

func far_enougth_node()->bool:
	return nearest_node_distance(get_local_mouse_position())>dist_far_enougth_node

func road_fragment_count():
	var sum:int=0
	for r in roadlist:
		sum+=r.get_number_of_road_fragment()
	return sum

func get_first_road_fragment():
	for r in roadlist:
		if r.get_number_of_road_fragment()>0:
			return r.get_road_fragment(0)

func get_the_minimal_distance_pos_parameter_projected_on_straight_line(pos:Vector2,origin:Vector2,direction:Vector2):
	#minimal dist position = origin + t * direction
	var rigth:Vector2=direction.rotated(-PI/2)
	var t1:float
	var t2:float
	var Rx:float=rigth.x
	var Ry:float=rigth.y
	var Dx:float=direction.x
	var Dy:float=direction.y
	
	#pos+t1*rigth = origin+t2*direction
	#(Px)        (Rx)   (Ox)        (Dx)
	#(  ) + t1 * (  ) = (  ) + t2 * (  )
	#(Py)        (Ry)   (Oy)        (Dy)
	# LES INCONNUES SONT t1 et t2
	#{ Px + t1 * Rx = Ox + t2 * Dx
	#{ Py + t1 * Ry = Oy + t2 * Dy
	#
	#{ t1 * Rx - t2 * Dx = Ox - Px  
	#{ t1 * Ry - t2 * Dy = Oy - Py
	
	#{ (Rx  -Dx) (t1) = ( Ox - Px ) 
	#{ (Ry  -Dy) (t2) = ( Oy - Py )
	
	#{ (t1) = (Rx  -Dx)^-1  ( Ox - Px ) 
	#{ (t2) = (Ry  -Dy)     ( Oy - Py )
	var mat:Transform2D=Transform2D( Vector2(Rx,-Dx) , Vector2(Ry,-Dy) , Vector2(0,0) )
	var vec_o_minus_p:Vector2=origin-pos
	var t_vec:Vector2=mat.xform(vec_o_minus_p)
	t1=t_vec[0]
	t2=t_vec[1]
	#print("## Vector comparaison ##")
	#print(t_vec)
	#print(pos+t1*rigth)
	#print(origin+t2*direction)
	#print("## END Vector comparaison ##")
	
	return t2

func get_parameter_to_reach_point(origin:Vector2,direction:Vector2,target:Vector2)->float:
	#origin.x + direction.x * t = target.x
	#t = (target.x-origin.x)/direction.x
	if abs(direction.x)>abs(direction.y):
		return (target.x-origin.x)/direction.x
	else:
		return (target.y-origin.y)/direction.y

func get_the_minimal_distance_pos_projected_on_segment(pos:Vector2,segment)->Vector2:
	var seg0:Vector2=segment[0]
	var seg1:Vector2=segment[1]
	var origin:Vector2
	var direction:Vector2
	var t:float
	var tmax:float
	var parameter:float
	if seg0==seg1:
		return seg0
	else:
		origin=seg0
		direction=(seg1-seg0).normalized()
		t=get_the_minimal_distance_pos_parameter_projected_on_straight_line(pos,origin,direction)
		tmax=get_parameter_to_reach_point(origin,direction,seg1)
		if t<0:
			return seg0
		elif t>tmax:
			 return seg1
		else:
			return origin+t*direction
		


func nearest_fragment_road_position(pos:Vector2):#->[Vec2,road,frag_index]
	assert(road_fragment_count()>0)
	var nearest_pos:Vector2=get_first_road_fragment()[0]
	var nearest_road=null
	var nearest_frag_index:int=-1
	var fragment_points:Array
	var local_nearest_pos:Vector2
	for road in roadlist:
#		print(road.get_number_of_road_fragment())
		for i in range(road.get_number_of_road_fragment()):
			fragment_points=road.get_road_fragment(i)
			local_nearest_pos=get_the_minimal_distance_pos_projected_on_segment(pos,fragment_points)
			if (nearest_pos-pos).length() >= (local_nearest_pos-pos).length():
				#maj minimum distance
				nearest_pos=local_nearest_pos
				nearest_road=road
				nearest_frag_index=i
	return [nearest_pos,nearest_road,nearest_frag_index]
	
func far_enougth_road()->bool:
	#print("is far enougth")
	var pos_nearest_frag:Vector2
	var mouse_pos:Vector2=get_local_mouse_position()
	if road_fragment_count()==0:
		return true
	else:
		pos_nearest_frag=nearest_fragment_road_position(mouse_pos)[0]
		$Debugging_sprite.position=pos_nearest_frag
		return (pos_nearest_frag-mouse_pos).length()>dist_far_enougth_road

func create_node_on_nearest_road_frag(verbose:bool):
	var mouse_pos:Vector2=get_local_mouse_position()
	var road
	var newroad_a=null
	var newroad_b=null
	var new_node=$RoadNode.duplicate()
	add_child(new_node)
	var pos:Vector2
	var frag_index:int
	var nfrp_ret:Array
	nfrp_ret=nearest_fragment_road_position(mouse_pos)
	pos=nfrp_ret[0]
	road=nfrp_ret[1]
	frag_index=nfrp_ret[2]
	new_node.set_position(pos)
	roadlist.erase(road)
	var cwnasd_var=road.cut_with_node_and_self_destroy(new_node,frag_index)
	newroad_a=cwnasd_var[0]
	newroad_b=cwnasd_var[1]
	roadlist.append(newroad_a)
	roadlist.append(newroad_b)
	nodelist.append(new_node)
	#print(new_node.linked_road)

func create_node_on_mouse_pos(verbose:bool):
	var mouse_pos:Vector2=get_local_mouse_position()
	verbose_print("create node pos:"+String(mouse_pos),verbose)
	add_a_node(mouse_pos)
	pass

func delete_nearest_node(verbose:bool):
	assert(nodelist!=[])
	var mouse_pos:Vector2=get_local_mouse_position()
	var nearest_node=get_nearest_node(mouse_pos)
	verbose_print("RoadNode: "+nearest_node.to_string()+" deleting",verbose)
	remove_node(nearest_node)
	pass

func abort_savestate_connection(verbose):
	assert(savestate_last_road!=null and not savestate_last_road in roadlist)
	savestate_last_road.remove_road()
	savestate_last_road=null
	savestate_last_roadcp_index=-1
	if savestate_last_roadnode!=null:
		savestate_last_roadnode.remove_node()
		savestate_last_roadnode=null

func connect_the_savestate_road_and_save_savestate(verbose,node_b):
	assert(savestate_last_road!=null and not savestate_last_road in roadlist)
	savestate_last_road.remove_control_point_index(savestate_last_roadcp_index)
	savestate_last_road.set_node_b(node_b)
	roadlist.push_back(savestate_last_road)
	savestate_last_road=null
	savestate_last_roadcp_index=-1
	if savestate_last_roadnode!=null:
		nodelist.append(savestate_last_roadnode)
		savestate_last_roadnode=null

func connect_the_road_to_ex_nihilo_node(verbose):
	var mouse_pos:Vector2=get_local_mouse_position()
	var node_b=add_a_node(mouse_pos)
	verbose_print("connect road ex nihilo at pos:"+String(mouse_pos)+" to node:"+node_b.to_string(),verbose)
	connect_the_savestate_road_and_save_savestate(verbose,node_b)
	transition_from_WAITING_ROAD_SECOND_NODE_to_ROAD(verbose)

func deny_road_connection(verbose):
	verbose_print("abort road construction",verbose)
	abort_savestate_connection(verbose)
	transition_from_WAITING_ROAD_SECOND_NODE_to_ROAD(verbose)

func connect_the_road_to_nearest_node(verbose):
	var mouse_pos:Vector2=get_local_mouse_position()
	var node_b=get_nearest_node(mouse_pos)
	verbose_print("connect road to nearest node at pos:"+String(mouse_pos)+" to node:"+node_b.to_string(),verbose)
	connect_the_savestate_road_and_save_savestate(verbose,node_b)
	transition_from_WAITING_ROAD_SECOND_NODE_to_ROAD(verbose)
	
func create_road_ex_nihilo(verbose):
	var mouse_pos:Vector2=get_local_mouse_position()
	verbose_print("create road ex nihilo at pos:"+String(mouse_pos),verbose)
	savestate_last_roadnode=add_a_hidden_node(mouse_pos)
	savestate_last_road=add_a_hidden_road()
	savestate_last_road.set_node_a(savestate_last_roadnode)
	savestate_last_road.add_control_point(0,mouse_pos)
	savestate_last_roadcp_index=0
	change_to_state_WAITING_ROAD_SECOND_NODE(verbose)
	pass

func create_road_connected_to_nearest_node(verbose):
	var mouse_pos:Vector2=get_local_mouse_position()
	verbose_print("create road connected to nearest node at pos:"+String(mouse_pos),verbose)
	savestate_last_road=add_a_hidden_road()
	savestate_last_road.set_node_a(get_nearest_node(mouse_pos))
	savestate_last_road.add_control_point(0,mouse_pos)
	savestate_last_roadcp_index=0
	change_to_state_WAITING_ROAD_SECOND_NODE(verbose)
	pass

func destroy_nearest_road(verbose:bool):
	var mouse_pos:Vector2=get_local_mouse_position()
	var position:Vector2
	var road
	var nfrp_ret=nearest_fragment_road_position(mouse_pos)
	position=nfrp_ret[0]
	road=nfrp_ret[1]
	verbose_print("destroying road:"+road.to_string()+" at position :"+String(position),verbose)
	roadlist.erase(road)
	road.remove_road()


func add_a_hidden_road():
	var road=$SimpleRoad_class.duplicate()
	add_child(road)
	return road

func add_a_hidden_node(position:Vector2):
	var node=$RoadNode.duplicate()
	add_child(node)
	node.set_position(position)
	return node

func remove_node(node):
	nodelist.erase(node)
	for road in node.linked_road:
		roadlist.erase(road)
	node.remove_node()
	pass

func add_a_node(position:Vector2):
	var node=$RoadNode.duplicate()
	add_child(node)
	nodelist.append(node)
	node.set_position(position)
	return node

func get_distance_to_node(node,position:Vector2):
	return (position-node.get_position()).length()

func get_nearest_node(position:Vector2):
	assert(nodelist!=[])
	var nearest_node=nodelist[0]
	for node in nodelist:
		#if (mouse_pos-node.get_position()).length()<(mouse_pos-nearest_node.get_position()).length():
		if get_distance_to_node(node,position)<get_distance_to_node(nearest_node,position):
			nearest_node=node
	return nearest_node

func add_a_control_point_on_the_nearest_road(verbose:bool):
	var mouse_pos:Vector2=get_local_mouse_position()
	var nfrp=nearest_fragment_road_position(mouse_pos)
	var cp_pos:Vector2=nfrp[0]
	var road=nfrp[1]
	var frag_index:int=nfrp[2]
	verbose_print("adding a cp on road :"+road.to_string()+" on the fragment :"+String(frag_index)+" at position"+String(cp_pos),verbose)
	road.add_control_point_on_fragment(frag_index,cp_pos)
#########################
#### SIGNAL HANDLER #####
#### FOR STATE MACH #####
#########################

func _button_pressed(button:Object):
	print(button.button_name +" pressed signal")
	#print("current state is:"+EDIT_STATES.keys()[current_state])
	#print("send message:"+SMS.keys()[button.sms])
	#Input.set_custom_mouse_cursor(button.mouse_icon)#le faire dans la machine a etat
	global_state_machine(button.sms,true)
	pass

func _when_rigth_click():
	print("#########################")
	print("click rigth:"+String(get_local_mouse_position()))
	if not is_near_from_buttons(get_local_mouse_position()):
		global_state_machine(SMS.DENY,true)
	pass

func _when_left_click():
	print("#########################")
	print("click left:"+String(get_local_mouse_position()))
	if not is_near_from_buttons(get_local_mouse_position()):
		global_state_machine(SMS.ACCEPT,true)
	pass

func _when_cursor_move():
	#print("move")
	global_state_machine(SMS.POINTER_MOVE,false)
	pass


###############################################
####### STATE MACHINE TRANSITION FUNCS ########
###############################################

func state_machine_general_transition(sms,verbose:bool):
	match [sms]:
		[STATE_MACHINE_SIGNALS.ROAD_BUTTON_SIG]:change_to_state_ROAD(verbose)
		[STATE_MACHINE_SIGNALS.DESTROY_BUTTON_SIG]:change_to_state_DESTROY(verbose)
		[STATE_MACHINE_SIGNALS.NODE_BUTTON_SIG]:change_to_state_NODE(verbose)
		[STATE_MACHINE_SIGNALS.CP_BUTTON_SIG]:change_to_state_CP(verbose)

func change_to_state_ROAD(verbose:bool):
	verbose_print("call change_to_state_ROAD",verbose)
	Input.set_custom_mouse_cursor($Button_road_create.mouse_icon)
	current_state=EDIT_STATES.ROAD
	pass
	
func change_to_state_DESTROY(verbose:bool):
	verbose_print("call change_to_state_DESTROY",verbose)
	Input.set_custom_mouse_cursor($Button_road_destroy.mouse_icon)
	current_state=EDIT_STATES.DESTROY
	pass
	
func change_to_state_NODE(verbose:bool):
	verbose_print("call change_to_state_NODE",verbose)
	Input.set_custom_mouse_cursor($Button_add_node.mouse_icon)
	current_state=EDIT_STATES.NODE
	pass
	
func change_to_state_CP(verbose:bool):
	verbose_print("call change_to_state_CP",verbose)
	Input.set_custom_mouse_cursor($Button_modify_cp.mouse_icon)
	current_state=EDIT_STATES.CP
	pass

func change_to_state_WAITING_ROAD_SECOND_NODE(verbose:bool):
	verbose_print("call change_to_state_WAITING_ROAD_SECOND_NODE",verbose)
	current_state=EDIT_STATES.WAITING_ROAD_SECOND_NODE
	pass

func change_to_state_MOVE_CP(verbose:bool):
	verbose_print("change_to_state_MOVE_CP",verbose)
	current_state=EDIT_STATES.MOVE_CP
	pass

func transition_from_WAITING_ROAD_SECOND_NODE_to_ROAD(verbose:bool):
	verbose_print("call transition_from_WAITING_ROAD_SECOND_NODE_to_ROAD",verbose)
	assert(savestate_last_road==null)
	assert(savestate_last_roadnode==null)
	assert(savestate_last_roadcp_index==-1)
	current_state=EDIT_STATES.ROAD

func transition_from_MOVE_CP_to_CP(verbose:bool):
	verbose_print("call transition_from_MOVE_CP_to_CP",verbose)
	savestate_last_road=null
	savestate_last_roadcp_index=-1
	current_state=EDIT_STATES.CP

####################################
######### BEGIN STATE MACHINE ######
####################################

#WARNING performance reduced when far_enougth_road() or far_enougth_node() are called for a sms POINTER_MOVE

func state_machine_ROAD(sms,verbose:bool):
	match [sms,far_enougth_road(),far_enougth_node()]:
		[STATE_MACHINE_SIGNALS.ROAD_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.DESTROY_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.NODE_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.CP_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		
		[STATE_MACHINE_SIGNALS.ACCEPT,true,true]:
			create_road_ex_nihilo(verbose)
			assert(current_state==EDIT_STATES.WAITING_ROAD_SECOND_NODE)
		[STATE_MACHINE_SIGNALS.ACCEPT,_,false]:
			create_road_connected_to_nearest_node(verbose)
			assert(current_state==EDIT_STATES.WAITING_ROAD_SECOND_NODE)
		[STATE_MACHINE_SIGNALS.ACCEPT,false,true]:
			verbose_print("too close from a road to create a road and too far from a node to connect to the node",verbose)
	pass

func state_machine_DESTROY(sms,verbose:bool):
	match [sms,far_enougth_road()]:
		[STATE_MACHINE_SIGNALS.ROAD_BUTTON_SIG,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.DESTROY_BUTTON_SIG,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.NODE_BUTTON_SIG,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.CP_BUTTON_SIG,_]:state_machine_general_transition(sms,verbose)
		
		[STATE_MACHINE_SIGNALS.ACCEPT,false]:destroy_nearest_road(verbose)
	pass

func state_machine_NODE(sms,verbose:bool):
	match [sms,far_enougth_road(),far_enougth_node(),far_enougth_nearest_road_projected_on_node()]:
		[STATE_MACHINE_SIGNALS.ROAD_BUTTON_SIG,_,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.DESTROY_BUTTON_SIG,_,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.NODE_BUTTON_SIG,_,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.CP_BUTTON_SIG,_,_,_]:state_machine_general_transition(sms,verbose)
		
		[STATE_MACHINE_SIGNALS.ACCEPT,false,_,true]:create_node_on_nearest_road_frag(verbose)
		[STATE_MACHINE_SIGNALS.ACCEPT,true,true,_]:create_node_on_mouse_pos(verbose)
		[STATE_MACHINE_SIGNALS.DENY,_,false,_]:delete_nearest_node(verbose)
	pass

func state_machine_CP(sms,verbose:bool):
	match [sms,far_enougth_road(),far_enougth_cp()]:
		[STATE_MACHINE_SIGNALS.ROAD_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.DESTROY_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.NODE_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		[STATE_MACHINE_SIGNALS.CP_BUTTON_SIG,_,_]:state_machine_general_transition(sms,verbose)
		
		[STATE_MACHINE_SIGNALS.ACCEPT,false,true]:add_a_control_point_on_the_nearest_road(verbose)
		[STATE_MACHINE_SIGNALS.ACCEPT,false,false]:move_the_nearest_control_point(verbose)
		[STATE_MACHINE_SIGNALS.DENY,_,false]:remove_nearest_control_point(verbose)
	pass

func state_machine_NONE(sms,verbose:bool):
	match sms:
		STATE_MACHINE_SIGNALS.ROAD_BUTTON_SIG:change_to_state_ROAD(verbose)
		STATE_MACHINE_SIGNALS.DESTROY_BUTTON_SIG:change_to_state_DESTROY(verbose)
		STATE_MACHINE_SIGNALS.NODE_BUTTON_SIG:change_to_state_NODE(verbose)
		STATE_MACHINE_SIGNALS.CP_BUTTON_SIG:change_to_state_CP(verbose)
		_:pass

func state_machine_WAITING_ROAD_SECOND_NODE(sms,verbose):
	match [sms,far_enougth_road(),far_enougth_node()]:
		[STATE_MACHINE_SIGNALS.POINTER_MOVE,_,_]:make_the_road_follow_cursor(verbose)
		[STATE_MACHINE_SIGNALS.ACCEPT,true,true]:
			connect_the_road_to_ex_nihilo_node(verbose) #WANING possible to create road with nodes that are very near from each other
			assert(current_state==EDIT_STATES.ROAD)
		[STATE_MACHINE_SIGNALS.ACCEPT,_,false]:
			connect_the_road_to_nearest_node(verbose) #WANING possible to create road where node_a==node_b and a length of 0
			assert(current_state==EDIT_STATES.ROAD)
		[STATE_MACHINE_SIGNALS.DENY,_,_]:deny_road_connection(verbose)
	pass

func state_machine_MOVE_CP(sms,verbose):
	match [sms]:
		[STATE_MACHINE_SIGNALS.POINTER_MOVE]: make_the_road_follow_cursor(verbose)
		[STATE_MACHINE_SIGNALS.ACCEPT]: accept_cp_position(verbose)
		[STATE_MACHINE_SIGNALS.DENY]: deny_cp_position(verbose)

func global_state_machine(sms,verbose:bool=false):
	verbose_print("#########################",verbose)
	verbose_print("current state :"+EDIT_STATES.keys()[current_state],verbose)
	verbose_print("sms :"+SMS.keys()[sms],verbose)
	match current_state:
		EDIT_STATES.ROAD:state_machine_ROAD(sms,verbose)
		EDIT_STATES.DESTROY:state_machine_DESTROY(sms,verbose)
		EDIT_STATES.NODE:state_machine_NODE(sms,verbose)
		EDIT_STATES.CP:state_machine_CP(sms,verbose)
		EDIT_STATES.NONE:state_machine_NONE(sms,verbose)
		EDIT_STATES.WAITING_ROAD_SECOND_NODE:state_machine_WAITING_ROAD_SECOND_NODE(sms,verbose)
		EDIT_STATES.MOVE_CP:state_machine_MOVE_CP(sms,verbose)
		_: raise_fatal_error( "unknow state ,state:"+ String(current_state))

####################################
#########  END  STATE MACHINE ######
####################################


# Called every frame. 'delta' is the elapsed time since the previous frame.


var last_mouse_position:Vector2=Vector2(0,0)
var rigth_click_was_toggled:bool=false
var left_click_was_toggled:bool=false

func manage_move_signal():
	var new_Position=get_local_mouse_position()
	if new_Position!=last_mouse_position:
		emit_signal("SIG_MOUSE_MOVE")
	last_mouse_position=get_local_mouse_position()

func manage_rigth_click_signal():
	var click_statement:bool=Input.get_mouse_button_mask()/2%2
	if rigth_click_was_toggled and not click_statement:
		emit_signal("SIG_MOUSE_RIGTH_CLICK")
	rigth_click_was_toggled=click_statement
	pass

func manage_left_click_signal():
	var click_statement:bool=Input.get_mouse_button_mask()%2
	if left_click_was_toggled and not click_statement:
		emit_signal("SIG_MOUSE_LEFT_CLICK")
	left_click_was_toggled=click_statement
	pass

func manage_signals_delta(delta):
	manage_move_signal()
	manage_rigth_click_signal()
	manage_left_click_signal()
	pass

func manage_signals_event(event):
	manage_move_signal()
	manage_rigth_click_signal()
	manage_left_click_signal()
	pass

func _process(delta):
	#Input.set_default_cursor_shape(Input.CURSOR_MOVE)
	#print(get_viewport().get_mouse_position())
	#manage_signals_delta(delta)
	#print(last_mouse_position)
	pass

func _input(event):
	manage_signals_event(event)
