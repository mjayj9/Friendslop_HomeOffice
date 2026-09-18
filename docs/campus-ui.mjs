// Controls display authoritative car state; requests still require physical proximity.
export function createCampusUI({push,close}) {
  let state={},mode='',liftId='';
  const root=document.createElement('section');root.id='campusPanel';root.hidden=true;root.className='campus-panel';
  root.innerHTML='<header><span class="eyebrow">COMMONS · OFFICE</span><h2>층 안내</h2><button type="button" data-close>공간으로 돌아가기</button></header><p data-status role="status"></p><div data-floors class="campus-floors"></div><div data-feeds hidden><button data-feed="0">1층 공용 홀</button><button data-feed="1">B1 공용 홀</button><p>게임 속 공개 장소만 표시합니다. 콘솔을 닫거나 자리를 떠나면 화면 갱신이 중단됩니다.</p></div>';
  document.body.append(root);
  root.querySelector('[data-close]').onclick=close;
  root.querySelectorAll('[data-feed]').forEach(b=>b.onclick=()=>push({type:'campus_cctv',op:'select',feed:+b.dataset.feed}));
  const names={IDLE:'대기',OPENING:'문 열림 중',OPEN:'탑승 가능',CLOSING:'문 닫힘 중',MOVING:'이동 중',ARRIVING:'도착 중',LEVELING:'층 높이 조정',HOLD:'대기 필요',FAULT:'점검 중'};
  function render(){
    if(root.hidden)return;
    const car=state.lifts?.[liftId];root.querySelector('h2').textContent=mode==='directory'?'OFFICE 층별 안내':mode==='cctv'?'공용 공간 모니터':`${liftId==='service'?'서비스':'승객'} 승강기`;
    root.querySelector('[data-status]').textContent=mode==='directory'?`현재 ${state.floor||'1F'} · 계단과 승강기로 이동하세요`:mode==='cctv'?(state.cctv?'콘솔에서 실제 공간을 확인하세요 · 8fps':'모니터가 중지되었습니다'):car?`${car.floor} · ${names[car.state]||car.state}${car.target!==car.floor?' → '+car.target:''} · 탑승 ${car.occupants?.length||0}명${car.reason?' · '+car.reason:''}`:'승강기 상태를 확인하는 중…';
    const floors=root.querySelector('[data-floors]');floors.hidden=mode==='cctv';root.querySelector('[data-feeds]').hidden=mode!=='cctv';
    if(!floors.children.length)for(const floor of [...(state.directory||[])].reverse()){const b=document.createElement('button');b.dataset.floor=floor.id;b.textContent=`${floor.id}  ${floor.title}`;b.onclick=()=>push({type:'campus_lift',liftId,floor:floor.id});floors.append(b);}
    for(const b of floors.children){b.disabled=mode==='directory';b.classList.toggle('current',b.dataset.floor===car?.floor);b.classList.toggle('queued',car?.queue?.includes(b.dataset.floor)||b.dataset.floor===car?.target&&car.target!==car.floor);b.setAttribute('aria-pressed',String(b.classList.contains('queued')));}
  }
  return {zoneName(zone){if(!zone.startsWith('office-'))return '';const names={'office-2-council':'2F 느티나무 회의실','office-2-moss':'2F 이끼 회의실','office-2-clay':'2F 흙빛 회의실','office-2-seminar':'2F 열린 세미나','office-5-operations':'5F 운영실','office-5-broadcast':'5F 방송실'};if(names[zone])return names[zone];if(/^office-[1-8]$/.test(zone))return '4F 개인 작업실 '+zone.split('-')[1];const floor=(state.directory||[]).find(f=>zone.startsWith('office-'+f.id+'-'));return floor?`${floor.id} ${zone.endsWith('-wc')?'공용 화장실':floor.title}`:'';},open(value){mode=value==='directory'?'directory':value==='cctv'?'cctv':'lift';liftId=value.split(':')[1]||'';root.hidden=false;render();},hide(){if(mode==='cctv')push({type:'campus_cctv',op:'close'});mode='';root.hidden=true;},update(next){state=next;render();},diagnostics(){return state;}};
}
