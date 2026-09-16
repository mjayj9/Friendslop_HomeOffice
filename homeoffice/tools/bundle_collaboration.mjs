import {build} from 'esbuild';
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
await build({entryPoints:[root+'web/collaboration-source.mjs'],bundle:true,minify:true,format:'esm',outfile:root+'web/collaboration.mjs',legalComments:'linked'});
await fs.copyFile(root+'node_modules/quill/dist/quill.snow.css',root+'web/quill.css');
console.log('Bundled Yjs + QuillBinding + Quill for static offline-capable web export');
