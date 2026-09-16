from pathlib import Path
import argparse,datetime,hashlib,json,subprocess,uuid
R=Path(__file__).resolve().parents[1]
def git(*args):
 p=subprocess.run(['git','-C',str(R),*args],capture_output=True,text=True)
 return p.stdout.strip() if p.returncode==0 else None
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def source_manifest():
 files={}
 for folder in ['scripts','scenes','assets','web']:
  for p in sorted((R/folder).rglob('*')):
   if not p.is_file() or p.suffix in ['.import','.uid'] or p.name in ['build-version.json','build-id.mjs']:continue
   files[p.relative_to(R).as_posix()]=sha(p)
 for name in ['project.godot','export_presets.cfg']:
  if (R/name).exists():files[name]=sha(R/name)
 digest=hashlib.sha256(json.dumps(files,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 return {'algorithm':'SHA256 of sorted relative-path to SHA256 mapping; generated build ID and import cache excluded','digest':digest,'files':files}

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('phase',choices=['prepare','finalize']);args=parser.parse_args()
 marker=R/'assets/build-version.json'
 if args.phase=='prepare':
  info={'buildId':str(uuid.uuid4()),'commit':git('rev-parse','HEAD'),'dirty':bool(git('status','--porcelain')),'godotVersion':'4.6.1.stable','exportTemplatesVersion':'4.6.1.stable','protocolVersion':3,'assetVersion':3,'schemaVersion':2,'builtAt':datetime.datetime.now(datetime.timezone.utc).isoformat()}
  marker.write_text(json.dumps(info,indent=2),encoding='utf8')
  (R/'web/build-id.mjs').write_text('export const BUILD_ID='+json.dumps(info['buildId'])+';\n',encoding='utf8')
 else:
  info=json.loads(marker.read_text(encoding='utf8'));build=R/'build'
  info['source']=source_manifest()
  info['files']={p.name:{'bytes':p.stat().st_size,'sha256':sha(p)} for p in build.iterdir() if p.is_file() and p.suffix in ['.mjs','.js','.html','.css','.wasm','.pck']}
  (build/'build-info.json').write_text(json.dumps(info,indent=2),encoding='utf8')
  (R/'evidence/v3/build-info.json').write_text(json.dumps(info,indent=2),encoding='utf8')
  archive=R/'evidence/v3/builds';archive.mkdir(exist_ok=True)
  (archive/(info['buildId']+'.json')).write_text(json.dumps(info,indent=2),encoding='utf8')
 print(args.phase,info['buildId'])
