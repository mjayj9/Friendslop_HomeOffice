import bpy,bmesh,json
from pathlib import Path
ROOT=Path(r'C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice')
scene=next(s for s in bpy.data.scenes if s.name.startswith('Homeoffice_Production'));bpy.context.window.scene=scene
c=bpy.data.collections.get('Asset_architecture');c.hide_viewport=False
if not bpy.data.objects.get('OakFloor_0'):
    for o in list(c.objects):
        if o.type!='MESH' or not o.data.materials or not o.data.materials[0].name.startswith(('HO_oak','HO_paleoak')):continue
        bm=bmesh.new();bm.from_mesh(o.data)
        selected=[v for v in bm.verts if .0005<(o.matrix_world@v.co).z<.016]
        bmesh.ops.delete(bm,geom=selected,context='VERTS');bm.to_mesh(o.data);bm.free()
    for tone in range(3):
        m=bpy.data.materials.new('HO_FloorTone_'+str(tone));m.diffuse_color=(.46+tone*.016,.32+tone*.013,.19+tone*.008,1);m.use_nodes=True;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=m.diffuse_color;m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.8
        objs=[]
        for ix in range(38):
            for iz in range(4):
                if (ix+iz)%3!=tone:continue
                bpy.ops.mesh.primitive_cube_add(size=1,location=(-5.75+ix*.5,-3.75+iz*2.5,.008));o=bpy.context.object;o.dimensions=(.496,2.496,.014);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
                for col in list(o.users_collection):col.objects.unlink(o)
                c.objects.link(o);objs.append(o)
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs:o.select_set(True)
        bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();bpy.context.object.name='OakFloor_'+str(tone)
def slab(name,location,dimensions,material):
    if bpy.data.objects.get(name):return
    bpy.ops.mesh.primitive_cube_add(size=1,location=location);o=bpy.context.object;o.name=name;o.dimensions=dimensions;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(bpy.data.materials[material])
    for col in list(o.users_collection):col.objects.unlink(o)
    c.objects.link(o)
slab('Door_sidelight',(6,-1.0,1.2),(.06,1.18,2.4),'HO_glass')
slab('Door_sidelight_mullion',(6,-.41,1.2),(.14,.07,2.4),'HO_oak')
manifest_path=ROOT/'assets/asset-manifest.json';manifest=json.loads(manifest_path.read_text(encoding='utf8'))
for col in [{'position':[3.5,3.34,0],'size':[19,.14,10]},{'position':[6,1.2,1.0],'size':[.08,2.4,1.18]}]:
    if col not in manifest['assets']['architecture']['collisions']:manifest['assets']['architecture']['collisions'].append(col)
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf8')
bpy.ops.object.select_all(action='DESELECT')
for o in c.objects:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/environment/architecture.glb'),use_selection=True,use_active_scene=True,export_format='GLB',export_apply=True,export_extras=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/homeoffice.blend'))
scene.render.filepath=str(ROOT/'art/blender-preview.png');scene.cycles.samples=16;bpy.ops.render.render(write_still=True)
print('QUIET_OAK_FLOOR_AND_DOOR_COMPLETED')
