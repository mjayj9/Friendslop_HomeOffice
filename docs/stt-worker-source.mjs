import {pipeline,env} from '@huggingface/transformers';
env.allowLocalModels=false;
env.backends.onnx.wasm.numThreads=1;
env.backends.onnx.wasm.wasmPaths=new URL('./onnx/',import.meta.url).href;
const model='onnx-community/whisper-tiny',revision='ff4177021cc41f7db950912b73ea4fdf7d01d8e7';
let recognizer,loading=false,busy=false;
self.onmessage=async({data:m})=>{
 try{
  if(m.type==='load'&&!loading){loading=true;recognizer=await pipeline('automatic-speech-recognition',model,{revision,dtype:'q8',device:'wasm',session_options:{graphOptimizationLevel:'disabled'},progress_callback:p=>self.postMessage({type:'progress',progress:p})});self.postMessage({type:'ready',model,revision});return}
  if(m.type==='transcribe'&&recognizer&&!busy){busy=true;const start=performance.now();const result=await recognizer(m.audio,{language:'korean',task:'transcribe',return_timestamps:false,max_new_tokens:128});self.postMessage({type:'result',generation:m.generation,text:result.text,elapsedMs:performance.now()-start,duration:m.audio.length/16000,sequence:m.sequence});busy=false}
 }catch(e){busy=false;loading=false;self.postMessage({type:'error',error:e.message})}
};
