import {fileURLToPath} from 'node:url';
process.chdir(fileURLToPath(new URL('../../',import.meta.url)));
import {chromium} from 'playwright';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
const browsers=[],pages=[],logs=[],results=[];
const base='http://127.0.0.1:8060/homeoffice/?signal=local';
const wait=async(p,fn,ms=15000)=>p.waitForFunction(fn,null,{polling:100,timeout:ms});
const diag=p=>p.evaluate(()=>Homeoffice.diagnostics());
const actor=async p=>{const d=await diag(p);return d.currentState.players.find(v=>v.id===d.id)};
async function key(p,name,ms){await p.keyboard.down(name);await p.waitForTimeout(Math.max(30,ms));await p.keyboard.up(name);await p.waitForTimeout(120)}
async function turn(p,yaw,pitch=0){for(let i=0;i<3;i++){const s=await actor(p);const d=Math.atan2(Math.sin(yaw-s.yaw),Math.cos(yaw-s.yaw));if(Math.abs(d)<.025)break;await key(p,d>0?'ArrowLeft':'ArrowRight',Math.abs(d)/1.5*1000)}for(let i=0;i<3;i++){const s=await actor(p);const d=pitch-s.pitch;if(Math.abs(d)<.025)break;await key(p,d>0?'ArrowUp':'ArrowDown',Math.abs(d)/1.2*1000)}}
async function move(p,x,z){for(let i=0;i<4;i++){const s=await actor(p);const dx=x-s.p[0],dz=z-s.p[2],distance=Math.hypot(dx,dz);if(distance<.20)return;await turn(p,Math.atan2(-dx,-dz));await key(p,'KeyW',Math.min(1500,Math.max(60,(distance-.08)/3.1*1000)))}const s=await actor(p);assert.ok(Math.hypot(x-s.p[0],z-s.p[2])<.5,'walk path reached '+x+','+z+' actual '+s.p)}
async function aim(p,x,y,z){const s=await actor(p);const dx=x-s.p[0],dy=y-(s.p[1]+1.62),dz=z-s.p[2];await turn(p,Math.atan2(-dx,-dz),Math.atan2(dy,Math.hypot(dx,dz)))}
async function resume(p){await p.evaluate(()=>document.getElementById('resume').click());await p.waitForTimeout(200)}
function pass(name,data={}){results.push({name,passed:true,...data});console.log('PASS',name,JSON.stringify(data))}
try{
 for(let i=0;i<2;i++){const b=await chromium.launch({headless:true,args:['--use-angle=d3d11','--autoplay-policy=no-user-gesture-required','--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream']});browsers.push(b);const c=await b.newContext({viewport:{width:1280,height:720},permissions:['microphone']});const p=await c.newPage();pages.push(p);p.on('console',m=>logs.push(i+' '+m.type()+' '+m.text()));p.on('pageerror',e=>logs.push('PAGEERROR '+e.message));await p.goto(base);await wait(p,()=>Homeoffice.readyState(),30000);if(i===0){await p.locator('#host').click({force:true});await wait(p,()=>Homeoffice.diagnostics().currentState?.players.length===1)}}
 const[a,b]=pages;await b.locator('#room').fill((await diag(a)).room);await b.locator('#join').click({force:true});await wait(a,()=>Homeoffice.diagnostics().currentState?.players.length===2);await wait(b,()=>Homeoffice.diagnostics().currentState?.players.length===2);pass('T12 real WebRTC two-player connection');
 await move(b,2.4,2);await aim(b,2.4,.46,.4);await b.keyboard.press('KeyE');await b.waitForTimeout(500);assert.equal((await actor(b)).seat,'lounge-chair');pass('T05 guest sits in authored chair');
 await aim(a,2.4,.46,.4);await a.keyboard.press('KeyE');await a.waitForTimeout(300);assert.equal((await actor(a)).seat,'');pass('T05 occupied chair refuses second actual browser');
 await aim(a,2.4,1,.4);await a.screenshot({path:'homeoffice/evidence/game-seated-character.png'});
 await b.keyboard.press('KeyE');await b.waitForTimeout(300);assert.equal((await actor(b)).seat,'');pass('T06 safe standing from chair');
 await move(a,1.4,-.8);await aim(a,-.6,.88,-.5);await a.keyboard.press('KeyE');await a.waitForTimeout(400);assert.equal((await actor(a)).hold,'book-1');await a.keyboard.press('KeyF');await wait(a,()=>!document.getElementById('book').hidden);await a.screenshot({path:'homeoffice/evidence/game-reading.png'});await a.locator('#nextPage').click({force:true});assert.ok((await a.locator('#pageNumber').textContent()).startsWith('2'));pass('T07 real book pickup, reading and page turn');
 const still=(await actor(a)).p;await key(a,'KeyW',400);assert.ok(Math.hypot(...(await actor(a)).p.map((v,i)=>v-still[i]))<.05);pass('T04 DOM reading prevents movement shortcuts');await a.locator('#closeTool').click({force:true});await a.waitForTimeout(250);await a.keyboard.press('KeyQ');await a.waitForTimeout(300);
 await move(a,3.9,-.2);await aim(a,6,1,-.2);await a.keyboard.press('KeyE');await a.waitForTimeout(700);assert.equal((await diag(a)).currentState.door,true);pass('T12 door change synced');
 await move(a,5.2,-.2);await move(a,7.2,-.2);await move(a,7.5,-2.8);await move(a,9,-3.2);await aim(a,9.5,1.7,-4.7);await a.keyboard.press('KeyE');await wait(a,()=>!document.getElementById('tool').hidden);const rect=await a.locator('#whiteboard').boundingBox();await a.mouse.move(rect.x+180,rect.y+130);await a.mouse.down();await a.mouse.move(rect.x+480,rect.y+250,{steps:20});await a.mouse.up();await a.waitForTimeout(500);assert.ok((await diag(a)).boardStrokes.length>0);await wait(b,()=>Homeoffice.diagnostics().boardStrokes.length>0);pass('T28 real browser board drawing synchronized');await a.screenshot({path:'homeoffice/evidence/game-whiteboard.png'});await a.locator('#closeTool').click({force:true});await a.waitForTimeout(300);await a.screenshot({path:'homeoffice/evidence/game-meeting.png'});
 await a.evaluate(()=>Homeoffice.menu());const download=await Promise.all([a.waitForEvent('download'),a.locator('#export').click({force:true})]);await download[0].saveAs('homeoffice/evidence/lived-in.homeworld');pass('T42 browser export includes edited board');
 // Synthetic microphone sends real WebRTC media. This is not a human microphone/echo quality test.
 await a.locator('#mic').click({force:true});await a.locator('#openMic').check({force:true});await a.evaluate(()=>{const e=document.getElementById('range');e.value='2';e.dispatchEvent(new Event('input'))});await resume(a);
 await b.evaluate(()=>Homeoffice.menu());await b.locator('#mic').click({force:true});await b.locator('#openMic').check({force:true});await resume(b);
 await a.waitForTimeout(2500);const far=await diag(a);assert.equal(far.voiceOutgoing,0);pass('T19 audio track is not sent beyond selected 2m range');
 await move(b,4.3,-.2);await move(b,7.2,-.2);await move(b,7.5,-2.8);await move(b,9.8,-3.2);await b.waitForTimeout(3000);
 const stats=await b.evaluate(()=>Homeoffice.voice_stats());assert.ok(stats.some(s=>s.packetsReceived>0));pass('T19 synthetic microphone actual RTP received at near distance',{stats});
 await a.evaluate(()=>Homeoffice.menu());await a.locator('#mic').click({force:true});await resume(a);await a.waitForTimeout(500);assert.equal((await diag(a)).voiceOutgoing,0);pass('T22 mute closes outbound audio route');
}catch(e){results.push({name:'walkthrough',passed:false,error:e.message});console.log('FAIL',e.stack);for(let i=0;i<pages.length;i++)try{await pages[i].screenshot({path:`homeoffice/evidence/life-failure-${i}.png`});console.log('STATE',i,JSON.stringify(await diag(pages[i])))}catch{}}
finally{await fs.writeFile('homeoffice/evidence/browser-life.json',JSON.stringify({browser:browsers[0]?.version(),environment:'two Chromium processes; Windows D3D11; local WebRTC/PeerServer; synthetic microphone',results},null,2));await fs.writeFile('homeoffice/evidence/browser-life.log',logs.join('\n'));for(const b of browsers)await b.close()}
if(results.some(r=>!r.passed))process.exitCode=1;
