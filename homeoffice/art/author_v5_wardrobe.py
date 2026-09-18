"""Live Blender MCP: retain the user's mesh/rig, isolate facial UVs, author room fittings.

No original V3 file or existing scene is removed. The V5 derivative is repeatable.
Godot coordinates in the furnishing manifest are metres, Y up.
"""
import bpy, json, math, io_scene_gltf2
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes['COMMONS_V5_Character_Work']
bpy.context.window.scene=scene
arm=next(o for o in scene.objects if o.type=='ARMATURE')
body=next(o for o in scene.objects if o.name.startswith('Male_Standing'))
original=[tuple(v.co) for v in body.data.vertices]
face=bpy.data.materials.get('V5_Face') or body.data.materials[0].copy()
face.name='V5_Face'
if face.name not in body.data.materials:body.data.materials.append(face)
face_index=list(body.data.materials).index(face)
uv=body.data.uv_layers.active
face_faces=[]
for poly in body.data.polygons:
    # The source faces -Y. Isolate the forward facial cap, not hands/neck/body.
    center=sum((body.data.vertices[i].co for i in poly.vertices),Vector())/len(poly.vertices)
    if poly.material_index in (0,face_index) and center.z>1.42 and center.y<-.005 and poly.normal.y<-.18:
        poly.material_index=face_index;face_faces.append(poly.index)
        for loop_index in poly.loop_indices:
            co=body.data.vertices[body.data.loops[loop_index].vertex_index].co
            uv.data[loop_index].uv=((co.x+.16)/.32,(co.z-1.4)/.34)
assert original==[tuple(v.co) for v in body.data.vertices]
assert len(face_faces)>8
formats=[]
for cls in io_scene_gltf2.ExportGLTF2.__mro__:
    prop=getattr(cls,'__annotations__',{}).get('export_format')
    if prop:
        items=prop.keywords['items'];formats=items(None,bpy.context) if callable(items) else items
fmt=next(i[0] for i in formats if '.glb' in i[1])
def export(path,objects,animations=False):
    for o in bpy.context.scene.objects:o.select_set(False)
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    modes=[i.identifier for i in bpy.ops.export_scene.gltf.get_rna_type().properties['export_animation_mode'].enum_items]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format=fmt,use_selection=True,use_active_scene=True,export_animations=animations,export_animation_mode=next(m for m in modes if m=='ACTIONS'),export_force_sampling=True)
export(ROOT/'assets/characters/male-animated-v5.glb',[arm,body],True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/male-character-v5.blend'),copy=True)
(ROOT/'assets/characters/face-uv-v5.json').write_text(json.dumps({'version':1,'material':'V5_Face','sourceVertexCount':len(original),'facePolygonCount':len(face_faces),'canvas':512,'projection':{'x':[-.16,.16],'z':[1.4,1.74]},'originalGeometryPreserved':True}),encoding='utf-8')

# Separate scene for the wardrobe's real furniture, partitions and fitting station.
room=bpy.data.scenes.get('COMMONS_V5_Wardrobe') or bpy.data.scenes.new('COMMONS_V5_Wardrobe')
bpy.context.window.scene=room
for o in list(room.objects):
    if o.get('commons_v5_wardrobe'):bpy.data.objects.remove(o,do_unlink=True)
def mat(name,color,metal=0,rough=.5):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name)
    node=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value=(*color,1);node.inputs['Roughness'].default_value=rough;node.inputs['Metallic'].default_value=metal
    m.diffuse_color=(*color,1);return m
wood=mat('Wardrobe warm ash',(.43,.29,.16));linen=mat('Wardrobe linen',(.7,.67,.60));dark=mat('Wardrobe graphite',(.055,.065,.07));glass=mat('Wardrobe mirror silver',(.55,.64,.67),.95,.07)
brass=mat('Wardrobe brushed brass',(.47,.32,.12),.75,.3);blue=mat('Wardrobe blue knit',(.11,.20,.27));white=mat('Wardrobe console display',(.68,.84,.79),0,.25)
objects=[];colliders=[]
def box(name,p,size,material,solid=False,bevel=.015):
    # Input is Godot local X/Y/Z; export conversion yields the same convention.
    bpy.ops.mesh.primitive_cube_add(size=1,location=(p[0],-p[2],p[1]))
    o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(material);o['commons_v5_wardrobe']=True
    if bevel:
        mod=o.modifiers.new('Soft manufactured edges','BEVEL');mod.width=bevel;mod.segments=3
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    objects.append(o)
    if solid:colliders.append({'position':p,'size':size})
    return o
# Local origin is (-10, 3.6, -4); five metres east, seven south. Existing west lounge stays.
# Leave a 1.6 m opening to the reading lounge and the existing east gallery doorway clear.
box('West divider north',[0,1.45,1.6],[.12,2.9,3.2],linen,True)
box('West divider south',[0,1.45,6],[.12,2.9,2],linen,True)
box('West opening header',[0,2.7,4.1],[.12,.4,1.8],linen,True)
box('South acoustic partition',[2.5,1.45,7],[5,2.9,.12],linen,True)
box('South skirting',[2.5,.065,6.92],[5,.13,.055],wood)
for x in [1.05,2.75,4.05]:
    width=1.45 if x<3 else .95
    box('Wardrobe cabinet back',[x,1.15,.2],[width,2.3,.12],wood,True)
    for dx in [-width/2,width/2]:box('Cabinet stile',[x+dx,1.15,.48],[.06,2.3,.62],wood,True)
    for y in [.12,2.24]:box('Cabinet shelf',[x,y,.48],[width,.065,.62],wood,True)
    box('Cabinet plinth',[x,.055,.48],[width,.11,.55],dark,True)
    if x<3:
        box('Hanging rail',[x,1.95,.48],[width-.16,.03,.03],brass)
        for dx in [-.44,0,.44]:
            outline=[(-.05,1.79),(-.12,1.81),(-.22,1.70),(-.18,1.54),(-.12,1.57),(-.13,1.14),(.13,1.14),(.12,1.57),(.18,1.54),(.22,1.70),(.12,1.81),(.05,1.79),(.035,1.74),(-.035,1.74)]
            verts=[(x+dx+px,-z,y) for z in [.56,.62] for px,y in outline]
            count=len(outline);faces=[tuple(reversed(range(count))),tuple(range(count,count*2))]
            faces.extend((i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count))
            mesh=bpy.data.meshes.new('Knit shirt silhouette');mesh.from_pydata(verts,[],faces);mesh.update()
            garment=bpy.data.objects.new('Hanging knit shirt',mesh);room.collection.objects.link(garment);garment.data.materials.append(blue if dx<.1 else linen);garment['commons_v5_wardrobe']=True;objects.append(garment)
            box('Hanger neck',[x+dx,1.875,.59],[.018,.13,.02],brass,False,.005)
    else:
        for y in [.48,.9,1.32,1.74]:
            box('Folded shelf',[x,y,.48],[width,.055,.62],wood,True)
            box('Folded textile',[x,y+.095,.45],[.7,.12,.38],linen)
# Mirror and console face east, backed by the partition.
box('Mirror frame',[.14,1.22,2.16],[.13,2.12,1.27],brass,True)
box('Mirror pane',[.215,1.22,2.16],[.018,1.98,1.13],glass)
box('Console pedestal',[.47,.49,3.05],[.52,.98,.4],wood,True)
box('Console touch display',[.61,1.12,3.05],[.1,.4,.48],white,True)
for z in [1.54,2.78]:box('Mirror side light',[.26,1.23,z],[.035,1.82,.035],white)
# Real four-legged fitting bench with upholstery.
box('Fitting bench cushion',[2.6,.5,5.85],[1.8,.18,.63],blue,True,.045)
box('Fitting bench frame',[2.6,.38,5.85],[1.75,.08,.6],wood,True)
for x in [1.9,3.3]:
    for z in [5.65,6.05]:box('Fitting bench leg',[x,.18,z],[.08,.36,.08],wood,True)
box('Fitting rug',[2.25,.013,3.2],[2.9,.018,3.1],linen)
box('Ceiling light',[2.5,2.93,3.6],[1.5,.05,.6],white)
(ROOT/'assets/v5').mkdir(exist_ok=True)
export(ROOT/'assets/v5/wardrobe.glb',objects)
(ROOT/'assets/v5/wardrobe.json').write_text(json.dumps({'version':1,'origin':[-10,3.6,-4],'bounds':[-10,-4,-5,3],'console':[-9.34,4.72,-.95],'mirror':[-9.75,4.82,-1.84],'colliders':colliders,'existingReadingFurnitureUnmoved':True},indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/wardrobe-v5.blend'),copy=True)
print(json.dumps({'facePolygons':len(face_faces),'wardrobeObjects':len(objects),'colliders':len(colliders),'verticesPreserved':True}))
