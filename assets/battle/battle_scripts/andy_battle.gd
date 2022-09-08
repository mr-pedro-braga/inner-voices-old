extends Node

var end = false
var spared = false
var hugged = false
var offended = false
var aff = ""

func battle_join():
	offended = false
	hugged = false
	spared = false
	Utils.change_battle_bg("PoolWaves")
	Utils.set_character_acts(Characters.playable_character, [
		{"id" : "bad_talk", "icon" : "talk_bad"},
		{"id" : "spare", "icon" : "spare"},
		{"id" : "hug", "icon" : "wait"},
	])
	DCCore.load_dialog_into_cache("places/new_horizon/school_lines")
	BattleCore.current_battle_line["file"] = "places/new_horizon/school_lines"
	BattleCore.current_battle_line["dialog"] = "null"
	print("Entered battle!")
	BattleCore.battle_round = 0

func battle_turn_select(c, battle_round):
	if Gameplay.GAMEMODE != Gameplay.GM.BATTLE:
		return
	randomize()
	BattleCore.current_battle_line["file"] = "places/new_horizon/school_lines"
	if spared:
		BattleCore.current_battle_line["dialog"] = "andy_battle_spared"
	else:
		BattleCore.current_battle_line["dialog"] = "andy_battle_comment"
	
	if end:
		BattleCore.end_battle()
		queue_free()
		return
	
	if BattleCore.battle_round == 0:
		# Create and add a kuro to the battle box
			var k = Utils.kuro_scene.instantiate()
			
			k.name = "Kuro"
			
			k.character = BattleCore.battle_target
			k.get_node(^"Anim").play(Characters.playable_character)
			
			# Set the size of the battle box.
			BattleCore.battle.get_node(^"Anim").play("roll_in_with_style")
			BattleCore.battle.visible = true
			BattleCore.battle.size = Vector2(3, 3)
			BattleCore.battle.get_node(^"BattleBox").add_child(k)
			# Message
			DCCore.dialog("places/new_horizon/school_lines", "andy_battle_0")
			await DCCore.dialog_finished
			BattleCore.next_attack_name["id"] = "null"
			# Destroy kuro
			k.queue_free()
			# Play battle box out animation
			BattleCore.battle.get_node(^"Anim").play("roll_out")
			BattleCore.end_turn_intro()
			return
	
	var attacks = Utils.character_stats[c.character_id]["attacks"]
	BattleCore.next_attack_name = attacks[(fposmod(battle_round, attacks.size()))]
	if spared:
		match BattleCore.battle_round:
			1:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_1_spared")
				await DCCore.dialog_finished
			2:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_2_spared")
				await DCCore.dialog_finished
			3:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_3_spared")
				await DCCore.dialog_finished
	else:
		match BattleCore.battle_round:
			1:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_1")
				await DCCore.dialog_finished
			2:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_2")
				await DCCore.dialog_finished
			3:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_3")
				await DCCore.dialog_finished
	await get_tree().create_timer(0.2).timeout
	BattleCore.end_turn_intro()

func act(_user, act_name):
	match act_name:
		"spare":
			Characters.map_characters[_user].animation_state.battle_action = "act_yes"
			if not spared:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_nospare")
				await DCCore.dialog_finished
				Characters.map_characters[_user].animation_state.battle_action = "idle"
			else:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_spare")
				await DCCore.dialog_finished
				end = true
			Utils.emit_signal("act_finished")
		"bad_talk":
			if not offended:
				if hugged:
					DCCore.dialog("places/new_horizon/school_lines", "andy_battle_offense_hg")
				else:
					DCCore.dialog("places/new_horizon/school_lines", "andy_battle_offense")
				await DCCore.dialog_finished
				offended = true
				spared = true
				BattleCore.current_battle_line["dialog"] = "andy_battle_spared"
			else:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_offense2")
				await DCCore.dialog_finished
			Utils.emit_signal("act_finished")
		"hug":
			if not hugged:
				if offended:
					DCCore.dialog("places/new_horizon/school_lines", "andy_battle_hug_of")
				else:
					DCCore.dialog("places/new_horizon/school_lines", "andy_battle_hug")
				await DCCore.dialog_finished
				hugged = true
				spared = true
				BattleCore.current_battle_line["dialog"] = "andy_battle_spared"
			else:
				DCCore.dialog("places/new_horizon/school_lines", "andy_battle_hug2")
				await DCCore.dialog_finished
			Utils.emit_signal("act_finished")
		_:
			await get_tree().create_timer(1.0).timeout
			Utils.emit_signal("act_finished")
	pass
