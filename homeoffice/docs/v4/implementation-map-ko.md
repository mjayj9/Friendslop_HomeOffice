# V4 책임과 보존 범위

최신 요구는 [master-spec-ko.md](master-spec-ko.md)다. 이 문서는 구현 현황이며 원본 요구를 축소하지 않는다.

| 책임 | 현재 소유 파일 | 현황 |
|---|---|---|
| 세션·WebRTC·입력 포커스 | `web/bridge.mjs`, `session-directory.mjs`, `handoff.mjs` | 기존 흐름 유지. 프로토콜 4 + 동일 Build ID 요구. bridge 추가 분리 필요 |
| 카메라 | `scripts/player/camera_rig.gd` | 3인칭 기본, C, 휠, sphere sweep, 조준 어깨, FOV/반전/감도 |
| 이동·애니메이션 | `scripts/avatar.gd`, `v2/avatar.gd`, `player/contact_ik.gd` | look yaw와 몸 방향 분리, 보행 재생 속도 수정. 접촉 품질 인수는 미완료 |
| 세계·상호작용 | `scripts/v2/world.gd`, `v3/world.gd`, `interaction/prop_capabilities.gd` | 정상 기능 보존. V4 상속 세계 없음. 큰 V2/V3 경계의 추가 분리는 남음 |
| 방 입장 정책 | `scripts/security/room_access.gd`, `web/room-policy.mjs`, `room-admin.mjs` | 검증된 정책 적용, 새 입장 차단, 퇴실 유지. 실서비스 미연결 |
| 관리자·PIN | `server/admin-policy.mjs`, `clerk-adapter.mjs`, `serve-admin.mjs` | PCK/Pages에서 제외. [Clerk 설정](clerk-setup-ko.md) |
| 전투 | `scripts/combat/*`, V3 통합 | 개인/구역 허가·교실 무기 차단·회수 제거. 소유권·cooldown·벽·방패·HP 검증 유지 |
| 스포츠 | `scripts/sports/*`, 기존 세계 | 스핀·스틸·발 터치 등의 기존 구현 유지. 실제 두 사람 완결 경기 검수 미완료 |
| 채팅·첨부물 | `web/chat-protocol.mjs`, `messenger.mjs`, `attachment-policy.mjs` | 수신자별 라우팅, 답장/반응/수정/삭제/검색/읽음, P2P chunk 파일 |
| 회의 | 기존 documents/collaboration/presentation/board | 원본 링크와 내장 공동 문서 분리. 실제 외부 계정 공동편집 미실행 |
| 음성·방송 | bridge/captions/broadcast | 근거리·현재 방·전체 대화 유지. 방송은 검증된 운영 관리자 사용. 실제 마이크 검수 미완료 |
| 저장 | `web/save-v2.mjs`, schemas | 이전 파일 호환. 새 PIN 정책은 운영 서버에서 유지하고 세계 파일로 덮어쓰지 않음 |
| 회의실 미술 | `art/author_v4_meeting.py`, `pack_export.py`, `assets/v4`, `world/meeting_finish.gd` | 별도 Blender 원본, 게임용 GLB, 기존 문·좌석·컴퓨터 연결. 전 공간 미술 인수 미완료 |

## 메신저의 실제 범위

채널은 세션 전체/현재 공간/DM이다. 호스트가 권위 있는 수신자 집합을 정하고 DM 원문을 비참여 클라이언트로 전송하지 않는다. 호스트는 중계하는 DM을 읽을 수 있다. 종단간 암호화 대화가 아니다.

메시지는 세션당 500개까지 메모리에 보관한다. 자기 메시지 수정·삭제는 15분 이내다. 읽음은 실제 표시 영역·포커스 상태에서 보고한다. 일반 채널에는 일시적인 3D 말풍선이 표시되고 DM은 말풍선으로 공개하지 않는다. 멘션 자동완성·알림 설정·장기 검색·서버 이력은 아직 없다.

PNG/JPEG/PDF/UTF-8 TXT, 파일당 20MiB, 동시에 받기 2개, 송신/수신 캐시 각각 64MiB다. 12KiB 조각, 요청한 순서만 전달, 저우선순위 큐, bufferedAmount 한도, 취소/이어받기/재시도, SHA-256 및 수신 후 형식 확인을 사용한다. 이미지 각 변 8192px/1600만 화소 한도가 있다. 악성코드 검사 완료를 뜻하지 않는다. HTML/SVG/스크립트는 실행하지 않으며 PDF는 다운로드만 제공한다. Office 첨부물과 WebP 등은 아직 지원하지 않는다.

파일 원본은 발신자 기기에 있다. 발신자 퇴장 시 미수신 파일은 제공자 오프라인으로 표시한다. 이미 받은 파일은 해당 기기에 남아 다운로드할 수 있다. 호스트 이전 때 기존 대화는 각 수신자의 읽기 전용 이력으로 남고 진행 중 전송은 중단된다. 새 호스트에게 DM 전체를 넘기지 않는다. 아직 파일/대화 세션 이력의 연속 이전은 구현하지 않았으므로 필요한 파일은 새 대화에 다시 공유해야 한다.

## 저장 범위

세계 파일은 기존 가구/상태/문/전등/시설/개인실 슬롯/보드/내장 공동 문서/발표 첨부/외부 원본 링크/게임 결과를 포함한다. Google·Microsoft 원본의 내용을 백업하지 않는다.

메신저 대화·DM·채팅 첨부·PIN·PIN hash·관리자 토큰·개인키·원음은 포함하지 않는다. 선택 동의를 받은 공개 대화/사진 내보내기 UI는 아직 없다. 방 잠금은 운영 서버의 현재 정책을 유지하고 옛 세계 파일이 변경할 수 없다. 정책 ID/상태를 포함하는 별도 운영자 백업은 후속 설계 대상이다.

## 비교 조사와 증거 수준

Roblox의 [카메라 문서](https://create.roblox.com/docs/workspace/camera)는 시점·줌·가림 처리의 비교 근거로 사용했다. [FIFA Super Soccer 소개](https://www.roblox.com/games/12177325772/FIFA-Super-Soccer)의 공개 조작 설명도 읽었다. Basketball Legends/Arsenal 페이지를 확인했지만 실제 Roblox 플레이는 수행하지 않았다. 내부 물리·판정·네트워크 구현을 추정 사실로 기록하지 않는다. 해당 게임 코드·캐릭터·음원을 복제하지 않았다.
