import {MEETING_ROOMS,createMeetingPolicy,validateMeetingArchive} from './meeting-policy.mjs';
import {createCollaboration} from './collaboration.mjs';
import {createPresentation} from './presentation.mjs';
import {validateDocument,validateRegistry} from './document-registry.mjs';

export function createMeetingWorkspace({identity,isHost,isMember,members,send,notify,inWorld,inWorldPointer,name,sessionKey,onVisibility=()=>{}}) {
  const policy=createMeetingPolicy({isMember}), rooms=new Map();
  let active='',grant=null,pending='',visible=false,offline=false,revoked=false,tab='report',cacheDb=null;
  const root=document.createElement('section');root.id='meetingWorkspace';root.hidden=true;
  root.innerHTML=`<header class="workspace-heading"><div><small>COMMONS · 함께 일하는 공간</small><h2>회의 작업대</h2></div><label>참여할 회의 <select id="meetingRoom"></select></label><button id="meetingJoin">회의 참여</button></header><p id="meetingStatus" role="status">회의를 선택하고 참여하세요. 회의별 문서와 발표 자료가 분리됩니다.</p><div id="meetingPeople"></div><nav class="workspace-tabs"><button data-work-tab="report">공동 문서</button><button data-work-tab="board">화이트보드</button><button data-work-tab="brainstorm">아이디어</button><button data-work-tab="mindmap">마인드맵</button><button data-work-tab="meeting">의제 · 결정 · 할 일</button><button data-work-tab="presentation">발표</button><button data-work-tab="documents">원본 자료</button></nav><div id="meetingBody"></div>`;
  document.querySelector('.tool-panel').append(root);
  const $=id=>root.querySelector('#'+id);
  for(const room of MEETING_ROOMS)$('meetingRoom').append(new Option(room.title,room.id));
  const info=text=>{$('meetingStatus').textContent=text;};
  const peerName=who=>members().find(p=>p.id===who)?.displayName||members().find(p=>p.id===who)?.name||who.slice(-6);
  function state(room){return {id:room.id,collaboration:room.collab.snapshot(),documents:structuredClone(room.documents),presentation:room.presentation.metadata(),presentationView:room.presentation.view(),board:structuredClone(room.board)};}
  function cache(room){
    if(!cacheDb||!sessionKey()||revoked)return;
    try{const tx=cacheDb.transaction('drafts','readwrite');tx.objectStore('drafts').put({update:room.collab.snapshot().update,at:Date.now()},sessionKey()+':'+room.id);tx.oncomplete=()=>{if(active===room.id&&!revoked)info(offline?'연결 끊김 · 이 기기에만 초안 저장됨':'이 기기에 초안 저장됨 · 상대 수신은 연결 상태에 따릅니다.');};}catch{}
  }
  if(globalThis.indexedDB){const req=indexedDB.open('commons-meeting-drafts-v1',1);req.onupgradeneeded=()=>req.result.createObjectStore('drafts');req.onsuccess=()=>{cacheDb=req.result;};}
  function outgoing(room,channel,data,to=''){
    if(offline||revoked)return;
    if(isHost()){
      for(const who of policy.peers(room.id))if(who!==identity()&&(!to||who===to))send({type:'meeting-data',meetingId:room.id,channel,data,from:identity()},who);
    }else if(grant?.meetingId===room.id)send({type:'meeting-data',meetingId:room.id,generation:grant.generation,channel,data});
  }
  function ensure(meetingId){
    if(rooms.has(meetingId))return rooms.get(meetingId);
    if(!MEETING_ROOMS.some(r=>r.id===meetingId))throw Error('알 수 없는 회의');
    const node=document.createElement('section');node.dataset.meeting=meetingId;node.hidden=true;$('meetingBody').append(node);
    const room={id:meetingId,node,documents:[],board:[],peers:[]};rooms.set(meetingId,room);
    room.collab=createCollaboration({mount:node,scopeId:'meeting-'+meetingId,identity,name,notify,send:data=>{outgoing(room,'collab',data);if(data.type==='collab')cache(room);}});
    room.presentation=createPresentation({mount:node,scopeId:'meeting-'+meetingId,identity,isHost,members:()=>members().filter(p=>room.peers.includes(p.id)),notify,send:(data,to)=>outgoing(room,'presentation',data,to),inWorld:image=>inWorld(room.id,image),inWorldPointer:uv=>inWorldPointer(room.id,uv)});
    const resources=document.createElement('section');resources.className='meeting-resources';resources.hidden=true;
    resources.innerHTML='<h3>같은 원본에서 공동 편집</h3><p>Google·Microsoft의 원본 공유 권한은 각 계정에서 확인해야 합니다. 등록은 원본 편집 권한을 만들지 않습니다.</p><form><input name="name" placeholder="자료 이름" maxlength="120" required><select name="provider"><option value="docs">Google Docs</option><option value="slides">Google Slides</option><option value="excel">Microsoft Excel</option></select><input name="url" type="url" placeholder="원본 공유 링크" required><button>회의에 등록</button></form><div class="resource-list"></div><p>공간 파일에는 외부 원본 링크만 보관합니다. 외부 문서 내용은 해당 서비스에서 저장하세요.</p>';
    resources.querySelector('form').onsubmit=e=>{e.preventDefault();try{const f=new FormData(e.target),doc=validateDocument({id:crypto.randomUUID(),name:f.get('name'),provider:f.get('provider'),url:f.get('url')});command(room,'resource-add',{document:doc});e.target.reset();}catch(err){notify(err.message);}};
    room.resources=resources;node.append(resources);
    const board=document.createElement('section');board.hidden=true;board.innerHTML='<div class="row"><label>잉크 <input type="color" value="#344044"></label><label>굵기 <input type="range" min="1" max="16" value="4"></label><button>내 마지막 획 되돌리기</button></div><canvas width="1280" height="720" aria-label="회의별 공동 화이트보드"></canvas>';
    const canvas=board.querySelector('canvas');let stroke=null;
    const point=e=>{const b=canvas.getBoundingClientRect();return [Math.max(0,Math.min(1,(e.clientX-b.x)/b.width)),Math.max(0,Math.min(1,(e.clientY-b.y)/b.height))];};
    canvas.onpointerdown=e=>{stroke={id:crypto.randomUUID(),author:identity(),points:[point(e)],color:board.querySelector('[type=color]').value,width:Number(board.querySelector('[type=range]').value)};canvas.setPointerCapture(e.pointerId);};
    canvas.onpointermove=e=>{if(stroke&&stroke.points.length<256){stroke.points.push(point(e));paint(room,stroke);}};
    canvas.onpointerup=()=>{if(stroke?.points.length>1)command(room,'board-add',{stroke});stroke=null;paint(room);};canvas.onpointercancel=()=>{stroke=null;paint(room);};board.querySelector('button').onclick=()=>command(room,'board-undo',{});
    room.boardPane=board;room.canvas=canvas;node.append(board);paint(room);
    return room;
  }
  function paint(room,preview){const c=room.canvas.getContext('2d');c.fillStyle='#fffcf4';c.fillRect(0,0,1280,720);for(const s of [...room.board,...(preview?[preview]:[])]){c.strokeStyle=s.color;c.lineWidth=s.width;c.lineCap='round';c.beginPath();s.points.forEach((p,i)=>i?c.lineTo(p[0]*1280,p[1]*720):c.moveTo(p[0]*1280,p[1]*720));c.stroke();}}
  function renderResources(room){const list=room.resources.querySelector('.resource-list');list.replaceChildren();for(const row of room.documents){const card=document.createElement('article'),label=document.createElement('strong'),button=document.createElement('button');label.textContent=row.name;button.textContent='원본 공동편집 열기';button.onclick=()=>{window.open(row.url,'_blank','noopener,noreferrer,width=1100,height=800');info('원본 창을 요청했습니다. 팝업 차단과 원본 공유 권한을 확인하세요.');};card.append(label,button);list.append(card);}}
  function command(room,kind,data){if(isHost()){applyCommand(room,identity(),{kind,...data});outgoing(room,'tools',{kind:'state',documents:room.documents,board:room.board});}else outgoing(room,'tools',{kind,...data});}
  function applyCommand(room,peer,m){
    if(m.kind==='resource-add')room.documents=validateRegistry([...room.documents,validateDocument(m.document)]);
    else if(m.kind==='board-add'){const stroke={...m.stroke,author:peer};validateMeetingArchive([{...state(room),board:[...room.board,stroke]}]);if(!room.board.some(s=>s.id===stroke.id))room.board.push(stroke);}
    else if(m.kind==='board-undo'){const at=room.board.findLastIndex(s=>s.author===peer);if(at>=0)room.board.splice(at,1);}else return false;
    renderResources(room);paint(room);return true;
  }
  function show(){root.dataset.view=tab;root.querySelectorAll('[data-work-tab]').forEach(b=>b.setAttribute('aria-current',String(b.dataset.workTab===tab)));for(const room of rooms.values()){room.node.hidden=room.id!==active;room.collab.hide();room.presentation.hide();room.resources.hidden=true;room.boardPane.hidden=true;}
    if(!active)return;const room=ensure(active);room.node.hidden=false;room.node.inert=revoked||!isHost()&&grant?.meetingId!==active&&!offline;root.querySelectorAll('[data-work-tab]').forEach(button=>button.disabled=offline&&['board','presentation','documents'].includes(button.dataset.workTab));
    if(tab==='presentation')room.presentation.open();else if(tab==='documents'){room.resources.hidden=false;renderResources(room);}else if(tab==='board'){room.boardPane.hidden=false;paint(room);}else room.collab.open(tab);
  }
  function announce(meetingId){const room=ensure(meetingId);room.peers=policy.peers(meetingId);outgoing(room,'members',{peers:room.peers});renderPeople();}
  function renderPeople(){const room=rooms.get(active),box=$('meetingPeople');box.replaceChildren();for(const who of room?.peers||[]){const chip=document.createElement('span');chip.textContent=peerName(who);if(isHost()&&who!==identity()){const button=document.createElement('button');button.textContent='참여 중지';button.setAttribute('aria-label',peerName(who)+' 회의 참여 중지');button.onclick=()=>{policy.revoke(who,room.id);send({type:'meeting-revoked',meetingId:room.id},who);room.collab.clearPresence(who);announce(room.id)};chip.append(button)}box.append(chip)}}
  async function join(meetingId){
    if(offline){info('연결이 끊겼습니다. 재연결 후 회의를 바꿀 수 있습니다.');return;}if(!MEETING_ROOMS.some(r=>r.id===meetingId))return;revoked=false;active=meetingId;const room=ensure(meetingId);$('meetingRoom').value=meetingId;grant=null;show();
    if(cacheDb&&sessionKey()){await new Promise(resolve=>{const req=cacheDb.transaction('drafts').objectStore('drafts').get(sessionKey()+':'+meetingId);req.onsuccess=()=>{if(req.result)room.collab.receive({update:req.result.update});resolve();};req.onerror=resolve;});}
    pending=crypto.randomUUID();
    if(isHost()){const previous=policy.current(identity());grant=policy.join(identity(),meetingId);if(!grant)return;if(previous&&previous!==meetingId)announce(previous);announce(meetingId);show();info('이 회의에 참여했습니다 · 현재 세션에서 함께 편집');}
    else{send({type:'meeting-join',meetingId,requestId:pending,vector:room.collab.vector()});info('회의 참여 승인과 변경 내용을 확인하는 중…');}
  }
  async function receive(sender,m){
    if(!m.type?.startsWith('meeting-'))return false;
    try{
      if(isHost()){
        if(!isMember(sender))return true;
        if(m.type==='meeting-join'){
          if(typeof m.requestId!=='string'||m.requestId.length>80||typeof m.vector!=='string'||m.vector.length>16000)return true;
          const previous=policy.current(sender);const next=policy.join(sender,m.meetingId);if(!next){send({type:'meeting-denied',requestId:m.requestId},sender);return true;}
          if(previous&&previous!==m.meetingId)announce(previous);const room=ensure(m.meetingId);send({type:'meeting-grant',requestId:m.requestId,...next,update:room.collab.delta(m.vector),vector:room.collab.vector(),documents:room.documents,board:room.board,peers:policy.peers(room.id)},sender);room.presentation.sync(sender);announce(room.id);return true;
        }
        if(m.type!=='meeting-data'||!policy.permits(sender,m.meetingId,m.generation))return true;
        const room=ensure(m.meetingId);
        if(m.channel==='collab'){
          const data={...m.data,from:sender};if(!room.collab.receive(data))return true;
          for(const who of policy.peers(room.id))if(who!==identity())send({type:'meeting-data',meetingId:room.id,channel:'collab',data,from:sender},who);cache(room);
        }else if(m.channel==='presentation')await room.presentation.receive(sender,m.data);
        else if(m.channel==='tools'&&applyCommand(room,sender,m.data))outgoing(room,'tools',{kind:'state',documents:room.documents,board:room.board});
        return true;
      }
      if(m.type==='meeting-revoked'&&m.meetingId===active){grant=null;revoked=true;offline=false;ensure(active).collab.clearPresence();show();info('회의 참여가 중지되었습니다. 이미 받은 내용은 읽기 전용으로 남습니다.');return true;}
      if(m.type==='meeting-denied'){if(m.requestId===pending){grant=null;revoked=true;show();info('이 회의에 참여할 권한이 없습니다.');}return true;}
      if(m.type==='meeting-grant'){
        if(m.requestId!==pending||m.meetingId!==active)return true;
        const room=ensure(active);validateRegistry(m.documents);validateMeetingArchive([{...state(room),board:m.board}]);grant={meetingId:active,generation:m.generation};room.collab.receive({update:m.update});room.documents=m.documents;room.board=m.board;room.peers=m.peers;outgoing(room,'collab',{type:'collab',update:room.collab.delta(m.vector)});renderPeople();show();info('회의 연결됨 · 상대 변경 내용을 합쳤습니다');return true;
      }
      if(m.type!=='meeting-data'||m.meetingId!==grant?.meetingId)return true;
      const room=ensure(m.meetingId);
      if(m.channel==='collab'){room.collab.receive({...m.data,from:m.from});cache(room);}
      else if(m.channel==='presentation')await room.presentation.receive(sender,m.data);
      else if(m.channel==='members'){room.peers=m.data.peers.filter(p=>typeof p==='string');renderPeople();}
      else if(m.channel==='tools'&&m.data.kind==='state'){room.documents=validateRegistry(m.data.documents);validateMeetingArchive([{...state(room),board:m.data.board}]);room.board=m.data.board;renderResources(room);paint(room);}
    }catch(err){notify('회의 데이터 거절: '+err.message);}return true;
  }
  $('meetingJoin').onclick=()=>join($('meetingRoom').value);
  root.querySelectorAll('[data-work-tab]').forEach(button=>button.onclick=()=>{tab=button.dataset.workTab;show();});
  return {
    physicalPointer(actor,meetingId,uv){if(isHost()&&policy.current(actor)===meetingId)rooms.get(meetingId)?.presentation.physicalPointer(actor,uv);},
    connectionLost(){if(!active||revoked)return;offline=true;grant=null;for(const room of rooms.values())room.collab.clearPresence();tab='report';show();info('연결 끊김 · 문서 초안은 이 기기에 저장합니다. 재연결 후 권한을 확인하고 합칩니다.');},reconnect(){offline=false;if(active&&!revoked)join(active);},composing(){return [...rooms.values()].some(room=>room.collab.diagnostics().composing);},
    receive,join,open(meetingId){root.hidden=false;visible=true;onVisibility(true);if(meetingId&&meetingId!==active)join(meetingId);else show();},hide(){if(visible)onVisibility(false);visible=false;root.hidden=true;},
    snapshot(){return [...rooms.values()].map(state);},snapshotFor(peer){const key=policy.current(peer);return key&&rooms.has(key)?[state(rooms.get(key))]:[];},
    attachments(){return new Map([...rooms.values()].flatMap(room=>[...room.presentation.attachments]));},
    async validate(rows,files){for(const row of validateMeetingArchive(rows)){const room=ensure(row.id);room.collab.validate(row.collaboration);validateRegistry(row.documents);await room.presentation.validate(row.presentation,files);}return true;},
    restore(rows=[],files=new Map()){const archive=validateMeetingArchive(rows);for(const row of archive){ensure(row.id).collab.validate(row.collaboration);validateRegistry(row.documents);}policy.reset();grant=null;offline=false;revoked=false;for(const room of rooms.values()){room.collab.restore();room.collab.clearPresence();room.documents=[];room.board=[];room.presentation.restore([],new Map());room.peers=[];}for(const row of archive){const room=ensure(row.id);room.collab.restore(row.collaboration);room.collab.clearPresence();room.documents=validateRegistry(row.documents);room.board=row.board;room.presentation.restore(row.presentation,files,row.presentationView);room.peers=[];}if(isHost()&&active){grant=policy.join(identity(),active);announce(active)}show();},
    leave(peer){const key=policy.current(peer);policy.leave(peer);for(const room of rooms.values())room.collab.clearPresence(peer);if(key&&isHost())announce(key);},
    sameMeeting(a,b){return !!policy.current(a)&&policy.current(a)===policy.current(b);},
    scopeOf(peer){return isHost()?policy.current(peer):rooms.get(active)?.peers.includes(peer)?active:'';},
    diagnostics(){return {open:visible,active,offline,revoked,grant:grant?{meetingId:grant.meetingId}:null,rooms:[...rooms.values()].map(room=>({id:room.id,peers:room.peers,collaboration:room.collab.diagnostics(),board:room.board.length,presentation:room.presentation.diagnostics(),documents:room.documents}))};},
  };
}
