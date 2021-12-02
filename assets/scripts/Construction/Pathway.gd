tool
extends EventReference
class_name PathwayEvent

#
#
# @ General Events Class!
#
# Useful for general events here and there.
#

export(String, FILE, "*.tscn") var target_scene = null
export(Vector2) var target_position = Vector2(0, 0) setget set_target_position
export(EventReference.CharacterDirection) var target_facing_direction = CharacterDirection.KEEP
export(String, "slide_black", "diamonds_black", "set_black", "fade_black") var transition = "slide_black"

func _process(_delta):
	if not texture:
		texture = preload("res://assets/images/editor_only/icon_event_pathway.png")
	if not color:
		color = Color(0.098039, 0.619485, 1, 0.321569)

func set_target_position(value):
	target_position = value
	update()

func _draw():
	
	if not draw_debug:
		return
	
	#if Engine.editor_hint:
		if target_scene:
			draw_set_transform(- trigger_area / 2 - Vector2(0, 4), 0, Vector2(0.3, 0.3))
			draw_string(
				font,
				Vector2.ZERO,
				target_scene.split("/")[-1].replace(".tscn", ""),
				Color.white
			)
			
		var world_target_position = target_position - position
		var wtg = world_target_position.normalized()
		
		draw_circle(world_target_position, 0.525, Color.aqua)
		var arrow_origin := Vector2.ZERO
		
		arrow_origin = arrow_origin.move_toward(world_target_position, 8)
		draw_line(arrow_origin, world_target_position, Color.aqua, 1.05)
		draw_line(world_target_position, world_target_position-wtg.rotated(-TAU/8)*4, Color.aqua, 1.05)
		draw_line(world_target_position, world_target_position-wtg.rotated(+TAU/8)*4, Color.aqua, 1.05)

# When this event gets activated
func _on_activated():
	if not target_scene or target_scene == "":
		Gameplay.teleport(target_position, transition, target_facing_direction)
		return
	Gameplay.warp_by_path(target_scene, target_position, transition, target_facing_direction)
