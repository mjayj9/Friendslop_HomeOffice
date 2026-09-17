extends Node3D
## Additive finish with one authoritative tabletop collider; keeps legacy IDs and seating.
func _ready():
	add_child(load("res://assets/v4/meeting-finish.glb").instantiate())
	var body=StaticBody3D.new();body.position=Vector3(6.5,.81,8.15);body.collision_layer=1
	body.set_meta("object_id","meeting-table-0")
	var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(3.16,.12,6.3);collision.shape=shape;body.add_child(collision);add_child(body)
	for x in [3.8,9.2]:
		for z in [6.0,10.0]:
			var light=OmniLight3D.new();light.position=Vector3(x,2.9,z);light.omni_range=4.3;light.light_energy=.38;light.light_color=Color("fff6df");light.shadow_enabled=false;light.set_meta("base_energy",.38);light.set_meta("zone","meeting");add_child(light);get_parent().room_lights.append(light)
	var title=Label3D.new();title.text="회의실 01  /  COMMONS";title.font=load("res://assets/fonts/NotoSansKR-game.ttf");title.font_size=48;title.pixel_size=.0035;title.position=Vector3(6.5,2.1,11.76);title.rotation.y=PI;title.modulate=Color("203c3a");add_child(title)
