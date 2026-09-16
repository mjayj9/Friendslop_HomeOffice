// Full roster + changing physical objects. Ordered channel; missed bases request a keyframe.
export function createStateCodec(){
 const encoder=new TextEncoder();const sent=new Map(),received=new Map();let rawBytes=0,wireBytes=0,keyframes=0,deltas=0,resyncs=0;
 function encode(peer,state){
  const before=sent.get(peer),fingerprints=new Map(state.objects.map(o=>[o.id,JSON.stringify({...o,p:o.p?.map(n=>Math.round(n*1000)),r:o.r?.map(n=>Math.round(n*1000)),v:o.v?.map(n=>Math.round(n*100)),av:o.av?.map(n=>Math.round(n*100))})]));
  const full=!before||before.epoch!==state.epoch||state.tick-before.keyTick>=120;
  let message;
  if(full){message={...state,stateBaseline:true};keyframes++;}
  else{const objects=state.objects.filter(o=>before.objects.get(o.id)!==fingerprints.get(o.id));message={...state,type:'state-delta',baseTick:before.tick,objects,removed:[...before.objects.keys()].filter(id=>!fingerprints.has(id))};deltas++;}
  sent.set(peer,{epoch:state.epoch,tick:state.tick,keyTick:full?state.tick:before.keyTick,objects:fingerprints});
  rawBytes+=encoder.encode(JSON.stringify(state)).byteLength;wireBytes+=encoder.encode(JSON.stringify(message)).byteLength;return message;
 }
 function decode(peer,m){
  if(m.type==='state'){
   if(!Array.isArray(m.objects)||m.objects.length>256||m.objects.some(o=>!o||typeof o.id!=='string'))return null;
   const old=received.get(peer);if(old?.epoch===m.epoch&&m.tick<=old.tick)return null;
   received.set(peer,{epoch:m.epoch,tick:m.tick,objects:new Map(m.objects.map(o=>[o.id,o]))});return m;
  }
  const old=received.get(peer);
  if(!old||old.epoch!==m.epoch||old.tick!==m.baseTick||!Array.isArray(m.objects)||!Array.isArray(m.removed)||m.objects.length>256||m.removed.length>256){resyncs++;return null;}
  for(const id of m.removed)old.objects.delete(id);
  for(const o of m.objects){if(!o||typeof o.id!=='string'){resyncs++;return null;}old.objects.set(o.id,o);}
  if(old.objects.size>256){received.delete(peer);resyncs++;return null;}
  old.tick=m.tick;return {...m,type:'state',objects:[...old.objects.values()]};
 }
 return {encode,decode,forget(peer){sent.delete(peer);received.delete(peer);},requestKeyframe(peer){sent.delete(peer);},diagnostics:()=>({rawBytes,wireBytes,keyframes,deltas,resyncs,savedPercent:rawBytes?Math.round(100*(1-wireBytes/rawBytes)):0})};
}
