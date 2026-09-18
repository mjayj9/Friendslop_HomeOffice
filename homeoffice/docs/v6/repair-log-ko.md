# 실제 발견과 수리

완성도 판단을 코드 수나 첫 실행으로 대신하지 않는다. 아래에는 실패한 실행도 남겼다. 각 결과 파일의 Build ID가 그 실행의 기준이며, 다음 빌드에 자동 승계하지 않는다.

| 발견/재현 | 원인과 수리 | 증거/재시험 |
|---|---|---|
| HOME 동쪽 연결 통로에서 캐릭터가 막힘 | 옛 하부 유리/벽을 Blender 파생 자산에서 제거하고 일치하는 충돌체를 수정 | `evidence/v6/campus-browser-route2`, `campus-browser-passage`의 실패 기록 |
| 유리를 열어도 통로 입구에서 막힘 | 바깥 −0.17m와 안쪽 0m의 턱. 세 입구에 실제 경사와 일치하는 GLB/collider 제작 | `stair-route-headroom.log`, `campus-browser-render-split/report.json`의 실제 보행 통과 |
| 계단 첫 단에 못 오르거나 중간에서 머리가 막힘 | 시작이 바닥보다 높았고 경사 충돌체의 아래가 채워져 있었다. 바닥에서 시작하는 두께 0.15m 경사로 수리 | 실패 `stair-route.log`, `stair-route-repaired.log`; 수리 후 151개 B1↔RF 양 계단 fixture |
| 회의 화면이 문 개구와 겹침 | 회의실 화면을 실제 벽 구간으로 이동하고 작은 방의 폭을 별도로 지정 | `crafted_campus.gd`, `campus.json`, 현재 브라우저 동선 결과 |
| 4브라우저 9–11fps | 층/재질/외피·내부를 분리하고 멀리 있는 가구와 문/승강기 렌더를 숨김. 기존 정적 설비 노드 병합 | `meeting-browser-save3` → `meeting-browser-render-split` → 후속 결과. draw 감소만으로 fps 합격을 주장하지 않는다. |
| 자동 입장 시 pointer lock 오류 | 비동기 입장 완료에서 강제 캡처를 제거하고 실제 첫 화면 클릭을 소비해 캡처 | `meeting-browser-render-split/report.json` pageerror 0 |
| 책상 UI picker가 테이블 위의 큰 벽처럼 보행을 막음 | 높이 1m picker를 실제 상판 두께로 축소 | 실제 통로/회의실 보행과 현재 엔진 회귀 |
| 발표 캔버스 가운데가 화면 아래에 있어 레이저 검수가 실패 | 발표 UI를 창 높이에 맞추고 제목/참가자/툴바 밀도를 조정. 테스트도 보이는 canvas에 실제 mouse move | `meeting-browser-complete-flow` 실패 → `meeting-browser-visible-slide` 발표/레이저 통과 |
| 연결을 끊으면 재접속 버튼이 클릭되지 않음 | 메뉴를 열면서 바깥 tool veil을 숨기지 않아 입력을 가렸다. 메뉴 전환 경로에서 명시적으로 정리 | `meeting-browser-visible-slide/report.json`의 실제 pointer interception 실패, 후속 재시험 |
| 첫 개인실에 책상 없음 | 데스크톱/headless 초기 참가자 생성이 campus setup보다 빨랐다. setup 후 먼저 생성된 roomSlots를 물체로 실체화 | `engine/.../v6-private-rooms.log` 실패 → `private-rooms-repair.log` 13판정 |
| 개인 책상이 옆으로 밀림 | 작은 방 뒤편 서가가 기존 2.8m 테이블과 겹침. 서가를 옆벽 방향으로 회전하고 정착 검사 추가 | 후속 private-rooms 결과에 실제 물리 위치 포함 |
| 새 화장실의 뒤 칸까지 통로가 이어지지 않음 | 칸막이가 공용 통로 폭까지 가로질렀다. 오른쪽 칸과 왼쪽 세면/통로를 분리하고 불투명 문 추가 | author_v6_campus.py / campus_doors.gd. 실제 접근 검수는 추적표의 결과를 따른다. |
| 복원 문구가 엔진 적용보다 먼저 성공을 알릴 수 있음 | 검증 후 엔진의 restore_result 응답을 기다리고 회의/UI 자료를 전환 | 새 세션 import 브라우저 결과 |
| 과거 V5 storage-world 증거가 fixture로 덮임 | 새 결과는 V6 폴더로 복사하고 과거 파일 바이트를 복구, 실행 wrapper에서 보조 파일도 보존 | `tools/verify_v6_engine.py` |

Blender MCP는 실제 장면 조회와 제작·GLB export·렌더에 사용했다. viewport 캡처 도구는 반복해서 빈 그리드만 돌려주므로 이를 미술 검수 성공으로 계산하지 않는다. 생성한 Blender 렌더 파일과 실제 Godot 브라우저 화면을 별도로 열어 검토했다.


후속 검수: Build `f38c2ed4-11dd-46f5-8cd5-11dbb3a032aa`의 engine-regression.json에서 348/348 판정, meeting-browser-final에서 9/9, campus-browser-final에서 4/4가 통과했다. 반복 실패 파일도 남겨 둔다. 새 화장실은 실제 캡슐로 8층 각각 공용 통로→뒤 칸→문 열기→입출구를 통과했다. 개인실 서가 회전 뒤 8개 책상의 180프레임 정착과 재접속 위치 불변이 통과했다.

브라우저 회의실 첫 F 재시험은 화면 중심이 3m 사용 범위 밖에 있어 멈췄다(campus-browser-screen-range). 사거리 규칙을 바꾸지 않고 가까운 화면 부분을 직접 조준하여 재시험했다. 의상방 첫 실패(retained-wardrobe-first-capture)는 입장 시 마우스 재캡처 클릭이 소비되는 정상 정책을 fixture가 생략한 경우였다. 실제 첫 화면 클릭을 하고 걸어가니 현장 얼굴 편집·취소·적용·재입장 9흐름이 통과했다.

편집 성능 수리: 전체 화면 회의 작업대 뒤쪽 3D만 숨긴다. 시뮬레이션·문서·네트워크는 계속 실행한다. 작업대 닫기 뒤 실제 세계로 돌아와 승강기 왕복까지 확인했다. 성능 표본과 한계는 performance-ko.md에 기록했다.
