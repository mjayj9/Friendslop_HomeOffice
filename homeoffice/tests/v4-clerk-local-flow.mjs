import {chromium} from 'playwright';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
const dir='homeoffice/evidence/v4/clerk-local';await fs.mkdir(dir,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--use-angle=d3d11']});
const context=await browser.newContext({viewport:{width:1440,height:1000},recordVideo:{dir,size:{width:960,height:667}}});
const page=await context.newPage(),errors=[],results=[];
const report={environment:'Actual Godot WebGL and actual user-selected Clerk development SDK at http://localhost:5173. Fresh unauthenticated Chromium profile. No mocked Clerk API, account creation, credentials or session tokens recorded.'};
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error'&&!m.text().includes('favicon'))errors.push(m.text());});
const diag=()=>page.evaluate(()=>Homeoffice.diagnostics());
const actor=async()=>{const d=await diag();return d.currentState.players.find(a=>a.id===d.id);};
async function check(name,fn){await fn();results.push({name,passed:true});console.log('PASS',name);}
async function closeAuth(){await page.locator('.cl-modalCloseButton').click();await page.locator('.cl-modalBackdrop').waitFor({state:'hidden'});}
try {
 await page.goto('http://localhost:5173/');await page.waitForFunction(()=>window.Homeoffice?.readyState(),null,{timeout:90000});
 report.buildId=(await diag()).buildId;
 await check('Exact localhost:5173 origin serves the game and real Clerk SDK with visible account controls',async()=>{
  assert.equal(new URL(page.url()).origin,'http://localhost:5173');await page.getByText('로그인하거나 첫 계정을 만들어 보세요.',{exact:true}).waitFor({timeout:30000});
  const signIn=page.getByRole('button',{name:'로그인',exact:true});assert.equal(await signIn.isEnabled(),true);const box=await signIn.boundingBox();assert.ok(box.y>=0&&box.y+box.height<1000);
  assert.equal(await page.evaluate(()=>!!window.Clerk.loaded),true);await page.screenshot({path:dir+'/01-account-entry.png'});
 });
 await check('Real Clerk sign-in component opens from the existing welcome screen',async()=>{await page.getByRole('button',{name:'로그인',exact:true}).click();await page.locator('.cl-signIn-root').waitFor();await page.screenshot({path:dir+'/02-sign-in.png'});await closeAuth();});
 await check('Real Clerk sign-up component opens without replacing the game project',async()=>{await page.getByRole('button',{name:'회원가입',exact:true}).click();await page.locator('.cl-signUp-root').waitFor();await page.screenshot({path:dir+'/03-sign-up.png'});await closeAuth();});
 await page.locator('#solo').click();await page.waitForFunction(()=>Homeoffice.diagnostics().playing&&Homeoffice.diagnostics().currentState?.players.length===1);
 await check('Clerk modal cancels gameplay input; closing and resuming restores movement',async()=>{
  await page.keyboard.press('Escape');await page.locator('#roomAdmin summary').click();await page.locator('#adminLogin').click();await page.locator('.cl-signIn-root').waitFor();const before=await actor(),mode=(await diag()).avatarDiagnostics.instances.find(x=>x.local).cameraRig.mode;
  await page.keyboard.down('KeyW');await page.waitForTimeout(350);await page.keyboard.up('KeyW');await page.keyboard.press('KeyC');assert.ok(Math.hypot(...(await actor()).p.map((v,i)=>v-before.p[i]))<.05);assert.equal((await diag()).avatarDiagnostics.instances.find(x=>x.local).cameraRig.mode,mode);
  await closeAuth();await page.locator('#resume').click();await page.keyboard.down('KeyW');await page.waitForTimeout(700);await page.keyboard.up('KeyW');assert.ok(Math.hypot(...(await actor()).p.map((v,i)=>v-before.p[i]))>.5);
 });
 assert.equal((await diag()).roomAdmin.configured,false,'Clerk login alone never enables PIN or broadcast authority');
 assert.equal(errors.length,0,errors.join('\n'));report.completed=true;
} catch(error){report.failure=error.stack;console.error(error);await page.screenshot({path:dir+'/failure.png'}).catch(()=>{});report.visibleText=(await page.locator('body').innerText()).slice(-5000);process.exitCode=1;}
finally {report.results=results;report.errors=errors;report.video=await page.video().path();await browser.close();await fs.writeFile(dir+'/report.json',JSON.stringify(report,null,2));}
