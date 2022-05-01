extends Node

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 32

var server = null
var client = null

var ip_address = ""

signal joined_server(status)

func _ready():
	if OS.get_name() == "Windows":
		# Gets ipv4 address on windows
		ip_address = IP.get_local_addresses()[3]
	else:
		ip_address = IP.get_local_addresses()[3]

	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168."):
			ip_address = ip
			
	print(ip_address)
	
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	

func create_server() -> void:
	print('??')
	server = NetworkedMultiplayerENet.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().set_network_peer(server)


func join_server() -> void:
	client = NetworkedMultiplayerENet.new()
	var status = client.create_client(ip_address, DEFAULT_PORT)
	if status > 0:
		emit_signal("joined_server", status)
		return
	emit_signal("joined_server", status)
	
	get_tree().set_network_peer(client)


func _connected_to_server() -> void:
	print("Connected to the server")
	
func _server_disconnected() -> void:
	get_tree().set_network_peer(null)
	print("Disconnected from the server")
