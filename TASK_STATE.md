# COMMONS V6 — 사용자 테스트 게시 준비 (2026-09-19)

최신 기준: [V6 명세](homeoffice/docs/v6/master-spec-ko.md), [네 이미지 분석](homeoffice/docs/v6/design-decisions-ko.md), [OBS 원문](USER_OBSERVATIONS.md), [V6-T01–56](homeoffice/docs/v6/verification-ko.md). 기존 V5 이력은 아래에 그대로 보존한다. **전체 V6 인수 완료가 아니다.**

검수 빌드 `f38c2ed4-11dd-46f5-8cd5-11dbb3a032aa` / source `3704c4ccdd712215f6fafbddc719bd7e537153612aabea07e1a9b5a0bf468861`. 시작 HEAD 7cab26a, 실제 Pages codex/homeoffice-v3 및 기존 공개 9fa65de6을 확인했다. 같은 export를 docs/로 복사했다. 사용자는 같은 저장소 commit/push/Pages 게시를 명시적으로 요청했다. 실제 게시 증거는 [영수증](homeoffice/evidence/v6/publication/receipt.json)에 기록한다. 인증 서비스·Firebase·PIN·관리자 설정 변경 없음.

구현: 원본을 보존한 BlenderMCP 제작, 크림/우드/세이지 팔레트와 차양·식재, OFFICE B1~RF 8개층, 두 실제 승강기/두 U계단/층별 화장실, 4층 고정 개인실 8슬롯, 2층 4개 회의의 문서·보드·자료·발표 분리, 오프라인 초안 재접속/참여 중지, 이전 저장 좌표와 미배치 보관함. [평면](homeoffice/docs/v6/campus-plan.html), [책임/저장 경계](homeoffice/docs/v6/implementation-map-ko.md), [제작 출처](homeoffice/docs/v6/art-and-assets-ko.md).

같은 빌드 실제 검수: 4개 독립 Chromium 회의 9흐름, 실제 HOME→OFFICE·2F 회의·6F/RF/B1/1F 승강기 왕복 4흐름, 기존 의상방 9흐름, 옆 설치함/총 입력 격리 10흐름. 브라우저 pageerror 0. 엔진 348/348(기존 V5 125, V6 223), Node 33+6. 사람·실제 마이크·실계정 공동편집으로 오인하지 않는다. 이전 V5 증거 파일은 바이트 그대로 보존했다.

[실제 결함 수리](homeoffice/docs/v6/repair-log-ko.md): 문턱/계단 머리 공간/회의 화면과 문 겹침/개인실 초기 가구 누락과 서가 충돌/화장실 뒷칸 통로/발표 화면 배치/재접속 메뉴 가림/복원 성공 응답 순서를 수리하고 재시험했다.

남음: 첨부 사진 수준의 세밀한 표면·명암, 실제 사람 4명 및 마이크/두 외부 계정/운영 관리자/CCTV·방송 확인, 내장 프로젝트 문서의 회의 간 의도 공유, 모든 첨부의 host handoff, 2/4/8인 결합 성능, 일부 V5 스포츠/체형·좌석 접촉 품질. [성능](homeoffice/docs/v6/performance-ko.md)은 저사양 보행 약20fps로 목표 미달이다. 사용자 OBS 재확인은 대기 상태다.

[직접 테스트 안내](homeoffice/docs/v6/testing-ko.md). 기존 로컬 서버와 사용자 Blender는 종료하지 않는다.

---

# COMMONS WORKSPACE V5 — 현재 작업 상태

2026-09-18 KST. **V5 전체 미완료. 최신 사용자 요청과 V5 통합 명세가 기준이다.** 원래 V4 세계·자료·계정 설정을 보존하며 점진적으로 수리했다. 아래 결과는 제한된 로컬 및 공개 페이지 검수이며 완성형 제품 출시 판정이 아니다.

[최신 통합 명세](homeoffice/docs/v5/master-spec-ko.md) · [N01–N34 / T01–T48](homeoffice/docs/v5/verification-ko.md) · [결함 수리 기록](homeoffice/docs/v5/repair-log-ko.md) · [실제 영상/자료 관찰](homeoffice/docs/v5/research-observations-ko.md) · [건축/저장 이동 설계](homeoffice/docs/v5/architecture-and-migration-ko.md) · [상호작용 도면](homeoffice/docs/v5/architecture-plan.html) · [실제 의상방/얼굴 검수](homeoffice/docs/v5/wardrobe-review-ko.md)

## 사용자 테스트를 위한 공개 배포

2026-09-18 사용자가 커밋·푸시와 Pages 반영을 명시적으로 요청했다. 기존 Pages 설정으로 게시했고 GitHub 배포·CI와 실제 공개 Chromium/WebGL 검수를 완료했다. [배포/직접 테스트 안내](homeoffice/docs/v5/publication-ko.md) · [검증 영수증](homeoffice/evidence/v5/publication/receipt.json). 운영 인증 서버·Firebase·관리자 설정은 변경하지 않았다.

| 항목 | 확인 값 |
|---|---|
| 작업 디렉터리 | `deployment/Friendslop_HomeOffice/homeoffice` |
| 로컬 작업 브랜치 | `codex/commons-workspace-v5` |
| 실제 공개 배포 ref / commit | `codex/homeoffice-v3` / `4713d4142391a5ce38332a8802bc421449879210` |
| Pages / CI run | `35352390257` / `35352392152` — 모두 성공 |
| 공개 및 로컬 Build ID | `9fa65de6-20d0-4a7a-b315-f3b388891e24` |
| 공개 및 로컬 source digest | `74c8afce2b641b594aa5598ff4fe1f43eb070adc9d68be0c3249f86c9bc08b68` |
| 엔진 / protocol / asset / save | Godot 4.6.1 / 4 / 3 / 2 |
| 실제 공개 파일 | 88개 HTTP·크기·SHA256 일치 |
| 이번 공개 UI | 설치 10 / 의상방 9개, pageerror 0개 |

제작 당시 source base `27dccb8…`와 dirty 표시는 검수 export에 그대로 보존했다. 게시 커밋은 위 `4713d41`이며 Git index의 소스 244개도 manifest와 대조했다.

게시 전 V4 조사 기준은 HEAD `27dccb8adeccb51690a5f5c4abbebebf339b850c`, 실제 배포 `968554abb7e19802085ef2c43abec2df628d0eda`, Pages run `35205066858`, Build ID `cc2f8fbd-ba33-4601-b716-82bb26422424`다. 당시 73개 파일과 실제 앱을 관찰한 증거는 원래 값으로 보존한다. 이전 승인 이력은 [V4 상태](homeoffice/docs/v4/task-state-before-v5.md)에 있으며 이번 게시의 승인은 2026-09-18 새 사용자 요청이다.

## 이번에 반영한 수리

- `living-low-table` 지지대가 바닥 아래로 묻히는 원인을 상판만 있는 충돌체로 재현했다. 원본 GLB 지지대는 있었다. 네 다리 충돌체와 제한적인 idempotent 저장 보정을 추가했다. 집 `dining-table` 지지대는 원래 존재했다.
- 원격 avatar의 로컬 floor 판정 오용으로 land가 반복 선택되는 경우를 분리했다. 단일 AnimationTree, locomotion phase, 상체 filter, authority grounded, contact weight와 진단을 연결했다. 완전한 보행 미술/지연망 품질 판정은 남아 있다.
- 남자 V3 원본과 GLB를 보존하고 V5 파생 Blender/GLB를 만들었다. 13개 bone 원본의 손가락·체형 fitting 한계를 기록했다. 클립 개수를 완료 근거로 사용하지 않는다.
- 농구/축구 ADMIN_ONLY와 actor별 서명 lease를 연결했다. 실제 운영 관리자를 검증할 수 없으면 잠금 유지. simulation host, nickname, 열린 문, 총 소유는 입장권이 아니다. 무볼 활동 프로필은 경기 시작과 분리했다.
- 전체 의자 부피와 양손 grip 기준 운반, holder 충돌 유지, 급회전 경계 검사를 추가했다.
- 소파 세 슬롯의 골반·발·등받이 기준·접근/퇴실 계약과 seated 발 IK를 연결했다. 기본 체형으로 실제 10회 왕복했다. 다리가 곧게 보이는 자세·체형 극단·옆 사람·부드러운 진입과 등받이 접촉 완성은 남아 있다.
- 물건 설치 버튼·옆 패널·실제 GLB 썸네일·screen raycast preview·회전/스냅·지지면/문/좌석/관리 구역 검증을 연결했다. Tab으로 포인터 해제, 드래그/재포커스 클릭은 사격으로 전달되지 않는다.
- 의상방은 기존 2층 독서 가구를 보존한 5×7m 구획에 실제 Blender GLB·충돌·거울·옷장·콘솔·조명·피팅 벤치를 추가했다. 현장 직접 클릭, 위치/세션 검사, 512px 얼굴 UV·2레이어·브러시/지우개·Undo/Redo·회전 가능한 실제 3D preview·적용/취소를 연결했다. 확정 얼굴/옷 색은 actor별로 동기화하고 같은 브라우저에 저장한다. 체형/옷 메시 교체, 계정 연동, 전체 파일 프로필 복원은 남아 있다.
- 방장 인계가 의자/테이블의 holder collision exception을 다시 추가하던 결함을 수정했고, 확정 외형을 인계에 포함했다.
- 입장 하단의 정확한 교육용 문구를 순수 표시 모듈로 분리하고 카피 교체/숨김이 정책을 바꾸지 않는지 시험했다. 교육 규칙·과제·진도·퀴즈·학교 승인 표시를 추가하지 않았다.

## 실제 실행과 한계

BlenderMCP 장면 조회·Python·수입/내보내기·렌더·화면 캡처가 성공했다. Blender 5.2.1 LTS / addon 1.6 / protocol 5, 실제 Blender 프로세스가 127.0.0.1:9876 수신 중이다. [연결 증거](homeoffice/evidence/v5/blender-connection.json), [포트](homeoffice/evidence/v5/blender-listener.json). 원본이 있으므로 업로드를 요청하지 않는다.

현재 소스 fixture는 table 7, motion 14, court 35, carry 6, seat 20, placement 10, 생활 12, wardrobe 21 — 총 125개 제한된 판정이 통과했다. [현재 빌드별 실행 묶음](homeoffice/evidence/v5/engine-regression.json)에 source digest와 개별 로그/JSON 경로를 보존했다. 실행 전 source 포함 artifact verify를 통과했다. Node 33검사와 별도 V5 관리자 1검사도 통과했으며 V4+V5 정책 묶음은 7개다(중복 집계하지 않는다). 이 숫자는 T48 전체 합격이 아니다.

실제 UI: 공개와 수리 로컬 보행/테이블, 기본 소파 10회 왕복, 물건 설치 10검사, 독립 Chromium 3개에서 메신저/시점 14검사. 최신 빌드의 [의상방 두 브라우저 13검사](homeoffice/evidence/v5/wardrobe-browser-final/report.json)에는 실제 계단 보행·현장 클릭·초안 미전송·확정 얼굴 동기화·상대 재질 보존·재접속이 있다. 정면 거울과 상대 앞쪽 화면을 직접 열어 확인했다. [최신 메신저 결과](homeoffice/evidence/v5/retained-v4-browser-wardrobe-build/report.json), [최신 설치 결과](homeoffice/evidence/v5/placement-browser-wardrobe-build/report.json), [소파 전면 결과](homeoffice/evidence/v5/seating-browser-front/report.json). 각 결과에 해당 Build ID·화면·WebM을 연결했다. 일부 증거는 이전 로컬 빌드이므로 최신 빌드에서 수행한 것처럼 바꾸지 않는다.

큰 파일 이어받기 첫 시도는 20초 timeout이었다. 전송 상태를 보존하고 제한을 60초로 늘려 실제 완료·SHA 검증했다. 지연은 남는 성능 관찰이다. NBA/FC/VALORANT는 실제로 재생했으나 FC 주요 접촉 사건과 완결 경기 관찰은 부족하다. 음소거였으므로 소리 관찰은 없다. 실제 마이크, 외부 두 계정 문서 편집, 운영 관리자 계정, 8인+STT 동시 성능 인수는 미실행이다.

## 아직 완성되지 않은 핵심

1. 전체 건물 GLB·문/창·재료/음향·위생 시설·실제 U 계단·정교한 가구 배치 및 안전한 전체 layoutVersion 마이그레이션. 전체 도면은 설계만이며, 기존 세계의 의상방 구획만 별도로 런타임에 반영했다. 새 구획과 충돌하는 옛 가구는 복원 전에 거절하여 현재 세계와 원본 파일을 유지한다. 자동 재배치는 미구현이다.
2. 보행/스포츠/소파/의자/침대 접촉 미술, 30/60/고FPS와 실제 원격 지연 비교, 최소/기본/최대 체형 조합.
3. 농구 전체 플레이, 축구 실제 발-공 접촉 impulse, 훈련/봇·경기 완결. 기존 구현을 삭제하거나 없다고 판단하지 않았지만 V5 품질에 충분하다고 인정하지 않았다.
4. 자체 전술 지도와 한 라운드, 무기 1/3인칭 프레젠테이션·피격·복귀 완성.
5. 체형·옷 메시 교체/fitting, 계정·다른 기기 외형 연동, 전체 .homeworld의 프로필/래스터 복원. 현장 클릭/얼굴 UV 편집/옷 색/같은 브라우저 저장·세션 동기화는 실제 검수했다.
6. 실제 완결 회의·원본 두 계정 편집·레이저/보드·전체 생활·한국어 마이크/방송·고정 교실·개인실 확장·전체 저장 회귀.

## 이어서 작업할 위치

기존 통합은 `scripts/v3/world.gd` → `scripts/v2/world.gd`이며 새 v5 world 상속층을 만들지 않는다. 다음에는 설계에 실제 가구·문/창·단면 계약과 layout migration을 완성해 건축을 적용하고, 기본 소파의 무릎 각도/등받이 접촉과 원격 동작 시각 검수를 보강한다. 축구는 현재 `kick_ball`의 즉시 속도 변경과 `_physics_process`의 root 거리 impulse가 남아 있어 실제 foot phase/contact 이벤트로 바꿔야 한다. 의상방은 얼굴 편집과 옷 색까지 실행됐지만 체형/옷 메시 fitting과 전체 파일 프로필 보관은 남아 있다. 원본 13본의 한계를 해결하고 최소/기본/최대 조합을 실제 접촉까지 검수하기 전 체형 slider를 공개하지 않는다.

로컬 검수 서버: `http://127.0.0.1:5173/homeoffice/?signal=local`. 사용자의 기존 프로세스를 종료하지 않는다. 브라우저 조작은 실제 Playwright Chromium/WebGL로 검수했다. CUA 및 view_image 도구는 이 환경 ACL 오류가 있었으며 이를 사용 성공으로 기록하지 않았다.

명령: `npm test`, `npm run test:v5:policy`, Godot `--headless --path homeoffice --script res://tests/v5-*.gd`(baseline은 전/후 비교 전용), `tools/build.ps1 -Godot <4.6.1 console> -LocalOnly`, `python tools/site_artifact.py verify build --source`. 현재 shell 기본 sandbox의 ACL helper 오류 때문에 승인된 require_escalated 로컬 실행을 사용했다. 미승인 원격 변경은 하지 않는다.

최근 검수: `python homeoffice/tools/verify_v5_engine.py --godot <exe>`는 빌드 소스 일치 확인 후 8개 엔진 suite를 빌드별 아카이브에 남긴다. `V5_WARDROBE_PEER=yes`로 `homeoffice/tests/v5-wardrobe-browser.mjs`를 실행하면 독립 브라우저 2개로 검수한다. 현재 공개/로컬 Build ID는 위 표와 publication/receipt.json이 기준이다. 배포 후 기록만 추가하는 커밋은 실제 Pages export 커밋과 구분한다.
