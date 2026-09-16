const providers={docs:'Google Docs',slides:'Google Slides',excel:'Microsoft Excel',sheets:'Google Sheets'};
export function validateDocument(value){
 if(!value||Object.getPrototypeOf(value)!==Object.prototype)throw Error('자료 형식이 올바르지 않습니다.');
 const {id,name,provider,url}=value;
 if(!/^[a-zA-Z0-9_-]{1,80}$/.test(id)||typeof name!=='string'||!name.trim()||name.length>120||/[\x00-\x1f<>]/.test(name)||!providers[provider])throw Error('자료 이름과 공급자를 확인하세요.');
 if(typeof url!=='string'||url.length>2048)throw Error('자료 링크가 너무 깁니다.');
 const u=new URL(url);
 if(u.protocol!=='https:'||u.username||u.password||u.port)throw Error('공식 서비스의 HTTPS 링크만 등록할 수 있습니다.');
 const google={docs:'document',slides:'presentation',sheets:'spreadsheets'};
 if(provider in google){
  if(u.hostname!=='docs.google.com'||!new RegExp('^/'+google[provider]+'/d/[A-Za-z0-9_-]+/(edit|view|preview|present)?/?$').test(u.pathname))throw Error('해당 Google 원본 문서의 편집/보기 링크가 필요합니다. 게시용 링크는 공동편집 원본이 아닙니다.');
  u.search='';u.hash='';
 }else{
  const host=u.hostname.toLowerCase();
  const allowed=host==='1drv.ms'||host==='onedrive.live.com'||host==='excel.cloud.microsoft'||/^[a-z0-9-]+\.sharepoint\.com$/.test(host);
  if(!allowed)throw Error('OneDrive·SharePoint·Excel의 실제 통합문서 공유 링크를 입력하세요.');
  if(host==='1drv.ms'&&!u.pathname.startsWith('/x/'))throw Error('Excel 통합문서 공유 링크가 필요합니다.');
  if(host.endsWith('.sharepoint.com')&&!(/\/:x:\//.test(u.pathname)||/\/_layouts\/15\/Doc\.aspx$/i.test(u.pathname)))throw Error('SharePoint Excel 링크가 필요합니다.');
 }
 return {id,name:name.trim(),provider,url:u.href};
}
export function validateRegistry(values){
 if(!Array.isArray(values)||values.length>32)throw Error('회의 자료는 최대 32개입니다.');
 const rows=values.map(validateDocument);if(new Set(rows.map(v=>v.id)).size!==rows.length)throw Error('중복 자료 ID입니다.');return rows;
}
export function googleSearch(term){
 const text=String(term).trim();if(!text||text.length>500)throw Error('검색어를 1~500자로 입력하세요.');
 const u=new URL('https://www.google.com/search');u.searchParams.set('q',text);return u.href;
}
export function createDocumentRegistry({identity,isHost,send,canEdit,notify,openTool}){
 let rows=[],revision=0;const rates=new Map();
 const root=document.createElement('section');root.id='sharedDocuments';root.hidden=true;
 root.innerHTML='<h3>회의 자료 · 원본 공동작업</h3><p>같은 원본을 각자의 계정으로 엽니다. 편집 권한은 Google·Microsoft의 공유 설정을 따릅니다.</p><form id="documentForm"><input name="name" maxlength="120" placeholder="자료 이름" required><select name="provider"><option value="docs">Google Docs</option><option value="slides">Google Slides</option><option value="excel">Microsoft Excel</option><option value="sheets">Google Sheets (추가)</option></select><input name="url" type="url" maxlength="2048" placeholder="https:// 원본 공유 링크" required><button>회의에 등록</button></form><p class="fine">공유 링크는 참가자와 공간 저장 파일에 포함됩니다. 외부 문서 내용은 이 파일로 백업되지 않습니다. 원본은 별도 창에서 열립니다. 호스트 창도 화면에 함께 유지하거나 방장을 인계하세요.</p><div id="documentList"></div><hr><h3>내 컴퓨터 · Google 검색</h3><form id="searchForm"><input name="query" maxlength="500" placeholder="나만 보는 검색어" required><button>Google 검색 열기</button></form><p id="documentNotice" role="status"></p>';
 document.querySelector('.tool-panel').append(root);
 const nav=document.createElement('div');nav.className='row';for(const[mode,label]of [['report','회의록'],['brainstorm','브레인스토밍'],['mindmap','마인드맵'],['presentation','PDF·이미지 발표']]){const b=document.createElement('button');b.textContent=label;b.onclick=()=>openTool(mode);nav.append(b);}root.prepend(nav);
 function openUrl(url){const w=window.open(url,'_blank','noopener,noreferrer,width=1100,height=780');root.querySelector('#documentNotice').textContent='새 창을 요청했습니다. 열리지 않았다면 브라우저의 팝업 차단 표시를 확인하세요. 게임 호스트 창도 보이게 유지해 주세요.';return w;}
 function render(){const list=root.querySelector('#documentList');list.replaceChildren();for(const row of rows){const card=document.createElement('article');card.className='document-card';const title=document.createElement('strong');title.textContent=row.name;const label=document.createElement('span');label.textContent=providers[row.provider];const open=document.createElement('button');open.textContent='원본 열기 · 공동편집';open.onclick=()=>openUrl(row.url);const del=document.createElement('button');del.className='secondary';del.textContent='목록에서 제거';del.disabled=!isHost();del.onclick=()=>dispatch({type:'documents-remove',id:row.id});card.append(title,label,open,del);list.append(card)}}
 function dispatch(m){m.requestId=crypto.randomUUID();if(isHost())receive(identity(),m);else send(m);}
 function receive(sender,m){
  if(!m?.type?.startsWith('documents-'))return false;
  if(!isHost()){
   if(m.type==='documents-state'&&Number.isSafeInteger(m.revision)&&m.revision>=revision){try{rows=validateRegistry(m.rows);revision=m.revision;render()}catch(e){notify(e.message)}}return true;
  }
  if(m.type==='documents-request'){send({type:'documents-state',rows,revision},sender);return true;}
  if(!canEdit(sender))return true;
  if(performance.now()-(rates.get(sender)||-1000)<250)return true;rates.set(sender,performance.now());
  try{
   if(m.type==='documents-add'){const row=validateDocument(m.document);if(rows.some(v=>v.id===row.id))return true;rows=validateRegistry([...rows,row]);}
   else if(m.type==='documents-remove'&&sender===identity())rows=rows.filter(v=>v.id!==m.id);else return true;
   revision++;render();send({type:'documents-state',rows,revision});
  }catch(e){notify(e.message)}return true;
 }
 root.querySelector('#documentForm').onsubmit=e=>{e.preventDefault();const f=new FormData(e.target);try{const row=validateDocument({id:crypto.randomUUID(),name:f.get('name'),provider:f.get('provider'),url:f.get('url')});dispatch({type:'documents-add',document:row});e.target.reset()}catch(err){notify(err.message)}};
 root.querySelector('#searchForm').onsubmit=e=>{e.preventDefault();try{openUrl(googleSearch(new FormData(e.target).get('query')))}catch(err){notify(err.message)}};
 return {receive,open(){root.hidden=false;render();if(!isHost())send({type:'documents-request'})},hide(){root.hidden=true},sync(to){send({type:'documents-state',rows,revision},to)},snapshot:()=>structuredClone(rows),restore(values=[]){rows=validateRegistry(values);revision=0;render()},diagnostics:()=>({count:rows.length,revision,rows:structuredClone(rows)})};
}
