"""Keep the HOME/legacy rooms; make the east link a real public campus passage."""
import bpy,bmesh,io_scene_gltf2,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.get('COMMONS_V6_Retained_HOME') or bpy.data.scenes.new('COMMONS_V6_Retained_HOME')
bpy.context.window.scene=scene
for ob in list(scene.objects):bpy.data.objects.remove(ob,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/v2/house-v3.glb'))
removed=0;materials={}
palette={'plaster':'F1E5D2','wall':'F1E5D2','oak':'D7B68A','wood':'BC875F','sage':'819B7E','roof':'C77C59','trim':'BC875F','floor':'D9D2C0'}
for ob in list(scene.objects):
    if ob.type!='MESH':continue
    for slot in ob.material_slots:
        original=slot.material
        if original.name not in materials:
            m=original.copy();materials[original.name]=m
            key=next((k for k in palette if k in original.name.lower()),'')
            if key:
                values=[int(palette[key][i:i+2],16)/255 for i in (0,2,4)]
                m.diffuse_color=(*[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in values],1)
                node=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');node.inputs['Base Color'].default_value=m.diffuse_color;node.inputs['Roughness'].default_value=.8
        slot.material=materials[original.name]
    bm=bmesh.new();bm.from_mesh(ob.data);seen=set();remove=[]
    for vert in bm.verts:
        if vert in seen:continue
        todo=[vert];seen.add(vert);component=[]
        while todo:
            v=todo.pop();component.append(v)
            for edge in v.link_edges:
                nxt=edge.other_vert(v)
                if nxt not in seen:seen.add(nxt);todo.append(nxt)
        coords=[ob.matrix_world@v.co for v in component];center=sum(coords,Vector())/len(coords)
        if 15.65<center.x<19.31 and abs(abs(center.y)-1.5)<.18 and max(v.z for v in coords)<2.75 and min(v.z for v in coords)>-.02:remove.extend(component);removed+=1
    bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(ob.data);bm.free()
formats=[]
for cls in io_scene_gltf2.ExportGLTF2.__mro__:
    prop=getattr(cls,'__annotations__',{}).get('export_format')
    if prop:
        items=prop.keywords['items'];formats=items(None,bpy.context) if callable(items) else items
fmt=next(i[0] for i in formats if '.glb' in i[1])
for ob in scene.objects:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/v6/house-v6.glb'),export_format=fmt,use_selection=True,use_active_scene=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/retained-home-v6.blend'),copy=True)
print(json.dumps({'removedPassagePieces':removed,'materials':list(materials),'objects':len(scene.objects)}))
