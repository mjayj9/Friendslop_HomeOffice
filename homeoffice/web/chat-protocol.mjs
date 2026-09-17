// Host-owned routing. DM payloads reach only their participants and the relay host.
export const CHAT_LIMITS={text:2000,history:500,fileBytes:20*1024*1024,chunkBytes:12*1024,transfers:2};
const token=v=>typeof v==='string'&&/^[a-zA-Z0-9:-]{1,100}$/.test(v);
const reactions=new Set(['👍','❤️','✅','💡','👏','❓']);
export function createChatAuthority({members,clock=Date.now}){
 const records=new Map(),transfers=new Map(),rates=new Map(),fileIds=new Set();
 function deliver(row,op='event'){return row.recipients.map(to=>({to,packet:{type:'chat',op,row:structuredClone(row)}}));}
 function accept(sender,m){
  const roster=members(),actor=roster.find(p=>p.id===sender),now=clock();
  const reject=reason=>[{to:sender,packet:{type:'chat',op:'error',messageId:m.messageId,reason}}];
  if(!actor||!m||m.type!=='chat')return [];
  const rate=rates.get(sender)||{at:now,count:0};if(now-rate.at>1000){rate.at=now;rate.count=0;}
  rate.count++;rates.set(sender,rate);if(rate.count>80)return reject('전송 속도 한도입니다. 잠시 후 다시 시도하세요.');
  if(m.op==='create'){
   if(!token(m.messageId))return reject('메시지 ID가 올바르지 않습니다.');
   const existing=records.get(m.messageId);if(existing)return existing.sender===sender?deliver(existing):reject('메시지 ID 충돌');
   let recipients,channel;
   if(m.channel==='session'){recipients=roster.map(p=>p.id);channel='session';}
   else if(m.channel==='zone'){recipients=roster.filter(p=>p.zone===actor.zone).map(p=>p.id);channel='zone:'+actor.zone;}
   else if(m.channel==='dm'&&roster.some(p=>p.id===m.to)&&m.to!==sender){recipients=[sender,m.to];channel='dm:'+recipients.slice().sort().join(':');}
   else return reject('대화 상대 또는 채널이 유효하지 않습니다.');
   if(typeof m.text!=='string'||m.text.length>CHAT_LIMITS.text||(!m.text.trim()&&!m.file))return reject('메시지 내용이 비어 있거나 너무 깁니다.');
   let file=null;
   if(m.file){
    const f=m.file;
    if(!token(f.id)||typeof f.name!=='string'||f.name.length>120||/[\x00-\x1f<>/\\]/.test(f.name)||!Number.isSafeInteger(f.size)||f.size<1||f.size>CHAT_LIMITS.fileBytes||!['image/png','image/jpeg','application/pdf','text/plain'].includes(f.mime)||!/^[a-f0-9]{64}$/.test(f.hash))return reject('첨부 정보가 올바르지 않습니다.');
    if(fileIds.has(f.id)||fileIds.size>=2048)return reject("첨부 ID 재사용 또는 세션 파일 개수 한도입니다. 새 파일로 다시 공유하세요.");
    file={id:f.id,name:f.name,size:f.size,mime:f.mime,hash:f.hash,provider:sender};
   }
   const reply=m.replyTo?records.get(m.replyTo):null;
   if(m.replyTo&&(!reply||!recipients.every(p=>reply.recipients.includes(p))))return reject('다른 대화의 메시지를 인용할 수 없습니다.');
   const row={id:m.messageId,sender,name:String(actor.displayName||'친구').slice(0,24),channel,recipients,text:m.text.trim(),file,replyTo:reply?.id||'',replyText:reply?.text.slice(0,120)||'',createdAt:now,revision:1,deleted:false,reactions:{},delivered:[],read:[]};
   if(file)fileIds.add(file.id);records.set(row.id,row);while(records.size>CHAT_LIMITS.history){const first=records.keys().next().value;records.delete(first);for(const[k,t]of transfers)if(t.messageId===first)transfers.delete(k);}
   return deliver(row);
  }
  const row=records.get(m.messageId);if(!row||!row.recipients.includes(sender))return reject('이 대화에 접근할 수 없습니다.');
  if(m.op==='edit'||m.op==='delete'){
   if(row.sender!==sender||now-row.createdAt>15*60*1000||row.deleted)return reject('본인의 15분 이내 메시지만 변경할 수 있습니다.');
   if(m.op==='edit'&&(typeof m.text!=='string'||!m.text.trim()||m.text.length>CHAT_LIMITS.text))return reject('수정할 내용을 확인하세요.');
   row.revision++;row.editedAt=now;row.text=m.op==='delete'?'':m.text.trim();row.deleted=m.op==='delete';
   if(row.deleted){row.file=null;row.reactions={};for(const[k,t]of transfers)if(t.messageId===row.id)transfers.delete(k);}
   return deliver(row);
  }
  if(m.op==='react'){
   if(row.deleted||!reactions.has(m.emoji))return reject('지원하지 않는 반응입니다.');
   const list=new Set(row.reactions[m.emoji]||[]);list.has(sender)?list.delete(sender):list.add(sender);row.reactions[m.emoji]=[...list];row.revision++;return deliver(row);
  }
  if(m.op==='delivered'||m.op==='read'){
   if(sender===row.sender)return [];
   let changed=false;for(const field of (m.op==='read'?['delivered','read']:['delivered']))if(!row[field].includes(sender)){row[field].push(sender);changed=true;}
   if(!changed)return [];row.revision++;return deliver(row);
  }
  if(!row.file||row.deleted)return reject('첨부물 제공이 종료되었습니다.');
  const f=row.file,key=row.id+':'+sender;
  if(m.op==='file-request'){
   if(!roster.some(p=>p.id===f.provider))return reject('원본 제공자 오프라인');
   if(!Number.isSafeInteger(m.index)||m.index<0||m.index>=Math.ceil(f.size/CHAT_LIMITS.chunkBytes))return reject('잘못된 조각 요청');
   if(!transfers.has(key)&&[...transfers.values()].filter(t=>t.receiver===sender).length>=CHAT_LIMITS.transfers)return reject('동시 파일 받기는 2개까지입니다.');
   transfers.set(key,{messageId:row.id,receiver:sender,index:m.index,expires:now+15000});
   return [{to:f.provider,packet:{type:'chat',op:'file-next',messageId:row.id,fileId:f.id,index:m.index,receiver:sender}}];
  }
  if(m.op==='file-cancel'){transfers.delete(key);return [];}
  if(m.op==='file-chunk'){
   const lease=transfers.get(row.id+':'+m.receiver),count=Math.ceil(f.size/CHAT_LIMITS.chunkBytes),expected=m.index===count-1?f.size-m.index*CHAT_LIMITS.chunkBytes:CHAT_LIMITS.chunkBytes;
   if(sender!==f.provider||!row.recipients.includes(m.receiver)||!lease||lease.expires<now||lease.index!==m.index||typeof m.data!=='string'||m.data.length!==4*Math.ceil(expected/3)||!/^[A-Za-z0-9+/]+={0,2}$/.test(m.data))return reject('허용되지 않은 첨부 전송입니다.');
   transfers.delete(row.id+':'+m.receiver);
   return [{to:m.receiver,packet:{type:'chat',op:'file-chunk',messageId:row.id,fileId:f.id,index:m.index,data:m.data}}];
  }
  return [];
 }
 return {accept,reset(){records.clear();transfers.clear();rates.clear();fileIds.clear();},diagnostics:()=>({records:records.size,transfers:transfers.size})};
}
