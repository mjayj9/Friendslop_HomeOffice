"""Repair V2's fully transparent body materials, preserving original GLBs."""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[1]

def repair(source, target):
    data = source.read_bytes()
    magic, version, length = struct.unpack_from('<III', data)
    assert magic == 0x46546C67 and version == 2 and length == len(data)
    size, kind = struct.unpack_from('<II', data, 12)
    assert kind == 0x4E4F534A
    doc = json.loads(data[20:20 + size])
    changed = []
    for material in doc.get('materials', []):
        color = material.get('pbrMetallicRoughness', {}).get('baseColorFactor')
        if material.get('alphaMode') == 'MASK' and color and color[3] == 0:
            color[3] = 1
            material['alphaMode'] = 'OPAQUE'
            material.pop('alphaCutoff', None)
            changed.append(material.get('name'))
    payload = json.dumps(doc, separators=(',', ':')).encode('utf8')
    payload += b' ' * (-len(payload) % 4)
    tail = data[20 + size:]
    out = struct.pack('<III', magic, version, 20 + len(payload) + len(tail))
    out += struct.pack('<II', len(payload), kind) + payload + tail
    target.write_bytes(out)
    return {'source': source.name, 'output': target.name, 'materials': changed,
            'binaryChunkUnchanged': out[20 + len(payload):] == tail,
            'sourceSha256': hashlib.sha256(data).hexdigest(),
            'outputSha256': hashlib.sha256(out).hexdigest()}

if __name__ == '__main__':
    records = []
    for stem in ['male-rigged', 'male-seated', 'male-lying', 'male-arms']:
        records.append(repair(ROOT / f'assets/characters/{stem}.glb', ROOT / f'assets/characters/{stem}-v3.glb'))
    evidence = ROOT / 'evidence/v3/character-material-repair.json'
    evidence.parent.mkdir(parents=True, exist_ok=True)
    evidence.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps(records, ensure_ascii=False, indent=2))
