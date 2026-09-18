extends RefCounted
## The only skeletal playback owner. Motor owns displacement; this graph advances
## exactly once per simulation tick. Upper-body filters never overwrite leg tracks.
var avatar
var tree:AnimationTree
var graph:AnimationNodeBlendTree
var nodes={}
var clip_names={}
var base_clip=""
var upper_clip=""
var base_side="A"
var base_mix=0.0
var upper_mix=0.0
var phase=0.0
var playback_rate=1.0
var locomotion="idle"
var profile="HOME"
var posture="standing"
var upper_body=""
var one_shot=""
var grounded=true
var previous_grounded=true
var previous_posture="standing"
var transition_clip=""
var transition_left=0.0
var direction=""
var state_age=0.0
var changes=0
var profile_entries=0
var snapshot_tick=-1
var debug_mode="combined"
var last_action=""
var last_action_stamp=0
var action_id=""
var authored_contacts={}
var previous_yaw=0.0

func setup(p):
	avatar=p
	if not p.animator:return
	for name in p.animator.get_animation_list():
		var short=String(name).get_slice("/",String(name).count("/"))
		clip_names[short.trim_prefix("v3_").trim_prefix("v5_")]=name
	graph=AnimationNodeBlendTree.new()
	for slot in ["A","B","Upper"]:
		var node=AnimationNodeAnimation.new();node.animation=clip_names.get("idle","");nodes[slot]=node
		graph.add_node(slot,node)
		graph.add_node(slot+"Seek",AnimationNodeTimeSeek.new())
		graph.connect_node(slot+"Seek",0,slot)
		graph.add_node(slot+"Rate",AnimationNodeTimeScale.new())
		graph.connect_node(slot+"Rate",0,slot+"Seek")
	graph.add_node("Base",AnimationNodeBlend2.new());graph.connect_node("Base",0,"ARate");graph.connect_node("Base",1,"BRate")
	var upper=AnimationNodeBlend2.new();upper.filter_enabled=true
	var reference=p.animator.get_animation(clip_names["idle"])
	for index in reference.get_track_count():
		var path=reference.track_get_path(index);var bone=String(path).get_slice(":",1)
		if bone in ["Spine","Head"] or bone.begins_with("UpperArm.") or bone.begins_with("Forearm.") or bone.begins_with("Hand."):
			upper.set_filter_path(path,true)
	graph.add_node("UpperBody",upper);graph.connect_node("UpperBody",0,"Base");graph.connect_node("UpperBody",1,"UpperRate");graph.connect_node("output",0,"UpperBody")
	tree=AnimationTree.new();tree.name="MotionGraph";p.add_child(tree)
	tree.anim_player=tree.get_path_to(p.animator)
	tree.root_node=tree.get_path_to(p.animator.get_node(p.animator.root_node))
	tree.tree_root=graph
	tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active=true
	var curves="res://assets/characters/contact-curves-v5.json"
	if FileAccess.file_exists(curves):authored_contacts=JSON.parse_string(FileAccess.get_file_as_string(curves)).get("clips",{})

func duration(clip:String) -> float:
	return avatar.animator.get_animation(clip_names[clip]).length if clip_names.has(clip) else 1.0

func is_gait(clip:String) -> bool:
	return clip.begins_with("walk") or clip.begins_with("run") or clip.begins_with("basketball_jog") or clip.begins_with("football_jog")

func switch_base(clip:String):
	if not clip_names.has(clip):clip="idle"
	if base_clip==clip:return
	var retained=phase if is_gait(base_clip) and is_gait(clip) else 0.0
	base_side="B" if base_side=="A" else "A"
	nodes[base_side].animation=clip_names[clip]
	tree.set("parameters/"+base_side+"Seek/seek_request",retained*duration(clip))
	base_clip=clip;phase=retained;changes+=1

func update(dt:float):
	if not tree:return
	var p=avatar;var world=p.get_parent();var now=Time.get_ticks_msec()
	var speed=Vector2(p.velocity.x,p.velocity.z).length()
	grounded=p.is_on_floor() if world.host or p.local_player else bool(p.get_meta("authority_grounded",true))
	snapshot_tick=int(p.get_meta("snapshot_tick",world.tick))
	var zone=world.zone_at(p.position)
	var next_profile="BASKETBALL" if zone=="basketball" else ("FOOTBALL" if zone=="football" else ("OFFICE" if zone in ["meeting","resources","free","utility"] or zone.begins_with("office-") else "HOME"))
	if next_profile!=profile:
		profile=next_profile;profile_entries+=1
		if p.local_player:p.camera_rig.activity_profile(profile)
	posture=p.posture
	state_age+=dt
	var next_motion=locomotion
	if not grounded and absf(p.velocity.y)>.5:next_motion="jump" if p.velocity.y>1.0 else "air"
	elif locomotion in ["jump","air"]:next_motion="idle" if speed<.18 else "walk"
	elif locomotion=="idle" and speed>.20:next_motion="run" if speed>3.7 else "walk"
	elif locomotion!="idle" and speed<.09:next_motion="idle"
	elif locomotion=="walk" and speed>3.7:next_motion="run"
	elif locomotion=="run" and speed<3.15:next_motion="walk"
	if next_motion!=locomotion and (state_age>=.12 or next_motion in ["jump","air"]):locomotion=next_motion;state_age=0.0
	var local_velocity=p.global_basis.inverse()*Vector3(p.velocity.x,0,p.velocity.z)
	if speed>.2:
		var side_ratio=absf(local_velocity.x)/maxf(.05,absf(local_velocity.z))
		if side_ratio>1.35:direction="_right" if local_velocity.x>0 else "_left"
		elif side_ratio<.8:direction="_back" if local_velocity.z>.2 else ""
	else:direction=""
	var desired=locomotion+direction if locomotion in ["walk","run"] else locomotion
	var sleeping=posture in ["lying","sleeping"]
	if p.seated!="":desired="sleep_idle" if sleeping else "sit_idle"
	elif p.crouching:desired="crouch"
	elif locomotion=="idle" and profile in ["BASKETBALL","FOOTBALL"]:desired=profile.to_lower()+"_ready" if clip_names.has(profile.to_lower()+"_ready") else "idle"
	elif locomotion in ["walk","run"] and profile in ["BASKETBALL","FOOTBALL"] and direction=="":desired=profile.to_lower()+"_jog" if clip_names.has(profile.to_lower()+"_jog") else desired
	var turn_rate=angle_difference(previous_yaw,p.rotation.y)/maxf(.001,dt)
	previous_yaw=p.rotation.y
	if profile in ["BASKETBALL","FOOTBALL"] and locomotion=="idle" and absf(turn_rate)>.5 and p.seated=="":
		desired=profile.to_lower()+"_pivot_"+("left" if turn_rate>0 else "right")
	if grounded and not previous_grounded and p.seated=="":transition_clip="land";transition_left=.22
	previous_grounded=grounded
	if posture!=previous_posture:
		transition_clip="sleep_enter" if sleeping else ("wake" if previous_posture in ["lying","sleeping"] else ("sit_enter" if p.seated!="" else "sit_exit"))
		transition_left=duration(transition_clip);previous_posture=posture
	if transition_left>0:
		desired=transition_clip;transition_left=maxf(0,transition_left-dt)
	upper_body="";one_shot=""
	var kind=String(world.definitions.get(p.holding,{}).get("kind",""))
	if p.holding!="":upper_body={"gun":"aim","shield":"shield","book":"book_read","chair":"carry_heavy","table":"carry_heavy","low_table":"carry_heavy"}.get(kind,"carry")
	if kind=="basketball" and p.get_meta("dribble",false):upper_body="dribble_left" if p.get_meta("dribble_left",false) else "dribble"
	var activity=String(p.get_meta("activity",""))
	if activity=="broadcast":upper_body="broadcast"
	elif activity=="book":upper_body="book_read"
	elif activity in ["workspace","report","documents","brainstorm","mindmap","meeting"] and p.seated!="":upper_body="work"
	var gesture=String(p.get_meta("gesture","")) if now<int(p.get_meta("gesture_until",0)) else (p.remote_gesture if not world.host and not p.local_player else "")
	if gesture!="":
		one_shot=gesture
		if gesture in ["ko","respawn","kick","foot_pass","foot_steal"] and p.seated=="":desired=gesture
		elif gesture!="foot_touch":upper_body=gesture
	if p.get_meta("ko",false):desired="ko";upper_body=""
	if sleeping:upper_body=""
	if debug_mode=="ik_only":desired="idle";upper_body=""
	switch_base(desired)
	var target_rate=clampf(speed/(5.2 if locomotion=="run" else 3.1),.55,1.6) if is_gait(base_clip) else 1.0
	playback_rate=lerpf(playback_rate,target_rate,1-exp(-dt*9))
	base_mix=move_toward(base_mix,1.0 if base_side=="B" else 0.0,dt/.14)
	tree.set("parameters/Base/blend_amount",base_mix)
	tree.set("parameters/"+base_side+"Rate/scale",playback_rate)
	var stamp=int(p.get_meta("gesture_until",0)) if world.host or p.local_player else int(p.get_meta("remote_action_stamp",0))
	if upper_body!="" and clip_names.has(upper_body):
		if upper_clip!=upper_body or (one_shot!="" and (last_action!=one_shot or stamp!=last_action_stamp)):
			upper_clip=upper_body;nodes.Upper.animation=clip_names[upper_clip];tree.set("parameters/UpperSeek/seek_request",0.0)
			last_action=one_shot;last_action_stamp=stamp;action_id=one_shot+":"+str(stamp)
	upper_mix=move_toward(upper_mix,1.0 if upper_body!="" and clip_names.has(upper_body) else 0.0,dt/.12)
	tree.set("parameters/UpperBody/blend_amount",upper_mix)
	tree.set("parameters/UpperRate/scale",1.0)
	tree.advance(dt)
	phase=fposmod(phase+dt*playback_rate/maxf(.001,duration(base_clip)),1.0) if avatar.animator.get_animation(clip_names[base_clip]).loop_mode!=Animation.LOOP_NONE else minf(1,phase+dt*playback_rate/maxf(.001,duration(base_clip)))
	p.last_clip=String(clip_names[base_clip])

func contact_weight(side:String) -> float:
	if not grounded or posture!="standing" or base_clip in ["jump","air","kick","ko","respawn"]:return 0.0
	if not is_gait(base_clip):return 1.0 if base_clip in ["idle","basketball_ready","football_ready"] else .0
	var curve=authored_contacts.get(base_clip,{}).get(side,[])
	if curve.size()<2:return 0.0
	for i in range(1,curve.size()):
		if phase<=float(curve[i][0]):return lerpf(float(curve[i-1][1]),float(curve[i][1]),inverse_lerp(float(curve[i-1][0]),float(curve[i][0]),phase))
	return float(curve[-1][1])

func diagnostics() -> Dictionary:
	return {"profile":profile,"profileEntries":profile_entries,"locomotion":locomotion,"posture":posture,"upperBody":upper_body,"oneShot":one_shot,"clip":base_clip,"phase":phase,"speedScale":playback_rate,"grounded":grounded,"changes":changes,"actionId":action_id,"snapshotTick":snapshot_tick,"mode":debug_mode,"contactL":contact_weight("L"),"contactR":contact_weight("R")}
