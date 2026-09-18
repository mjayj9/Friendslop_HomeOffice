import {chromium} from 'playwright';import fs from 'node:fs/promises';import {pathToFileURL} from 'node:url';import path from 'node:path';
const dir='homeoffice/evidence/v5/architecture';await fs.mkdir(dir,{recursive:true});
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1500,height:1050}}),errors=[];p.on('pageerror',e=>errors.push(e.message));
await p.goto(pathToFileURL(path.resolve('homeoffice/docs/v5/architecture-plan.html')).href);
await p.screenshot({path:dir+'/ground-plan.png'});await p.locator('#u').click();await p.screenshot({path:dir+'/upper-plan.png'});
const plan=JSON.parse(await fs.readFile('homeoffice/docs/v5/architecture-plan.json','utf8')),overlaps=[];
for(let i=0;i<plan.rooms.length;i++)for(const b of plan.rooms.slice(i+1)){const a=plan.rooms[i];if(a.y!==b.y)continue;const dx=Math.min(a.rect[2],b.rect[2])-Math.max(a.rect[0],b.rect[0]),dz=Math.min(a.rect[3],b.rect[3])-Math.max(a.rect[1],b.rect[1]);if(dx>1e-6&&dz>1e-6)overlaps.push([a.id,b.id,dx*dz]);}
await fs.writeFile(dir+'/design-review.json',JSON.stringify({status:'DESIGN ONLY; not proof of runtime walking or finished building',overlaps,errors,programAreas:plan.rooms.length,reservedAreas:plan.rooms.filter(x=>x.wing==='RESERVE').length},null,2));await b.close();if(errors.length||overlaps.length)process.exitCode=1;
