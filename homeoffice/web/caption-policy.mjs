export function createCaptionPolicy(){
 const generations=new Map(),utterances=new Map();
 return {invalidate(speaker,generation){if(!Number.isSafeInteger(generation)||generation<0)return false;if(generation<(generations.get(speaker)||0))return false;generations.set(speaker,generation);for(const[k,v]of utterances)if(v.speaker===speaker&&v.generation<generation)utterances.delete(k);return true;},accept(m){
  if(typeof m.speaker!=='string'||typeof m.utterance!=='string'||m.utterance.length>80||!Number.isSafeInteger(m.sequence)||!Number.isSafeInteger(m.generation)||m.generation<0||typeof m.text!=='string'||!m.text.trim()||m.text.length>400)return false;
  const current=generations.get(m.speaker)||0;if(m.generation<current)return false;if(m.generation>current)this.invalidate(m.speaker,m.generation);
  const key=m.speaker+':'+m.generation+':'+m.utterance,prior=utterances.get(key);
  if(prior&&(m.sequence<=prior.sequence||prior.final&&!m.final))return false;
  utterances.set(key,{speaker:m.speaker,generation:m.generation,sequence:m.sequence,final:!!m.final});if(utterances.size>512)utterances.delete(utterances.keys().next().value);return true;
 }};
}
