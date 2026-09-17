import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const project=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const args=process.argv.slice(2);
const option=(name,fallback)=>{const at=args.indexOf(name);return at<0?fallback:args[at+1]};
const port=Number(option('--port',process.env.PORT||8060));
if(!Number.isInteger(port)||port<1||port>65535)throw Error('Invalid HTTP port');
const published=path.resolve(project,'../docs'), built=path.join(project,'build');
const artifact=option('--artifact','auto');
if(!['auto','published','build'].includes(artifact))throw Error('Use --artifact auto, published or build');
const root=artifact==='published'?published:artifact==='build'?built:fs.existsSync(path.join(built,'build-info.json'))?built:published;
const manifestPath=path.join(root,'build-info.json');
if(!fs.existsSync(manifestPath))throw Error(`V3 export is missing in ${root}. Download the complete repository including docs/, or run tools/build.ps1.`);
const manifest=JSON.parse(fs.readFileSync(manifestPath,'utf8'));
if(![3,4].includes(manifest.protocolVersion)||!['index.html','index.js','index.pck','index.wasm','build-guard.mjs'].every(name=>fs.existsSync(path.join(root,name))))throw Error(`Incomplete V3 export: ${root}`);
const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.json':'application/json','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml','.jpg':'image/jpeg','.pdf':'application/pdf','.wav':'audio/wav','.txt':'text/plain; charset=utf-8'};
const server=http.createServer((req,res)=>{
 let url;try{url=decodeURIComponent(new URL(req.url,'http://localhost').pathname)}catch{res.writeHead(400).end();return}
 if(url==='/favicon.ico'){res.writeHead(204).end();return}
 let rel=url.replace(/^\/(?:homeoffice|Friendslop_HomeOffice)\//,'/');
 if(rel.endsWith('/'))rel+='index.html';
 const file=path.resolve(root,'.'+rel);
 if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return}
 fs.stat(file,(err,s)=>{
  if(err||!s.isFile()){res.writeHead(404).end();return}
  res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Content-Length':s.size,'Cache-Control':'no-store','X-HomeOffice-Build':manifest.buildId});
  if(req.method==='HEAD'){res.end();return}
  fs.createReadStream(file).on('error',()=>res.destroy()).pipe(res);
 });
});
try{
 await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,'127.0.0.1',resolve)});
 console.log(`Game: http://localhost:${port}/ | build ${manifest.buildId} | ${root}`);
 if(args.includes('--local-signaling')){
  const {PeerServer}=await import('peer');
  const peer=PeerServer({port:9001,host:'127.0.0.1',path:'/homeoffice',allow_discovery:false});
  peer.on('error',error=>{console.error('Local signaling failed:',error.message);server.close();process.exitCode=1});
  console.log('Development signaling: loopback 9001; use ?signal=local');
 }
}catch(error){console.error(error.code==='EADDRINUSE'?`Port ${port} is busy. Stop the previous preview or use --port <number>.`:error);server.close();process.exitCode=1}
