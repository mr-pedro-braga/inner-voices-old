tool
extends KinematicBody2D
class_name Character


#-----------------------------------------#
#
#   Chroma RPG 1.0.0
#     "Character.gd"
#          Those pesky little guys that
#         move around in move routes or
#         are controlled by a player.
#
#-----------------------------------------#

#---------------SIGNALS-----------------#
signal route_line_finished
signal route_finished
#---------------------------------------#

#-----------------------------------------#
### Character ID for movements and such ###
#-----------------------------------------#

# The Character's ID (in lowercase, please)
export(String) var character_id = "claire"
export(String, "ALLY", "OPPONENT") var alignment = "OPPONENT"
var is_party_member := false
var party_index := 0

#-----------------------------------------#
#   Movement Variables
#-----------------------------------------#
export var enabled := true
export var current := false
var ignoring_inputs := true
var in_cutscene := false

var animation_state := {
	"lock_animation": false,
	"lock_animation_name": "",
	"ovw_action": "idle",
	"ovw_action_lock": false,
	"ovw_angle": 2,
	"ovw_angle_lock": false,
	"battle_action": "idle",
	"battle_facing": "left",
	
	"using_angle": true,
	"prefix": ""
}


#-----------------------------------------#
export var attacks = ""
export var char_stats_file = "claire.attacks"
#-----------------------------------------#
var is_running := false
var in_route := false
var in_path := false
var velocity := Vector2.ZERO
var input_vector := Vector2.ZERO
var last_input_vector := Vector2.DOWN
var mv_target := Vector2.ZERO
export var angle := 2 setget set_angle
export var Z := 0

func set_angle(value):
	angle = value
	animation_state.ovw_angle = value

# The current movement route
var mv_route: Array = []
var current_mv_instruction_index = 0
var current_mv_instruction = {}
var EPSILON = 0.1

# Battle Variables
var world_parent
var world_position := Vector2.ZERO
#-----------------------------------------#
var acceleration := 640
var friction := 640
var max_speed := 64
var max_speed_multiplier := 1
#-----------------------------------------#


#-----------------------------------------#


#-----------------------------------------#
#  UTILITY FUNCTIONS
#-----------------------------------------#

# Loads this character stats into Utils::character_stats.
func load_options():
	Utils.load_stats(character_id, char_stats_file, alignment)

# Make this character face the center of the Battle.
func face_center():
	if position.x < BattleCore.battle.position.x:
		scale.x = -abs(scale.x)
	else:
		scale.x =  abs(scale.x)

# Sets the overworld SOUL effect transparency.
func set_fx_soul_intensity(value:bool):
	#$AnimatedSprite.material.set_shader_param("soul_effect_intensity", value)
	pass

# Set wheter this character is being highlighted.
func set_highlited(value:bool):
	#$AnimatedSprite.material.set_shader_param("is_highlighted", value)
	pass

# Updates the current animation to "anim", if it exists.
func set_animation(anim:String):
	if $AnimatedSprite.frames.has_animation(anim) and $AnimatedSprite.animation!=anim and $AnimatedSprite.animation!=anim+"_talk":
		$AnimatedSprite.play(anim)

func set_animation_property(property:String, value):
	animation_state[property] = value

func get_animation_property(property:String):
	return animation_state[property]

func update_animation():
	$AnimationHandler._animate()

#-----------------------------------------#
#  PHYSICS AND MOTION
#-----------------------------------------#

# Halt every action.
func stop():
	is_running = false
	mv_target = position
	input_vector = Vector2.ZERO
	velocity = Vector2.ZERO

# Updates the position, for party followers.
func process_party_member(_i, _delta):
	if Gameplay.in_dialog:
		return
	mv_target = Characters.party_follower_path.get_child(_i-1).position

# Updates the path, for the party leader.
var last_pos: Vector2 = Vector2.ZERO
func add_follower_point(_point: Vector2):
	var pathio = Characters.party_follower_path
	var curve : Curve2D = pathio.get_curve()
		
	if position.distance_to(last_pos) > 12:
		curve.add_point(position)
	else:
		curve.set_point_position(curve.get_point_count() - 1, position)
	
	var size = curve.get_baked_length()
	
	if size > 64:
		curve.remove_point(0)
	
	var p = pathio.get_children()
	for f in range(p.size()):
		p[f].offset = size - 24 * (f+1)

### Physics ###
func _physics_process(delta):
	update()
	if Engine.editor_hint:
		return # FROM HERE, CODE ONLY RUNS IN RUNTIME
	
	# If this character is moving, and the angle isn't locked, set it to face the current velocity.
	if not animation_state.ovw_angle_lock and input_vector:
		animation_state.ovw_angle = round(fposmod(last_input_vector.angle() * 8/TAU, 8))
	
	#---------------#
	#  Input
	#---------------#
	
	if not (ignoring_inputs) and not Gameplay.GAMEMODE == Gameplay.GM.BATTLE and not in_route:
		
		# If this character is the playable character (and the party leader!)
		if character_id == Characters.playable_character:
			# Generate the input vector from the appropriate actions set in Project Settings.
			input_vector = Vector2(
				Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
				Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
			)
				
			# Halt every action as you enter an event, a menu or a dialog.
			if (Gameplay.in_event or Gameplay.in_ui or Gameplay.in_dialog):
				stop()
		
		# If this character isn't the party leader.
		elif is_party_member:
				# Do whatever needs to be done as a party member.
				process_party_member(party_index, delta)
				
				# Synchronize it's MAX_SPEED_MULTIPLIER with the party leader.
				max_speed_multiplier = Characters.playable_character_node.max_speed_multiplier
				
				# Move toward its target, otherwise, stop with no acceleration at all.
				if (mv_target- get_position()).length() > 2 and (mv_target- position).length() > 0:
					input_vector = (mv_target- get_position())
				else:
					stop()
		
		# Halt every action as you enter an event, a menu or a dialog.
		if (Gameplay.in_ui or Gameplay.in_dialog or Gameplay.in_event):
			stop()
		
		# Normalize the input vector if it is not null.
		input_vector = input_vector.normalized() if input_vector != Vector2.ZERO else Vector2.ZERO
	
	#---------------#
	#  Movement
	#---------------#
	
	# If walking
	if input_vector != Vector2.ZERO:
		# Store the input vector
		last_input_vector = input_vector
		# Accelerate (with cap) towards the input arrow (input_vector * speed)
		velocity = velocity.move_toward((last_input_vector if is_running else input_vector) * max_speed, acceleration * delta)
	else:
		# If not walking, slow down.
		velocity = velocity.move_toward(Vector2.ZERO, min(friction * delta, velocity.length()))
	
	# If in a movement route, process it here.
	if in_route:
		process_route(delta)
	
	# If character is enabled (and not in battle), move it.
	if enabled and not Gameplay.GAMEMODE == Gameplay.GM.BATTLE:
		move_and_slide(velocity)
		# If character is not in a cutscene.
		if not in_cutscene and not Gameplay.in_event and is_party_member:
			
			# RUNNING!
			# When you release the charge button, toggle running.
			# While running, the max_speed is multiplied by a big value.
			if Input.is_action_just_released("move_run_charge"):
				is_running = !is_running
			if not Input.is_action_pressed("move_run_charge") and is_running:
				max_speed = 128*max_speed_multiplier
				# If this character is running, set its velocity to the maximum with no acceleration.
				velocity = max_speed * last_input_vector
			
			# SNEAKING...
			# When you press the sneak button, your speed is drastically decreased.
			elif Input.is_action_pressed("move_sneak"):
				max_speed = 32*max_speed_multiplier
			else:
				max_speed = 64*max_speed_multiplier
			
			# UPDATE ACTIONS!!!
			# If this character is updating actions.
			if not animation_state.ovw_action_lock:
				# If this character is the main character, update its position and all in Gameplay.
				if character_id == Characters.playable_character:
					Characters.mainchar_moving = velocity != Vector2.ZERO
				
				# Update actions between running, walking, charging the run.
				if velocity or in_path:
					# Set the action to "run" if this character is running, otherwise just walk.
					animation_state.ovw_action = "run" if is_running else "walk"
				elif animation_state.ovw_action in ["run_charge", "idle", "run", "walk"]:
					# Set the action to "run_charge" if the charge button is pressed.
					animation_state.ovw_action = "run_charge" if Input.is_action_pressed("move_run_charge")  else "idle"
	
	# Update the damn animation.

### Movement Routes! ###
# They are kind of like animations, but by programming.

# Move along a given route.
func move_route(_route):
	if _route != []:
		mv_route = _route
		play_route()

# Move along a given path, by setting up a movement_route for it.
func move_along(_path:Path2D):
	mv_route = []
	_path.curve.set_point_position(0, position)
	_path.get_child(0).offset=0
	mv_route.append({"type":"path", "path":_path})
	in_route = true
	if character_id == Characters.playable_character:
		add_follower_point(position)
	play_route()

# Start playing the given movement_route.
func play_route():
	in_route = true
	
	# Reset route_specific variables
	current_mv_instruction_index = 0
	t = 0
	p0 = Vector2.ZERO
	started = false
	
	# Halt player
	stop()
	
	# Play all the instructions
	while current_mv_instruction_index < mv_route.size():
		current_mv_instruction = mv_route[current_mv_instruction_index]
		current_mv_instruction_index+=1
		yield(self, "route_line_finished")
	
	# Reset the route and max_speed.
	mv_route = []
	max_speed = 64
	current_mv_instruction = {}
	
	# Update variables
	in_route = false
	in_path = false
	emit_signal("route_finished")

#-----------------------#
var t = 0
var p0 = Vector2.ZERO
var started
var path:Path2D
var poff:PathFollow2D
#-----------------------#

# Process the current movement_route.
func process_route(delta):
	var backup = current_mv_instruction
	if not current_mv_instruction.has("type"):
		emit_signal("route_line_finished")
		return
	match current_mv_instruction["type"]:
		"speed":
			# Set the current maximum speed.
			max_speed = current_mv_instruction["value"]
			emit_signal("route_line_finished")
		"goto":
			# Go to a different point in this movement route.
			current_mv_instruction_index = current_mv_instruction["line"]
			emit_signal("route_line_finished")
		"lock_angle":
			# Lock the angle.
			animation_state.ovw_angle_lock = true
			emit_signal("route_line_finished")
		"unlock_angle":
			# Unlock the angle.
			animation_state.ovw_angle_lock = false
			emit_signal("route_line_finished")
		"append_path":
			# Move the start of a path towards this character.
			path = current_mv_instruction["path"]
			path.curve.set_point_position(0, position)
			path.get_child(0).offset=0
			emit_signal("route_line_finished")
		"path":
			# Move along a path.
			if not started:
				in_path = true
				started = true
				path = current_mv_instruction["path"]
				poff = path.get_child(0)
			poff.offset += max_speed * delta
			animation_state.ovw_action = "walk"
			position = poff.position
			angle = int(round((fposmod(poff.rotation_degrees/45, 8))))
			if poff.unit_offset >= 1:
				emit_signal("route_line_finished")
				started=false
				in_path = false
		"absolute":
			# Move very much not relative to the world.
			if not started:
				p0 = position
				started = true
			t+=delta
			var t2 = Vector2(current_mv_instruction["target"][0], current_mv_instruction["target"][1])
			input_vector = (t2 - p0).normalized()
			velocity = input_vector * max_speed
			if t >= p0.distance_to(t2)/max_speed:
				input_vector = Vector2.ZERO
				velocity = Vector2.ZERO
				t=0
				started=false
				emit_signal("route_line_finished")
		"delta":
			# Move relative to the current position.
			if not started:
				p0 = position
				started = true
			t+=delta
			var t2 = Vector2(current_mv_instruction["target"][0], current_mv_instruction["target"][1])
			var ttt = p0 + t2
			input_vector = (ttt - p0).normalized()
			velocity = input_vector * max_speed
			if t >= p0.distance_to(ttt)/max_speed:
				input_vector = Vector2.ZERO
				velocity = Vector2.ZERO
				t=0
				started=false
				emit_signal("route_line_finished")
		"dialog":
			# Call a dialog real quick.
			Gameplay.dialog(current_mv_instruction["file"], current_mv_instruction["block"])
			yield(get_node("/root/GameRoot/Dialog"), "dialog_section_finished")
			emit_signal("route_line_finished")
		"wait":
			# Wait for a custom amount of time, without using yield().
			if not started:
				t=0
				started = true
			t+=delta
			if t>=backup["amount"]:
				t=0
				started=false
				emit_signal("route_line_finished")
		"anim":
			# Play a very custom animation.
			
			# TO DO
			
			emit_signal("route_line_finished")
		"action":
			# Set the action and update the animation.
			animation_state.ovw_action = current_mv_instruction.value
			$AnimationHandler._animate()
			emit_signal("route_line_finished")
		"dir":
			# Set the direction immediately.
			animation_state.ovw_angle = current_mv_instruction["angle"]
			$AnimationHandler._animate()
			emit_signal("route_line_finished")
		"face_position":
			# Face a certain target position
			var _tp = current_mv_instruction["position"]
			
			animation_state.ovw_angle = fposmod(int(position.angle_to(_tp) / 8), 8)
			
			emit_signal("route_line_finished")
		"destroy":
			# Commit suicide.
			emit_signal("route_line_finished")
			emit_signal("route_finished")
			queue_free()

#-----------------------------------------#
#  EXTRA PROCESSING
#-----------------------------------------#

func _ready():
	if Engine.editor_hint: return
	
	# Update its reference in Party::map_characters
	update_reference()

func update_reference():
	Characters.map_characters[character_id] = self
	if current:
		Characters.set_playable_character(character_id)
		print("playing as ", character_id)
		ScreenCore.attach_camera()

### Events ###
func _process(_delta):
	
	### Cast Raycast to correct position in order to interact with events!
	var a = animation_state.ovw_angle * 45
	get_node("RayCast2D").cast_to = 10 * Vector2(cos(deg2rad(a))*1.5, sin(deg2rad(a)))
	
	if Engine.editor_hint: return
	
	### If this character is the main character, leave a trail of positions for the party followers to follow.
	if character_id == Characters.playable_character:
		if in_route or not velocity == Vector2.ZERO:
			add_follower_point(position)
	
	# Ignore the inputs in these situations.
	if not Gameplay.GAMEMODE == Gameplay.GM.OVERWORLD or Gameplay.in_event or Gameplay.in_ui or Gameplay.in_dialog or Gameplay.in_cutscene or not enabled:
		ignoring_inputs = true
	else:
		ignoring_inputs = false
	
	$AnimationHandler._animate()

## Configuration Warnings
func _get_configuration_warning():
	if get_node_or_null("AnimationHandler") == null:
		return 'Character Nodes need an Animation Handler, you know?'
	return ''
