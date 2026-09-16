# 제3자 자료와 라이선스

- Godot Engine 4.6.1 / Jolt Physics: MIT. 엔진이 export한 JS/WASM과 전체 저작권 목록은 [Godot 라이선스](https://godotengine.org/license/) 및 `licenses/`를 따릅니다.
- PeerJS 1.5.5 / PeerServer 1.0.2: MIT. Playwright 1.63.0: Apache-2.0 (시험 도구).
- Yjs 13.6.27, y-quill 1.0.0: MIT. Quill 2.0.3: BSD-3-Clause. PDF.js 6.3.289, Transformers.js 4.2.0: Apache-2.0. ONNX Runtime: MIT. 정확한 의존성은 package-lock.json입니다.
- 사용자가 제공한 quaternius_cc0-male-character-*.glb: 파일명/제공 출처는 Quaternius. [제작자 공식 FAQ](https://quaternius.com/faq.html)는 모든 모델의 CC0와 수정/상업적 사용 허용을 명시합니다. 개별 파일이 어떤 팩에서 내려왔는지는 확인되지 않았으며 원본 파일과 검사 정보는 보존했습니다. 새 리깅/절차 동작은 제공 애니메이션이라고 주장하지 않습니다.
- Noto Sans KR 게임용 subset: SIL OFL 1.1. 원래 이름/라이선스 고지를 `assets/fonts/OFL-NotoSansKR.txt`에 보존합니다. DOM은 시스템 폰트 fallback을 사용합니다.
- 선택적 로컬 Whisper tiny: [OpenAI Whisper](https://github.com/openai/whisper)의 MIT 모델을 [ONNX Community 변환본](https://huggingface.co/onnx-community/whisper-tiny)으로 사용합니다. revision `ff4177021cc41f7db950912b73ea4fdf7d01d8e7`. 모델은 게임 기본 배포에 포함되지 않으며 사용자가 선택해 다운로드합니다. 음성 추론은 로컬입니다.
- Friendslop Base 참고 문서/코드는 MIT. 읽기용 보존본에 LICENSE를 유지합니다. 원본 앱의 Three.js/Rapier 코드, 캐릭터·음원을 게임에 복제하지 않았습니다.
- 새 환경/가구·나무/천/타일 텍스처·책 본문·정원 미로/공룡 캐릭터·장난감 효과음은 이번 작업에서 제작했습니다. 별도 상용 게임 상표·캐릭터·음원은 사용하지 않았습니다.

전문은 `licenses/` 및 번들 안의 라이선스 주석을 따릅니다. 공개 배포 docs/licenses에도 포함합니다. 이 문서는 서로 다른 라이선스를 프로젝트 전체에 일괄 적용하지 않습니다.

의존성 감사: 현재 npm 그래프에 Quill의 사용하지 않는 HTML export 경로(low) 및 Transformers.js의 Node 전용 ONNX 설치/Sharp/adm-zip 경로(high) 경고가 있습니다. 웹 번들은 Node 설치/ZIP/Sharp 경로를 사용하지 않고 npm 설치는 `--ignore-scripts`로 합니다. 전체 개발 의존성 경고 해소는 남아 있으며, 이 사실을 전체 의존성 보안 검증 완료로 해석하지 않습니다.
