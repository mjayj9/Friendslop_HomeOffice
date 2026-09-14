import {chromium} from 'playwright';
const browsers=[],pages=[];const diag=p=>p.evaluate(()=>Homeoffice.diagnostics());const wait=(p,f)=>p.waitForFunction(f,null,{polling:100,timeout:45000});
try{for(let i=0;i<2;i++){const b=await chromium.launch({headless:true,args:['--use-angle=d3d11']});browsers.push(b);const p=await b.newPage({viewport:{width:960,height:540}});pages.push(p);await p.goto('http://127.0.0.1:8060/homeoffice/?signal=local');await wait(p,()=>Homeoffice?.readyState());if(i===0){await p.locator('#host').click({force:true});await wait(p,()=>Homeoffice.diagnostics().currentState?.players.length===1)}}
const [a,b]=pages;await b.locator('#room').fill((await diag(a)).room);await b.locator('#join').click({force:true});await wait(b,()=>Homeoffice.diagnostics().currentState?.players.length===2);await b.waitForTimeout(1000);const bid=(await diag(b)).id;
async function log(label){for(const[i,p]of pages.entries()){const d=await diag(p);console.log(label,i,JSON.stringify({playing:d.playing,epoch:d.epoch,player:d.currentState.players.find(a=>a.id===bid),text:await p.locator('#interaction').textContent()}))}}
await log('initial');for(const k of ['ArrowLeft','KeyW','ArrowRight','KeyW']){await b.keyboard.down(k);await b.waitForTimeout(500);await b.keyboard.up(k);await b.waitForTimeout(500);await log(k)}
}finally{for(const b of browsers)await b.close()}
