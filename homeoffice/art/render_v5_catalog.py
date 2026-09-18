"""Render real retained GLBs in a separate Blender scene; no source editing."""
import bpy, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.get('COMMONS_V5_Catalog') or bpy.data.scenes.new('COMMONS_V5_Catalog')
bpy.context.window.scene=scene
out=ROOT/'web/catalog';out.mkdir(parents=True,exist_ok=True)
camera=bpy.data.objects.get('V5_Catalog_Camera')
if not camera:
    camera=bpy.data.objects.new('V5_Catalog_Camera',bpy.data.cameras.new('V5_Catalog_Camera'));scene.collection.objects.link(camera)
camera.data.type=next(i.identifier for i in camera.data.bl_rna.properties['type'].enum_items if i.identifier=='ORTHO');scene.camera=camera
light=bpy.data.objects.get('V5_Catalog_Light')
if not light:
    light_type=next(i.identifier for i in bpy.data.lights.bl_rna.functions['new'].parameters['type'].enum_items if i.identifier=='AREA')
    light=bpy.data.objects.new('V5_Catalog_Light',bpy.data.lights.new('V5_Catalog_Light',light_type));scene.collection.objects.link(light)
light.data.energy=800;light.data.size=5
scene.render.resolution_x=192;scene.render.resolution_y=192;scene.render.resolution_percentage=100;scene.render.film_transparent=True
scene.render.image_settings.file_format=next(i.identifier for i in scene.render.image_settings.bl_rna.properties['file_format'].enum_items if i.identifier=='PNG')
scene.world=bpy.data.worlds.get('V5_Catalog_World') or bpy.data.worlds.new('V5_Catalog_World')
scene.world.use_nodes=True
background=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND');background.inputs['Color'].default_value=(.25,.3,.27,1);background.inputs['Strength'].default_value=.5
items=globals().get('CATALOG_BATCH',['chair','table','sofa','bed','book','crate','gun','shield','plate','storage','drawer','floor_lamp'])
for kind in items:
    for obj in list(scene.objects):
        if obj not in [camera,light]:bpy.data.objects.remove(obj,do_unlink=True)
    path=ROOT/'assets/v2'/f'{kind}.glb'
    if not path.exists():path=ROOT/'assets/environment'/f'{kind}.glb'
    bpy.ops.import_scene.gltf(filepath=str(path))
    bpy.context.view_layer.update()
    meshes=[o for o in scene.objects if o.type=='MESH']
    points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo=Vector([min(p[i] for p in points) for i in range(3)]);hi=Vector([max(p[i] for p in points) for i in range(3)]);centre=(lo+hi)*.5
    camera.location=centre+Vector((3,4 if kind=='sofa' else -4,2.7));camera.rotation_euler=(centre-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=max(hi-lo)*1.45
    light.location=centre+Vector((-2,-3,4));light.rotation_euler=(centre-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(out/f'{kind}.png');bpy.ops.render.render(write_still=True)
    print('THUMBNAIL',kind,str(path.relative_to(ROOT)),[round(x,3) for x in hi-lo])
