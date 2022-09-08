extends CanvasLayer

var soul_trait = "#ffffff"
var game_started = false
var game_running = false
var game_canceled = false
var minigame_timeout = 6.0
var minigame_wait_timeout = 2.0
var minigame_level = 1.0

@export var infinite := false

var target

func _ready():
	if get_parent() is Node2D:
		offset = get_parent().position

func _process(_delta):
	if minigame_timeout < 0.0 and game_running and not infinite:
		game_running = false
		Utils.emit_signal("minigame_finished")
		queue_free()
	if minigame_wait_timeout < 0.0 and not game_canceled:
		AudioManager.play_sound("SFX_Hurt")
		end(1.0)
		game_canceled = true

func end(delay):
	await get_tree().create_timer(delay).timeout
	Utils.emit_signal("minigame_finished")
	queue_free()
