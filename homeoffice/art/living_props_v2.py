"""BlenderMCP: beveled oak chest, sliding drawer, and a fabric floor lamp.
Preserves previous Blender scenes/files. Godot coordinates in metres.
"""
import bpy,json,os
from pathlib import Path
R=Path(os.environ.get('MOYEO_PROJECT',str(Path(bpy.data.filepath).parent.parent)))
exec(compile((R/'art/build_v2.py').read_text(encoding='utf8').split("begin('house')")[0],'living_helpers','exec'))
scene.name='Moyeo_V2_Interactive_Living_Props'
begin('storage')
box('bottom',(0,.11,0),(1.24,.12,.9),'walnut')
for x in [-.58,.58]:box('side',(x,.39,0),(.08,.56,.9),'oak')
for z in [-.41,.41]:box('face',(0,.39,z),(1.16,.56,.08),'oak')
for x in [-.45,.45]:
 for z in [-.29,.29]:cyl('foot',(x,.045,z),.055,.09,'metal')
box('latch',(0,.51,.465),(.10,.15,.025),'brass')
collisions.append(dict(position=[0,.36,0],size=[1.24,.72,.9],yaw=0))
finish('storage',{'lid_hinge':[0,.68,-.43],'handle':[0,.51,.48],'interior':[0,.31,0]},.008)
begin('storage_lid')
box('lid',(0,.025,.43),(1.28,.05,.94),'oak')
for x in [-.40,.40]:box('hinge',(x,-.01,.015),(.10,.04,.05),'brass')
finish('storage_lid',{},.009)
begin('drawer')
box('top',(0,.80,0),(.96,.055,.66),'oak')
box('back',(0,.46,-.285),(.90,.62,.055),'walnut')
for x in [-.43,.43]:box('side',(x,.46,0),(.06,.62,.62),'oak')
box('bottom',(0,.36,0),(.86,.045,.6),'oak')
for x in [-.36,.36]:
 for z in [-.22,.22]:box('leg',(x,.16,z),(.055,.32,.055),'metal')
collisions.append(dict(position=[0,.43,0],size=[.96,.86,.66],yaw=0))
finish('drawer',{'drawer_track':[0,.57,0],'handle':[0,.57,.365],'interior':[0,.54,0]},.007)
begin('drawer_slide')
box('front',(0,0,.30),(.85,.27,.055),'oak')
box('bottom',(0,-.12,0),(.82,.03,.56),'walnut')
for x in [-.4,.4]:box('side',(x,-.025,0),(.025,.20,.55),'oak')
box('back',(0,-.025,-.26),(.82,.20,.025),'oak')
for x in [-.13,.13]:box('handle mount',(x,0,.347),(.025,.025,.06),'brass')
box('handle',(0,0,.38),(.28,.025,.025),'brass')
finish('drawer_slide',{},.006)
begin('floor_lamp')
cyl('weighted base',(0,.03,0),.24,.06,'metal',24)
cyl('stem',(0,.72,0),.018,1.40,'brass',12)
cyl('fabric shade',(0,1.45,0),.245,.40,'cloth',32)
for y in [1.25,1.65]:cyl('piped shade rim',(0,y,0),.25,.024,'walnut',32)
cyl('switch',(0,.92,.035),.035,.028,'metal',12)
collisions.append(dict(position=[0,.85,0],size=[.5,1.7,.5],yaw=0))
finish('floor_lamp',{'switch':[0,.92,.06],'bulb':[0,1.36,0]},.003)
manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf8'));manifest['assets'].update(ASSETS)
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
for col in scene.collection.children:col.hide_viewport=False;col.hide_render=False
for i,(name,col) in enumerate([(c.name,c) for c in scene.collection.children]):
 for o in col.objects:o.location.x+=i*1.8
# Preview scene is laid out for inspection; GLBs above retain exact origin/anchors.
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/v2-living-props.blend'))
print(json.dumps({'produced':list(ASSETS),'source':str(R/'art/v2-living-props.blend')},ensure_ascii=False))
