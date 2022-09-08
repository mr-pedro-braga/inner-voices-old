@tool
extends Node2D

@export var size: Vector2 = Vector2(3, 3):
	set(value):
		# TODO: Manually copy the code from this method.
		update_size(value)
@onready var back = get_node(^"BattleBox/Textures/Back")
@onready var border = get_node(^"BattleBox/Textures/Border")
@onready var border_sensor = get_node(^"BorderSensor/Collision2")
@onready var col = get_node(^"BattleBox/Collision")

@export var backs: Array[Texture2D]

var back_sprite = ""
func set_back(back_a):
	back.texture = backs[back_a]

func update_size(value):
	size = value
	if back != null:
		back.position = -size/2 * 10
		back.size = size * 10
		border.position = -size/2 * 10 - Vector2(3, 3)
		border.size = size * 10 + Vector2(6, 6)
		col.scale = size / 4
		border_sensor.scale = col.scale

func _process(_delta):
	if Engine.is_editor_hint():
		return
	border.modulate = Color.WHITE
	col.disabled = false
	if Utils.arena_status.hot_border:
		border.modulate = Color(1, 0.652893, 0.054688).lerp(Color(1, 0.143311, 0.054688), sin(10*Utils.time)*0.5+0.5)
	if Utils.arena_status.torus_border:
		border.modulate = Color(0.164063, 0.275085, 1)
		col.disabled = true
		if has_node("BattleBox/Kuro"):
			var k = get_node(^"BattleBox/Kuro")
			if k.position.x < back.position.x:
				k.position.x += back.size.x+4
			if k.position.x > back.position.x + back.size.x+4:
				k.position.x -= back.size.x+4
			if k.position.y < back.position.y:
				k.position.y += back.size.y+4
			if k.position.y > back.position.y + back.size.y+4:
				k.position.y -= back.size.y+4
	if Utils.arena_status.slippery_floor and back_sprite != "blue" :
		set_back(0)
		back_sprite = "blue"

@export var damage = {
	"amount": 0.1,
	"element": "fire",
	"type": "normal"
}

func _on_Damage_area_entered(area):
	if area.name == "KuroSensor":
		if Utils.arena_status.hot_border:
			Utils.damage(BattleCore.battle_target, damage)
			AudioManager.play_sound("SFX_Hurt")
