import {chromium} from 'playwright';import fs from 'node:fs/promises';import assert from 'node:assert/strict';
const base=process.env.V5_BASE_URL||'http://127.0.0.1:5173/homeoffice/?signal=local';
const dir=process.env.V5_PLACEMENT_DIR||'homeoffice/evidence/v5/placement-browser';await fs.mkdir(dir,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--use-angle=d3d11']}),context=await browser.newContext({viewport:{width:1440,height:900},deviceScaleFactor:1.5,recordVideo:{dir,size:{width:1440,height:900}}}),page=await context.newPage();
const report={kind:'Actual Chromium UI input, isolated room, deviceScaleFactor 1.5',checks:[],errors:[]};page.on('pageerror',e=>report.errors.push(e.message));
const diag=()=>page.evaluate(()=>Homeoffice.diagnostics()),actor=async()=>{const d=await diag();return d.currentState.players.find(x=>x.id===d.id);};
const key=async(k,ms)=>{await page.keyboard.down(k);await page.waitForTimeout(ms);await page.keyboard.up(k);await page.waitForTimeout(80);};
async function turn(yaw,pitch=0){for(let i=0;i<8;i++){const a=await actor(),d=Math.atan2(Math.sin(yaw-a.lookYaw),Math.cos(yaw-a.lookYaw));if(Math.abs(d)<.025)break;await key(d>0?'ArrowLeft':'ArrowRight',Math.abs(d)/1.5*1000);}for(let i=0;i<6;i++){const d=pitch-(await actor()).pitch;if(Math.abs(d)<.025)break;await key(d>0?'ArrowUp':'ArrowDown',Math.abs(d)/1.2*1000);}}
async function move(x,z){for(let i=0;i<16;i++){const a=await actor(),dx=x-a.p[0],dz=z-a.p[2],n=Math.hypot(dx,dz);if(n<.3)return;await turn(Math.atan2(-dx,-dz));await key('KeyW',Math.min(1300,Math.max(25,(n-.12)/3.1*1000)));}throw Error('Walking route blocked');}
async function look(x,y,z){const a=await actor();await turn(Math.atan2(a.p[0]-x,a.p[2]-z),Math.atan2(y-a.p[1]-1.62,Math.hypot(x-a.p[0],z-a.p[2])));}
async function check(name,fn){try{await fn();report.checks.push({name,ok:true});console.log('PASS',name);}catch(e){report.checks.push({name,ok:false,error:e.message});throw e;}}
const count=async()=> (await diag()).currentState.objects.length;
async function drag(kind,x,y){const card=page.locator(`.placement-card[data-kind="${kind}"]`);await card.scrollIntoViewIfNeeded();const r=await card.boundingBox();await page.mouse.move(r.x+r.width/2,r.y+r.height/2);await page.mouse.down();await page.mouse.move(x,y,{steps:16});await page.waitForTimeout(400);}
try{
 await page.goto(base);await page.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:120000});report.buildId=(await diag()).buildId;report.url=base;if(process.env.V5_EXPECTED_BUILD)assert.equal(report.buildId,process.env.V5_EXPECTED_BUILD);
 await check('Exact entry notice is display-only',async()=>{assert.equal(await page.locator('#entryNotice').innerText(),'교육용으로 활용할 수 있는 메타버스입니다.');const before=await diag();await page.evaluate(async()=>{const m=await import('./presentation-copy.mjs');m.renderEntryNotice(document.querySelector('#entryNotice'),{text:'표시 문자열 교체 시험',visible:false});});const after=await diag();assert.deepEqual(after.roomAdmin,before.roomAdmin);assert.equal(after.loaded,before.loaded);await page.evaluate(async()=>{const m=await import('./presentation-copy.mjs');m.renderEntryNotice(document.querySelector('#entryNotice'));});});
 await page.locator('#displayName').fill('V5 설치 검수');await page.locator(process.env.V5_SOLO==='yes'?'#solo':'#host').click();await page.waitForFunction(()=>Homeoffice.diagnostics().playing&&Homeoffice.diagnostics().currentState?.players.length===1,null,{timeout:60000});
 await key('KeyC',50);await move(-.4,10.95);await move(-6,10.95);await move(-8.8,10.95);await move(-8.8,7.8);await look(-7.5,.02,8);
 await page.keyboard.press('Tab');await page.locator('#installObjects').click();
 await check('Button opens side panel with real model thumbnails',async()=>{assert.ok(await page.locator('#placementPanel').isVisible());assert.equal(await page.locator('.placement-card img').evaluateAll(es=>es.filter(e=>e.complete&&e.naturalWidth>0).length),12);assert.equal((await diag()).playing,false);});
 const before=await count(),pose=await actor();
 await drag('chair',720,450);await page.screenshot({path:dir+'/01-ray-preview.png'});
 await check('Actual pointer ray produces a valid world preview',async()=>{assert.equal((await diag()).placement.lastResult.valid,true);});
 await page.keyboard.press('KeyR');await page.waitForTimeout(180);
 await check('R rotates preview without camera or actor movement',async()=>{const d=await diag(),p=await actor();assert.ok(d.placement.lastResult.yaw>.7);assert.ok(Math.abs(p.lookYaw-pose.lookYaw)<.01);assert.ok(Math.hypot(...p.p.map((v,i)=>v-pose.p[i]))<.03);});
 await page.mouse.up();await page.waitForFunction(n=>Homeoffice.diagnostics().currentState.objects.length===n+1,before,{timeout:10000});
 await check('Drop creates exactly one authoritative object',async()=>{assert.equal(await count(),before+1);assert.ok((await diag()).lastCommandResult.accepted);});
 await page.mouse.up();await page.mouse.click(720,450);await page.waitForTimeout(300);assert.equal(await count(),before+1);
 await page.screenshot({path:dir+'/02-placed-chair.png'});
 await check('Panel drop cancels without object creation',async()=>{await drag('book',1200,250);await page.mouse.up();await page.waitForTimeout(250);assert.equal(await count(),before+1);assert.equal((await diag()).placement.dragging,false);});
 await check('Escape cancels drag and keeps the panel usable',async()=>{await drag('book',680,520);await page.keyboard.press('Escape');await page.mouse.up();await page.waitForTimeout(250);assert.equal(await count(),before+1);assert.equal((await diag()).placement.dragging,false);assert.ok(await page.locator('#placementPanel').isVisible());});
 await check('Real browser tab focus loss cancels drag',async()=>{await drag('book',680,520);const other=await context.newPage();await other.goto('about:blank');await other.bringToFront();await page.waitForTimeout(200);await page.bringToFront();await page.mouse.up();await page.waitForTimeout(300);assert.equal((await diag()).placement.dragging,false);assert.equal(await count(),before+1);await other.close();});
 await page.setViewportSize({width:1152,height:760});await drag('book',576,480);await page.waitForTimeout(300);report.resized=await diag();await page.keyboard.press('Escape');await page.mouse.up();
 await page.getByRole('button',{name:'설치함 닫기'}).click();await look(-8.9,.02,9.5);await page.keyboard.press('Tab');await page.locator('#installObjects').click();await drag('gun',576,380);await page.waitForTimeout(300);assert.equal((await diag()).placement.lastResult.valid,true);const preGun=await count();await page.mouse.up();await page.waitForFunction(n=>Homeoffice.diagnostics().currentState.objects.length===n+1,preGun);await page.getByRole('button',{name:'설치함 닫기'}).click();
 const d=await diag(),gun=d.currentState.objects.filter(o=>o.kind==='gun').at(-1);await look(...gun.p);await key('KeyE',50);await page.waitForFunction(()=>Homeoffice.diagnostics().currentState.players.find(p=>p.id===Homeoffice.diagnostics().id)?.hold?.startsWith('placed-'),null,{timeout:8000});
 const firstShots=(await diag()).currentState.shots;assert.ok(Number.isFinite(firstShots));await page.mouse.click(576,380);await page.waitForFunction(n=>Homeoffice.diagnostics().currentState.shots>n,firstShots,{timeout:5000});
 report.checks.push({name:'Held global gun still fires in HOME before UI isolation test',ok:true});
 const shots=(await diag()).currentState.shots;
 await page.keyboard.press('Tab');await page.locator('#installObjects').click();await drag('book',560,480);await page.keyboard.press('Escape');await page.mouse.up();await page.waitForTimeout(600);
 await check('Dragging while holding a gun emits no shot',async()=>{assert.equal((await diag()).currentState.shots,shots);assert.equal((await actor()).hold,gun.id);});
 await page.screenshot({path:dir+'/03-panel-gun-no-shot.png'});report.final=await diag();report.completed=true;
}catch(e){report.failure=e.stack;await page.screenshot({path:dir+'/failure.png'}).catch(()=>{});report.final=await diag().catch(()=>null);}
finally{report.video=await page.video()?.path();await context.close();await browser.close();await fs.writeFile(dir+'/report.json',JSON.stringify(report,null,2));console.log(JSON.stringify({buildId:report.buildId,completed:report.completed,failure:report.failure,checks:report.checks.map(x=>[x.name,x.ok]),errors:report.errors}));}
