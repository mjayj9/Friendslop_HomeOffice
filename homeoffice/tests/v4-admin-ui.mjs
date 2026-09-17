import {chromium} from 'playwright';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';

// Configuration-state UI fixture only. It deliberately does not exercise real Clerk login.
const root='http://127.0.0.1:8065/homeoffice/';
const browser=await chromium.launch({headless:true});
const page=await browser.newPage();
const requests=[],results=[];
const report={environment:'Chromium DOM configuration fixture; synthetic Clerk SDK/session, no real account or PIN. Actual exported room-admin module.'};
try {
 await page.route('**/admin-ui-fixture.html',r=>r.fulfill({contentType:'text/html',body:'<!doctype html><div id="menu"><div class="panel"></div></div>'}));
 await page.route('https://clerk-fixture.invalid/**',r=>r.fulfill({contentType:'text/javascript',headers:{'Access-Control-Allow-Origin':'*'},body:r.request().url().includes('ui.browser')?'window.__internal_ClerkUICtor={};':'window.Clerk={load:async()=>{},user:{id:"user_fixture_only"},session:{getToken:async()=>"synthetic-ui-token"}};'}));
 page.on('request',r=>requests.push(r.url()));
 await page.goto(root+'admin-ui-fixture.html');
 report.buildId=await page.evaluate(async()=> (await fetch('./build-info.json').then(r=>r.json())).buildId);
 await page.evaluate(async()=>{const {createRoomAdmin}=await import('./room-admin.mjs');window.makeAdmin=createRoomAdmin;window.admin=makeAdmin({identity:()=> 'fixture-player',apply:()=>{},notify:()=>{},config:{}});});
 await page.locator('#roomAdmin summary').click();
 assert.equal(await page.locator('#adminLogin').isDisabled(),true);
 assert.equal(await page.locator('#roomLockForm').isHidden(),true);
 results.push({name:'No configuration exposes neither login nor PIN management',passed:true});
 await page.evaluate(()=>{admin.destroy();window.admin=makeAdmin({identity:()=> 'fixture-player',apply:()=>{},notify:()=>{},config:{clerkPublishableKey:'pk_test_fixture_only',clerkFrontendApi:'https://clerk-fixture.invalid'}});});
 await page.locator('#roomAdmin summary').click();
 assert.equal(await page.locator('#adminLogin').isEnabled(),true);
 assert.equal(await page.locator('#roomLockForm').isHidden(),true);
 await page.locator('#adminLogin').click();
 await page.getByText(/user_fixture_only.*운영 관리자 권한은 아직 검증되지 않았습니다/).waitFor();
 assert.ok(!requests.some(url=> /\/(identity|command|state)(\?|$)/.test(url)));
 assert.equal((await page.evaluate(()=>admin.diagnostics())).configured,false);
 assert.equal(await page.evaluate(()=>admin.authorized('fixture-player')),false);
 results.push({name:'Clerk-only onboarding shows UID without granting operator authority or sending token to an absent service',passed:true});
 report.completed=true;
} catch(error) {report.failure=error.stack;process.exitCode=1;}
finally {
 report.results=results;await browser.close();
 await fs.writeFile('homeoffice/evidence/v4/admin-ui.json',JSON.stringify(report,null,2));
 console.log(JSON.stringify(report,null,2));
}
