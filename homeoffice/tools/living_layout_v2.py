from pathlib import Path
import json
p=Path(__file__).resolve().parents[1]/"assets/v2/layout.json"
d=json.loads(p.read_text(encoding="utf8"))
items=[{'id': 'living-storage', 'kind': 'storage', 'p': [-5.85, 0, 8.15], 'yaw': -1.57079632679, 'state': {'open': False, 'contents': []}}, {'id': 'living-drawer', 'kind': 'drawer', 'p': [-13.6, 0, 10.75], 'yaw': 1.57079632679, 'state': {'open': False, 'contents': []}}, {'id': 'living-lamp', 'kind': 'floor_lamp', 'p': [-13.7, 0, 4.15], 'yaw': 0, 'state': {'on': True}}]
d["furniture"]=[x for x in d["furniture"] if x["id"] not in {i["id"] for i in items}]+items
p.write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding="utf8")
