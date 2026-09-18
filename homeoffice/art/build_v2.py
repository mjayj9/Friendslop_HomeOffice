"""BlenderMCP production script. Separate V2 scene; never modifies previous scenes."""
import bpy,json,math,random
from pathlib import Path
from mathutils import Vector
R=Path(__import__('os').environ.get('MOYEO_PROJECT', str(Path(bpy.data.filepath).parent.parent)));OUT=R/'assets/v2';L=json.loads((OUT/'layout.json').read_text(encoding='utf8'))
scene=bpy.data.scenes.new('Moyeo_V2_Production');bpy.context.window.scene=scene;scene.unit_settings.system='METRIC'
M={};random.seed(42)
palette={'plaster':(.80,.79,.71),'sage':(.30,.43,.36),'oak':(.53,.35,.20),'oak2':(.56,.38,.23),'walnut':(.24,.14,.085),'stone':(.56,.55,.49),'tile':(.69,.73,.68),'carpet':(.35,.45,.42),'concrete':(.44,.48,.46),'rubber':(.21,.27,.31),'deck':(.43,.28,.17),'court_blue':(.18,.34,.43),'court_green':(.23,.40,.27),'grass':(.30,.43,.22),'white':(.9,.90,.82),'metal':(.055,.075,.07),'brass':(.57,.37,.12),'glass':(.46,.68,.70),'orange':(.79,.34,.14),'blue':(.16,.29,.43),'cloth':(.62,.62,.50),'dark':(.03,.045,.045),'leaf':(.19,.34,.18),'bark':(.27,.17,.1),'red':(.60,.18,.12),'screen':(.11,.24,.28)}
for name,c in palette.items():
 m=bpy.data.materials.new('V2_'+name);m.diffuse_color=(*c,.22 if name=='glass' else 1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,.22 if name=='glass' else 1);p.inputs['Roughness'].default_value=.25 if name in ['metal','brass','glass'] else .8;p.inputs['Metallic'].default_value=.65 if name in ['metal','brass'] else 0
 if name=='glass':p.inputs['Alpha'].default_value=.22;m.surface_render_method='DITHERED'
 M[name]=m
exec(compile((R/'art/materials_v2.py').read_text(encoding='utf8'),'materials_v2.py','exec'))
apply_materials(palette,M,R)
groups={};collisions=[];ASSETS={};current='';objects=[]
def begin(name):
 global groups,collisions,current,objects
 groups={};collisions=[];objects=[];current=name
def poly(mat,verts,faces):
 v,f=groups.setdefault(mat,([],[]));offset=len(v);v.extend([(p[0],-p[2],p[1]) for p in verts]);f.extend([tuple(offset+i for i in face) for face in faces])
def box(name,p,s,mat='plaster',solid=False,rot=0):
 x,y,z=p;a,b,c=[i/2 for i in s];co=math.cos(rot);si=math.sin(rot)
 pts=[(xx,yy,zz) for xx,yy,zz in [(-a,-b,-c),(a,-b,-c),(a,b,-c),(-a,b,-c),(-a,-b,c),(a,-b,c),(a,b,c),(-a,b,c)]]
 poly(mat,[(x+xx*co+zz*si,y+yy,z-xx*si+zz*co) for xx,yy,zz in pts],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)])
 if solid:collisions.append(dict(position=p,size=s,yaw=rot))
def cyl(name,p,r,h,mat='metal',n=12):
 pts=[(p[0]+r*math.cos(i*math.tau/n),p[1]+yy*h/2,p[2]+r*math.sin(i*math.tau/n)) for yy in [-1,1] for i in range(n)]
 faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)];poly(mat,pts,faces)
def sphere(p,r,mat='leaf',n=12,m=6):
 pts=[(p[0]+r[0]*math.cos(j*math.pi/m)*math.cos(i*math.tau/n),p[1]+r[1]*math.sin(j*math.pi/m),p[2]+r[2]*math.cos(j*math.pi/m)*math.sin(i*math.tau/n)) for j in range(-m//2,m//2+1) for i in range(n)]
 poly(mat,pts,[(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(m) for i in range(n)])
def rail(a,b,y=0):
 dx=b[0]-a[0];dz=b[1]-a[1];length=math.hypot(dx,dz);angle=-math.atan2(dz,dx)
 for i in range(math.ceil(length/.28)+1):
  t=i/math.ceil(length/.28);cyl('baluster',(a[0]+dx*t,y+.55,a[1]+dz*t),.019,1.1,'metal',8)
 box('handrail',[(a[0]+b[0])/2,y+1.1,(a[1]+b[1])/2],[length,.07,.09],'walnut',True,angle)
 # continuous invisible barrier keeps characters from passing between bars
 collisions.append(dict(position=[(a[0]+b[0])/2,y+.52,(a[1]+b[1])/2],size=[length,1.04,.09],yaw=angle))
def shelf(x,y,z,w=2):
 box('cabinet',[x,y+.45,z],[w,.9,.40],'walnut',True)
 for yy in [.95,1.5,2.05]:box('shelf',[x,y+yy,z],[w,.05,.42],'oak')
 for xx in [-w/2,w/2]:box('upright',[x+xx,y+1.08,z],[.06,2.15,.42],'oak')
 for i in range(int(w/.12)-1):
  xx=x-w/2+.13+i*.12;hh=random.uniform(.24,.39);box('book',[xx,y+1.53+hh/2,z],[.065,hh,.26],['sage','orange','blue','cloth'][i%4])
def plant(x,y,z,r=.3):
 cyl('pot',[x,y+.18,z],r*.6,.36,'stone');cyl('stem',[x,y+.7,z],.025,1,'bark')
 for i in range(6):sphere([x+math.cos(i)*r*.5,y+.7+i*.1,z+math.sin(i)*r*.5],[r*.55,.24,r*.55])
def gap(at,width=1.8,sill=0,height=2.5,kind='passage'):return dict(at=at,width=width,sill=sill,height=height,kind=kind)
def wall(data):
 a,b=data['a'],data['b'];x,z=a;dx=b[0]-x;dz=b[1]-z;length=math.hypot(dx,dz);horizontal=abs(dx)>abs(dz);y=data['y'];h=data['height'];th=data['thickness'];mat=data['material']
 def segment(start,end,bottom,top,material=mat,solid=True):
  if end-start<.005 or top-bottom<.005:return
  mid=(start+end)/2;p=[x+mid if horizontal else x,y+(bottom+top)/2,z if horizontal else z+mid];s=[end-start if horizontal else th,top-bottom,th if horizontal else end-start];box('wall',p,s,material,solid)
 cursor=0
 for g in sorted(data['openings'],key=lambda a:a['at']):
  lo=g['at']-g['width']/2;hi=g['at']+g['width']/2;segment(cursor,lo,0,h);segment(lo,hi,0,g['sill']);segment(lo,hi,g['sill']+g['height'],h);cursor=hi
  frame=.055
  for u in [lo,hi]:
   pos=[x+u if horizontal else x,y+g['sill']+g['height']/2,z if horizontal else z+u];box('jamb',pos,[frame if horizontal else th+.06,g['height'],th+.06 if horizontal else frame],'walnut')
  for v in ([g['sill'],g['sill']+g['height']] if g['kind']=='window' else [g['height']]):
   pos=[x+g['at'] if horizontal else x,y+v,z if horizontal else z+g['at']];box('frame',pos,[g['width'] if horizontal else th+.06,.055,th+.06 if horizontal else g['width']],'walnut')
  if g['kind']=='window':
   pos=[x+g['at'] if horizontal else x,y+g['sill']+g['height']/2,z if horizontal else z+g['at']];box('glazing',pos,[g['width'] if horizontal else .025,g['height'],.025 if horizontal else g['width']],'glass',True)
   if g['width']>2.5:box('mullion',pos,[.04 if horizontal else .08,g['height'],.08 if horizontal else .04],'walnut')
  # trim follows actual opening edges; it never fills a passage
 segment(cursor,length,0,h)
 for lo,hi in zip([0]+[g['at']+g['width']/2 for g in sorted(data['openings'],key=lambda a:a['at'])],[g['at']-g['width']/2 for g in sorted(data['openings'],key=lambda a:a['at'])]+[length]):
  mid=(lo+hi)/2;box('skirting',[x+mid if horizontal else x,y+.07,z if horizontal else z+mid],[max(.01,hi-lo) if horizontal else th+.04,.14,th+.04 if horizontal else max(.01,hi-lo)],'oak')
def rectslab(r,y,mat,solid=True,th=.16):a,b,c,d=r;box('slab',[(a+c)/2,y-th/2,(b+d)/2],[c-a,th,d-b],mat,solid)
def cut_rect(r,hole):
 a,b,c,d=r;u,v,w,t=hole;return [[a,b,c,v],[a,t,c,d],[a,v,u,t],[w,v,c,t]]
def finish(name,anchors={},bevel=0):
 global objects
 col=bpy.data.collections.new('V2_'+name);scene.collection.children.link(col)
 for mat,(vertices,faces) in groups.items():
  mesh=bpy.data.meshes.new('V2_'+name+'_'+mat);mesh.from_pydata(vertices,[],faces);mesh.update();world_uv(mesh);o=bpy.data.objects.new(mesh.name,mesh);col.objects.link(o);o.data.materials.append(M[mat]);objects.append(o)
  if bevel:
   mod=o.modifiers.new('Crafted edges','BEVEL');mod.width=bevel;mod.segments=2;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 for n,p in anchors.items():
  o=bpy.data.objects.new(n,None);col.objects.link(o);o.location=(p[0],-p[2],p[1]);objects.append(o)
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 if objects:bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,use_active_scene=True,export_format='GLB',export_apply=True,export_extras=True)
 ASSETS[name]=dict(assetId=name,version=2,collisions=collisions.copy(),anchors=anchors,meshTriangles=sum(sum(len(f)-2 for f in faces) for verts,faces in groups.values()))
 col.hide_render=True;col.hide_viewport=True
 return col

begin('house')
for r in L['rooms']:
 a,b,c,d=r['rect'];y=r['y'];floorparts=cut_rect(r['rect'],[-4.95,5.5,-1.45,10.4]) if r['id']=='upper_hall' else [r['rect']]
 for rr in floorparts:rectslab(rr,y,r['finish'])
 if r['ceiling']:
  parts=cut_rect(r['rect'],[-4.95,5.5,-1.45,10.4]) if r['id']=='hall' else [r['rect']]
  for rr in parts:rectslab(rr,y+3.4,'plaster',True,.10)
 # Sparse plank seams, not an oversized grid; preserve grain direction.
 if r['finish'] in ['oak','deck']:
  for zi in range(int((d-b)/.22)):
   zz=b+zi*.22
   if r['id']=='upper_hall' and 5.5<zz<10.4:continue
   box('plank seam',[(a+c)/2,y+.002,zz],[c-a,.002,.006],'oak2')
for w in L['walls']:wall(w)
# Upper roof, capped parapets and deep eaves make a coherent two-storey silhouette.
rectslab([-15.4,-12.4,1.8,12.4],7.03,'metal',False,.16)
for a,b in [([-15.3,-12.3],[1.7,-12.3]),([-15.3,12.3],[1.7,12.3])]:
 box('roof fascia',[(a[0]+b[0])/2,6.94,a[1]],[b[0]-a[0],.25,.12],'walnut')
for a,b in [([15,-12],[15,12]),([1.5,12],[15,12]),([1.5,-12],[15,-12])]:rail(a,b,3.6)
rectslab([19.6,-6.4,36.4,6.4],3.52,'metal',False,.16)
# U stair: visual treads, continuous convex physics ramps and real 1.5 m landing.
for side in range(2):
 xc=-4.15+side*1.8
 for i in range(10):
  yy=(i+1)*.18+side*1.8;zz=10.05-i*.3 if side==0 else 7.35+i*.3
  box('stair tread',[xc,yy-.05,zz],[1.5,.1,.3],'oak');box('riser',[xc,yy-.14,zz+.145 if side==0 else zz-.145],[1.5,.18,.035],'walnut')
 # Ramp shape uses points in Godot coordinates, separate from visible steps.
 za,zb=(10.2,7.2) if side==0 else (7.2,10.2);y0=side*1.8;y1=(side+1)*1.8
 collisions.append(dict(points=[[xc-.75,y0-.15,za],[xc+.75,y0-.15,za],[xc-.75,y0+.02,za],[xc+.75,y0+.02,za],[xc-.75,y1,zb],[xc+.75,y1,zb],[xc-.75,y1-.2,zb],[xc+.75,y1-.2,zb]]))
 for i in range(10):
  yy=(i+1)*.18+side*1.8;zz=10.05-i*.3 if side==0 else 7.35+i*.3
  cyl('stair baluster',[xc+(.75 if side else -.75),yy+.52,zz],.02,1.04,'metal',8)
 # Inclined handrail mesh (not a horizontal barrier across the flight).
 poly('walnut',[(xc+(.75 if side else -.75)+dx,yy,zz) for zz,yy in [(za,y0+1.08),(zb,y1+1.08)] for dx in [-.04,.04] for yy in [yy-.04,yy+.04]],[(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3),(0,1,3,2),(4,6,7,5)])
for side in range(2):
 xc=-4.15+side*1.8;za,zb=(10.2,7.2) if side==0 else (7.2,10.2);y0=side*1.8;y1=(side+1)*1.8
 poly('walnut',[(xc+dx,yy,zz) for zz,yy in [(za,y0-.10),(zb,y1-.10)] for dx in [-.74,.74] for yy in [yy-.14,yy]],[(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3),(0,1,3,2),(4,6,7,5)])
for z in [-8,-2,4,10]:
 box('hall beam',[-1.8,3.15,z],[6.4,.18,.14],'oak')
 cyl('hall light',[-.05,2.9,z],.20,.09,'white')
rectslab([-4.9,5.7,-1.5,7.2],1.8,'oak',True,.18)
rail([-4.96,5.5],[-1.45,5.5],3.6);rail([-1.43,5.5],[-1.43,10.1],3.6)
box('stair guard west',[-4.94,2.2,7.8],[.10,4.4,4.8],'plaster',True)
# Furniture-like architectural fittings: entry cabinets, library, pantry, kitchen cabinetry.
shelf(-3.9,0,-9.8,1.5);shelf(13.6,0,10.7,2);shelf(-14.2,3.6,2.8,1.35);shelf(4,0,-10.8,2.5)
box('entry shoe cabinet',[-.6,.5,11.5],[1.4,1,.4],'oak',True)
for x in [-.9,-.4]:cyl('coat peg',[x,1.7,11.48],.035,.06,'brass')
box('entry mat',[-1.8,.006,10.9],[2.3,.012,1.3],'carpet')
box('living rug',[-10.5,.008,6.9],[6.2,.016,5.2],'cloth')
for x,z in [(-14,10.8),(-6.2,4.5),(13.8,5.5),(2.6,-4.8),(-6.2,3.5)]:plant(x,0,z)
for x in [-14,-12.7,-11.4,-10.1,-8.8,-7.5,-6.2]:
 box('pantry cabinet',[x,.85,-11.6],[1.18,1.7,.6],'oak',True)
 box('pantry recessed front',[x,.85,-11.28],[1.06,1.52,.035],'cloth')
 box('handle',[x+.4,.92,-11.23],[.025,.18,.025],'brass')
for x in [-13.7,-12.4,-11.1,-9.8,-8.5,-7.2]:
 box('upper kitchen cabinet',[x,2.35,-9.45],[1.18,.7,.5],'sage')
 box('under cabinet strip',[x,1.99,-9.32],[1.08,.016,.08],'white')
for x,z,y in [(-12,9.8,0),(6.5,8,0),(-10,0,0),(-10,-5.7,0),(-12,.5,3.6)]:
 cyl('pendant stem',[x,y+2.95,z],.016,.65,'metal');cyl('pendant shade',[x,y+2.64,z],.36,.18,'cloth');cyl('pendant diffuser',[x,y+2.54,z],.31,.02,'white')
# Bath fixtures are architectural amenities, not claimed simulation features.
for x,y,z in [(12,0,-10),(-12,3.6,9)]:
 box('bath basin plinth',[x,y+.42,z],[1.4,.84,.6],'oak',True);box('basin rim',[x,y+.86,z],[1.46,.06,.66],'white');box('mirror',[x,y+1.55,z-.31],[1.3,.85,.035],'glass')
 cyl('toilet base',[x+1.6,y+.25,z],.27,.5,'white');sphere([x+1.6,y+.51,z],[.3,.08,.4],'white')
 box('shower screen',[x-1.5,y+1.1,z-1.2],[.03,2.2,1.6],'glass',True)
# Living detail: original artwork, folded curtains, bookshelf and covered entry.
shelf(-13.3,0,3.3,2.3)
box('art frame',[-13.25,1.9,11.86],[1.7,1.12,.08],'walnut')
box('art paper',[-13.25,1.9,11.80],[1.55,.96,.025],'cloth')
sphere([-13.55,2.02,11.775],[.27,.27,.009],'orange',20,10)
box('art horizon',[-13.15,1.75,11.76],[1.2,.14,.015],'sage')
for z in [4.45,9.55]:
 for i in range(7):
  box('linen curtain',[-14.8+.06*math.sin(i*2),1.85,z+i*.085],[.065,2.45,.095],'cloth')
box('curtain track',[-14.8,3.1,7],[.10,.07,5.9],'metal')
rectslab([-3.6,12,0,14.2],2.95,'walnut',False,.12)
for x in [-3.45,-.15]:cyl('porch column',[x,1.43,14.05],.05,2.86,'metal')
for lo,hi in [(-4.7,-3.0),(-.6,1.2)]:
 for i in range(int((hi-lo)/.15)):
  box('entry timber slat',[lo+i*.15,1.42,12.13],[.085,2.84,.07],'oak')
finish('house')

begin('grounds')
rectslab(L['site'], -.17,'grass',True,.24)
rectslab([-250,-250,250,250],-.22,'grass',False,.02)
for rect in [[-3.2,12,0,22],[-15,18,41,21],[22,6,25,22],[-17,16,-14,24],[-2,-36,2,-12]]:rectslab(rect,-.02,'stone',True,.12)
for x,z in [(-19,-10),(-18,8),(-19,19),(40,-7),(40,10),(5,45),(40,46),(-18,45),(-10,-35),(10,-35)]:
 cyl('tree trunk',[x,1.9,z],.16,3.8,'bark');sphere([x,3.8,z],[1.8,1.7,1.7]);sphere([x+.8,4.2,z+.4],[1.3,1.4,1.3])
for x in range(-20,43,3):box('garden border',[x,.22,47],[2.8,.6,.8],'leaf')
for x,z in [(-12,17.4),(4,17.4),(30,17.4)]:
 box('bench',[x,.47,z],[2.2,.12,.5],'oak',True)
 for xx in [-.8,.8]:box('bench support',[x+xx,.22,z],[.09,.44,.4],'metal',True)
# Lines and real open rims. Basketball played along X; football along X.
for r in ['basketball','football']:
 a,b,c,d=next(q['rect'] for q in L['rooms'] if q['id']==r);mat='white'
 for z in [b+.1,d-.1]:box('sideline',[(a+c)/2,.007,z],[c-a,.012,.065],mat)
 for x in [a+.1,c-.1,(a+c)/2]:box('end/centre line',[x,.007,(b+d)/2],[.065,.012,d-b],mat)
 cx=(a+c)/2;cz=(b+d)/2;radius=1.9 if r=='basketball' else 3
 for i in range(64):
  t=i*math.tau/64;box('circle',[cx+math.cos(t)*radius,.008,cz+math.sin(t)*radius],[.065,.012,math.tau*radius/64],mat,False,-t)
for x,sign in [(-17,1),(5,-1)]:
 z=30;cyl('basket stanchion',[x-sign*.6,1.75,z],.09,3.5,'metal');box('backboard',[x,3.38,z],[.075,1.05,1.8],'white',True)
 box('board inset',[x+sign*.044,3.25,z],[.018,.46,.64],'orange')
 cx=x+sign*.65;cy=3.05;radius=.43
 for i in range(24):
  t=i*math.tau/24;box('open rim segment',[cx+math.cos(t)*radius,cy,z+math.sin(t)*radius],[.04,.035,math.tau*radius/24],'orange',True,-t)
 for i in range(12):
  t=i*math.tau/12;cyl('net cord',[cx+math.cos(t)*radius*.8,cy-.18,z+math.sin(t)*radius*.8],.006,.35,'white',6)
for x in [10,40]:
 for z in [29,35]:cyl('goal post',[x,1.2,z],.055,2.4,'white');collisions.append(dict(position=[x,1.2,z],size=[.12,2.4,.12],yaw=0))
 box('crossbar',[x,2.4,32],[.12,.12,6],'white',True)
 back=x+(-1.3 if x<20 else 1.3)
 for z in [29+i*.3 for i in range(21)]:cyl('net',[back,1.2,z],.006,2.4,'white',6)
 for y in [.3,.6,.9,1.2,1.5,1.8,2.1]:box('net horizontal',[back,y,32],[.015,.015,6],'white')
finish('grounds')

# Append-only upper gallery module. Coordinates are local to its southern edge.
begin('gallery')
rectslab([-1.4,-5.4,1.4,0],0,'oak');rectslab([-1.4,-5.4,1.4,0],3.4,'plaster');rectslab([-1.5,-5.5,1.5,.05],3.52,'metal',False)
for x in [-1.4,1.4]:wall(dict(a=[x,-5.4],b=[x,0],y=0,height=3.3,thickness=.16,openings=[gap(2.7,1.6)],material='plaster'))
finish('gallery')
for side in [-1,1]:
 begin('office_left' if side<0 else 'office_right');rect=[-6.2,-5.4,-1.4,0] if side<0 else [1.4,-5.4,6.2,0];a,b,c,d=rect
 rectslab(rect,0,'oak');rectslab(rect,3.4,'plaster');rectslab([a-.05,b-.05,c+.05,d+.05],3.52,'metal',False)
 for aa,bb,op in [([a,b],[c,b],[]),([a,d],[c,d],[]),([a if side<0 else c,b],[a if side<0 else c,d],[gap(2.7,3.2,.75,1.95,'window')])]:wall(dict(a=aa,b=bb,y=0,height=3.3,thickness=.16,openings=op,material='plaster'))
 shelf((a+c)/2,0,-.35,2.4);plant(a+.55,0,-4.7,.24)
 for x in [a+.15,c-.15]:cyl('support',[x,-1.8,-5.15],.09,3.6,'metal')
 finish(current)

# New authored catalog assets. Each mesh has purposeful shape and separate colliders/anchors.
begin('low_table');box('top',[0,.42,0],[1.65,.08,.8],'oak',True)
for x in [-.65,.65]:
 for z in [-.26,.26]:
  cyl('leg',[x,.2,z],.045,.4,'walnut')
  collisions.append(dict(position=[x,.2,z],size=[.09,.4,.09],yaw=0))
finish('low_table',{'work_surface':[0,.47,0],'grip_left':[-.28,.4,.36],'grip_right':[.28,.4,.36]},.015)
begin('bed');box('bed frame',[0,.25,0],[1.15,.3,2.1],'oak',True);box('mattress',[0,.5,0],[1.1,.24,2.04],'cloth',True);box('headboard',[0,.72,-1.04],[1.19,1.1,.1],'walnut',True);box('duvet',[0,.645,.28],[1.08,.1,1.42],'sage');box('pillow',[0,.67,-.65],[.78,.15,.43],'white')
finish('bed',{'lie':[0,.69,0],'stand':[.9,0,.25]},.055)
for kind in ['counter','cooker','sink','fridge']:
 begin(kind);height=2 if kind=='fridge' else .95;box('cabinet',[0,height/2,0],[1.2,height,.75],'white' if kind=='fridge' else 'sage',True)
 if kind!='fridge':box('stone top',[0,.98,0],[1.28,.06,.82],'stone',True)
 for x in [-.29,.29]:box('inset front',[x,height/2,.385],[.54,height-.12,.025],'cloth');box('pull',[x+.15,height*.68,.415],[.022,.16,.025],'brass')
 if kind=='cooker':
  for x in [-.3,.3]:
   for z in [-.2,.2]:cyl('burner',[x,1.017,z],.13,.02,'dark',16)
  box('oven glass',[0,.45,.403],[.9,.48,.035],'dark')
 if kind=='sink':
  box('basin inset',[0,1.016,0],[.72,.02,.48],'metal');cyl('tap',[0,1.2,-.25],.023,.38,'brass');box('spout',[0,1.38,-.14],[.045,.035,.25],'brass')
 if kind=='fridge':box('freezer divider',[0,1.4,.40],[1.08,.018,.025],'metal')
 finish(kind,{'work_surface':[0,1.04,0],'handle':[.45,height*.68,.42]},.018)
begin('plate');cyl('plate rim',[0,0,0],.20,.035,'white',32);cyl('dish inset',[0,.02,0],.16,.008,'cloth',32);finish('plate',{'grip':[0,0,0],'food':[0,.06,0]},.005)
begin('pan');cyl('pan',[0,0,0],.21,.09,'metal',24);cyl('inside',[0,.05,0],.18,.012,'dark',24);box('handle',[.31,0,0],[.25,.045,.065],'walnut');finish('pan',{'grip':[.4,0,0]},.009)
for kind,r,col in [('basketball',.24,'orange'),('football',.22,'white'),('ingredient',.13,'red'),('meal',.13,'orange')]:
 begin(kind);sphere([0,0,0],[r,r,r],col,16,8)
 if kind=='basketball':
  for i in range(32):
   t=i*math.tau/32;box('ball seam',[math.cos(t)*r,math.sin(t)*r,0],[.018,.035,.012],'dark',False,-t)
 if kind=='football':
  for i in range(6):t=i*math.tau/6;sphere([math.cos(t)*.185,0,math.sin(t)*.185],[.055,.06,.055],'dark',6,4)
 finish(kind,{'grip':[0,0,0]})
begin('gun');box('toy receiver',[0,0,0],[.11,.14,.30],'blue');box('orange muzzle',[0,.01,-.21],[.12,.12,.12],'orange');box('grip',[0,-.12,.05],[.075,.2,.09],'dark');box('sight',[0,.09,-.03],[.025,.035,.07],'white');finish('gun',{'grip':[0,-.12,.05],'muzzle':[0,.01,-.27]},.012)
begin('shield');box('padded shield',[0,0,0],[.64,.86,.08],'blue');box('rim',[0,0,.05],[.69,.91,.025],'orange');box('handle',[0,0,.14],[.04,.3,.05],'metal');finish('shield',{'grip':[0,0,.15]},.05)
begin('arcade');box('base',[0,.45,0],[.72,.9,.72],'walnut',True);box('screen case',[0,1.29,.14],[.78,.79,.35],'blue',True);box('screen',[0,1.29,-.045],[.65,.49,.015],'screen');box('marquee',[0,1.81,.1],[.79,.2,.41],'orange');box('control deck',[0,.94,-.2],[.77,.12,.58],'metal');cyl('joystick',[ -.18,1.08,-.31],.025,.2,'metal');sphere([-.18,1.18,-.31],[.07,.07,.07],'red');
for x in [.08,.24]:cyl('button',[x,1.02,-.30],.04,.035,'white')
finish('arcade',{'screen':[0,1.29,-.06],'stand':[0,0,-1]},.025)
begin('wide_door');box('door stile',[.55,1.23,0],[1.1,2.46,.09],'oak',True);box('inset',[.55,1.35,-.052],[.9,1.75,.025],'sage');box('lever',[.88,1,-.11],[.21,.04,.045],'brass');finish('wide_door',{'hinge':[0,0,0],'handle':[.88,1,-.11]},.013)
(OUT/'manifest.json').write_text(json.dumps({'version':2,'assets':ASSETS},ensure_ascii=False,indent=2),encoding='utf8')
# Keep an inspectable composition in the source, including all static architecture.
for c in scene.collection.children:
 if c.name.split('.')[0] in ['V2_house','V2_grounds']:c.hide_viewport=False;c.hide_render=False
scene.world=bpy.data.worlds.new('V2_daylight');scene.world.color=(.35,.4,.45)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art'/'moyeo-v2.blend'))
print('V2_ASSETS_DONE',len(ASSETS),'assets',sum(a['meshTriangles'] for a in ASSETS.values()),'base triangles')
