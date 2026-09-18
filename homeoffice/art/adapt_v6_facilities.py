"""Batch static retained facilities without merging animated lids/water/on-air panels."""
import bpy, io_scene_gltf2, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.get('COMMONS_V6_Retained_Facilities') or bpy.data.scenes.new('COMMONS_V6_Retained_Facilities')
bpy.context.window.scene=scene
for ob in list(scene.objects):bpy.data.objects.remove(ob,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/v2/campus-details-v3.glb'))
before=len(scene.objects);groups={}
for ob in scene.objects:
    if ob.type!='MESH' or ob.name.startswith(('ToiletLid_','Water_','OnAir')):continue
    key=tuple(m.name for m in ob.data.materials)
    groups.setdefault(key,[]).append(ob)
for index,items in enumerate(groups.values()):
    for ob in scene.objects:ob.select_set(False)
    for ob in items:ob.select_set(True)
    bpy.context.view_layer.objects.active=items[0]
    if len(items)>1:bpy.ops.object.join()
    items[0].name='V6StaticFacilities_'+str(index)
formats=[]
for cls in io_scene_gltf2.ExportGLTF2.__mro__:
    prop=getattr(cls,'__annotations__',{}).get('export_format')
    if prop:
        items=prop.keywords['items'];formats=items(None,bpy.context) if callable(items) else items
fmt=next(i[0] for i in formats if '.glb' in i[1])
for ob in scene.objects:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/v6/facilities-v6.glb'),export_format=fmt,use_selection=True,use_active_scene=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/retained-facilities-v6.blend'),copy=True)
print(json.dumps({'beforeNodes':before,'afterNodes':len(scene.objects),'preservedDynamic':[o.name for o in scene.objects if not o.name.startswith('V6Static')]}))
