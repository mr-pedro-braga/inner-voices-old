extends Node

#
#
#	Handles the entire system for dialogs, choices and
#	cutscene-related things like cameras and signals.
#
#

### The current language of the game
@export var lang: String = "world"

### The dialog box used to display the dialog
@onready var dialog_box = get_node(^"/root/GameRoot/HUD/bottom_black_bar/Dialog Label")

signal dialog_finished

### Useful UI strings
var strings:Dictionary = {}
### Dialog cache
var dialog_cache:Dictionary = {}
### Is currently writing some dialog
var is_writing:bool = false:
	set(value):
		# TODO: Manually copy the code from this method.
		update_speaking_character_anim(value)
### Is currently using portraits
var use_portraits:bool = true
### If in camera_beding_cutscene
var in_cutscene = false

var speaking_character:String = "" 
func update_speaking_character_anim(value):
	is_writing = value
	if Characters.map_characters == null:
		return

### Request Dialog from file!
func dialog_by_file(file:String, sub_id:String):
	var dialog_path = file.replace("res://episodes/" + Memory.get_episode_name() + "/dialogue/world/", "").replace(".sson", "")
	dialog(dialog_path, sub_id)

### Request Dialog from id.
func dialog(id, sub_id):
	Gameplay.in_dialog = true
	# Animate black bars!
	if not Gameplay.GAMEMODE == Gameplay.GM.BATTLE and not in_cutscene and not MenuCore.in_mmenu:
		get_node(^"/root/GameRoot/HUD/black_bars").play("dialog_pop_in")
		get_node(^"/root/GameRoot/HUD/black_bars_top").play("menu_in")
	# Stop Main character from walking!
	if Characters.playable_character_node:
		Characters.playable_character_node.stop()
	load_dialog_script(id)
	#DialogHandler.play(dialog_cache[id], sub_id)

func on_dialog_finished():
	emit_signal("dialog_finished")
	Gameplay.in_dialog = false
	deactivate_dialog_callers()

var SceneScript = load("res://assets/scripts/Game Architecture/SceneScript.gd")

### Loads a whole dialog file into cache so you have to load only once
func load_dialog_into_cache(file):
	if dialog_cache.has(file):
		return

	var text = Utils.load_as_text("res://episodes/" + Memory.get_episode_name() + "/dialogue/" + lang + "/" + file + ".json")
	var test_json_conv = JSON.new()
	test_json_conv.parse(text)
	#####dialog_cache[file] = test_json_conv.get_data()

###	Loads a ScreenScript file and parses it into Chroma RPG Alpha
#	compatible format!
func load_dialog_script(file):
	if dialog_cache.has(file):
		return
	var text = Utils.load_as_text("res://episodes/" + Memory.get_episode_name() + "/dialogue/" + lang + "/" + file + ".sson")

	dialog_cache[file] = SceneScript.parse_sson_cutscene(text)

### Clears the dialog cache to save memory
func clear_dialog_cache():
	dialog_cache = {}

### Loads useful UI strings
func load_strings():
	var file = File.new()
	file.open("res://episodes/" + Memory.get_episode_name() + "/dialogue/" + lang + "/strings.json", file.READ)
	var text = file.get_as_text()
	var test_json_conv = JSON.new()
	test_json_conv.parse(text)
	#####strings = test_json_conv.get_data()
	strings["item_name"] = "nothing"
	if OS.has_environment("USER"):
		strings["player"] = OS.get_environment("USER")
	else:
		strings["player"] = "player"

# Cutscenes!

func enter_cutscene():
	Utils.enter_event()
	if in_cutscene:
		return
	in_cutscene = true
	get_node(^"/root/GameRoot/HUD/black_bars").play("dialog_pop_in")
	get_node(^"/root/GameRoot/HUD/black_bars_top").play("menu_in")

func leave_cutscene():
	Utils.leave_event()
	if not in_cutscene:
		return
	in_cutscene = false
	get_node(^"/root/GameRoot/HUD/black_bars").play("dialog_pop_out")
	get_node(^"/root/GameRoot/HUD/black_bars_top").play("menu_out")

#
# @ Choices and choice related stuff.
#

### If there is a choice going on rn
var in_choice: bool = false
### The result of the choice
var choice_result:int = 0
### If you're selecting an item with your kuro
var kuro_select:bool = false

signal choice_selected(index)
signal choice_finished(status)

### Request a choice
func choice (question:String, choices, icons, offset=0, _dialog_box=dialog_box, mode=0, text_pos=0):
	var ChoiceNode: Choice = Choice.new()
	ChoiceNode.display = mode
	ChoiceNode.dialog_box = _dialog_box
	ChoiceNode.question = question
	ChoiceNode.choices = choices
	ChoiceNode.choice_icons = icons
	ChoiceNode.text_pos = text_pos
	get_node(^"/root/GameRoot/WorldUI/").add_child(ChoiceNode)
	ChoiceNode.init_icons()
	match Gameplay.GAMEMODE:
		0:
			ChoiceNode.position = Characters.playable_character_node.position + Vector2(0, offset)
		1:
			pass#ChoiceNode.position = BattleCore.battlers[BattleCore.battle_turn]["position"] + Vector2(0, offset)

### Character select
func char_choice (question:String, characters, text_pos=0):
	var ChoiceNode: CharChoice = CharChoice.new()
	ChoiceNode.question = question
	ChoiceNode.choices_chars = characters
	ChoiceNode.text_pos = text_pos
	get_node(^"/root/GameRoot/WorldUI/").add_child(ChoiceNode)

### DIALOG EVENTS ###

var _dialog_callers := []

func add_dialog_caller(dc:DialogEvent):
	_dialog_callers.append(dc)

func deactivate_dialog_callers():
	for i in _dialog_callers:
		i._deactivate()
	_dialog_callers = []
