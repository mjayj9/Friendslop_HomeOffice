export const diag=p=>p.evaluate(()=>Homeoffice.diagnostics());
export const actor=async p=>{const d=await diag(p);return d.currentState.players.find(a=>a.id===d.id)};
export async function key(p,k,ms=60){await p.keyboard.down(k);await p.waitForTimeout(Math.max(20,ms));await p.keyboard.up(k);await p.waitForTimeout(80)}
export async function turn(p,yaw,pitch=0){for(let i=0;i<6;i++){const a=await actor(p),d=Math.atan2(Math.sin(yaw-a.yaw),Math.cos(yaw-a.yaw));if(Math.abs(d)<.025)break;await key(p,d>0?'ArrowLeft':'ArrowRight',Math.abs(d)/1.5*1000)}for(let i=0;i<5;i++){const a=await actor(p),d=pitch-a.pitch;if(Math.abs(d)<.025)break;await key(p,d>0?'ArrowUp':'ArrowDown',Math.abs(d)/1.2*1000)}}
export async function move(p,x,z){for(let i=0;i<20;i++){const a=await actor(p),dx=x-a.p[0],dz=z-a.p[2],n=Math.hypot(dx,dz);if(n<.25)return;await turn(p,Math.atan2(-dx,-dz));await key(p,'KeyW',Math.min(1800,Math.max(30,(n-.12)/3.1*1000)))}throw Error('Walking blocked '+[x,z]+' at '+(await actor(p)).p)}
export async function aim(p,x,y,z){const a=await actor(p);await turn(p,Math.atan2(a.p[0]-x,a.p[2]-z),Math.atan2(y-a.p[1]-1.62,Math.hypot(x-a.p[0],z-a.p[2])))}
export async function route(p,points){for(const[x,z]of points)await move(p,x,z)}
