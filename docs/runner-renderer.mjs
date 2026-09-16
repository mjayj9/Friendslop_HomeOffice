// Original vector artwork, bundled locally. No Chromium sprites or trademarks.
export function drawRunner(c,s){
 const night=Math.floor(s.time/35)%2===1;const ink=night?'#d8d9d5':'#4f5350';
 c.fillStyle=night?'#252a2b':'#f6f5ee';c.fillRect(0,0,840,520);c.fillStyle=ink;
 c.fillRect(0,435,840,2);for(let i=0;i<20;i++)c.fillRect((i*73-s.time*130)%900,450+(i%3)*9,12,2);
 c.font='18px monospace';c.fillText(String(s.score).padStart(5,'0'),700,50);
 const y=435-s.height,duck=s.duck&&s.height===0;
 if(duck){c.fillRect(108,y-28,48,19);c.fillRect(146,y-31,25,15);c.fillRect(100,y-26,15,8)}
 else{c.fillRect(112,y-43,27,31);c.fillRect(132,y-65,31,26);c.fillRect(132,y-40,12,13);c.fillRect(98,y-31,18,11);c.fillRect(143,y-26,10,5)}
 const stride=s.phase==='play'?Math.floor(s.time*12)%2:0;
 c.fillRect(114,y-13,7,stride?8:13);c.fillRect(131,y-13,7,stride?13:8);
 c.fillStyle=night?'#252a2b':'#f6f5ee';c.fillRect(153,duck?y-27:y-60,4,4);
 c.fillStyle=ink;
 for(const o of s.obstacles){
  const top=435-o.y-o.h;
  if(o.kind==='bird'){c.fillRect(o.x,top+8,o.w,10);c.fillRect(o.x+7,top+(Math.floor(s.time*9)%2?0:13),22,8);c.fillRect(o.x-7,top+10,9,4)}
  else{c.fillRect(o.x+o.w*.4,top,o.w*.24,o.h);c.fillRect(o.x,top+8,o.w*.2,o.h*.45);c.fillRect(o.x+o.w*.15,top+o.h*.48,o.w*.35,7);c.fillRect(o.x+o.w*.8,top+15,o.w*.2,o.h*.45);c.fillRect(o.x+o.w*.57,top+o.h*.58,o.w*.3,7)}
 }
 if(s.phase==='result'){c.font='24px monospace';c.fillText('GAME OVER',330,230);c.font='16px sans-serif';c.fillText('Space 또는 시작 버튼으로 다시 달리기',270,265)}
}
