# HomeOffice V3 — 분석·구현·가상 검증

두 MD의 요구를 실제 Godot 코드, Blender 제작 원본, 웹 빌드와 자동 검증에 반영한 작업 기록입니다. 사용자의 최신 범위인 **구현 + 가상 시뮬레이션**을 기준으로 합니다. 실제 사람의 마이크, 외부 계정 공동 편집, 서로 다른 인터넷망, 운영 배포는 이번 완료 판정에 포함하지 않습니다.

## 결과물

- [설계·결함 원인·구현 상세 분석](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/docs/v3/implementation-analysis-ko.md)
- [R01–R30 / U01–U56 / G01–G16 전수 대조표](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/docs/v3/requirements-traceability-ko.md)
- [이번 실행 결과·수치·증거·제약](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/docs/v3/verification-report-ko.md)
- [62개 동작과 전이·접촉 검수 범위](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/docs/v3/animation-review-ko.md)
- [실행 방법·조작 안내](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/README.md)

현재 로컬 실행: [HomeOffice V3](http://127.0.0.1:8060/homeoffice/?signal=local). 이 주소는 이 PC에서 실행 중인 개발 서버입니다. 고정 교실은 [교실 링크](http://127.0.0.1:8060/homeoffice/?signal=local&room=classroom)입니다.

## 빌드 기준

| 항목 | 값 |
|---|---|
| Build ID | `4edb96de-caa2-4b53-b132-5fb0cade9ec1` |
| 엔진 / 웹 템플릿 | Godot 4.6.1 stable / 같은 버전 |
| 물리 | Jolt, 60 Hz, 1 unit = 1 m |
| 네트워크 프로토콜 / 저장 형식 | 3 / 2 |
| 제작 소스 | Blender 5.2.1 LTS 연결에서 V3 별도 씬·파일 제작 |
| 기준 Git 자료 | PR #1 head `e62360fd45e03e15fe7e2371d204dc30ff35c9ae` |
| 이번 변경 전달 방식 | 현재 작업 폴더의 소스·에셋·실행 빌드. 원격 PR/배포 변경 없음 |

해시와 바이트 크기는 [실제 빌드 매니페스트](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/build-info.json)에 있습니다. 과거 `evidence/v2-*`는 회귀 시험의 설계 자료이며 이번 통과 결과로 합산하지 않습니다.

## 읽는 순서

1. 분석에서 원인과 설계 결정을 확인합니다.
2. 요구 대조표에서 각 항목의 구현 파일과 검증 범위를 확인합니다.
3. 검증 보고서에서 자동 실행의 성공·실패·미실행을 확인합니다.
4. 실제 브라우저 캡처와 `.homeworld` 파일로 결과를 재현합니다.

모든 항목을 한꺼번에 ‘완료’로 표시하지 않았습니다. 파일 링크 연동, 엔진 장면 시험, 실제 WebRTC 브라우저 시험, 사람/외부 서비스 검증을 구분했습니다.
