// Server only. Clerk verifies the session JWT; the private UID set determines administrator status.
export async function clerkIdentity({jwtKey,authorizedParties,issuer}){
 if(!jwtKey||!issuer?.startsWith('https://')||!authorizedParties?.length)throw Error('Clerk 검증 설정이 필요합니다.');
 const {verifyToken}=await import('@clerk/backend');
 return async token=>{if(typeof token!=='string'||token.length>8192)throw Error('인증 오류');const p=await verifyToken(token,{jwtKey,authorizedParties});if(p.iss!==issuer||!p.sid||!p.sub)throw Error('인증 발급자 오류');return {id:p.sub};};
}
