tool
extends Node2D
class_name CharacterAnimationHandler

enum {
	DIRECTIONAL_8 = 0,
	DIRECTIONAL_4 = 1,
	ACTIONS_ONLY = 2
}

export var enabled = true
export var animation_mode = DIRECTIONAL_8
export(NodePath) var animation_target_path
var animation_target : AnimationPlayer
var parent : Character

export(Resource) var animation_scheme


func _ready():
	animation_target = get_node(animation_target_path)
	parent = get_parent()

func _animate():
	if not enabled:
		return
		
	if not animation_target:
		return
	
	if Engine.editor_hint:
		_update_animation_editor()
	else:
		_update_animation()

func set_property(property, value):
	parent.animation_state[property] = value

func get_property(property):
	return parent.animation_state[property]

# Calculate the animation to play based on the action and angle.
func _update_animation():
	update()
	
	if parent.velocity.length() >= 4:
		parent.animation_state.ovw_action = "walk"
	else:
		parent.animation_state.ovw_action = "idle"
	
	animation_scheme.state = parent.animation_state
	
	if animation_target.has_animation(animation_scheme.get_animation_name()):
		animation_target.play(animation_scheme.get_animation_name())

# Calculate the animation to play based on the action and angle (works in editor).
func _update_animation_editor():
	animation_target.play(animation_scheme.get_animation_name())

func fwrap(x, m):
	return fposmod(x, m) if x >= 0 else fposmod(x + 1, m)
