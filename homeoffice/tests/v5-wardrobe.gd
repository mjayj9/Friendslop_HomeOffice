extends SceneTree
const Appearance=preload("res://scripts/wardrobe/appearance.gd")
var checks=[]
func check(name:String,ok:bool):
	checks.append({"name":name,"ok":ok});print(name," ",ok)
func _initialize():call_deferred("run")
func run():
	var world=load("res://scripts/v3/world.gd").new();root.add_child(world)
	await process_frame;await physics_frame
	var p=world.players.local
	check("world has actual imported wardrobe and station colliders",world.wardrobe.get_child_count()>=4)
	check("outside cannot open by action",world.wardrobe.action("local","wardrobe_open",{}).length()>0)
	check("outside cannot apply without station session",world.wardrobe.action("local","wardrobe_apply",{"token":"forged","profile":Appearance.defaults()}).length()>0)
	check("default profile accepted",not Appearance.validate(Appearance.defaults()).is_empty())
	var wrong=Appearance.defaults();wrong.admin=true
	check("privilege or unknown fields rejected",Appearance.validate(wrong).is_empty())
	wrong=Appearance.defaults();wrong.shirt="javascript:alert(1)"
	check("material code rejected",Appearance.validate(wrong).is_empty())
	wrong=Appearance.defaults();wrong.face=Marshalls.raw_to_base64("<svg onload='alert(1)'/>".to_utf8_buffer())
	check("SVG and non-PNG rejected",Appearance.validate(wrong).is_empty())
	var image=Image.create(512,512,false,Image.FORMAT_RGBA8);image.fill(Color(0,0,0,0));image.fill_rect(Rect2i(225,225,64,64),Color("dd2255"))
	var bytes=image.save_png_to_buffer();var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	var profile=Appearance.defaults();profile.face=Marshalls.raw_to_base64(bytes);profile.faceHash=hash.finish().hex_encode();profile.shirt="#228844"
	check("real decoded PNG hash accepted",not Appearance.validate(profile).is_empty())
	var altered=profile.duplicate();altered.faceHash="0".repeat(64)
	check("raster hash mismatch rejected",Appearance.validate(altered).is_empty())
	var huge=bytes.duplicate();huge[18]=32;altered=profile.duplicate();altered.face=Marshalls.raw_to_base64(huge)
	check("oversized header rejected before decompression",Appearance.validate(altered).is_empty())
	world.add_player("other");p.set_appearance(profile)
	check("other avatar profile remains default",world.players.other.appearance_profile.face=="")
	var own=p.standing.find_children("*","MeshInstance3D",true,false)[0];var other=world.players.other.standing.find_children("*","MeshInstance3D",true,false)[0]
	check("material instances are not shared",own.get_active_material(0)!=other.get_active_material(0))
	p.position=Vector3(-8.2,3.6,-.95);p.command.yaw=PI/2;p.command.pitch=-.28;p.camera_rig.third_person=false;p.command.third=false
	await physics_frame
	check("inside bounds recognized",world.wardrobe.inside(p))
	world.wardrobe.sessions.local={"token":"unit-session","epoch":world.epoch}
	var applied=world.wardrobe.action("local","wardrobe_apply",{"token":"unit-session","profile":profile})
	check("valid own active session applies",applied=="" and p.appearance_profile.revision==1)
	check("one-time apply cannot replay",world.wardrobe.action("local","wardrobe_apply",{"token":"unit-session","profile":profile})!="")
	world.wardrobe.sessions.local={"token":"leave-session","epoch":world.epoch};p.position=Vector3(0,0,10);world.wardrobe.maintain()
	check("leaving room expires edit session",not world.wardrobe.sessions.has("local"))
	var saved=world.save_world()
	check("original furnished V4 world fits wardrobe partitions",world.wardrobe.restore_conflicts(saved).is_empty())
	var previous_revision=world.revision
	saved.objects.append({"id":"old-custom-table","kind":"table","p":[-9.8,3.6,-2.2],"yaw":0,"state":{}})
	check("old custom furniture in new wall detected before mutation",world.wardrobe.restore_conflicts(saved).has("old-custom-table"))
	world.restore_world(saved)
	check("conflicting restore preserves current world",not world.objects.has("old-custom-table") and world.revision==previous_revision)
	var checkpoint=world.make_checkpoint()
	world.apply_checkpoint({"host":true,"epoch":"wardrobe-fixture-handoff","checkpoint":checkpoint})
	check("handoff retains decoded appearance profile",world.players.local.appearance_profile.faceHash==profile.faceHash)
	check("handoff invalidates old edit sessions",world.wardrobe.sessions.is_empty())
	var report={"scope":"Engine fixture; synthetic actor positioning is not physical browser entry proof","checks":checks,"passed":checks.all(func(c):return c.ok)}
	var file=FileAccess.open("res://evidence/v5/wardrobe-engine.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	quit(0 if report.passed else 1)
