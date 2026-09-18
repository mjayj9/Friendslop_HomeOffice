# V6 사용자 테스트 배포

[공개 앱](https://mjayj9.github.io/Friendslop_HomeOffice/) · [코드 커밋](https://github.com/mjayj9/Friendslop_HomeOffice/commit/6bfcc2bbfc64095f0bbfdba55efc33b056b2596b) · [직접 테스트 안내](testing-ko.md) · [검증 영수증](../../evidence/v6/publication/receipt.json).

2026-09-19 KST, 사용자의 기존 commit/push/Pages 요청에 따라 같은 저장소의 실제 배포 ref `codex/homeoffice-v3`에 정상 fast-forward로 게시했다. main 및 운영 인증 서비스/Firebase/관리자 설정은 바꾸지 않았다. 아래 runtime commit 뒤에는 동일 export를 유지한 증거 문서 커밋이 추가될 수 있다.

| 항목 | 실제 확인 |
|---|---|
| Runtime commit | `6bfcc2bbfc64095f0bbfdba55efc33b056b2596b` |
| Build ID | `f38c2ed4-11dd-46f5-8cd5-11dbb3a032aa` |
| source digest | `3704c4ccdd712215f6fafbddc719bd7e537153612aabea07e1a9b5a0bf468861` |
| Git index source | 277개 파일 일치 |
| 공개 HTTP 산출물 | 91개 크기·SHA256 일치, PCK/WASM/JS/하위 자산 포함 |
| Pages / CI | 35379947495 / 35379948854, 둘 다 성공 |
| 공개 온라인 회의 | 독립 Chromium 4개, 9흐름, pageerror 0 |
| 공개 건물 | 실제 보행·2F 회의·6F/RF/B1/1F 승강기 왕복 4흐름, pageerror 0 |

공개 회의 검수는 실제 온라인 연결에서 한국어 IME 경합, 서로 다른 두 회의 문서·보드 분리, 실제 PNG 발표·레이저·질문·할 일, 자기 Undo, 연결 차단 후 초안 병합, 참여 중지, 두 회의/첨부 export→새 세션 import를 실행했다. 네 사람이 사용한 검사는 아니다. 실제 마이크와 외부 문서 계정은 사용하지 않았다.

[공개 회의 화면/영상](../../evidence/v6/publication/meeting-browser/report.json) · [공개 보행 화면/영상](../../evidence/v6/publication/campus-browser/report.json). 로컬과 공개 결과의 Build ID가 같다. 기존 저장의 전역 자료는 기존 컴퓨터 화면에서 보존하고 새 회의 작업대와 구분한다.

구버전 화면이 보이면 Ctrl+Shift+R로 새로고침한다. 서로 다른 Build ID의 참가자는 접속을 거절하며 양쪽 새로고침을 안내한다. 기존 파일은 먼저 별도로 보관하고 가져오기 미리보기를 확인할 수 있다.

전체 V6 인수는 완료하지 않았다. [V6-T01–T56](verification-ko.md)의 미실행/미완료, [미술 검토](art-and-assets-ko.md), [성능 미달](performance-ko.md)을 함께 확인한다. 이 문서의 배포 성공은 제품의 모든 품질 요구 통과를 뜻하지 않는다.
