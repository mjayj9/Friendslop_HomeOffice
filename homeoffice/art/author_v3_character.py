"""Authored key poses on the existing male rig; run in the V3 Blender scene.

Preserves the original mesh and rig. Clips are new work, not original animations.
No root-motion translation: the Godot controller owns world movement.
"""
import bpy, json, math
from pathlib import Path
from mathutils import Quaternion, Vector

ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes['HomeOffice_V3_Character']
bpy.context.window.scene=scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.type=='MESH' and o.name.startswith('Male_Standing'))
scene.render.fps=30
arm.animation_data_create()

# Smooth the original rigid one-bone groups near knees/elbows/hips.
# Vertices elsewhere retain their original assignment and exact coordinates.
for vertex in body.data.vertices:
    weights={body.vertex_groups[g.group].name:g.weight for g in vertex.groups}
    x,y,z=vertex.co
    side='L' if x>=0 else 'R'
    pairs=[]
    if abs(x)>.195 and .98<z<1.28:pairs=[('UpperArm.'+side,'Forearm.'+side,1.14,.12)]
    elif abs(x)<.21 and .36<z<.58:pairs=[('Thigh.'+side,'Shin.'+side,.47,.11)]
    for top,bottom,centre,width in pairs:
        if weights.get(top,0)+weights.get(bottom,0)<.9:continue
        t=max(0,min(1,(z-(centre-width))/(2*width)));t=t*t*(3-2*t)
        body.vertex_groups[top].add([vertex.index],t,'REPLACE')
        body.vertex_groups[bottom].add([vertex.index],1-t,'REPLACE')

def pose(**values):return values
idle={}
carry={'UpperArm.L':-.75,'UpperArm.R':-.75,'Forearm.L':-.75,'Forearm.R':-.75}
sit={'Hips.z':-.36,'Thigh.L':-1.35,'Thigh.R':-1.35,'Shin.L':1.4,'Shin.R':1.4,'Spine':.05}
sleep={'Hips.z':-.11,'Hips.xrot':math.pi/2,'UpperArm.L':-.1,'UpperArm.R':-.1}
aim={**carry,'UpperArm.L':-1.1,'UpperArm.R':-1.15,'Forearm.L':-.25,'Forearm.R':-.20}
crouch={'Hips.z':-.32,'Thigh.L':-.8,'Thigh.R':-.8,'Shin.L':1.35,'Shin.R':1.35,'Spine':.2}
walk_a={'Thigh.L':-.48,'Thigh.R':.38,'Shin.L':.15,'Shin.R':.65,'UpperArm.L':.27,'UpperArm.R':-.27}
walk_b={'Thigh.R':-.48,'Thigh.L':.38,'Shin.R':.15,'Shin.L':.65,'UpperArm.R':.27,'UpperArm.L':-.27}
clips={
 'idle':(2.0,True,[(0,idle),(.5,{'Spine':.015}),(1,idle)]),
 'walk':(.92,True,[(0,walk_a),(.25,{}),(.5,walk_b),(.75,{}),(1,walk_a)]),
 'run':(.64,True,[(0,{**walk_a,'Spine':.16}),(.25,{'Hips.z':.06}),(.5,{**walk_b,'Spine':.16}),(.75,{'Hips.z':.06}),(1,{**walk_a,'Spine':.16})]),
 'crouch':(1.1,True,[(0,crouch),(1,crouch)]),
 'jump':(.65,False,[(0,crouch),(.25,{'UpperArm.L':-.6,'UpperArm.R':-.6}),(.7,{'Thigh.L':-.3,'Thigh.R':-.3,'Shin.L':.65,'Shin.R':.65}),(1,idle)]),
 'land':(.25,False,[(0,crouch),(1,idle)]),
 'carry':(1,True,[(0,carry),(1,carry)]),
 'pickup':(.65,False,[(0,idle),(.5,{**carry,'Spine':.55,'Hips.z':-.15}),(1,carry)]),
 'drop':(.45,False,[(0,carry),(.5,{'UpperArm.L':-.35,'UpperArm.R':-.35}),(1,idle)]),
 'throw':(.5,False,[(0,carry),(.3,{'UpperArm.R':-2,'Forearm.R':-1}),(.6,{'UpperArm.R':-1.2,'Forearm.R':0}),(1,idle)]),
 'sit_enter':(.9,False,[(0,idle),(.35,{'Spine':.25,'Hips.z':-.12}),(1,sit)]),
 'sit_idle':(2,True,[(0,sit),(.5,{**sit,'Spine':.07}),(1,sit)]),
 'sit_exit':(.8,False,[(0,sit),(.5,{**crouch,'Spine':.4}),(1,idle)]),
 'sleep_enter':(1.4,False,[(0,sit),(.4,{**sit,'Hips.xrot':.5}),(1,sleep)]),
 'sleep_idle':(3,True,[(0,sleep),(.5,{**sleep,'Spine':.012}),(1,sleep)]),
 'wake':(1.2,False,[(0,sleep),(.6,sit),(1,idle)]),
 'aim':(1,True,[(0,aim),(1,aim)]),
 'fire':(.22,False,[(0,aim),(.3,{**aim,'UpperArm.R':-1.25,'Spine':-.035}),(1,aim)]),
 'reload':(1.4,False,[(0,aim),(.4,{**carry,'UpperArm.L':-.9,'Forearm.L':-1.5}),(.7,carry),(1,aim)]),
 'hit':(.3,False,[(0,idle),(.35,{'Spine':-.15}),(1,idle)]),
 'ko':(.6,False,[(0,idle),(.5,crouch),(1,sit)]),
 'respawn':(.6,False,[(0,sit),(1,idle)]),
 'dribble':(.6,True,[(0,{'UpperArm.R':-.7,'Forearm.R':-.7}),(.45,{'UpperArm.R':-.5,'Forearm.R':0}),(1,{'UpperArm.R':-.7,'Forearm.R':-.7})]),
 'pass':(.5,False,[(0,carry),(.5,{'UpperArm.L':-1.2,'UpperArm.R':-1.2}),(1,idle)]),
 'shot':(.85,False,[(0,carry),(.4,{'UpperArm.L':-2.1,'UpperArm.R':-2.1,'Forearm.L':-1,'Forearm.R':-1}),(.7,{'UpperArm.L':-2.6,'UpperArm.R':-2.6}),(1,{'UpperArm.L':-2.2,'UpperArm.R':-2.2})]),
 'steal':(.55,False,[(0,idle),(.4,{'UpperArm.R':-1.3,'Spine':.25}),(1,idle)]),
 'kick':(.55,False,[(0,{'Thigh.R':.55,'Shin.R':.7}),(.45,{'Thigh.R':-.85,'Shin.R':.1}),(1,idle)]),
 'work':(2,True,[(0,{**sit,**carry}),(.5,{**sit,**carry,'Forearm.R':-.85}),(1,{**sit,**carry})]),
 'switch':(.6,False,[(0,idle),(.5,{'UpperArm.R':-1.25}),(1,idle)]),
 'cook':(1.5,True,[(0,carry),(.5,{**carry,'Forearm.R':-.3}),(1,carry)]),
 'eat':(1.5,True,[(0,{**sit,**carry}),(.5,{**sit,'UpperArm.R':-1.15,'Forearm.R':-1.6}),(1,{**sit,**carry})]),
}
manifest=[]
for name,(seconds,loop,keys) in clips.items():
    action=bpy.data.actions.new('v3_'+name);arm.animation_data.action=action;action.use_fake_user=True
    end=round(seconds*30)+1
    for t,values in keys:
        frame=1+round(t*(end-1))
        for bone in arm.pose.bones:
            bone.rotation_mode='QUATERNION'
            angle=values.get(bone.name,0)+values.get(bone.name+'.xrot',0)
            bone.rotation_quaternion=Quaternion((1,0,0),angle)
            bone.location=Vector((0,values.get(bone.name+'.z',0),0))
            bone.keyframe_insert('rotation_quaternion',frame=frame,group=bone.name)
            bone.keyframe_insert('location',frame=frame,group=bone.name)
    manifest.append({'name':'v3_'+name,'seconds':seconds,'loop':loop,'rootMotion':False,'bones':len(arm.pose.bones),'source':'New Blender keyframe poses on existing male rig','validation':'Pending in-game pose/contact review'})
arm.animation_data.action=bpy.data.actions['v3_idle'];scene.frame_set(1)
for o in scene.objects:o.select_set(False)
arm.select_set(True);body.select_set(True);bpy.context.view_layer.objects.active=arm
ROOT.joinpath('assets/characters/animation-manifest-v3.json').write_text(json.dumps({'clips':manifest,'limitations':['13-bone inherited rig; no finger articulation','Full contact/IK and motion quality still require review'],'originalAnimations':[]},indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/male-character-v3.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/characters/male-animated-v3.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True)
print('V3_AUTHORED',len(clips),'clips; preserved source mesh; saved new blend and animated GLB')
