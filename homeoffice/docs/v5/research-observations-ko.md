# V5 실제 관찰 기록 — 2026-09-17

이 문서는 이번 세션에서 읽거나 재생한 자료를 기록한다. 첨부 문서의 과거 관찰을 이번 실행으로 집계하지 않았다. 영상은 실제 Chromium 페이지의 HTML video를 재생하고 currentTime, paused, readyState와 화면을 저장했다. 모두 음소거 상태였으므로 소리·음성·타격음 품질은 관찰하지 않았다. 검색 결과와 자막으로 영상 시청을 대체하지 않았다.

## 현재 앱과 Blender

공개 사이트를 실제 WebGL로 실행하고 현관→거실→식당을 키 입력으로 걸었다. 첫 경로는 벽에 막혀 실패했고, 실제 문을 통과하는 경로로 수정했다. [공개 기준 자료](../../evidence/v5/baseline/report.json), [재실행](../../evidence/v5/baseline-attempt2/report.json)을 보존했다.

사용자가 지정한 집의 식탁과 거실 테이블을 확인했다. `living-low-table`의 Y가 약 -0.381m였고, GLB 지지대는 존재했다. `dining-table`은 바닥에 정상적으로 서 있었다. Blender의 수입 모델, 원본 GLB와 게임 충돌체를 대조한 결과 낮은 테이블에 상판 충돌체만 있어 바닥까지 가라앉는 결함이었다. 네 지지대 충돌체와 제한된 저장 보정을 추가했다. `reading-table`에도 같은 보정을 적용한다. 다른 모든 책상을 시각 검수했다고 주장하지 않는다.

BlenderMCP 실제 응답은 Blender 5.2.1 LTS, addon 1.6, protocol 5였다. 장면 조회·Python 실행·화면 캡처·GLB 수입/내보내기와 렌더가 성공했다. 원래 기본 Scene과 V3 남자 원본을 보존하고 별도 작업 장면과 V5 파생 파일을 만들었다. 프로토콜 업데이트나 사용자 설정 변경은 하지 않았다. 기존 남자 원본이 있으므로 업로드는 요청하지 않았다.

## 게임 영상 — 본 장면과 적용 판단

| 자료·실제 시각 | 화면에서 확인한 사실 | 카메라·피드백 | 우리 구현에 적용할 원리 / 한계 |
|---|---|---|---|
| [NBA LIVE 19 공식 공개 트레일러](https://www.youtube.com/watch?v=J2tMMb4rh1c), 1.985–12.188초 | 8.110초 양발을 넓게 벌린 무릎 굽힌 공 보유 자세, 10.155초 낮은 발 시점, 12.188초 수비자 앞에서 몸을 낮추고 공을 바닥 가까이 제어하는 장면 | 후면·낮은 시점·측면을 편집한 홍보 영상 | 무볼 준비와 공 보유 동작을 분리한다. 이 편집 영상만으로 입력 지연·접촉 이벤트·게임 내부 알고리즘을 추정하지 않는다. |
| [NBA LIVE 19 실제 플레이](https://www.youtube.com/watch?v=uNhzALVGrB4), 관찰 프레임 6.145 / 12.392 / 18.643 / 24.917 / 31.166 / 39.527초 | 도입 후 코트 플레이. 18.643초 공 보유자와 동료 간격, 24.917초 팔을 올린 슛 동작과 다른 선수 이동, 31.166초 점수 표시 1과 다음 위치 전개, 39.527초 수비자의 낮고 넓은 자세 | 공 보유자 뒤 높은 카메라, 발밑 선택 원, 점수판 | 시야에 동료·수비·목표가 함께 남아야 한다. 슛 전후 하체와 다음 플레이가 연결되어야 한다. 2초 간격 캡처로 정확한 릴리스 순간·백스핀·리바운드 충돌을 판정하지 않았다. |
| [FC 온라인 공식 볼타 홍보](https://www.youtube.com/watch?v=AFDS_2Fy9bg), 9.968–28.136초 | 스타일 연출과 공 묘기·춤이 섞인 편집 장면 | 짧은 컷·인물 중심 | 연속 경기 제어의 근거로 사용하지 않는다. 축구 발 접촉 품질 인수 근거로 부족하다. |
| [FC 온라인 공식 대회 영상](https://www.youtube.com/watch?v=6eTX4UjhzS4), 4.044 / 10.301 / 16.577 / 22.825 / 31.175 / 39.515초 | 4.044초 실제 피치와 선수 배치, 이후 선수 카메라·명단·선택/매치 안내 중심 | 높은 중계 시점과 방송 그래픽 | 경기 장면이 실제로 포함되지만 현재 본 범위로 드리블→첫 터치→패스→골 전 과정을 분석할 수 없다. T03 축구 주요 사건은 미완료다. |
| [VALORANT 공식 The Round](https://www.youtube.com/watch?v=g8amyzDHOKw), 35.483 / 39.817 / 43.950 / 48.087 / 52.197 / 56.278초 | 조준경, 도구 사용 손, 녹색 가림막 주변 소총 이동, 탄약 표시 변화, 칼로 바꿔 이동하는 장면 | 1인칭 무기 실루엣·조준·탄약 HUD가 함께 보임 | 장착·이동·조준·발사 피드백을 상태별로 연결한다. 이 구간으로 재장전·피격·KO·한 라운드 완결을 검증했다고 하지 않는다. |

근거 파일은 [references](../../evidence/v5/references/)의 `playback-attempts.json`, 각 `observation.json`과 JPG다. NBA 공식 6장, NBA 실제 플레이 6장, FC 홍보·대회 및 VALORANT 대표 프레임을 실제로 열어 확인했다. 저장된 모든 프레임을 개별로 판독한 것은 아니다.

NBA 100초·FC 120초 탐색은 재생 데이터가 준비되지 않아 실패했다. 연속 재생도 일부 영상에서 약 40초 뒤 멈췄다. 실패한 폴더를 성공 자료로 덮어쓰지 않았다. FC 가이드의 2.375초 `Gamestart.webm`은 경기 관찰로 세지 않았다. 이번 조사는 부분 시청이며 T03 전체 합격이 아니다.

## 읽은 1차 기술 자료

- [Roblox IK 문서](https://create.roblox.com/docs/animation/inverse-kinematics): 목표·체인 기반 보정을 상태별 애니메이션과 분리하는 참고 자료다. Roblox 내부 이동 코드를 복제했다고 주장하지 않는다.
- [Godot AnimationTree](https://docs.godotengine.org/en/4.6/tutorials/animation/animation_tree.html), [AnimationNodeTimeSeek](https://docs.godotengine.org/en/4.6/classes/class_animationnodetimeseek.html), [SkeletonModifier3D](https://docs.godotengine.org/en/4.6/classes/class_skeletonmodifier3d.html): 한 트리에서 합성하고 위상을 유지하며 보정 단계가 애니메이션 뒤에 실행되도록 구성했다.
- [EA FC 25 개발 설명](https://www.ea.com/games/ea-sports-fc/fc-25/news/pitch-notes-fc-25-gameplay-deep-dive): 공 소유 여부와 역할에 따른 움직임 분리의 보조 자료다. FC ONLINE과 다른 제품이며 해당 영상 시청의 대체가 아니다.
- [VALORANT 무기 제작 설명](https://playvalorant.com/en-us/news/dev/how-the-valorant-arsenal-was-built/): 무기별 식별성과 명료한 프레젠테이션을 참고했다. 기존 자유사격을 유지하며 자체 지도·라운드 완성은 남아 있다.

## 실제 공간 설계 자료와 적용

[WBDG Office Building](https://legacy.wbdg.org/building-types/office-building)은 사무실 외 로비·공용 공간·화장실·식사·수납·IT·유지관리 공간과 음향 분리를 함께 다룬다. 이를 OFFICE 프로그램에 반영했다. [WBDG Conference / Classroom](https://legacy.wbdg.org/space-types/conference-classroom)의 가구 접근, 자료 보기, 조명과 주변 공간의 음향 분리 원리를 회의실 설계에 적용한다. 페이지 제목은 교육용 앱 규칙을 추가하는 근거가 아니다.

[YourHome의 접근·변경 가능한 집](https://www.yourhome.gov.au/live-adapt/liveable-adaptable-home)과 [집 설계 과정](https://www.yourhome.gov.au/buy-build-renovate/design-house)은 생활·주방·욕실·수면 연결과 실제 가구 크기로 평면을 검토하는 원리를 제공한다. HOME 공용 복도와 위생 블록을 층별로 연결하고 옷방을 실제 방으로 계획했다. 이 자료를 건축 법규 인증이나 특정 치수의 법적 적합성으로 사용하지 않는다.

초기 WBDG 일반 주소는 본문 0줄이었으나 이번에는 `legacy.wbdg.org`의 본문을 실제로 읽었다. 앞서 안전 열기 오류가 난 GSA·FIBA 주소는 읽은 자료로 집계하지 않았다. 운동장 치수는 첨부 명세에 근거한 설계 가정이며, 공식 규격의 최신 원문 대조는 별도 미실행이다.
