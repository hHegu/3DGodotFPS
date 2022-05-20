extends Node

# Player info, associate ID to data
remotesync var players: Dictionary = {} setget _set_players
signal player_joined
signal player_switched_team

# Emitted when a player finishes loading a map
signal player_map_loaded

func register_to_server(id: int, username: String):
	rpc_id(1, "_sync_add_player", id, {"username": username, "map_loaded": false})


remotesync func _sync_add_player(id, new_player):
	if Utils.is_host():
		new_player.team = _get_team_with_least_players()
		players[id] = new_player
		rset('players', players)


func _set_players(new_players):
	players = new_players
	emit_signal("player_joined", players)


func _get_team_with_least_players():
	var red_team_size = filter_players_by_team(Enums.TEAMS.RED).size()
	var blue_team_size = filter_players_by_team(Enums.TEAMS.BLUE).size()
	
	return Enums.TEAMS.BLUE if blue_team_size < red_team_size else Enums.TEAMS.RED


func get_amount_of_players_loaded():
	var count := 0
	for player_id in players:
		if players[player_id].map_loaded:
			count += 1
	return count


func filter_players_by_team(team) -> Array:
	var team_players := []
	for player_id in players:
		if players[player_id].team == team:
			team_players.push_front(players[player_id])
	return team_players


remotesync func switch_team(id, team):
	players[id].team = team
	emit_signal("player_switched_team")


# Called from Level when a player has finished loading level. 
# Used to start the game when all players have finished loading.
remotesync func player_map_load_ready(id):
	Lobby.players[id].map_loaded = true
	emit_signal("player_map_loaded")


remotesync func set_player(id, new_player):
	Lobby.players[id] = new_player
