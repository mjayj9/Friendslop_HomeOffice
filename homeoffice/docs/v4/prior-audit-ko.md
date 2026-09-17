# 전문 협업 메타버스 V4 — 현재 저장소·배포 아티팩트 감사

확인일: 2026-09-17. 대상: mjayj9/Friendslop_HomeOffice. 이 문서는 요구사항·정적 코드 감사이며 게임 수리 결과가 아니다.

## 확인 범위

GitHub 연결 도구로 main 및 codex/homeoffice-v3가 `d67dd929cc719fb3e7e72626e59fc9bd9050a2d9`를 가리키는 것을 확인했다. Pages 워크플로 run `35106271065`도 해당 커밋을 대상으로 success였다. 그 실행의 아티팩트 `10450034120`을 다운로드하고 ZIP SHA256 `1a828f21020dbd99e6b1156aa7284f0bd2d1a83ea46e52e067ad0a75fc33c37d`를 확인했다. 내부 매니페스트 67개 파일의 크기·SHA256을 실제 계산해 67/67 일치를 확인했다. 이는 패키지 무결성 확인이지 게임 기능이나 화면 품질 시험이 아니다.

공개 사이트의 web 도구 조회는 Internal Error, 로컬 HTTP 요청은 DNS 해석 실패였다. 내려받은 배포본을 로컬 HTTP 서버로 열고 Chromium으로 렌더하려 했으나 `ERR_BLOCKED_BY_ADMINISTRATOR`로 차단되어 중단했다. 이를 우회하지 않았다. 따라서 최신 3D 화면을 직접 보거나 실제 다중 사용자로 조작·청취한 결과는 없다. 사용자가 말한 아마추어 같은 시각 품질은 사용자 평가이며, 아래 정적 코드 사실과 구분한다. 과거 저장소의 검증 보고서도 이번 독립 재실행 결과가 아니다.

배포 아티팩트 build ID는 `52b4edbc-4abd-4619-bea4-463db1278f2b`, 기록된 빌드 commit은 `4cd064e…`, dirty=true다. 현재 저장소 커밋과 다르다는 이유만으로 잘못된 배포라고 결론내리지 않는다. 소스 파일 digest 및 배포 시점 기록과 함께 확인할 사항이다. 이전 V3 검증 문서의 build ID `4edb96de…`도 현재 배포 ID와 다르므로 과거 통과를 현 빌드 통과로 일괄 승계하지 않는다.

## 사실·해석·다음 작업

| ID | 소스에서 확인한 사실 | 해석 및 새 요구와의 관계 | 위치 |
|---|---|---|---|
| A01 | 현재 main은 V3이며 Godot 4.6.1/Jolt를 사용한다. | 사용자의 '초보 Three.js 느낌'은 품질 비유다. 실제 엔진을 Three.js라고 진단하거나 엔진명 교체만으로 개선된다고 하지 않는다. | README, docs/build-info.json |
| A02 | social.mjs는 text 400자 제한, 최근 40개 rows, p.textContent 출력의 텍스트 채팅이다. | 채팅이 없는 것이 아니다. 카카오톡식 대화 목록·이미지·파일·답장·읽음·검색·알림·전송 상태는 별도 제품 설계가 필요하다. | homeoffice/web/social.mjs |
| A03 | avatar.gd는 AnimationPlayer와 클립 전환/접촉 IK를 사용하며, local standing 표시와 카메라 뒤 이동은 수면 상태에 연결되어 있다. | 예전 sin 보행만 그대로라고 하면 부정확하다. 일반 탐색·조준·상호작용의 3인칭 카메라와 자기 몸 표시를 별도 CameraRig로 분리해야 한다. | scripts/v2/avatar.gd |
| A04 | animation-review는 13본/62 Action을 기록하고 손목·손가락 전용 본 및 모든 접촉 품질 인수의 한계를 명시한다. | '62개 있음'은 62개가 모두 자연스럽다는 증거가 아니다. 리깅·전이·접촉·보행 속도와 영상 기반 미술 검수가 우선이다. | docs/v3/animation-review-ko.md |
| A05 | v3/world.gd는 v2/world.gd를 상속하고, combat/sports/physics 등 일부 책임을 분리했다. | 정규식 합성기 문제는 이미 중단되었다는 현 문서를 반영한다. 다음 단계는 상속/공유 mutable state 결합을 줄이는 점진적 구조 개편이다. | scripts/v3/world.gd, docs/v3/implementation-analysis-ko.md |
| A06 | carry의 gun/shield 경로에 allowed_weapon가 있고 classroom의 관리자성 행동을 차단한다. 피해 처리에서도 상대 allowed_weapon 검사 경로가 남아 있다. | 최신 요청인 '총 꺼내면 회의실 포함 어디서나 사용'과 직접 충돌한다. UI뿐 아니라 모든 상속 경로/회수 루프/피해 처리/복원 규칙을 일괄 전환해야 한다. | scripts/v3/world.gd |
| A07 | 농구에 슛 charge, 각속도 지정, steal_ball이 있고 축구에 foot-touch impulse가 추가되었다. | 이전 '.24m 공, 스핀 없음, 손으로만 축구'를 최신 확정 결함으로 반복하지 않는다. 상태 전이·조작감·입력 지연·충돌 프로필을 재측정한다. | scripts/v3/world.gd |
| A08 | document-registry는 실제 Google/Microsoft 링크를 검증하고 window.open으로 연다. | 원본 링크 연동은 존재한다. 내장 편집/화면 공유/발표 동기화/회의 UX 및 실제 외부 두 계정 검증은 별개다. | web/document-registry.mjs |
| A09 | 배포 HTML/CSS는 모여집 진입 화면, 전체 veil 메뉴, 여러 tool-panel, 최근 텍스트 패널을 사용한다. | 미술 수준을 코드 줄 수로 점수 매기지 않는다. 프로 UX에는 공통 디자인 토큰·상태/포커스·반응형 패널·게임 위 HUD를 묶는 일관성 검수가 필요하다. | docs/index.html, docs/homeoffice.css |
| A10 | 현 문서는 별도 일반 peer alias와 classroom을 구현했다고 설명하며 실제 아티팩트에도 교실 입장 카드가 있다. | 짧은 코드/고정 링크를 새로 아무것도 없는 것처럼 재구현하지 않는다. PIN 관리자 신원·세션 호스트·고정 주소·세계 저장을 분리하고 회귀 시험한다. | README, docs/index.html, invitations/directory 모듈 |
| A11 | 검증 보고서는 실제 사람 마이크·외부 공동편집 계정·WAN을 제외한 가상 시험 범위를 명시한다. | 코드/합성 시험과 실제 사용 품질 사이의 간극을 완료 조건으로 해소해야 한다. 한 PC 8개 브라우저 표본을 서로 다른 8대 성능으로 바꾸지 않는다. | docs/v3/verification-report-ko.md |

## 권장 작업 순서

현재 재현과 기준 빌드 고정 → 제품/미술 기준 확정 → CameraRig·입력·캐릭터 정리 → 모듈 경계/새 정책 회귀 → 회의실 대표 장면 완성 → 채팅·첨부물 → 스포츠/전투의 실제 루프 튜닝 → HOME/OFFICE 전체 마감 → 한국어 음성/방송·저장·교실 통합 인수. 전체 기능을 한 번에 새 껍데기로 바꾸지 않는다.

## 근거 파일

- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/README.md
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/docs/build-info.json
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/homeoffice/docs/v3/implementation-analysis-ko.md
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/homeoffice/docs/v3/verification-report-ko.md
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/homeoffice/docs/v3/animation-review-ko.md
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/homeoffice/scripts/v2/avatar.gd
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/homeoffice/scripts/v3/world.gd
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/homeoffice/web/social.mjs
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/homeoffice/web/document-registry.mjs
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/docs/index.html
- https://github.com/mjayj9/Friendslop_HomeOffice/blob/d67dd929cc719fb3e7e72626e59fc9bd9050a2d9/docs/homeoffice.css

워크플로: https://github.com/mjayj9/Friendslop_HomeOffice/actions/runs/35106271065

## 이 감사에서 하지 않은 일

저장소 push·PR 수정/병합·계정/비용 설정 변경·운영 배포·사용자 BlenderMCP 접속·마이크 수집·외부 문서 계정 접근은 하지 않았다. 아티팩트 내려받기·파일 해시 검사·정적 코드 확인만 수행했으며, 게임 실행 시도는 위 사유로 실패했다.
