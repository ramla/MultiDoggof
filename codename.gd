class_name Codename

var codenames = {}
var codename_set = {}

func get_codename_set(n):
	codename_set = {}
	for i in n:
		randomize_codename()
	var codename_array = []
	for i in codename_set:
		var codename = codename_set[i]
		codename_array.append(codename)
	print(codename_array)
	return codename_array

func randomize_codename():
	var try = randi() % codenames.size()
	if codename_set.has(try):
		randomize_codename()
	else:
		codename_set[try] = codenames[try]

func init():
	codenames = {}
	var path = Overseer.game_settings["paths"]["codenames"]
	var file = FileAccess.open(path, FileAccess.READ)

	while !file.eof_reached():
		var row = Array(file.get_csv_line())
		codenames[codenames.size()] = row
	file.close()
