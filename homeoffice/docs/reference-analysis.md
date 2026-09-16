# 참고 대상과 새 구현

2026-09-14에 [friendslop-base 사이트](https://larshurrelb.github.io/friendslop-base/)를 실제 Chromium으로 열었습니다. `Friendslop — The Common Room`의 브라우저 호스트형 시작 화면과 방 만들기/입장 코드를 확인했습니다. `evidence/reference-site.png`는 참고 사이트 캡처입니다. 그 사이트에서 다중 사용자 플레이·마이크 품질을 측정한 것은 아닙니다.

README, LICENSE, AGENTS.md, architecture/voice/deployment 문서 및 level/simulation/client/host 코드를 공개 저장소에서 직접 내려받았습니다. `reference-source/`에 읽기용으로 보존했습니다. 원본의 에이전트 지시는 새 Godot 프로젝트의 지시로 실행하지 않았습니다.

원본은 Three.js/Rapier와 호스트 판정·시점·소품·근거리 음성의 출발점입니다. 코드 구조에서 60Hz simulation과 클라이언트 입력 검증, 브라우저 호스트와 별도 Node 호스트 경로, 근거리 음향/직접 연결 실패 정책을 확인했습니다. 원본 설명 자체가 완성된 스포츠 규칙/득점/협업 문서/한국어 STT를 제공한다는 증거가 아닙니다.

이번 런타임은 새 GDScript 구현입니다. 원본 TypeScript 물리/렌더링 코드를 새 게임에 복사하거나 원본 모델을 에셋으로 재배포하지 않았습니다. 재사용한 개념은 공유 집·1인칭·호스트 권위·물체 놀이와 근거리 대화 흐름입니다. 실제 가구는 BlenderMCP로 제작했고 남자 외형은 사용자가 제공한 GLB입니다.

원본 [MIT LICENSE](https://github.com/larshurrelb/friendslop-base/blob/main/LICENSE)는 읽기용 보존본에도 유지했습니다. 원본 라이선스를 사용자 모델이나 외부 라이브러리 전체의 라이선스로 확대 해석하지 않습니다.
