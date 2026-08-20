
#########################################################################################################
##
## MINOR UTILS
##
#########################################################################################################

# Dungeondraft mod to add small additional functions to the UI
var script_class = "tool"

# Variables
var tool_panel
var ui_config = {}
var toolset_button_count
var unique_id

var select_tool_panel
var scatter_tool
var last_selected = null
var mod_name = "Minor Utils"

var PresetsDropdown
var presetsdropdown

var _lib_config_builder
var _lib_mod_config

var scatter_preset_config_name = "scatter_presets_config.json"

# Configuration file values
const CONFIG_FILENAME = "shortcut_buttons_config.json"
var config_path
const STORE_DEFAULT_CONFIG = {
	"config_name": "Minor Utils Configuration",
	"grid_visible": true,
	"buttons": [
		{"icon_path": "res://ui/icons/tools/floor_shape_tool.png", "tool_reference": "FloorShapeTool", "tool_display_name": "Building Tool", "order_id": 0,"shortcut_key_value": "B","shortcut_key_active": false, "visible": false},
		{"icon_path": "res://ui/icons/tools/wall_tool.png", "tool_reference": "WallTool", "tool_display_name": "Wall Tool", "order_id": 1,"shortcut_key_value": "W","shortcut_key_active": true, "visible": true},
		{"icon_path": "res://ui/icons/tools/door_tool.png", "tool_reference": "PortalTool", "tool_display_name": "Portal Tool", "order_id": 2,"shortcut_key_value": "D","shortcut_key_active": false, "visible": false},
		{"icon_path": "res://ui/icons/tools/cave_brush.png", "tool_reference": "CaveBrush", "tool_display_name": "Cave Brush", "order_id": 3,"shortcut_key_value": "V","shortcut_key_active": false, "visible": false},
		{"icon_path": "res://ui/icons/tools/pattern_shape_tool.png", "tool_reference": "PatternShapeTool", "tool_display_name": "Pattern Tool", "order_id": 4,"shortcut_key_value": "N","shortcut_key_active": true, "visible": false},
		{"icon_path": "res://ui/icons/tools/roof_tool.png", "tool_reference": "RoofTool", "tool_display_name": "Roof Tool", "order_id": 5,"shortcut_key_value": "F","shortcut_key_active": false, "visible": false},
		{"icon_path": "res://ui/icons/tools/terrain_brush.png", "tool_reference": "TerrainBrush", "tool_display_name": "Terrain Brush", "order_id": 5,"shortcut_key_value": "E","shortcut_key_active": false, "visible": true},
		{"icon_path": "res://ui/icons/tools/water_brush.png", "tool_reference": "WaterBrush", "tool_display_name": "Water Brush", "order_id": 6,"shortcut_key_value": "A","shortcut_key_active": false, "visible": false},
		{"icon_path": "res://ui/icons/tools/material_brush.png", "tool_reference": "MaterialBrush", "tool_display_name": "Material Brush", "order_id": 7,"shortcut_key_value": "M","shortcut_key_active": false, "visible": false},
		{"icon_path": "res://ui/icons/tools/path_tool.png", "tool_reference": "PathTool", "tool_display_name": "Path Tool", "order_id": 8,"shortcut_key_value": "J","shortcut_key_active": true, "visible": true},
		{"icon_path": "res://ui/icons/tools/object_tool.png", "tool_reference": "ObjectTool", "tool_display_name": "Object Tool", "order_id": 9,"shortcut_key_value": "O","shortcut_key_active": true, "visible": true},
		{"icon_path": "res://ui/icons/tools/scatter_tool.png", "tool_reference": "ScatterTool", "tool_display_name": "Scatter Tool", "order_id": 10,"shortcut_key_value": "K","shortcut_key_active": true, "visible": true},
		{"icon_path": "res://ui/icons/tools/environment.png", "tool_reference": "Environment", "tool_display_name": "Environment", "order_id": 11,"shortcut_key_value": "U","shortcut_key_active": false, "visible": false},
		{"icon_path": "res://ui/icons/tools/light_tool.png", "tool_reference": "LightTool", "tool_display_name": "Light Tool", "order_id": 12,"shortcut_key_value": "I","shortcut_key_active": false, "visible": false}
	],
	"scatter_presets_enabled": true
}

const SLIDER_WAIT_TIME = 0.5


# Logging Functions
const ENABLE_LOGGING = true
var logging_level = 0

func outputlog(msg,level=0):
	if ENABLE_LOGGING:
		if level <= logging_level:
			printraw("(%d) <MinorUtils>: " % OS.get_ticks_msec())
			print(msg)
	else:
		pass

#########################################################################################################
##
## UTILITY FUNCTIONS
##
#########################################################################################################

# Function to look at resource string and return the texture
func load_image_texture(texture_path: String):

	var image = Image.new()
	var texture = ImageTexture.new()

	# If it isn't an internal resource
	if not "res://" in texture_path:
		image.load(Global.Root + texture_path)
		texture.create_from_image(image)
	# If it is an internal resource then just use the ResourceLoader
	else:
		texture = ResourceLoader.load(texture_path)
	
	return texture

# Function to see if a structure that looks like a copied dd data entry is the same
func is_the_same(a, b) -> bool:

	if a is Dictionary:
		if not b is Dictionary:
			return false
		if a.keys().size() != b.keys().size():
			return false
		for key in a.keys():
			if not b.has(key):
				return false
			if not is_the_same(a[key], b[key]):
				return false
	elif a is Array:
		if not b is Array:
			return false
		if a.size() != b.size():
			return false
		for _i in a.size():
			if not is_the_same(a[_i], b[_i]):
				return false
	elif a != b:
		return false

	return true

# Make a button and return it
func make_button(parent_node, icon_path: String, hint_tooltip: String, toggle_mode: bool) -> Button:

	var button = Button.new()
	button.toggle_mode = toggle_mode
	button.icon = load_image_texture(icon_path)
	button.hint_tooltip = hint_tooltip
	parent_node.add_child(button)
	return button

## SUPPORT FUNCTIONS
# Sort buttons by order id
class MyCustomSorter:
	static func sort_orderid_ascending(a: Dictionary, b: Dictionary):
		if a["order_id"] < b["order_id"]:
			return true
		return false

# Sort scatter configs alphabetically by name
class ScatterConfigSorter:
	static func sort_name_ascending(a: Dictionary, b: Dictionary):
		if a.name.to_lower() < b.name.to_lower():
			return true
		return false

# Return the name of the texture and the pack it is in from the resource path string as a dictionary
func find_texture_name_and_pack(texture_string):

	var texture_name
	var pack_name
	var pack_id
	var array: Array

	# If this is a custom pack then find the pack name and split out the 
	if texture_string.left(12) == "res://packs/":
		array = texture_string.right(12).split("/")
		pack_id = array[0]
		texture_name = array[-1].split(".")[0]
		for pack in Global.Header.AssetManifest:
			if pack.ID == pack_id:
				pack_name = pack.Name
	# If this is a native DD pack, then return the name
	elif texture_string.left(15) == "res://textures/":
		array = texture_string.right(6).split("/")
		texture_name = array[-1].split(".")[0]
		pack_id = "nativeDD"
		pack_name = "Native DD"
	# Otherwise return a "Not Set" string
	else:
		texture_name = "Not Set"
		pack_id = "n/a"
		pack_name = "Not Set"
	
	return {"texture_name": texture_name,"pack_name": pack_name, "pack_id": pack_id}

# Function to look through the children of a container and return the index of a control type with a text that matches one of the find_text values
func find_index_of_text_in_container(box, type, find_text) -> int:

	var index = -1	
	# Look through all the children and when we find a label or button with the right text then store that index
	for thing in box.get_children():
		if thing is Label || thing is Button:
			if thing.text.to_upper() in find_text:
				index = thing.get_index()
				break
		if thing is HBoxContainer:
			if thing.get_children().size() > 0:
				if thing.get_child(0) is Label || thing.get_child(0) is Button:
					if thing.get_child(0).text.to_upper() in find_text:
						index = thing.get_index()
						break
	
	return index


# Create a linked slider because the standard one whinges about property values not being set
func make_hslider(vbox, default: float, minimum: float, maximum: float, step: float):

	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = 1
	hbox.size_flags_horizontal = 3

	outputlog("make_hslider",2)

	var hslider = HSlider.new()
	hslider.max_value = maximum
	hslider.min_value = minimum
	
	hslider.step = step
	hslider.size_flags_horizontal = 3
	hslider.size_flags_vertical = 3

	var timer = Timer.new()
	timer.one_shot = true
	timer.auto_start = false
	timer.wait_time = SLIDER_WAIT_TIME
	hslider.set_meta("timer",timer)
	hslider.get_meta("timer").connect("timeout", self, "emit_history_event_signal")
	
	var spinbox = SpinBox.new()
	spinbox.max_value = maximum
	spinbox.min_value = minimum
	spinbox.value = default
	spinbox.step = step
	spinbox.align = 1
	spinbox.connect("value_changed",self,"slider_change",[hslider,false])
	hslider.connect("value_changed",self,"slider_change",[spinbox,true])
	hslider.connect("value_changed",self,"start_slider_timer",[timer])
	hslider.set_meta("spinbox",spinbox)
	
	hbox.add_child(hslider)
	hbox.add_child(spinbox)
	hbox.add_child(timer)
	vbox.add_child(hbox)
	hslider.set_meta("hbox",hbox)

	spinbox.get_line_edit().expand_to_text_length = true

	# Silly work around to get the default value to display properly
	hslider.value = default
	if default != minimum:
		hslider.value = minimum
	elif default != maximum:
		hslider.value = maximum
	hslider.value = default
	
	return hslider

# Link spinbox and slider
func slider_change(value: float, target, suppress_signal: bool):

	if suppress_signal:
		target.set_block_signals(true)
		target.value = value
		target.set_block_signals(false)
	else:
		target.value = value

# Function to update the values of a slider and its spinbox without triggering further signals
func slider_and_spinbox_change(value: float, slider: HSlider, suppress_signal: bool):

	outputlog("slider_and_spinbox_change",2)

	if suppress_signal:
		slider_change(value, slider, suppress_signal)
		if slider.has_meta("spinbox"):
			if slider.get_meta("spinbox") is SpinBox:
				slider_change(value, slider.get_meta("spinbox"), suppress_signal)		
	else:
		# Note that this should automatically update the spinbox via signals
		slider.value = value

# Function to start or reset the slider timer. Once the timer completes we call a function to emit the record history event.
func start_slider_timer(value: float, timer: Timer):

	if timer.is_stopped():
		timer.start()
	else:
		timer.wait_time = SLIDER_WAIT_TIME

# Function to get the texture of a node based on tool_type
func get_asset_texture(node, tool_type: String):
	var texture = null

	match tool_type:
		"ObjectTool","ScatterTool","WallTool","PortalTool","objects","portals","walls":
			texture = node.Texture
		"PathTool", "LightTool","paths","lights":
			texture = node.get_texture()
		"PatternShapeTool","pattern_shapes":
			texture = node._Texture
		"RoofTool","roofs":
			texture = node.TilesTexture
		_:
			return null

	return texture

# Function to look at a node and determine what type it is based on its properties
func get_node_type(node):

	if node.get("WallID") != null:
		return "portals"

	# Note this is also true of portals but we caught those with WallID
	elif node.get("Sprite") != null:
		return "objects"
	elif node.get("FadeIn") != null:
		return "paths"
	elif node.get("HasOutline") != null:
		return "pattern_shapes"
	elif node.get("Joint") != null:
		return "walls"

	return null
#########################################################################################################
##
## SHORTCUT BUTTON FUNCTIONS
##
#########################################################################################################

func _save_config_file():

	outputlog("_save_config_file: " + str(config_path),2)

	var data: Dictionary
	var temp_dict: Dictionary

	var file = File.new()
	var err = file.open(config_path, File.WRITE)

	data["config_name"] = ui_config["config_name"]
	data["grid_visible"] = Global.Editor.GridToggle.pressed
	data["buttons"] = []
	data["scatter_presets_enabled"] = ui_config["preferences_ui"]["scatter_presets_enabled"]

	outputlog("scatter_presets_enabled: " + str(ui_config["preferences_ui"]["scatter_presets_enabled"]),2)
	# Update the _lib values to be stored in the config file
	if Engine.has_signal("_lib_register_mod"):
		_lib_mod_config.scatter_presets_enabled = ui_config["preferences_ui"]["scatter_presets_enabled"]

	# For each button config in the ui config file
	for button_config in ui_config["buttons"]:

		temp_dict["icon_path"] = button_config["icon_path"]
		temp_dict["tool_reference"] = button_config["tool_reference"]
		temp_dict["tool_display_name"] = button_config["tool_display_name"]
		temp_dict["order_id"] = button_config["order_id"]
		temp_dict["visible"] = button_config["visible"]
		# Note this works for _lib and standard configuration
		# Check if there is an active action for button, use the value from the associated action if so
		if InputMap.has_action(button_config["tool_reference"]):
			if InputMap.get_action_list(button_config["tool_reference"]).size() > 0:
				temp_dict["shortcut_key_value"] = convert_key_action_to_string(InputMap.get_action_list(button_config["tool_reference"])[0])
		# Otherwise use the shortcut value stored in the button config
		else:
			temp_dict["shortcut_key_value"] = button_config["shortcut_key_value"]

		if button_config["key_button"].pressed:
			temp_dict["shortcut_key_active"] = true		
		else:
			temp_dict["shortcut_key_active"] = false

		data["buttons"].append(JSON.parse(JSON.print(temp_dict, "\t")).result)
	
	file.store_string(JSON.print(data, "\t"))
	file.close()

# Read the stored configuration file from last time
func _read_config_file():

	outputlog("_read_config_file")

	var data
	var temp_dict = {}

	var file = File.new()
	var err = file.open(config_path, File.READ)
	if err != OK:
		data = STORE_DEFAULT_CONFIG.duplicate(true)

	else:
		var content = file.get_as_text()
		file.close()
		
		var json_result = JSON.parse(content)
		if json_result.error == OK:
			data = json_result.result
		else:
			# JSON parse error use default values
			outputlog("JSON Parse Error: ", json_result.error_string(), " in ", content, " at line ", json_result.error_line())
			data = STORE_DEFAULT_CONFIG.duplicate(true)

	if not data["grid_visible"]:
		Global.Editor.ToggleGrid(false)

	ui_config["buttons"].clear()
	ui_config["shortcut_keys"].clear()
	ui_config["preferences_ui"]["scatter_presets_enabled"] = data["scatter_presets_enabled"]

	for button_config in data["buttons"]:
		temp_dict["icon_path"] = button_config["icon_path"]
		temp_dict["tool_reference"] = button_config["tool_reference"]
		temp_dict["tool_display_name"] = button_config["tool_display_name"]
		temp_dict["order_id"] = button_config["order_id"]

		# For old versions which did not require the shortcut_key_value, add it if it doesn't exist, read it in if it does
		if not button_config.has("shortcut_key_value"):
			button_config["shortcut_key_value"] = ""
		else:
			if not button_config.has("shortcut_key_active"):
				button_config["shortcut_key_active"] = true
		if not button_config.has("shortcut_key_active"):
			button_config["shortcut_key_active"] = false
		
		# If there is no visible record, then set it to false
		if not button_config.has("visible"):
			button_config["visible"] = false
		temp_dict["visible"] = button_config["visible"]
		button_config["active_button"].pressed = button_config["visible"]
		
		temp_dict["shortcut_key_value"] = button_config["shortcut_key_value"]
		temp_dict["shortcut_key_active"] = button_config["shortcut_key_active"]
		# If not _Lib then create actions for each shortcut
		if not Engine.has_signal("_lib_register_mod"):
			create_or_set_key_action(button_config["tool_reference"], button_config["shortcut_key_value"])
		if button_config["shortcut_key_active"]:
			ui_config["shortcut_keys"].append(button_config["tool_reference"])
		ui_config["buttons"].append(JSON.parse(JSON.print(temp_dict, "\t")).result)


# Function to display/hide shortcut button
func set_active_button(button_config: Dictionary):

	button_config["button"].visible = button_config["active_button"].pressed
	button_config["visible"] = button_config["active_button"].pressed
	
	_save_config_file()

# Function to rearrange the buttons in order
func move_button(button_config: Dictionary, direction: String):

	var new_index

	if direction == "up":
		new_index = button_config["config_hbox"].get_index()-1
		if new_index < 0:
			return
	else:
		new_index = button_config["config_hbox"].get_index()+1
		if new_index > tool_panel.Align.get_child_count()-1:
			return

	tool_panel.Align.move_child(button_config["config_hbox"],new_index)
	Global.Editor.Toolset.move_child(button_config["button"],new_index+toolset_button_count)

	# Refresh the order_id value in the buttons array
	for config_in_array in ui_config["buttons"]:
		config_in_array["order_id"] = config_in_array["config_hbox"].get_index()
	
	ui_config["buttons"].sort_custom(MyCustomSorter, "sort_orderid_ascending")
	_save_config_file()

# Function to make a config entry for a button
func make_config_entry_for_button(button_config: Dictionary):

	outputlog("make_config_entry_for_button: " + str(button_config),2)

	var hbox = HBoxContainer.new()
	button_config["config_hbox"] = hbox

	var label = Label.new()
	label.text = button_config["tool_display_name"]
	label.size_flags_horizontal = 2

	var icon = TextureRect.new()
	icon.texture = ResourceLoader.load(button_config["icon_path"])
	icon.stretch_mode = 6

	var active_button = CheckButton.new()
	button_config["active_button"] = active_button
	active_button.connect("pressed", self, "set_active_button", [button_config])
	active_button.hint_tooltip = "Display shortcut button"
	active_button.pressed = true
	if button_config.has("visible"):
		if not button_config["visible"]:
			button_config["active_button"].pressed = false

	var up_button = Button.new()
	up_button.icon = ResourceLoader.load("res://ui/icons/misc/up.png")
	up_button.hint_tooltip = "Move Up"
	up_button.connect("pressed", self, "move_button", [button_config,"up"])

	var down_button = Button.new()
	down_button.icon = ResourceLoader.load("res://ui/icons/misc/down.png")
	down_button.hint_tooltip = "Move Down"
	down_button.connect("pressed", self, "move_button", [button_config,"down"])

	var key_button = CheckButton.new()
	button_config["key_button"] = key_button
	key_button.hint_tooltip = "Enable in order to link a shortcut key value to this tool in Preferences->Shortcuts table"
	# Set the button as on if there is a record that is non-blank
	key_button.pressed = button_config["shortcut_key_active"]
	key_button.connect("toggled", self, "on_shortcut_key_enabled_disabled_toggle")

	hbox.add_child(icon)
	hbox.add_child(label)
	hbox.add_child(down_button)
	hbox.add_child(up_button)
	hbox.add_child(active_button)
	hbox.add_child(key_button)

	hbox.alignment = 2

	tool_panel.Align.add_child(hbox)

# Function when shortcut key enabled
func on_shortcut_key_enabled_disabled_toggle(pressed: bool):

	refresh_active_shortcuts()

func refresh_active_shortcuts():

	outputlog("refresh_active_shortcuts")

	# Reset all the active list of shortcut keys
	ui_config["shortcut_keys"] = []
	for button_config in ui_config["buttons"]:
		if button_config["key_button"].pressed:
			button_config["shortcut_key_active"] = true
			ui_config["shortcut_keys"].append(button_config["tool_reference"])
			# If _Lib is installed
			if Engine.has_signal("_lib_register_mod"):
				# Check that the action doesn't exist alreday
				if not InputMap.has_action(button_config["tool_reference"]):
					outputlog("adding shortcuts: " + str(button_config["tool_reference"]),2)
					# Build a dictionary of input shortcut definitions for _lib
					var shortcut_definitions = {}
					shortcut_definitions[button_config["tool_display_name"]] = [button_config["tool_reference"],button_config["shortcut_key_value"]]
					# Add the action
					Global.API.InputMapApi.add_actions(shortcut_definitions)
		else:
			button_config["shortcut_key_active"] = false
		
		button_config["button"].visible = button_config["active_button"].pressed
		button_config["visible"] = button_config["active_button"].pressed
	
	_save_config_file()


# A proxy function to call the quick switch function with a tool_name parameter
func switch_tool(tool_name: String):

	Global.Editor.Toolset.Quickswitch(tool_name)

# Function to create a shortcut button based on a button config
func make_shortcut_button(button_config: Dictionary):

	outputlog("make_shortcut_button: " + str(button_config),1)

	var button = Button.new()
	var hint_tooltip: String
	button.icon = ResourceLoader.load(button_config["icon_path"])
	
	button.connect("pressed", self, "switch_tool", [button_config["tool_reference"]])
	button_config["button"] = button
	Global.Editor.Toolset.add_child(button)

	if button_config["shortcut_key_active"] && button_config["shortcut_key_value"] != "":
		button_config["button"].hint_tooltip = button_config["tool_display_name"] + " (" + button_config["shortcut_key_value"] + ")"
	else:
		button_config["button"].hint_tooltip = button_config["tool_display_name"]

	if button_config.has("visible"):
		if not button_config["visible"]:
			button_config["button"].visible = false

# Function to read and store links to the Preferences UI
func read_preferences_ui_values():

	outputlog("read_preferences_ui_values",0)

	ui_config["preferences_ui"]["vbox"] = Global.Editor.Windows["Preferences"].find_node("VAlign")
	ui_config["preferences_ui"]["shortcuts_area"] = ui_config["preferences_ui"]["vbox"].find_node("Shortcuts")
	ui_config["preferences_ui"]["general_area"] = ui_config["preferences_ui"]["vbox"].find_node("General")
	ui_config["preferences_ui"]["shortcuts_tree"] = ui_config["preferences_ui"]["shortcuts_area"].get_child(0)
	ui_config["preferences_ui"]["control_buttons_hbox"] = ui_config["preferences_ui"]["vbox"].find_node("Buttons")
	ui_config["preferences_ui"]["apply_button"] = ui_config["preferences_ui"]["control_buttons_hbox"].find_node("SaveButton")
	# Connect to the signal so we know when the apply button is pressed
	ui_config["preferences_ui"]["apply_button"].connect("pressed", self, "on_preferences_apply_button_pressed")

	# If _lib is not installed then set up parameters to populate shortcuts when Preferences is opened
	if not Engine.has_signal("_lib_register_mod"):

		ui_config["preferences_ui"]["timer"] = Timer.new()
		ui_config["preferences_ui"]["timer"].one_shot = true
		ui_config["preferences_ui"]["timer"].connect("timeout",self,"add_custom_shortcut_items_to_preferences")
		# Add the timer as a child to the shortcuts area so we don't lose it
		ui_config["preferences_ui"]["shortcuts_area"].add_child(ui_config["preferences_ui"]["timer"])

		# Connect to the menu button list looking for when an entry is pressed
		Global.Editor.menuButton.get_popup().connect("id_pressed", self, "on_menu_item_pressed")

# Function to capture pressed signals from the menu list
func on_menu_item_pressed(menu_item_index):

	# If the preferences element has been pressed from the menu button then call the related function to do something
	if menu_item_index == 4:
		# Wait a bit so the standard preferences items can be created as want that to happen first before adding the custom ones. Note we have already linked the add_custom_shortcut_items_to_preferences function to this timer
		ui_config["preferences_ui"]["timer"].start(0.5)

# Function to act when the save map button is pressed. In the initial case, simply to save the config file
func on_save_button_pressed():

	# When saving a map file also save the config file
	_save_config_file()

# Function to implement changes when the apply button in Preferences is pressed
func on_preferences_apply_button_pressed():

	var tree_root
	var tree_item
	var list_of_shortcut_tools = []
	var button_index = 0
	var action_text
	var key_string

	outputlog("on_preferences_apply_button_pressed")
	# A series of remembered and fixed values to navigate through UI and build references
	

	# Cycle through all the entries in the table
	if not Engine.has_signal("_lib_register_mod"):
		outputlog("not _Lib")
		refresh_non_lib_shortcuts()
		
	else:
		for button in ui_config["buttons"]:
			# Set the shortcut key value if there is a reference for it in the action list
			if InputMap.has_action(button["tool_reference"]):
				if InputMap.get_action_list(button["tool_reference"]).size() > 0:
					button["shortcut_key_value"] = convert_key_action_to_string(InputMap.get_action_list(button["tool_reference"])[0])
			# Update the hint tooltip for the button
			if button["shortcut_key_active"]:
				button["button"].hint_tooltip = button["tool_display_name"] + " (" + button["shortcut_key_value"] + ")"
			else:
				button["button"].hint_tooltip = button["tool_display_name"]
			
		update_preferences_after_delay()

	refresh_active_shortcuts()

	# save the status including the _lib values
	_save_config_file()

# Update all the preferences status but after a short delay as they aren't updated immediately on the apply button is pressed.
func update_preferences_after_delay(delay: float = 0.2):

	outputlog("update_preferences_after_delay: ",2)
	var timer = Timer.new()
	timer.autostart = false
	timer.one_shot = true
	Global.Editor.Toolset.GetToolPanel("SelectTool").add_child(timer)

	timer.start(delay)
	yield(timer,"timeout")

	# If the hide default object shadows button is pressed, then hide the shadows button in each menu
	on_show_hide_default_object_shadow_in_preferences(_lib_mod_config.show_hide_default_object_shadow)
	# If the hide default wall shadows button is pressed, then hide the shadows button in each menu
	on_show_hide_default_wall_shadow_in_preferences(_lib_mod_config.show_hide_default_wall_shadow)

	# Update disable_bevel_walls
	on_disable_bevel_walls(_lib_mod_config.disable_bevel_walls)
	logging_level = int(_lib_mod_config.core_log_level)
	presetsdropdown.logging_level = logging_level

	Global.Editor.Toolset.GetToolPanel("SelectTool").remove_child(timer)
	timer.queue_free()


# Function to refresh all the shortcuts in the shortcuts tree if _Lib is not installed.
func refresh_non_lib_shortcuts():

	var list_of_shortcut_display_names = []
	var button_index = 0
	var action_text
	var key_string

	var tree_root = ui_config["preferences_ui"]["shortcuts_tree"].get_root()
	var tree_item = tree_root.get_children()

	for button in ui_config["buttons"]:
		list_of_shortcut_display_names.append(button["tool_display_name"])

	while tree_item != null:
			outputlog("tree_item.get_text(0): " + str(tree_item.get_text(0)))
			
			# If we have started looking at custom keys
			if tree_item.get_text(0) in list_of_shortcut_display_names:
				button_index = list_of_shortcut_display_names.find(tree_item.get_text(0))
				outputlog("found display_name: " + str(ui_config["buttons"][button_index]["tool_display_name"]))
				action_text = ui_config["buttons"][button_index]["tool_reference"]
				key_string = tree_item.get_text(1)
				# Set the shortcut key value
				ui_config["buttons"][button_index]["shortcut_key_value"] = key_string
				outputlog("setting value: " + str(action_text) + " key: " + str(key_string),2)
				# Update the hint tooltip for the button
				ui_config["buttons"][button_index]["button"].hint_tooltip = ui_config["buttons"][button_index]["tool_display_name"] + " (" + ui_config["buttons"][button_index]["shortcut_key_value"] + ")"
				
				# Add the shortcut key to an array that we will use to check against key input events
				create_or_set_key_action(action_text, key_string)

			tree_item = tree_item.get_next()


# Function to create an action if it doesn't exist and reset the key event if it is non-blank
func create_or_set_key_action(action_text: String, key_string: String):
	if InputMap.has_action(action_text):
		if not InputMap.action_has_event(action_text,create_key_action(key_string)) && key_string != "":
			InputMap.action_erase_events(action_text)
			InputMap.action_add_event(action_text,create_key_action(key_string))		
	else:
		InputMap.add_action(action_text)
		if key_string != "":
			InputMap.action_add_event(action_text,create_key_action(key_string))

# Function to add additional shortcut key items to the preferences menu
func add_custom_shortcut_items_to_preferences():

	var tree_root
	var new_entry
	var texture

	# Get the tree root
	tree_root = ui_config["preferences_ui"]["shortcuts_tree"].get_root()
	# Get the texture of the change key icon from the first entry in the tree
	texture = tree_root.get_children().get_button(2,0)

	# For each button config, look to see if we want to add shortcut key
	for button_config in ui_config["buttons"]:
		# If the config indicates that they want to have a shortcut button defined
		if button_config["key_button"].pressed:
			# Create a new entry in the tree to capture the value of the shortcut
			new_entry = ui_config["preferences_ui"]["shortcuts_tree"].create_item(tree_root)
			new_entry.set_text(0, button_config["tool_display_name"])
			new_entry.set_text(1, button_config["shortcut_key_value"])
			new_entry.add_button(2, texture)

# Create InputEventKey from key string
func create_key_action(key_string: String) -> InputEventKey:
	var input = InputEventKey.new()
	input.pressed = true
	if key_string.find("+") > -1:
		var split_string = key_string.split("+", true, 0)
		input.scancode = OS.find_scancode_from_string(split_string[-1])
		for _i in split_string.size()-1:
			match split_string[_i]:
				"Command", "Cmd":
					input.command = true
				"Alt":
					input.alt = true
				"Shift":
					input.shift = true
				"Control", "Ctrl":
					input.control = true	
	else:
		input.scancode = OS.find_scancode_from_string(key_string)

	return input

# Create key string from InputEventKey
func convert_key_action_to_string(inputeventkey: InputEventKey) -> String:
	var key_string = ""
	if inputeventkey.command:
		key_string = "Command+"
	if inputeventkey.alt:
		key_string = "Alt+"		
	if inputeventkey.shift:
		key_string = "Shift+"
	if inputeventkey.control:
		key_string = "Control+"
		
	key_string = key_string + OS.get_scancode_string(inputeventkey.scancode)
	return key_string

#########################################################################################################
##
## CHANGE WALL ORDER FUNCTIONS
##
#########################################################################################################

# Function to move the selected wall in the current level to the back or forwards based on a string value
func move_wall_order(destination: String):

	# Check there is only one wall selected. Noting it should not be possible to call this function if this is not true
	if Global.Editor.Tools["SelectTool"].Selected.size() != 1:
		return

	# Get the currently selected wall
	var selected_wall = Global.Editor.Tools["SelectTool"].Selected[0]

	# If destination is back
	if destination == "Back":
		# Move the wall to be the first child, i.e. the lowest wall
		Global.World.GetCurrentLevel().Walls.move_child(selected_wall,0)
	else:
		# Move the wall to be the last child, i.e. the highest wall
		Global.World.GetCurrentLevel().Walls.move_child(selected_wall,Global.World.GetCurrentLevel().Walls.get_child_count()-1)

# Make the UI for the move wall functions
func make_ui_for_change_wall_order():

	# Get the wall grid menu
	var select_tool_wall_gridmenu = Global.Editor.Toolset.GetToolPanel("SelectTool").wallTextureMenu
	# Get the wall vbox which appears when a wall is selected
	var select_tool_wall_vbox = Global.Editor.Toolset.GetToolPanel("SelectTool").wallOptions
	# Get the index of the grid menu in the vbox
	var ui_index = select_tool_wall_gridmenu.get_index()

	# Add the buttons to change the wall order
	make_buttons_for_change_wall_order(select_tool_wall_vbox, ui_index)

# Create UI buttons for changing the wall order based on the vbox in the select tool and the index of the grid menu
func make_buttons_for_change_wall_order(vbox: VBoxContainer, index: int):

	# Make a new hbox to contain the buttons
	var hbox = HBoxContainer.new()

	# Make a bring to front button and link the function correctly.
	var up_button = Button.new()
	up_button.icon = ResourceLoader.load("res://ui/icons/misc/over.png")
	up_button.text = "Bring to Front"
	up_button.connect("pressed",self,"move_wall_order",["Front"])
	hbox.add_child(up_button)

	# Make a send to back button and link the function correctly.
	var down_button = Button.new()
	down_button.icon = ResourceLoader.load("res://ui/icons/misc/under.png")
	down_button.text = "Send to Back"
	down_button.connect("pressed",self,"move_wall_order",["Back"])
	hbox.add_child(down_button)

	# Add the hbox to the wall selected vbox and move it to the right place
	vbox.add_child(hbox)
	vbox.move_child(hbox,index)

#########################################################################################################
##
## SCATTER TOOL PRESETS FUNCTIONS
##
#########################################################################################################

# Function to look for old scatter presets in the mod directory and move them to the new data structure.
func migrate_old_scatter_presets():

	outputlog("migrate_old_scatter_presets()",1)

	# Config file path as the old config file path
	var file_path = Global.Root + "scatter_presets_config.json"
	var data = {"config_name": "Scatter Tool Preset Configs", "group_data": {}}

	var file = File.new()
	var err = file.open(file_path, File.READ)
	if err != OK:
		outputlog("on_preset_file_to_import_selected: file not found nothing to migrate" + str(file_path),1)

		return
	else:
		var content = file.get_as_text()
		file.close()
		
		var json_result = JSON.parse(content)
		if json_result.error == OK:
			# Convert the current store data into a long list
			presetsdropdown.convert_store_data_to_long_list()
			# Convert old data format into group data
			var group_id = presetsdropdown.get_new_group_id()
			data["group_data"][group_id] = {"group_name": "Legacy"}
			if json_result.result.has("list"):
				data["group_data"][group_id]["list"] = json_result.result["list"].duplicate(true)
			else:
				data["group_data"][group_id]["list"] = []
			
			outputlog(JSON.print(data,"\t"))
			
			# Merge the new data into the store data object
			presetsdropdown.merge_into_store_data(data)
			# Load the result into the ui
			presetsdropdown._load_store_data_into_ui()
			presetsdropdown._save_preset_config_file()
			var dir = Directory.new()
			dir.remove(file_path)
				
		else:
			outputlog("JSON Parse Error: ", json_result.error_string(), " in ", content, " at line ", json_result.error_line())

	return

# Function to build a button in preferences to enable scatter presets
func add_preferences_option_to_view_scatter_presets():

	var hbox = HBoxContainer.new()
	ui_config["preferences_ui"]["general_area"].add_child(hbox)
	var button = CheckButton.new()
	hbox.add_child(button)
	ui_config["preferences_ui"]["scatter_presets_button"] = button
	button.text = "Enable Presets in Scatter Tool"
	button.connect("toggled", self, "on_press_scatter_presets_button_in_preferences")
	ui_config["preferences_ui"]["scatter_presets_button"].pressed = ui_config["preferences_ui"]["scatter_presets_enabled"]

	if Engine.has_signal("_lib_register_mod"):
		button.visible = false
	

# Function to enable/disable 
func on_press_scatter_presets_button_in_preferences(button_pressed):

	outputlog("on_press_scatter_presets_button_in_preferences",2)

	ui_config["preferences_ui"]["scatter_presets_enabled"] = button_pressed
	presetsdropdown.ui_hbox.visible = button_pressed

# Function to save the current preset values into the presetdropdown
func save_ui_values_into_current_preset(presets_dropdown):

	# Construct of dictionary of saved values from the ui
	var preset_config = {}

	var index = presets_dropdown.dropdown.selected
	# If we have selected no scatter preset or this it the "add button" (noting this should not be possible) then don't save
	if index == 0 || index == presets_dropdown.dropdown.get_item_count()-1:
		return

	# Read in values from the current configuration of the scatter tool
	preset_config["texture_paths"] = []
	for texture in Global.Editor.ObjectLibraryPanel.objectMenu.GetMultiselectedTextures():
		preset_config["texture_paths"].append(texture.resource_path)
	preset_config["name"] = presets_dropdown.dropdown.get_item_text(presets_dropdown.dropdown.selected)
	preset_config["layer"] = scatter_tool.ActiveLayer
	preset_config["shadow"] = scatter_tool.Shadow
	preset_config["MinRotation"] = scatter_tool.MinRotation.value
	preset_config["MaxRotation"] = scatter_tool.MaxRotation.value
	preset_config["MinScale"] = scatter_tool.MinScale.value
	preset_config["MaxScale"] = scatter_tool.MaxScale.value
	preset_config["Spread"] = scatter_tool.Spread.value
	preset_config["Sorting"] = scatter_tool.Sorting
	preset_config["colors"] = []
	for color in scatter_tool.Colors:
		preset_config["colors"].append(color.to_html(true))

	# Set the data store to this new preset_config, noting we are ignoring the first value

	presets_dropdown.save_current_preset_values(preset_config)

# Function to laod the preset values from a selected config into the UI based on the index of the preset dropdown selection
func load_preset_values_into_ui_from_config(preset_config,presets_dropdown):

	outputlog("load_preset_values_into_ui_from_config: " + str(preset_config),2)

	var array_of_textures
	var array_of_colors
	
	# Not needed but just to stop empty presets loading. Used in development only.
	if not preset_config.has("layer"):
		return

	# For the layers we need to use SetLayer so look at the LayerMenu and find the right value 
	for layer_index in scatter_tool.LayerMenu.get_item_count():
		# Note that the metadata of the optionbutton is what holds the true layer rather than the display name
		if scatter_tool.LayerMenu.get_item_metadata(layer_index) == preset_config["layer"]:
			scatter_tool.SetLayer(layer_index)
			scatter_tool.LayerMenu.selected = layer_index

	scatter_tool.SetShadow(preset_config["shadow"])
	scatter_tool.MinRotation.value = preset_config["MinRotation"]
	scatter_tool.MaxRotation.value = preset_config["MaxRotation"]
	scatter_tool.MinScale.value = preset_config["MinScale"]
	scatter_tool.MaxScale.value = preset_config["MaxScale"]
	scatter_tool.Spread.value = preset_config["Spread"]
	scatter_tool.SetSorting(preset_config["Sorting"])

	# Read in values from the current configuration of the scatter tool
	# If there is only one texture in the list then just set the singleton
	if preset_config["texture_paths"].size() == 1:
		# Construct an array of textures, this is a bit of a funky method
		array_of_textures = []
		array_of_textures.append(ResourceLoader.load(preset_config["texture_paths"][0]))
		# Set the "textures" array to that value
		scatter_tool.textures = array_of_textures
		# Set the single value to that texture
		scatter_tool.texture = ResourceLoader.load(preset_config["texture_paths"][0])
		# Select the right texture on the grid menu
		scatter_tool.GridMenu.SelectTexture(scatter_tool.texture)

	# If there is more than one then set up textures array
	elif preset_config["texture_paths"].size() > 1:
		# Construct an array of textures, this is a bit of a funky method
		array_of_textures = []
		# for each texture path add the right texture
		for texture_path in preset_config["texture_paths"]:
			array_of_textures.append(ResourceLoader.load(texture_path))
		scatter_tool.textures = array_of_textures
		# Select the textures in the grid by selecting the first one, first
		var isfirst = true
		for texture in array_of_textures:
			if isfirst:
				isfirst = false
				# select the first texture in the gridmenu
				scatter_tool.GridMenu.SelectTexture(texture)
			else:
				scatter_tool.GridMenu.MultiselectTexture(texture)
		scatter_tool.Next(true)

	# Load up colors
	array_of_colors = []
	for color_string in preset_config["colors"]:
		# Add the color to the array of colours array to set in the scatter tool later
		array_of_colors.append(Color(color_string))
		# If this is first of the selected colours, then select as a single to deselect all previous values
		if color_string == preset_config["colors"][0]:
			# For each colour look at the current UI list and if it exists select it or create a new one and select it. Note we select a single so to deselect previous colours
			ui_config["custom_color_palette"].colorList.select(find_add_custom_colour_in_scatter_tool(Color(color_string)),true)
			# Set the background of the main colour button to the first colour
			ui_config["custom_color_palette"].SetColor(Color(color_string),true)
		else:
			# For each colour look at the current UI list and if it exists select it or create a new one and select it.
			ui_config["custom_color_palette"].colorList.select(find_add_custom_colour_in_scatter_tool(Color(color_string)),false)

	scatter_tool.Colors = array_of_colors

# Function to build the UI to add and modify scatter tool presets
func make_scatter_presets_ui():

	outputlog("make_modify_path_ui")

	var vbox = Global.Editor.Toolset.GetToolPanel("ScatterTool").Align
	var index
	var find_text = ["CUSTOM COLOR","CUSTOM_COLOR"]

	ui_config["scatter_tool_panel"] = {}

	# Look for the custom color label
	index = find_index_of_text_in_container(vbox, ["Label"], find_text)
	# Check if the next thing is a color palette and assume it is the custom color one if so
	if vbox.get_child(index+1).get("colorList") != null:
		ui_config["custom_color_palette"] = vbox.get_child(index+1)
	if ui_config["custom_color_palette"] == null:
		return
	index += 2
	
	# Make presets 
	presetsdropdown.make_presets_ui(vbox, index)
	index += 1
	# List for the request to save the UI values into the preset dropdown, pass this dropdown in case we have multiple preset dropdowns
	presetsdropdown.connect("request_save_current_preset_values", self, "save_ui_values_into_current_preset", [presetsdropdown])
	presetsdropdown.connect("load_preset_values", self, "load_preset_values_into_ui_from_config", [presetsdropdown])
	presetsdropdown.dropdown.hint_tooltip = "Select or create new preset values for scatter tool."
	

	# If this has been disabled in preferences then hide the hbox
	add_preferences_option_to_view_scatter_presets()
	if not ui_config["preferences_ui"]["scatter_presets_enabled"]:
		presetsdropdown.ui_hbox.visible = false
	
	presetsdropdown._load_scatter_preset_config_file()

# Function to look for the specified colour in the scatter tool custom colour list and either return its position or add a new entry and return its position
func find_add_custom_colour_in_scatter_tool(color: Color):

	var colorlist = ui_config["custom_color_palette"].colorList
	var new_index

	# Check each current item in the custom colour list
	for index in colorlist.get_item_count()-1:
		# If we find a matching color then return its index
		if colorlist.get_item_icon_modulate(index) == color:
			return index

	# If we got here then there was no matching colour so create a new one noting that it is always added at the end
	var colorpreviewicon = ResourceLoader.load("res://ui/icons/buttons/color_preview.png")
	colorlist.add_icon_item(colorpreviewicon)
	# Move it so the add new button is at the end
	colorlist.move_item(colorlist.get_item_count()-1,colorlist.get_item_count()-2)
	new_index = colorlist.get_item_count()-2

	# Set the icon modulate
	colorlist.set_item_icon_modulate(new_index,color)
	# Return the new colours index, ie the peniultimate one
	return new_index

# Check whether the all of the assets in the scatter presets template are available in the current map
func check_scatter_preset_has_valid_assetpacks(config: Dictionary):

	var pack_def
	var asset_manifest_ids = []

	for asset_pack in Global.Header.AssetManifest:
		asset_manifest_ids.append(asset_pack.ID)

	outputlog("check_scatter_preset_has_valid_assetpacks: " + str(config),1)

	for texture_path in config["texture_paths"]:

		# Find the pack id for the texture path, noting that pack id is the 2nd element of the returned array
		pack_def = find_texture_name_and_pack(texture_path)

		# If this is native DD asset then we can
		if pack_def["pack_id"] == "nativeDD":
			if not Global.Header.UsesDefaultAssets:
				return false
		else:
			# For each asset pack in the manifest, check whether it is valid
			if not pack_def["pack_id"] in asset_manifest_ids:
				# If we didn't get a match yet then there isn't one and 
				outputlog("check_scatter_preset_has_valid_assetpacks: asset pack not found " + JSON.print(pack_def))
				return false
	
	return true

#########################################################################################################
##
## RANDOM MIRROR FUNCTIONS
##
#########################################################################################################

# Make the UI element to set a random mirror option in scatter tool
func make_scatter_random_mirror_ui():

	var vbox = Global.Editor.Toolset.GetToolPanel("ScatterTool").Align
	# Find the index of the Scale label and put the UI just before it there.
	var index = find_index_of_text_in_container(vbox, "Label", ["SCALE"])
	var checkbutton = CheckButton.new()

	ui_config["scatter"] = {}
	ui_config["scatter"]["random_mirror_button"] = checkbutton
	ui_config["scatter"]["last_stroke"] = []
	checkbutton.text = "Random Mirror"

	vbox.add_child(checkbutton)
	vbox.move_child(checkbutton,index)

# Function to look at the current stroke and apply random mirror to any objects that have not been looked at
func apply_random_mirror_to_current_stroke():

	# If the stroke list has changed and is non-zero
	if ui_config["scatter"]["last_stroke"] != Global.Editor.Tools["ScatterTool"].currentStroke && Global.Editor.Tools["ScatterTool"].currentStroke.size() > 0:
		# For each record in the current stroke, noting that it is very unlikely that this function will not have been called after only a single extra placement
		for _i in Global.Editor.Tools["ScatterTool"].currentStroke.size():
			var prop = Global.Editor.Tools["ScatterTool"].currentStroke[_i]
			# Check if the index exists in the last stroke
			if _i < ui_config["scatter"]["last_stroke"].size():
				# If it does not match the record in the current stroke then randomise the mirror state
				if ui_config["scatter"]["last_stroke"][_i] != prop:
					prop.Mirror = randi() & 1
			# If not then randomise its mirror state
			else:
				prop.Mirror = randi() & 1
		# Register this as the last stroke
		ui_config["scatter"]["last_stroke"] = Global.Editor.Tools["ScatterTool"].currentStroke


#########################################################################################################
##
## SHOW OR HIDE DEFAULT SHADOW FUNCTION
##
#########################################################################################################

# Function to show or hide the default object shadow button in the Object Tool, Scatter Tool or Select Tool
func on_show_hide_default_object_shadow_in_preferences(button_pressed: bool):

	outputlog("on_show_hide_default_object_shadow_in_preferences",2)

	var find_text = ["SHADOW"]
	var index
	var list_of_vboxes = [Global.Editor.Toolset.GetToolPanel("ObjectTool").Align, Global.Editor.Toolset.GetToolPanel("ScatterTool").Align, Global.Editor.Toolset.GetToolPanel("SelectTool").objectOptions]

	ui_config["scatter_tool_panel"] = {}

	# Look for the custom color label
	for vbox in list_of_vboxes:
		index = find_index_of_text_in_container(vbox, ["Button"], find_text)
		# If we have found the index of something then set it to visible/invisible
		if index >= 0:
			# Get the matching child and set its visibility to 
			if button_pressed:
				vbox.get_child(index).visible = false
				vbox.get_child(index).pressed = false
			else:
				vbox.get_child(index).visible = true


# Function to show or hide the default wall shadow button in the Wall Tool or Select Tool
func on_show_hide_default_wall_shadow_in_preferences(button_pressed: bool):

	outputlog("on_show_hide_default_wall_shadow_in_preferences",2)

	var find_text = ["SHADOW"]
	var index
	var list_of_vboxes = [Global.Editor.Toolset.GetToolPanel("WallTool").Align, Global.Editor.Toolset.GetToolPanel("SelectTool").wallOptions]

	ui_config["scatter_tool_panel"] = {}

	# Look for the custom color label
	for vbox in list_of_vboxes:
		index = find_index_of_text_in_container(vbox, ["Button"], find_text)
		# If we have found the index of something then set it to visible/invisible
		if index >= 0:
			# Get the matching child and set its visibility to 
			if button_pressed:
				vbox.get_child(index).visible = false
				vbox.get_child(index).pressed = false
			else:
				vbox.get_child(index).visible = true


#########################################################################################################
##
## CHANGE SORTING BUTTONS FUNCTIONS
##
#########################################################################################################

# Function to find all the sorting buttons
func find_all_sorting_buttons():

	outputlog("find_all_sorting_buttons()",0)

	var buttons
	var vbox
	ui_config["sorting"] = {}

	# For the main tools, find the sorting buttons
	for tool_type in ["ObjectTool", "ScatterTool", "PathTool", "WallTool"]:
		vbox = Global.Editor.Toolset.GetToolPanel(tool_type).Align
		buttons = find_sorting_buttons_in_container(vbox,["SORTING"])
		if buttons[0] != null && buttons[1] != null:
			if not ui_config["sorting"].has(tool_type):
				ui_config["sorting"][tool_type] = {}
			ui_config["sorting"][tool_type]["over_button"] = buttons[0]
			ui_config["sorting"][tool_type]["under_button"] = buttons[1]

	# Find the Bring to Front and send to back buttons
	var tool_type = "SelectTool"
	if not ui_config["sorting"].has(tool_type):
		ui_config["sorting"][tool_type] = {}
	
	for thing in select_tool_panel.layerSection.get_children():
		if thing is HBoxContainer:
			if thing.get_child(0) is Button:
				ui_config["sorting"][tool_type]["over_button"] = thing.get_child(0)
				ui_config["sorting"][tool_type]["under_button"] = thing.get_child(1)

# Function to find the sorting buttons in a container
func find_sorting_buttons_in_container(vbox, find_text):

	outputlog("find_sorting_buttons_in_container: " + str(vbox),1)

	var buttons = [null,null]
	var index = -1

	index = find_index_of_text_in_container(vbox,"Label",find_text)

	# If we have found the text
	if not index < 0:
		# Check that the next entry is an HBoxContainer hopefully containing two buttons
		if vbox.get_child(index+1) is HBoxContainer:
			if vbox.get_child(index+1).get_child(0) is Button:
				buttons[0] = vbox.get_child(index+1).get_child(0)
			if vbox.get_child(index+1).get_child(1) is Button:
				buttons[1] = vbox.get_child(index+1).get_child(1)

	return buttons

# Function to implement a sorting change action
func on_sorting_change_requested(tool_type: String, sorting_action: String):

	outputlog("on_sorting_change_requested: " + tool_type + " " + sorting_action,2)
	if tool_type == "SelectTool":
		if Global.Editor.Tools["SelectTool"].Selected.size() == 0:
			return
	if not ui_config.has("sorting"):
		return
	if ui_config["sorting"].has(tool_type):
		match sorting_action:
			"sorting_up":
				if ui_config["sorting"][tool_type].has("over_button"):
					ui_config["sorting"][tool_type]["over_button"].pressed = true
					ui_config["sorting"][tool_type]["over_button"].emit_signal("pressed")

			"sorting_down":
				if ui_config["sorting"][tool_type].has("under_button"):
					ui_config["sorting"][tool_type]["under_button"].pressed = true
					ui_config["sorting"][tool_type]["under_button"].emit_signal("pressed")


#########################################################################################################
##
## CHANGE LAYER MENU FUNCTIONs
##
#########################################################################################################

func find_all_layer_menus():

	outputlog("find_all_layer_menus()",0)

	ui_config["layer_menus"] = {}

	var vbox
	var index

	# For the main tools, find the sorting buttons
	for tool_type in ["ObjectTool", "ScatterTool", "PathTool", "WallTool", "PatternShapeTool", "MaterialBrush"]:
		vbox = Global.Editor.Toolset.GetToolPanel(tool_type).Align
		index = find_index_of_text_in_container(vbox,"Label",["LAYER"])
		if not index < 0:
			if vbox.get_child(index+1) is OptionButton:
				ui_config["layer_menus"][tool_type] = vbox.get_child(index+1)
				outputlog("Found " + str(tool_type) + " Layer menu: " + str(vbox.get_child(index+1)),1)

	# Find select layer menu
	ui_config["layer_menus"]["SelectTool"] = Global.Editor.Tools["SelectTool"].LayerMenu

# Function to return the index of the layer with value layer
func get_layer_index(layer: int, layer_menu):

	# For each record in the layer menu
	for _i in layer_menu.get_item_count():
		if layer == layer_menu.get_item_metadata(_i):
			return _i
	
	return -1

# Function to get the layer of an asset
func get_layer(node):

	# If it is a pattern
	if node is Polygon2D:
		return node.GetLayer()
	# If it is an object or path
	elif node.get("Sprite") != null || node is Line2D:
		return node.z_index

	return -10000

# Function to set the layer of an asset
func set_layer(node, layer: int):

	# If it is a pattern we need to use the SetLayer function
	if node is Polygon2D:
		node.SetLayer(layer)
	# If it is an object
	elif node.get("Sprite") != null || node is Line2D:
		node.z_index = layer

# get the array of valid user layers for the current level
func get_current_user_layer_array() -> Array:

	outputlog("get_current_user_layer_array",2)

	var layer_array = []

	for layer in Global.World.GetCurrentLevel().SaveLayers().keys():
		layer_array.append(int(layer))

	layer_array.sort()

	return layer_array

# Find the next user layer in change index direction
func find_next_user_layer(current_layer: int, change_index: int):

	outputlog("find_next_user_layer: " + str(current_layer),2)

	var layer_array = get_current_user_layer_array()

	var index = int(clamp(layer_array.find(current_layer) + change_index, 0, layer_array.size()-1))

	return layer_array[index]

# Function to find the layer value in the selection that is closest to the biggest/smallest possible user layer
func find_closest_layer_to_end_in_selection(change_index: int) -> int:

	outputlog("find_closest_layer_to_end_in_selection:  " + str(change_index),2)

	var farthest = - change_index * 2000
	var layer

	# For each asset that is selected, find the highest layer
	for node in Global.Editor.Tools["SelectTool"].Selectables.keys():
		# If the selected node is an object, path or pattern, then find its layer
		if Global.Editor.Tools["SelectTool"].Selectables[node] in [4,5,7]:
			# Get the layer of the thing
			layer = get_layer(node)
			# If the layer is closer to the extreme than the stored version, then store it
			if (change_index > 0 && layer > farthest) || (change_index < 0 && layer < farthest):
				farthest = layer
	
	return farthest

# Function to move the selected nodes to the next user layer. 
func move_selected_nodes_to_next_user_layer(change_index: int):

	outputlog("move_selected_nodes_to_next_user_layer", 2)

	var history = {}

	# For each asset that is selected, find the highest layer
	for node in Global.Editor.Tools["SelectTool"].Selectables.keys():
		outputlog("node: " + str(node),2)
		# If the selected node is an object, path or pattern, then move it
		if Global.Editor.Tools["SelectTool"].Selectables[node] in [4,5,7]:
			outputlog("type: " + str(Global.Editor.Tools["SelectTool"].Selectables[node]),2)
			history[node.get_meta("node_id")] = {"previous_layer": get_layer(node), "new_layer": -10000}
			move_node_to_next_user_layer(node, change_index)
			# Check if there has been a change and remove the record if not
			if get_layer(node) == history[node.get_meta("node_id")]["previous_layer"]:
				history.erase(node.get_meta("node_id"))
			else:
				history[node.get_meta("node_id")]["new_layer"] = get_layer(node)
	
	# If there is a non-zero change then create a history record
	if history.keys().size() > 0:
		create_update_custom_history_layer_change(history)

# Function to move the node to the next valid layer
func move_node_to_next_user_layer(node, change_index: int):

	outputlog("move_node_to_next_user_layer: " + str(node),2)

	var current_layer = get_layer(node)

	# Get the new index of the layer
	var new_layer = find_next_user_layer(current_layer, change_index)

	# If it is the same as before return without changing anything
	if new_layer == current_layer:
		return
	
	set_layer(node, new_layer)

# Function to change the layer dropdown in response to an action key press
func on_layer_change_requested(tool_type: String, layer_change_action: String):

	outputlog("on_layer_change_requested: " + str(tool_type) + " " + str(layer_change_action),2)

	var layer_menu = ui_config["layer_menus"][tool_type]
	var change_index
	var farthest = -1

	# Error check if the layer menu is null for any reason
	if layer_menu == null:
		return
	
	# Convert the layer action to an index increment
	if layer_change_action == "layer_change_up":
		change_index = 1
	else:
		change_index = -1

	# Sense check that if there is nothing selected then don't do anything
	if tool_type == "SelectTool":
		if Global.Editor.Tools["SelectTool"].Selected.size() == 0:
			return
		# Check in case we ever implement this without requiring _lib
		if Engine.has_signal("_lib_register_mod"):
			# If we want to preserve the layer differences on layer up/down
			if _lib_mod_config.preserve_layer_diff_on_layer_change:
				# Find the closest layer to the last possible one
				farthest = find_closest_layer_to_end_in_selection(change_index)
				# Check whether moving that layer is possible and if so, then, change all the values
				if find_next_user_layer(farthest, change_index) != farthest:
					move_selected_nodes_to_next_user_layer(change_index)
			else:
				move_selected_nodes_to_next_user_layer(change_index)
	
	# Change the layer menu
	outputlog("selected layer menu: " + str(layer_menu.get_item_metadata(layer_menu.selected)),2)
	var new_layer = find_next_user_layer(layer_menu.get_item_metadata(layer_menu.selected), change_index)

	# If this a valid layer on the menu, then set the new value
	var new_index = get_layer_index(new_layer, layer_menu)
	if not new_index < 0:
		layer_menu.select(new_index)
	
		# Change the layer menu signal in case this does something else
		if tool_type != "SelectTool":

			# Emit the change signal to trigger a change in DD
			layer_menu.emit_signal("item_selected", new_index)

# Create custom history record for a change path event
func create_update_custom_history_layer_change(history_data: Dictionary):

	outputlog("create_update_custom_history_layer_change",2)

	outputlog("history_data: " + str(history_data),2)

	# Create a new record if one is needed or simply update the existing one
	var record_script = Script.InstanceReference("library/custom_history_record_layer_change.gd")

	# If this is null for any reason then return to avoid a crash
	if record_script == null:
		outputlog("record_script is null",2)
		return

	record_script.history_data = history_data

	# If this is a new action then create a new custom record
	var record = Global.Editor.History.CreateCustomRecord(record_script)

#########################################################################################################
##
## BEVEL WALLS FUNCTIONS
##
#########################################################################################################

func on_disable_bevel_walls(pressed: bool):

	outputlog("on_disable_bevel_walls: " + str(pressed),2)

	Global.Editor.Tools["WallTool"].Controls["Bevel"].visible = not pressed
	Global.Editor.Tools["WallTool"].Controls["Bevel"].pressed = not pressed

	if ui_config["select_tool_bevel_walls_button"] != null:
		ui_config["select_tool_bevel_walls_button"].visible = not pressed
		ui_config["select_tool_bevel_walls_button"].pressed = not pressed

func make_bevel_walls_ui():

	var button = CheckButton.new()
	button.text = "Bevel Corners"
	Global.Editor.Toolset.GetToolPanel("SelectTool").wallOptions.add_child(button)
	ui_config["select_tool_bevel_walls_button"] = button
	button.connect("toggled", self, "on_bevel_walls_button_pressed")

func on_bevel_walls_button_pressed(button_pressed: bool):

	for node in Global.Editor.Tools["SelectTool"].Selected:
		if get_node_type(node) == "walls":
			if button_pressed:
				node.Joint = 1
			else:
				node.Joint = 0
			node.RemakeLines()

#########################################################################################################
##
## MAIN UPDATE FUNCTIONs
##
#########################################################################################################

# Check every frame if the we need to check the selection
func update(delta : float):

	# If we are in the scatter tool
	if Global.Editor.ActiveToolName == "ScatterTool":
		# Check if the random mirror option is active
		if ui_config["scatter"]["random_mirror_button"].pressed:
			# Check if there is a mouse press on the canvas
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				# Apply random mirror to the current stroke
				apply_random_mirror_to_current_stroke()


#########################################################################################################
##
## START FUNCTION
##
#########################################################################################################

# Function to get the url for the file path
func get_config_path_dir() -> String:

	var config_path_dir = "user://mod_config/" + unique_id.to_lower().replace(" ", "").replace(".", "_")

	var dir: Directory = Directory.new()
	if not dir.dir_exists(config_path_dir):
		dir.make_dir_recursive(config_path_dir)

	return config_path_dir

# Main Script
func start() -> void:

	outputlog("Minor Utils Mod Has been loaded.")
	select_tool_panel = Global.Editor.Toolset.ToolPanels["SelectTool"]
	scatter_tool = Global.Editor.Tools["ScatterTool"]

	toolset_button_count = Global.Editor.Toolset.get_child_count()

	var category = "Settings"
	var id = "MinorUtils"
	mod_name = "Shortcut Configuration"
	unique_id = "uchideshi34.MinorUtils"
	
	var icon = "res://ui/icons/tools/map_settings.png"
	tool_panel = Global.Editor.Toolset.CreateModTool(self, category, id, mod_name, icon)
	config_path = get_config_path_dir() + "/" + CONFIG_FILENAME

	make_bevel_walls_ui()

	# If _Lib is installed then register with it
	if Engine.has_signal("_lib_register_mod"):
		# Register this mod with _lib
		Engine.emit_signal("_lib_register_mod", self)
		# Build a dictionary of input shortcut definitions for _lib
		var shortcut_definitions = {}
		for entry in STORE_DEFAULT_CONFIG["buttons"]:
			shortcut_definitions[entry["tool_display_name"]] = [entry["tool_reference"],entry["shortcut_key_value"]]
		
		shortcut_definitions["Bring To Front/Sorting Over"] = ["sorting_up","Shift+61"]
		shortcut_definitions["Send To Back/Sorting Under"] = ["sorting_down","Shift+45"]
		shortcut_definitions["Layer Up"] = ["layer_change_up","Shift+46"]
		shortcut_definitions["Layer Down"] = ["layer_change_down","Shift+44"]

		# Add the actions
		outputlog("shortcut_definitions: " + str(shortcut_definitions),2)
		Global.API.InputMapApi.add_actions(shortcut_definitions)

		# Create a config builder to ensure we can store the keys if changed in preferences
		_lib_config_builder = Global.API.ModConfigApi.create_config()
		_lib_config_builder\
			.shortcuts("shortcuts",shortcut_definitions)\
			.check_button("preserve_layer_diff_on_layer_change", true, "Selected Asset Layer Differences Preserved on Layer Up")\
			.check_button("scatter_presets_enabled", true, "Show Optional Scatter Presets")\
			.connect_current("toggled", self, "on_press_scatter_presets_button_in_preferences")\
			.check_button("show_hide_default_object_shadow", false, "Hide Default Object Shadows")\
			.check_button("show_hide_default_wall_shadow", false, "Hide Default Wall Shadows")\
			.check_button("disable_bevel_walls", false, "Hide And Disable Bevel Wall Option")\
			.h_box_container().enter()\
				.label("Core Log Level ")\
				.option_button("core_log_level", 0, ["0","1","2","3","4"])\
			.exit()
		_lib_mod_config = _lib_config_builder.build()
		# If the hide default object shadows button is pressed, then hide the shadows button in each menu
		on_show_hide_default_object_shadow_in_preferences(_lib_mod_config.show_hide_default_object_shadow)
		# If the hide default wall shadows button is pressed, then hide the shadows button in each menu
		on_show_hide_default_wall_shadow_in_preferences(_lib_mod_config.show_hide_default_wall_shadow)
		# If the hide bevel walls 
		on_disable_bevel_walls(_lib_mod_config.disable_bevel_walls)
		logging_level = int(_lib_mod_config.core_log_level)

		var _lib_mod_meta = Global.API.ModRegistry.get_mod_info("CreepyCre._Lib").mod_meta
		if _lib_mod_meta != null:
			if compare_semver("1.1.2", _lib_mod_meta["version"]):
				var update_checker = Global.API.UpdateChecker
				
				update_checker.register(Global.API.UpdateChecker.builder()\
														.fetcher(update_checker.github_fetcher("uchideshi34", "MinorUtils"))\
														.downloader(update_checker.github_downloader("uchideshi34", "MinorUtils"))\
														.build())

	# Initialise the UI config for buttons
	ui_config["config_name"] = "Minor Utils Configuration"
	ui_config["buttons"] = []
	ui_config["shortcut_keys"] = []
	Global.Editor.saveButton.connect("pressed", self, "on_save_button_pressed")
	ui_config["preferences_ui"] = {}

	# Initialise Preset Scatter Options
	PresetsDropdown = ResourceLoader.load(Global.Root + "PresetsDropdown.gd", "GDScript", true)
	presetsdropdown = PresetsDropdown.new()
	presetsdropdown.global = Global
	presetsdropdown.preset_config_filename = "scatter_presets_config.json"
	presetsdropdown.preset_config_name = "Scatter Tool Preset Configs"
	presetsdropdown.archive_is_valid_data = {"main_script": self, "is_valid_function": "check_scatter_preset_has_valid_assetpacks"}
	presetsdropdown.logging_level = logging_level

	_read_config_file()
	read_preferences_ui_values()

	for config in ui_config["buttons"]:
		make_shortcut_button(config)
		make_config_entry_for_button(config)

	make_scatter_presets_ui()

	make_scatter_random_mirror_ui()

	make_ui_for_change_wall_order()

	find_all_layer_menus()
	find_all_sorting_buttons()

	# Function to migrate old scatter presets to the new storage system
	migrate_old_scatter_presets()

	set_up_unhandled_key_inputs()

#########################################################################################################
##
## VERSION CHECKER FUNCTIONS
##
#########################################################################################################

# Check whether a semver strng 2 is greater than string one. Only works on simple comparisons - DO NOT USE THIS FUNCTION OUTSIDE THIS CONTEXT
func compare_semver(semver1: String, semver2: String) -> bool:

	outputlog("compare_semver: semver1: " + str(semver1) + " semver2" + str(semver2),2)
	var semver1data = get_semver_data(semver1)
	var semver2data = get_semver_data(semver2)

	if semver1data == null || semver2data == null : return false

	if semver1data["major"] != semver2data["major"]:
		return semver1data["major"] < semver2data["major"]
	if semver1data["minor"] != semver2data["minor"]:
		return semver1data["minor"] < semver2data["minor"]
	if semver1data["patch"] != semver2data["patch"]:
		return semver1data["major"] < semver2data["major"]
	
	return false

# Parse the semver string
func get_semver_data(semver: String):

	var data = {}

	if semver.split(".").size() < 3: return null

	return {
		"major": int(semver.split(".")[0]),
		"minor": int(semver.split(".")[1]),
		"patch": int(semver.split(".")[2].split("-")[0])
	}



#########################################################################################################
##
## KEY INPUT FUNCTIONS
##
#########################################################################################################
# Function to set up the unhandled key inputs
func set_up_unhandled_key_inputs():

	var unhandledkeyemitter = UnhandledKeyEmitter.new()
	unhandledkeyemitter.global = Global
	Global.World.add_child(unhandledkeyemitter)
	# Connects to the key input signal and calls on_unhandled_key_event function
	unhandledkeyemitter.connect("this_is_a_key_input", self, "on_unhandled_key_event")

# Function that responds to key input events specific to this mod
func on_unhandled_key_event(event):

	outputlog("on_unhandled_key_event: " + str(OS.get_scancode_string(event.physical_scancode)) + " pressed: " + str(event.pressed),3)
	
	# For each custom shortcut key in the list
	for shortcut_action in ui_config["shortcut_keys"]:
		if InputMap.has_action(shortcut_action):
			if Input.is_action_just_pressed(shortcut_action,true):
				Global.Editor.Toolset.Quickswitch(shortcut_action)
				return
		
	# Check Layer Change Actions
	for layer_change_action in ["layer_change_up","layer_change_down"]:
		if InputMap.has_action(layer_change_action):
			if Input.is_action_just_pressed(layer_change_action,true):
				if Global.Editor.ActiveToolName != null:
					on_layer_change_requested(Global.Editor.ActiveToolName, layer_change_action)
					return
		
		# Check Layer Change Actions
	for sorting_action in ["sorting_up","sorting_down"]:
		if InputMap.has_action(sorting_action):
			if Input.is_action_just_pressed(sorting_action,true):
				if Global.Editor.ActiveToolName != null:
					on_sorting_change_requested(Global.Editor.ActiveToolName, sorting_action)
					return
		
	# If we have just toggled the grid, then trigger a save effect
	if InputMap.has_action("toggle_grid"):
		if Input.is_action_just_pressed("toggle_grid",true):
			outputlog("grid toggled",2)
			_save_config_file()
			return
	
	

# Class which is node that emits unhandled key signals
class UnhandledKeyEmitter extends Node:

	var global = null
	# Main signal that is emitted
	signal this_is_a_key_input

	# Overwrites function to capture the unhandled key input
	func _unhandled_key_input(event):

		# Replicates DD function and logic for handled inputs that aren't captured by the UI
		if not global.Editor.SearchHasFocus:
			var focus = global.Editor.GetFocus()
			if focus == null || (not focus is LineEdit && not focus is Tree):
				self.emit_signal("this_is_a_key_input", event)



