from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
p=R/'scripts/v2/world_base.gd'
base=p.read_text(encoding='utf8') if p.exists() else (R/'tools/v2_base.txt').read_text(encoding='utf8')
base=base.replace('func _unhandled_input(', 'func base_input(').replace('func perform(', 'func base_perform(')
ext=(R/'tools/v2_functions.txt').read_text(encoding='utf8')
for match in re.finditer(r'(?ms)^func (\w+)\(.*?(?=^func |\Z)',ext):
    name=match.group(1);code=match.group(0).rstrip()+'\n\n';pattern=rf'(?ms)^func {name}\(.*?(?=^func |\Z)'
    base=re.sub(pattern,lambda _:code,base,count=1) if re.search(pattern,base) else base+'\n'+code
(R/'scripts/v2/world.gd').write_text(base,encoding='utf8')
if p.exists():
    (R/'tools/v2_base.txt').write_text(p.read_text(encoding='utf8'),encoding='utf8');p.unlink()
print('Assembled complete V2 world script')
