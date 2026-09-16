import {fileURLToPath} from 'node:url';
process.chdir(fileURLToPath(new URL('../../',import.meta.url)));
import {chromium} from 'playwright';
import fs from 'node:fs/promises';
const browsers=[],pages=[],logs=[],errors=[];
async function wait(p,fn,timeout=45000){await p.waitForFunction(fn,null,{polling:200,timeout})}
try{
 for(let i=0;i<2;i++){
  console.log('LAUNCH',i);
  const b=await chromium.launch({headless:true,args:['--use-angle=d3d11','--autoplay-policy=no-user-gesture-required','--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream']});browsers.push(b);
  const c=await b.newContext({viewport:{width:960,height:540},permissions:['microphone']});const p=await c.newPage();pages.push(p);
  p.on('console',m=>{logs.push(i+' '+m.type()+' '+m.text());console.log(i,m.type(),m.text())});p.on('pageerror',e=>errors.push(e.message));
  await p.goto('http://127.0.0.1:8060/homeoffice/?signal=local');await wait(p,()=>Homeoffice.readyState());console.log('READY',i);
  if(i===0){await p.screenshot({path:'homeoffice/evidence/browser-entry.png',timeout:15000});await p.locator('#host').click({force:true});await wait(p,()=>Homeoffice.diagnostics().currentState?.players.length===1);console.log('HOST',await p.evaluate(()=>Homeoffice.diagnostics().room))}
 }
 const [a,b]=pages;const room=await a.evaluate(()=>Homeoffice.diagnostics().room);
 await b.locator('#room').fill(room);await b.locator('#join').click({force:true});
 await wait(a,()=>Homeoffice.diagnostics().currentState?.players.length===2);await wait(b,()=>Homeoffice.diagnostics().currentState?.players.length===2);
 console.log('REAL_WEBRTC_TWO_PLAYERS');
 await b.locator('#canvas').click({force:true,position:{x:480,y:270}});
 await a.screenshot({path:'homeoffice/evidence/browser-two-player.png',timeout:15000});
 const before=await b.evaluate(()=>{const d=Homeoffice.diagnostics();return d.currentState.players.find(p=>p.id===d.id).p});
 await b.keyboard.down('KeyW');await b.waitForTimeout(750);await b.keyboard.up('KeyW');await b.waitForTimeout(600);
 const aa=await a.evaluate(()=>Homeoffice.diagnostics()),bb=await b.evaluate(()=>Homeoffice.diagnostics());
 const after=bb.currentState.players.find(p=>p.id===bb.id).p,auth=aa.currentState.players.find(p=>p.id===bb.id).p;
 if(Math.hypot(...before.map((v,i)=>v-after[i]))<.4)errors.push('guest did not move');if(Math.hypot(...auth.map((v,i)=>v-after[i]))>.5)errors.push('host/guest divergence');
 console.log('MOVEMENT',JSON.stringify({before,after,auth,errors}));await a.evaluate(()=>Homeoffice.menu());console.log('MENU',await a.locator('#menu').isVisible());await a.screenshot({path:'homeoffice/evidence/menu.png'});const dl=await Promise.all([a.waitForEvent('download',{timeout:10000}),a.locator('#export').click({force:true})]);await dl[0].saveAs('homeoffice/evidence/browser-export.homeworld');
 await fs.writeFile('homeoffice/evidence/browser-2p.json',JSON.stringify({browser:browsers[0].version(),transport:'two separate real Chromium processes, local PeerServer + native WebRTC loopback ICE; no mock transport',before,after,auth,errors},null,2));
 console.log('RESULT',JSON.stringify({before,after,auth,errors}));
}catch(e){console.log('FAILURE',e.message);errors.push(e.message)}finally{await fs.writeFile('homeoffice/evidence/browser-2p.log',logs.join('\n'));for(const b of browsers)await b.close()}
if(errors.length)process.exitCode=1;
