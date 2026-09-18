import { chromium } from 'playwright';import fs from 'node:fs/promises';
const [id,url,secondsText='60']=process.argv.slice(2),seconds=+secondsText;
const dir=`homeoffice/evidence/v5/references/${id}-continuous`;await fs.mkdir(dir,{recursive:true});
const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1280,height:800}});
const report={url,method:'Actual continuous browser playback from beginning, muted, no seeking. Recorded frames do not imply each frame has been visually reviewed.',frames:[]};
const timer=setTimeout(()=>browser.close(),(seconds+40)*1000);page.setDefaultTimeout(12000);
try{
 await page.goto(url,{waitUntil:'domcontentloaded',timeout:30000});await page.waitForTimeout(4000);
 report.title=await page.title();report.publisher=await page.locator('#owner').innerText().catch(()=>null);
 const v=page.locator('video').first();await v.evaluate(e=>{e.muted=true;e.play().catch(()=>{});});
 for(let i=0;i<seconds/2;i++){
  await page.waitForTimeout(2000);const at=await v.evaluate(e=>({time:e.currentTime,rate:e.playbackRate,paused:e.paused,readyState:e.readyState,error:e.error?.message}));
  const file=`${String(i).padStart(3,'0')}.jpg`;await v.screenshot({path:dir+'/'+file,type:'jpeg',quality:70});report.frames.push({...at,file});
  if(at.paused||at.readyState<2){report.failure='Playback stopped or lost media data';break;}
 }
}catch(e){report.failure=e.message;}
finally{clearTimeout(timer);await browser.close();await fs.writeFile(dir+'/observation.json',JSON.stringify(report,null,2));console.log(JSON.stringify({dir,title:report.title,frames:report.frames.length,last:report.frames.at(-1),failure:report.failure}));}
