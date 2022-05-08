extends Node

var player_character = preload("res://Character/FPSCharacter.tscn")


remotesync func start_game():
	_initiate_players()


func _initiate_players():
	for player_id in Lobby.players:
		_instance_player(player_id, Lobby.players[player_id])


func _instance_player(id: int, player: Dictionary):
	var player_i = Utils.instance_node(player_character, Players)
	player_i.name = str(id)
	player_i.set_network_master(id)
	player_i.is_player_enabled = false
	return player_i
