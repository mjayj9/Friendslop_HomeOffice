export function validateAnnouncements(values){
 if(!Array.isArray(values)||values.length>32)throw Error('공지는 최대 32개입니다.');
 const ids=new Set();return values.map(v=>{if(!v||Object.getPrototypeOf(v)!==Object.prototype||Object.keys(v).some(k=>!['id','text','scope','createdAt'].includes(k))||typeof v.id!=='string'||v.id.length>80||ids.has(v.id)||typeof v.text!=='string'||!v.text.trim()||v.text.length>400||/[\x00-\x1f<>]/.test(v.text)||!BROADCAST_SCOPES.includes(v.scope)||typeof v.createdAt!=='string'||!Number.isFinite(Date.parse(v.createdAt)))throw Error('공지 형식이 올바르지 않습니다.');ids.add(v.id);return {...v,text:v.text.trim()};});
}
export const BROADCAST_SCOPES=['session','home','office','play'];
export function atBroadcastConsole(player){return !!player&&Array.isArray(player.p)&&(Math.hypot(player.p[0]-5,player.p[1],player.p[2]+9.7)<3||Math.hypot(player.p[0]-27,player.p[1]-14.4,player.p[2]+27.4)<2.7);}
export function broadcastAudience(scope,player){
 if(!player)return false;
 if(scope==='session')return true;
 if(scope==='home')return ['living','dining','kitchen','sleep','reading','upper_hall','bath_upper'].includes(player.zone);
 if(scope==='office')return ['meeting','resources','free','utility','bath_ground'].includes(player.zone)||player.zone?.startsWith('office-');
 if(scope==='play')return ['game','arcade','basketball','football'].includes(player.zone);
 return false;
}
export function createBroadcast({identity,isHost,isClassroom,players,authorized,send,notify,onMode,onState}){
 let state={speaker:'',scope:'session',revision:0};let announcements=[];
 const root=document.createElement('section');root.id='broadcastPanel';root.hidden=true;
 root.innerHTML='<h3>방송석</h3><p>서버가 인증한 운영 관리자가 마이크 앞에서 시작합니다. 방송 중 V를 누르거나 메뉴에서 열린 마이크를 직접 켜세요.</p><label>수신 범위 <select id="broadcastScope"><option value="session">세션 전체</option><option value="home">HOME</option><option value="office">OFFICE</option><option value="play">PLAY</option></select></label><div class="row"><button id="broadcastStart">ON AIR · 방송 시작</button><button id="broadcastStop" class="secondary">방송 종료</button></div><p id="broadcastState" role="status"></p><h3>수동 공지</h3><textarea id="announcementText" maxlength="400" placeholder="저장할 공지 내용"></textarea><button id="postAnnouncement">공지 게시</button><div id="announcementList"></div>';
 document.querySelector('.tool-panel').append(root);
 const badge=document.createElement('div');badge.id='onAirBadge';badge.hidden=true;document.body.append(badge);
 function render(){if(!state.speaker)onMode('near');onState?.(state);const list=root.querySelector('#announcementList');list.replaceChildren();for(const note of announcements.slice(-12)){const row=document.createElement('p');row.textContent='['+note.scope.toUpperCase()+'] '+note.text;list.append(row);}const active=!!state.speaker;root.querySelector('#broadcastState').textContent=active?'ON AIR · '+state.scope+' · '+state.speaker.slice(-6):'방송 대기';badge.hidden=!active;badge.textContent='● ON AIR · '+state.scope.toUpperCase();}
 function publish(){state.revision++;render();send({type:'broadcast-state',state,announcements});}
 function request(type){const m={type,scope:root.querySelector('#broadcastScope').value};if(isHost())receive(identity(),m);else send(m);}
 function receive(sender,m){
  if(!m?.type?.startsWith('broadcast-'))return false;
  if(!isHost()){if(m.type==='broadcast-state'&&Number.isSafeInteger(m.state?.revision)&&m.state.revision>=state.revision&&typeof m.state.speaker==='string'&&m.state.speaker.length<100&&BROADCAST_SCOPES.includes(m.state.scope)){state={...m.state};try{announcements=validateAnnouncements(m.announcements||[]);}catch{return true;}render();if(state.speaker===identity())onMode('broadcast');}return true;}
  if(m.type==='broadcast-stop'){if(authorized(sender)||sender===state.speaker){state.speaker='';publish();}return true;}
  if(!['broadcast-start','broadcast-notice'].includes(m.type))return true;
  const player=players().find(p=>p.id===sender);
  let error='';
  if(!authorized(sender))error='운영 관리자 로그인과 방송실 PIN 검증이 필요합니다.';
  else if(!atBroadcastConsole(player))error='방송석 마이크 가까이에서 시작하세요.';
  else if(state.speaker&&state.speaker!==sender)error='다른 참가자가 방송 중입니다.';
  else if(!BROADCAST_SCOPES.includes(m.scope))error='방송 범위를 확인하세요.';
  if(error){if(sender===identity())notify(error);else send({type:'notice',text:error},sender);return true;}
  if(m.type==='broadcast-notice'){try{announcements=validateAnnouncements([...announcements.slice(-31),{id:crypto.randomUUID(),text:m.text,scope:m.scope,createdAt:new Date().toISOString()}]);publish();}catch(e){notify(e.message);}return true;}
  state.speaker=sender;state.scope=m.scope;publish();if(sender===identity())onMode('broadcast');return true;
 }
 root.querySelector('#postAnnouncement').onclick=()=>{const m={type:'broadcast-notice',text:root.querySelector('#announcementText').value,scope:root.querySelector('#broadcastScope').value};if(isHost())receive(identity(),m);else send(m);};
 root.querySelector('#broadcastStart').onclick=()=>request('broadcast-start');root.querySelector('#broadcastStop').onclick=()=>request('broadcast-stop');
 return {receive,open(){root.hidden=false;render();},hide(){root.hidden=true;},tick(){if(isHost()&&state.speaker&&(!authorized(state.speaker)||!atBroadcastConsole(players().find(p=>p.id===state.speaker)))){state.speaker='';publish();}},sync(to){send({type:'broadcast-state',state,announcements},to);},reset(){state={speaker:'',scope:'session',revision:0};announcements=[];render();},snapshot:()=>structuredClone(announcements),restore(values=[]){announcements=validateAnnouncements(values);render();},active:()=>({...state}),canHear(sender,receiver){return authorized(sender)&&state.speaker===sender&&atBroadcastConsole(players().find(p=>p.id===sender))&&broadcastAudience(state.scope,players().find(p=>p.id===receiver));}};
}
