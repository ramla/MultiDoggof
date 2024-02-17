class_name SettingsManager

var config = ConfigFile.new()
var config_path = "user://user.cfg"

func _init():
	load_settings()
	print("SettingsManager initialized")

func load_settings():
	var error = config.load(config_path)
	if error != OK:
		print("An error occurred while loading the settings.")

func get_setting(section, key, default_value):
	#return config.get_value(section, key, default_value)
	return config.get_value(section, key, default_value)

func set_setting(section, key, value):
	config.set_value(section, key, value)
	save_settings()

func save_settings():
	var error = config.save(config_path)
	if error != OK:
		print("An error occurred while saving the settings.")

#func load_or_create_settings():
	#var error = config.load(config_path)
	#if error != OK:
		#print("User settings not found. Loading default settings.")
		#config.load(config_path)
# Usage
#load_or_create_settings("user://user_settings.cfg", "res://default_settings.cfg")
