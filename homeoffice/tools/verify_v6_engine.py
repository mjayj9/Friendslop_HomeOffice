"""Bind retained and campus physics fixtures to a verified build without rewriting V5 evidence."""
import argparse, datetime, json, subprocess, sys
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,str(root/'tools/site_artifact.py'),'verify',str(root/'build'),'--source'],check=True)
build=json.loads((root/'build/build-info.json').read_text(encoding='utf-8'))
dest=root/'evidence/v6/engine'/build['buildId'];dest.mkdir(parents=True,exist_ok=True)
tests=[('v5-table-support','v5/table-support',60),('v5-motion-matrix','v5/motion-matrix',60),('v5-court-access','v5/court-access',60),('v5-carry-volume','v5/carry-volume',60),('v5-seat-contacts','v5/seat-contacts',60),('v5-placement','v5/placement',60),('v5-retained-living-props','v5/retained-living-props',60),('v5-wardrobe','v5/wardrobe-engine',60),('v6-campus-physics','v6/campus-physics',90),('v6-stair-route','v6/stair-route',420),('v6-private-rooms','v6/private-rooms',90),('v6-facility-access','v6/facility-access',120)]
aux=root/'evidence/v5/storage-world.json';aux_before=aux.read_bytes() if aux.exists() else None
rows=[]
for script,out,limit in tests:
    path=root/'evidence'/(out+'.json');before=path.read_bytes() if path.exists() else None
    try:
        result=subprocess.run([a.godot,'--headless','--path',str(root),'--script','res://tests/'+script+'.gd'],capture_output=True,timeout=limit)
        log=(result.stdout+result.stderr).decode('utf-8',errors='replace')
        (dest/(script+'.log')).write_text(log,encoding='utf-8')
        checks=[line.startswith('PASS ') for line in log.splitlines() if line.startswith(('PASS ','FAIL '))]
        if not checks and path.exists():
            data=json.loads(path.read_text(encoding='utf-8'));checks=[bool(c.get('ok',c.get('passed',False))) for c in data.get('checks',data.get('results',[]))]
        row={'script':script,'ok':result.returncode==0 and bool(checks) and all(checks) and 'ERROR:' not in log and 'SCRIPT ERROR' not in log,'checks':len(checks),'passed':sum(checks),'exitCode':result.returncode}
        if path.exists():(dest/(script+'.json')).write_bytes(path.read_bytes())
    except subprocess.TimeoutExpired as e:
        row={'script':script,'ok':False,'timeout':limit};(dest/(script+'.log')).write_bytes((e.stdout or b'')+(e.stderr or b''))
    finally:
        if out.startswith('v5/'):
            if before is not None:path.write_bytes(before)
            elif path.exists():path.unlink()
    rows.append(row);print(json.dumps(row),flush=True)
if aux.exists():(dest/'retained-storage-world.json').write_bytes(aux.read_bytes())
if aux_before is not None:aux.write_bytes(aux_before)
report={'buildId':build['buildId'],'sourceDigest':build['source']['digest'],'testedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'Headless physics/authority/save fixtures, not artwork, real accounts or human acceptance. V5 historical files restored byte-for-byte.','suites':rows,'passed':all(r['ok'] for r in rows)}
(dest/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(root/'evidence/v6/engine-regression.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
sys.exit(0 if report['passed'] else 1)
