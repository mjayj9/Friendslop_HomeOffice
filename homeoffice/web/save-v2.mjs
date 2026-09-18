import {validateMeetingArchive} from './meeting-policy.mjs';
import {validateAnnouncements} from './broadcast.mjs';
import {validateRegistry} from './document-registry.mjs';
import {validatePresentationView} from './presentation-view.mjs';
import {crc32,zipStored} from './save.mjs';
const te=new TextEncoder(),td=new TextDecoder('utf-8',{fatal:true});
const MAX=32*1024*1024,assets=new Set(['chair','table','sofa','book','crate','marker','laser','low_table','bed','counter','cooker','sink','fridge','plate','pan','basketball','football','ingredient','meal','gun','shield','arcade','storage','drawer','floor_lamp']);
function bad(s='파일 형식/범위 오류'){throw new Error(s+' · 현재 공간을 유지합니다.')}
const finite=(v,a,b)=>typeof v==='number'&&Number.isFinite(v)&&v>=a&&v<=b;
const str=(v,n=100)=>typeof v==='string'&&v.length>0&&v.length<=n&&!/[\x00-\x1f<>]/.test(v);
function keys(o,required,optional=[]){if(!o||Object.getPrototypeOf(o)!==Object.prototype||required.some(k=>!(k in o))||Object.keys(o).some(k=>![...required,...optional].includes(k)))bad()}
function safeState(o){keys(o,[],['recipe','stage','food','dirty','cooking','ready','ammo','reloadUntil','nextShot','open','on','contents']);for(const[k,v]of Object.entries(o)){if(['recipe','stage'].includes(k)){if(!str(v,40))bad()}else if(['food','dirty','ready','open','on'].includes(k)){if(typeof v!=='boolean')bad()}else if(k==='contents'){if(!Array.isArray(v)||v.length>16||!v.every(x=>str(x)))bad()}else if(!finite(v,0,1e15))bad()}}
export function validateWorld(w){
 keys(w,['schemaVersion','worldId','assetPack','layoutVersion','roomSlots','objects','doors','board','revision','results','settings'],['collaboration','presentation','presentationView','documents','facilities','announcements','meetings','campusVersion','unplaced','campusDoors','campusTaps']);
 if(w.schemaVersion!==2||w.assetPack!==2||w.layoutVersion!==2||!str(w.worldId)||!Number.isSafeInteger(w.revision)||w.revision<0)bad('V2 공간 파일이 필요합니다');
 if(!Array.isArray(w.objects)||w.objects.length>256||!Array.isArray(w.roomSlots)||w.roomSlots.length>8)bad();
 if(w.campusTaps!==undefined){keys(w.campusTaps,[],['B1','1F','2F','3F','4F','5F','6F','RF'].map(f=>'campus-wc-'+f));if(Object.values(w.campusTaps).some(v=>typeof v!=='boolean'))bad('수전 상태 형식 오류');}
 if(w.campusDoors!==undefined){keys(w.campusDoors,[],['council','moss','clay','seminar','operations','broadcast',...['B1','1F','2F','3F','4F','5F','6F','RF'].flatMap(f=>['wc-'+f+'-0','wc-'+f+'-1'])]);if(Object.values(w.campusDoors).some(v=>typeof v!=='boolean'))bad('문 상태 형식 오류');}
 if(w.campusVersion!==undefined&&w.campusVersion!==1)bad('알 수 없는 캠퍼스 배치');if(w.unplaced!==undefined&&(!Array.isArray(w.unplaced)||w.unplaced.length+w.objects.length>256))bad('가구 보관 한도');
 const allObjects=[...w.objects,...(w.unplaced||[])],ids=new Set();
 for(const o of allObjects){keys(o,['id','kind','p','yaw','state']);if(!str(o.id)||ids.has(o.id)||!assets.has(o.kind)||!Array.isArray(o.p)||o.p.length!==3||!o.p.every(x=>finite(x,-110,110))||!finite(o.yaw,-100000,100000))bad();safeState(o.state);ids.add(o.id)}
 for(let i=0;i<w.roomSlots.length;i++){const s=w.roomSlots[i];keys(s,['personalRoomId','memberSlotId','moduleIndex','side','label']);if(s.personalRoomId!==`office-${i+1}`||s.memberSlotId!==`slot-${i+1}`||s.moduleIndex!==Math.floor(i/2)||s.side!==i%2||!str(s.label,60))bad()}
 if(!w.doors||Object.getPrototypeOf(w.doors)!==Object.prototype||Object.keys(w.doors).length>20)bad();
 const doorIds=new Set(['front-door','terrace-door','meeting-door','game-gate','sleep-door',...w.roomSlots.map(s=>s.personalRoomId+'-door')]);
 for(const[k,v]of Object.entries(w.doors))if(!doorIds.has(k)||typeof v!=='boolean')bad();
 if(!Array.isArray(w.board)||w.board.length>512)bad();const strokes=new Set();
 for(const s of w.board){keys(s,['id','author','points','color','width'],['kind','text','fontSize','version']);if(s.kind!==undefined&&(s.kind!=='text'||typeof s.text!=='string'||s.text.length>160||s.fontSize!==28))bad();if(s.version!==undefined&&(!Number.isSafeInteger(s.version)||s.version<0))bad();if(!str(s.id,180)||!str(s.author)||strokes.has(s.id)||!['#183b32','#bd5737','#305ea2','#f4f4ed'].includes(s.color)||!finite(s.width,1,24)||!Array.isArray(s.points)||s.points.length<2||s.points.length>256||s.points.some(p=>!Array.isArray(p)||p.length!==2||!p.every(n=>finite(n,0,1))))bad();strokes.add(s.id)}
 keys(w.results,['basketball','football'],['arcade']);if(w.results.arcade!==undefined){if(!Array.isArray(w.results.arcade)||w.results.arcade.length>64)bad();for(const r of w.results.arcade){keys(r,['game','score','won']);if(!['maze','runner'].includes(r.game)||!Number.isSafeInteger(r.score)||r.score<0||r.score>1e7||typeof r.won!=='boolean')bad()}}for(const a of [w.results.basketball,w.results.football])if(!Array.isArray(a)||a.length!==2||!a.every(v=>Number.isSafeInteger(v)&&v>=0&&v<1e7))bad();
 keys(w.settings,['maxPlayers']);if(w.settings.maxPlayers!==8)bad();
 if(w.collaboration!==undefined){keys(w.collaboration,['update','revision']);if(typeof w.collaboration.update!=='string'||w.collaboration.update.length>3e6||!/^[A-Za-z0-9+/]*={0,2}$/.test(w.collaboration.update)||!Number.isSafeInteger(w.collaboration.revision)||w.collaboration.revision<0)bad()}
 if(w.presentation!==undefined){if(!Array.isArray(w.presentation)||w.presentation.length>64)bad();for(const a of w.presentation){keys(a,['id','name','mime','sha256','bytes']);if(!/^[a-f0-9]{64}$/.test(a.id)||a.sha256!==a.id||!str(a.name,160)||!['image/png','image/jpeg','application/pdf'].includes(a.mime)||!Number.isSafeInteger(a.bytes)||a.bytes<1||a.bytes>16*1024*1024)bad()}}
 if(w.presentationView!==undefined)validatePresentationView(w.presentationView,w.presentation||[]);
 const attachmentIds=(w.presentation||[]).map(a=>a.id);if(new Set(attachmentIds).size!==attachmentIds.length)bad('중복 발표 자료 ID');for(const o of allObjects)if(o.state.contents?.some(id=>!ids.has(id)||id===o.id))bad('수납 참조 오류');
 const contained=new Set();for(const o of allObjects){const contents=o.state.contents||[];if(contents.length&&!['storage','drawer'].includes(o.kind))bad('수납 사물이 아닙니다');if(contents.length>(o.kind==='drawer'?2:4))bad('수납 용량 초과');for(const id of contents){const item=allObjects.find(i=>i.id===id);const allowed=o.kind==='storage'?['book','marker','crate','plate','pan','ingredient','meal']:['book','marker','plate','ingredient','meal'];if(contained.has(id)||!allowed.includes(item.kind))bad('중복 또는 허용하지 않는 수납 참조');contained.add(id)}}
 if(w.facilities!==undefined){keys(w.facilities,[],['toilet_ground','toilet_upper','tap_ground','tap_upper','home_light','office_light','bath_light','flush_ground','flush_upper','vent']);if(Object.values(w.facilities).some(v=>typeof v!=='boolean'))bad('시설 상태 형식 오류');}
 if(w.announcements!==undefined)validateAnnouncements(w.announcements);
 if(w.documents!==undefined)validateRegistry(w.documents);
 if(w.meetings!==undefined){for(const row of validateMeetingArchive(w.meetings)){const scoped={...w,collaboration:row.collaboration,documents:row.documents,presentation:row.presentation,presentationView:row.presentationView};delete scoped.meetings;validateWorld(scoped);}if(presentationAssets(w).length>64)bad('전체 발표 자료는 최대 64개입니다');}
 return structuredClone(w);
}
export function presentationAssets(world){const out=new Map();for(const a of [...(world.presentation||[]),...(world.meetings||[]).flatMap(m=>m.presentation||[])]){if(out.has(a.id)&&JSON.stringify(out.get(a.id))!==JSON.stringify(a)&&out.get(a.id).bytes!==a.bytes)bad('상충하는 첨부 참조');out.set(a.id,a);}return [...out.values()];}
export async function sha(bytes){return [...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(v=>v.toString(16).padStart(2,'0')).join('')}
export function unzip(bytes){
 if(!(bytes instanceof Uint8Array)||bytes.length<22||bytes.length>MAX)bad('파일 크기 제한 32MB');
 const v=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength),end=bytes.length-22;
 if(v.getUint32(end,true)!==0x06054b50||v.getUint16(end+4,true)||v.getUint16(end+6,true)||v.getUint16(end+20,true))bad();
 const count=v.getUint16(end+10,true),start=v.getUint32(end+16,true);if(count<2||count>66||count!==v.getUint16(end+8,true)||start+v.getUint32(end+12,true)!==end)bad();
 let at=start,cursor=0;const files=new Map();
 for(let i=0;i<count;i++){
  if(at+46>end||v.getUint32(at,true)!==0x02014b50||v.getUint16(at+8,true)||v.getUint16(at+10,true))bad('압축/실행 항목은 허용하지 않습니다');
  const crc=v.getUint32(at+16,true),size=v.getUint32(at+20,true),raw=v.getUint32(at+24,true),n=v.getUint16(at+28,true),off=v.getUint32(at+42,true);
  if(raw!==size||size>MAX||n>90||v.getUint16(at+30,true)||v.getUint16(at+32,true)||v.getUint16(at+34,true)||off!==cursor||off+30>start||at+46+n>end)bad();
  const name=td.decode(bytes.subarray(at+46,at+46+n));if(!/^(manifest\.json|world\.json|attachments\/[a-f0-9]{64})$/.test(name)||files.has(name))bad('허용되지 않는 경로/중복 ID');
  if(v.getUint32(off,true)!==0x04034b50||v.getUint16(off+6,true)||v.getUint16(off+8,true)||v.getUint32(off+14,true)!==crc||v.getUint32(off+18,true)!==size||v.getUint32(off+22,true)!==size||v.getUint16(off+26,true)!==n||v.getUint16(off+28,true))bad();
  if(td.decode(bytes.subarray(off+30,off+30+n))!==name)bad();cursor=off+30+n+size;if(cursor>start)bad();const content=bytes.slice(off+30+n,cursor);if(crc32(content)!==crc)bad('CRC 오류');files.set(name,content);at+=46+n;
 }
 if(at!==end||cursor!==start)bad();return files;
}
export function validAttachment(a,bytes){if(bytes.length!==a.bytes)bad();const m=a.mime;const okay=m==='application/pdf'?td.decode(bytes.slice(0,5))==='%PDF-':m==='image/png'?bytes[0]===137&&bytes[1]===80&&bytes[2]===78&&bytes[3]===71:bytes[0]===255&&bytes[1]===216&&bytes[2]===255;if(!okay)bad('자료 종류가 실제 파일과 다릅니다')}
export async function encodeWorld(world,attachments=new Map()){
 const clean=validateWorld(world);const w=te.encode(JSON.stringify(clean));const entries=[['world.json',w]];
 for(const a of presentationAssets(clean)){const b=attachments.get(a.id);if(!b)bad('발표 자료가 아직 수신되지 않았습니다');validAttachment(a,b);if(await sha(b)!==a.sha256)bad('자료 checksum 오류');entries.push(['attachments/'+a.id,b])}
 const manifest={format:'homeworld',schemaVersion:2,assetPack:2,createdAt:new Date().toISOString(),worldSha256:await sha(w)};
 const bytes=zipStored([['manifest.json',te.encode(JSON.stringify(manifest))],...entries]);if(bytes.length>MAX)bad();return bytes;
}
export async function decodeBundle(bytes){
 const files=unzip(bytes);const m=JSON.parse(td.decode(files.get('manifest.json')));keys(m,['format','schemaVersion','assetPack','createdAt','worldSha256']);if(m.format!=='homeworld'||m.schemaVersion!==2||m.assetPack!==2||!str(m.createdAt,40)||await sha(files.get('world.json'))!==m.worldSha256)bad('manifest/checksum 오류');const world=validateWorld(JSON.parse(td.decode(files.get('world.json'))));const attachments=new Map();
 for(const a of presentationAssets(world)){const b=files.get('attachments/'+a.id);if(!b)bad('자료 누락');validAttachment(a,b);if(await sha(b)!==a.sha256)bad('자료 checksum 오류');attachments.set(a.id,b)}
 if(files.size!==attachments.size+2)bad('미참조 자료');return {world,attachments};
}
export async function decodeWorld(bytes){return (await decodeBundle(bytes)).world}
