# V6 책임과 데이터 경계

기존 `scripts/v3/world.gd` → `scripts/v2/world.gd`를 유지한다. 별도의 v6 world 상속은 추가하지 않았다. 새로운 건축과 시설은 구성 요소로 연결한다.

| 책임 | 실제 소스 | 소유 상태와 경계 |
|---|---|---|
| 건축/층/방 | `art/author_v6_campus.py`, `assets/v6/campus.json`, `scripts/world/crafted_campus.gd` | 단위 m, Y up. OFFICE x10–36/z−38–−14. B1부터 RF까지 3.6m 간격. 슬롯과 시설 위치는 동일 manifest에서 읽는다. |
| 승강기 | `scripts/world/campus_lifts.gd` | 시뮬레이션 호스트가 두 car의 queue/trip/문/층을 소유한다. 탑승 플랫폼 속도는 Godot 물리가 한 번 적용한다. 운영 관리자 권한을 만들지 않는다. |
| 문/출입 | `scripts/world/campus_doors.gd`, `scripts/security/room_access.gd` | 물리 문 상태와 검증된 관리자 신원을 분리한다. 저장된 열린 문으로 ADMIN_ONLY 권한을 얻지 않는다. |
| 개인실 | `crafted_campus.gd:add_personal`, 기존 roomSlots/claims | 고정 8개 슬롯, ID office-1…office-8 보존. 기존 방이나 코어를 밀어 늘리지 않는다. 새 세션에서 계정 기반 영구 소유권까지 구현한 것은 아니다. |
| 회의 | `web/meeting-policy.mjs`, `web/meeting-workspace.mjs` | room ID → meeting ID → 별도 Yjs/보드/자료/발표. 물리 입장과 회의 참여는 구분한다. 매 메시지에 현재 참여 세대와 epoch를 확인한다. |
| 내장 문서 | `web/collaboration-source.mjs` | Quill/Yjs 바인딩, 상대 위치에 상대 CRDT 위치 사용. Undo는 본인 report origin. 회의 손들기·타이머·presence는 일시 메시지이며 파일 복원으로 되살리지 않는다. |
| 원본 문서 | `web/document-registry.mjs` | Google Docs/Slides/Microsoft Excel 공유 링크를 검증한다. 외부 편집 권한은 해당 서비스가 결정하고 파일에는 링크를 보관한다. |
| 발표 | `web/presentation.mjs` | 회의별 asset hash/page/pageRevision/presenter/sequence. 늦은 포인터는 자료·쪽·버전이 맞아야 수신한다. 실물 screen plane과 패널 UV를 연결한다. |
| 음성/자막/방송 | `web/bridge.mjs`, `broadcast.mjs`, `caption-policy.mjs` | 근거리의 회의 참여와 층 높이를 함께 확인한다. 실제 장치 consent는 직접 켜기와 별개 권한. 기존 전체 대화·방송은 사용자가 선택한 수신 범위를 유지한다. |
| 가상 CCTV | `crafted_campus.gd` | 관리자 콘솔, 공개 B1/1F 홀만 두 선택지. 640×360 / 최대 8회 갱신, 닫힘·거리·권한 만료 시 중지. 사용자 이름과 문서 화면 레이어 제외. 실제 기기 캡처와 무관하다. |
| 저장 | `campus_migration.gd`, `save-v2.mjs`, `bridge.mjs` | 원본 복사 → 옛 개인실 좌표 이동 → 충돌 물건을 ID/수납 관계와 함께 미배치 보관 → 미리보기 → 기존 파일 백업 → 엔진 복원 응답 → 자료 전환. PIN·관리자 lease는 허용 필드가 아니다. |
| 렌더링 | `crafted_campus.gd:refresh_visibility`, `art/adapt_v6_facilities.py` | 층별 외피/내부 메시, 멀리 있는 가구/문/승강기 시각만 숨김. 물리·CRDT·권한을 제거하지 않는다. 정적 기존 시설은 145→13 노드로 합치고 움직이는 뚜껑·물·ON AIR는 보존한다. |

새 파일은 기존 schemaVersion 2/assetPack 2/layoutVersion 2에 검증되는 선택 필드 `campusVersion:1`, `meetings`, `unplaced`, `campusDoors`, `campusTaps`를 추가한다. 과거 파일은 선택 필드 없이 읽을 수 있다. 낮은 테이블 지지 보정은 V5 경로를 유지한다. 개인실 이동에서 벽이나 시설과 겹친 물건은 버리지 않는다.

원본 male GLB와 리그, HOME·농구·축구·전역 사격·메신저·의상방의 기존 데이터와 경로는 보존한다. 기존 개선 부족 사항은 [V5 추적표](../v5/verification-ko.md)에 그대로 남겨 두며 V6 건축 추가로 해결됐다고 간주하지 않는다.
