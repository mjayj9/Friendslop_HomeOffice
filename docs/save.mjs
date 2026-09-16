const te=new TextEncoder(),td=new TextDecoder('utf-8',{fatal:true});
const MAX=8*1024*1024, ALLOWED=new Set(['chair','table','sofa','book','crate','marker']);
const crcTable=Uint32Array.from({length:256},(_,n)=>{for(let i=0;i<8;i++)n=n&1?0xedb88320^(n>>>1):n>>>1;return n>>>0});
export function crc32(a){let c=0xffffffff;for(const b of a)c=crcTable[(c^b)&255]^(c>>>8);return (c^0xffffffff)>>>0}
const fail=()=>{throw new Error('지원하지 않거나 손상된 .homeworld 파일입니다. 현재 공간은 유지됩니다.')};
function exact(o,keys){if(!o||Object.getPrototypeOf(o)!==Object.prototype||Object.keys(o).sort().join()!==keys.sort().join())fail()}
const num=(n,lo,hi)=>typeof n==='number'&&Number.isFinite(n)&&n>=lo&&n<=hi;
const text=(s,n)=>typeof s==='string'&&s.length>0&&s.length<=n&&!/[\x00-\x1f<>]/.test(s);
export function validateWorld(w){
 exact(w,['schemaVersion','worldId','assetPack','zones','objects','doorOpen','board','revision']);
 if(w.schemaVersion!==1||w.assetPack!==1||!text(w.worldId,100)||JSON.stringify(w.zones)!=='["living","meeting"]'||typeof w.doorOpen!=='boolean'||!Number.isSafeInteger(w.revision)||w.revision<0)fail();
 if(!Array.isArray(w.objects)||w.objects.length>64||!Array.isArray(w.board)||w.board.length>512)fail();
 const ids=new Set();
 for(const o of w.objects){exact(o,['id','kind','p','yaw']);if(!text(o.id,100)||ids.has(o.id)||!ALLOWED.has(o.kind)||!Array.isArray(o.p)||o.p.length!==3||!o.p.every(n=>num(n,-100,100))||!num(o.yaw,-100000,100000))fail();ids.add(o.id)}
 const strokes=new Set();
 for(const s of w.board){exact(s,['id','author','points','color','width']);if(!text(s.id,180)||strokes.has(s.id)||!text(s.author,100)||!['#183b32','#bd5737','#305ea2','#f4f4ed'].includes(s.color)||!num(s.width,1,24)||!Array.isArray(s.points)||s.points.length<2||s.points.length>256)fail();strokes.add(s.id);for(const p of s.points)if(!Array.isArray(p)||p.length!==2||!p.every(n=>num(n,0,1)))fail()}
 return structuredClone(w);
}
async function sha(a){return [...new Uint8Array(await crypto.subtle.digest('SHA-256',a))].map(b=>b.toString(16).padStart(2,'0')).join('')}
export function zipStored(entries){
 let offset=0;const parts=[],central=[];
 for(const [name,bytes] of entries){const n=te.encode(name),crc=crc32(bytes),head=new Uint8Array(30+n.length),h=new DataView(head.buffer);h.setUint32(0,0x04034b50,true);h.setUint16(4,20,true);h.setUint32(14,crc,true);h.setUint32(18,bytes.length,true);h.setUint32(22,bytes.length,true);h.setUint16(26,n.length,true);head.set(n,30);parts.push(head,bytes);
 const c=new Uint8Array(46+n.length),v=new DataView(c.buffer);v.setUint32(0,0x02014b50,true);v.setUint16(4,20,true);v.setUint16(6,20,true);v.setUint32(16,crc,true);v.setUint32(20,bytes.length,true);v.setUint32(24,bytes.length,true);v.setUint16(28,n.length,true);v.setUint32(42,offset,true);c.set(n,46);central.push(c);offset+=head.length+bytes.length}
 const size=central.reduce((s,p)=>s+p.length,0),end=new Uint8Array(22),v=new DataView(end.buffer);v.setUint32(0,0x06054b50,true);v.setUint16(8,entries.length,true);v.setUint16(10,entries.length,true);v.setUint32(12,size,true);v.setUint32(16,offset,true);
 const out=new Uint8Array(offset+size+22);let at=0;for(const p of [...parts,...central,end]){out.set(p,at);at+=p.length}return out;
}
export function unzipStored(bytes){
 if(!(bytes instanceof Uint8Array)||bytes.length>MAX||bytes.length<22)fail();
 const d=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength),end=bytes.length-22;
 if(d.getUint32(end,true)!==0x06054b50||d.getUint16(end+4,true)!==0||d.getUint16(end+6,true)!==0||d.getUint16(end+8,true)!==2||d.getUint16(end+10,true)!==2||d.getUint16(end+20,true)!==0)fail();
 let at=d.getUint32(end+16,true),cursor=0,total=0;const centralEnd=at+d.getUint32(end+12,true),files={};if(centralEnd!==end)fail();
 for(let i=0;i<2;i++){
  if(at+46>end||d.getUint32(at,true)!==0x02014b50||d.getUint16(at+8,true)!==0||d.getUint16(at+10,true)!==0)fail();
  const size=d.getUint32(at+20,true),raw=d.getUint32(at+24,true),n=d.getUint16(at+28,true),extra=d.getUint16(at+30,true),comment=d.getUint16(at+32,true),local=d.getUint32(at+42,true),crc=d.getUint32(at+16,true);
  if(size!==raw||size>MAX||n>40||extra||comment||local!==cursor||at+46+n>end||local+30>at)fail();
  const name=td.decode(bytes.subarray(at+46,at+46+n));if(!['manifest.json','world.json'].includes(name)||files[name])fail();
  if(d.getUint32(local,true)!==0x04034b50||d.getUint16(local+6,true)!==0||d.getUint16(local+8,true)!==0||d.getUint32(local+14,true)!==crc||d.getUint32(local+18,true)!==size||d.getUint32(local+22,true)!==raw||d.getUint16(local+26,true)!==n||d.getUint16(local+28,true)!==0)fail();
  if(td.decode(bytes.subarray(local+30,local+30+n))!==name)fail();
  cursor=local+30+n+size;total+=size;if(cursor>d.getUint32(end+16,true)||total>MAX)fail();
  const data=bytes.slice(local+30+n,cursor);if(crc32(data)!==crc)fail();files[name]=data;at+=46+n;
 }
 if(at!==centralEnd||cursor!==d.getUint32(end+16,true))fail();return files;
}
export async function encodeWorld(world){const w=te.encode(JSON.stringify(validateWorld(world)));const manifest={format:'homeworld',schemaVersion:1,assetPack:1,createdAt:new Date().toISOString(),worldSha256:await sha(w)};return zipStored([['manifest.json',te.encode(JSON.stringify(manifest))],['world.json',w]])}
export async function decodeWorld(bytes){const files=unzipStored(bytes),m=JSON.parse(td.decode(files['manifest.json']));exact(m,['format','schemaVersion','assetPack','createdAt','worldSha256']);if(m.format!=='homeworld'||m.schemaVersion!==1||m.assetPack!==1||typeof m.createdAt!=='string'||m.createdAt.length>40||await sha(files['world.json'])!==m.worldSha256)fail();return validateWorld(JSON.parse(td.decode(files['world.json'])))}
