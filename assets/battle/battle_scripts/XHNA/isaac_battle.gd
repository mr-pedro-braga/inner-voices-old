extends Node

var next_pattern = "punches"
var next_pool = "general"
var aff = ""

func battle_join():
	Utils.change_battle_bg("Delta")
	pass

func battle_turn_select(c, battle_round):
	if Gameplay.GAMEMODE != Gameplay.GM.BATTLE:
		return
	match battle_round:
		0:
			next_pool = "twistedhallways"
			DCCore.dialog("places/mrealm/mrealm_lines", "isaac_dodge")
			await DCCore.dialog_finished
			BattleCore.current_battle_line["dialog"] = "isaac_battle_1"
		1:
			DCCore.dialog("places/mrealm/mrealm_lines", "isaac_attackme")
			await DCCore.dialog_finished
			BattleCore.current_battle_line["dialog"] = "isaac_battle_2"
		2:
			next_pattern = "lasso"
			BattleCore.current_battle_line["dialog"] = "isaac_battle_3"
		_:
			if Utils.character_stats["isaac"]["attributes"]["HP"] < 6:
				if Gameplay.GAMEMODE != Gameplay.GM.BATTLE or spared:
					return
				match advice:
					0:
						DCCore.dialog("places/mrealm/mrealm_lines", "isaac_spare_end")
						await DCCore.dialog_finished
					1:
						DCCore.dialog("places/mrealm/mrealm_lines", "isaac_spare_please")
						await DCCore.dialog_finished
				advice += 1
				next_pool = "general"
				next_pattern = "wait"
				BattleCore.current_battle_line["dialog"] = "isaac_sparing"
			else:
				randomize()
				var attacks = ["lasso", "punches", "radial_escape"]
				attacks.shuffle()
				next_pattern = (attacks[0])
				BattleCore.current_battle_line["dialog"] = "isaac_battle_3"
	BattleCore.next_attack_name = {"pool":next_pool, "id":next_pattern}
	await get_tree().create_timer(0.2).timeout
	BattleCore.end_turn_intro()

var advice = 0
var spared = false

func act(_user, act_name):
	print("Thinking about ", act_name)
	match act_name:
		"help":
			DCCore.dialog("places/mrealm/mrealm_lines", "claire_help")
			await DCCore.dialog_finished
			Utils.emit_signal("act_finished")
		"spare":
			if Utils.character_stats["isaac"].attributes.HP < 6:
				Characters.map_characters[_user].animation_state.battle_action = "act_yes"
				DCCore.dialog("places/mrealm/mrealm_lines", "darwin_spare")
				await DCCore.dialog_finished
				spared = true
				Utils.emit_signal("act_finished")
				BattleCore.end_battle()
				#Characters.map_characters["isaac"].get_node("AnimationPlayer").play("Goodbye")
			else:
				DCCore.dialog("places/mrealm/mrealm_lines", "isaac_nospare")
				await DCCore.dialog_finished
				Utils.emit_signal("act_finished")
		_:
			await get_tree().create_timer(1.0).timeout
			Utils.emit_signal("act_finished")
	pass
