import bpy,bmesh,json,io_scene_gltf2
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.get('COMMONS_V6_Passage') or bpy.data.scenes.new('COMMONS_V6_Passage');bpy.context.window.scene=scene
for o in list(scene.objects):bpy.data.objects.remove(o,do_unlink=True)
mat=bpy.data.materials.new('V6 passage limestone');node=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');node.inputs['Base Color'].default_value=(.69,.62,.49,1);node.inputs['Roughness'].default_value=.88
shapes=[]
for x,width,z1,z2,y1,y2 in [(17.5,3.6,1.48,2.4,0,-.17),(17.5,3.6,-1.48,-2.4,0,-.17),(23,4.5,-14.1,-12.6,0,-.17)]:
    points=[[x-width/2,-.23,z1],[x+width/2,-.23,z1],[x-width/2,-.23,z2],[x+width/2,-.23,z2],[x-width/2,y1,z1],[x+width/2,y1,z1],[x-width/2,y2,z2],[x+width/2,y2,z2]]
    bm=bmesh.new()
    for p in points:bm.verts.new((p[0],-p[2],p[1]))
    bmesh.ops.convex_hull(bm,input=list(bm.verts));mesh=bpy.data.meshes.new('Accessible threshold');bm.to_mesh(mesh);bm.free();ob=bpy.data.objects.new('Accessible threshold',mesh);scene.collection.objects.link(ob);ob.data.materials.append(mat);shapes.append({'points':points})
for o in scene.objects:o.select_set(True)
items=[]
for cls in io_scene_gltf2.ExportGLTF2.__mro__:
    p=getattr(cls,'__annotations__',{}).get('export_format')
    if p:items=p.keywords['items'];items=items(None,bpy.context) if callable(items) else items
fmt=next(i[0] for i in items if '.glb' in i[1])
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/v6/passage.glb'),export_format=fmt,use_selection=True,use_active_scene=True,export_animations=False)
(ROOT/'assets/v6/passage.json').write_text(json.dumps(shapes),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/passage-v6.blend'),copy=True)
print({'ramps':len(shapes)})
