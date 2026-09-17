"""Additive conference finish. Preserves the open Blender scene and existing game topology."""
import bpy, math, json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
old_scene=bpy.context.window.scene
scene=bpy.data.scenes.new('COMMONS_Meeting_V4')
bpy.context.window.scene=scene
materials={}
def material(name,color,roughness,metal=0):
 m=bpy.data.materials.new('COMMONS_'+name);m.use_nodes=True
 node=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
 node.inputs['Base Color'].default_value=(*color,1)
 node.inputs['Roughness'].default_value=roughness;node.inputs['Metallic'].default_value=metal
 materials[name]=m;return m
material('Oak',(.34,.215,.115),.58)
material('Edge',(.18,.105,.052),.65)
material('Graphite',(.032,.048,.05),.34,.7)
material('Fabric',(.09,.17,.17),.94)
material('Linen',(.48,.53,.47),.98)
material('Stone',(.52,.54,.48),.8)
material('Diffuser',(.87,.87,.72),.42)
material('Bronze',(.33,.23,.12),.30,.75)
def pos(p):return (p[0],-p[2],p[1])
def box(name,p,size,mat,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos(p));o=bpy.context.object;o.name=name
 o.scale=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(materials[mat])
 if bevel:
  mod=o.modifiers.new('Physical edge radius','BEVEL');mod.width=min(bevel,min(size)*.4);mod.segments=3
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def export(file):
 import importlib.util
 spec=importlib.util.spec_from_file_location('commons_pack',R/'art/pack_export.py')
 module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
 module.pack_scene(scene,file)
# A single usable conference table; original desks retain object IDs and computer controls in Godot.
box('ConferenceTop',(6.5,.81,8.15),(3.16,.12,6.3),'Oak',.055)
box('ConferenceEdge',(6.5,.733,8.15),(3.02,.035,6.16),'Edge',.012)
for z in [6.15,10.05]:
 box('Pedestal',(6.5,.34,z),(.38,.68,.80),'Graphite',.07)
 box('PedestalFoot',(6.5,.035,z),(1.75,.07,.70),'Graphite',.03)
for z in [6.5,8.1,9.7]:
 box('CablePort',(6.5,.874,z),(.15,.014,.32),'Graphite',.01)
 box('CablePortInsert',(6.5,.883,z),(.095,.005,.27),'Bronze',.003)
box('CableService',(6.5,.64,8.15),(.28,.12,5.3),'Graphite',.02)
# Material zones, actual geometry in metres. No extra solid walls or fake doors.
box('ConferenceCarpet',(6.5,.008,8.13),(7.2,.012,7.35),'Linen',.002)
for x in [3.0,10.0]:box('CarpetBorder',(x,.016,8.13),(.045,.006,7.22),'Fabric',.002)
for z in [4.5,11.7]:box('CarpetBorder',(6.5,.016,z),(7.0,.006,.045),'Fabric',.002)
for x in [3.0,6.4,10.5]:
 box('AcousticBacking',(x,1.85,4.115),(1.0,2.35,.032),'Fabric',.01)
 for n in range(8):box('OakSlat',(x-.43+n*.123,1.85,4.148),(.04,2.35,.03),'Oak',.007)
for x in [3.8,9.2]:
 box('SuspendedLight',(x,3.025,8.1),(.095,.075,5.3),'Graphite',.02)
 box('LinearDiffuser',(x,2.98,8.1),(.065,.014,5.2),'Diffuser',.004)
 for z in [5.5,10.7]:box('LightSuspension',(x,3.13,z),(.012,.16,.012),'Graphite',.003)
box('BoardPenTray',(4.5,.92,4.25),(3.1,.045,.22),'Graphite',.01)
for x in [2.0,10.95]:
 box('MeetingSkirting',(x,.065,8.15),(.04,.13,7.2),'Graphite',.008)
# Subtle felt wall panels at the rear, with a central architectural notice panel.
for x in [3.0,4.3,8.8,10.1]:box('RearFelt',(x,1.8,11.85),(1.0,1.65,.065),'Fabric',.03)
box('WayfindingPanel',(6.5,2.1,11.82),(2.4,.72,.08),'Stone',.03)
out=R/'assets/v4';out.mkdir(exist_ok=True)
export(out/'meeting-finish.glb')
bpy.data.libraries.write(str(R/'art/meeting-v4.blend'),{scene},fake_user=True)
count=len(scene.objects)
# An independent chair asset replaces only the meeting chair visuals, not their interaction bodies.
chair_scene=bpy.data.scenes.new('COMMONS_Meeting_Chair_V4');bpy.context.window.scene=chair_scene;scene=chair_scene
box('Seat',(0,.50,0),(.54,.12,.52),'Fabric',.08)
box('Back',(0,.81,.24),(.54,.56,.10),'Fabric',.04)
for x in [-.24,.24]:
 for z in [-.20,.20]:box('ChairLeg',(x,.24,z),(.026,.48,.026),'Graphite',.005)
 box('ArmSupport',(x,.57,.09),(.025,.25,.025),'Graphite',.005)
 box('Armrest',(x,.69,0),(.045,.04,.36),'Oak',.015)
export(out/'meeting-chair.glb')
bpy.data.libraries.write(str(R/'art/meeting-chair-v4.blend'),{chair_scene},fake_user=True)
bpy.context.window.scene=old_scene
(out/'meeting-manifest.json').write_text(json.dumps({'units':'metres, Godot Y up','table':{'center':[6.5,.81,8.15],'size':[3.16,.12,6.3]},'decorativeObjects':count,'preserved':'Existing room, doors, seats, original documents and board controls','quality':'Pending actual Godot WebGL review'},indent=2),encoding='utf-8')
print('COMMONS meeting finish authored:',count,'objects; existing Blender scene restored')
