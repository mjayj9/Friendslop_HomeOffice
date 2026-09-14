# 모여집 · Friendslop HomeOffice V2

Godot 4.6.1 / GDScript로 만든 집+오피스 소셜 공간입니다. 기본 화면은 캐릭터의 1인칭 시점입니다. **필수 기능을 구현·검증 중인 개발 빌드이며 전체 제품 완료가 아닙니다.**

2층 본관, 현관/계단, 거실·식당·주방, 회의실·자료 공간, 자유방, 독립 개인실과 확장 복도, 수면/독서/욕실, 연결된 게임 별동, 테라스·농구·축구 마당이 있습니다. 환경은 BlenderMCP로 제작했고 실제 사용자 제공 남자 GLB를 연결했습니다.

## 실행

- 웹: GitHub Pages 배포 주소는 [배포 안내](docs/deployment.md)를 확인하세요.
- 로컬: Node 22.12 이상에서 이 폴더의 `npm ci --ignore-scripts` 후 `npm run dev`. `http://127.0.0.1:8060/homeoffice/?signal=local`을 두 개의 독립 Chrome/Edge 창에서 여세요.
- 한 사람이 **함께할 공간 열기**, 친구는 초대 코드를 입력하고 **참여**합니다. 마이크는 입장 후 Esc 메뉴에서 직접 켭니다. 기본은 V 눌러 말하기이며 열린 마이크를 선택할 수 있습니다.
- 직접 P2P가 실패하는 NAT/기관망에서는 연결할 수 없을 수 있습니다. 유료 TURN, Firebase, 상시 서버로 자동 우회하지 않습니다. 호스트 탭을 숨기면 게임이 일시정지됩니다.
- Godot 프로젝트: `project.godot`. Compatibility / 단일 스레드 / Jolt 60Hz. JavaScriptBridge 기반 온라인·음성·문서 기능은 웹 빌드에서 동작합니다.

## 조작과 생활

| 입력 | 동작 |
|---|---|
| WASD / 마우스 / Shift / Space / C | 이동 / 시점 / 달리기 / 점프 / 웅크리기 |
| E | 보고 있는 의자·소파 앉기, 물건 집기, 문·책상·보드·스크린·기계 사용, 일어서기 |
| Q / 클릭 | 내려놓기(농구 패스) / 던지기·마카 쓰기·총 발사 |
| F | 든 책 읽기; 축구공 근처에서 짧게 패스/길게 누른 뒤 슛 |
| R / 클릭 누른 뒤 놓기 | 농구 드리블 또는 총 재장전 / 농구 충전 슛 |
| Z | 소파 눕기·침대 취침·접시를 들고 앉았을 때 먹기 |
| B / R / 클릭 | 가구 카탈로그·미리보기 / 회전 / 설치 |
| G / Delete | 보고 있는 일반 가구 이동 / 제거 (점유·보호 위치는 호스트 거절) |
| Enter / V / Esc | 텍스트 대화 / 눌러 말하기 / 메뉴·포인터락 탈출 |

주방에서는 냉장고에서 재료를 받고, 조리대의 화구에 넣어 6초 뒤 조리된 음식을 집습니다. 준비대 위 접시에 담은 다음 식탁 의자에서 Z로 먹고 싱크에서 접시를 정리합니다. 각 단계는 실제 물건/호스트 상태입니다. 현재 한 종류의 간단한 조리 경로이며 동작의 미술/그립은 다듬는 중입니다.

회의실의 책상 E로 Yjs 공동 보고서/메모/마인드맵, 보드 E로 확대 도구, 스크린 E로 PDF/이미지 발표를 엽니다. PPTX 직접 재생은 지원하지 않으며 PowerPoint에서 PDF로 내보냅니다. 발표자 권한, 페이지, 레이저와 주석이 공유됩니다. 문서 입력 중 이동 입력을 막습니다.

게임 별동은 방장 메뉴에서 문을 열고 사용자별 출입을 승인합니다. 무기 사용 승인은 별도입니다. 자체 제작 정원 미로는 씨앗 수집/로봇 회피, 공룡 러너는 장애물 점프 게임입니다. 기계 앞에서 E로 실행하고 닫으면 원래 캐릭터 위치로 돌아옵니다.

## 내보내고 다시 만나기

방장이 Esc → **공간 내보내기**로 `.homeworld` 파일을 내려받습니다. 파일을 실제 보관했는지 확인하세요. 다음 모임 때 한 사람이 빈 호스트 세션에서 **파일 가져오기** → 검증 미리보기 → 복원을 실행하고 새 초대 코드를 공유합니다. 복원 전 현재 세계/문서의 백업 다운로드가 먼저 완료되도록 순서를 분리했습니다.

단일 파일에는 가구·개인실·복도·문·보드·Yjs 문서·원본 PDF/이미지·발표 페이지/주석·생활 상태·스포츠/아케이드 결과가 들어갑니다. 기본 에셋은 버전 ID 참조입니다. 옛 peer/호스트/무기 권한과 좌석·손 점유를 재사용하지 않습니다. 원음·동의 없는 전사·토큰·개인키·실행 코드를 포함하지 않습니다. 허용 경로, CRC/SHA256, 버전/크기/ID/자산/참조를 검증합니다. 압축 폭주를 막기 위해 압축 없는 ZIP 항목만 받습니다. 현재 제한은 32MiB / 첨부 64개 / 자료당 16MiB입니다.

정상 방장 이전은 두 단계 확인과 체크포인트로 세계·문서·권위를 전달합니다. 강제 종료는 마지막 확인 시각과 손실 가능성을 표시하고 복구본으로 **새 세션**을 엽니다. 무중단 이전·자동 영구 저장을 보장하지 않습니다.

## 실제 검증과 남은 필수 작업

| 증거 | 범위 |
|---|---|
| `evidence/v2-browser-walk.json`, `v2-walk-video/` | 실제 Chromium에서 키보드 연속 보행과 게임 캡처 |
| `evidence/v2-multiplayer-scale.json` | 독립 Chromium 2/4/8명, 개인실/동일 이름/기존 책상/퇴장 보존 |
| `evidence/v2-browser-collaboration.json` | 두 브라우저 Yjs 동시 한국어 CDP 조합 입력·메모·마인드맵 |
| `evidence/v2-browser-presentation.json` | 원본 PDF 수신·페이지·권한·레이저·주석·다운로드 |
| `evidence/v2-browser-handoff.json` | 복원/late join/좌표·Yjs·PDF·주석·권위 이전과 재내보내기 |
| `evidence/v2-browser-arcade-voice.json` | 실제 기계 접근/미로 수집/러너 실패·재시작, 합성 마이크 RTP, 범위/방송/강제 종료 복구 |
| `evidence/v2-interactions.json`, `v2-authority.json`, `v2-dribble.json` | 실제 Godot 엔진의 제어된 위치/행동·권위·물리 시험. 사람 플레이와 구분 |
| `docs/v2/korean-stt-measurement.md` | 로컬 한국어 Whisper의 합성 6문장 CER/WER/추론/FPS. 실제 사람 품질 아님 |

한 PC에 브라우저 8개를 실행한 시험에서 호스트 6~7fps로 목표 성능에 못 미쳤습니다. 실제 사람 음성·여러 마이크의 한국어 인식, 자연스러운 전체 캐릭터 동작/손·발 그립, 수납/서랍/조명, 팀 경기 규칙, 모든 기능을 함께 쓰는 회의·생활·저장 인수, 다른 WAN의 두 PC와 장시간 성능 검증이 남았습니다.

전체 필수 범위는 [U01~U56](docs/v2/requirements-traceability.md), [80개 인수](docs/v2/acceptance-80.md), [필수 미완료](docs/v2/required-remaining.md)에 기록했습니다. 버튼이나 씬만 있는 기능을 검증완료로 표시하지 않습니다.

## 다시 빌드 / 제작

Godot 공식 **4.6.1 stable** 실행 파일과 같은 버전의 `web_nothreads_debug.zip` / `web_nothreads_release.zip`을 `.runtime/godot/` 및 `.runtime/templates/`에 준비합니다. `tools/build.ps1 -Godot <실행 파일>`이 import 후 웹 export와 JS/선택적 ONNX 런타임 복사를 실행합니다. 기본 제공 바이너리 빌드는 npm 재번들 없이 실행됩니다. 소스 수정 시 `node tools/bundle_collaboration.mjs`와 `node tools/bundle_stt.mjs`를 사용합니다.

Blender 원본은 `art/moyeo-v2.blend`, `art/furniture-v2.blend`, `art/male-character-v2.blend`입니다. `.blend`를 열고 Python에서 `os.environ['MOYEO_PROJECT']=r'<프로젝트 절대 경로>'`를 지정해 해당 `art/*.py`를 실행하면 새 제작 씬을 생성합니다. `art/v2-blender-exterior-preview.png`는 **Blender 프리뷰**입니다. `evidence/v2-game-*.png`가 **실제 게임 화면**입니다. 배포 게임은 제작용 9876 포트에 접근하지 않습니다.

테스트는 저장소 상위 폴더에서 `node homeoffice/tests/v2-browser-*.mjs` 중 원하는 파일 하나씩 실행합니다. 여러 GPU 브라우저 시험을 병렬 실행하면 측정이 섞입니다. 이 폴더에서 `npm test`는 Node 저장/아케이드 규칙 시험입니다. GDScript 시험은 Godot `--headless --path homeoffice --script res://tests/v2-interactions.gd` 등을 사용합니다.

[전체 도면과 공간 프로그램](docs/v2/space-program.md) · [참고작 분석](docs/reference-analysis.md) · [라이선스](docs/third-party-notices.md)
