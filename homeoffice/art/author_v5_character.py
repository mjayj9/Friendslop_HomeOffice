"""Run through the live Blender MCP on the preserved character work scene.
The original source blend and V3 GLB are never overwritten.
"""
import bpy, json, math, io_scene_gltf2
from pathlib import Path
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
scene = bpy.data.scenes['COMMONS_V5_Character_Work']
bpy.context.window.scene = scene
arm = next(o for o in scene.objects if o.type == 'ARMATURE')
body = next(o for o in scene.objects if o.type == 'MESH' and o.name.startswith('Male_Standing'))
original_vertices = [tuple(v.co) for v in body.data.vertices]
scene.render.fps = 30
manifest = json.loads((ROOT/'assets/characters/animation-manifest-v3.json').read_text(encoding='utf-8'))
ready = {
    'basketball': {'Hips.z': -.08, 'Thigh.L': -.32, 'Thigh.R': -.32, 'Shin.L': .58, 'Shin.R': .58, 'Spine': .10, 'UpperArm.L': -.3, 'UpperArm.R': -.3, 'Forearm.L': -.7, 'Forearm.R': -.7},
    'football': {'Hips.z': -.045, 'Thigh.L': -.23, 'Thigh.R': -.23, 'Shin.L': .41, 'Shin.R': .41, 'Spine': .08, 'UpperArm.L': -.16, 'UpperArm.R': -.16, 'Forearm.L': -.3, 'Forearm.R': -.3},
}
clips = {}
for sport, pose in ready.items():
    clips[sport+'_ready'] = (1.8, True, [(0,pose),(.5,{**pose,'Spine':pose['Spine']+.012}),(1,pose)])
    a = {**pose,'Thigh.L':-.65,'Thigh.R':.30,'Shin.L':.18,'Shin.R':.88,'UpperArm.L':.25,'UpperArm.R':-.65}
    b = {**pose,'Thigh.R':-.65,'Thigh.L':.30,'Shin.R':.18,'Shin.L':.88,'UpperArm.R':.25,'UpperArm.L':-.65}
    clips[sport+'_jog'] = (.72, True, [(0,a),(.25,{**pose,'Hips.z':-.015}),(.5,b),(.75,{**pose,'Hips.z':-.015}),(1,a)])
    for side, sign in [('left',1),('right',-1)]:
        clips[sport+'_pivot_'+side] = (.42, True, [(0,pose),(.5,{**pose,'Hips.yaw':sign*.16,'Shin.L':.7 if sign>0 else .58,'Shin.R':.7 if sign<0 else .58}),(1,pose)])
for name,(seconds,loop,keys) in clips.items():
    action = bpy.data.actions.get('v5_'+name) or bpy.data.actions.new('v5_'+name)
    arm.animation_data.action = action
    action.use_fake_user = True
    end = round(seconds*30)+1
    for t, values in keys:
        frame = 1+round(t*(end-1))
        for bone in arm.pose.bones:
            bone.rotation_mode='QUATERNION'
            bone.rotation_quaternion=Quaternion((0,1,0), values.get(bone.name+'.yaw',0)) @ Quaternion((1,0,0), values.get(bone.name,0))
            bone.location=Vector((0, values.get(bone.name+'.z',0),0))
            bone.keyframe_insert('rotation_quaternion',frame=frame,group=bone.name)
            bone.keyframe_insert('location',frame=frame,group=bone.name)
    manifest['clips'].append({'name':'v5_'+name,'seconds':seconds,'loop':loop,'rootMotion':False,'source':'V5 authored no-ball readiness on preserved male rig','validation':'Requires game visual/contact review; clip existence is not acceptance'})

# Contact envelopes from evaluated ankle heights, with swing deliberately unpinned.
# They are authored hints, not proof of physically correct gait or foot speed.
curves={}
for action in bpy.data.actions:
    short=action.name.removeprefix('v3_').removeprefix('v5_')
    if not (short.startswith(('walk','run')) or short.endswith('_jog')):continue
    arm.animation_data.action=action
    start,end=action.frame_range
    samples={s:[] for s in ['L','R']}
    for i in range(33):
        frame=start+(end-start)*i/32
        scene.frame_set(int(frame),subframe=frame-int(frame))
        for side in samples:samples[side].append(float(arm.pose.bones['Foot.'+side].head.z))
    curves[short]={}
    for side, heights in samples.items():
        low=min(heights);high=max(heights)
        curves[short][side]=[[i/32,round(max(0,min(1,(low+.045-h)/.035)),4)] for i,h in enumerate(heights)]
    curves[short]['source']='Blender evaluated ankle-height envelope; no planted target during high swing'
assert original_vertices == [tuple(v.co) for v in body.data.vertices]
manifest['limitations']=['Inherited 13-bone rig has no fingers; foot stride/contact and body fitting require further visual review.']
(ROOT/'assets/characters/animation-manifest-v5.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
(ROOT/'assets/characters/contact-curves-v5.json').write_text(json.dumps({'version':1,'clips':curves},indent=2),encoding='utf-8')
arm.animation_data.action=bpy.data.actions['v5_basketball_ready'];scene.frame_set(1)
for obj in scene.objects:obj.select_set(False)
arm.select_set(True);body.select_set(True);bpy.context.view_layer.objects.active=arm
formats=[]
for cls in io_scene_gltf2.ExportGLTF2.__mro__:
    prop=getattr(cls,'__annotations__',{}).get('export_format')
    if prop:
        items=prop.keywords['items'];formats=items(None,bpy.context) if callable(items) else items
fmt=next(item[0] for item in formats if '.glb' in item[1])
valid_modes=[i.identifier for i in bpy.ops.export_scene.gltf.get_rna_type().properties['export_animation_mode'].enum_items]
mode=next(m for m in valid_modes if m=='ACTIONS')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/male-character-v5.blend'),copy=True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/characters/male-animated-v5.glb'),export_format=fmt,use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode=mode,export_force_sampling=True)
print('V5_DERIVED_CHARACTER',len(manifest['clips']),'clips; original vertex coordinates preserved; no original file overwritten')
