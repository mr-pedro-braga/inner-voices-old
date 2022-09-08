#--------------------------------------------------------#
#
#		Another Series Party
#	
#	Takes care of the party!
#	Add and remove_at characters to the party, and more!
#	game states.
#
#--------------------------------------------------------#

extends Node

### The current character ID and node
var playable_character:String = "ninten"
var playable_character_node:Node2D

### If the main character is currently moving
var mainchar_moving:bool = false

### The main character position
var playable_character_position := Vector2.ZERO

### All the party member character IDs and nodes
@export var party := []
var party_character_nodes = []

### The positions walked by the playable character that will be retraced by the party followers
@onready var party_follower_path: Path2D

### All the characters present on the current map
var map_characters: Dictionary = {}

func set_playable_character(character:String):
	playable_character = character
	playable_character_node = map_characters[character]
	playable_character_position = playable_character_node.position
	playable_character_node.alignment = 0
	add_party_member(character)
	return map_characters[character]

func add_party_member(member):
	if not party.has(member):
		var c = map_characters[member]
		if not c == playable_character_node:
			c.get_node(^"CollisionShape2D").disabled = true
		c.is_party_member = true
		c.party_index = party.size()
		party.append(member)
		update_party()
		Utils.load_stats(member, c.char_stats_file, c.alignment)

func remove_party_member(member):
	if party.has(member):
		var c = map_characters[member]
		c.stop()
		c.get_node(^"CollisionShape2D").disabled = false
		c.is_party_member = false
		c.party_index = 0
		party.erase(member)
		update_party()

func update_party():
	party_character_nodes = []
	for i in party:
		party_character_nodes.append(map_characters[i])

## Setup Function to be called in start of game
func setup():
	party_follower_path = get_node(^"/root/GameRoot/World3D/FollowerPath")
