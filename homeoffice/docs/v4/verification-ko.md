# V4 검증 기록과 Q01–Q32

**전체 V4 미완료. 이 문서는 최종 인수 통과 선언이 아니다.** 최신 명세는 [master-spec-ko.md](master-spec-ko.md)이며, 원래 기능과 품질 목표를 이 표의 현재 구현 범위로 축소하지 않는다. 현재 빌드·우선 결함·다음 작업은 [TASK_STATE.md](../../../TASK_STATE.md)에 기록한다.

## 2026-09-17 검토 배포 재검증

검토 배포 빌드는 `cc2f8fbd-ba33-4601-b716-82bb26422424` / source `d3f3b1f7bc2bd3343825fd5705089bd5a7807f1fb7cb8ccc3e333d5c12a62514`다. 사용자 배포 요청 이후 **카메라/메신저 14개 + 회의실 5개 + 전역 사격 7개를 이 빌드에서 다시 실행해 모두 통과**했다. 실제 Clerk 개발 SDK 로그인/가입/입력 차단 4개와 구성 UI 2개는 같은 빌드의 기존 결과다. Node 33개, 공개 artifact 회귀 6개, Clerk 합성 JWT 1개, PCK 318경로 검사를 재실행했다. [배포 검수 집계](../../evidence/v4/review-deployment.json), [Clerk 화면 결과](../../evidence/v4/clerk-local/report.json). 실제 사용자 계정 로그인·PIN 서버 인수는 아직 미완료다.

## 빌드와 증거의 구분

- 기준 HEAD: `d67dd929cc719fb3e7e72626e59fc9bd9050a2d9`. 작업 브랜치는 `codex/commons-workspace-v4`다. 사용자가 후속 요청으로 검토 배포를 승인했다.
- 배포 전 공개 V3의 Build ID는 `52b4edbc-4abd-4619-bea4-463db1278f2b`, source digest는 `858aac6def60e9f92c7ef4cd54c57039b7ed0d4842b7e51fa1b823b159b6c430`이다. 최신 확인된 Pages run `35106271065`는 `codex/homeoffice-v3`의 기준 HEAD를 배포했다. 관리용 `/pages` API는 404여서 설정 자체를 읽었다고 주장하지 않는다. [원격 확인](../../evidence/v4/remote-audit.json)
- 새 로컬 빌드의 식별자와 파일별 SHA-256은 [build-info.json](../../evidence/v4/build-info.json)에 있다. [UI 실행 묶음](../../evidence/v4/ui-suite.json)과 [엔진 실행 묶음](../../evidence/v4/engine-suite.json)의 Build ID를 함께 비교한다. 이번 검토 배포는 같은 V4 artifact를 `docs/`에 게시한다. 공개 반영은 [build-info](https://mjayj9.github.io/Friendslop_HomeOffice/build-info.json)와 Pages 실행의 commit으로 확인한다.
- `evidence/v3`는 이전 검증 기록이다. 이번 검증은 `evidence/v4`이며, 실패를 발견한 이전 로컬 빌드의 보고서·화면은 `evidence/v4/iterations/<buildId>`에 보존한다. 이전 영상은 각 보고서의 절대 경로로 연결된다.

코드와 함수의 존재, 제어된 엔진 fixture, 실제 브라우저 UI 입력, 실제 사람이 서로 다른 기기에서 수행한 사용 검증을 구분한다. 이번 브라우저 검증은 한 Windows PC의 독립 Chromium 프로세스와 실제 Godot WebGL·로컬 PeerJS 연결을 사용한 자동 입력이다. 실제 두 사람, WAN, 실제 마이크, Google/Microsoft 계정 검증을 대신하지 않는다.

과거 엔진/통합 기록(이번 UI 보고서와 구분): **`fa3e62b2-1222-43f9-bbcc-662894987f1e`**, source **`2af1fa865757671b234ac519bc8c9ba7f532fae9fe79cbed03ee486ebba79bfb`**. 같은 빌드의 UI 14+5+7개와 엔진 112개 assertion/드리블 측정이 통과했다. [결과 집계](../../evidence/v4/final-verification.json). Node 33개, Clerk 합성 JWT 1개, 설정 단계 UI 2개, 실제 PCK 318경로/금지 경로 0개를 별도로 확인했다.

## 이번 실제 실행

| 증거 | 직접 확인한 범위 | 남은 한계 |
|---|---|---|
| [메신저·카메라 보고서](../../evidence/v4/browser/report.json) | 3브라우저 몸체, C 전환/줌, 포커스, 한국어 DM, 파일 바이트 수신·다운로드 hash, 취소/이어받기, 이미지 decode, 제공자 퇴장 | 테스트별 결과를 확인한다. 실제 사람의 한글 IME 조합과 실네트워크 음성 동시 부하는 별도 |
| [회의실 보고서](../../evidence/v4/meeting-browser/report.json) | 직접 걸어서 입장, F 좌석/R 자료, 두 클라이언트 내장 한국어 회의록, 문서 입력 차단, 세계 파일 왕복 | 내장 문서는 Google Docs가 아니다. 외부 원본 계정 공동편집 미실행 |
| [전역 사격 보고서](../../evidence/v4/play-browser/report.json) | 고정 교실 세션, 실제 F 문/E 총, 어깨 조준, 게임방→오피스→마당→회의실→HOME 이동·사격, HP/KO/킬/복귀 합치 | 자동 입력이며 실제 사람의 조준감·경기 결과 인수는 남음 |
| [엔진 묶음](../../evidence/v4/engine-suite.json) | 기존 생활·점유·물리·스포츠·저장·호스트 이전, 새 카메라·방 잠금 | 통제된 위치/명령 fixture. 사람 플레이나 미술 인수 증거가 아님 |
| [Node 회귀](../../evidence/v4/all-node-tests.log) | 33개: 저장, 초대/게시자료, 러너 규칙, 방송/자막 범위, 상태 압축, 채팅 라우팅/형식, 관리자 정책 | 실제 외부 서비스와 마이크는 포함하지 않음 |
| [Clerk SDK](../../evidence/v4/clerk-adapter-tests.log), [관리 UI](../../evidence/v4/admin-ui.json) | 공식 SDK의 합성 JWT 검증 및 연결 단계의 UI fixture | 실제 Clerk 계정 로그인 성공 기록이 아님 |
| [저장 검사](../../evidence/v4/save-inspection.json) | 실제 내보낸 파일의 schema/checksum/항목 검사, 임의 PIN·채팅·잠금 항목 삽입 거절 | 실제 운영 PIN은 로드하지 않았음. 외부 원본 내용 백업과 채팅 첨부 내보내기는 지원하지 않음 |

실제 게임 화면:

- [일반 3인칭](../../evidence/v4/browser/01-third-person.png), [1인칭](../../evidence/v4/browser/02-first-person.png)
- [회의실 1인칭](../../evidence/v4/meeting-browser/01-meeting-first-person.png), [3인칭](../../evidence/v4/meeting-browser/02-meeting-third-person.png), [좌석 자료](../../evidence/v4/meeting-browser/03-seated-documents.png), [공동 회의록](../../evidence/v4/meeting-browser/04-shared-korean-notes.png)
- [받은 파일](../../evidence/v4/browser/04-received-files.png), [제공자 오프라인](../../evidence/v4/browser/05-provider-offline.png)
- [총 어깨 시점](../../evidence/v4/play-browser/00-shoulder-aim.png)

위 화면은 Chromium이 실행한 게임 캡처다. Blender 렌더나 생성 이미지를 게임 화면으로 사용하지 않았다. 각 보고서의 `videos`는 해당 실행의 WebM 경로다.


동일 검토 배포 빌드의 자동 입력 영상(실제 사람 촬영이 아님):

| 흐름 | 영상 |
|---|---|
| 메신저 A/B/C | [A 영상](../../evidence/v4/browser/page@d2be6e57cf550c97546bddf5936893b9.webm) · [B 영상](../../evidence/v4/browser/page@03db76fe04ea9c4ee18f41ea339347c3.webm) · [C 영상](../../evidence/v4/browser/page@f98fe838c1cfe49b1bc3c2f6c3b3dcca.webm) |
| 회의실 A/B | [A 영상](../../evidence/v4/meeting-browser/page@c06cd97149de8b7dcdbd7f52e501275f.webm) · [B 영상](../../evidence/v4/meeting-browser/page@24439e0c58b42d3c99c7a5d84a6ff071.webm) |
| 전역 사격 A/B | [A 영상](../../evidence/v4/play-browser/page@ea81599542f8f81b4ccd39444eba4f6c.webm) · [B 영상](../../evidence/v4/play-browser/page@6264c768e74e740a7f827a4fec864509.webm) |

## Q 추적

`부분 통과`는 적힌 하위 시나리오만 확인했다는 뜻이다. `미실행`은 기능 없음과 다르다. `품질 미달`은 코드/화면이 있어도 요구 수준을 인수하지 않았다는 뜻이다.

| ID | 현재 판정 | 이번 증거와 남은 조건 |
|---|---|---|
| Q01 | 부분 통과 | 실제 3프로세스가 2개 원격 몸체를 각각 생성하고 이동·퇴장을 관찰. 새 빌드의 전체 늦은 입장/재접속/양방향 행동 인수는 남음. 메신저 보고서 |
| Q02 | 부분 통과 | 실제 C 1↔3인칭/휠/몸 표시, 사격 어깨 시점. 벽 sphere sweep·수면 후 모드 복원은 카메라 fixture 통과. 실제 수면/전이 전수 영상은 남음 |
| Q03 | 부분 통과 | 실제 회의실 출입·좌석·연결 통로 이동. 문이 점유자 위로 닫히지 않는 엔진 시험. 계단/낮은 천장/모든 체형 교행은 미실행 |
| Q04 | 부분 통과 | 실제 채팅·문서 입력에서 W/C 차단, 닫기 후 이동, 연사 중 Enter가 발사 취소. 실제 한국어 IME 조합과 운영 PIN 입력은 미실행 |
| Q05 | 품질 미달 | 원본 남성 GLB 5개와 13본/62클립 파생본 확인. [원본 검사](../../evidence/v4/character-inspection.json). 클립 수를 자연스러운 손·발 접촉 인수로 간주하지 않음. 보행 속도 수정 외 전이/그립 검수 남음 |
| Q06 | 품질 미달 | Blender 원본→GLB→게임 회의실, 가구 비례·흡음 패널·조명·사인 추가. 실제 화면에서 재질 대비/접촉 그림자/스크린 글자 대비가 부족함. HOME/욕실/마당 등 전체 미술 마감 미완료 |
| Q07 | 부분 통과 | 실제 F 문/의자·E 총·클릭 사격·R 자료. 책/컵/마카/가구/방패 등은 기존 기능 및 일부 fixture. 모든 샘플 실제 UI 전수 미실행 |
| Q08 | 부분 통과 | 실제 좌석 점유 원격 표시·기립, 엔진 수납/전등/요리/식사/설거지/취침·점유 이동 차단 회귀. 모든 생활 흐름의 이번 브라우저 검증 미실행 |
| Q09 | 부분 통과 | 24개 공간 독립 정책, 서버 관리자+PIN 검증, 엔진 잠금/해제/퇴실/공용 통로/KO 안전 복귀. 현재 서비스 미설정이므로 운영 빌드에서는 잠금 비활성. 실제 다중 기기 PIN UI 미실행 |
| Q10 | 부분 통과 | 합성 신원으로 학생 호스트/위조 role 거절, 클라이언트는 검증 공개키만 사용, server 폴더 export 제외. 초기 비공개 메모를 코드/파일로 복사하지 않음. 실제 UID·운영 키/ACL 설정은 남음 |
| Q11 | 부분 통과 | 서버 5회/15분 시도 제한, revision/nonce/세션/서명/만료 검사, 독립 salted scrypt, 세계 복원으로 현재 정책 변경 불가. 실제 운영 재시작·키 회전·외부 서비스 장애 인수는 남음 |
| Q12 | 자동 UI 통과 | 고정 교실 플래그가 켜진 같은 세션에서 게임방·오피스·마당·회의실·HOME으로 총을 들고 걸어가 실제 발사. 이동 중 회수 없음. 기존 개인 허가 조건 제거. 전역 사격 보고서 |
| Q13 | 부분 통과 | 실제 누르고 연사, 두 클라이언트 HP=0/KO/kill=1/meter=25/복귀 HP=100 합치. 소유권·쿨다운·벽·방패 회귀는 엔진 fixture. 명시적 경기 결과까지 사람 플레이 미실행 |
| Q14 | 부분 통과 | 실제 UI 연사 취소, camera aim→muzzle 경로 및 벽/방패 fixture 유지. 문서 클릭/가려진 총구를 같은 실제 두 사람 영상으로 전수 확인하지 않음 |
| Q15 | 미실행(사람 경기) | 기존 드리블·스핀·스틸·슛·득점 구현과 이번 물리 fixture 보존. 실제 두 사람이 드리블→스틸→패스→백스핀/림→득점→종료→재시작한 경기 미실행 |
| Q16 | 미실행(사람 경기) | 손 집기 차단·발 터치·패스·슛·골의 기존 구현/이번 fixture. 지연 조건의 실제 두 사람 축구 완결 경기 미실행 |
| Q17 | 부분 통과 | 실제 DM 전달/읽음/반응/수정/답장/검색/삭제 및 비수신자 C의 RTC data-event에서 chat 패킷 0 확인. 일반/Zone 라우팅·권한 규칙은 Node 시험도 있음. 멘션 및 호스트 이전 뒤 연속 이력은 미구현 |
| Q18 | 부분 통과 | 실제 파일 선택→P2P 바이트→TXT 다운로드 SHA-256 일치, PNG decode, 취소/오프셋 이어받기, 제공자 퇴장 후 DM 유지·오프라인 안내. 실제 Clipboard API→Ctrl+V 이미지 전달과 모의 DOM drop→TXT 전달도 통과. 네이티브 파일 탐색기 드래그와 이미지 확대 인수는 남음 |
| Q19 | 부분 통과 | 파일명·시그니처·이미지 차원/픽셀·동시 전송·chunk 검증. 전송 중 C 이동 관찰. 실제 음성/STT 동시 대파일 부하 미실행. 악성코드 검사 완료라고 표시하지 않음 |
| Q20 | 미실행 | Google Docs/Slides/Excel 원본 링크 기능 보존. 이번 실제 두 계정 공동편집/서비스별 embed 허용 확인 없음. 내장 문서 성공을 해당 서비스 성공으로 바꾸지 않음 |
| Q21 | 부분 통과 | 실제 두 브라우저가 내장 한국어 회의록에 쓴 내용이 수렴. 보드 update/동시 버전/Undo는 엔진 fixture. 전체 마인드맵·재접속·Undo 결합 시나리오는 남음 |
| Q22 | 부분 통과 | 기존 실제 물리 광선→presentation collider→UV→페이지/발표자 검증 경로 보존 및 authority fixture. 새 빌드 실제 원격 3D 레이저 영상 미실행 |
| Q23 | 부분 통과 | 실제 회의실 좌석·내장 기록·파일 저장 왕복. 발표→질문→결정→담당/기한 및 외부 창 전환/음성까지 실제 회의 미실행 |
| Q24 | 미실행 | 기존 한국어 STT 코드 보존. 실제 한국어 마이크 CER/지연/FPS·잡음/오류 UX를 이번에 측정하지 않음 |
| Q25 | 부분 통과 | 근거리/현재 공간/전체 음성 코드와 자막 범위 회귀. 원음 기본 저장 없음. 잠긴 방에 대한 기밀 음성 경계·실제 마이크·퇴장 트랙 부하 검증 미완료 |
| Q26 | 부분 통과 | 기존 방송 콘솔/ON AIR/범위/종료 경로 보존, 학생 호스트 권한을 서버 검증 관리자 lease로 대체. 미설정 빌드 방송은 명시적으로 비활성. 실제 운영 방송 미실행 |
| Q27 | 부분 통과 | 개인실 8인 한도/복도 자동 확장 보존, 슬롯/가구/호스트 이전·저장 fixture. 실제 새 빌드 반복 입퇴장/확장 인수 미실행. 8명보다 큰 팀을 지원한다고 주장하지 않음 |
| Q28 | 부분 통과 | 실제 짧은 방 코드 입장과 고정 교실 2클라이언트 입장. 입력 epoch/자리/시점의 호스트 이전 fixture. 현재 빌드 URL 복사·호스트 종료 복구·동시 입장 전체 재시험 남음 |
| Q29 | 부분 통과 | 실제 UI 세계·내장 문서 파일 왕복, strict schema/hash 검증. 외부 문서는 원본 링크만 저장. 메신저/DM/PIN/원음 제외. 선택 공개 채팅 첨부 내보내기 미구현 |
| Q30 | 품질 미달 / 미실행 | 실제 WebGL 보고서에 FPS/draw 통계 샘플은 있으나 통제된 장시간·동시 음성/STT·대파일·메모리/큐 측정 아님. 낮음/균형 품질의 다른 조건 값을 정식 비교로 쓰지 않음 |
| Q31 | 부분 통과 | 로컬 source/export 73파일 hash 및 엔진/웹 Build ID 확인. 공개 V3 67파일은 별도 유지. 새 V4 운영 배포·실제 Pages 캐시 재접속 검증 미실행 |
| Q32 | 반복 수정 증거 있음 / 인수 미완료 | 아래 실패→수정→재시험 기록, 모든 Q의 남은 범위 명시. 사용자 미술 인수와 실제 사용 검증을 자기평가 점수로 대체하지 않음 |

## 관찰 → 수정 → 재시험

1. 기준 V3의 일반 탐색에서 자기 몸이 숨겨지는 실제 프레임을 확인했다. [기준 캡처](../../evidence/v4/baseline-v3.png). 별도 CameraRig를 기존 아바타에 조합하고 기본 3인칭/C/줌/벽 충돌을 구현했다. 실제 C 전환과 카메라 fixture로 재시험했다.
2. 새 카메라의 yaw와 몸 방향이 달라지는 상황을 확인해 이동을 카메라 기준으로 계산하고 조준·손 도구와 몸 회전을 연결했다. 호스트 이전의 look yaw 보존 회귀를 추가했다.
3. 첨부 제공자 퇴장 시 DM 선택 목록에서 상대가 사라져 이력까지 숨겨졌다. 현재 멤버와 이전 수신자 이력을 함께 표시하도록 수정하고 실제 제공자 브라우저 종료로 다시 확인했다.
4. Build `ea7d95ca-e973-4c73-8930-6a42f1a4980e`의 재시험에서 수신 진행률마다 전체 메시지 DOM을 교체해 취소 버튼 클릭이 실패했다. 진행률 텍스트만 갱신하도록 수정했다. `d37cc7c9-721f-4093-8427-c03865de6f71`에서 같은 버튼 노드 유지, 실제 취소, 오프셋 보존, 재개, 최종 hash 수신을 재확인했다. 앞선 성공 한 번을 안정성의 증거로 삼지 않았다.
5. 게임방이 잠겼을 때 KO 복귀가 잠금을 우회할 수 있는 코드를 발견했다. 잠겨 있으면 공개 홀로 복귀하도록 수정하고 잠금/해제 두 상태를 엔진에서 시험했다.
6. 실제 회의실 화면에서 새 가구와 기존 기능 좌표를 함께 검토했다. Blender 개별 오브젝트를 export 전 정적 material surface별로 합쳤으며 원본 편집 씬은 보존했다. 실제 게임에서 좌석/자료/전등을 재시험했다. 재질과 접촉 그림자는 여전히 인수 수준에 미달한다.
7. 자동 걷기가 벤치와 유리 벽을 관통하려던 실패 및 문 바로 앞에서 F가 안전거리 안내로 거절된 실패는 테스트 경로 문제로 분류했다. 실제 출입구와 1.25m 문 안전거리를 따라 걷도록 바꾸었으며 충돌을 끄거나 순간이동으로 통과시키지 않았다.

## 남은 작업과 재현

- 운영 인증: [Clerk 설정](clerk-setup-ko.md)의 공개 설정 → 실제 로그인/UID → HTTPS 서버·비공개 저장소·정책 공개키 → 두 기기 관리자/학생 검증 순서. 서버 비용/변경 범위를 확정하기 전 서비스를 생성하지 않았다.
- 미술: `art/author_v4_meeting.py`, `art/pack_export.py`, `assets/v4`, `scripts/world/meeting_finish.gd`. 대표 회의실의 접촉 그림자·재질·발표 화면 대비와 성능부터 다시 비평한 뒤 HOME/OFFICE/PLAY에 적용한다.
- 스포츠/생활/원본 문서/한국어 음성/방송은 Q의 미실행 조건을 실제 사용으로 채워야 한다. 기존 함수·과거 영상으로 대신하지 않는다.
- 구조: 카메라/입장 정책/채팅/서버 경계는 분리했지만 큰 V2/V3 세계와 bridge의 추가 분리는 남았다. [책임 지도](implementation-map-ko.md)

실행 위치는 저장소 루트다. 미리보기 `node homeoffice/tools/serve.mjs --port 8065 --artifact build`와 기존 로컬 signaling 9001이 필요하다. 메신저/회의/사격: `node homeoffice/tests/v4-browser-flow.mjs`, `v4-meeting-flow.mjs`, `v4-play-flow.mjs`. Node 단위 회귀는 `cd homeoffice; npm test`, 실제 Clerk SDK 합성 검증은 `node --test tests/v4-clerk-adapter.test.mjs`다. UI 보고서에 실패가 있으면 해당 흐름을 통과로 세지 않는다.
