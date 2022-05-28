extends Spatial

class_name Level

onready var level_camera: Camera = $LevelCamera
onready var waiting_for_players_overlay: ColorRect = $LevelUI/WaitingForPlayersOverlay

export var respawn_time := 5.0

remotesync var blue_team_score := 0 setget set_blue_team_score
remotesync var red_team_score := 0 setget set_red_team_score

export var score_needed_to_win := 50

func set_blue_team_score(new_score: int):
	blue_team_score = new_score
	HUDSingleton.emit_signal("score_changed", blue_team_score, red_team_score)
	print(blue_team_score)
	
func set_red_team_score(new_score: int):
	red_team_score = new_score
	HUDSingleton.emit_signal("score_changed", blue_team_score, red_team_score)	
	print(red_team_score)

func _ready():
	Lobby.connect("player_map_loaded", self, "_on_player_map_loaded")
	GameMaster.connect("player_died", self, "_player_died")
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
	for player_id in Lobby.players:
		var team = Lobby.players[player_id].team
		var spawn_point = get_random_spawn_point_for_team(team)
		rpc("spawn_player", player_id, spawn_point.transform.origin, spawn_point.rotation)


func get_random_spawn_point_for_team(team: int):
	randomize()
	var red_spawns := $SpawnPositions/RedTeam.get_children()
	var blue_spawns := $SpawnPositions/BlueTeam.get_children()
	var spawn_points = red_spawns if team == Enums.TEAMS.RED else blue_spawns
	var spawn_index = int(randf() * spawn_points.size())
	var spawn_point: Position3D = spawn_points[spawn_index]
	return spawn_point


remotesync func spawn_player(player_id, position: Vector3, rotation: Vector3):
	var player: KinematicBody = Players.get_node(str(player_id))
	player.transform.origin = position
	player.rotation = rotation


remotesync func _start_match():
	yield(get_tree(),"idle_frame")
	waiting_for_players_overlay.visible = false
	var player: Player = Players.get_player()
	player.toggle_player_control(true)
	player.toggle_player_camera(true)
	GameMaster.emit_signal("round_started")


master func update_score(killed_player_id: int):
	var team = Lobby.players[killed_player_id].team
	if team == Enums.TEAMS.RED:
		rset("blue_team_score", blue_team_score + 1)
	if team == Enums.TEAMS.BLUE:
		rset("red_team_score", red_team_score + 1)



func _player_died(player_id: int):
	rpc("update_score", player_id)
	level_camera.current = true
	respawn(player_id)


func respawn(player_id):
	yield(get_tree().create_timer(respawn_time), "timeout")
	var player_node: Player = Players.get_node_or_null(str(player_id))

	if not player_node:
		return

	var player = Lobby.players[player_id]
	var spawn_point = get_random_spawn_point_for_team(player.team)
	rpc("sync_respawn_player", player_id, spawn_point.transform.origin, spawn_point.rotation)
	player_node.toggle_player_control(true)
	player_node.toggle_player_camera(true)


remotesync func sync_respawn_player(player_id, position, rotation):
	spawn_player(player_id, position, rotation)
	var player_node: Player = Players.get_node(str(player_id))
	player_node.visible = true
	player_node.body.disabled = false
	player_node.reset_player()
