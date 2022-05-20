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

func center_bbtext(text: String):
	return "[center]%s[/center]" % text

func get_time_string() -> String:
	var time = OS.get_time()
	return "%s:%s:%s" % [str(time.hour), str(time.minute), str(time.second)]

func uuid(prefix: String = '') -> String:
	randomize()
	var random_float_string := str(randf() * 100000)
	var time := get_time_string()
	var hashed = "{prefix}{rand}{time}".format({"prefix": prefix, "rand": random_float_string, "time": time}).hash()
	if(prefix.length() > 0):
		return "{prefix}_{hashed}".format({"prefix": prefix, "hashed": hashed})
	else:
		return hashed
