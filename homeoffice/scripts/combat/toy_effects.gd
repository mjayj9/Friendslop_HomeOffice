extends Node3D
## Bounded pools: repeated fire reuses 16 tracers and 6 spatial sounds.
var tracers=[]
var sounds=[]
var cursor=0
var duck=1.0
var seen={}
func _ready():
	for i in 16:
		var mesh=MeshInstance3D.new();mesh.mesh=ImmediateMesh.new();mesh.visible=false;add_child(mesh);tracers.append(mesh)
	for i in 6:
		var sound=AudioStreamPlayer3D.new();sound.stream=load("res://assets/audio/toy-pop.wav");sound.max_distance=22;add_child(sound);sounds.append(sound)
func show_shot(id:String,from:Vector3,to:Vector3,sound_enabled=true):
	if seen.has(id):return
	seen[id]=true
	if seen.size()>256:seen.erase(seen.keys()[0])
	var mesh=tracers[cursor%tracers.size()];var line:ImmediateMesh=mesh.mesh;line.clear_surfaces()
	var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color("ffb950")
	line.surface_begin(Mesh.PRIMITIVE_LINES,mat);line.surface_add_vertex(from);line.surface_add_vertex(to);line.surface_end();mesh.visible=true;mesh.set_meta("until",Time.get_ticks_msec()+90)
	if sound_enabled:
		var audio=sounds[cursor%sounds.size()];audio.position=from;audio.volume_db=-15+linear_to_db(maxf(.01,duck));audio.play()
	cursor+=1
func _process(_dt):
	for mesh in tracers:
		if mesh.visible and Time.get_ticks_msec()>int(mesh.get_meta("until",0)):mesh.visible=false
