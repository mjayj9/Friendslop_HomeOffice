"""Non-destructive derivative of the retained site, with a real basement opening."""
import bpy,bmesh,json,hashlib,io_scene_gltf2
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.get('COMMONS_V6_Site') or bpy.data.scenes.new('COMMONS_V6_Site')
bpy.context.window.scene=scene
for ob in list(scene.objects):bpy.data.objects.remove(ob,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/v2/grounds-v3.glb'))
palette={'grass':'A7B88C','leaf':'88A363','bark':'977257','stone':'DFD5C3','oak':'CCA777'}
ground_material=None
for ob in list(scene.objects):
    if ob.type!='MESH':continue
    for slot in ob.material_slots:
        m=slot.material.copy();slot.material=m
        key=next((k for k in palette if k in m.name),'')
        if key:
            m.diffuse_color=(*[int(palette[key][i:i+2],16)/255 for i in (0,2,4)],1)
            node=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            node.inputs['Base Color'].default_value=m.diffuse_color;node.inputs['Roughness'].default_value=.82
        if 'grass' in m.name:ground_material=m
    if 'grass' in ob.name:
        bpy.data.objects.remove(ob,do_unlink=True);continue
    # Remove only connected pieces whose centre conflicts with the new footprint.
    bm=bmesh.new();bm.from_mesh(ob.data);seen=set();remove=[]
    for vert in bm.verts:
        if vert in seen:continue
        todo=[vert];seen.add(vert);component=[]
        while todo:
            v=todo.pop();component.append(v)
            for edge in v.link_edges:
                nxt=edge.other_vert(v)
                if nxt not in seen:seen.add(nxt);todo.append(nxt)
        center=sum((ob.matrix_world@v.co for v in component),Vector())/len(component)
        if 10<center.x<36 and 14<center.y<38:remove.extend(component)
    bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(ob.data);bm.free()
# Four separate ground blocks leave a geometric opening; no invisible covering plane.
for a,b,c,d in [(-250,10,-250,250),(36,250,-250,250),(10,36,-250,14),(10,36,38,250)]:
    bpy.ops.mesh.primitive_cube_add(size=1,location=((a+b)/2,(c+d)/2,-.29))
    ob=bpy.context.object;ob.name='Ground outside OFFICE';ob.scale=(b-a,d-c,.24);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);ob.data.materials.append(ground_material)
formats=[]
for cls in io_scene_gltf2.ExportGLTF2.__mro__:
    prop=getattr(cls,'__annotations__',{}).get('export_format')
    if prop:
        items=prop.keywords['items'];formats=items(None,bpy.context) if callable(items) else items
fmt=next(i[0] for i in formats if '.glb' in i[1])
for ob in scene.objects:ob.select_set(True)
target=ROOT/'assets/v6/grounds-v6.glb'
bpy.ops.export_scene.gltf(filepath=str(target),export_format=fmt,use_selection=True,use_active_scene=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/site-v6.blend'),copy=True)
print(json.dumps({'source':'assets/v2/grounds-v3.glb','derivative':str(target),'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'objects':len(scene.objects)}))
