extends Node

@onready var global_camera = get_node(^"/root/GameRoot/World3D/Camera3D")	# RefCounted to the main camera
var character_camera_offset = -16
var zoom_offset = 0
var camera_position = Vector2.ZERO
var camera_attached := false
@export var zoom := 1.0:
	set(value):
		# TODO: Manually copy the code from this method.
		zoom = (value)
var zoom_drag := 1.0

func update_zoom_instant(_zoom):
	zoom = _zoom
	zoom_drag = zoom
	
func release_camera():
	camera_attached = false

func attach_camera():
	camera_attached = true

func set_camera_position(_position:Vector2):
	global_camera.position = _position

func process_camera(_delta):
	if not Gameplay.is_game_running or Gameplay.LOADING:
		return
		
	# Update Main Camera3D Zoom
	zoom_drag = move_toward(zoom_drag, zoom, 0.05)
	global_camera.zoom = Vector2(zoom_drag, zoom_drag)
	
	if Gameplay.is_playing_story and Characters.playable_character_node != null:
		match Gameplay.GAMEMODE:
			Gameplay.GM.OVERWORLD:
				character_camera_offset = - 16
				camera_position = Characters.playable_character_node.position + Vector2(0, character_camera_offset)
			Gameplay.GM.BATTLE:
				camera_position = lerp(
					BattleCore.battle.position,
					BattleCore.battlers[BattleCore.battle_turn].position,
					0.2
				)
		
	if camera_attached:
		global_camera.position = camera_position


######### SETTING UP

func setup():
	update_zoom_instant(1.2)
