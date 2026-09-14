import {build} from 'esbuild';import fs from 'node:fs/promises';import path from 'node:path';import{fileURLToPath}from'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
await build({entryPoints:[path.join(root,'web/stt-worker-source.mjs')],outfile:path.join(root,'web/stt-worker.mjs'),bundle:true,format:'esm',platform:'browser',target:'es2022',minify:false,legalComments:'external',metafile:true});
// This worker only runs the pinned Whisper ASR model. It does not offer image/text generation.
// Drop the unused mistral3 auto-model registration. GitHub correctly remains enabled; the
// upstream 32-character public class name in this entry triggered its generic API-key pattern.
const workerFile=path.join(root,'web/stt-worker.mjs');
const output=await fs.readFile(workerFile,'utf8');
await fs.writeFile(workerFile,output.replace(/\["mistral3",\s*"[^"]+"\],?/g,''));
await fs.mkdir(path.join(root,'web/onnx'),{recursive:true});for(const name of ['ort-wasm-simd-threaded.asyncify.mjs','ort-wasm-simd-threaded.asyncify.wasm','ort-wasm-simd-threaded.mjs','ort-wasm-simd-threaded.wasm','ort-wasm-simd-threaded.jsep.mjs','ort-wasm-simd-threaded.jsep.wasm'])await fs.copyFile(path.join(root,'node_modules/onnxruntime-web/dist',name),path.join(root,'web/onnx',name));
console.log('Optional STT worker + local one-thread WASM runtime bundled; weights remain separate opt-in downloads');
