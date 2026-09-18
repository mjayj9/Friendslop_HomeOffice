import { chromium } from 'playwright';import fs from 'node:fs/promises';
const [id,url,startText='0',secondsText='16',rateText='1']=process.argv.slice(2),start=+startText,seconds=+secondsText,rate=+rateText;
const dir=`homeoffice/evidence/v5/references/${id}-${start}-${rate}`;await fs.mkdir(dir,{recursive:true});
const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1280,height:850}});
page.setDefaultTimeout(15000);const watchdog=setTimeout(()=>browser.close(),70000);
const report={url,start,requestedSeconds:seconds,rate,frames:[],environment:'Actual muted browser playback; screenshots, no transcript substitution. No audio observation.'};
try{await page.goto(url,{waitUntil:'domcontentloaded'});await page.waitForFunction(()=>document.querySelector('video')?.readyState>=2,null,{timeout:30000});report.title=await page.title();report.publisher=await page.locator('#owner').innerText().catch(()=>null);const v=page.locator('video').first();await v.scrollIntoViewIfNeeded();let started=false;for(let attempt=0;attempt<5&&!started;attempt++){await v.evaluate(e=>{e.muted=true;e.play().catch(()=>{});});await page.waitForTimeout(2000);await v.evaluate((e,p)=>{e.currentTime=p.start;e.playbackRate=p.rate;},{start,rate});await page.waitForTimeout(1500);await v.evaluate(e=>{e.play().catch(()=>{});});started=await v.evaluate((e,t)=>!e.paused&&e.readyState>=2&&Math.abs(e.currentTime-t)<5,start);}if(!started)throw Error('Requested playback interval did not stabilize');
 for(let i=0;i<seconds*2;i++){await page.waitForTimeout(500/rate);const info=await v.evaluate(e=>({time:e.currentTime,rate:e.playbackRate,paused:e.paused,readyState:e.readyState}));const file=`${String(i).padStart(3,'0')}.jpg`;await v.screenshot({path:dir+'/'+file,type:'jpeg',quality:76});report.frames.push({...info,file});}
 await v.evaluate(e=>e.pause());
}catch(e){report.failure=e.message;}
finally{clearTimeout(watchdog);await browser.close();await fs.writeFile(dir+'/observation.json',JSON.stringify(report,null,2));console.log(JSON.stringify({dir,title:report.title,frames:report.frames.length,first:report.frames[0],last:report.frames.at(-1),failure:report.failure}));}
