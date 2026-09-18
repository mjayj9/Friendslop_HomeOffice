import {createCampusUI} from './campus-ui.mjs';
import {createMeetingWorkspace} from './meeting-workspace.mjs';
import {createWardrobe} from './wardrobe.mjs';
import {createPlacementPanel} from './placement-panel.mjs';
import {renderEntryNotice} from './presentation-copy.mjs';
import {createRoomAdmin} from './room-admin.mjs';
import {createStateCodec} from './state-codec.mjs';
import {createBroadcast} from './broadcast.mjs';
import {BUILD_ID} from './build-id.mjs';
import {createRoomCode,parseInvitation,invitationLink,PROTOCOL_VERSION} from './invitations.mjs';
import {claimRoom,resolveRoom,reclaimRoom} from './session-directory.mjs';
import {createDocumentRegistry} from './document-registry.mjs';
import {createGameplayHud} from './gameplay-hud.mjs';
import {createBindings} from './key-bindings.mjs';
import {createArcade} from './arcade.mjs';
import {createSocial} from './social.mjs';
import {createBoardTools} from './board-tools.mjs';
import {createHandoff} from './handoff.mjs';
import {createPresentation} from './presentation.mjs';
import {createCollaboration} from './collaboration.mjs';
import {createActivities} from './activities.mjs';
import {createCaptions} from './captions.mjs';
import {encodeWorld,decodeWorld,decodeBundle,validateWorld} from './save-v2.mjs';
const $=id=>document.getElementById(id),events=[],connections=new Map(),incoming=new Map(),outgoing=new Map(),gains=new Map();
renderEntryNotice(document.getElementById("entryNotice"));
const params=new URLSearchParams(location.search);
let lastCommandResult=null;let cursorPaused=false;
let adminSession='';
let roomCode='',directoryPeer=null,classroomSession=false,avatarDiagnostics={},stateReceived=0;
let clientIdentity;try{clientIdentity=localStorage.getItem('moyeo-client-id')||crypto.randomUUID();localStorage.setItem('moyeo-client-id',clientIdentity)}catch{clientIdentity=crypto.randomUUID()}
let recoverPending=null;let perfSample={};let handoffSwitching=false;let pendingAttachments=new Map();
let peer,host=false,id='',epoch='',room='',playing=false,loaded=false,currentState=null,boardStrokes=[],pendingWorld=null,lastWorld=null,recoveryTime='',micStream=null,meterStream=null,context=null,meterSource=null,analyser=null,ptt=false,muted=true,boardPoints=null,page=0,statusTimer;
const gameplayHud=createGameplayHud();
const documents=createDocumentRegistry({openTool,identity:()=>id,isHost:()=>host,send:(m,to='')=>net({...m,epoch},to),canEdit:who=>canCollaborate(who),notify:status});
const collabAllowed=new Set();
let voiceBeforeBroadcast='near';
let voiceMode='near',voiceMax=24,broadcastAllowed=new Set(),voiceModes={},blocksByPeer={};const blocked=new Set();
let activePeers=new Set(),rangeByPeer={},range=8,lastStateAt=0;let menuVisible=false;
const micFlags={echoCancellation:true,noiseSuppression:true,autoGainControl:true,channelCount:1};
const presentation=createPresentation({send:(m,to='')=>net({...m,epoch},to),identity:()=>id,isHost:()=>host,members:()=>currentState?.players,inWorld:image=>push({type:'slide_texture',image}),inWorldPointer:uv=>push({type:'slide_pointer',uv}),notify:s=>status(s)});
const collaboration=createCollaboration({send:m=>{if(id)net({...m,epoch,from:id})},notify:s=>status(s),identity:()=>id});
const meetingWorkspace=createMeetingWorkspace({onVisibility:open=>push({type:'workspace_visibility',open}),identity:()=>id,isHost:()=>host,isMember:who=>who===id||activePeers.has(who),members:()=>currentState?.players||[],send:(m,to='')=>net({...m,epoch},to),notify:status,name:()=>social.name(),sessionKey:()=>roomCode?roomCode+':'+(adminSession||epoch):'',inWorld:(meetingId,image)=>push({type:'campus_slide',meetingId,image}),inWorldPointer:(meetingId,uv)=>push({type:'campus_pointer',meetingId,uv})});
const campusUI=createCampusUI({push,close:resume});
const workspaceButton=document.createElement('button');workspaceButton.id='openMeetingWorkspace';workspaceButton.textContent='공동 작업';workspaceButton.onclick=()=>openTool('workspace');$('installObjects').after(workspaceButton);
function allAttachments(){return new Map([...presentation.attachments,...meetingWorkspace.attachments()]);}
const activities=createActivities({action:(action,data)=>push(action==='build_begin'?{type:'build',kind:data.kind}:{type:'action',action,data}),close:resume,identity:()=>id,send:m=>{if(id)net({...m,epoch})},notify:s=>status(s)});
const wardrobe=createWardrobe({push,storageKey:'commons-appearance-v1:'+clientIdentity,pause:()=>{playing=false;ptt=false;gateVoice();push({type:'ui_focus',focused:true});document.exitPointerLock?.();$('menu').hidden=true;$('tool').hidden=true;},resume,notify:status});
const placement=createPlacementPanel({canvas:$('canvas'),push,onClose:resume,onOpen:()=>{campusUI.hide();meetingWorkspace.hide();push({type:'ui_focus',focused:true});push({type:'activity',mode:'catalog'});playing=false;ptt=false;gateVoice();document.exitPointerLock?.();$('menu').hidden=true;$('tool').hidden=true;broadcast.hide();documents.hide();collaboration.hide();activities.hide();presentation.hide();arcade.hide();}});
$('installObjects').onclick=()=>{wardrobe.cancel();placement.open()};
// Release mouse capture for visible controls; the recapture click is consumed.
window.addEventListener('keydown',e=>{if(e.code==='Tab'&&playing&&document.activeElement===$('canvas')){e.preventDefault();e.stopImmediatePropagation();cursorPaused=true;playing=false;push({type:'ui_focus',focused:true});document.exitPointerLock?.();$('installObjects').focus();status('마우스를 움직여 화면 버튼을 누르세요. 공간을 클릭하면 돌아갑니다.');}},true);
$('canvas').addEventListener('pointerdown',e=>{if(cursorPaused&&$('menu').hidden&&$('tool').hidden&&!placement.diagnostics().open){e.preventDefault();e.stopImmediatePropagation();resume();}},true);

const broadcast=createBroadcast({identity:()=>id,isHost:()=>host,isClassroom:()=>classroomSession,players:()=>currentState?.players||[],authorized:who=>roomAdmin.authorized(who),send:(m,to='')=>net({...m,epoch},to),notify:status,onState:state=>push({type:"broadcast_visual",active:!!state.speaker}),onMode:mode=>{if(mode==='near'&&voiceMode!=='broadcast')return;if(mode==='broadcast'&&voiceMode!=='broadcast')voiceBeforeBroadcast=voiceMode;voiceMode=mode==='near'?voiceBeforeBroadcast:mode;mode=voiceMode;voiceModes[id]=mode;$('voiceMode').value=mode;if(!host)net({type:'voice-settings',range,mode});}});
const captions=createCaptions({send:m=>{if(m.type==='caption-generation'){if(host)net({...m,epoch,speaker:id});else net({...m,epoch});}else if(host)relayCaption(id,m);else net({...m,epoch})},canTransmit:()=>transmitting(),identity:()=>id,stream:()=>micStream,notify:s=>status(s)});
function canCollaborate(who){const a=currentState?.players.find(p=>p.id===who);return !!a&&(a.zone==='meeting'||a.zone==='resources'||a.zone==='free'||a.zone==='dining'||a.zone==='living'||a.zone==='reading'||a.zone?.startsWith('office-'))}
function voiceScope(sender,receiver){if((blocksByPeer[receiver]||[]).includes(sender)||receiver===id&&blocked.has(sender))return false;const a=currentState?.players.find(p=>p.id===sender),b=currentState?.players.find(p=>p.id===receiver);if(!a||!b)return false;const mode=sender===id?voiceMode:(voiceModes[sender]||'near');if(mode==='broadcast')return broadcast.canHear(sender,receiver);if(mode==='session')return true;if(mode==='zone')return a.zone===b.zone;const sa=meetingWorkspace.scopeOf(sender),sb=meetingWorkspace.scopeOf(receiver);if(sa||sb){if(!sa||sa!==sb)return false;}if(Math.abs(a.p[1]-b.p[1])>2.5)return false;return Math.hypot(...a.p.map((v,i)=>v-b.p[i]))<Math.min(voiceMax,sender===id?range:(rangeByPeer[sender]||8))}
function relayCaption(sender,m){if(m.epoch&&m.epoch!==epoch||typeof m.text!=='string'||m.text.length>400||!Number.isSafeInteger(m.sequence)||typeof m.utterance!=='string'||m.utterance.length>80)return;const out={type:'caption',epoch,speaker:sender,generation:m.generation??0,broadcast:broadcast.active().speaker===sender,text:m.text,sequence:m.sequence,utterance:m.utterance,final:!!m.final};if(sender!==id&&voiceScope(sender,id))captions.show(out);for(const[who,c]of connections)if(who!==sender&&voiceScope(sender,who))sendRaw(c,out)}
function status(s){$('status').textContent=s;clearTimeout(statusTimer);statusTimer=setTimeout(()=>{$('status').textContent=''},8000)}
function push(e){if(events.length<256)events.push(e)}
const keyBindings=createBindings({changed:bindings=>push({type:'bindings',bindings})});
function isMember(who){return activePeers.has(who)}
const sendQueues=new Map();
const stateCodec=createStateCodec();
function sendRaw(c,m){if(!c?.open)return;const q=sendQueues.get(c)||{urgent:[],bulk:[],bytes:0};const text=JSON.stringify(m),size=text.length;if(['input','state','voice-ranges','arcade-progress'].includes(m.type)){if(c.dataChannel?.bufferedAmount<96*1024)try{c.send(m.type==='state'&&host?stateCodec.encode(c.peer,m):m)}catch{}return}if(q.bytes+size>4*1024*1024){status('전송 대기 한도입니다. 큰 자료는 취소 후 다시 요청하세요.');return}q.bytes+=size;(m.type.startsWith('asset-')||m.type==='meeting-data'&&m.channel==='presentation'&&m.data?.type?.startsWith('asset-')||m.type==='chat'&&m.op==='file-chunk'?q.bulk:q.urgent).push({m,size});sendQueues.set(c,q)}
setInterval(()=>{for(const[c,q]of sendQueues){if(!c.open){sendQueues.delete(c);continue}if(c.dataChannel?.bufferedAmount>96*1024)continue;const item=q.urgent.shift()||q.bulk.shift();if(item){q.bytes-=item.size;try{c.send(item.m)}catch{}}}},25);
function net(m,to=''){if(host){for(const [who,c]of connections)if(!to||to===who)sendRaw(c,m)}else{const c=connections.get(room);if(c)sendRaw(c,m)}}
function entered(){setTimeout(()=>{const profile=wardrobe.saved();if(profile)push({type:'appearance_bootstrap',profile})},650);roomAdmin.setSession(adminSession||epoch);setTimeout(()=>{if(host)push({type:'profile',id,name:social.name()});else net({type:'profile',epoch,name:social.name()})},350);context??=new AudioContext();context.resume().catch(()=>{});playing=true;$('entry').hidden=true;$('menu').hidden=true;$('topbar').hidden=false;$('reticle').hidden=false;$('canvas').focus();cursorPaused=true;push({type:'resume',capture:false});$('invitation').textContent=peer?'초대 코드: '+(roomCode==='classroom'?'교실':roomCode):'혼자 둘러보기 · 온라인 세션을 열려면 새로고침하세요.';$('copyInvite').hidden=!peer;$('copyInviteLink').hidden=!peer;$('network').textContent=host?'방장 · '+(peer?'초대 가능':'혼자 둘러보기'):'친구의 집에 연결됨'}
function peerOptions(){return params.get('signal')==='local'?{host:'127.0.0.1',port:9001,path:'/homeoffice',secure:false,debug:1}:{debug:1,config:{iceServers:[{urls:'stun:stun.l.google.com:19302'}]}}}
function createPeer(who){const p=new Peer(who,peerOptions());p.on('error',e=>{status('실제 연결 실패: '+e.type+' · 재시도하거나 혼자 둘러보세요.');$('loading').textContent='시그널링 연결 실패 · '+e.type;if(!playing&&!connections.size){p.destroy();if(peer===p)peer=null}});p.on('disconnected',()=>status('시그널링 연결이 끊겼습니다. 기존 P2P 연결 상태를 확인합니다.'));p.on('call',receiveVoice);return p}
function bind(c){
 let count=0,windowAt=performance.now();
 c.on('open',()=>{
  if(host&&(c.metadata?.protocolVersion!==PROTOCOL_VERSION||c.metadata?.buildId!==BUILD_ID)){c.send({type:'session-reject',reason:'서로 다른 게임 버전입니다. 양쪽 모두 새로고침하세요.'});setTimeout(()=>c.close(),400);return}
  if(host&&(handoff.active()&&!handoffSwitching||connections.size>=7||connections.has(c.peer))){c.send({type:'session-reject',reason:connections.size>=7?'이 집의 정원은 8명입니다.':'방장 이전 중이거나 이미 연결된 참가자입니다.'});setTimeout(()=>c.close(),400);return}
  connections.set(c.peer,c);c.lastSeen=performance.now();
  if(host){push({type:'join',id:c.peer,clientId:typeof c.metadata?.clientId==='string'&&c.metadata.clientId.length<80?c.metadata.clientId:c.peer});setTimeout(()=>{sendRaw(c,{type:'collab-sync',epoch,...collaboration.snapshot()});presentation.sync(c.peer);documents.sync(c.peer);broadcast.sync(c.peer)},800)}
  else if(!handoffSwitching){push({type:'start',host:false,id,epoch:'',clientId:clientIdentity,classroom:classroomSession});playing=false;status('호스트의 확정 상태를 받는 중입니다.')}else entered()
 });
 c.on('data',m=>{
  c.lastSeen=performance.now();
  if(m?.type==='heartbeat')return;
  if(performance.now()-windowAt>1000){windowAt=performance.now();count=0}
  if(++count>100||!m||typeof m!=='object'||typeof m.type!=='string'||m.type.length>40)return;
  let size;try{size=JSON.stringify(m).length}catch{return}if(size>(m.type==='handoff-offer'?4:1)*1024*1024)return;
  if(host&&m.type==='state-resync'){if(m.epoch===epoch)stateCodec.requestKeyframe(c.peer);return;}
  if(!host&&['state','state-delta'].includes(m.type)){if(m.epoch!==epoch)return;const decoded=stateCodec.decode(c.peer,m);if(!decoded){net({type:'state-resync',epoch});return;}m=decoded;}
  if(m.type.startsWith('meeting-')){if(m.epoch===epoch)meetingWorkspace.receive(c.peer,m);return;}
  if(m.type.startsWith('broadcast-')){if(m.epoch===epoch)broadcast.receive(c.peer,m);return}
  if(m.type.startsWith('documents-')){if(m.epoch===epoch)documents.receive(c.peer,m);return}
  if(m.type.startsWith('handoff-')){handoff.receive(c.peer,m);return}
  if(m.type==='session-reject'&&!host){$('loading').textContent=m.reason;status(m.reason);return}
  if(m.type==='profile'){if(host&&m.epoch===epoch&&typeof m.name==='string'&&m.name.length<=24)push({type:'profile',id:c.peer,name:m.name});return}
  if(m.type==='chat'){if(m.epoch===epoch)social.receive(c.peer,m);return}
  if(m.type.startsWith('asset-')||m.type.startsWith('presentation-')){if(m.epoch!==epoch)return;presentation.receive(c.peer,m);return}
  if(m.type.startsWith('collab')){if(m.epoch!==epoch)return;if(host&&!canCollaborate(c.peer))return;if(collaboration.receive({...m,from:host?c.peer:m.from})&&host)net({...m,epoch,from:c.peer});return}
  if(m.type==='caption-generation'){if(m.epoch===epoch&&Number.isSafeInteger(m.generation)){if(host){captions.invalidate(c.peer,m.generation);net({type:'caption-generation',epoch,speaker:c.peer,generation:m.generation});}else captions.invalidate(m.speaker,m.generation);}return;}
  if(m.type==='caption'){if(m.epoch!==epoch)return;if(host)relayCaption(c.peer,m);else if(voiceScope(m.speaker,id))captions.show(m);return}
  if(m.type.startsWith('arcade-')){if(m.epoch===epoch)arcade.receive(c.peer,m);return}
  if(m.type==='arcade-progress'||m.type==='arcade-result'){if(m.epoch!==epoch)return;if(host){const a=currentState?.players.find(p=>p.id===c.peer);if(a?.zone==='arcade'&&Number.isFinite(m.score)&&m.score>=0&&m.score<1e7)net({...m,speaker:c.peer})}else if(m.type==='arcade-result')status('친구 아케이드 결과 · '+m.score+'점');return}
  if(host&&m.type==='voice-block'){if(typeof m.peer==='string'&&activePeers.has(m.peer)){const list=new Set(blocksByPeer[c.peer]||[]);m.block?list.add(m.peer):list.delete(m.peer);blocksByPeer[c.peer]=[...list]}return}
  if(host&&m.type==='voice-settings'){if(typeof m.range==='number'&&Number.isFinite(m.range))rangeByPeer[c.peer]=Math.min(voiceMax,Math.max(2,m.range));if(['near','zone','session','broadcast'].includes(m.mode))voiceModes[c.peer]=m.mode;return}
  if(!host&&m.type==='voice-ranges'){if(m.epoch!==epoch)return;rangeByPeer=m.ranges;voiceModes=m.modes||{};voiceMax=m.max||24;broadcastAllowed=new Set(m.broadcast||[]);blocksByPeer=m.blocks||{};return}
  if(!host&&['welcome','world'].includes(m.type)){try{validateWorld(m.world)}catch{return}}
  if(!host&&m.type==='state'){stateReceived++;if(m.epoch!==epoch)return;observeState(m);if(m.paused)status('호스트 일시정지 · 같은 게임 창을 보이게 유지해 주세요.')}
  if(!host&&m.type==='action-result'){if(m.epoch===epoch)lastCommandResult=m;return;}
  if(!host&&m.type==='notice')status(m.text);
  if(!host&&m.type==='welcome'){if(m.roomCode)roomCode=m.roomCode;classroomSession=classroomSession||!!m.classroom;epoch=m.epoch;adminSession=classroomSession?'commons-classroom-v4':typeof m.adminSession==='string'?m.adminSession:epoch;if(m.world.collaboration)collaboration.restore(m.world.collaboration);broadcast.restore(m.world.announcements||[]);documents.restore(m.world.documents||[]);entered();setTimeout(()=>meetingWorkspace.reconnect(),500);$('reconnectSession').hidden=true;$('offlineMeetingDraft').hidden=true;handoffSwitching=false;status('같은 집에 연결되었습니다. 서로의 캐릭터를 확인하세요.')}
  push({type:'data',sender:c.peer,message:m});
 });
 c.on('close',()=>forgetConnection(c));
 c.on('error',e=>status('P2P 연결 오류: '+e.message));
}
async function startOnline(joinCode='',claimClassroom=false){
 social.reset();broadcast.reset();broadcastAllowed.clear();voiceMode='near';voiceModes={};
 if(peer)return;
 let parsed;try{parsed=joinCode?parseInvitation(joinCode):parseInvitation(createRoomCode())}catch(e){status(e.message);return}
 roomCode=parsed.code;classroomSession=roomCode==='classroom';host=!joinCode||claimClassroom;id='ho3-user-'+crypto.randomUUID();epoch=crypto.randomUUID();adminSession=classroomSession?'commons-classroom-v4':epoch;
 $('loading').textContent='연결 확인 중…';peer=createPeer(id);
 peer.on('connection',c=>{if(host)bind(c);else c.close()});
 peer.on('open',async()=>{
  try{
   if(host){try{directoryPeer=await claimRoom(roomCode,id,epoch,peerOptions())}catch(e){
    if(classroomSession&&e.code==='unavailable-id')host=false;
    else if(e.code==='unavailable-id'){roomCode=createRoomCode();directoryPeer=await claimRoom(roomCode,id,epoch,peerOptions())}
    else throw e;
   }}
   if(host){room=id;push({type:'start',host:true,id,epoch,clientId:clientIdentity,classroom:classroomSession});entered();
    if(recoverPending){const w=recoverPending;recoverPending=null;meetingWorkspace.restore(w.meetings,allAttachments());presentation.restore(w.presentation,allAttachments(),w.presentationView);collaboration.restore(w.collaboration);broadcast.restore(w.announcements||[]);documents.restore(w.documents||[]);arcade.restore({records:w.results.arcade||[]});push({type:'restore',world:w});}
   }else{const found=await resolveRoom(peer,roomCode);room=found.hostId;epoch=found.epoch;bind(peer.connect(room,{reliable:true,serialization:'binary',metadata:{clientId:clientIdentity,protocolVersion:PROTOCOL_VERSION,buildId:BUILD_ID}}));}
  }catch(e){status('입장 실패: '+e.message);$('loading').textContent='연결 실패 · 다시 시도할 수 있습니다.';directoryPeer?.destroy();directoryPeer=null;peer?.destroy();peer=null;}
 });
}
function showMenu(){$('tool').hidden=true;campusUI.hide();meetingWorkspace.hide();wardrobe.cancel();placement.hide();push({type:"ui_focus",focused:true});menuVisible=true;playing=false;ptt=false;gateVoice();document.exitPointerLock?.();$('menu').hidden=false;push({type:'visibility',hidden:document.hidden});$('export').textContent=host?'공간 내보내기':'마지막 확인 복구본 내보내기';$('import').disabled=!host||connections.size>0}
function resume(){campusUI.hide();meetingWorkspace.hide();cursorPaused=false;placement.hide();push({type:"activity",mode:""});broadcast.hide();documents.hide();collaboration.hide();activities.hide();presentation.hide();arcade.hide();menuVisible=false;playing=true;$('menu').hidden=true;$('tool').hidden=true;$('canvas').focus();push({type:'resume'})}
function openTool(mode){campusUI.hide();meetingWorkspace.hide();if(mode==='wardrobe'){status('의상방의 거울 또는 콘솔을 직접 클릭하세요.');return;}wardrobe.cancel();if(mode==='catalog'){placement.open();return;}placement.hide();push({type:"ui_focus",focused:true});push({type:"activity",mode});playing=false;ptt=false;gateVoice();document.exitPointerLock?.();$('tool').hidden=false;broadcast.hide();documents.hide();collaboration.hide();activities.hide();presentation.hide();arcade.hide();$('book').hidden=mode!=='book';$('whiteboard').hidden=mode!=='board';$('boardTools').hidden=mode!=='board';$('toolTitle').textContent=({book:'잠깐, 책 한 권',board:'함께 그리는 보드',report:'함께 만드는 회의',catalog:'가구 놓기',runner:'작은 공룡 달리기',maze:'공룡 러너',documents:'회의 자료 · 컴퓨터',broadcast:'OFFICE 방송석'})[mode]||'함께 만드는 회의';if(mode==='directory'||mode==='cctv'||mode.startsWith('lift:')){$('tool').hidden=true;campusUI.open(mode);}else if(mode==='workspace'||mode.startsWith('workspace:'))meetingWorkspace.open(mode.split(':')[1]);else if(mode==='broadcast')broadcast.open();else if(mode==='documents')documents.open();else if(mode==='presentation')presentation.open();else if(mode==='book')renderPage();else if(mode==='board')renderBoard();else if(['runner','maze'].includes(mode))arcade.open(mode);else if(mode==='catalog')activities.open(mode);else collaboration.open(mode)}
const pages=[['같은 집, 다른 하루','이 집의 첫 규칙은 간단합니다.\n누군가의 이야기를 끝까지 듣기.\n쓰던 물건은 다음 사람이 찾기 쉬운 곳에 두기.\n오늘의 생각은 회의실 보드에 남겨 두세요.'],['함께 일하는 시간','혼자 생각할 시간과 함께 이야기할 시간.\n둘 중 어느 쪽도 서두를 필요는 없습니다.\n회의가 끝나면 가장 중요한 문장 하나를\n우리의 공간에 남겨 보세요.'],['다음에 다시 만나요','모두 떠나기 전에 방장이 공간을 내보냅니다.\n가구와 보드가 한 파일에 담깁니다.\n다음 모임에는 한 사람이 파일을 가져오고,\n친구들은 새 초대 코드로 같은 집에 들어옵니다.']];
function renderPage(){$('bookTitle').textContent=pages[page][0];$('bookText').textContent=pages[page][1];$('pageNumber').textContent=(page+1)+' / '+pages.length;$('prevPage').disabled=page===0;$('nextPage').disabled=page===pages.length-1}
function renderBoard(){boardTools.render()}
function point(e){const r=$('whiteboard').getBoundingClientRect();return [Math.min(1,Math.max(0,(e.clientX-r.left)/r.width)),Math.min(1,Math.max(0,(e.clientY-r.top)/r.height))]}
$('whiteboard').onpointerdown=e=>{boardPoints=[point(e)];$('whiteboard').setPointerCapture(e.pointerId)};
$('whiteboard').onpointermove=e=>{if(boardPoints&&boardPoints.length<256){boardPoints.push(point(e));renderBoard()}};
$('whiteboard').onpointerup=e=>{if(boardPoints?.length>1)push({type:'action',action:'stroke',data:{points:boardPoints,color:$('color').value,width:Number($('width').value)}});boardPoints=null;renderBoard()};
$('whiteboard').onpointercancel=()=>{boardPoints=null;renderBoard()};
$('undo').onclick=()=>push({type:'action',action:'undo'});
$('host').onclick=()=>startOnline();$('join').onclick=()=>startOnline($('room').value);$('classroomJoin').onclick=()=>startOnline('classroom',true);try{if(params.has('room'))$('room').value=parseInvitation(params.get('room')).code}catch(e){status(e.message)};
$('solo').onclick=()=>{social.reset();broadcast.reset();directoryPeer?.destroy();directoryPeer=null;if(peer){peer.destroy();peer=null}connections.clear();host=true;id='local';epoch=crypto.randomUUID();adminSession=epoch;room='';push({type:'start',host:true,id,epoch,clientId:clientIdentity});entered()};
$('menuButton').onclick=showMenu;$('resume').onclick=resume;$('closeTool').onclick=resume;
$('prevPage').onclick=()=>{page=Math.max(0,page-1);renderPage()};$('nextPage').onclick=()=>{page=Math.min(pages.length-1,page+1);renderPage()};
$('copyInvite').onclick=async()=>{try{await navigator.clipboard.writeText(roomCode);status('초대 코드를 복사했습니다.')}catch{status('초대 코드를 직접 선택해 복사해 주세요.')}};
$('copyInviteLink').onclick=async()=>{try{await navigator.clipboard.writeText(invitationLink(location.href,roomCode));status('초대 링크를 복사했습니다.')}catch{status('링크: '+invitationLink(location.href,roomCode))}};
function download(bytes,name){const url=URL.createObjectURL(new Blob([bytes],{type:'application/zip'})),a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),60000);status('다운로드를 요청했습니다. 파일이 저장됐는지 확인해 주세요.')}
$('export').onclick=async()=>{if(host)push({type:'export'});else if(lastWorld)download(await encodeWorld(lastWorld,allAttachments()),'모여집-복구본.homeworld');else status('아직 확인된 복구본이 없습니다.')};
$('import').onchange=async e=>{try{if(!host||connections.size)throw new Error('참여자가 없는 방장 공간에서 새 세션으로 가져올 수 있습니다.');const f=e.target.files[0];if(!f)return;if(f.size>32*1024*1024)throw new Error('파일은 32MB 이하여야 합니다.');const bundle=await decodeBundle(new Uint8Array(await f.arrayBuffer()));collaboration.validate(bundle.world.collaboration);await presentation.validate(bundle.world.presentation,bundle.attachments);await meetingWorkspace.validate(bundle.world.meetings,bundle.attachments);pendingWorld=null;pendingAttachments=bundle.attachments;push({type:'restore_preview',world:bundle.world});status('실제 건축과 가구의 충돌을 확인하는 중…')}catch(err){pendingWorld=null;$('importPreview').hidden=true;status(err.message)}finally{e.target.value=''}};
let restoreBackup=null,restoreCommit=null;
$('restore').onclick=async()=>{if(!pendingWorld||!host||connections.size||restoreBackup)return;const candidate=pendingWorld,files=pendingAttachments;$('restore').disabled=true;try{await new Promise((resolve,reject)=>{restoreBackup={resolve,reject};push({type:'export'})});await new Promise((resolve,reject)=>{restoreCommit={resolve,reject};push({type:'restore_transaction',world:candidate})});meetingWorkspace.restore(candidate.meetings,files);broadcast.restore(candidate.announcements||[]);documents.restore(candidate.documents||[]);collaboration.restore(candidate.collaboration);presentation.restore(candidate.presentation,files,candidate.presentationView);arcade.restore({records:candidate.results.arcade||[]});pendingWorld=null;$('importPreview').hidden=true;resume();status('공간을 복원했습니다. 좌석·손 점유와 옛 권한은 초기화했습니다.')}catch(e){status('현재 세계를 보존했습니다: '+e.message)}finally{restoreBackup=null;restoreCommit=null;$('restore').disabled=false}};

function observeState(s){if(currentState?.epoch===s.epoch&&currentState.tick>s.tick)return;currentState=s;broadcast.tick();lastStateAt=performance.now();activePeers=new Set(s.players.map(p=>p.id));const me=s.players.find(p=>p.id===id);if(me)$('zone').textContent=({hall:'현관 · 계단',living:'거실',dining:'식당',kitchen:'주방',meeting:'회의실',free:'자유 작업방',game:'태그 · 사격',arcade:'아케이드',sleep:'수면실',reading:'독서 휴식',wardrobe:'의상방',upper_hall:'2층 갤러리',garden:'마당',basketball:'농구',football:'축구','personal-gallery':'개인실 복도'})[me.zone]||campusUI.zoneName(me.zone)||me.zone;$('network').textContent=(host?'방장':'연결됨')+' · '+s.players.length+'명';for(const who of [...incoming.keys()])if(!activePeers.has(who)){incoming.get(who).call.close();incoming.delete(who)};gateVoice();updateSpatial();}
async function enableMic(){
 if(micStream){muted=!muted;gateVoice();$('mic').textContent=muted?'음소거 해제':'음소거';return}
 try{context??=new AudioContext();await context.resume();const selected=$('device').value;micStream=await navigator.mediaDevices.getUserMedia({audio:{...micFlags,...(selected?{deviceId:{exact:selected}}:{})},video:false});muted=false;meterStream=micStream.clone();meterSource=context.createMediaStreamSource(meterStream);analyser=context.createAnalyser();analyser.fftSize=256;meterSource.connect(analyser);micStream.getAudioTracks()[0].onended=()=>{muted=true;status('마이크 장치가 분리되었습니다.');stopTransmit();micStream=null};$('mic').textContent='음소거';$('micStatus').textContent='로컬 입력 레벨 확인 중 · V를 누를 때만 전송';console.info('MIC_SETTINGS',micStream.getAudioTracks()[0].getSettings());await devices();gateVoice()}catch(e){status('마이크를 켜지 못했습니다: '+e.name+' · 게임은 계속할 수 있습니다.');$('micStatus').textContent='마이크 오류 · '+e.name}
}
async function devices(){try{const selected=$('device').value;const ds=await navigator.mediaDevices.enumerateDevices();$('device').replaceChildren(new Option('기본 마이크',''));for(const d of ds)if(d.kind==='audioinput')$('device').append(new Option(d.label||'마이크',d.deviceId));$('device').value=selected}catch{}}
function transmitting(){return !!micStream&&!muted&&((ptt&&playing)||$('openMic').checked)&&!document.hidden&&!currentState?.paused&&performance.now()-lastStateAt<2500}
function audible(who,outbound=false){if(!voiceScope(outbound?id:who,outbound?who:id))return false;if(outbound?(blocksByPeer[who]||[]).includes(id):blocked.has(who))return false;if(!currentState)return false;const me=currentState.players.find(p=>p.id===id),other=currentState.players.find(p=>p.id===who);if(!me||!other)return false;const d=Math.hypot(...me.p.map((v,i)=>v-other.p[i]));const mode=outbound?voiceMode:(voiceModes[who]||'near');if(mode==='broadcast')return broadcast.canHear(outbound?id:who,outbound?who:id);if(mode==='session')return true;if(mode==='zone')return me.zone===other.zone;const max=Math.min(voiceMax,outbound?range:(rangeByPeer[who]||8));const active=outbound?outgoing.get(who)?.active:incoming.get(who)?.active;return d<(active?max:Math.max(0,max-.6))}
function stopTransmit(){ptt=false;captions.stop();for(const track of micStream?.getAudioTracks()||[])track.enabled=false;for(const v of outgoing.values()){v.call.close()}outgoing.clear()}
function gateVoice(){
 const enabled=transmitting();for(const t of micStream?.getAudioTracks()||[])t.enabled=enabled;
 if(!peer||!currentState)return;
 for(const who of activePeers){if(who===id)continue;const allow=enabled&&audible(who,true);let out=outgoing.get(who);if(out&&performance.now()-out.started>3000&&!out.call.peerConnection?.remoteDescription){callStop(out.call);outgoing.delete(who);out=null;}
  if(allow&&!out){const call=peer.call(who,micStream,{metadata:{session:room,epoch,speaker:id}});if(call){const item={call,active:true,started:performance.now()};outgoing.set(who,item);call.on('close',()=>{if(outgoing.get(who)===item)outgoing.delete(who)});call.on('error',()=>{if(outgoing.get(who)===item)outgoing.delete(who)})}}
  if(!allow&&out){out.active=false;callStop(out.call);outgoing.delete(who)}
 }
}
function callStop(call){for(const sender of call.peerConnection?.getSenders()||[])if(sender.track?.kind==='audio')sender.replaceTrack(null).catch(()=>{});call.close()}
async function receiveVoice(call){
 // Signaling and the host policy use different channels. Never answer before permission arrives.
 for(let n=0;n<15&&isMember(call.peer)&&!blocked.has(call.peer)&&!audible(call.peer);n++)await new Promise(resolve=>setTimeout(resolve,100));
 if(!isMember(call.peer)||blocked.has(call.peer)||!audible(call.peer)||call.metadata?.session!==room||call.metadata?.epoch!==epoch){call.close();return}
 incoming.get(call.peer)?.call.close();
 const item={call,active:true,nodes:[]};incoming.set(call.peer,item);call.answer();
 call.on('stream',async stream=>{try{context??=new AudioContext();await context.resume();const source=context.createMediaStreamSource(stream),filter=context.createBiquadFilter(),panner=context.createStereoPanner(),gain=context.createGain();filter.type='lowpass';filter.frequency.value=18000;source.connect(filter).connect(panner).connect(gain).connect(context.destination);item.nodes=[source,filter,panner,gain];item.gain=gain;item.panner=panner;item.filter=filter;updateSpatial()}catch(e){status('음성 재생을 허용하려면 마이크 버튼을 누르세요. '+e.name)}});
 call.on('close',()=>{for(const n of item.nodes)n.disconnect();if(incoming.get(call.peer)===item)incoming.delete(call.peer)});
 addVolume(call.peer);
}
function addVolume(who){if(gains.has(who))return;gains.set(who,1);const label=document.createElement('label');label.textContent='친구 '+who.slice(-4)+' 음량';const slider=document.createElement('input');slider.type='range';slider.min='0';slider.max='1.5';slider.step='.05';slider.value='1';slider.oninput=()=>{gains.set(who,+slider.value);updateSpatial()};const block=document.createElement('button');block.textContent='상대 차단 / 해제';block.onclick=()=>{blocked.has(who)?blocked.delete(who):blocked.add(who);blocksByPeer[id]=[...blocked];if(!host)net({type:'voice-block',peer:who,block:blocked.has(who)});if(blocked.has(who)){incoming.get(who)?.call.close();incoming.delete(who)}gateVoice();updateSpatial()};label.append(slider,block);$('volumes').append(label)}
function updateSpatial(){if(!context||!currentState)return;const me=currentState.players.find(p=>p.id===id);if(!me)return;for(const [who,v]of incoming){const p=currentState.players.find(p=>p.id===who);if(!p||!v.gain)continue;const dx=p.p[0]-me.p[0],dz=p.p[2]-me.p[2],d=Math.hypot(dx,dz),allowed=audible(who);v.active=allowed;const acoustic=currentState.voiceOcclusion?.[id+'|'+who]??(me.zone!==p.zone?0.22:1);const occluded=acoustic<1;const gain=allowed?((voiceModes[who]==='broadcast'&&broadcast.canHear(who,id))||['zone','session'].includes(voiceModes[who])?1:Math.max(0,1-d/(rangeByPeer[who]||8)))*(voiceModes[who]==='broadcast'?1:acoustic)*(broadcast.active().speaker&&voiceModes[who]!=='broadcast'?0.35:1)*(gains.get(who)||0):0;v.gain.gain.setTargetAtTime(gain,context.currentTime,.08);v.filter.frequency.setTargetAtTime(occluded?1100:18000,context.currentTime,.1);v.panner.pan.setTargetAtTime(Math.max(-1,Math.min(1,(dx*Math.cos(me.yaw)-dz*Math.sin(me.yaw))/Math.max(d,1))),context.currentTime,.08)}}
$('mic').onclick=enableMic;$('micOff').onclick=()=>{stopTransmit();for(const t of micStream?.getTracks()||[])t.stop();for(const t of meterStream?.getTracks()||[])t.stop();meterSource?.disconnect();micStream=null;meterStream=null;analyser=null;muted=true;$('level').value=0;$('mic').textContent='마이크 켜기';$('micStatus').textContent='장치 종료 · 캡처와 전송 중단'};$('device').onchange=async()=>{stopTransmit();for(const t of micStream?.getTracks()||[])t.stop();meterSource?.disconnect();for(const t of meterStream?.getTracks()||[])t.stop();meterStream=null;micStream=null;await enableMic()};$('openMic').onchange=gateVoice;
$('range').oninput=()=>{range=+$('range').value;rangeByPeer[id]=range;$('rangeValue').textContent=range+'m';if(!host)net({type:'voice-settings',range,mode:voiceMode});gateVoice()};
document.addEventListener('keydown',e=>{if(keyBindings.match(e,'talk')&&playing){ptt=true;gateVoice()}if(keyBindings.match(e,'mute')&&playing&&!e.repeat){muted=!muted;gateVoice();$('mic').textContent=muted?'음소거 해제':'음소거';status(muted?'마이크 음소거':'마이크 준비')}if(e.code==='Escape'){if(!$('tool').hidden)resume();else showMenu()}});
document.addEventListener('keyup',e=>{if(keyBindings.match(e,'talk')){ptt=false;gateVoice()}});
window.addEventListener('blur',()=>{push({type:'ui_focus',focused:true});ptt=false;gateVoice()});document.addEventListener('visibilitychange',()=>{ptt=false;gateVoice();push({type:'visibility',hidden:document.hidden})});
document.addEventListener('pointerlockchange',()=>{if(!document.pointerLockElement){ptt=false;gateVoice()}});
navigator.mediaDevices?.addEventListener('devicechange',devices);
setInterval(()=>{if(analyser){const a=new Uint8Array(analyser.fftSize);analyser.getByteTimeDomainData(a);$('level').value=Math.min(1,Math.sqrt(a.reduce((s,v)=>s+(v-128)**2,0)/a.length)/40)}if(host){rangeByPeer[id]=range;voiceModes[id]=voiceMode;net({type:'voice-ranges',epoch,ranges:rangeByPeer,modes:voiceModes,max:voiceMax,broadcast:[...broadcastAllowed],blocks:blocksByPeer})}gateVoice()},250);
window.addEventListener('beforeunload',()=>{stopTransmit();for(const v of incoming.values())v.call.close();for(const c of connections.values())c.close();for(const t of micStream?.getTracks()||[])t.stop();for(const t of meterStream?.getTracks()||[])t.stop();context?.close();directoryPeer?.destroy();peer?.destroy()});
window.Homeoffice={
 restore_preview(json){try{const result=JSON.parse(json);if(result.conflicts.length)throw Error('의상방과 충돌하는 가구: '+result.conflicts.join(', '));pendingWorld=validateWorld(result.world);$('importInfo').textContent=`배치 검증 완료 · 설치 가구 ${pendingWorld.objects.length}개 · 재배치 보관 ${result.unplaced}개 · 회의 ${pendingWorld.meetings?.length||0}개. 현재 공간을 백업한 뒤 엽니다. 보관한 사물은 원래 ID·자료를 유지합니다.`;$('importPreview').hidden=false;}catch(e){pendingWorld=null;status(e.message);}},
 restore_result:(okay,reason)=>{if(okay)restoreCommit?.resolve();else restoreCommit?.reject(Error(String(reason)))},campus_status:json=>{const state=JSON.parse(json);campusUI.update(state);placement.stored(state.stored);},
 wardrobe_open:json=>wardrobe.open(JSON.parse(json)),wardrobe_result:json=>wardrobe.result(JSON.parse(json)),
 placement_feedback:json=>placement.update(JSON.parse(json)),
 command_result:json=>{lastCommandResult=JSON.parse(json);placement.ack(lastCommandResult);wardrobe.ack(lastCommandResult)},key_matches:(e,action)=>keyBindings.match(e,action),key_label:action=>keyBindings.label(action),
 campus_physical_laser:(actor,meetingId,uv)=>meetingWorkspace.physicalPointer(actor,meetingId,JSON.parse(uv)),avatar_diagnostics:json=>{avatarDiagnostics=JSON.parse(json)},physical_laser:(actor,uv)=>presentation.physicalPointer(actor,JSON.parse(uv)),gameplay_hud:json=>gameplayHud.update(JSON.parse(json),playing,currentState?.players.find(p=>p.id===id)?.zone),
 performance_sample:json=>{perfSample=JSON.parse(json)},ready(engineInfo){const version=JSON.parse(engineInfo);if(version.buildId!==BUILD_ID){status("게임 코드와 에셋의 빌드가 다릅니다. Ctrl+Shift+R로 새로고침하세요.");return}push({type:'bindings',bindings:keyBindings.godot()});try{const gl=$('canvas').getContext('webgl2'),ext=gl?.getExtension('WEBGL_debug_renderer_info'),renderer=ext?gl.getParameter(ext.UNMASKED_RENDERER_WEBGL):'',saved=localStorage.getItem('moyeo-graphics');$('graphicsQuality').value=['balanced','low'].includes(saved)?saved:(/Intel|SwiftShader|llvmpipe/i.test(renderer)?'low':'balanced')}catch{}loaded=true;$('loading').textContent='공간 준비 완료 · 천천히 들어오세요';for(const n of ['host','solo','join','classroomJoin'])$(n).disabled=false;console.info('GODOT_WEB_READY')},
 take_events(){return JSON.stringify(events.splice(0,256))},is_playing(){return playing&&!document.hidden&&document.hasFocus()&&document.activeElement===$('canvas')},readyState(){return loaded},
 send(json,to){let m;try{m=JSON.parse(json)}catch{return}if(m.type==='welcome'){m.roomCode=roomCode;m.classroom=classroomSession;m.adminSession=adminSession||epoch;}if(m.world){m.world.meetings=meetingWorkspace.snapshot();m.world.announcements=broadcast.snapshot();m.world.documents=documents.snapshot();m.world.collaboration=collaboration.snapshot();m.world.presentation=presentation.metadata();m.world.presentationView=presentation.view();m.world.results.arcade=arcade.results();if(host){for(const[who,c]of connections)if(!to||who===to)sendRaw(c,{...m,world:{...m.world,meetings:meetingWorkspace.snapshotFor(who)}});return;}}net(m,to)},
 camera_fov:()=>Number($('cameraFov').value),look_inverted:()=>$('invertLook').checked,graphics_quality:()=>$('graphicsQuality').value,look_sensitivity:()=>Number($('sensitivity').value)/10000,pen_color:()=>$('color').value,pen_width:()=>Number($('width').value),status,menu:showMenu,open_tool:openTool,set_epoch(e){epoch=e},
 hint(s){$('interaction').textContent=keyBindings.hint(s)},
 observe(json){observeState(JSON.parse(json))},board(json){boardStrokes=JSON.parse(json);renderBoard()},
 handoff_capture:json=>handoff.captured(json),
 async export_world(json){try{const world=JSON.parse(json);world.meetings=meetingWorkspace.snapshot();world.announcements=broadcast.snapshot();world.documents=documents.snapshot();world.collaboration=collaboration.snapshot();world.presentation=presentation.metadata();world.presentationView=presentation.view();world.results.arcade=arcade.results();lastWorld=validateWorld(world);download(await encodeWorld(world,allAttachments()),'모여집.homeworld');restoreBackup?.resolve()}catch(e){restoreBackup?.reject(e);status('내보내기 실패: '+e.message)}},
 recovery(json){try{lastWorld=validateWorld(JSON.parse(json));recoveryTime=new Date().toISOString()}catch{}},
 // Read-only diagnostics: no teleports, fake peers, or authority bypass.
 async voice_stats(){const rows=[];for(const [who,v] of incoming){const stats=await v.call.peerConnection?.getStats();stats?.forEach(s=>{if(s.type==='inbound-rtp'&&s.kind==='audio')rows.push({who,packetsReceived:s.packetsReceived,bytesReceived:s.bytesReceived,jitter:s.jitter})})}return rows},
 diagnostics(){return {campus:campusUI.diagnostics(),meetingWorkspace:meetingWorkspace.diagnostics(),wardrobe:wardrobe.diagnostics(),placement:placement.diagnostics(),roomAdmin:roomAdmin.diagnostics(),messenger:social.diagnostics(),lastCommandResult,replication:stateCodec.diagnostics(),documents:documents.diagnostics(),avatarDiagnostics,stateReceived,roomCode,classroomSession,keyBindings:keyBindings.snapshot(),presentation:presentation.diagnostics(),arcade:arcade.diagnostics(),performance:perfSample,graphicsQuality:$('graphicsQuality').value,host,id,epoch,room,buildId:BUILD_ID,playing,loaded,currentState,boardStrokes,collaboration:collaboration.diagnostics(),stt:captions.diagnostics(),broadcast:broadcast.active(),voicePolicy:{mode:voiceMode,broadcast:[...broadcastAllowed],modes:voiceModes,openMic:$('openMic').checked,hidden:document.hidden,stateAge:performance.now()-lastStateAt},voiceTracks:[...outgoing.values()].map(v=>v.call.peerConnection?.getSenders().map(s=>s.track?.enabled)),connections:[...connections.keys()],mic:!!micStream,muted,voiceIncoming:incoming.size,voiceOutgoing:outgoing.size,recoveryTime}}
};


const controls=document.createElement('div');controls.innerHTML='<hr><h3>방장 · 대화 설정</h3><label>내 음성 범위 <select id="voiceMode"><option value="near">근거리</option><option value="zone">현재 물리적 방 전체</option><option value="session">세션 전체 대화</option><option value="broadcast">방송석 ON AIR (운영 관리자)</option></select></label><div id="hostControls"><label>발화 상한 <input id="voiceMax" type="number" min="2" max="24" value="24"></label><div id="memberPermissions"></div><button id="exportEnd">공간 내보내고 세션 종료</button></div>';$('menu').querySelector('.panel').append(controls);
$('voiceMode').onchange=()=>{voiceMode=$('voiceMode').value;voiceModes[id]=voiceMode;if(!host)net({type:'voice-settings',range,mode:voiceMode});gateVoice()};
$('voiceMax').onchange=()=>{if(host)voiceMax=Math.max(2,Math.min(24,+$('voiceMax').value))};

setInterval(()=>{$('hostControls').hidden=!host},500);
$('exportEnd').onclick=()=>{if(!host)return;push({type:'export'});status('파일 다운로드 후 세션 종료를 선택하세요. 파일 보관을 확인해야 합니다.');const b=document.createElement('button');b.textContent='다운로드한 파일 확인 · 세션 연결 종료';b.onclick=()=>{stopTransmit();for(const c of connections.values())c.close();directoryPeer?.destroy();directoryPeer=null;peer?.destroy();peer=null;playing=false;broadcast.reset();b.remove();status('세션 연결을 종료했습니다. 브라우저는 그대로 열려 있습니다.')};$('hostControls').append(b)};

const roundsPanel=document.createElement('div');roundsPanel.innerHTML='<h3>경기 진행 (방장)</h3><select id="gamePick"><option value="basketball">농구</option><option value="football">축구</option><option value="tag">타깃 / 태그</option></select><select id="gameMode"><option value="timed">시간제</option><option value="team">두 팀</option><option value="targets">타깃 연습</option></select><div class="row"><button data-round="prepare">규칙 확인</button><button data-round="start">시작 / 재시작</button><button data-round="end">경기 종료</button><button data-round="practice">자유 연습</button></div><p>3초 준비 뒤 2분 경기입니다. 코트 양쪽 점수로 경쟁합니다. 농구는 위에서 아래 통과, 축구는 골라인 통과가 득점입니다. 총은 모든 공간에서 자유롭게 사용할 수 있습니다. 기본 무제한 탄약 · 현재 총 소유권과 벽 충돌 검증.</p>';$('hostControls').append(roundsPanel);roundsPanel.querySelectorAll('[data-round]').forEach(b=>b.onclick=()=>{if(host)push({type:'action',action:'round',data:{game:$('gamePick').value,mode:$('gameMode').value,op:b.dataset.round}})});


async function flushNetwork(){for(let n=0;n<160;n++){if([...sendQueues.values()].every(q=>!q.urgent.length)&&[...connections.values()].every(c=>(c.dataChannel?.bufferedAmount||0)<1024))return;await new Promise(r=>setTimeout(r,25))}throw Error('전송 대기열이 비워지지 않았습니다')}
const handoff=createHandoff({host:()=>host,id:()=>id,room:()=>room,peers:()=>[...connections.keys()],composing:()=>collaboration.diagnostics().composing||meetingWorkspace.composing(),
 pause(){playing=false;stopTransmit();collaboration.hide();activities.hide();presentation.hide();arcade.suspend();$('tool').hidden=true;document.activeElement?.blur();status('방장 이전 중 · 세계와 문서의 확인 시점을 맞추고 있습니다.')},resume,notify:status,engine:push,send:(m,to)=>net({...m,epoch},to),flush:flushNetwork,
 decorate(world){world.meetings=meetingWorkspace.snapshot();world.announcements=broadcast.snapshot();world.documents=documents.snapshot();world.collaboration=collaboration.snapshot();world.presentation=presentation.metadata();world.presentationView=presentation.view();world.results.arcade=arcade.results();return world},arcade:()=>arcade.snapshot(),presentation:()=>presentation.session(),voice:()=>({adminSession,max:voiceMax,broadcast:[...broadcastAllowed],ranges:rangeByPeer,modes:voiceModes,blocks:blocksByPeer}),
 async validate(c){validateWorld(c.world);await meetingWorkspace.validate(c.world.meetings,allAttachments());collaboration.validate(c.world.collaboration);await presentation.validate(c.world.presentation,presentation.attachments);if(!c.state?.players.some(p=>p.id===id))throw Error('수신 참가자가 체크포인트에 없습니다')},
 async switch(target,newEpoch,checkpoint){
  directoryPeer?.destroy();directoryPeer=null;handoffSwitching=true;playing=false;stopTransmit();const old=[...connections.values()];for(const c of old){c.retired=true;sendQueues.delete(c)}connections.clear();host=id===target;room=target;epoch=newEpoch;
  social.handoff();broadcast.reset();if(checkpoint)meetingWorkspace.restore(checkpoint.world.meetings,allAttachments());if(host&&checkpoint){adminSession=checkpoint.voice.adminSession||adminSession;broadcast.restore(checkpoint.world.announcements||[]);documents.restore(checkpoint.world.documents||[]);collaboration.restore(checkpoint.world.collaboration);presentation.setSession(checkpoint.presentation);arcade.restore(checkpoint.arcade);voiceMax=checkpoint.voice.max;broadcastAllowed=new Set(checkpoint.voice.broadcast);rangeByPeer=checkpoint.voice.ranges;voiceModes=checkpoint.voice.modes;blocksByPeer=checkpoint.voice.blocks;}
  push({type:'handoff_commit',host,epoch,checkpoint:checkpoint||{}});
  for(const c of old)c.close();
  if(host){roomCode=classroomSession?'classroom':createRoomCode();directoryPeer=await reclaimRoom(roomCode,id,epoch,peerOptions());handoffSwitching=false;entered();status('세계·문서·권위를 인수했습니다. 친구들의 재연결을 기다립니다.')}
  else{bind(peer.connect(room,{reliable:true,serialization:'binary',metadata:{clientId:clientIdentity,protocolVersion:PROTOCOL_VERSION,buildId:BUILD_ID}}));status('새 방장에게 다시 연결하는 중입니다.')}
 }
});
const transferPanel=document.createElement('div');transferPanel.innerHTML='<h3>방장 이전</h3><select id="nextHost"></select><button id="transferHost">선택한 친구에게 세계와 방장 권한 이전</button><p>정상 연결 중 확인·일시정지·인수·재접속을 진행합니다. 강제 종료는 마지막 확인 복구본을 사용하며 미확정 변경은 잃을 수 있습니다.</p>';$('hostControls').append(transferPanel);
setInterval(()=>{const select=$('nextHost'),before=select.value,ids=[...connections.keys()];if(select.dataset.ids===ids.join(','))return;select.dataset.ids=ids.join(',');select.replaceChildren();for(const who of ids)select.append(new Option(who.slice(-6),who));if(ids.includes(before))select.value=before},1000);$('transferHost').onclick=()=>handoff.begin($('nextHost').value);

const boardTools=createBoardTools({strokes:()=>boardStrokes,action:(action,data)=>push({type:"action",action,data})});

const roomAdmin=createRoomAdmin({pause(){push({type:"ui_focus",focused:true});playing=false;ptt=false;gateVoice();document.exitPointerLock?.()},identity:()=>id,apply:policy=>push({type:'room_policy',...policy}),notify:status});
const social=createSocial({onMessage:row=>{if(!row.channel.startsWith('dm:')&&row.text)push({type:'chat_bubble',sender:row.sender,text:row.text});},send:(m,to='')=>net({...m,epoch},to),isHost:()=>host,id:()=>id,members:()=>currentState?.players||[],pause(){push({type:"ui_focus",focused:true});playing=false;ptt=false;gateVoice();document.exitPointerLock?.()},resume,notify:status,profile(name,who=id){if(name!==null)return;return currentState?.players.find(p=>p.id===who)?.displayName||'친구'}});
const preferences=document.createElement('div');preferences.innerHTML='<hr><h3>시점 · 조작</h3><label>그래픽 <select id="graphicsQuality"><option value="balanced">기본 · 가까운 조명 4개</option><option value="low">저사양 · 65% 해상도 / 조명 2개 / 그림자 끄기</option></select></label><label>시야각 <input id="cameraFov" type="range" min="55" max="95" value="75"></label><label><input id="invertLook" type="checkbox"> 마우스 상하 반전</label><label>마우스 감도 <input id="sensitivity" type="range" min="5" max="50" value="20"></label><p class="fine">카메라 흔들림과 강제 FOV 변화는 사용하지 않습니다. WASD 이동 · Shift 달리기 · Ctrl 웅크리기 · C 1/3인칭 · 휠 줌 · 총 우클릭 조준 · Space 점프 · E 집기/내리기 · Q 던지기/패스 · F 시설 사용/읽기/앉기/스틸 · 좌클릭 도구 사용/충전 슛 · R 재장전/드리블 · Z 눕기/먹기 · B 가구 설치 · G 가구 이동 · Delete 가구 철거. Esc로 포인터락을 해제합니다.</p>';$('menu').querySelector('.panel').append(preferences);

const arcade=createArcade({send:m=>net({...m,epoch}),isHost:()=>host,id:()=>id,state:()=>currentState,notify:status});

function forgetConnection(c){if(c.retired||connections.get(c.peer)!==c)return;meetingWorkspace.leave(c.peer);collaboration.clearPresence(c.peer);connections.delete(c.peer);sendQueues.delete(c);stateCodec.forget(c.peer);push({type:'leave',id:c.peer});if(!host){meetingWorkspace.connectionLost();playing=false;stopTransmit();$('reconnectSession').hidden=false;$('offlineMeetingDraft').hidden=false;$('network').textContent='호스트 연결 종료';showMenu();status('호스트 연결이 종료되었습니다. 마지막 확인: '+(recoveryTime||'없음')+' · 확인 이후 변경은 잃을 수 있습니다.');$('recoverSession').hidden=false}}
setInterval(()=>{for(const c of [...connections.values()]){if(performance.now()-(c.lastSeen||0)>15000){forgetConnection(c);c.close()}else sendRaw(c,{type:'heartbeat',epoch})}},1000);
const reconnectButton=document.createElement('button');reconnectButton.id='reconnectSession';reconnectButton.textContent='같은 세션에 다시 연결';reconnectButton.hidden=true;reconnectButton.onclick=async()=>{if(host||!peer||connections.size)return;reconnectButton.disabled=true;try{if(peer.disconnected){peer.reconnect();await new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('시그널링 재연결 시간 초과')),10000);peer.once('open',()=>{clearTimeout(timer);resolve()})})}const found=await resolveRoom(peer,roomCode);room=found.hostId;epoch=found.epoch;bind(peer.connect(room,{reliable:true,serialization:'binary',metadata:{clientId:clientIdentity,protocolVersion:PROTOCOL_VERSION,buildId:BUILD_ID}}));status('같은 공간과 회의의 최신 상태를 요청했습니다.')}catch(e){status('재연결 실패: '+e.message)}finally{reconnectButton.disabled=false}};$('menu').querySelector('.panel').append(reconnectButton);
const offlineDraftButton=document.createElement('button');offlineDraftButton.id='offlineMeetingDraft';offlineDraftButton.textContent='이 기기의 회의 초안 이어 쓰기';offlineDraftButton.hidden=true;offlineDraftButton.onclick=()=>{$('menu').hidden=true;openTool('workspace')};$('menu').querySelector('.panel').append(offlineDraftButton);
const recoveryButton=document.createElement('button');recoveryButton.id='recoverSession';recoveryButton.textContent='마지막 확인 복구본으로 새 세션 열기';recoveryButton.hidden=true;recoveryButton.onclick=async()=>{try{if(!lastWorld)throw Error('확인된 복구본이 없습니다.');const w=validateWorld(lastWorld);collaboration.validate(w.collaboration);await presentation.validate(w.presentation,allAttachments());await meetingWorkspace.validate(w.meetings,allAttachments());recoverPending=w;for(const c of connections.values()){c.retired=true;c.close()}connections.clear();peer?.destroy();peer=null;recoveryButton.hidden=true;await startOnline()}catch(e){status('복구를 시작하지 못했습니다: '+e.message)}};$('menu').querySelector('.panel').append(recoveryButton);

$('graphicsQuality').onchange=()=>{try{localStorage.setItem('moyeo-graphics',$('graphicsQuality').value)}catch{}};

try{const camera=JSON.parse(localStorage.getItem('commons-camera')||'{}');if(Number.isFinite(camera.fov))$('cameraFov').value=Math.min(95,Math.max(55,camera.fov));$('invertLook').checked=camera.invert===true;if(Number.isFinite(camera.sensitivity))$('sensitivity').value=Math.min(50,Math.max(5,camera.sensitivity));}catch{}
for(const field of ['cameraFov','invertLook','sensitivity'])$(field).addEventListener('change',()=>{try{localStorage.setItem('commons-camera',JSON.stringify({fov:+$('cameraFov').value,invert:$('invertLook').checked,sensitivity:+$('sensitivity').value}));}catch{}});
