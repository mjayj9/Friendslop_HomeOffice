# Friendslop HomeOffice · V3

[웹에서 실행](https://mjayj9.github.io/Friendslop_HomeOffice/) · [조작 안내](homeoffice/README.md) · [V3 분석·요구 대조](homeoffice/docs/v3/README.md)

Godot 4.6.1 / Jolt 기반의 집·오피스·회의·게임 공간입니다. V3에는 상대 캐릭터 표시 수리, 의자·책·생활 조작, Blender 동작과 시설, 회의 자료·물리 레이저, 전투·스포츠, 방송·교실·저장 복구가 포함됩니다.

## 내려받아 실행

```powershell
cd homeoffice
npm ci --ignore-scripts
npm run dev
```

[로컬 게임](http://127.0.0.1:8060/homeoffice/?signal=local)을 엽니다. 새 체크아웃은 저장소에 포함된 `docs/` V3 배포본으로 실행됩니다. 로컬 `homeoffice/build/`가 있으면 그 빌드를 우선합니다. 게임 실행에 Godot·Blender 설치는 필요하지 않습니다.

## GitHub Pages와 다시 빌드

현재 Pages 배포 원본은 `codex/homeoffice-v3` 브랜치의 `/docs`입니다. `homeoffice/`의 소스만 바꿔 푸시하면 공개 게임이 갱신되지 않습니다.

`homeoffice/tools/build.ps1`은 Godot export → 전체 파일 해시 검증 → `/docs` 갱신을 함께 수행합니다. `-LocalOnly`를 지정한 경우에만 로컬 export로 끝냅니다. 자세한 엔진·템플릿 준비는 [빌드 안내](homeoffice/README.md#다시-빌드)를 참조하세요.

```powershell
python homeoffice/tools/site_artifact.py verify docs --source
```

위 명령과 GitHub 검증 작업은 배포 누락, 소스와 배포본의 불일치, PCK/JS 혼합, 누락된 의존 파일을 검사합니다. 배포 파일은 Git 줄바꿈 변환 없이 저장해 검증 해시를 유지합니다.

## 검증 기록

- [V3 기능·가상 검증](homeoffice/docs/v3/verification-report-ko.md)
- [배포 실패 원인과 수정 검증](homeoffice/docs/v3/deployment-repair-ko.md)
- [라이선스](homeoffice/docs/third-party-notices.md)

기능 시험과 실제 사람·실마이크·서로 다른 외부망 품질 검증은 구분합니다. 기존 V2 증거는 이력으로 보존합니다.
