import {createChatAuthority,CHAT_LIMITS} from './chat-protocol.mjs';
import {prepareFile,inspectBytes} from './attachment-policy.mjs';

export function createSocial({send,isHost,id,members,pause,resume,notify,profile,onMessage}){
 const entry=document.querySelector('#entry .welcome'),label=document.createElement('label'),name=document.createElement('input');
 label.textContent='표시 이름 ';name.id='displayName';name.maxLength=24;name.placeholder='이름';
 try{name.value=localStorage.getItem('moyeo-name')||'친구';}catch{name.value='친구';}
 label.append(name);entry.insertBefore(label,entry.querySelector('.buttons'));name.onchange=()=>{try{localStorage.setItem('moyeo-name',name.value);}catch{}profile(name.value);};
 const panel=document.createElement('section');panel.id='textChat';panel.hidden=true;panel.setAttribute('aria-label','메신저');
 panel.innerHTML=`<header class="row"><div><small>COMMONS / MESSENGER</small><h2>대화</h2></div><button id="closeChat" class="secondary" type="button">닫기</button></header>
 <div class="chat-navigation"><select id="chatChannel" aria-label="대화 채널"><option value="session">세션 전체</option><option value="zone">현재 공간</option><option value="dm">개인 대화</option></select><select id="chatRecipient" aria-label="개인 대화 상대" hidden></select></div>
 <div class="row"><input id="chatSearch" type="search" placeholder="이 대화 검색" aria-label="메시지 검색"><button id="chatMedia" class="secondary" type="button">파일 모아보기</button></div>
 <p class="chat-policy">현재 세션에서만 보관 · 세계 저장에 포함하지 않음<br>개인 대화는 호스트가 중계하며 종단간 암호화 대화가 아닙니다.</p>
 <div id="chatLines" role="log" aria-label="메시지"></div><p id="chatReply" hidden></p>
 <form id="chatForm"><textarea id="chatText" maxlength="2000" rows="2" placeholder="메시지 · Enter 전송 / Shift+Enter 줄바꿈" aria-label="메시지 내용"></textarea><div class="row"><label class="filebutton" tabindex="0">파일 선택<input id="chatFile" type="file" accept=".png,.jpg,.jpeg,.pdf,.txt" multiple hidden></label><button type="submit">보내기</button></div></form>
 <p class="chat-policy">파일 드롭 · 이미지 붙여넣기 / PNG·JPEG·PDF·TXT, 20MiB. 형식·무결성을 확인하며 악성코드 검사 완료를 뜻하지 않습니다. PDF는 다운로드로 엽니다.</p>
 <p id="chatNotice" role="status"></p>`;
 document.body.append(panel);const $=key=>panel.querySelector('#'+key),button=document.createElement('button');button.textContent='대화 · Enter';button.id='chatToggle';button.onclick=open;document.getElementById('topbar').append(button);
 const authority=createChatAuthority({members}),rows=new Map(),files=new Map(),downloads=new Map(),pending=new Map(),seen=new Set();
 let replyTo='',editing='',composing=false,unread=0,mediaOnly=false,renderTimer=0,providedBytes=0,receivedBytes=0;
 const report=message=>{$('chatNotice').textContent=message;};
 function selected(){const channel=$('chatChannel').value;return channel==='session'?'session':channel==='zone'?'zone:'+(members().find(p=>p.id===id())?.zone||''):'dm:'+ [id(),$('chatRecipient').value].sort().join(':');}
 function refreshMembers(){const s=$('chatRecipient'),old=s.value,choices=members().filter(p=>p.id!==id());for(const row of rows.values())if(row.channel.startsWith('dm:'))for(const who of row.recipients)if(who!==id()&&!choices.some(p=>p.id===who))choices.push({id:who,displayName:([...rows.values()].find(r=>r.sender===who)?.name||'이전 참여자')+' (오프라인)'});const signature=choices.map(p=>p.id+':'+p.displayName).join('|');if(s.dataset.signature===signature)return;s.dataset.signature=signature;s.replaceChildren();for(const p of choices)s.append(new Option(p.displayName||'친구',p.id));if(choices.some(p=>p.id===old))s.value=old;changed();}
 function route(to,packet){if(to===id())inbox(packet);else send(packet,to);}
 function request(packet){const m={type:'chat',...packet};if(isHost())receive(id(),m);else send(m);}
 function receive(sender,m){if(m.type!=='chat')return false;if(isHost())for(const out of authority.accept(sender,m))route(out.to,out.packet);else inbox(m);return true;}
 function changed(){if(!renderTimer)renderTimer=setTimeout(()=>{renderTimer=0;render();},120);}
 function acknowledge(row,kind){if(!row.archived&&row.sender!==id())request({op:kind,messageId:row.id});}
 function inbox(m){
  if(m.op==='event'){
   const row=m.row;if(!row?.recipients?.includes(id())||typeof row.id!=='string')return;
   const prior=rows.get(row.id);if(prior&&row.revision<prior.revision)return;
   if(row.deleted&&prior?.file)dropFile(prior.file.id);
   rows.set(row.id,row);pending.delete(row.id);
   if(!prior){onMessage?.(row);acknowledge(row,'delivered');if(row.sender!==id()&&(panel.hidden||selected()!==row.channel)){unread++;button.textContent='대화 · '+unread;}}
   while(rows.size>CHAT_LIMITS.history){const old=rows.values().next().value;if(old.file)dropFile(old.file.id);rows.delete(old.id);seen.delete(old.id);}
   changed();return;
  }
  if(m.op==='error'){
   const p=pending.get(m.messageId);if(p){p.status='failed';p.error=m.reason;}
   const d=downloads.get(m.messageId);if(d?.state==='receiving'){d.state='failed';d.error=m.reason;}
   report(m.reason||'전송 실패');changed();return;
  }
  if(m.op==='file-next'){
   const source=files.get(m.fileId);if(!source?.bytes)return;
   const begin=m.index*CHAT_LIMITS.chunkBytes,chunk=source.bytes.subarray(begin,Math.min(begin+CHAT_LIMITS.chunkBytes,source.bytes.length));
   if(!chunk.length)return;const data=btoa(String.fromCharCode(...chunk));
   request({op:'file-chunk',messageId:m.messageId,receiver:m.receiver,index:m.index,data});return;
  }
  if(m.op==='file-chunk')void takeChunk(m);
 }
 async function takeChunk(m){
  const d=downloads.get(m.messageId),row=rows.get(m.messageId);if(!d||d.state!=='receiving'||!row?.file||d.next!==m.index||row.file.id!==m.fileId)return;
  try{
   const chunk=Uint8Array.from(atob(m.data),c=>c.charCodeAt(0)),offset=m.index*CHAT_LIMITS.chunkBytes,expected=Math.min(CHAT_LIMITS.chunkBytes,row.file.size-offset);
   if(chunk.length!==expected)throw Error('조각 크기가 일치하지 않습니다.');d.bytes.set(chunk,offset);d.next++;d.updated=Date.now();d.retries=0;
   if(offset+chunk.length===row.file.size){
    d.state='verifying';changed();const hash=[...new Uint8Array(await crypto.subtle.digest('SHA-256',d.bytes))].map(x=>x.toString(16).padStart(2,'0')).join('');
    if(hash!==row.file.hash)throw Error('파일 해시 불일치. 다시 받으세요.');
    const info=inspectBytes(d.bytes,row.file.name);if(info.mime!==row.file.mime)throw Error('파일 형식 불일치');
    const blob=new Blob([d.bytes],{type:info.mime});if(info.mime.startsWith('image/')){const bitmap=await createImageBitmap(blob);bitmap.close();}
    files.set(row.file.id,{bytes:d.bytes,meta:row.file,url:URL.createObjectURL(blob),received:true});d.state='complete';report('파일 수신 완료 · SHA-256 일치');
   }else setTimeout(()=>{if(d.state==='receiving')requestNext(row,d);},25);
  }catch(error){d.state='failed';d.error=error.message;report(error.message);}
  // Progress must not replace the focused cancel button or any message controls.
  if(d.state==='receiving')refreshTransfer(row);else changed();
 }
 function requestNext(row,d){d.updated=Date.now();request({op:'file-request',messageId:row.id,index:d.next});}
 function cached(file){const value=files.get(file.id);return value&&value.meta.hash===file.hash&&value.meta.mime===file.mime&&value.meta.size===file.size?value:null;}
 function download(row){
  const source=cached(row.file);if(source?.url){const a=document.createElement('a');a.href=source.url;a.download=row.file.name;a.click();return;}
  if(downloads.get(row.id)?.state==='receiving')return;
  if([...downloads.values()].filter(x=>['receiving','verifying'].includes(x.state)).length>=CHAT_LIMITS.transfers){report('동시 전송은 2개까지입니다.');return;}
  let d=downloads.get(row.id);
  if(d?.next>=Math.ceil(row.file.size/CHAT_LIMITS.chunkBytes)){receivedBytes-=d.bytes.byteLength;downloads.delete(row.id);d=null;}
  if(!d){if(receivedBytes+row.file.size>64*1024*1024){report('기기 수신 캐시 64MiB 한도입니다. 대화를 새로 열기 전에 필요한 파일을 저장하세요.');return;}d={bytes:new Uint8Array(row.file.size),next:0};receivedBytes+=row.file.size;downloads.set(row.id,d);}
  d.state='receiving';d.error='';d.retries=0;requestNext(row,d);changed();
 }
 function cancel(row){const d=downloads.get(row.id);if(d){d.state='cancelled';request({op:'file-cancel',messageId:row.id});changed();}}
 function dropFile(fileId){const file=files.get(fileId);if(file){if(file.url)URL.revokeObjectURL(file.url);if(!file.received)providedBytes-=file.bytes.length;files.delete(fileId);}for(const[k,d]of downloads)if(rows.get(k)?.file?.id===fileId){receivedBytes-=d.bytes.length;downloads.delete(k);}}
 async function attach(list){
  for(const file of Array.from(list).slice(0,2)){
   try{if(providedBytes+file.size>64*1024*1024)throw Error('공유 파일 기기 캐시 64MiB 한도입니다.');report('파일 형식과 이미지 크기 확인 중…');const value=await prepareFile(file);providedBytes+=value.bytes.length;value.url=URL.createObjectURL(new Blob([value.bytes],{type:value.meta.mime}));files.set(value.meta.id,value);post('',value.meta);}
   catch(error){report(error.message);}
  }
 }
 function post(text,file=null){
  const message={op:'create',messageId:crypto.randomUUID(),channel:$('chatChannel').value,to:$('chatRecipient').value,text,file,replyTo};
  pending.set(message.messageId,{message,status:'sending',at:Date.now()});request(message);replyTo='';$('chatReply').hidden=true;changed();
 }
 function sendText(){if(composing)return;const value=$('chatText').value.trim();if(!value)return;if(editing){request({op:'edit',messageId:editing,text:value});editing='';}else post(value);$('chatText').value='';$('chatText').focus();}
 function control(text,fn){const b=document.createElement('button');b.type='button';b.className='secondary';b.textContent=text;b.onclick=fn;return b;}
 const observer=new IntersectionObserver(entries=>{for(const e of entries){if(!e.isIntersecting||panel.hidden||document.hidden||!document.hasFocus())continue;const row=rows.get(e.target.dataset.message);if(row&&!seen.has(row.id)){seen.add(row.id);acknowledge(row,'read');}}},{root:$('chatLines'),threshold:.75});
 function fileStatus(row){
  const f=row.file,local=cached(f),d=downloads.get(row.id);
  return local?'기기에 있음 · P2P 세션 공유':d?.state==='receiving'?'수신 중 '+Math.floor(Math.min(1,d.next*CHAT_LIMITS.chunkBytes/f.size)*100)+'%':d?.state==='verifying'?'무결성 확인 중':d?.state==='cancelled'?'취소됨 · 이어받기 가능':d?.state==='failed'?'실패 · '+d.error:members().some(p=>p.id===f.provider)?'받기 대기':'원본 제공자 오프라인';
 }
 function refreshTransfer(row){
  const article=[...$('chatLines').children].find(node=>node.dataset.message===row.id),status=article?.querySelector('.chat-file-status');
  if(status)status.textContent=fileStatus(row);
 }
 function render(){
  refreshMembers();const list=$('chatLines'),wasBottom=list.scrollHeight-list.scrollTop-list.clientHeight<100,scroll=list.scrollTop;observer.disconnect();list.replaceChildren();
  const term=$('chatSearch').value.trim().toLowerCase();let date='';
  for(const row of rows.values()){
   if(row.channel!==selected()||(mediaOnly&&!row.file)||term&&!((row.text+' '+row.name+' '+(row.file?.name||'')).toLowerCase().includes(term)))continue;
   const day=new Date(row.createdAt).toLocaleDateString('ko-KR');if(day!==date){date=day;const divider=document.createElement('p');divider.className='chat-date';divider.textContent=day;list.append(divider);}
   const article=document.createElement('article');article.className='chat-message'+(row.sender===id()?' mine':'');article.dataset.message=row.id;
   const meta=document.createElement('small');meta.textContent=row.name+' · '+new Date(row.createdAt).toLocaleTimeString('ko-KR',{hour:'2-digit',minute:'2-digit'})+(row.editedAt?' · 수정됨':'');article.append(meta);
   if(row.archived){const note=document.createElement('small');note.textContent='호스트 이전 전 대화 · 읽기 전용';article.append(note);}
   if(row.replyTo){const quote=document.createElement('blockquote');quote.textContent=row.replyText;article.append(quote);}
   const text=document.createElement('p');text.textContent=row.deleted?'삭제된 메시지입니다.':row.text;article.append(text);
   if(row.file){
    const f=row.file,local=cached(f),d=downloads.get(row.id),info=document.createElement('div');info.className='chat-file';const detail=document.createElement('p');detail.textContent=f.name+' · '+(f.size/1024).toFixed(1)+' KiB';info.append(detail);
    if(local?.url&&f.mime.startsWith('image/')){const img=document.createElement('img');img.src=local.url;img.alt=f.name;img.loading='lazy';img.onclick=()=>{const dialog=document.createElement('dialog'),large=document.createElement('img');dialog.className='chat-image-dialog';large.src=local.url;large.alt=f.name;dialog.append(large,control('닫기',()=>{dialog.close();dialog.remove();}));document.body.append(dialog);dialog.addEventListener('cancel',()=>dialog.remove());dialog.showModal();};info.append(img);}
    const status=document.createElement('small');status.className='chat-file-status';status.textContent=fileStatus(row);info.append(status);
    if(row.archived&&!local){status.textContent='호스트 이전 · 원본을 새 대화에 다시 공유하세요.';}else if(d?.state==='receiving')info.append(control('취소',()=>cancel(row)));else info.append(control(local?'내려받기':d?'재시도 / 이어받기':'파일 받기',()=>download(row)));article.append(info);
   }
   const actions=document.createElement('div');actions.className='chat-actions';
   if(!row.deleted&&!row.archived){actions.append(control('답장',()=>{replyTo=row.id;$('chatReply').hidden=false;$('chatReply').textContent='답장: '+row.text.slice(0,80);$('chatText').focus();}));for(const emoji of ['👍','✅','💡'])actions.append(control(emoji+(row.reactions[emoji]?.length?' '+row.reactions[emoji].length:''),()=>request({op:'react',messageId:row.id,emoji})));
    if(row.sender===id()){actions.append(control('수정',()=>{editing=row.id;$('chatText').value=row.text;$('chatText').focus();}),control('삭제',()=>request({op:'delete',messageId:row.id})));}}
   if(row.sender===id()){const state=document.createElement('small');state.textContent='접수됨 · 수신 '+row.delivered.length+' · 읽음 '+row.read.length;actions.append(state);}article.append(actions);list.append(article);observer.observe(article);
  }
  for(const[value,p]of pending){const row=document.createElement('p');row.textContent=p.message.text+' · '+(p.status==='failed'?'전송 실패':'전송 중');if(p.status==='failed')row.append(control('재시도',()=>{p.status='sending';p.at=Date.now();request(p.message);changed();}));list.append(row);}
  list.scrollTop=wasBottom?list.scrollHeight:scroll;
 }
 function open(){if(!id())return;pause();panel.hidden=false;unread=0;button.textContent='대화 · Enter';refreshMembers();render();$('chatText').focus();}
 function close(){panel.hidden=true;resume();}
 $('chatForm').onsubmit=e=>{e.preventDefault();sendText();};$('closeChat').onclick=close;
 $('chatText').addEventListener('compositionstart',()=>composing=true);$('chatText').addEventListener('compositionend',()=>composing=false);
 $('chatText').onkeydown=e=>{if(e.key==='Enter'&&!e.shiftKey&&!e.isComposing&&!composing&&e.keyCode!==229){e.preventDefault();sendText();}};
 $('chatFile').onchange=e=>{void attach(e.target.files);e.target.value='';};panel.ondragover=e=>{e.preventDefault();};panel.ondrop=e=>{e.preventDefault();void attach(e.dataTransfer.files);};
 $('chatText').onpaste=e=>{const list=[...e.clipboardData.items].filter(x=>x.kind==='file').map(x=>x.getAsFile());if(list.length){e.preventDefault();void attach(list);}};
 $('chatChannel').onchange=()=>{$('chatRecipient').hidden=$('chatChannel').value!=='dm';replyTo='';editing='';render();};$('chatRecipient').onchange=render;$('chatSearch').oninput=render;$('chatMedia').onclick=()=>{mediaOnly=!mediaOnly;$('chatMedia').textContent=mediaOnly?'모든 메시지':'파일 모아보기';render();};
 document.addEventListener('keydown',e=>{if(window.Homeoffice?.key_matches(e,'chat')&&panel.hidden&&e.target===document.getElementById('canvas')){e.preventDefault();open();}else if(e.code==='Escape'&&!panel.hidden){e.preventDefault();e.stopImmediatePropagation();close();}},true);
 const timer=setInterval(()=>{for(const p of pending.values())if(p.status==='sending'&&Date.now()-p.at>8000){p.status='failed';changed();}for(const[key,d]of downloads)if(d.state==='receiving'&&Date.now()-d.updated>5000){if(++d.retries>3){d.state='failed';d.error='응답 시간 초과';}else{const row=rows.get(key);if(row)requestNext(row,d);}changed();}if(!panel.hidden)refreshMembers();},1000);
 return {receive,handoff(){authority.reset();for(const row of rows.values())row.archived=true;for(const d of downloads.values())if(d.state!=='complete'){d.state='failed';d.error='호스트 이전으로 전송 종료 · 새 대화에 다시 공유하세요.';}for(const p of pending.values())p.status='failed';changed();},name:()=>name.value.trim().slice(0,24)||'친구',hide(){panel.hidden=true;},diagnostics:()=>({messages:rows.size,unread,files:[...files.values()].map(x=>({name:x.meta.name,hash:x.meta.hash,size:x.meta.size,received:!!x.received})),transfers:[...downloads.values()].map(x=>({state:x.state,next:x.next})),authority:authority.diagnostics()}),reset(){for(const f of files.values())if(f.url)URL.revokeObjectURL(f.url);rows.clear();files.clear();downloads.clear();pending.clear();seen.clear();authority.reset();providedBytes=0;receivedBytes=0;unread=0;changed();},destroy(){clearInterval(timer);clearTimeout(renderTimer);observer.disconnect();for(const f of files.values())if(f.url)URL.revokeObjectURL(f.url);panel.remove();button.remove();}};
}
