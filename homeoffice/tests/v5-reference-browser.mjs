import { chromium } from 'playwright';
import fs from 'node:fs/promises';
const dir = 'homeoffice/evidence/v5/references'; await fs.mkdir(dir, {recursive:true});
const browser = await chromium.launch({headless:true});
const sources = [
 ['nba-official','https://www.youtube.com/watch?v=J2tMMb4rh1c'],
 ['nba-play','https://www.youtube.com/watch?v=uNhzALVGrB4'],
 ['fc-official','https://fconline.nexon.com/news/guide'],
 ['valorant-official','https://playvalorant.com/en-us/news/dev/how-the-valorant-arsenal-was-built/']
];
const results=[];
for (const [id,url] of sources) {
 const page=await browser.newPage({viewport:{width:1280,height:800}}), result={id,url,checkedAt:new Date().toISOString()};
 try {
  await page.goto(url,{waitUntil:'domcontentloaded',timeout:30000}); await page.waitForTimeout(4000);
  result.title=await page.title(); result.body=(await page.locator('body').innerText()).slice(0,8000);
  result.embeds=await page.locator('iframe').evaluateAll(es=>es.map(e=>e.src));
  result.videos=await page.locator('video').evaluateAll(es=>es.map(e=>({src:e.currentSrc,time:e.currentTime,duration:e.duration,readyState:e.readyState,paused:e.paused,error:e.error?.message})));
  if (result.videos.length && result.videos[0].readyState>=2) {
   const v=page.locator('video').first(); await v.evaluate(e=>{e.muted=true;return e.play();});
   result.frames=[];
   for(let n=0;n<6;n++){await page.waitForTimeout(2000);const at=await v.evaluate(e=>({time:e.currentTime,rate:e.playbackRate,paused:e.paused}));await page.screenshot({path:`${dir}/${id}-${n}.jpg`,type:'jpeg',quality:70});result.frames.push({...at,file:`${id}-${n}.jpg`});}
  }
  await page.screenshot({path:`${dir}/${id}.jpg`,type:'jpeg',quality:70});
 }catch(e){result.failure=e.message;}
 results.push(result); await page.close();
}
await browser.close();await fs.writeFile(dir+'/playback-attempts.json',JSON.stringify(results,null,2));
console.log(JSON.stringify(results.map(({id,title,videos,frames,failure})=>({id,title,videos,frames,failure}))));
