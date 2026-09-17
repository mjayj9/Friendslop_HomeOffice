import {CHAT_LIMITS} from './chat-protocol.mjs';
export function safeFileName(name){return String(name).normalize('NFKC').replace(/[\x00-\x1f\x7f<>:"/\\|?*\u202a-\u202e\u2066-\u2069]/g,'_').slice(0,120)||'file';}
function jpegSize(a){
 let i=2;while(i+9<a.length){if(a[i++]!==255)continue;const tag=a[i++];if(tag===0xd9||tag===0xda)break;if(tag===0xd8||tag===1)continue;const length=(a[i]<<8)|a[i+1];if(length<2||i+length>a.length)break;if([0xc0,0xc1,0xc2].includes(tag))return [(a[i+5]<<8)|a[i+6],(a[i+3]<<8)|a[i+4]];i+=length;}return [0,0];
}
export function inspectBytes(bytes,name){
 const a=bytes instanceof Uint8Array?bytes:new Uint8Array(bytes),ext=name.split('.').pop().toLowerCase();
 if(!a.length||a.length>CHAT_LIMITS.fileBytes)throw Error('파일은 1바이트–20MiB까지 지원합니다.');
 let mime='',dimensions=null;
 if(ext==='png'&&a.length>=24&&[137,80,78,71,13,10,26,10].every((b,i)=>a[i]===b)&&String.fromCharCode(...a.slice(12,16))==='IHDR'){
  mime='image/png';const d=new DataView(a.buffer,a.byteOffset,a.byteLength);dimensions=[d.getUint32(16),d.getUint32(20)];
 }else if(['jpg','jpeg'].includes(ext)&&a[0]===255&&a[1]===216&&a[2]===255){mime='image/jpeg';dimensions=jpegSize(a);}
 else if(ext==='pdf'&&new TextDecoder().decode(a.slice(0,5))==='%PDF-')mime='application/pdf';
 else if(ext==='txt'){
  let value;try{value=new TextDecoder('utf-8',{fatal:true}).decode(a);}catch{throw Error('텍스트 파일은 UTF-8을 사용하세요.');}
  if(/[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(value)||/^\s*(<!doctype\s+html|<html|<svg|<script)/i.test(value))throw Error('실행 가능한 문서 형식은 지원하지 않습니다.');mime='text/plain';
 }
 if(!mime)throw Error('PNG/JPEG, PDF, UTF-8 TXT를 지원합니다. 파일 확장자와 실제 형식이 일치해야 합니다.');
 if(dimensions&&(!dimensions[0]||!dimensions[1]||dimensions[0]>8192||dimensions[1]>8192||dimensions[0]*dimensions[1]>16000000))throw Error('이미지는 각 변 8192px, 전체 1600만 픽셀 이하여야 합니다.');
 return {mime,dimensions,size:a.length,name:safeFileName(name)};
}
export async function prepareFile(file){
 if(file.size>CHAT_LIMITS.fileBytes)throw Error('파일은 20MiB 이하여야 합니다.');
 const bytes=new Uint8Array(await file.arrayBuffer()),info=inspectBytes(bytes,file.name);
 if(info.mime.startsWith('image/')){const bitmap=await createImageBitmap(new Blob([bytes],{type:info.mime}));if(bitmap.width*bitmap.height>16000000){bitmap.close();throw Error('이미지 디코드 한도를 초과했습니다.');}bitmap.close();}
 const hash=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(x=>x.toString(16).padStart(2,'0')).join('');
 return {bytes,meta:{id:crypto.randomUUID(),name:info.name,size:info.size,mime:info.mime,hash}};
}
