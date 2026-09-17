import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createPrivateKey,createPublicKey} from 'node:crypto';
import {createAdminPolicy,PolicyError} from './admin-policy.mjs';
import {clerkIdentity} from './clerk-adapter.mjs';

// A single process owns this private store. Multiple replicas require a transactional shared store.
export function privateDiskStore(directory){const file=path.join(directory,'room-policy.private.json');return {read:async()=>{try{return JSON.parse(await fs.readFile(file,'utf8'));}catch(e){if(e.code==='ENOENT')return {rooms:{},sessions:{}};throw e;}},write:async value=>{const temp=file+'.tmp';await fs.writeFile(temp,JSON.stringify(value),{mode:0o600});await fs.rename(temp,file);}};}
export function createPolicyHttpServer({policy,origins}){
 const limits=new Map();
 return http.createServer(async(req,res)=>{
  const origin=req.headers.origin;
  res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
  if(!origins.includes(origin)){res.writeHead(403);res.end();return;}
  res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');res.setHeader('Access-Control-Allow-Headers','Authorization, Content-Type');res.setHeader('Access-Control-Allow-Methods','GET, POST, OPTIONS');
  if(req.method==='OPTIONS'){res.writeHead(204);res.end();return;}
  const address=req.socket.remoteAddress,at=Date.now();for(const[k,v]of limits)if(at-v.at>60000)limits.delete(k);const l=limits.get(address)||{at,count:0};l.count++;limits.set(address,l);
  const respond=(status,value)=>{res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify(value));};
  try{
   if(l.count>240)throw new PolicyError(429,'요청 제한입니다.');
   const url=new URL(req.url,'http://local');
   if(req.method==='GET'&&url.pathname==='/state')return respond(200,await policy.state({session:url.searchParams.get('session'),challenge:url.searchParams.get('challenge')}));
   const token=req.headers.authorization?.replace(/^Bearer /,'');
   if(req.method==='POST'&&url.pathname==='/identity')return respond(200,await policy.identify(token));
   if(req.method!=='POST'||url.pathname!=='/command')throw new PolicyError(404,'지원하지 않는 요청');
   if(!req.headers['content-type']?.startsWith('application/json'))throw new PolicyError(415,'JSON 요청이 필요합니다.');
   const chunks=[];let size=0;for await(const chunk of req){size+=chunk.length;if(size>8192)throw new PolicyError(413,'요청 크기 제한');chunks.push(chunk);}
   let input;try{input=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{throw new PolicyError(400,'요청 형식 오류');}
   respond(200,await policy.command({...input,token}));
  }catch(e){respond(e instanceof PolicyError?e.status:500,{error:e instanceof PolicyError?e.message:'관리 서비스 처리 실패'});}
  // Do not log Authorization, request bodies, PINs, or internal exceptions.
 });
}
async function main(){
 const dir=process.env.COMMONS_PRIVATE_DIR;if(!dir||!path.isAbsolute(dir))throw Error('프로젝트 밖의 절대 COMMONS_PRIVATE_DIR 경로가 필요합니다.');
 const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..'),resolved=await fs.realpath(dir);if(resolved.toLowerCase().startsWith(repo.toLowerCase()+path.sep)||resolved===repo)throw Error('비공개 저장소를 프로젝트 안에 둘 수 없습니다.');
 const origins=(process.env.COMMONS_ORIGINS||'').split(',').filter(Boolean),adminIds=new Set((process.env.COMMONS_ADMIN_IDS||'').split(',').filter(Boolean));if(!origins.length||!adminIds.size)throw Error('허용 Origin과 실제 관리자 UID가 필요합니다.');
 const privateKey=createPrivateKey(await fs.readFile(path.join(resolved,'signing-key.pem'))),publicKey=createPublicKey(privateKey).export({format:'jwk'});if(publicKey.crv!=='P-256')throw Error('P-256 서명 키가 필요합니다.');
 const verifyIdentity=await clerkIdentity({jwtKey:await fs.readFile(path.join(resolved,'clerk-jwt-public.pem'),'utf8'),authorizedParties:origins,issuer:process.env.CLERK_ISSUER});
 const policy=createAdminPolicy({verifyIdentity,adminIds,privateKey,store:privateDiskStore(resolved)});
 // One-time bootstrap consumes an operator-provisioned private file; its value is never returned or logged.
 const initial=path.join(resolved,'initial-pin.private');try{await policy.bootstrap((await fs.readFile(initial,'utf8')).trim());await fs.unlink(initial);}catch(e){if(e.code!=='ENOENT')throw e;}
 createPolicyHttpServer({policy,origins}).listen(Number(process.env.PORT||9087),'127.0.0.1',()=>console.log('COMMONS admin service ready on loopback; use an HTTPS reverse proxy.'));
}
if(process.argv[1]&&fileURLToPath(import.meta.url)===path.resolve(process.argv[1]))main().catch(()=>{console.error('관리 서비스 시작 실패: 비공개 설정과 의존성을 확인하세요.');process.exitCode=1;});
