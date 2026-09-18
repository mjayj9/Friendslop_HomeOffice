"""Generate an explicit, non-inflated N/T checkpoint from actual evidence files."""
from pathlib import Path
import json, re
R=Path(__file__).resolve().parents[1]
D=R/'docs/v5';E=R/'evidence/v5'
build=json.loads((R/'build/build-info.json').read_text(encoding='utf-8'))
def evidence(path):
    p=E/path
    if not p.exists():return '미실행 — 아직 결과 파일 없음'
    data=json.loads(p.read_text(encoding='utf-8'))
    bid=data.get('buildId','headless 소스 fixture / 영상·도면 자료') if isinstance(data,dict) else '실제 외부 영상 재생 기록'
    return f'[{path}](../../evidence/v5/{path}) · `{bid}`'
T={
1:('기준 확인','baseline/report.json','공개 73개 파일 bytes/SHA와 실제 WebGL. 소스 HEAD와 배포 ref가 다름. 최신 로컬 88개 파일은 별도 검증. 미술 합격으로 사용하지 않음.'),
2:('부분','repair-browser/report.json','living-low-table 가라앉음 재현·수리. dining-table 지지대 존재. 소파 현재 검수 추가. 계단/전 각도 의자 사용자 재현은 미완료.'),
3:('부분 시청','references/playback-attempts.json','NBA 공식/플레이, FC 공식 홍보/대회, VALORANT 실제 재생. 구간과 접근 실패는 research-observations-ko.md. 축구 주요 사건·한 라운드 시청은 부족.'),
4:('전체 설계·의상방만 반영','architecture/design-review.json','2층 의상방만 기존 독서 가구 보존하며 반영. 새 HOME/OFFICE/SPORTS 도면을 정리했으나 실제 건물·연속 보행 미완료.'),
5:('부분','repair-browser/report.json','거실 낮은 테이블과 식탁 실제 화면, reading-table 높이는 engine fixture. 모든 책상의 아래/측면 검수는 미완료.'),
6:('설계만','architecture/design-review.json','HOME/OFFICE 각 층 공용 복도에 위생 블록을 계획. 실제 이전·설비 사용은 미실행.'),
7:('설계만','architecture/design-review.json','3.6m U 계단, 20×.18m, 실제 계단참·슬래브 개구부 계획. runtime 계단/물건 운반 보행 미완료.'),
8:('부분 화면','seating-browser-front/report.json','기존 HOME 일부만 이번 빌드에서 시각 확인. 전 공간 재료·생활 소품 완성 판정 불가.'),
9:('fixture 부분','motion-matrix.json','위상·접지·클립 선택을 계측. 30/60/고FPS 실제 렌더·stride 일치 영상은 미완료.'),
10:('fixture 부분','motion-matrix.json','animation_only / ik_only / combined / remote_interpolation 표기 4모드. 마지막 모드는 수동 원격 위치 fixture이며 실제 지연망 비교 영상이 아님.'),
11:('부분 실제 UI','retained-v4-browser-wardrobe-build/report.json','3개 독립 Chromium에서 원격 몸체 표시 확인. 원격 발 contact 시계열·지연 조건별 품질은 미완료.'),
12:('기본 체형 부분','seating-browser-front/report.json','living-sofa-a 세 슬롯 실제 접근/F 착석/F 기상 10회. seat-contacts.json 20검사. 체형 최소/최대·옆 사람·부드러운 진입은 미완료. 다리가 곧은 자세도 추가 미술 수리 대상.'),
13:('fixture 부분','carry-volume.json','전체 chair collider AABB·양손 grip·급회전·release·인계 6검사. 실제 여러 각도·문 통과·던지기 영상은 미실행.'),
14:('이번 미실행',None,'기존 침대·소파 rest/sleep 경로 보존. 자기/원격 수면 인수 영상은 이번에 확인하지 않음.'),
15:('부분 실제 UI','retained-v4-browser-wardrobe-build/report.json','C 1/3인칭·휠 zoom·메신저 입력 격리 확인. Tab 포인터 해제와 캔버스 복귀 클릭 격리 추가. 계단·좁은 문 전체 인수는 미완료.'),
16:('명시 fixture만','court-access.json','일반 사용자·시뮬레이션 호스트 거절 및 임시 관리자 actor lease fixture. 실제 운영 관리자 계정 검증 미실행.'),
17:('fixture 확인','court-access.json','미검증/만료 상태는 잠금 유지. signed policy 서버 단위 검사도 시행. 운영 서버 장애 실험은 미실행.'),
18:('fixture 확인','court-access.json','열린 문·점프·복원·스폰·호스트 이전 경로 거절. 실제 총 보유 상태에서도 코트 거절, 총 소유는 유지.'),
19:('fixture 확인','court-access.json','공 없이 입장해 경기 시작 전 ready/jog/pivot 프로필·전용 카메라 적용. 운영 관리자 실제 브라우저 입장 영상은 없음.'),
20:('fixture 부분','court-access.json','프로필 entry 1회·이탈 시 이전 카메라 복원·무볼 phantom action 방지. 유볼 전이·원격 UI 조합 미완료.'),
21:('이번 미실행',None,'기존 농구 드리블/크로스오버/스틸 경로가 존재함. 현재 V5 접촉 시점 품질 검수·재설계 미완료.'),
22:('이번 미실행',None,'기존 게이지·릴리스·백스핀 경로 보존. 손 접촉·착지·거리별 궤적 인수 미완료.'),
23:('이번 미실행',None,'기존 링/보드와 득점 처리 존재. swish/bank/rim-out 실제 반복 검수 미완료.'),
24:('미완료',None,'기존 경기 제어를 삭제하지 않음. 새 지원 모드의 연속 시작→결과→재시작 영상 없음.'),
25:('미완료',None,'기존 발 제어 존재. 아직 root 거리/주기 기반 impulse 경로여서 실제 발 접촉 타이밍 요구 충족으로 판정할 수 없음.'),
26:('이번 미실행',None,'기존 goal/out-of-bounds 경로 보존. 새 first touch·가로채기·골 완결 검수 미실행.'),
27:('미완료',None,'훈련·봇·지원 경기 한 회의 현재 빌드 인수 없음.'),
28:('HOME 부분','placement-browser-wardrobe-build/report.json','HOME 실제 총 장착·발사 positive control 뒤 패널 드래그 시 추가 shot 없음. 회의실·교실·마당 전체 실제 조작은 미실행.'),
29:('이번 미실행',None,'기존 equip/aim/fire/reload/효과 경로 보존. 1/3인칭 동기화 미술 인수 미완료.'),
30:('이번 미실행',None,'기존 CombatState HP/KO/게이지/respawn 보존. 이번 전체 combat 지연/가림 인수는 미실행.'),
31:('미완료',None,'새 자체 전술 지도와 승패/재시작 한 라운드 구현·인수 남음.'),
32:('실제 UI 확인','placement-browser-wardrobe-build/report.json','Tab으로 포인터를 해제한 뒤 화면 물건 설치 버튼 클릭. 검색·12개 실제 GLB 썸네일·크기·옆 패널 확인.'),
33:('실제 UI 부분','placement-browser-wardrobe-build/report.json','DPR1.5에서 실제 pointer ray/ghost/R 회전/drop 1객체. resize trace 존재. 여러 브라우저 배율 전체 조합은 미완료.'),
34:('부분 확인','placement-browser-wardrobe-build/report.json','패널 drop·Escape·실제 탭 포커스 상실·중복 pointerup·총 발사 격리. engine 출입구/좌석/지지/관리 구역 검사. 동시 사용자 경합 UI 미실행.'),
35:('실제 UI·fixture 부분','wardrobe-browser-final/report.json','실제 계단 보행 뒤 의상방 콘솔 직접 클릭. 밖에서 메뉴 호출 거절. engine 21검사에 actor/장소/편집 세션/PNG/복원·인계 포함. 로그인 계정 연동은 미구현.'),
36:('실제 UI 확인','wardrobe-browser-final/report.json','512px 얼굴 전용 UV, 2D 브러시/지우개/Undo/Redo와 실제 Godot 3D 회전·적용·취소. PNG 헤더/실제 디코드/해시 검증. 두 브라우저에서 초안 비전송과 확정 얼굴·다른 재질 격리 확인.'),
37:('색 편집만','wardrobe-browser-final/report.json','기존 상의/하의/신발 재질 색은 변경 가능. 체형·의상 메시 교체·fitting·collision/camera/손발/좌석 극단 조합은 미구현.'),
38:('세션·같은 브라우저 부분','wardrobe-browser-final/report.json','확정 프로필 실제 두 브라우저 동기화, 같은 브라우저 저장/재접속 확인. 원본 남자 GLB 보존. 계정/다른 기기 연동과 전체 homeworld 프로필 매핑·래스터 복원 미구현.'),
39:('실제 UI 확인','placement-browser-wardrobe-build/report.json','정확한 입장 하단 문구. 표시 문자열 변경/숨김에 roomAdmin과 loaded 상태 동일. 교육 규칙·점수 시스템을 추가하지 않음.'),
40:('이번 미실행',None,'기존 실제 회의실·원본 자료·보드·질문·할 일 코드를 보존. 완결 회의 실제 흐름 미실행.'),
41:('계정 미실행',None,'Google Docs/Slides/Excel 외부 두 계정 원본 동시 편집은 미실행. 열기 버튼을 합격으로 세지 않음.'),
42:('이번 미실행',None,'기존 실제 레이저·보드·발표 경로 보존. 두 화면 지목/페이지 인수 미실행.'),
43:('생활 일부 fixture','retained-living-props.json','수납 원본 물체·경합·세계 복원·서랍·전등 12검사. 전체 요리/식사/욕실/소리 연속 검수는 미실행.'),
44:('실제 UI 확인','retained-v4-browser-wardrobe-build/report.json','한글 DM·수신자 격리·읽음·답장·수정·삭제·실제 파일 SHA 다운로드·PNG·클립보드·취소/이어받기·제공자 이탈 14검사. 초반 20초 timeout은 보존.'),
45:('마이크 미실행',None,'기존 한국어 음성/자막·방송 경로 보존. 실제 마이크·사람·음성 품질 인수 없음.'),
46:('부분 회귀',None,'기존 개인실·복도 확장·고정 교실·짧은 코드 경로 보존. 현재 세 브라우저 입장은 검수했으나 교실/확장/인계 전 과정 미실행.'),
47:('제한된 보정','table-support.json','low_table 매몰만 idempotent 보정하고 근접 지지 소품 동반 이동. 일반 세계 저장/수납 회귀 있음. 의상방 새 구조와 충돌하는 옛 가구는 복원 전 거절하고 현재 세계 보존. 새 전체 건축 좌표·외형 마이그레이션 미구현.'),
48:('미완료',None,'동일 빌드 전체 공간·2–8인·STT/첨부 동시 성능·최종 미술 인수 남음. 해시·클립 수·fixture 통과로 완료 처리하지 않음.')}
N_to_T={1:[1,2],2:[4,8,48],3:[2,5],4:[6],5:[7],6:[9,10,11],7:[12],8:[13],9:[9,15],10:[3],11:[21,22,23,24],12:[25,26,27],13:[16,17,18],14:[19,20],15:[9,19,20],16:[28,29,30,31],17:[8,40,43],18:[1,3],19:[32],20:[33,34],21:[35,38],22:[36],23:[37],24:[35],25:[35],26:[39],27:[39],28:[5,6,7,8,13],29:[9,10,12,19,20],30:[4,6,40],31:[4,6,7,8,43],32:[4,24,27,31,48],33:[40,41,42,43,44,45,46,47],34:[2,9,10,12,34,44,48]}
spec=(D/'master-spec-ko.md').read_text(encoding='utf-8');labels={}
for line in spec.splitlines():
    match=re.match(r'\| ([NT]\d\d) \| ([^|]+) \|',line)
    if match:labels[match[1]]=match[2].strip()
receipt_path=E/'publication/receipt.json'
publication='공개 배포는 `cc2f8fbd-ba33-4601-b716-82bb26422424`인 게시 전 조사 기준이다.'
if receipt_path.exists():
    receipt=json.loads(receipt_path.read_text(encoding='utf-8'))
    publication=f'공개 Build ID `{receipt["buildId"]}` / Pages commit `{receipt["deploymentCommit"]}`. [실제 공개 배포 검수](publication-ko.md).'
    T[1]=('공개 배포 검수','publication/receipt.json','새 공개 Pages에서 88개 파일 bytes/SHA 대조와 실제 WebGL 의상방/설치 조작을 수행했다. 최초 V4 기준과 새 배포의 commit/ref/Build ID를 구분한다. 전체 제품 미술 합격으로 사용하지 않음.')
lines=['# V5 N01–N34 / T01–T48 추적표','','전체 상태: **미완료**. 각 행은 이번에 실제 수행한 범위만 설명한다. 기존 기능이 있다는 사실, fixture 통과, 실제 브라우저 UI, 실제 사람/계정 인수를 구분한다.','',f'현재 로컬 Build ID `{build["buildId"]}` / source digest `{build["source"]["digest"]}`. {publication} 증거가 다른 빌드에서 만들어졌으면 아래 링크의 Build ID가 기준이다.','', '## N 대조표','','| ID | 요구 | 연결된 실제 결과 |','|---|---|---|']
for n,ts in N_to_T.items():
    refs=' · '.join(f'[T{t:02}](#t{t:02}) {T[t][0]}' for t in ts)
    lines.append(f'| N{n:02} | {labels[f"N{n:02}"]} | {refs} |')
lines+=['','## T 실제 결과']
for n,(status,path,detail) in T.items():
    lines += ['',f'### T{n:02}','','**'+status+'** — '+labels[f'T{n:02}']+'. '+detail,'',evidence(path) if path else '이번 실행 증거 없음. 과거 기록을 현재 합격으로 전환하지 않음.']
lines+=['','## 코드와 모델 연결','','| 영역 | 실제 파일 |','|---|---|','| 모델 지지/저장 보정 | [manifest](../../assets/v2/manifest.json), [furniture_support.gd](../../scripts/interaction/furniture_support.gd), [Blender 검사 원본](../../art/v5-table-inspection.blend) |','| 캐릭터 합성/접촉 | [motion_graph.gd](../../scripts/player/motion_graph.gd), [contact_ik.gd](../../scripts/player/contact_ik.gd), [원본 보존 파생 GLB](../../assets/characters/male-animated-v5.glb), [Blender 작업본](../../art/male-character-v5.blend) |','| 좌석/운반 | [seat_contacts.gd](../../scripts/interaction/seat_contacts.gd), [furniture_carry.gd](../../scripts/interaction/furniture_carry.gd), [좌석 계약](../../assets/asset-manifest.json) |','| 관리자 경계 | [room_access.gd](../../scripts/security/room_access.gd), [서명 정책](../../server/admin-policy.mjs), [브라우저 verifier](../../web/room-admin.mjs) |','| 설치 패널 | [placement-panel.mjs](../../web/placement-panel.mjs), [실제 raycast](../../scripts/interaction/placement_pointer.gd), [출입/좌석/지지 검증](../../scripts/interaction/placement_clearance.gd) |','| 의상방·얼굴 | [실제 검수/화면](wardrobe-review-ko.md), [세션/현장 클릭](../../scripts/wardrobe/station.gd), [PNG/재질](../../scripts/wardrobe/appearance.gd), [편집 UI](../../web/wardrobe.mjs) |','| 표시 전용 안내 | [presentation-copy.mjs](../../web/presentation-copy.mjs) |','| 건축 설계만 | [층별/동별 도면](architecture-plan.html), [계획 계약](architecture-plan.json) |','', '대표 화면: [테이블 수리](../../evidence/v5/repair-browser/), [소파 전면](../../evidence/v5/seating-browser-front/seat-1.png), [설치 ray preview](../../evidence/v5/placement-browser-current/01-ray-preview.png). 실제 WebM 경로는 각 report.json의 video/videos 항목에 있다.']
(D/'verification-ko.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('WROTE N34/T48 with explicit incomplete scope',build['buildId'])
