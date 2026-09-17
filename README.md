# COMMONS WORKSPACE · V4 검토 빌드

기존 Friendslop_HomeOffice 저장소와 [공개 게임 주소](https://mjayj9.github.io/Friendslop_HomeOffice/)를 유지하는 Godot 4.6.1 / Jolt 프로젝트입니다. **사용자 검토용 빌드입니다. V4 전체 완료나 운영 인증 완료 상태가 아닙니다.**

- 최신 요구: [V4 통합 명세](homeoffice/docs/v4/master-spec-ko.md)
- 현재 빌드·결함·다음 작업: [TASK_STATE](TASK_STATE.md)
- 모듈과 보존 범위: [구현 지도](homeoffice/docs/v4/implementation-map-ko.md)
- 인증 프레임워크와 사용자 설정: [Clerk 연결 안내](homeoffice/docs/v4/clerk-setup-ko.md)
- 현재 검수: [Q01–Q32](homeoffice/docs/v4/verification-ko.md)
- 조작·실행: [프로젝트 README](homeoffice/README.md)

## 로컬 실행

```powershell
cd homeoffice
npm ci --ignore-scripts
npm run preview -- --port 5173
```

`docs/`에는 V4 검토 배포본이 있습니다. `homeoffice/build/`가 있으면 해당 로컬 빌드를 우선 사용합니다. [로컬 미리보기](http://localhost:5173/)는 이 PC에서만 접속하며, 다른 사람과 검토할 때는 위 공개 게임 주소를 사용합니다. 로컬 다중 브라우저 시험은 `npm run preview -- --port 5173 --local-signaling` 후 `?signal=local`로 접속합니다.

## 검증과 빌드

```powershell
cd homeoffice
npm test
npm --prefix server ci
node --test tests/v4-clerk-adapter.test.mjs
```

Godot 경로를 지정해 `tools/build.ps1 -Godot <4.6.1 콘솔 실행파일> -LocalOnly`로 만듭니다. 이후 `python tools/site_artifact.py verify build --source`가 현재 소스와 로컬 배포 파일을 함께 확인합니다.

**`-LocalOnly`를 빼면 저장소의 `docs/`를 갱신합니다.** 2026-09-17 사용자의 커밋·푸시·사이트 업데이트 요청에 따라 기존 Pages 배포 브랜치 `codex/homeoffice-v3`와 URL을 유지합니다. 검토 대상 Build ID는 `cc2f8fbd-ba33-4601-b716-82bb26422424`이며 [공개 빌드 정보](https://mjayj9.github.io/Friendslop_HomeOffice/build-info.json)에서 실제 반영 여부를 확인할 수 있습니다.

Clerk는 개발 인스턴스의 공개 설정을 사용합니다. 계정 없이 둘러보거나 일반 세션에 참여할 수 있습니다. 관리자 PIN 검증 서버와 운영 관리자 지정은 아직 연결되지 않아 방 잠금·관리 방송은 비활성입니다. [검토 배포 기록](homeoffice/docs/v4/review-deployment-ko.md)에 실행 결과와 제한을 구분합니다.

## 이전 기록

[V3 감사와 검증](homeoffice/docs/v3/README.md)은 역사적 기록입니다. 이전 개인별 게임방/무기 승인은 폐기됐으며 최신 정책은 V4 명세를 따릅니다. 기존 채팅·62개 애니메이션·스포츠·외부 원본 링크·방송·고정 교실을 없던 기능으로 취급하지 않습니다. [라이선스](homeoffice/docs/third-party-notices.md)
