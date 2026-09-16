"""Additional authored directional, tool, domestic and sports clips. No mesh replacement."""
import bpy,math,json
from mathutils import Quaternion,Vector
from pathlib import Path
R=Path(__file__).resolve().parents[1];scene=bpy.data.scenes['HomeOffice_V3_Character'];bpy.context.window.scene=scene
arm=next(o for o in scene.objects if o.type=='ARMATURE');body=next(o for o in scene.objects if o.type=='MESH' and o.name.startswith('Male_Standing'))
carry={'UpperArm.L':-.75,'UpperArm.R':-.75,'Forearm.L':-.75,'Forearm.R':-.75}
sit={'Hips.z':-.36,'Thigh.L':-1.35,'Thigh.R':-1.35,'Shin.L':1.4,'Shin.R':1.4}
a={'Thigh.L':-.40,'Thigh.R':.32,'Shin.L':.12,'Shin.R':.60,'UpperArm.L':.22,'UpperArm.R':-.22}
b={'Thigh.R':-.40,'Thigh.L':.32,'Shin.R':.12,'Shin.L':.60,'UpperArm.R':.22,'UpperArm.L':-.22}
clips={}
def add(name,seconds,loop,keys):clips[name]=(seconds,loop,keys)
for direction,angle in [('back',math.pi),('left',math.pi/2),('right',-math.pi/2)]:
 for speed,sec in [('walk',.92),('run',.64)]:
  def rotated(p):return {**p,'Hips.yaw':angle,'Spine.yaw':-angle*.4,'Head.yaw':-angle*.25}
  add(speed+'_'+direction,sec,True,[(0,rotated(a)),(.25,rotated({})),(.5,rotated(b)),(.75,rotated({})),(1,rotated(a))])
add('start',.25,False,[(0,{}),(1,{**a,'Spine':.12})]);add('stop',.3,False,[(0,b),(1,{})])
for side,sign in [('left',1),('right',-1)]:add('turn_'+side,.4,True,[(0,{'Hips.yaw':-.12*sign,'Shin.L':.2}),(.5,{'Hips.yaw':.12*sign,'Shin.R':.2}),(1,{'Hips.yaw':-.12*sign,'Shin.L':.2})])
add('air',.8,True,[(0,{'Thigh.L':-.2,'Thigh.R':-.3,'Shin.L':.35,'Shin.R':.5}),(1,{'Thigh.L':-.2,'Thigh.R':-.3,'Shin.L':.35,'Shin.R':.5})])
add('stairs',.9,True,[(0,{**a,'Thigh.L':-.85,'Shin.L':1}),(.5,{**b,'Thigh.R':-.85,'Shin.R':1}),(1,{**a,'Thigh.L':-.85,'Shin.L':1})])
add('carry_heavy',1.3,True,[(0,{**carry,'Spine':.18,'Thigh.L':-.1,'Thigh.R':-.1}),(.5,{**carry,'Spine':.2,'Thigh.L':-.1,'Thigh.R':-.1}),(1,{**carry,'Spine':.18,'Thigh.L':-.1,'Thigh.R':-.1})])
add('book_read',2.5,True,[(0,{**carry,'Head':.22}),(.5,{**carry,'Head':.27,'Forearm.R':-.85}),(1,{**carry,'Head':.22})])
for name in ['marker_write','marker_erase','clean']:
 add(name,1,True,[(0,{'UpperArm.R':-1.25,'Forearm.R':-.2}),(.5,{'UpperArm.R':-1.1,'Forearm.R':-.45}),(1,{'UpperArm.R':-1.25,'Forearm.R':-.2})])
shield={**carry,'UpperArm.L':-1.0,'Forearm.L':-1.4,'Spine':.1}
add('shield',1.5,True,[(0,shield),(1,shield)]);add('block',.3,False,[(0,shield),(.4,{**shield,'Spine':-.08}),(1,shield)])
add('crossover',.65,False,[(0,{'UpperArm.R':-.8,'Forearm.R':-.6}),(.5,{'UpperArm.R':-.5,'UpperArm.L':-.65}),(1,{'UpperArm.L':-.8,'Forearm.L':-.6})])
add('dribble_left',.6,True,[(0,{'UpperArm.L':-.7,'Forearm.L':-.7}),(.45,{'UpperArm.L':-.5,'Forearm.L':0}),(1,{'UpperArm.L':-.7,'Forearm.L':-.7})])
for name,angle in [('foot_touch',-.28),('receive',-.18),('foot_pass',-.6),('foot_steal',-.5)]:add(name,.45,False,[(0,{'Shin.R':.35}),(0.45,{'Thigh.R':angle,'Shin.R':.1}),(1,{})])
add('sofa_relax',3,True,[(0,{**sit,'Spine':-.15}),(.5,{**sit,'Spine':-.13}),(1,{**sit,'Spine':-.15})])
add('broadcast',2,True,[(0,{'UpperArm.R':-.3,'Forearm.R':-.5}),(.5,{'UpperArm.R':-.45,'Forearm.R':-.7,'Head':.02}),(1,{'UpperArm.R':-.3,'Forearm.R':-.5})])
for name in ['door_use','drawer_use','plate','carry_food']:
 add(name,.7,name=='carry_food',[(0,carry),(.5,{**carry,'Spine':.2}),(1,carry)])
manifest_path=R/'assets/characters/animation-manifest-v3.json';manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
for name,(seconds,loop,keys) in clips.items():
 old=bpy.data.actions.get('v3_'+name)
 if old:bpy.data.actions.remove(old)
 action=bpy.data.actions.new('v3_'+name);action.use_fake_user=True;arm.animation_data.action=action
 for t,values in keys:
  for bone in arm.pose.bones:
   bone.rotation_mode='QUATERNION'
   bone.rotation_quaternion=Quaternion((0,1,0),values.get(bone.name+'.yaw',0))@Quaternion((1,0,0),values.get(bone.name,0))
   bone.location=Vector((0,values.get(bone.name+'.z',0),0));frame=1+round(t*seconds*30)
   bone.keyframe_insert('rotation_quaternion',frame=frame,group=bone.name);bone.keyframe_insert('location',frame=frame,group=bone.name)
 manifest['clips']=[c for c in manifest['clips'] if c['name']!='v3_'+name]
 manifest['clips'].append({'name':'v3_'+name,'seconds':seconds,'loop':loop,'rootMotion':False,'bones':13,'source':'Authored Blender poses on inherited male mesh','validation':'Engine import and pose/contact simulation required','transition':'Avatar animation state selects by speed, direction, tool and action'})
manifest['limitations']=['Inherited 13-bone rig has no fingers. Runtime analytic hand/foot contact modifier supplements authored clips.']
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
arm.animation_data.action=bpy.data.actions['v3_idle'];scene.frame_set(1)
for o in bpy.context.view_layer.objects:o.select_set(False)
arm.select_set(True);body.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/male-character-v3.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/characters/male-animated-v3.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True)
print('Authored clip count:',len(manifest['clips']))
