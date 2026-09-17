# Clerk 로그인과 관리자 PIN 서버

현재 **`http://localhost:5173/`**에 실제 Clerk 개발 앱 `app_3JPx7wBJ683SFfndYIqhAHGOKeX`를 연결했다. 공개 Frontend API는 `https://frank-whale-1215.clerk.accounts.dev`다. CLI 로그인과 프로젝트 link, 실제 Clerk 로그인/가입 화면 표시를 확인했다. 사용자 게임 계정 로그인·관리자 UID 지정·PIN 서버는 아직 확인 대기다. 기존 Firebase는 변경하지 않았다. 사용자의 후속 배포 요청에 따라 같은 개발 설정을 포함한 검토 빌드를 기존 Pages 주소에 게시한다. 운영 인증 전환이나 PIN 서버 배포가 아니다.

## 지금 사용자가 할 일

1. `cd homeoffice` 후 `npm run dev`로 시작하거나, 이미 실행 중인 [http://localhost:5173/](http://localhost:5173/)를 연다.
2. 첫 화면 **COMMONS 계정 → 회원가입 또는 로그인**을 선택한다. CLI 개발자 계정 로그인과 게임 계정 로그인은 별개다.
3. **로그인됨**과 계정 아이콘이 보이면 **내 사용자 ID 복사**를 눌러 관리자 대상으로 사용할 `user_…`를 확인한다. 로그인만으로 방 잠금/방송 관리자 권한이 생기지 않는다.

현재 빌드 `cc2f8fbd-ba33-4601-b716-82bb26422424`에서 실제 Clerk 창 표시·입력 차단 4개 시험과 구성 UI 2개 시험을 통과했다. 계정 가입·비밀번호 입력을 테스트 봇이 수행하지 않았으며 실제 사용자 로그인 성공으로 표시하지 않는다. [실행 증거](../../evidence/v4/clerk-local/report.json)

CLI `init`은 기존 Godot/ES modules를 자동 감지하지 못했다. `clerk link --app app_3JPx7wBJ683SFfndYIqhAHGOKeX`로 지정 앱을 연결하고 공식 JavaScript SDK/CDN 방식을 사용했다. `clerk doctor`에서 로그인·앱 접근/연결은 정상이며, production 미설정과 env 파일 없음은 경고다. 공개 키는 `web/admin-config.mjs`에 있고 Secret Key가 담긴 env 파일을 만들지 않았다.


## 선택할 프레임워크

Clerk의 프런트엔드 예시는 **JavaScript / Vanilla JS**, 서버 예시는 **Node.js**를 선택한다. 기존 게임의 ES modules에 Clerk SDK를 연결하므로 새 Vite 앱을 만들 필요가 없다. Dashboard의 API Keys → Quick Copy에서 JavaScript를 고르면 된다.

| 구성 | 역할 |
|---|---|
| 기존 Godot 4.6.1 Web | 3D 세계, 이동, 물리, 도구, 경기 |
| 기존 ES modules + Clerk JS 6 / UI 1 | 로그인 창과 관리자 설정 화면 |
| 기존 GitHub Pages | 게임·공개 설정·서명 공개키 배포 |
| 별도 Node.js + `@clerk/backend` 3.18.1 | 로그인 토큰 검증, 관리자 UID 확인, PIN KDF 검증, 정책 서명 |
| 서버의 비공개 영속 저장소 | 방별 salted scrypt 검증값, 잠금 상태, 서명 개인키 |

학생 입장은 기존 교실/초대 경로를 유지한다. 먼저 들어온 시뮬레이션 호스트가 운영 관리자가 되지 않는다. Clerk 사용자 ID가 서버의 관리자 목록에 있어야 하며, 방 PIN도 확인해야 잠금을 변경한다.

## 다른 개발 인스턴스로 다시 연결할 때

1. Clerk에서 새 앱을 만들고 Google 또는 이메일 로그인을 활성화한다. 개발 인스턴스로 먼저 검증한다.
2. **Publishable Key (`pk_test_…`)**를 먼저 전달한다. Frontend API HTTPS 주소가 함께 보이면 같이 전달해도 된다. 공식 JavaScript 방식처럼 공개 키에서 Frontend API 도메인을 확인할 수 있으므로, 주소를 따로 찾느라 막힐 필요는 없다.
3. 연결된 게임의 메뉴 → 방 잠금 · 운영 관리자 → Clerk 관리자 로그인에서 본인 계정으로 가입한다. 로그인 후 버튼을 다시 누르면 서비스 연결 전에도 사용자 ID를 확인할 수 있다. Clerk Users에도 표시되는 **`user_…` ID**를 관리자 대상으로 지정한다. 로그인만으로 관리자 권한을 주지 않는다.
4. API Keys에서 **JWT Public Key → PEM 공개키**를 확인한다. 서버는 이 공개키와 발급자 URL, 허용 Origin으로 Clerk 토큰을 검증한다.

Secret Key, 로그인 세션 토큰, PIN, 서명 개인키는 대화·소스·공개 설정에 넣지 않는다. `pk_test_…`는 공개 식별자이며 관리자 권한을 부여하는 비밀키가 아니다.

프런트엔드 공개 설정은 `web/admin-config.mjs`에 연결한다. 서버의 허용 Origin은 실제 Pages의 `https://mjayj9.github.io`다. Pages 하위 경로는 Origin에 포함되지 않는다. 이 작업의 로컬 시험 Origin은 정확히 `http://localhost:5173`이다. `127.0.0.1`은 다른 Origin이다. 로컬 Origin은 운영 때 제거한다.

## 개발용 연결과 운영 전환

처음에는 **Development** 인스턴스를 유지한다. JavaScript Quick Copy의 공개 키를 전달하면 기존 게임에 연결할 수 있다. 사용자가 새 프런트엔드 저장소나 Node 코드를 직접 만들 필요는 없다.

Clerk의 정식 Production 전환은 본인이 소유하고 DNS를 설정할 수 있는 도메인을 요구한다. GitHub Pages의 기존 `mjayj9.github.io/Friendslop_HomeOffice` 주소는 유지하며, 운영 인증 도메인/프록시 또는 별도 관리자 로그인 화면을 어떻게 연결할지 검증한 뒤 서버·도메인 비용과 변경 범위를 합의해야 한다. 개발 키로 로그인되는 것을 이 운영 조건의 완료로 간주하지 않는다. [Clerk 운영 배포 조건](https://clerk.com/docs/guides/development/deployment/production)

## 구현한 서버 계약

- `GET /state`: session + 매 요청 nonce에 바인딩된 P-256 서명 정책. 유효기간 30초. 브라우저는 고정 공개키·세션·nonce·revision·만료를 확인한다.
- `POST /identity`: Clerk 토큰을 검증하고 비공개 UID 목록과 비교한다.
- `POST /command`: 방별 잠금/해제/열어 두기/PIN 변경, 방송실 인증. 관리자 신원과 현재 PIN을 함께 검증한다.
- PIN은 방마다 독립 salt와 scrypt(N=32768, r=8, p=1, 32bytes)로 저장한다. 계정 전체에서 15분당 실패 시도 5회 제한. 공개 응답에는 PIN과 hash가 없다.
- 명령은 session/zone/revision/nonce로 확인하고 응답은 서명한다. 오래된 revision·반복 nonce·다른 세션·서명 변경·만료는 거절한다.
- 방송 인증은 해당 세션의 참가자 ID에 10분간 연결한다. 실제 콘솔 가까이에서만 방송할 수 있고, 정책 갱신 실패로 서명이 만료되면 방송 권한이 유효하지 않다.
- 첫 정책 수신을 기다리는 설정된 클라이언트는 공개 이동 경로를 제외한 새 입장을 잠정 차단한다. 연결 실패 때 마지막 잠금 상태를 유지하며 퇴실을 막지 않는다.

짧은 PIN 자체가 강한 계정 인증은 아니다. Clerk 계정 인증과 서버의 UID 확인이 먼저다. 고정 교실은 고정 정책 ID를 쓰고 일반 세션은 별도 정책 ID를 쓴다.

## 서버 실행 준비와 배포 범위

`server/package.json`과 lockfile에 SDK 버전을 고정했다. 설치는 `npm --prefix server ci`, 실행은 `node server/serve-admin.mjs`다. 기본 바인딩은 loopback이며 운영 시 HTTPS reverse proxy가 필요하다.

필수 서버 설정:

- `COMMONS_PRIVATE_DIR`: **프로젝트 밖**의 비공개 절대 경로. Windows에서는 소유자와 서비스 계정만 접근할 수 있도록 ACL도 설정한다.
- `COMMONS_ADMIN_IDS`: 서버만 읽는 실제 Clerk 관리자 UID 목록.
- `COMMONS_ORIGINS`: 허용할 웹 Origin 목록.
- `CLERK_ISSUER`: 실제 Clerk 토큰 발급자 HTTPS 주소.
- 비공개 폴더의 `signing-key.pem`(P-256 개인키), `clerk-jwt-public.pem`(Clerk 공개 검증 키).
- 최초 부트스트랩의 `initial-pin.private`: 사용자 비공개 메모의 지정값을 운영자가 전달한다. 서버가 KDF로 바꾼 뒤 이 일회성 파일을 제거한다. 이 작업은 아직 실행하지 않았다.

서버는 요청 본문·토큰·PIN을 로그에 남기지 않는다. 단일 프로세스의 원자적 파일 교체를 사용한다. 여러 replica로 확장하려면 공유 트랜잭션 저장소와 공유 rate limit이 먼저 필요하다. 무료 호스팅의 임시 디스크를 영속 비밀 저장소로 취급하지 않는다.

2026-09-17 확인한 Clerk Hobby는 월 유지 사용자(MRU) 50,000명까지 무료이며 카드가 필요 없는 요금제다. 별도 Node 서버·영속 저장소·도메인의 비용은 호스팅을 선택한 뒤 확정해야 한다. 별도 서버 생성·결제·운영 배포 변경은 하지 않았다. [Clerk 요금표](https://clerk.com/pricing)

## 검증 범위와 남은 경계

서버 단위/실제 loopback HTTP 시험과, 공식 Clerk SDK의 **합성 토큰** 검증을 실행했다. 실제 Clerk SDK와 로그인/가입 창은 연결했으며 계정 로그인 성공·계정 복구·운영 키 회전·외부 HTTPS 서비스·다중 기기 PIN UI는 확인 대기 또는 미실행이다.

방 잠금은 물리적 입장 정책이다. 현재 P2P 호스트는 세계와 협업 데이터를 중계한다. 악의적으로 수정한 호스트에 대한 기밀 문서 경계, 서버 소유 시뮬레이션, 신뢰된 세션 directory는 완성되지 않았다. 이를 기밀 회의실 보안이라고 표시하지 않는다.

참고: [JavaScript 연결](https://clerk.com/docs/js-frontend/getting-started/quickstart), [서버 verifyToken](https://clerk.com/docs/reference/backend/verify-token), [Session getToken](https://clerk.com/docs/js-frontend/reference/objects/session).
