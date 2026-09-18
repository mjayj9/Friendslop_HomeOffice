from pathlib import Path
import argparse,datetime,hashlib,json,subprocess,uuid
R=Path(__file__).resolve().parents[1]
def git(*args):
 p=subprocess.run(['git','-C',str(R),*args],capture_output=True,text=True)
 return p.stdout.strip() if p.returncode==0 else None
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
TEXT_EXTENSIONS={'.gd','.mjs','.js','.json','.tscn','.tres','.css','.html','.txt','.md','.svg','.godot','.cfg'}
def source_sha(p):
 data=p.read_bytes()
 if p.suffix in TEXT_EXTENSIONS:data=data.replace(b'\r\n',b'\n')
 return hashlib.sha256(data).hexdigest()
def source_manifest():
 files={}
 for folder in ['scripts','scenes','assets','web']:
  for p in sorted((R/folder).rglob('*')):
   if not p.is_file() or p.suffix in ['.import','.uid'] or p.name in ['build-version.json','build-id.mjs']:continue
   files[p.relative_to(R).as_posix()]=source_sha(p)
 for name in ['project.godot','export_presets.cfg']:
  if (R/name).exists():files[name]=source_sha(R/name)
 digest=hashlib.sha256(json.dumps(files,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 return {'algorithm':'SHA256 of sorted relative-path to SHA256 mapping; text uses LF; generated build ID and import cache excluded','digest':digest,'files':files}

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('phase',choices=['prepare','finalize']);args=parser.parse_args()
 marker=R/'assets/build-version.json'
 if args.phase=='prepare':
  info={'buildId':str(uuid.uuid4()),'commit':git('rev-parse','HEAD'),'dirty':bool(git('status','--porcelain')),'godotVersion':'4.6.1.stable','exportTemplatesVersion':'4.6.1.stable','protocolVersion':4,'assetVersion':3,'schemaVersion':2,'builtAt':datetime.datetime.now(datetime.timezone.utc).isoformat()}
  marker.write_text(json.dumps(info,indent=2),encoding='utf8',newline='\n')
  (R/'web/build-id.mjs').write_text('export const BUILD_ID='+json.dumps(info['buildId'])+';\n',encoding='utf8',newline='\n')
 else:
  info=json.loads(marker.read_text(encoding='utf8'));build=R/'build'
  # Git checkouts use different EOL settings. Published bytes must be stable.
  for p in build.rglob('*'):
   if p.is_file() and p.suffix in TEXT_EXTENSIONS and '_qa' not in p.relative_to(build).parts:
    data=p.read_bytes();normal=data.replace(b'\r\n',b'\n')
    if data!=normal:p.write_bytes(normal)
  info['source']=source_manifest()
  info['files']={p.relative_to(build).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(build.rglob('*')) if p.is_file() and p.name not in ['build-info.json','.gdignore'] and p.suffix not in ['.import','.uid'] and '_qa' not in p.relative_to(build).parts}
  (build/'build-info.json').write_text(json.dumps(info,indent=2),encoding='utf8',newline='\n')
  (R/'evidence/v5/build-info.json').write_text(json.dumps(info,indent=2),encoding='utf8',newline='\n')
  archive=R/'evidence/v5/builds';archive.mkdir(parents=True,exist_ok=True)
  (archive/(info['buildId']+'.json')).write_text(json.dumps(info,indent=2),encoding='utf8',newline='\n')
 print(args.phase,info['buildId'])
