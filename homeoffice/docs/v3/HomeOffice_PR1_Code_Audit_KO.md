# Friendslop HomeOffice — PR #1 근거 기반 개선 감사

확인일: 2026-09-15. 기준 커밋: `e62360fd45e03e15fe7e2371d204dc30ff35c9ae`. 저장소: `mjayj9/Friendslop_HomeOffice`.

## 1. 확인 범위와 한계

GitHub 연결을 통해 PR 정보, 파일 트리, Godot 코드, 제작 스크립트, 웹 브리지, 발표 모듈, 테스트와 미완료 문서를 읽었다. PR은 open·draft·unmerged이고 head는 `codex/godot-homeoffice-v2`이다. Pages 배포 작업 `34869820468`은 이 head 커밋으로 success 상태다. 배포 성공은 실제 게임의 기능 정상 증거가 아니다.

해당 작업의 실제 `github-pages` 아티팩트(artifact ID `10358148308`)를 내려받아 압축을 검사하고 배포 HTML/JS/WASM/PCK를 확인했다. `bridge.mjs`와 `presentation.mjs`의 Git blob 해시는 읽은 소스 파일과 일치했다. 이는 내려받은 아티팩트와 소스 사이의 일치이며, 사용자의 브라우저 캐시나 공개 서버의 현재 응답을 실시간으로 대조한 결과는 아니다.

공개 URL의 직접 열기/다운로드는 이 환경에서 실패했다. 아티팩트의 로컬 브라우저 실행도 `ERR_BLOCKED_BY_ADMINISTRATOR`로 차단되었다. 실행 환경에는 Godot 실행 파일이 없었다. 따라서 실제 게임 렌더링·사용자 간 가시성·WAN 연결·마이크·BlenderMCP를 검증하지 않았다. 제한 우회는 하지 않았다. 사용자 경험을 부정하거나, 사이트 전체가 다운되었다고 추정하지 않는다.

6개 배포 JS 모듈에 `node --check`를 실행했고 문법 검사는 통과했다. 이는 논리·상호작용·게임성·다중사용자 통과가 아니다. 저장소에 적힌 과거 테스트 결과와 이번 감사에서 실행한 항목을 분리한다.

## 2. 코드에서 확인한 사실과 해석

| ID | 근거 | 확인된 사실 | 해석·수정 방향 / 확실성 |
|---|---|---|---|
| F01 | scripts/v2/world.gd: add_player, handle_packet; tests/v2-multiplayer-scale.mjs | 플레이어 배열·노드 생성 경로는 존재. 규모 테스트는 players 길이, 개인실 수, 좌표 보존을 주로 확인 | 상대 안 보임의 단일 원인은 아직 미확정. transport→state→node→mesh→camera를 분리 검증. 인원수=시각 표시로 판정하지 말 것 |
| F02 | scripts/avatar.gd: animate; scripts/v2/avatar.gd; docs/v2/required-remaining.md | sin(gait) 기반 본 회전. 문서에 간이 13본과 별도 앉기/눕기 메시, IK/그립 미완료 명시 | 애니메이션 파일/리깅/블렌딩의 재작업 근거가 있음. 사용자 원본이 불충분했다는 책임 전가는 금지 |
| F03 | scripts/v2/avatar.gd: animate | local_player의 lying 메시도 숨김. 수면 시 1인칭 카메라 높이 조절 | 이번 요구의 자기 수면 3인칭에 맞는 별도 카메라/시각 정책 필요 |
| F04 | scripts/v2/world.gd: rounds, fire_tag, trigger_down | tag 초기 phase=ready. fire_tag는 practice/play만 허용하고 그 외엔 조용히 return. 12발·재장전·220ms 간격. trigger_down에서 한 번 fire_tag 호출 | 허가 후에도 라운드 상태 때문에 발사 안 되는 재현 가능한 경로가 있음. 모든 실제 실패의 원인으로 단정하지 않음. 자유사격 초기화·오류 안내·홀드 연사·무제한 탄약 모드 필요 |
| F05 | scripts/v2/world.gd: fire_tag, network_state | 명중 시 tag_score와 안내를 쓰는 경로. HP/KO/복귀·킬 게이지를 완성하는 전투 상태 흐름은 확인되지 않음 | 단순 토스트를 피해/킬 상태와 동일시하지 말 것. 분리된 host-authoritative 상태로 구현 |
| F06 | scripts/v2/world.gd: trigger_up, spawn_object | 농구 충전 시간은 계산하지만 발사 속도식은 direction*(5+strength*5)+UP*2.4. 해당 경로에 backspin 각속도 지정 없음. bounce=.75 | 슛 게이지가 존재한다고 주장하지 말 것. 각도·릴리스 위치·회전·접촉 재질·득점 검증을 함께 교정. bounce 하나만 원인이라고 단정 금지 |
| F07 | scripts/v2/world.gd: spawn_object; art/build_v2.py | 농구공 반지름 .24, 축구공 반지름 .22. 림 중심선 반지름 .43. 제작 값과 충돌체 값에 대형화 경향 | 미터 단위라면 공 지름 .48/.44m. 외형과 질량·농구 림·골 센서·손 그립 치수를 함께 재검토. 반지름/지름 혼동 여부를 우선 점검 |
| F08 | scripts/v2/world.gd: kick_start/kick; update_sports | 축구 킥은 고정 ID football을 찾아 거리/무소유/구역 확인 후 속도 지정. 발로 유지하는 드리블 상태 경로는 확인되지 않음 | 일반 집기와 축구 경기 제어를 분리. 발 터치, 상대 스틸, 패스/슛으로 실제 경기 루프 구성 |
| F09 | scripts/v2/world.gd: base_input, update_hint | E=사용, Q=drop, 일반 좌클릭=throw. 책은 RigidBody3D 경로에 포함 | ‘책 던지기 코드가 전혀 없다’고 하면 틀림. 최신 E 집기/내리기·Q 던지기와 입력 불일치를 수정하고 실제 키 경로 검사 |
| F10 | scripts/v2/world.gd: perform, setup_living_prop | floor_lamp state.on 토글과 Bulb가 있음. 모든 방의 전등이 통일된 switch 회로인 것은 아님 | 모든 조명이 미구현이라는 주장 대신 히트 대상·방 스위치·시각 변화·권위 복제를 시험 |
| F11 | tools/assemble_v2.py; scenes/main.tscn | .txt 함수들을 정규식으로 합쳐 world.gd 작성. main.tscn은 이 world 스크립트 하나 연결 | 게임 동작 코드와 생성 원천이 이중화됨. 런타임 수정이 생성기로 덮어써지는 회귀 위험. 데이터/에셋 생성과 .gd 로직을 분리 |
| F12 | web/collaboration-source.mjs; web/presentation.mjs | Yjs/Quill 공동 보고서, PDF/이미지 발표. presentation-pointer는 DOM slideCanvas 이벤트에서 생성 | 실제 Google Docs/Slides/Excel 연동과 다른 기능. 물리 레이저 소품의 3D 입력은 별도 구현·검증 대상 |
| F13 | web/bridge.mjs visibilitychange; world.gd visibility handler | document.hidden이 host frozen 및 RigidBody freeze로 연결 | 호스트가 Google Docs 탭으로 옮기면 게임 정지 경로가 있음. 브라우저 백그라운드 제약까지 포함해 공동작업 전략 설계 |
| F14 | web/bridge.mjs startOnline, copyInvite | mh-UUID 일부가 방 코드. copyInvite는 room 문자열만 복사 | QEC-ETE 같은 표시 코드, 실제 URL 복사, 고정 교실 alias를 분리 설계 |
| F15 | web/captions.mjs; docs/v2/required-remaining.md | 브라우저/온디바이스/Whisper 선택 경로는 있음. 보고된 CER17.2%/WER29.7%는 합성6문장 | STT 없는 코드라는 판단은 부정확. 설치/가용성/실마이크/한국어 품질과 FPS를 검증해 개선 |
| F16 | docs/v2/required-remaining.md | 동시8개 브라우저 한 PC 시험에서 낮은 FPS와 다수 필수 미완료 명시 | 사용자 불만과 미완료 문서가 부합. 하지만 이 수치를 실제8인 분산기기 성능으로 일반화하지 말 것 |

## 3. 수정 우선순위

P0: 배포 재현성과 실제 서로 보이는 2~3인 네트워크. P1: 입력/권위/애니메이션/물리의 작은 단위 회귀를 지키며 구조 정리. P2: 최우선 제품 기능인 회의실·실제 협업 서비스·레이저·교실 입장. P3: 총/체력/킬, 농구, 축구와 생활·공간 마감. 음성/방송과 저장은 모든 단계에서 통합 검증한다. 일정상 병렬 가능하지만 서로 보이지 않는 빌드를 완성본으로 제출하지 않는다.

## 4. 반드시 구분할 제품 선택

- HP(피격시 감소·회복/리스폰시 증가)와 킬/콤보 게이지(킬시 증가·정의한 조건에서 감소)는 별개다. 사용자의 ‘킬 게이지’ 의미를 임의로 하나로 덮지 않고 기본안을 명시한다.
- 무제한 사격은 허가된 놀이 공간의 자유사격이다. 기존 방장 승인 요구를 유지하되 허가 후 ready 단계에 갇히거나 재장전 안내 없이 막히게 하지 않는다.
- 영구 교실 링크, 현재 시뮬레이션 호스트, 월드 영구 보존은 서로 다르다. 정적 Pages만으로 세 가지가 자동 완성되지는 않는다.
- Google Docs/Slides와 Excel은 실제 서비스 원본 공동 편집을 요구한다. Yjs/Quill이나 PDF 뷰어를 Google/Excel 기능이라고 바꿔 부르지 않는다.
- Google 검색 결과·실제 편집기를 iframe/3D 텍스처로 자유롭게 넣을 수 있다고 보장하지 않는다. 공식 허용 임베드·안전한 원본 탭·명시적 화면 공유를 구분한다.
- Chrome 공룡 러너가 기존 미로/픽맨 최종 요구를 대체한다. chrome://dino 내부 주소를 iframe으로 연결하는 것이 아니라 라이선스 확인한 코드/자산 또는 동등한 자체 구현을 배포한다.

## 5. 파일 증거

| 파일 | byte | SHA-256 |
|---|---:|---|
| index.html | 5201 | `352a5b2e9739150942694880fb8528a339c97d1576738f715a23d05471f6462c` |
| index.wasm | 37685705 | `99962b29677e42f3ba0258bd90fdc52ad90295954c4473e816ad02cfe5ff1d4f` |
| index.pck | 7908968 | `b85acfc2229bb8a570d790b9aee4c852fbe2159d887179df8887c0ae71acd74b` |
| bridge.mjs | 40314 | `b752fbfecb6a3e73eebc862ca89579bc111ed099c73fc36c32c16802eb090f32` |
| presentation.mjs | 12701 | `5dd1eb9edcd7e5ec427a95fe8b9ee2018f18c49d4b9be6c240c5125e17e920de` |

## 6. 직접 읽은 코드 출처

- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/scenes/main.tscn
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/scripts/avatar.gd
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/scripts/v2/avatar.gd
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/scripts/v2/world.gd
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/art/build_v2.py
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/tools/assemble_v2.py
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/web/bridge.mjs
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/web/presentation.mjs
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/web/collaboration-source.mjs
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/web/captions.mjs
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/tests/v2-multiplayer-scale.mjs
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/e62360fd45e03e15fe7e2371d204dc30ff35c9ae/homeoffice/docs/v2/required-remaining.md
