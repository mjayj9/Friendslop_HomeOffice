"""Build Korean audit/traceability documents from explicit implementation notes and current evidence.
Never changes evidence or turns a missing/failed test into a pass.
"""
from pathlib import Path
from datetime import datetime,timezone
import json,re,statistics,sys
sys.stdout.reconfigure(encoding="utf-8")
R=Path(__file__).resolve().parents[1];D=R/'docs/v3';E=R/'evidence/v3'
def read(p,default=None):
    try:return json.loads(p.read_text(encoding='utf-8-sig'))
    except (FileNotFoundError,json.JSONDecodeError):return default
def write(name,text): (D/name).write_text(text.strip()+'\n',encoding='utf-8')
def link(path,label=None):return f'[{label or path}]({(R/path).resolve().as_posix()})'
build=read(E/'build-info.json',{})
cases=[('의자·책·회의·한글·파일 복원','user-flow/report.json'),('교실 동시 입장·인계·재개','session-flow/report.json'),('계단·자기 수면·생활','life-flow/report.json'),('회의 질문·할 일·물리 레이저','tools-flow/report.json'),('공룡 게임기·원격 관전','arcade-flow/report.json'),('가상 음성·방송·욕실·복원','voice-facilities/report.json'),('2/4/8 접속·30분 활동','scale-soak/report.json'),('기본 게임 규칙·캐릭터','gameplay-tests.json'),('권위·득점·피해·광선','authority-physics.json'),('물리 낙하·CCD','physics-lab.json'),('수납·서랍·램프·파일 복원','living-props.json'),('요리·식사·설거지·수면·권한','legacy-interactions.json'),('보드·점유·개인실·명령 검증','legacy-authority.json')]
summary=[]
engine_run=read(E/'engine-final-run.json',{})
for title,file in cases:
    value=read(E/file,{})
    rows=value.get('results',[])
    okay=sum(r.get('passed') is True for r in rows);bad=sum(r.get('passed') is False for r in rows)
    done=bool(value.get('completed')) if file.endswith('/report.json') else bool(rows) and not bad and not value.get('failure')
    summary.append(dict(title=title,file=file,passed=okay,failed=bad,completed=done,buildId=value.get('buildId'),sourceBuildId=engine_run.get('buildId') if engine_run.get('completed') and not file.endswith('/report.json') else None,failure=value.get('failure')))
(E/'verification-summary.json').write_text(json.dumps({'buildId':build.get('buildId'),'generatedAt':datetime.now(timezone.utc).isoformat(),'groups':summary},ensure_ascii=False,indent=2),encoding='utf-8')

write('README.md',f'''
# HomeOffice V3 — 분석·구현·가상 검증

두 MD의 요구를 실제 Godot 코드, Blender 제작 원본, 웹 빌드와 자동 검증에 반영한 작업 기록입니다. 사용자의 최신 범위인 **구현 + 가상 시뮬레이션**을 기준으로 합니다. 실제 사람의 마이크, 외부 계정 공동 편집, 서로 다른 인터넷망, 운영 배포는 이번 완료 판정에 포함하지 않습니다.

## 결과물

- {link('docs/v3/implementation-analysis-ko.md','설계·결함 원인·구현 상세 분석')}
- {link('docs/v3/requirements-traceability-ko.md','R01–R30 / U01–U56 / G01–G16 전수 대조표')}
- {link('docs/v3/verification-report-ko.md','이번 실행 결과·수치·증거·제약')}
- {link('docs/v3/animation-review-ko.md','62개 동작과 전이·접촉 검수 범위')}
- {link('README.md','실행 방법·조작 안내')}

현재 로컬 실행: [HomeOffice V3](http://127.0.0.1:8060/homeoffice/?signal=local). 이 주소는 이 PC에서 실행 중인 개발 서버입니다. 고정 교실은 [교실 링크](http://127.0.0.1:8060/homeoffice/?signal=local&room=classroom)입니다.

## 빌드 기준

| 항목 | 값 |
|---|---|
| Build ID | `{build.get('buildId','미생성')}` |
| 엔진 / 웹 템플릿 | Godot 4.6.1 stable / 같은 버전 |
| 물리 | Jolt, 60 Hz, 1 unit = 1 m |
| 네트워크 프로토콜 / 저장 형식 | 3 / 2 |
| 제작 소스 | Blender 5.2.1 LTS 연결에서 V3 별도 씬·파일 제작 |
| 기준 Git 자료 | PR #1 head `e62360fd45e03e15fe7e2371d204dc30ff35c9ae` |
| 이번 변경 전달 방식 | 현재 작업 폴더의 소스·에셋·실행 빌드. 원격 PR/배포 변경 없음 |

해시와 바이트 크기는 {link('evidence/v3/build-info.json','실제 빌드 매니페스트')}에 있습니다. 과거 `evidence/v2-*`는 회귀 시험의 설계 자료이며 이번 통과 결과로 합산하지 않습니다.

## 읽는 순서

1. 분석에서 원인과 설계 결정을 확인합니다.
2. 요구 대조표에서 각 항목의 구현 파일과 검증 범위를 확인합니다.
3. 검증 보고서에서 자동 실행의 성공·실패·미실행을 확인합니다.
4. 실제 브라우저 캡처와 `.homeworld` 파일로 결과를 재현합니다.

모든 항목을 한꺼번에 ‘완료’로 표시하지 않았습니다. 파일 링크 연동, 엔진 장면 시험, 실제 WebRTC 브라우저 시험, 사람/외부 서비스 검증을 구분했습니다.
''')

write('implementation-analysis-ko.md','''
# 두 문서의 상세 분석과 V3 구현

## 1. 문서의 역할과 이번 작업 범위

`HomeOffice_PR1_Code_Audit_KO.md`는 2026-09-15의 코드·배포 아티팩트 감사입니다. F01–F16은 코드에서 확인한 사실과 해석이며, 당시 상대 캐릭터 렌더링·실제 마이크·WAN 검증이 성공했다는 문서가 아닙니다. 특히 ‘연결된 플레이어 수’와 ‘보이는 캐릭터’가 같지 않다는 지적이 핵심입니다.

`HomeOffice_V3_Repair_And_Completion_Prompt_KO.md`는 이 감사를 30개 최신 요구, 56개 기존 요구의 승계, 16개 검증 묶음으로 확장한 명세입니다. R/U/G는 각각 기능, 보존 범위, 검증 시나리오이며 102개의 서로 다른 신규 기능을 뜻하지 않습니다. 코드에 기능 이름이 있다는 사실과 사용자가 실제 조작할 수 있다는 사실도 구분해야 합니다.

사용자는 문서 분석에 이어 실제 구현을 요청했고, BlenderMCP 연결을 알려 주었으며, 이후 실제 사람·현실 환경 인수 대신 가상 시뮬레이션을 진행하도록 범위를 정했습니다. 따라서 기능 구현·로컬 실행·브라우저/엔진 검증은 수행하며, 첨부 문서에 포함된 운영 배포·외부 계정·실제 사람 시험 지시는 별도의 사용자 실행 요청으로 간주하지 않았습니다.

### 우선순위와 충돌 해결

1. 상대 몸체가 보이지 않는 P0를 먼저 재현했습니다.
2. 의자와 입력·소유권·파일 복원을 수리한 뒤 기능을 확장했습니다.
3. E는 집기/내리기, Q는 던지기, F는 기능 사용으로 통일했습니다. 이전 E 만능 사용/Q 내리기 설명은 갱신했습니다.
4. U46 미로/픽맨은 최신 R16 공룡 러너로 대체했습니다. 오래된 저장 호환 코드는 보존하되 두 게임기 모두 러너를 엽니다.
5. HP와 킬 게이지는 별도 상태로 만들었습니다. 수치 100 HP / 25 피해 / 3초 복귀 / 2초 보호 / KO당 게이지 25는 이번 구현의 기본 설계값입니다.
6. Google/Microsoft 원본 링크와 내장 Yjs 문서는 별도 기능으로 유지했습니다.

## 2. 실제로 찾은 결함과 수정

| 감사/재현 | 실제 원인 또는 관찰 | 수정과 의미 |
|---|---|---|
| F01 상대 이름만 표시 | 남자 GLB 재질의 `alphaMode=MASK`, baseColor alpha=0. 노드·스킨은 존재해도 모든 픽셀이 버려짐 | 원본 바이너리를 보존한 V3 재질 파생본. 이후 세 브라우저에서 몸체 표시를 확인 |
| F02 본 자세 손상 | 원래 rest rotation을 지우는 단순 회전 덮어쓰기, 런타임 sin 보행 | rest 회전 보존, Blender keyframe 62개, AnimationPlayer 전이, 후처리 접촉 IK |
| F03 자기 취침 불가시 | 로컬 lying 메시까지 숨김 | 같은 리깅 몸체를 취침 시 보이고 3인칭 카메라로 이동. 깨면 1인칭 복귀 |
| 의자 낙하 | 의자를 이동 가능한 RigidBody로 바꾸면서 원래 비어 있던 충돌 배열 사용 | 좌판·등받이·하부 충돌체 추가, 점유 중 고정, 비점유 때 실제 물리. E/Q/F 브라우저 회귀 |
| F04 승인 후 총 무반응 | tag가 ready인데 fire는 practice/play만 허용 | Practice 초기화, 220ms 연사 제한, 연습 무제한 탄약, 권한/총구/탄약/상태 설명 |
| F05 실제 피해 없음 | 기존 점수/토스트만 존재 | CombatState에서 피해·KO·복귀·보호·킬/사망·게이지 감소를 관리 |
| F06–F08 과대 공/림과 단순 킥 | 공 반지름 .24/.22m, 림 중심선 .43m, 고정 ID 킥 | 공 .12/.11m, 림 안쪽 .225m, 물리 프로필·회전·실제 득점·등록 공·발 터치 |
| F09 입력 불일치 | 안내/이벤트/기능에 서로 다른 키 의미 | 입력 우선순위와 안내 갱신, 한글 입력 중 이동 차단 회귀 |
| F10 불완전한 방 조명 | 스탠드 기능은 있었으나 방 스위치 없음 | HOME/OFFICE/욕실 회로, 실물 스위치·광원·동기화·저장 |
| F11 생성기 회귀 위험 | `.txt`를 합쳐 `.gd`를 다시 쓰는 생성기 | 해당 조합기를 명시적으로 중단. 런타임은 `.gd`, 제작은 데이터/에셋 스크립트 |
| F12 DOM 전용 레이저 | 발표 캔버스 포인터만 연결 | 실제 소품→물리 광선→표면 로컬 좌표→UV→권한 확인→원격 포인터 |
| F13 문서 탭 전환 시 정지 | document.hidden을 호스트 freeze로 직접 연결 | 의도적인 정지를 제거. 정상 호스트 인계 제공. 브라우저 자체 throttling은 별도 제약 |
| F14 긴 내부 ID 초대 | peer ID를 표시 코드로 사용 | AAA-AAA 표시 코드와 directory alias, URL 입장, 고정 교실 alias 분리 |
| F15 합성 STT와 실제 품질 혼동 | 기존 Whisper 경로는 있었고 6문장 수치는 사람 발화 검증이 아님 | 현재 V3에서 실제 WASM 인식·FPS를 재측정, 늦은 자막 순서/음소거 처리 강화. 사람 정확도 주장은 제외 |
| F16 8브라우저 성능 저하 | 한 PC의 8개 렌더러 부하가 분산된 8인 성능과 다름 | 변경 사물 전송·물리 sleep 유지·효과 풀링, 동일 PC 2/4/8 접속과 30분 시험을 별도 측정 |
| 복원 시 물내림 재생 | 저장된 toggle 상태를 새 이벤트로 오인 | quiet restore와 이벤트 이력 초기화. 네트워크의 새 물내림은 재생 |
| 작은 레이저 집기 실패 | 3cm 물체에 키보드 조준 오차가 충돌체 폭보다 큼 | 작은 레이저/마카만 7cm 조준 여유, 별도 장애물 광선 확인. 물리 크기는 유지 |
| 메뉴 클릭 차단 | 브라우저와 엔진의 포인터 잠금 전환이 중복됨 | 메뉴/도구 열기에 명시적 ui_focus, Godot 입력 해제. 실제 마이크 종료 클릭으로 재검증 |
| 앉은 상태 F 오작동 | 탁자/도구 기능이 V2의 일어서기보다 먼저 실행 | 앉기·취침 종료를 최우선 처리. 빈손 회의석은 R로 자료 열기. 식사 후 설거지까지 회귀 검증 |
| 욕실 모델 겹침 | V2 장식 세면대/변기에 새 시설을 겹쳐 배치 | 기존 건물 파생 GLB에서 448개 삼각형·충돌체 2개만 제거. 새 속이 빈 세면대/변기와 경첩 추가 |

### 상대 표시 결함을 판정한 순서

네트워크 roster → Godot 플레이어 인스턴스 → 남자 mesh/skin → 재질 alpha → 카메라와 실제 픽셀을 분리해 조사했습니다. 따라서 “접속 3명”만으로 가시성 수리를 판정하지 않았습니다. `baseline`, `after-material-fix`, `integrated-three` 캡처는 각각 수정 전과 수정 후 실행 자료입니다.

## 3. 코드 구조와 권위

```mermaid
flowchart LR
  Input[키보드·마우스·HTML UI] --> Command[actor / epoch / requestId / seq]
  Command --> Host[Godot 호스트 판정]
  Host --> Ledger[중복 요청 응답 캐시]
  Host --> Physics[Jolt 60 Hz · 충돌과 소유권]
  Host --> Systems[전투 · 공 규칙 · 시설]
  Physics --> Snapshot[전체 플레이어 + 사물 변경분]
  Systems --> Snapshot
  Snapshot --> Peer[WebRTC 참가자 시각 보간]
  Blender[Blender 동작·시설] --> GLB[V3 GLB와 manifest]
  GLB --> Visual[몸체·애니메이션·IK]
  Peer --> Visual
  Host --> Save[검증된 homeworld 파일]
```

새 책임은 `scripts/combat`, `scripts/sports`, `scripts/physics`, `scripts/player`, `scripts/interaction`, `scripts/world`, `scripts/core`와 웹의 invitations/directory/document-registry/broadcast/caption-policy/state-codec/build-guard로 나눴습니다. `scripts/v3/world.gd`가 통합하고 검증된 기존 `scripts/v2/world.gd`를 상속합니다.

이는 생성기 이중 원천을 없애고 신규 로직을 분리한 점진적 전환입니다. 기존 V2 world/bridge가 완전히 작은 모듈로 해체되었다고 주장하지 않습니다. 기존 수납·요리·보드·개인실을 한 번에 다시 생성하는 회귀를 피하기 위해 유지한 부분입니다.

### 조작 명령

- actor는 수신 연결의 실제 ID와 일치해야 합니다. payload에 적힌 호스트 ID를 신뢰하지 않습니다.
- epoch는 현재 세션과 일치해야 합니다. 호스트가 바뀌면 새 epoch를 사용합니다.
- requestId는 동일 epoch/actor에서 한 번 처리하고 최대 128개 응답을 보관합니다. 재전송은 저장된 결과를 돌려줍니다.
- seq, 크기, 데이터 타입, 동작 목록을 확인합니다. 거절은 accepted=false/reason/stateRevision을 반환합니다.
- 집기·앉기·시설 사용·배치·발사는 거리/광선/가림/점유/구역/권한을 호스트가 확인합니다.
- PeerJS 연결별 크기·속도·인원 제한과 명시적 baseline 재요청을 유지합니다.

### 상태 복제

플레이어 목록은 매 상태에 포함하고, 사물은 변경된 항목과 삭제 ID만 보냅니다. 위치/회전은 변경 감지에 1mm/.001rad, 속도는 .01 단위 양자화를 사용합니다. 실제 전송값 자체는 원래 수치입니다. 120 tick마다 기준 상태를 보내며 기준 tick이 없으면 재요청합니다. 참가자 로컬 시계가 호스트 tick을 덮어쓰지 않게 했습니다.

이 구조는 호스트 권위의 물리 상태를 복제합니다. 서로 다른 장치에서 완전히 결정적인 lockstep 물리라는 뜻이 아닙니다.

## 4. 캐릭터·접촉·생활

사용자 프로젝트의 실제 남자 mesh를 유지했습니다. 리깅은 13개 본이며 손가락/손목 전용 본은 없습니다. 새 캐릭터로 대체하지 않았고, 원본 GLB 및 기존 Blender 파일은 보존했습니다. `art/male-character-v3.blend`, `male-animated-v3.glb`에 62개의 실제 Action/클립을 만들었습니다.

클립은 root motion을 끄고 실제 수평 속도와 방향, 앉기/취침, 들고 있는 물건, 제스처와 활동에 따라 전이합니다. 몸체 이동은 CharacterBody 제어기가 맡고 IK는 최종 시각 본 자세만 수정합니다. 발은 지면 광선과 접촉 유지점을 사용하고, 손은 실제 들고 있는 물체의 그립 위치를 목표로 합니다. 리깅 길이 밖의 손 목표는 제한하며 실제 관찰에서 약 8cm 잔차가 있었으므로 모든 자세의 손/발 완전 접촉을 판정하지 않았습니다.

의자·상자·책·마카·도구·이동 가능한 책상/스탠드를 실제로 들고 놓고 던집니다. 무게에 따라 이동 속도와 던지는 속도가 달라집니다. 회의실 컴퓨터가 올라간 두 책상은 고정 설비로 설명하고 다른 일반 책상은 집을 수 있습니다. 점유 중이거나 수납물이 있는 가구의 무단 이동을 막습니다.

수면은 F 진입→같은 몸체의 bed/sleep 동작→본인 3인칭→F 깨기→안전한 출구 위치→1인칭으로 연결됩니다. 실제 계단을 올라 침대에 가고 다시 내려오는 브라우저 시험으로 확인했습니다.

욕실은 새 hollow 세면대/변기, 경첩 뚜껑, 수도의 물 메시와 반복 소리, 물내림의 제한된 재생, 회전 환기 팬과 스위치, 광원을 제공합니다. 물줄기와 물내림은 게임용 시각/음향 시뮬레이션이며 유체 역학을 구현한 것은 아닙니다.

## 5. 물리와 경기

| 항목 | 현재 구현 |
|---|---|
| 농구공 | 반지름 .12m, 질량 .62kg, CCD, friction .68, bounce .72 |
| 축구공 | 반지름 .11m, 질량 .43kg, CCD, friction .68, bounce .48 |
| 림 | 중심선 .245m, 안쪽 .225m, 방사 두께 .04m. 원본 48개 충돌체 함께 수정 |
| 슛 | 호스트가 누른 시간 확인, 속도/각도 상한, 실제 backspin 각속도, 자동 골대 흡인 없음 |
| 드리블 | 중력·바닥 반발로 튀고, 손 높이에서 제한된 하향 impulse. 수평 추종 힘·속도 제한 |
| 스틸 | 빈손·거리·시선·드리블 노출 높이·가림·재사용 대기 검사 후 loose ball |
| 축구 터치 | 근처의 등록된 공, 160ms 이상 터치 간격, 제한된 impulse. 손 점유 없이 패스/충전 슛 |
| 득점 | 농구는 유효 중심의 위→아래 통과 1회 2점, 축구 골라인 통과 1점 후 중앙 재개 |
| 경기 공 | 자유 배치 공도 동작. 정식 play 중에는 지정 경기 공만 점수에 반영 |
| 그물 | 공의 실제 위치/속도에 반응하는 시각 그물. 점수나 공의 힘을 바꾸지 않음 |
| 전투 | 100 HP, 명중 25 피해, KO 3초 후 복귀, 2초 보호, 킬 +25 게이지, 10초 무킬 후 초당 8 감소 |

숫자는 이 게임의 튜닝값입니다. 프로 스포츠 전체 규칙/물리 재현으로 표현하지 않습니다. 간단한 팀 배정은 청팀 +X, 주황팀 -X 공격이며 농구는 모두 2점입니다. 경기 시작/제한 시간/결과/재시작 경로는 기존 라운드 UI와 통합했습니다.

별도 `physics_lab.tscn`에는 평지·계단·경사·낮은 천장·문·책상과 낙하 공·얇은 벽이 있습니다. 검증은 실제 엔진에 초기 조건을 배치한 시험과 실제 브라우저에서 걸어간 시험을 구분합니다. 모든 교행·모든 가구 조합을 전수 물리 검증했다는 의미는 아닙니다.

## 6. 회의와 외부 자료

회의실은 8개 좌석과 책상, 실제 모니터·키보드·탁상 마이크, 발표 스크린, 보드, 천장 흡음 패널을 갖춘 OFFICE 구역입니다. 책상 F에서 다음 기능으로 연결됩니다. 이미 앉아 있을 때 F는 일어서기를 우선하고, 빈손 회의석에서는 R로 자료를 열고, 책을 들고 앉아 있으면 R로 읽습니다.

- Google 검색: 사용자의 검색어를 인코딩해 Google 원본 창을 엽니다. 검색어를 월드의 공개 사물 상태에 넣지 않습니다.
- Google Docs/Slides/Sheets, Microsoft OneDrive/SharePoint Excel 원본: 허용된 URL을 검증해 같은 원본 참조를 참가자에게 공유합니다. 팝업이 막히면 안내하고 원본 창을 엽니다.
- Yjs/Quill 보고서, 브레인스토밍 메모·투표, 마인드맵과 순환 금지, 공동 의제/결론, 손들기, 타이머를 보존했습니다.
- 질문 대기열과 담당자별 후속 할 일, 원격 완료/다시 열기/삭제를 추가했습니다. Yjs 연산과 저장 파일에 들어가며 항목 수·문자열·타입을 검증합니다.
- PDF/이미지는 실제 원본 바이트를 전송·검증·저장하고 페이지/주석/발표자 권한을 공유합니다. PPTX는 외부 도구에서 PDF로 내보낸 파일을 사용합니다.

문서 URL을 공유하는 기능은 구현되어 있지만 사용자 계정의 Google/Microsoft 공유 권한을 대신 발급하지 않습니다. 내장 편집기를 Google Docs/Excel이라고 부르지 않습니다. 외부 계정에서 실제 두 사람이 공동 편집하는 인수는 사용자가 지정한 이번 가상 범위 밖입니다.

### 물리 레이저

작은 실제 소품을 E로 들고 클릭을 유지하면 손의 위치에서 광선을 쏩니다. 첫 물리 충돌이 발표 표면일 때만 mesh의 local 좌표와 크기로 UV를 계산합니다. 웹은 발표 권한·현재 자료·페이지·순서를 확인하고 두 브라우저에 같은 점을 그립니다. 입력/통신이 끊기면 400–500ms 내에 지웁니다. 벽/사물 뒤 화면을 통과하지 않습니다.

## 7. 초대·교실·저장 정책

AAA-AAA 코드는 내부 peer ID와 분리된 표시용 alias입니다. 코드 자체 또는 복사한 URL을 붙여넣어 입장할 수 있고 하위 배포 경로를 보존합니다. 교실은 `room=classroom` 고정 alias를 사용합니다.

빈 교실에 동시에 들어오면 directory 이름 선점으로 한 사람만 호스트가 됩니다. 참가자는 이미 열린 호스트를 조회합니다. 정상 인계는 barrier→체크포인트 검증→확인→새 epoch→고정 alias 재선점으로 처리합니다. 최초 입장자/호스트는 교사 인증을 받은 사람이 아닙니다. 자율 교실에서는 무기·방송 관리자 권한을 부여하지 않습니다.

모두 떠나면 링크는 유지되지만 월드를 영구 보존하는 상시 서버는 없습니다. 빈 교실 재입장은 새로운 세션입니다. 보존이 필요하면 `.homeworld`를 내보내고 빈 호스트에서 가져옵니다. 강제 종료는 마지막 확인 복구본과 시점을 안내합니다. 동일 고정 주소와 영구 저장을 같은 기능으로 혼동하지 않습니다.

파일은 기존 schema 2를 유지하면서 시설 상태, 공식 문서 참조, 수동 공지를 허용 목록에 추가했습니다. Yjs 질문/할 일은 문서 update에, PDF/이미지는 첨부에 들어갑니다. transient 손/좌석 점유, 옛 연결 ID 권한, 자동 재발사 상태는 복원하지 않습니다. 제한 크기·CRC/SHA256·ID·참조·타입·허용 자산·경로를 확인하고 잘못된 파일은 현재 세계를 바꾸기 전에 거절합니다.

## 8. 음성·자막·방송

기본 마이크는 꺼져 있고 사용자가 직접 켭니다. V 눌러 말하기/열린 마이크/음소거/완전 종료를 제공합니다. 근거리/같은 물리 구역/허가된 방송석 모드는 실제 RTC 전송 경로와 음량 처리에 연결됩니다. 차단 사용자와 전달 범위를 검사합니다.

방송은 실제 콘솔 근처, 허가된 사용자, 한 명의 활성 발화자 조건을 사용합니다. 세션/HOME/OFFICE/PLAY 범위를 선택하고 ON AIR를 표시합니다. 방송 중 다른 대화와 효과음의 ducking 계수는 .35입니다. 콘솔을 떠나거나 권한을 잃으면 종료합니다. 수동 공지 최대 32개는 별도로 저장합니다.

한국어는 기존 browser/local recognition 선택과 Whisper WASM 경로를 보존했습니다. generation/utterance/sequence로 늦게 온 중간 결과가 최종 자막을 덮지 못하고 mute 이후 이전 결과를 폐기합니다. 브라우저 외부 인식으로 몰래 전환하지 않습니다. 합성 음성의 현재 실행 결과와 과거 CER/WER를 섞지 않으며 실제 사람의 정확도를 주장하지 않습니다.

## 9. 빌드·배포·보존

빌드마다 UUID와 엔진/템플릿/프로토콜/자산/저장 형식, 파일 바이트·SHA256을 생성합니다. 시작 전에 JS/PCK/WASM 등 핵심 5개 파일의 해시를 검사하고 Godot 내부 build ID와 웹 build ID도 맞춥니다. 혼합 파일을 주입한 별도 브라우저 시험에서 입장 전에 차단했습니다. 이는 모든 CDN 캐시의 원자적 배포를 보장하는 배포 시스템은 아닙니다.

기존 소스는 `evidence/v3/source-before.zip`, 입력 문서는 별도 복사/해시로 남겼습니다. V3 남자·건물·농구장·시설은 새 파일입니다. root의 다른 프로젝트와 `deployment/Friendslop_HomeOffice` 배포 클론을 변경하지 않았고 운영 배포/PR 병합은 하지 않았습니다.

## 10. 근거로 사용한 공식 자료

- [glTF 2.0 명세](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html): alphaMode와 재질의 불투명도 처리.
- [Godot SkeletonModifier3D](https://docs.godotengine.org/en/4.6/classes/class_skeletonmodifier3d.html): 애니메이션 뒤 시각 본 보정 구조.
- [Godot Skeleton3D](https://docs.godotengine.org/en/4.6/classes/class_skeleton3d.html): 본의 rest/pose 공간.
- [Godot 4.6](https://godotengine.org/releases/4.6/): 선택한 엔진 계열과 기능 기준.
- [Google 파일 공유 안내](https://support.google.com/docs/answer/2494822): 원본 문서의 공유 권한은 제공 서비스에서 설정.

API가 있다는 사실만으로 게임 기능의 성공을 판단하지 않았습니다. 구현 판단의 근거는 별도 검증 보고서의 이번 실행 자료입니다.
''')

reqs=[
('R01','현재 PR·빌드·캐시','tools/write_build_info.py; web/build-guard.mjs','session-flow/report.json','로컬 빌드/혼합 핵심 파일 차단 검증. 운영 서버 최신 응답/배포는 이번 범위 밖'),
('R02','상대 몸체 가시성','tools/repair_character_materials.py; scripts/v2/avatar.gd','integrated-three/; user-flow/report.json','실제 3브라우저 화면과 2인 인스턴스. 실제 WAN 제외'),
('R03','실제 남자·Blender 동작','art/male-character-v3.blend; assets/characters/male-animated-v3.glb','gameplay-tests.json; life-flow/report.json','62클립 로딩·일부 실제 동작 검증. 모든 접촉의 미술 검수는 별도'),
('R04','발·손·그립','scripts/player/contact_ik.gd; scripts/v2/avatar.gd','user-flow/report.json; life-flow/report.json','실제 속도 전이·IK 적용. 13본 제약과 일부 손 목표 잔차 있음'),
('R05','물리·제어기','scripts/physics; scripts/sports/ball_profile.gd','physics-lab.json; authority-physics.json; dribble.json','낙하·반발·고속 벽 관통·계단·소품 검증. 모든 교행 조합 전수 시험 아님'),
('R06','생성기 중단·책임 분리','tools/assemble_v2.py; scripts/v3; web/*-policy.mjs','build-final.log; node-tests.log','신규 시스템 분리·단일 .gd 원천. 기존 world/bridge의 전면 해체는 남아 있음'),
('R07','자유사격·연사·사유','scripts/v3/world.gd; scripts/combat/toy_effects.gd','gameplay-tests.json; authority-physics.json','실제 엔진 발사/광선·권한 검증. 전투 UI 전체를 8명이 플레이한 시험 아님'),
('R08','HP·KO·게이지','scripts/combat/combat_state.gd; web/gameplay-hud.mjs','gameplay-tests.json; authority-physics.json','4회 명중 KO·단일 킬·복귀 보호·게이지 감소'),
('R09','농구 조작 루프','scripts/v3/world.gd; scripts/sports/match_rules.gd','dribble.json; authority-physics.json; gameplay-tests.json','실제 반발 드리블·충전·스틸·패스. 사람의 경기 조작감 제외'),
('R10','스핀·림·득점','tools/repair_court_rims.py; scripts/sports/hoop_feedback.gd','court-rim-repair.json; authority-physics.json','실제 각속도·수정 충돌체·중복 득점 차단. 그물은 시각 반응'),
('R11','발로 축구','scripts/v3/world.gd; scripts/sports/match_rules.gd','authority-physics.json','E 차단·발 터치·패스·골 중앙 재개·추가 공 등록'),
('R12','HOME/OFFICE/PLAY','assets/v2/layout.json; assets/v2/house-v3.glb','life-flow/report.json; voice-facilities/report.json','실제 분리 평면·재료·동선·음성 범위. 물리 음향실 해석 아님'),
('R13','건축 마감','assets/v2/house-v3.glb; art/campus-details-v3.blend','life-flow/report.json; house-fixture-repair.json','계단·난간·문·창·천장·가구. 모든 신체 크기 교행 시험 아님'),
('R14','E/Q/F/클릭 입력','scripts/v3/world.gd; web/key-bindings.mjs','user-flow/report.json; tools-flow/report.json','의자/책/레이저 실제 조작, 한글 UI 중 이동 차단'),
('R15','책·가구·조명','scripts/v2/world.gd; scripts/world/campus_details.gd','user-flow/report.json; living-props.json; authority-physics.json','수납·서랍·램프 엔진 회귀, 회로 추가. 모든 가구 조합의 브라우저 전수 인수는 아님'),
('R16','공룡 러너','web/arcade-rules.mjs; web/runner-renderer.mjs; web/arcade.mjs','arcade-flow/report.json','자체 그림·물리/입력·관전·결과·최고점. Chrome 원본 자산 사용 아님'),
('R17','실제 검색·컴퓨터','web/document-registry.mjs; scripts/world/campus_details.gd','node-tests.log; user-flow/report.json','Google 원본 검색/자료 창. 검색 결과를 자체 편집기에 흉내내지 않음'),
('R18','본인 3인칭 취침','scripts/v2/avatar.gd; scripts/v3/world.gd','life-flow/report.json','실제 계단 접근·F 취침·몸체 표시·F 깨기'),
('R19','욕실 시설','art/refine_v3_bathrooms.py; scripts/world/campus_details.gd','voice-facilities/report.json; authority-physics.json','뚜껑·수도·물내림·환기·동기화·복원'),
('R20','회의실 완성','art/author_v3_facilities.py; web/collaboration-source.mjs','tools-flow/report.json','8석/업무 설비/발표/질문·할 일. 전문 음향 시뮬레이션 아님'),
('R21','Docs·Slides·Excel 원본','web/document-registry.mjs','node-tests.log; user-flow/report.json','원본 URL 검증·공유·열기 구현. 실제 두 계정 편집은 사용자 지정 범위 밖'),
('R22','물리 레이저','scripts/v3/world.gd; web/presentation.mjs','tools-flow/report.json; authority-physics.json','실제 집기·광선·같은 UV·권한·가림·만료'),
('R23','한국어·음성','web/captions.mjs; web/caption-policy.mjs; web/local-stt.mjs','stt-browser.json; voice-facilities/report.json; node-tests.log','가상 RTP/자막 정책/합성 인식 결과. 사람·실마이크 품질은 제외'),
('R24','AAA-AAA 코드','web/invitations.mjs; web/session-directory.mjs','user-flow/report.json; node-tests.log','실제 두 브라우저 코드 입장과 형식 검증'),
('R25','초대 URL','web/invitations.mjs; web/bridge.mjs','node-tests.log; session-flow/report.json','하위 경로/코드/교실 URL 해석. 외부망 도달성 보장 아님'),
('R26','고정 교실 카드','web/shell.html; web/session-directory.mjs','session-flow/report.json','같은 고정 alias에 입장'),
('R27','빈 방·경합·인계·재개','web/session-directory.mjs; web/handoff.mjs; web/bridge.mjs','session-flow/report.json','동시 선점·정상 인계·강제 종료·빈 재개. 상시 영구 서버 없음'),
('R28','방송실','web/broadcast.mjs; scripts/world/campus_details.gd','voice-facilities/report.json; node-tests.log','콘솔 접근·승인·범위·실제 가상 RTP·ducking·공지 저장. 사람 발화 제외'),
('R29','기존 전체 기능·복원','scripts/v2/world.gd; web/save-v2.mjs; web/collaboration-source.mjs','user-flow/report.json; tools-flow/report.json; scale-soak/report.json; legacy-interactions.json; legacy-authority.json; living-props.json','기존 공간·생활·Yjs·발표 보존. 요리/식사/설거지/수납/보드/점유 새 엔진 회귀. 옛 V2 로그는 합산 안 함'),
('R30','통합 인수','tests/v3-*.mjs; tests/v3-*.gd','verification-summary.json; scale-soak/report.json','가상 엔진/실제 브라우저 범위. 사람·WAN·운영 배포는 이번 범위 밖')]
lines=['# 요구사항 전수 대조','', '각 행은 구현 경로와 실제 검증 범위를 연결합니다. 시험의 최종 성공 여부와 실행 빌드는 `verification-report-ko.md`를 기준으로 합니다. 구현 경로 존재를 자동 통과로 취급하지 않습니다.','', '## R01–R30 최신 요구','', '| ID | 요구 | 구현 | 증거 | 판정 범위·남은 제약 |','|---|---|---|---|---|']
for rid,name,impl,evidence,scope in reqs:
    files='; '.join(link(p,p) if (R/p).exists() else f'`{p}`' for p in impl.split('; '))
    ev='; '.join(link('evidence/v3/'+p,p) if (E/p).exists() else f'`{p}` (아직 결과 없음)' for p in evidence.split('; '))
    lines.append(f'| {rid} | {name} | {files} | {ev} | {scope} |')
u_map={1:'R01,R12',2:'R12,R29',3:'R06',4:'R02,R24',5:'R29',6:'R29',7:'R03,R13',8:'R05',9:'R03',10:'R03',11:'R03',12:'R07,R08',13:'R09,R10',14:'R23',15:'R23',16:'R23',17:'R23,R28',18:'R23',19:'R23',20:'R14,R29',21:'R14,R15',22:'R14,R20',23:'R07',24:'R08',25:'R15',26:'R14,R20',27:'R05,R14',28:'R14',29:'R14',30:'R14,R20',31:'R07',32:'R12,R29',33:'R20',34:'R20,R29',35:'R20,R29',36:'R20,R29',37:'R20,R21',38:'R21,R22',39:'R20',40:'R29',41:'R13,R29',42:'R12,R29',43:'R09,R10',44:'R11',45:'R07,R12',46:'R16',47:'R16',48:'R18',49:'R29',50:'R29',51:'R05,R29',52:'R23,R29',53:'R12',54:'R06',55:'R03,R13',56:'R13,R19'}
source=(D/'HomeOffice_V3_Repair_And_Completion_Prompt_KO.md').read_text(encoding='utf-8')
lines+=['','## U01–U56 기존 요구의 승계','', '같은 기능을 최신 R 요구에 연결합니다. “승계”는 삭제하지 않았다는 의미이며, 최신 브라우저 전수 시험 완료를 뜻하지 않습니다.','', '| ID | 원문 요지 | V3 연결 | 처리 |','|---|---|---|---|']
for match in re.finditer(r'^\| U(\d{2}) \| ([^|]+) \|',source,re.M):
    num=int(match[1]);note='구현 보존·최신 연결 항목의 검증 범위 적용'
    if num==3:note='프로젝트 삭제 없이 결함 수리·점진적 책임 분리'
    if num==10:note='기존 실제 남자 원본 발견·사용; 추가 업로드 요청 없음'
    if num==46:note='최신 지시에 따라 공룡 러너로 대체'
    if num in [14,15,16,17,18,19,52]:note='음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외'
    if num in [37,38]:note='내장 공동 도구 보존 + 실제 서비스 원본 참조; 계정 편집 제외'
    if num in [20,26,27,30,34,35,36,49,50,51]:note='기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님'
    lines.append(f'| U{num:02} | {match[2].strip()} | {u_map[num]} | {note} |')
groups=[('G01','로컬 build ID·혼합 PCK 차단','session-flow/report.json','운영 서버 캐시/CDN 배포 제외'),('G02','3브라우저 몸체·2인 행동','integrated-three/; user-flow/report.json','전체 양방향 사람 영상·WAN 제외'),('G03','62클립·IK·취침·그립','gameplay-tests.json; life-flow/report.json','모든 전이·접촉 미술 품질 완전 인수 아님'),('G04','의자/책/레이저 E/Q/F·한글','user-flow/report.json; tools-flow/report.json','기존 모든 소품 조합 전수 아님'),('G05','낙하/CCD·계단·의자·물리 광선','physics-lab.json; authority-physics.json','교행/모든 체형/복잡한 더미는 확대 검증 가능'),('G06','Practice·연사·실제 광선 피해·방패','gameplay-tests.json; authority-physics.json','엔진 제어 초기 조건 시험'),('G07','반발 드리블·스틸·슛·득점','dribble.json; authority-physics.json','엔진 제어 초기 조건 시험; 사람 경기 조작감 제외'),('G08','손 집기 차단·발 패스·골·추가 공','authority-physics.json','엔진 제어 초기 조건 시험'),('G09','원본 서비스 참조 검증·공유·열기','node-tests.log; user-flow/report.json','실제 별도 계정 두 명 편집은 범위 밖'),('G10','질문/할 일 공동 처리·원본 PDF·3D 레이저','tools-flow/report.json; authority-physics.json','보드 변경/undo/경합은 legacy-authority.json에서 추가 확인. 모든 Yjs 조합 전수 아님'),('G11','계단·취침·방송석·욕실·컴퓨터','life-flow/report.json; voice-facilities/report.json; legacy-interactions.json; living-props.json','요리/식사/설거지/수납은 새 엔진 시험 추가. 최신 모든 조합의 브라우저 전수 인수 아님'),('G12','가상 RTP·전달 범위·종료·방송·자막 정책','voice-facilities/report.json; stt-browser.json; node-tests.log','실제 사람/마이크/잡음 환경 정확도 제외'),('G13','동시 교실 입장·고정주소 인계·재개','session-flow/report.json','정적 링크와 영구 서버는 구별'),('G14','회의/공지/시설/개인실 파일 복원','user-flow/report.json; voice-facilities/report.json; scale-soak/report.json','현재 한 PC의 독립 브라우저/프로세스 범위'),('G15','실제 게임기·점프/duck·결과·관전·종료','arcade-flow/report.json','자체 러너 구현'),('G16','2/4/8 접속·30분 활동·재입장','scale-soak/report.json','실행 완료/시간/성능은 검증 보고서 확인. WAN/실제 Docs 계정 제외')]
lines+=['','## G01–G16 검증 묶음','', '| ID | 이번 구현·시험 범위 | 증거 | 해석 |','|---|---|---|---|']
for gid,scope,ev,limit in groups:lines.append(f'| {gid} | {scope} | {ev} | {limit} |')
write('requirements-traceability-ko.md','\n'.join(lines))

manifest=read(R/'assets/characters/animation-manifest-v3.json',{})
lines=['# 캐릭터 동작·전이·접촉 기록','', '실제 남자 GLB의 13본 구조에 Blender Action 62개를 제작했습니다. 전체 클립의 import/이름/재질은 엔진 시험으로 확인했습니다. 모든 클립의 접촉을 사람이 세밀하게 검수한 것으로 표시하지 않습니다.','', '## 전이 정책','', '| 상황 | 선택 원리 |','|---|---|','| 걷기/달리기 | 실제 수평 속도와 캐릭터 기준 이동 방향. 전후좌우 분기·속도별 재생률 |','| 정지/출발/회전 | 이전 속도와 현재 속도, 시점 변화로 start/stop/turn 전이 |','| 점프/착지 | 바닥 접촉과 수직 속도, jump/air/land |','| 집기/던지기/도구 | 호스트가 확정한 gesture와 만료 시각, holding kind |','| 앉기/수면 | seat/posture와 local sleep camera. 동일 리깅 몸체 사용 |','| 회의/방송 | 복제된 activity, 앉은 상태의 laptop/meeting, 마이크 앞 broadcast |','| 그립/발 | AnimationPlayer 뒤 SkeletonModifier3D. 실제 사물·지면 좌표 목표, 길이 제한 |','', 'Root motion은 사용하지 않습니다. CharacterBody 이동에 애니메이션 이동을 중복 합산하지 않습니다. 손목/손가락 전용 본이 없어 forearm 끝을 손 기준으로 사용하며 정밀 접촉은 제한됩니다.','', '## 실제 클립 목록','', '| 클립 | 길이(초) | 루프 | root motion | 제작·검증 수준 |','|---|---:|---|---|---|']
for c in manifest.get('clips',[]):lines.append(f"| {c['name']} | {c.get('seconds','-')} | {'예' if c.get('loop') else '아니오'} | {'예' if c.get('rootMotion') else '없음'} | Blender 키프레임 + 엔진 로딩 확인; 개별 접촉 품질 전수 인수 아님 |")
lines+=['','실제 브라우저에서 확인한 동작은 `user-flow`의 앉기/집기/던지기/책, `life-flow`의 보행/계단/취침/깨기, `tools-flow`의 물리 레이저, `voice-facilities`의 방송/스위치 사용입니다. 스포츠·전투의 값과 광선은 엔진 시험에서 별도로 확인했습니다.']
write('animation-review-ko.md','\n'.join(lines))

lines=['# 이번 실행 검증 보고서','',f"최종 작업 빌드: `{build.get('buildId','미생성')}`. 보고서 생성: {datetime.now(timezone.utc).isoformat()}.",'', '## 환경과 증거 구분','', '- 실제 브라우저 시험: 독립 Chromium 프로세스, 실제 WebGL/WASM, 키보드·마우스·HTML 컨트롤, 실제 loopback PeerJS/WebRTC. 진단값은 읽어서 확인하며 위치를 주입하지 않습니다.','- 엔진 시험: Godot/Jolt 실제 물리 장면에 재현 가능한 초기 위치·속도·명령을 설정합니다. 사람 플레이로 표현하지 않습니다.','- 가상 마이크: Chromium 생성 신호의 실제 RTP 수신. 한국어 합성 음성: Microsoft Heami 입력을 실제 Whisper WASM worker가 인식합니다.','- 과거 V2 로그는 이번 성공 수에 포함하지 않습니다. 최종 빌드와 다른 Build ID의 시험은 같은 작업 중 앞선 빌드의 근거로 남깁니다. 관련 코드 변경이 없더라도 같은 해시로 재실행했다고 표현하지 않습니다.','', '## 자동 실행 결과','', '| 묶음 | 통과 | 실패 | 실행 완료 | 실행 Build ID | 증거 |','|---|---:|---:|---|---|---|']
for r in summary:lines.append(f"| {r['title']} | {r['passed']} | {r['failed']} | {'예' if r['completed'] else '아니오 / 진행·결과 확인 필요'} | `{r['buildId'] or ('동일 소스: '+r['sourceBuildId'] if r.get('sourceBuildId') else '엔진 시험/기록 없음')}` | {link('evidence/v3/'+r['file'],'JSON')} |")
run=read(E/'engine-final-run.json',{})
if run:lines += ['',f"엔진 회귀 일괄 실행 완료={run.get('completed',False)}, 대응 build ID `{run.get('buildId')}`, 소스 digest `{run.get('sourceDigest')}`. {link('evidence/v3/engine-final-run.json','실행 시각·종료 코드 기록')}"]
lines += ['', '장시간 시험 이후 최종 변경: '+link('evidence/v3/final-build-changes.json','수정 범위와 재검증 기록')+'.']
lines += ['', '빌드별 파일 해시는 '+link('evidence/v3/builds','보존한 빌드 manifest')+'에서 확인합니다. 최종 빌드는 runtime .gd/scene/asset/web 파일별 SHA256과 전체 digest를 함께 기록합니다. 빌드 ID 주입 파일과 import 캐시는 digest에서 제외합니다.']
node=(E/'node-tests.log').read_text(encoding='utf-8') if (E/'node-tests.log').exists() else ''
lines+=['',f"Node 규칙/저장/초대/방송/자막/상태 복제 시험: {next((l.strip() for l in node.splitlines() if ' pass ' in l),'결과 없음')}; {next((l.strip() for l in node.splitlines() if ' fail ' in l),'결과 없음')}. {link('evidence/v3/node-tests.log','전체 로그')}"]
dribble=read(E/'dribble.json',{})
if dribble:lines+=['','## 실제 드리블 측정','',f"7초, 420회 물리 tick. 통과={dribble.get('passed')}, 반발 {dribble.get('bounces')}회, 공 중심 최저 {dribble.get('minY',0):.3f}m / 최고 {dribble.get('maxY',0):.3f}m, 최대 속도 {dribble.get('maxSpeed',0):.3f}m/s. 수직 위치를 애니메이션으로 주입하지 않았습니다."]
soak=read(E/'scale-soak/report.json',{})
lines+=['','## 2·4·8 접속과 장시간 활동','', '낮음 그래픽, 호스트 1280×720 / 참가자 640×360. '+link('evidence/v3/test-machine.json','실제 시험 PC 사양')+'.']
if soak:
    lines += [f"완료={soak.get('completed',False)}. 계획 활동 {soak.get('plannedActiveSeconds')}초 / 기록된 경과 {soak.get('elapsedActiveSeconds',0):.1f}초, 입력 활동 {soak.get('loops',0)}회, 재입장 {soak.get('rejoins',0)}회."]
    lines += ['', '기록된 경과 시간은 마지막 내보내기/복원 시간도 포함합니다. 30분 활동 도중 계획된 두 차례 재입장 구간에서는 일시적으로 7개 참가자가 연결됩니다. 8명이 다른 PC에서 플레이한 시험은 아닙니다.']
    savings=[]
    rows=[c for s in soak.get('samples',[]) if 'elapsedSeconds' in s for c in s.get('clients',[]) if c.get('performance',{}).get('fps')]
    if rows:
        fps=[c['performance']['fps'] for c in rows];raf=[c['raf']['p95'] for c in rows if c.get('raf',{}).get('p95')]
        savings=[c.get('replication',{}).get('savedPercent') for c in rows if c.get('host')];savings=[x for x in savings if x is not None]
        lines += [f"동일 PC의 8개 렌더러 표본 FPS 중앙값 {statistics.median(fps):.1f}, 최저 {min(fps)}, 최고 {max(fps)}. 각 클라이언트의 최근 rAF 표본 p95 중앙값 {statistics.median(raf) if raf else 0:.1f}ms.", '', '이 수치는 분산된 8명 PC의 프레임률이 아닙니다. rAF 간격에는 브라우저 스케줄링이 포함됩니다. Godot fps 표본도 전체 프레임 p95와 동일하지 않습니다. 기능 안정성과 성능 목표 달성 여부를 구분합니다. 최저 표본이 30 미만이면 지속적인 30 FPS를 보장한 시험으로 해석하지 않습니다.']
        if statistics.median(fps)<30:lines+=['','**이 PC에서 동시 8렌더러 30 FPS 목표는 달성하지 못했습니다.** 기능 시험 통과가 성능 목표 통과를 뜻하지 않습니다.']
    if savings:lines += ['',f"호스트 상태 복제 통계의 누적 절감률 중앙값 {statistics.median(savings):.1f}%. 매번 전체 사물 상태를 전송했을 때의 추정 바이트와 실제 변경분 메시지 바이트를 비교한 값이며, 전체 WebRTC/음성 트래픽 절감률은 아닙니다."]
    if soak.get('failure'):lines+=['','실패/중단 내용:', '```',soak['failure'],'```']
else:lines+=['아직 실행 결과가 없습니다. 30분 성공으로 표시하지 않습니다.']
stt=read(E/'stt-browser.json',{})
lines+=['','## 현재 한국어 합성 인식','']
if stt.get('results'):
    def normalize(s):return re.sub(r'[^\w\s]','',__import__('unicodedata').normalize('NFC',s)).strip()
    def dist(a,b):
        row=list(range(len(b)+1))
        for i,x in enumerate(a,1):
            nxt=[i]
            for j,y in enumerate(b,1):nxt.append(min(nxt[-1]+1,row[j]+1,row[j-1]+(x!=y)))
            row=nxt
        return row[-1]
    ce=we=cn=wn=0;lines+=['| 원문 | 실제 인식 | 추론 ms | FPS 표본 |','|---|---|---:|---:|']
    for r in stt['results']:
        expected=normalize(r['reference']);actual=normalize(r['result']['text']);ce+=dist(expected.replace(' ',''),actual.replace(' ',''));we+=dist(expected.split(),actual.split());cn+=len(expected.replace(' ',''));wn+=len(expected.split())
        lines.append(f"| {r['reference']} | {r['result']['text']} | {r['result']['elapsedMs']:.0f} | {r['performance'].get('fps','-')} |")
    lines+=['',f"이번 {len(stt['results'])}개 합성 입력의 CER {ce/cn:.1%}, WER {we/wn:.1%}. NFC/구두점 제거, CER 공백 제외, WER 공백 토큰 기준. 숫자/이름을 의미 추정으로 고치지 않았습니다.", '', '합성 소수 문장의 결과이며 사람/소음/겹말/실마이크 품질 수치가 아닙니다. 인식 worker 실행 시간은 발화 종료부터 최종 자막까지의 전체 지연과 다릅니다.']
elif stt.get('error'):lines+=['현재 실행 오류: `'+stt['error'].replace('\n',' ')+'`. 과거 수치를 현재 결과로 대체하지 않습니다.']
else:lines+=['현재 결과 미확정. 과거 CER17.2%/WER29.7%를 현재 결과로 재인용하지 않습니다.']
lines+=['','## 실제 화면','']
for img,title in [('integrated-three/client-0-forward.png','상대 몸체'),('life-flow/sleep-third-person.png','본인 3인칭 취침'),('tools-flow/meeting-questions-tasks.png','공동 질문과 할 일'),('tools-flow/physical-laser-host.png','3D 물리 레이저'),('voice-facilities/refined-basin-water.png','정리한 세면대와 수도'),('arcade-flow/runner-result.png','실제 공룡 러너 결과'),('scale-soak/eight-peers.png','8개 브라우저 접속')]:
    if (E/img).exists():lines += [f'### {title}','',f'![{title}]({(E/img).resolve().as_posix()})','']
lines+=['## 해석할 때 남는 제약','', '1. 사람/실마이크/외부 두 계정/WAN/운영 배포는 사용자 지정 가상 범위 밖입니다.','2. 62개 클립의 존재·로딩과 일부 실제 행동을 검증했으며 모든 프레임의 손·발·가구 접촉 품질을 완전히 인수한 것은 아닙니다. 13본 구조에는 손가락/손목 본이 없습니다.','3. 기존 거대한 V2 world/bridge의 점진적 분리는 진행했지만 전면 해체하지 않았습니다.','4. 요리·식사·설거지·수납·서랍·램프·보드·점유·저장에 대한 현재 V3 엔진 회귀를 추가했습니다. 모든 기존 기능 조합을 최종 브라우저 빌드에서 전수 재시험한 것은 아닙니다.','5. 호스트 탭을 숨길 때 의도적으로 freeze하지 않지만 브라우저/운영체제의 백그라운드 제한과 비정상 종료 시 최근 상태 손실까지 제거하지는 못합니다.','6. 교실 고정 링크는 영구 저장 서버가 아닙니다. 보존에는 실제 파일 내보내기/가져오기를 사용합니다.']
write('verification-report-ko.md','\n'.join(lines))
print(json.dumps({'documents':5,'buildId':build.get('buildId'),'groups':[(r['title'],r['passed'],r['failed'],r['completed']) for r in summary]},ensure_ascii=False))
