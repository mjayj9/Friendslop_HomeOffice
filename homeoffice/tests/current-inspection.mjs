import {chromium} from 'playwright';
import fs from 'node:fs/promises';
const b=await chromium.launch({headless:true,args:['--use-angle=d3d11']});
const p=await b.newPage({viewport:{width:1280,height:720}});const logs=[];
p.on('console',m=>logs.push(m.text()));
try{await p.goto('http://127.0.0.1:8060/homeoffice/');await p.waitForFunction(()=>window.Homeoffice?.readyState(),null,{polling:100,timeout:40000});await p.locator('#solo').click({force:true});await p.waitForTimeout(1200);await p.screenshot({path:'homeoffice/evidence/v2-before-current.png'});await fs.writeFile('homeoffice/evidence/v2-before-current.json',JSON.stringify({url:p.url(),title:await p.title(),browser:b.version(),diagnostics:await p.evaluate(()=>Homeoffice.diagnostics()),logs},null,2));console.log('Inspected local Godot page; screenshot and state saved.')}finally{await b.close()}
