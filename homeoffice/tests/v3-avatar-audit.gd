extends SceneTree

func _initialize():
	call_deferred("run")

func inspect_node(n:Node):
	var row={"name":str(n.get_path()),"type":n.get_class()}
	if n is Node3D:
		row.visible=n.visible
		row.world=str(n.global_transform)
	if n is MeshInstance3D:
		row.aabb=str(n.get_aabb())
		row.layers=n.layers
		row.skin_binds=n.skin.get_bind_count() if n.skin else -1
		row.skeleton=str(n.skeleton)
		row.surfaces=n.mesh.get_surface_count() if n.mesh else 0
	if n is Skeleton3D:
		row.bones=n.get_bone_count()
		row.bone_names=[]
		for i in n.get_bone_count():row.bone_names.append({"name":n.get_bone_name(i),"rest":str(n.get_bone_rest(i)),"pose":str(n.get_bone_global_pose(i))})
	print(JSON.stringify(row))
	for c in n.get_children():inspect_node(c)

func run():
	var a=load("res://scripts/v2/avatar.gd").new()
	root.add_child(a)
	await process_frame
	a.animate(.016)
	inspect_node(a)
	quit()
