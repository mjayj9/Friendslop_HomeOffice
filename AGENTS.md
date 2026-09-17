# COMMONS WORKSPACE 실행 지도

- 최신 요구: [V4 통합 명세](homeoffice/docs/v4/master-spec-ko.md). 현재 상태: [TASK_STATE.md](TASK_STATE.md).
- 기능/저장 경계: [책임 지도](homeoffice/docs/v4/implementation-map-ko.md). 실측: [Q01–Q32](homeoffice/docs/v4/verification-ko.md). 인증 준비: [Clerk](homeoffice/docs/v4/clerk-setup-ko.md).
- 실제 프로젝트는 `homeoffice/project.godot`, Godot 4.6.1 / Jolt / Web Compatibility. 저장소와 Pages URL을 유지한다.
- 기존 V3를 점진적으로 수정한다. `v4 extends v3` 세계를 추가하거나 V2 세계를 재생성하지 않는다.
- E 집기/내리기, Q 던지기, F 기능 사용, 클릭 도구, R 보조, C 시점, Ctrl 웅크리기. 입력 포커스는 게임보다 우선한다.
- 전역 자유사격: 사용자/구역별 허가와 강제 회수 없음. 소유권·세션·속도·벽·HP 검증 유지.
- 방 잠금은 실제 관리자 신원과 서버 PIN 검증이 필요하다. 시뮬레이션 호스트는 관리자가 아니다. PIN/토큰/개인키/DM을 공개 산출물에 넣지 않는다.
- 명세의 Q01–Q32를 추적한다. 코드 사실, 과거 기록, 자동 fixture, 이번 실제 UI, 실제 사람 검증을 구분한다.
- `cd homeoffice; npm test` / `python tools/site_artifact.py verify build --source` (새 로컬 빌드). 공개 V3 기록 검사는 `verify ../docs`.
- 로컬 빌드: `tools/build.ps1 -Godot <4.6.1 console executable> -LocalOnly`. 미승인 원격 push/배포/병합/Firebase 변경 금지.
- 각 변경은 관찰→기대/실패 조건→구현→실행→비평→수정→회귀→기록. 기존 기능 회귀 없이 대량 삭제 금지.
