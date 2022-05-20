extends Spatial


func get_player(player_id: int = get_tree().get_network_unique_id()):
	return get_node(str(player_id))


func get_player_node_and_info(player_id: int = get_tree().get_network_unique_id()):
	var node = get_player(player_id)
	var info = Lobby.players[player_id]
	return {"node": node, "info": info}
