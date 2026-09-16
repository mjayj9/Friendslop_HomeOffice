import { chromium } from 'playwright';
import fs from 'node:fs/promises';
const dir = process.env.CAPTURE_DIR || 'homeoffice/evidence/v3/baseline';
await fs.mkdir(dir, {recursive:true});
const browsers=[], pages=[], errors=[], report={environment:'One Windows PC, three independent Chromium processes, local PeerJS signaling, actual WebGL rendering. Automated keyboard input. No human/WAN acceptance.',views:[]};
try {
 for(let i=0;i<3;i++) {
  const b=await chromium.launch({headless:true,args:['--use-angle=d3d11']}); browsers.push(b);
  const p=await b.newPage({viewport:{width:960,height:640}}); pages.push(p);
  p.on('pageerror',e=>errors.push({client:i,error:e.message}));
  p.on('console',m=>{if(m.type()==='error')errors.push({client:i,error:m.text()})});
  await p.goto('http://127.0.0.1:8060/homeoffice/?signal=local');
  await p.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:60000});
  await p.locator('#displayName').fill('같은이름');
  if(!i)await p.locator('#host').click();
  else {await p.locator('#room').fill(report.room);await p.locator('#join').click();}
  await p.waitForFunction(()=>Homeoffice.diagnostics().playing&&Homeoffice.diagnostics().currentState?.players.length>0,null,{timeout:45000});
  report.room=(await pages[0].evaluate(()=>Homeoffice.diagnostics())).roomCode;
 }
 await pages[0].waitForFunction(()=>Homeoffice.diagnostics().currentState?.players.length===3,null,{timeout:45000});
 for(let i=0;i<3;i++) {
  const p=pages[i];await p.waitForTimeout(900);
  await p.screenshot({path:`${dir}/client-${i}-forward.png`});
  await p.keyboard.down('ArrowLeft');await p.waitForTimeout(2100);await p.keyboard.up('ArrowLeft');await p.waitForTimeout(300);
  await p.screenshot({path:`${dir}/client-${i}-back.png`});
  report.views.push({client:i,...await p.evaluate(()=>Homeoffice.diagnostics())});
 }
 report.completed=true;
} catch(e){report.failure=e.stack;process.exitCode=1;} finally {
 report.errors=errors;await fs.writeFile(`${dir}/report.json`,JSON.stringify(report,null,2));
 for(const b of browsers)await b.close();
 console.log(JSON.stringify({completed:report.completed,failure:report.failure,errors,views:report.views.map(v=>({id:v.id,players:v.currentState?.players,fps:v.performance}))},null,2));
}
