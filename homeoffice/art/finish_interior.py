import bpy,math
from pathlib import Path
ROOT=Path(r'C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice')
scene=next(s for s in bpy.data.scenes if s.name.startswith('Homeoffice_Production'));bpy.context.window.scene=scene
c=bpy.data.collections.get('Asset_architecture');c.hide_viewport=False
roof=bpy.data.objects.get('Ceiling_Plaster')
if not roof:
    bpy.ops.mesh.primitive_cube_add(size=1,location=(3.5,0,3.34));roof=bpy.context.object;roof.name='Ceiling_Plaster';roof.dimensions=(19,10,.14);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    roof.data.materials.append(bpy.data.materials['HO_cream'])
    for old in list(roof.users_collection):old.objects.unlink(roof)
    c.objects.link(roof)
glass=bpy.data.materials.get('HO_glass')
if glass:
    glass.diffuse_color=(.38,.64,.70,.22)
    glass.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=.22
    glass.surface_render_method='DITHERED'
bpy.ops.object.select_all(action='DESELECT')
for o in c.objects:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/environment/architecture.glb'),use_selection=True,use_active_scene=True,export_format='GLB',export_apply=True,export_extras=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/homeoffice.blend'))
scene.render.filepath=str(ROOT/'art/blender-preview.png');scene.cycles.samples=16;bpy.ops.render.render(write_still=True)
print('CEILING_AND_GLAZING_ADDED')
