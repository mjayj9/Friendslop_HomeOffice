"""Pack our static conference geometry for WebGL; retain separate authoring objects."""
import bpy
def pack_scene(source,filepath):
 import io_scene_gltf2
 formats={item[0] for item in io_scene_gltf2.get_format_items(None,bpy.context)}
 if 'GLB' not in formats:raise RuntimeError('GLB export unavailable')
 previous=bpy.context.window.scene
 packed=bpy.data.scenes.new('__COMMONS_EXPORT_'+source.name)
 try:
  bpy.context.window.scene=packed
  for obj in source.objects:
   if obj.type!='MESH':continue
   copy=obj.copy();copy.data=obj.data.copy();packed.collection.objects.link(copy);copy.select_set(True)
  if not packed.objects:raise RuntimeError('No authored meshes')
  bpy.context.view_layer.objects.active=next(iter(packed.objects))
  bpy.ops.object.join()
  merged=bpy.context.view_layer.objects.active;merged.name='COMMONS_StaticMaterialGroups'
  bpy.ops.export_scene.gltf(filepath=str(filepath),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
  print(source.name,'authoring objects',len(source.objects),'export objects',len(packed.objects),'materials',len(merged.data.materials))
 finally:
  bpy.context.window.scene=previous
  # Only this function's new scratch scene is removed; user's scenes are retained.
  for obj in list(packed.objects):bpy.data.objects.remove(obj,do_unlink=True)
  bpy.data.scenes.remove(packed)
