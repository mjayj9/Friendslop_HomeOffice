import {chromium} from 'playwright';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
const base=process.env.COMMONS_PUBLIC_URL||'https://mjayj9.github.io/Friendslop_HomeOffice/';
const expected=JSON.parse(await fs.readFile('docs/build-info.json','utf8')).buildId;
const dir='homeoffice/.runtime/public-review-smoke';await fs.mkdir(dir,{recursive:true});
const browsers=[],pages=[],results=[],errors=[];
const report={environment:'Two isolated Chromium processes on one PC, real public GitHub Pages bytes, Clerk development SDK and default remote PeerJS signaling. No real user account or microphone. Not a two-person WAN acceptance test.',expectedBuildId:expected,url:base};
const diag=p=>p.evaluate(()=>Homeoffice.diagnostics());
async function check(name,fn){await fn();results.push({name,passed:true});console.log('PASS',name);}
try{
 for(let i=0;i<2;i++){
  const b=await chromium.launch({headless:true,args:['--use-angle=d3d11']});browsers.push(b);
  const p=await b.newPage({viewport:{width:1440,height:1000}});pages.push(p);p.on('pageerror',e=>errors.push(e.message));
  const url=new URL(base);url.searchParams.set('review',expected);await p.goto(url.href,{waitUntil:'domcontentloaded'});
  await p.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:120000});assert.equal((await diag(p)).buildId,expected);
 }
 const[a,b]=pages;
 await check('Published game and actual Clerk sign-in load on the unchanged Pages URL',async()=>{
  await a.waitForFunction(()=>window.Clerk?.loaded,null,{timeout:45000});await a.getByRole('button',{name:'로그인',exact:true}).click();await a.locator('.cl-signIn-root').waitFor();await a.screenshot({path:dir+'/01-public-sign-in.png'});await a.locator('.cl-modalCloseButton').click();await a.locator('.cl-modalBackdrop').waitFor({state:'hidden'});
 });
 await check('Public host and invite join establish two visible participants through remote signaling',async()=>{
  await a.locator('#displayName').fill('배포 확인 A');await a.locator('#host').click();await a.waitForFunction(()=>Homeoffice.diagnostics().playing&&Homeoffice.diagnostics().currentState?.players.length===1,null,{timeout:60000});
  await b.locator('#displayName').fill('배포 확인 B');await b.locator('#room').fill((await diag(a)).roomCode);await b.locator('#join').click();
  for(const p of pages){await p.waitForFunction(()=>Homeoffice.diagnostics().currentState?.players.length===2&&Homeoffice.diagnostics().avatarDiagnostics.instances.length===2,null,{timeout:60000});assert.equal((await diag(p)).avatarDiagnostics.instances.filter(x=>!x.local&&x.standingVisible).length,1);}
  await a.screenshot({path:dir+'/02-public-two-players.png'});
 });
 await check('Public build changes normal camera with actual C input and delivers Korean session chat',async()=>{
  await a.keyboard.press('KeyC');await a.waitForFunction(()=>Homeoffice.diagnostics().avatarDiagnostics.instances.find(x=>x.local).cameraRig.mode==='first');await a.keyboard.press('KeyC');
  await a.keyboard.press('Enter');await b.keyboard.press('Enter');await a.locator('#chatText').fill('공개 검토 빌드 연결 확인');await a.locator('#chatText').press('Enter');await b.getByText('공개 검토 빌드 연결 확인',{exact:true}).waitFor({timeout:20000});await b.screenshot({path:dir+'/03-public-chat.png'});
 });
 assert.equal(errors.length,0,errors.join('\n'));report.completed=true;
}catch(e){report.failure=e.stack;console.error(e);process.exitCode=1;await pages[0]?.screenshot({path:dir+'/failure.png'}).catch(()=>{});}
finally{report.checkedAt=new Date().toISOString();report.results=results;report.errors=errors;await fs.writeFile(dir+'/report.json',JSON.stringify(report,null,2));for(const b of browsers)await b.close();}
