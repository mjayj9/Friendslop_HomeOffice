import {chromium} from 'playwright';
import {fileURLToPath} from 'node:url';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {decodeWorld} from '../web/save.mjs';
process.chdir(fileURLToPath(new URL('../../',import.meta.url)));
const expected=await decodeWorld(new Uint8Array(await fs.readFile('homeoffice/evidence/lived-in.homeworld')));
const b=await chromium.launch({headless:true,args:['--use-angle=d3d11']});
const results=[];
try{
 const p=await b.newPage({viewport:{width:1280,height:720}});
 await p.goto('http://127.0.0.1:8060/homeoffice/');await p.waitForFunction(()=>Homeoffice.readyState(),null,{polling:100});await p.locator('#solo').click({force:true});await p.waitForFunction(()=>Homeoffice.diagnostics().currentState?.players.length===1,null,{polling:100});
 await p.evaluate(()=>Homeoffice.menu());await p.locator('#import').setInputFiles('homeoffice/evidence/lived-in.homeworld');await p.waitForFunction(()=>!document.getElementById('importPreview').hidden,null,{polling:100});
 await p.locator('#restore').click({force:true});await p.waitForFunction(n=>Homeoffice.diagnostics().boardStrokes.length===n,expected.board.length,{polling:100});
 const restored=await p.evaluate(()=>Homeoffice.diagnostics());assert.deepEqual(restored.boardStrokes,expected.board);for(const object of expected.objects.filter(o=>['chair','table','sofa'].includes(o.kind))){const actual=restored.currentState.objects.find(o=>o.id===object.id);assert.ok(actual);assert.ok(actual.p.every((n,i)=>Math.abs(n-object.p[i])<.001));assert.equal(actual.occupant,'');assert.equal(actual.owner,'')}
 results.push({test:'T42 T43 fresh actual browser file input restores board and static furniture, occupancy reset',passed:true});
 await p.evaluate(()=>Homeoffice.menu());await p.locator('#import').setInputFiles({name:'broken.homeworld',mimeType:'application/zip',buffer:Buffer.from([1,2,3])});await p.waitForTimeout(300);assert.ok(await p.locator('#importPreview').isHidden());assert.deepEqual((await p.evaluate(()=>Homeoffice.diagnostics())).boardStrokes,expected.board);results.push({test:'T45 actual browser rejects damaged file while keeping current world',passed:true});
 await p.screenshot({path:'homeoffice/evidence/game-restored.png'});
 console.log('IMPORT_PASSED',results);
}catch(e){results.push({passed:false,error:e.message});console.log(e.stack);process.exitCode=1}finally{await fs.writeFile('homeoffice/evidence/browser-import.json',JSON.stringify({browser:b.version(),results},null,2));await b.close()}
