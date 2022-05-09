extends Spatial

class_name Level

onready var level_camera: Camera = $LevelCamera
onready var waiting_for_players_overlay: ColorRect = $LevelUI/WaitingForPlayersOverlay


func _ready():
	Lobby.connect("player_map_loaded", self, "_on_player_map_loaded")
	waiting_for_players_overlay.visible = true
	level_camera.current = true
	Lobby.rpc("player_map_load_ready", get_tree().get_network_unique_id())


func _on_player_map_loaded():
	if Utils.is_host():
		var player_count = Lobby.players.size()
		var players_ready = Lobby.get_amount_of_players_loaded()
		if player_count == players_ready:
			_spawn_players()
			rpc("_start_match")


func _spawn_players():
	var red_spawns := $SpawnPositions/RedTeam.get_children()
	var blue_spawns := $SpawnPositions/BlueTeam.get_children()
	
	for player_id in Lobby.players:
		randomize()
		var spawn_points = red_spawns if Lobby.players[player_id].team == Enums.TEAMS.RED else blue_spawns
		var spawn_index = int(randf() * spawn_points.size())
		var spawn_point: Position3D = spawn_points[spawn_index]
		rpc("spawn_player", player_id, spawn_point.transform.origin)


remotesync func spawn_player(player_id, position):
	var player: KinematicBody = Players.get_node(str(player_id))
	player.transform.origin = position


remotesync func _start_match():
	waiting_for_players_overlay.visible = false
	GameMaster.emit_signal("round_started")
