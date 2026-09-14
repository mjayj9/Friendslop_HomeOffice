"""Deterministic authored, tileable material bitmaps; no external artwork."""
import math,random,struct,zlib
from pathlib import Path
import bpy
def linear(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def png(path,pixels,w,h):
 def chunk(kind,data):return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data)&0xffffffff)
 raw=b''.join(b'\0'+pixels[y*w*3:(y+1)*w*3] for y in range(h))
 path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
def apply_materials(palette,materials,root):
 folder=Path(root)/'assets/textures/v2';folder.mkdir(parents=True,exist_ok=True)
 for name,c in palette.items():
  mat=materials[name];bsdf=mat.node_tree.nodes.get('Principled BSDF')
  bsdf.inputs['Base Color'].default_value=(*[linear(v) for v in c],.22 if name=='glass' else 1)
  mat.diffuse_color=(*[linear(v) for v in c],.22 if name=='glass' else 1)
  if name not in ['oak','oak2','walnut','deck','cloth','carpet','stone','tile','plaster']:continue
  n=256;data=bytearray();rng=random.Random(415)
  for y in range(n):
   for x in range(n):
    u=x/n;v=y/n
    if name in ['oak','oak2','walnut','deck']:a=1+.065*math.sin(v*math.tau*43+.9*math.sin(u*math.tau*2))+.035*math.sin(v*math.tau*107)+rng.uniform(-.018,.018)
    elif name in ['cloth','carpet']:a=1+(.038 if x%4<2 else -.038)+(.03 if y%4<2 else -.03)+rng.uniform(-.018,.018)
    elif name in ['stone','tile']:a=.80 if x<2 or y<2 else 1+rng.uniform(-.025,.025)
    else:a=1+rng.uniform(-.018,.018)
    data.extend(round(max(0,min(1,value*a))*255) for value in c)
  path=folder/(name+'.png');png(path,data,n,n)
  image=bpy.data.images.load(str(path),check_existing=False);image.pack()
  tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.label='Authored '+name+' surface';tex.extension='REPEAT'
  mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
def world_uv(mesh):
 uv=mesh.uv_layers.new(name='WorldScale')
 for face in mesh.polygons:
  normal=face.normal;axis=max(range(3),key=lambda i:abs(normal[i]))
  for li in face.loop_indices:
   p=mesh.vertices[mesh.loops[li].vertex_index].co
   a,b=(p.x,p.y) if axis==2 else ((p.z,p.y) if axis==0 else (p.z,p.x))
   uv.data[li].uv=(a*.8,b*.8)
