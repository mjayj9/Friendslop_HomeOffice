export const PROTOCOL_VERSION = 4;
const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
export function createRoomCode(random=crypto){
 const letters=[];
 // Rejection sampling avoids modulo bias.
 while(letters.length<6){for(const b of random.getRandomValues(new Uint8Array(12))){if(b<234)letters.push(alphabet[b%26]);if(letters.length===6)break;}}
 return letters.slice(0,3).join('')+'-'+letters.slice(3).join('');
}
export function parseInvitation(value){
 let text=String(value||'').trim();
 if(/^https?:\/\//i.test(text)){
  const url=new URL(text);text=url.searchParams.get('room')||'';
 }
 if(text.toLowerCase()==='classroom')return {code:'classroom',peer:'ho3-classroom-v1'};
 const compact=text.replace(/[\s-]/g,'').toUpperCase();
 if(!/^[A-Z]{6}$/.test(compact))throw Error('AAA-AAA 형식의 코드 또는 초대 링크를 입력하세요.');
 const code=compact.slice(0,3)+'-'+compact.slice(3);
 return {code,peer:'ho3-'+code};
}
export function invitationLink(base,code){
 const url=new URL(base);url.hash='';url.search='';url.searchParams.set('room',parseInvitation(code).code);
 // Development signaling remains loopback-only; never add it to a public invite.
 const original=new URL(base);
 if(['127.0.0.1','localhost'].includes(url.hostname)&&original.searchParams.get('signal')==='local')url.searchParams.set('signal','local');
 return url.href;
}
