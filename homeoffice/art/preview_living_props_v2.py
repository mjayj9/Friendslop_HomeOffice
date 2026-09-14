"""Actual Blender asset preview. Run after living_props_v2.py. Not a game capture."""
import bpy,os
from mathutils import Vector,Matrix
from pathlib import Path
R=Path(os.environ.get('MOYEO_PROJECT',str(Path(bpy.data.filepath).parent.parent)))
source=bpy.data.scenes['Moyeo_V2_Interactive_Living_Props']
preview=bpy.data.scenes.new('Moyeo_V2_Living_Props_Preview');bpy.context.window.scene=preview
placements=[(-1.55,0,0),(-1.55,.43,.68),(.2,0,0),(.2,-.38,.57),(1.7,0,0)]
for i,col in enumerate(source.collection.children):
 for obj in col.objects:
  if obj.type!='MESH':continue
  c=obj.copy();preview.collection.objects.link(c)
  local=obj.matrix_world.copy();local.translation.x-=i*1.8
  transform=Matrix.Translation(Vector(placements[i]))
  if i==1:transform=transform@Matrix.Rotation(-1.35,4,'X')
  c.matrix_world=transform@local
world=bpy.data.worlds.new('Living Preview World');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.60,.57,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5;preview.world=world
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.03))
ground=bpy.context.object;mat=bpy.data.materials.new('Preview Neutral');mat.diffuse_color=(.37,.42,.38,1);ground.data.materials.append(mat)
for at,energy,size in [((1,-4,6),1100,5),((-4,-1,3),600,4)]:
 light=bpy.data.lights.new('Preview softbox','AREA');light.energy=energy;light.shape='DISK';light.size=size;o=bpy.data.objects.new('Preview softbox',light);preview.collection.objects.link(o);o.location=at;o.rotation_euler=(Vector((0,0,.5))-o.location).to_track_quat('-Z','Y').to_euler()
cam=bpy.data.cameras.new('Preview camera');o=bpy.data.objects.new('Preview camera',cam);preview.collection.objects.link(o);o.location=(4,-7,4);o.rotation_euler=(Vector((0,0,.7))-o.location).to_track_quat('-Z','Y').to_euler();cam.type='ORTHO';cam.ortho_scale=5.5;preview.camera=o
preview.render.engine='CYCLES';preview.cycles.samples=16;preview.cycles.device='CPU';preview.render.resolution_x=1100;preview.render.resolution_y=660;preview.render.resolution_percentage=100;preview.render.image_settings.file_format='PNG';preview.render.filepath=str(R/'art/v2-living-props-blender-preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/v2-living-props-preview.blend'));bpy.ops.render.render(write_still=True)
print('Actual Blender-only asset preview',preview.render.filepath)
