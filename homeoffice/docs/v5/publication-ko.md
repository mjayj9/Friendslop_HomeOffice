# V5 수리본 공개 배포 확인

2026-09-18 KST 사용자 요청에 따라 커밋·푸시와 기존 GitHub Pages 게시를 완료했다. 사용자 테스트용 수리본이며 전체 V5 완성 판정은 아니다.

- [실제 테스트 페이지](https://mjayj9.github.io/Friendslop_HomeOffice/?v=9fa65de6-20d0-4a7a-b315-f3b388891e24)
- 배포 ref: `codex/homeoffice-v3:/docs`
- [배포 커밋 `4713d41`](https://github.com/mjayj9/Friendslop_HomeOffice/commit/4713d4142391a5ce38332a8802bc421449879210)
- Build ID: `9fa65de6-20d0-4a7a-b315-f3b388891e24`
- source digest: `74c8afce2b641b594aa5598ff4fe1f43eb070adc9d68be0c3249f86c9bc08b68`
- [Pages 배포 성공](https://github.com/mjayj9/Friendslop_HomeOffice/actions/runs/35352390257), [게시 파일 CI 성공](https://github.com/mjayj9/Friendslop_HomeOffice/actions/runs/35352392152)

PCK·WASM·JS·썸네일·의상방 모듈 등 공개 파일 **88/88개**의 HTTP 상태·크기·SHA256을 확인했다. 커밋에 넣은 소스 244개도 검수 빌드의 manifest와 일치했다. 검수한 export를 재생성하지 않았으므로 build-info의 제작 당시 기반 커밋 `27dccb8…`와 dirty 표시는 그대로 보존했다. 실제 게시 커밋은 `4713d41`이다.

새 Chromium/WebGL에서 공개 URL을 직접 실행했다. **설치 UI 10개 / 의상방 UI 9개** 판정 통과, pageerror 0개다. 이동·raycast preview·회전·드롭·취소·포커스 상실, 집 안 총 발사와 드래그 중 발사 차단, 계단 보행·현장 콘솔 클릭·얼굴 브러시/지우개/Undo/Redo·3D 회전·취소·적용·같은 브라우저 재접속을 검수했다. 이 공개 검수는 서로 분리된 1인 세션이다. 공개 서버 다인 연결을 시험한 것으로 확대하지 않는다. 기존 로컬 두 브라우저 동기화 증거는 별도 보존했다.

- [배포 영수증](../../evidence/v5/publication/receipt.json) · [88개 파일 대조](../../evidence/v5/publication/integrity.json)
- [설치 결과](../../evidence/v5/publication/placement/report.json) · [설치 화면](../../evidence/v5/publication/placement/02-placed-chair.png)
- [의상방 결과](../../evidence/v5/publication/wardrobe/report.json) · [거울 화면](../../evidence/v5/publication/wardrobe/physical-room.png)

## 직접 테스트

입장 화면에서 1인 입장으로 시작할 수 있다. C로 시점을 바꾸고, Tab으로 포인터를 해제한 뒤 상단 ‘물건 설치’를 눌러 썸네일을 바닥으로 끌어 놓는다. 의상방은 로비 계단을 통해 2층으로 올라가 독서 공간 옆에서 거울/꾸미기 콘솔을 직접 클릭한다. 얼굴 편집은 현장 클릭으로 시작한다.

기존 탭에서 이전 화면이 남으면 Ctrl+Shift+R로 새로고침한다. 저장 파일이나 브라우저 저장소를 지울 필요는 없다.

운영 인증 서버·Firebase·관리자 설정은 바꾸지 않았다. 관리자를 검증하지 못하면 농구·축구 코트 잠금이 유지된다. 전체 건축 재설계, 체형/옷 메시 fitting, 완결 스포츠·전술 라운드 등 [남은 V5 요구](verification-ko.md)는 이번 게시를 이유로 완료 처리하지 않는다.
