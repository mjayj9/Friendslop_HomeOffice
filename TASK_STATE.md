# COMMONS WORKSPACE — 진행 상태

2026-09-17 KST. **V4 전체 미완료. 사용자가 현재 변경의 커밋·푸시·기존 Pages 검토 배포를 승인했다. Firebase/별도 인증 서버 변경은 포함하지 않는다.** 최신 통합 명세를 유지하며 기존 세계를 작은 시제품으로 교체하지 않았다.

## 현재 빌드

| 항목 | 값 |
|---|---|
| 실제 저장소 | `deployment/Friendslop_HomeOffice` |
| 작업 브랜치 | `codex/commons-workspace-v4` |
| V4 작업 시작 기준 HEAD | `d67dd929cc719fb3e7e72626e59fc9bd9050a2d9` |
| 검토 배포 Build ID | `cc2f8fbd-ba33-4601-b716-82bb26422424` |
| 이번 source digest | `d3f3b1f7bc2bd3343825fd5705089bd5a7807f1fb7cb8ccc3e333d5c12a62514` |
| 엔진 / 프로토콜 / 자산 / 저장 | Godot 4.6.1 / 4 / 3 / 2 |
| 로컬 export | 73파일 hash 일치, `homeoffice/build` |
| Pages 게시 대상 Build ID | `cc2f8fbd-ba33-4601-b716-82bb26422424` |
| Pages 게시 대상 source digest | `d3f3b1f7bc2bd3343825fd5705089bd5a7807f1fb7cb8ccc3e333d5c12a62514` |
| 기존 Pages 배포 ref | `codex/homeoffice-v3`, URL 유지 |

배포 전 기록: 2026-09-17 02:30 KST 공개 main·Pages 응답 재확인. `/pages` 관리 API는 404로 설정 자체 미확인. 공개 67파일은 별도 hash 검증 통과. [원격 증거](homeoffice/evidence/v4/remote-audit.json), [로컬 manifest](homeoffice/evidence/v4/build-info.json).

명세: [최신 원본](homeoffice/docs/v4/master-spec-ko.md), [이전 감사](homeoffice/docs/v4/prior-audit-ko.md), [Q01–Q32](homeoffice/docs/v4/verification-ko.md), [모듈/저장 경계](homeoffice/docs/v4/implementation-map-ko.md), [미술 기준](homeoffice/docs/v4/art-direction-ko.md).

## 최근 구현과 직접 관찰

- 기본 3인칭/C 전환/휠 줌/구체 카메라 충돌/어깨 조준/카메라 기준 이동을 기존 avatar에 조합했다. `scripts/player/camera_rig.gd`, `scripts/v2/avatar.gd`. V4 세계 상속 클래스는 추가하지 않았다.
- E/Q/F/좌클릭/R 우선순위를 유지하고 C/Ctrl 바인딩, UI 포커스 해제·연사 취소를 연결했다. `web/bridge.mjs`, `key-bindings.mjs`, `scripts/v3/world.gd`.
- 활성 V2/V3 경로의 개인 entry/weapon grants, 구역 사격 금지, 교실 무기 차단, 자동 회수/이전 승인 UI를 제거했다. 총 소유권·세션·쿨다운·벽·방패·HP/KO는 유지했다.
- 방별 정책/실제 관리자 신원+PIN 검증 서버를 분리했다. 공개 서명 검증, 만료/nonce/revision, PIN KDF, 실패 제한, 방송 lease, 퇴실/공용 경로, 문 점유, 잠긴 방 KO 복귀 보호를 구현했다. `server/*`, `web/room-*.mjs`, `scripts/security/room_access.gd`.
- 사용자 답변에 따라 Clerk JavaScript/Node.js adapter를 준비했다. 사용자가 지정한 `app_3JPx7wBJ683SFfndYIqhAHGOKeX`의 실제 Clerk 개발 공개 설정은 연결했다. 관리자 UID·PIN 검증 서버는 아직 미설정이다. 현재 게임의 잠금·관리 방송은 비활성이며 원인을 UI에 표시한다. [설정 순서](homeoffice/docs/v4/clerk-setup-ko.md).
- 메신저를 세션/공간/DM, 읽음/답장/반응/수정/삭제/검색, P2P 파일/썸네일/다운로드/취소/이어받기/오프라인 안내로 교체했다. 비수신자 DM 중계 차단. 호스트는 DM을 읽을 수 있고 세계 저장에는 포함하지 않는다. `web/messenger.mjs`, `chat-protocol.mjs`, `attachment-policy.mjs`.
- BlenderMCP 9876에서 실제 author/export 실행, 회의실 테이블/의자/흡음 패널/선형 조명/사인을 기존 상호작용과 결합했다. Blender 5.2.1 LTS, addon protocol 5 / server 기대 7 차이를 기록하고 임의 업데이트하지 않았다. 기존 씬을 보존했다. `art/author_v4_meeting.py`, `pack_export.py`, `.blend`, `assets/v4`, `scripts/world/meeting_finish.gd`.
- 원본 남성 GLB 5개와 13 bones / 62 animations 파생본이 있다. 추가 업로드를 요청하지 않았다. 이 개수를 접촉 품질 인수로 삼지 않는다.

## 최근 실행 결과

- 사용자 요청의 검토 배포를 위해 현재 `cc2f8fbd…`에서 실제 UI **26/26(14+5+7)**, Node **33/33**, artifact 회귀 **6/6**, Clerk 합성 JWT **1/1**, 실제 PCK **318경로/금지 0**을 다시 확인했다. `docs/`와 로컬 export 모두 **73파일/source hash 일치**. [배포 기록](homeoffice/docs/v4/review-deployment-ko.md), [집계](homeoffice/evidence/v4/review-deployment.json). 이전 빌드 결과와 합산해 새 빌드 통과 수를 부풀리지 않는다.

- 현재 Clerk 연동 Build ID `cc2f8fbd-ba33-4601-b716-82bb26422424`: 정확한 `http://localhost:5173/`에서 실제 Clerk SDK/로그인/가입/게임 입력 차단 **4/4**, 합성 구성 UI **2/2**, Node 회귀 **33/33** 통과. [실제 Clerk 화면/영상 보고서](homeoffice/evidence/v4/clerk-local/report.json). 실제 사용자 계정 로그인 완료와 관리자 권한 검증은 아직 확인 대기다.
- Clerk CLI 3.3.0 설치, 사용자 브라우저 인증 완료, 지정 앱 link 완료. `init`은 `framework_undetected`로 기존 Godot를 자동 scaffold하지 못해 공식 JavaScript CDN 방식으로 연결했다. `doctor`는 인증/앱 연결 정상, production 미설정·env 파일 없음 경고 2개. Secret Key/env 파일을 만들지 않았으며 공개 JS 설정만 사용한다.
- 직전 통합 Build ID `fa3e62b2-1222-43f9-bbcc-662894987f1e`의 실제 UI: 메신저/카메라 **14/14**, 회의실 **5/5**, 전역 사격 **7/7** 통과, 브라우저 console/page 오류 0. [최종 집계](homeoffice/evidence/v4/final-verification.json).
- 직전 통합 빌드 엔진: 9개 실행 묶음, **112개 assertion + 드리블 물리 측정** 통과, 종료/스크립트 오류 0. 사람 플레이를 대신하는 결과가 아님.
- 실제 회의실 UI에서 내보낸 67개 사물/2개 개인실 슬롯/내장 한국어 문서 파일을 복원. 저장 schema가 PIN/토큰/채팅/roomLocks 삽입을 거절. 이번 저장 파일의 발표 첨부는 0개이므로 첨부 전체 왕복 통과로 표시하지 않음.
- Node 회귀 33/33, 공식 Clerk SDK 합성 JWT 1/1, Clerk 연결 단계 UI fixture 2/2 통과. 실제 Clerk 계정 로그인 성공이 아니다.
- 실제 PCK를 빈 프로젝트에 탑재해 318개 경로 검사. server/art/tests/evidence/web/비공개 설정/PEM 경로 0. 실제 초기 PIN 값을 읽거나 비교하지 않았다. [PCK 검사](homeoffice/evidence/v4/package-audit.json)
- 현재 source/export 73파일 및 기존 공개 V3 export 67파일 hash 각각 통과. `git diff --check` 종료 0 (Windows EOL 정규화 경고만 있음).
- 시험 방식: 한 PC 독립 Chromium의 실제 키/마우스·WebGL·WebRTC. 자동 플레이이며 실제 두 사람/외부 계정/마이크/WAN 검증이 아니다. 각 보고서의 Build ID와 영상 경로를 확인한다.

## 발견 → 수정 → 재시험

- 발신자 퇴장 후 DM 선택 목록에서 이력이 숨겨짐 → 오프라인 수신자 유지 → 실제 제공자 프로세스 종료 후 이력/파일 안내 통과.
- `ea7d95ca-…`에서 전송률 갱신마다 전체 DOM을 교체해 취소 클릭 시간 초과 → 진행률 텍스트만 갱신 → `d37cc7c9-…`에서 같은 취소 버튼 보존/취소/이어받기/완료 통과.
- KO 복귀가 잠긴 게임방으로 들어갈 수 있음 → 공개 홀 대체 복귀 → 잠금/해제 두 상태 엔진 회귀 통과.
- 회의실 편집용 개별 mesh의 비용 → Blender 원본 보존 후 export용 material surface 통합. 기능을 실제 게임에서 재검증. 전체 미술 인수와 성능 목표 달성으로 간주하지 않음.

## 우선 결함·미완료와 재현

| 우선 | 담당 파일 | 재현/남은 조건 |
|---|---|---|
| P0 운영 인증 연결 | `server/*`, `web/admin-config.mjs`, `room-admin.mjs` | Clerk 앱/계정 UI는 연결됨. 첫 화면에서 실제 게임 계정 로그인/UID 확인 후 PIN 서버·HTTPS 운영 경로를 연결해야 함. 비용·호스팅 범위를 확정하기 전 서비스 생성 안 함 |
| P1 대표 미술/성능 | `art/*v4*`, `world/meeting_finish.gd`, 기존 world 조명 | 회의실 좌석·스크린 프레임의 재질/접촉 그림자/글자 대비 부족. 균형 품질 두 브라우저의 FPS 샘플은 정식 부하 기준 미달 판단을 해소하지 못함 |
| P1 신체/조작 품질 | `v2/avatar.gd`, `player/contact_ik.gd`, `camera_rig.gd` | 손 그립·발 접촉·계단/천장·회전·스포츠/요리 전이를 사람 영상으로 검수해야 함 |
| P1 실제 협업 | documents/collaboration/presentation/board | 내장 한국어 회의록 성공. Google Docs/Slides/Excel 원본 공동편집/임베드·외부 창 전환·3D 레이저는 실제 계정/기기 검증 남음 |
| P1 스포츠·러너 | `scripts/sports/*`, `web/arcade.mjs` | 기존 물리/규칙 회귀는 통과. 이번 빌드에서 두 사람의 농구·축구 완결 경기와 러너 시작→실패→재시작→관전 미실행 |
| P1 음성·방송 | bridge/captions/broadcast/room-admin | 실제 마이크/CER/지연·전체/근거리/방송 종료 및 첨부 동시 부하 미실행 |
| P2 메신저 확장 | messenger/chat-protocol | 멘션·장기 보존·알림 설정·Office 첨부 미구현. 호스트 이전 시 기존 이력은 각 수신자의 읽기 전용, 진행 전송 중단/새 대화 재공유 필요 |
| P2 전체 생활·구조 | V2/V3 world, bridge, save | 전 공간 미술·개인실 반복 확장·선택 공개 첨부 내보내기·책임 추가 분리·장시간 8인 부하 남음 |

## 바로 다음 작업

사용자 검토 배포 후 실제 [Pages build-info](https://mjayj9.github.io/Friendslop_HomeOffice/build-info.json)와 Actions에서 위 Build ID/배포 commit을 확인한다. `node homeoffice/tests/v4-public-smoke.mjs`로 공개 원본의 Clerk 창·두 독립 클라이언트·카메라/한국어 채팅을 시험한다. 결과는 비공개 설정이 없는 로컬 `.runtime/public-review-smoke/report.json`에 기록한다.

인증의 다음 단계는 사용자가 **http://localhost:5173/** 첫 화면에서 회원가입/로그인해 `로그인됨`과 자신의 사용자 ID를 확인한다. 현재 CLI 로그인은 완료됐지만 게임 계정 로그인은 별개다. 이 실제 사용자 UID를 서버 관리자 allowlist에 명시적으로 연결한다. 첫 시뮬레이션 참가자에게 자동 관리자 권한을 주지 않는다. 이후 비공개 PIN 서버를 로컬에서 검증하고, 원격 배포는 비용·저장소·도메인·변경 영향이 구체화된 뒤 승인된 범위에서 수행한다.

인증 정보와 무관하게 진행할 다음 구현은 대표 회의실 재질·접촉 그림자·발표 화면 대비와 실측 성능의 개선이다. 원래 명세의 다른 항목을 삭제하거나 완료로 간주하지 않는다. 이 파일은 다음 실행의 상태 기록이며 대화 종료 뒤 작업을 계속한다는 의미가 아니다.

## 실행 위치와 명령

- 모든 경로는 실제 저장소 기준. Godot 실행 파일은 바깥 workspace의 `homeoffice/.runtime/godot/Godot_v4.6.1-stable_win64_console.exe`다.
- 로컬 새 빌드: `homeoffice/tools/build.ps1 -Godot <위 실행 파일> -LocalOnly`.
- 검증: `python homeoffice/tools/site_artifact.py verify homeoffice/build --source`; 공개 V3만 검사할 때는 `verify docs`.
- 단위 회귀: `cd homeoffice; npm test`. UI는 저장소 루트에서 `node homeoffice/tests/v4-browser-flow.mjs`, `v4-meeting-flow.mjs`, `v4-play-flow.mjs`.
- 2026-09-17 17:18 KST 재연결: 5173/8065/9001 수신 프로세스가 없고 localhost 연결 거부를 확인. 같은 빌드로 **`http://localhost:5173/`** HTTP와 9001 로컬 signaling을 Node PID 24808로 재실행했다. 두 서비스 HTTP 200, 실제 Godot 로딩/Clerk 로그인 창 표시/브라우저 page 오류 0을 새 독립 Chromium에서 확인했다. 사용자 로그인 세션은 검사하지 않았다. 복구 결과는 `homeoffice/.runtime/reconnect-check.json`. 후속 배포 검수에서 8065 보조 서버를 PID 26236으로 실행했다. 기준 V3 8064 서버는 실행하지 않았다.
- Windows sandbox helper ACL 오류 때문에 CUA/이미지 도구 실행이 실패해 승인된 shell의 Playwright·실제 화면 캡처를 사용했다. 도구 실패를 숨기거나 Blender 뷰포트를 게임 캡처로 바꾸지 않았다.
