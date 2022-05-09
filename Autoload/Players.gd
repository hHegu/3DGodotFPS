extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_player(player_id: int = get_tree().get_network_unique_id()):
	get_node(str(player_id))
