extends Node3D
var states={"toilet_ground":false,"toilet_upper":false,"tap_ground":false,"tap_upper":false,"home_light":true,"office_light":true,"bath_light":true,"flush_ground":false,"flush_upper":false,"vent":false}
var fixtures={}
var lights={}
var sounds={}
var flush_until={}
var flush_seen={}
var flush_water={}
var fan:Node3D
var scene:Node3D

func _ready():
	scene=load("res://assets/v2/campus-details-v3.glb").instantiate();add_child(scene)
	for row in [["flush_ground",Vector3(12.10,1.03,-10.32),Vector3(.18,.12,.18)],["flush_upper",Vector3(-11.9,4.63,8.68),Vector3(.18,.12,.18)],["vent",Vector3(11.2,1.25,-6.2),Vector3(.15,.22,.12)],["toilet_ground",Vector3(12,.50,-10),Vector3(.55,.65,.75)],["toilet_upper",Vector3(-12,4.10,9),Vector3(.55,.65,.75)],["tap_ground",Vector3(13.35,1.0,-10),Vector3(.95,.5,.6)],["tap_upper",Vector3(-10.65,4.6,9),Vector3(.95,.5,.6)],["home_light",Vector3(-5.1,1.25,10.2),Vector3(.15,.22,.12)],["office_light",Vector3(1.65,1.25,10.2),Vector3(.15,.22,.12)],["bath_light",Vector3(10.8,1.25,-6.2),Vector3(.15,.22,.12)],["broadcast_console",Vector3(5,1.1,-9.7),Vector3(2.4,.65,1)],["meeting_computer",Vector3(6.5,1.1,6.7),Vector3(.7,.5,.3)]]:
		var body=StaticBody3D.new();body.position=row[1];body.set_meta("object_id",row[0]);body.collision_layer=1
		var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=row[2];shape.shape=box;body.add_child(shape);add_child(body);fixtures[row[0]]=body
	for row in [["home_light",Vector3(-10,2.8,7)],["office_light",Vector3(6.5,2.9,8)],["bath_light",Vector3(12,2.8,-9)]]:
		var light=OmniLight3D.new();light.position=row[1];light.omni_range=7;light.light_energy=1.1;light.shadow_enabled=false;add_child(light);lights[row[0]]=light
	for tag in ["ground","upper"]:
		var y=0 if tag=="ground" else 3.6
		var point=Vector3(12,y,-10) if tag=="ground" else Vector3(-12,y,9)
		var sound=AudioStreamPlayer3D.new();sound.position=point+Vector3.UP*.7;sound.stream=load("res://assets/audio/bath-flush-v3.wav");sound.max_distance=10;sound.volume_db=-16;add_child(sound);sounds["flush_"+tag]=sound
		var tap=AudioStreamPlayer3D.new();tap.position=point+Vector3(1.35,1,0);tap.stream=load("res://assets/audio/bath-water-v3.wav");tap.max_distance=6;tap.volume_db=-23;add_child(tap);sounds["tap_"+tag]=tap
		var water=MeshInstance3D.new();var disk=CylinderMesh.new();disk.top_radius=.15;disk.bottom_radius=.14;disk.height=.015;water.mesh=disk;water.position=point+Vector3(0,.5,0)
		var mat=StandardMaterial3D.new();mat.albedo_color=Color(.18,.58,.72);water.material_override=mat;add_child(water);flush_water[tag]=water;water.visible=false
	fan=Node3D.new();fan.position=Vector3(11.1,2.55,-11.6);add_child(fan)
	for angle in [0,PI/2]:
		var blade=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3(.5,.06,.02);blade.mesh=box;blade.rotation.z=angle;fan.add_child(blade)
	apply();broadcast_display(false)

func toggle(id:String) -> bool:
	if not states.has(id):return false
	if id.begins_with("flush") and Time.get_ticks_msec()<int(flush_until.get(id.trim_prefix("flush_"),0)):return false
	states[id]=not states[id];apply();return true

func apply():
	if not scene:return
	for tag in ["ground","upper"]:
		var lids=scene.find_children("ToiletLid_"+tag+"*","Node3D",true,false)
		if not lids.is_empty():lids[0].rotation.x=-1.2 if states["toilet_"+tag] else 0.0
		var water=scene.find_children("Water_"+tag+"*","Node3D",true,false)
		if not water.is_empty():water[0].visible=states["tap_"+tag]
		var flush_key="flush_"+tag
		if flush_seen.has(tag) and flush_seen[tag]!=states[flush_key]:
			flush_until[tag]=Time.get_ticks_msec()+3400;sounds[flush_key].play()
		flush_seen[tag]=states[flush_key]
		if states["tap_"+tag] and not sounds["tap_"+tag].playing:sounds["tap_"+tag].play()
		elif not states["tap_"+tag]:sounds["tap_"+tag].stop()
	for key in lights:lights[key].visible=states[key]

func restore(value:Dictionary,quiet=false):
	if quiet:flush_seen.clear();flush_until.clear()
	for key in states:
		if value.get(key) is bool:states[key]=value[key]
	apply()

func reset():
	flush_seen.clear();flush_until.clear()
	for key in states:states[key]=key.ends_with("light")
	apply()

func _process(dt):
	for tag in flush_water:
		var remaining=int(flush_until.get(tag,0))-Time.get_ticks_msec()
		flush_water[tag].visible=remaining>0 and states["toilet_"+tag]
		flush_water[tag].rotation.y+=dt*5
		flush_water[tag].scale=Vector3.ONE*(.65+.35*clampf(remaining/3400.0,0,1))
		if states["tap_"+tag] and not sounds["tap_"+tag].playing:sounds["tap_"+tag].play()
	if states.vent:fan.rotation.z+=dt*12

func broadcast_display(active:bool):
	var panels=scene.find_children("OnAir*","MeshInstance3D",true,false)
	for panel in panels:
		panel.visible=active
