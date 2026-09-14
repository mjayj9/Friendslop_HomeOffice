"""Blender asset preview, deliberately separate from actual game captures."""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
R=Path(__import__('os').environ.get('MOYEO_PROJECT', str(Path(bpy.data.filepath).parent.parent)));layout=json.loads((R/'assets/v2/layout.json').read_text(encoding='utf8'))
scene=bpy.data.scenes.new('Moyeo_V2_Asset_Preview');bpy.context.window.scene=scene
def asset(kind,p=(0,0,0),yaw=0):
 path=R/'assets/v2'/f'{kind}.glb'
 if not path.exists():path=R/'assets/environment'/f'{kind}.glb'
 before=set(scene.objects);bpy.ops.import_scene.gltf(filepath=str(path));created=set(scene.objects)-before
 root=bpy.data.objects.new('Preview_'+kind,None);scene.collection.objects.link(root)
 for obj in created:
  if obj.parent not in created:obj.parent=root
 root.location=(p[0],-p[2],p[1]);root.rotation_euler.z=yaw
 return root
asset('house');asset('grounds')
for item in layout['furniture']:asset(item['kind'],item['p'],item['yaw'])
for i in range(2):
 if i%2==0:asset('gallery',(0,3.6,-12-(i//2)*5.4))
 asset('office_left' if i%2==0 else 'office_right',(0,3.6,-12-(i//2)*5.4))
camera_data=bpy.data.cameras.new('V2_Preview_Camera');camera=bpy.data.objects.new('V2_Preview_Camera',camera_data);scene.collection.objects.link(camera);camera.location=(57,-68,54);camera.rotation_euler=(Vector((7,-9,0))-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.type='ORTHO';camera_data.ortho_scale=80;scene.camera=camera
world=bpy.data.worlds.new('V2 Preview World');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.5,.61,.64,1);world.node_tree.nodes['Background'].inputs[1].default_value=.55;scene.world=world
light_data=bpy.data.lights.new('V2 Preview Sun','SUN');light=bpy.data.objects.new('V2 Preview Sun',light_data);scene.collection.objects.link(light);light.rotation_euler=(.45,-.5,-.6);light_data.energy=2
scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.render.resolution_x=1200;scene.render.resolution_y=850;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.filepath=str(R/'art/v2-blender-exterior-preview.png')
scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/v2-preview.blend'))
bpy.ops.render.render(write_still=True)
print('BLENDER_PREVIEW_ONLY',scene.render.filepath)
