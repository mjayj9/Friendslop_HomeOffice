export const MEETING_ROOMS = Object.freeze([
  {id:'council',title:'느티나무 · 주회의실',buildingId:'office',floorId:'2F',roomId:'office-2-council',projectId:'commons'},
  {id:'moss',title:'이끼 · 소회의실',buildingId:'office',floorId:'2F',roomId:'office-2-moss',projectId:'studio'},
  {id:'clay',title:'흙빛 · 소회의실',buildingId:'office',floorId:'2F',roomId:'office-2-clay',projectId:'design'},
  {id:'seminar',title:'열린 세미나',buildingId:'office',floorId:'2F',roomId:'office-2-seminar',projectId:'community'},
]);

// Simulation moderators manage meeting membership, never building administrator access.
export function createMeetingPolicy({isMember}) {
  const membership=new Map(), revoked=new Map(); let generation=0;
  return {
    join(peer,meetingId){
      if(!isMember(peer)||!MEETING_ROOMS.some(r=>r.id===meetingId)||revoked.get(meetingId)?.has(peer))return null;
      const lease={meetingId,generation:++generation};membership.set(peer,lease);return {...lease};
    },
    permits(peer,meetingId,lease){const grant=membership.get(peer);return isMember(peer)&&!!grant&&grant.meetingId===meetingId&&grant.generation===lease;},
    current(peer){return membership.get(peer)?.meetingId||'';},
    grant(peer){return membership.has(peer)?{...membership.get(peer)}:null;},
    peers(meetingId){return [...membership].filter(([p,v])=>v.meetingId===meetingId&&isMember(p)).map(([p])=>p);},
    revoke(peer,meetingId){if(!revoked.has(meetingId))revoked.set(meetingId,new Set());revoked.get(meetingId).add(peer);if(membership.get(peer)?.meetingId===meetingId)membership.delete(peer);},
    leave(peer){membership.delete(peer);},
    reset(){membership.clear();revoked.clear();generation++;},
  };
}

export function validateMeetingArchive(value){
  if(value===undefined)return [];
  if(!Array.isArray(value)||value.length>MEETING_ROOMS.length)throw Error('회의 보관 형식/수 한도');
  const ids=new Set();
  for(const row of value){
    const allowed=['id','collaboration','documents','presentation','presentationView','board'];
    if(!row||Object.getPrototypeOf(row)!==Object.prototype||Object.keys(row).some(k=>!allowed.includes(k))||!MEETING_ROOMS.some(r=>r.id===row.id)||ids.has(row.id))throw Error('알 수 없는 회의 또는 일시 권한 포함');
    ids.add(row.id);
    if(!row.collaboration||Object.keys(row.collaboration).some(k=>!['update','revision'].includes(k))||typeof row.collaboration.update!=='string'||row.collaboration.update.length>3e6||!/^[A-Za-z0-9+/]*={0,2}$/.test(row.collaboration.update)||!Number.isSafeInteger(row.collaboration.revision)||row.collaboration.revision<0)throw Error('회의 문서 형식');
    if(!Array.isArray(row.board)||row.board.length>256)throw Error('회의 보드 한도');
    for(const stroke of row.board)if(!stroke||Object.keys(stroke).some(k=>!['id','author','points','color','width'].includes(k))||typeof stroke.id!=='string'||stroke.id.length>100||typeof stroke.author!=='string'||stroke.author.length>100||!/^#[a-fA-F0-9]{6}$/.test(stroke.color)||!Number.isFinite(stroke.width)||stroke.width<1||stroke.width>16||!Array.isArray(stroke.points)||stroke.points.length<2||stroke.points.length>256||stroke.points.some(p=>!Array.isArray(p)||p.length!==2||p.some(n=>!Number.isFinite(n)||n<0||n>1)))throw Error('회의 보드 데이터 형식');
  }
  return structuredClone(value);
}
