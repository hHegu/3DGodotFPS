extends Control

onready var multiplayer_config_ui = $MultiplayerConfigure
onready var server_ip_address = $MultiplayerConfigure/VBoxContainer/ServerIPAddress

onready var device_ip_address = $CanvasLayer/DeviceIPAddress

onready var join_error_msg = $MultiplayerConfigure/VBoxContainer/JoinErrorMsg

var error_msg_timer: Timer

func _ready():
	error_msg_timer = Timer.new()
	error_msg_timer.one_shot = true
	add_child(error_msg_timer)
	error_msg_timer.connect("timeout", self, "_hide_error")

	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	Network.connect("joined_server", self, "_joined_server")
	device_ip_address.text = Network.ip_address


func _player_connected(id) -> void:
	print("Player " + str(id) + " has connected")


func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")


func _joined_server(status: int):
	if status > 0:
		join_error_msg.show()
		error_msg_timer.start(5)
	else:
		multiplayer_config_ui.hide()

func _hide_error():
	join_error_msg.hide()

func _on_CreateServer_pressed():
	multiplayer_config_ui.hide()
	Network.create_server()


func _on_JoinServer_pressed():
	if server_ip_address.text.length() > 0:
		Network.ip_address = server_ip_address.text
		Network.join_server()
