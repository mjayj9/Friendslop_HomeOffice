import test from 'node:test';
import assert from 'node:assert/strict';
import {createChatAuthority,CHAT_LIMITS} from '../web/chat-protocol.mjs';
import {inspectBytes,safeFileName} from '../web/attachment-policy.mjs';
const roster=[{id:'host',displayName:'진행',zone:'meeting'},{id:'a',displayName:'가',zone:'meeting'},{id:'b',displayName:'나',zone:'living'}];
const create=(messageId='m1',extra={})=>({type:'chat',op:'create',messageId,text:'안녕하세요',channel:'session',...extra});
test('Session, zone and DM are routed before delivery; sender identity is connection-owned',()=>{
 const chat=createChatAuthority({members:()=>roster});
 assert.deepEqual(chat.accept('a',create()).map(x=>x.to),['host','a','b']);
 assert.deepEqual(chat.accept('a',create('m2',{channel:'zone'})).map(x=>x.to),['host','a']);
 const dm=chat.accept('a',create('m3',{channel:'dm',to:'b',sender:'host'}));
 assert.deepEqual(dm.map(x=>x.to),['a','b']);assert.ok(dm.every(x=>x.packet.row.sender==='a'));
 assert.deepEqual(chat.accept('outsider',create()),[]);
});
test('Retries deduplicate; edits/deletes/replies cannot cross identities or channel boundaries',()=>{
 let now=1000;const chat=createChatAuthority({members:()=>roster,clock:()=>now});
 chat.accept('a',create());assert.equal(chat.accept('a',create())[0].packet.row.revision,1);
 assert.equal(chat.accept('b',create())[0].packet.op,'error');
 assert.equal(chat.accept('b',{type:'chat',op:'delete',messageId:'m1'})[0].packet.op,'error');
 chat.accept('a',create('private',{channel:'dm',to:'b'}));
 assert.equal(chat.accept('a',create('leak',{replyTo:'private'}))[0].packet.op,'error');
 now+=16*60*1000;assert.equal(chat.accept('a',{type:'chat',op:'edit',messageId:'m1',text:'late'})[0].packet.op,'error');
});
test('Delivery and read are distinct and reactions bind to actual participants',()=>{
 const chat=createChatAuthority({members:()=>roster});chat.accept('a',create());
 const delivered=chat.accept('b',{type:'chat',op:'delivered',messageId:'m1'})[0].packet.row;
 assert.deepEqual(delivered.delivered,['b']);assert.deepEqual(delivered.read,[]);
 const read=chat.accept('b',{type:'chat',op:'read',messageId:'m1'})[0].packet.row;assert.deepEqual(read.read,['b']);
 assert.deepEqual(chat.accept('b',{type:'chat',op:'read',messageId:'m1'}),[]);
 const reacted=chat.accept('b',{type:'chat',op:'react',messageId:'m1',emoji:'👍'})[0].packet.row;assert.deepEqual(reacted.reactions['👍'],['b']);
});
test('Attachment fragments need a participant request, exact size and original provider',()=>{
 const chat=createChatAuthority({members:()=>roster});
 const file={id:'f1',name:'회의.txt',size:3,mime:'text/plain',hash:'a'.repeat(64)};
 chat.accept('a',create('m1',{channel:'dm',to:'b',file}));
 assert.equal(chat.accept('host',{type:'chat',op:'file-request',messageId:'m1',index:0})[0].packet.op,'error');
 const request=chat.accept('b',{type:'chat',op:'file-request',messageId:'m1',index:0});assert.equal(request[0].to,'a');
 const packet={type:'chat',op:'file-chunk',messageId:'m1',receiver:'b',index:0,data:'YWJj'};
 assert.equal(chat.accept('b',packet)[0].packet.op,'error');assert.equal(chat.accept('a',packet)[0].to,'b');
 assert.equal(chat.accept('a',packet)[0].packet.op,'error');
});
test('Cancel revokes transfer; offline provider is reported without pretending server storage',()=>{
 let members=roster;const chat=createChatAuthority({members:()=>members});chat.accept('a',create('m1',{file:{id:'f1',name:'x.txt',size:3,mime:'text/plain',hash:'a'.repeat(64)}}));
 chat.accept('b',{type:'chat',op:'file-request',messageId:'m1',index:0});chat.accept('b',{type:'chat',op:'file-cancel',messageId:'m1'});
 assert.equal(chat.accept('a',{type:'chat',op:'file-chunk',messageId:'m1',receiver:'b',index:0,data:'YWJj'})[0].packet.op,'error');
 members=roster.filter(x=>x.id!=='a');assert.match(chat.accept('b',{type:'chat',op:'file-request',messageId:'m1',index:0})[0].packet.reason,/오프라인/);
});
test('Validation rejects spoofed images, scripts, oversized decoding and path-shaped names',()=>{
 const text=new TextEncoder();assert.equal(inspectBytes(text.encode('한글 회의 기록'),'회의.txt').mime,'text/plain');
 assert.throws(()=>inspectBytes(text.encode('<html><script>bad</script></html>'),'x.txt'));
 assert.throws(()=>inspectBytes(text.encode('<svg/>'),'x.png'));assert.throws(()=>inspectBytes(text.encode('MZbinary'),'x.exe'));
 const png=new Uint8Array(24);png.set([137,80,78,71,13,10,26,10]);png.set(text.encode('IHDR'),12);const view=new DataView(png.buffer);view.setUint32(16,8000);view.setUint32(20,8000);assert.throws(()=>inspectBytes(png,'bomb.png'));
 assert.ok(!safeFileName('../../x\u202ehtml.exe').includes('/'));assert.throws(()=>inspectBytes(new Uint8Array(CHAT_LIMITS.fileBytes+1),'large.txt'));
});

test('Conflicting attachment IDs cannot alias an existing receiver cache',()=>{const chat=createChatAuthority({members:()=>roster}),file={id:'cache-id',name:'original.txt',size:3,mime:'text/plain',hash:'a'.repeat(64)};chat.accept('a',create('m1',{file}));assert.equal(chat.accept('b',create('m2',{file:{...file,hash:'b'.repeat(64)}}))[0].packet.op,'error');});
