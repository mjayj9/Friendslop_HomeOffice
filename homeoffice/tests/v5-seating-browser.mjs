import {chromium} from 'playwright';import fs from 'node:fs/promises';import assert from 'node:assert/strict';
const dir=process.env.V5_SEATING_DIR||'homeoffice/evidence/v5/seating-browser';await fs.mkdir(dir,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--use-angle=d3d11']}),context=await browser.newContext({viewport:{width:1440,height:900},recordVideo:{dir,size:{width:1440,height:900}}}),page=await context.newPage();
const report={environment:'Real local Godot WebGL keyboard route and F use; default male only',checks:[],errors:[],cycles:[]};page.on('pageerror',e=>report.errors.push(e.message));
const diag=()=>page.evaluate(()=>Homeoffice.diagnostics()),actor=async()=>{const d=await diag();return d.currentState.players.find(x=>x.id===d.id);};
const key=async(k,ms)=>{await page.keyboard.down(k);await page.waitForTimeout(ms);await page.keyboard.up(k);await page.waitForTimeout(80);};
async function turn(yaw,pitch=0){for(let i=0;i<8;i++){const a=await actor(),d=Math.atan2(Math.sin(yaw-a.lookYaw),Math.cos(yaw-a.lookYaw));if(Math.abs(d)<.025)break;await key(d>0?'ArrowLeft':'ArrowRight',Math.abs(d)/1.5*1000);}for(let i=0;i<6;i++){const d=pitch-(await actor()).pitch;if(Math.abs(d)<.025)break;await key(d>0?'ArrowUp':'ArrowDown',Math.abs(d)/1.2*1000);}}
async function move(x,z){for(let i=0;i<16;i++){const a=await actor(),dx=x-a.p[0],dz=z-a.p[2],n=Math.hypot(dx,dz);if(n<.25)return;await turn(Math.atan2(-dx,-dz));await key('KeyW',Math.min(1300,Math.max(25,(n-.1)/3.1*1000)));}throw Error('Walking route blocked');}
async function look(x,y,z){const a=await actor();await turn(Math.atan2(a.p[0]-x,a.p[2]-z),Math.atan2(y-a.p[1]-1.62,Math.hypot(x-a.p[0],z-a.p[2])));}
try{
 await page.goto('http://127.0.0.1:5173/homeoffice/?signal=local');await page.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:120000});report.buildId=(await diag()).buildId;await page.locator('#displayName').fill('V5 좌석 검수');await page.locator('#host').click();await page.waitForFunction(()=>Homeoffice.diagnostics().playing&&Homeoffice.diagnostics().currentState?.players.length===1);
 await key('KeyC',40);await move(-.4,10.95);await move(-6,10.95);await move(-8.8,10.95);await move(-8.8,7.7);
 for(let i=0;i<10;i++){
  const slot=i%3,x=-11+(slot-1)*.77;await move(x,7.68);await look(x,.65,8.7);await page.keyboard.press('KeyF');await page.waitForFunction(()=>Homeoffice.diagnostics().currentState.players.find(x=>x.id===Homeoffice.diagnostics().id).seat==='living-sofa-a',null,{timeout:8000});await page.waitForTimeout(1200);
  const state=await actor(),a=(await diag()).avatarDiagnostics.instances.find(x=>x.local);assert.equal(state.seatIndex,slot);report.cycles.push({i,slot,position:state.p,contacts:a.contactSamples});
  if(i<3){await page.keyboard.press('KeyC');await turn(2.6,-.10);await page.mouse.wheel(0,-720);await page.waitForTimeout(300);await page.screenshot({path:dir+`/seat-${slot}.png`});await page.mouse.wheel(0,720);await page.keyboard.press('KeyC');}
  await page.keyboard.press('KeyF');await page.waitForFunction(()=>Homeoffice.diagnostics().currentState.players.find(x=>x.id===Homeoffice.diagnostics().id).seat==='');
 }
 report.checks.push({name:'Ten physical approach / F sit / F stand cycles across all three seats',ok:true});assert.equal(report.errors.length,0);report.completed=true;
}catch(e){report.failure=e.stack;report.state=await diag().catch(()=>null);await page.screenshot({path:dir+'/failure.png'});process.exitCode=1;console.error(e);}
finally{report.video=await page.video().path();await browser.close();await fs.writeFile(dir+'/report.json',JSON.stringify(report,null,2));console.log(JSON.stringify({buildId:report.buildId,completed:report.completed,checks:report.checks,errors:report.errors}));}
