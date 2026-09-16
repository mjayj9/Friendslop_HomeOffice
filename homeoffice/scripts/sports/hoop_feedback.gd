extends Node3D
## Visual net response reads physical ball positions; it never changes ball forces or scoring.
var hoops=[]
var elapsed=0.0
func _ready():
	for x in [-16.35,4.35]:
		var instance=MeshInstance3D.new();var mesh=ImmediateMesh.new();instance.mesh=mesh;add_child(instance)
		var material=StandardMaterial3D.new();material.albedo_color=Color(.91,.92,.85);material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		hoops.append({"x":x,"mesh":mesh,"material":material,"energy":0.0,"dirty":true,"cooldown":0.0})
func _process(dt):
	elapsed+=dt
	var world=get_parent()
	for hoop in hoops:
		hoop.cooldown=maxf(0,hoop.cooldown-dt)
		if hoop.cooldown<=0:
			for id in world.objects:
				if world.definitions[id].kind!="basketball":continue
				var ball=world.objects[id];var at=ball.position
				if absf(at.x-hoop.x)<.35 and absf(at.z-30)<.35 and at.y>2.6 and at.y<3.22 and ball.linear_velocity.length()>.2:
					hoop.energy=1.0;hoop.cooldown=.3;hoop.dirty=true;break
		if hoop.energy>0:
			hoop.energy=maxf(0,hoop.energy-dt*1.8);hoop.dirty=true
		if not hoop.dirty:continue
		hoop.dirty=false;draw_net(hoop)
func point(hoop,row:int,index:int) -> Vector3:
	var theta=float(index)*TAU/12+row*TAU/24
	var radius=[.245,.205,.15][row];var y=[3.015,2.82,2.65][row]
	var strength=hoop.energy*float(row)/2
	return Vector3(hoop.x+cos(theta)*radius+sin(elapsed*14)*.04*strength,y+sin(elapsed*18+theta)*.025*strength,30+sin(theta)*radius+cos(elapsed*14)*.04*strength)
func draw_net(hoop):
	var mesh:ImmediateMesh=hoop.mesh;mesh.clear_surfaces();mesh.surface_begin(Mesh.PRIMITIVE_LINES,hoop.material)
	for row in range(3):
		for i in range(12):
			mesh.surface_add_vertex(point(hoop,row,i));mesh.surface_add_vertex(point(hoop,row,(i+1)%12))
			if row<2:
				for next in [i,(i+11)%12]:mesh.surface_add_vertex(point(hoop,row,i));mesh.surface_add_vertex(point(hoop,row+1,next))
	mesh.surface_end()
