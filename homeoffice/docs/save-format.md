# 공간 파일 V2

`.homeworld`는 압축 없는 ZIP 컨테이너다. `manifest.json`, `world.json`, `attachments/<sha256>`를 담는다. 호스트의 확정된 세계와 Yjs 업데이트, 자료 수신 완료 시점을 모은다. 원음, 동의 없는 전사, 실행 코드, 로그인 토큰은 포함하지 않는다.

- 구조 스키마: [world-v2.schema.json](../schemas/world-v2.schema.json), [manifest-v2.schema.json](../schemas/manifest-v2.schema.json).
- 실행 시 검사: [save-v2.mjs](../web/save-v2.mjs), [presentation-view.mjs](../web/presentation-view.mjs), Yjs 후보 문서 검증과 PDF/이미지 파싱.
- 파일 최대 32MiB, world 물건 256개, 개인실 8개, 보드 512개, 발표 자료 64개/개별 16MiB. 임의 압축 방식이나 경로는 허용하지 않는다.

구조 스키마만으로 가져오기를 승인하지 않는다. 실행 검증은 CRC와 SHA256, ZIP 경로/중복/크기, ID 유일성, 개인실 순서/배정 관계, 허용 에셋, 수치, 발표 자료 참조/실제 바이트를 확인한다. 수납함은 최대 4개, 서랍은 2개이며 책·마카·접시 등 허용 종류만 보관한다. 중복 보관·중첩 가구·존재하지 않는 물건·스포츠 공이나 무기의 수납 우회를 거절한다.

수납 상태는 `objects[].state.contents`의 물건 ID 배열과 `open`에 저장한다. 스탠드의 전원은 `state.on`이다. 물건은 컨테이너 안에서도 원래 ID와 내용/재질 에셋 참조를 유지한다. 꺼내면 host ownership과 물리가 복원된다. 파일에 peer ID나 점유를 기록하여 재사용하지 않는다.

가져오기는 후보 파일/문서/자료 검증 → 포함 내용 미리보기 → 현재 공간 백업 다운로드 → 복원 순서다. 파일 검증 실패가 현재 세계를 교체하지 않는다. 임시 물리 세계에서 모든 가구 배치 충돌을 전수 검사하는 단계는 필수 미완료다. 다른 사용자는 복원한 호스트의 새 초대 코드에 참가한다.
