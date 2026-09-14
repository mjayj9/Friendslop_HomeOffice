import bpy,bmesh,json
from pathlib import Path
R=Path(__import__('os').environ.get('MOYEO_PROJECT', str(Path(bpy.data.filepath).parent.parent)))
scene=bpy.data.scenes.new('Moyeo_V2_Character');bpy.context.window.scene=scene
bpy.ops.import_scene.gltf(filepath=str(R/'assets/characters/male-rigged.glb'))
body=next(o for o in scene.objects if o.type=='MESH');arm=next(o for o in scene.objects if o.type=='ARMATURE')
def export(name,objs):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(R/'assets/characters'/name),use_selection=True,use_active_scene=True,export_format='GLB',export_animations=False)
lying=body.copy();lying.data=body.data.copy();scene.collection.objects.link(lying);lying.name='Male_Lying_V2';lying.parent=None
for m in list(lying.modifiers):lying.modifiers.remove(m)
for v in lying.data.vertices:
 x,y,z=v.co;v.co=(x,z-.85,.72-y)
export('male-lying.glb',[lying])
arms=body.copy();arms.data=body.data.copy();scene.collection.objects.link(arms);arms.name='Male_FirstPerson_Arms'
bm=bmesh.new();bm.from_mesh(arms.data);deform=bm.verts.layers.deform.active
arm_indices={g.index for g in arms.vertex_groups if 'Arm.' in g.name or 'Forearm.' in g.name}
remove=[v for v in bm.verts if not deform or not any(i in arm_indices and weight>.5 for i,weight in v[deform].items())]
bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(arms.data);bm.free()
export('male-arms.glb',[arms,arm])
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/male-character-v2.blend'))
(R/'docs/v2/character-methods.json').write_text(json.dumps({'source':'provided 1157 static male standing + seated','originalClips':[],'walkRun':'coarse new skeleton with runtime gait','sit':'provided seated static mesh','lieSleep':'standing mesh rotated in vertex space to bed anchor; new static pose','firstPersonArms':'original male arm vertices extracted with same skeleton; runtime procedural grip','stillRequired':['smooth sit/stand/lie transitions','precise two-bone hand IK and foot placement','authored/validated sport/cooking/shield/reload gestures']},ensure_ascii=False,indent=2),encoding='utf8')
print('V2_CHARACTER',len(arms.data.vertices),'arm vertices;',len(lying.data.vertices),'lying vertices')
