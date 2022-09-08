extends DefaultScene

@onready var camera = get_node(^"Camera2D")
@onready var andy = get_node(^"3DObjects/andy")
@onready var bruno = get_node(^"3DObjects/bruno")

@export var debug: bool

func evt_exit(_id, _parameter, _arguments):
	if not Memory.has_switch("joke_1") and not debug:
		DCCore.dialog("places/new_horizon/school_lines", "library_dont_leave")
		await DCCore.dialog_finished
	else:
		if Memory.sget("joke_1") or debug:
			Memory.switch(Memory.EPISODE, "section", 1)
			Gameplay.warp(_parameter, _arguments[0], _arguments[1], _arguments[2])
		else:
			DCCore.enter_cutscene()
			DCCore.dialog("places/new_horizon/school_lines", "library_leave_attack_1")
			_id.queue_free()
			Memory.switch(Memory.EPISODE, "section", 1)
			await DCCore.dialog_finished
			Gameplay.warp(_parameter, _arguments[0], _arguments[1], _arguments[2])

func evt_andy(_id, _parameter, _arguments):
	if debug:
		Characters.add_party_member("andy")
		return
	if Memory.has_switch("joke_1"):
		return
	Utils.enter_event()
	Memory.switch(Memory.EPISODE, "joke_1", false)
	#andy.action = "sit_look"
	DCCore.dialog("places/new_horizon/school_lines", "library_talk_andy")
	await DCCore.dialog_finished
	Utils.leave_event()
	Characters.add_party_member("andy")

func _ready():
	if not Memory.has_switch("entered_library"):
		
		SoundtrackCore.preload_music("mus_vn_tension.wav")
		SoundtrackCore.load_music("mus_new_horizon_night", "Syncopation")
		
		Memory.switch(Memory.EPISODE, "section", 1)
		
		if debug:
			return
		
		Utils.enter_event()
		Utils.play_transition("set_black")

		var dialog_box = DCCore.dialog_box
		
		var k = dialog_box.position.y

		await get_tree().create_timer(0.5).timeout
		Utils.play_transition("set_black")
		
		DCCore.use_portraits = false
		dialog_box.position.y = -55
		DCCore.dialog("places/new_horizon/school_lines", "cutscene_2_1")
		await DCCore.dialog_finished

		dialog_box.position.y = -65
		DCCore.dialog("places/new_horizon/school_lines", "cutscene_2_2")
		await DCCore.dialog_finished
		DCCore.use_portraits = true

		dialog_box.position.y = k
		await get_tree().create_timer(1.0).timeout

		Utils.play_transition("set_clear")
		ScreenCore.global_camera.clear_current()
		$Camera2D.make_current()

		DCCore.dialog("places/new_horizon/school_lines", "cutscene_2_3")
		await DCCore.dialog_finished

		Utils.leave_event()

func _process(_delta):
	camera.offset = Vector2(0, 0.5*(135 - get_node(^"/root/GameRoot/HUD/bottom_black_bar").position.y))
