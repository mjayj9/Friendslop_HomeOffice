import bpy,json
from pathlib import Path
ROOT=Path(__import__('os').environ.get('MOYEO_PROJECT', str(Path(bpy.data.filepath).parent.parent)))
scene=bpy.data.scenes.new('Moyeo_V2_OptimizedFurniture')
bpy.context.window.scene=scene
results=[]
for kind in ['chair','table','sofa','book','crate','marker']:
 for o in list(scene.objects):scene.collection.objects.unlink(o)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/environment'/f'{kind}.glb'))
 objects=[o for o in scene.objects if o.type=='MESH']
 materials={}
 for obj in objects:
  for i,mat in enumerate(obj.data.materials):
   principled=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if mat.use_nodes else None
   key=tuple(round(v,5) for v in principled.inputs['Base Color'].default_value)+(round(principled.inputs['Roughness'].default_value,5),round(principled.inputs['Metallic'].default_value,5)) if principled else tuple(mat.diffuse_color)
   if key in materials:obj.data.materials[i]=materials[key]
   else:materials[key]=mat
 bpy.ops.object.select_all(action='DESELECT')
 for obj in objects:obj.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 before=len(objects)
 bpy.ops.object.join()
 mesh=bpy.context.active_object;mesh.name='V2_'+kind+'_batched'
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/v2'/f'{kind}.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_cameras=False,export_lights=False)
 results.append({'asset':kind,'sourceMeshes':before,'outputMeshes':1,'materials':len(mesh.data.materials),'triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons),'sourceUnchanged':True})
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/furniture-v2.blend'))
(ROOT/'docs/v2/furniture-optimization.json').write_text(json.dumps(results,indent=2),encoding='utf8')
print('FURNITURE_BATCHED',results)
