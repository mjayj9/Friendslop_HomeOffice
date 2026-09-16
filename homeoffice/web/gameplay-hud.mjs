export function createGameplayHud(){
 const box=document.createElement('section');box.id='gameplayHud';box.hidden=true;
 box.innerHTML='<div id="healthHud"><span id="healthText"></span><meter id="healthMeter" min="0" max="100" value="100"></meter><span id="comboText"></span><meter id="comboMeter" min="0" max="100" value="0"></meter></div><div id="chargeHud" hidden><strong>슛 파워</strong><meter id="shotMeter" min="0" max="1"></meter><span id="chargeText"></span></div>';
 document.body.append(box);
 const $=id=>box.querySelector('#'+id);
 return {update(s,active,zone){box.hidden=!active;const c=s.combat||{};$('healthHud').hidden=zone!=='game';$('healthMeter').value=c.hp??100;$('healthText').textContent=c.respawnMs>0?'KO · '+Math.ceil(c.respawnMs/1000)+'초 후 복귀':`HP ${c.hp??100} / 100${c.protectedMs>0?" · 복귀 보호 "+Math.ceil(c.protectedMs/1000)+"초":""}`;$('comboMeter').value=c.meter||0;$('comboText').textContent=`킬 ${c.kills||0} · 게이지 ${Math.round(c.meter||0)}% (KO +25 / 10초 무킬 후 감소)`;$('chargeHud').hidden=s.charge<0;$('shotMeter').value=Math.max(0,s.charge);$('chargeText').textContent=Math.round(s.charge*100)+'% · 클릭을 놓으면 슛';}};
}
