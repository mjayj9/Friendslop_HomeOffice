# 이번 실행 검증 보고서

최종 작업 빌드: `4edb96de-caa2-4b53-b132-5fb0cade9ec1`. 보고서 생성: 2026-09-15T16:35:31.383105+00:00.

## 환경과 증거 구분

- 실제 브라우저 시험: 독립 Chromium 프로세스, 실제 WebGL/WASM, 키보드·마우스·HTML 컨트롤, 실제 loopback PeerJS/WebRTC. 진단값은 읽어서 확인하며 위치를 주입하지 않습니다.
- 엔진 시험: Godot/Jolt 실제 물리 장면에 재현 가능한 초기 위치·속도·명령을 설정합니다. 사람 플레이로 표현하지 않습니다.
- 가상 마이크: Chromium 생성 신호의 실제 RTP 수신. 한국어 합성 음성: Microsoft Heami 입력을 실제 Whisper WASM worker가 인식합니다.
- 과거 V2 로그는 이번 성공 수에 포함하지 않습니다. 최종 빌드와 다른 Build ID의 시험은 같은 작업 중 앞선 빌드의 근거로 남깁니다. 관련 코드 변경이 없더라도 같은 해시로 재실행했다고 표현하지 않습니다.

## 자동 실행 결과

| 묶음 | 통과 | 실패 | 실행 완료 | 실행 Build ID | 증거 |
|---|---:|---:|---|---|---|
| 의자·책·회의·한글·파일 복원 | 8 | 0 | 예 | `4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json) |
| 교실 동시 입장·인계·재개 | 5 | 0 | 예 | `4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/session-flow/report.json) |
| 계단·자기 수면·생활 | 5 | 0 | 예 | `1667820a-0d15-45fa-9b8f-f506fc5f557b` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/life-flow/report.json) |
| 회의 질문·할 일·물리 레이저 | 4 | 0 | 예 | `4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/tools-flow/report.json) |
| 공룡 게임기·원격 관전 | 2 | 0 | 예 | `9a27534c-6f90-4dc8-bf9c-3481c37a6cee` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/arcade-flow/report.json) |
| 가상 음성·방송·욕실·복원 | 6 | 0 | 예 | `007ca110-991d-4e1c-bb93-a09a7523896a` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/voice-facilities/report.json) |
| 2/4/8 접속·30분 활동 | 8 | 0 | 예 | `007ca110-991d-4e1c-bb93-a09a7523896a` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/scale-soak/report.json) |
| 기본 게임 규칙·캐릭터 | 14 | 0 | 예 | `동일 소스: 4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/gameplay-tests.json) |
| 권위·득점·피해·광선 | 15 | 0 | 예 | `동일 소스: 4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) |
| 물리 낙하·CCD | 4 | 0 | 예 | `동일 소스: 4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/physics-lab.json) |
| 수납·서랍·램프·파일 복원 | 12 | 0 | 예 | `동일 소스: 4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/living-props.json) |
| 요리·식사·설거지·수면·권한 | 21 | 0 | 예 | `동일 소스: 4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/legacy-interactions.json) |
| 보드·점유·개인실·명령 검증 | 14 | 0 | 예 | `동일 소스: 4edb96de-caa2-4b53-b132-5fb0cade9ec1` | [JSON](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/legacy-authority.json) |

엔진 회귀 일괄 실행 완료=True, 대응 build ID `4edb96de-caa2-4b53-b132-5fb0cade9ec1`, 소스 digest `81c6f8fff1d90ed4ea96ebbb7d20790b77fdb5169faffd6abcc779986bc063dd`. [실행 시각·종료 코드 기록](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/engine-final-run.json)

장시간 시험 이후 최종 변경: [수정 범위와 재검증 기록](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/final-build-changes.json).

빌드별 파일 해시는 [보존한 빌드 manifest](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/builds)에서 확인합니다. 최종 빌드는 runtime .gd/scene/asset/web 파일별 SHA256과 전체 digest를 함께 기록합니다. 빌드 ID 주입 파일과 import 캐시는 digest에서 제외합니다.

Node 규칙/저장/초대/방송/자막/상태 복제 시험: ℹ pass 20; ℹ fail 0. [전체 로그](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log)

## 실제 드리블 측정

7초, 420회 물리 tick. 통과=True, 반발 5회, 공 중심 최저 0.118m / 최고 1.326m, 최대 속도 6.982m/s. 수직 위치를 애니메이션으로 주입하지 않았습니다.

## 2·4·8 접속과 장시간 활동

낮음 그래픽, 호스트 1280×720 / 참가자 640×360. [실제 시험 PC 사양](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/test-machine.json).
완료=True. 계획 활동 1800초 / 기록된 경과 1821.4초, 입력 활동 319회, 재입장 2회.

기록된 경과 시간은 마지막 내보내기/복원 시간도 포함합니다. 30분 활동 도중 계획된 두 차례 재입장 구간에서는 일시적으로 7개 참가자가 연결됩니다. 8명이 다른 PC에서 플레이한 시험은 아닙니다.
동일 PC의 8개 렌더러 표본 FPS 중앙값 43.0, 최저 20, 최고 61. 각 클라이언트의 최근 rAF 표본 p95 중앙값 33.4ms.

이 수치는 분산된 8명 PC의 프레임률이 아닙니다. rAF 간격에는 브라우저 스케줄링이 포함됩니다. Godot fps 표본도 전체 프레임 p95와 동일하지 않습니다. 기능 안정성과 성능 목표 달성 여부를 구분합니다. 최저 표본이 30 미만이면 지속적인 30 FPS를 보장한 시험으로 해석하지 않습니다.

호스트 상태 복제 통계의 누적 절감률 중앙값 58.0%. 매번 전체 사물 상태를 전송했을 때의 추정 바이트와 실제 변경분 메시지 바이트를 비교한 값이며, 전체 WebRTC/음성 트래픽 절감률은 아닙니다.

## 현재 한국어 합성 인식

| 원문 | 실제 인식 | 추론 ms | FPS 표본 |
|---|---|---:|---:|
| 안녕하세요. 오늘 회의를 시작하겠습니다. |  안녕하세요 오늘 회의를 시작하겠습니다. | 1354 | 32 |
| 민수님은 보고서를 쓰고 지연님은 발표 자료를 준비해 주세요. |  민수님은 보고서를 쓰고 지언니们 발표 자료를 준비해 주세요. | 1506 | 37 |
| 다음 회의는 9월 14일 오후 3시 30분입니다. |  다음 후에는 9월 14일 5월 13일 30분입니다. | 1321 | 34 |
| 이번 스프린트의 API 테스트와 코드 리뷰를 마무리하겠습니다. |  이번 스프린트의 API Test와 코드립을 마무리하겠습니다. | 1416 | 31 |
| 농구를 한 다음 주방에서 함께 저녁을 만들자. |  농구를 한 다음 주방에서 함께 전역을 만들자 | 1254 | 31 |
| 예산은 125000원이고 참석자는 8명입니다. |  예산은 12만 5천 원이고 참석자는 8명입니다. | 1311 | 31 |

이번 6개 합성 입력의 CER 17.2%, WER 29.7%. NFC/구두점 제거, CER 공백 제외, WER 공백 토큰 기준. 숫자/이름을 의미 추정으로 고치지 않았습니다.

합성 소수 문장의 결과이며 사람/소음/겹말/실마이크 품질 수치가 아닙니다. 인식 worker 실행 시간은 발화 종료부터 최종 자막까지의 전체 지연과 다릅니다.

## 실제 화면

### 상대 몸체

![상대 몸체](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/integrated-three/client-0-forward.png)

### 본인 3인칭 취침

![본인 3인칭 취침](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/life-flow/sleep-third-person.png)

### 공동 질문과 할 일

![공동 질문과 할 일](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/tools-flow/meeting-questions-tasks.png)

### 3D 물리 레이저

![3D 물리 레이저](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/tools-flow/physical-laser-host.png)

### 정리한 세면대와 수도

![정리한 세면대와 수도](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/voice-facilities/refined-basin-water.png)

### 실제 공룡 러너 결과

![실제 공룡 러너 결과](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/arcade-flow/runner-result.png)

### 8개 브라우저 접속

![8개 브라우저 접속](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/scale-soak/eight-peers.png)

## 해석할 때 남는 제약

1. 사람/실마이크/외부 두 계정/WAN/운영 배포는 사용자 지정 가상 범위 밖입니다.
2. 62개 클립의 존재·로딩과 일부 실제 행동을 검증했으며 모든 프레임의 손·발·가구 접촉 품질을 완전히 인수한 것은 아닙니다. 13본 구조에는 손가락/손목 본이 없습니다.
3. 기존 거대한 V2 world/bridge의 점진적 분리는 진행했지만 전면 해체하지 않았습니다.
4. 요리·식사·설거지·수납·서랍·램프·보드·점유·저장에 대한 현재 V3 엔진 회귀를 추가했습니다. 모든 기존 기능 조합을 최종 브라우저 빌드에서 전수 재시험한 것은 아닙니다.
5. 호스트 탭을 숨길 때 의도적으로 freeze하지 않지만 브라우저/운영체제의 백그라운드 제한과 비정상 종료 시 최근 상태 손실까지 제거하지는 못합니다.
6. 교실 고정 링크는 영구 저장 서버가 아닙니다. 보존에는 실제 파일 내보내기/가져오기를 사용합니다.
