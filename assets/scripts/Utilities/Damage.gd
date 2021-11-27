extends Area2D

func _on_Damage_body_entered(body):
	if body.name == "Kuro":
		get_parent().on_hit(body)
		body.emit_signal("on_hit")
	if body.name == "bullet_destroyer" or body.name == "Shield":
		get_parent().on_hit_2(body)

func _on_Damage_body_exited(_body):
	pass # Replace with function body.
