"""One source for dimensioned design documents and the built Godot level. Metres, Y up."""
from pathlib import Path
import json,re,html
R=Path(__file__).resolve().parents[1]; O=R/'assets/v2';O.mkdir(parents=True,exist_ok=True)
D=R/'docs/v2';D.mkdir(parents=True,exist_ok=True)
rooms=[];walls=[];furniture=[];doors=[];protected=[]
def room(id,name,r,y=0,finish='oak',ceiling=True):
    rooms.append(dict(id=id,name=name,rect=r,y=y,finish=finish,ceiling=ceiling))
def wall(id,a,b,y=0,openings=[],material='plaster'):
    walls.append(dict(id=id,a=a,b=b,y=y,height=3.3,thickness=.22,openings=openings,material=material))
def gap(at,width=1.8,sill=0,height=2.5,kind='passage'):return dict(at=at,width=width,sill=sill,height=height,kind=kind)
def obj(id,kind,x,y,z,yaw=0,**extra):furniture.append(dict(id=id,kind=kind,p=[x,y,z],yaw=yaw,**extra))
room('hall','현관 · 계단 홀',[-5,-12,1.4,12],finish='stone')
room('living','거실',[-15,3,-5,12])
room('dining','식당',[-15,-3,-5,3])
room('kitchen','주방',[-15,-10,-5,-3],finish='tile')
room('pantry','팬트리',[-15,-12,-5,-10],finish='tile')
room('meeting','회의실',[1.4,4,11.4,12],finish='carpet')
room('resources','자료 · 토론',[11.4,4,15,12],finish='carpet')
room('free','자유 작업방',[1.4,-6,15,4],finish='concrete')
room('utility','수납 · 다용도',[1.4,-12,9,-6],finish='tile')
room('bath_ground','화장실',[9,-12,15,-6],finish='tile')
room('vestibule','별동 연결 전실',[15,-1.5,20,1.5],finish='stone')
room('game','태그 · 사격',[20,-6,36,2],finish='rubber')
room('arcade','아케이드 · 관전',[20,2,36,6],finish='rubber')
room('upper_hall','2층 갤러리',[-5,-12,1.4,12],3.6,'oak')
room('sleep','수면실',[-15,-12,-5,-4],3.6,'carpet')
room('reading','독서 · 휴식',[-15,-4,-5,5],3.6,'oak')
room('bath_upper','욕실 · 린넨',[-15,5,-5,12],3.6,'tile')
room('roof_terrace','2층 테라스',[1.4,-12,15,12],3.6,'deck',False)
room('terrace','정원 데크',[-15,12,-5,17],0,'deck',False)
room('basketball','농구',[-18,23,6,37],0,'court_blue',False)
room('football','축구',[10,22,40,42],0,'court_green',False)
# External shell. Doors are wide enough for two 0.54 m character capsules.
wall('south',[-15,12],[15,12],openings=[gap(5,2.2),gap(13.2,2.2),gap(22,4,1,1.7,'window')])
wall('north',[-15,-12],[15,-12],openings=[gap(6,3,1,1.7,'window'),gap(15,2.2),gap(25,2.4,1.2,1.4,'window')])
wall('west',[-15,-12],[-15,12],openings=[gap(5,2.4,1,1.7,'window'),gap(11,3,1,1.7,'window'),gap(19,4.6,.6,2.1,'window')])
wall('east',[15,-12],[15,12],openings=[gap(12,2.2),gap(20,3.6,1,1.7,'window')])
wall('west_spine',[-5,-12],[-5,12],openings=[gap(5.5,2),gap(12,2.6),gap(22.5,2.2)])
wall('east_spine',[1.4,-12],[1.4,12],openings=[gap(3,1.8),gap(10,2.2),gap(19,2.2)])
wall('kitchen_dining',[-15,-3],[-5,-3],openings=[gap(7.2,3.4)])
wall('living_dining',[-15,3],[-5,3],openings=[gap(6.4,5.2)])
wall('pantry',[-15,-10],[-5,-10],openings=[gap(7.5,1.8)])
wall('utility',[1.4,-6],[15,-6],openings=[gap(4,1.8),gap(10.5,1.8)])
wall('bath_divide',[9,-12],[9,-6])
wall('meeting_free',[1.4,4],[15,4],openings=[gap(11,1.8)],material='sage')
wall('resource_glass',[11.4,4],[11.4,12],openings=[gap(2,2.2),gap(5.5,3,0.9,2,'window')])
wall('vest_n',[15,-1.5],[20,-1.5],openings=[gap(2.5,3.6,.8,1.9,'window')])
wall('vest_s',[15,1.5],[20,1.5],openings=[gap(2.5,3.6,.8,1.9,'window')])
wall('game_w',[20,-6],[20,6],openings=[gap(6,2.2)])
wall('game_e',[36,-6],[36,6],openings=[gap(9,3,1,1.7,'window')])
wall('game_n',[20,-6],[36,-6],openings=[gap(4,3,1.6,1.1,'window'),gap(12,3,1.6,1.1,'window')])
wall('game_s',[20,6],[36,6],openings=[gap(4,2.2,1,1.7,'window'),gap(11,4,1,1.7,'window')])
wall('arcade_divider',[23,2],[36,2],openings=[gap(3,3.5)])
for id,a,b,op in [
 ('upper_w',[-15,-12],[-15,12],[gap(4,3,1,1.7,'window'),gap(13,4,.7,2,'window'),gap(20,2,1.2,1.5,'window')]),
 ('upper_s',[-15,12],[1.4,12],[gap(6,3,1.2,1.5,'window'),gap(13.3,3,.8,1.9,'window')]),
 ('upper_n',[-15,-12],[1.4,-12],[gap(4,3,1.2,1.5,'window'),gap(15,2.6)]),
 ('upper_e',[1.4,-12],[1.4,12],[gap(6,3,.6,2.1,'window'),gap(14,2.2),gap(20,3,.6,2.1,'window')]),
 ('upper_spine',[-5,-12],[-5,12],[gap(4,1.8),gap(12,2.2),gap(20,1.8)]),
 ('sleep_read',[-15,-4],[-5,-4],[]),('read_bath',[-15,5],[-5,5],[])]:wall(id,a,b,3.6,op)
# Door pivots: dimensions and swing clearance are part of the generated plan.
doors=[dict(id='terrace-door',p=[-11.1,0,12],yaw=0,width=2.2,open=True,secure=False),dict(id='front-door',p=[-2.9,0,12],yaw=0,width=2.2,open=True,secure=False),dict(id='meeting-door',p=[1.4,0,5.9],yaw=-1.570796,width=2.2,open=True,secure=False),dict(id='game-gate',p=[20,0,-1.1],yaw=-1.570796,width=2.2,open=False,secure=True),dict(id='sleep-door',p=[-5,3.6,-8.9],yaw=-1.570796,width=1.8,open=True,secure=False)]
for d in doors:protected.append(dict(id=d['id'],p=d['p'],radius=2))
protected += [dict(id='spawn',p=[-1.8,0,10.6],radius=2),dict(id='stairs',rect=[-4.9,5.5,-1.45,10.4]),dict(id='gallery_extension',rect=[-1.4,-34.4,1.4,-12]),dict(id='basketball',rect=[-19,22,7,38]),dict(id='football',rect=[9,21,41,43])]
# Distinct furniture arrangements, all gameplay objects retain stable IDs.
obj('living-sofa-a','sofa',-11,0,8.8);obj('living-sofa-b','sofa',-13,0,6,-1.570796)
obj('living-sofa-c','sofa',-7,0,6,1.570796);obj('living-low-table','low_table',-10.4,0,6.3)
obj('living-book','book',-10.4,.48,6.3);obj('living-chair','chair',-7,0,10.1)
obj('dining-table','table',-10,0,0)
for i in range(8):obj(f'dining-chair-{i}','chair',-11.1+(i%4)*.72,0,1.05 if i<4 else -1.05,0 if i<4 else 3.141593)
for n,z in enumerate([7,9.4]):obj(f'meeting-table-{n}','table',6.5,0,z)
for i in range(8):obj(f'meeting-chair-{i}','chair',4.4 if i<4 else 8.6,0,5.6+(i%4)*1.5,-1.570796 if i<4 else 1.570796)
obj('meeting-marker','marker',6.5,1.02,4.25);obj('free-table','table',8,0,-3)
for i in range(4):obj(f'free-crate-{i}','crate',6+i*.58,.25,0)
obj('free-book','book',7.6,.9,-3)
obj('kitchen-fridge','fridge',-13.8,0,-8.6);obj('cook-station','cooker',-11,0,-8.8);obj('sink-station','sink',-7.8,0,-8.8)
obj('kitchen-island','counter',-10.2,0,-5.7);obj('plate-1','plate',-9.8,1.04,-5.7);obj('pan-1','pan',-11,1.03,-8.8)
for i in range(8):obj(f'bed-{i}','bed',-13.7+(i%4)*2.4,3.6,-10.3 if i<4 else -5.7,0 if i<4 else 3.141593)
obj('reading-sofa','sofa',-12,3.6,.8);obj('reading-table','low_table',-12,3.6,-1);obj('reading-book','book',-12,4.08,-1)
obj('basketball','basketball',-7,.3,30);obj('football','football',25,.28,32)
obj('tag-gun-1','gun',23,.9,-3.8);obj('tag-gun-2','gun',24,.9,-3.8);obj('tag-shield','shield',25,.9,-3.8)
obj('toy-rack','table',24,0,-3.8);obj('arcade-maze','arcade',29,0,4.9);obj('arcade-runner','arcade',32,0,4.9)
plan=dict(version=2,units='metres; Godot Y up; north is -Z',site=[-23,-38,43,48],rooms=rooms,walls=walls,doors=doors,furniture=furniture,protected=protected,spawn=[-.4,0,11.0],board=[4.4,1.76,4.14],stairs=dict(rect=[-4.9,5.7,-1.5,10.2],rise=3.6,steps=20,riser=.18,tread=.3,flightWidth=1.5,landingDepth=1.5),officeExpansion=dict(maxRooms=8,startZ=-12,moduleDepth=5.4,corridorWidth=2.8,roomWidth=4.8,floorY=3.6,bounds=[-6.2,-33.6,6.2,-12]),voice=dict(zones='room IDs + generated office IDs',floorSeparation=3.6,closedDoorTransmission=.22,wallTransmission=.10),weaponZones=['game'])
(O/'layout.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf8')
# SVG is an engineering plan generated from the same room/wall/portal coordinates.
def svg(floor):
    allsite=floor=='site';scale=9 if allsite else 23;bounds=plan['site'] if allsite else [-17,-35,38,19];x0,z0,x1,z1=bounds;w=(x1-x0)*scale+130;h=(z1-z0)*scale+150
    X=lambda x:60+(x-x0)*scale;Z=lambda z:95+(z-z0)*scale
    s=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><style>text{{font-family:Malgun Gothic,Arial;fill:#23352f}}.small{{font-size:11px}}.room{{font-size:13px;font-weight:600}}</style><rect width="100%" height="100%" fill="#f6f3ec"/><text x="60" y="38" font-size="25">모여집 V2 · '+('부지 배치' if allsite else f'{floor+1}층 평면')+'</text><text x="60" y="62" class="small">게임 설계 제안 · m 단위 · 북쪽 ↑ · 건축 법규/공식 경기 규격 아님</text>']
    for r in rooms:
        if not allsite and r['y']!=(3.6 if floor==1 else 0):continue
        a,b,c,d=r['rect'];fill='#ddd8ca' if r['ceiling'] else '#c1d5b9'
        s.append(f'<rect x="{X(a)}" y="{Z(b)}" width="{(c-a)*scale}" height="{(d-b)*scale}" fill="{fill}" stroke="#99a295"/><text class="room" x="{X((a+c)/2)}" y="{Z((b+d)/2)-4}" text-anchor="middle">{r["name"]}</text><text class="small" x="{X((a+c)/2)}" y="{Z((b+d)/2)+13}" text-anchor="middle">{c-a:g} × {d-b:g}</text>')
    a,b,c,d=plan['officeExpansion']['bounds'];s.append(f'<rect x="{X(a)}" y="{Z(b)}" width="{(c-a)*scale}" height="{(d-b)*scale}" fill="#d7ddd0" stroke="#587a66" stroke-dasharray="7 5"/>')
    for i in range(4):
        zz=-12-(i+1)*5.4
        for j in range(2):
            xx=-6.2 if j==0 else 1.4
            s.append(f'<rect x="{X(xx)}" y="{Z(zz)}" width="{4.8*scale}" height="{5.4*scale}" fill="none" stroke="#7d957f"/><text class="small" x="{X(xx+2.4)}" y="{Z(zz+2.7)}" text-anchor="middle">개인실 {i*2+j+1:02} · 4.8×5.4</text>')
    if not allsite:
        for wall_ in walls:
            if wall_['y']!=(3.6 if floor==1 else 0):continue
            a,b=wall_['a'],wall_['b'];s.append(f'<path d="M {X(a[0])} {Z(a[1])} L {X(b[0])} {Z(b[1])}" stroke="#33493e" stroke-width="5"/>')
            horizontal=a[1]==b[1]
            for g in wall_['openings']:
                at=g['at'];half=g['width']/2;px=a[0]+at if horizontal else a[0];pz=a[1] if horizontal else a[1]+at
                s.append(f'<path d="M {X(px-half if horizontal else px)} {Z(pz if horizontal else pz-half)} L {X(px+half if horizontal else px)} {Z(pz if horizontal else pz+half)}" stroke="'+('#81bdc4' if g['kind']=='window' else '#f6f3ec')+'" stroke-width="7"/>')
        for d in doors:
            if d['p'][1]!=(3.6 if floor==1 else 0):continue
            s.append(f'<circle cx="{X(d["p"][0])}" cy="{Z(d["p"][2])}" r="{d["width"]*scale}" fill="none" stroke="#c98853" stroke-dasharray="3 4"/>')
    s.append(f'<path d="M {X(-1.8)} {Z(15)} L {X(-1.8)} {Z(-12)} L {X(0)} {Z(-30)} M {X(-1.8)} {Z(1)} L {X(22)} {Z(1)} M {X(-10)} {Z(17)} L {X(-10)} {Z(20)} L {X(26)} {Z(20)}" fill="none" stroke="#c46b46" stroke-dasharray="6 4" stroke-width="2"/><text x="60" y="{h-35}" class="small">주황 점선: 주요 동선 · 청록: 창 · 점선 상단: 고정 좌표 개인실 확장 · 게임 출입/무기 허가는 별개</text></svg>')
    return ''.join(s)
for floor,name in [('site','site-plan'),(0,'ground-floor'),(1,'upper-floor')]: (D/(name+'.svg')).write_text(svg(floor),encoding='utf8')
(D/'architecture.md').write_text('''# V2 건축 실행안

사용자 원문 U01~U56의 공간과 기능을 모두 유지한다. 아래 치수·2층 구성은 추가 게임 설계안이며 공식 건축/스포츠 규격이 아니다.

본관 30×24m, 1층 유효 높이 3.3m, 층고 3.6m. 동쪽 업무부 위는 외부 옥상 테라스, 서쪽 생활부 위는 조용한 수면·독서·욕실이다. 실내에는 천장이 있으며 외부로 분류한 데크·옥상·코트만 열린다. 주 동선 폭 2.8m, 공용 문 2.2m. 계단은 폭 1.5m 두 경사로, 20개 시각 단, 높이 0.18m, 디딤판 0.30m와 1.5m 중간참으로 구성한다. 단별 시각 메시와 걸음 안정성을 위한 연속 경사 충돌체를 분리한다.

북쪽 위층에 개인실 갤러리를 연장한다. 한 모듈은 복도 2.8m와 양옆 개인실 4.8×5.4m이다. 4개 모듈/8실까지 좌표를 미리 확보한다. 기존 방/가구를 이동시키지 않는다. 지상은 기둥과 정원이 있는 개방부로 코트와 겹치지 않는다. 참가자가 나가도 모듈을 지우지 않는다.

본관에서 동쪽 유리 전실 5m를 통과하면 16×12m 별동이다. 태그/사격과 아케이드/관전 구역을 구획한다. 출입 승인은 기본 잠김이며 도구 사용 허가와 별도다. 마당 남쪽의 농구 24×14m와 축구 30×20m를 4m 보행 완충 구간으로 분리한다. 전체 부지 66×86m는 제안 예시보다 남북으로 늘렸으며 운동 구역과 증축 날개를 겹치지 않게 하는 변경이다.

각 room ID가 물리 Zone이다. Session은 전체 접속 그룹이다. 음향은 거리, 층, 벽/닫힌 문을 따로 판단해야 한다. 개인실마다 새 Zone을 생성한다. 무기는 game Zone만 기본 허용 후보이며 방장 승인이 필요하다. 자유방은 명시적 추가 허가 전에는 허용하지 않는다.

공간/가구/창/문/보호 영역의 실제 좌표와 치수는 assets/v2/layout.json을 단일 원본으로 사용한다. site-plan.svg, ground-floor.svg, upper-floor.svg는 이 데이터에서 생성한다. 문 원은 회전 여유이며 점선은 동선이다. 생성 코드가 변경되면 도면도 재생성한다.

상태: 설계/구현 중. 전체 보행 검사 전에는 동선 검증완료가 아니다. 작동하지 않는 스포츠/생활/협업 물건은 필수 미완료로 유지한다.
''',encoding='utf8')
print('Wrote layout, 3 dimensioned plans and architectural decisions:',len(rooms),'zones;',len(furniture),'gameplay objects')

# Interactive living furniture extension is applied by living_layout_v2.py after regeneration.
