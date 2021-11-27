extends DefaultScene

func scene_ready():
	SoundtrackCore.load_music("mus_new_horizon.wav", "New Horizon")
	SoundtrackCore.bgm_resume()
	
	Characters.set_playable_character("claire")
	ScreenCore.attach_camera()

func _process(delta):
	if not Gameplay.in_event and Gameplay.GAMEMODE != Gameplay.GM.BATTLE and Input.is_action_just_pressed("cheat"):
		DCCore.enter_cutscene()
		DialogHandler.playc("", "",
			[
				"Fight Lily",
				"Get Food Items!",
				"Start Music",
				"Add Party Member"
			],
			["fight", "ch_bruno", "act", "game"],
				-16, 0)
		yield(DCCore, "choice_selected")
		DCCore.leave_cutscene()
		match DCCore.choice_result:
			0:
				ScreenCore.update_zoom(1.0)
				BattleCore.request_battle(["lily"], true, true)
			1:
				print("Cheated")
				MenuCore.inventories["claire"].give_item("pepperoni_pizza", 3)
				MenuCore.inventories["claire"].give_item("paçoca", 4)
				MenuCore.inventories["claire"].give_item("mana_pop", 1)
				MenuCore.inventories["claire"].give_item("flame_chips", 2)
				MenuCore.inventories["claire"].give_item("burger", 4)
				#Gameplay.warp("ClioRoom", Vector2(0.0, 0.0))
				#SoundtrackCore.bgm_restart()
			2:
				pass
			3:
				print("Attempt to add party member!")
				Characters.add_party_member("andy")
				print(Characters.party)
				#Gameplay.add_party_member("lily")

func evt_testevent(_id, _parameter, _arguments):
	DCCore.dialog("places/new_horizon/one_liners", "subspace")
	yield(get_node("/root/GameRoot/Dialog"), "dialog_section_finished")
	Gameplay.warp("NHC/XHNA/Hallways", Vector2(0, 64), "slide_black", 2)

# Runs a simple dialogue that will repeat again exactly the same when you call this function again.
func evt_simple_dialogue(_id, _parameter, _arguments):
	DCCore.dialog(_parameter, _arguments[0])
