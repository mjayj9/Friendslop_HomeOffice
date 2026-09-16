import {chromium} from 'playwright';
import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {aim} from './v3-browser-helpers.mjs';

const project=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const url=process.env.V3_URL||'http://127.0.0.1:8062/Friendslop_HomeOffice/?signal=local';
const output=path.resolve(project,process.env.V3_EVIDENCE||'evidence/v3/deployment-repair/local');
await fs.mkdir(output,{recursive:true});
const browsers=[],pages=[],results=[],errors=[],failedRequests=[];
const report={url,startedAt:new Date().toISOString(),environment:'Actual Chromium WebGL/WASM and WebRTC; keyboard and HTML controls; two independent browser processes on one PC. No injected world state.'};
const diagnostics=p=>p.evaluate(()=>Homeoffice.diagnostics());
const actor=d=>d.currentState.players.find(p=>p.id===d.id);
const pass=name=>{results.push({name,passed:true});console.log('PASS',name)};
try{
 for(let i=0;i<2;i++){
  const browser=await chromium.launch({headless:true,args:['--use-angle=d3d11']});browsers.push(browser);
  const p=await browser.newPage({viewport:{width:1280,height:720},acceptDownloads:true});pages.push(p);
  p.on('pageerror',e=>errors.push({client:i,message:e.message}));
  p.on('requestfailed',r=>failedRequests.push({client:i,url:r.url(),failure:r.failure()?.errorText}));
  p.on('response',r=>{if(r.status()>=400&&r.url().startsWith(new URL('.',url).href))errors.push({client:i,status:r.status(),url:r.url()})});
  await p.goto(url,{waitUntil:'domcontentloaded'});
  await p.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:120000});
  const d=await diagnostics(p);
  const manifest=await p.evaluate(()=>({buildId:HomeofficeBuild.buildId,protocol:HomeofficeBuild.protocolVersion,files:Object.keys(HomeofficeBuild.files).length}));
  assert.equal(manifest.protocol,3);assert.equal(d.buildId,manifest.buildId);
  if(process.env.V3_EXPECTED_BUILD)assert.equal(d.buildId,process.env.V3_EXPECTED_BUILD);
  if(!i){report.buildId=d.buildId;report.manifest=manifest;await p.screenshot({path:path.join(output,'v3-entry.png')});await p.locator('#solo').click();await p.waitForFunction(()=>Homeoffice.diagnostics().playing&&Homeoffice.diagnostics().currentState?.players.length===1);await p.screenshot({path:path.join(output,'solo.png')});pass('Published V3 shell, verified PCK and solo world start');await p.reload({waitUntil:'domcontentloaded'});await p.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:120000});await p.locator('#host').click()}
  else{await p.locator('#room').fill((await diagnostics(pages[0])).roomCode);await p.locator('#join').click()}
  await p.waitForFunction(()=>Homeoffice.diagnostics().playing&&Homeoffice.diagnostics().currentState?.players.length>0,null,{timeout:65000});
 }
 const [host,guest]=pages;
 for(const p of pages)await p.waitForFunction(()=>Homeoffice.diagnostics().currentState.players.length===2&&Homeoffice.diagnostics().avatarDiagnostics.instances?.length===2,null,{timeout:45000});
 pass('Two published clients join the same invite and instantiate both avatars');
 const before=actor(await diagnostics(host)).p;
 await host.keyboard.down('KeyA');await host.waitForTimeout(700);await host.keyboard.up('KeyA');await host.waitForTimeout(700);
 const h=await diagnostics(host),g=await diagnostics(guest),local=actor(h),remote=g.currentState.players.find(p=>p.id===h.id);
 assert.ok(Math.hypot(...local.p.map((x,i)=>x-before[i]))>.25,'Keyboard moves the host');
 assert.ok(Math.hypot(...remote.p.map((x,i)=>x-local.p[i]))<.2,'Peer sees the same movement');
 assert.equal(g.avatarDiagnostics.instances.filter(a=>!a.local&&a.standingVisible).length,1);
 pass('Real keyboard movement and a visible remote body synchronize');
 await aim(guest,local.p[0],local.p[1]+1.05,local.p[2]);await guest.waitForTimeout(350);
await host.screenshot({path:path.join(output,'host.png')});await guest.screenshot({path:path.join(output,'guest.png')});
 await host.keyboard.press('Escape');const download=host.waitForEvent('download');await host.locator('#export').click();const file=await download;await file.saveAs(path.join(output,'published-session.homeworld'));assert.ok((await fs.stat(path.join(output,'published-session.homeworld'))).size>1000);
 pass('Published game exports a real world file');
 assert.equal(errors.length,0,JSON.stringify(errors));
 report.completed=true;
}catch(e){report.failure=e.stack;process.exitCode=1;console.error(e);for(let i=0;i<pages.length;i++)await pages[i].screenshot({path:path.join(output,`failure-${i}.png`)}).catch(()=>{})}
finally{report.finishedAt=new Date().toISOString();report.results=results;report.errors=errors;report.failedRequests=failedRequests;await fs.writeFile(path.join(output,'report.json'),JSON.stringify(report,null,2));for(const b of browsers)await b.close()}
