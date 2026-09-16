import {chromium} from 'playwright';import fs from 'node:fs/promises';import assert from 'node:assert/strict';
const dir='homeoffice/evidence/v3/session-flow';await fs.mkdir(dir,{recursive:true});const browsers=[],pages=[],errors=[],results=[];const report={environment:'Two independent Chromium processes on one Windows PC and local PeerJS. Actual signaling claims and WebRTC data channels; no WAN claim.'};
const diag=p=>p.evaluate(()=>Homeoffice.diagnostics());
async function create(){const b=await chromium.launch({headless:true,args:['--use-angle=d3d11']});browsers.push(b);const p=await b.newPage({viewport:{width:960,height:720}});pages.push(p);p.on('pageerror',e=>errors.push(e.message));await p.goto('http://127.0.0.1:8060/homeoffice/?signal=local&room=classroom');await p.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:70000});return p;}
try{
 const a=await create(),b=await create();report.buildId=(await diag(a)).buildId;
 await Promise.all([a.locator('#classroomJoin').click(),b.locator('#classroomJoin').click()]);
 for(const p of [a,b])await p.waitForFunction(()=>Homeoffice.diagnostics().currentState?.players.length===2,null,{timeout:45000});
 const states=await Promise.all([diag(a),diag(b)]);assert.equal(states.filter(s=>s.host).length,1);assert.equal(states[0].epoch,states[1].epoch);assert.ok(states.every(s=>s.classroomSession&&s.roomCode==='classroom'));results.push({name:'Simultaneous empty classroom claims produce one host and two real peers',passed:true});
 await a.screenshot({path:`dir-placeholder` .replace('dir-placeholder',`${dir}/classroom.png`)});
 let hostIndex=states[0].host?0:1,guestIndex=1-hostIndex;
 const oldHost=pages[hostIndex],newHost=pages[guestIndex],newId=(await diag(newHost)).id;
 await oldHost.keyboard.press('Escape');await oldHost.locator('#nextHost').selectOption(newId);await oldHost.locator('#transferHost').click();
 await newHost.waitForFunction(()=>Homeoffice.diagnostics().host&&Homeoffice.diagnostics().connections.length===1,null,{timeout:50000});
 await oldHost.waitForFunction(()=>!Homeoffice.diagnostics().host&&Homeoffice.diagnostics().currentState?.players.length===2,null,{timeout:50000});
 for(const page of [oldHost,newHost]){const d=await diag(page);assert.equal(d.roomCode,'classroom');assert.equal(d.classroomSession,true);assert.notEqual(d.epoch,states[0].epoch);}
 results.push({name:'Orderly classroom handoff preserves fixed address and transfers authority',passed:true});
 [hostIndex,guestIndex]=[guestIndex,hostIndex];await browsers[hostIndex].close();browsers[hostIndex]=null;
 await pages[guestIndex].waitForFunction(()=>!Homeoffice.diagnostics().playing,null,{timeout:25000});results.push({name:'Host departure stops stale session rather than claiming persistent state',passed:true});
 await browsers[guestIndex].close();browsers[guestIndex]=null;
 const c=await create();await c.locator('#classroomJoin').click();await c.waitForFunction(()=>Homeoffice.diagnostics().playing,null,{timeout:25000});const reopened=await diag(c);assert.equal(reopened.host,true);assert.notEqual(reopened.epoch,states[0].epoch);results.push({name:'Same fixed classroom address reopens a fresh empty session',passed:true});
 const mix=await browsers.at(-1).newPage();await mix.route('**/build-info.json',async route=>{const r=await route.fetch();const v=await r.json();v.files['index.pck'].sha256='0'.repeat(64);await route.fulfill({response:r,json:v});});await mix.goto('http://127.0.0.1:8060/homeoffice/?signal=local');await mix.waitForFunction(()=>document.querySelector('#loading').textContent.includes('서로 다른 빌드'),null,{timeout:40000});assert.equal(await mix.locator('#host').isDisabled(),true);results.push({name:'Mismatched PCK hash is rejected before joining',passed:true});await mix.screenshot({path:`${dir}/mixed-build-rejected.png`});report.completed=true;
}catch(e){report.failure=e.stack;process.exitCode=1;console.error(e);}
finally{report.results=results;report.errors=errors;await fs.writeFile(`${dir}/report.json`,JSON.stringify(report,null,2));for(const b of browsers)await b?.close();console.log(JSON.stringify({completed:report.completed,results,errors,failure:report.failure},null,2));}
