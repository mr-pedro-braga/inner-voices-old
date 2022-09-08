#--------------------------------------------------------#
#
#		Another Series Gameplay
#	
#	Takes care of the CORE gameplay
#	sucha as loading worlds, scenes, and managing
#	game states.
#
#--------------------------------------------------------#

extends Node

##########

#
# @ Game State Variables
#

### If you are currently in a scene with characters
@export var is_playing_story = true
@export var is_game_running = false
@export var slider1 = 0.0

### Assets and references to important nodes.
var _Assets
@onready var world = get_node(^"/root/GameRoot/World3D") 				# RefCounted to the map container
@onready var transition_player = get_node(^"/root/GameRoot/Transition/TransitionPlayer") # RefCounted to the transition player

var has_finished_setting_up: bool # Setup finished

var LOADING:bool = false # Whether the game has loaded already or not
signal LOADING_FINISHED

### The initial configuration of the game when loaded.
var scene_space = "E01" # The folder where scenes are drawn from (the current episode).

##########

#
# @  Setting up the game
#

func _ready():
	#get_tree().get_root().set_transparent_background(true)
	#OS.window_per_pixel_transparency_enabled = true
	
	### Setup is complete!
	if get_node(^"/root").has_node("GameRoot"):
		is_game_running = true
	
	### Load the strings for my language
	print("-- Loading strings for the current language.")
	DCCore.load_strings()
	
	### Boot the character system
	print("-- Booting the Character System")
	Utils.character_system_init()
	
	### Setup the streeam players!
	print("-- Plugging in the Speakers!")
	SoundtrackCore.setup_stream_players()
	
	### Setup useful variables
	if OS.has_environment("USERNAME"):
		DCCore.strings["player_name"] = OS.get_environment("USERNAME")
	else:
		DCCore.strings["player_name"] = "player"
	
	### If starting on the is_playing_story, setup the is_playing_story.
	print("-- Done! Opening the Story's Book.")
	if has_node("/root/GameRoot"):
		if is_playing_story:
			setup_is_playing_story()

#@ Setup the is_playing_story, import the start scene and spawn the main character
func setup_is_playing_story():
	world.remove_child(get_node(^"/root/GameRoot/World3D/Scene"))
	
	LOADING = true
	
	var new_scene
	
	if ProjectSettings.get_setting("application/run/custom_first_scene") == "":
		Utils.async_load("res://assets/__tests/stest_scenes.tscn", {"id":"scene"})
	else:
		Utils.async_load(ProjectSettings.get_setting("application/run/custom_first_scene"), {"id":"scene"})
		print("-- Loading Main Scene: " + ProjectSettings.get_setting("application/run/custom_first_scene"))
	new_scene = load(ProjectSettings.get_setting("application/run/custom_first_scene")).instantiate()#(await Utils.scene_loaded).instance
	print("-- Scene Loaded: ", new_scene)
	
	world.add_child(new_scene)
	new_scene.name = "Scene"
	if not get_node(^"/root/GameRoot/World3D/Scene").has_node("3DObjects"):
		print("(!) Warning; not a valid room (missing 3DObjects node)!")
		return
	
	LOADING = false
	emit_signal("LOADING_FINISHED")
	
	### Call the scene's special ready method if it has one
	if new_scene.has_method("scene_ready"):
		new_scene.scene_ready()
	
	
	ScreenCore.setup()
	MenuCore.update_items()
	Characters.setup()
	BattleCore.setup_all()

###########################

func _process(delta):
	ScreenCore.process_camera(delta)

###########################

#
# @ Game Interaction Modes
#

var in_cutscene: bool = false
var in_event: bool = false
var in_dialog:bool = false
var in_ui: bool = false

# Game Mode
enum GM {
	OVERWORLD,
	BATTLE,
	BOSS,
	CUTSCENE
}
@onready var GAMEMODE = GM.OVERWORLD

##########

#
# @ Teleportation and switch between maps
#

### Warp between scenes or within a scene
func warp(scene:String, location:Vector2, transition="slide_black", angle=-1):
	Utils.async_load("res://episodes/"+scene_space+"/scenes/"+scene+".tscn")
	warp_scene(
		(await Utils.scene_loaded).loader,
		location,
		transition,
		angle
	)

func warp_by_path(path:String, location:Vector2, transition="slide_black", angle=-1):
	Utils.async_load(path)
	warp_scene(
		(await Utils.scene_loaded).loader,
		location,
		transition,
		angle
	)

func warp_scene(scene:PackedScene, location:Vector2, transition="slide_black", angle=1):
	LOADING = true
	Characters.map_characters = {}
	Characters.party_follower_path.get_curve().clear_points()
	transition_player.play(transition)
	Characters.playable_character_node.enabled = false
	await transition_player.animation_finished
	
	for i in range(Characters.party_character_nodes.size()):
		var c:Node = Characters.party_character_nodes[i]
		if c.get_parent() != null:
			c.get_parent().remove_child(c)
	
	await get_tree().create_timer(0.25).timeout
	var new_scene = scene.instantiate()
	world.remove_child(get_node(^"/root/GameRoot/World3D/Scene"))
	new_scene.name = "Scene"
	world.add_child(new_scene)
	var w = new_scene.get_node(^"3DObjects")
	if w:
		for index in range(Characters.party_character_nodes.size()):
			var i = Characters.party_character_nodes[index]
			i.name = i.character_id
			#Add in the new character
			w.add_child(i)
			Characters.map_characters[i.character_id] = i
			i.position = location
			i.mv_target = i.position
			i.input_vector = Vector2.ZERO
			i.velocity = Vector2.ZERO
		ScreenCore.global_camera.make_current()
		ScreenCore.global_camera.position = Characters.playable_character_node.position
		Characters.party_follower_path.get_curve().clear_points()
		if new_scene.has_method("scene_ready"):
			new_scene.scene_ready()
		if not angle == -1:
			Characters.playable_character_node.angle = angle
		Characters.playable_character_node.update_reference()
		Characters.playable_character_node.enabled = true
	transition_player.play(transition+"_out")
	emit_signal("LOADING_FINISHED")
	emit_signal("warp_completed")
	LOADING = false

signal warp_completed

### Warp between scenes or within a scene
func teleport(location, transition="slide_black", angle=-1):
	var t = get_node(^"/root/GameRoot/Transition/TransitionPlayer")
	t.play(transition)
	Characters.playable_character_node.enabled = false
	await get_tree().create_timer(0.25).timeout
	for i in range(Characters.party_character_nodes.size()):
		Characters.party_character_nodes[i].mv_target = location
		Characters.party_character_nodes[i].position = location
	Characters.party_follower_path.get_curve().clear_points()
	ScreenCore.global_camera.position = location - Vector2(0, 16)
	Characters.playable_character_node.enabled = true
	if not angle == -1:
		for c in Characters.party_character_nodes:
			c.angle = angle
	await get_tree().create_timer(0.25).timeout
	t.play(transition+"_out")
	#emit_signal("warp_completed")
	#emit_signal("LOADING_FINISHED")
