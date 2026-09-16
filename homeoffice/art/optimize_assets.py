import bpy,json
from pathlib import Path
ROOT=Path(r'C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice')
scene=next(s for s in bpy.data.scenes if s.name.startswith('Homeoffice_Production'))
bpy.context.window.scene=scene
for c in list(scene.collection.children):
    if not c.name.startswith('Asset_'):continue
    name=c.name[6:];c.hide_viewport=False
    objs=list(c.objects);groups={}
    for o in objs:
        if o.type=='MESH':groups.setdefault(o.data.materials[0].name,[]).append(o)
    for group in groups.values():
        bpy.ops.object.select_all(action='DESELECT')
        for o in group:o.select_set(True)
        bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join()
    bpy.ops.object.select_all(action='DESELECT')
    for o in c.objects:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/environment'/(name+'.glb')),use_selection=True,use_active_scene=True,export_format='GLB',export_apply=True,export_extras=True)
    c.hide_viewport=name!='architecture'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/homeoffice.blend'))
print('OPTIMIZED_ACTIVE_SCENE_ONLY')
