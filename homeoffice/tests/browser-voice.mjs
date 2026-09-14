import {chromium} from 'playwright';
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
process.chdir(fileURLToPath(new URL('../../',import.meta.url)));
const browsers=[],pages=[],results=[];
const wait=(p,f)=>p.waitForFunction(f,null,{polling:100,timeout:15000});
try{
 for(let i=0;i<2;i++){const b=await chromium.launch({headless:true,args:['--use-angle=d3d11','--autoplay-policy=no-user-gesture-required','--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream']});browsers.push(b);const p=await b.newPage({viewport:{width:960,height:640},permissions:['microphone']});pages.push(p);await p.goto('http://127.0.0.1:8060/homeoffice/?signal=local');await wait(p,()=>Homeoffice.readyState());if(i===0){await p.locator('#host').click({force:true});await wait(p,()=>Homeoffice.diagnostics().currentState?.players.length===1)}}
 const[a,b]=pages;await b.locator('#room').fill(await a.evaluate(()=>Homeoffice.diagnostics().room));await b.locator('#join').click({force:true});await wait(a,()=>Homeoffice.diagnostics().currentState?.players.length===2);await wait(b,()=>Homeoffice.diagnostics().currentState?.players.length===2);
 await a.evaluate(()=>Homeoffice.menu());await a.locator('#mic').click({force:true});await a.locator('#openMic').check({force:true});await a.waitForTimeout(2000);
 let d=await a.evaluate(()=>Homeoffice.diagnostics());assert.equal(d.playing,false);assert.equal(d.voiceOutgoing,1);const stats=await b.evaluate(()=>Homeoffice.voice_stats());assert.ok(stats.some(s=>s.packetsReceived>0));results.push({test:'Synthetic real RTC audio continues while sender uses modal UI with open mic selected',passed:true,stats});
 assert.ok(await a.locator('#level').evaluate(m=>m.value)>0);results.push({test:'Actual local input meter receives synthetic microphone samples in menu',passed:true});
 await a.locator('#micOff').click({force:true});await a.waitForTimeout(400);d=await a.evaluate(()=>Homeoffice.diagnostics());assert.equal(d.mic,false);assert.equal(d.voiceOutgoing,0);results.push({test:'Device stop terminates capture and media route',passed:true});
 console.log('VOICE_TESTS',JSON.stringify(results));
}catch(e){results.push({passed:false,error:e.message});console.log(e.stack);process.exitCode=1}finally{await fs.writeFile('homeoffice/evidence/browser-voice.json',JSON.stringify({scope:'real WebRTC, synthetic source; not actual human mic quality',results},null,2));for(const b of browsers)await b.close()}
