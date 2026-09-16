extends Node3D
## Standalone reproducible test scene. It does not inject a multiplayer user's position.
const Ball=preload("res://scripts/sports/ball_profile.gd")
const Surface=preload("res://scripts/physics/surface_profile.gd")
var objects={}
var definitions={}
var samples=[]
var steps=0
func block(p:Vector3,size:Vector3,color:Color,surface="wood"):
	var body=StaticBody3D.new();body.position=p;body.collision_layer=1;body.physics_material_override=Surface.material(surface)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=size;shape.shape=box;body.add_child(shape)
	var mesh=MeshInstance3D.new();var cube=BoxMesh.new();cube.size=size;mesh.mesh=cube
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mesh.material_override=mat;body.add_child(mesh);add_child(body);return body
func ball(id:String,p:Vector3,kind:String):
	var body=RigidBody3D.new();body.position=p;body.name=id;body.collision_layer=4;body.collision_mask=1|4;Ball.configure(body,kind)
	var shape=CollisionShape3D.new();var sphere=SphereShape3D.new();sphere.radius=Ball.radius(kind);shape.shape=sphere;body.add_child(shape)
	var mesh=MeshInstance3D.new();var visual=SphereMesh.new();visual.radius=sphere.radius;visual.height=sphere.radius*2;mesh.mesh=visual;body.add_child(mesh);add_child(body)
	objects[id]=body;definitions[id]={"kind":kind};return body
func _ready():
	block(Vector3(0,-.1,0),Vector3(24,.2,18),Color(.35,.45,.38),"court")
	block(Vector3(8,1,0),Vector3(.06,2,8),Color(.75,.8,.8),"backboard")
	for i in 8:block(Vector3(-6+i*.35,(i+1)*.1,-3),Vector3(.35,(i+1)*.2,2),Color(.58,.38,.2))
	block(Vector3(-4,2,-3),Vector3(2,.2,2),Color(.58,.38,.2))
	var ramp=block(Vector3(-2,.8,-3),Vector3(3,.12,2),Color(.5,.55,.5));ramp.rotation.z=-.45
	block(Vector3(0,.05,-6),Vector3(2,.10,1),Color(.7,.6,.4))
	block(Vector3(2,1.3,-6),Vector3(2,.12,1),Color(.7,.6,.4))
	for x in [3.5,5.5]:block(Vector3(x,1,-6),Vector3(.15,2,.15),Color(.4,.4,.5))
	block(Vector3(4.5,2,-6),Vector3(2.2,.15,.15),Color(.4,.4,.5))
	block(Vector3(-3,.7,3),Vector3(2.4,.15,1.1),Color(.6,.4,.2))
	ball("basket_drop",Vector3(0,3,0),"basketball")
	ball("football_drop",Vector3(2,3,0),"football")
	var fast=ball("ccd",Vector3(5,1,2),"basketball");fast.linear_velocity=Vector3(14,0,0);fast.angular_velocity=Vector3(0,0,8)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-60,-25,0);add_child(light)
	var camera=Camera3D.new();camera.position=Vector3(13,13,17);add_child(camera);camera.look_at(Vector3.ZERO);camera.current=true
	var label=Label3D.new();label.text="PHYSICS LAB · 1 unit = 1 m\nDROP / CCD WALL / STAIRS / RAMP / LOW CEILING / DOOR / TABLE";label.position=Vector3(0,4,-6);label.font_size=48;add_child(label)
func _physics_process(_dt):
	steps+=1
	if steps%2==0:
		var row={"tick":steps}
		for id in objects:row[id]={"p":[objects[id].position.x,objects[id].position.y,objects[id].position.z],"v":[objects[id].linear_velocity.x,objects[id].linear_velocity.y,objects[id].linear_velocity.z],"spin":objects[id].angular_velocity.length()}
		samples.append(row)
		if samples.size()>1800:samples.pop_front()
