import test from 'node:test';import assert from 'node:assert/strict';import {generateKeyPairSync,sign} from 'node:crypto';
import {clerkIdentity} from '../server/clerk-adapter.mjs';
test('Official Clerk SDK rejects expired, foreign-origin, foreign-issuer and forged synthetic session JWTs',async()=>{
 const keys=generateKeyPairSync('rsa',{modulusLength:2048}),issuer='https://synthetic-only.clerk.accounts.dev',origin='http://localhost:8065',at=Math.floor(Date.now()/1000);
 const verify=await clerkIdentity({jwtKey:keys.publicKey.export({format:'pem',type:'spki'}),authorizedParties:[origin],issuer});
 function jwt(extra={}){const encode=o=>Buffer.from(JSON.stringify(o)).toString('base64url'),value=encode({alg:'RS256',typ:'JWT',kid:'fixture'})+'.'+encode({iss:issuer,azp:origin,sub:'user_fixture',sid:'sess_fixture',iat:at-1,nbf:at-1,exp:at+60,...extra});return value+'.'+sign('RSA-SHA256',Buffer.from(value),keys.privateKey).toString('base64url');}
 assert.deepEqual(await verify(jwt()),{id:'user_fixture'});
 for(const token of [jwt({exp:at-60}),jwt({azp:'https://attacker.invalid'}),jwt({iss:'https://other.clerk.accounts.dev'}),jwt().slice(0,-50)+'invalid'])await assert.rejects(verify(token));
});
