// Display-only strings. Gameplay, roles, world layout and save schemas never import this module.
export const ENTRY_NOTICE_KO='교육용으로 활용할 수 있는 메타버스입니다.';
export function renderEntryNotice(element,{text=ENTRY_NOTICE_KO,visible=true}={}){
 if(!element)return;
 element.textContent=text;element.hidden=!visible;
}
