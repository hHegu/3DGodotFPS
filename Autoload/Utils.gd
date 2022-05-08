extends Node

func instance_node_at_location(node: Object, parent: Spatial, location: Vector3) -> Spatial:
	var node_instance = instance_node(node, parent)
	node_instance.global_transform.origin = location 
	return node_instance

func instance_node(node: Object, parent: Spatial) -> Spatial:
	var node_instance = node.instance()
	parent.add_child(node_instance)
	return node_instance

func is_host():
	return get_tree().is_network_server()
