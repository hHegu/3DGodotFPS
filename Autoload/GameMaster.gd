extends Node

var player_character = preload("res://Character/FPSCharacter.tscn")
var current_level

signal round_started

# Player has died. Emitted only for the client of the player that has died
signal player_died


remotesync func start_game(level := "res://Levels/Level1.tscn"):
	_initiate_players()
	get_tree().change_scene(level)
	current_level = get_tree().current_scene


func _initiate_players():
	for player_id in Lobby.players:
		_instance_player(player_id, Lobby.players[player_id])


func _instance_player(id: int, player: Dictionary):
	var player_i = Utils.instance_node(player_character, Players)
	player_i.set_network_master(id)
	player_i.name = str(id)
