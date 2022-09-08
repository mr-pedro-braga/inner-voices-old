@tool
extends Area2D
class_name EventReference

var texture:Texture2D
var color:Color
var draw_debug:bool = true
var font:Font = preload("res://assets/fonts/8BitOperator.tres")

enum TriggerMode {NEVER=-1, ON_TOUCH=0, ON_INTERACT=1, ON_INTERACT_FACING=2, ON_CONTINUOUS_TOUCH=3, EXISTS=4}
enum CharacterDirection {KEEP = -1, EAST = 0, SOUTHEAST = 1, SOUTH = 2, SOUTHWEST = 3, WEST = 4, NORTHWEST = 5, NORTH = 6, NORTHEAST = 7}

@export var trigger_mode: TriggerMode
@export var trigger_area: Vector2 = Vector2(64, 16):
	set(value):
		# TODO: Manually copy the code from this method.
		set_trigger_area(value)
@export var trigger_once: bool = false

var overlapping: bool = false
var activated: bool = false

func _ready():
	if not is_connected("body_entered", _event_body_entered):
		connect(&"body_entered", self._event_body_entered)
		connect(&"body_exited", self._event_body_exited)
	if not Engine.editor_hint:
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.extents = trigger_area / 2
		shape.shape = rectangle
		add_child(shape)

#@ A virtual function that should be implemented by each event type.
func _on_activated():
	pass

# Draws the gizmo.
func _draw():
	
	if not draw_debug:
		return
	
	var area = Vector2(float(trigger_area.x), float(trigger_area.y))
	var top_left = - area / 2
	color.a = 0.3
	draw_rect(Rect2(top_left, area), color, true, 1.0)
	color.a = 1.0
	draw_rect(Rect2(top_left, area), color, false, 1.05)
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	if not texture:
		return
	draw_texture(texture, Vector2(-4, -4), Color.WHITE)

# Process the activation of the event.
func _process(_delta):
	
	update()
	draw_debug = true
	if (not Engine.editor_hint):
		draw_debug = global_debug.display_events
		if Gameplay.LOADING:
			return
	
	if activated:
		return
	
	if trigger_mode == TriggerMode.EXISTS:
		_on_activated()
		if trigger_once:
			queue_free()
		return
	if (overlapping
		and not Gameplay.in_dialog
		and not Characters.map_characters[Characters.playable_character].in_route
		and not Gameplay.in_event ):
			if Input.is_action_pressed("ghost"):
				return
			match trigger_mode:
				3:
					_on_activated()
					if trigger_once:
						activated = true
				2:
					if Input.is_action_just_pressed("ok"):# and Gameplay.playable_character_node.angle >= min_facing_angle and Gameplay.playable_character_node.angle <= max_facing_angle:
						_on_activated()
						if trigger_once:
							activated = true
				1:
					if Input.is_action_just_pressed("ok"):
						_on_activated()
						if trigger_once:
							activated = true
				0:
					if not activated:
						_on_activated()
						activated = true

func _event_body_entered(body:Node2D) -> void:
	if body is Character and body.character_id == Characters.playable_character:
		overlapping = true

func _event_body_exited(body) -> void:
	if body is Character and body.character_id == Characters.playable_character:
		overlapping = false
		if not trigger_once:
			activated = false

func set_trigger_area(value):
	trigger_area = value
	update()
