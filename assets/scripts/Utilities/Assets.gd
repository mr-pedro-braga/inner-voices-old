extends Node

### The scene for the SOUL, the thing that dodges in the battle box.
const kuro_scene = preload("res://assets/battle/Kuro.tscn")
const info_scene = preload("res://assets/scene_components/SoulInfo.tscn")

export(Array, PackedScene) var scene_assets

onready var choice_nametag = load("res://assets/scene_components/SelectionNametag.tscn")

### The transition player located at game_root
onready var transition_player: AnimationPlayer = get_node("/root/GameRoot/Transition/TransitionPlayer")

### The box that shows the content of choices
onready var selected_choice_box: RichTextLabel = get_node("/root/GameRoot/HUD/ChoiceDisplay")

var character_anim_frame_paths = {
	"andy": "res://assets/characters/andy/Andy.res",
	"claire": "res://assets/characters/claire/S_claire.tres",
	"bruno": "res://assets/characters/bruno/S_Bruno.tres",
	"rodrick": "res://assets/characters/rodrick/Rodrick.tres",
}

func _ready():
	get_parent().call_deferred("remove_child", self)

func get_asset(asset):
	return get_node(asset)
