extends Reference

# Custom History Record for layer changes
var history_data: Dictionary
const ENABLE_LOGGING = true
const LOGGING_LEVEL = 2

func outputlog(msg,level=0):
	if ENABLE_LOGGING:
		if level <= LOGGING_LEVEL:
			printraw("(%d) <MinorUtils>: " % OS.get_ticks_msec())
			print(msg)
	else:
		pass

# Function to set the layer of an asset
func set_layer(node, layer: int):

	# If it is a pattern we need to use the SetLayer function
	if node.get("HasOutline"):
		node.SetLayer(layer)
	# If it is an object
	elif node.get("Sprite") || node.get("FadeIn"):
		node.z_index = layer

func undo():

	var node

	# For each entry in the history record, set everything back to the previous version
	for history_record in history_data.keys():
		if Global.World.HasNodeID(int(history_record)):
			node = Global.World.GetNodeByID(int(history_record))
			set_layer(node, history_data[history_record]["previous_layer"])

	if Global.Editor.History.get("history"):
		outputlog(Global.Editor.History.history)
		for record in Global.Editor.History.history:
			outputlog(record.ScriptInstance.record_type())
		
func redo():

	var node

	# For each entry in the history record, set everything back to the previous version
	for history_record in history_data.keys():
		if Global.World.HasNodeID(int(history_record)):
			node = Global.World.GetNodeByID(int(history_record))
			set_layer(node, history_data[history_record]["new_layer"])

		
