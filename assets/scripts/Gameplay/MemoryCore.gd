#--------------------------------------------------------#
#
#		Another Series Memory Core
#	
#	Takes care of the switches, and saving and loading
#	between episodes and play sessions.
#
#--------------------------------------------------------#

extends Node

enum {
	PERMANENT, EPISODE, SESSION
}

# The whole memory of the game (what gets saved and loaded)

var memory = {
	"progression": {
		"episode": 1,
		"act": 0
	},
	
	"save_data": {
		"player_name": "Player",
		"place_name": "[No Entry]",
		"hours": 0,
		"minutes": 0,
		"seconds": 0,
		"save_scene": "NHC/House_Claire/Claire-Start-Dream.tscn",
		"party": [],
		"character_stats": null,
		"inventories": [],
	},
	
	PERMANENT: {
		
	},
	
	EPISODE: {
		
	},
	
	SESSION: {
		
	}
}

# Save and Load Game
func save_game ( where:String, scene:String ):
	memory.save_data.place_name = where
	var playtime = Utils.playtime()
	memory.save_data.hours   = playtime.hours
	memory.save_data.minutes = playtime.minutes
	memory.save_data.seconds = playtime.seconds
	memory.save_data.party = Gameplay.party
	memory.save_data.character_stats = Utils.character_stats
	memory.save_data.inventories = MenuCore.inventories

func resume_game ():
	var playtime = {}
	playtime.hours        = memory.save_data.hours
	playtime.minutes      = memory.save_data.minutes
	playtime.seconds      = memory.save_data.seconds
	
	Utils.time    = 0
	Utils.time   += playtime.hours * 3600
	Utils.time   += playtime.minutes * 60
	Utils.time   += playtime.seconds
	
	Gameplay.party        = memory.save_data.party
	Utils.character_stats = memory.save_data.character_stats
	MenuCore.inventories  = memory.save_data.inventories
	
	return {
		"scene": memory.save_data.save_scene
	}

# Set the value of a switch
# Optionally, set a value other than "true"
func sset ( type, switch_name, value=true ):
	switch(type, switch_name, value)
func switch ( type, switch_name, value=true ):
	memory[type][switch_name] = value

func sget( switch_name ):
	if memory[PERMANENT].has(switch_name):
		return memory[PERMANENT][switch_name]
	if memory[EPISODE].has(switch_name):
		return memory[EPISODE][switch_name]
	if memory[SESSION].has(switch_name):
		return memory[SESSION][switch_name]
	return false

func has_switch( switch_name ):
	return memory[PERMANENT].has(switch_name) or memory[EPISODE].has(switch_name) or memory[SESSION].has(switch_name)

# Checks for the existance of a switch anywhere
# Optionally, check for a value
func check( switch_name, value=true ):
	if memory[PERMANENT].has(switch_name):
		return memory[PERMANENT][switch_name] == value
	if memory[EPISODE].has(switch_name):
		return memory[EPISODE][switch_name] == value
	if memory[SESSION].has(switch_name):
		return memory[SESSION][switch_name] == value
	return false

func get_episode_name():
	var ep : int = memory.progression.episode
	return "E0" + str(ep)
