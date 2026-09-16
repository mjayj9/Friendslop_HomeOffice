"""Remove only obsolete V2 bathroom fittings; preserve the original GLB and all other triangles."""
from pathlib import Path
import json,struct,hashlib
import numpy as np
R=Path(__file__).resolve().parents[1]
source=R/'assets/v2/house.glb';raw=source.read_bytes()
n,jkind=struct.unpack_from('<II',raw,12);doc=json.loads(raw[20:20+n]);offset=20+n
size,bkind=struct.unpack_from('<II',raw,offset);data=bytearray(raw[offset+8:offset+8+size])
regions=[]
for x,y,z in [(12,0,-10),(-12,3.6,9)]:
    regions += [(np.array([x-.731,y-.001,z-.331]),np.array([x+.731,y+.901,z+.331])),
                (np.array([x-.651,y+1.124,z-.329]),np.array([x+.651,y+1.976,z-.290])),
                (np.array([x+1.299,y-.001,z-.401]),np.array([x+1.901,y+.591,z+.401]))]
removed=0;primitives=[]
for mesh in doc['meshes']:
    for p in mesh['primitives']:
        a=doc['accessors'][p['attributes']['POSITION']];v=doc['bufferViews'][a['bufferView']]
        pts=np.ndarray((a['count'],3),dtype='<f4',buffer=data,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',12),4))
        ia=doc['accessors'][p['indices']];iv=doc['bufferViews'][ia['bufferView']]
        dtype={5123:'<u2',5125:'<u4'}[ia['componentType']]
        indices=np.frombuffer(data,dtype=dtype,count=ia['count'],offset=iv.get('byteOffset',0)+ia.get('byteOffset',0))
        triangles=indices.copy().reshape(-1,3);reject=np.zeros(len(triangles),dtype=bool)
        for low,high in regions:reject|=np.all((pts[triangles]>=low)&(pts[triangles]<=high),axis=(1,2))
        keep=triangles[~reject].ravel();count=int(reject.sum());removed+=count
        if count:indices[:len(keep)]=keep;ia['count']=len(keep);ia['min']=[int(keep.min())];ia['max']=[int(keep.max())]
        primitives.append({'mesh':mesh.get('name'),'removedTriangles':count})
assert 100<removed<1500,removed
j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
out=struct.pack('<III',0x46546c67,2,28+len(j)+len(data))+struct.pack('<II',len(j),jkind)+j+struct.pack('<II',len(data),bkind)+data
(R/'assets/v2/house-v3.glb').write_bytes(out)
manifest=json.loads((R/'assets/v2/manifest.json').read_text(encoding='utf-8'))
colliders=manifest['assets']['house']['collisions'];keep=[];removed_colliders=0
for c in colliders:
    if c.get('size')==[1.4,.84,.6] and any(np.allclose(c.get('position',[0,0,0]),pt) for pt in [[12,.42,-10],[-12,4.02,9]]):removed_colliders+=1
    else:keep.append(c)
assert removed_colliders==2,removed_colliders
(R/'assets/v2/house-collisions-v3.json').write_text(json.dumps(keep,separators=(',',':')),encoding='utf-8')
report={'sourceSHA256':hashlib.sha256(raw).hexdigest(),'outputSHA256':hashlib.sha256(out).hexdigest(),'removedTriangles':removed,'removedColliders':removed_colliders,'primitives':primitives}
(R/'evidence/v3/house-fixture-repair.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
