extends Control

var player_character = preload("res://Character/FPSCharacter.tscn")

onready var multiplayer_config_ui = $MultiplayerConfigure
onready var server_ip_address: LineEdit = $MultiplayerConfigure/VBoxContainer/ServerIPAddress
onready var username: LineEdit = $MultiplayerConfigure/VBoxContainer/Username

onready var create_btn: Button = $MultiplayerConfigure/VBoxContainer/CreateServer
onready var join_btn: Button = $MultiplayerConfigure/VBoxContainer/JoinServer
onready var device_ip_address = $CanvasLayer/DeviceIPAddress

onready var join_error_msg = $MultiplayerConfigure/VBoxContainer/JoinErrorMsg

var error_msg_timer: Timer


func _ready():
	username.grab_focus()
	error_msg_timer = Timer.new()
	error_msg_timer.one_shot = true
	add_child(error_msg_timer)
	error_msg_timer.connect("timeout", self, "_hide_error")

	create_btn.disabled = true
	join_btn.disabled = true

	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")

	Network.connect("joined_server", self, "_joined_server")
	device_ip_address.text = Network.ip_address
	server_ip_address.text = Network.ip_address


func _player_connected(id) -> void:
	print("Player " + str(id) + " has connected")


func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")


#	if Players.has_node(str(id)):
#		Players.get_node(str(id)).queue_free()


func _joined_server(status: int):
	if status != OK:
		join_error_msg.show()
		error_msg_timer.start(5)
	else:
		multiplayer_config_ui.hide()


func _hide_error():
	join_error_msg.hide()


func _on_CreateServer_pressed():
	multiplayer_config_ui.hide()
	Network.create_server()
	var id = get_tree().get_network_unique_id()
	Lobby.register_to_server(id, username.text)
	proceed_to_lobby()


func _on_JoinServer_pressed():
	if server_ip_address.text.length() > 0:
		Network.ip_address = server_ip_address.text
		Network.join_server()


func _connected_to_server():
	yield(get_tree().create_timer(0.1), "timeout")
	var id = get_tree().get_network_unique_id()
	Lobby.register_to_server(id, username.text)
	proceed_to_lobby()


func proceed_to_lobby():
	get_tree().change_scene("res://Menus/Networking/MatchLobby.tscn")


func _on_Username_text_changed(new_text: String):
	var buttons_disabled := new_text.length() == 0
	create_btn.disabled = buttons_disabled
	join_btn.disabled = buttons_disabled
