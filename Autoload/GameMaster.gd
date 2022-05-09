extends Node

var player_character = preload("res://Character/FPSCharacter.tscn")
var current_level

signal round_started

remotesync func start_game(level := "res://Levels/test_level.tscn"):
	_initiate_players()
	get_tree().change_scene(level)
	current_level = get_tree().current_scene


func _initiate_players():
	for player_id in Lobby.players:
		_instance_player(player_id, Lobby.players[player_id])


func _instance_player(id: int, player: Dictionary):
	var player_i = Utils.instance_node(player_character, Players)
	player_i.name = str(id)
	player_i.set_network_master(id)
	player_i.is_player_enabled = false
	return player_i
