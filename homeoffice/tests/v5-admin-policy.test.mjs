import test from 'node:test';import assert from 'node:assert/strict';
import {generateKeyPairSync,randomUUID} from 'node:crypto';
import {createAdminPolicy,memoryStore} from '../server/admin-policy.mjs';
import {createPolicyVerifier} from '../web/room-policy.mjs';
test('Only server-verified operator can bind court identity; session, actor, signature and expiry are enforced',async()=>{
 const {privateKey,publicKey}=generateKeyPairSync('ec',{namedCurve:'prime256v1'});let now=Date.now();
 const token=randomUUID(),policy=createAdminPolicy({verifyIdentity:async value=>({id:value===token?'real-operator':'ordinary-host'}),adminIds:new Set(['real-operator']),privateKey,store:memoryStore(),now:()=>now});
 const verifier=createPolicyVerifier({publicKey:publicKey.export({format:'jwk'}),clock:()=>now});
 const session='test-session-courts',challenge=randomUUID(),actor='peer-real-operator';
 await assert.rejects(policy.bindActor({token:'host-admin-nickname',session,challenge,actor}),e=>e.status===403);
 const envelope=await policy.bindActor({token,session,challenge,actor});const accepted=await verifier.accept(envelope,{expectedSession:session,challenge});
 assert.ok(accepted.administrators[actor]>now);assert.equal(accepted.administrators['ordinary-host'],undefined);assert.equal(accepted.rooms.basketball.locked,false,'Open door remains separate from the role requirement');
 assert.ok(!Object.hasOwn(accepted,'uid'), 'Private account UID is not sent in policy');
 await assert.rejects(verifier.accept(envelope,{expectedSession:'another-session',challenge}));
 const forged={...envelope,payload:Buffer.from(JSON.stringify({...accepted,administrators:{'ordinary-host':now+30000}})).toString('base64url')};
 await assert.rejects(verifier.accept(forged,{expectedSession:session,challenge}));
 now+=30001;await assert.rejects(verifier.accept(envelope,{expectedSession:session,challenge}));
 const nonce=randomUUID(),expired=await verifier.accept(await policy.state({session,challenge:nonce}),{expectedSession:session,challenge:nonce});assert.deepEqual(expired.administrators,{});
});
