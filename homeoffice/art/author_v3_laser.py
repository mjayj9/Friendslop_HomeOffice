"""A distinct laser pointer, authored in Blender in metre units; original scenes retained."""
import bpy,math
from pathlib import Path
R=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.new('HomeOffice_V3_Laser');bpy.context.window.scene=scene
materials={}
for name,color in [('charcoal',(.025,.032,.036,1)),('steel',(.25,.29,.31,1)),('tip',(.8,.02,.01,1))]:
    m=bpy.data.materials.new('V3_Laser_'+name);m.use_nodes=True
    node=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');node.inputs['Base Color'].default_value=color;node.inputs['Roughness'].default_value=.32
    materials[name]=m
for name,p,r,h,material in [('LaserBody',(0,0,0),.012,.17,'charcoal'),('LaserCap',(0,.086,0),.014,.014,'steel'),('LaserLens',(0,.095,0),.006,.008,'tip')]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=h,location=p,rotation=(math.pi/2,0,0));o=bpy.context.object;o.name=name;o.data.materials.append(materials[material])
bpy.ops.mesh.primitive_cube_add(size=1,location=(0,-.01,.012));o=bpy.context.object;o.name='LaserButton';o.scale=(.009,.025,.006);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(materials['tip'])
for o in scene.objects:o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/laser-pointer-v3.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/v2/laser-v3.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
print('Distinct 19cm laser pointer exported with red lens and button.')
