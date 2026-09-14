# 실행·GitHub Pages 배포

사용자가 지정한 공개 저장소는 https://github.com/mjayj9/Friendslop_HomeOffice 입니다. V2 개편은 `codex/godot-homeoffice-v2` 브랜치에서 보존합니다. 기존 main/기존 로컬 Firebase 프로젝트를 삭제하지 않습니다.

이 브랜치의 `docs/`는 Godot 웹 export 정적 파일입니다. Pages의 브랜치 소스를 `codex/godot-homeoffice-v2`, 폴더를 `/docs`로 지정하면 예상 주소는 https://mjayj9.github.io/Friendslop_HomeOffice/ 입니다. 2026-09-15 실제 Pages 배포와 두 독립 Chromium의 공개 시그널링·이동·한글 대화·합성 마이크 RTP를 검증했습니다. 서로 다른 WAN 두 PC 시험은 아닙니다. **실제 배포/브라우저 확인 결과는 `evidence/pages-validation.json`을 확인하세요. 파일이 없으면 공개 검증을 완료했다고 뜻하지 않습니다.**

빌드는 WASM 약 37.7MB, PCK 약 7.3MB이며 정확한 파일별 크기와 SHA256은 `docs/v2/web-build-manifest.json`에 기록합니다. 한국어 로컬 모델은 초기 파일에 포함하지 않고 사용자가 선택하면 Hugging Face에서 약 43.6MB 모델/설정/토크나이저를 받습니다. ONNX 런타임도 선택 시 별도 로드합니다.

운영은 정적 Pages + 무료 공개 PeerServer 시그널링 + STUN/직접 WebRTC입니다. 이 시그널링은 음성 중계 서버가 아니며, 호스트 브라우저가 게임의 기준입니다. 직접 연결 불가 NAT/기관망은 실패할 수 있습니다. TURN/유료 API/상시 서버/Firebase 비용·설정을 추가하지 않습니다. 무료 서비스 가용성은 보장하지 않습니다.

마이크는 HTTPS 또는 localhost의 보안 컨텍스트와 사용자 허가가 필요합니다. 게임이 준비된 뒤 이름을 입력하고 공간을 열어 코드를 공유하세요. 브라우저 내부 프리뷰에서 마이크나 포인터락이 제한되면 정식 Chrome/Edge에서 주소를 엽니다.

로컬 서버 `tools/serve.mjs`는 127.0.0.1:8060, 개발 시그널링은 127.0.0.1:9001에만 바인딩합니다. BlenderMCP 9876은 제작 시에만 쓰며 배포 파일은 이 포트에 접근하지 않습니다. `file://`로 index.html을 열면 실행되지 않습니다.

수동 재빌드: README의 Godot/동일 템플릿 준비 → `tools/build.ps1` → build 결과를 저장소 docs에 복사(시험용 `_qa`/합성 원음 제외) → 변경 브랜치에 커밋/푸시합니다. 기존 Pages source가 있다면 목적과 경로를 확인한 뒤 갱신합니다. `.runtime`, node_modules, .godot, 개인 복구본, 기존 Firebase 파일은 공개하지 않습니다.

GitHub Pro가 무제한 호스팅을 뜻하지 않습니다. [공식 Pages 제한](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)을 따릅니다. 예약 실행이나 유료 리소스를 생성하지 않습니다.

키 재설정·실제 수납함/서랍/조명·저장 참조 검사·원격 소품 보간을 추가한 실행 빌드를 같은 개발 브랜치의 `/docs`에 갱신한다. main과 이전 프로젝트는 유지한다. `deployment/github-pages.yml`은 선택적 수동 재빌드 예제이며 현재 실제 배포는 Pages 브랜치 배포다.
