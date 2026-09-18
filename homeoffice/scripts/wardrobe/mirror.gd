extends Node3D
## A planar reflection of the existing world. It neither teleports the actor nor
## removes collision. Only a render-only duplicate makes first-person bodies visible.
const REFLECTION_BODY_LAYER=1<<19
const Appearance=preload("res://scripts/wardrobe/appearance.gd")
var world
var center:Vector3
var view:SubViewport
var camera:Camera3D
var surface:MeshInstance3D
var reflected_body:Node3D
var reflected_skeleton:Skeleton3D
var clock=0.0
var profile_key=""

func setup(owner_world,at:Vector3):
	world=owner_world;center=at+Vector3(.009,0,0)
	view=SubViewport.new();view.size=Vector2i(288,504);view.world_3d=world.get_world_3d();view.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(view)
	camera=Camera3D.new();camera.cull_mask=1|REFLECTION_BODY_LAYER;camera.keep_aspect=Camera3D.KEEP_HEIGHT;view.add_child(camera);camera.current=true
	surface=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(1.13,1.98);surface.mesh=quad
	var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_texture=view.get_texture();material.uv1_scale=Vector3(-1,1,1);material.uv1_offset=Vector3(1,0,0)
	surface.material_override=material;surface.layers=2;world.add_child(surface);surface.global_position=center;surface.rotation.y=PI/2
	reflected_body=load("res://assets/characters/male-animated-v5.glb").instantiate();world.add_child(reflected_body);reflected_body.visible=false
	for mesh in reflected_body.find_children("*","MeshInstance3D",true,false):mesh.layers=REFLECTION_BODY_LAYER
	for animation in reflected_body.find_children("*","AnimationPlayer",true,false):animation.active=false
	for skeleton in reflected_body.find_children("*","Skeleton3D",true,false):reflected_skeleton=skeleton;break

func _process(dt):
	clock+=dt
	if clock<.05 or not world:return
	clock=0
	var p=world.players.get(world.local_id)
	if not p or p.position.distance_to(center)>5 or p.eye().x<center.x+.25 or world.wardrobe.local_session!="":
		if reflected_body:reflected_body.visible=false
		return
	p.camera.cull_mask=p.camera.cull_mask&~REFLECTION_BODY_LAYER
	var eye=p.camera.global_position
	if eye.x<center.x+.2:return
	camera.global_position=Vector3(2*center.x-eye.x,eye.y,eye.z)
	camera.global_rotation=Vector3(0,-PI/2,0)
	var distance=eye.x-center.x
	camera.set_frustum(1.98,Vector2(center.z-eye.z,center.y-eye.y),distance+.012,80)
	reflected_body.visible=not p.standing.is_visible_in_tree()
	reflected_body.global_transform=p.standing.global_transform
	for bone in p.skeleton.get_bone_count():reflected_skeleton.set_bone_pose(bone,p.skeleton.get_bone_pose(bone))
	var key=p.actor_id+":"+str(p.appearance_profile.revision)+":"+p.appearance_profile.faceHash
	if key!=profile_key:profile_key=key;Appearance.apply(reflected_body,p.appearance_profile)
	view.render_target_update_mode=SubViewport.UPDATE_ONCE

func _exit_tree():
	if is_instance_valid(surface):surface.queue_free()
	if is_instance_valid(reflected_body):reflected_body.queue_free()
