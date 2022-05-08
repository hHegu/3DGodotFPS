extends Control

onready var player_list: ItemList = $VBoxContainer/PlayerList


func _ready():
	if not Utils.is_host():
		$VBoxContainer/StartGameButton.disabled = true
		$VBoxContainer/StartGameButton.text = "Waiting for host to start the game"
	Lobby.connect("player_joined", self, "_on_player_joined")
	player_list.clear()
	for player_id in Lobby.players:
		player_list.add_item(Lobby.players[player_id].username)


func _on_player_joined(players):
	player_list.clear()
	for player_id in Lobby.players:
		player_list.add_item(Lobby.players[player_id].username)


func _on_StartGameButton_pressed():
	GameMaster.rpc("start_game")
