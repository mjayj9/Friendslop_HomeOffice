import test from 'node:test';
import assert from 'node:assert/strict';
import {createRoomCode,parseInvitation,invitationLink} from '../web/invitations.mjs';
import {validateRegistry,validateDocument,googleSearch} from '../web/document-registry.mjs';
test('Invite code, pasted URL, classroom and subpath round trip',()=>{
 for(let i=0;i<100;i++)assert.match(createRoomCode(),/^[A-Z]{3}-[A-Z]{3}$/);
 assert.deepEqual(parseInvitation(' qec ete '),{code:'QEC-ETE',peer:'ho3-QEC-ETE'});
 const link=invitationLink('https://example.test/Friendslop_HomeOffice/?old=1#x','QEC-ETE');
 assert.equal(link,'https://example.test/Friendslop_HomeOffice/?room=QEC-ETE');
 assert.equal(parseInvitation(link).peer,'ho3-QEC-ETE');assert.equal(parseInvitation('classroom').peer,'ho3-classroom-v1');
 for(const bad of ['mh-abc','abc','javascript:alert(1)','https://example.test/?room=%3Cfoo%3E'])assert.throws(()=>parseInvitation(bad));
});
const doc={id:'doc-1',name:'회의 보고서',provider:'docs',url:'https://docs.google.com/document/d/abc123/edit?usp=sharing'};
test('Official original documents are validated and preserved in snapshots',()=>{
 assert.equal(validateDocument(doc).url,'https://docs.google.com/document/d/abc123/edit');
 assert.equal(validateDocument({...doc,provider:'slides',url:'https://docs.google.com/presentation/d/ABC/edit'}).provider,'slides');
 assert.equal(validateDocument({...doc,provider:'excel',url:'https://1drv.ms/x/s!abc123'}).provider,'excel');
 assert.throws(()=>validateRegistry([doc,doc]));
 for(const url of ['javascript:alert(1)','http://docs.google.com/document/d/a/edit','https://docs.google.com.evil.test/document/d/a/edit','https://user:pass@docs.google.com/document/d/a/edit','https://docs.google.com/document/d/e/xxx/pub'])assert.throws(()=>validateDocument({...doc,url}));
 assert.throws(()=>validateDocument({...doc,provider:'excel'}));
 assert.equal(new URL(googleSearch('회의 & 일정 #1')).searchParams.get('q'),'회의 & 일정 #1');
});
