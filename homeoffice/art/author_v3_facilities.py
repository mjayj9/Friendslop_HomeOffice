"""Additive HOME/OFFICE detail assets in world metres; original scenes preserved."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.new('HomeOffice_V3_Facilities');bpy.context.window.scene=scene
palette={'oak':(.31,.19,.10,1),'cream':(.87,.86,.79,1),'metal':(.045,.065,.065,1),'screen':(.025,.07,.075,1),'teal':(.12,.27,.27,1),'water':(.24,.65,.83,1),'red':(.75,.06,.03,1),'ceramic':(.91,.93,.91,1),'fabric':(.38,.47,.44,1)}
mats={}
for name,color in palette.items():
 m=bpy.data.materials.new('V3_'+name);m.use_nodes=True;n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');n.inputs['Base Color'].default_value=color;n.inputs['Roughness'].default_value=.45;mats[name]=m
def pos(p):return (p[0],-p[2],p[1])
def box(name,p,size,material):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos(p));o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[material]);return o
def cylinder(name,p,r,h,material):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=h,location=pos(p));o=bpy.context.object;o.name=name;o.data.materials.append(mats[material]);return o
def label(name,text,p,size,material,rotation=(math.pi/2,0,0)):
 curve=bpy.data.curves.new(name,'FONT');curve.body=text;curve.size=size;curve.align_x='CENTER';o=bpy.data.objects.new(name,curve);scene.collection.objects.link(o);o.location=pos(p);o.rotation_euler=rotation;o.data.materials.append(mats[material]);return o
# Work computers, conference desk accessories and acoustic panels.
for i,z in enumerate([7,9.4]):
 cylinder('MonitorStand'+str(i),(6.5,.96,z-.3),.025,.25,'metal')
 box('MonitorFoot'+str(i),(6.5,.845,z-.3),(.3,.025,.18),'metal')
 box('ComputerScreen'+str(i),(6.5,1.2,z-.35),(.62,.38,.045),'metal')
 box('DisplayGlass'+str(i),(6.5,1.2,z-.32),(.56,.32,.008),'screen')
 box('Keyboard'+str(i),(6.5,.852,z+.1),(.4,.025,.14),'metal')
 for row in range(3):
  for col in range(12):box('Key',(6.32+col*.031,.87,z+.054+row*.037),(.024,.008,.026),'cream')
 cylinder('TableMicrophone'+str(i),(6.98,1.02,z),.026,.30,'metal')
for x in [3.5,6.5,9.5]:
 for z in [6,8.5,11]:box('AcousticCeiling',(x,3.16,z),(1.4,.10,1.1),'fabric')
label('OfficeSign','OFFICE',(3.1,2.55,11.82),.24,'teal')
label('HomeSign','HOME',(-7,2.55,11.82),.24,'oak')
# Bathroom fixtures, with individually named moving lid/water parts.
for tag,x,y,z in [('ground',12.,0.,-10.),('upper',-12.,3.6,9.)]:
 cylinder('ToiletBase_'+tag,(x,y+.23,z),.18,.46,'ceramic')
 box('ToiletBowl_'+tag,(x,y+.47,z),(.40,.14,.54),'ceramic')
 box('ToiletTank_'+tag,(x,y+.69,z-.32),(.44,.62,.19),'ceramic')
 box('ToiletLid_'+tag,(x,y+.56,z),(.40,.045,.53),'cream')
 cylinder('FlushButton_'+tag,(x+.10,y+1.02,z-.32),.025,.02,'metal')
 box('Washstand_'+tag,(x+1.35,y+.4,z),(.90,.8,.48),'oak')
 box('Basin_'+tag,(x+1.35,y+.84,z),(.94,.09,.54),'ceramic')
 cylinder('Tap_'+tag,(x+1.35,y+1.01,z-.14),.025,.32,'metal')
 box('TapSpout_'+tag,(x+1.35,y+1.16,z-.04),(.05,.04,.24),'metal')
 cylinder('Water_'+tag,(x+1.35,y+1.,z+.05),.014,.24,'water')
 box('Mirror_'+tag,(x+1.35,y+1.65,z-.29),(.84,.70,.025),'teal')
 box('Towel_'+tag,(x+.75,y+1.0,z+.25),(.30,.45,.025),'fabric')
 box('ShowerTray_'+tag,(x-1.7,y+.03,z),(1.1,.06,1.1),'ceramic')
 cylinder('ShowerDrain_'+tag,(x-1.7,y+.068,z),.055,.01,'metal')
 cylinder('ShowerPipe_'+tag,(x-2.15,y+1.15,z-.48),.018,2.2,'metal')
# Broadcast corner, a real desk, mic and acoustic separation within OFFICE utility.
box('BroadcastDesk',(5,.74,-9.8),(2.4,.12,.9),'oak')
for x in [4,6]:box('BroadcastLeg',(x,.35,-9.8),(.10,.7,.7),'metal')
cylinder('BroadcastMicStand',(5,1.,-9.7),.035,.52,'metal')
cylinder('BroadcastMicrophone',(5,1.35,-9.7),.07,.20,'metal')
box('BroadcastConsole',(5.65,.85,-9.65),(.65,.08,.35),'metal')
for i in range(4):cylinder('Fader',(5.43+i*.14,.91,-9.60),.028,.04,'cream')
box('OnAir',(5,2.4,-11.88),(1.6,.42,.07),'red')
label('OnAirText','ON AIR',(5,2.3,-11.82),.25,'cream')
for x in [2.3,3.7,6.3,7.7]:box('BroadcastAcoustic',(x,1.8,-11.86),(1.0,1.5,.10),'fabric')
label('BroadcastSign','BROADCAST',(5,2.8,-8.8),.22,'teal')
for tag,p in [('home',(-5.1,1.25,10.2)),('office',(1.65,1.25,10.2)),('bath',(10.8,1.25,-6.2))]:
 box('Switch_'+tag,p,(.12,.18,.04),'cream')
# Save and export the additive asset only.
for o in bpy.data.objects:o.select_set(False)
for o in scene.objects:o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/campus-details-v3.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/v2/campus-details-v3.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
print('V3 facilities:',len(scene.objects),'objects; additive asset exported')
