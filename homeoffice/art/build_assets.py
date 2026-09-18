import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice')
OUT=ROOT/'assets/environment'
for previous in list(bpy.data.scenes):
    if previous.name.startswith('Homeoffice_Production'):
        owned_collections=list(previous.collection.children)
        for obj in list(previous.objects):bpy.data.objects.remove(obj,do_unlink=True)
        bpy.data.scenes.remove(previous)
        for col in owned_collections:
            if col.users==0:bpy.data.collections.remove(col)
SCENE=bpy.data.scenes.new('Homeoffice_Production')
bpy.context.window.scene=SCENE
SCENE.unit_settings.system='METRIC'
M={}
def mat(name,color,rough=.7,metal=0):
    m=bpy.data.materials.new('HO_'+name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;M[name]=m
for args in [('oak',(.46,.25,.115)),('paleoak',(.72,.51,.30)),('cream',(.83,.79,.68)),('wall',(.82,.85,.78)),('teal',(.10,.27,.24)),('cloth',(.37,.51,.40)),('orange',(.68,.26,.10)),('metal',(.055,.075,.07),.3,.65),('white',(.92,.94,.89)),('leaf',(.16,.32,.12)),('soil',(.1,.06,.03)),('paper',(.86,.82,.68)),('blue',(.10,.21,.32)),('glass',(.38,.64,.70),.18,.25),('brass',(.65,.43,.15),.28,.7)]:mat(*args)
current=[];collisions=[];assets={}
def box(name,pos,size,material,bevel=.025,collision=False):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(pos[0],-pos[2],pos[1]));o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(M[material]);current.append(o)
    if bevel:
        mod=o.modifiers.new('Soft manufactured edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
        o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    if collision:collisions.append({'position':pos,'size':size})
    return o
def cyl(name,pos,radius,depth,material,vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=(pos[0],-pos[2],pos[1]));o=bpy.context.object;o.name=name;o.data.materials.append(M[material]);current.append(o)
    mod=o.modifiers.new('Edge','BEVEL');mod.width=.014;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
    return o
def sphere(name,pos,scale,material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,location=(pos[0],-pos[2],pos[1]));o=bpy.context.object;o.name=name;o.scale=(scale[0],scale[2],scale[1]);o.data.materials.append(M[material]);current.append(o);return o
def anchor(name,pos):
    o=bpy.data.objects.new(name,None);SCENE.collection.objects.link(o);o.location=(pos[0],-pos[2],pos[1]);current.append(o)
def begin():
    global current,collisions
    current=[];collisions=[]
def finish(name,anchors={}):
    for n,p in anchors.items():anchor(n,p)
    bpy.ops.object.select_all(action='DESELECT')
    for o in current:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,use_active_scene=True,export_format='GLB',export_apply=True,export_extras=True)
    meshes=[o for o in current if o.type=='MESH']
    coords=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
    assets[name]={'assetId':name,'version':1,'anchors':anchors,'collisions':collisions.copy(),'dimensions':[round(max(v[i] for v in coords)-min(v[i] for v in coords),3) for i in [0,2,1]],'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)}
    collection=bpy.data.collections.new('Asset_'+name);SCENE.collection.children.link(collection)
    for o in current:
        for c in list(o.users_collection):c.objects.unlink(o)
        collection.objects.link(o)
    collection.hide_render=True;collection.hide_viewport=True
    return collection
begin()
box('Seat shell',(0,.46,0),(.54,.1,.54),'oak')
box('Fabric cushion',(0,.53,-.015),(.50,.10,.47),'cloth',.055)
box('Back shell',(0,.85,.23),(.54,.57,.07),'oak',.045)
box('Back cushion',(0,.85,.18),(.47,.40,.055),'cloth',.035)
for x in [-.20,.20]:
    for z in [-.20,.20]:box('Tapered leg',(x,.23,z),(.055,.46,.055),'oak',.012)
finish('chair',{'sit':(0,.56,0),'stand':(0,0,-.85),'grip_left':(-.25,.78,.26),'grip_right':(.25,.78,.26)})
begin()
box('Tabletop',(0,.76,0),(2.8,.12,1.2),'paleoak',.07,True)
for x in [-1.12,1.12]:
    for z in [-.40,.40]:box('Steel leg',(x,.35,z),(.07,.7,.07),'metal',.012,True)
finish('table',{'work_surface':(0,.83,0)})
begin()
box('Base',(0,.28,0),(2.65,.38,.98),'teal',.09,True)
box('Back',(0,.72,.39),(2.65,.73,.24),'cloth',.10,True)
for x in [-1.24,1.24]:box('Arm',(x,.57,0),(.22,.49,1.04),'cloth',.07,True)
for x in [-.77,0,.77]:box('Seat cushion',(x,.51,-.05),(.73,.18,.70),'cloth',.07)
for x in [-1.02,1.02]:
    for z in [-.30,.30]:cyl('Sofa foot',(x,.09,z),.05,.18,'oak')
for x in [-.9,.9]:
    p=box('Accent pillow',(x,.79,.15),(.42,.37,.16),'orange',.06);p.rotation_euler[1]=.2
finish('sofa',{'sit_left':(-.77,.60,-.05),'sit_right':(.77,.60,-.05),'stand':(0,0,-1.1)})
assets['sofa']['seatContactVersion']=1
assets['sofa']['seatContacts']=[dict(id=str(i),pelvis=[x,.64,-.1],feet={'L':[x-.12,.09,-.54],'R':[x+.12,.09,-.54]},back=[x,.96,.22],approach=[x,0,-1.12],exits=[[x,0,-1.15],[x,0,-1.5]],width=.65) for i,x in enumerate([-.77,0,.77])]
begin()
box('Crate',(0,0,0),(.44,.44,.44),'paleoak',.015)
for y in [-.17,.17]:
    box('Band front',(0,y,-.23),(.46,.035,.025),'oak',.005)
    box('Band rear',(0,y,.23),(.46,.035,.025),'oak',.005)
for x in [-.17,.17]:box('Top batten',(x,.23,0),(.04,.025,.46),'oak',.005)
finish('crate',{'grip':(0,0,0)})
begin()
box('Pages',(0,0,0),(.22,.045,.30),'paper',.006)
for y in [-.028,.028]:box('Linen cover',(0,y,0),(.24,.013,.32),'blue',.004)
box('Spine',(-.116,0,0),(.02,.065,.32),'blue',.007)
box('Gold title',(0,.036,0),(.12,.003,.025),'brass',0)
finish('book',{'grip':(0,0,0)})
begin()
cyl('Marker',(0,0,0),.013,.16,'white',12);cyl('Nib',(0,-.088,0),.006,.018,'metal',12)
finish('marker',{'grip':(0,0,0),'tip':(0,-.10,0)})
begin()
box('Door',(0.63,1.18,0),(1.26,2.36,.07),'teal',.02)
box('Raised panel',(.63,1.35,-.045),(.99,1.6,.025),'cloth',.015)
for z in [-.07,.07]:box('Brass lever',(1.09,1.02,z),(.20,.035,.04),'brass',.012)
finish('door',{'hinge':(0,0,0),'handle':(1.09,1.02,-.1)})
begin()
# Continuous shell: lounge x -6..6, meeting x 6..13, z -5..5.
box('Foundation',(3.5,-.13,0),(19,.26,10),'oak',.015,True)
for x in range(38):
    for z in range(10):box('Floorboard',(-5.75+x*.5,.008,-4.5+z),(.492,.014,.99),'paleoak' if (x+z)%5 else 'oak',.003)
box('North wall',(3.5,1.65,-5),(19,.0+3.3,.18),'wall',.01,True)
box('West wall',(-6,1.65,0),(.18,3.3,10),'wall',.01,True)
box('East wall',(13,1.65,0),(.18,3.3,10),'wall',.01,True)
# South windows have solid sill and top with slender mullions.
box('Window sill wall',(3.5,.42,5),(19,.84,.18),'cream',.01,True)
box('Window lintel',(3.5,3.05,5),(19,.5,.18),'cream',.01,True)
box('Window collision',(3.5,1.82,5),(19,1.96,.025),'glass',0,True)
for x in [-6,-3,0,3,6,9,13]:box('Window mullion',(x,1.82,4.97),(.065,2.1,.09),'oak',.005)
for z,depth in [(-2.95,4.1),(3.3,3.4)]:box('Meeting partition',(6,1.65,z),(.18,3.3,depth),'wall',.01,True)
box('Door header',(6,2.85,.35),(.20,.90,2.5),'wall',.01,True)
for z in [-.91,1.61]:box('Door casing',(5.87,1.25,z),(.12,2.50,.1),'oak',.012)
box('Door casing top',(5.87,2.47,.35),(.12,.10,2.62),'oak',.012)
for x,w in [(0,11.8),(9.5,6.8)]:
    box('Skirting north',(x,.09,-4.87),(w,.18,.05),'oak',.007)
    box('Ceiling beam',(x,3.18,-1),(w,.16,.16),'oak',.015)
box('Living rug',(-1,.026,.3),(4.2,.025,3.2),'cream',.04)
for z in [-1.18,1.78]:box('Woven rug border',(-1,.042,z),(4.05,.004,.065),'orange',0)
box('Meeting rug',(9.5,.025,0),(5.5,.025,4.1),'teal',.035)
# Built-in storage, books and framed art.
for x in [-4.4,-2.8]:
    box('Cabinet',(x,.51,-4.58),(1.55,1.02,.62),'oak',.035,True)
    for dx in [-.39,.39]:
        box('Cabinet door',(x+dx,.52,-4.24),(.71,.86,.045),'cream',.015)
        box('Handle',(x+dx,.72,-4.205),(.15,.025,.025),'brass',.008)
for i in range(12):box('Book on shelf',(-4.8+i*.14,1.22,-4.56),(.10,.3+(.05*(i%3)),.24),['orange','blue','teal'][i%3],.005)
box('Artwork frame',(-1,2.02,-4.85),(1.5,1.05,.06),'oak',.02)
box('Artwork canvas',(-1,2.02,-4.805),(1.38,.94,.025),'cream',.002)
sphere('Artwork sun',(-1.22,2.16,-4.775),(.23,.23,.014),'orange')
box('Artwork horizon',(-.8,1.85,-4.777),(.82,.18,.02),'teal',.02)
box('Whiteboard frame',(9.5,1.76,-4.82),(3.64,1.86,.10),'oak',.025)
box('Whiteboard',(9.5,1.76,-4.75),(3.48,1.70,.025),'white',.005)
box('Marker ledge',(9.5,.87,-4.65),(3.4,.055,.20),'metal',.01,True)
# Plants: visible faceted leaves, no texture dependency.
for x,z in [(-5.2,3.8),(4.8,-4.1),(12.1,3.9)]:
    cyl('Terracotta pot',(x,.24,z),.27,.48,'orange')
    cyl('Soil',(x,.485,z),.24,.012,'soil')
    for i in range(7):
        a=i*2.4;leaf=sphere('Leaf',(x+math.cos(a)*.22,.85+i*.06,z+math.sin(a)*.22),(.12,.4,.08),'leaf');leaf.rotation_euler=(math.sin(a)*.6,math.cos(a)*.6,a)
for x in [-1,9.5]:
    cyl('Pendant cable',(x,2.93,0),.012,.50,'metal',8)
    cyl('Pendant shade',(x,2.64,0),.44,.15,'cream')
    cyl('Pendant warm diffuser',(x,2.55,0),.38,.018,'white')
finish('architecture',{'board':(9.5,1.76,-4.70),'spawn':(1,0,3.4)})
(ROOT/'assets/asset-manifest.json').write_text(json.dumps({'version':1,'assets':assets},indent=2),encoding='utf8')
# Keep original user scene untouched; this is a new production scene/file.
for c in SCENE.collection.children:
    if c.name=='Asset_architecture':c.hide_render=False;c.hide_viewport=False
for name,pos in [('sofa',(-1,0,1.8)),('table',(9.5,0,0)),('chair',(9.5,0,1.15))]:
    c=bpy.data.collections.get('Asset_'+name)
    for src in c.objects:
        o=src.copy();o.data=src.data;SCENE.collection.objects.link(o);o.location+=Vector((pos[0],-pos[2],pos[1]))
SCENE.world=bpy.data.worlds.new('Warm daylight');SCENE.world.use_nodes=True;SCENE.world.node_tree.nodes['Background'].inputs[0].default_value=(.60,.72,.83,1);SCENE.world.node_tree.nodes['Background'].inputs[1].default_value=.7
data=bpy.data.lights.new('Sun','SUN');o=bpy.data.objects.new('Sun',data);SCENE.collection.objects.link(o);o.rotation_euler=(.45,-.5,-.3);data.energy=2
data=bpy.data.lights.new('Window softbox','AREA');o=bpy.data.objects.new('Window softbox',data);SCENE.collection.objects.link(o);o.location=(0,-3,5);data.energy=1600;data.shape='DISK';data.size=8
bpy.ops.object.camera_add(location=(2,-3.6,1.75));camera=bpy.context.object;camera.rotation_euler=(Vector((-2,1.5,1.3))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.lens=22;SCENE.camera=camera
SCENE.render.engine='CYCLES';SCENE.cycles.samples=24;SCENE.render.resolution_x=1100;SCENE.render.resolution_y=700;SCENE.render.resolution_percentage=100
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/homeoffice.blend'))
SCENE.render.filepath=str(ROOT/'art/blender-preview.png');bpy.ops.render.render(write_still=True)
print('ASSETS_DONE',len(assets))
