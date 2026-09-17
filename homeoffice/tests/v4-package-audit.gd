extends SceneTree

var paths: Array[String] = []
func visit(path: String):
	var directory = DirAccess.open(path)
	if directory == null: return
	directory.list_dir_begin()
	var item = directory.get_next()
	while item != "":
		if item != "." and item != "..":
			var target = path.path_join(item)
			if directory.current_is_dir(): visit(target)
			else: paths.append(target.trim_prefix("res://"))
		item = directory.get_next()
	directory.list_dir_end()

func _initialize():
	var arguments = OS.get_cmdline_user_args()
	if arguments.size() != 2: quit(2); return
	if not ProjectSettings.load_resource_pack(arguments[0]): quit(3); return
	visit("res://")
	var rejected = []
	for path in paths:
		for prefix in ["server/", "tests/", "evidence/", "art/", "web/", "node_modules/", "PRIVATE_"]:
			if path.begins_with(prefix): rejected.append(path)
		if path.ends_with(".pem") or path.ends_with(".private"): rejected.append(path)
	var marker = JSON.parse_string(FileAccess.get_file_as_string("res://assets/build-version.json"))
	var output = FileAccess.open(arguments[1], FileAccess.WRITE)
	output.store_string(JSON.stringify({"environment":"Actual exported PCK mounted by Godot in a separate empty audit project. No private PIN value loaded or compared.","buildId":marker.buildId,"paths":paths,"forbiddenPaths":rejected,"passed":rejected.is_empty()}, "  "))
	output.close()
	print("Pack paths: ", paths.size(), " forbidden: ", rejected.size(), " build: ", marker.buildId)
	quit(0 if rejected.is_empty() else 1)
