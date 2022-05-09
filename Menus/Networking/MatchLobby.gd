extends Control

onready var player_list: ItemList = $VBoxContainer/PlayerList

var blue_team_icon = preload("res://assets/team_icons/team_icon_blue.png")
var red_team_icon = preload("res://assets/team_icons/team_icon_red.png")

var icons = {
	Enums.TEAMS.RED: red_team_icon,
	Enums.TEAMS.BLUE: blue_team_icon,
}

func _ready():
	if not Utils.is_host():
		$VBoxContainer/StartGameButton.disabled = true
		$VBoxContainer/StartGameButton.text = "Waiting for host to start the game"
	Lobby.connect("player_joined", self, "_render_players")
	Lobby.connect("player_switched_team", self, "_render_players")
	_render_players()
	player_list.grab_focus()


func _render_players(players = Lobby.players):
	player_list.clear()
	for player_id in players:
		var player = players[player_id]
		player_list.add_item(player.username, icons[player.team])


func _on_StartGameButton_pressed():
	GameMaster.rpc("start_game")


func _on_SwitchTeamButton_pressed():
	var my_id = get_tree().get_network_unique_id()
	var new_team = Enums.TEAMS.RED if Lobby.players[my_id].team == Enums.TEAMS.BLUE else Enums.TEAMS.BLUE
	Lobby.rpc("switch_team", get_tree().get_network_unique_id(), new_team)
