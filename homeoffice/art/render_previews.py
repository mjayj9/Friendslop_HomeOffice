import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice')
out=ROOT/'art/previews';out.mkdir(exist_ok=True)
preview=bpy.data.scenes.new('Homeoffice_AssetPreview');bpy.context.window.scene=preview
preview.world=bpy.data.worlds.new('Asset neutral background');preview.world.use_nodes=True;preview.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.37,.32,1);preview.world.node_tree.nodes['Background'].inputs[1].default_value=.8
preview.render.engine='CYCLES';preview.cycles.samples=12;preview.render.resolution_x=512;preview.render.resolution_y=512;preview.render.resolution_percentage=100
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';preview.camera=cam
light_data=bpy.data.lights.new('Asset softbox','AREA');light=bpy.data.objects.new('Asset softbox',light_data);preview.collection.objects.link(light)
for name in ['chair','table','sofa','crate','book','marker','door']:
    copies=[];coords=[]
    for obj in bpy.data.collections['Asset_'+name].objects:
        if obj.type!='MESH':continue
        copy=obj.copy();copy.data=obj.data;copy.hide_render=False;copy.hide_viewport=False;preview.collection.objects.link(copy);copies.append(copy)
        coords.extend(copy.matrix_world@Vector(v) for v in copy.bound_box)
    center=Vector(tuple((max(v[i] for v in coords)+min(v[i] for v in coords))/2 for i in range(3)));extent=max(max(v[i] for v in coords)-min(v[i] for v in coords) for i in range(3))
    cam.location=center+Vector((extent*1.4,-extent*2,extent*1.3));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=extent*1.55
    light.location=center+Vector((extent,-extent,extent*2));light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler();light_data.energy=100*extent**2;light_data.shape='DISK';light_data.size=extent*2
    preview.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
    for o in copies:bpy.data.objects.remove(o,do_unlink=True)
print('SEVEN_ASSET_PREVIEWS_RENDERED')
