"""Derive regulation-scale ring geometry and matching colliders, preserving V2 inputs."""
from pathlib import Path
import json,struct,math,hashlib
import numpy as np
R=Path(__file__).resolve().parents[1]
source=R/'assets/v2/grounds.glb'
raw=source.read_bytes();jsize,jkind=struct.unpack_from('<II',raw,12)
doc=json.loads(raw[20:20+jsize]);offset=20+jsize
bsize,bkind=struct.unpack_from('<II',raw,offset);data=bytearray(raw[offset+8:offset+8+bsize])
centers=[(-16.35,30),(4.35,30)];ratio=.245/.43;changed=0
accessors={p['attributes']['POSITION'] for mesh in doc['meshes'] for p in mesh['primitives']}
for aid in accessors:
 a=doc['accessors'][aid];v=doc['bufferViews'][a['bufferView']]
 assert a['componentType']==5126 and a['type']=='VEC3'
 points=np.ndarray((a['count'],3),dtype='<f4',buffer=data,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',12),4))
 for cx,cz in centers:
  for pt in points:
   x,y,z=map(float,pt);dx=x-cx;dz=z-cz;r=math.hypot(dx,dz)
   if abs(y-3.05)<.019 and abs(r-.43)<.04:
    theta=round(math.atan2(dz,dx)/(math.tau/24))*math.tau/24
    c,s=math.cos(theta),math.sin(theta)
    radial=dx*c+dz*s-.43;tangent=(-dx*s+dz*c)*ratio
    pt[0]=cx+c*(.245+radial)-s*tangent;pt[2]=cz+s*(.245+radial)+c*tangent;changed+=1
   elif 2.69<y<3.05 and abs(r-.344)<.01:
    theta=round(math.atan2(dz,dx)/(math.tau/12))*math.tau/12
    pt[0]-=math.cos(theta)*(.344-.196);pt[2]-=math.sin(theta)*(.344-.196);changed+=1
 a['min']=points.min(axis=0).tolist();a['max']=points.max(axis=0).tolist()
# Replace the old rigid visual cords with runtime diamond nets that react to contact.
removed_net_triangles=0
for mesh in doc['meshes']:
 for p in mesh['primitives']:
  a=doc['accessors'][p['attributes']['POSITION']];v=doc['bufferViews'][a['bufferView']]
  pts=np.ndarray((a['count'],3),dtype='<f4',buffer=data,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',12),4))
  ia=doc['accessors'][p['indices']];iv=doc['bufferViews'][ia['bufferView']]
  indices=np.frombuffer(data,dtype={5123:'<u2',5125:'<u4'}[ia['componentType']],count=ia['count'],offset=iv.get('byteOffset',0)+ia.get('byteOffset',0))
  tris=indices.copy().reshape(-1,3);tri=pts[tris];remove=np.zeros(len(tris),dtype=bool)
  for cx,cz in centers:
   r=np.sqrt((tri[:,:,0]-cx)**2+(tri[:,:,2]-cz)**2)
   remove|=np.all((tri[:,:,1]>2.69)&(tri[:,:,1]<3.05)&(r>.185)&(r<.207),axis=1)
  if remove.any():
   keep=tris[~remove].ravel();removed_net_triangles+=int(remove.sum());indices[:len(keep)]=keep;ia['count']=len(keep);ia['min']=[int(keep.min())];ia['max']=[int(keep.max())]
assert removed_net_triangles==480,removed_net_triangles
j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
out=struct.pack('<III',0x46546c67,2,12+8+len(j)+8+len(data))+struct.pack('<II',len(j),jkind)+j+struct.pack('<II',len(data),bkind)+data
target=source.with_name('grounds-v3.glb');target.write_bytes(out)
manifest=json.loads((R/'assets/v2/manifest.json').read_text(encoding='utf-8'));collisions=manifest['assets']['grounds']['collisions'];count=0
for box in collisions:
 if 'position' not in box:continue
 x,y,z=box['position']
 for cx,cz in centers:
  dx=x-cx;dz=z-cz
  if abs(y-3.05)<.001 and abs(math.hypot(dx,dz)-.43)<.001:
   box['position']=[cx+dx*ratio,y,cz+dz*ratio];box['size'][2]*=ratio;count+=1;break
assert count==48 and changed>500,(count,changed)
(R/'assets/v2/grounds-collisions-v3.json').write_text(json.dumps(collisions,separators=(',',':')),encoding='utf-8')
e={'sourceSHA256':hashlib.sha256(raw).hexdigest(),'outputSHA256':hashlib.sha256(out).hexdigest(),'changedVertices':changed,'rimColliders':count,'replacedStaticNetTriangles':removed_net_triangles,'centrelineRadius':.245,'radialThickness':.04,'innerRadius':.225,'basketballRadius':.12}
(R/'evidence/v3/court-rim-repair.json').write_text(json.dumps(e,indent=2),encoding='utf-8');print(json.dumps(e))
