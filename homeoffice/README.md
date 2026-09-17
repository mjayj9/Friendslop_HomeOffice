# COMMONS WORKSPACE · V4 개발 빌드

Godot 4.6.1 / Jolt / Blender의 기존 V3 세계를 보존하며 V4 통합 명세를 적용하는 중입니다. [현재 상태](../TASK_STATE.md) · [V4 검수](docs/v4/verification-ko.md) · [Clerk 설정](docs/v4/clerk-setup-ko.md). 전체 제품 인수와 실제 외부 계정·마이크 검증은 미완료입니다.

**이전 V3 기록(현행 정책이 아님):** [V3 보고서](docs/v3/README.md) · [요구사항 전수 대조](docs/v3/requirements-traceability-ko.md) · [실행 결과](docs/v3/verification-report-ko.md)

## 바로 실행

프로젝트 폴더 `homeoffice`에서 Node 22.12 이상을 사용합니다. 필요한 패키지가 이미 있다면 재설치할 필요가 없습니다.

```powershell
npm ci --ignore-scripts
npm run preview -- --port 5173 --local-signaling
```

[로컬 게임](http://localhost:5173/?signal=local)을 엽니다. 한 사람이 **함께할 공간 열기**, 다른 독립 브라우저는 **AAA-AAA 초대 코드 또는 초대 링크**로 참여합니다. 혼자 볼 때는 **혼자 먼저 둘러보기**를 선택합니다.

[고정 교실](http://localhost:5173/?signal=local&room=classroom)은 같은 주소로 입장합니다. 빈 교실의 첫 참가자가 시뮬레이션 호스트가 되고, 동시 입장은 단일 호스트로 정리됩니다. 최초 입장자를 교사로 인증하지 않습니다. 총은 교실에서도 집어 사용할 수 있습니다. 방 잠금·방송 관리자는 별도 Clerk 신원/PIN 서버 검증을 사용하며, 운영 서비스 미연결 상태에서는 해당 관리자 기능이 비활성입니다.

새 체크아웃은 포함된 `../docs/` 배포본을 자동으로 사용합니다. `build/`가 있으면 해당 로컬 빌드를 사용합니다. 서버는 loopback 5173/9001을 사용하며 로컬 URL은 다른 PC의 접속 주소가 아닙니다. [공개 검토 빌드](https://mjayj9.github.io/Friendslop_HomeOffice/)는 GitHub Pages의 `/docs` 배포본입니다.

## 기본 조작

| 입력 | 동작 |
|---|---|
| WASD / 마우스 또는 방향키 | 이동 / 시점 |
| Shift / Space / Ctrl | 달리기 / 점프 / 웅크리기 |
| C / 마우스 휠 | 일반 1·3인칭 전환 / 줌 |
| **E** | 이동 가능한 사물 집기 / 들고 있으면 내리기 |
| **Q** | 사물 던지기 / 농구·축구 짧은 패스 |
| **F** | 앉기·일어서기·취침·깨기·읽기·문·조명·수납·컴퓨터·보드·게임기 사용 |
| 좌클릭 | 총 연사 / 마카 사용 / 레이저 유지 / 공 충전 슛과 릴리스 |
| R | 총 재장전 / 농구 드리블 전환 / 수납함 열기·닫기 / 빈손으로 회의실에 앉으면 자료 열기 |
| 우클릭 | 총 어깨 조준 / 농구 드리블 손 전환 |
| B / G / Delete | 가구 카탈로그 / 일반 가구 배치 이동 / 제거 |
| Z | 소파 눕기 / 추가 휴식 / 접시를 들고 앉아서 먹기 |
| Enter / V / M | 텍스트 대화 / 눌러 말하기 / 음소거 |
| Esc | 도구 종료 또는 메뉴·커서 해제 |

메뉴에서 키를 바꾸고 기본값으로 복원할 수 있습니다. 안내는 현재 대상과 활동에 따라 달라집니다. 한글·채팅·문서 입력 중에는 이동과 발사를 막습니다.

## 둘러보기

- **HOME:** 거실·식당·주방·팬트리, 실제 계단을 거쳐 침실·독서·욕실. 의자·책·수납·스탠드·요리/식사 경로를 보존했습니다.
- **OFFICE:** 회의실 8석, 컴퓨터·키보드·마이크·스크린·보드, 공동 도구, 방송석, 참가자 수에 따라 최대 8개까지 늘어나는 개인실과 복도.
- **PLAY:** 게임 별동, 농구·축구 마당, 두 게임기에서 사용하는 공룡 러너.

계단은 현관 왼쪽에서 올라가 계단참을 돌아 반대편 계단으로 올라갑니다. 개인실 복도는 2층에서 북쪽으로 이어집니다. 게임방과 아케이드 사이에는 내부 통로가 있습니다.

### 회의

회의 책상이나 컴퓨터를 바라보고 **F**를 누르면 회의 자료와 검색을 엽니다. 내장 공동 보고서·메모/투표·마인드맵·의제/결론·질문 대기열·담당자별 할 일·손들기·타이머를 사용할 수 있습니다.

Google Docs/Slides/Sheets와 Microsoft OneDrive/SharePoint의 Excel 원본 URL을 등록하면 같은 참조가 공유됩니다. **원본 열기**는 실제 제공 서비스의 창을 엽니다. 그 서비스의 공유 권한은 사용자가 해당 서비스에서 설정합니다. 내장 Yjs 보고서는 별도 기능입니다.

발표 스크린 **F**에서 PDF/PNG/JPEG를 올리고 페이지·주석·발표자 권한을 공유합니다. PPTX는 PowerPoint 등에서 PDF로 내보낸 파일을 사용합니다. 원본 첨부는 `.homeworld`에 포함됩니다.

회의실 레이저 소품을 **E**로 들고 스크린을 보며 클릭을 유지하면 실제 3D 충돌 지점에 포인터가 표시됩니다. 발표 권한과 장애물 판정을 거칩니다.

### 생활과 욕실

앉거나 누운 상태에서 F는 항상 일어서기·깨기입니다. 회의실에 빈손으로 앉아 있을 때 R로 자료를 열고, 책을 들고 앉아 있을 때 R로 읽습니다.

책은 E로 집고 F로 읽고 Q로 던집니다. 수납함/서랍을 바라보며 F를 누르면 대상의 수납 기능이 우선합니다. R은 수납함을 열고 닫습니다. 내용물이 있거나 다른 사람이 점유한 가구는 이동·철거를 막습니다.

냉장고 F로 재료를 받고 화구 F에 넣어 약 6초 조리합니다. 준비된 음식을 꺼내 E로 집고 준비대에서 접시에 담습니다. 접시를 들고 식탁에 앉아 Z로 먹고 싱크 F로 정리합니다. 간단한 한 종류의 조리 시뮬레이션입니다.

침대 F로 취침하면 자기 몸체가 3인칭으로 보이고, F로 깨면 안전한 위치에서 취침 전 시점으로 돌아옵니다. 욕실에서는 변기 뚜껑·물내림·수도·환기, 벽 스위치로 조명을 사용합니다.

### 스포츠와 장난감 총

농구는 E로 공을 집고 R로 실제 반발 드리블, 우클릭으로 손 전환, Q 패스, 클릭 유지/놓기로 충전 슛을 합니다. 빈손 F는 가까운 드리블 공을 노립니다. 슛은 실제 공 속도와 backspin을 사용하며 골대 흡인력은 없습니다.

축구장에서는 손으로 공을 집지 않습니다. 공에 다가가 움직이면 발 터치를 하고 Q 패스, 클릭 충전/릴리스 슛, F 가로채기를 사용합니다. 공은 자유 물리 상태이며 경계 밖이나 골 이후 중앙에서 재개합니다.

일반 자유사격은 모든 공간에서 별도 사용자 승인 없이 사용할 수 있습니다. 기본 무제한 탄약이며 클릭 유지 시 220ms 간격으로 발사합니다. 제한 탄약은 명시적으로 선택하는 경기 규칙으로 분리합니다. 100 HP/25 피해, KO 후 3초 복귀와 2초 보호, 킬 게이지 판정은 유지합니다. 실제 소유권·세션·발사 간격·벽·방패 검증은 계속 적용됩니다.

공룡 러너는 기계 앞에서 F, Space/↑ 점프, ↓/C 웅크리기입니다. 다른 참가자는 같은 경기를 관전합니다. 결과·최고 점수·재시작·Esc 종료를 제공합니다.

### 음성·자막·방송

마이크는 입장만으로 켜지지 않습니다. Esc 메뉴에서 장치를 선택해 켜고 V를 누르거나 열린 마이크를 선택합니다. M은 음소거, 메뉴의 **종료**는 장치 캡처와 전달을 끝냅니다. 근거리/같은 구역 범위를 사용합니다.

한국어 자막은 지원 가능한 브라우저 인식 또는 선택한 로컬 Whisper WASM 경로입니다. 모델 다운로드가 필요한 경우 UI에서 안내합니다. 기본 원음·전사 저장과 외부 인식 자동 전환은 하지 않습니다. 이번 합성 음성 결과를 실제 사람의 정확도로 해석하지 않습니다.

OFFICE 북쪽 방송석에서 권한을 받은 사용자가 F → ON AIR로 세션/HOME/OFFICE/PLAY 범위를 선택합니다. 다른 음성과 효과음은 방송 중 줄어들며, 콘솔 이탈/권한 회수 시 종료합니다. 수동 공지는 저장할 수 있습니다.

## 내보내기·복원·방장 인계

Esc → **공간 내보내기**에서 `.homeworld` 파일을 실제로 내려받아 보관합니다. 다음 모임의 빈 호스트 세션에서 **파일 가져오기 → 검증 미리보기 → 복원**으로 다시 엽니다. 복원 전 현재 공간의 백업 다운로드를 제공하며, 연결된 참가자가 있으면 직접 파일 덮어쓰기를 막습니다.

파일에는 개인실/복도·사물·보드·내장 공동 문서·질문/할 일·PDF/이미지·발표 페이지/주석·외부 문서 참조·시설·수동 공지·경기 결과가 들어갑니다. 옛 연결 권한과 손/좌석 점유·자동 발사 상태는 재사용하지 않습니다. 형식·크기·허용 경로·CRC/SHA256·ID·참조를 검증합니다.

정상 방장 인계는 확인 응답과 체크포인트를 거칩니다. 교실은 고정 주소를 유지합니다. 강제 종료는 최근 확인 복구본과 시점을 안내하며, 모두 떠난 교실을 상시 서버가 자동 영구 저장하지는 않습니다. 보존은 내보낸 파일을 사용합니다.

## 다시 빌드

다시 빌드할 때만 Python 3과 Godot **4.6.1 stable**이 필요합니다. 새 체크아웃의 `npm run preview -- --port 5173 --local-signaling`에는 필요하지 않습니다.

1. [Godot 4.6.1 공식 배포](https://github.com/godotengine/godot-builds/releases/tag/4.6.1-stable)에서 Windows 실행 파일과 같은 버전의 export templates를 받습니다.
2. Windows 실행 파일을 `.runtime/godot/`에 풀거나 `-Godot`으로 실행 파일의 경로를 전달합니다.
3. export templates의 `web_nothreads_debug.zip`과 `web_nothreads_release.zip`을 `.runtime/templates/`에 둡니다.
4. 아래 빌드를 실행하면 `build/`와 저장소 루트의 `docs/`가 함께 갱신됩니다. `.runtime/`와 `build/`는 커밋하지 않고, 갱신된 `docs/`는 소스와 함께 커밋합니다.

```powershell
# homeoffice 폴더에서
./tools/build.ps1
# 다른 위치의 Godot를 사용하는 경우
./tools/build.ps1 -Godot "C:/Tools/Godot/Godot_v4.6.1-stable_win64_console.exe"
# 소스와 Pages 배포본을 확인
npm run verify:published

# 공동 편집 원본을 바꿨을 때만
node tools/bundle_collaboration.mjs
# Whisper worker 원본을 바꿨을 때만
node tools/bundle_stt.mjs
```

기본 빌드는 GitHub Pages가 제공하는 `../docs/`까지 갱신합니다. 로컬 빌드만 필요하면 `-LocalOnly`를 사용합니다. 빌드마다 UUID와 하위 의존 파일을 포함한 SHA256 목록을 생성합니다. JS/PCK/WASM 핵심 파일이 섞이면 입장 전에 오류를 표시합니다. `tools/assemble_v2.py`는 중단된 옛 생성기입니다. 실행 `.gd`를 다시 조합해 덮어쓰지 않습니다.

Blender 제작 원본: `art/male-character-v3.blend`, `art/campus-details-v3.blend`, `art/laser-pointer-v3.blend`. 기존 V2 원본도 보존했습니다. BlenderMCP는 제작에 사용하며 배포 게임이 Blender의 포트에 접근하지 않습니다. 이미 제공된 GLB로 실행할 때 Blender를 켤 필요는 없습니다.

## 재현 검증

```powershell
# homeoffice 폴더
npm test
npm run test:browser
npm run test:connection
npm run test:soak  # 기본 30분 활동, 실제 브라우저 8개 사용
./tools/test_v3_engine.ps1  # Godot 엔진 회귀

# 저장소 상위 폴더에서 필요한 시험 하나씩 실행
node homeoffice/tests/v3-tools-flow.mjs
node homeoffice/tests/v3-arcade-flow.mjs
node homeoffice/tests/v3-voice-facilities.mjs
node homeoffice/tests/v3-life-flow.mjs
& homeoffice/.runtime/godot/Godot_v4.6.1-stable_win64_console.exe --headless --path homeoffice --script res://tests/v3-authority-physics.gd
```

브라우저 시험을 동시에 실행하면 같은 GPU 자원을 나눠 사용합니다. 현재 실행 로그와 환경·실패/미실행·제약은 [검증 보고서](docs/v3/verification-report-ko.md)에 기록했습니다. 테스트의 진단값은 판정에 사용하지만 사람 플레이로 위장하지 않습니다.

[전체 분석](docs/v3/implementation-analysis-ko.md) · [62개 애니메이션](docs/v3/animation-review-ko.md) · [라이선스](docs/third-party-notices.md)
