extends Node

# Player info, associate ID to data
remotesync var players: Dictionary = {} setget _set_players
signal player_joined


func register_to_server(id: int, username: String):
	rpc_id(1, "_sync_players", id, {"username": username})


remotesync func _sync_players(id, new_player):
	if Utils.is_host():
		players[id] = new_player
		rset('players', players)


func _set_players(new_players):
	players = new_players
	emit_signal("player_joined", players)
