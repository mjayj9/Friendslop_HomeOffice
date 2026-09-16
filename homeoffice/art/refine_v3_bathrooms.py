"""Refine existing V3 facility meshes in Blender, retaining their runtime node names."""
import bpy,math
from pathlib import Path
R=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes['HomeOffice_V3_Facilities'];bpy.context.window.scene=scene
def vessel(obj,levels):
    vertices=[];faces=[];n=32
    for rx,ry,z in levels:
        vertices.extend([(rx*math.cos(i*math.tau/n),ry*math.sin(i*math.tau/n),z) for i in range(n)])
    for j in range(len(levels)-1):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    faces.append(tuple(range((len(levels)-1)*n,len(levels)*n)))
    mesh=bpy.data.meshes.new(obj.name+'_hollow');mesh.from_pydata(vertices,[],faces);mesh.validate();mesh.update();mesh.materials.append(bpy.data.materials['V3_ceramic']);obj.data=mesh
for tag in ['ground','upper']:
    vessel(scene.objects['Basin_'+tag],[(.44,.245,-.07),(.47,.27,.04),(.36,.18,.04),(.29,.13,-.09)])
    vessel(scene.objects['ToiletBowl_'+tag],[(.15,.21,-.08),(.21,.28,.07),(.14,.20,.07),(.11,.15,-.03)])
    stand=scene.objects['Washstand_'+tag];stand.scale.z=.9125;stand.location.z=(0 if tag=="ground" else 3.6)+.365
    lid=scene.objects['ToiletLid_'+tag]
    if not lid.get('hinged'):
        for v in lid.data.vertices:v.co.y-=.265
        lid.location.y+=.265;lid['hinged']=True
for name in ['V3_ceramic','V3_metal']:
    node=next(n for n in bpy.data.materials[name].node_tree.nodes if n.type=='BSDF_PRINCIPLED');node.inputs['Roughness'].default_value=.24
for o in bpy.context.view_layer.objects:o.select_set(False)
for o in scene.objects:
    if o.type not in ['CAMERA','LIGHT']:o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/campus-details-v3.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/v2/campus-details-v3.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
print('Refined four hollow basins/bowls and two hinged lids; retained fixture names.')
