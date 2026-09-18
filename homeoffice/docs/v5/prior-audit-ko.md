# COMMONS WORKSPACE V5 — 현재 코드 감사와 외부 조사 근거

작성일: 2026-09-17. 이 문서는 조사 결과와 제안의 구분을 위한 부록이다. 앱 수정·운영 배포·관리자 설정 완료 보고가 아니다.

## 1. 확인 범위와 한계

- GitHub 현재 main / codex/commons-workspace-v4 / codex/homeoffice-v3: `27dccb8adeccb51690a5f5c4abbebebf339b850c`.
- 가장 최근 조회된 Pages 배포: run `35205066858`, commit `968554abb7e19802085ef2c43abec2df628d0eda`, artifact `10489900909`.
- 내려받은 실제 Pages 아티팩트: Build ID `cc2f8fbd-ba33-4601-b716-82bb26422424`, source digest `d3f3b1f7bc2bd3343825fd5705089bd5a7807f1fb7cb8ccc3e333d5c12a62514`.
- 아티팩트 manifest의 73개 파일 크기/SHA-256을 검사했고 불일치 0개였다. 이는 내려받은 배포 묶음의 내부 무결성 검사이지 공개 origin의 응답이나 게임 품질 검증이 아니다.
- 저장소/배포 커밋 차이는 비교 API로 조사했다. 후속 커밋은 검증 기록을 갱신하는 커밋이다. commit 문자열과 dirty 표기만으로 옛 빌드나 소스 불일치를 단정하지 않는다.
- 공개 사이트는 웹 조회에서 Internal Error, 컨테이너의 공개 HTTPS 조회에서 DNS 실패가 발생했다.
- 실제 아티팩트의 로컬 브라우저 실행을 시도했으나 `ERR_BLOCKED_BY_ADMINISTRATOR`로 차단되었다. 보안 정책 우회는 하지 않았다.
- 따라서 이번 작성자는 최신 게임을 직접 플레이하거나, 사용자의 다리 떨림/의자 겹침/없는 책상 다리를 화면에서 재현했다고 주장하지 않는다.
- 외부 공식 문서와 게임 소개/개발 설명은 조사했다. 게임 영상의 실제 재생·프레임별 관찰은 완료하지 못했다. 아래 ‘영상 조사 과제’는 구현 에이전트가 수행할 작업이며 이미 관찰한 사실이 아니다.

## 2. 현재 소스에서 확인한 사실 / 해석 / 수정 과제

### F01. V4가 이미 반영되어 있다
현재 README와 TASK_STATE는 일반 3인칭, 메신저, 전역 사격, Clerk 개발 공개 설정, 회의실 마감 추가를 기록한다. 따라서 V3 기준으로 ‘텍스트만 있는 채팅’, ‘수면 외 3인칭 없음’, ‘무기 승인제 그대로’라고 현재를 진단하지 않는다. 기록에 존재하는 시험과 이번 독립 실행은 구분한다.

### F02. 책상 지지대가 소스에 전혀 없는 것은 아니다
`homeoffice/art/author_v4_meeting.py`에는 `ConferenceTop`, `Pedestal`, `PedestalFoot`를 생성하는 코드가 있다. `homeoffice/scripts/world/meeting_finish.gd`는 `meeting-finish.glb`와 상판 충돌체를 추가하고 기존 ID/좌석을 유지한다. 다른 책상까지 다리가 있다는 뜻도, 최종 화면에 제대로 보인다는 뜻도 아니다.

사용자 증상의 후보: 보고 있는 책상 종류 차이, export/mesh packing 누락, 가시성/LOD/재질, 중복 상판, 위치·스케일·원점, 그림자와 조명. 해당 objectId를 먼저 고정한 뒤 Blender→GLB→Godot→PCK→공개 화면을 추적해야 한다.

### F03. 건축은 여전히 이전 배치에 덧붙이는 성격이 있다
`tools/design_v2.py`는 중앙의 긴 홀, 한쪽 생활공간과 다른쪽 회의/자유공간, 구석의 화장실, 별동, 두 코트의 위치를 정의한다. 회의실 제작 스크립트는 명시적으로 기존 topology를 보존하는 additive finish다. 이는 미술 추가와 전체 인접 관계 재설계가 다른 작업임을 보여준다. 화장실이 잘못 배치되었다는 최종 판정은 동선·평면·실제 보행 검토가 필요하다.

### F04. 애니메이션 선택과 접촉 보정의 결합을 검사해야 한다
`homeoffice/scripts/v2/avatar.gd::animate()`에는 속도·방향·접지·동작·자세를 순차 if로 선택하고 마지막 clip을 덮어쓰는 흐름이 있다. 전이 임계값이 여러 군데 있고 `AnimationPlayer.play(name,.12)`는 이름 변화에 따라 실행된다. ‘매 프레임 무조건 play한다’는 주장은 하지 않는다.

`grounded_before`는 `is_on_floor()`에서 계산된다. 원격 캐릭터가 호스트와 같은 방식으로 이동 시뮬레이션을 수행하지 않는 경우 이 접지 판정의 의미를 별도 점검해야 한다. 코드만으로 사용자 증상의 단일 원인을 확정할 수 없다.

### F05. 발 IK의 목표와 손 그립이 단순화되어 있다
`player/contact_ik.gd`는 Animation 이후 두 링크 IK를 적용한다. 발 목표를 광선으로 찾고, 수평 .33m / 높이 .15m 등의 문턱으로 앵커를 갱신한다. 애니메이션의 명시적인 좌/우 발 contact curve와 가중치 혼합은 이 파일에서 확인되지 않는다. 함수의 `_delta` 인자는 실제 계산에 사용되지 않는다.

손 목표는 사물 종류별 상단 높이와 좌우 ±.13m 같은 오프셋으로 잡고 손목/손가락 대신 가상의 .24m 끝부분을 사용한다. 이것은 사용자별 체형, 소파/의자 실제 접촉점, 복잡한 그립을 검증할 필요가 있다는 근거이지 모든 겹침의 확정 원인은 아니다.

### F06. 애니메이션 ‘62개 존재’는 접촉 품질의 증거가 아니다
현재 진행 문서는 13 bones / 62 animations 파생본을 기록하면서 품질 인수가 남았다고 명시한다. 상태 수와 클립 수를 늘리는 것보다 phase, 접지, 전이, 그립, 리그 구조 및 체형 극값 검증이 우선이다.

### F07. 현 방 잠금은 새 관리자 전용 코트 정책과 다르다
`security/room_access.gd::blocks_entry()`는 잠긴 구역 경계 통과를 제어한다. 안내 문구는 관리자가 열면 누구나 들어가는 정책이다. 최신 요구는 농구/축구 코트에 관리자만 들어가는 것이므로 signed actor identity + zone role policy를 추가해야 한다. 문이 열렸다는 사실이 코트 사용권을 의미하면 안 된다.

### F08. 운영 인증 연결은 아직 미완료로 기록되어 있다
README/TASK_STATE에 Clerk 공개 설정과 UI는 연결됐지만 운영 관리자 지정/PIN 검증 서버는 아직 연결되지 않아 잠금/관리 방송이 비활성이라고 명시돼 있다. UI 로그인창 표시를 관리자 인증 완료로 바꾸면 안 된다. 코트는 운영 검증이 안 됐을 때 일반 사용자에게 fail-open하면 안 된다.

### F09. 소품 설치 UI의 현재 형태
다운로드한 `activities.mjs`에는 가구별 버튼을 클릭하면 build_begin을 요청하고 패널을 닫는 흐름이 있다. 사용자 최신 요구인 ‘옆에 열린 설치함에서 월드로 끌어 놓기’는 현재 방식의 이름 변경으로 해결되지 않는다. drag 좌표→실제 게임 viewport→raycast→미리보기→검증→확정을 통합해야 한다.

### F10. 이미 있는 것을 회귀시키지 않는다
현재 메신저/카메라/총/공 물리/Clerk adapter/자료 원본 링크/교실/내보내기 경로를 인벤토리화하고 재사용할 부분을 정한다. V2→V3 상속을 유지한 채 단순히 V5를 다시 상속하는 것만으로 모듈 구조를 개선했다고 주장하지 않는다.

## 3. 외부 1차 자료 — 실제 확인한 범위

아래 자료의 원리는 참고하되, 실제 기능 설계·게임 치수·시험 목표 중 자료가 직접 정하지 않은 내용은 V5 설계 제안이다.

| ID | 출처 | 확인한 근거 / 이번 적용 |
|---|---|---|
| S01 | Roblox Character Controller Library | 능력 판단과 이동 시뮬레이션 controller의 분리. Godot 구현에 구조 원리를 참고하며 Roblox 코드를 그대로 실행한다는 뜻이 아니다. |
| S02 | Roblox Create character animations | 접촉·하강·통과·상승 자세, 반복 보행, 저속/다각도 검토. |
| S03 | Godot AnimationTree | 블렌딩과 상태 전이 구조. 단일 애니메이션 소유자와 활동별 그래프 설계의 근거. |
| S04 | Godot SkeletonModifier3D | 애니메이션 이후 스켈레톤 수정의 실행 순서를 확인할 기준. |
| S05 | EA NBA LIVE 19 | EA 농구 게임의 Real Player Motion / 1v1 Everywhere 소개. 현재 서비스 가동이나 내부 알고리즘을 검증한 자료가 아니다. |
| S06 | Nexon FC ONLINE 공식 가이드 | 기본 조작·프리롬·볼타·관전 등 공식 안내가 있는 출발점. |
| S07 | EA FC 26 Gameplay Deep Dive | 터치 간격, 발 선택, 높이별 일관성, 애니메이션 전이/분기, 입력 반응성에 관한 개발 설명. FC ONLINE와 같은 제품이라고 취급하지 않는다. |
| S08 | Riot How the VALORANT Arsenal was built | 무기별 시각 식별, 기능적 차별, 일관된 아트/소리/동작의 설계 원칙. 실제 총기 사용 매뉴얼이 아닌 게임 프레젠테이션 참고. |
| S09 | Riot The State of Hit Registration | 올바른 판정과 읽기 쉬운 시각 피드백의 구분, 로컬 효과와 서버 확정 결과의 구분. |
| S10 | WBDG Office Building | 업무실 외 회의, 로비, 휴게/식사, 화장실, 저장, IT/유지관리 지원공간의 필요를 프로그래밍할 근거. 모든 항목이 이 앱의 필수 구현이라는 뜻은 아니다. |
| S11 | Steelcase Expanding Sightlines for Hybrid Meetings | 10인 회의 환경의 좌석/테이블/화면 시야 계획 사례. 해당 상표/제품을 복제하지 않는다. |
| S12 | IKEA Kitchen layout / workflow | 싱크·조리·냉장과 쓰는 위치 근처 수납, 조리 동선의 근거. |
| S13 | NKBA Planning Guidelines 공개 소개 | 주방·욕실·의상/수납·세탁·홈오피스 등의 기기 위치, 활동 여유, 접근성 고려. 유료 지침 전체나 법규 준수를 확인한 것이 아니다. |
| S14 | Svenska Basketbollförbundet Basketball court | 코트 28×15m, 링 윗면 3.05m 등 공식 연맹의 미터 기반 치수. NBA 규격과 혼동하지 않는다. |
| S15 | FIFA Stadium Guidelines 5.3 | FIFA 권장 105×68m 피치와 선 밖 여유 공간. 앱 전체 인원/성능 보장과 다르다. |
| S16 | NBA Rule No.1 | NBA식 도면/장비를 선택할 때 별도로 사용할 규정 원본. FIBA 계열과 혼합하지 않는다. |
| S17 | Godot Control | UI drag/drop 훅의 실제 API 참고. 월드 좌표 변환은 별도 구현이다. |
| S18 | Godot Web export | 실제 웹 렌더링/스레드/오디오 지원 검증의 출발점. |

### 공식 URL

- S01 https://create.roblox.com/docs/characters/character-controller-library
- S02 https://create.roblox.com/docs/tutorials/use-case-tutorials/animation/create-an-animation
- S03 https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- S04 https://docs.godotengine.org/en/stable/classes/class_skeletonmodifier3d.html
- S05 https://www.ea.com/games/nba-live/nba-live-19
- S06 https://fconline.nexon.com/news/guide
- S07 https://www.ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-gameplay-deep-dive
- S08 https://playvalorant.com/en-us/news/dev/how-the-valorant-arsenal-was-built/
- S09 https://playvalorant.com/en-us/news/dev/the-state-of-hit-registration/
- S10 https://legacy.wbdg.org/building-types/office-building
- S11 https://www.steelcase.com/settings/expanding-sightlines-for-hybrid-meetings/
- S12 https://www.ikea.com/us/en/rooms/kitchen/how-to/kitchen-layout-ideas-for-the-best-workflow-pubaa839870/
- S13 https://nkba.org/planning-guidelines/
- S14 https://www.basket.se/aktiva/domare/basketplanen/
- S15 https://publications.fifa.com/es/football-stadiums-guidelines/technical-guideline/stadium-guidelines/pitch-dimensions-and-surrounding-areas/
- S16 https://official.nba.com/rule-no-1-court-dimensions-equipment/
- S17 https://docs.godotengine.org/en/stable/classes/class_control.html
- S18 https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

## 4. 제목 해석과 영상 조사 과제

사용자의 ‘EA SPORTS NBA’는 EA의 NBA LIVE를 우선 후보로 삼았다. NBA 2K는 다른 제작사의 시리즈이므로 같은 것으로 쓰지 않는다. ‘EA SPORTS ONLINE’은 FC ONLINE을 우선 후보로 삼고, FC 26 개발 설명을 보조 참고로 구분한다. 특정 작품/연도/영상의 지정은 아직 없다.

구현 에이전트는 공식 게임플레이 영상과 원출처가 분명한 무편집 플레이 영상을 브라우저로 실제 관찰한다. 농구/축구/사격 각각 최소한 아래 플레이 사건을 확인한다. 영상 재생이 막히면 실패 이유를 쓰고 실제로 받은 영상/접근 가능한 자료로 보완한다. 제목이나 자동 자막만 읽고 프레임을 봤다고 하지 않는다.

- 공통: 정지→출발→방향 전환→정지, 카메라 가림, 상하체 분리, 이동과 접지.
- 농구: 무볼 준비, 수비 사이드스텝, 드리블 손 교체, gather, release, landing, rebound.
- 축구: 첫 터치, 작은 볼 터치, 급회전, 패스의 지지발, 킥 follow-through, tackle, 공 소유권 분리.
- 사격: equip, aim, shot, recoil recovery, reload, hit confirm, moving target, round transition.
- 가구: 의자/소파 접근, 정렬, 체중 이동, 착석, 일어서기; 사람과 가구의 기준점.

관찰 기록의 필수 필드: 출처 URL, 게시 주체, 작품/연도, 실제 관찰 timestamp, 재생 속도, 입력/상태, 접촉/무게중심, 카메라, 피드백, 그대로 적용하지 않을 요소, 자체 구현안, 실제 검증 방법. 이 문서는 아직 본 적 없는 timestamp를 만들어 넣지 않는다.

## 5. 보안·범위 메모

코트 관리자 전용은 최신 명시적 제품 정책이다. 처음 표시하는 교육용 안내 문구 때문에 자동 도입하는 기능이 아니다. 다른 방의 PIN 정책, 전역 총 사용 정책, 관리자와 시뮬레이션 호스트의 구분을 섞지 않는다. 비공개 PIN은 이 감사와 공개 프롬프트에 포함하지 않는다.
