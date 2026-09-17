# V4 검토 배포 · 2026-09-17

사용자가 현재 변경의 커밋·푸시와 GitHub 사이트 업데이트를 요청한 범위의 검토 배포다. **전체 V4 인수 완료를 뜻하지 않는다.**

- 주소: [COMMONS WORKSPACE](https://mjayj9.github.io/Friendslop_HomeOffice/)
- 기존 Pages 브랜치: `codex/homeoffice-v3`, 공개 폴더 `docs/`. 저장소와 URL은 유지한다.
- Build ID: `cc2f8fbd-ba33-4601-b716-82bb26422424`
- source digest: `d3f3b1f7bc2bd3343825fd5705089bd5a7807f1fb7cb8ccc3e333d5c12a62514`
- [공개 build-info](https://mjayj9.github.io/Friendslop_HomeOffice/build-info.json)와 [Pages 실행](https://github.com/mjayj9/Friendslop_HomeOffice/actions/workflows/pages/pages-build-deployment)에서 실제 배포된 바이트와 커밋을 확인한다. 빌드 manifest의 `commit`은 export 생성 당시 기준 HEAD이고 `dirty: true`다. 배포 커밋은 Actions의 `head_sha`, 소스 일치는 위 digest로 확인한다.

## 배포 전 같은 빌드 검증

[결과 집계](../../evidence/v4/review-deployment.json): 실제 Godot WebGL/독립 Chromium에서 카메라·메신저 14개, 회의실 5개, 전역 사격 7개를 재실행해 모두 통과했다. 같은 빌드의 실제 Clerk 개발 SDK 로그인/가입/입력 차단 4개 기록도 포함한다. 서로 다른 실제 사람이나 실제 외부 계정의 검증은 아니다.

Node 33개, 공개 artifact 회귀 6개, Clerk 합성 JWT 1개, export 73파일/source hash 검사와 실제 PCK 318경로 검사를 통과했다. PCK 안 서버·테스트·비공개 설정 경로는 0개다. PIN·Secret Key·토큰·관리자 허용 목록은 공개 설정에 넣지 않았다.

보고서에 연결된 최종 영상만 Git에 선별하며, 반복 실행 영상은 로컬에 보존한다. 이전 빌드의 엔진 112 assertion 기록은 [기존 검수 문서](verification-ko.md)에서 별도 구분한다.

## 검토 방법과 남은 조건

처음에는 **혼자 먼저 둘러보기**로 입장한다. 공동 접속은 한 사람이 **함께할 공간 열기**, 다른 사람은 표시된 AAA-AAA 코드로 참여한다. 고정 교실도 유지한다. C는 시점 전환, 휠은 줌, E는 집기, F는 기능 사용, Enter는 채팅, Esc는 메뉴다.

Clerk는 개발 인스턴스다. 사용자 계정 로그인과 관리 권한은 별개이며 관리자 UID/PIN 서버는 아직 연결되지 않았다. 방 잠금·관리 방송은 비활성이다. Firebase, 별도 유료 호스팅, 인증 도메인 설정은 변경하지 않는다.

미술 마감·손발 접촉·완결된 사람 스포츠 경기·실제 음성/한국어 자막·외부 Google/Microsoft 원본 공동편집 등은 [Q01–Q32](verification-ko.md)의 미실행/부분 통과/품질 미달을 그대로 유지한다.
