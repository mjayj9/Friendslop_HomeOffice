import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../build');
const mime={'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml'};
http.createServer((req,res)=>{let url;try{url=decodeURIComponent(new URL(req.url,'http://localhost').pathname)}catch{res.writeHead(400).end();return}let rel=url.replace(/^\/homeoffice\//,'/');if(rel.endsWith('/'))rel+='index.html';const file=path.resolve(root,'.'+rel);if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return}fs.stat(file,(err,s)=>{if(err||!s.isFile()){res.writeHead(404).end();return}res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Content-Length':s.size,'Cache-Control':'no-store'});fs.createReadStream(file).pipe(res)})}).listen(8060,'127.0.0.1',()=>console.log('Game: http://127.0.0.1:8060/homeoffice/'));
if(process.argv.includes('--local-signaling')){const {PeerServer}=await import('peer');PeerServer({port:9001,host:'127.0.0.1',path:'/homeoffice',allow_discovery:false});console.log('Development signaling: loopback 9001; use ?signal=local')}
