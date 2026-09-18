"""Author original, metre-scale crafted campus modules in an isolated Blender scene.
All coordinates/contracts below use Godot Y-up, north=-Z. Originals are untouched.
"""
import bpy, bmesh, math, json, hashlib, io_scene_gltf2
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/v6';OUT.mkdir(exist_ok=True)
SCENE='COMMONS_V6_Crafted_Campus'
scene=bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
bpy.context.window.scene=scene
for ob in list(scene.objects):
    if ob.get('commons_v6'):bpy.data.objects.remove(ob,do_unlink=True)
palette={'cream':'F1E5D2','ivory':'FAF3E5','wood':'BC875F','oak':'D7B68A','sage':'819B7E','deep':'436D61','ochre':'EDBB58','ink':'344044','clay':'C77C59','rose':'CF9B86','stone':'D9D2C0','leaf':'8EA95E','leaf2':'AAC27C','water':'83B5B2','glass':'C3DDD7','metal':'5F6E65','light':'FFE4AB'}
materials={}
def mat(key):
    if key in materials:return materials[key]
    m=bpy.data.materials.new('V6_'+key)
    values=[int(palette[key][i:i+2],16)/255 for i in (0,2,4)]
    m.diffuse_color=(*[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in values],1)
    node=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value=m.diffuse_color
    node.inputs['Roughness'].default_value=.76 if key not in ('glass','metal') else .3
    if key=='glass':
        node.inputs['Alpha'].default_value=.22
        enums=[i.identifier for i in m.bl_rna.properties['surface_render_method'].enum_items]
        blend=next((v for v in enums if 'BLEND' in v),None)
        if blend:m.surface_render_method=blend
    if key=='light':
        node.inputs['Emission Color'].default_value=m.diffuse_color;node.inputs['Emission Strength'].default_value=.35
    materials[key]=m;return m
def tag(ob,name,key):
    ob.name=name;ob['commons_v6']=True;ob['v6_floor']=current_floor;ob['v6_shell']=current_floor=='site' or name.startswith(('Facade','Side sill','Side header','Side pier','Side window','Wood framed window','Terracotta course','Entry side sill','Roof parapet','Roof tree','Pergola','Terrace','Garden terrace','Roof WC','Roof lift'));ob.data.materials.append(mat(key));return ob
def mesh_object(name,p,bm,key):
    mesh=bpy.data.meshes.new(name);bm.to_mesh(mesh);bm.free()
    ob=bpy.data.objects.new(name,mesh);scene.collection.objects.link(ob);ob.location=(p[0],-p[2],p[1]);return tag(ob,name,key)
def box(name,p,size,key='cream',bevel=.025):
    bm=bmesh.new();bmesh.ops.create_cube(bm,size=1)
    for v in bm.verts:v.co.x*=size[0];v.co.y*=size[2];v.co.z*=size[1]
    if bevel:bmesh.ops.bevel(bm,geom=list(bm.edges),offset=min(bevel,min(size)*.2),segments=2,profile=.5)
    return mesh_object(name,p,bm,key)
def ellipsoid(name,p,scale,key='leaf'):
    bm=bmesh.new();bmesh.ops.create_uvsphere(bm,u_segments=12,v_segments=8,radius=1)
    for v in bm.verts:v.co.x*=scale[0];v.co.y*=scale[2];v.co.z*=scale[1]
    for f in bm.faces:f.smooth=True
    return mesh_object(name,p,bm,key)
def cylinder(name,p,r,height,key='wood'):
    bm=bmesh.new();bmesh.ops.create_cone(bm,cap_ends=True,cap_tris=False,segments=12,radius1=r,radius2=r,depth=height)
    bmesh.ops.bevel(bm,geom=list(bm.edges),offset=min(.035,r*.15),segments=2,profile=.5)
    return mesh_object(name,p,bm,key)
collisions=[];furniture=[];fixtures=[];floor_objects={};current_floor='site'
def solid(name,p,size,key='cream',bevel=.025):
    ob=box(name,p,size,key,bevel);collisions.append({'floor':current_floor,'name':name,'position':p,'size':size});return ob
def window(name,x,y,z,width,height,axis='x'):
    dims=(width,height,.12) if axis=='x' else (.12,height,width)
    box(name+' glass',(x,y,z),dims,'glass',0)
    collisions.append({'floor':current_floor,'name':name+' glazing','position':[x,y,z],'size':dims})
    for sign in (-1,1):
        box(name+' lintel',(x,y+sign*height/2,z),(width+.14,.13,.22) if axis=='x' else (.22,.13,width+.14),'wood')
        p=(x+sign*width/2,y,z) if axis=='x' else (x,y,z+sign*width/2)
        box(name+' jamb',p,(.13,height,.22) if axis=='x' else (.22,height,.13),'wood')
    box(name+' mullion',(x,y,z),(.08,height,.16) if axis=='x' else (.16,height,.08),'wood')
def table(name,x,y,z,w=2.3,d=1.1):
    solid(name+' top',(x,y+.78,z),(w,.12,d),'oak',.065)
    for xx in (-w/2+.14,w/2-.14):
        for zz in (-d/2+.14,d/2-.14):solid(name+' leg',(x+xx,y+.34,z+zz),(.12,.68,.12),'wood',.025)
    fixtures.append({'id':name,'floor':current_floor,'kind':'worktable','position':[x,y+.95,z],'size':[w,1.0,d]})
def chair(name,x,y,z,yaw=0):furniture.append({'id':name,'kind':'chair','p':[x,y,z],'yaw':yaw,'state':{},'floor':current_floor})
def plant(name,x,y,z,r=.6):
    collisions.append({'floor':current_floor,'name':name+' pot','position':[x,y+.24,z],'size':[r,.48,r]})
    cylinder(name+' pot',(x,y+.24,z),r*.5,.48,'clay');cylinder(name+' stem',(x,y+.65,z),.06,.9,'wood')
    for dx,dy,dz,s in [(-.25,.9,0,.55),(.2,1.13,.1,.62),(0,1.42,-.06,.48)]:ellipsoid(name+' foliage',(x+dx*r,y+dy*r,z+dz*r),(s*r,.58*r,s*r),'leaf' if dy<1.2 else 'leaf2')
def bench(name,x,y,z,w=2):
    solid(name+' seat',(x,y+.43,z),(w,.14,.54),'wood',.07);solid(name+' back',(x,y+.82,z+.23),(w,.72,.12),'sage',.055)
    for xx in (-w*.36,w*.36):solid(name+' foot',(x+xx,y+.18,z),(.16,.36,.42),'deep',.035)
def shelf(name,x,y,z,w=2.4):
    solid(name+' back',(x,y+1.06,z),(w,2.12,.42),'oak',.04)
    for level in range(3):
        yy=y+.38+level*.55;box(name+' recess',(x,yy+.12,z+.225),(w-.18,.40,.03),'cream',0)
        for b in range(9):box(name+' book',(x-w*.43+b*w*.096,yy+.09,z+.25),(.12,.27+(b%3)*.05,.14),['sage','clay','ochre','deep'][b%4],.01)
def door_wall(name,x1,x2,z,y,door_center=None,width=1.6,key='cream'):
    if door_center is None:solid(name,((x1+x2)/2,y+1.47,z),(x2-x1,2.94,.16),key);return
    for a,b in ((x1,door_center-width/2),(door_center+width/2,x2)):
        if b>a:solid(name,((a+b)/2,y+1.47,z),(b-a,2.94,.16),key)
    solid(name+' header',(door_center,y+2.77,z),(width,.34,.16),key)
    for x in (door_center-width/2,door_center+width/2):box(name+' trim',(x,y+1.23,z+.01),(.11,2.46,.23),'wood')
def slab(y,holes,key='stone'):
    xs=sorted(set([10,36]+[q for h in holes for q in (h[0],h[2])]))
    zs=sorted(set([-38,-14]+[q for h in holes for q in (h[1],h[3])]))
    for a,b in zip(xs,xs[1:]):
        for c,d in zip(zs,zs[1:]):
            cx,cz=(a+b)/2,(c+d)/2
            if any(h[0]<cx<h[2] and h[1]<cz<h[3] for h in holes):continue
            solid('Floor '+current_floor,(cx,y-.12,cz),(b-a,.24,d-c),key,.006)
def ramp(points):collisions.append({'floor':current_floor,'name':'Stair ramp','points':points})
def stairs(x,z,y):
    # Two true ten-riser flights with a 1.4m intermediate landing.
    for i in range(10):
        h=(i+1)*.18;solid('Stair tread',(x+.8,y+h-.065,z-i*.30),(1.5,.13,.32),'oak',.018)
        h=1.8+(i+1)*.18;solid('Return tread',(x+2.45,y+h-.065,z-2.7+i*.30),(1.5,.13,.32),'oak',.018)
    solid('Stair entry landing',(x+.8,y-.06,z+.60),(1.5,.12,1.04),'oak')
    solid('Stair upper landing',(x+2.45,y+3.52,z+.54),(1.5,.16,.80),'oak')
    solid('Half landing',(x+1.625,y+1.73,z-3.55),(3.25,.14,1.4),'oak')
    for xx,yy,rev in [(x+.05,y,False),(x+1.55,y,False),(x+1.7,y+1.8,True),(x+3.2,y+1.8,True)]:
        for i in range(5):
            zz=z-i*.675;top=(1.8-i*.45 if rev else i*.45)+yy
            cylinder('Stair baluster',(xx,top+.55,zz),.035,1.1,'deep')
        ob=box('Continuous handrail',(xx,yy+.9+.94,z-1.35),(.075,.075,3.28),'wood',.025);ob.rotation_euler.x=math.atan2(1.8,2.7)*(-1 if rev else 1)
    for xx,yy,rev in [(x+.05,y,False),(x+1.7,y+1.8,True)]:
        lo=z+(.46 if not rev else -.16);hi=z+(-2.54 if not rev else -3.16)
        top1=yy+(0 if not rev else 1.8);top2=yy+(1.8 if not rev else 0)
        ramp([[xx,top1-.15,lo],[xx+1.5,top1-.15,lo],[xx,top2-.15,hi],[xx+1.5,top2-.15,hi],[xx,top1,lo],[xx+1.5,top1,lo],[xx,top2,hi],[xx+1.5,top2,hi]])
def restroom(y):
    door_wall('WC corridor wall',30.6,35.8,-28.4,y,31.8,1.5)
    solid('WC west wall',(30.6,y+1.45,-33),( .16,2.9,9.2),'cream')
    for z in (-35.8,-32.8):
        solid('Cubicle divider',(34.45,y+1.05,z+1.25),(2.7,2.1,.12),'sage')
        for dz in [-1.025,1.025]:solid('Cubicle front return',(33.1,y+1.05,z+dz),(.12,2.1,.45),'sage')
        cylinder('WC base',(34.1,y+.24,z),.26,.48,'ivory');ellipsoid('WC bowl',(34.1,y+.51,z),(.37,.15,.48),'ivory');box('WC cistern',(34.1,y+.72,z-.45),(.63,.75,.23),'ivory',.07)
    solid('Basin counter',(31.25,y+.78,-34.2),(.75,.12,2.0),'oak',.07)
    for z in (-34.8,-33.7):ellipsoid('Porcelain basin',(31.25,y+.86,z),(.31,.1,.36),'ivory')
    box('WC mirror',(30.73,y+1.55,-34.25),(.03,1.1,1.9),'glass');fixtures.append({'id':'campus-wc-'+current_floor,'floor':current_floor,'kind':'tap','position':[31.6,y+.95,-33.7],'size':[.5,.4,.5]})

floor_specs=[('B1',-3.6,'지원 · 주차'),('1F',0,'도착 · 카페'),('2F',3.6,'회의 · 공동작업'),('3F',7.2,'프로젝트 스튜디오'),('4F',10.8,'집중 · 개인 작업'),('5F',14.4,'운영 · 방송'),('6F',18,'식사 · 커뮤니티'),('RF',21.6,'하늘 정원')]
lifts=[{'id':'passenger','x':21.0,'z':-34.8,'width':2.7,'depth':3.0},{'id':'service','x':26.0,'z':-34.8,'width':3.5,'depth':3.0}]
holes=[[10.6,-36.7,14.25,-31.2],[31.5,-22.7,35.15,-17.2]]+[[l['x']-l['width']/2,-36.3,l['x']+l['width']/2,-33.3] for l in lifts]
rooms=[];personal_slots=[]
for floor,y,title in floor_specs:
    current_floor=floor;before=set(scene.objects)
    slab(y,[] if floor=='B1' else holes+([[10,-16.4,36,-14]] if floor=='RF' else []),'stone' if floor in ('B1','1F','RF') else 'oak')
    if floor!='RF':
        front=-16.4 if floor in ('5F','6F') else -14
        facade='sage' if floor in ('1F','2F') else 'cream'
        # Exterior: actual openings, deep reveal and paired wood mullions.
        for z in [-38,front]:
            solid('Facade sill',(23,y+.4,z),(26,.8,.25),facade,.07)
            solid('Facade header',(23,y+3.12,z),(26,.72,.25),'cream',.07)
            for x in [10,14.3,18.7,23,27.3,31.7,36]:
                if not(z==front and ((floor=='1F' and x==23) or (floor in ('5F','6F') and x==27.3))):solid('Facade pier',(x,y+1.84,z),(.3,2.18,.3),'cream',.055)
            for x in [12.15,16.5,20.85,25.15,29.5,33.85]:
                if not(z==front and ((floor=='1F' and x in (20.85,25.15)) or (floor in ('5F','6F') and x in (25.15,29.5)))):window('Wood framed window',x,y+1.83,z,3.82,1.9)
            box('Terracotta course',(23,y+3.48,z),(26.28,.20,.46),'clay',.07)
        for x in [10,36]:
            depth=front+38;center_z=(-38+front)/2
            solid('Side sill',(x,y+.4,center_z),(.25,.8,depth),facade,.07);solid('Side header',(x,y+3.12,center_z),(.25,.72,depth),'cream',.07)
            spans=6;step=depth/spans
            for i in range(spans+1):solid('Side pier',(x,y+1.85,-38+i*step),(.3,2.1,.3),'cream',.05)
            for i in range(spans):window('Side window',x,y+1.83,-38+(i+.5)*step,step-.55,1.9,'z')
        if floor in ('1F','5F','6F'):
            for ob in list(scene.objects):
                if ob.get('v6_floor')==floor and ob.name.startswith('Facade sill') and abs(ob.location.y+front)<.1:bpy.data.objects.remove(ob,do_unlink=True)
            collisions[:]=[c for c in collisions if not(c['floor']==floor and c['name']=='Facade sill' and c['position'][2]==front)]
            entrance=23 if floor=='1F' else 27.3
            for left,right in [(10,entrance-2.3),(entrance+2.3,36)]:solid('Entry side sill',((left+right)/2,y+.4,front),(right-left,.8,.25),facade)
        if floor in ('5F','6F'):
            solid('Garden terrace guard',(23,y+.58,-14.13),(26,1.16,.16),'sage',.04)
            for x in (10.1,35.9):solid('Terrace side guard',(x,y+.58,-15.2),(.18,1.16,2.4),'sage')
            for x in (13.8,18.2,31.5):plant('Terrace planter',x,y,-15.35,.8)
            bench('Terrace seat',23,y,-15.25,2.2)
        restroom(y)
        for l in lifts:
            for side in (-1,1):solid('Lift shaft wall',(l['x']+side*(l['width']/2+.10),y+1.7,l['z']),(.2,3.4,3.2),'cream')
            solid('Lift shaft back',(l['x'],y+1.7,-36.4),(l['width']+.4,3.4,.2),'cream')
            fixtures.append({'id':'lift-call-'+l['id']+'-'+floor,'kind':'lift-call','liftId':l['id'],'floor':floor,'position':[l['x']+l['width']/2+.3,y+1.2,-33.04],'size':[.24,.46,.16]})
            box('Lift call brass',(l['x']+l['width']/2+.3,y+1.2,-33.04),(.24,.46,.08),'ochre',.04)
        stairs(10.8,-32,y);stairs(31.7,-18,y)
        for x in (17.0,29.0):plant('Hall planter',x,y,-30,.85)
        shelf('Shared resource island',22,y,-26,1.4);bench('Hall conversation',22,y,-24.8,1.4)
        # Corridor ring stays clear; real rooms front/north-west have distinct layouts.
        if floor not in ('B1','1F','4F'):
            door_wall('Front west room',10.2,21.5,-22.6,y,16.7,1.7)
            door_wall('Front east room',24.2,30.4,-22.6,y,27,1.7)
            solid('Front room divider',(23,y+1.48,-18.3),(.17,2.96,8.45),'cream')
        if floor=='B1':
            for x in [17,20,23,26,29]:
                for z in [-28,-21]:
                    for xx in [-1.25,1.25]:box('Parking stripe',(x+xx,y+.012,z),(.07,.018,4.6),'ivory',0)
                    box('Wheel stop',(x,y+.07,z-1.8),(1.6,.12,.18),'ochre')
            for x in [16,19,22]:shelf('Maintenance storage',x,y,-36,2)
        elif floor=='1F':
            table('information-desk',27.3,y,-21.4,4.5,1.2);shelf('Lobby welcome shelves',16,y,-26,3.2)
            for x,z in [(13,-18),(17,-18),(13,-24),(27,-18),(29,-24)]:
                table('cafe-table-'+str(x)+'-'+str(z),x,y,z,1.35,1.0);chair('cafe-chair-'+str(x)+'-'+str(z),x,y,z+1.0,0);chair('cafe-chair-b-'+str(x)+'-'+str(z),x,y,z-1.0,math.pi)
                cylinder('Cafe cup',(x+.25,y+.91,z),.07,.14,'ivory')
            solid('Cafe service counter',(13.4,y+.5,-27.7),(4.5,1,1.0),'sage',.09)
        elif floor=='2F':
            for ident,left,right,north in [('Seminar',14.8,20,-31.2),('Clay',24,30.4,-31.5)]:
                door_wall(ident+' entrance',left,right,-24,y,(left+right)/2,1.7)
                door_wall(ident+' screen wall',left,right,north,y)
                for x in (left,right):solid(ident+' side',(x,y+1.47,(north-24)/2),(.16,2.94,-24-north),'cream')
            table('council-table',16.3,y,-18.5,6.4,1.5)
            for i in range(5):
                x=13.8+i*1.2;chair('council-chair-n-'+str(i),x,y,-20.2,math.pi);chair('council-chair-s-'+str(i),x,y,-16.8,0)
            for ident,z in [('moss',-19.4),('clay',-27.8)]:
                table(ident+'-table',27,y,z,2.3,1.1)
                for i,(dx,dz,yaw) in enumerate([(-.65,1,0),(.65,1,0),(-.65,-1,math.pi),(.65,-1,math.pi)]):chair(ident+'-chair-'+str(i),27+dx,y,z+dz,yaw)
            for i in range(6):chair('seminar-chair-'+str(i),15.5+(i%3)*1.1,y,-27.5-(i//3)*1.2,0)
            for ident,rect,screen in [('council',[10.2,-22.5,22.8,-14.2],[19.6,y+1.9,-22.47]),('moss',[23.2,-22.5,30.4,-14.2],[29.1,y+1.9,-22.47]),('clay',[24,-31.5,30.4,-24],[27,y+1.9,-31.3]),('seminar',[14.8,-31.2,20,-24],[17,y+1.9,-31.0])]:rooms.append({'id':'office-2-'+ident,'meetingId':ident,'floor':floor,'rect':rect,'y':y,'screen':screen,'screenWidth':1.8 if ident=='moss' else 3.4})
        elif floor=='3F':
            for row,z in enumerate([-18,-27.9]):
                for col,x in enumerate([16,20,27]):
                    table('studio-'+floor+'-'+str(row)+'-'+str(col),x,y,z,2.3,1.05);chair('studio-chair-'+floor+'-'+str(row)+'-'+str(col),x,y,z+1,0)
                    box('Monitor stem',(x,y+.95,z-.2),(.12,.32,.1),'deep');box('Monitor',(x,y+1.24,z-.2),(.75,.46,.09),'deep',.055);box('Monitor inset',(x,y+1.24,z-.145),(.66,.37,.02),'water',.01)
            for x in [15.5,19.2,27]:shelf('Project archives '+floor,x,y,-37.1,2.4)
        elif floor=='4F':
            # Eight fixed rooms around a 2.2m gallery, with a separate eastern approach.
            for index in range(8):
                col=index%4;row=index//4;left=10.35+col*4.15;right=left+4.10;x=(left+right)/2
                near=-18.0 if row==0 else -20.2;far=-14.18 if row==0 else -24.0;center=(near+far)/2
                door_wall('Personal gallery wall',left,right,near,y,x,1.4)
                for edge in (left,right):solid('Personal room side',(edge,y+1.47,center),(.12,2.94,abs(far-near)),'cream')
                if row:solid('Personal room back',(x,y+1.47,far),(4.1,2.94,.14),'cream')
                shelf_start=set(scene.objects);collision_start=len(collisions);sx=left+.28;sz=center
                shelf('Personal archive',sx,y,sz,1.2)
                for ob in set(scene.objects)-shelf_start:
                    dx=ob.location.x-sx;dy=ob.location.y+sz;ob.location.x=sx-dy;ob.location.y=-sz+dx;ob.rotation_euler.z+=math.pi/2
                for shape in collisions[collision_start:]:
                    px,py,pz=shape['position'];shape['position']=[sx+pz-sz,py,sz-(px-sx)];a,b,c=shape['size'];shape['size']=[c,b,a]
                personal_slots.append({'id':'office-'+str(index+1),'index':index,'floor':'4F','rect':[left,min(near,far),right,max(near,far)],'center':[x,y,center],'door':[x-.7,y,near],'outYaw':0 if row else math.pi})
            for x in [16.0,19.5,27.5]:shelf('Quiet library archive',x,y,-37.1,2.4)
            table('consultation-table',17,y,-28,2.3,1.1);chair('consultation-chair-a',17,y,-26.95,0);chair('consultation-chair-b',17,y,-29.05,math.pi)
            bench('Quiet library reading',28.3,y,-26.5,2.6)
        elif floor=='5F':
            door_wall('Broadcast entrance',24.2,30.4,-24,y,27.3,1.7)
            door_wall('Broadcast back',24.2,30.4,-31.3,y)
            for xx in (24.2,30.4):solid('Broadcast side',(xx,y+1.47,-27.65),(.16,2.94,7.3),'cream')
            table('operations-table',16.3,y,-18.5,4.8,1.5)
            for i in range(4):chair('operations-chair-'+str(i),14.5+i*1.2,y,-16.9,0)
            table('broadcast-campus',27,y,-27.4,3,1.1);table('cctv-console',13,y,-20.4,3.0,1.1)
            for x in [12.2,13.4]:box('CCTV monitor',(x,y+1.2,-20.7),(1,.7,.12),'ink',.05)
            fixtures.append({'id':'campus-cctv','kind':'cctv','floor':floor,'position':[13,y+1.2,-20.4],'size':[2,.8,.6]})
        elif floor=='6F':
            for x,z in [(15,-18),(19,-18),(27,-18),(16,-28),(27,-28)]:
                table('dining-sky-'+str(x)+'-'+str(z),x,y,z,2.1,1.05);chair('sky-seat-a-'+str(x)+'-'+str(z),x,y,z+1,0);chair('sky-seat-b-'+str(x)+'-'+str(z),x,y,z-1,math.pi)
            for ident,kind,x,z in [('fridge','fridge',15.3,-36.9),('cooker','cooker',17,-36.9),('sink','sink',18.6,-36.9),('counter','counter',29,-36.9),('plate','plate',29,-36.9)]:
                furniture.append({'id':'sky-kitchen-'+ident,'kind':kind,'p':[x,y+(1.03 if kind=='plate' else 0),z],'yaw':0,'state':{},'floor':floor})
            for x in [16,20,28]:plant('Sky planting',x,y,-24.3,1.1)
        # Pendant bodies emit softly; runtime lights are separately switchable.
        for x,z in [(16,-18),(27,-18),(23,-29)]:
            cylinder('Pendant cord',(x,y+3.07,z),.016,.54,'ink');ellipsoid('Ceramic pendant',(x,y+2.79,z),(.32,.14,.32),'ochre');ellipsoid('Pendant diffuser',(x,y+2.74,z),(.26,.045,.26),'light')
    else:
        for x in (10,36):solid('Roof parapet',(x,y+.58,-27.2),(.3,1.16,21.6),'cream',.06)
        for z in (-38,-16.4):solid('Roof parapet',(23,y+.58,z),(26,1.16,.3),'cream',.06)
        for x,z in [(16,-18),(23,-18),(28,-26),(17,-28),(29,-36)]:plant('Roof tree',x,y,z,1.7)
        for x,z in [(16,-22),(25,-18),(27,-30)]:bench('Garden bench',x,y,z,2.6)
        for x in [18,28]:
            for z in [-23,-17.5]:solid('Pergola column',(x,y+1.45,z),(.2,2.9,.2),'wood')
        for z in [-23,-22,-21,-20,-19,-18,-17.5]:box('Pergola beam',(23,y+2.9,z),(10.4,.2,.14),'wood')
        restroom(y)
        solid('Roof WC enclosure',(35.85,y+1.5,-33.2),(.25,3,9.6),'cream')
        solid('Roof WC back',(33.2,y+1.5,-37.9),(5.3,3,.2),'cream')
        solid('Roof WC cap',(33.2,y+3,-33.2),(5.6,.2,9.8),'clay')
        for l in lifts:
            solid('Roof lift back',(l['x'],y+1.65,-36.4),(l['width']+.4,3.3,.2),'cream')
            for side in [-1,1]:solid('Roof lift side',(l['x']+side*(l['width']/2+.1),y+1.65,-34.8),(.2,3.3,3.2),'cream')
            solid('Roof lift cap',(l['x'],y+3.3,-34.8),(l['width']+.6,.2,3.5),'clay')
            fixtures.append({'id':'lift-call-'+l['id']+'-'+floor,'kind':'lift-call','liftId':l['id'],'floor':floor,'position':[l['x']+l['width']/2+.3,y+1.2,-33.04],'size':[.24,.46,.16]})
    if floor!='B1':
        for h in holes[:2]:
            solid('Stair well guard back',((h[0]+h[2])/2,y+.57,h[1]),(h[2]-h[0],1.14,.12),'deep')
            for x in (h[0],h[2]):solid('Stair well side guard',(x,y+.57,(h[1]+h[3]-.6)/2),(.12,1.14,h[3]-h[1]-.6),'deep')
    floor_objects[floor]=list(set(scene.objects)-before)

# Street edge: human scale, awnings and a shaded café approach.
current_floor='site';before=set(scene.objects)
for x in [13,17,21,25,29,33]:
    for z in [-12.5,-10.9]:box('Paving tile',(x,-.055,z),(3.92,.1,1.54),'stone',.03)
for i in range(12):box('Striped cafe awning',(12+i*.62,2.78,-12.9),(.63,.16,2.0),'clay' if i%2 else 'ivory',.04)
for x,z in [(10,-10),(36,-10),(8,-26),(39,-26),(38,-35)]:
    plant('Street tree',x,0,z,2.2);cylinder('Streetlamp',(x+1.2,1.45,z),.06,2.9,'deep');ellipsoid('Lantern globe',(x+1.2,2.88,z),(.21,.30,.21),'light')
for x,z in [(13,-11),(31,-11)]:bench('Street bench',x,0,z,2.5)
floor_objects['site']=list(set(scene.objects)-before)

formats=[]
for cls in io_scene_gltf2.ExportGLTF2.__mro__:
    prop=getattr(cls,'__annotations__',{}).get('export_format')
    if prop:
        items=prop.keywords['items'];formats=items(None,bpy.context) if callable(items) else items
fmt=next(i[0] for i in formats if '.glb' in i[1])
registry=[]
for floor,objects in floor_objects.items():
    for ob in scene.objects:ob.select_set(False)
    # Merge each material per storey to keep real WebGL draw calls bounded.
    for key in palette:
        for exterior in [False,True]:
            group=[o for o in scene.objects if o.get('v6_floor')==floor and bool(o.get('v6_shell'))==exterior and o.type=='MESH' and o.data.materials and o.data.materials[0]==mat(key)]
            if not group:continue
            for ob in scene.objects:ob.select_set(False)
            for ob in group:ob.select_set(True)
            bpy.context.view_layer.objects.active=group[0]
            if len(group)>1:bpy.ops.object.join()
            bpy.context.object.name=('Shell_' if exterior else 'Inside_')+key+'_'+floor
    survivors=[o for o in scene.objects if o.get('v6_floor')==floor]
    for ob in scene.objects:ob.select_set(False)
    for ob in survivors:ob.select_set(True)
    bpy.context.view_layer.objects.active=survivors[0]
    target=OUT/('campus-'+floor+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(target),export_format=fmt,use_selection=True,use_active_scene=True,export_animations=False)
    registry.append({'assetId':'campus-'+floor,'source':'Original project-authored geometry; visual reference only, no reference pixels redistributed','cost':0,'publicSourceRedistribution':True,'path':target.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size,'triangles':sum(len(o.data.polygons)*2 for o in survivors),'materials':len(survivors),'unitScale':1})

manifest={'version':6,'units':'metres; Godot Y up','buildingId':'office','bounds':[10,-38,36,-14],'floorHeight':3.6,'floors':[{'id':i,'y':y,'title':t,'asset':'res://assets/v6/campus-'+i+'.glb'} for i,y,t in floor_specs],'lifts':lifts,'stairHoles':holes[:2],'collisions':collisions,'furniture':furniture,'fixtures':fixtures,'rooms':rooms,'personalSlots':personal_slots,'assets':registry}
(OUT/'campus.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/campus-v6.blend'),copy=True)
print(json.dumps({'scene':SCENE,'objects':len(scene.objects),'floors':len(floor_specs),'collisions':len(collisions),'furniture':len(furniture),'assets':registry},ensure_ascii=False))
