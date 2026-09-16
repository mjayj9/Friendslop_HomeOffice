export const diagnostics=p=>p.evaluate(()=>Homeoffice.diagnostics());
export const wait=(p,f,timeout=50000)=>p.waitForFunction(f,null,{polling:100,timeout});
export function walker(p){
 const actor=async()=>{const s=await diagnostics(p);return s.currentState.players.find(a=>a.id===s.id)};
 async function key(k,ms){await p.keyboard.down(k);await p.waitForTimeout(Math.max(30,ms));await p.keyboard.up(k);await p.waitForTimeout(90)}
 async function turn(yaw,pitch=0){for(let i=0;i<6;i++){const a=await actor(),dy=Math.atan2(Math.sin(yaw-a.yaw),Math.cos(yaw-a.yaw));if(Math.abs(dy)<.03)break;await key(dy>0?'ArrowLeft':'ArrowRight',Math.abs(dy)/1.5*1000)}for(let i=0;i<4;i++){const a=await actor(),dy=pitch-a.pitch;if(Math.abs(dy)<.03)break;await key(dy>0?'ArrowUp':'ArrowDown',Math.abs(dy)/1.2*1000)}}
 async function move(x,z){for(let i=0;i<45;i++){const a=await actor(),dx=x-a.p[0],dz=z-a.p[2],n=Math.hypot(dx,dz);if(n<.26)return;await turn(Math.atan2(-dx,-dz));await key('KeyW',Math.min(1800,Math.max(45,(n-.1)/3.1*1000)))}throw Error('Walk blocked '+x+','+z+' actual '+(await actor()).p)}
 async function aim(x,y,z){const a=await actor();await turn(Math.atan2(a.p[0]-x,a.p[2]-z),Math.atan2(y-a.p[1]-1.62,Math.hypot(x-a.p[0],z-a.p[2])))}
 return {actor,key,turn,move,aim};
}
