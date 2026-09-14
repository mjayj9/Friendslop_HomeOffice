// Two-phase, acknowledged host transfer. Every old data channel is ordered.
export function createHandoff(h){
 let transaction=null,staged=null,timeout;
 const freeze=()=>{h.pause();h.engine({type:'handoff_freeze',paused:true})};
 const thaw=()=>{h.engine({type:'handoff_freeze',paused:false});h.resume()};
 function reset(){clearTimeout(timeout);transaction=null;staged=null}
 function cancel(reason){console.info('HANDOFF_CANCEL',reason);if(transaction&&h.host())h.send({type:'handoff-cancel',token:transaction.token,reason});reset();thaw();h.notify(reason)}
 async function begin(target){console.info('HANDOFF_BEGIN',target);if(!h.host()||!h.peers().includes(target)||transaction)return;if(h.composing())return h.notify('한글 조합을 마친 뒤 방장을 이전해 주세요.');const token=crypto.randomUUID();transaction={token,target,acks:new Set(),epoch:crypto.randomUUID()};freeze();h.send({type:'handoff-barrier',token,target});timeout=setTimeout(()=>cancel('방장 이전 응답 시간이 초과되어 기존 방장을 유지합니다.'),20000);await h.flush();if(!h.peers().length)cancel('이전할 참가자가 없습니다.')}
 async function receive(sender,m){if(!m.type.startsWith('handoff-'))return false;console.info('HANDOFF_RECEIVE',m.type,sender);
  if(m.type==='handoff-barrier'&&!h.host()&&sender===h.room()){
   if(h.composing()){h.send({type:'handoff-refuse',token:m.token,reason:'참가자가 한글을 조합 중입니다.'});return true}
   staged={token:m.token,target:m.target};freeze();await h.flush();h.send({type:'handoff-barrier-ack',token:m.token});timeout=setTimeout(()=>{reset();thaw();h.notify('이전이 중단되어 원래 세션으로 돌아갑니다.')},24000);return true
  }
  if(m.type==='handoff-cancel'&&!h.host()&&sender===h.room()){reset();thaw();h.notify(m.reason);return true}
  if(h.host()&&transaction&&m.token===transaction.token){
   if(m.type==='handoff-refuse'){cancel(m.reason||'수신 준비에 실패했습니다.');return true}
   if(m.type==='handoff-barrier-ack'){transaction.acks.add(sender);if(h.peers().every(p=>transaction.acks.has(p)))h.engine({type:'handoff_capture'});return true}
   if(m.type==='handoff-ready'&&sender===transaction.target){const t=transaction;h.send({type:'handoff-commit',token:t.token,target:t.target,newEpoch:t.epoch});await h.flush();clearTimeout(timeout);await h.switch(t.target,t.epoch,t.checkpoint);reset();return true}
  }
  if(m.type==='handoff-offer'&&!h.host()&&sender===h.room()&&staged?.token===m.token&&staged.target===h.id()){
   try{await h.validate(m.checkpoint);staged.checkpoint=m.checkpoint;h.send({type:'handoff-ready',token:m.token})}catch(e){h.send({type:'handoff-refuse',token:m.token,reason:'받는 방장 검증 실패: '+e.message})}return true
  }
  if(m.type==='handoff-commit'&&!h.host()&&sender===h.room()&&staged?.token===m.token){const checkpoint=staged.checkpoint;clearTimeout(timeout);await h.switch(m.target,m.newEpoch,checkpoint);reset();return true}
  return true;
 }
 function captured(json){console.info('HANDOFF_CAPTURED',json.length);if(!h.host()||!transaction)return;try{const checkpoint=JSON.parse(json);checkpoint.world=h.decorate(checkpoint.world);checkpoint.presentation=h.presentation();checkpoint.voice=h.voice();checkpoint.arcade=h.arcade();transaction.checkpoint=checkpoint;h.send({type:'handoff-offer',token:transaction.token,checkpoint},transaction.target);console.info('HANDOFF_OFFER_SENT')}catch(e){cancel('체크포인트 생성 실패: '+e.message);console.info('HANDOFF_CAPTURE_ERROR',e.stack)}}
 return {begin,receive,captured,active:()=>!!transaction||!!staged};
}
