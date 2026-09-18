# V6 인수 추적표 — 확인 수준을 구분한 기록

검수 빌드 **f38c2ed4-11dd-46f5-8cd5-11dbb3a032aa**, source **3704c4ccdd712215f6fafbddc719bd7e537153612aabea07e1a9b5a0bf468861**. 시작 HEAD `7cab26a`에서 작업했고 동일 export를 게시한다. 빌드에 남은 base commit/dirty는 제작 당시 사실이며 게시 커밋은 별도 영수증에 기록한다.

[4브라우저 회의 9흐름](../../evidence/v6/meeting-browser-final/report.json) · [실제 캠퍼스/승강기 4흐름](../../evidence/v6/campus-browser-final/report.json) · [엔진 회귀 348판정](../../evidence/v6/engine-regression.json) · [Node 회귀](../../evidence/v6/node-final.log) · [회의 정책](../../evidence/v6/meeting-policy-final.log) · [수리 기록](repair-log-ko.md).

자동 fixture는 조작 가능한 테스트 상태이며 운영 권한·실제 사람 증거가 아니다. 네 Chromium은 실제 WebGL/WebRTC지만 네 사람이 아니다. 이번 작업은 전체 V6 인수 완료가 아니다. 특히 실제 마이크/외부 계정/운영 관리자/8인 성능과 내장 프로젝트 문서 공유, 여러 접촉·미술 품질이 남아 있다.

| ID | 대상 | 확인 수준 | 실제 근거·남은 범위 |
|---|---|---|---|
| V6-T01 | 배포와 main 차이 | 확인 | baseline.json: HEAD 7cab26a / 실제 Pages codex/homeoffice-v3 / 당시 공개 9fa65de6. 현재 게시 영수증 별도. |
| V6-T02 | 불편 원문 보존 | 보존 | USER_OBSERVATIONS.md의 OBS001–012 원문 유지. 코드 사실로 불편을 종결하지 않음. |
| V6-T03 | R1/R2/R3 반영 | 부분·미술 미달 | design-decisions-ko.md, art-and-assets-ko.md, campus-browser-final 실제 화면. 세밀한 표면/명암/사용자 평가는 남음. |
| V6-T04 | 깊이흐림 없는 회의 | 자동 브라우저 실행 | meeting-browser-final: DOF 없는 큰 편집 UI. 사람 가독성 인수는 미실행. |
| V6-T05 | 모델 실제 지지 | 부분 | v5-table-support 7 / seat-contacts 20 / carry-volume 6, v6-private-rooms 14. 전체 체형/미술 접촉은 미완료. |
| V6-T06 | export 일치 | 부분 | 실제 BlenderMCP export, GLB/manifest/브라우저 확인. viewport 캡처는 검수 불가, baked 광원 미완료. |
| V6-T07 | 라이선스/키 | 기록·검사 | art-and-assets-ko.md 및 기존 라이선스 유지. 신규 외부 다운로드/유료 API/참고 이미지 재배포 없음. |
| V6-T08 | B1~RF 전체 연결 | 부분 | 8층 GLB/시설/두 코어. 모든 층 계단 fixture와 주요 층 실제 승강기 왕복. B1 지원실의 완결된 작동은 부족. |
| V6-T09 | 공용 화장실 | 물리 fixture 실행 | v6-facility-access 43: 8개 층 공용 진입·뒤 칸·실제 문·입출구. 새 변기 전체 생활 동작은 미완료. |
| V6-T10 | 계단 보행 | 물리 fixture 실행 | v6-stair-route 151: 양 U계단 B1→RF→B1 연속 캡슐 보행, 계단참/머리 공간/입구 턱. |
| V6-T11 | 읽기 쉬운 층 안내 | 구현·부분 실행 | campus.json FloorDirectory, 실제 로비 표지·승강기 패널·campus-plan.html 동일 데이터. 사용성 미인수. |
| V6-T12 | 개인실 추가 | 물리 fixture 실행 | v6-private-rooms 14: 8개 고정 슬롯/ID/높이/가구 정착/퇴장·재접속/옛 좌표 변환. 영구 계정 소유 미구현. |
| V6-T13 | 기본 왕복 | 실제 브라우저 실행 | campus-browser-final 4흐름: HOME→OFFICE, 2F 회의, 6F/RF/B1/1F 탑승·하차. 영상 포함. |
| V6-T14 | 호출 경합 | 부분 fixture | campus-physics: 반복 목적지 중복 제거와 장애물 뒤 큐 보존. 여러 실제 사람의 층간 동시 호출 미실행. |
| V6-T15 | 사람/문 끼임 | 부분 fixture | 사람 장애물 재열림, 도착층 문 정렬 실행. 실제 운반 의자 끼임 전체 조합 미실행. |
| V6-T16 | 물체/사람 탑승 | 부분 | 실제 캡슐 탑승 높이 확인. 의자 운반+점프+내려놓기 전체 흐름 미실행. |
| V6-T17 | 이동 중 재접속 | 구현·미실행 | 원격 car snapshot 보간 있음. 이동 중 실제 늦은 참가자 복원은 미실행. |
| V6-T18 | 인계/층 로딩 실패 | 부분·미완료 | 큐 snapshot/restore fixture와 도착층 hold 있음. 실제 호스트 인계·fault 복구 전체 미실행. |
| V6-T19 | ADMIN_ONLY 회귀 | 자동 회귀 | v5-court-access 35: host/이름/총/열린 문/옛 상태로 권한 승격 불가. 운영 관리자 실계정 미실행. |
| V6-T20 | 관리자/호스트 분리 | 자동 회귀 | v6-facility-access: simulation host의 운영 문/CCTV 거절. 운영 인증 설정 변경 없음. |
| V6-T21 | 가상 장면만 | 구현·부분 fixture | SubViewport 공용 B1/1F만. 웹캠/마이크 API 사용 없음. 운영 관리자 실제 CCTV 사용 미실행. |
| V6-T22 | 비공개 공간 보호 | 코드 경계·미실행 | 공용 홀 카메라 far9, 사용자 이름/자료 레이어 제외. 운영 관리자 실제 시야 침해 검수 미실행. |
| V6-T23 | 화면 종료/예산 | 부분 fixture | 미인가 닫힌 CCTV UPDATE_DISABLED 검사. 640×360/8Hz 한 화면. 실제 운영 종료/부하 미실행. |
| V6-T24 | 회의 완결 | 자동 브라우저 실행·사람 미실행 | meeting-browser-final 4독립 Chromium, 작성→발표→질문/할 일/결정→저장·새 세션 복원. 실제 사람 4명 아님. |
| V6-T25 | 두 회의 분리 | 부분 브라우저 실행 | 두 회의의 문서/보드/자료 권한 분리 확인. 실제 음성·음향 분리 미실행. |
| V6-T26 | 프로젝트 문서 공유 | 미구현 | 서로 다른 회의가 같은 내장 프로젝트 문서 원본을 명시적으로 공유하는 기능은 남음. |
| V6-T27 | 한글 IME 경합 | 부분 브라우저 실행 | CDP 한국어 IME+동시 원격 삽입 수렴 확인. OS 한글 키보드/표·목록/모든 삭제 경합 미실행. |
| V6-T28 | presence/Undo | 부분 브라우저 실행 | peer 상대 CRDT 위치 presence, 자기 Undo 확인. 영구 저장에서 presence/손들기/타이머 제외. 사람 선택·커서 사용성 미실행. |
| V6-T29 | 재접속 수렴 | 실제 연결 차단 실행 | RTCPeerConnection 종료→기기 초안→동료 온라인 변경→같은 세션 재접속/state-vector 병합. 전체 덮어쓰기 없음. |
| V6-T30 | Docs 원본 | 미실행 | Google Docs 링크 검증·원본 열기 유지. 실제 두 계정 공동편집 확인 안 됨. |
| V6-T31 | Slides/Excel 원본 | 미실행 | Google Slides/Microsoft Excel 링크 지원 유지. 실제 두 계정 공동편집 확인 안 됨. Sheets 대체 없음. |
| V6-T32 | 외부 탭 호스트 | 부분·미완료 | 숨은 host를 의도 정지하지 않음. 브라우저 throttling/원본 탭·호스트 인계 실계정 흐름 미실행. |
| V6-T33 | page/laser race | 부분 브라우저 실행 | 현재 자료 실제 PNG/레이저 4브라우저 전달. asset/page/pageRevision/presenter/sequence 거절 코드. 지연·페이지 race 전체 미실행. |
| V6-T34 | 발표자 이탈 | 부분·미완료 | 참여 중지와 stale 재가입 거절 실행. 발표자 전체 인계/다른 회의 첨부의 host handoff 사전복제는 미완료. |
| V6-T35 | 화면 공유 동의 | 미실행 | 기존 사용자가 선택하는 화면 공유 경로 보존. 실제 화면 선택/종료 consent 시험 미실행. |
| V6-T36 | 층간 프라이버시 | 구현·미실행 | 회의 참여+층 높이로 음성/자막 범위 제한. 실제 마이크/포털 음향·차음 미실행. |
| V6-T37 | 방송 실제 종료 | 구현·미실행 | 5F 방송 콘솔과 기존 방송 경로·ON AIR 보존. 운영 관리자 실제 송출/종료 미실행. |
| V6-T38 | 한국어 실제 마이크 | 미실행 | 실제 한국어 마이크/CER/지연 측정 없음. 합성 테스트로 대체하지 않음. |
| V6-T39 | 파일 동시 부하 | 부분 | 기존 메신저/파일 코드 및 Node 회귀 유지. 음성+문서+취소/재시도 결합 부하 미실행. |
| V6-T40 | DM/퇴장/보존 | 부분 | 기존 DM 권한/첨부 가용성 경로 보존, Node 회귀. 이번 실제 다자 DM 회귀 미실행. |
| V6-T41 | 드래그 설치 | 부분·브라우저 10흐름 통과 | V5 placement 10 fixture. 실제 옆 패널 회귀 결과는 retained-placement/report.json 참조. |
| V6-T42 | 포커스 차단 | 부분 브라우저 실행 | 회의/승강기 UI 키 입력 차단·닫기 후 보행. 설치/의상은 retained UI 결과 참조. 모든 PIN/throw 조합 미실행. |
| V6-T43 | 가시성/보행 | 부분 | v5-motion-matrix 14, 연속 계단 물리. 실제 3인 양방향 미술/발 접촉 품질 인수 미실행. |
| V6-T44 | 좌석/운반 | 부분 | seat/carry fixture 회귀. 체형 극단·다인 소파·손 관통 근접 품질 남음. |
| V6-T45 | 의상방/얼굴 | 부분·브라우저 9흐름 통과 | v5-wardrobe 21. retained-wardrobe/report.json: 현장 클릭/얼굴/취소/재입장. 체형·옷 fitting 전체 미완료. |
| V6-T46 | 실제 생활 흐름 | 부분 | v5-retained-living-props 12. HOME 보존과 6F 기존 조리 설비. 실제 사람의 전체 생활 흐름 재검수 미실행. |
| V6-T47 | 기존 게임 유지 | 부분 | V5 court/motion/combat 경로 보존. V5 검수표의 미완료 스포츠·전술·접촉을 V6 완료로 승계하지 않음. |
| V6-T48 | 기존 파일 변환 | 부분 fixture | campus migration은 원본 복사/옛 개인실 ID와 높이/충돌→미배치/수납 관계/idempotence 검사. 실제 사용자 모든 과거 파일 미실행. |
| V6-T49 | 전체 왕복 | 부분 브라우저 실행 | 2회의 문서·보드·1PNG첨부 export→새단독세션 import 성공. 전 층 모든 변경+프로필 전체 왕복은 미완료. |
| V6-T50 | 실패 원자성 | 부분 자동 검사 | Node archive/hash/version/첨부 검증, UI preview→백업→엔진 응답→자료 전환. 모든 실패 시점 fault injection 미실행. |
| V6-T51 | 비밀 미포함 | 자동 검사 | strict schema의 허용 필드만 저장/복원. PIN/token/admin lease 미포함. presence/손들기/타이머 일시 상태 분리. |
| V6-T52 | 다층 결합 부하 | 품질 미달·미실행 | 4프로세스 실제 fps/p95만 기록. 2/4/8인+실제 음성+엘리베이터+CCTV 결합 목표는 미실행/미달. |
| V6-T53 | 휴면/재활성 | 부분 | 층별 외피/내부·문/가구 시각 culling, 편집 UI 뒤 3D만 숨김. 물리/문서 유지. 모든 활동 결합 검수 미실행. |
| V6-T54 | 교육용 카피 격리 | 자동 회귀 | 표시 문자열 모듈 독립. V5 placement UI의 문자열 변경 후 권한 불변 검사를 같은 빌드로 재실행. |
| V6-T55 | 같은 빌드 증거 | 게시 확인 전 | Build/source/91 file manifest 연결. publication/receipt.json의 실제 공개 HTTP·Build·브라우저·GitHub 결과가 최종 근거. |
| V6-T56 | 사용자 재확인 | 사용자 재확인 대기 | 사용자 OBS 원문, 실패/수리/재시험 증거를 보존. 기술 실행을 사용자 만족으로 대체하지 않음. |
