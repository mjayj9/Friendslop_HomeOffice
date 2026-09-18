"""Run current engine fixtures and archive results with the verified local build."""
import argparse, datetime, hashlib, json, shutil, subprocess, sys
from pathlib import Path

parser=argparse.ArgumentParser();parser.add_argument('--godot',required=True);args=parser.parse_args()
root=Path(__file__).resolve().parents[1];evidence=root/'evidence/v5'
subprocess.run([sys.executable,str(root/'tools/site_artifact.py'),'verify',str(root/'build'),'--source'],check=True)
build=json.loads((root/'build/build-info.json').read_text(encoding='utf-8'))
destination=evidence/'engine'/build['buildId'];destination.mkdir(parents=True,exist_ok=True)
tests=[('table-support','table-support'),('motion-matrix','motion-matrix'),('court-access','court-access'),('carry-volume','carry-volume'),('seat-contacts','seat-contacts'),('placement','placement'),('retained-living-props','retained-living-props'),('wardrobe','wardrobe-engine')]
report={'buildId':build['buildId'],'sourceDigest':build['source']['digest'],'scope':'Headless fixture checks; not browser, human, artwork or full V5 acceptance','testedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'suites':[]}
failed=False
for script,name in tests:
    output=evidence/(name+'.json')
    if output.exists():
        old=evidence/'prior-engine'/hashlib.sha256(output.read_bytes()).hexdigest()[:12];old.mkdir(parents=True,exist_ok=True);shutil.copy2(output,old/output.name)
    result=subprocess.run([args.godot,'--headless','--path',str(root),'--script','res://tests/v5-'+script+'.gd'],capture_output=True,timeout=50)
    log=(result.stdout+result.stderr).decode('utf-8',errors='replace');(destination/(script+'.log')).write_text(log,encoding='utf-8')
    row={'script':'tests/v5-'+script+'.gd','exitCode':result.returncode,'log':str((destination/(script+'.log')).relative_to(evidence)).replace('\\','/')}
    if output.exists():
        data=json.loads(output.read_text(encoding='utf-8'));checks=data.get('checks',data.get('results',[]));checks=checks or [{'ok':line.startswith('PASS ')} for line in log.splitlines() if line.startswith(('PASS ','FAIL '))];row.update(checks=len(checks),passed=sum(bool(c.get('ok',c.get('passed',False))) for c in checks));shutil.copy2(output,destination/output.name);row['result']=str((destination/output.name).relative_to(evidence)).replace('\\','/')
    row['ok']=result.returncode==0 and 'SCRIPT ERROR' not in log and 'ERROR:' not in log and row.get('checks',0)>0 and row.get('checks',0)==row.get('passed',-1)
    failed|=not row['ok'];report['suites'].append(row);print(json.dumps(row),flush=True)
report['passed']=not failed
(destination/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8');(evidence/'engine-regression.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
raise SystemExit(1 if failed else 0)
