import test from 'node:test';
import assert from 'node:assert/strict';
import {createMeetingPolicy,validateMeetingArchive} from '../web/meeting-policy.mjs';
import {validateWorld,encodeWorld,decodeBundle} from '../web/save-v2.mjs';

test('Two simultaneous meetings require independent current membership grants',()=>{
  const online=new Set(['a','b','c','d']),p=createMeetingPolicy({isMember:id=>online.has(id)});
  const ga=p.join('a','council'),gb=p.join('b','council'),gc=p.join('c','moss'),gd=p.join('d','moss');
  assert.deepEqual(p.peers('council'),['a','b']);assert.deepEqual(p.peers('moss'),['c','d']);
  assert.ok(p.permits('b','council',gb.generation));assert.equal(p.permits('b','moss',gb.generation),false);
  assert.equal(p.permits('a','council',gc.generation),false);assert.equal(p.join('outsider','council'),null);
  p.join('a','clay');assert.equal(p.permits('a','council',ga.generation),false);
  online.delete('d');assert.equal(p.permits('d','moss',gd.generation),false);
});

test('Revocation and host reset invalidate stale grants; no administrator privilege exists',()=>{
  const p=createMeetingPolicy({isMember:()=>true}),g=p.join('peer','council');
  assert.deepEqual(Object.keys(g).sort(),['generation','meetingId']);p.revoke('peer','council');
  assert.equal(p.join('peer','council'),null);assert.equal(p.permits('peer','council',g.generation),false);
  p.reset();const fresh=p.join('peer','council');assert.notEqual(fresh.generation,g.generation);
  assert.equal(p.permits('peer','council',g.generation),false);
});

const meeting=id=>({id,collaboration:{update:'AAA=',revision:1},documents:[],presentation:[],presentationView:{selected:0,page:1,annotations:[]},board:[]});
const world=()=>({schemaVersion:2,worldId:'review',assetPack:2,layoutVersion:2,roomSlots:[],objects:[],doors:{},board:[],revision:1,results:{basketball:[0,0],football:[0,0]},settings:{maxPlayers:8},meetings:[meeting('council'),meeting('moss')]});
test('Old worlds remain accepted and two scoped meetings survive archive round trip',async()=>{
  const before=world(),old={...before};delete old.meetings;assert.deepEqual(validateWorld(old),old);
  const bytes=await encodeWorld(before);const restored=await decodeBundle(bytes);assert.deepEqual(restored.world.meetings,before.meetings);
});
test('Archives reject session grants, PIN fields, duplicate scopes and unknown meetings',()=>{
  for(const field of ['pin','token','generation','members','administrator'])assert.throws(()=>validateMeetingArchive([{...meeting('council'),[field]:'forged'}]));
  assert.throws(()=>validateMeetingArchive([meeting('council'),meeting('council')]));
  assert.throws(()=>validateMeetingArchive([meeting('outside')]));
});
test('Meeting attachment data is exported and validated, not silently left behind',async()=>{
  const w=world(),bytes=Uint8Array.of(137,80,78,71,13,10,26,10);
  const {sha}=await import('../web/save-v2.mjs');const id=await sha(bytes);
  w.meetings[0].presentation=[{id,name:'fixture.png',mime:'image/png',sha256:id,bytes:bytes.length}];
  await assert.rejects(encodeWorld(w));
  const restored=await decodeBundle(await encodeWorld(w,new Map([[id,bytes]])));
  assert.deepEqual(restored.attachments.get(id),bytes);
});


test('Unplaced furniture preserves identity and storage references without importing authority',async()=>{
 const w=world();w.campusVersion=1;w.unplaced=[{id:'saved-cabinet',kind:'storage',p:[21,0,-34.8],yaw:0,state:{contents:['saved-book']}},{id:'saved-book',kind:'book',p:[21,.8,-34.8],yaw:0,state:{}}];w.campusDoors={operations:true};
 assert.deepEqual((await decodeBundle(await encodeWorld(w))).world,w);
 const injected=structuredClone(w);injected.unplaced[0].state.token='not-a-real-secret';assert.throws(()=>validateWorld(injected));
 const duplicate=structuredClone(w);duplicate.objects=[duplicate.unplaced[1]];assert.throws(()=>validateWorld(duplicate));
 const privilege=structuredClone(w);privilege.campusDoors.administrator=true;assert.throws(()=>validateWorld(privilege));
});
