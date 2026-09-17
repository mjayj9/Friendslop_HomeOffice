export async function verifyBuild(){
 const response=await fetch('./build-info.json',{cache:'no-store'});if(!response.ok)throw Error('빌드 정보를 읽지 못했습니다.');
 const info=await response.json();if(info.protocolVersion!==4)throw Error('지원하지 않는 게임 버전입니다.');
 const files=['index.pck','index.wasm','index.js','bridge.mjs','build-id.mjs'];
 for(const name of files){
  const expected=info.files[name];if(!expected)throw Error('빌드 파일 목록 누락: '+name);
  const r=await fetch('./'+name,{cache:'no-store'});if(!r.ok)throw Error('파일을 읽지 못했습니다: '+name);
  const data=await r.arrayBuffer();const digest=[...new Uint8Array(await crypto.subtle.digest('SHA-256',data))].map(b=>b.toString(16).padStart(2,'0')).join('');
  if(data.byteLength!==expected.bytes||digest!==expected.sha256)throw Error('서로 다른 빌드가 섞였습니다: '+name+' · Ctrl+Shift+R로 새로고침하세요. 저장 파일은 삭제하지 마세요.');
 }
 window.HomeofficeBuild=info;return info;
}
