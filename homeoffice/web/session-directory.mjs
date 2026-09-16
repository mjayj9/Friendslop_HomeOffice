import {parseInvitation,PROTOCOL_VERSION} from './invitations.mjs';
// Uses the already configured PeerJS signaling namespace. No new database or paid service.
// Discovery ownership is a simulation role; it does not authenticate a teacher.
export function claimRoom(code,hostId,epoch,options){
 return new Promise((resolve,reject)=>{
  const alias=new Peer(parseInvitation(code).peer,options);let settled=false;
  const timer=setTimeout(()=>{if(!settled){alias.destroy();reject(Error('방 주소 예약 시간 초과'));}},12000);
  alias.on('open',()=>{settled=true;clearTimeout(timer);resolve(alias)});
  alias.on('error',e=>{if(!settled){settled=true;clearTimeout(timer);alias.destroy();const err=Error(e.type);err.code=e.type;reject(err)}});
  alias.on('connection',c=>{c.on('open',()=>{c.send({type:'directory',protocolVersion:PROTOCOL_VERSION,hostId,epoch});setTimeout(()=>c.close(),500)})});
 });
}
export function resolveRoom(peer,code){
 return new Promise((resolve,reject)=>{
  const c=peer.connect(parseInvitation(code).peer,{reliable:true,serialization:'json'});
  let done=false;const finish=(error,value)=>{if(done)return;done=true;clearTimeout(timer);c.close();error?reject(error):resolve(value)};
  const timer=setTimeout(()=>finish(Error('방을 찾지 못했습니다. 호스트가 열어 둔 코드인지 확인하세요.')),10000);
  c.on('data',m=>{
   if(m?.type==='directory'&&m.protocolVersion===PROTOCOL_VERSION&&/^ho3-user-[a-f0-9-]{36}$/.test(m.hostId)&&typeof m.epoch==='string')finish(null,m);
  });
  c.on('error',()=>finish(Error('방에 연결하지 못했습니다.')));
 });
}

export async function reclaimRoom(code,hostId,epoch,options){
 for(let attempt=0;attempt<8;attempt++){
  try{return await claimRoom(code,hostId,epoch,options);}catch(e){if(e.code!=='unavailable-id'||attempt===7)throw e;await new Promise(resolve=>setTimeout(resolve,400));}
 }
}
