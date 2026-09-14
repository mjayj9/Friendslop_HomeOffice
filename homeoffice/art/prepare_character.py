import bpy,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice')
scene=bpy.data.scenes.new('Homeoffice_Character');bpy.context.window.scene=scene
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/characters/quaternius_cc0-male-character-1157.glb'))
models={o.name:o for o in scene.objects if o.type=='MESH'}
standing=next(o for n,o in models.items() if n.startswith('Male_Standing') and not any(s in n for s in ['Covering','Hips','Waving']))
seated=next(o for n,o in models.items() if n.startswith('Male_Sitting') and 'Cheering' not in n)
height=max(v.co.z for v in standing.data.vertices)-min(v.co.z for v in standing.data.vertices)
scale=1.78/height;floor=min(v.co.z for v in standing.data.vertices)
for obj in models.values():
    for v in obj.data.vertices:v.co=Vector((v.co.x*scale,v.co.y*scale,(v.co.z-floor)*scale))
    obj.location=(0,0,0)
def export(obj,name,extra=[]):
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
    for o in extra:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/characters'/name),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
export(seated,'male-seated.glb')
armdata=bpy.data.armatures.new('Homeoffice_anatomical_rig');arm=bpy.data.objects.new('MaleRig',armdata);scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
bones=[('Hips',(0,0,.80),(0,0,1.0),None),('Spine',(0,0,1.0),(0,0,1.36),'Hips'),('Head',(0,0,1.36),(0,0,1.75),'Spine')]
for side,s in [('L',1),('R',-1)]:
    bones += [(f'Thigh.{side}',(s*.12,0,.88),(s*.12,0,.47),'Hips'),(f'Shin.{side}',(s*.12,0,.47),(s*.12,0,.09),f'Thigh.{side}'),(f'Foot.{side}',(s*.12,0,.09),(s*.12,-.15,.07),f'Shin.{side}'),(f'UpperArm.{side}',(s*.24,0,1.38),(s*.25,0,1.14),'Spine'),(f'Forearm.{side}',(s*.25,0,1.14),(s*.27,0,.90),f'UpperArm.{side}')]
for name,head,tail,parent in bones:
    b=armdata.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=armdata.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
groups={name:standing.vertex_groups.new(name=name) for name,*_ in bones}
for v in standing.data.vertices:
    x,y,z=v.co;side='L' if x>0 else 'R'
    if z>1.42:key='Head'
    elif abs(x)>.225 and .82<z<1.40:key=('UpperArm.' if z>1.12 else 'Forearm.')+side
    elif z<.12:key='Foot.'+side
    elif z<.47:key='Shin.'+side
    elif z<.86:key='Thigh.'+side
    elif z<1.03:key='Hips'
    else:key='Spine'
    groups[key].add([v.index],1,'REPLACE')
mod=standing.modifiers.new('New procedural skeleton','ARMATURE');mod.object=arm;standing.parent=arm
export(standing,'male-rigged.glb',[arm])
for o in models.values():o.hide_render=o!=standing
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/male-character.blend'))
report={'source':'quaternius_cc0-male-character-1157.glb','selected':'Male_Standing','originalHeight':height,'scale':scale,'heightM':1.78,'origin':'feet centered, grounded','forward':'Blender -Y, glTF +Z; runtime rotates PI','originalSkeleton':False,'originalAnimations':[],'newSkeletonBones':list(groups),'method':'new coarse rigid anatomical weights + procedural walk/run/jump/hold; supplied static seated mesh','limitations':['coarse rig, no smooth shoulder retargeting','seated source uses separate mesh','lie, get-up, basketball, aim are deferred']}
(ROOT/'docs/character-preparation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('CHARACTER_PREPARED',report)
