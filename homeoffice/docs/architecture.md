# V2 런타임 구조

Godot 4.6.1 Compatibility 단일 스레드/Jolt 60Hz가 건축·이동·소품·좌석·생활·스포츠·권한의 기준이다. `scripts/v2/world.gd`는 `tools/v2_base.txt`와 `v2_functions.txt`를 `assemble_v2.py`로 조합한 실행 파일이다. `scripts/v2/avatar.gd`는 캐릭터 물리/절차 동작, `scripts/v2/board.gd`는 실제 보드 렌더링이다.

Session은 연결 그룹/epoch/호스트, Zone은 실제 물리적 방이다. `assets/v2/layout.json`에서 도면·방/복도·개인실 확장과 구역을 정의한다. BlenderMCP `art/build_v2.py`는 메시/단순 충돌/anchor/GLB와 `.blend` 원본을 만든다. 네트워크와 무관한 제작 도구이며 런타임은 포트 9876에 접근하지 않는다.

`web/bridge.mjs`는 JavaScriptBridge 이벤트와 PeerJS 1.5.5 binary WebRTC data transport를 중계한다. Godot WebRTCMultiplayerPeer와 PeerJS 호환을 가정하지 않았다. 이동/상태는 혼잡 시 오래된 것을 버릴 수 있는 전송, 행동/협업은 순서 있는 큐, 첨부물은 별도 bulk 큐를 사용한다. 호스트가 입력/거리/가림/점유/구역/점수/권한을 검증한다. 입력 예측과 상태 보정은 있지만 원격 소품의 위치/회전 보간을 적용했다. 완전한 입력 재적용과 지연·손실 인수는 미완료다.

음성은 별도의 실제 RTC media track이며 근거리 밖은 송신 경로를 닫는다. Zone 전체/승인된 Session 전체, 차단/PTT/장치 설정을 구분한다. 변경된 권한과 media signaling의 순서 경합에서 권한 도착 전에는 answer하지 않는다. 신뢰 가능한 호스트·수정하지 않은 클라이언트를 가정하며 암호학적 사적 공간을 보장하지 않는다.

`web/collaboration-source.mjs`는 Yjs+Quill의 동시 보고서/메모/마인드맵이다. `presentation.mjs`는 PDF.js/이미지/페이지·레이저·주석·권한, `arcade.mjs`는 호스트의 실제 미로/러너 규칙, `captions.mjs`와 local-stt/worker는 선택적 한국어 인식이다. UI 입력 중 게임 이동은 막는다.

`save-v2.mjs`는 버전 있는 ZIP 컨테이너 검증과 생성, `handoff.mjs`는 확인 장벽→체크포인트→준비→권위 이전→재연결이다. 강제 종료는 마지막 확인본으로 새 세션을 만들며 무중단 이전과 구분한다. 가구·전체 문서·자료·개인실을 함께 다루는 통합 인수의 잔여 범위는 docs/v2/required-remaining.md를 따른다.

Jolt CCD 바닥 접촉 오차를 실제 드리블로 측정하여 continuous_cd_movement_threshold=.15, continuous_cd_max_penetration=.02, penetration_slop=.005를 사용했다. [Godot 4.6 공식 설정](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html#class-projectsettings-property-physics-jolt-physics-3d-simulation-continuous-cd-max-penetration)의 의미를 따르며, 자체 충돌 엔진으로 대체하지 않았다.

`key-bindings.mjs`의 로컬 물리 키 설정을 Godot에 전달하며, UI 상태에서 눌렸던 키는 release 전에 재개하지 않는다. `setup_living_prop/use_storage/update_living_props`는 뚜껑·서랍·조명과 수납 사물을 연결한다. 수납된 물건은 같은 ID를 유지한 채 물리 동작을 멈추고, 꺼낼 때 호스트가 소유권과 충돌을 복원한다.
