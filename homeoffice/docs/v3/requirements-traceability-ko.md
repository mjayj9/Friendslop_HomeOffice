# 요구사항 전수 대조

각 행은 구현 경로와 실제 검증 범위를 연결합니다. 시험의 최종 성공 여부와 실행 빌드는 `verification-report-ko.md`를 기준으로 합니다. 구현 경로 존재를 자동 통과로 취급하지 않습니다.

## R01–R30 최신 요구

| ID | 요구 | 구현 | 증거 | 판정 범위·남은 제약 |
|---|---|---|---|---|
| R01 | 현재 PR·빌드·캐시 | [tools/write_build_info.py](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/tools/write_build_info.py); [web/build-guard.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/build-guard.mjs) | [session-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/session-flow/report.json) | 로컬 빌드/혼합 핵심 파일 차단 검증. 운영 서버 최신 응답/배포는 이번 범위 밖 |
| R02 | 상대 몸체 가시성 | [tools/repair_character_materials.py](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/tools/repair_character_materials.py); [scripts/v2/avatar.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v2/avatar.gd) | [integrated-three/](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/integrated-three); [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json) | 실제 3브라우저 화면과 2인 인스턴스. 실제 WAN 제외 |
| R03 | 실제 남자·Blender 동작 | [art/male-character-v3.blend](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/art/male-character-v3.blend); [assets/characters/male-animated-v3.glb](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/assets/characters/male-animated-v3.glb) | [gameplay-tests.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/gameplay-tests.json); [life-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/life-flow/report.json) | 62클립 로딩·일부 실제 동작 검증. 모든 접촉의 미술 검수는 별도 |
| R04 | 발·손·그립 | [scripts/player/contact_ik.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/player/contact_ik.gd); [scripts/v2/avatar.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v2/avatar.gd) | [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json); [life-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/life-flow/report.json) | 실제 속도 전이·IK 적용. 13본 제약과 일부 손 목표 잔차 있음 |
| R05 | 물리·제어기 | [scripts/physics](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/physics); [scripts/sports/ball_profile.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/sports/ball_profile.gd) | [physics-lab.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/physics-lab.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json); [dribble.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/dribble.json) | 낙하·반발·고속 벽 관통·계단·소품 검증. 모든 교행 조합 전수 시험 아님 |
| R06 | 생성기 중단·책임 분리 | [tools/assemble_v2.py](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/tools/assemble_v2.py); [scripts/v3](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v3); `web/*-policy.mjs` | [build-final.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/build-final.log); [node-tests.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log) | 신규 시스템 분리·단일 .gd 원천. 기존 world/bridge의 전면 해체는 남아 있음 |
| R07 | 자유사격·연사·사유 | [scripts/v3/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v3/world.gd); [scripts/combat/toy_effects.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/combat/toy_effects.gd) | [gameplay-tests.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/gameplay-tests.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) | 실제 엔진 발사/광선·권한 검증. 전투 UI 전체를 8명이 플레이한 시험 아님 |
| R08 | HP·KO·게이지 | [scripts/combat/combat_state.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/combat/combat_state.gd); [web/gameplay-hud.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/gameplay-hud.mjs) | [gameplay-tests.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/gameplay-tests.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) | 4회 명중 KO·단일 킬·복귀 보호·게이지 감소 |
| R09 | 농구 조작 루프 | [scripts/v3/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v3/world.gd); [scripts/sports/match_rules.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/sports/match_rules.gd) | [dribble.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/dribble.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json); [gameplay-tests.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/gameplay-tests.json) | 실제 반발 드리블·충전·스틸·패스. 사람의 경기 조작감 제외 |
| R10 | 스핀·림·득점 | [tools/repair_court_rims.py](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/tools/repair_court_rims.py); [scripts/sports/hoop_feedback.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/sports/hoop_feedback.gd) | [court-rim-repair.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/court-rim-repair.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) | 실제 각속도·수정 충돌체·중복 득점 차단. 그물은 시각 반응 |
| R11 | 발로 축구 | [scripts/v3/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v3/world.gd); [scripts/sports/match_rules.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/sports/match_rules.gd) | [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) | E 차단·발 터치·패스·골 중앙 재개·추가 공 등록 |
| R12 | HOME/OFFICE/PLAY | [assets/v2/layout.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/assets/v2/layout.json); [assets/v2/house-v3.glb](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/assets/v2/house-v3.glb) | [life-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/life-flow/report.json); [voice-facilities/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/voice-facilities/report.json) | 실제 분리 평면·재료·동선·음성 범위. 물리 음향실 해석 아님 |
| R13 | 건축 마감 | [assets/v2/house-v3.glb](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/assets/v2/house-v3.glb); [art/campus-details-v3.blend](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/art/campus-details-v3.blend) | [life-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/life-flow/report.json); [house-fixture-repair.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/house-fixture-repair.json) | 계단·난간·문·창·천장·가구. 모든 신체 크기 교행 시험 아님 |
| R14 | E/Q/F/클릭 입력 | [scripts/v3/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v3/world.gd); [web/key-bindings.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/key-bindings.mjs) | [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json); [tools-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/tools-flow/report.json) | 의자/책/레이저 실제 조작, 한글 UI 중 이동 차단 |
| R15 | 책·가구·조명 | [scripts/v2/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v2/world.gd); [scripts/world/campus_details.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/world/campus_details.gd) | [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json); [living-props.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/living-props.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) | 수납·서랍·램프 엔진 회귀, 회로 추가. 모든 가구 조합의 브라우저 전수 인수는 아님 |
| R16 | 공룡 러너 | [web/arcade-rules.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/arcade-rules.mjs); [web/runner-renderer.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/runner-renderer.mjs); [web/arcade.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/arcade.mjs) | [arcade-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/arcade-flow/report.json) | 자체 그림·물리/입력·관전·결과·최고점. Chrome 원본 자산 사용 아님 |
| R17 | 실제 검색·컴퓨터 | [web/document-registry.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/document-registry.mjs); [scripts/world/campus_details.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/world/campus_details.gd) | [node-tests.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log); [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json) | Google 원본 검색/자료 창. 검색 결과를 자체 편집기에 흉내내지 않음 |
| R18 | 본인 3인칭 취침 | [scripts/v2/avatar.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v2/avatar.gd); [scripts/v3/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v3/world.gd) | [life-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/life-flow/report.json) | 실제 계단 접근·F 취침·몸체 표시·F 깨기 |
| R19 | 욕실 시설 | [art/refine_v3_bathrooms.py](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/art/refine_v3_bathrooms.py); [scripts/world/campus_details.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/world/campus_details.gd) | [voice-facilities/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/voice-facilities/report.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) | 뚜껑·수도·물내림·환기·동기화·복원 |
| R20 | 회의실 완성 | [art/author_v3_facilities.py](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/art/author_v3_facilities.py); [web/collaboration-source.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/collaboration-source.mjs) | [tools-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/tools-flow/report.json) | 8석/업무 설비/발표/질문·할 일. 전문 음향 시뮬레이션 아님 |
| R21 | Docs·Slides·Excel 원본 | [web/document-registry.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/document-registry.mjs) | [node-tests.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log); [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json) | 원본 URL 검증·공유·열기 구현. 실제 두 계정 편집은 사용자 지정 범위 밖 |
| R22 | 물리 레이저 | [scripts/v3/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v3/world.gd); [web/presentation.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/presentation.mjs) | [tools-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/tools-flow/report.json); [authority-physics.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/authority-physics.json) | 실제 집기·광선·같은 UV·권한·가림·만료 |
| R23 | 한국어·음성 | [web/captions.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/captions.mjs); [web/caption-policy.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/caption-policy.mjs); [web/local-stt.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/local-stt.mjs) | [stt-browser.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/stt-browser.json); [voice-facilities/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/voice-facilities/report.json); [node-tests.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log) | 가상 RTP/자막 정책/합성 인식 결과. 사람·실마이크 품질은 제외 |
| R24 | AAA-AAA 코드 | [web/invitations.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/invitations.mjs); [web/session-directory.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/session-directory.mjs) | [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json); [node-tests.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log) | 실제 두 브라우저 코드 입장과 형식 검증 |
| R25 | 초대 URL | [web/invitations.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/invitations.mjs); [web/bridge.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/bridge.mjs) | [node-tests.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log); [session-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/session-flow/report.json) | 하위 경로/코드/교실 URL 해석. 외부망 도달성 보장 아님 |
| R26 | 고정 교실 카드 | [web/shell.html](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/shell.html); [web/session-directory.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/session-directory.mjs) | [session-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/session-flow/report.json) | 같은 고정 alias에 입장 |
| R27 | 빈 방·경합·인계·재개 | [web/session-directory.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/session-directory.mjs); [web/handoff.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/handoff.mjs); [web/bridge.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/bridge.mjs) | [session-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/session-flow/report.json) | 동시 선점·정상 인계·강제 종료·빈 재개. 상시 영구 서버 없음 |
| R28 | 방송실 | [web/broadcast.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/broadcast.mjs); [scripts/world/campus_details.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/world/campus_details.gd) | [voice-facilities/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/voice-facilities/report.json); [node-tests.log](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/node-tests.log) | 콘솔 접근·승인·범위·실제 가상 RTP·ducking·공지 저장. 사람 발화 제외 |
| R29 | 기존 전체 기능·복원 | [scripts/v2/world.gd](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/scripts/v2/world.gd); [web/save-v2.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/save-v2.mjs); [web/collaboration-source.mjs](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/web/collaboration-source.mjs) | [user-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/user-flow/report.json); [tools-flow/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/tools-flow/report.json); [scale-soak/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/scale-soak/report.json); [legacy-interactions.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/legacy-interactions.json); [legacy-authority.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/legacy-authority.json); [living-props.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/living-props.json) | 기존 공간·생활·Yjs·발표 보존. 요리/식사/설거지/수납/보드/점유 새 엔진 회귀. 옛 V2 로그는 합산 안 함 |
| R30 | 통합 인수 | `tests/v3-*.mjs`; `tests/v3-*.gd` | [verification-summary.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/verification-summary.json); [scale-soak/report.json](C:/Users/admin/Documents/ChatGPT/3D_모임/homeoffice/evidence/v3/scale-soak/report.json) | 가상 엔진/실제 브라우저 범위. 사람·WAN·운영 배포는 이번 범위 밖 |

## U01–U56 기존 요구의 승계

같은 기능을 최신 R 요구에 연결합니다. “승계”는 삭제하지 않았다는 의미이며, 최신 브라우저 전수 시험 완료를 뜻하지 않습니다.

| ID | 원문 요지 | V3 연결 | 처리 |
|---|---|---|---|
| U01 | 참고 사이트·저장소와 비슷하게 | R01,R12 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U02 | 저 사이트와 전체적인 틀은 비슷하게 | R12,R29 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U03 | 차라리 지금 프로젝트 폐기 | R06 | 프로젝트 삭제 없이 결함 수리·점진적 책임 분리 |
| U04 | 팀원 모두 방에서 | R02,R24 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U05 | 나오려고 할 때 내보내기 버튼 | R29 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U06 | 다시 접속할 때 가져오기 | R29 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U07 | 3D가 매우 심플하니깐 침밀하게 모델 | R03,R13 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U08 | 물리 엔진을 짜고 | R05 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U09 | 캐릭터 자체는 내가 glb 파일 | R03 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U10 | 프롬프트 짤 때 업로드 하라고 | R03 | 기존 실제 남자 원본 발견·사용; 추가 업로드 요청 없음 |
| U11 | 일단 남자만 | R03 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U12 | 총 게임 ... 매우 많이 보완 | R07,R08 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U13 | 농구 게임 ... 실제로 게임 | R09,R10 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U14 | 음성 ... 아직 안 좋으니 더 발전 | R23 | 음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외 |
| U15 | 가까이 있어야 들리는 모드 | R23 | 음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외 |
| U16 | 사용자 설정 가능. 거리 조절 가능 | R23 | 음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외 |
| U17 | 방 전체가 울리는 모드 | R23,R28 | 음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외 |
| U18 | 한국어에 특화 ... 인식이 잘 | R23 | 음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외 |
| U19 | 자막도 제공 ... 좋겠어 | R23 | 음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외 |
| U20 | 사용자가 직접 ... 방에 설치 | R14,R29 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U21 | 의자 | R14,R15 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U22 | 책상 | R14,R20 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U23 | 총 | R07 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U24 | 방패 | R08 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U25 | 책 | R15 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U26 | 보드마카 | R14,R20 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U27 | 상자 | R05,R14 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U28 | 실제로 상호작용 ... 모두 | R14 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U29 | 특정 버튼을 누르면 앉거나 | R14 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U30 | 특정 버튼 ... 보드마카로 그릴 | R14,R20 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U31 | 총 ... 방장이 허락해야만 | R07 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U32 | 방을 좀 더 많이 ... 현재 3방과 마당 | R12,R29 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U33 | 회의방 | R20 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U34 | 화이트 보드 사용 가능 | R20,R29 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U35 | 브레인스토밍 | R20,R29 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U36 | 마인드맵 | R20,R29 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U37 | 보고서 같이 쓰기 | R20,R21 | 내장 공동 도구 보존 + 실제 서비스 원본 참조; 계정 편집 제외 |
| U38 | PPT ... 레이저 등 | R21,R22 | 내장 공동 도구 보존 + 실제 서비스 원본 참조; 계정 편집 제외 |
| U39 | 회의에 필요한 건 모두 | R20 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U40 | 개인 일하는 방 ... 사용자 수에 따라 자동 생성 | R29 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U41 | 복도 ... 방 수에 따라 복도가 늘어나는 | R13,R29 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U42 | 자유 방(모든 기능 사용 가능) | R12,R29 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U43 | 마당(농구장 | R09,R10 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U44 | 축구장 등등) | R11 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U45 | 게임-무기 방 ... 방장이 승인 해야 열림 | R07,R12 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U46 | 간단한 픽맨 | R16 | 최신 지시에 따라 공룡 러너로 대체 |
| U47 | 공룡 게임 | R16 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U48 | 자는 방 ... 수면 취침 | R18 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U49 | 거실 ... 밥 먹고 | R29 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U50 | 요리 하고 | R29 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U51 | 소파에서 점프도 가능 | R05,R29 | 기존 런타임 보존. 수납/요리/식사/보드/점유 새 엔진 회귀를 추가했으나 모든 브라우저 조합 전수 인수는 아님 |
| U52 | 자유럽게 소통 | R23,R29 | 음성/자막 구현 및 가상 시험; 사람·실마이크 인수 제외 |
| U53 | 집+회사처럼 | R12 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U54 | 엔진은 godot | R06 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U55 | 3d 툴은 blenderMCP ... 포트 9876 | R03,R13 | 구현 보존·최신 연결 항목의 검증 범위 적용 |
| U56 | 기본적인 집 구조라기에는 너무 간단함 | R13,R19 | 구현 보존·최신 연결 항목의 검증 범위 적용 |

## G01–G16 검증 묶음

| ID | 이번 구현·시험 범위 | 증거 | 해석 |
|---|---|---|---|
| G01 | 로컬 build ID·혼합 PCK 차단 | session-flow/report.json | 운영 서버 캐시/CDN 배포 제외 |
| G02 | 3브라우저 몸체·2인 행동 | integrated-three/; user-flow/report.json | 전체 양방향 사람 영상·WAN 제외 |
| G03 | 62클립·IK·취침·그립 | gameplay-tests.json; life-flow/report.json | 모든 전이·접촉 미술 품질 완전 인수 아님 |
| G04 | 의자/책/레이저 E/Q/F·한글 | user-flow/report.json; tools-flow/report.json | 기존 모든 소품 조합 전수 아님 |
| G05 | 낙하/CCD·계단·의자·물리 광선 | physics-lab.json; authority-physics.json | 교행/모든 체형/복잡한 더미는 확대 검증 가능 |
| G06 | Practice·연사·실제 광선 피해·방패 | gameplay-tests.json; authority-physics.json | 엔진 제어 초기 조건 시험 |
| G07 | 반발 드리블·스틸·슛·득점 | dribble.json; authority-physics.json | 엔진 제어 초기 조건 시험; 사람 경기 조작감 제외 |
| G08 | 손 집기 차단·발 패스·골·추가 공 | authority-physics.json | 엔진 제어 초기 조건 시험 |
| G09 | 원본 서비스 참조 검증·공유·열기 | node-tests.log; user-flow/report.json | 실제 별도 계정 두 명 편집은 범위 밖 |
| G10 | 질문/할 일 공동 처리·원본 PDF·3D 레이저 | tools-flow/report.json; authority-physics.json | 보드 변경/undo/경합은 legacy-authority.json에서 추가 확인. 모든 Yjs 조합 전수 아님 |
| G11 | 계단·취침·방송석·욕실·컴퓨터 | life-flow/report.json; voice-facilities/report.json; legacy-interactions.json; living-props.json | 요리/식사/설거지/수납은 새 엔진 시험 추가. 최신 모든 조합의 브라우저 전수 인수 아님 |
| G12 | 가상 RTP·전달 범위·종료·방송·자막 정책 | voice-facilities/report.json; stt-browser.json; node-tests.log | 실제 사람/마이크/잡음 환경 정확도 제외 |
| G13 | 동시 교실 입장·고정주소 인계·재개 | session-flow/report.json | 정적 링크와 영구 서버는 구별 |
| G14 | 회의/공지/시설/개인실 파일 복원 | user-flow/report.json; voice-facilities/report.json; scale-soak/report.json | 현재 한 PC의 독립 브라우저/프로세스 범위 |
| G15 | 실제 게임기·점프/duck·결과·관전·종료 | arcade-flow/report.json | 자체 러너 구현 |
| G16 | 2/4/8 접속·30분 활동·재입장 | scale-soak/report.json | 실행 완료/시간/성능은 검증 보고서 확인. WAN/실제 Docs 계정 제외 |
